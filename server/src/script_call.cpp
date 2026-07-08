#include "singleton.h"
#include "protocol.h"
#include "online_user.h"
#include "user.h"
#include "utility.h"
#include "script_call.h"
#include "call_script.h"
#include "huo_dong.h"
#include "main.h"
#include "init.h"
#include "rank.h"
#include <lua.hpp>
#include <boost/thread.hpp>
#include <boost/format.hpp>
#include <boost/xpressive/xpressive_dynamic.hpp>  
#include "mission_manager.h"
#include "award_manager.h"
#include "pet_equip_manage.h"

struct KunLunShanRoleData
{
	KunLunShanRoleData()
	{
		roleId = 0;
		zhandouli = 0;
		score = 0;
		continueWinNum = 0;
		serverId = 0;
		serverZone = 0;
		xiang = 0;
		roleName.clear();
	}
	uint32 roleId;
	uint32 zhandouli;
	string roleName;
	int score;	// 历练点
	int continueWinNum;	// 连续胜利次数
	int serverId;
	int serverZone;
	int xiang;
};

struct SKunLunShanScore
{
	bool operator()(const KunLunShanRoleData &b1,const KunLunShanRoleData &b2)
	{
		if(b1.score > b2.score)
			return true;
		else if(b1.score == b2.score)
		{
			if(b1.zhandouli > b2.zhandouli)
				return true;
			else if(b1.zhandouli == b2.zhandouli)
			{
				if(b1.roleId < b2.roleId)
					return true;
			}
		}
		return false;
	}
};

struct KunLunShanServerData
{
	KunLunShanServerData()
	{
		zoneId = 0;
		score = 0;
	}
		
	uint32 zoneId;
	uint32 score;
};

struct SKunLunShanServerScore
{
	bool operator()(const KunLunShanServerData &b1,const KunLunShanServerData &b2)
	{
		if(b1.score > b2.score)
			return true;
		return false;
	}
};


vector<KunLunShanRoleData> kunlunshanPaiHang;
boost::recursive_mutex kunLunShan_mutex;

vector<KunLunShanRoleData> kunlunshanTeamPaiHang;
vector<KunLunShanServerData> kunlunshanTeamServerPaiHang;
boost::recursive_mutex kunLunShanTeam_mutex;

extern CDatabaseSql g_LoginDB;
extern boost::recursive_mutex G_LoginDB_Mutex;

const int sMaxMoney[] = {500000,700000,1000000,2000000,5000000};
extern std::map<uint16,SkillInfoNode> skillInfoListMap;

extern boost::recursive_mutex tongTianTa_mutex;
extern uint16 tongTianTaBaZhuFloor[5];
extern vector<uint32> tongTianTaBaZhuData;	// 通天塔霸主ID,12/24/36/48/60

extern const char *gConfigFile;
static int CREATE_BANGPAI_YB = 1000;

extern uint32 randombox_stamp;
extern std::map<uint32,uint32> limitSaveMap;
extern std::map<uint32,RandomBoxItem> randombox_cfg;

#ifndef KUA_FU
static int BZ_WIN_BANG_ID = 0;
#else
static int BZ_WIN_BANG_ID[CBangPaiManager::MAX_KFBZ_GROUP] = {0};
#endif

bool CheckPass(char *pStr)
{
	while(*pStr)
	{
		if(isalnum(*pStr) == 0)
			return false;
		pStr++;
	}
	return true;
}

int DialogT(CUser *pUser,const char *name,const char *text)
{
	if(pUser == NULL || name == NULL || text == NULL)
		return -1;
	
	vector<ShareUserPtr> pMember;
	GetTeamMemberList(pUser,pMember);
	int roleNum = pMember.size();
	if(roleNum < 1)
		return -1;
	for(int i=0;i < roleNum;i++)
	{
		if(pMember[i].get() != NULL)
			Dialog(pMember[i].get(),name,text);
	}
	return 1;
}

static void MakeNpcPic(CNetMessage &msg,SNpcInstance &npc)
{
	if(npc.templateId == 0 || npc.pNpc == NULL)
		return;
	if(npc.type > 0)
		msg<<npc.type;
	else
		msg<<npc.pNpc->type;
	if(npc.pic > 0)
		msg<<npc.pic;
	else
		msg<<npc.pNpc->pic;
}

int Dialog(CUser *pUser,const char *name,const char *text)
{
	if((name == NULL) || (text == NULL))
		return 1;

	if (pUser == NULL)
		return 1;
	pUser->SetScriptCallOption();

	SNpcInstance &npc = pUser->GetInteractNpc();
	if(npc.templateId == 0)
		return 1;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_INTERACT);

	msg<<(uint8)1<<name<<text<<(uint8)0;
	MakeNpcPic(msg,npc);
	sock.SendMsg(pUser->GetSock(),msg);
	return 1;
}

int Dialog_End(CUser *pUser,const char *name,const char *text)
{
	if((name == NULL) || (text == NULL))
		return 1;

	if (pUser == NULL)
		return 1;
	pUser->SetScriptCallOption();

	SNpcInstance &npc = pUser->GetInteractNpc();
	if(npc.templateId == 0)
		return 1;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_INTERACT);

	msg<<(uint8)1<<name<<text<<(uint8)1;
	MakeNpcPic(msg,npc);
	sock.SendMsg(pUser->GetSock(),msg);
	return 1;
}

// @param int state 剧情对话的状态 1:开始 2:过程中 3:结束
// @param int npcId 是否是玩家 -1:玩家 -2:没有人 其他负数:怪
int DialogS(CUser* pUser, int npcId, int state, const char* name, const char* text) // 剧情对话
{
	if((pUser == NULL) ||(npcId == 0) || (name == NULL) || (text == NULL))
		return -1;
	pUser->SetScriptCallOption();

	CNetMessage msg;
	msg.SetType(PRO_INTERACT);
	if (npcId == -1) // 玩家
	{
		msg<<(uint8)42<<(uint16)0<<(uint8)1<<(uint8)state<<name<<text;
	}
	else if (npcId == -2) // 没有人
	{
		msg<<(uint8)42<<(uint16)0<<(uint8)9<<(uint8)state<<name<<text;
	}
	else if (npcId == -3) // 坐骑
	{
		msg<<(uint8)42<<(uint16)1<<(uint8)3<<(uint8)state<<name<<text;
	}
	else if (npcId < 0) // 怪物
	{
		npcId = npcId*(-1);
		CNpcManager &npcManager = SingletonNpcManager::instance();
		SNpcTemplate *pNpc = npcManager.GetNpcTemplate(npcId);
		if(pNpc == NULL)
			return -1;
		msg<<(uint8)42<<pNpc->pic<<(uint8)2<<(uint8)state<<name<<text;
	}
	else // npc
	{
		CNpcManager &npcManager = SingletonNpcManager::instance();
		SNpcTemplate *pNpc = npcManager.GetNpcTemplate(npcId);
		if (pNpc == NULL)
			return -1;

		msg<<(uint8)42<<pNpc->pic<<(uint8)pNpc->type<<(uint8)state<<name<<text;
	}
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
	return 0;
}

// 剧情对话 特化处理 开始
int DialogS_Start(CUser* pUser, int npcId, const char* name, const char* text)
{
	pUser->m_npcInteractTimeout = GetSysTime();
	return DialogS(pUser,npcId,1,name,text);
}

// 剧情对话 特化处理 进行
int DialogS_Doing(CUser* pUser, int npcId, const char* name, const char* text)
{
	return DialogS(pUser,npcId,2,name,text);
}

// 剧情对话 特化处理 结束
int DialogS_End(CUser* pUser, int npcId, const char* name, const char* text)
{
	pUser->m_npcInteractTimeout = 0;
	return DialogS(pUser,npcId,3,name,text);
}

// 弹出寻神将界面
void ShowPetCopyPanel(CUser *pUser)
{
	if(pUser == NULL)
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_INTERACT);
	msg<<(uint8)49;
	sock.SendMsg(pUser->GetSock(),msg);
}

// 弹出矿产界面
void ShowMinePanel(CUser *pUser)
{
	if(pUser == NULL)
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_INTERACT);
	msg<<(uint8)50;
	sock.SendMsg(pUser->GetSock(),msg);
}

// type=0积分1伏妖镇魔
int MakeDailyBossInfo(CUser *pUser,int type,int sid,int x,int y,const char *str)
{
	if(pUser == NULL || str == NULL)
		return -1;

	const int S_NUM = 440;
	char *split[S_NUM];
	string buf = str;
	const int splitNum = 13;
	int num = SplitLine(split,S_NUM,(char*)buf.c_str());
	if(num%splitNum != 0)
	{
		cout<<"MakeDailyBossInfo str error"<<endl;
		return -1;
	}
	num /= splitNum;

	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_DailyBoss_TASK);
	msg<<(uint8)1<<(uint8)type;

	uint8 maxNum = pUser->GetCanDoRingBossNum() + pUser->GetBossBuyNum();
	uint8 leftNum = (uint8)(maxNum - pUser->GetBossTZNum());
	if(leftNum > 127)
		leftNum = 0;
	msg<<leftNum;
	// 			当前总星星数				最多星星数
	msg<<pUser->GetBossMissionTotolStarNum()<<(uint8)(DAILY_BOSS_MAX_NUM*3);

	msg<<(uint16)sid<<(uint16)x<<(uint16)y<<(uint8)num;
	for (int i = 0; i < num; i++)
	{
		//                 index                       star                    difficult(1-4)               monsterId
		msg<<(uint8)atoi(split[splitNum*i])<<(uint8)atoi(split[splitNum*i+1])<<(uint8)atoi(split[splitNum*i+2])<<(uint16)atoi(split[splitNum*i+3]);
		//             exp                     itemId                     itemNum               desc1               flag 0未完成1完成  
		msg<<atoi(split[splitNum*i+4])<<(uint16)atoi(split[splitNum*i+5])<<atoi(split[splitNum*i+6])<<split[splitNum*i+7]<<(uint8)atoi(split[splitNum*i+8]);
		//           desc2				flag 0未完成1完成				name                      推荐等级
		msg<<split[splitNum*i+9]<<(uint8)atoi(split[splitNum*i+10])<<split[splitNum*i+11]<<(uint16)atoi(split[splitNum*i+12]);
	}

	uint8 yindaoFlag = 0;	// 0不引导1引导
	if(!pUser->HaveBitSet(333))
	{
		if(pUser->GetBossMissionTotolStarNum() >= 1)
		{
			pUser->SetBitSet(333);
			yindaoFlag = 1;
		}
	}
	msg<<yindaoFlag;

	uint32 leftTime = GetSysTime() - pUser->GetExtData32(104);
	if(leftTime >= 5*60)
		msg<<(uint32)0;
	else
		msg<<leftTime;
	sock.SendMsg(pUser->GetSock(),msg);
	return 0;
}

// type 0 不打开面板 1 打开每日boss界面
void ShowDailyBossFightEnd(CUser *pUser,int starNum,int exp,int index,int type,int addStar,int itemId,int itemNum)
{
	if(pUser == NULL)
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_DailyBoss_TASK);
	msg<<(uint8)7<<(uint8)index<<exp<<(uint8)starNum<<(uint8)type;
	msg<<(uint8)pUser->GetBossMissionTotolStarNum()<<(uint8)addStar;
	msg<<(uint16)itemId<<itemNum;
	sock.SendMsg(pUser->GetSock(),msg);
}

// type 0 不打开面板 1 打开每日boss界面
void SendDailyBossShowIconInfo(CUser *pUser)
{
	if(pUser == NULL/* || pUser->GetLevel() < DailyBossLevelLimit*/)
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_DailyBoss_TASK);
	msg<<(uint8)11;

	uint8 totolStar = pUser->GetBossMissionTotolStarNum();
	uint8 show = 0;	// 0不显示1显示
	if(totolStar < 5)
		show = 1;
	msg<<show<<totolStar;
	sock.SendMsg(pUser->GetSock(),msg);
}

void PlayPetDrawCartoon(CUser *pUser,uint16 petId,uint16 petLevel,uint8 petStar,uint16 transItemId,uint16 transItemNum)
{
	if(pUser == NULL || petId == 0)
		return;
	
	CNetMessage msg;
	msg.SetType(MSG_PET_CARTOON);
	if(transItemId == 0)
		msg<<(uint8)1<<petId<<petLevel<<petStar;
	else
		msg<<(uint8)3<<petId<<petLevel<<petStar<<transItemId<<transItemNum;
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void PlayItemDrawCartoon(CUser *pUser,uint16 itemId,uint16 itemNum)
{
	if(pUser == NULL || itemId == 0)
		return;
	CNetMessage msg;
	msg.SetType(MSG_PET_CARTOON);
	msg<<(uint8)2<<itemId<<itemNum;
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

bool SetGenSuiPetDown(CUser *pUser)
{
	if(pUser == NULL)
		return false;
	pUser->SetExtData16(54,0);
	uint16 gensuiId = pUser->GetGenSuiPet();
	if(gensuiId != 0)
	{
		pUser->SetExtData16(54,gensuiId);
		pUser->SetPetHide(gensuiId);
		CScene *pScene = pUser->GetScene();
		if(pScene != NULL)
			pScene->UpdateUserInfo(pUser,ESRT_Pet_Follow);
	}
	return true;
}

void SetGenSuiPetUp(CUser *pUser)
{
	if(pUser == NULL)
		return;
	uint16 petId = pUser->GetExtData16(54);
	if(petId > 0)
	{
		uint16 gensuiId = pUser->GetGenSuiPet();
		if(gensuiId == 0)
		{
			pUser->SetGenSuiPet(petId);
			CScene *pScene = pUser->GetScene();
			if(pScene != NULL)
				pScene->UpdateUserInfo(pUser,ESRT_Pet_Follow);
		}
	}
}

bool SetQiPetDown(CUser *pUser)
{
	if(pUser == NULL)
		return false;
	uint8 index = pUser->GetMountIndex();
	if(index != 0xff)
	{
		CNetMessage msg;
		msg.ReWrite();
		msg.SetType(MSG_MOUNT);
		msg<<(uint8)4<<(uint8)0xff;
		pUser->SetExtData8(144,index);
		pUser->SetMountState(msg,0xff);	// 坐骑休息
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);

		CScene *pScene = pUser->GetScene();
		if(pScene != NULL)
			pScene->UpdateUserInfo(pUser,ESRT_Mount_State);		
		return true;
	}
	pUser->SetExtData8(144,index);
	return false;
}

void SetQiPetUp(CUser *pUser)
{
	if(pUser == NULL)
		return;
	uint8 index = pUser->GetExtData8(144);
	if(index == 0xff)
		return;
	uint8 mid = pUser->GetMountIdByIdx(index);
	if(mid == 0)
		return;
	if(pUser->GetMountIndex() == 0xff)
	{
		CNetMessage msg;
		msg.ReWrite();
		msg.SetType(MSG_MOUNT);
		msg<<(uint8)4<<mid;
		pUser->SetExtData8(144,0xff);
		pUser->SetMountState(msg,index);	// 骑坐骑
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);

		CScene *pScene = pUser->GetScene();
		if(pScene != NULL)
			pScene->UpdateUserInfo(pUser,ESRT_Mount_State);
	}
}

// type=1积分2跑环
int UpdateDailyBossInfo(CUser *pUser,int index,int starNum,const char* pStr1,int isfinish1,const char* pStr2,int isfinish2)
{
	if(pUser == NULL || pStr1 == NULL || pStr2 == NULL)
		return -1;

	uint8 maxNum = pUser->GetCanDoRingBossNum();
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_DailyBoss_TASK);
	msg<<(uint8)2<<pUser->GetBossMissionTotolStarNum()<<(uint8)index;
	if(pUser->GetBossTZNum() >= maxNum)
		msg<<(uint8)0;
	else
		msg<<(uint8)(maxNum - pUser->GetBossTZNum());
	msg<<(uint8)starNum<<pStr1<<(uint8)isfinish1<<pStr2<<(uint8)isfinish2;
	sock.SendMsg(pUser->GetSock(),msg);
	return 0;
}

void CloseDailyBossPanel(CUser *pUser)
{
	if(pUser == NULL)
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_DailyBoss_TASK);
	msg<<(uint8)6;
	sock.SendMsg(pUser->GetSock(),msg);
}

// 战斗失败推送消息
void SendFightFailed_PushMsg(CUser *pUser, const char *pStr, const char* pHintStr)
{
	return;
/*	
	if(pUser == NULL || pStr == NULL || pHintStr == NULL)
		return;

	//长度检测
	if(strlen(pStr) > 256 || strlen(pHintStr) > 256)
		return;

	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_FIGHT_END_PUSH_MSG);
	msg<<pHintStr;
	msg<<pStr;
	sock.SendMsg(pUser->GetSock(),msg);
*/
}

int Option(CUser *pUser,const char *name,const char *text,const char *opt)
{
	if(opt == NULL || name == NULL || text == NULL)
		return 0;
	if (pUser == NULL)
		return 1;

	char *split[40];
	string str = opt;
	int num = SplitLine(split,40,(char*)str.c_str());
	if (num % 2 != 0)
	{
		//cout<<opt<<endl;
		cout<<"opt error"<<endl;
		return 0;
	}
	num /= 2;
	/********************
	TYPE=2 弹出选项 CONT格式为:
	+-----+-------+-----+-------+-----+-----+-----+
	| LEN | TITLE | NUM | OPTID | LEN | OPT | ... |
	+-----+-------+-----+-------+-----+-----+-----+
	|  2  |  Var  |  1  |   1   |  2  | Var | ... |
	+-----+-------+-----+-------+-----+-----+-----+
	*********************/

	SNpcInstance &npc = pUser->GetInteractNpc();
	if(npc.templateId == 0)
		return 1;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	list<int> t_list;
	msg.SetType(PRO_INTERACT);

	msg<<(uint8)2<<name<<text;
	MakeNpcPic(msg,npc);
	msg<<(uint8)num;
	for (int i = 0; i < num; i++)
	{
		msg<<atoi(split[2*i])<<split[2*i+1];
		t_list.push_back(atoi(split[2*i]));
	}
	pUser->SetScriptCallOption(&t_list);
	sock.SendMsg(pUser->GetSock(),msg);
	return 1;
}

//针对交互中需要再次出现交互的选择框
int OptionConfirm(CUser *pUser,const char *name,const char *text,const char *opt)
{
	if(opt == NULL)
		return 0;
	if (pUser == NULL)
		return 1;

	char *split[40];
	string str = opt;
	int num = SplitLine(split,40,(char*)str.c_str());
	if (num % 2 != 0)
	{
		//cout<<opt<<endl;
		cout<<"opt error"<<endl;
		return 0;
	}
	num /= 2;
	/********************
	TYPE=2 弹出选项 CONT格式为:
	+-----+-------+-----+-------+-----+-----+-----+
	| LEN | TITLE | NUM | OPTID | LEN | OPT | ... |
	+-----+-------+-----+-------+-----+-----+-----+
	|  2  |  Var  |  1  |   1   |  2  | Var | ... |
	+-----+-------+-----+-------+-----+-----+-----+
	*********************/
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	list<int> t_list;
	msg.SetType(PRO_INTERACT);

	msg<<(uint8)43<<name<<text<<(uint8)num;
	for (int i = 0; i < num; i++)
	{
		msg<<atoi(split[2*i])<<split[2*i+1];
		t_list.push_back(atoi(split[2*i]));
	}
	pUser->SetScriptCallOption(&t_list);
	sock.SendMsg(pUser->GetSock(),msg);
	return 1;
}

// type = 1 普通采集 3s
// type = 2    3s
// type = 3    15s
// type = 4 宝箱拾取 15s
// type = 5 占领塔 6s 
int Collect(CUser *pUser,int npcId,int npcIdx,int pic,int type,const char *showMsg)
{
	if (pUser == NULL || showMsg == NULL)
		return -1;
	int seconds = 3;	//读条时间(添加的协议字段，只对类型3有用处，其他类型默认0)
	if (type == 3 || type == 4)
		seconds = 15;
	else if (type == 5)
		seconds = 6;
	list<int> t_list;
	t_list.push_back(npcIdx);
	pUser->SetScriptCallOption(&t_list);

	string str = LANGUAGE_SSJ_0402;
	if(showMsg != NULL)
		str = showMsg;
	CNetMessage msg;
	msg.SetType(PRO_INTERACT);
	msg<<(uint8)40<<str<<(uint16)npcId<<(uint16)npcIdx<<seconds<<pic;
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);

	pUser->SetCollectIndex(npcId);
	CScene *pScene = pUser->GetScene();
	if (pScene != NULL)
		pScene->UpdateUserInfo(pUser, ESRT_State);
	return 0;
}

// 显示引导
// @param int type 引导类型 1:接取任务 2:交任务 3:Shortcut提示框 4:任务追踪
// @return 0:正常 -1:用户为空
int ShowGuidance(CUser *pUser,int type)
{
	if (pUser == NULL)
		return -1;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_INTERACT);
	msg<<(uint8)41<<(uint8)type;
	sock.SendMsg(pUser->GetSock(),msg);
	return 0;
}

void CreateBangPaiPanel(CUser *pUser)
{
#ifdef KUA_FU
	return;
#endif
	if(pUser == NULL)
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_INTERACT);
	msg<<(uint8)45<<(uint16)CREATE_BANGPAI_YB;
	sock.SendMsg(pUser->GetSock(),msg);
}

SItemTemplate *GetItem(int itemId)
{
	return SingletonItemManager::instance().GetItem(itemId);
}

const char *GetItemName(int itemId)
{
	switch (itemId)
	{
	case HDAT_MONEY:// 金币
		return LANGUAGE_LLD_0106;
	case HDAT_BANG_YB:// 元宝
		//return LANGUAGE_LLD_0107;
	case HDAT_YB:// 元宝
		return LANGUAGE_LLD_0108;
	case HDAT_EXP:
		return LANGUAGE_SSJ_1007;
	case HDAT_QIANNENG:// 潜能
		return LANGUAGE_TRANSFORM_2960;
	case HDAT_SHEN_HUN:// 神魂之魄
		return LANGUAGE_TRANSFORM_2959;
	case HDAT_VIP_EXP:// 贵族经验
		return LANGUAGE_ZQX_0026;
	case HDAT_LEITAI_JIFEN:// 积分
		return LANGUAGE_ZQX_0043;
	case HDAT_BANG_GONG:// 帮贡
		return LANGUAGE_ZQX_0089;
	case HDAT_XingXiuJingHua: // 星宿精华
		return LANGUAGE_ZQX_0096;
	case HDAT_HuoYue:	// 活跃度
		return LANGUAGE_SSJ_0549;
	case HDAT_JJCMoney:
		return LANGUAGE_ZQX_0211;
	case HDAT_KunLunMoney:
		return LANGUAGE_ZQX_0212;
	case HDAT_ArenaCnt:
		return LANGUAGE_ZQX_0222;
	case HDAT_FaBaoSS:
		return LANGUAGE_ZQX_0223;
	default:
		break;
	}
	SItemTemplate *pItem = GetItem(itemId);
	if(pItem == NULL)
		return NULL;
	return pItem->name.c_str();
}

int GetItemColor(int item)
{
	SItemTemplate *pItem = GetItem(item);
	if (pItem == NULL)
		return 4;
	return GetQualityColor(pItem->quality);
}

int GetQualityColor(int quality)
{
	switch (quality)
	{
	case 1:
		return GGCT_WHITE;
	case 2:
		return GGCT_GREEN;
	case 3:
		return GGCT_BLUE;
	case 4:
		return GGCT_PURPLE;
	case 5:
		return GGCT_ORANGE;
	case 6:
		return GGCT_RED;
	case 7:
		return GGCT_GOLD;
	default:
		return GGCT_WHITE;
	}
	return 4;
}

string GetItemColorStr(int type, int value, int extValue/* = 0*/, int extValue1/* = 0*/)
{
	char buf[256];
	switch (type)
	{
	case HDAT_PetEquip:
	{
		CItemCfgManager& mgr = sCItemCfgManager;
		snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0095, mgr.GetEquipColor(extValue), mgr.GetEquipName(value), 1);
	}
	break;

	case HDAT_PET:
		snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0063, GetPetDefaultQuality(value), GetPetName(value));
		break;

	case HDAT_CHENGHAO:
		snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0095, GetItemColor(type), sTitltAttrCfgManager.GetTitleName(value), 1);
		break;

	case HDAT_FaBao:
	{
		CItemCfgManager& mgr = sCItemCfgManager;
		FaBaoCfg* fcfg = mgr.GetFaBaoCfg(value);
		if (fcfg == NULL)
			return "";
		snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0095, GetQualityColor(fcfg->quality), fcfg->name.c_str(), 1);
	}
	break;

	default:
		snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0095, GetItemColor(type), GetItemName(type), value);
		break;
	}
	return buf;
}

void AddItemTmpl(SItemTemplate *pItem)
{
	SItemTemplate *pTemp = new SItemTemplate;
	*pTemp = *pItem;

	SingletonItemManager::instance().AddItem(pTemp);
}

void SysInfo(CUser *pUser,const char *info)
{
#ifdef DEBUG
	cout<<"SysInfo:"<<endl<<info<<endl;
#endif
	SendSysInfo(pUser,info);
}

void FirstLoginPanel(CUser *pUser,const char *pMsg)
{
	if(pUser == NULL || pMsg == NULL)
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_FIRST_LOGIN_PANEL);

	msg<<(uint8)1<<pMsg;
	sock.SendMsg(pUser->GetSock(),msg);
}

void SMessage(CUser *pUser,const char *pMsg)
{
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_INTERACT);
	if (pUser == NULL)
		return;
	pUser->SetScriptCallOption();

	msg<<(uint8)5<<pMsg<<(uint8)0;
	sock.SendMsg(pUser->GetSock(),msg);
}

void SMessage_End(CUser *pUser,const char *pMsg)
{
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_INTERACT);
	if (pUser == NULL)
		return;
	pUser->SetScriptCallOption();

	msg<<(uint8)5<<pMsg<<(uint8)1;
	sock.SendMsg(pUser->GetSock(),msg);
}

//物品选择
void SelectItem(CUser *pUser,int i,int j)
{
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_INTERACT);
	if (pUser == NULL)
		return;

	msg<<(uint8)3<<(uint8)i<<(uint8)j;
	sock.SendMsg(pUser->GetSock(),msg);
}

//选择神将
void SelectPet(CUser *pUser,int petId,const char *name,const char *pMsg)
{
	if ((pUser == NULL) || (pMsg == NULL) || (name == NULL))
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_INTERACT);

	msg<<(uint8)6<<name<<pMsg<<(uint16)petId;
	sock.SendMsg(pUser->GetSock(),msg);
}

void OpenPackage(CUser *pUser,int type)
{
	if (pUser == NULL)
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_INTERACT);

	msg<<(uint8)7<<(uint8)type;
	sock.SendMsg(pUser->GetSock(),msg);
}

/**************
用户学习技能金币和潜能消耗：
***************/
int GetMoney(uint16 skillId,uint8 skillLevel,int &qianNeng,int &money)
{
	struct SkillLevelUpNode
	{
		SkillLevelUpNode()
		{
			qianNeng = -1;
			money = -1;
		}
		int qianNeng;
		int money;
	};
	struct SkillLevelUpConst
	{
		SkillLevelUpConst()
		{
			skillId = 0;
		}
		uint8 skillId;
		SkillLevelUpNode SkillLevelNode[120];
	};
	static struct SkillLevelUpConst *t_skillLevelUp = NULL;

	qianNeng = -1;
	money = -1;
	if(t_skillLevelUp == NULL)
	{
		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		if(pDb == NULL)
			return -1;
		char sql[256];
		char **row = NULL;
		snprintf(sql,sizeof(sql),"select max(skillId) from skill_levelup");
		if(!pDb->Query(sql))
			return -1;
		if((row = pDb->GetRow()) != NULL)
		{
			t_skillLevelUp = new SkillLevelUpConst[atoi(row[0])];
			if(t_skillLevelUp == NULL)
				return -1;
		}
		else
		{
			return -1;
		}

		snprintf(sql,sizeof(sql),"select skillId,skillLevel,QianNeng,money from skill_levelup order by skillId asc,skillLevel asc");
		if(!pDb->Query(sql))
			return -1;
		while((row = pDb->GetRow()) != NULL)
		{
			t_skillLevelUp[atoi(row[0])-1].skillId = atoi(row[0]);
			t_skillLevelUp[atoi(row[0])-1].SkillLevelNode[atoi(row[1])-1].qianNeng = atoi(row[2]);
			t_skillLevelUp[atoi(row[0])-1].SkillLevelNode[atoi(row[1])-1].money = atoi(row[3]);
		}
	}
/*
	for(int i=0;i < skillNum;i++)
	{
		cout<<">>>>> skill id = "<<(int)(t_skillLevelUp[i].skillId)<<endl;
		for(int j=0;j < 100;j++)
		{
			cout<<"== level = "<<j+1<<", money = "<<(int)t_skillLevelUp[i].SkillLevelNode[j].money<<", qianneng = "<<(int)t_skillLevelUp[i].SkillLevelNode[j].qianNeng<<endl;
		}
	}
*/

	if(t_skillLevelUp[skillId-1].skillId != skillId)
		return -1;
	qianNeng = t_skillLevelUp[skillId-1].SkillLevelNode[skillLevel-1].qianNeng;
	money = t_skillLevelUp[skillId-1].SkillLevelNode[skillLevel-1].money;
	if(qianNeng == -1 || money == -1)
		return -1;
	return 0;
}

void SellItem(CUser *pUser,int type,const char *items, int selectId/* = 0*/, int cnt/* = 0*/)//items "1|2|3……"
{
	if ((pUser == NULL) || (items == NULL))
		return;

	CSocketServer &sock = SingletonSocket::instance();

	char *split[100];
	string item = items;
	uint8 num = SplitLine(split,50,(char*)item.c_str());

	CNetMessage msg;
	msg.SetType(PRO_INTERACT);
	msg<<(uint8)4<<(uint8)type;
	uint16 pos = msg.GetDataLen();
	msg<<num;
	CItemTemplateManager &itemMgr = SingletonItemManager::instance();
	uint8 count = 0;
	for (uint8 i = 0; i < num; i++)
	{
		SItemTemplate *pItem = itemMgr.GetItem(atoi(split[i]));
		if (pItem != NULL)
		{
			//msg<<pItem->id;//<<(int)pItem->jiage;
			SItemInstance item;
			item.tmplId = pItem->id;
			item.num = cnt;
			MakeItemInfo(&item,msg);
			msg<<(uint8)1<<(int)pItem->jiage;
			count++;
		}
	}
	msg<<(uint16)selectId<<cnt;
	msg.WriteData(pos,&count,sizeof(count));
	sock.SendMsg(pUser->GetSock(),msg);
}

void SellSeedItem(CUser *pUser,const char *items)	//items "1|2|3……"
{
	if ((pUser == NULL) || (items == NULL))
		return;

	CSocketServer &sock = SingletonSocket::instance();

	char *split[100];
	string item = items;
	uint8 num = SplitLine(split,50,(char*)item.c_str());

	CNetMessage msg;
	msg.SetType(PRO_INTERACT);
	msg<<(uint8)4<<(uint8)5;
	uint16 pos = msg.GetDataLen();
	msg<<num;

	CItemTemplateManager &itemMgr = SingletonItemManager::instance();
	CPlantSeedManager &seedMgr = SingletonCPlantSeedManager::instance();
	uint8 count = 0;
	for (uint8 i = 0; i < num; i++)
	{
		SItemTemplate *pItem = itemMgr.GetItem(atoi(split[i]));
		if(pItem != NULL)
		{
			SPlantSeed *pTmpSeed = seedMgr.FindSeed(pItem->id);
			if(pTmpSeed == NULL)
				continue;
			SItemInstance item;
			item.tmplId = pItem->id;
			item.num = 1;
			MakeItemInfo(&item,msg);
			uint32 price = pTmpSeed->price;
			msg<<pTmpSeed->priceType<<price;
			count++;
		}
	}
	msg<<(uint16)0;	// 默认选中id
	msg.WriteData(pos,&count,sizeof(count));
	sock.SendMsg(pUser->GetSock(),msg);
}

SPlantSeed *GetSeedItem(uint32 itemId)
{
	return SingletonCPlantSeedManager::instance().FindSeed(itemId);
}

void ShowUserExchangePanel(CUser *pUser)
{
	if(pUser == NULL)
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_SHOP);
	msg<<(uint8)9;
	
	uint8 num = 0;
	uint16 pos = msg.GetDataLen();
	msg<<num;
	num += pUser->GetPetExchangeList(msg);
	num += pUser->GetItemChipExchangeList(msg);
	msg.WriteData(pos,&num,sizeof(num));
	sock.SendMsg(pUser->GetSock(),msg);
}

void CloseInteract(CUser *pUser)
{
	if (pUser == NULL)
		return;
	pUser->ClearScriptCallOption();
	CNetMessage msg;
	msg.SetType(PRO_CLOSE_INTERACT);
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void ShowJoinBangPaiPanel(CUser *pUser)
{
	CNetMessage msg;
	msg.SetType(PRO_INTERACT);
	msg<<(uint8)48;
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

// 尝试转换钓鱼场景srcid
void TryTranslateFishingSrcSceneId(CUser *pUser, uint16& srcSceneId)
{
	if (pUser == NULL)
		return;
	if (pUser->m_fishSceneSrcId == FISH_ID2)
		srcSceneId = FISH_ID2 + 1;
	else
		srcSceneId = FISH_ID2;
	pUser->m_fishSceneSrcId = srcSceneId;
}

// 是否是在钓鱼房间
bool IsInFishingRoom(int sceneSrcId)
{
	if((sceneSrcId == FISH_ID2) || (sceneSrcId == (FISH_ID2 + 1)))
	{
		return true;
	}
	return false;
}

bool CanJoinActivity (CUser *pUser)
{
	if(pUser == NULL)
		return false;
	uint8 res = pUser->InHuSongMission();
	if(res == 1)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_762,TIPS_FAILURE_COLOR).c_str());
		return false;
	}
	else if(res == 2)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_763,TIPS_FAILURE_COLOR).c_str());
		return false;
	}
	if(pUser->InTreasure())
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_764,TIPS_FAILURE_COLOR).c_str());
		return false;
	}
	return true;
}

void SyncUserScenePos(CUser *pUser,uint16 x,uint16 y,uint8 face)
{
	if(pUser == NULL)
		return;
	CScene *pScene = pUser->GetScene();
	if(pScene == NULL)
		return;
	CNetMessage msg;
	msg.SetType(PRO_SYNC_POS);
	msg<<pUser->GetRoleId()<<x<<y<<face;
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
	pScene->BroadcastMsgExcept(msg,pUser);
}

void TransportUser(CUser *pUser,int sceneId,uint16 x,uint16 y,uint8 face)
{
/*
	if(pUser == NULL)
		return;
	if(pUser->GetFightId() != 0)
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CSceneManager &scene = SingletonSceneManager::instance();

	CScene *pScene = NULL;
	CScene *pOld = pUser->GetScene();
	if(pOld == NULL)
		return;
	int oldSrcSid = pOld->GetSrcSceneId();
	if(oldSrcSid == COPY_ID_SHI_LIAN)	// 试炼，退出副本时覆盖数据
	{
		do
		{
			uint32 role2_Id = pUser->GetExtData32(109);
			if(role2_Id != 0)
			{
				int zhandouli = pUser->GetTotalZhanDouLi();
				CGetDbConnect getDb;
				CDatabaseSql *pDb = getDb.GetDbConnect();
				if(pDb == NULL)
					break;
				char sql[10240];
				char **row = NULL;
				snprintf(sql,sizeof(sql),"select id,zhanDouLi from shilian_robot where id=%u",role2_Id);
				if(!pDb->Query(sql))
					break;
				if((row = pDb->GetRow()) == NULL)
					break;
				int tarZhanDouLi = atoi(row[1]);
				if(tarZhanDouLi >= (int)(zhandouli*0.95) && tarZhanDouLi <= (int)(zhandouli*1.10))
				{
					// 覆盖角色数据
					string pet,title,petKaiJia,mount,bankItem,sg_bitset;
					pUser->GetPet(pet);
					pUser->GetTitleStr(title);
					pUser->GetMount(mount);
					pUser->GetBankItem(bankItem);
					pUser->GetSGBitSet(sg_bitset);
					snprintf(sql,sizeof(sql),"update shilian_robot set sex=%d,xiang=%d,level=%d,pet='%s',title='%s',petKaiJia='%s',"\
						"mount='%s',bank_item='%s',zhanDouLi=%u,petZhanDouLi=%d,sg_bitset='%s' where id=%u",
						(int)pUser->GetSex(),(int)pUser->GetXiang(),(int)pUser->GetLevel(),pet.c_str(),title.c_str(),
						petKaiJia.c_str(),mount.c_str(),bankItem.c_str(),pUser->GetZhanDouLi(),pUser->GetPetZhanDouLi(),sg_bitset.c_str(),role2_Id);
					pDb->Query(sql);
				}
			}
		}while(0);
	}
	else if(oldSrcSid >= FEI_XIAN_SID1 && oldSrcSid <= FEI_XIAN_SID5 && (sceneId < FEI_XIAN_SID1 || sceneId > FEI_XIAN_SID5))
	{
		SetQiPetUp(pUser);
		SetGenSuiPetUp(pUser);
	}
	
	if(sceneId == BANG_PAI_SCENE_ID)
	{
		if(pUser->GetBangPai() == 0)
			return;
		pScene = scene.GetBangPaiScene(sceneId,pUser->GetBangPai());
	}
	else if(pOld->GetGroupId() != 0)
	{
		if(pOld->IsFuBen())
			pScene = scene.Find2Scene(sceneId,pOld->GetGroupId());
		else
			pScene = scene.FindScene(sceneId,pOld->GetGroupId());
	}

	if(pScene == NULL)
	{
		pScene = scene.FindScene(sceneId);
		if(pScene == NULL)
		{
			pScene = scene.FindBangPaiScene(sceneId);
			if(pScene == NULL)
				return;
		}
	}

	uint16 srcSceneId = pScene->GetSrcSceneId();
	if(srcSceneId == FISH_ID2) // 钓鱼场景切换特殊处理
		TryTranslateFishingSrcSceneId(pUser,srcSceneId);

	CNetMessage msg;
	msg.SetType(PRO_JUMP_SCENE);
	msg<<(uint16)srcSceneId<<x<<y<<face<<(uint8)0;
	sock.SendMsg(pUser->GetSock(),msg);
	pUser->SetPos(x,y);
	pUser->SetFace(face);
	if(pUser->GetSceneId() != sceneId)
		pUser->EnterScene(pScene);
*/
}

// 玩家跳转 特殊读条
void TransportUserWithLoadingType ( CUser *pUser, int sceneId, uint16 x, uint16 y, uint8 face, uint8 loadType ) // 特殊读条类型
{
/*
	if(pUser == NULL)
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CSceneManager &scene = SingletonSceneManager::instance();

	CScene *pScene = NULL;
	CScene *pOld = pUser->GetScene();
	if(pOld == NULL)
		return;
	if(sceneId == BANG_PAI_SCENE_ID)
		pScene = scene.GetBangPaiScene(sceneId,pUser->GetBangPai());
	else if(pOld->GetGroupId() != 0)
	{
		if(pOld->IsFuBen())
			pScene = scene.Find2Scene(sceneId,pOld->GetGroupId());
		else
			pScene = scene.FindScene(sceneId,pOld->GetGroupId());
	}

	if(pScene == NULL)
		pScene = scene.FindScene(sceneId);
	if(pScene == NULL)
		return;

	CNetMessage msg;
	msg.SetType(PRO_JUMP_SCENE);
	msg<<(uint16)pScene->GetSrcSceneId()<<x<<y<<face<<(uint8)loadType;
	sock.SendMsg(pUser->GetSock(),msg);
	pUser->SetPos(x,y);
	pUser->SetFace(face);
	if (pUser->GetSceneId() != sceneId)
		pUser->EnterScene(pScene);
*/
}

void UserJumpTo(CUser *pUser,uint16 sceneId,uint16 x,uint16 y,uint8 face)
{
/*
	if (pUser == NULL)
		return;
	pUser->SetFace(face);
	pUser->SetPos(x,y);
	SendUserPos(pUser);
*/
}

bool EnterBangPaiScene(CUser *pUser,int bId)
{
/*
	const int BP_USER_NUM_LIMIT = 65;
	if(pUser == NULL)
		return false;
	if(pUser->InHuSongMission() == 1)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_765,TIPS_FAILURE_COLOR).c_str());
		return false;
	}
	else if(pUser->InHuSongMission() == 2)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_766,TIPS_FAILURE_COLOR).c_str());
		return false;
	}

	CScene *pSrcScene = pUser->GetScene();
	if(pSrcScene == NULL)
		return false;
	int srcSceneId = pSrcScene->GetSrcSceneId();
	if(IsFuBen(srcSceneId))
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_767,TIPS_FAILURE_COLOR).c_str());
		return false;
	}
	CBangPai *pBangPai = SingletonCBangPaiManager::instance().FindBangPai(bId);
	if(pBangPai == NULL)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_768,TIPS_FAILURE_COLOR).c_str());
		return false;
	}
	
	if(srcSceneId != BANG_PAI_SCENE_ID)
		pUser->SaveEnterPos(pSrcScene->GetId(),pUser->GetX(),pUser->GetY());

	CSocketServer &sock = SingletonSocket::instance();
	CSceneManager &scene = SingletonSceneManager::instance();
	CScene *pScene = NULL;
	if(bId == 0)	// 进入本帮
		pScene = scene.GetBangPaiScene(BANG_PAI_SCENE_ID,pUser->GetBangPai());
	else			// 进入其他帮派
		pScene = scene.GetBangPaiScene(BANG_PAI_SCENE_ID,bId);
	if(pScene == NULL)
		return false;
	if(pScene->GetUserNum() >= BP_USER_NUM_LIMIT)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_769,TIPS_FAILURE_COLOR).c_str());
		return false;
	}

	uint16 x=0,y=0;
	CNetMessage msg;
	msg.SetType(PRO_JUMP_SCENE);
	if(pUser->GetBangPai() == (uint32)bId)	// 本帮
	{
		x = 425;
		y = 452;
		pUser->SendBangPaiPlantCnt();
	}
	else	// 非本帮
	{
		x = 1139;
		y = 733;
	}
	uint8 face = 1;
	msg<<BANG_PAI_SCENE_ID<<x<<y<<face<<(uint8)0;
	sock.SendMsg(pUser->GetSock(),msg);

	pUser->SetPos(x,y);
	pUser->SetFace(face);
	pUser->EnterScene(pScene);
	pUser->ClearBangAreaContinuousKillNum();
*/
	return true;
}

bool EnterBPFightReadyScene(CUser *pUser)
{
/*
	if(pUser == NULL || pUser->GetBangPai() == 0)
		return false;
	if(pUser->InHuSongMission() == 1)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_770,TIPS_FAILURE_COLOR).c_str());
		return false;
	}
	else if(pUser->InHuSongMission() == 2)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_771,TIPS_FAILURE_COLOR).c_str());
		return false;
	}
	
	if(!TeamCanEnterBangPaiFightScene(pUser))
		return false;
	CScene *pSrcScene = pUser->GetScene();
	if(pSrcScene == NULL)
		return false;
	int srcSceneId = pSrcScene->GetSrcSceneId();
	if(IsFuBen(srcSceneId))
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_772,TIPS_FAILURE_COLOR).c_str());
		return false;
	}
	CBangPai *pBangPai = SingletonCBangPaiManager::instance().FindBangPai(pUser->GetBangPai());
	if(pBangPai == NULL)
	{
//		SendSysInfo(pUser,MakeStringColor("该帮派已解散",TIPS_FAILURE_COLOR).c_str());
		return false;
	}
	if(srcSceneId != BP_FIGHT_SID && srcSceneId != BP_FIGHT_READY_SID && srcSceneId != KUAFU_BZ_SID && srcSceneId != KUAFU_BZ_READY_SID)
		pUser->SaveEnterPos(pSrcScene->GetId(),pUser->GetX(),pUser->GetY());

	CSocketServer &sock = SingletonSocket::instance();
	CSceneManager &scene = SingletonSceneManager::instance();
#ifndef KUA_FU
	CScene *pScene = scene.GetBangPaiScene(BP_FIGHT_READY_SID,pUser->GetBangPai());
#else
	CScene *pScene = scene.GetBangPaiScene(KUAFU_BZ_READY_SID,pUser->GetBangPai());
#endif
	if(pScene == NULL)
		return false;

	CNetMessage msg;
	msg.SetType(PRO_JUMP_SCENE);
	
	uint16 x=368,y=400;
	uint8 face = 1;
	pScene->GetCanWalkPos(x,y);	
#ifndef KUA_FU
	msg<<BP_FIGHT_READY_SID<<x<<y<<face<<(uint8)0;
#else
	msg<<KUAFU_BZ_READY_SID<<x<<y<<face<<(uint8)0;
#endif
	sock.SendMsg(pUser->GetSock(),msg);
	pUser->SetPos(x,y);
	pUser->SetFace(face);
	pUser->EnterScene(pScene);
*/
	return true;
}

bool EnterBPFightScene(CUser *pUser)
{
/*
	const int MAX_USER_NUM = 150;
	if(pUser == NULL)
		return false;
	int bangId = pUser->GetBangPai();
	if(bangId == 0)
		return false;
	if(pUser->InHuSongMission() == 1)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_773,TIPS_FAILURE_COLOR).c_str());
		return false;
	}
	else if(pUser->InHuSongMission() == 2)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_774,TIPS_FAILURE_COLOR).c_str());
		return false;
	}
	
	if(!TeamCanEnterBangPai(pUser))
		return false;
	CScene *pSrcScene = pUser->GetScene();
	if(pSrcScene == NULL)
		return false;
	int srcSceneId = pSrcScene->GetSrcSceneId();
	if(IsFuBen(srcSceneId))
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_775,TIPS_FAILURE_COLOR).c_str());
		return false;
	}

	CSceneManager &scene = SingletonSceneManager::instance();
#ifndef KUA_FU
	CScene *pFightScene = scene.FindScene(BP_FIGHT_SID);
	if(pFightScene == NULL)
		return false;
	if(pFightScene->GetUserNum() >= MAX_USER_NUM)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_776,TIPS_FAILURE_COLOR).c_str());
		return false;
	}

	CBangPai *pBangPai = SingletonCBangPaiManager::instance().FindBangPai(pUser->GetBangPai());
	if(pBangPai == NULL)
		return false;
//	if(pBangPai->GetBZ_JiFen() == 0)
//		pBangPai->SetBZ_JiFen(100);
	if(!pUser->HaveBitSet(621))
	{
		pUser->SetBitSet(621);
		pUser->SetExtData32(90, 0); // 第一次进帮战 积分归零
		SingletonCBangPaiManager::instance().AddBangPaiJiFen(pUser, 1);
		pBangPai->UpdateHuoYue(pUser,EBHT_JoinBangZhan);
	}
	
	uint16 x=368,y=400;
	GetSafeAreaPos(x,y);
	TransportUser(pUser,BP_FIGHT_SID,x,y,ENTER_FU_BEN_DEFAULT_MAP_FACE);
#else
	int groupId = SingletonCBangPaiManager::instance().GetKuaFuBangZhanGroupIdx(bangId);
	if(groupId <= 0)
		return false;
	CSocketServer &sock = SingletonSocket::instance();
	CScene *pFightScene = scene.GetKuaFuBZScene(groupId);
	if(pFightScene == NULL)
		return false;
	if(pFightScene->GetUserNum() >= MAX_USER_NUM)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_776,TIPS_FAILURE_COLOR).c_str());
		return false;
	}
	int type = GetKuaFuBangZhanType();
	CBangPai *pBangPai = SingletonCBangPaiManager::instance().FindBangPai(pUser->GetBangPai());
	if(pBangPai == NULL)
		return false;
	if(type == 1 && pBangPai->GetBZ_JiFen_KF() == 0)
		pBangPai->SetBZ_JiFen_KF(100);
	else if(type == 2 && pBangPai->GetBZ_JiFen_KF_Final() == 0)
		pBangPai->SetBZ_JiFen_KF_Final(100);

	CNetMessage msg;
	msg.SetType(PRO_JUMP_SCENE);
	uint16 x=368,y=400;
	uint8 face = 1;
	pFightScene->GetCanWalkPos(x,y);
	msg<<KUAFU_BZ_SID<<x<<y<<face<<(uint8)0;
	sock.SendMsg(pUser->GetSock(),msg);
	pUser->SetPos(x,y);
	pUser->SetFace(face);
	pUser->EnterScene(pFightScene);
#endif
*/
	return true;
}

void EnterBPFightSafeArea(CUser *pUser)
{
/*
	uint16 x, y;
	GetSafeAreaPos(x, y);
	pUser->SetPos(x, y);
	SyncUserScenePos(pUser, x, y, 0);
*/
}

void GetSafeAreaPos(uint16& x, uint16& y)
{
/*
	static int safePos[][2] = { { 150, 1290 },{ 3480, 1290 } };
	//static int radius[] = { 380, 490 };
	int lr = Random(0, 1);
	x = safePos[lr][0] + Random(0, 380);
	y = safePos[lr][1] - Random(0, 490);
*/
}

bool CheckSafeAreaPos(uint16 x, uint16 y)
{
/*
	static int lbpos[] = { 150, 890 };
	static int ltpos[] = { 530, 1290 };
	static int rbpos[] = { 3480, 890 };
	static int rtpos[] = { 3860, 1290 };
	if (x >= lbpos[0] && x <= ltpos[0]
		&& y >= lbpos[1] && y <= ltpos[1])
	{
		return true;
	}
	if (x >= rbpos[0] && x <= rtpos[0]
		&& y >= rbpos[1] && y <= rtpos[1])
	{
		return true;
	}
*/
	return false;
}

bool CollectTower(CUser *pUser, int npcId)
{
/*
	if (!CSceneManager::IsInActivityTime(SOT_BangPaiZhan))
	{
		SendSysInfo(pUser, MakeStringColor(LANGUAGE_ZQX_0128, TIPS_FAILURE_COLOR).c_str());
		return false;
	}
	CSceneManager &scene = SingletonSceneManager::instance();
	CScene *pFightScene = scene.FindScene(BP_FIGHT_SID);
	if (pFightScene == NULL)
		return false;

	return pFightScene->CollectTower(pUser, npcId);
*/
	return true;
}

void ClearCollectState(CUser *pUser)
{
/*
	if (pUser->GetCollectIndex() == 0)
		return;
	pUser->SetCollectIndex(0);
	CScene *pScene = pUser->GetScene();
	if (pScene != NULL)
		pScene->UpdateUserInfo(pUser, ESRT_State);
*/
}

int GetEnterBangPaiTime(CUser *pUser)
{
	if(pUser == NULL)
		return 0;
	int bId = pUser->GetBangPai();
	if(bId == 0)
		return 0;

	CBangPaiManager &bangPaiMgr = SingletonCBangPaiManager::instance();
	CBangPai *pBangPai = bangPaiMgr.FindBangPai(bId);
	if(pBangPai == NULL)
		return 0;
	SBangPaiMember data;
	pBangPai->GetMemberInfoById(pUser->GetRoleId(),data);
	if(data.roleId == 0)
		return 0;
	else
		return data.utime;
}

bool CanEnterBangPaiFightScene(CUser *pUser)
{
	if(pUser == NULL)
		return false;
	int bId = pUser->GetBangPai();
	if(bId == 0)
		return false;
	return SingletonCBangPaiManager::instance().IsInBangPaiFightList(bId);
}

bool IsOpenBangPaiFight()
{
	return SingletonCBangPaiManager::instance().IsOpenBangPaiFight();
}

const char *GetMonsterBossName(int bossId)
{
	return SingletonMonsterBossManager::instance().GetMonsterBossName(bossId);
}

const char *GetMonsterName(int id)
{
	return GetMonsterBossName(id);
}

const char *GetPetName(int id)
{
	CPetCfgManager &petMgr = SingletonCPetCfgMgr::instance();
	SPetBasicData *pCfg = petMgr.GetPetCfg(id);
	if(pCfg == NULL)
		return "";
	return pCfg->name.c_str();
}

int GetPetDefaultQuality(int id)
{
	CPetCfgManager &petMgr = SingletonCPetCfgMgr::instance();
	SPetBasicData *pCfg = petMgr.GetPetCfg(id);
	if(pCfg == NULL)
		return 1;
	return pCfg->quality;
}

int AddDefaultNpc(CUser *pUser,int npcId,int scenseId,int x,int y,int timeOut)
{
	return AddNpc(pUser,npcId,(const char*)NULL,scenseId,x,y,timeOut);
}

bool FindNpc(CUser *pUser,int npcId)
{
	if(pUser == NULL)
		return false;
	return pUser->FindNpcScript(npcId) != NULL;
}

bool FindNpcScene(CUser *pUser,int npcId, int sceneId)
{
	CSceneManager &sceneMgr = SingletonSceneManager::instance();
	CScene *pScene = sceneMgr.FindScene(sceneId);
	if (pScene == NULL)
	{
		//cout << "获取地图失败" << endl;
		return false;
	}
	return pScene->FindNpc(npcId) != NULL;
}
bool FindNpcByScene(int npcId, int sceneId)
{
	CSceneManager &sceneMgr = SingletonSceneManager::instance();
	CScene *pScene = sceneMgr.FindScene(sceneId);
	if (pScene == NULL)
	{
		return false;
	}
	return pScene->FindNpc(npcId) != NULL;
}

void DelNpcScene(CUser *pUser,int npcId, int sceneId,int npcIndex)
{
	CSceneManager &sceneMgr = SingletonSceneManager::instance();
	CScene *pScene = sceneMgr.FindScene(sceneId);
	if (pScene == NULL)
	{
		//cout << "获取地图失败" << endl;
		return;
	}
	SNpcInstance* pNpc = pScene->FindNpc(npcId,npcIndex);
	if (pNpc == NULL)
		return;
	pScene->DelDynamicNpc(pNpc);
}

const char *GetUserNpcName(CUser *pUser,int npcId)
{
	if (pUser != NULL)
		return pUser->GetNpcName(npcId);
	return NULL;
}

// taskType 1-9999  对应特定的怪物战斗
int AddMonster(CUser *pUser,int taskType,int pic,const char *name,int sceneId,int x,int y)
{
	if ((pUser == NULL) || (pUser->GetScene() == NULL))
		return -3;
	SVisibleMonster monster;
	if(name != NULL)
		monster.name = name;
	monster.id = taskType;
	monster.sceneId = sceneId;
	monster.x = x;
	monster.y = y;
	monster.pic = pic;

	int res = pUser->AddMonster(monster);
	if (res!= 0)
	{
		cout << "AddMonster ErrorCode:" << res << endl;
		return res;
	}

	if(sceneId == pUser->GetScene()->GetMapId())	//GetId())
	{
		CNetMessage msg;
		msg.SetType(MSG_MONSTER_OPTION);
		int monId = monster.id;
		msg<<(uint8)2<<monster.id<<monster.name<<monId<<monster.pic<<(uint16)0<<monster.x<<monster.y<<monster.face<<(uint8)2;	// boss
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
	}
	return res;
}

void DelMonster(CUser *pUser,int monsterType,int sceneId)
{
	if(pUser == NULL)
		return;
	pUser->DelMonster(monsterType,sceneId);
	if(sceneId == pUser->GetScene()->GetMapId())
	{
		CNetMessage msg;
		msg.SetType(MSG_MONSTER_OPTION);
		msg<<(uint8)3<<monsterType;
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
	}
}

int AddNpc(CUser *pUser,int npcId,const char *name,int sceneId,int x,int y,int timeOut)
{
	if ((pUser == NULL) || (pUser->GetScene() == NULL))
		return -3;
	SNpcInstance npc;
	CNpcManager &npcManager = SingletonNpcManager::instance();
	SNpcTemplate *pNpc = npcManager.GetNpcTemplate(npcId);
	if (pNpc == NULL)
		return -4;
	npc.pNpc = new SNpcTemplate;
	*(npc.pNpc) = *pNpc;

	if (name != NULL)
		npc.pNpc->name = name;
	if (npc.pNpc == NULL)
		return -5;

	npc.id = npcId;
	npc.templateId  = npcId;
	npc.x = x;
	npc.y = y;
	if (timeOut != 0)
		npc.timeOut = timeOut*60+GetSysTime();

	npc.sceneId = sceneId;
	int res = pUser->AddNpc(sceneId,npc);
	if (res!= 0)
	{
		cout << "AddNpcErrorCode:" << res << endl;
		return res;
	}

	if (sceneId == pUser->GetScene()->GetMapId())//GetId())
	{
		CNetMessage msg;
		msg.SetType(PRO_ADD_NPC);
		npc.MakeNpcInfo(msg);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
	}
	return npc.id;
}

int AddNpcDirect(CUser* pUser, int npcId, int sceneId, int x, int y, int direct,int index)
{
	if ((pUser == NULL) || (pUser->GetScene() == NULL))
		return -3;
	SNpcInstance npc;
	CNpcManager &npcManager = SingletonNpcManager::instance();
	SNpcTemplate *pNpc = npcManager.GetNpcTemplate(npcId);
	if (pNpc == NULL)
		return -4;
	npc.pNpc = new SNpcTemplate;
	*(npc.pNpc) = *pNpc;

	if (npc.pNpc == NULL)
		return -5;

	npc.id = npcId;
	npc.templateId  = npcId;
	npc.x = x;
	npc.y = y;
	npc.direct = direct;
	npc.index = index;

	npc.sceneId = sceneId;
	int res = pUser->AddNpc(sceneId,npc);
	if (res!= 0)
	{
		cout << "AddNpcErrorCode:" << res << endl;
		return res;
	}

	if (sceneId == pUser->GetScene()->GetSrcSceneId())//GetId())
	{
		CNetMessage msg;
		msg.SetType(PRO_ADD_NPC);
		npc.MakeNpcInfo(msg);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
	}
	return npc.id;
}

int AddNpcWithInfo(CUser *pUser,int npcId,int sceneId,int x,int y,int type,int pic,const char *name, int color/* = 0*/)
{
	if((pUser == NULL) || (pUser->GetScene() == NULL))
		return -1;
	SNpcInstance npc;
	CNpcManager &npcManager = SingletonNpcManager::instance();
	SNpcTemplate *pNpc = npcManager.GetNpcTemplate(npcId);
	if(pNpc == NULL)
		return -1;
	
	npc.pNpc = new SNpcTemplate;
	*(npc.pNpc) = *pNpc;
	if(npc.pNpc == NULL)
		return -1;

	npc.id = npcId;
	npc.templateId  = npcId;
	npc.x = x;
	npc.y = y;
	npc.direct = 0;
	npc.type = type;
	npc.pic = pic;
	npc.name = name;
	npc.sceneId = sceneId;
	if (color != 0)
	{
		npc.nameColor = color;
	}
	int res = pUser->AddNpc(sceneId,npc);
	if (res!= 0)
	{
		cout << "AddNpcErrorCode:" << res << endl;
		return res;
	}

	if(sceneId == pUser->GetScene()->GetSrcSceneId())
	{
		CNetMessage msg;
		msg.SetType(PRO_ADD_NPC);
		npc.MakeNpcInfo(msg);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
	}
	return npc.id;
}


void AddNpcScene(CUser *pUser,int npcId,const char *name,int sceneId,int posX,int posY)
{
	CSceneManager &sceneMgr = SingletonSceneManager::instance();
	CScene *pScene = sceneMgr.FindScene(sceneId);
	if (pScene == NULL)
	{
		//cout << "获取地图失败" << endl;
		return;
	}
	if ((posX != -1) && (posY != -1))
		pScene->AddNpc(npcId, posX, posY, 8);
	else
	{
		uint16 x,y;
		pScene->GetCanWalkPos(x,y);

		pScene->AddNpc(npcId, x, y, 8);
	}
	//cout << "添加npc:" << pScene->GetName() <<"mapId:"<<sceneId << "  " << (int)x << ","<< (int)y<<endl;
	//AddNpc(pUser, npcId, name, sceneId, x, y);
}

int GetNpcSceneId(int npcId)
{
	CNpcManager &npcManager = SingletonNpcManager::instance();
	SNpcInstance *pNpc = npcManager.GetNpcInstance(npcId);
	if (pNpc != NULL)
		return pNpc->sceneId;
	return 0;
}

SNpcPos GetNpcTmplPos(int tmplId)
{
	SNpcPos pos = {0};
	CNpcManager &npcManager = SingletonNpcManager::instance();
	SNpcInstance *pNpc = npcManager.GetNpcInstanceByTmplId(tmplId);
	if(pNpc == NULL)
		return pos;
	pos.sceneId = pNpc->sceneId;
	pos.x = pNpc->x;
	pos.y = pNpc->y;
	return pos;
}

SNpcPos GetNpcScenePos(int npcId)
{
	SNpcPos pos = {0};
	CNpcManager &npcManager = SingletonNpcManager::instance();
	SNpcInstance *pNpc = npcManager.GetNpcInstance(npcId);
	if (pNpc == NULL)
		return pos;
	pos.sceneId = pNpc->sceneId;
	pos.x = pNpc->x;
	pos.y = pNpc->y;
	return pos;
}

//得到可过点
SNpcPos GetCanWalkPos(int sceneId)
{
	SNpcPos pos = {0};
	CSceneManager &scene = SingletonSceneManager::instance();
	CScene *pScene = scene.FindScene(sceneId);
	if (pScene == NULL)
		return pos;
	uint16 x = 0,y = 0;
	if (pScene->GetCanWalkPos(x,y))
	{
		pos.sceneId = sceneId;
		pos.x = x;
		pos.y = y;
	}
	return pos;
}

const char *GetNpcName(int npcId)
{
	CNpcManager &npcManager = SingletonNpcManager::instance();
	SNpcInstance *pNpc = npcManager.GetNpcInstance(npcId);
	if (pNpc != NULL)
		return pNpc->pNpc->name.c_str();
	return "";
}

const char *GetNpcTmplName(int tmplId)
{
	CNpcManager &npcManager = SingletonNpcManager::instance();
	SNpcTemplate *pTmpl = npcManager.GetNpcTemplate(tmplId);
	if(pTmpl != NULL)
		return pTmpl->name.c_str();
	return NULL;
}

const char *GetDiaNameByIndex(CUser *pUser,int npcId,int index)
{
	if(pUser == NULL)
		return NULL;
	CScene *pScene = pUser->GetScene();
	if(pScene == NULL)
		return "";
	return pScene->GetDynamicNpcName(npcId,index);
}

uint8 GetNpcPicType(int npcId)
{
	CNpcManager &npcManager = SingletonNpcManager::instance();
	SNpcTemplate *pTmpl = npcManager.GetNpcTemplate(npcId);
	if(pTmpl != NULL)
		return pTmpl->type;
	return 0;
}

uint16 GetNpcPicId(int npcId)
{
	CNpcManager &npcManager = SingletonNpcManager::instance();
	SNpcTemplate *pTmpl = npcManager.GetNpcTemplate(npcId);
	if(pTmpl != NULL)
		return pTmpl->pic;
	return 0;
}

void DelNpc(CUser *pUser,int npcId,int index)
{
	if((pUser == NULL) || (pUser->GetScene() == NULL))
		return;

	SNpcInstance npc;
	if(pUser->DelNpc(npcId,npc,index) == pUser->GetScene()->GetSrcSceneId())
	{
		CNetMessage msg;
		msg.SetType(PRO_DEL_NPC);
		msg<<npc.id<<npc.index;
		delete npc.pNpc;
		delete npc.pHumanData;
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		//cout<<"del npc:"<<npcId<<endl;
	}
}

void DelNpcScript(CUser *pUser,int npcId,int index)
{
	DelNpc(pUser,npcId,index);
}

void DelAllNpc(CUser *pUser, int npcId, int index/* = 0*/)
{
	if ((pUser == NULL) || (pUser->GetScene() == NULL))
		return;
	uint16 sceneId = 0;
	do
	{
		SNpcInstance npc;
		sceneId = pUser->DelNpc(npcId, npc, index);
		if (sceneId == pUser->GetScene()->GetSrcSceneId())
		{
			CNetMessage msg;
			msg.SetType(PRO_DEL_NPC);
			msg << npc.id << npc.index;
			delete npc.pNpc;
			delete npc.pHumanData;
			SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);
		}
	} while (sceneId != 0);
}

bool FindDynamicNpcWithIndex(CUser *pUser,int npcId,int npcIdx)
{
	if(pUser == NULL || pUser->GetScene() == NULL)
		return false;
	if(pUser->GetScene()->FindNpc(npcId,npcIdx) != NULL)
		return true;
	else
		return false;
}

void DelDynamicNpcWithIndex(CUser *pUser,int npcId,int npcIdx)
{
	if ((pUser == NULL) || (pUser->GetScene() == NULL))
		return;
	pUser->GetScene()->DelDynamicNpcWithIndex(npcId,npcIdx);
}

void ShiMenFight(CUser *pUser)
{
	if ((pUser != NULL) && (pUser->GetScene() != NULL))
	{
		pUser->GetScene()->ShiMenFight(pUser);
	}
}

int GetTeamMemNum(CUser *pUser)
{
	if(pUser == NULL)
		return 0;
	uint32 teamId = pUser->GetTeam();
	if(teamId == 0)
		return 1;
	ShareUserPtr pHead = SingletonOnlineUser::instance().GetUserByRoleId(teamId);
	if(pHead.get() == NULL)
		return 0;
	CScene *pScene = pHead->GetScene();
	if(pScene == NULL)
		return 0;
	return pScene->GetTeamMemNum(teamId);
}

int GetTeamAllMemNum(CUser *pUser)
{
	if(pUser == NULL)
		return 0;
	uint32 teamId = pUser->GetTeam();
	if(teamId == 0)
		teamId = pUser->TempLeaveTeam();
	if(teamId == 0)
		return 0;
	ShareUserPtr pHead = SingletonOnlineUser::instance().GetUserByRoleId(teamId);
	if(pHead.get() == NULL)
		return 0;
	CScene *pScene = pHead->GetScene();
	if(pScene == NULL)
		return 0;
	int num = pScene->GetTeamAllMemNum(teamId);
	return num;
}

CUser *GetTeamLeader(CUser *pUser)
{
	if (pUser == NULL)
		return NULL;
	if (pUser->GetTeam() == 0)
		return NULL;
	if (pUser->GetTeam() == pUser->GetRoleId())
		return pUser;
	ShareUserPtr ptr = SingletonOnlineUser::instance().GetUserByRoleId(pUser->GetTeam());
	return ptr.get();
}

CUser *GetTeamMember(CUser *pUser,int idx)
{
	if (pUser == NULL)
		return NULL;
	CScene *pScene = pUser->GetScene();
	if (pScene == NULL)
		return NULL;
	if (pUser->GetTeam() == 0)
		return NULL;
	if (pUser->GetTeam() != pUser->GetRoleId())
		return NULL;
	return pScene->GetTeamMember(pUser->GetTeam(),idx);
}

const char *GetSceneName(int id)
{
	CSceneManager &scene = SingletonSceneManager::instance();
	CScene *pScene = scene.FindScene(id);
	if (pScene == NULL)
		return NULL;

	return pScene->GetName();
}

int GetSceneUserNum(int id)
{
	CSceneManager &scene = SingletonSceneManager::instance();
	CScene *pScene = scene.FindScene(id);
	if (pScene == NULL)
		return 0;

	return pScene->GetUserNum();
}

void ShiLianNoticeToExit(CUser *pUser,int second)
{
	if(pUser == NULL)
		return;
	CNetMessage msg;
	msg.SetType(MSG_SHI_LIAN);
	msg<<(uint8)2<<(uint16)second;
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void EnterFeiXianScene(CUser *pUser,int floor)
{
	if(pUser == NULL || floor <= 0 || floor > 5)
		return;
	if(pUser->GetRobot() > 0)
		return;
	int sid = pUser->GetSrcSceneId();
	if(sid < FEI_XIAN_SID1 || sid > FEI_XIAN_SID5)
		pUser->SaveEnterPos(pUser->GetSceneId(),pUser->GetX(),pUser->GetY());

	pUser->SetExtData8(138,0);
	pUser->SetExtData8(139,0);

	int nextSid = FEI_XIAN_SID1-1+floor;
	CScene *pNextScene = SingletonSceneManager::instance().FindScene(nextSid);
	uint16 x=368,y=400;
	pNextScene->GetCanWalkPos(x,y);
	TransportUser(pUser,pNextScene->GetSrcSceneId(),x,y,ENTER_FU_BEN_DEFAULT_MAP_FACE);
	pUser->UpdateFeiXianData();

	CScene *pScene = pUser->GetScene();
	if(pScene == NULL || (pScene->GetSrcSceneId() < FEI_XIAN_SID1 || pScene->GetSrcSceneId() > FEI_XIAN_SID4))
		return;
	int userNum = pScene->GetUserNum() + (int)pScene->GetVisibleRobotNum();
	const int MAX_ADD_ROBOT_USER_NUM = 50;
	if(userNum < MAX_ADD_ROBOT_USER_NUM)
		pScene->AddVisibleRobot(pUser);
	else if(userNum > MAX_ADD_ROBOT_USER_NUM)
		pScene->RemoveVisibleRobot(userNum-MAX_ADD_ROBOT_USER_NUM);
}

// 英勇试炼副本
void EnterShiLianFuBen(CUser *pUser)
{
//	const int boxPos[][2] = {{729,413},{990,403},{1195,475},{1222,622},{1074,727}};
	if(pUser == NULL)
		return;
	CScene *pScene = SingletonSceneManager::instance().GetShiLianFuBen();
	if(pScene == NULL)
		return;
	bool needRefresh = false;
	if(pScene != NULL)
	{
		pScene->SetState(0);
		uint8 floor = pUser->GetExtData8(136);
		uint8 openBox = pUser->GetExtData8(137);
		if(floor <= 15)
		{
			if(floor == 15 && openBox == floor)
				return;
//			uint16 npcId = Random(181,183);
//			uint16 pic = npcId-181+71;
//			char name[128];
			if(floor == openBox)	// 刷怪
			{
				needRefresh = true;
			}
			else	// 刷宝箱
			{
				pUser->SendShiLianGetAwardPanel();
			}
		}
		else
		{
			return;
		}
		pUser->SaveEnterPos(pUser->GetSceneId(),pUser->GetX(),pUser->GetY());
		if(pUser->GetExtData32(111) == 0)		// 前一天最高战斗力
			pUser->SetExtData32(111,pUser->GetExtData32(110));

		TransportUser(pUser, pScene->GetId(), 811, 654, ENTER_FU_BEN_DEFAULT_MAP_FACE);
		if (needRefresh)
			pUser->MatchYingYongRobot(floor + 1);
	}
}

// 强化副本
void EnterQiangHuaFuBen(CUser *pUser)
{
	if (pUser == NULL)
		return;

	//pUser->CheckMissionHuoYueDu();
	CSceneManager &scene = SingletonSceneManager::instance();
	CScene *pScene = scene.GetQiangHuaFuBen();
	if (pScene == NULL)
		return;
	if (pScene != NULL)
	{
		pScene->AddQiangHuaMonsterBoss();
		pScene->SetState(0);
		TransportUser(pUser,pScene->GetId(),pScene->GetX(),pScene->GetY(),ENTER_FU_BEN_DEFAULT_MAP_FACE);
	}
}

// 神将副本
void EnterChongWuFuBen(CUser *pUser,int difficulty)
{
	if(pUser == NULL)
		return;

	CSceneManager &scene = SingletonSceneManager::instance();
	CScene *pScene = scene.GetChongWuFuBen(difficulty);
	if(pScene == NULL)
		return;
	if(pScene != NULL)
	{
		pScene->AddPetCopyMonsterBoss(pUser->GetLevel());
		pScene->SetState(0);
		pScene->SetPetCopyDifficulty(difficulty);
		pUser->ClearFuBenData();
		TransportUser(pUser,pScene->GetId(),pScene->GetX(),pScene->GetY(),ENTER_FU_BEN_DEFAULT_MAP_FACE);
	}
}

// 金币副本
void EnterJinBiFuBen(CUser *pUser)
{
	if (pUser == NULL)
		return;

	CSceneManager &scene = SingletonSceneManager::instance();
	CScene *pScene = scene.GetJinBiFuBen();
	if (pScene == NULL)
		return;
	if (pScene != NULL)
	{
		pScene->SetState(0);
		TransportUser(pUser,pScene->GetId(),pScene->GetX(),pScene->GetY(),ENTER_FU_BEN_DEFAULT_MAP_FACE);
	}
}

// 道具副本
void EnterShengJieFuBen(CUser *pUser)
{
	if (pUser == NULL)
		return;

	CSceneManager &scene = SingletonSceneManager::instance();
	CScene *pScene = scene.GetDaoJuFuBen();
	if (pScene == NULL)
		return;
	if (pScene != NULL)
	{
		pScene->AddShengJieMonsterBoss(pUser->GetLevel());
		pScene->SetState(0);
		TransportUser(pUser,pScene->GetId(),pScene->GetX(),pScene->GetY(),ENTER_FU_BEN_DEFAULT_MAP_FACE);
	}
}

// 镶嵌副本
void EnterXiangQianFuBen(CUser *pUser)
{
	if(pUser == NULL)
		return;
	CSceneManager &scene = SingletonSceneManager::instance();
	CScene *pScene = scene.GetXiangQianFuBen();
	if(pScene == NULL)
		return;
	if(pScene != NULL)
	{
		pScene->SetState(0);
		TransportUser(pUser,pScene->GetId(),pScene->GetX(),pScene->GetY(),ENTER_FU_BEN_DEFAULT_MAP_FACE);
	}
}

// 洗炼副本
void EnterXiLianFuBen(CUser *pUser)
{
	if(pUser == NULL)
		return;
	CSceneManager &scene = SingletonSceneManager::instance();
	CScene *pScene = scene.GetXiLianFuBen();
	if(pScene == NULL)
		return;
	if(pScene != NULL)
	{
		pScene->AddXiLianMonsterBoss();
		pScene->SetState(0);
		TransportUser(pUser,pScene->GetId(),pScene->GetX(),pScene->GetY(),ENTER_FU_BEN_DEFAULT_MAP_FACE);
	}
}

// 潜能副本
void EnterQianNengFuBen(CUser *pUser)
{
	if (pUser == NULL)
		return;

	CSceneManager &scene = SingletonSceneManager::instance();
	CScene *pScene = scene.GetQianNengFuBen();
	if (pScene == NULL)
		return;
	if (pScene != NULL)
	{
		pScene->SetState(0);
		TransportUser(pUser,pScene->GetId(),pScene->GetX(),pScene->GetY(),ENTER_FU_BEN_DEFAULT_MAP_FACE);
	}
}

// 神将铠副本
void EnterChongKaiFuBen(CUser *pUser)
{
	if(pUser == NULL)
		return;

	CSceneManager &scene = SingletonSceneManager::instance();
	CScene *pScene = scene.GetChongKaiFuBen();
	if (pScene == NULL)
		return;
	if (pScene != NULL)
	{
		pScene->AddChongKaiMonsterBoss();
		pScene->SetState(0);
		TransportUser(pUser,pScene->GetId(),pScene->GetX(),pScene->GetY(),ENTER_FU_BEN_DEFAULT_MAP_FACE);
	}
}

// state 0无任务 1可接 2已接未完成 3完成
void UpdateNpcState(CUser *pUser,int npcId,int state)
{
	if (pUser == NULL)
		return;
	CNetMessage msg;
	msg.SetType(PRO_UPDATE_NPC);
	msg<<(uint8)2<<(uint16)npcId<<(uint16)0<<(uint8)state;
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void UpdateNpcHeadState(CUser *pUser,int npcId,int npcIndex,int headState)
{
	// headState(位变量): 1已击杀 
	if (pUser == NULL)
		return;
	CNetMessage msg;
	msg.SetType(PRO_UPDATE_NPC);
	msg<<(uint8)3<<(uint16)npcId<<(uint16)npcIndex<<(uint8)headState;
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

int CreateBangPai(CUser *pUser,const char *name,const char *gonggao,int pic,uint16 limitLv)
{
	if(pUser == NULL || name == NULL || gonggao == NULL)
		return -1;	// 异常
	if(strlen(name) <= 2)
		return 1;	// 名字长度不足
	if(pUser->GetTongBao() < CREATE_BANGPAI_YB)
		return 2;	// 元宝不足
	string bpGongGao = SQLFilter(gonggao);

	CBangPaiManager &bangPaiMgr = SingletonCBangPaiManager::instance();
	CBangPai *pBangPai = bangPaiMgr.CreateBangPai(pUser,name,pic,limitLv);
	if(pBangPai != NULL)
	{
		pUser->SetBangPai(pBangPai->GetId(),EBRBangZhu,pBangPai->GetName().c_str());
	}
	else
	{
		return 4;	// 帮派名已存在
	}
	pBangPai->SetGongGao(bpGongGao.c_str());
	
	pUser->AddTongBao(-CREATE_BANGPAI_YB);
	ItemCurrencyLog(pUser->GetRoleId(),0,0,0,CREATE_BANGPAI_YB,pUser->GetTongBao(),YBL_CREATE_BANGPAI);
	pUser->UpdateBangPai();
	pUser->SetBangPaiShow();
	return 0;
}

void InputStr(CUser *pUser,const char *pMsg)
{
	if ((pUser == NULL) && (pMsg == NULL))
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_INTERACT);

	msg<<(uint8)9<<pMsg;
	sock.SendMsg(pUser->GetSock(),msg);
}

void Input2Str( CUser *pUser, const char *pMsg)
{
	if ((pUser == NULL) && (pMsg == NULL))
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_INTERACT);

	msg<<(uint8)32<<pMsg;
	sock.SendMsg(pUser->GetSock(),msg);
}

void Input3Str(CUser *pUser,const char *pMsg)
{
	if ((pUser == NULL) && (pMsg == NULL))
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_INTERACT);

	msg<<(uint8)47<<pMsg;
	sock.SendMsg(pUser->GetSock(),msg);
}
/*
TYPE=18 选择属性
+-----+
| IND |
+-----+
|  1  |
+-----+
物品在背包中的索引
*/
void SelectAttr(CUser *pUser,uint8 pos)
{
	if (pUser == NULL)
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_INTERACT);

	msg<<(uint8)18<<pos;
	sock.SendMsg(pUser->GetSock(),msg);
}

SNpcPos GetNpcPos(CUser *pUser)
{
	SNpcPos pos = {0};
	if (pUser == NULL)
		return pos;
	//id,等级,三个坐标(需要除16)
	const uint16 NPC_POS[] = {
		3,10,288,64,400,80,320,192
		,54,10,192,144,368,176,432,208
		,41,15,144,240,320,240,48,288
		,45,15,80,80,272,112,48,176
		,51,15,384,48,240,112,144,224
		,88,15,80,176,352,256,128,352
		,94,15,80,80,400,96,384,432
		,124,15,320,112,368,224,176,384
		,55,20,192,96,336,224,208,368
		,72,20,32,144,64,336,384,336
		,87,20,144,96,352,176,192,352
		,90,20,160,128,384,64,112,336
		,123,20,336,64,96,352,400,400
		,125,20,160,80,80,368,336,384
		,56,25,192,64,336,112,80,416
		,71,25,208,256,416,240,32,384
		,86,25,64,80,320,224,256,384
		,91,25,288,80,64,208,224,400
		,113,25,336,80,48,144,400,384
		,126,25,352,96,128,320,288,384
		,57,30,176,96,304,304,96,384
		,69,30,128,112,352,160,96,336
		,85,30,160,144,320,208,368,400
		,89,30,352,96,240,144,144,336
		,92,30,208,144,400,192,272,368
		,112,30,416,144,144,224,304,416
		,58,35,320,160,96,208,400,352
		,59,35,224,48,80,256,320,336
		,67,35,48,102,272,256,320,400
		,82,35,96,80,192,208,352,320
		,84,35,96,176,48,320,400,208
		,111,35,80,112,336,192,208,320
		,157,35,80,80,288,256,224,384
		,49,40,96,64,320,128,160,256
		,61,40,96,208,384,272,176,336
		,68,40,256,208,112,256,336,432
		,83,40,128,80,384,208,192,304
		,96,40,128,112,384,176,208,304
		,114,40,80,96,368,128,96,320
		,46,45,208,176,384,80,320,288
		,52,45,96,80,400,224,192,368
		,81,45,128,144,400,144,48,272
		,93,45,160,112,400,160,144,384
		,95,45,160,128,384,304,192,320
		,122,45,80,96,352,160,240,384
		,151,45,48,112,352,96,400,368
		,50,50,224,96,160,256,288,320
		,53,50,96,128,288,160,416,96
		,97,50,224,128,320,208,160,368
		,121,50,144,112,272,192,96,400
		,152,50,64,80,288,192,384,400
		,42,55,144,80,336,288,64,256
		,43,55,128,64,240,256,80,400
		,98,55,208,80,368,256,240,304
		,115,55,160,112,96,240,224,352
		,153,55,352,176,64,256,400,416
		,44,60,96,96,432,80,384,224
		,48,60,144,112,304,160,224,268
		,99,60,80,144,288,176,192,336
		,116,60,128,128,176,384,384,320
		,154,60,64,176,256,240,64,416
		,60,65,80,96,384,144,176,256
		,63,65,128,112,288,240,64,320
		,70,65,64,224,400,96,240,368
		,100,65,304,112,96,336,288,384
		,117,65,112,112,192,288,352,352
		,155,65,208,80,272,240,96,384
		,65,70,128,128,368,256,128,416
		,66,70,144,112,352,192,256,416
		,101,70,144,96,176,368,384,352
		,118,70,144,80,336,192,176,416
		,156,70,224,224,96,400,416,432
		,47,75,288,96,160,176,304,336
		,64,75,176,96,208,288,384,400
		,102,75,64,224,325,160,256,304
		,119,75,192,128,64,304,352,352
		,62,80,240,160,64,320,208,416
		,103,80,32,112,240,144,272,400
		,120,80,176,64,304,224,160,416
		,127,80,352,80,288,288,48,336
		,131,85,96,128,304,144,128,320
		,132,85,96,112,336,80,48,384
		,133,85,48,144,288,224,176,352
		,134,85,80,112,416,192,320,400
		,135,90,48,128,128,352,320,384
		,136,90,48,112,272,240,48,288
		,137,90,32,176,288,304,160,432
		,138,95,144,160,288,320,160,352
		,139,95,224,96,272,256,192,384
		,140,95,96,160,432,240,192,352
		,141,95,160,208,80,272,384,400
		,142,100,64,144,400,144,224,304
	};
	int num = sizeof(NPC_POS)/sizeof(uint16)/8;
	uint8 level = pUser->GetLevel();
	level = ((level/5)+1)*5;
	int maxPos = 0;
	for (int i = num-1; i >= 0; i--)
	{
		if (NPC_POS[8*i+1] == level)
		{
			maxPos = i;
			break;
		}
	}
	int randPos = Random(0,maxPos);
	pos.sceneId = NPC_POS[8*randPos];
	int xyPos = Random(0,2);
	pos.x = NPC_POS[8*randPos+2+2*xyPos]/16;
	pos.y = NPC_POS[8*randPos+2+2*xyPos+1]/16;
	return pos;
}

void DoItem(CUser *pUser,int stype)
{
	if (pUser == NULL)
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_INTERACT);
	msg<<(uint8)14<<(uint8)stype;
	sock.SendMsg(pUser->GetSock(),msg);
}

static bool sHuoDong = false;
static int sHuoDongBeiLv = 1;

void SetHuoDong(bool flag)
{
	sHuoDong = flag;
}
void SetHuoDongBeiLv(int beilv)
{
	if (beilv > 0)
		sHuoDongBeiLv = beilv;
	else
		sHuoDongBeiLv = 1;
}
bool InHuoDong()
{
	return sHuoDong;
}
int GetHuoDongBeiLv()
{
	return sHuoDongBeiLv;
}

void DuiHuanBG(CUser *pUser,char *info)
{
	if ((pUser == NULL) || (info == NULL))
		return;
	string str = info;
	char *split[90];
	int num = SplitLine(split,90,(char*)str.c_str());
	if (num % 3 != 0)
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_INTERACT);
	msg<<(uint8)21;
	msg<<pUser->GetData32(5)<<(uint8)(num/3);
	for (int i = 0; i < num; i += 3)
	{
		msg<<(uint8)atoi(split[i])<<(uint16)atoi(split[i+1])<<atoi(split[i+2]);
	}
	sock.SendMsg(pUser->GetSock(),msg);
}

void DonateBang(CUser *pUser)
{
	if (pUser == NULL)
		return;
	CBangPaiManager &bPMgr = SingletonCBangPaiManager::instance();
	CBangPai *pBangPai = bPMgr.FindBangPai(pUser->GetBangPai());
	if (pBangPai == NULL)
		return;

	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_INTERACT);
	msg<<(uint8)22;

	int money = sMaxMoney[4];
	if ((pBangPai->GetLevel() >= 1) && (pBangPai->GetLevel() <= 5))
		money = sMaxMoney[pBangPai->GetLevel()-1];
	msg<<pBangPai->GetMoney()<<money;
	sock.SendMsg(pUser->GetSock(),msg);
}

// <0没有重奖，0重奖已领过，>0重奖物品
SUserAward GetAward(CUser *pUser)
{
	SUserAward aw;
	aw.id = -1;
	aw.num = 0;
	if (pUser == NULL)
	{
		return aw;
	}
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char sql[128];
	snprintf(sql,sizeof(sql),"select item_id,state,num from user_award where role_id=%d",
			 pUser->GetRoleId());

	char **row;
	if ((pDb != NULL) && (pDb->Query(sql)))
	{
		while ((row = pDb->GetRow()) != NULL)
		{
			if (atoi(row[1]) == 0)
			{
				aw.id = atoi(row[0]);
				aw.num = atoi(row[2]);
				return aw;
			}
			else
			{
				aw.id = 0;
			}
		}
	}
	return aw;
}

//设置玩家已经领取奖励
void SetGetAword(CUser *pUser)
{
	if (pUser == NULL)
		return;
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char sql[128];
	snprintf(sql,sizeof(sql),"update user_award set get_time=FROM_UNIXTIME(%lu),state=1 where role_id=%d and state!=1 limit 1",
			 GetSysTime(),pUser->GetRoleId());

	if (pDb != NULL)
	{
		pDb->Query(sql);
	}
}

int GetSecond()
{
	return GetSysSecond();
}

int GetMinute()
{
	return GetSysMinute();
}

int GetHour()
{
	return GetSysHour();
}

int GetYDay()
{
	return GetSysYDay();
}

int GetWeekDay()
{
	return GetSysWDay();
}

int GetDay()
{
	return GetSysMDay();
}

int GetMonth()
{
	return GetSysMonth();
}

int GetYear()
{
	return GetSysYear();
}

int GetMonthDayNum()
{
	int day[12] = {31,28,31,30,31,30,31,31,30,31,30,31};
	int month = GetMonth();
	int year = GetYear() + 1900;
	if(month != 1)
	{
		return day[month];
	}
	else
	{
		if((year%4 == 0 && year%100 != 0) || (year % 400 == 0))
			return 29;
		else
			return 28;
	}
}

void EnterFuBen(CUser *pUser,int mapId,int x,int y,int face)
{
	if (pUser == NULL)
		return;
	CSceneManager &scene = SingletonSceneManager::instance();
	CScene *pScene = scene.GetFuBen(mapId);
	if (pScene != NULL)
	{
		TransportUser(pUser,pScene->GetId(),x,y,face);
	}
}

char *GetPaiMing()
{
	CSceneManager &scene = SingletonSceneManager::instance();
	CScene *pScene = scene.FindScene(LEI_TAI_ID2);
	if (pScene == NULL)
		return NULL;
	return pScene->GetMatchPaiMing();
}

//根据帮派id,得到帮派繁荣度
int GetBangPros(CUser *pUser,int bid)
{
	if (pUser == NULL)
		return 0;
	CBangPaiManager &bPMgr = SingletonCBangPaiManager::instance();
	CBangPai *pBangPai = bPMgr.FindBangPai(bid);
	if (pBangPai != NULL)
	{
		return pBangPai->GetFanRong();
	}
	return 0;
}

string GetRoleBangPaiName(uint32 roleId)
{
	string name = "";
	int bangpaiId = 0;
	ShareUserPtr ptr = SingletonOnlineUser::instance().GetUserByRoleId(roleId);
	if(ptr.get() == NULL)
	{
		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		if(pDb == NULL)
			return name;
		char sql[128];
		snprintf(sql,sizeof(sql),"select bangpai_id from bang_pai_role where role_id=%u",roleId);
		if(!pDb->Query(sql))
			return name;
		char **row = NULL;
		if((row = pDb->GetRow()) != NULL)
			bangpaiId = atoi(row[0]);
		else
			return name;
	}
	else
	{
		bangpaiId = ptr->GetBangPai();
	}

	CBangPai *pBangPai = SingletonCBangPaiManager::instance().FindBangPai(bangpaiId);
	if(pBangPai == NULL)
		return name;
	return pBangPai->GetName();
}

const char *GetBangName(int id)
{
	CBangPaiManager &bPMgr = SingletonCBangPaiManager::instance();
	CBangPai *pBangPai = bPMgr.FindBangPai(id);
	if (pBangPai == NULL)
		return NULL;
	return pBangPai->GetName().c_str();
}

//获得所在帮派场景id
int GetSceneBang(CUser *pUser)
{
	if (pUser == NULL)
		return 0;
	CScene *pScene = pUser->GetScene();
	if (pScene == NULL)
		return 0;
	return pScene->GetId()>>16;
}

int GetBangMoney(CUser *pUser)
{
	CBangPaiManager &bPMgr = SingletonCBangPaiManager::instance();
	CBangPai *pBangPai = bPMgr.FindBangPai(pUser->GetBangPai());
	if (pBangPai == NULL)
		return 0;
	return pBangPai->GetMoney();
}
void AddBangMoney(CUser *pUser,int money)
{
	CBangPaiManager &bPMgr = SingletonCBangPaiManager::instance();
	CBangPai *pBangPai = bPMgr.FindBangPai(pUser->GetBangPai());
	if (pBangPai == NULL)
		return;
	pBangPai->SetMoney(pBangPai->GetMoney() + money);
	if ((pBangPai->GetLevel() >= 1) && (pBangPai->GetLevel() <= 5)
			&& (pBangPai->GetMoney() > sMaxMoney[pBangPai->GetLevel()-1]))
	{
		pBangPai->SetMoney(sMaxMoney[pBangPai->GetLevel()-1]);
	}
}

const char *GetQuestion(CUser *pUser/* = NULL*/)
{
	static vector<string> questionList;
	if (questionList.size() == 0)
	{
		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		if (pDb != NULL)
		{
			if (pDb->Query("select question,answer1,answer2,answer3,answer4 from question"))
			{
				char **row;
				char buf[256];
				while ((row = pDb->GetRow()) != NULL)
				{
					snprintf(buf,sizeof(buf),"%s|%s|%s|%s|%s",row[0],row[1],row[2],row[3],row[4]);
					questionList.push_back(buf);
				}
			}
		}
	}
	if (questionList.size() > 0)
	{
		if (pUser == NULL)
		{
			// 用于初始化
			int r = Random(0, questionList.size() - 1);
			return questionList[r].c_str();
		}
		int r = pUser->GetQuestionId(questionList.size()-1);
		if (r == -1)
			return NULL;
		return questionList[r].c_str();
	}
	return NULL;
}

//返回"鉴定书1|鉴定书2|鉴定书3"
char *IdentifyBook(CUser *pUser,uint8 pos)
{
	if (pUser == NULL)
		return NULL;
	SItemInstance *pItem = pUser->GetItem(pos);
	if ((pItem == NULL) || (pItem->tmplId != 1817))
		return NULL;
	pUser->DelPackage(pos);
	static const uint16 jianDing[] = {540,541,542,543,544,545,548,549,550,551,552,553,554,555,556,557,
		558,559,564,565,566,567,568,569,570,572,575,578,585,586,587,588,589,590,591,592,593,594,595,596};

	CItemTemplateManager &itemMgr = SingletonItemManager::instance();
	static char buf[64];
	buf[0] = 0;
	uint16 index = Random(1,(int)(sizeof(jianDing)/sizeof(jianDing[0]))) - 1;
	SItemInstance item;
	item.tmplId = jianDing[index];
	if(pUser->AddPackage(item))
	{
		SItemTemplate *pItem = itemMgr.GetItem(jianDing[index]);
		if(pItem != NULL)
			strcat(buf,pItem->name.c_str());
	}
	return buf;
}

void BangPaiHuoYuePaiHang(CUser *pUser,char *str)
{
	if (pUser == NULL || str == NULL)
		return;
	CBangPaiManager &bangPaiMgr = SingletonCBangPaiManager::instance();
	bangPaiMgr.BangPaiHuoYuePaiHang(pUser,str);
}

#define DEFINE_FIGHT(ScriptFight)\
void ScriptFight(CUser *pUser)\
{\
	if((pUser != NULL) && (pUser->GetScene() != NULL))\
	{\
		pUser->GetScene()->ScriptFight(pUser);\
	}\
}

/*
TYPE=25 输入数量
+-----+
| ID  |
+-----+
|  2  |
+-----+
*/
void InputNumber(CUser *pUser,int id)
{
	if (pUser == NULL)
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_INTERACT);

	msg<<(uint8)25<<(uint16)id;
	sock.SendMsg(pUser->GetSock(),msg);
}

int ChangeCharName(CUser *pUser,char *name)
{
	if((pUser == NULL) || (name == NULL))
		return 1;
	string n = name;
	int nameLen = strlen(name);
	if((nameLen < 2) || (nameLen > 16))
		return 1;
	if(IllegalStr(n))
		return 1;
	if(IsIllegalMsg(name))
		return 1;

	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if (pDb == NULL)
		return 1;
	char buf[512];
	snprintf(buf,sizeof(buf),"update role_info set name='%s' where id=%d",name,pUser->GetRoleId());
	if(pDb->Query(buf))
	{
		pUser->SetName(name);
		return 0;
	}
	return 2;
}

int ChangeRoleName(CUser *pUser,char *name)		// -1 异常1非法字符2用户名冲突3和原名字一样0成功
{
	if((pUser == NULL) || (name == NULL))
		return -1;
	string n = name;
	int nameLen = strlen(name);
	if((nameLen < 2) || (nameLen > 16))
		return 1;
	if(IllegalStr(n))
		return 1;
	if(IsIllegalMsg(name))
		return 1;
	if(strcmp(pUser->GetName(),name) == 0)
		return 3;

	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if (pDb == NULL)
		return -1;
	char buf[512];
	snprintf(buf,sizeof(buf),"update role_info set name='%s' where id=%d",name,pUser->GetRoleId());
	if(pDb->Query(buf))
	{
		snprintf(buf,sizeof(buf),"insert into change_name_log (user_id,role_id,before_name,after_name) values(%d,%d,'%s','%s')",
			(int)pUser->GetUserId(),(int)pUser->GetRoleId(),pUser->GetName(),name);
		if(!pDb->Query(buf))
			cout<<"Error insert into change_name_log : "<<buf<<endl;
		pUser->SetName(name);
		return 0;
	}
	return 2;
}

bool CanChangeName(CUser *pUser)
{
	if(pUser == NULL)
		return false;
	int len = strlen(pUser->GetName());
	if(len <= 2)
		return false;
	const char *name = pUser->GetName();
	if(strstr(name,"[1]") != NULL)
		return true;
	return false;
}

extern int GetOnlineUserNum();

void TeXiao(int type,int scene)
{
	CNetMessage msg;
	msg.SetType(MSG_SERVER_VISUAL_EFFECT);
	msg<<(uint8)type;
	if(scene == 0)
		SendMsgToAllUser(msg);
	else
		SendSceneMsg(msg,scene);
}

static void SendMsg(CSocketServer *pSock,CNetMessage *pMsg,CUser *pUser)
{
	pSock->SendMsg(pUser->GetSock(),*pMsg);
}

void SendSysChannelMsg(const char *info)
{
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_MSG_CHAT);
	msg<<(uint8)0<<0<<LANGUAGE_TRANSFORM_803<<(uint8)0<<info;
	SingletonOnlineUser::instance().ForEachUser(boost::bind(SendMsg,&sock,&msg,_1));
}

int FindUniqueJiHuoMa(CUser *pUser,char *str,int ad,int type,bool useMul)
{
	if(str == NULL || ad < 0 || pUser == NULL)
		return 2;
	string filtStr = SQLFilter(str);
	uint32 curTime = GetSysTime();

	char sql[512];
	snprintf(sql,sizeof(sql),"select state from jihuoma where binary str='%s' and ad=%d and type=%d",filtStr.c_str(),ad,type); // 区分大小写
	boost::recursive_mutex::scoped_lock lk(G_LoginDB_Mutex);
	if(!g_LoginDB.Query(sql))
		return 2;
	char **row = g_LoginDB.GetRow();
	if(row == NULL)
		return 2;
	if(atoi(row[0]) != 0)
		return 1;

	if (useMul)
		return 0;

	snprintf(sql,sizeof(sql),"update jihuoma set state=1,uid = %d,roleId = %d,serverId = %d,time = from_unixtime(%d) where binary str='%s' and ad=%d and type=%d",
								pUser->GetUserId(),pUser->GetRoleId(),pUser->GetServerId(),curTime,filtStr.c_str(),ad,type);
	if(g_LoginDB.Query(sql))
		return 0;
	else
		return 2;
}

const char *GetJiHuoMaInfo(char *str)
{
	static char buf[512];
	if(str == NULL)
		return NULL;
	string filtStr = SQLFilter(str);

	char sql[512];
	snprintf(sql,sizeof(sql),"select type,ad from jihuoma where binary str='%s'",filtStr.c_str()); // 区分大小写
	boost::recursive_mutex::scoped_lock lk(G_LoginDB_Mutex);
	if(!g_LoginDB.Query(sql))
		return NULL;
	char **row = g_LoginDB.GetRow();
	if(row == NULL)
		return NULL;
	snprintf(buf, sizeof(buf), "%s|%s",row[0], row[1]);
	return buf;
}

bool IsTestCZAccount(CUser *pUser)
{
	if(pUser == NULL)
		return false;
	string accountName;
	pUser->GetAccountName(accountName);

	char sql[256];
	snprintf(sql,sizeof(sql),"select money from chongfanli where user_name='%s'",accountName.c_str());
	boost::recursive_mutex::scoped_lock lk(G_LoginDB_Mutex);
	if(!g_LoginDB.Query(sql))
		return false;
	char **row = g_LoginDB.GetRow();
	if(row == NULL)
		return false;
	return true;
}

const char *GetTestCZFanLiInfo(CUser *pUser)
{
	static char buf[512];
	if(pUser == NULL)
		return NULL;
	string accountName;
	pUser->GetAccountName(accountName);

	char sql[256];
	snprintf(sql,sizeof(sql),"select money,getaward from chongfanli where user_name='%s' and getaward=0",accountName.c_str());
	boost::recursive_mutex::scoped_lock lk(G_LoginDB_Mutex);
	if(!g_LoginDB.Query(sql))
		return NULL;
	char **row = g_LoginDB.GetRow();
	if(row == NULL)
		return NULL;
	snprintf(buf,sizeof(buf),"%s|%s",row[1],row[0]);
	return buf;
}

bool SetTestCZFanLiAward(CUser *pUser)
{
	if(pUser == NULL)
		return false;
	string accountName;
	pUser->GetAccountName(accountName);

	char sql[256];
	boost::recursive_mutex::scoped_lock lk(G_LoginDB_Mutex);
	snprintf(sql,sizeof(sql),"select getaward from chongfanli where user_name='%s'",accountName.c_str());
	if(!g_LoginDB.Query(sql))
		return false;
	char **row = g_LoginDB.GetRow();
	if(row == NULL)
		return false;
	if(atoi(row[0]) == 1)
		return false;
	uint32 roleId = pUser->GetRoleId();
	int serverId = pUser->GetServerId();
	snprintf(sql,sizeof(sql),"update chongfanli set getaward=1,get_time=%u,get_roleid=%u,get_serverid=%d where user_name='%s'",
		(uint32)GetSysTime(),roleId,serverId,accountName.c_str());
	if(!g_LoginDB.Query(sql))
		return false;
	return true;
}

bool HaveAward_TestAccount(CUser *pUser)
{
	if(pUser == NULL)
		return false;
	string accountName;
	pUser->GetAccountName(accountName);

	char sql[256];
	snprintf(sql,sizeof(sql),"select getaward from old_account where user_name='%s' and getaward=0",accountName.c_str());
	boost::recursive_mutex::scoped_lock lk(G_LoginDB_Mutex);
	if(!g_LoginDB.Query(sql))
		return false;
	char **row = g_LoginDB.GetRow();
	if(row == NULL)
		return false;
	return (atoi(row[0]) == 0);
}

bool SetAward_TestAccount(CUser *pUser)
{
	if(pUser == NULL)
		return false;
	string accountName;
	pUser->GetAccountName(accountName);

	char sql[256];
	boost::recursive_mutex::scoped_lock lk(G_LoginDB_Mutex);
	snprintf(sql,sizeof(sql),"select getaward from old_account where user_name='%s'",accountName.c_str());
	if(!g_LoginDB.Query(sql))
		return false;
	char **row = g_LoginDB.GetRow();
	if(row == NULL)
		return false;
	if(atoi(row[0]) == 1)
		return false;
	uint32 roleId = pUser->GetRoleId();
	int serverId = pUser->GetServerId();
	snprintf(sql,sizeof(sql),"update old_account set getaward=1,get_time=%u,get_roleid=%u,get_serverid=%d where user_name='%s'",
		(uint32)GetSysTime(),roleId,serverId,accountName.c_str());
	if(!g_LoginDB.Query(sql))
		return false;
	return true;
}

void SendHotPointStatus(CUser *pUser, uint16 type, uint8 status)
{
	if (pUser == NULL)
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_Func_HotPoint);
	msg<<(uint8)2<<type<<status;
	sock.SendMsg(pUser->GetSock(),msg);
}

void OpenXinShi(CUser *pUser)
{
	if (pUser == NULL)
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_SERVER_XINSHI);

	msg<<(uint8)0;
	sock.SendMsg(pUser->GetSock(),msg);
}

void QueryArenaLog(CUser *pUser)
{
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_SERVER_ARENA);
	msg<<pUser->GetRoleId()<<(uint8)3;
	sock.SendServerMsg(EST_LONG, msg);
}

void InitArena(CUser *pUser)
{
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_SERVER_ARENA);
	msg<<pUser->GetRoleId()<<(uint8)0;
	sock.SendServerMsg(EST_LONG, msg);
}

void ListXinShi(CUser *pUser)
{
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_SERVER_SERVER_XINSHI);
	msg<<pUser->GetRoleId()<<(uint8)2;
	sock.SendServerMsg(EST_LONG, msg);
}

void QueryRoleName(int sock,uint8 sex)
{
	CSocketServer &sockServer = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_SERVER_ROLE_NAME);
	msg<<sock<<(uint8)2<<sex;
	sockServer.SendServerMsg(EST_LONG, msg);
}

int GetLeiTaiJiFen(CUser *pUser)
{
	if (pUser == NULL)
		return 0;

	CSceneManager &scene = SingletonSceneManager::instance();

	CScene *pScene = scene.FindScene(LEI_TAI_ID2);
	if (pScene == NULL)
		return 0;
	return pScene->GetUserJiFen(pUser->GetRoleId());
}

void ClearLeiTaiJiFen(CUser *pUser)
{
	if(pUser == NULL)
		return;
	CSceneManager &scene = SingletonSceneManager::instance();
	CScene *pScene = scene.FindScene(LEI_TAI_ID2);
	if(pScene == NULL)
		return;
	pScene->ClearUserJiFen(pUser->GetRoleId());
}

void SendNpcPos(CUser *pUser,int mapId,uint8 x,uint8 y)
{
	if (pUser == NULL)
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_NPC_POS);

	msg<<(uint16)mapId<<x<<y;
	sock.SendMsg(pUser->GetSock(),msg);
}

void SendNpcMsg(CUser *pUser,int npcId,const char *chatMsg)
{
	if ((pUser == NULL) || (chatMsg == NULL))
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_SERVER_NPC_SAY);

	msg<<(uint16)npcId<<chatMsg;
	sock.SendMsg(pUser->GetSock(),msg);
}

bool HaveChongZhi(CUser *pUser)
{
	if(pUser == NULL)
		return false;
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char sql[512];
	snprintf(sql,sizeof(sql),"SELECT sum(money) FROM cz_complete where role_id=%u and date(time)>'2011-09-01'",pUser->GetRoleId());
	if ((pDb == NULL) || (!pDb->Query(sql)))
	{
		return false;
	}
	char **row = pDb->GetRow();
	if((row == NULL) || (row[0] == NULL) || (atoi(row[0]) == 0))
		return false;
	return true;
}

bool CanEnterLeiTai(uint32 roleId)
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char sql[512];
	snprintf(sql,sizeof(sql),"SELECT id FROM leitai_paiming where role_id=%u and UNIX_TIMESTAMP(time)>%lu",roleId,GetSysTime()-7*24*3600);
	if ((pDb == NULL) || (!pDb->Query(sql)))
	{
		return false;
	}
	char **row = pDb->GetRow();
	if(row == NULL)
		return true;
	if(atoi(row[0]) <= 2)
		return false;
	return true;
}

int GetOnlineDay(int roleId)
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char sql[512];
	char tab[64];
	GetLoginLogTab(tab,sizeof(tab));
	snprintf(sql,sizeof(sql),"select id from %s where role_id=%d and date(`login_time`) = date(FROM_UNIXTIME(%lu)) limit 1",tab,roleId,GetSysTime()-24*3600);
	if ((pDb == NULL) || (!pDb->Query(sql)))
	{
		return 0;
	}
	if(pDb->GetRow() == NULL)
		return 0;
	snprintf(sql,sizeof(sql),"select id from %s where role_id=%d and date(`login_time`) = date(FROM_UNIXTIME(%lu)) limit 1",tab,roleId,GetSysTime()-24*2*3600);
	if ((pDb == NULL) || (!pDb->Query(sql)))
	{
		return 0;
	}
	if(pDb->GetRow() == NULL)
		return 1;
	return 2;
}

int BitAnd(int i,int j)
{
	return i & j;
}
int BitOr(int i,int j)
{
	return i | j;
}

int GetRoleLastTime(const int id, bool isForce)
{
	if (!isForce)
	{
		ShareUserPtr ptr = SingletonOnlineUser::instance().GetUserByRoleId(id);
		if(ptr.get() != NULL)
			return (int)GetSysTime();
	}

    CGetDbConnect getDb;
    CDatabaseSql *pDb = getDb.GetDbConnect();
    if(pDb == NULL)
        return 0x7effffff;
    char sql[128];
	snprintf(sql,sizeof(sql),"select login_time from role_info where id=%d",id);
    if(!pDb->Query(sql))
        return 0x7effffff;
    char **row = pDb->GetRow();
    if(row == NULL)
        return 0x7effffff;
    return atoi(row[0]);
}

void DisMissBangActive(CUser *pUser)
{
	uint32 bangpaiID = pUser->GetBangPai();
	CBangPai *pBangPai = SingletonCBangPaiManager::instance().FindBangPai(bangpaiID);
	if(pBangPai == NULL)
		return;
	if(pBangPai->dismissbang_time == 0)
		return;
	pBangPai->DismissBang_updata();
}

char *GetName(CUser *pUser,int rank,int tangzhurank)
{
	static char name[128];
	name[0] = '\0';
	if(name[0] == '\0')
		return NULL;
	else
		return name;
}

int IsChuangWei(CUser *pUser)
{
	CBangPai *pBangPai = SingletonCBangPaiManager::instance().FindBangPai(pUser->GetBangPai());
	if(pBangPai == NULL)
		return 0;
	if(pBangPai->IsChuangwei() == true)
		return 1;
	else
		return 0;
}

int IsDisMissBangPai(CUser *pUser)
{
	CBangPai *pBangPai = SingletonCBangPaiManager::instance().FindBangPai(pUser->GetBangPai());
	if(pBangPai == NULL)
		return 0;
	if(pBangPai->dismissbang_time > 0)
		return 1;
	else
		return 0;
}

int ExportUserInfo(CUser *pUser)
{
	return 0;
}

int SendYinDaoNPCPos(CUser *pUser,int mapId,int x,int y,int npcId)
{
	return SendYinDaoMissionNPCPos(pUser, mapId, x, y, npcId, 0);
}

int SendYinDaoMissionNPCPos(CUser *pUser, int mapId, int x, int y, int npcId, int mid)
{
	if (pUser == NULL)
		return 1;
	SNpcPos npcPos = pUser->FindNpcPos(npcId);
	if (npcPos.sceneId == 0)	// 无NPC instance
	{
		npcPos = GetNpcTmplPos(npcId);
		if (npcPos.sceneId == 0)	// 自身npc也没有
		{
			npcPos.sceneId = mapId;
			npcPos.x = x;
			npcPos.y = y;
		}
	}

	if (pUser->HaveBitSet(364))
	{
		CScene *pScene = pUser->GetScene();
		if (pScene == NULL)
			return 1;
		if (mapId != pScene->GetSrcSceneId())
		{
			pScene = SingletonSceneManager::instance().FindScene(mapId);
			if (pScene == NULL)
				return 1;
			TransportUser(pUser, mapId, pScene->GetX(), pScene->GetY(), 0);
		}
	}

	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_YINDAO);
	//	msg<<(uint8)0<<(uint16)npcPos.sceneId<<(uint16)npcPos.x<<(uint16)npcPos.y<<(uint16)npcId;
	msg << (uint8)0 << (uint16)npcPos.sceneId << (uint16)-1 << (uint16)-1 << (uint16)npcId << (uint16)mid;
	pUser->SetExtData16(19, (uint16)npcPos.sceneId);
	pUser->SetExtData16(112, (uint16)npcPos.x);
	pUser->SetExtData16(113, (uint16)npcPos.y);
	sock.SendMsg(pUser->GetSock(), msg);
	return 1;
}

int SendYinDaoMonsterPos(CUser *pUser,int mapId,int x,int y,int monsterId)
{
	if(pUser == NULL)
		return 1;
	if(pUser->HaveBitSet(364))
	{
		CScene *pScene = pUser->GetScene();
		if(pScene == NULL)
			return 1;
		if(mapId != pScene->GetSrcSceneId())
		{
			pScene = SingletonSceneManager::instance().FindScene(mapId);
			if(pScene == NULL)
				return 1;
			TransportUser(pUser,mapId,pScene->GetX(),pScene->GetY(),0);
		}
	}

	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_YINDAO);
	msg<<(uint8)1<<(uint16)mapId<<(uint16)x<<(uint16)x<<(uint16)monsterId;
	sock.SendMsg(pUser->GetSock(),msg);
	return 1;
}

/********************* 总体引导
// 0	测试引导
// 5	神将进化
// 6	商场抽神将引导
// 7	锻造-强化引导
// 15	神将引导出阵(6级出战、观看)
// 16	技能学习引导(人物技能引导)
// 17	坐骑引导(坐骑引导)
// 22	第二次副本引导
// 23	神将出战引导14级
// 25	神将出战引导26级
// 26	装备升阶
// 27	第三次副本引导(神将)
// 28	换神将出阵引导
// 29	日常boss引导获得奖励
// 30	神将抽取引导
// 31	玩法猜拳引导
// 32	玩法闯关
// 33	玩法答题
// 34	强化副本引导
// 35	手动战斗引导
// 36	自动战斗引导
// 40	第一场战斗引导
// 41   第二次战斗引导
// 101	坐骑骑乘引导
// 103	技能引导
// 106	神将副本引导
// 107  普通副本引导
// 108	强化引导
// 109	7日礼包引导
// 110  竞技场引导

// 1001 打开猜拳界面
// 1002 打开答题界面
// 1003 打开猜拳界面(跳过选择奖励界面)
// 1004 打开组队界面
*****************************/
void SendYinDao2_Op(CUser *pUser, int op)
{
	if(pUser == NULL)
		return;
	if(op < 0)
		return;

	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_XINSHOUYINDAO);
	msg<<(uint16)op;
	sock.SendMsg(pUser->GetSock(),msg);
}

// 获取升级经验
int GetLvUpExp(int level)
{
	return GetLevelUpExp(level);
}

void KuaFuZhan_paihang(CUser *pUser,char *time,char *str)
{
	if(pUser == NULL || time == NULL || str == NULL)
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
	char buf[256];
	msg.SetType(PRO_INTERACT);
	msg<<(uint8)17;
	msg<<(uint8)13<<str;
	uint16 pos = msg.GetDataLen();
	uint8 num=0;
	msg<<num;

	snprintf(buf,sizeof(buf),"select role_id,name,paiming from kuafu_paihang where date(time)='%s' order by paiming asc",time);
	if(pDb->Query(buf))
	{
		char **row;
		uint8 limite=30;
		while((row = pDb->GetRow()) != NULL && limite > 0)
		{
			limite--;
			num++;
			msg<<(uint32)atoi(row[0])<<row[1]<<(uint32)atoi(row[2]);
		}
		msg.WriteData(pos,&num,1);
		sock.SendMsg(pUser->GetSock(),msg);
	}
}

char *TiaoZhanSai_paihang(CUser *pUser,char *time)
{
	if(pUser == NULL || time == NULL)
		return NULL;
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return NULL;
	char sql[256];
	static char buf[256];
	buf[0] = '\0';
	snprintf(sql,sizeof(sql),"select name from kuafu_paihang where date(time)='%s' order by paiming asc",time);
	if(pDb->Query(sql))
	{
		char **row;
		uint8 limite=5;
		while((row = pDb->GetRow()) != NULL && limite > 0)
		{
			if(limite < 5)
				strcat(buf,"|");
			strcat(buf,row[0]);
			limite--;
		}
		return buf;
	}
	else
		return NULL;
}

void ChangeRoleShape(CUser *pUser,int val)
{
	if(pUser == NULL)
		return;
	pUser->SetExtData8(72,(uint8)val);
	CScene *pScene = pUser->GetScene();
	if(pScene == NULL)
		return;
	pScene->UpdateUserInfo(pUser,ESRT_TransormShape);
}

// 获取全局数据值
int GetGlobalVarible(int key)
{
	char sql[128];
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return 0;
	snprintf(sql,sizeof(sql),"select value from global_variable where id = %d", key);
	if (!pDb->Query(sql))
		return 0;
	char** row;
	if (pDb->GetRowNum() == 0)
	{
		snprintf(sql,sizeof(sql),"insert into global_variable (id) values (%d)", key);
		pDb->Query(sql);
		snprintf(sql,sizeof(sql),"select value from global_variable where id = %d", key);
		pDb->Query(sql);
	}
	if ((row = pDb->GetRow()) == NULL)
		return 0;
	return atoi(row[0]);
}

// 设置全局数据值
void SetGlobalVarible(int key, int value)
{
	char sql[128];
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
	snprintf(sql,sizeof(sql),"update global_variable set value='%d' where id=%d",value,key);
	pDb->Query(sql);
}

// 全局表数据读取
string GetGlobalVaribleData(int key)
{
	static string data;
	data.clear();
	
	char sql[128];
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return data;
	snprintf(sql,sizeof(sql),"select data from global_variable where id=%d",key);
	if(!pDb->Query(sql))
		return data;
	char **row = NULL;
	if(pDb->GetRowNum() == 0)
	{
		snprintf(sql,sizeof(sql),"insert into global_variable (id) values (%d)",key);
		pDb->Query(sql);
		return data;
	}
	if((row = pDb->GetRow()) == NULL)
		return data;
	data = row[0];
	return data;
}

// 全局表数据设置
void SetGlobalVaribleData(int key, const char* data)
{
	if(data == NULL)
		return;	
	char sql[2048];
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
	snprintf(sql,sizeof(sql),"update global_variable set data='%s' where id=%d",data,key);
	pDb->Query(sql);
}

// 全局表数据设置
void SetGlobalVaribleDataAndTime(int key, const char* data, uint32 time)
{
	if(data == NULL)
		return;	
	char sql[2048];
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
	snprintf(sql,sizeof(sql),"update global_variable set data='%s',time=FROM_UNIXTIME(%d) where id=%d",data,time,key);
	pDb->Query(sql);
}


// 全局表数据设置
void SetGlobalVaribleData(int key, int data)
{
	char sql[2048];
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
	snprintf(sql, sizeof(sql),"update global_variable set data='%d' where id=%d",data,key);
	pDb->Query(sql);
}

uint32 GetGlobalVaribleTime(int key)
{
	uint32 time = 0;
	
	char sql[256];
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return time;

	snprintf(sql,sizeof(sql),"select UNIX_TIMESTAMP(time) from global_variable where id=%d",key);
	if(!pDb->Query(sql))
		return time;
	
	char **row = NULL;
	if(pDb->GetRowNum() == 0)
	{
		snprintf(sql,sizeof(sql),"insert into global_variable (id) values (%d)",key);
		pDb->Query(sql);
		return time;
	}
	
	if((row = pDb->GetRow()) == NULL)
		return time;
	if(row[0] == NULL)
		return time;
	time = (uint32)atoi(row[0]);
	return time;
}

// 保存记录
void SaveDataEx(CUser* pUser, int type, int data1, int data2, int data3)
{
	{ // 数据库没有这个表 该记录功能暂时取消
		return;
	}
	uint32 roleId = 0;
	if (pUser != NULL)
		roleId = pUser->GetRoleId();
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char sql[256];
	snprintf(sql,sizeof(sql),"INSERT INTO script_save_2 (role_id,type,data1,data2,data3,time) "\
		"VALUES (%d,%d,%d,%d,%d,FROM_UNIXTIME(%lu))",
		roleId,type,data1,data2,data3,GetSysTime());
	if (pDb != NULL)
		pDb->Query(sql);
}

// 发送帮派信息
void SysInfoToBangPai(int bId, const char* msg)
{
	if (bId == 0)
		return;

	CBangPaiManager &bangPaiMgr = SingletonCBangPaiManager::instance();
	CBangPai *pBangPai = bangPaiMgr.FindBangPai(bId);
	if (pBangPai == NULL)
		return;
	pBangPai->Say(msg);
}

void SysInfoToBangPai_Tips(int bangId,const char *msg)
{
	if(bangId == 0)
		return;

	CBangPaiManager &bangPaiMgr = SingletonCBangPaiManager::instance();
	CBangPai *pBangPai = bangPaiMgr.FindBangPai(bangId);
	if(pBangPai == NULL)
		return;
	pBangPai->TipsToAllOnLineMembers(msg);
}


// 帮派挑战赛数据
extern int BANG_PAI_TIAO_ZHAN_YEAR; // 年
extern int BANG_PAI_TIAO_ZHAN_MONTH; // 月
extern int BANG_PAI_TIAO_ZHAN_DAY; // 日
extern int BANG_PAI_TIAO_ZHAN_HOUR; // 时
extern int BANG_PAI_TIAO_ZHAN_MIN; // 分
extern int BANG_PAI_TIAO_ZHAN_BAO_MING_HOUR; // 报名时间
extern int BANG_PAI_TIAO_ZHAN_BAO_CHI_XU; // 持续时间
extern int BANG_PAI_TIAO_ZHAN_LIMIT_TEAM; // 帮派队伍限制数
extern int BANG_PAI_TIAO_ZHAN_BAOMINGTIME; // 报名时间点
extern int BANG_PAI_TIAO_ZHAN_STARTTIME; // 开始时间点
extern int BANG_PAI_TIAO_ZHAN_ENDTIME; // 结束时间点
extern char BANG_PAI_TIAO_ZHAN_RANK[255]; // 榜排行
int BangPaiTiaoZhanSaiBangBaoMingShu(int bId);
int BangPaiTiaoZhanSaiBangGetBaoMingId(int roleId);


// 返回0：成功报名；1：已经报过了；2：达到帮派报名上限了；3：系统忙（未知原因）
int BangPaiTiaoZhanSaiBaoMing(CUser *pUser, int bId, int roleId1, int roleId2, int roleId3)
{
	if (pUser == NULL)
		return 3;
	int num = BangPaiTiaoZhanSaiBangBaoMingShu(bId);
	if (num >= BANG_PAI_TIAO_ZHAN_LIMIT_TEAM)
		return 2;
	if (roleId1 != 0)
	{
		if (BangPaiTiaoZhanSaiBangGetBaoMingId(roleId1) > 0)
			return 1;
	}
	if (roleId2 != 0)
	{
		if (BangPaiTiaoZhanSaiBangGetBaoMingId(roleId2) > 0)
			return 1;
	}
	if (roleId3 != 0)
	{
		if (BangPaiTiaoZhanSaiBangGetBaoMingId(roleId3) > 0)
			return 1;
	}

	int now = GetSysTime();
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if (pDb == NULL)
		return 3;
	char sql[255];
	snprintf(sql,sizeof(sql),"insert into bang_tiaozhan (bang,data1,data2,data3,type,time) values (%d,%d,%d,%d,2,%d);",bId,roleId1,roleId2,roleId3,now);
	if (!pDb->Query(sql))
		return 3;
	return 0;
}

// 帮派报名队伍数
int BangPaiTiaoZhanSaiBangBaoMingShu(int bId)
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if (pDb == NULL)
		return BANG_PAI_TIAO_ZHAN_LIMIT_TEAM;
	char sql[255];
	snprintf(sql,sizeof(sql),"select count(bang) from bang_tiaozhan where bang = %d;",bId);
	if (!pDb->Query(sql))
		return BANG_PAI_TIAO_ZHAN_LIMIT_TEAM;
	if (pDb->GetRowNum() == 0)
		return 0;
	char** row;
	if ((row = pDb->GetRow()) == NULL)
		return BANG_PAI_TIAO_ZHAN_LIMIT_TEAM;
	int num = atoi(row[0]);
	return num;
}

// 获取报名记录id 没报过名则返回0 出错则返回-1
int BangPaiTiaoZhanSaiBangGetBaoMingId(int roleId)
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if (pDb == NULL)
		return -1;
	char sql[255];
	snprintf(sql,sizeof(sql),"select id from bang_tiaozhan where ((data1 = %d) or (data2 = %d) or (data3 = %d)) and type = 2;",roleId,roleId,roleId);
	if (!pDb->Query(sql))
		return -1;
	if (pDb->GetRowNum() == 0)
		return 0;
	char** row;
	if ((row = pDb->GetRow()) == NULL)
		return -1;
	int id = atoi(row[0]);
	return id;
}

// 是否可以进入场景
bool BangPaiTiaoZhanSaiBangEnterEnable(int roleId1, int roleId2, int roleId3)
{
	int empty = 0;
	if (roleId1 == 0)
		++empty;
	if (roleId2 == 0)
		++empty;
	if (roleId3 == 0)
		++empty;
	if (empty > 1) // 有两个人不再就不能进入
		return false;
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if (pDb == NULL)
		return false;
	char sql[255];
	snprintf(sql,sizeof(sql),"select data1,data2,data3 from bang_tiaozhan where ((data1 = %d) or (data2 = %d) or (data3 = %d)) and type = 2;",roleId1,roleId1,roleId1);
	if (!pDb->Query(sql))
		return false;
	if (pDb->GetRowNum() == 0)
		return false;
	char** row;
	if ((row = pDb->GetRow()) == NULL)
		return false;
	int t1,t2,t3;
	t1 = atoi(row[0]);
	t2 = atoi(row[1]);
	t3 = atoi(row[2]);
	if ((roleId2 == t1) || (roleId2 == t2) || (roleId2 == t3) || (roleId2 == 0))
	{
		if ((roleId3 == t1) || (roleId3 == t2) || (roleId3 == t3) || (roleId3 == 0))
		{
			return true;
		}
	}
	return false;
}

// 帮派挑战赛活动状态 返回：0：不在活动中；1：报名中；2：活动进行中；3：活动即将开始；4：活动马上结束
int BangPaiTiaoZhanSaiState()
{
	time_t t = GetSysTime();
	if (GetYear() + 1900 != BANG_PAI_TIAO_ZHAN_YEAR)
		return 0;
	if (GetMonth()+ 1 != BANG_PAI_TIAO_ZHAN_MONTH)
		return 0;
	if (GetDay() != BANG_PAI_TIAO_ZHAN_DAY)
		return 0;
	if (t < (time_t)((BANG_PAI_TIAO_ZHAN_BAOMINGTIME-BANG_PAI_TIAO_ZHAN_SPACE)))
		return 0;
	if ((t >= (time_t)((BANG_PAI_TIAO_ZHAN_BAOMINGTIME-BANG_PAI_TIAO_ZHAN_SPACE)) && (t < BANG_PAI_TIAO_ZHAN_BAOMINGTIME)))
		return 3;
	if ((t >= (time_t)(BANG_PAI_TIAO_ZHAN_BAOMINGTIME) && (t < BANG_PAI_TIAO_ZHAN_STARTTIME)))
		return 1;
	if ((t >= (time_t)(BANG_PAI_TIAO_ZHAN_STARTTIME) && (t < BANG_PAI_TIAO_ZHAN_ENDTIME)))
		return 2;
	if ((t >= (time_t)(BANG_PAI_TIAO_ZHAN_ENDTIME) && (t < (BANG_PAI_TIAO_ZHAN_ENDTIME+BANG_PAI_TIAO_ZHAN_SPACE))))
		return 4;
	return 0;
}

// 获取排行榜
const char* BangPaiTiaoZhanSaiPaiHang()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if (pDb == NULL)
		return NULL;
	char sql[255];
	snprintf(sql,sizeof(sql),"select data1,data2,data3 from bang_tiaozhan where id = 1");
	if (!pDb->Query(sql))
		return NULL;
	if (pDb->GetRowNum() == 0)
		return NULL;
	char** row;
	if ((row = pDb->GetRow()) == NULL)
		return NULL;
	int bang1,bang2,bang3;
	bang1 = atoi(row[0]);
	bang2 = atoi(row[1]);
	bang3 = atoi(row[2]);
	snprintf(BANG_PAI_TIAO_ZHAN_RANK,sizeof(BANG_PAI_TIAO_ZHAN_RANK),"%d|%d|%d",bang1,bang2,bang3);
	return BANG_PAI_TIAO_ZHAN_RANK;
}

// 是否可以领奖 返回：0：不能领奖；1：第一名奖励；2：第二名奖励；3：第三名奖励；4：已经领取过了；5：第一名帮派奖励；6：参与奖
int BangPaiTiaoZhanSaiEnableLingJiang(CUser *pUser)
{
	if (pUser == NULL)
		return 0;

	// 是否已经领取过了
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if (pDb == NULL)
		return 0;
	int roleId = pUser->GetRoleId();
	char sql[255];
	snprintf(sql,sizeof(sql),"select id from bang_tiaozhan where type = 3 and data1 = %d",roleId);
	if (!pDb->Query(sql))
		return 0;
	if (pDb->GetRowNum() != 0)
		return 4;

	// 帮派信息
	int bang = pUser->GetBangPai();
	snprintf(sql,sizeof(sql),"select data1,data2,data3 from bang_tiaozhan where id = 1");
	if (!pDb->Query(sql))
		return 0;
	if (pDb->GetRowNum() == 0)
		return 0;
	char** row;
	if ((row = pDb->GetRow()) == NULL)
		return 0;
	int bang1,bang2,bang3;
	bang1 = atoi(row[0]);
	bang2 = atoi(row[1]);
	bang3 = atoi(row[2]);

	// 参与信息
	snprintf(sql,sizeof(sql),"select id from bang_tiaozhan where type = 2 and ((data1 = %d) or (data2 = %d) or (data3 = %d))",roleId,roleId,roleId);
	if (!pDb->Query(sql))
		return 0;
	if (pDb->GetRowNum() == 0)
	{
		if (bang == bang1)
			return 5;
		else
			return 0;
	}
	if (bang == bang1)
		return 1;
	else if (bang == bang2)
		return 2;
	else if (bang == bang3)
		return 3;
	else
		return 6;
}

// 领奖
bool BangPaiTiaoZhanSaiLingJiang(CUser *pUser,int type)
{
	if (pUser == NULL)
		return false;

	// 是否已经领取过了
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if (pDb == NULL)
		return false;
	int roleId = pUser->GetRoleId();
	char sql[255];
	snprintf(sql,sizeof(sql),"insert into bang_tiaozhan (bang,data1,data2,data3,type,time) values (0,%d,%d,0,3,%d)",roleId,type,(int)GetSysTime());
	if (!pDb->Query(sql))
		return false;
	return true;
}

bool SendSystemMail(int roleId,const char *pMsg,SMailData *pMailData)
{
	return SendMailToUser(0,LANGUAGE_TRANSFORM_804,roleId,pMsg,pMailData);
}

bool SendSystemAwardMail(int roleId, const char *buf, std::vector<SAwardData> &award)
{
	SMailData mdata;
	stringstream str;
	str << buf;
	for (uint16 i = 0; i < award.size(); ++i)
	{
		str << GetItemName(award[i].type) << "*" << award[i].num;
	}
	mdata.awards = award;
	SendSystemMail(roleId, buf, &mdata);
	return true;
}

bool SendSysTest(int roleId, int type, int rank)
{
	//SMailData mdata;
	//mdata.YB = 100;
	//mdata.bdYB = 110;
	//mdata.money = 10000;
	//mdata.shenhun = 1000;
	//mdata.awards.push_back(make_pair(HDAT_XingXiuJingHua, 120));
	//mdata.awards.push_back(make_pair(HDAT_LEITAI_JIFEN, 130));
	//mdata.awards.push_back(make_pair(HDAT_BANG_GONG, 140));
	//SharePetPtr pet = CreatePet(47, 30, 2);
	//if (pet.get() == NULL)
	//	return false;
	//mdata.pet.push_back(*(pet.get()));
	//SItemInstance item[3];
	//item[0].tmplId = 502;
	//item[0].num = 1;
	//item[1].tmplId = 2311;
	//item[1].num = 2;
	//mdata.item.push_back(item[0]);
	//mdata.item.push_back(item[1]);

	//// CEquip equip;
	//// equip.id = 1001;
	//// equip.star = 6;
	//// mdata.equips.push_back(equip);
	//SendMailToUser(0, LANGUAGE_TRANSFORM_804, roleId, "hahaha", &mdata);
	return true;
}


bool SendMailToUser(int fromId,string fromName,int toId,const char *pMsg,SMailData *pMailData)
{
	if(pMsg == NULL)
		return false;
	
	int money = 0;
	int YB = 0;
	int bdYB = 0;
	int shenhun = 0;
	string strCompress;
	string mailStr = pMsg;
	string extStr = "";
	mailStr += LANGUAGE_ZQX_0106;
	char resultStr[1024] = { 0 };
	if (pMailData != NULL)
	{
		for (size_t i = 0; i < pMailData->awards.size(); i++)
		{
			SAwardData& award = pMailData->awards[i];
			switch (award.type)
			{
			case HDAT_MONEY:
			case HDAT_YB:
			case HDAT_BANG_YB:
			case HDAT_BANG_GONG:
			case HDAT_XingXiuJingHua:
			case HDAT_FaBaoSS:
			case HDAT_BANG_Exp:
			case HDAT_JJCMoney:
			case HDAT_KunLunMoney:
				if (!extStr.empty())
					extStr += LANGUAGE_ZQX_0101;
				extStr += GetItemColorStr(award.type, award.num);
				break;

			default:
				if (award.type > HDAT_MONEY)
				{
					if (!extStr.empty())
						extStr += LANGUAGE_ZQX_0101;
					extStr += GetItemColorStr(award.typeId, award.num);
				}
				else
				{
					if (!extStr.empty())
						extStr += LANGUAGE_ZQX_0101;
					extStr += GetItemColorStr(award.type, award.num);
				}
				break;
			}
		}

		MakeMailAttachStr(strCompress, pMailData);
	}

	if (extStr.empty())
		extStr = LANGUAGE_ZQX_0107;
	snprintf(resultStr, sizeof(resultStr) - 1, mailStr.c_str(), extStr.c_str());
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_SERVER_SERVER_XINSHI);
	msg<<toId<<(uint8)1;
	msg<<fromId;
	int nlen=fromName.size();
	msg<<(uint16)nlen;
	msg.WriteData((void *)fromName.c_str(),nlen);
    msg<<toId<<money<<YB<<bdYB<<shenhun;
	nlen=strCompress.size();
	msg<<(uint16)nlen;
	msg.WriteData((void *)strCompress.c_str(),nlen);
	nlen=strlen(resultStr);
	msg<<(uint16)nlen;
	msg.WriteData((void *)resultStr,nlen);
	sock.SendServerMsg(EST_LONG, msg);
	return true;
}

void MakeMailAttachStr(string &strCompress,SMailData *pMailData)
{
	strCompress.clear();
	if(pMailData == NULL)
		return;
	
	uint8 strdata[4096];
	uint32 pos = 0;
	strdata[pos++] = pMailData->awards.size();
	for (size_t i = 0; i < pMailData->awards.size(); i++)
	{
		SAwardData& award = pMailData->awards[i];
		CopyDataToBuf((char *)strdata, &(award.type), sizeof(award.type), pos, sizeof(strdata) - pos);
		CopyDataToBuf((char *)strdata, &(award.typeId), sizeof(award.typeId), pos, sizeof(strdata) - pos);
		CopyDataToBuf((char *)strdata, &(award.num), sizeof(award.num), pos, sizeof(strdata) - pos);
	}
	HexToStr(strdata,pos,strCompress);
}

// 获取激活码
const char* GetJiHuoMa(int type)
{
	const int stateEnable = 0; // 没有使用的激活码state为0
	const int stateDisable = 1; // 使用过的激活码state为1

	char sql[256];
	snprintf(sql,sizeof(sql),"select code from jihuoma_fa where state = %d and type = %d limit 1",stateEnable,type);
	boost::recursive_mutex::scoped_lock lk(G_LoginDB_Mutex);
	if (!g_LoginDB.Query(sql))
	{
		cout << "Error:GetJiHuoMa: query sql error" << endl;
		return "";
	}
	char **row = g_LoginDB.GetRow();
	if (row == NULL)
	{
		cout << "Error:GetJiHuoMa: empty table at jihuoma_fa" << endl;
		return "";
	}

	static char code[32] = {0};
	memset(code,0,sizeof(code)); // 清空字符串
	strcpy(code,row[0]); // 获取激活码

	snprintf(sql,sizeof(sql),"update jihuoma_fa set state = %d where code = '%s'", stateDisable,code);
	if (!g_LoginDB.Query(sql))
	{
		cout << "Error:GetJiHuoMa: update sql error" << endl;
		return "";
	}

	return code;
}

void ShowChoosePanel2(CUser *pUser,char *str)
{
	if(pUser == NULL || str == NULL)
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_INTERACT);
	msg<<(uint8)46<<str;
	sock.SendMsg(pUser->GetSock(),msg);
}

int GetTongTianTaBaZhuId(uint8 bazhuIndex)
{
	uint8 bazhuNum = sizeof(tongTianTaBaZhuFloor)/sizeof(tongTianTaBaZhuFloor[0]);
	if(bazhuIndex > bazhuNum-1)
		return 0;
	boost::recursive_mutex::scoped_lock lk(tongTianTa_mutex);
	if(tongTianTaBaZhuData.size() >= bazhuNum)
		return tongTianTaBaZhuData[bazhuIndex];
	else
		return 0;
}

// -1 错误 -2 在战斗中 -3 不能挑战自己 -4 在副本中
int TongTianTaBaZhuFight(CUser *pUser,int bazhuIndex)
{
	uint8 bazhuNum = sizeof(tongTianTaBaZhuFloor)/sizeof(tongTianTaBaZhuFloor[0]);
	if(pUser == NULL || bazhuIndex > bazhuNum-1)
		return -1;
	CScene *pScene = pUser->GetScene();
	if(pScene == NULL)
		return -1;
	uint32 bazhuId = 0;
	{
		boost::recursive_mutex::scoped_lock lk(tongTianTa_mutex);
		if(tongTianTaBaZhuData.size() >= bazhuNum)
		{
			bazhuId = tongTianTaBaZhuData[bazhuIndex];
			if(bazhuId <= 0)
				return -1;
		}
		else
			return -1;
	}

	ShareUserPtr ptr = SingletonOnlineUser::instance().GetUserByRoleId(pUser->GetRoleId());
	if(ptr.get() == NULL)
		return -1;
	if(pUser->GetKuaFuState() != EKFS_IN_LOCAL)
		return -1;
	if(pUser->GetFightId() != 0)
		return -2;
//	if(!pUser->CanWorldTransPort())
//		return -4;
	if(pUser->GetRoleId() == bazhuId)
		return -3;

	ShareUserPtr ptr2;
	CUser *pBaZhu = new CUser;
	pBaZhu->SetSock(-1);
	if(!pBaZhu->CopyUserData(bazhuId))
	{
		delete pBaZhu;
		return -1;
	}

	ptr2.reset(pBaZhu);
	ShareFightPtr pFight = SingletonFightManager::instance().CreateFight();
	pFight->SetFightType(CFight::EFTTongTianTa_TiaoZhan);
	pFight->SetFightChooseMode();
	pFight->AddUserGroupToFight(ptr);
	pFight->AddUserGroupToFight(ptr2, CFight::EGT_GROUP2);
	pFight->BeginFight(pScene);
	SingletonFightManager::instance().AddFight(pFight);
	return 0;
}

int GetHuoDongExpWithType(CUser *pUser,int type,double ratio)
{
	if(pUser == NULL)
		return 0;
	CHuoDongExpManage &expManager = SingletonHuoDongExpManager::instance();
	int64 addexp = expManager.GetHuoDongExp(type,pUser->GetLevel(),ratio);
	return (int)addexp;
}

void ShowHuSongShenShowTaskPanel(CUser *pUser)
{
	if(pUser == NULL)
		return;
	uint16 b_time = 0;
	uint16 s_time = 0;
	uint16 e_time = 0;
	if(!sSystemOpenCfgMananger.GetFuncLvTime(SOT_Husong,b_time,s_time,e_time))
		return;

	CHuoDongExpManage &expManager = SingletonHuoDongExpManager::instance();
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_HU_SONG);

	const float qualityRatio[] = {0.3f,0.5f,0.7f,0.85f,1.0f};
	uint8 quality = pUser->GetExtData8(78);
	int64 addExp = expManager.GetHuoDongExp(17,pUser->GetLevel(),0.2*qualityRatio[quality]);
	uint8 doubleExp = 1;	// 1双倍
	if(!CSceneManager::IsInActivityTime(SOT_Husong))
	{
		doubleExp = 0;
		addExp /= 2;
	}
	addExp = addExp - addExp%1000;

	char buf[256];
	snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_805,s_time/100,s_time%100,e_time/100,e_time%100);
	//			  任务品质	最大可接次数		剩余可接次数			 经验	 			消耗金币		双倍标志
	msg<<(uint8)1<<quality<<(uint8)5<<(uint8)(5-pUser->GetExtData8(81))<<addExp<<(int)(pUser->GetLevel()*10)<<doubleExp<<buf;
	sock.SendMsg(pUser->GetSock(),msg);

}

void UserLeaveTeam(CUser *pUser)
{
	CScene *pScene = pUser->GetScene();
	if (pScene == NULL)
		return;
	if (pScene->IsFuBen())
	{
		pUser->ExitFuBen();
	}
	pScene->LeaveTeam(pUser);
}

void ShowHuSongShenShouNextTaskPanel(CUser *pUser)
{
	if(pUser == NULL)
		return;
	uint8 num = pUser->GetExtData8(81);
	if(num >= 5)
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	char buf[128];
	msg.SetType(MSG_HU_SONG);
	snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_806,(int)(5-num));
	msg<<(uint8)8<<buf;
	sock.SendMsg(pUser->GetSock(),msg);
}

void UpdateHuSongTaskState(CUser *pUser)
{
	if(pUser == NULL)
		return;
	pUser->SendUpdateInfo(EUUT_HuSongState);
}

static void MakeYaYunBiaoCheInfo(CUser *pUser,uint16 npcId,uint8 isChanged,uint8 op)
{
/*
	if(pUser == NULL)
		return;
	const char *pMission = pUser->GetMission(213);
	if(pMission == NULL)
		return;

	char buf[128];
	char *split[10];
	//   0      1       2       3      4           5          6       7
	// step|quality|totolexp|lostexp|index|completeNpcIndex|money|loseMoney
	string str = pMission;
	int num = SplitLine(split,8,(char*)str.c_str());
	if(num < 8)
	{
		cout<<LANGUAGE_TRANSFORM_807<<endl;
		return;
	}

	const int qualityPercent[] = {100,106,111,128,156};
	const char *qualityName[] = {LANGUAGE_TRANSFORM_808,LANGUAGE_TRANSFORM_809,LANGUAGE_TRANSFORM_810,LANGUAGE_TRANSFORM_811,LANGUAGE_TRANSFORM_812};
	const int NPC[] = {161,162,163,164,165,166};
	const int color[] = {0,3,2,7,8};
	const int itmeNum[] = {1,1,1,1,2};//五色石数目
	const int itemAward = 2818;
	int step = atoi(split[0]);
	int quality = atoi(split[1]);
	if(quality < 0 || quality > 4 || step < 1 || step > 6)
		return;
	int64 exp = strtoll(split[2],NULL,10);
	int64 loseExp = strtoll(split[3],NULL,10);
	int money = atoi(split[6]);
	int loseMoney = atoi(split[7]);
	exp = (int64)(exp*qualityPercent[quality]/100.0 - loseExp);
	exp = exp - exp%1000;
	money = (int)(money*qualityPercent[quality]/100.0 - loseMoney);

	if(npcId == 0)
		npcId = NPC[step-1];
	SNpcPos npcPos = GetNpcScenePos(npcId);
	const char *sceneName = GetSceneName(npcPos.sceneId);
	const char *npcName = GetNpcName(npcId);
	if(sceneName == NULL || npcName == NULL)
		return;

	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_HU_SONG);
	if(isChanged == 0)
		snprintf(buf,sizeof(buf),LANGUAGE_CHY_59,color[quality],qualityName[quality],exp,money,GetItemName(itemAward),itmeNum[quality],sceneName,npcName);
	else
		snprintf(buf,sizeof(buf),LANGUAGE_CHY_60,color[quality],qualityName[quality],exp,money,GetItemName(itemAward),itmeNum[quality],sceneName,npcName);
	msg<<(uint8)op<<(uint16)npcId<<npcPos.sceneId<<npcPos.x<<npcPos.y<<buf;
	sock.SendMsg(pUser->GetSock(),msg);
*/
}

// isChanged 0 不换车 1 换车
void ShowYaYunBiaoChePanel(CUser *pUser,uint8 isChanged,int npcId)
{
	MakeYaYunBiaoCheInfo(pUser,npcId,isChanged,11);
}

void GetYaYunBiaoCheInfo(CUser *pUser,uint8 op)
{
	MakeYaYunBiaoCheInfo(pUser,0,0,op);
}

void SendChangeYaYunBiaoCheSuccess(CUser *pUser,int step)
{
	if(pUser == NULL || (step < 1 || step > 6))
		return;

	const int NPC[] = {161,162,163,164,165,166};
	SNpcPos npcPos = GetNpcScenePos(NPC[step-1]);
	if(npcPos.sceneId == 0)
		return;

	CNetMessage msg;
	msg.SetType(MSG_HU_SONG);
	msg<<(uint8)17<<(uint16)NPC[step-1]<<npcPos.sceneId<<npcPos.x<<npcPos.y;
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void ShowFinishYaYunBiaoChePanel(CUser *pUser)
{
/*
	if(pUser == NULL)
		return;
	const char *pMission = pUser->GetMission(213);
	if(pMission == NULL)
		return;

	char buf[128];
	char *split[10];
	//   0      1       2       3      4           5          6       7
	// step|quality|totolexp|lostexp|index|completeNpcIndex|money|loseMoney
	string str = pMission;
	int num = SplitLine(split,8,(char*)str.c_str());
	if(num < 8)
	{
		cout<<LANGUAGE_TRANSFORM_815<<endl;
		return;
	}

	const int qualityPercent[] = {100,106,111,128,156};
	const char *qualityName[] = {LANGUAGE_TRANSFORM_816,LANGUAGE_TRANSFORM_817,LANGUAGE_TRANSFORM_818,LANGUAGE_TRANSFORM_819,LANGUAGE_TRANSFORM_820};
	const int color[] = {0,3,2,7,8};
	const int itemNum[]={1,1,1,1,2}; //五色石的数目
	const int itemAward = 2818;//五色石
	int quality = atoi(split[1]);
	if(quality < 0 || quality > 4)
		return;
	int64 exp = strtoll(split[2],NULL,10);
	int64 loseExp = strtoll(split[3],NULL,10);
	int money = atoi(split[6]);
	int loseMoney = atoi(split[7]);
	exp = (int64)(exp*qualityPercent[quality]/100.0 - loseExp);
	exp = exp - exp%1000;
	money = (int)(money*qualityPercent[quality]/100.0 - loseMoney);

	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_HU_SONG);
	snprintf(buf,sizeof(buf),LANGUAGE_CHY_61,color[quality],qualityName[quality],exp,money,GetItemName(itemAward),itemNum[quality]);
	msg<<(uint8)16<<buf;
	sock.SendMsg(pUser->GetSock(),msg);
*/
}

void ShowYaYunBiaoChe_CheckChange(CUser *pUser,const char *str)
{
	if(pUser == NULL || str == NULL)
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_HU_SONG);
	msg<<(uint8)15<<str;
	sock.SendMsg(pUser->GetSock(),msg);
}

void ShowYaYunBiaoCheNextTaskPanel(CUser *pUser,int exp,int money,int item_id,int item_num)
{
	if(pUser == NULL)
		return;
	const uint8 limitNum = 10;
	uint8 num = pUser->GetExtData8(88);
	if(num >= limitNum)
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	char buf[128];
	msg.SetType(MSG_HU_SONG);
	snprintf(buf,sizeof(buf),LANGUAGE_CHY_62,exp,money,GetItemName(item_id),item_num,(int)(limitNum-num));
	msg<<(uint8)12<<buf;
	sock.SendMsg(pUser->GetSock(),msg);
}

// 昆仑山数据更新,type=1历险点,2杀敌数,3杀怪数,4杀敌任务(index)完成标识,5杀怪任务(index)完成标志,6更新时间
void KunLunShan_UpdateRoleMsg(CUser *pUser,int type,int value,int index)
{
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_HUODONG_OPTION);
	msg<<(uint16)5<<(uint8)type<<value<<(uint8)index;
	sock.SendMsg(pUser->GetSock(),msg);
}

// 组队昆仑山数据更新,type=1积分,2杀敌数,3杀怪数,4杀敌任务(index)完成标识,5杀怪任务(index)完成标志,6更新时间
void KunLunShanTeam_UpdateRoleMsg(CUser *pUser,int type,int value,int index)
{
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_KUN_LUN_SHAN_TEAM);
	msg<<(uint8)6<<(uint8)type<<value<<(uint8)index;
	sock.SendMsg(pUser->GetSock(),msg);
}

void KunLunShan_SendMonsterReward(CUser *pUser, int type)
{

}

void AddKunLunShanPaiHangScore(CUser *pUser)
{
	if(pUser == NULL)
		return;
	bool isfind = false;
	{
		boost::recursive_mutex::scoped_lock lk(kunLunShan_mutex);
		for(uint16 i=0; i < kunlunshanPaiHang.size();i++)
		{
			if(kunlunshanPaiHang[i].roleId == pUser->GetRoleId())
			{
				kunlunshanPaiHang[i].score = pUser->GetExtData16(31);
				kunlunshanPaiHang[i].continueWinNum = pUser->GetExtData16(43);
				kunlunshanPaiHang[i].zhandouli = pUser->GetZhanDouLi();
				isfind = true;
				break;
			}
		}
		if(!isfind)
		{
			KunLunShanRoleData temp;
			temp.roleId = pUser->GetRoleId();
			temp.roleName = pUser->GetName();
			temp.zhandouli = pUser->GetZhanDouLi();
			temp.score = pUser->GetExtData16(31);
			temp.continueWinNum = pUser->GetExtData16(43);
			kunlunshanPaiHang.push_back(temp);
		}
	}
	if(!isfind)
		SaveDate(pUser, 30, 1);
}

#ifdef KUA_FU
void UpdateKunLunShanTeamServerScore(uint32 zoneId,int srcScore,int newScore)
{
	for(uint32 i=0;i < kunlunshanTeamServerPaiHang.size();i++)
	{
		KunLunShanServerData &serverData = kunlunshanTeamServerPaiHang[i];
		if(serverData.zoneId == zoneId)
		{
			serverData.score += newScore - srcScore;
			return;
		}
	}
	KunLunShanServerData t;
	t.zoneId = zoneId;
	t.score = newScore;
	kunlunshanTeamServerPaiHang.push_back(t);
}
#endif

void AddKunLunShanTeamPaiHangScore(CUser *pUser)
{
#ifdef KUA_FU
	if(pUser == NULL)
		return;
	bool isfind = false;
	{
		int srcScore = 0;
		int newScore = pUser->GetExtData32(292);
		int zoneId = GetServerZone(pUser->GetServerId());
		boost::recursive_mutex::scoped_lock lk(kunLunShanTeam_mutex);
		for(uint16 i=0; i < kunlunshanTeamPaiHang.size();i++)
		{
			if(kunlunshanTeamPaiHang[i].roleId == pUser->GetRoleId())
			{
				srcScore = kunlunshanTeamPaiHang[i].score;
				kunlunshanTeamPaiHang[i].score = newScore;
				kunlunshanTeamPaiHang[i].continueWinNum = pUser->GetExtData16(55);
				kunlunshanTeamPaiHang[i].zhandouli = pUser->GetZhanDouLi();
				isfind = true;
				break;
			}
		}
		if(!isfind)
		{
			KunLunShanRoleData temp;
			temp.roleId = pUser->GetRoleId();
			temp.roleName = pUser->GetName();
			temp.zhandouli = pUser->GetZhanDouLi();
			temp.score = newScore;
			temp.continueWinNum = pUser->GetExtData16(55);
			temp.serverId = pUser->GetServerId();
//			temp.xiang = pUser->GetXiang();
			temp.serverZone = zoneId;
			kunlunshanTeamPaiHang.push_back(temp);
		}
		UpdateKunLunShanTeamServerScore(zoneId,srcScore,newScore);
	}
	if(!isfind)
		SaveDate(pUser, 44, 1);
#endif
}

void SortKunLunShanTeamPaiHang_NoLocked()
{
	SKunLunShanScore scoreSort;
	std::sort(kunlunshanTeamPaiHang.begin(),kunlunshanTeamPaiHang.end(),scoreSort);

	SKunLunShanServerScore serverSort;
	std::sort(kunlunshanTeamServerPaiHang.begin(),kunlunshanTeamServerPaiHang.end(),serverSort);
}

void SortKunLunShanPaiHang_NoLocked()
{
	SKunLunShanScore scoreSort;
	std::sort(kunlunshanPaiHang.begin(),kunlunshanPaiHang.end(),scoreSort);
}

void SendKunLunShanTopUser()
{
	boost::recursive_mutex::scoped_lock lk(kunLunShan_mutex);
	if(kunlunshanPaiHang.empty())
		return;
	if(kunlunshanPaiHang.size() > 1)
		SortKunLunShanPaiHang_NoLocked();
	char buf[256];
	snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_823,ROLE_NAME_COLOR,kunlunshanPaiHang[0].roleName.c_str());
	SysInfoToAllUser(buf);
}

void ShowBaiHuaAwardPanel(CUser *pUser,const char *data,const char *userMsg)
{
	if(pUser == NULL || data == NULL || userMsg == NULL)
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_HUODONG_OPTION);
	msg<<(uint16)11<<data<<userMsg;
	sock.SendMsg(pUser->GetSock(),msg);
}

int64 GetRoleLevelUpExp(int level)
{
	return GetLevelUpExp((uint8)level);
}

void ClearKunLunShanPaiHang()
{
	boost::recursive_mutex::scoped_lock lk(kunLunShan_mutex);
	if(!kunlunshanPaiHang.empty())
		kunlunshanPaiHang.clear();
}

void GetKunLunShanPaiHang(CUser *pUser,CNetMessage &msg)
{
	if(pUser == NULL)
		return;
	boost::recursive_mutex::scoped_lock lk(kunLunShan_mutex);
	if(kunlunshanPaiHang.size() > 1)
		SortKunLunShanPaiHang_NoLocked();
	uint16 paiHangNum = kunlunshanPaiHang.size();
	if(paiHangNum > 30)
		paiHangNum = 30;
	msg<<(uint8)paiHangNum;
	for(uint16 i=0;i < kunlunshanPaiHang.size();i++)
	{
		msg<<(uint32)kunlunshanPaiHang[i].roleId<<kunlunshanPaiHang[i].roleName<<(uint16)kunlunshanPaiHang[i].score;
		paiHangNum--;
		if(paiHangNum == 0)
			break;
	}
	CSocketServer &sock = SingletonSocket::instance();
	sock.SendMsg(pUser->GetSock(),msg);
}

void ClearKunLunShanTeamPaiHang()
{
	boost::recursive_mutex::scoped_lock lk(kunLunShanTeam_mutex);
	kunlunshanTeamPaiHang.clear();
	kunlunshanTeamServerPaiHang.clear();
}

void GetKunLunShanTeamPaiHang(CUser *pUser,CNetMessage &msg)
{
	const uint16 PAI_HANG_NUM_LIMIT = 30;
	const uint16 IN_BANG_LIMIT = 100;	// 上榜名次限制
	if(pUser == NULL)
		return;
	uint32 myId = pUser->GetRoleId();
	boost::recursive_mutex::scoped_lock lk(kunLunShanTeam_mutex);
	if(kunlunshanTeamPaiHang.size() > 1)
		SortKunLunShanTeamPaiHang_NoLocked();
	msg<<pUser->GetExtData32(292);
	uint16 myRank = 0;
	uint16 pos = msg.GetDataLen();
	msg<<myRank;
	uint16 size = kunlunshanTeamPaiHang.size();
	uint16 paiHangNum = 0;
	uint16 numPos = msg.GetDataLen();
	msg<<paiHangNum;
	for(uint16 i=0;i < size && i < PAI_HANG_NUM_LIMIT;i++)
	{
		msg<<(uint16)(i+1)<<(uint32)kunlunshanTeamPaiHang[i].roleId<<kunlunshanTeamPaiHang[i].roleName<<kunlunshanTeamPaiHang[i].score;
		paiHangNum++;
		if(kunlunshanTeamPaiHang[i].roleId == myId)
			myRank = i+1;
	}
	if(myRank == 0 && size > PAI_HANG_NUM_LIMIT)
	{
		for(uint16 i=PAI_HANG_NUM_LIMIT;i < size && i < IN_BANG_LIMIT;i++)
		{
			if(kunlunshanTeamPaiHang[i].roleId == myId)
			{
				myRank = i+1;
				break;
			}
		}
	}
	msg.WriteData(numPos,&paiHangNum,sizeof(paiHangNum));
	if(myRank > 0)
		msg.WriteData(pos,&myRank,sizeof(myRank));

	// 各个服务器数据统计
	uint32 szone = 0;
#ifdef KUA_FU
	szone = GetServerZone(pUser->GetServerId());
#endif
	uint32 serverScore = 0;
	uint16 serverScorePos = msg.GetDataLen();
	msg<<serverScore;
	uint16 serverRank = 0;
	uint16 serverPos = msg.GetDataLen();
	msg<<serverRank;
	size = kunlunshanTeamServerPaiHang.size();
	paiHangNum = 0;
	numPos = msg.GetDataLen();
	msg<<paiHangNum;
	
	char buf[128];
	for(uint16 i=0;i < size && i < PAI_HANG_NUM_LIMIT;i++)
	{
		paiHangNum++;
		KunLunShanServerData &serverData = kunlunshanTeamServerPaiHang[i];
		snprintf(buf,sizeof(buf),"s%u",serverData.zoneId);
		msg<<(uint16)(i+1)<<serverData.zoneId<<buf<<serverData.score;
		if(serverData.zoneId == szone)
		{
			serverRank = i+1;
			serverScore = serverData.score;
		}
	}
	if(paiHangNum > 0)
		msg.WriteData(numPos,&paiHangNum,sizeof(paiHangNum));
	for(uint16 i=PAI_HANG_NUM_LIMIT;i < size;i++)
	{
		KunLunShanServerData &serverData = kunlunshanTeamServerPaiHang[i];
		if(serverData.zoneId == szone)
		{
			serverRank = i+1;
			serverScore = serverData.score;
			break;
		}
	}
	if(serverRank > IN_BANG_LIMIT)
		serverRank = 0;
	if(serverScore > 0)
		msg.WriteData(serverScorePos,&serverScore,sizeof(serverScore));
	if(serverRank > 0)
		msg.WriteData(serverPos,&serverRank,sizeof(serverRank));
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void SendPaiHangJiangLi()
{
	/*boost::recursive_mutex::scoped_lock lk(kunLunShan_mutex);
	if(kunlunshanPaiHang.empty())
		return;

	char buf[256];
	for(uint16 i=0;i < kunlunshanPaiHang.size();i++)
	{
		if(i == 0)
		{
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_824,ROLE_NAME_COLOR,kunlunshanPaiHang[i].roleName.c_str());
			SysInfoToAllUser(buf);
		}

		snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_825, i + 1);
		sAwardManager.SendRankAwardMail(EMRA_ZHU_TIAN_HUAN_JING, kunlunshanPaiHang[i].roleId, i + 1, buf);
	}*/
}

void SendKunLunShanTeamAward()
{
#ifdef KUA_FU
	boost::recursive_mutex::scoped_lock lk(kunLunShanTeam_mutex);
	if(kunlunshanTeamPaiHang.empty())
		return;
	SortKunLunShanTeamPaiHang_NoLocked();

	char buf[512];
	SendLongQuerySqlToAllDB("delete from level_rank where id>30000 and id<=30050");
	AwardManager &awardMgr = SingletonAwardManager::instance();
	int maxScore = kunlunshanTeamPaiHang[0].score;
	for(uint16 i=0;i < kunlunshanTeamPaiHang.size();i++)
	{
		KunLunShanRoleData &data = kunlunshanTeamPaiHang[i];
		int rank = i+1;
		if (maxScore == data.score)
			rank = 1;
		if(rank == 1)
		{
			snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0051,ROLE_NAME_COLOR,data.roleName.c_str(),data.score);
			SysInfoToAllUser(buf);
		}
		snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0049,rank);
		awardMgr.SendRankAwardMail(EMRA_KUN_LUN_SHAN_TEAM, data.roleId, rank, buf);

		if(rank <= 30)
		{
			snprintf(buf,sizeof(buf)-1,"insert into level_rank(id,role_id,role_name,rank,type,data,xiang) values(%d,%u,'%s',%u,601,%d,%d)",
				30000+i+1,data.roleId,data.roleName.c_str(),rank,data.score,data.xiang);
			SendLongQuerySqlToAllDB(buf);
		}

		// 游戏服排行奖励
		int serverRank = 0;
		for(uint32 j=0; j < kunlunshanTeamServerPaiHang.size();j++)
		{
			KunLunShanServerData &serverData = kunlunshanTeamServerPaiHang[j];
			if((uint32)data.serverZone == serverData.zoneId)
			{
				serverRank = j+1;
				break;
			}
		}
		snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0514,serverRank);
		awardMgr.SendRankAwardMail(EMRA_KUN_LUN_SHAN_TEAM_Server, data.roleId, serverRank, buf);
	}
#endif
}

int LingQiJuanXianFight(CUser *pUser)
{
	if((pUser != NULL) && (pUser->GetScene() != NULL))
	{
		COnlineUser &onlineUser = SingletonOnlineUser::instance();
		ShareUserPtr ptr = onlineUser.GetUserByRoleId(pUser->GetRoleId());
		return pUser->GetScene()->LingQiJuanXianFight(ptr);
	}
	else
	{
		return -1;
	}
}

void XunChaShiFight(CUser *pUser,int npcId,int index)
{
	if((pUser != NULL) && (pUser->GetScene() != NULL))
	{
		ShareUserPtr ptr = SingletonOnlineUser::instance().GetUserByRoleId(pUser->GetRoleId());
		pUser->GetScene()->XunChaShiFight(ptr,npcId,index);
		// ===================
		// 更新六界巡查任务
		SingletonCMissionManager::instance().VerifyNewBranchMissionFinish(pUser, EMISS_DC_35); // TODO
	}
}

SharePetPtr CreatePet(int petId,int level,int star,CUser *pUser)
{
	SharePetPtr pet;
	if(petId == 0)
		return pet;
	
	CPetCfgManager &petMgr = SingletonCPetCfgMgr::instance();
	SPetBasicData *pCfg = petMgr.GetPetCfg(petId);
	if(pCfg == NULL)
		return pet;
	SPet *pPet = new SPet;
	pPet->Clear();
	if(pPet == NULL)
		return pet;
	pPet->id = petId;
	if(star < 0)
		pPet->star = pCfg->initStar;
	else
		pPet->star = star;
	pPet->level = level;
	pPet->name = pCfg->name;
	petMgr.InitBasicData(pPet);
	pPet->Init(pUser);
	pPet->hp = pPet->basicAttr.maxHp;
	pet.reset(pPet);
	return pet;
}

bool AddPet(CUser *pUser,int petId,int level,int star,bool isShow,uint8 *pType, uint16 *itemId, uint16 *itemNum)
{
	if(pUser == NULL || petId == 0)
		return false;
	SharePetPtr pet = CreatePet(petId,level,star,pUser);
	if(pet.get() == NULL)
		return false;
	if(pType != NULL)
		*pType = pet->type;
	uint16 toItemId = 0;
	uint16 toItemNum = 0;
	bool res;
	if (itemId != NULL && itemNum != NULL)
	{
		res = pUser->AddPet(pet, itemId, itemNum);
	}
	else
	{
		res = pUser->AddPet(pet, &toItemId, &toItemNum);
	}

	if((itemId != NULL && itemNum != NULL && *itemId == 0 && *itemNum == 0) 
		|| (itemId == NULL && itemNum == NULL && toItemId == 0 && toItemNum == 0))
	{
//		SingletonCRankMgr::instance().UpdateData(CRankMgr::ERT_Pet, pUser->GetRoleId(), pet->zhanDouli, 0, pet->id);
	}
	if(isShow)
	{
		PlayPetDrawCartoon(pUser,petId,pet->level,pet->star,toItemId,toItemNum);
	}
	return res;
}

bool AddPetToMail(SMailData &mdata,int petId,int level,int star)
{
	if(petId == 0)
		return false;
	mdata.AddAward(HDAT_PET, petId, 1);
	return true;
}

// 退出采集副本
void ExitCaiJiFB(CUser* pUser)
{
	if (pUser == NULL)
		return;
	pUser->ExitFuBen(ETLT_MoBaoFB);
}

// 退出登陆副本
void ExitDengLuFB(CUser* pUser)
{
	if (pUser == NULL)
		return;
	pUser->ExitFuBen(ETLT_None);
}

// 是否是擂台赛时间
bool IsLeiTaiSaiTime(int level, bool ignoreItme)
{
	static const int leiTaiLevel[] = {40,50,60,70,80};
	static const int leiTaiWDay[] = {3,4,5,6,7};
	static const int leiTaiLen = sizeof(leiTaiLevel)/sizeof(leiTaiLevel[0]);
	int stage = (level-30)/10 - 1;
	if (stage < 0)
		return false;
	if (stage > (leiTaiLen-1))
		stage = leiTaiLen-1;
	if (GetWeekDay() != (leiTaiWDay[stage]-1))
		return false;
	if ((!ignoreItme) && (GetHour() != LEI_TAI_SAI_TIME))
		return false;
	return true;
}

// 保存玩家输入的字符串
bool SaveUserInput(int roleId, int type, char* input)
{
	if(input == NULL)
		return false;
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if (pDb == NULL)
		return false;
	static char sql[1224];
	memset(sql,0,sizeof(sql));
	snprintf(sql,sizeof(sql),"insert into user_input (type,roleId,data,time) values (%d,%d,'%s',now())",type,roleId,input);
	return pDb->Query(sql);
}

const char *GetRandomSequence(int maxValue)
{
	const int MAX_NUM = 200;
	static string str;
	if(maxValue < 1 || maxValue > MAX_NUM)
		return "";
	
	int seq[MAX_NUM];
	if(RandomSequence(seq,maxValue,maxValue))
	{
		stringstream out;
		str.clear();
		for(int i=0;i < maxValue;i++)
		{
			if(i == 0)
				out<<seq[i];
			else
				out<<"|"<<seq[i];
		}
		str = out.str();
		return str.c_str();
	}
	return "";
}

// 试炼战斗
void ShiLianFight(CUser *pUser,int floor,int xiang)
{
	const int Percent[15] = {-60,-50,-40,-30,-25,-20,-15,-10,-5,0,5,10,15,20,25};
	if(floor < 0 || floor >= (int)(sizeof(Percent)/sizeof(Percent[0])))
		return;
	if(xiang < 1 || xiang > 6)
		return;
	if ((pUser != NULL) && (pUser->GetScene() != NULL))
	{
		CScene *pScene = pUser->GetScene();
		ShareUserPtr ptr = SingletonOnlineUser::instance().GetUserByRoleId(pUser->GetRoleId());
		if (ptr.get() == NULL)
			return;

		int tarRobotId = pUser->GetExtData32(453);
		if (tarRobotId == 0)
		{
			int zhandouli = (int)pUser->GetExtData32(111);	// 前一天最高战斗力
			zhandouli = (int)(zhandouli * (100 + Percent[floor]) / 100.0);

			CGetDbConnect getDb;
			CDatabaseSql *pDb = getDb.GetDbConnect();
			if (pDb == NULL)
				return;
			char sql[512];
			char **row = NULL;
			snprintf(sql, sizeof(sql), "select id from shilian_robot where zhanDouLi>=%d order by zhanDouLi asc limit 1", zhandouli);
			if (!pDb->Query(sql))
				return;
			if ((row = pDb->GetRow()) != NULL)
				tarRobotId = atoi(row[0]);
		}
		ShareUserPtr ptr2;
		CUser *pUser2 = new CUser;
		if(pUser2 == NULL)
			return;
		pUser2->SetSock(-1);
		uint8 robot = 0;
		if (tarRobotId <= 20)
			robot = 1;
		if (!pUser2->CopyUserData(tarRobotId, robot))
		{
			delete pUser2;
			return;
		}

		char name[256];
		snprintf(name, sizeof(name), LANGUAGE_TRANSFORM_777, floor + 1);
		//snprintf(sql,sizeof(sql),"%s%c%c",robotName.c_str(),Random(0,25)+'a',Random(0,25)+'a');
		pUser2->SetName(name);
		ptr2.reset(pUser2);

		ShareFightPtr pFight = SingletonFightManager::instance().CreateFight();
		pFight->SetFightType(CFight::EFTShiLian);
		pFight->SetFightChooseMode();
		pFight->AddUserGroupToFight(ptr);	// 玩家
		pFight->AddUserGroupToFight(ptr2, CFight::EGT_GROUP2);	// 机器人
		pFight->BeginFight(pScene);
		SingletonFightManager::instance().AddFight(pFight);
	}
}

int GetMonsterFindPathX(int monsterId)
{
	uint16 x,y;
	if(GetMonsterFindPathPosById(monsterId,x,y))
		return (int)x;
	else
		return 0;
}

int GetMonsterFindPathY(int monsterId)
{
	uint16 x,y;
	if(GetMonsterFindPathPosById(monsterId,x,y))
		return (int)y;
	else
		return 0;
}

void ZhuoGuiFight(CUser *pUser,int fightType,int monPic,const char *pName,int turn)
{
	if((pUser != NULL) && (pUser->GetScene() != NULL))
	{
		ShareUserPtr ptr = SingletonOnlineUser::instance().GetUserByRoleId(pUser->GetRoleId());
		if(ptr.get() == NULL)
			return;
		string bossName = pName;
		pUser->GetScene()->ZhuoGuiBattle(ptr,fightType,monPic,bossName,turn,monPic);
	}
}

int GetJuanxianMax(CUser *pUser)
{
	return G_VipConfig[pUser->GetVipLevel()].lingqi;
}

int GetArenaLeftNum(CUser *pUser)
{
	return G_VipConfig[pUser->GetVipLevel()].arenatz-pUser->GetExtData16(ED16_72);
}

static bool inLingMoActivity = false;
void SetLingMoActivity(bool val)
{
	inLingMoActivity = val;
}

bool IsInLingMoActivity()
{
	return inLingMoActivity;
}

void HD_DropExchangeItem(CUser *pUser,int hd_id)
{
	SingletonCHDExchangeManager::instance().DropExchangeItem(pUser,hd_id);
}

void HD_DropHDItem(CUser *pUser,int hd_id)
{
	SingletonCHDExchangeManager::instance().DropHDItem(pUser,hd_id);
	//SingletonCHDExchangeManager::instance().DropHDItem_New(pUser,hd_id);
}

float GetWorldExpRatio(uint16 level)
{
	uint32 curTime = GetSysTime();
	uint32 openTime = GetServerOpenTime();
	if(curTime < openTime || curTime - openTime < 24*3600)
		return 0.0f;
	float ratio = 0.0f;
	int worldlevel = GetWorldLevel();
	if((int)level >= WORLD_LEVEL_LIMIT_LV && level < worldlevel)
		ratio = pow(0.45,(1 - (double)worldlevel/(double)level)) - 1;
	if(ratio < 0.0)
		ratio = 0.0f;
	return ratio;
}

int GetWorldExpPercent(uint16 level)
{
	return (int)(GetWorldExpRatio(level) * 100);
}

int GetWorldExp(uint16 level, int exp)
{
	int blessExp = (int)(GetWorldExpRatio(level) * exp);
	return blessExp > 0 ? blessExp : 0;
}

const char *GetAccountName(CUser *pUser)
{
	static string accountName;
	accountName.clear();
	pUser->GetAccountName(accountName);
	return accountName.c_str();
}

// +kf: 跨服服务器
static string ServerType;
static uint32 ServerOpenTime = 0;
const char *GetServerType()
{
	return ServerType.c_str();
}

void SetServerType(string &type)
{
	ServerType = type;
}

void SetServerOpenTime(uint32 time)
{
	ServerOpenTime = time;
}

uint32 GetServerOpenTime()
{
	return ServerOpenTime;
}

void Test_SendPetMail(CUser *pUser,int petId)
{
	if(pUser == NULL)
		return;
	SHuoDongAward data;
	data.award[0] = HDAT_CHENGHAO;
	data.num[0] = petId;
	SendHuoDongAwardMail(pUser->GetRoleId(),pUser->GetLevel(),data,"add title",1);
}

void SetBZ_WIN_BANG_ID(int id)
{
#ifndef KUA_FU
	BZ_WIN_BANG_ID = id;
#endif
}

int GetBZ_WIN_BANG_ID()
{
#ifndef KUA_FU
	return BZ_WIN_BANG_ID;
#else
	return 0;
#endif
}

void SetBZ_WIN_BANG_ID(int idx,int id)
{
#ifdef KUA_FU
	if(idx < 1 || idx > CBangPaiManager::MAX_KFBZ_GROUP)
		return;
	BZ_WIN_BANG_ID[idx-1] = id;
#endif
}

int GetBZ_WIN_BANG_ID(int idx)
{
#ifdef KUA_FU
	if(idx < 1 || idx > CBangPaiManager::MAX_KFBZ_GROUP)
		return 0;
	return BZ_WIN_BANG_ID[idx-1];
#else
	return 0;
#endif
}

void ClearBZ_WIN_BANG_ID()
{
#ifdef KUA_FU
	memset(BZ_WIN_BANG_ID,0,sizeof(BZ_WIN_BANG_ID));
#else
	BZ_WIN_BANG_ID = 0;
#endif
}

int GetMonthCardExpRatio(CUser *pUser)
{
	int ratio = 100;
	uint8 cardValue = pUser->GetMonthCard();
	if((cardValue & 0x2) > 0)
		ratio += 5;
	if((cardValue & 0x4) > 0)
		ratio += 10;
	return ratio;
}

uint32 doRandomByRandomBoxCfg( uint32 box_id )//进行一次随机返回key)
{
	uint32 ret = 0;
	uint32 odds = Random(1,100000);
	std::map<uint32,RandomBoxItem>::iterator map_iter = randombox_cfg.begin();
	for(; map_iter  != randombox_cfg.end() ;++map_iter)
	{
		if( map_iter->second.box_id == box_id )
		{
			if(!ret)
			{
				ret = map_iter->first;
			}
			if( map_iter->second.odds >= odds)
			{
				if(map_iter->second.day_limit)
				{
					std::map<uint32,uint32>::iterator limit_iter = limitSaveMap.find(map_iter->first);
					if( limit_iter != limitSaveMap.end() )
					{
						if( map_iter->second.day_limit <= limit_iter->second )
						{
							continue;
						}
						else
						{
							limit_iter->second = limit_iter->second  + 1;
						}
					}
					else
					{
						limitSaveMap.insert(std::make_pair(map_iter->first,1));
					}
					ret = map_iter->first;
					break;
				}
				else
				{
					ret = map_iter->first;
					break;
				}
			}
		}
	}//end of for
	return ret;
}
uint32 getRandomBoxCfg( uint32 key ,const char* find ) //查找配置某项
{
	uint32 ret = 0;
	if( randombox_stamp +60*60 < (uint32)GetSysTime())
	{
		LoadRandomBoxCfg();
	}
	std::map<uint32,RandomBoxItem>::iterator map_iter = randombox_cfg.find(key);
	if( map_iter != randombox_cfg.end() )
	{
		if(!strcmp(find,"odds"))
		{
			ret = map_iter->second.odds;
		}
		else if( !strcmp(find,"id"))
		{
			ret = map_iter->second.id;
		}
		else if(!strcmp(find,"num"))
		{
			ret = map_iter->second.num; 
		}
		else if(!strcmp(find,"quality"))
		{
			ret = map_iter->second.quality;
		}
		else if(!strcmp(find,"quality_level"))
		{
			ret = map_iter->second.quality_level;
		}
		else if(!strcmp(find,"notice"))
		{
			ret = map_iter->second.notice;
		}
		else if(!strcmp(find,"day_limit"))
		{
			ret = map_iter->second.day_limit;
		}
			
	}//end of for
	return ret;
}
void clearRandomBoxSaveLimit()                                                                                                                   
{
	        limitSaveMap.clear();
} 

void ShowXiuXianPanel(CUser *pUser)
{
	if(pUser == NULL)
		return;
	CNetMessage msg;
	msg.SetType(MSG_XIU_XIAN_LI_LIAN);
	msg<<(uint8)5;
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void EnterWaitingList(int user_id,int npc_id,int index)
{
	SingletonCWaitForFightManager::instance().EnterWaitingList(user_id,npc_id,index);	
}

void StartToFight( CUser *pUser ,int npc_id,int index,int des )
{
	SingletonCWaitForFightManager::instance().StartToFight(pUser,npc_id,index,des);
}

void OpenXtmasBox( CUser *pUser)
{
	SingletonCHDExchangeManager::instance().OpenXtmasBox(pUser);
}

int GetSystemTime()
{
	return GetSysTime();
}

void Binding(CUser *pUser,const char *npcName,const char *name,const char *passwd)
{
	if (pUser == NULL || npcName == NULL || name == NULL || passwd == NULL)
		return;
	
	uint16 nameLen = strlen(name);
	uint16 pwdLen = strlen(passwd);
	if(nameLen < 6 || nameLen > 11)
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0008);
		return;
	}

	if (pwdLen < 6 || pwdLen > 13)
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0015);
		return;
	}

	if(!CheckPass((char *)name))
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0009);
		return;
	}

	if(!CheckPass((char *)passwd))
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0010);
		return;
	}

	uint32 uid = pUser->GetUserId();
	int binding = pUser->GetAccountBinding();

	CDatabaseSql *pDb = GetLoginDb();
	if(pDb == NULL)
		return;

	if (binding == 0)
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0012);
		return;
	}

	uint32 curTime = GetSysTime();
	string oldName;
	pUser->GetAccountName(oldName);

	char sql[255];
	snprintf(sql,sizeof(sql),"update user_info set name = '%s',password = md5('%s'),binding = '%d' where id = '%d'",name,passwd,0,uid);
	if(! pDb->Query(sql))
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0013);
		return;	
	}

	pUser->SetAccountName(name);
	pUser->SetAccountBinding(0);

	snprintf(sql,sizeof(sql),"insert binding_log (`id`,`from_name`,`to_name`,`time`) values ('%d','%s','%s',from_unixtime(%d))",uid,oldName.c_str(),name,curTime);
	pDb->Query(sql);
	
	Dialog(pUser,npcName,LANGUAGE_LLD_0014);
}

bool RecordPhoneInfo(CUser *pUser,const char *npcName,const char *qqNum,const char *phoneNum)
{
	const uint8 PHONE_NUMBER_LENGTH = 11;
	const uint8 QQ_NUMBER_LENGTH_MIX = 5;
	const uint8 QQ_NUMBER_LENGTH_MAX = 12;

	if (strlen(qqNum) < QQ_NUMBER_LENGTH_MIX || strlen(qqNum) > QQ_NUMBER_LENGTH_MAX)
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0064);
		return false;
	}
	
	if (strlen(phoneNum) != PHONE_NUMBER_LENGTH)
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0065);
		return false;
	}
	 
	// 匹配移动、联通、电信手机号
	// 130、131、132、133、134、135、136、137、138、139、
	// 145、147
	// 150、151、152、153、155、156、157、158、159、
	// 170、171、173、176、177、178
	// 180、182、184、185、186、187、188、189
	 
	boost::xpressive::cregex regAll = boost::xpressive::cregex::compile("^1(3\\d|4(5|7)|5([0-3]|[5-9])|7(0|1|3|[6-8])|8\\d)\\d{8}$");
	if (!boost::xpressive::regex_match(phoneNum, regAll))
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0066);
		return false;
	}

	CDatabaseSql *pDb = GetLoginDb();
	if(pDb == NULL)
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0011);
		return false;
	}

	char sql[255];
	snprintf(sql,sizeof(sql),"update user_info set phone_state = '%d',qq_num = '%s',phone_num = '%s' where id = '%d'",1,qqNum,phoneNum,pUser->GetUserId());
	if(! pDb->Query(sql))
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0011);
		return false;	
	}
	pUser->SetRecordPhoneState(1);

	return true;
}

bool IsKuaFuBangZhanWinner(int bangId)
{
#ifdef KUA_FU
	if(bangId <= 0)
		return false;
	for(int i=0;i < CBangPaiManager::MAX_KFBZ_GROUP;i++)
	{
		if(bangId == BZ_WIN_BANG_ID[i])
			return true;
	}
#endif
	return false;
}

void SendQunXianMsg(CUser *pUser)
{
	if(pUser == NULL)
		return;
	pUser->SetExtData32(357,0);
	pUser->SetExtData32(358,0);
	pUser->SetExtData32(359,0);
	pUser->SetExtData32(360,0);
	pUser->SetExtData32(361,0);
	pUser->SetExtData32(362,0);
	pUser->SetExtData8(489,0);
	pUser->SetExtData8(490,0);
	pUser->ClearBitSet(578);

	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_QUNXIANZHENGBA);
	msg<<(uint8)1;
	MakeQunXianMsg(pUser,msg);
}

void MakeQunXianMsg(CUser *pUser,CNetMessage &msg)
{
	if(pUser == NULL)
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CQunXianZhengBaManager &manager = SingletonCQunXianZhengBaManager::instance();
	int resetTimes = pUser->GetExtData8(485);
	if(!manager.IsOpen())
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0099,TIPS_FAILURE_COLOR);
		sock.SendMsg(pUser->GetSock(),msg);
		return;
	}

	uint8 curFloor = pUser->GetExtData8(486);	// 0~60
	int totalStar = pUser->GetExtData16(58);
	int leftStar = pUser->GetExtData16(59);
	uint8 lastFloor = pUser->GetExtData8(487);

	bool canTakeFlag = HaveQunXianAwardCanTake(pUser);
	msg<<PRO_SUCCESS<<leftStar<<totalStar<<curFloor<<lastFloor<<(CQunXianZhengBaManager::MAX_RESET_NUM-resetTimes)<<CQunXianZhengBaManager::MAX_RESET_NUM;
	msg<<(uint8)(canTakeFlag ? 1 : 0);

	SQunXianZhengBaConig floorCF1,floorCF2;
	manager.GetFloorConfig(curFloor+1,floorCF1);
	manager.GetFloorConfig(curFloor+2,floorCF2);

	uint8 num = 0;
	uint16 pos = msg.GetDataLen();
	msg<<num;
	if(floorCF1.type > 0)
	{
		MakeQunXianFloorMsg(pUser,curFloor+1,msg);
		num++;
	}
	if(floorCF2.type > 0)
	{
		MakeQunXianFloorMsg(pUser,curFloor+2,msg);
		num++;
	}
	msg.WriteData(pos,&num,sizeof(num));
	sock.SendMsg(pUser->GetSock(),msg);
}

void MakeQunXianFloorMsg(CUser *pUser,uint8 floor,CNetMessage &msg)
{
	CQunXianZhengBaManager &manager = SingletonCQunXianZhengBaManager::instance();
	uint8 curFloor = pUser->GetExtData8(486);	// 0~60 
	if(curFloor != floor-1 && curFloor != floor-2)
		return;
	SQunXianZhengBaConig cf;
	manager.GetFloorConfig(floor,cf);
	if(cf.type == 0)
		return;
	
	msg<<cf.type;
	if(cf.type == 1)	// role
	{
		uint32 s_roleId = 0;
		uint32 m_roleId = 0;
		uint32 h_roleId = 0;
		if(curFloor+1 == floor)	// 下一层
		{
			s_roleId = pUser->GetExtData32(357);
			m_roleId = pUser->GetExtData32(358);
			h_roleId = pUser->GetExtData32(359);
		}
		else
		{
			s_roleId = pUser->GetExtData32(360);
			m_roleId = pUser->GetExtData32(361);
			h_roleId = pUser->GetExtData32(362);
		}

		if(s_roleId == 0 || m_roleId == 0 || h_roleId == 0)
		{
			manager.GetMatchRole(floor,s_roleId,m_roleId,h_roleId);
			if(curFloor+1 == floor)	// 下一层
			{
				pUser->SetExtData32(357,s_roleId);
				pUser->SetExtData32(358,m_roleId);
				pUser->SetExtData32(359,h_roleId);
			}
			else
			{
				pUser->SetExtData32(360,s_roleId);
				pUser->SetExtData32(361,m_roleId);
				pUser->SetExtData32(362,h_roleId);
			}
		}
		if(s_roleId == 0 || m_roleId == 0 || h_roleId == 0)
			msg<<0;
		else
		{
			SQunXianPowerPaiHang info;
			manager.GetRoleDataById(h_roleId,info);
			if(info.roleId == 0)
				msg<<0;
			else
				msg<<info.roleId<<info.xiang<<info.sex<<info.name<<info.vipLv<<info.weapon;
		}
	}
	else if(cf.type == 2)	// buff
	{
		const string name = "shop";
		const int pic = 1;
		msg<<name<<pic;
	}
	else if(cf.type == 3)	// box
	{
		const string name = "box";
		const int pic = 1;
		msg<<name<<pic;
	}
}

bool AddKuaFuZhuoGuiMiss(CUser *pUser)
{
/*
	const int picId[] = {18,19,22,24,34,36,58};
	const int bossPic[] = {44};
	const char *areaName[] = {LANGUAGE_SSJ_0115,LANGUAGE_SSJ_0116,LANGUAGE_SSJ_0117,LANGUAGE_SSJ_0118,LANGUAGE_SSJ_0119,LANGUAGE_SSJ_0120,LANGUAGE_SSJ_0121,LANGUAGE_SSJ_0122,LANGUAGE_SSJ_0123,LANGUAGE_SSJ_0124,LANGUAGE_SSJ_0125,LANGUAGE_SSJ_0126,LANGUAGE_SSJ_0127,LANGUAGE_SSJ_0128,LANGUAGE_SSJ_0129,LANGUAGE_SSJ_0130,LANGUAGE_SSJ_0131,LANGUAGE_SSJ_0132};
	const char *monsterName[] = {LANGUAGE_SSJ_0133,LANGUAGE_SSJ_0134,LANGUAGE_SSJ_0135,LANGUAGE_SSJ_0136,LANGUAGE_SSJ_0137,LANGUAGE_SSJ_0138,LANGUAGE_SSJ_0139,LANGUAGE_SSJ_0140,LANGUAGE_SSJ_0141,LANGUAGE_SSJ_0142,LANGUAGE_SSJ_0143,LANGUAGE_SSJ_0144,LANGUAGE_SSJ_0145,LANGUAGE_SSJ_0146,LANGUAGE_SSJ_0147};
	const char *bossName[] = {LANGUAGE_SSJ_0148,LANGUAGE_SSJ_0149,LANGUAGE_SSJ_0150,LANGUAGE_SSJ_0151};
	if(pUser == NULL)
		return false;
	if(pUser->GetMission(806) != NULL)
		return false;
	CScene *pScene = pUser->GetScene();
	if(pScene == NULL)
		return false;
	uint16 idx = pUser->GetExtData16(61);
//	uint16 turn = pUser->GetExtData16(60);
	uint16 x = 0;
	uint16 y = 0;
	int picSize = sizeof(picId)/sizeof(picId[0]);
	int pic1 = 0;
	int pic2 = picId[Random(1,picSize)-1];
	int areaSize = sizeof(areaName)/sizeof(areaName[0]);
	int fightType = Random(1,5);
	if(!pScene->GetCanWalkPos(x,y))
		return false;
	char buf[256];
	char name[256];
	if(idx < 9)
	{
		int size = sizeof(monsterName)/sizeof(monsterName[0]);
		pic1 = picId[Random(1,picSize)-1];
		if(pic1 == pic2)
		{
			pic1 = picId[0];
			if(pic1 == pic2)
				pic1 = picId[1];
		}
		snprintf(name,sizeof(name),"%s%s",areaName[Random(1,areaSize)-1],monsterName[Random(1,size)-1]);
	}
	else
	{
		int size = sizeof(bossName)/sizeof(bossName[0]);
		pic1 = bossPic[0];
		snprintf(name,sizeof(name),"%s%s",areaName[Random(1,areaSize)-1],bossName[Random(1,size)-1]);
	}
	if(AddNpcWithInfo(pUser,231,KUA_FU_SCENE_ID,x,y,2,pic1,name) < 0)
		return false;
	SendYinDaoNPCPos(pUser,KUA_FU_SCENE_ID,x,y,231);

	//                 complete|sid|x|y|name|pic1|pic2
	snprintf(buf,sizeof(buf),"0|%u|%u|%u|%s|%d|%d|%d",KUA_FU_SCENE_ID,x,y,name,pic1,pic2,fightType);
	return pUser->AddMission(806,buf);
*/
	return false;
}

void KuaFuZhuoGuiFight(CUser *pUser)
{
	if(pUser == NULL)
		return;
	ShareUserPtr ptr = SingletonOnlineUser::instance().GetUserByRoleId(pUser->GetRoleId());
	if(pUser->GetScene() != NULL)
	{
		pUser->GetScene()->KuaFuZhuoGuiFight(ptr);
	}
}

int GetUnOpenPackageNum(CUser *pUser)
{
	if(pUser == NULL)
		return 0;
	return (CUser::MAX_PACKAGE_NUM2 - pUser->GetMaxPackageNum());
}

bool InHuoDongTime(uint32 huodong_type)
{
	return SingletonCHuoDongAwardManager::instance().InHuoDongTime(huodong_type);
}

bool InHuoDongHour(uint32 huodong_type)
{
	return SingletonCHuoDongAwardManager::instance().InHuoDongHour(huodong_type);
}

// 0:没到指定小时  1:进行中  2:已结束
void HDChouCall(CUser *pUser,const char *npcName,const char  *callbackName)
{
	if (pUser == NULL)
		return;

	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 huodongType = CHuoDongAwardManager::DUOBAO_CHOU;
	uint32 curTime = GetSysTime();
	uint32 curMin = GetSysMinute();
	uint8 state = awardManager.GetChouState(curMin);
	char buff[215];

	if (state == CHuoDongAwardManager::CHOU_NOT_START)
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0078);
		return;
	}

	uint32 costId = 0;
	int costNum = 0;
	uint32 awardId = 0;
	int awardNum = 0;
	string errStr;
	if (!awardManager.GetChouAwardInfo(costId,costNum,awardId,awardNum,errStr))
	{
		Dialog(pUser,npcName,errStr.c_str());
		return;
	}

	if (state == CHuoDongAwardManager::CHOU_START)
	{
		uint32 startHour = 0;
		uint32 endHour = 0;
		awardManager.GetHuoDongHour(huodongType,startHour,endHour);
		snprintf(buff,sizeof(buff),LANGUAGE_LLD_0079,startHour,endHour);
		Dialog(pUser,npcName,buff);
		return;
	}

	string opt;
	if (state == CHuoDongAwardManager::CHOU_DOING)
	{
		int count = awardManager.GetChouCount(curTime / 3600 * 3600,pUser->GetRoleId());
		snprintf(buff,sizeof(buff),LANGUAGE_LLD_0080,GetItemName(awardId),awardNum,GetAwardName(costId).c_str(),costNum,count);
		opt = LANGUAGE_LLD_0084;
	}
	else if (state == CHuoDongAwardManager::CHOU_END)
	{
		string name = awardManager.GetChouWinPlayName(curTime / 3600 * 3600);
		char nameBuff[128] = {0};
		if (name.size() > 0)
			snprintf(nameBuff, sizeof(nameBuff),LANGUAGE_LLD_0082,name.c_str());
		snprintf(buff,sizeof(buff),LANGUAGE_LLD_0081,nameBuff);
	}
	opt = opt + LANGUAGE_LLD_0085;
	opt[opt.size() - 1] = '\0';

	Option(pUser,npcName,buff,opt.c_str());
	pUser->SetCallFun(callbackName);
}


void HDChouBet(CUser *pUser,const char *npcName,uint32 limitCount,const char  *callbackName)
{
	if (pUser == NULL)
		return;

	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 curTime = GetSysTime();
	uint32 curMin = GetSysMinute();
	uint32 myCount = awardManager.GetChouCount(curTime / 3600 * 3600,pUser->GetRoleId());

	uint8 state = awardManager.GetChouState(curMin);
	if (state != CHuoDongAwardManager::CHOU_DOING)
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0090);
		return;
	}
	
	if (myCount >= limitCount)
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0088);
		return;
	}

	uint32 costId = 0;
	int costNum = 0;
	uint32 awardId = 0;
	int awardNum = 0;
	string errStr;
	if (!awardManager.GetChouAwardInfo(costId,costNum,awardId,awardNum,errStr))
	{
		Dialog(pUser,npcName,errStr.c_str());
		return;
	}

	if (GetRoleAwardNum(pUser,costId) < costNum)
	{
		char buff[125];
		snprintf(buff,sizeof(buff),LANGUAGE_LLD_0086,GetAwardName(costId).c_str());
		Dialog(pUser,npcName,buff);
		return;
	}
	
	if (awardManager.HDBetChou(pUser,curTime))
	{
		CostAward(pUser,costId,costNum);

		Option(pUser,npcName,LANGUAGE_LLD_0087,LANGUAGE_LLD_0095);
		pUser->SetCallFun(callbackName);
	}
	else
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0089);
	}
}

void HDChouIntro(CUser *pUser,const char *npcName,uint32 limitCount)
{
	uint32 huodongType = CHuoDongAwardManager::DUOBAO_CHOU;
	uint32 curTime = GetSysTime();
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	string name = awardManager.GetChouWinPlayName(curTime / 3600 * 3600 - 3600);
	int chouMin = CHuoDongAwardManager::CHOU_MIN;

	uint32 costId = 0;
	int costNum = 0;
	uint32 awardId = 0;
	int awardNum = 0;
	string errStr;
	if (!awardManager.GetChouAwardInfo(costId,costNum,awardId,awardNum,errStr))
	{
		Dialog(pUser,npcName,errStr.c_str());
		return;
	}

	uint32 startHour = 0;
	uint32 endHour = 0;
	awardManager.GetHuoDongHour(huodongType,startHour,endHour);

	char nameBuff[128] = {0};
	char buff[512];
	if (name.size() > 0)
		snprintf(nameBuff, sizeof(nameBuff),LANGUAGE_LLD_0092,name.c_str());
	snprintf(buff,sizeof(buff),LANGUAGE_LLD_0091,nameBuff,startHour,endHour,limitCount,chouMin,GetAwardName(costId).c_str(),costNum,GetAwardName(awardId).c_str(),awardNum);

	Dialog(pUser,npcName,buff);
}

void SendMianZhanPaiCD(CUser *pUser)
{

	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_MIANZHANPAI_TIME);
	uint32 curTime = GetSysTime();
	uint32 mianZhanTime = pUser->GetExtData32(365);
	uint32 cdTime = (curTime > mianZhanTime) ? 0 : mianZhanTime - curTime;
	msg<<cdTime;
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

bool HDFindYouYuanRenShow(CUser *pUser,const char *npcName,const char  *callbackName)
{
	if (pUser == NULL)
		return false;

	const uint32 kuizhengGetDataId = 366;
	const uint32 exchangeGetDataId = 367;
	uint32 huodongType = CHuoDongAwardManager::FIND_YOUYUANREN;
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 timeData = awardManager.MakeFindYouYuanRenCurTime();
	uint32 kuizhengTimeData = pUser->GetExtData32(kuizhengGetDataId);
	uint32 exchangeTimeData = pUser->GetExtData32(exchangeGetDataId);
	int curMin = GetMinute();

	if (! (awardManager.InHuoDongTime(huodongType) && awardManager.InHuoDongHour(huodongType) && curMin < CHuoDongAwardManager::YOUYUANREN_TIME))
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0127);
		return false;
	}

	int count = awardManager.GetFindYouYuanRenCount();
	string text;
	string opt;
	SHuoDongAward awardList;
	char buff[512];
	uint32 curHour = GetHour();
	int state = 0;  // 1 : 感谢  2:兑换 3:完成
	if (count < CHuoDongAwardManager::YOUYUANREN_AWARD_RANK && timeData != kuizhengTimeData)
	{
		state = 1;
	}
	else if (state == 0 && timeData != exchangeTimeData)
	{
		state = 2;
	}
	else if (state == 0)
	{
		state = 3;
	}

	if (state == 1)
	{
		awardManager.GetAwardData(huodongType,count + 1,awardList);
		string awardsName = GetAwardsName(awardList.award,awardList.num,SHuoDongAward::AWARD_NUM);
		if (awardsName.size() <= 0)
		{
			Dialog(pUser,npcName,LANGUAGE_LLD_0141);
			return false;
		}

		snprintf(buff,sizeof(buff),LANGUAGE_LLD_0131,awardsName.c_str());
		text = buff;
		opt = LANGUAGE_LLD_0128;
	}
	else if (state == 2)
	{
		HDExchangeInfo exchangeInfo;
		if (!awardManager.GetExchangeInfo(huodongType, curHour, exchangeInfo))
		{
			Dialog(pUser,npcName,LANGUAGE_LLD_0142);
			return false;
		}

		uint32 awardId = 0;
		uint32 awardNum = 0;
		uint32 YB = 0;

		for (int i = 0; i < HDExchangeInfo::MATERIAL_NUM; i++)
		{
			if (awardId == 0 && exchangeInfo.material[i] < HDAT_MONEY)
			{
				awardId = exchangeInfo.material[i];
				awardNum = exchangeInfo.material_num[i];
			}
			else if (YB == 0 && exchangeInfo.material[i] == HDAT_YB)
			{
				YB = exchangeInfo.material_num[i];
			}
		}

		if (awardId == 0 || awardNum == 0 || YB == 0)
		{
			Dialog(pUser,npcName,LANGUAGE_LLD_0144);
			return false;
		}

		string awardsName = GetAwardsName(exchangeInfo.award,exchangeInfo.num,HDExchangeInfo::AWARD_NUM);
		if (awardsName.size() <= 0)
		{
			Dialog(pUser,npcName,LANGUAGE_LLD_0143);
			return false;
		}

		snprintf(buff,sizeof(buff),LANGUAGE_LLD_0132,awardsName.c_str(),GetAwardName(awardId).c_str(),awardNum,YB);
		text = buff;

		opt = LANGUAGE_LLD_0129;
		opt += LANGUAGE_LLD_0130;
	}
	else if (state == 3)
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0149);
		return false;
	}

	opt[opt.size() - 1] = '\0';
	Option(pUser,npcName,text.c_str(),opt.c_str());
	pUser->SetCallFun(callbackName);
	return true;
}

bool HDFindYouYuanRenThank(CUser *pUser,const char *npcName)
{
	if (pUser == NULL)
		return false;

	uint32 huodongType = CHuoDongAwardManager::FIND_YOUYUANREN;
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	int count = awardManager.GetFindYouYuanRenCount();
	const uint32 kuizhengGetDataId = 366;
	uint32 timeData = awardManager.MakeFindYouYuanRenCurTime();
	uint32 kuizhengTimeData = pUser->GetExtData32(kuizhengGetDataId);
	int curMin = GetMinute();

	if (! (awardManager.InHuoDongTime(huodongType) && awardManager.InHuoDongHour(huodongType) && curMin < CHuoDongAwardManager::YOUYUANREN_TIME))
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0127);
		return false;
	}
	
	if (count >= CHuoDongAwardManager::YOUYUANREN_AWARD_RANK)
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0145);
		return false;
	}

	if (kuizhengTimeData == timeData)
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0148);
		return false;
	}

	char buff[512];
	SHuoDongAward awardList;
	awardManager.GetAwardData(huodongType,count + 1,awardList);
	string awardsName = GetAwardsName(awardList.award,awardList.num,SHuoDongAward::AWARD_NUM);
	if (awardsName.size() <= 0)
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0141);
		return false;
	}

	for(uint8 i=0;i < SHuoDongAward::AWARD_NUM;i++)
		AddHuoDongAward(pUser,huodongType,awardList.award[i],awardList.num[i],awardList.petQuality[i],awardList.petQualityLv[i],false);

	snprintf(buff,sizeof(buff),LANGUAGE_LLD_0146,count+1,awardsName.c_str());
	SysInfo(pUser,buff);

	snprintf(buff,sizeof(buff),LANGUAGE_LLD_0147,pUser->GetName(),npcName);
	SysInfoToAllUser(buff);
	
	awardManager.AddFindYouYuanRenCount(1);
	pUser->SetExtData32(kuizhengGetDataId,timeData);
	return true;
}

bool HDFindYouYuanRenExchange(CUser *pUser,const char *npcName,bool isYB)
{
	if (pUser == NULL)
		return false;

	uint32 curHour = GetHour();
	uint32 huodongType = CHuoDongAwardManager::FIND_YOUYUANREN;
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	const uint32 exchangeGetDataId = 367;
	uint32 timeData = awardManager.MakeFindYouYuanRenCurTime();
	uint32 exchangeTimeData = pUser->GetExtData32(exchangeGetDataId);
	HDExchangeInfo exchangeInfo;
	int curMin = GetMinute();

	if (! (awardManager.InHuoDongTime(huodongType) && awardManager.InHuoDongHour(huodongType) && curMin < CHuoDongAwardManager::YOUYUANREN_TIME))
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0127);
		return false;
	}

	if (!awardManager.GetExchangeInfo(huodongType, curHour, exchangeInfo))
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0142);
		return false;
	}

	if (timeData == exchangeTimeData)
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0152);
		return false;
	}

	uint32 awardId = 0;
	uint32 awardNum = 0;
	int YB = 0;
	char buff[512];
	for (int i = 0; i < HDExchangeInfo::MATERIAL_NUM; i++)
	{
		if (awardId == 0 && exchangeInfo.material[i] < HDAT_MONEY)
		{
			awardId = exchangeInfo.material[i];
			awardNum = exchangeInfo.material_num[i];
		}
		else if (YB == 0 && exchangeInfo.material[i] == HDAT_YB)
		{
			YB = exchangeInfo.material_num[i];
		}
	}
		
	if (awardId == 0 || awardNum == 0 || YB == 0)
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0144);
		return false;
	}

	string awardsName = GetAwardsName(exchangeInfo.award,exchangeInfo.num,HDExchangeInfo::AWARD_NUM);
	if (awardsName.size() <= 0)
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0143);
		return false;
	}

	if (isYB)
	{
		if (YB > pUser->GetTongBao())
		{
			Dialog(pUser,npcName,LANGUAGE_LLD_0150);
			return false;
		}

		pUser->AddTongBao(-YB);
		ItemCurrencyLog(pUser->GetRoleId(),0,0,0,YB,pUser->GetTongBao(),YBL_FIND_YOUYUANREN);
	}
	else
	{
		if ((int)awardNum > pUser->GetItemNum(awardId))
		{
			snprintf(buff,sizeof(buff),LANGUAGE_LLD_0151,awardNum,GetAwardName(awardId).c_str());
			Dialog(pUser,npcName,buff);
			return false;
		}

		pUser->DelPackageById(awardId,awardNum);
	}

	for(uint8 i=0;i < HDExchangeInfo::AWARD_NUM;i++)
		AddHuoDongAward(pUser,huodongType,exchangeInfo.award[i],exchangeInfo.num[i],exchangeInfo.petQuality[i],exchangeInfo.petQualityLv[i],false);

	snprintf(buff,sizeof(buff),LANGUAGE_LLD_0133,awardsName.c_str());
	SysInfo(pUser,buff);
	pUser->SetExtData32(exchangeGetDataId,timeData);
	return true;
}

void DelSceneNpc(int mapId,int npcid,int index)
{
	CSceneManager &sceneMgr = SingletonSceneManager::instance();
	CScene *pScene = sceneMgr.FindScene(mapId);
	if (pScene == NULL)
		return;

	CNpcManager &npcManager = SingletonNpcManager::instance();
	SNpcTemplate *pNpc = npcManager.GetNpcTemplate(npcid);
	if (pNpc == NULL)
		return;

	pScene->DelNpc(pNpc->id,index);
}

void ChristmasTreeShow(CUser *pUser,const char *npcName,const char  *callbackName,int costYB)
{
	if (pUser == NULL)
		return;

	const uint32 huodongType = CHuoDongAwardManager::SHENGDAN_FENGSHOU;
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 gongxianDataId = 369;

	if (!(awardManager.InHuoDongTime(huodongType) && (awardManager.GetHuoDongPic(huodongType) == CHuoDongAwardManager::CHRISTMAS_TREE_ID)))
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0127);
		return;
	}

	vector<uint32> awardChangZhangidx;
	vector<SHuoDongAward> awardChangZhangList;
	awardManager.GetAwardIdxList(huodongType,CHuoDongAwardManager::CHRISTMAS_TREE_IDX2_CHENGZHANG,awardChangZhangidx);
	awardManager.GetAwardDataList(huodongType,awardChangZhangidx,awardChangZhangList);
	if (awardChangZhangList.size() <= 0)
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0160);
		return;
	}

	vector<uint32> awardPersonidx;
	vector<SHuoDongAward> awardPersonList;
	awardManager.GetAwardIdxList(huodongType,CHuoDongAwardManager::CHRISTMAS_TREE_IDX2_PERSON,awardPersonidx);
	awardManager.GetAwardDataList(huodongType,awardPersonidx,awardPersonList);
	if (awardPersonList.size() <= 0)
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0161);
		return;
	}

	uint32 curChengZhangZhi = awardManager.GetChristmasChengZhangZhi();
	uint32 chengZhangIdx = 0;
	for (;chengZhangIdx < awardChangZhangList.size();chengZhangIdx++)
	{
		if (awardChangZhangList[chengZhangIdx].needYB > curChengZhangZhi)
			break;
	}
	if (chengZhangIdx >= awardChangZhangList.size())
		chengZhangIdx = awardChangZhangList.size() - 1;

	uint32 curGongXianZhi = pUser->GetExtData32(gongxianDataId);
	uint32 gongxianIdx = 0;
	for (;gongxianIdx < awardPersonList.size();gongxianIdx++)
	{
		if (awardPersonList[gongxianIdx].needYB > curGongXianZhi)
			break;
	}
	if (gongxianIdx >= awardPersonList.size())
		gongxianIdx = awardPersonList.size() - 1;

	string opt = "";
	string text = "";
	char buff[512];

	if (chengZhangIdx >= awardPersonList.size())
	{
		snprintf(buff,sizeof(buff),LANGUAGE_LLD_0170,chengZhangIdx + 1,(int)awardChangZhangList.size()
							,curGongXianZhi,awardPersonList[gongxianIdx].needYB,gongxianIdx + 1,(int)awardPersonList.size());
	}
	else
	{
		snprintf(buff,sizeof(buff),LANGUAGE_LLD_0157,curChengZhangZhi,awardChangZhangList[chengZhangIdx].needYB,chengZhangIdx + 1,(int)awardChangZhangList.size()
						,curGongXianZhi,awardPersonList[gongxianIdx].needYB,gongxianIdx + 1,(int)awardPersonList.size());
	}

	text = buff;

	opt += LANGUAGE_LLD_0162;
	opt += LANGUAGE_LLD_0163;
	opt += LANGUAGE_LLD_0158;
	snprintf(buff,sizeof(buff),LANGUAGE_LLD_0159,costYB);
	opt += buff;
	
	opt[opt.size() - 1] = '\0';
	Option(pUser,npcName,text.c_str(),opt.c_str());
	pUser->SetCallFun(callbackName);
}

void ChristmasTreeBangShow(CUser *pUser,const char *npcName,const char  *callbackName)
{
	if (pUser == NULL)
		return;

	const uint32 huodongType = CHuoDongAwardManager::SHENGDAN_FENGSHOU;
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();

	if (!(awardManager.InHuoDongTime(huodongType) && (awardManager.GetHuoDongPic(huodongType) == CHuoDongAwardManager::CHRISTMAS_TREE_ID)))
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0127);
		return;
	}

	vector<HDPaiHangRecordInfo> info;
	awardManager.GetHDPaiHangRecord(huodongType,info);

	string text = LANGUAGE_LLD_0164;
	string bangStr = "";
	char buff[512];
	for(uint32 i = 0;i < info.size(); i++)
	{
		snprintf(buff,sizeof(buff),LANGUAGE_LLD_0166,i + 1,info[i].role_name.c_str(),info[i].data);
		bangStr += buff;
	}

	text += bangStr;
	string opt = LANGUAGE_LLD_0165;
	opt[opt.size() - 1] = '\0';
	Option(pUser,npcName,text.c_str(),opt.c_str());
	pUser->SetCallFun(callbackName);
}

void GetChristmasTreeGrowAward(CUser *pUser,const char *npcName)
{
	if (pUser == NULL)
		return;

	const uint32 huodongType = CHuoDongAwardManager::SHENGDAN_FENGSHOU;
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 gongxianDataId = 369;
	uint32 awardChengZhangDataId = 370;

	if (!(awardManager.InHuoDongTime(huodongType) && (awardManager.GetHuoDongPic(huodongType) == CHuoDongAwardManager::CHRISTMAS_TREE_ID)))
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0127);
		return;
	}

	vector<uint32> awardChangZhangidx;
	vector<SHuoDongAward> awardChangZhangList;
	awardManager.GetAwardIdxList(huodongType,CHuoDongAwardManager::CHRISTMAS_TREE_IDX2_CHENGZHANG,awardChangZhangidx);
	awardManager.GetAwardDataList(huodongType,awardChangZhangidx,awardChangZhangList);
	if (awardChangZhangList.size() <= 0)
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0160);
		return;
	}

	uint32 curGongXianZhi = pUser->GetExtData32(gongxianDataId);
	if (curGongXianZhi == 0)
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0167);
		return;
	}

	uint32 curChengZhangZhi = awardManager.GetChristmasChengZhangZhi();
	if (curChengZhangZhi < awardChangZhangList[0].needYB)
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0168);
		return;
	}

	uint32 awardChengZhangZhi = pUser->GetExtData32(awardChengZhangDataId);
	if (awardChengZhangZhi >= awardChangZhangList[awardChangZhangList.size() - 1].needYB)
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0169);
		return;
	}

	uint32 myAwardIdx = 0;
	uint32 curAwardIdx = 0;
	for (uint32 i = 0; i < awardChangZhangList.size(); i++)
	{
		if (awardChengZhangZhi >= awardChangZhangList[i].needYB)
			myAwardIdx++;

		if (curChengZhangZhi >= awardChangZhangList[i].needYB)
			curAwardIdx++;
	}

	if (myAwardIdx < curAwardIdx)
		SysInfo(pUser,LANGUAGE_LLD_0172);

	char buff[512];
	for (uint32 i = myAwardIdx;i < curAwardIdx; i++)
	{
		SHuoDongAward award;
		uint32 idx = awardManager.GetAwardIdx(huodongType,CHuoDongAwardManager::CHRISTMAS_TREE_IDX2_CHENGZHANG,i + 1);
		if (idx == 0)
			continue;

		awardManager.GetAwardData(huodongType,idx,award);
		snprintf(buff,sizeof(buff),LANGUAGE_LLD_0171,award.idx3);
		SendHuoDongAwardMail(pUser->GetRoleId(),pUser->GetLevel(),award,buff,huodongType);
	}

	pUser->SetExtData32(awardChengZhangDataId,curChengZhangZhi);

	if (myAwardIdx >= curAwardIdx)
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0179);
	}
}

// zhuangbanType 1:普通档  2:豪华档
void ChristmasTreeZhuangBan(CUser *pUser,const char *npcName,uint32 zhuangbanType)
{
	const uint32 huodongType = CHuoDongAwardManager::SHENGDAN_FENGSHOU;
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	HDExchangeInfo exchangeInfo;
	uint32 gongxianDataId = 369;

	if (!(awardManager.InHuoDongTime(huodongType) && (awardManager.GetHuoDongPic(huodongType) == CHuoDongAwardManager::CHRISTMAS_TREE_ID)))
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0127);
		return;
	}

	vector<uint32> awardPersonidx;
	vector<SHuoDongAward> awardPersonList;
	awardManager.GetAwardIdxList(huodongType,CHuoDongAwardManager::CHRISTMAS_TREE_IDX2_PERSON,awardPersonidx);
	awardManager.GetAwardDataList(huodongType,awardPersonidx,awardPersonList);
	if (awardPersonList.size() <= 0)
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0161);
		return;
	}

	if (!awardManager.GetExchangeInfo(huodongType, zhuangbanType, exchangeInfo))
	{
		Dialog(pUser,npcName,LANGUAGE_LLD_0142);
		return;
	}

	char buff[512];
	for (int i = 0; i < HDExchangeInfo::MATERIAL_NUM; i++)
	{
		if (exchangeInfo.material[i] > 0 && exchangeInfo.material_num[i] > 0)
		{
			if (GetRoleAwardNum(pUser,exchangeInfo.material[i]) < (int)exchangeInfo.material_num[i])
			{
				snprintf(buff,sizeof(buff),LANGUAGE_LLD_0175,GetAwardName(exchangeInfo.material[i]).c_str());
				Dialog(pUser,npcName,buff);
				return;
			}
		}
	}

	uint32 oldIdx = 0;
	uint32 oldGongXianZhi = pUser->GetExtData32(gongxianDataId);
	for (uint32 i = 0; i < awardPersonList.size(); i++)
	{
		if (oldGongXianZhi >= awardPersonList[i].needYB)
			oldIdx++;
	}



	for (int i = 0; i < HDExchangeInfo::MATERIAL_NUM; i++)
	{
		if (exchangeInfo.material[i] > 0 && exchangeInfo.material_num[i] > 0)
		{
			CostAward(pUser,exchangeInfo.material[i],exchangeInfo.material_num[i]);

			if(exchangeInfo.material[i] == HDAT_YB)
				ItemCurrencyLog(pUser->GetRoleId(),0,0,0,exchangeInfo.material_num[i],pUser->GetTongBao(),YBL_CHRISTMASTREE);
		}
	}

	for(uint8 i=0;i < HDExchangeInfo::AWARD_NUM;i++)
		AddHuoDongAward(pUser,huodongType,exchangeInfo.award[i],exchangeInfo.num[i],exchangeInfo.petQuality[i],exchangeInfo.petQualityLv[i]);

	uint32 newIdx = 0;
	uint32 newGongXianZhi = pUser->GetExtData32(gongxianDataId);
	for (uint32 i = 0; i < awardPersonList.size(); i++)
	{
		if (newGongXianZhi >= awardPersonList[i].needYB)
			newIdx++;
	}

	for (uint32 i = oldIdx;i < newIdx; i++)
	{
		SHuoDongAward award;
		uint32 idx = awardManager.GetAwardIdx(huodongType,CHuoDongAwardManager::CHRISTMAS_TREE_IDX2_PERSON,i + 1);
		if (idx == 0)
			continue;

		awardManager.GetAwardData(huodongType,idx,award);
		snprintf(buff,sizeof(buff),LANGUAGE_LLD_0174,award.idx3);
		SendHuoDongAwardMail(pUser->GetRoleId(),pUser->GetLevel(),award,buff,huodongType);
	}
}

//0 未领取，1已领取，2系统错误
int GetDelTestAwardStatus(CUser *pUser)
{
	if (pUser == NULL)
		return 2;
	CDatabaseSql *pDb = GetLoginDb();
	if(pDb == NULL)
		return 2;
	char sql[255];
	snprintf(sql,sizeof(sql),"select del_test_award from user_info where id = %d",pUser->GetUserId());
	if (!pDb->Query(sql))
		return 2;
	if (pDb->GetRowNum() == 0)
		return 2;
	char** row = pDb->GetRow();
	if (row == NULL)
		return 2;

	int getAwardStatus = atoi(row[0]);
	if (getAwardStatus == 1)
		return 1;

	snprintf(sql,sizeof(sql),"update user_info set del_test_award = 1 where id = %d",pUser->GetUserId());
	if (!pDb->Query(sql))
		return 2;
	
	return 0;
}


void ShowShopYaoShiPanel(CUser *pUser)
{
	if (pUser == NULL)
		return;

	SingletonShopManager::instance().ShowYaoShiItems(pUser);
}

const char* GetHuoYueTask(CUser *pUser, int taskMax)
{
	if (pUser == NULL)
		return NULL;

	pUser->SetHuoYueTaskMax(taskMax);

	if (!pUser->HaveBitSet(599))
	{
		pUser->CreateHuoYueTask();
		pUser->SetBitSet(599);
	}

	string taskStr = "";
	int count = 0;
	for (int i = 0; i < HUOYUE_MAX_TASK; i++)
	{
		uint32 taskNum = pUser->GetExtData32(HUOYUE_TASK_DATA_ID[i]) & 0x0000ffff;
		if (count > 0)
			taskStr += "|";

		char buf[10];
		snprintf(buf,sizeof(buf),"%d",taskNum);
		taskStr += buf;
		count++;
	}

	return taskStr.c_str();
}

void ShowHuoYueTaskPanel(CUser *pUser, const char *taskListStr)
{
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 hd_type = CHuoDongAwardManager::HUOYUE_TASK;

	if (pUser == NULL)
		return;

	CNetMessage msg;
	msg.SetType(MSG_TMP_HUODONG);
	msg<<(uint8)(HD_HUOYUE_TASK);
	msg<<(uint8)1;// 显示活跃任务界面

	vector<uint32> idxList;
	awardManager.GetAwardIdxList(hd_type,CHuoDongAwardManager::HUOYUE_TASK_BOX_IDX2,idxList);
	if (idxList.size() == 0)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0246,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}

	vector<HDExchangeInfo> exchangeInfo;
	awardManager.GetExchangeInfo(hd_type,exchangeInfo);
	if (exchangeInfo.size() == 0)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0247,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}

	vector<HuoYueTaskInfo> taskList;
	if (taskListStr != NULL)
	{
		char *p[HUOYUE_MAX_TASK * 7];
		if(! (SplitLine(p,HUOYUE_MAX_TASK * 7,(char *)taskListStr) == HUOYUE_MAX_TASK * 7))
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0245,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}
		for (int i = 0; i < HUOYUE_MAX_TASK; i++)
		{
			struct HuoYueTaskInfo info;
			info.taskName = p[i * 7 + 0];
			info.taskInfo = p[i * 7 + 1];
			info.taskCount= (uint32)atoi(p[i * 7 + 2]);
			info.level = (uint8)atoi(p[i * 7 + 3]);
			info.document = p[i * 7 + 4];
			info.taskNeedCount = (uint32)atoi(p[i * 7 + 5]);
			info.pic = (uint32)atoi(p[i * 7 + 6]);
			taskList.push_back(info);
		}
		pUser->SetHuoYueTaskList(taskList);
	}
	else
	{
		pUser->GetHuoYueTaskList(taskList);
	}

	msg<<PRO_SUCCESS<<HUOYUE_TASK_FLUSH_YB<<GetHuoYueTaskCompleteCount(pUser);
	msg<<(uint8)taskList.size();
	for (uint32 i = 0; i < taskList.size(); i++)
	{
		
		msg<<(uint8)i;
		msg<<GetHuoYueTaskState(pUser->GetExtData32(HUOYUE_TASK_DATA_ID[i]));
		msg<<taskList[i].taskName;
		msg<<taskList[i].taskInfo;
		msg<<taskList[i].taskCount;
		msg<<taskList[i].level;
		msg<<taskList[i].document;
		msg<<taskList[i].taskNeedCount;
		msg<<taskList[i].pic;
	}

	// 宝箱信息
	uint32 getMask = pUser->GetExtData32(420);
	msg<<(uint8)idxList.size();
	for (uint32 i = 0; i < idxList.size(); i++)
	{
		SHuoDongAward award;
		awardManager.GetAwardData(hd_type,idxList[i],award);
		uint8 isGet = ((getMask&(1<<award.needYB)) == 0) ? (uint8)0 : (uint8)1;

		msg<<isGet;
		msg<<award.needYB;

		uint16 pos = msg.GetDataLen();
		uint8 typeNum = 0;
		msg<<typeNum;
		typeNum = MakeAwardMsg(pUser,award,hd_type,msg);
		msg.WriteData(pos,&typeNum,sizeof(typeNum));
	}

	// 兑换信息
	msg<<(uint8)exchangeInfo.size();
	for (uint32 i = 0; i < exchangeInfo.size(); i++)
	{
		MakeExchangeInfoMsg(pUser,exchangeInfo[i],msg,hd_type);
	}

	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

//add by zhudaolong 2017.11.10
void ShowTaoHuaGengPanel(CUser *pUser)
{
	if (pUser == NULL)
		return;
	CNetMessage msg;
	msg.SetType(MSG_TMP_HUODONG);
	msg<<(uint8)(82);
	msg<<(uint8)4;// 显示桃花羹制作界面
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}
uint8 GetYaoQianShuFreeNum(CUser *pUser)
{
	if(pUser == NULL)
		return 0;
	//此处返回的是从vip配置表中读出的摇钱树免费次数
	//因为配置中不为0，所以在pUser为空时返回0，有冲突时需修改	
	return G_VipConfig[pUser->GetVipLevel()].yaoqianshuNum[pUser->GetVipLevel()];
}

static int HDHuanLeShangYan_JiFen = 0;
static int curBaoWeiZhanBossHp = -1;
void LoadHuoDongGlobalData()
{
	LoadHuanLeShengYanJiFen();
	curBaoWeiZhanBossHp = GetGlobalVarible(EGV_BWZ);

}

void SaveHuoDongGlobalData()
{
	SaveHuanLeShengYanJiFen();
	SetGlobalVarible(EGV_BWZ,curBaoWeiZhanBossHp);
}

void LoadHuanLeShengYanJiFen()
{
	HDHuanLeShangYan_JiFen = GetGlobalVarible(EGV_HLSY);
}

void SaveHuanLeShengYanJiFen()
{
	SetGlobalVarible(EGV_HLSY,HDHuanLeShangYan_JiFen);
}

void AddHDHuanLeShengYanJiFen(CUser *pUser,int jifen)
{
	if(pUser == NULL)
		return;
	HDHuanLeShangYan_JiFen += jifen;
}

void SetHDHuanLeShengYanJiFen(int jifen)
{
	HDHuanLeShangYan_JiFen = jifen;
}

bool HDHuanLeShengYanCall(CUser *pUser,const char *npcName)
{
	if(pUser == NULL || npcName == NULL)
		return false;

	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 huodongType1 = CHuoDongAwardManager::ZHOU_NIAN_QING_1;
	uint32 huodongType2 = CHuoDongAwardManager::ZHOU_NIAN_QING_2;
	bool isActive = false;
	string str;
	string choose;
	if(awardManager.InHuoDongTime(huodongType1))
	{
		isActive = true;

		pUser->SetExtData32(437,awardManager.GetHuoDongStartTime(huodongType1));
		
		if(awardManager.InHuoDongLeijiTime(huodongType1))
		{
			char buf[2048];
			char buftmp[256];
			int needJiFen = 0;
			int idx = -1;
			int maxId = 0;
			vector<uint32> awardList;
			awardManager.GetAwardIdxList(huodongType1,0,awardList);
			for(uint32 i=0;i < awardList.size();i++)
			{
				SHuoDongAward award;
				awardManager.GetAwardData(huodongType1,awardList[i],award);
				maxId = (maxId < (int)award.idx) ? award.idx : maxId;
				if(HDHuanLeShangYan_JiFen < (int)award.needYB)
				{
					idx = i;
					needJiFen = award.needYB;
					break;
				}
			}
			
			if(idx == -1)
			{
				snprintf(buftmp,sizeof(buftmp),LANGUAGE_SSJ_0275,maxId);
				snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0273,buftmp);
			}
			else if(idx == 0)
			{
				snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0271,HDHuanLeShangYan_JiFen,needJiFen,LANGUAGE_SSJ_0274);
			}
			else
			{
				snprintf(buftmp,sizeof(buftmp),LANGUAGE_SSJ_0275,idx);
				snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0271,HDHuanLeShangYan_JiFen,needJiFen,buftmp);
			}
			
			Option(pUser,npcName,buf,LANGUAGE_SSJ_0272);
			return true;
		}
		else	// 正式开始
		{
			str = LANGUAGE_SSJ_0276;
			choose = LANGUAGE_SSJ_0277;
		}
	}
	if(awardManager.InHuoDongTime(huodongType2))
	{
		isActive = true;
		if(str.empty())
			str = LANGUAGE_SSJ_0276;
		if(choose.empty())
			choose = LANGUAGE_SSJ_0278;
		else
		{
			choose += "|";
			choose += LANGUAGE_SSJ_0278;
		}
	}
	if(isActive)
	{
		Option(pUser,npcName,str.c_str(),choose.c_str());
		return true;
	}
	else
	{
		return false;
	}
}

const char *GetHuanLeShengYan_DuiHuanInfo()
{
	string info;
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 type = CHuoDongAwardManager::ZHOU_NIAN_QING_1;
	uint32 pic = awardManager.GetHuoDongPic(type);
	vector<GoodsInfo> goodslist;
	awardManager.GetHDBangGoods(pic,goodslist,type);
	for(uint32 i=0;i < goodslist.size();i++)
	{
		if(!info.empty())
			info += "|";
		info += IntToStr(goodslist[i].award) + "|" + IntToStr(goodslist[i].score_give);
	}
	return info.c_str();
}

bool HuanLeShengYan_LiBaoDesc(CUser *pUser,const char *npcName)
{
	if(pUser == NULL || npcName == NULL)
		return false;
	string str = LANGUAGE_SSJ_0279;
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 huodongType = CHuoDongAwardManager::ZHOU_NIAN_QING_1;
	vector<uint32> awardList;
	awardManager.GetAwardIdxList(huodongType,0,awardList);
	for(uint32 i=0;i < awardList.size();i++)
	{
		SHuoDongAward award;
		awardManager.GetAwardData(huodongType,awardList[i],award);
		str += LANGUAGE_SSJ_0280 + IntToStr(i+1) + ": ";
		for(uint32 j=0;j < SHuoDongAward::AWARD_NUM;j++)
		{
			if(award.award[j] > 0 && award.award[j] < 60000)
			{
				if(j > 0)
					str += "; ";
				str += GetItemName(award.award[j]);
				str += "*";
				str += IntToStr(award.num[j]);
			}
		}
		str += "\n";
	}
	Option(pUser,npcName,str.c_str(),LANGUAGE_SSJ_0281);
	return true;
}

void HuanLeShengYan_SendLiBao(CUser *pUser)
{
	if(pUser == NULL)
		return;
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 huodongType = CHuoDongAwardManager::ZHOU_NIAN_QING_1;
	if(!awardManager.InHuoDongTime(huodongType))
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0282,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	if(pUser->HaveBitSet(603))
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0283,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	
	vector<uint32> awardList;
	awardManager.GetAwardIdxList(huodongType,0,awardList);
	int idx = -1;
	for(uint32 i=0;i < awardList.size();i++)
	{
		SHuoDongAward award;
		awardManager.GetAwardData(huodongType,awardList[i],award);
		if(HDHuanLeShangYan_JiFen >= (int)award.needYB)
			idx = i;
		else
			break;
	}
	if(idx == -1)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0285,TIPS_FAILURE_COLOR).c_str());
		return;
	}

	pUser->SetBitSet(603);

	SHuoDongAward award;
	awardManager.GetAwardData(huodongType,awardList[idx],award);
	for(uint32 i=0;i < SHuoDongAward::AWARD_NUM;i++)
		AddHuoDongAward(pUser,huodongType,award.award[i],award.num[i],award.petQuality[i],award.petQualityLv[i]); 
}

void ShowHuanLeShengYan_PaiHang(CUser *pUser)
{
	if(pUser == NULL)
		return;
	CNetMessage msg;
	msg.SetType(MSG_HUODONG_PAIHANG);
	msg<<(uint8)1;

	const int MAX_SHOW_NUM = 10;
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 huodongType = CHuoDongAwardManager::ZHOU_NIAN_QING_1;
	
	vector<SHuoDongAward> awardList;
	vector<HDPaiHangInfo> paihangInfo;
	awardManager.GetHDPaiHangInfo(huodongType,paihangInfo);
	for(uint32 i = 0; i < paihangInfo.size(); i++)
	{
		SHuoDongAward award;
		uint32 idx3 = paihangInfo[i].idx;
		uint32 idx = awardManager.GetAwardIdx(huodongType,1,idx3);
		awardManager.GetAwardData(huodongType,idx,award);
		for(uint32 j=paihangInfo[i].startId;j <= paihangInfo[i].endId;j++)
			awardList.push_back(award);
	}
	uint32 awardSize = awardList.size();
	uint16 num = 0;
	uint16 pos = msg.GetDataLen();
	msg<<num;

	vector<HDPaiHangRecordInfo> recordInfo;
	awardManager.GetHDPaiHangRecord(huodongType,recordInfo);
	for(uint32 i=0;i < recordInfo.size() && i < (uint32)MAX_SHOW_NUM;i++)
	{
		msg<<(i+1)<<recordInfo[i].role_id<<recordInfo[i].role_name<<recordInfo[i].data;

		uint16 idx = (i > awardSize-1) ? (awardSize-1) : i;
		uint16 pos = msg.GetDataLen();
		uint8 typeNum = 0;
		msg<<typeNum;
		typeNum = MakeAwardMsg(pUser,awardList[idx],CHuoDongAwardManager::ZHOU_NIAN_QING_1,msg);
		msg.WriteData(pos,&typeNum,sizeof(typeNum));
		num++;
	}
	msg.WriteData(pos,&num,sizeof(num));
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
	
//	if(awardManager.MakeHLSYPaiHangData(pUser,msg,awardList))
//		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
//	else
//		cout<<"ShowHuanLeShengYan_PaiHang config error !!!"<<endl;
}

void ShowHuanLeShengYan_AwardList(CUser *pUser)
{
	if(pUser == NULL)
		return;
	CNetMessage msg;
	msg.SetType(MSG_HUODONG_PAIHANG);
	msg<<(uint8)2;

	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 huodongType = CHuoDongAwardManager::ZHOU_NIAN_QING_1;
	vector<HDPaiHangInfo> paihangInfo;
	awardManager.GetHDPaiHangInfo(huodongType,paihangInfo);
	msg<<(uint16)paihangInfo.size();
	for (uint32 i = 0; i < paihangInfo.size(); i++)
	{
		SHuoDongAward award;
		msg<<paihangInfo[i].startId<<paihangInfo[i].endId;
		uint32 idx3 = paihangInfo[i].idx;
		uint32 idx = awardManager.GetAwardIdx(huodongType,1,idx3);
		awardManager.GetAwardData(huodongType,idx,award);
		
		uint16 pos = msg.GetDataLen();
		uint8 typeNum = 0;
		msg<<typeNum;
		typeNum = MakeAwardMsg(pUser,award,huodongType,msg);
		msg.WriteData(pos,&typeNum,sizeof(typeNum));
	}
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void UpdateHuanLeShengYan_PaiHangList(CUser *pUser,int jifen)
{
	if(pUser == NULL || jifen == 0)
		return;
	uint32 huodongType = CHuoDongAwardManager::ZHOU_NIAN_QING_1;
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	awardManager.UpdatePaiHang(pUser,huodongType,jifen);
//	awardManager.UpdateHLSY_PaiHangData(pUser->GetRoleId(),pUser->GetName(),jifen);
}

int GetBaoWeiZhanBossCurHp()
{
	return curBaoWeiZhanBossHp;
}

void ReduceBaoWeiZhanBossCurHp(int hp)
{
	if(hp > curBaoWeiZhanBossHp)
		curBaoWeiZhanBossHp = 0;
	else
		curBaoWeiZhanBossHp -= hp;
}

void SetBaoWeiZhanBossCurHp(int hp)
{
	curBaoWeiZhanBossHp = hp;
}

void BaoWeiZhanTimer()
{
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	if(!awardManager.InHuoDongTime(CHuoDongAwardManager::ZHOU_NIAN_QING_2))
	{
		curBaoWeiZhanBossHp = -1;
		return;
	}
	
	int h = GetHour();
	int m = GetMinute();
	if((h == 11 || h == 17) && m >= 55)
	{
		curBaoWeiZhanBossHp = -1;
	}

	static bool addBox = false;
	static bool clearFlag = true;
	static bool showGongGao = true;
	if((h == 12 || h == 18) && m < 3 && showGongGao)
	{
		showGongGao = false;
		SysInfoToAllUser(LANGUAGE_SSJ_0286);
#ifdef KUA_FU
		SysGongGaoToAllServer(LANGUAGE_SSJ_0286);
#endif
	}
	if(h != 12 && h != 18)
	{
		showGongGao = true;
	}
	
	if(h >= 12)
	{
		if(m >= 30 && !addBox && curBaoWeiZhanBossHp == 0)
		{
			addBox = true;
			
			CScene *pScene = SingletonSceneManager::instance().FindScene(70);
			if(pScene != NULL)
			{
				pScene->AddBaoWeiZhanBox();
				SysInfoToAllUser(LANGUAGE_SSJ_0287);
#ifdef KUA_FU
				SysGongGaoToAllServer(LANGUAGE_SSJ_0287);
#endif
			}
		}
	}
	if(m <= 3)
		addBox = false;
	if(h == 0)
	{
		if(m < 5 && clearFlag)
		{
			clearFlag = false;

			CScene *pScene = SingletonSceneManager::instance().FindScene(70);
			if(pScene != NULL)
				pScene->ClearBaoWeiZhanBox();
		}
	}
	else
	{
		clearFlag = true;
	}
}

void BaoWeiZhanFight(CUser *pUser)
{
	if(pUser == NULL || pUser->GetFightId() > 0)
		return;
	if(pUser->GetTeam() > 0 && pUser->GetTeam() != pUser->GetRoleId())
		return;
	ShareUserPtr ptr = SingletonOnlineUser::instance().GetUserByRoleId(pUser->GetRoleId());
	if(pUser->GetScene() != NULL)
	{
		pUser->GetScene()->BaoWeiZhaoFight(ptr);
	}
}

void ShowBangPai_XianZhunGe(CUser *pUser)
{
    const uint8 BP_LEVEL_LIMIT = 2;
	if(pUser == NULL)
		return;
	CScene *pScene = pUser->GetScene();
	if(pScene == NULL)
		return;
	
	CNetMessage msg;
	msg.SetType(MSG_BANGPAI_ZHONGZHI);
	msg<<(uint8)41;
	
	uint32 bangpaiId = pScene->GetId() >> 8;
	CBangPaiManager &manager = SingletonCBangPaiManager::instance();
	CBangPai *pBangPai = manager.FindBangPai(bangpaiId);
	if(pBangPai == NULL)
		return;
	if(bangpaiId != pUser->GetBangPai())
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0288,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}
    if(pBangPai->GetLevel() < BP_LEVEL_LIMIT)
    {
        char buf[512];
        snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0384,(int)BP_LEVEL_LIMIT);
        msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
    }
	msg<<PRO_SUCCESS;
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}


const char *GetCMissionInts(CUser *pUser,int id)
{
	if(pUser == NULL || !pUser->HaveCMission(id))
		return NULL;

	vector<int> ints;
	if(!pUser->GetCMissionInts(id,ints))
		return NULL;
	string res;
	for(uint16 i=0;i < ints.size();i++)
	{
		if(!res.empty())
			res += "|";
		res += IntToStr(ints[i]);
	}
	return res.c_str();
}

const char *GetCMissionStrs(CUser *pUser,int id)
{
	if(pUser == NULL || !pUser->HaveCMission(id))
		return NULL;

	vector<string> strs;
	if(!pUser->GetCMissionStrs(id,strs))
		return NULL;
	string res;
	for(uint16 i=0;i < strs.size();i++)
	{
		if(!res.empty())
			res += "|";
		res += strs[i];
	}
	return res.c_str();
}

void WabaoFight(CUser *pUser)
{
	if ((pUser != NULL) && (pUser->GetScene() != NULL))
	{
		pUser->GetScene()->WabaoFight(pUser);
	}
}



void SetTeamFaBuInfo(CUser *pUser,uint8 type,uint16 minLevel,uint16 maxLevel,uint8 fabu)
{
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(PRO_USER_TEAM);
	msg<<(uint8)20;

	bool fabuSuccess = false;
	uint8 srcType = 0;
	uint16 srcMinLv = 0;
	uint16 srcMaxLv = 0;
	uint32 teamId = 0;
	CScene *pScene = pUser->GetScene();
	if(pScene == NULL)
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CTeamFaBuConfigMgr &mgr = SingletonTeamFaBuCfgMgr::instance();
	if(type > 0 && mgr.GetCfg(type) == NULL)
	{
		msg<<PRO_ERROR<<fabu<<srcType<<srcMinLv<<srcMaxLv<<MakeStringColor(LANGUAGE_SSJ_0400,TIPS_FAILURE_COLOR);
		sock.SendMsg(pUser->GetSock(),msg);
		return;
	}
	teamId = pUser->GetTeam();
	if(teamId == 0)
	{
		msg<<PRO_ERROR<<fabu<<srcType<<srcMinLv<<srcMaxLv<<MakeStringColor(LANGUAGE_TRANSFORM_884,TIPS_FAILURE_COLOR);
		sock.SendMsg(pUser->GetSock(),msg);
		return;
	}
	if(pUser->GetRoleId() != teamId)
	{
		msg<<PRO_ERROR<<fabu<<srcType<<srcMinLv<<srcMaxLv<<MakeStringColor(LANGUAGE_TRANSFORM_885,TIPS_FAILURE_COLOR);
		sock.SendMsg(pUser->GetSock(),msg);
		return;
	}
	CUserTeam *pTeam = pScene->GetTeam(teamId);
	if(pTeam == NULL)
	{
		msg<<PRO_ERROR<<fabu<<srcType<<srcMinLv<<srcMaxLv<<MakeStringColor(LANGUAGE_SSJ_0399,TIPS_FAILURE_COLOR);
		sock.SendMsg(pUser->GetSock(),msg);
		return;
	}

	srcType = pTeam->GetType();
	pTeam->GetLevelInfo(srcMinLv,srcMaxLv);
	if(fabu == 0)	// 取消发布或更新
	{
		if(mgr.FindTeamByType(srcType,teamId))
		{
			mgr.RemoveFaBuTeam(srcType,teamId);
			pTeam->SendTeamFaBuData();
			msg<<PRO_SUCCESS<<fabu<<type<<minLevel<<maxLevel<<MakeStringColor(LANGUAGE_TRANSFORM_887,TIPS_WARNING_COLOR);
		}
		else
		{
			msg<<PRO_SUCCESS<<fabu<<type<<minLevel<<maxLevel<<"";
		}
		pScene->SetTeamFaBuStatus(teamId,false);
		pScene->SetTeamType(teamId,type,minLevel,maxLevel);
		mgr.ChangeTeamInfo(type,teamId,minLevel,maxLevel);
	}
	else	// 发布或更新
	{
		if(GetTeamAllMemNum(pUser) >= MAX_TEAM_MEMBER)
		{
			msg<<PRO_ERROR<<fabu<<srcType<<srcMinLv<<srcMaxLv<<MakeStringColor(LANGUAGE_TRANSFORM_877,TIPS_FAILURE_COLOR);
			sock.SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(srcType == type)
		{
			if(mgr.FindTeamByType(srcType,teamId))	// 已发布更新
			{
				pScene->SetTeamType(teamId,type,minLevel,maxLevel);
				mgr.ChangeTeamInfo(type,teamId,minLevel,maxLevel);
				msg<<PRO_SUCCESS<<fabu<<type<<minLevel<<maxLevel<<MakeStringColor(LANGUAGE_TRANSFORM_879,TIPS_FAILURE_COLOR);
			}
			else	// 未发布
			{
				if(mgr.InsertFaBuList(type,teamId,minLevel,maxLevel))
				{
					pScene->SetTeamFaBuStatus(teamId,true);
					pScene->SetTeamType(teamId,type,minLevel,maxLevel);
					mgr.ChangeTeamInfo(type,teamId,minLevel,maxLevel);
					fabuSuccess = true;
					msg<<PRO_SUCCESS<<fabu<<type<<minLevel<<maxLevel<<MakeStringColor(LANGUAGE_TRANSFORM_879,TIPS_WARNING_COLOR);
				}
				else
				{
					msg<<PRO_ERROR<<fabu<<srcType<<srcMinLv<<srcMaxLv<<MakeStringColor(LANGUAGE_SSJ_0401,TIPS_FAILURE_COLOR);
				}
			}
		}
		else	// 类型切换
		{
			if(mgr.FindTeamByType(srcType,teamId))	// 已发布更新
			{
				mgr.RemoveFaBuTeam(srcType,teamId);
				pTeam->SendTeamFaBuData();
			}
			if(mgr.InsertFaBuList(type,teamId,minLevel,maxLevel))
			{
				pScene->SetTeamFaBuStatus(teamId,true);
				pScene->SetTeamType(teamId,type,minLevel,maxLevel);
				mgr.ChangeTeamInfo(type,teamId,minLevel,maxLevel);
				fabuSuccess = true;
				msg<<PRO_SUCCESS<<fabu<<type<<minLevel<<maxLevel<<MakeStringColor(LANGUAGE_TRANSFORM_879,TIPS_WARNING_COLOR);
			}
			else
			{
				msg<<PRO_ERROR<<fabu<<srcType<<srcMinLv<<srcMaxLv<<MakeStringColor(LANGUAGE_SSJ_0401,TIPS_FAILURE_COLOR);
			}
		}
	}
	sock.SendMsg(pUser->GetSock(),msg);

	if(fabuSuccess)
	{
		pTeam->SendTeamFaBuData();
	}
}

void GetAwardFromLevelAward(CUser *pUser, uint32 awardid, bool isFight/* = false*/)
{
	std::vector<SAwardData> awvec;

	SingletonAwardManager::instance().GetLevelAward(awardid, pUser->GetLevel(), awvec);
	if(awvec.empty()){
		cout<<"GetAwardFromLevelAward not award aid = "<<awardid<<endl;
		return;
	}

	for (size_t i = 0; i < awvec.size(); ++i)
	{
		pUser->AddMaterial(awvec[i], isFight);
	}
	CNetMessage msg;
	msg.SetType(MSG_TREASURE_MAP);
	msg << (uint8)10 << PRO_SUCCESS;
	CSocketServer &sock = SingletonSocket::instance();
	sock.SendMsg(pUser->GetSock(), msg);
}

// 获取转盘
void SendZhuanpanFromLevelAward(CUser *pUser, uint32 awardid, int num)
{
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_TREASURE_MAP);
	msg << (uint8)9;
	std::vector<SAwardData> awvec;
	uint8 idx = SingletonAwardManager::instance().GetAwardPanal(awardid, pUser->GetLevel(), num, awvec);
	if (awvec.size() < idx || awvec.empty())
	{
		msg << PRO_ERROR;
		sock.SendMsg(pUser->GetSock(), msg);
		return;
	}

	msg << PRO_SUCCESS << (uint8)idx << (uint8)awvec.size();
	for (size_t i=0; i<awvec.size(); ++i)
	{
		msg << (uint16)awvec[i].type << awvec[i].num;
	}
	//printf("panal num is %d, award idx %d", (int)awvec.size(), (int)idx);
	sock.SendMsg(pUser->GetSock(), msg);
	pUser->AddMaterial(awvec[idx].type, awvec[idx].num);
}

void SendAwardByDropId(CUser *pUser, int dropId)
{
	std::vector<SAwardData> awvec;
	SingletonAwardManager::instance().GetLevelAward(dropId, pUser->GetLevel(), awvec);
	for (size_t i = 0; i < awvec.size(); ++i)
	{
		pUser->AddMaterial(awvec[i], true, true);
	}
}

void StartCMissionFight(CUser *pUser,int missId,int fightId)
{
	if(pUser == NULL)
		return;
	if(pUser != NULL && pUser->GetScene() != NULL)
		pUser->GetScene()->CMissionFight(pUser,missId,fightId);
}

void UpdateDCMissionComplate(CUser *pUser, int mid, int num/* = 1*/, int cond/* = 0*/)
{
	SingletonCMissionManager::instance().UpdateDCMissionComplate(pUser, mid, num, cond);
}

int GetShiMenExp(CUser *pUser)
{
	if(pUser == NULL)
		return 0;
	return GetHuoDongExpWithType(pUser,9,1.0/10);
}

int GetShiMenMoney(CUser *pUser)
{
	if(pUser == NULL)
		return 0;
	return 750;
}

void GetZhuoGuiExpAndMoney(int times,uint16 level,int &exp,int &money)
{
	if(times <= 10)
	{
		exp = level*2400 + 4800;
		money = 2400;
	}
	else if(times <= 20)
	{
		exp = level*2000 + 4000;
		money = 2000;
	}
	else if(times <= 30)
	{
		exp = level*1600 + 3200;
		money = 1600;
	}
	else if(times <= 40)
	{
		exp = level*1200 + 2400;
		money = 1200;
	}
	else if(times <= 50)
	{
		exp = level*800 + 1600;
		money = 800;
	}
	else
	{
		exp = 0;
		money = 0;
	}
}

int GetDailyBossExp(int idx)
{
	if(idx < 1)
		return 0;
	return (130000 + 6000*(idx - 1));
}


int GetFengShenDoNum(CUser *pUser)
{
	if(pUser == NULL)
		return 0;
	return pUser->GetExtData8(478) + pUser->GetExtData8(479) + pUser->GetExtData8(480) + pUser->GetExtData8(481);
}

int GetFSBossFightNumPerDay(CUser *pUser)
{
	if(pUser == NULL)
		return 0;
	int num = SingletonCFengShenMgr::instance().GetFSFightNum();
	num += G_VipConfig[pUser->GetVipLevel()].fengShenNum * (num/(int)CFengShenMgr::CAN_DO_NUM);
	return num;
}

int GetCMissionAcceptLevel(int missId)
{
	int lv = 10000;
	if(missId < 1)
		return lv;
	SMissionConfig *pMiss = SingletonCMissionManager::instance().GetMissionCfg(missId);
	if(pMiss == NULL)
		return lv;
	lv = pMiss->min_level;
	return lv;
}

int GetFuncOpenLevel(int sysId)
{
	return sSystemOpenCfgMananger.GetFuncOpenLevel(sysId);
}


void GetKuaFuXinMo(CUser *pUser)
{
	uint32 robotId = pUser->GetExtData32(463);
	if (robotId != 0)
		return;
	int percent = 80;
	int idx = pUser->GetExtData8(641);
	if (idx == 4)
		percent += 15;
	uint32 matchPower = pUser->GetExtData32(118) * percent / 100;
	CNetMessage synsMsg;
	synsMsg.SetType(MSG_SERVER_USER_POWER);
	synsMsg << (uint8)4 << pUser->GetRoleId() << matchPower;
	SingletonSocket::instance().SendServerMsg(EST_MATCH, synsMsg);
}

void ShiLianXinMoFight(CUser *pUser)
{
	CScene *pScene = pUser->GetScene();
	ShareUserPtr ptr = SingletonOnlineUser::instance().GetUserByRoleId(pUser->GetRoleId());
	if (ptr.get() == NULL)
		return;

	int tarRobotId = pUser->GetExtData32(463);
	ShareUserPtr ptr2;
	CUser *pUser2 = new CUser;
	if (pUser2 == NULL)
		return;
	pUser2->SetSock(-1);
	uint8 robot = 0;
	if (tarRobotId <= 20)
		robot = 1;
	if (!pUser2->CopyUserData(tarRobotId, robot))
	{
		delete pUser2;
		return;
	}
	char npcName[128];
	snprintf(npcName, sizeof(npcName), LANGUAGE_ZQX_0069, pUser2->GetName());
	pUser2->SetName(npcName);
	pUser2->SetSex(3); // 让客户端作红色显示
	ptr2.reset(pUser2);
	ShareFightPtr pFight = SingletonFightManager::instance().CreateFight();
	pFight->SetFightType(CFight::EFTScript);
	pFight->SetTaskId(0);
	pFight->SetFightChooseMode();
	pFight->AddUserGroupToFight(ptr);	// 玩家
	pFight->AddUserGroupToFight(ptr2, CFight::EGT_GROUP2);	// 机器人
	pFight->BeginFight(pScene);
	SingletonFightManager::instance().AddFight(pFight);
}

void MsgToAllServer(CUser *pUser,const char *msg)
{
#ifdef KUA_FU
	UserMsgToAllServer(pUser,msg);
#endif
}

const char *GetBangPaiRobTime()
{
	return LANGUAGE_SSJ_0522;
}

int CanCreateJZZXJiHuoMa(CUser *pUser)
{
	char sql[256];
	snprintf(sql, sizeof(sql), "select role_id from fanli_jihuoma where role_id = %d", pUser->GetRoleId());
	if (g_LoginDB.GetRowNum() != 0)
		return 1;	// 已经创建了激活码
	return 0;
}

const char* CreateJZZXJiHuoMa(CUser *pUser, int type)
{
	string jihuoma = "";
	char sql[256];
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if (pDb == NULL)
		return "";
	snprintf(sql, sizeof(sql), "select role_id from fanli_jihuoma where role_id = %d and flag = 1", pUser->GetRoleId());
	if (!g_LoginDB.Query(sql))
		return "";
	if (g_LoginDB.GetRowNum() != 0)
	{
		SendSysInfo(pUser, MakeStringColor(LANGUAGE_ZQX_0144, TIPS_FAILURE_COLOR).c_str());
		return "";
	}
	while (true)
	{
		jihuoma = MakeJiHuoMa(type);
		snprintf(sql, sizeof(sql), "select role_id from fanli_jihuoma where jihuoma = '%s'", jihuoma.c_str());
		if (!g_LoginDB.Query(sql))
			return "";
		if (g_LoginDB.GetRowNum() != 0)
			continue;

		break;
	}
	int money = 0;
	snprintf(sql, sizeof(sql), "select sum(money) from cz_complete where state = 0 and is_deal = 1 and role_id = %d", pUser->GetRoleId());
	if (!pDb->Query(sql))
		return "";
	if (pDb->GetRowNum() != 0)
	{
		char **row = pDb->GetRow();
		if (row[0] != NULL)
			money = atoi(row[0]);
	}
	snprintf(sql, sizeof(sql), "insert into fanli_jihuoma (jihuoma, state, type, uid, role_id, role_name, level, money, server_id) values ('%s', %d, %d, %u, %u, '%s', %d, %d, %d) on duplicate key update jihuoma = '%s', type = %d",
		jihuoma.c_str(), 0, type, pUser->GetUserId(), pUser->GetRoleId(), pUser->GetName(), pUser->GetLevel(), money, pUser->GetServerId(), jihuoma.c_str(), type);
	g_LoginDB.Query(sql);
	return jihuoma.c_str();
}

const char* QueryJZZXJiHuoMa(CUser *pUser)
{
	char sql[256];
	snprintf(sql, sizeof(sql), "select jihuoma from fanli_jihuoma where role_id = %d", pUser->GetRoleId());
	if (!g_LoginDB.Query(sql))
		return "";
	if (g_LoginDB.GetRowNum() != 0)
	{
		char **row = g_LoginDB.GetRow();
		return row[0];
	}
	return "";
}

int UseJZZXJiHuoMa(CUser *pUser, const char *mark)
{
/*
	if (strcmp(GetServerType(), "jianzhen") != 0)
	{
		SendSysInfo(pUser, MakeStringColor(LANGUAGE_ZQX_0147, TIPS_FAILURE_COLOR).c_str());
		return 0;
	}
	if (strlen(mark) < 12)
		return 0;
#ifdef KUA_FU
	SendSysInfo(pUser, MakeStringColor(LANGUAGE_ZQX_0143, TIPS_FAILURE_COLOR).c_str());
	return 0;
#endif // KUA_FU
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if (pDb == NULL)
		return 3;
	char sql[256];
	//                                   0        1      2    3       4     5         6     7
	snprintf(sql, sizeof(sql), "select role_id, state, type, money, level, role_name, yb, bd_yb from fanli_jihuoma where jihuoma = '%s'", mark);
	if (!g_LoginDB.Query(sql))
		return 1;
	if (g_LoginDB.GetRowNum() == 0)
	{
		SendSysInfo(pUser, MakeStringColor(LANGUAGE_ZQX_0147, TIPS_FAILURE_COLOR).c_str());
		return 2;
	}
	char **baserow = g_LoginDB.GetRow();
	uint32 roleId = atoi(baserow[0]);
	int state = atoi(baserow[1]);
	int type = atoi(baserow[2]);
	int money = atoi(baserow[3]);
	int level = atoi(baserow[4]);
	int yb = atoi(baserow[6]);
	int bd_yb = atoi(baserow[7]);

	if (mark[0] == 'J' && mark[1] == 'Z')
		type = 1;
	else if (mark[0] == 'W' && mark[1] == 'Z')
		type = 2;
	else
		return 0;
	if (pUser->HaveBitSet(1550))
	{
		SendSysInfo(pUser, MakeStringColor(LANGUAGE_ZQX_0137, TIPS_FAILURE_COLOR).c_str());
		return 0;
	}

	if (pUser->HaveBitSet(1543))
	{
		SendSysInfo(pUser, MakeStringColor(LANGUAGE_ZQX_0138, TIPS_FAILURE_COLOR).c_str());
		return 0;
	}

	if (state == 1)
	{
		SendSysInfo(pUser, MakeStringColor(LANGUAGE_ZQX_0132, TIPS_FAILURE_COLOR).c_str());
		return 0;
	}
	if (type == 1)
	{
		if (pUser->GetServerId() <= 100)
		{
			SendSysInfo(pUser, MakeStringColor(LANGUAGE_ZQX_0145, TIPS_FAILURE_COLOR).c_str());
			return 0;
		}
		if (money > 0)
		{
			SMailData mail;
			mail.bdYB = money * 2;
			mail.YB = money * 10;
			SendSystemMail(pUser->GetRoleId(), LANGUAGE_ZQX_0136, &mail);
			char buf[256];
			snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0139, money * 10, money * 2);
			SendSysInfo(pUser, MakeStringColor(buf, TIPS_WARNING_COLOR).c_str());
			pUser->AddMaterial(HDAT_VIP_EXP, money * 10);
		}
		else
		{
			SendSysInfo(pUser, MakeStringColor(LANGUAGE_ZQX_0134, TIPS_FAILURE_COLOR).c_str());
		}
		SendJZZXLuckBoxMail(pUser->GetRoleId(), level, false);
	}
	else if (type == 2)
	{
		if (pUser->GetServerId() > 100)
		{
			SendSysInfo(pUser, MakeStringColor(LANGUAGE_ZQX_0146, TIPS_FAILURE_COLOR).c_str());
			return 0;
		}
		snprintf(sql, sizeof(sql), "select name from role_info_transfer where id = %d", roleId);
		if (!pDb->Query(sql))
		{
			cout << " select name Error" << endl;
			return -1;
		}
		char ** nameRow = pDb->GetRow();
		if (nameRow == NULL)
		{
			cout << " select name GetRow Error" << endl;
			return -1;
		}
		snprintf(sql, sizeof(sql), "select id from role_info where name = '%s'", nameRow[0]);
		if (!pDb->Query(sql))
		{
			cout << " select id from role_info where name Error" << endl;
			return -1;
		}
		bool needChangeName = pDb->GetRowNum() != 0;

		char **row = NULL;
		char selectSql[1024 * 16];
		//                                               0       1          2      3      4       5          6        7        8         9      10       11            12
		snprintf(selectSql, sizeof(selectSql), "select `id`, `position`, `name`, `sex`, `head`, `xiang`, `map_id`, `x_pos`, `y_pos`, `level`, `exp`, `zhanDouLi`, `petZhanDouLi`,"\
			// 13            14             15           16              17           18         19         20            21          22
			"`mission`, `bossFightStar`, `xiuxian`, `newmarriage`, `petPosJewel`, `xianyuan`, `shenqi`, `kuafu_1vs1`, `qunxian`, `transform`," \
			//   23               24    25     26       27        28         29        30          31         32        33          34
			"`korea_money_gift`, `hp`, `mp`, `tili`, `money`, `currency`, `pk_val`, `daohang`, `qianneng`, `title`, `menpai`, `mp_gongxian`," \
			//   35            36              37                 38             39           40       41      42        43           44
			"`bangpai`, `use_double_end`, `use_double_type`, `script_timer`, `equipment`, `package`, `pet`, `zhenfa`, `petKaiJia`, `mount`," \
			// 45          46               47         48      49      50         51             52             53              54
			"`wing`, `wing_zhandouli`, `find_res`, `bitset`, `hots`, `shop`, `mysteryShop`, `yaoshiShop`, `drop_touchitem`, `save_val`," \
			//   55            56            57             58          59            60            61             62            63         64
			"`save_npc`, `save_monster`, `collect_npc`, `skills`, `chat_channel`, `bank_money`, `bank_item`, `jianyu_time`, `chat_time`, `state`,"\
			//   65           66         67         68           69           70              71              72            73            74           75
			"`kuafu_state`, `admin`, `pk_time`, `open_pack`, `lingshou`, `nextOpenTime`, `script_double`, `save_data`,  `sg_bitset`,  `reg_time`, `login_time`, "\
			//   76              77              78        79          80           81      
			"`clientstring`, `shenhunShop`, `questIds`, `xunbao`, `pet_equip`, `bang_skills` from role_info_transfer where id = %d", roleId);
		if (!pDb->Query(selectSql))
		{
			cout << " select role_info Error" << endl;
			return -1;
		}

		if ((row = pDb->GetRow()) == NULL)
		{
			cout << "Error: select role_info getRow is nil " << endl;
			return -1;
		}
		//                                           0          1       2      3       4        5          6        7        8       9      10             11
		string inertSql = "insert into role_info (`position`, `name`, `sex`, `head`, `xiang`, `map_id`, `x_pos`, `y_pos`, `level`, `exp`, `zhanDouLi`, `petZhanDouLi`,"\
			//   12            13            14             15           16            17       18         19           20            21
			"`mission`, `bossFightStar`, `xiuxian`, `newmarriage`, `petPosJewel`, `xianyuan`, `shenqi`, `kuafu_1vs1`, `qunxian`, `transform`," \
			//    22              23               24    25     26       27        28         29        30          31         32        33
			"`korea_money_gift`, `hp`, `mp`, `tili`, `money`, `currency`, `pk_val`, `daohang`, `qianneng`, `title`, `menpai`, `mp_gongxian`," \
			//   34             35              36              37                 38        39       40       41       42           43
			"`bangpai`, `use_double_end`, `use_double_type`, `script_timer`, `equipment`, `package`, `pet`, `zhenfa`, `petKaiJia`, `mount`," \
			// 44              45          46       47         48      49        50              51             52             53
			"`wing`, `wing_zhandouli`, `find_res`, `bitset`, `hots`, `shop`, `mysteryShop`, `yaoshiShop`, `drop_touchitem`, `save_val`," \
			//   54              55            56           57         58          59             60            61             62            63
			"`save_npc`, `save_monster`, `collect_npc`, `skills`, `chat_channel`, `bank_money`, `bank_item`, `jianyu_time`, `chat_time`, `state`,"\
			//     64         65         66         67          68           69               70              71              72            73          74
			"`kuafu_state`, `admin`, `pk_time`, `open_pack`, `lingshou`, `nextOpenTime`, `script_double`, `save_data`,  `sg_bitset`,  `reg_time`, `login_time`, "\
			//     75             76          77         78          79             80
			"`clientstring`, `shenhunShop`, `questIds`, `xunbao`, `pet_equip`, `bang_skills`) values(";
		for (int i = 1; i < 82; ++i)
		{
			if ((i >= 13 && i <= 23)
				|| i == 32
				|| (i >= 38 && i <= 45)
				|| (i >= 47 && i <= 58)
				|| i == 61
				|| i == 69
				|| (i >= 72 && i <= 73)
				|| (i >= 76 && i <= 80)
				)
			{
				inertSql += "'";
				if (row[i] != NULL)
					inertSql += row[i];
				inertSql += "', ";
			}
			else if (i == 81)
			{
				inertSql += "'";
				if (row[i] != NULL)
					inertSql += row[i];
				inertSql += "')";
			}
			else if (i == 2)
			{
				inertSql += "'";
				inertSql += row[i];
				if (needChangeName)
				{
					inertSql += "@";
				}
				inertSql += "', ";
			}
			else
			{
				if (row[i] != NULL && strlen(row[i]) > 0)
					inertSql += row[i];
				else
					inertSql += '0';
				inertSql += ", ";
			}
		}
		if (!pDb->Query(inertSql.c_str()))
		{
			cout << " insert into role_info Error" << endl;
			return -1;
		}
		uint32 newRoleId = pDb->InsertId();
		snprintf(sql, sizeof(sql), "update user_info%d set role0 = %u, money = money + %d, bd_money = bd_money + %d where id = %u", pUser->GetServerId(), newRoleId, yb, bd_yb, pUser->GetUserId());
		if (!pDb->Query(sql))
		{
			cout << " update user_info Error" << endl;
			return -1;
		}
		SendSysInfo(pUser, MakeStringColor(LANGUAGE_ZQX_0135, TIPS_WARNING_COLOR).c_str());
		SendJZZXLuckBoxMail(newRoleId, level, needChangeName);
	}
	snprintf(sql, sizeof(sql), "update fanli_jihuoma set state = 1, tran_uid = %d, tran_role_id = %d, tran_server_id = %d, tran_time = %d where jihuoma = '%s'",
		pUser->GetUserId(), pUser->GetRoleId(), pUser->GetServerId(), (int)GetSysTime(), mark);
	g_LoginDB.Query(sql);
	pUser->SetBitSet(1550);
*/
	return 0;
}

int	SendJZZXLuckBoxMail(uint32 role_id, int level, bool needChangeName/* = false*/)
{
	int idx = level / 10 - 5;
	if (idx < 0) idx = 0;
	if (idx > 9) idx = 4;
	int dropId = 81160 + idx;
	SMailData mdata;
	sAwardManager.GetLevelAward(dropId, level, mdata.awards);
	
	if (needChangeName)
	{
		mdata.AddAward(2503, 0, 1);
	}
	char buf[256];
	snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0140, level);
	SendSystemMail(role_id, buf, &mdata);
	return 0;
}

const char* SQLFilterForLua(const char *sql)
{
	string str = SQLFilter(sql);
	return str.c_str();
}
