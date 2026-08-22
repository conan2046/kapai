#include "pack_deal.h"
#include "singleton.h"
#include "protocol.h"
#include "online_user.h"
#include "scene_manager.h"
#include "npc_manager.h"
#include "call_script.h"
#include "script_call.h"
#include "main.h"
#include "init.h"
#include "xun_bao_manage.h"
#include <boost/bind.hpp>
#include <boost/format.hpp>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sstream>
#include "pet_equip_manage.h"
#include "chou_ka_manager.h"
#include "blood_fight_manage.h"
#include "user_shop_manage.h"
#include "rank.h"
#include "arena.h"
#include "role_simple_mgr.h"
#include "friend.h"
#include "config_para.h"
#ifdef _DEBUG_CHY
#include "gm_tool.h"
#include "user_spirit.h"
#include "user_guanqia.h"
#endif
extern CMainClass *gpMain;
extern const char *gConfigFile;

extern list<ArenaPaiHangData> arenaPaiHang;
extern boost::recursive_mutex tongTianTa_mutex;
extern vector<uint32> tongTianTaBaZhuData;	// 通天塔霸主ID,12/24/36/48/60
extern uint16 tongTianTaBaZhuFloor[5];
extern boost::recursive_mutex lingQiJuanXian_mutex;	// 灵气捐献
extern int lingQiValue;

extern map<int,int> tianJiangXiangRuiMapSelects; // 天降祥瑞野外宝箱添加
extern int mdCheckSock;
extern int mdCheckIndex;
extern int mdCheckIndexArr[MAX_CON_USER];
extern string mdCheckHost;
extern int mdCheckPort;
extern std::map<uint16,SkillInfoNode> skillInfoListMap;
extern vector<uint32> topBangPai;

static bool RepairLocalRoleNullFields(CDatabaseSql *pDb, uint32 roleId)
{
	if(pDb == NULL || roleId == 0)
		return false;
	static const char *emptyFields[] = {
		"zhenfa", "package", "title", "hots", "bitset", "save_val", "bank_item", "save_data",
		"mount", "wing", "bossFightStar", "sg_bitset", "mysteryShop", "xiuxian", "shenqi",
		"transform", "mission", "clientstring", "shenhunShop", "questIds", "find_res", "xunbao",
		"pet_equip", "bang_skills", "guan_qia", "user_book", "chou_ka", "blood_fight",
		"copyData", "user_spirit", "pet", "korea_money_gift", "kuafu_1vs1", "xianyuan"
	};
	static const char *zeroFields[] = {
		"state", "exp", "money", "qianneng", "chat_channel", "chat_time", "admin", "login_time"
	};
	std::ostringstream sql;
	sql << "update role_info set ";
	bool first = true;
	for(size_t i = 0; i < sizeof(emptyFields) / sizeof(emptyFields[0]); ++i)
	{
		if(!first) sql << ',';
		first = false;
		sql << '`' << emptyFields[i] << "`=ifnull(`" << emptyFields[i] << "`,'')";
	}
	for(size_t i = 0; i < sizeof(zeroFields) / sizeof(zeroFields[0]); ++i)
	{
		sql << ",`" << zeroFields[i] << "`=ifnull(`" << zeroFields[i] << "`,'0')";
	}
	sql << ",`level`=ifnull(`level`,'1'),`kuafu_state`=ifnull(`kuafu_state`,'0') where id=" << roleId;
	return pDb->Query(sql.str().c_str());
}

static bool GetLocalChoiceItemAward(uint16 itemId, uint8 target, int& rewardId, int& rewardNum)
{
	if(target == 0)
		return false;

	if(itemId >= 1111 && itemId <= 1113 && target <= 8)
	{
		rewardId = 4621 + (itemId - 1111) * 8 + target - 1;
		rewardNum = 1;
		return true;
	}

	static const int formationBooks[] = { 2725, 2726, 2727, 2728, 2729, 2730 };
	static const int redHeroFragments[] = { 2404, 2405, 2406, 2418, 2419, 2420, 2421, 2422, 2423 };
	static const int redHeroPair[] = { 2406, 2418 };
	const int *rewards = NULL;
	size_t rewardCount = 0;
	rewardNum = 1;
	if(itemId == 1114)
	{
		rewards = formationBooks;
		rewardCount = sizeof(formationBooks) / sizeof(formationBooks[0]);
	}
	else if(itemId == 1116)
	{
		rewards = redHeroFragments;
		rewardCount = sizeof(redHeroFragments) / sizeof(redHeroFragments[0]);
		rewardNum = 3300;
	}
	else if(itemId == 1120)
	{
		rewards = redHeroPair;
		rewardCount = sizeof(redHeroPair) / sizeof(redHeroPair[0]);
	}
	if(rewards == NULL || target > rewardCount)
		return false;
	rewardId = rewards[target - 1];
	return true;
}

extern vector<SChongZhiData> G_CZ_INFO_A;
extern vector<SChongZhiData> G_CZ_INFO_IOS;
extern vector<SChongZhiData> G_CZ_INFO_RMBSHOP;
extern vector<SChongZhiData> G_CZ_MYCARD;
extern vector<SChongZhiData> G_CZ_INFO_WEIXIN;
extern vector<SChongZhi2OtherAward> G_CZ_TO_OTHER_INFO;
extern boost::recursive_mutex cz_fanli_mutex;//充值返利返物品
extern int GetOnlineUserNum();

#ifdef KUA_FU
static int LongIndex = 0;
static int SockLongIdx[MAX_CON_USER];
static boost::recursive_mutex sockLong_mutex;

void ClearSockLongIdx(int sock)
{
	if(sock < 1)
		return;
	boost::recursive_mutex::scoped_lock lk(sockLong_mutex);
	SockLongIdx[sock] = 0;
}
#endif


static void MakeMoBaiData(uint8 showNum,CNetMessage &msg)
{
	char **row = NULL;
	char sql[256];
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;

	msg.ReWrite();
	msg.SetType(MSG_MOBAI);
	msg<<(uint8)1;
	uint16 pos = msg.GetDataLen();
	uint8 count = 0;
	msg<<count;
	for(uint8 rank=1;rank <= showNum;rank++)
	{
		ArenaPaiHangData data;
		if(!SingletonCArenaManager::instance().GetDataByRank(rank, data))
			continue;
		
		uint8 wingId = 0;
		uint8 zuoqi = 0;
		uint8 shenqi = 0;
		if(data.type == EUT_User)
		{
			ShareUserPtr pU = SingletonOnlineUser::instance().GetUserByRoleId(data.roleId);
			if(pU.get() == NULL)
			{
				snprintf(sql,sizeof(sql),"select wing, mount, shenqi from role_info where id=%u", data.roleId);
				if(pDb->Query(sql) && ((row = pDb->GetRow()) != NULL))
				{
					CUser *pTemp = new CUser;
					pTemp->SetWing(row[0]);
					pTemp->SetMount(row[1]);
					pTemp->LoadNewShenQi(row[2]);
					wingId = pTemp->GetWingId();
					zuoqi = pTemp->GetMountId();
					shenqi = pTemp->GetNewShenQiCarryID();
					delete pTemp;
				}
			}
			else
			{
				wingId = pU->GetWingId();
				zuoqi = pU->GetMountId();
				shenqi = pU->GetNewShenQiCarryID();
			}
		}
		else
		{
			

		}
		
		count++;
		msg<<data.rank<<data.roleId<<data.type;
//		msg<<data.name<<data.level<<data.sex<<wingId<< zuoqi<< shenqi;
	}
	msg.WriteData(pos,&count,sizeof(count));
}



CPackageDeal::CPackageDeal():
	m_socketServer(SingletonSocket::instance())
	,m_onlineUser(SingletonOnlineUser::instance())
	,m_npcManager(SingletonNpcManager::instance())
	,m_sceneManager(SingletonSceneManager::instance())
	,m_bangPaiMgr(SingletonCBangPaiManager::instance())
{
	cout << "[local] CPackageDeal: ctor begin" << endl;
	CDespatchCommand &despatch = SingletonDespatch::instance();
	cout << "[local] CPackageDeal: despatch ready" << endl;

	std::vector<SCommand> cmdFun;
	cmdFun.reserve(192);
	cmdFun.push_back(SCommand{PRO_USER_LOGIN,boost::bind(&CPackageDeal::UserLogin,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_ROLE_NAME_CHECK,boost::bind(&CPackageDeal::RoleNameOption,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_CREATE_ROLE,boost::bind(&CPackageDeal::CreateRole,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_SELECT_ROLE,boost::bind(&CPackageDeal::SelectRole,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_ROLE_PACKAGE,boost::bind(&CPackageDeal::GetPackage,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_ROLE_MOVE,boost::bind(&CPackageDeal::RoleMove,this,_1,_2)});
//		{MSG_CLIENT_JUMP,boost::bind(&CPackageDeal::ClientJump,this,_1,_2)},
//		{MSG_JUMP_POINT,boost::bind(&CPackageDeal::SendJumpPoint,this,_1,_2)},
	cmdFun.push_back(SCommand{PRO_OPEN_INTERACT,boost::bind(&CPackageDeal::OpenNpcInteract,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_INTERACT,boost::bind(&CPackageDeal::NpcInteract,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_IGNORE_DIALOG,boost::bind(&CPackageDeal::IgnoreNpcDialog,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_GET_ITEM_INFO,boost::bind(&CPackageDeal::GetItemInfo,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_USER_TEAM,boost::bind(&CPackageDeal::UserTeamOption,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_PLAYER_INFO,boost::bind(&CPackageDeal::GetPlayerInfo,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_USER_PK,boost::bind(&CPackageDeal::PlayerPk,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_PLYAER_MATCH,boost::bind(&CPackageDeal::PlayerMatch,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_NEAR_PLAYER_LIST,boost::bind(&CPackageDeal::NearPlayerList,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_PET,boost::bind(&CPackageDeal::PetOption,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_TASK_LIST,boost::bind(&CPackageDeal::GetMissionList,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_PET_SKILL,boost::bind(&CPackageDeal::GetPetSkill,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_MSG_CHAT,boost::bind(&CPackageDeal::UserChat,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_OTHER_ITEM_INFO,boost::bind(&CPackageDeal::GetOtherUserItemInfo,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_Friend, boost::bind(&CPackageDeal::FriendOption, this, _1, _2)});
		
	cmdFun.push_back(SCommand{PRO_CHONG_ZHI,boost::bind(&CPackageDeal::ChongZhiOption,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_USE_ITEM,boost::bind(&CPackageDeal::UseSpecialItem,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_ZHEN_FA,boost::bind(&CPackageDeal::ZhenFaOption,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_FINISHED_MISSION,boost::bind(&CPackageDeal::QueryFinishedCMissions,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_QUERY_PET_INFO,boost::bind(&CPackageDeal::QueryUserPetInfo,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_FIND_RESOURCE,boost::bind(&CPackageDeal::FindResourceOption,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_FENGSHEN_SHILIAN,boost::bind(&CPackageDeal::FengShenShiLianOption,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_BANGPAI,boost::bind(&CPackageDeal::BangPai,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_BANG_ZHAN,boost::bind(&CPackageDeal::BangZhanOption,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_BANGPAI_COPY, boost::bind(&CPackageDeal::BangPaiCopyOption, this, _1, _2)});
	cmdFun.push_back(SCommand{PRO_Func_HotPoint, boost::bind(&CPackageDeal::FuncHotPointOption, this, _1, _2)});
	cmdFun.push_back(SCommand{PRO_YAO_LING,boost::bind(&CPackageDeal::YaoLingOption,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_BANGPAI_ZHONGZHI,boost::bind(&CPackageDeal::BangPaiZhongZhi,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_UPDATE_PACK,boost::bind(&CPackageDeal::UpdatePackage,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_JUMP_SCENE,boost::bind(&CPackageDeal::UserJumpOk,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_UPDATE_NPC,boost::bind(&CPackageDeal::GetNpcState,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_SKILL_DESC,boost::bind(&CPackageDeal::QuerySkillDesc,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_SWITCH_CHANNEL,boost::bind(&CPackageDeal::ChatChannel,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_SWITCH_INFO,boost::bind(&CPackageDeal::SwitchInfo,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_OTHER_PET,boost::bind(&CPackageDeal::QueryPetInfo,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_MY_BANG,boost::bind(&CPackageDeal::MyBangPai,this,_1,_2)});
//		{PRO_CHANGE_FACE,boost::bind(&CPackageDeal::ChangeUserFace,this,_1,_2)},
	cmdFun.push_back(SCommand{PRO_ITEM_DESC,boost::bind(&CPackageDeal::ItemDesc,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_CHARGE,boost::bind(&CPackageDeal::Charge,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_AVAILABLE_TASK,boost::bind(&CPackageDeal::AvailableTask,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_SCENE_POS,boost::bind(&CPackageDeal::GetScenePos,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_SPEC_CHAT,boost::bind(&CPackageDeal::SpecChat,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_QUERY_SCENE,boost::bind(&CPackageDeal::QueryScene,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_CLIENT_ITEM_DEF,boost::bind(&CPackageDeal::QueryItem,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_SERVER_HEART_BEAT,boost::bind(&CPackageDeal::HeartBeat,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_GET_TITLE_LIST,boost::bind(&CPackageDeal::GetTitleList,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_TITLE_OPTION,boost::bind(&CPackageDeal::TitleOption,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_CLIENT_LIST_FUQI,boost::bind(&CPackageDeal::FuQi,this,_1,_2)});
//		{MSG_CLIENT_DEL_CHAR,boost::bind(&CPackageDeal::DelRole,this,_1,_2)},
	cmdFun.push_back(SCommand{MSG_MGR,boost::bind(&CPackageDeal::ServerMgr,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_SERVER_XINSHI,boost::bind(&CPackageDeal::XinShi,this,_1,_2)});
	cmdFun.push_back(SCommand{GUANZHAN_ENTER_BATTLE,boost::bind(&CPackageDeal::GuanZhan,this,_1,_2)});
	cmdFun.push_back(SCommand{LEAVE_GUANZHAN,boost::bind(&CPackageDeal::LeaveGuanZhan,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_CLIENT_SAVE_VAL,boost::bind(&CPackageDeal::SetSaveVal,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_CLIENT_GET_SAVE_VAL,boost::bind(&CPackageDeal::GetSaveVal,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_CLIENT_STRING_DATA_OPRATETION,boost::bind(&CPackageDeal::ClientDataOperation,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_HUODONG,boost::bind(&CPackageDeal::SendHuoDongInfo,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_GUAJI,boost::bind(&CPackageDeal::GUAJI,this,_1,_2)});
//		{MSG_CLIENT_LOGOUT,boost::bind(&CPackageDeal::ClientLogOut,this,_1,_2)},
	cmdFun.push_back(SCommand{MSG_ARENA,boost::bind(&CPackageDeal::ArenaOption,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_DOPTION_CALLBACK,boost::bind(&CPackageDeal::DOptionCallBack,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_YINDAO,boost::bind(&CPackageDeal::NPCYinDao,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_XINSHOUYINDAO,boost::bind(&CPackageDeal::XinShouYinDao,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_GOOGLEPLAY,boost::bind(&CPackageDeal::GooglePlayRestult,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_CLIENT_NET_CHECK,boost::bind(&CPackageDeal::ClientNetCheck,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_PLAYER_DETAIL,boost::bind(&CPackageDeal::GetUserDetail,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_CLIENT_CALLBACK_FROM_SHOP,boost::bind(&CPackageDeal::ClientShopReturnCall,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_GET_360_TOKEN,boost::bind(&CPackageDeal::Get360Token,this,_1,_2)});
//		{MSG_CHANGE_PASSWORD,boost::bind(&CPackageDeal::ChangePassword,this,_1,_2)},
	cmdFun.push_back(SCommand{MSG_MOUNT,boost::bind(&CPackageDeal::MountOption,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_WING,boost::bind(&CPackageDeal::WingOption,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_NPC_AUTO_TRANSPORT,boost::bind(&CPackageDeal::NPC_AutoTransport,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_FUBEN_OPTION,boost::bind(&CPackageDeal::FuBenOption,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_HE_CHENG_OPTION,boost::bind(&CPackageDeal::HeChengOption,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_USER_RANK,boost::bind(&CPackageDeal::UserRankOption,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_USER_PACKAGE_ITEM,boost::bind(&CPackageDeal::QueryRolePackageItem,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_WORLD_MAP_TRANSPORT,boost::bind(&CPackageDeal::WorldMapTransport,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_ANSWER_QUESION,boost::bind(&CPackageDeal::AnswerQuestionOption,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_SYNC_TIME,boost::bind(&CPackageDeal::SyncTime,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_HUODONG_OPTION,boost::bind(&CPackageDeal::HuoDongOption,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_OPEN_PACKAGE_OPTION,boost::bind(&CPackageDeal::OpenPackageOption,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_MEET_MONSTER,boost::bind(&CPackageDeal::CanMeetMonsterOption,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_HELP,boost::bind(&CPackageDeal::HelpOption,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_DAILY_ACTIVITY,boost::bind(&CPackageDeal::DailyActivityOption,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_PLAY_ANIMATION,boost::bind(&CPackageDeal::AnimationOption,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_CHUANG_GUAN,boost::bind(&CPackageDeal::ChuangGuanOption,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_XIU_XIAN_LI_LIAN,boost::bind(&CPackageDeal::XiuXianLiLianOption,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_TONG_TIAN_TA,boost::bind(&CPackageDeal::TongTianTa,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_GET_CHARGE_ORDER,boost::bind(&CPackageDeal::GetChargeOrder,this,_1,_2)});
//		{MSG_KUN_LUN_SHAN,boost::bind(&CPackageDeal::KunLunShan_HuoDong,this,_1,_2)},
	cmdFun.push_back(SCommand{MSG_FISH,boost::bind(&CPackageDeal::FishOption,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_OFFLINE_EXP,boost::bind(&CPackageDeal::OfflineExpOption,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_VIP_OPTION,boost::bind(&CPackageDeal::UserVIPOption,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_SHOP,boost::bind(&CPackageDeal::ShopOption,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_TMP_HUODONG,boost::bind(&CPackageDeal::HuoDongTmpOption,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_STAGE_GOAL,boost::bind(&CPackageDeal::StageGoalOption,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_PET_RANDOM_DRAW,boost::bind(&CPackageDeal::PetDraw,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_DailyBoss_TASK,boost::bind(&CPackageDeal::DailyBossOption,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_HU_SONG,boost::bind(&CPackageDeal::HuSongShenShouOption,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_LEI_TAI_SAI,boost::bind(&CPackageDeal::LeiTaiSaiOption,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_CAI_QUAN,boost::bind(&CPackageDeal::CaiQuanOption,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_GONGGAO,boost::bind(&CPackageDeal::QueryGongGao,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_GET_SERVER_ID,boost::bind(&CPackageDeal::GetChongZhiServerId,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_USER_MSG_TO_WORLD,boost::bind(&CPackageDeal::SendUserGongGaoMsg,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_MOBAI,boost::bind(&CPackageDeal::MoBaiOption,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_PET_COPY,boost::bind(&CPackageDeal::PetCopyOption,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_TREASURE_MAP,boost::bind(&CPackageDeal::TreasureMapOption,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_SHI_LIAN,boost::bind(&CPackageDeal::ShiLianOption,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_FEI_XIAN,boost::bind(&CPackageDeal::FeiXianOption,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_QUERY_ROLE_BY_NAME,boost::bind(&CPackageDeal::FindRoleByNameId,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_GET_WORLD_LEVEL,boost::bind(&CPackageDeal::SendWorldLevel,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_TASK_TRACK,boost::bind(&CPackageDeal::QueryTaskTrack,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_SERVER_RANK,boost::bind(&CPackageDeal::ServerRank,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_SERVER_TONGTIANTA,boost::bind(&CPackageDeal::ServerTongTianTa,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_SERVER_SERVER_XINSHI,boost::bind(&CPackageDeal::ServerXinShi,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_SERVER_ARENA,boost::bind(&CPackageDeal::ServerArena,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_SERVER_ROLE_NAME,boost::bind(&CPackageDeal::ServerRoleName,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_SERVER_QUERY_ONLINE_NUM,boost::bind(&CPackageDeal::ServerQueryOnlineNum,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_STOP_PROGRESSBAR,boost::bind(&CPackageDeal::ServerStopProgressBar,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_XIANYUAN,boost::bind(&CPackageDeal::ServerXianYuan,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_JINGJIE,boost::bind(&CPackageDeal::JingJieOption,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_NEW_SHENQI,boost::bind(&CPackageDeal::ServerNewShenQi,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_TRANSFORM,boost::bind(&CPackageDeal::ServerTransFormOption,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_WEIXIN_SHARE_REWARD,boost::bind(&CPackageDeal::SendWeiXinReward,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_IGNORE_QIECUO,boost::bind(&CPackageDeal::ServerIgnoreQieCuo,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_IGNORE_FUNC,boost::bind(&CPackageDeal::ServerIgnoreFunc,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_MIANZHANPAI_TIME,boost::bind(&CPackageDeal::GetMianZhanPaiCD,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_JIAOYI_HANG,boost::bind(&CPackageDeal::ServerJiaoYiHang,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_PK_NOTICE,boost::bind(&CPackageDeal::PK_Notice_Option,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_REAL_NAME_REG,boost::bind(&CPackageDeal::RealNameReg_Option,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_FLOWER,boost::bind(&CPackageDeal::FlowerOption,this,_1,_2)});
	cmdFun.push_back(SCommand{PRO_SYSTEM_INFO,boost::bind(&CPackageDeal::SysGongGaoOption,this,_1,_2)});
	cmdFun.push_back(SCommand{ MSG_SHENJIE_MIJING,boost::bind(&CPackageDeal::ShenJieMiJingOption,this,_1,_2) });

#ifdef KUA_FU
	cmdFun.push_back(SCommand{MSG_KUN_LUN_SHAN_TEAM,boost::bind(&CPackageDeal::KunLunShanTeamOption,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_KF_LOGIN,boost::bind(&CPackageDeal::KuaFuLoginRet,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_SERVER_KF_BANG_PAI,boost::bind(&CPackageDeal::KuaFu_QueryBangPaiRet,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_KUA_FU_1V1,boost::bind(&CPackageDeal::KuaFu_1VS1_Option,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_SERVER_KF_BANGZHAN_INFO,boost::bind(&CPackageDeal::KuaFu_BangZhan_Option,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_QUNXIANZHENGBA,boost::bind(&CPackageDeal::QunXianZhengBaOption,this,_1,_2)});
#else
	cmdFun.push_back(SCommand{MSG_CHONGZHI_TO_OTHER,boost::bind(&CPackageDeal::ChongZhiToOtherOption,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_SERVER_KF_BANG_PAI,boost::bind(&CPackageDeal::KuaFu_QueryBangPai,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_QUERY_KF_STATE,boost::bind(&CPackageDeal::QueryKuaFuState,this,_1,_2)});
#endif
	cmdFun.push_back(SCommand{MSG_KOREA_MONEY_GIFT,boost::bind(&CPackageDeal::ServerHuoDongMoneyGiftBag,this,_1,_2) });
	cmdFun.push_back(SCommand{MSG_CLIENT_GETMISSIONAWARD,boost::bind(&CPackageDeal::GetMissonAward,this,_1,_2) });
	cmdFun.push_back(SCommand{MSG_SERVER_USER_POWER,boost::bind(&CPackageDeal::MatchResult,this,_1,_2) });
	cmdFun.push_back(SCommand{PET_EQUIP_OPERATE,boost::bind(&CPackageDeal::DealPetEquipOperate,this,_1,_2) });
	cmdFun.push_back(SCommand{MSG_GUANQIA,boost::bind(&CPackageDeal::DealGuanQia,this,_1,_2)});
	cmdFun.push_back(SCommand{MSG_SPIRIT,boost::bind(&CPackageDeal::DealSpirit,this,_1,_2)});
	cmdFun.push_back(SCommand{ MSG_HERO_BOOK,boost::bind(&CPackageDeal::DealHeroBook,this,_1,_2) });
	cmdFun.push_back(SCommand{ MSG_BLOOD_FIGHT,boost::bind(&CPackageDeal::DealBloodFight,this,_1,_2) });
	cmdFun.push_back(SCommand{ MSG_YOU_LI,boost::bind(&CPackageDeal::DealYouLi,this,_1,_2) });

	cmdFun.push_back(SCommand{MSG_SERVER_SYSINFO,boost::bind(&CPackageDeal::RecvServerSysInfo,this,_1,_2)});

//		{PRO_CLIENT_TEST,boost::bind(&CPackageDeal::ClientTestOption,this,_1,_2)},	// 测试接口，不开放
	m_socketServer.ObserveConnectClose(boost::bind(&CPackageDeal::OnSockClose,this,_1));
	cout << "[local] CPackageDeal: add command deal count=" << cmdFun.size() << endl;
	despatch.AddCommandDeal(cmdFun.data(), cmdFun.size());

	cout << "[local] CPackageDeal: CheckBangPaiId" << endl;
	CheckBangPaiId();
	cout << "[local] CPackageDeal: BangPaiMgr.Init" << endl;
	if(!m_bangPaiMgr.Init())
	{
		exit(0);
	}
	cout << "[local] CPackageDeal: BangPaiMgr.Init done" << endl;

	string user = gyu::util::CIniFile::GetValue("username","login_db",gConfigFile);
	string password = gyu::util::CIniFile::GetValue("password","login_db",gConfigFile);
	string host = gyu::util::CIniFile::GetValue("host","login_db",gConfigFile);
	string db = gyu::util::CIniFile::GetValue("dbname","login_db",gConfigFile);
	string port = gyu::util::CIniFile::GetValue("port","login_db",gConfigFile);
	string localTest = gyu::util::CIniFile::GetValue("local_test","server",gConfigFile);
	if(localTest != "1" && !m_loginDb.Connect(user.c_str(),password.c_str(),host.c_str(),
				db.c_str(),atoi(port.c_str())))
	{
		cout<<"connect login db error"<<endl;
		exit(0);
	}
	cout << "[local] CPackageDeal: GetHuoDongConfig" << endl;
	GetHuoDongConfig();
	cout << "[local] CPackageDeal: GetDengJiLiBaoInfo" << endl;
	GetDengJiLiBaoInfo();
	cout << "[local] CPackageDeal: ctor done" << endl;
}

void CPackageDeal::GetDengJiLiBaoInfo()
{
	char sql[512];
	char **row = NULL;
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
	//                                0  1   2        3    4     5    6      7
	snprintf(sql,sizeof(sql),"select id,level,goods1,num1,value1, goods2,num2,value2,goods3,num3,value3 from dengjilibao order by id asc");
	if(!pDb->Query(sql))
		return;
	while((row = pDb->GetRow()) != NULL)
	{
		int pos = 0;
		struct DengJiLiBaoInfo libao;
		libao.id = uint8(atoi(row[pos++]) - 1);
		libao.level = uint16(atoi(row[pos++]));
		for (uint8 i = 0; i < sizeof(libao.goods)/sizeof(libao.goods[0]); i++)
		{
			libao.goods[i][0] = uint32(atoi(row[pos++]));
			libao.goods[i][1] = uint32(atoi(row[pos++]));
			libao.goods[i][2] = uint32(atoi(row[pos++]));
		}
		
		m_dengJiLiBao.push_back(libao);
	}
}


void CPackageDeal::GetExitHuoDongConfig()
{
	FILE *file = NULL;
	file = fopen(EXIT_HUODONG_FILE,"r");
	if(file == NULL)
		return;
	const int num = 11;
	char buf[512];
	char *ptime = NULL;
	int len;
	while(fgets(buf,sizeof(buf)-1,file))
	{
		ExitHuoDongInfo temp;
		char *p[num];
		char *q = buf;
		int n;
		len = strlen(buf);
		if(buf[len-1] == '\n')	buf[len-1] = '\0';
		if(buf[len-2] == '\r')	buf[len-2] = '\0';
		while(isspace(*q))
			q++;
		if(*q == 0)
			return;
		if(*q == '#')
			continue;
		n = SplitLine(p,num,buf);
		if(n < num)
			continue;
		temp.taskname = p[0];
		temp.taskcontect = p[1];
		temp.time = p[2];
		char *t = NULL;
		if((ptime = strpbrk(p[2],":-")) == NULL)
			continue;
		*ptime = '\0';
		if(*(ptime-2) >= '0' && *(ptime-2) <= '9')
			temp.min_time = atoi(ptime-2);
		else
			continue;
		t = ptime+1;
		if((ptime = strpbrk(t,":-")) == NULL)
			continue;
		*ptime = '\0';
		temp.min_time = temp.min_time*100 + atoi(t);
		t = ptime+1;
		if((ptime = strpbrk(t,":-")) == NULL)
			continue;
		*ptime = '\0';
		temp.max_time = atoi(t);
		t = ptime+1;
		temp.max_time = temp.max_time*100 + atoi(t);
		temp.NPCname = p[3];
		temp.taskaward = p[4];
		temp.mapid = (short)atoi(p[5]);
		temp.x = atoi(p[6]);
		temp.y = atoi(p[7]);
		temp.min_lv = (uint8)atoi(p[8]);
		temp.max_lv = (uint8)atoi(p[9]);
		snprintf(temp.weekday,sizeof(temp.weekday),"%s",p[10]);
		exit_huodong.push_back(temp);
	}
	fclose(file);
}

void CPackageDeal::GetHuoDongConfig(int day)
{
	const char *week[HUODONG_SIZE] = {"[Sunday]","[Monday]","[Tuesday]","[Wednesday]","[Thursday]","[Friday]","[Saturday]","[festival]"};
	FILE *file = NULL;
	char *p = NULL;
	char buf[512] = {0};
	int len;
	int count;
	file = fopen(HUODONG_FILE,"r");
	if(file == NULL)
		return;
	if(day == -1)
		count = 0;
	else if(day >= 0 && day <= HUODONG_SIZE-1)
		count = day;
	else
		return;
	while(fgets(buf,sizeof(buf)-1,file))
	{
		len = strlen(buf);
		if(buf[len-1] == '\n')
			buf[len-1] = '\0';
		if(buf[len-2] == '\r')
			buf[len-2] = '\0';
		p = buf;
		while(isspace(*p))
			p++;
		if(*p == '#' || *p == 0)
			continue;
		if(strcmp(buf,week[count]) == 0)
		{
			GetHuoDongInfo(huodong[count],file);
			if(day == -1)
				count++;
			else
				break;
		}
	}
	fclose(file);
}

void CPackageDeal::GetHuoDongInfo(list<HuoDongInfo> &huodong_list,FILE *file)
{
	char buf[512];
	char *p = NULL;
	char *ptr = NULL;
	char *ptime = NULL;
	char **pend = NULL;
	int len;
	HuoDongInfo temp;
	if(file == NULL)
		return;
	while(fgets(buf,sizeof(buf)-1,file))
	{
		len = strlen(buf);
		if(buf[len-1] == '\n')
			buf[len-1] = '\0';
		p = buf;
		while(isspace(*p))
			p++;
		if(*p == 0)
			return;
		if(*p == '#')
			continue;
		if(*p == '[')
			return;
		if((ptr = strpbrk(p," \t\r\n")) == NULL)
			continue;
		*ptr = '\0';
		temp.name = p;
		p = ptr+1;
		if((ptr = strpbrk(p," \t\r\n")) == NULL)
			continue;
		*ptr = '\0';
		temp.time = p;
		if((ptime = strpbrk(p,":-")) == NULL)
			continue;
		*ptime = '\0';
		temp.min_time = (int)strtol(p,pend,10);
		p = ptime+1;
		if((ptime = strpbrk(p,":-")) == NULL)
			continue;
		*ptime = '\0';
		temp.min_time = temp.min_time*100 + (int)strtol(p,pend,10);
		p = ptime+1;
		if((ptime = strpbrk(p,":-")) == NULL)
			continue;
		*ptime = '\0';
		temp.max_time = (int)strtol(p,pend,10);
		p = ptime+1;
		temp.max_time = temp.max_time*100 + (int)strtol(p,pend,10);
		p = ptr+1;
		if((ptr = strpbrk(p," -\t\r\n")) == NULL)
			continue;
		*ptr = '\0';
		temp.min_lv = (uint8)strtol(p,pend,10);
		p = ptr+1;
		if((ptr = strpbrk(p," \t\r\n")) == NULL)
			continue;
		*ptr = '\0';
		temp.max_lv = (uint8)strtol(p,pend,10);
		p = ptr+1;
		if((ptr = strpbrk(p," \t\r\n")) == NULL)
			continue;
		*ptr = '\0';
		temp.NPC_name = p;
		p = ptr+1;
		if((ptr = strpbrk(p," \t\r\n")) == NULL)
			continue;
		*ptr = '\0';
		temp.mapid = (short)strtol(p,pend,10);
		p = ptr+1;
		if((ptr = strpbrk(p," \t\r\n")) == NULL)
			continue;
		*ptr = '\0';
		temp.x = (int)strtol(p,pend,10);
		p = ptr+1;
		if(*p == '\0')
			continue;
		temp.y = (int)strtol(p,pend,10);
		huodong_list.push_back(temp);
	}
}

#define GET_MSG if(pMsg == NULL)\
						 return;\
CNetMessage &msg = *pMsg;
#define GET_USER ShareUserPtr ptr = m_onlineUser.GetUserBySock(sock);\
									CUser *pUser = ptr.get();\
if((pUser == NULL) || (pUser->GetRoleId() == 0))\
return;

// 注意 这个宏必须在GET_USER 后面使用 保证pUser是有效的
#define CHECK_SYSTEM_OPEN(x) \
if (!sSystemOpenCfgMananger.CheckSystemOpen(pUser, x)) {\
	/*SendSysInfo(pUser, MakeStringColor(LANGUAGE_LLD_0072, TIPS_FAILURE_COLOR).c_str());*/\
	return;}\

void CPackageDeal::QuerySkillDesc(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER
	//// CHECK_SYSTEM_OPEN(SOT_RoleSkill)

	uint16 id = 0;
	msg>>id;
	std::map<uint16,SkillInfoNode>::iterator i = skillInfoListMap.find(id);
	if(i != skillInfoListMap.end())
	{
		msg<<i->second.desc;
		m_socketServer.SendMsg(pUser->GetSock(),msg);
	}
}

void CPackageDeal::SetVerInfo(const string &version)
{
	m_version = version;
}

//当乐 android ad 62
bool IsDLAndroid(uint16 ad)
{
	return ad == 62 || ad == 44;
}

const int PVP_BASE_AD_CODE = 10000;

struct SRoleDel
{
	uint32 id;
	time_t dT;//删除时间
};

struct SSortRole
{
	bool operator()(const SRoleDel &r1,const SRoleDel &r2)
	{
		return r1.id < r2.id;
	}
};

const int CAN_SAVE_TIME = 7*24*3600;

void CPackageDeal::UserLogin(CNetMessage *pMsg,int sock)
{
	GET_MSG

	uint32 id = 0;
	int serverId = 0;
	string signature;
	string version = "0";
	string netInfo,mac,IMEI,IDFA;
	msg>>id>>signature>>version>>serverId>>netInfo>>mac>>IMEI>>IDFA;
	if(id == 0)
	{
		if(signature == "restart_test_string0")
		{
			m_socketServer.SendMsg(sock,msg);
//			cout<<"--------- restart_test_string0 : "<<GetMonth()+1<<"."<<GetDay()<<" "<<GetHour()<<":"<<GetMinute()<<":"<<GetSysTime()%60<<endl;
			return;
		}
	}

	cout<<" CPackageDeal::UserLogin  id="<<id<<", serverId="<<serverId<<endl;
	
	if(serverId == 0 || id == 0)
	{
		cout<<"------------------>>>>>>> CPackageDeal::UserLogin serverId = "<<serverId<<", id="<<id<<",  error  return"<<endl;
		return;
	}

	string localTest = gyu::util::CIniFile::GetValue("local_test","server",gConfigFile);
	cout << "[local] UserLogin: version client=" << version << " server=" << m_version << endl;
	if(localTest != "1" && atoi(version.c_str()) < atoi(m_version.c_str()))
	{
		cout << "[local] UserLogin: version reject" << endl;
		msg.ReWrite();
		msg.SetType(PRO_USER_LOGIN);
		msg<<PRO_ERROR<<LANGUAGE_SSJ_0533;
		m_socketServer.SendMsg(sock,msg);
		return;
	}
	
	ShareUserPtr pUserOld = m_onlineUser.GetUserBySock(sock);
	CUser *pOld = pUserOld.get();
	if(pOld != NULL)
	{
		cout<<"------------------>>>>>>> CPackageDeal::UserLogin pUserOld != NULL "<<endl;
		return;
	}
	
	vector<int> serverIdList;
	GetServerIdList(serverIdList);
	cout << "[local] UserLogin: server list size=" << serverIdList.size() << endl;
	if(!serverIdList.empty())
	{
		int size = serverIdList.size();
		bool findSid = false;
		for(int i=0;i < size;i++)
		{
			if(serverId == serverIdList[i])
			{
				findSid = true;
				break;
			}
		}
		if(!findSid)
		{
			cout << "[local] UserLogin: serverId not found " << serverId << endl;
			return;
		}
	}
	else
	{
		cout << "[local] UserLogin: server list empty" << endl;
		return;
	}

#ifdef KUA_FU
	static bool initIdx = true;
	if(initIdx)
	{
		initIdx = false;
		memset(SockLongIdx,0,sizeof(SockLongIdx));
	}
	{
		boost::recursive_mutex::scoped_lock lk(sockLong_mutex);
		LongIndex++;
		SockLongIdx[sock] = LongIndex;
		CopyUserDataToKuaFu(serverId,GetServerZone(serverId),id,signature,LongIndex,sock);
	}
#else
	char sql[1024];
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;

	char **row = NULL;
	uint32 userId = 0;
	uint32 roleId;
	uint32 YB = 0;
	uint32 bangYB = 0;
	uint32 ad = 0;
	string mobileType;
	string mobileInfo;
	CUser *pUser = NULL;
	msg.ReWrite();
	msg.SetType(PRO_USER_LOGIN);
	if(localTest == "1")
	{
		cout << "[local] UserLogin: local_test account" << endl;
		userId = (uint32)atoi(gyu::util::CIniFile::GetValue("local_user_id","server",gConfigFile).c_str());
		if(userId == 0)
			userId = id > 0 ? id : 1;
		ad = 1;
		mobileType = "0";
		mobileInfo = "local_test";
	}
	else
	{
	snprintf(sql,sizeof(sql),"select uid,sig,ad,mobile_type,mobile_info from sig_log where id=%u",id);
	if(!m_loginDb.Query(sql))
	{
		msg<<PRO_ERROR<<LANGUAGE_TRANSFORM_842;
		m_socketServer.SendMsg(sock,msg);
		return;
	}
	if(m_loginDb.GetRowNum() == 0)
	{
		msg<<PRO_ERROR<<LANGUAGE_TRANSFORM_843;
		m_socketServer.SendMsg(sock,msg);
		return;
	}
	if((row = m_loginDb.GetRow()) == NULL)
		return;
	if(signature != row[1])
	{
		msg<<PRO_ERROR<<LANGUAGE_TRANSFORM_844;
		m_socketServer.SendMsg(sock,msg);
		return;
	}
	userId = (uint32)atoi(row[0]);
	ad = atoi(row[2]);
	mobileType = row[3];
	mobileInfo = row[4];
	}
	
	cout << "[local] UserLogin: query user_info userId=" << userId << endl;
	snprintf(sql,sizeof(sql),"select role0,money,bd_money,ad,del_time0,type,reg_time,mobile_type,mobile_info,new_user from %s where id=%u",GetUserInfoTab(serverId).c_str(),userId);
	if(!pDb->Query(sql))
	{
		if(localTest == "1")
		{
			roleId = 0;
		}
		else
		{
			msg<<PRO_ERROR<<LANGUAGE_TRANSFORM_845;
			m_socketServer.SendMsg(sock,msg);
			return;
		}
	}
	else if((row = pDb->GetRow()) == NULL)
	{
		roleId = 0;
	}
	else
	{
		roleId = atoi(row[0]);
		YB = atoi(row[1]);
		bangYB = atoi(row[2]);
	}

	cout << "[local] UserLogin: add user roleId=" << roleId << endl;
	pUser = m_onlineUser.AddUser(sock,userId);
	if(pUser == NULL)
		return;

	pUser->SetAd(ad);
	pUser->SetTongBao(YB,0);
	pUser->SetTongBao(bangYB,1);
	pUser->SetServerId(serverId);
	pUser->SetLoginSig(id,signature);
	pUser->SetLogInfo(netInfo,mac,IMEI,IDFA);
	pUser->SetMobileType(atoi(mobileType.c_str()));
	pUser->SetMobileInfo(mobileInfo);

	if(localTest == "1" && roleId == 0 && userId == 1)
	{
		const char *localRoleName = "Test01";
		snprintf(sql, sizeof(sql), "select id from role_info where name='%s'", localRoleName);
		if(pDb->Query(sql) && (row = pDb->GetRow()) != NULL)
		{
			roleId = (uint32)atoi(row[0]);
		}
		else
		{
			uint32 regTime = (uint32)GetSysTime();
			snprintf(sql, sizeof(sql), "insert into role_info (name,sex,head,model,level,kuafu_state,reg_time) values('%s',0,5,5,1,%d,%u)", localRoleName, EKFS_IN_LOCAL, regTime);
			if(pDb->Query(sql))
				roleId = (uint32)pDb->InsertId();
		}
		if(roleId > 0)
		{
			string userTab = GetUserInfoTab(serverId);
			snprintf(sql, sizeof(sql), "insert into %s(id,role0,money,bd_money,ad,del_time0,type,reg_time,mobile_type,mobile_info,new_user) values(%u,%u,0,0,%u,0,0,%u,'0','local_test',0) on duplicate key update role0=%u",
				userTab.c_str(), userId, roleId, ad, (uint32)GetSysTime(), roleId);
			pDb->Query(sql);
		}
	}

	if(localTest == "1" && roleId > 0)
	{
		if(!RepairLocalRoleNullFields(pDb, roleId))
		{
			cout << "[local] UserLogin: role null-field repair failed roleId=" << roleId
				<< " error=" << pDb->GetErrMsg() << endl;
			msg<<PRO_ERROR<<"Local role data repair failed";
			m_socketServer.SendMsg(sock,msg);
			m_onlineUser.DelUser(pUser);
			return;
		}
		const uint32 localTestMoney = 1000000;
		const string localTestTongBaoText = gyu::util::CIniFile::GetValue(
			"local_test_tongbao", "server", gConfigFile);
		const string localTestBdTongBaoText = gyu::util::CIniFile::GetValue(
			"local_test_bd_tongbao", "server", gConfigFile);
		const uint32 localTestTongBao = localTestTongBaoText.empty()
			? 100000 : (uint32)strtoul(localTestTongBaoText.c_str(), NULL, 10);
		const uint32 localTestBdTongBao = localTestBdTongBaoText.empty()
			? 100000 : (uint32)strtoul(localTestBdTongBaoText.c_str(), NULL, 10);
		const uint32 preserveLevelUserId = (uint32)atoi(
			gyu::util::CIniFile::GetValue("local_preserve_level_user_id","server",gConfigFile).c_str());
		const uint32 preserveBalanceUserId = (uint32)atoi(
			gyu::util::CIniFile::GetValue("local_preserve_balance_user_id","server",gConfigFile).c_str());
		const bool preserveLocalBalance = preserveBalanceUserId > 0 && preserveBalanceUserId == userId;
		if(preserveLevelUserId > 0 && preserveLevelUserId == userId)
		{
			cout << "[local] UserLogin: preserve role level for fixture userId=" << userId << endl;
			if(!preserveLocalBalance)
			{
				snprintf(sql, sizeof(sql),
					"update role_info set money=greatest(cast(ifnull(nullif(money,''),'0') as unsigned),%u) where id=%u",
					localTestMoney, roleId);
				pDb->Query(sql);
			}
		}
		else
		{
			if(preserveLocalBalance)
				snprintf(sql, sizeof(sql),
					"update role_info set level=greatest(cast(ifnull(nullif(level,''),'0') as unsigned),60) where id=%u", roleId);
			else
				snprintf(sql, sizeof(sql),
					"update role_info set level=greatest(cast(ifnull(nullif(level,''),'0') as unsigned),60),money=greatest(cast(ifnull(nullif(money,''),'0') as unsigned),%u) where id=%u",
					localTestMoney, roleId);
			pDb->Query(sql);
		}
		string userTab = GetUserInfoTab(serverId);
		if(!preserveLocalBalance)
		{
			snprintf(sql, sizeof(sql),
				"update %s set money=greatest(money,%u),bd_money=greatest(bd_money,%u) where id=%u",
				userTab.c_str(), localTestTongBao, localTestBdTongBao, userId);
			pDb->Query(sql);
			YB = std::max(YB, localTestTongBao);
			bangYB = std::max(bangYB, localTestBdTongBao);
		}
		pUser->SetTongBao(YB,0);
		pUser->SetTongBao(bangYB,1);
	}

	msg<<PRO_SUCCESS;
	msg<<(uint8)0;	// not in kuafu
	msg<<userId;
	if(roleId > 0)
	{
		cout << "[local] UserLogin: load role brief roleId=" << roleId << endl;
		pUser->AddRole(roleId);
		//pUser->UpdateBangHuoYue(EBHT_Login);

		//                        0   1    2   3   4      5
		snprintf(sql,sizeof(sql),"select id,name,head,level,sex,kuafu_state from role_info where id=%u",roleId);
		if(!pDb->Query(sql) || (row = pDb->GetRow()) == NULL)
			return;
		if(atoi(row[5]) != EKFS_IN_LOCAL)
		{
			msg.ReWrite();
			msg.SetType(PRO_USER_LOGIN);
			msg<<PRO_ERROR<<"";
			m_socketServer.SendMsg(sock,msg);
			SendKuaFuData(serverId,id,signature,sock);
			return;
		}
		msg<<atoi(row[0])<<row[1]<<(uint8)atoi(row[2])<<(uint16)atoi(row[3])<<(uint8)atoi(row[4]);
	}
	else
	{
		msg<<(uint32)0;
	}
	cout << "[local] UserLogin: send response" << endl;
	m_socketServer.SendMsg(sock,msg);
	cout << "[local] UserLogin: done" << endl;
#endif
}

#ifdef KUA_FU
void CPackageDeal::KuaFuLoginRet(CNetMessage *pMsg,int sock)
{
	GET_MSG
	
    if(!m_socketServer.IsServer(sock))
		return;
	int index = 0;
	int userSock = 0;
	int serverId = 0;
	int id = 0;
	uint8 success = 0;	// 0 failed 1 success
	string signature;
	msg>>index>>userSock>>serverId>>id;
	msg.ReadString(signature);
	msg>>success;

	if(index == 0 || userSock == 0 || userSock >= MAX_CON_USER)
		return;
	{
		boost::recursive_mutex::scoped_lock lk(sockLong_mutex);
		if(SockLongIdx[userSock] != index)
			return;
	}

	if(success)
	{
		uint32 userId = 0;
		int ad = 0;
		uint32 roleId = 0;
		uint32 YB = 0;
		uint32 bangYB = 0;
		msg>>userId>>ad>>roleId>>YB>>bangYB;
		QueryGameServer_BangPaiInfo(serverId,roleId);

		msg.ReWrite();
		msg.SetType(PRO_USER_LOGIN);
		if(userId == 0 || roleId == 0 || ad == 0)
		{
			msg<<PRO_ERROR<<LANGUAGE_TRANSFORM_918;
			m_socketServer.SendMsg(userSock,msg);
			return;
		}
		
		char sql[1024];
		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		if(pDb == NULL)
			return;
		char **row = NULL;
		CUser *pUser = m_onlineUser.AddUser(userSock,userId);
		if(pUser == NULL)
			return;
		msg.ReWrite();
		msg.SetType(PRO_USER_LOGIN);
		
		pUser->SetAd(ad);
		pUser->SetTongBao(YB,0);
		pUser->SetTongBao(bangYB,1);
		pUser->SetServerId(serverId);
		pUser->SetLoginSig(id,signature);

		msg<<PRO_SUCCESS;
		msg<<(uint8)1;	// in kuafu
		msg<<userId;
		pUser->AddRole(roleId);
        //pUser->UpdateBangHuoYue(EBHT_Login);
		//                        0  1     2   3    4   5
		snprintf(sql,sizeof(sql),"select id,name,head,model,level,sex from role_info where id=%u",roleId);
		if(pDb->Query(sql) && (row = pDb->GetRow()) != NULL)
			msg<<atoi(row[0])<<row[1]<<(uint8)atoi(row[2])<<(uint8)atoi(row[3])<<(uint8)atoi(row[4])<<(uint8)atoi(row[5]);
		else
			return;
		m_socketServer.SendMsg(userSock,msg);
	}
	else
	{
		msg.ReWrite();
		msg.SetType(PRO_USER_LOGIN);
		msg<<PRO_ERROR<<LANGUAGE_TRANSFORM_918;
		m_socketServer.SendMsg(userSock,msg);
		return;
	}
}
#endif

void CPackageDeal::RoleNameOption(CNetMessage *pMsg,int sock)
{
	GET_MSG

	uint8 op = 1;	// 1 check roleName  2 get reg name
	string name;
	msg>>op;

	if(op == 1)		// check roleName
	{
		msg>>name;
		CUser *pUser = m_onlineUser.GetUserBySock(sock).get();
		if(pUser == NULL)
			return;

		int nameLen = GetCharacterNum(name);
		if(nameLen > 6)
		{
			msg<<PRO_ERROR<<LANGUAGE_TRANSFORM_847;
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(IllegalStr(name))
		{
			char buf[64];
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_848,name.c_str());
			msg<<PRO_ERROR<<buf;
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(IsIllegalMsg(name.c_str()))
		{
			msg<<PRO_ERROR<<LANGUAGE_TRANSFORM_849;
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}

		char sql[128];
		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		if(pDb == NULL)
			return;
		snprintf(sql,sizeof(sql),"select id from role_info where name='%s'",name.c_str());
		if(!pDb->Query(sql))
			return;
		if(pDb->GetRowNum() == 0)
		{
			msg<<PRO_SUCCESS;
		}
		else
		{
			msg<<PRO_ERROR<<LANGUAGE_TRANSFORM_850;
		}
		m_socketServer.SendMsg(pUser->GetSock(),msg);
	}
	else if(op == 2)		// get reg name
	{
		uint8 sex = 0;	// 0男1女
		msg>>sex;
		if(sex > 1)
			return;
		if(gyu::util::CIniFile::GetValue("local_test","server",gConfigFile) == "1")
		{
			CUser *pUser = m_onlineUser.GetUserBySock(sock).get();
			if(pUser == NULL)
				return;
			char localName1[16];
			char localName2[16];
			char localName3[16];
			snprintf(localName1,sizeof(localName1),"T%05u",pUser->GetUserId()%100000);
			snprintf(localName2,sizeof(localName2),"U%05u",pUser->GetUserId()%100000);
			snprintf(localName3,sizeof(localName3),"V%05u",pUser->GetUserId()%100000);
			CNetMessage newmsg;
			newmsg.SetType(PRO_ROLE_NAME_CHECK);
			newmsg<<op<<sex<<(uint8)3<<string(localName1)<<string(localName2)<<string(localName3);
			m_socketServer.SendMsg(sock,newmsg);
			return;
		}
		//未创建角色，只好以sock来识别，应该生成一个唯一id
		QueryRoleName(sock,sex);
	}
}

void CPackageDeal::ServerRoleName(CNetMessage *pMsg,int sock)
{
	GET_MSG
	
    if(!m_socketServer.IsServer(sock))
		return;
	int roleSock;
	uint8 op;
	uint8 sex;
	uint8 num;

	msg>>roleSock>>op>>sex>>num;
	
	CUser *pUser = m_onlineUser.GetUserBySock(roleSock).get();
	if(pUser == NULL)
		return;
	
	CNetMessage newmsg;
	newmsg.SetType(PRO_ROLE_NAME_CHECK);
	newmsg<<op;
	newmsg<<sex;
    newmsg<<num;
	for(uint8 i=0;i < num;i++)
	{
		string name;
		msg.ReadString(name);
		newmsg<<name;
	}
	m_socketServer.SendMsg(pUser->GetSock(),newmsg);
}

void CPackageDeal::ServerQueryOnlineNum(CNetMessage *pMsg,int sock)
{
	GET_MSG

	uint16 sid = 0;
	msg>>sid;
	int onlineNum = GetOnlineUserNum();
	CNetMessage newmsg;
	newmsg.SetType(PRO_SERVER_QUERY_ONLINE_NUM);
	newmsg<<sid<<onlineNum;
	m_socketServer.SendMsg(sock,newmsg);
}

void CPackageDeal::RemoveFastRoleName(int sex,string &name)
{
	if(gyu::util::CIniFile::GetValue("local_test","server",gConfigFile) == "1")
		return;
	char buf[256];
	if(sex == 0)
		snprintf(buf,sizeof(buf),"delete from name_reg0 where name='%s'",name.c_str());
	else
		snprintf(buf,sizeof(buf),"delete from name_reg1 where name='%s'",name.c_str());
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
	pDb->Query(buf);
}

void CPackageDeal::CreateRole(CNetMessage *pMsg,int sock)
{
	GET_MSG

	ShareUserPtr ptr = m_onlineUser.GetUserBySock(sock);
	CUser *pUser = ptr.get();
	if(pUser == NULL)
		return;

	string name;
	uint8 sex = 0;	// 性别 0 m 1 f
	uint8 model = 0;	// 模型
	uint8 head = 0;	// 头像
	uint16 ad = 0;
	msg>>name>>sex>>model>>head>>ad;
	msg.ReWrite();
	msg.SetType(PRO_CREATE_ROLE);

	if(model == 0 || head == 0 || sex > 1)
		return;
	int nameLen = GetCharacterNum(name);
	if(nameLen > 6 || nameLen < 1)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_851,TIPS_FAILURE_COLOR);
		m_socketServer.SendMsg(pUser->GetSock(),msg);
		return;
	}
	if(IllegalStr(name))
	{
		char buf[64];
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_852,name.c_str());
		msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
		m_socketServer.SendMsg(pUser->GetSock(),msg);
		return;
	}
	if(IsIllegalMsg(name.c_str()))
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_853,TIPS_FAILURE_COLOR);
		m_socketServer.SendMsg(pUser->GetSock(),msg);
		return;
	}

	char sql[512];
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
	if(pUser->HaveRole())
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_854,TIPS_FAILURE_COLOR);
		m_socketServer.SendMsg(pUser->GetSock(),msg);
		return;
	}

	snprintf(sql,sizeof(sql),"select id from role_info where name='%s'",name.c_str());
	if(!pDb->Query(sql))
		return;
	if(pDb->GetRow() != NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_855,TIPS_FAILURE_COLOR);
		RemoveFastRoleName(sex,name);
		m_socketServer.SendMsg(pUser->GetSock(),msg);
		return;
	}

	uint32 reg_time = (uint32)GetSysTime();
	string localTest = gyu::util::CIniFile::GetValue("local_test","server",gConfigFile);
	const uint32 preserveLevelUserId = (uint32)atoi(
		gyu::util::CIniFile::GetValue("local_preserve_level_user_id","server",gConfigFile).c_str());
	const bool preserveLocalLevel = localTest == "1" && preserveLevelUserId > 0 &&
		preserveLevelUserId == pUser->GetUserId();
	uint8 initLevel = (localTest == "1" && !preserveLocalLevel) ? 60 : 1;
	uint32 initMoney = (localTest == "1") ? 1000000 : 0;
	uint32 initTongBao = (localTest == "1") ? 100000 : 0;
	uint32 initBdTongBao = (localTest == "1") ? 100000 : 0;
	snprintf(sql,sizeof(sql),"insert into role_info (name,sex,head,model,level,kuafu_state,state,reg_time,money) values('%s',%d,%d,%d,%u,%d,0,%u,%u)",
		name.c_str(), (int)sex, (int)head, (int)model, (uint32)initLevel, EKFS_IN_LOCAL, reg_time, initMoney);
	if(!pDb->Query(sql))
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_856,TIPS_FAILURE_COLOR);
		RemoveFastRoleName(sex,name);
		m_socketServer.SendMsg(pUser->GetSock(),msg);
		return;
	}
	
	uint32 roleId = pDb->InsertId();
	string userTab = GetUserInfoTab(pUser->GetServerId());
	if(localTest == "1")
	{
		if(!RepairLocalRoleNullFields(pDb, roleId))
		{
			cout << "[local] CreateRole: role null-field repair failed roleId=" << roleId
				<< " error=" << pDb->GetErrMsg() << endl;
			snprintf(sql, sizeof(sql), "delete from role_info where id=%u", roleId);
			pDb->Query(sql);
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_856,TIPS_FAILURE_COLOR);
			RemoveFastRoleName(sex,name);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}

		snprintf(sql, sizeof(sql), "insert into %s(id,role0,money,bd_money,ad,del_time0,type,reg_time,mobile_type,mobile_info,new_user) values(%u,%u,%u,%u,%u,0,0,%u,'0','local_test',0) on duplicate key update role0=%u,money=%u,bd_money=%u",
			userTab.c_str(), pUser->GetUserId(), roleId, initTongBao, initBdTongBao, (uint32)ad, reg_time, roleId, initTongBao, initBdTongBao);
		pDb->Query(sql);
		pUser->SetTongBao((int)initTongBao, 0);
		pUser->SetTongBao((int)initBdTongBao, 1);
		pUser->AddRole(roleId);
		RemoveFastRoleName(sex,name);
		msg<<PRO_SUCCESS<<roleId<<name<<sex<<model<<head<<reg_time;
		m_socketServer.SendMsg(pUser->GetSock(),msg);
		return;
	}

	snprintf(sql, sizeof(sql), "select id from %s where id=%u", userTab.c_str(), pUser->GetUserId());
	if(!pDb->Query(sql))
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_918,TIPS_FAILURE_COLOR);
		RemoveFastRoleName(sex,name);
		m_socketServer.SendMsg(pUser->GetSock(),msg);
		return;
	}
	if(pDb->GetRowNum() > 0)
	{
		snprintf(sql, sizeof(sql), "update %s set role0=%u where id=%u", userTab.c_str(), roleId, pUser->GetUserId());
		if(!pDb->Query(sql))
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_918,TIPS_FAILURE_COLOR);
			RemoveFastRoleName(sex,name);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
	}
	else
	{
		snprintf(sql,sizeof(sql),"insert into %s (id,ad,reg_time,mobile_type,mobile_info,role0) values(%u,%u,from_unixtime(%u),%d,'%s',%u)",
			GetUserInfoTab(pUser->GetServerId()).c_str(), pUser->GetUserId(), ad, (uint32)GetSysTime(), pUser->GetMobileType(), pUser->GetMobileInfo().c_str(), roleId);
		if(!pDb->Query(sql))
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_846, TIPS_FAILURE_COLOR);
			RemoveFastRoleName(sex,name);
			m_socketServer.SendMsg(sock,msg);
			return;
		}
	}
	
	pUser->AddRole(roleId);
//	pUser->m_isCreatedRole = true; // 标记创建角色
	RemoveFastRoleName(sex,name);
	msg<<PRO_SUCCESS<<roleId<<name<<sex<<model<<head<<reg_time;
	m_socketServer.SendMsg(pUser->GetSock(),msg);
}

void CPackageDeal::SelectRole(CNetMessage *pMsg,int sock)
{
	GET_MSG

	ShareUserPtr ptr = m_onlineUser.GetUserBySock(sock);
	CUser *pUser = ptr.get();
	uint32 roleId = 0;
	msg>>roleId;
	bool localTestLog = (gyu::util::CIniFile::GetValue("local_test","server",gConfigFile) == "1");
	if(localTestLog)
		cout << "[local] SelectRole: begin sock=" << sock << " roleId=" << roleId << endl;
	msg.ReWrite();
	msg.SetType(PRO_SELECT_ROLE);
	//需要对user id进行判断
	if ((pUser == NULL) || (roleId == 0) || !pUser->HaveRole(roleId))
	{
		msg<<PRO_ERROR<<LANGUAGE_TRANSFORM_858;
		m_socketServer.SendMsg(sock,msg);
		return;
	}
	else
	{
		ShareUserPtr ptrOther = m_onlineUser.GetUserByRoleId(roleId);
		CUser *pOther = ptrOther.get();
		if((pOther != NULL) && (pOther->GetSock() == sock))
		{
			return;
		}
	}

	bool useSrcInfo = false;//使用已在线用户的信息
	uint32 userRoles[MAX_ROLE_NUM] = {0};
	pUser->GetRoles(userRoles);
	for(uint8 i = 0; i < MAX_ROLE_NUM; i++)
	{
		if(userRoles[i] != 0)
		{
			ShareUserPtr ptrOther = m_onlineUser.GetUserByRoleId(userRoles[i]);
			CUser *pOther = ptrOther.get();
			if(pOther != NULL)
			{
				if(userRoles[i] != roleId)
				{
					msg<<PRO_ERROR<<LANGUAGE_TRANSFORM_859;
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				else if(userRoles[i] == roleId)
				{
					if(pOther->GetFightId() != 0)
					{
						int oldSock = pOther->GetSock();
						if((oldSock >= 0) && (oldSock != sock))
						{
							close(oldSock);
							OnSockClose(oldSock);
						}
						pUser = m_onlineUser.ReLogin(sock,roleId);
						if(pUser == NULL)
							return;
						useSrcInfo = true;
					}
					else
					{
#ifdef KUA_FU
						int oldSock = pOther->GetSock();
						if((oldSock >= 0) && (oldSock != sock))
						{
							m_onlineUser.DelUser(pOther,false);
							pOther->UserLogout(true);
						}
						pUser = m_onlineUser.ReLogin(sock,roleId);
						if((oldSock >= 0) && (oldSock != sock))
							close(oldSock);
						if(pUser == NULL)
							return;
						useSrcInfo = true;
#else
						if(pOther->GetSock() > 0)
							close(pOther->GetSock());
						UserLogout(pOther);
#endif
					}
					break;
				}
			}
		}
	}
	CRankMgr& rmgr = SingletonCRankMgr::instance();
	if(localTestLog)
		cout << "[local] SelectRole: before ReadData roleId=" << roleId << " useSrcInfo=" << useSrcInfo << endl;
	if(useSrcInfo || pUser->ReadData(roleId))
	{
		if(localTestLog)
			cout << "[local] SelectRole: after ReadData roleId=" << roleId << endl;
		// The production login server normally restores the role's scene before the
		// game-server flow continues.  The local direct-connect path has no login
		// server, so bind a valid scene here when the loaded role has none.
		if(localTestLog && pUser->GetScene() == NULL)
		{
			uint32 sceneId = pUser->GetData32(3);
			CScene *pScene = sceneId == 0 ? NULL : m_sceneManager.FindScene(sceneId);
			if(pScene == NULL)
				pScene = m_sceneManager.FindScene(1);
			if(pScene != NULL)
			{
				pUser->SetPos(pScene->GetX(), pScene->GetY());
				pUser->EnterScene(pScene);
				cout << "[local] SelectRole: bound scene roleId=" << roleId
					<< " sceneId=" << pScene->GetId()
					<< " x=" << pScene->GetX() << " y=" << pScene->GetY() << endl;
			}
		}
		if(!useSrcInfo)
		{
			m_onlineUser.SetRoleId(sock,roleId);
//			pUser->ReadBangPai();

			rmgr.UpdateData(CRankMgr::ERT_Level, pUser->GetRoleId(), pUser->GetLevel(), pUser->GetExp());
			rmgr.UpdateData(CRankMgr::ERT_Power, pUser->GetRoleId(), pUser->GetZhanDouLi());
		}

		if(pUser->GetBangPai() != 0)
		{
			CBangPaiManager &bPMgr = SingletonCBangPaiManager::instance();
			CBangPai *pBangPai = bPMgr.FindBangPai(pUser->GetBangPai());
			if((pBangPai == NULL) || (pBangPai->GetMemberRank(roleId) == 0))
			{
				pUser->SetBangPai(0);
			}
		}

		SingletonCSimpleRoleDataMgr::instance().UpdateRoleData(pUser);

		// 第一次登录
		/*if (!pUser->HaveBitSet(2))
		{
			pUser->SetBitSet(2);
		}*/
		uint16 bornPet = 57;
		if (!pUser->HavePet(bornPet))
		{
			if(localTestLog)
				cout << "[local] SelectRole: add born pet roleId=" << roleId << endl;
			AddPet(pUser, bornPet, 1, 1, false);
			pUser->ZhenFa_SetPetState(bornPet, 1, false);
		}
		if(localTestLog)
			cout << "[local] SelectRole: before send login roleId=" << roleId << endl;
		msg << PRO_SUCCESS;
		msg<<roleId<<pUser->GetName()<<pUser->GetSex()<<pUser->GetModel()<<pUser->GetHead()
			<<pUser->GetLevel()<<pUser->GetExp()<<pUser->GetZhanDouLi();
		msg<<pUser->GetMoney()<<pUser->GetTongBao()<<pUser->GetTongBao(1)<<pUser->GetQianNeng()<<pUser->GetShenhun()<<pUser->GetMaxPackageNum();
		msg<<pUser->GetBangPai()<<pUser->GetBangPaiRank()<<pUser->GetBangPaiName()<<pUser->GetBangPaiShowInfo()<<pUser->GetBangGong();
		msg<<OPEN_CHONGZHI_MONEY;

		uint8 tranState = pUser->HaveBitSet(600) ? 1: 0;
		int meiLiVal = pUser->GetExtData32(465);
		msg<<pUser->GetTransFormMonsterID( pUser->GetCurTransFormID())<<tranState<<meiLiVal;
		msg<<pUser->GetRegTime()<<pUser->GetServerId();

#ifdef KUA_FU
		msg<<GetServerZone(pUser->GetServerId());
#endif
		m_socketServer.SendMsg(pUser->GetSock(),msg);
		if(localTestLog)
			cout << "[local] SelectRole: sent login roleId=" << roleId << endl;

		uint16 rank = rmgr.GetRankIdx(CRankMgr::ERT_Power, pUser->GetRoleId());
		if (rank > 0 && rank <= 5)
		{
			char buf[128];
			snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0242, rank, pUser->GetName());
			SysInfoToAllUser(buf);
		}

		rank = rmgr.GetRankIdx(CRankMgr::ERT_Level, pUser->GetRoleId());
		if (rank > 0 && rank <= 5)
		{
			char buf[128];
			snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0243, rank, pUser->GetName());
			SysInfoToAllUser(buf);
		}
	}
	else
	{
		if(localTestLog)
			cout << "[local] SelectRole: ReadData failed roleId=" << roleId << endl;
		msg<<PRO_ERROR<<LANGUAGE_TRANSFORM_860;
		m_socketServer.SendMsg(pUser->GetSock(),msg);
		return;
	}
	if(useSrcInfo)
	{
		ShareFightPtr pFight = SingletonFightManager::instance().FindFight(pUser->GetFightId());
		if(pFight.get() != NULL)
		{
			ShareUserPtr ptr = m_onlineUser.GetUserBySock(sock);
			if(!pFight->ReBegin(m_socketServer,ptr))
				pUser->SetFight(0);
		}
		else
		{
			pUser->SetFight(0);
		}
	}
	else
	{
		CCallScript *pScript = GetScript();
		if(localTestLog)
			cout << "[local] SelectRole: before Logon script roleId=" << roleId << endl;
		if(pScript != NULL)
			pScript->Call("Logon","u",pUser);
		if(localTestLog)
			cout << "[local] SelectRole: after Logon script roleId=" << roleId << endl;
	}

	if(localTestLog)
		cout << "[local] SelectRole: before post-login notices roleId=" << roleId << endl;
#ifdef KUA_FU
	CSceneManager::NotiyActivityInfo(pUser, SOT_ShenJieMiJing);// 神界秘境
#else
	CSceneManager::NotiyActivityInfo(pUser, SOT_ShenJieMiJing);// 神界秘境
	pUser->ShowHuoDongIcon();
	//if(GetDropExItemDayIdx() != 0)		// 兑换豪礼活动
	//	SendHuoDongFlag_Single(pUser,18,1);
	// 开服活动
	int leftTime = SingletonCHuoDongAwardManager::instance().GetHuoDongIconEndTime() - (int)GetSysTime();
	if(leftTime > 0)
	{
		CNetMessage qzlhlMsg;
		qzlhlMsg.SetType(MSG_TMP_HUODONG);
		qzlhlMsg<<(uint8)HD_QIANGZHUANGLINGHAOLI<<(uint8)3<<(int)leftTime;
		m_socketServer.SendMsg(pUser->GetSock(),qzlhlMsg);
	}
#endif

	// 组队昆仑山
//	if(InFuncionLevelReadyTime(SOT_KuaFuLunDao))
//		SendHuoDongFlag(SOT_KuaFuLunDao,3);
//	else if(InFuncionLevelTime(SOT_KuaFuLunDao))
//		SendHuoDongFlag(SOT_KuaFuLunDao,1);

	pUser->UpdateVipInfo();
	pUser->UpdateOfflineExpTime(); // 更新玩家离线经验时间

	pUser->TimeOutUpdateUserData();

	pUser->UpdateJifenInfo(); // 更新擂台积分
#ifndef KUA_FU
	pUser->SendUpdateInfo(EUUT_ArenaScore); // 更新客户端竞技场积分
	pUser->Multi_Exp_UpdateActiveTime();
	pUser->Send_HuoDongMsg();
	SendDailyBossShowIconInfo(pUser);
	// 发送type有修改
	/*uint8 joinchuanguan = pUser->GetExtData8(21);
	if((joinchuanguan == 0 && pUser->HaveBitSet(180)) || (joinchuanguan > 0 && joinchuanguan < CXunBaoManage::JOIN_LIMIT))
		SendHuoDongFlag_Single(pUser,19,1);*/
	pUser->SendUpdateMoney(HDAT_JJCMoney);
	pUser->SendUpdateMoney(HDAT_KunLunMoney);
	pUser->SendUpdateMoney(HDAT_XingXiuJingHua);
	pUser->SendUpdateMoney(HDAT_HuoYue);

	pUser->sendXtmasTreeInfo();//发送圣诞树图标信息
#endif
	
	pUser->AddSpecialTitle();
	//境界信息
	pUser->SendJingJieInfo();
	//神器->新神器
	pUser->InitFromOldShenQi();
	//屏蔽切磋功能
//	pUser->SendIgnoreQieCuoInfo();
	pUser->SendIgnoreVipInfo();

#ifdef KUA_FU
	SingletonCShenJieMiJingManager::instance().SendRedPointInfo(pUser);
	ShowBangZhanIcon_Single(pUser);
#endif
#ifndef KUA_FU
	SingletonCHuoDongMoneyGiftBag::instance().SendIconInfo(pUser);
#endif

//	int bitset = 581;
//	if (!pUser->HaveBitSet(bitset))
//	{
//		pUser->GiveVipNewAward();
//		pUser->SetBitSet(bitset);
//	}
	if (pUser->GetBangPai() > 0 && pUser->HaveCMission(EMISS_DC_18))
	{
		pUser->UpdateCMissionState(EMISS_DC_18, EMISS_STATE_FINISH);
	}
//	pUser->DelCMission(MISSION_ID_ZhuoGui);

	if (pUser->GetExtData32(14) > 0)
	{
		SingletonCMissionManager::instance().UpdateDCMissionComplate(pUser, EMISS_DC_70, 0);
	}
	CMissionManager& mmgr = sCMissionManager;
	mmgr.UpdateQuestState(pUser, EMQCT_4, 1);
	mmgr.UpdateQuestState(pUser, EMQCT_37, 1, pUser->GetRegDay());

	if (pUser->GetBangPai() != 0)
		mmgr.UpdateQuestState(pUser, EMQCT_59);
#ifdef KUA_FU
	pUser->SyncPowerToMatch();
#endif

	SingletonCSimpleRoleDataMgr::instance().UpdateRoleData(pUser);
	if(localTestLog)
		cout << "[local] SelectRole: done roleId=" << roleId << endl;
}

void CPackageDeal::GetPackage(CNetMessage *pMsg,int sock)
{
	GET_MSG

	msg.ReWrite();
	msg.SetType(PRO_ROLE_PACKAGE);
	ShareUserPtr ptr = m_onlineUser.GetUserBySock(sock);
	CUser *pUser = ptr.get();
	if (pUser == NULL)
		return;

	pUser->MakePack(msg);
	m_socketServer.SendMsg(pUser->GetSock(),msg);
}

bool CPackageDeal::UserMoveOneStep(CUser *pUser,CScene *pScene,ShareUserPtr &ptr,uint16 x,uint16 y)
{
	SJumpTo *pJump = NULL;
	if(pScene == NULL)
		return false;
	if(pScene->GetJumpPoint(x,y,pJump))
	{
		vector<ShareUserPtr> pMember;
		GetTeamMemberList(pUser,pMember);
		int roleNum = pMember.size();
		if(roleNum == 0)
			return false;
		for(int i=0; i < roleNum;i++)
		{
			if(pMember[i].get() != NULL)
				pMember[i]->StopGuaJi();
		}

		if(pJump->sceneId == 0)
		{
			SJumpTo backPoint = pUser->GetFuBenBackPoint();
			if(backPoint.sceneId == 0)
				return false;
			else
			{
				TransportUser(pUser,backPoint.sceneId,backPoint.x,backPoint.y,backPoint.face);
				return true;
			}
		}

		CNetMessage msg;
		CScene *pOld = pUser->GetScene();
		if(pOld == NULL)
			return false;
		if((pOld != NULL) && (pOld->GetGroupId() != 0))
		{
			msg.ReWrite();
			msg.SetType(PRO_JUMP_SCENE);
			msg<<pJump->sceneId<<pJump->x<<pJump->y<<pJump->face<<(uint8)0;
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			pUser->SetPos(pJump->x,pJump->y);
			pUser->SetFace(pJump->face);

			CScene *pScene = m_sceneManager.FindScene(pJump->sceneId,pOld->GetGroupId());
			if(pScene == NULL)
			{
				pUser->EnterScene(m_sceneManager.FindScene(pJump->sceneId));
				return true;
			}
			else
			{
				pUser->EnterScene(pScene);
			}
		}
		else
		{
			msg.ReWrite();
			msg.SetType(PRO_JUMP_SCENE);
			msg<<pJump->sceneId<<pJump->x<<pJump->y<<pJump->face<<(uint8)0;
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			pUser->SetPos(pJump->x,pJump->y);
			pUser->SetFace(pJump->face);
			pUser->EnterScene(m_sceneManager.FindScene(pJump->sceneId));
		}
#ifdef DEBUG
		boost::format fmt("jump to:%1%,x:%2%,y%3%,face:%4%");
		fmt % (int)pJump->sceneId % (int)pJump->x % (int)pJump->y % (int)pJump->face;
		cout<<fmt<<endl;
#endif
	}
	else
	{
		if(pUser->GetFightId() == 0 && pUser->CanMeetEnemy())
		{
			int srcSceneId = pScene->GetSrcSceneId();
			if(srcSceneId >= KUN_LUN_SHAN_SCENE_ID && srcSceneId < KUN_LUN_SHAN_SCENE_ID+30)
				pScene->KunLunShanFight(ptr);
			else if(srcSceneId >= FEI_XIAN_SID1 && srcSceneId <= FEI_XIAN_SID5)
				pScene->FeiXianFight(ptr);
#ifdef KUA_FU
			else if(srcSceneId == KUN_LUN_SHAN_TEAM_SCENE_ID)
				pScene->KunLunShanTeamFight(ptr);
#endif
			else
				pScene->MeetEnemy(ptr);
		}
	}
	return true;
}

void CPackageDeal::RoleMove(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint16 x;
	uint16 y;
	msg>>x>>y;

	if((pUser->GetFightId() != 0) || pUser->InJump())
		return;

	if((pUser->GetTeam() != 0) && (pUser->GetTeam() != pUser->GetRoleId()) && !pUser->TempLeaveTeam())
	{
		return;
	}

	CScene *pScene = pUser->GetScene();
	if(pScene == NULL)
		return;
	if(!pScene->CheckPos(x,y))
		return;

	uint16 origx,origy;
	pUser->GetOrigPos(origx,origy);
	if(!pUser->Move(x,y))
	{
		SingletonSocket::instance().CloseConnect(sock);
		return;
	}

	int dx = (int)origx - (int)x;
	int dy = (int)origy - (int)y;
	if(dx*dx + dy*dy >= 64*64)
	{
		pScene->UserMove(pUser,x,y);
		pUser->SetOrigPos(x,y);
	}

	UserMoveOneStep(pUser,pScene,ptr,x,y);
}

void CPackageDeal::SendJumpPoint(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 x,y;
	uint16 sceneId;
	msg>>x>>y>>sceneId;
	CScene *pScene = pUser->GetScene();
	if(pScene == NULL)
	{
		return;
	}
	pScene->SendJumpPoint(pUser);
}

void CPackageDeal::ClientJump(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 x,y;
	uint16 sceneId;
	msg>>x>>y>>sceneId;
	CScene *pScene = pUser->GetScene();
	if(pScene == NULL)
	{
		return;
	}
	if(pScene->GetMapId() == sceneId)
	{
		if(!UserMoveOneStep(pUser,pScene,ptr,x,y))
			m_socketServer.SendMsg(pUser->GetSock(),msg);
	}
}

void CPackageDeal::OnSockClose(int sock)
{
	ShareUserPtr ptr = m_onlineUser.GetUserBySock(sock);
	CUser *pUser = ptr.get();
	if (pUser != NULL)
	{
		UserLogout(pUser);
	}
}

void CPackageDeal::UserLogout(CUser *pUser)
{
/*	uint32 guanzhanFight = pUser->GetGuanZhan();
	if(guanzhanFight != 0)
	{
		ShareFightPtr ptr = SingletonFightManager::instance().FindFight(guanzhanFight);
		if(ptr.get() != NULL)
		{
			ptr->LeaveGuanZhan(pUser);
		}
	}
*/
	uint32 fightId = pUser->GetFightId();
	if(fightId != 0)
	{
		ShareFightPtr ptr = SingletonFightManager::instance().FindFight(fightId);
		if(ptr.get() != NULL)
		{
			m_onlineUser.DelUser(pUser);
			pUser->SetAutoFightTurn(0xff);
			pUser->UserLogout(true);
			return;
		}
	}

#ifndef KUA_FU
//	pUser->ExitFishRoom();
#endif

	m_onlineUser.DelUser(pUser);
	pUser->UserLogout(true);
#ifdef KUA_FU
	CopyKuaFuDataToGameServer(pUser->GetRoleId(),pUser->GetServerId());
#endif

	pUser->UserLogout(true);
	pUser->SyncPowerToMatch(); // 同步战力给匹配服
	m_onlineUser.DelUser(pUser);
}

void CPackageDeal::OpenNpcInteract(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint16 npcId = 0;
	uint16 npcIdx = 0;
	uint16 missionId = 0;
	msg>>npcId>>npcIdx>>missionId;

	if ((GetSysTime()-pUser->m_npcInteractTimeout) < 2) // 目前设置超时未两秒钟
		return;
	if(pUser->GetTeam() != 0 && pUser->GetTeam() != pUser->GetRoleId())
	{
		CloseInteract(pUser);
		return;
	}

	SNpcInstance *pNpc = pUser->GetInteractNpc(npcId, npcIdx);
	if(pNpc == NULL || pNpc->pNpc == NULL)
		return;
	
	msg.ReWrite();
	msg.SetType(PRO_OPEN_INTERACT);
	uint16 x,y;
	pUser->GetPos(x,y);
	if((x-pNpc->x)*(x-pNpc->x) + (y-pNpc->y)*(y-pNpc->y) <= NPC_Distance*NPC_Distance)
	{
		pUser->SetInteractNpc(pNpc);
		pUser->SetCall(0,"");
		pUser->SetScriptCallOption();

		if(SingletonCMissionManager::instance().CheckCMissionNpcInteract(pUser,npcId,npcIdx,missionId))
		{
			msg<<PRO_SUCCESS;
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}

		CCallScript *pScript = NULL;
		if(pNpc->pNpc != NULL)
		{
			pScript = pNpc->pNpc->pScript;
			if(pScript != NULL)
			{
				pUser->SetCollectIndex(npcIdx);
				pUser->SetCallScript(pScript->GetScriptId());
				if(npcIdx == 0)
					pScript->Call("NpcMain","ui",pUser,missionId);
				else
					pScript->Call("NpcMain","uii",pUser,missionId,npcIdx);
			}
		}

		msg<<PRO_SUCCESS;
		m_socketServer.SendMsg(pUser->GetSock(),msg);
		return;
	}

	cout<<"OpenNpcInteract Error ux = "<<x<<", uy = "<<y<<" , npcx = "<<pNpc->x<<", npcy = "<<pNpc->y<<endl;
	msg<<PRO_ERROR;
	m_socketServer.SendMsg(pUser->GetSock(),msg);
}

void CPackageDeal::IgnoreNpcDialog(CNetMessage *pMsg,int sock)
{
	GET_USER
	if(pUser->GetKuaFuState() != EKFS_IN_LOCAL)
		return;
	if(pUser->GetFightId() != 0)
		return;
	if(pUser->InScriptCall())
		return;
	SingletonCMissionManager::instance().PlayNpcAct(pUser,true);
}
void CPackageDeal::NpcInteract(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	if(pUser->GetKuaFuState() != EKFS_IN_LOCAL)
		return;
	if(pUser->GetFightId() != 0)
		return;

	if(pUser->InScriptCall())
		return;
	uint8 op = 0;
	uint8 num = 0;
	uint8 type;
	msg>>op;

	// The shipped client still exposes a local debug packet on PRO_INTERACT:
	// op=50, uint32 itemId, uint16 itemNum. Never parse it as NPC arguments.
	if(op == 50)
	{
		if(gyu::util::CIniFile::GetValue("local_test","server",gConfigFile) != "1")
			return;
		uint32 itemId = 0;
		uint16 itemNum = 0;
		msg>>itemId>>itemNum;
		if(itemId == 0 || itemId > 0xffff || itemNum == 0 || itemNum > 100)
			return;
		if(!pUser->AddPackage((int)itemId,itemNum))
			cout<<"[local] NpcInteract add-item rejected itemId="<<itemId<<" num="<<itemNum<<endl;
		return;
	}
	// Local isolated-role task validation: op=51, uint16 condition, uint16 amount.
	// This is deliberately unavailable outside local_test and only drives the
	// normal mission manager path so production task behaviour remains unchanged.
	if(op == 51)
	{
		if(gyu::util::CIniFile::GetValue("local_test","server",gConfigFile) != "1")
			return;
		uint16 condition = 0;
		uint16 amount = 0;
		msg>>condition>>amount;
		if(condition == 0 || amount == 0 || amount > 100)
			return;
		SingletonCMissionManager::instance().UpdateQuestState(pUser, condition, amount);
		return;
	}
	// Local isolated-role currency validation: op=52, uint16 awardType,
	// int32 delta. Restrict it to the two main HUD currencies.
	if(op == 52)
	{
		if(gyu::util::CIniFile::GetValue("local_test","server",gConfigFile) != "1")
			return;
		uint16 awardType = 0;
		int delta = 0;
		msg>>awardType>>delta;
		if((awardType != HDAT_MONEY && awardType != HDAT_YB) || delta <= 0 || delta > 10000)
			return;
		pUser->AddMaterial(awardType, delta, false, false);
		return;
	}
	// Local isolated-role hero equipment validation: op=53, uint8 kind,
	// uint16 templateId. kind=1 adds equipment, kind=2 adds FaBao. The normal
	// manager path emits the authoritative /319 op=6/op=22 update packet.
	if(op == 53)
	{
		if(gyu::util::CIniFile::GetValue("local_test","server",gConfigFile) != "1")
			return;
		uint8 kind = 0;
		uint16 templateId = 0;
		msg>>kind>>templateId;
		if(templateId == 0)
			return;
		CEquipManeger& equipMgr = pUser->GetPetEquipMgr();
		bool added = kind == 1 ? equipMgr.AddEquip(pUser, templateId)
			: kind == 2 ? equipMgr.AddFaBao(pUser, templateId) : false;
		if(!added)
			cout<<"[local] NpcInteract add hero equipment rejected kind="<<(int)kind
				<<" templateId="<<templateId<<endl;
		return;
	}
	// Local isolated-role mail validation: op=54 inserts a deterministic mail
	// matrix directly into the game DB. Production mail routing still goes
	// through the long server and is untouched outside local_test.
	if(op == 54)
	{
		if(gyu::util::CIniFile::GetValue("local_test","server",gConfigFile) != "1")
			return;
		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		if(pDb == NULL)
			return;
		char sql[2048];
		snprintf(sql, sizeof(sql),
			"delete from xin_shi where to_id=%u and message like 'Unity mail validation%%'",
			pUser->GetRoleId());
		pDb->Query(sql);
		// Freeze the local-only fixture to one UTC-day baseline so SQLite and
		// MySQL emit byte-identical expireAt values even when run minutes apart.
		const uint32 fixtureBaseTime = (uint32)(GetSysTime() / 86400 * 86400 + 43200);
		for(int index = 13; index >= 0; --index)
		{
			int rewardCount = index == 0 ? 9 : index == 1 ? 2 : index == 2 ? 1 : (index % 3 == 0 ? 0 : 1);
			SMailData mailData;
			for(int rewardIndex = 0; rewardIndex < rewardCount; ++rewardIndex)
			{
				SAwardData award;
				award.type = 3201 + (rewardIndex % 3);
				award.typeId = 0;
				award.num = rewardIndex + 1;
				mailData.awards.push_back(award);
			}
			string attachment;
			MakeMailAttachStr(attachment, &mailData);
			const char *body = index == 3
				? "Unity mail validation long body\n"
				  "01 This paragraph verifies vertical mail body scrolling.\n"
				  "02 This paragraph verifies vertical mail body scrolling.\n"
				  "03 This paragraph verifies vertical mail body scrolling.\n"
				  "04 This paragraph verifies vertical mail body scrolling.\n"
				  "05 This paragraph verifies vertical mail body scrolling.\n"
				  "06 This paragraph verifies vertical mail body scrolling.\n"
				  "07 This paragraph verifies vertical mail body scrolling.\n"
				  "08 This paragraph verifies vertical mail body scrolling.\n"
				  "09 This paragraph verifies vertical mail body scrolling.\n"
				  "10 This paragraph verifies vertical mail body scrolling.\n"
				  "11 This paragraph verifies vertical mail body scrolling.\n"
				  "12 This paragraph verifies vertical mail body scrolling.\n"
				  "13 This paragraph verifies vertical mail body scrolling.\n"
				  "14 This paragraph verifies vertical mail body scrolling.\n"
				  "15 This paragraph verifies vertical mail body scrolling.\n"
				  "16 This paragraph verifies vertical mail body scrolling.\n"
				  "17 This paragraph verifies vertical mail body scrolling.\n"
				  "18 This paragraph verifies vertical mail body scrolling.\n"
				  "19 This paragraph verifies vertical mail body scrolling.\n"
				  "20 End of long mail body."
				: "Unity mail validation body.";
			snprintf(sql, sizeof(sql),
				"insert into xin_shi (money,YB,bdYB,attachment,from_id,to_id,gmtime,time,shenhun,deleted,from_name,message) "
				"values (0,0,0,'%s',0,%u,0,from_unixtime(%u),0,0,'System','Unity mail validation %02d - %s')",
				attachment.c_str(), pUser->GetRoleId(), fixtureBaseTime - index, index + 1, body);
			pDb->Query(sql);
		}
		return;
	}
	// Local isolated-role FengShenStory validation: op=58, uint16 petLevel.
	// Raise only the current disposable role's owned pets, matching the
	// reversible historical fixture without exposing this path outside
	// local_test. Normal /320 op25 still owns battle, rewards, and persistence.
	if(op == 58)
	{
		if(gyu::util::CIniFile::GetValue("local_test","server",gConfigFile) != "1")
			return;
		uint16 petLevel = 0;
		msg>>petLevel;
		if(petLevel == 0 || petLevel > 100)
			return;
		vector<uint16> petIds;
		pUser->GetPetIdList(petIds);
		for(size_t i = 0; i < petIds.size(); ++i)
		{
			SharePetPtr pet = pUser->GetPet(petIds[i]);
			if(pet.get() == NULL)
				continue;
			pet->level = petLevel;
			pet->exp = 0;
			pet->Init(pUser);
		}
		return;
	}
	// Local isolated-role Arena restart validation: op=59.
	// Flush the production Arena manager snapshot on demand so the short S5
	// process lifecycle exercises the same SQL path as the scheduled/server
	// shutdown save instead of waiting for the twice-daily timer.
	if(op == 59)
	{
		if(gyu::util::CIniFile::GetValue("local_test","server",gConfigFile) != "1")
			return;
		SingletonCArenaManager::instance().Save();
		return;
	}
	// Local isolated-role PlayerHud validation: op=57, uint32 experience.
	// This invokes the production AddExp/level-up path so /18 and /226 remain
	// authoritative server pushes. It is unavailable outside local_test.
	if(op == 57)
	{
		if(gyu::util::CIniFile::GetValue("local_test","server",gConfigFile) != "1")
			return;
		uint32 experience = 0;
		msg>>experience;
		if(experience == 0 || experience > 1000000)
			return;
		pUser->AddExp(experience, false, false);
		return;
	}
	// Local isolated-role hero fixture: op=55, uint16 petId.
	// Use the normal award path so the authoritative pet store, client update
	// packet and persistence behaviour stay identical to regular gameplay.
	if(op == 55)
	{
		if(gyu::util::CIniFile::GetValue("local_test","server",gConfigFile) != "1")
			return;
		uint16 petId = 0;
		msg>>petId;
		if(petId == 0)
			return;
		if(!AddPet(pUser, petId, 1))
			cout<<"[local] NpcInteract add hero rejected petId="<<petId<<endl;
		return;
	}
	// Local isolated-role chapter fixture: op=56, uint8 type, uint16 chapters.
	// The implementation is debug-build only and advances through the normal
	// GuanQia container, which is then persisted with the role.
	if(op == 56)
	{
		if(gyu::util::CIniFile::GetValue("local_test","server",gConfigFile) != "1")
			return;
		uint8 type = 0;
		uint16 chapters = 0;
		msg>>type>>chapters;
		if((type != 1 && type != 2) || chapters == 0 || chapters > 100)
			return;
#ifdef _DEBUG
		pUser->GetGuanQia().GuanQiaGM(pUser, type, chapters);
#else
		cout<<"[local] NpcInteract chapter fixture requires a debug build"<<endl;
#endif
		return;
	}

	msg>>num;//>>input;

	if(op == 0)
	{
		CloseInteract(pUser);
		return;
	}

	if(num > 6)
		return;

	if(SingletonCMissionManager::instance().CheckCMissionNpcInteract(pUser,0,0,0))
		return;
	

	int optionSelect = 0x7fffffff;
	ArgList argList;
	argList.push_back(boost::any(pUser));

	for(uint8 i = 0; i < num; i++)
	{
		msg>>type;
		if(type == 0)
		{
			int inputInt = 0;
			msg>>inputInt;
			if(i == 0)
				optionSelect = inputInt;
			argList.push_back(boost::any(inputInt));
		}
		else
		{
			string input;
			msg>>input;
			argList.push_back(boost::any(input));
		}
	}

	int script = 0;
	string call = pUser->GetCall(script);

	char buf[128];
	snprintf(buf,sizeof(buf),"==  CPackageDeal::NpcInteract  scriptId=%d",script);
	gyu::util::TimePrint aa(buf);
	
	if(!pUser->IsScriptCallOptionEmpty())
	{
//		if(optionSelect != 0x7fffffff && optionSelect != 0 && !pUser->InScriptCallOption(optionSelect))
		if(!pUser->InScriptCallOption(optionSelect))
		{
			list<int> opList;
			pUser->GetScriptCallOption(opList);
			cout<<">> CPackageDeal::NpcInteract roleId="<<pUser->GetRoleId()<<", InScriptCallOption() optionSelect="<<optionSelect<<", return"<<endl;
			for(list<int>::iterator i=opList.begin(); i != opList.end(); i++)
				cout<<">> CPackageDeal::NpcInteract optionList="<<*i<<endl;
			return;
		}
		pUser->SetScriptCallOption();
	}

	if(call.empty())
	{
//		cout<<">> CPackageDeal::NpcInteract call empty"<<endl;
#ifdef DEBUG
		cout<<"could fond find script:"<<script<<endl;
#endif
		CloseInteract(pUser);
		return;
	}
	pUser->SetCall(0,"");

	CCallScript *pCallScript = FindScript(script);//(name);
	if(pCallScript != NULL)
	{
		pUser->SetCallScript(pCallScript->GetScriptId());
		pCallScript->Call(call.c_str(),&argList);
	}
	else
	{
	}
}

void CPackageDeal::GetItemInfo(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 op = 0;
	uint8 ind = 0;
	msg>>op>>ind;

	if(op == 1)
	{
		//查看背包信息
		if(!pUser->MakePackInfo(ind,msg))
			return;
	}
	else
	{
		return;
	}
	m_socketServer.SendMsg(pUser->GetSock(),msg);
}

void CPackageDeal::GetOtherUserItemInfo(CNetMessage *pMsg,int sock)
{
	GET_MSG

	uint8 op = 0;
	uint32 userId = 0;
	uint8 ind = 0;
	ShareUserPtr ptrMe = m_onlineUser.GetUserBySock(sock);
	CUser *pMe = ptrMe.get();
	if((pMe == NULL) || (pMe->GetRoleId() == 0))
		return;

	msg>>op>>userId>>ind;

	ShareUserPtr ptr = m_onlineUser.GetUserByRoleId(userId);
	CUser *pUser = ptr.get();
	bool online = true;
	if(pUser == NULL)
	{
		online = false;
		pUser = new CUser;
		if(pUser == NULL)
		{
			delete pUser;
			return;
		}
		else
		{
			CGetDbConnect getDb;
			CDatabaseSql *pDb = getDb.GetDbConnect();
			if(pDb == NULL)
			{
				delete pUser;
				return;
			}
			char sql[128];
			char **row = NULL;
			snprintf(sql,sizeof(sql),"select package from role_info where id=%u",userId);
			if(!pDb->Query(sql))
			{
				delete pUser;
				return;
			}
			if((row = pDb->GetRow()) != NULL)
			{
				pUser->SetPackage(row[0]);
			}
			else
			{
				delete pUser;
				return;
			}
		}
	}

	if(op == 1)
	{
		//查看背包信息
		if(!pUser->MakePackInfo(ind,msg))
			return;
	}
	else
	{
		return;
	}
	m_socketServer.SendMsg(pMe->GetSock(),msg);
	if(!online)
		delete pUser;
}

void CPackageDeal::UserTeamOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER
	//// CHECK_SYSTEM_OPEN(SOT_Team)
	const uint32 SHOW_CAN_JOIN_NUM = 50;
	CScene *pScene = pUser->GetScene();
	if(pScene == NULL)
		return;
	if(pUser->InHuSongMission() == 1)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_864,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	else if(pUser->InHuSongMission() == 2)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_865,TIPS_FAILURE_COLOR).c_str());
		return;
	}

	if(pUser->HaveBitSet(156))
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_866,TIPS_FAILURE_COLOR).c_str());
		return;
	}

	uint8 op = 0;
	msg>>op;
//	if((pScene->IsFuBen()) && (op != 9) && (op != 11)) // 玩家主动退出队伍除外
//	{
//		SendSysInfo(pUser,MakeStringColor("本场景不能进行组队操作",TIPS_FAILURE_COLOR).c_str());
//		return;
//	}
	switch(op)
	{
		case 1:		// 创建队伍
			{
				if(pUser->GetTeam() > 0 || pUser->TempLeaveTeam() > 0)
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_867,TIPS_FAILURE_COLOR).c_str());
					return;
				}
				CScene *pScene = pUser->GetScene();
				if(pScene == NULL)
					return;
				if(pScene != NULL && !pScene->CanJoinTeam())
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_868,TIPS_FAILURE_COLOR).c_str());
					return;
				}
				
//				uint16 srcId = pScene->GetSrcSceneId();
//				if(srcId == 47)
//				{
//					if((pScene->GetId()>>16) != (int)pUser->GetBangPai())
//					{
//						SendSysInfo(pUser,MakeStringColor("非本帮领地，此功能暂时无法使用",TIPS_FAILURE_COLOR).c_str());
//						return;
//					}
//				}
				pScene->CreateTeam(pUser);
				pScene->UpdateTeamData(pUser->GetRoleId());
				break;
			}
		case 2:		// 申请加入队伍
			{
				CScene *pScene = pUser->GetScene();
				if(pScene != NULL && !pScene->CanJoinTeam())
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_869,TIPS_FAILURE_COLOR).c_str());
					return;
				}
				
				uint32 headId = 0;
				msg>>headId;
				if(pUser->GetTeam() > 0 || pUser->TempLeaveTeam() > 0)
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_870,TIPS_FAILURE_COLOR).c_str());
				else
					pScene->AskForJoinTeam(pUser,headId);
				break;
			}
		case 3:		// 队伍列表
			{
				uint8 page = 0;
				msg>>page;
				pScene->GetTeamList(pUser,page);
				break;
			}
		case 4:		// 队长同意入队申请
			{
				if(pUser->GetTeam() == 0 || pUser->GetTeam() != pUser->GetRoleId())
					return;
				uint32 memberId = 0;
				uint8 agree = 0;
				msg>>agree>>memberId;
				if(agree == 1)
					pScene->AllowJoinTeam(pUser,memberId);
				else
					pScene->NotAllowJoin(pUser,memberId);
				break;
			}
		case 5:		// 创建队伍并邀请玩家，或邀请玩家加入
			{
//				if(GetSysTime() - pUser->GetActivityTime() < 3)
//				{
//					SendSysInfo(pUser,MakeStringColor("你邀请组队过快",TIPS_FAILURE_COLOR).c_str());
//					return;
//				}
//				pUser->SetActivityTime(GetSysTime());
				CScene *pScene = pUser->GetScene();
				if(pScene != NULL && !pScene->CanJoinTeam())
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_871,TIPS_FAILURE_COLOR).c_str());
					return;
				}

				uint32 requestId = 0;
				msg>>requestId;
				pScene->CreateTeam(pUser,requestId);
				pScene->UpdateTeamData(pUser->GetRoleId());
				break;
			}
		case 6:		// 玩家选择是否接受邀请
			{
				if(pUser->GetTeam() > 0 || pUser->TempLeaveTeam() > 0)
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_872,TIPS_FAILURE_COLOR).c_str());
					return;
				}
				CScene *pScene = pUser->GetScene();
				if(pScene != NULL && !pScene->CanJoinTeam())
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_873,TIPS_FAILURE_COLOR).c_str());
					return;
				}
				uint32 headId = 0;
				uint8 agree = 0;
				msg>>agree;
				msg>>headId;
				if(agree == 1)	// 同意入队
					pScene->AskForJoinTeam(pUser,headId,1);
				else
					pScene->RefuseJoinTeam(pUser,headId);
				break;
			}
		case 7:
			{
				uint8 page = 0;
				msg>>page;
				pScene->NotInTeamUser(page,msg);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				break;
			}
		case 8:		// 请求队伍成员列表
			{
				pScene->GetTeamMembers(pUser);
				break;
			}
		case 9:		// 离开队伍
			{
				if(pScene->IsFuBen())
				{
					pUser->ExitFuBen();
				}
				pScene->LeaveTeam(pUser);
				break;
			}
		case 10:	// 队长剔除队员
			{
				uint32 memberId;
				msg>>memberId;
				pScene->DelTeamMember(pUser,memberId);
				break;
			}
			
		case 11:	// 更换队长
			{
				uint32 memberId = 0;
				msg>>memberId;
				pScene->SetNewHead(pUser,memberId);
				break;
			}
		case 12:	// 暂离队伍
			{
				if(pUser->TempLeaveTeam() > 0)
					return;
				if(pUser->GetRoleId() == pUser->GetTeam())
					return;
				pScene->TempLeaveTeam(pUser);
				break;
			}
		case 13:	// 队员归队
			{
				if(pUser->GetTeam() != 0 || pUser->TempLeaveTeam() == 0)
					return;
				pScene->ReturnTeam(pUser);
				break;
			}
		case 14:	// 召回
			{
				if(pUser->GetTeam() == 0 || pUser->TempLeaveTeam() == 0)
					return;
				uint8 accept = 0;
				msg>>accept;
				if(accept == 1)
					pScene->ReturnTeam(pUser);
				break;
			}
		case 15:	// 集合
			{
				if(GetSysTime() - pUser->GetTeamCallTime() < 20)
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_874,TIPS_FAILURE_COLOR).c_str());
					return;
				}
				pUser->SetTeamCallTime(GetSysTime());
				
				pScene->CallBackTeam(pUser);
				break;
			}
		case 16:	// 获得组队详细信息
			{
				pScene->GetTeamData(pUser);
				break;
			}
		case 17:	// 队伍出战阵容
			{
				break;
			}
		case 18:	// 队员1和队员2对调位置
			{
				break;
			}
		case 19:	// 玩家拒绝加入队伍,服务器主动推送
			{
				break;
			}
		case 20:	// 设置队伍信息
			{
				uint8 fabu = 0;	// 1 发布 0 不发布
				uint8 type = 0;
				uint16 minLevel = 0;
				uint16 maxLevel = 0;
				msg>>fabu>>type>>minLevel>>maxLevel;
				SetTeamFaBuInfo(pUser,type,minLevel,maxLevel,fabu);
				break;
			}
		case 21:	// 取消队伍发布消息(不用)
			{
/*
				uint8 type = 0;
				uint32 teamId = 0;
				msg>>type>>teamId;
				if(pUser->GetTeam() == 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_884,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				if(pUser->GetTeam() != teamId)
					return;
				if(pUser->GetTeam() != pUser->GetRoleId())
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_885,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				CTeamFaBuConfigMgr &mgr = SingletonTeamFaBuCfgMgr::instance();
				if(!mgr.FindTeamByType(type,teamId))
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_886,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
				}
				else
				{
					mgr.RemoveFaBuTeam(type,teamId);
					msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_TRANSFORM_887,TIPS_WARNING_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);

					pScene->SetTeamFaBuStatus(teamId,false);
				}
*/
				break;
			}
		case 22:	// 获得发布队伍列表
			{
				uint8 type = 0;
				msg>>type;
				uint16 srcType = pUser->GetTeamUIQueryType();
				uint32 srcTime = pUser->GetTeamUIQueryTime();
				uint32 curTime = GetSysTime();
				if((uint16)type == srcType && curTime < srcTime + 1)
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_ZDL_0822,TIPS_FAILURE_COLOR).c_str());
					return;
				}
				pUser->SetTeamUIQueryType(type);
				pUser->SetTeamUIQueryTime(curTime);
				
				SendTeamListByType(pUser,type);
				break;
			}
		case 23:	// 便捷组队列表中加入队伍(不用队长同意)
			{
				if(pUser->HaveTeam())
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_888,TIPS_FAILURE_COLOR).c_str());
					return;
				}
				
				uint8 type = 0;
				uint32 teamId = 0;
				msg>>type>>teamId;

				STeamFaBuData teamInfo;
				if(!SingletonTeamFaBuCfgMgr::instance().GetFaBuTeamInfo(type,teamId,teamInfo) || teamInfo.teamId == 0)
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0394,TIPS_FAILURE_COLOR).c_str());
					return;
				}
				uint16 level = pUser->GetLevel();
				if(level < teamInfo.minLevel || level > teamInfo.maxLevel)
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0395,TIPS_FAILURE_COLOR).c_str());
					return;
				}
				
				ShareUserPtr pTeamLeader = m_onlineUser.GetUserByRoleId(teamId);
				if(pTeamLeader.get() == 0)
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_889,TIPS_FAILURE_COLOR).c_str());
					return;
				}
				pScene = pTeamLeader->GetScene();
				if(pScene == NULL)
					return;
				bool res = pScene->AllowJoinTeam(pTeamLeader.get(),pUser->GetRoleId(),true);
				if(!res)
				{
					msg<<PRO_ERROR;
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					SendTeamListByType(pUser,type);
				}
				else
				{
					msg<<PRO_SUCCESS;
					m_socketServer.SendMsg(pUser->GetSock(),msg);
				}
				break;
			}
		case 24:	// 个人开启便捷组队匹配
			{
				if(pUser->HaveTeam())
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_890,TIPS_FAILURE_COLOR).c_str());
					return;
				}
				
				uint8 type = 0;
				msg>>type;

				bool res = SingletonTeamFaBuCfgMgr::instance().PlayerMatchFaBuTeam(type,pUser->GetRoleId(),true);
				if(res)
				{
					pUser->m_autoMatchTeamType = type;
					msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_SSJ_0396,TIPS_WARNING_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
				}
				break;
			}
		case 25:	// 获取在线帮派成员列表
			{
				const uint16 QUETY_BANGPAI_TYPE = 501;
				uint16 srcType = pUser->GetTeamUIQueryType();
				uint32 srcTime = pUser->GetTeamUIQueryTime();
				uint32 curTime = GetSysTime();
				if(QUETY_BANGPAI_TYPE == srcType && curTime < srcTime + 1)
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_ZDL_0822,TIPS_FAILURE_COLOR).c_str());
					return;
				}
				pUser->SetTeamUIQueryType(QUETY_BANGPAI_TYPE);
				pUser->SetTeamUIQueryTime(curTime);
			
				uint32 teamId = pUser->GetTeam();
				if(teamId == 0)
				{
					teamId = pUser->TempLeaveTeam();
					if(teamId == 0)
						SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0391,TIPS_FAILURE_COLOR).c_str());
					else
						SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0392,TIPS_FAILURE_COLOR).c_str());
					return;
				}
				uint32 bangpai = pUser->GetBangPai();
				if(bangpai == 0)
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0393,TIPS_FAILURE_COLOR).c_str());
					return;
				}
				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(bangpai);
				if(pBangPai == NULL)
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0393,TIPS_FAILURE_COLOR).c_str());
					return;
				}

				ShareUserPtr leader = m_onlineUser.GetUserByRoleId(teamId);
				if(leader.get() == NULL)
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0399,TIPS_FAILURE_COLOR).c_str());
					return;
				}
				CScene *pScene = leader->GetScene();
				if(pScene == NULL)
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0399,TIPS_FAILURE_COLOR).c_str());
					return;
				}
				
				list<uint32> memList;
				pBangPai->GetMember(memList);
				uint16 pos = msg.GetDataLen();
				uint16 num = 0;
				msg<<num;
				for(list<uint32>::iterator it=memList.begin(); it != memList.end(); it++)
				{
					ShareUserPtr p = m_onlineUser.GetUserByRoleId(*it);
					CUser *pU = p.get();
					if(pU != NULL && pU->GetTeam() == 0 && pU->TempLeaveTeam() == 0)
					{
						uint8 state = (pScene->IsInTeamRequest(leader.get(),*it)) ? 1 : 0;
						msg<<pU->GetRoleId()<<pU->GetName()<<pU->GetSex()<<pU->GetLevel()<<pU->GetZhanDouLi()<<state;
						num++;
					}
					if(num >= SHOW_CAN_JOIN_NUM)
						break;
				}
				msg.WriteData(pos,&num,sizeof(num));
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			break;
		case 26:	// 个人取消便捷组队自动匹配
			{
				int type = pUser->m_autoMatchTeamType;
				if(type == 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0397,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
				}
				
				pUser->m_autoMatchTeamType = 0;
				SingletonTeamFaBuCfgMgr::instance().RemoveMatchUser(type,pUser->GetRoleId());
				msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_SSJ_0398,TIPS_WARNING_COLOR);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			break;
		case 27:	// 推送队伍设置信息
			{
				// 服务器主动推送
			}
			break;
		case 28:	// 邀请组队界面请求周围玩家
			{
				const int SHOW_MAX_DISTANCE = 1500;
				const uint16 QUETY_NEAR_PLAYER_TYPE = 502;
				uint16 srcType = pUser->GetTeamUIQueryType();
				uint32 srcTime = pUser->GetTeamUIQueryTime();
				uint32 curTime = GetSysTime();
				if(QUETY_NEAR_PLAYER_TYPE == srcType && curTime < srcTime + 1)
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_ZDL_0822,TIPS_FAILURE_COLOR).c_str());
					return;
				}
				pUser->SetTeamUIQueryType(QUETY_NEAR_PLAYER_TYPE);
				pUser->SetTeamUIQueryTime(curTime);
				
				uint32 teamId = pUser->GetTeam();
				if(teamId == 0)
				{
					teamId = pUser->TempLeaveTeam();
					if(teamId == 0)
						SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0391,TIPS_FAILURE_COLOR).c_str());
					else
						SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0392,TIPS_FAILURE_COLOR).c_str());
					return;
				}

				ShareUserPtr leader = m_onlineUser.GetUserByRoleId(teamId);
				if(leader.get() == NULL)
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0399,TIPS_FAILURE_COLOR).c_str());
					return;
				}
				CScene *pScene = leader->GetScene();
				if(pScene == NULL)
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0399,TIPS_FAILURE_COLOR).c_str());
					return;
				}

				CScene *pMyScene = pUser->GetScene();
				if(pMyScene == NULL)
					return;
				list<uint32> userList;
				pMyScene->GetUserList(userList);
				uint16 x = 0,y=0;
				pUser->GetPos(x,y);
				int ix = x,iy = y;
				
				uint16 pos = msg.GetDataLen();
				uint16 num = 0;
				msg<<num;
				for(list<uint32>::iterator it=userList.begin(); it != userList.end(); it++)
				{
					ShareUserPtr p = m_onlineUser.GetUserByRoleId(*it);
					CUser *pU = p.get();
					if(pU != NULL && pU->GetTeam() == 0 && pU->TempLeaveTeam() == 0)
					{
						uint16 x1 = 0,y1=0;
						pU->GetPos(x1,y1);
						int ix1 = x1,iy1 = y1;
						if((ix - ix1)*(ix - ix1) + (iy - iy1)*(iy - iy1) > SHOW_MAX_DISTANCE*SHOW_MAX_DISTANCE)
							continue;
						uint8 state = (pScene->IsInTeamRequest(leader.get(),*it)) ? 1 : 0;
						msg<<pU->GetRoleId()<<pU->GetName()<<pU->GetSex()<<(uint16)pU->GetLevel()<<pU->GetZhanDouLi()<<state;
						num++;
					}
					if(num >= SHOW_CAN_JOIN_NUM)
						break;
				}
				msg.WriteData(pos,&num,sizeof(num));
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			break;
		case 29:	// 邀请组队界面请求好友
			{
				const uint16 QUETY_HOTS_TYPE = 503;
				uint16 srcType = pUser->GetTeamUIQueryType();
				uint32 srcTime = pUser->GetTeamUIQueryTime();
				uint32 curTime = GetSysTime();
				if(QUETY_HOTS_TYPE == srcType && curTime < srcTime + 1)
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_ZDL_0822,TIPS_FAILURE_COLOR).c_str());
					return;
				}
				pUser->SetTeamUIQueryType(QUETY_HOTS_TYPE);
				pUser->SetTeamUIQueryTime(curTime);
				
				uint32 teamId = pUser->GetTeam();
				if(teamId == 0)
				{
					teamId = pUser->TempLeaveTeam();
					if(teamId == 0)
						SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0391,TIPS_FAILURE_COLOR).c_str());
					else
						SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0392,TIPS_FAILURE_COLOR).c_str());
					return;
				}

				ShareUserPtr leader = m_onlineUser.GetUserByRoleId(teamId);
				if(leader.get() == NULL)
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0399,TIPS_FAILURE_COLOR).c_str());
					return;
				}
				CScene *pScene = leader->GetScene();
				if(pScene == NULL)
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0399,TIPS_FAILURE_COLOR).c_str());
					return;
				}
/*				
				uint16 pos = msg.GetDataLen();
				uint16 num = 0;
				msg<<num;
				for(list<HotInfo>::iterator it=hotList.begin(); it != hotList.end(); it++)
				{
					ShareUserPtr p = m_onlineUser.GetUserByRoleId(it->hotId);
					CUser *pU = p.get();
					if(pU != NULL && pU->GetTeam() == 0 && pU->TempLeaveTeam() == 0)
					{
						uint8 state = (pScene->IsInTeamRequest(leader.get(),it->hotId)) ? 1 : 0;
						msg<<pU->GetRoleId()<<pU->GetName()<<pU->GetSex()<<(uint16)pU->GetLevel()<<pU->GetZhanDouLi()<<state;
						num++;
					}
					if(num >= SHOW_CAN_JOIN_NUM)
						break;
				}
				msg.WriteData(pos,&num,sizeof(num));
				m_socketServer.SendMsg(pUser->GetSock(),msg);
*/
			}
			break;
		case 30:	// 世界喊话
			{
				const uint32 WORLD_CHAT_TIME = 60;
				uint32 teamId = pUser->GetTeam();
				if(teamId == 0 || teamId != pUser->GetRoleId())
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0200,TIPS_FAILURE_COLOR).c_str());
					return;
				}
				CScene *pScene = pUser->GetScene();
				if(pScene == NULL)
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0408,TIPS_FAILURE_COLOR).c_str());
					return;
				}
				CUserTeam *pTeam = pScene->GetTeam(teamId);
				if(pTeam == NULL)
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0408,TIPS_FAILURE_COLOR).c_str());
					return;
				}
				int teamNum = pTeam->GetMemberNum() + pTeam->GetLeaveNum();
				if(teamNum >= MAX_TEAM_MEMBER)
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0411,TIPS_FAILURE_COLOR).c_str());
					return;
				}

				char buf[512];
				uint32 curTime = GetSysTime();
				if(curTime < pTeam->m_lastWorldChatTime + WORLD_CHAT_TIME)
				{
					int cd = WORLD_CHAT_TIME - (curTime - pTeam->m_lastWorldChatTime);
					snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0412,cd);
					SendSysInfo(pUser,MakeStringColor(buf,TIPS_FAILURE_COLOR).c_str());
					return;
				}
				pTeam->m_lastWorldChatTime = curTime;

				STeamFaBuData teamInfo;
				int type = 0;
				if(!SingletonTeamFaBuCfgMgr::instance().GetFaBuTeamInfo(teamId,teamInfo,type) || type == 0 || teamInfo.teamId != teamId)
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0407,TIPS_FAILURE_COLOR).c_str());
					return;
				}
				STeamFaBuCfgData *pCfg = SingletonTeamFaBuCfgMgr::instance().GetCfg(type);
				if(pCfg == NULL)
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0408,TIPS_FAILURE_COLOR).c_str());
					return;
				}

				snprintf(buf,sizeof(buf),"[c3]%s%u-%u%s(%d/%d)[/c][d|2,%u,%s]",pCfg->name.c_str(),teamInfo.minLevel,teamInfo.maxLevel,
					LANGUAGE_SSJ_0409,teamNum,MAX_TEAM_MEMBER,teamId,LANGUAGE_SSJ_0410);
				SendTeamInfoToWorldChat(pUser,buf);
			}
			break;
		case 31:	// 更新队伍内玩家等级, 服务器主动推送
			{

			}
			break;
		case 32:	// 请求其他角色队伍信息
			{
				uint32 roleId = 0;
				msg>>roleId;
				if(roleId == 0)
					return;
				ShareUserPtr Other = m_onlineUser.GetUserByRoleId(roleId);
				CUser *pOther = Other.get();
				if(Other == NULL)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2681,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}
				uint32 teamId = pOther->GetTeam();
				if(teamId == 0)
					teamId = pOther->TempLeaveTeam();
				msg<<PRO_SUCCESS<<teamId;
				m_socketServer.SendMsg(sock,msg);
			}
			break;
		
		default:
			break;
	}
}

void CPackageDeal::SendTeamListByType(CUser *pUser,uint8 type)
{
	const uint16 MAX_SHOW_NUM = 50;
	if(pUser == NULL)
		return;
	uint32 teamId = pUser->GetTeam();
	if(teamId == 0)
		teamId = pUser->TempLeaveTeam();
	list<STeamFaBuData> teamList;
	SingletonTeamFaBuCfgMgr::instance().GetFaBuList(type,teamList);

	uint8 teamNum = 0;
	CNetMessage msg;
	msg.SetType(PRO_USER_TEAM);
	msg<<(uint8)22<<type;
	uint16 pos = msg.GetDataLen();
	msg<<teamNum;

	if(teamId > 0)
	{
		STeamFaBuData data;
		data.teamId = teamId;
		list<STeamFaBuData>::iterator it = find(teamList.begin(),teamList.end(),data);
		if(it != teamList.end())
		{
			ShareUserPtr p = m_onlineUser.GetUserByRoleId(it->teamId);
			if(p.get() != NULL)
			{
				CScene *pScene = p->GetScene();
				if(pScene != NULL)
					teamNum += pScene->MakeTeamFaBuInfo(msg,*it);
			}
		}
	}

	for(list<STeamFaBuData>::iterator it=teamList.begin(); it != teamList.end(); it++)
	{
		if(it->teamId == teamId)
			continue;
		ShareUserPtr p = m_onlineUser.GetUserByRoleId(it->teamId);
		if(p.get() != NULL)
		{
			CScene *pScene = p->GetScene();
			if(pScene != NULL)
				teamNum += pScene->MakeTeamFaBuInfo(msg,*it);
		}
		if(teamNum >= MAX_SHOW_NUM)
			break;
	}
	msg.WriteData(pos,&teamNum,sizeof(teamNum));
	m_socketServer.SendMsg(pUser->GetSock(),msg);
}

void CPackageDeal::GetPlayerInfo(CNetMessage *pMsg,int sock)
{
	GET_MSG
	
	uint32 roleId = 0;
	msg>>roleId;
	if(roleId == 0)
	{
		//cout<<"GetPlayerInfo roleId:"<<roleId<<endl;
		return;
	}
	ShareUserPtr ptrMe = m_onlineUser.GetUserBySock(sock);
	CUser *pMe = ptrMe.get();
	if((pMe == NULL) || (pMe->GetRoleId() == 0))
		return;

	ShareUserPtr ptr1 = m_onlineUser.GetUserByRoleId(roleId);
	CUser *pU = ptr1.get();
	if(pU == NULL)
	{
		int srcSid = pMe->GetSrcSceneId();
		if(srcSid >= FEI_XIAN_SID1 && srcSid <= FEI_XIAN_SID4)
		{
			CScene *pScene = ptrMe->GetScene();
			if(pScene != NULL)
			{
				ptr1 = pScene->GetVisibleRobotPtr(roleId);
				pU = ptr1.get();
				if(pU == NULL)
					return;
			}
			else
				return;
		}
		else
			return;
	}

	msg.ReWrite();
	msg.SetType(PRO_PLAYER_INFO);
	pU->MakePlayerInfo(msg,pMe);
	pU->MakeOtherTitle(msg);
	m_socketServer.SendMsg(pMe->GetSock(),msg);
}

void CPackageDeal::PlayerPk(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	CScene *pScene = pUser->GetScene();
	if(pScene == NULL)
		return;

	uint8 op = 0xff;
	uint32 roleId = 0;
	msg>>op;
	if(op == 0)	// 邀请PK
	{
		uint16 sceneId = pScene->GetSrcSceneId();
		if(sceneId == BANG_PAI_SCENE_ID)
		{
			if((pScene->GetId()>>8) != (int)pUser->GetBangPai())
			{
				SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_893,TIPS_FAILURE_COLOR).c_str());
				return;
			}
		}

		msg>>roleId;
		if(roleId != pUser->GetRoleId())
			pScene->PlayerPk(ptr,roleId,true);
	}
	else if(op == 1)	// 对方选择
	{
		uint8 res;
		msg>>res;
		msg>>roleId;
		if(res == 0)	// 拒绝PK
		{
			ShareUserPtr User = m_onlineUser.GetUserByRoleId(roleId);
			CUser *pU = User.get();
			if(pU != NULL)
			{
				CNetMessage msg1;
				msg1.SetType(PRO_USER_PK);
				msg1 <<(uint8)1;
				m_socketServer.SendMsg(pU->GetSock(), msg1);
			}
		}
		else	// 接受PK
		{
			pScene->PlayerPk(ptr,roleId,false);
		}
	}
	else if(op == 2)	// 强制PK(击杀)
	{
		msg>>roleId;
		if(roleId == 0 || pUser->GetRoleId() == roleId)
			return;
		CNetMessage msg;
		msg.ReWrite();
		msg.SetType(PRO_USER_PK);
		msg<<op;
		if(pUser->GetKuaFuState() != EKFS_IN_LOCAL)
			return;
		if(pUser->GetFightId() != 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_894,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		ShareUserPtr tarUser = m_onlineUser.GetUserByRoleId(roleId);
		if(tarUser.get() == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_896,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		if(tarUser->GetKuaFuState() != EKFS_IN_LOCAL)
			return;
		if(tarUser->GetFightId() != 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_897,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		if(tarUser->GetSceneId() != pUser->GetSceneId())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_898,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}

		int srcSceneId = pScene->GetSrcSceneId();
		if(srcSceneId == BANG_PAI_SCENE_ID)
		{
			uint32 srcBangId = pUser->GetBangPai();
			uint32 tarBangId = tarUser->GetBangPai();
			if(srcBangId == tarBangId && srcBangId != 0)	// 同个帮派
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_899,TIPS_FAILURE_COLOR);
				m_socketServer.SendMsg(sock,msg);
				return;
			}
			msg<<PRO_SUCCESS;
			m_socketServer.SendMsg(sock,msg);

			pScene->BangPaiPKFight(ptr,tarUser);
		}
		else if(srcSceneId == SHENJIEMIJING_SCENE_ID)
		{
#ifdef KUA_FU
			int zoneId = GetServerZone(pUser->GetServerId());
			int tarZoneId = GetServerZone(tarUser->GetServerId());
			if(zoneId != tarZoneId)
			{
				uint32 curTime = GetSysTime();
				if (pUser->GetExtData32(365) > curTime)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0096,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}
				else if (tarUser->GetExtData32(365) > curTime)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0097,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}
				if (pUser->GetExtData32(301) + 60 > curTime)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0515,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}
				else if (tarUser->GetExtData32(301) + 60 > curTime)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0516,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}
				
				msg<<PRO_SUCCESS;
				m_socketServer.SendMsg(sock,msg);

				pScene->KuaFuBossPKFight(ptr,tarUser);
			}
#endif
		}
	}
}

void CPackageDeal::PlayerMatch(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER
	//// CHECK_SYSTEM_OPEN(SOT_Qiecuo)

	CScene *pScene = pUser->GetScene();
	if(pScene == NULL)
		return;

	uint32 roleId = 0;
	uint8 op = 0;
	msg>>op;
	switch(op)
	{
		case 0://发起切磋
			{
				/*if(pUser->GetLevel() <= 35)
					return;*/
				uint16 sceneId = pScene->GetSrcSceneId();
				if(sceneId == BANG_PAI_SCENE_ID)
				{
					if((pScene->GetId()>>8) != (int)pUser->GetBangPai())
					{
						SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_893,TIPS_FAILURE_COLOR).c_str());
						return;
					}
				}
				if (!pScene->CanQieCuo())
				{
					SendSysInfo(pUser, MakeStringColor(LANGUAGE_ZQX_0044, TIPS_FAILURE_COLOR).c_str());
					return;
				}
				uint8 mod = 0;
				msg>>mod;
				if(mod == 1)	// 指定玩家ID
				{
					msg>>roleId;
					if(roleId == pUser->GetRoleId())
						return;
				}
				pScene->PlayerAskForMatch(ptr,roleId);
				break;
			}
		case 1://被邀请方接受或者拒绝
			{
				uint8 accept = 0;
				msg>>accept;
				msg>>roleId;
				pScene->AcceptAskForMatch(ptr,accept!=0,roleId);
				break;
			}
	}
}

void CPackageDeal::NearPlayerList(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 page = 0;
	msg>>page;
	if(page < 1)
		return;

	CScene *pScene = pUser->GetScene();
	if(pScene == NULL)
		return;

	msg.ReWrite();
	msg.SetType(PRO_NEAR_PLAYER_LIST);
	pScene->MakeNearPlayerList(pUser,page,msg);
	m_socketServer.SendMsg(pUser->GetSock(),msg);
}

void CPackageDeal::PetOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER
	//// CHECK_SYSTEM_OPEN(SOT_Shenjiang)
	uint8 op = 0;
	msg>>op;
	if(op == 0)
		return;
	switch (op)
	{
	case 1:// 获取所有神将
		pUser->MakePet(msg);
		break;
		
	case 3:// 神将升级
		CHECK_SYSTEM_OPEN(SOT_1060)
		if(!pUser->HeroLevelUp(msg))
			return;
		break;
		
	case 4:// 神将一键升级
		CHECK_SYSTEM_OPEN(SOT_1060)
		if(!pUser->HeroAutoLevelUp(msg))
			return;
		break;
	
	case 5:// 神将突破
		CHECK_SYSTEM_OPEN(SOT_1080)
		if (!pUser->HeroBreak(msg))
			return;
		break;
		
	case 6:// 神将修炼
		if(!pUser->HeroXiuLian(msg))
			return;
		break;
		
	case 7:// 神将升星
		CHECK_SYSTEM_OPEN(SOT_1070)
		if(!pUser->HeroStarUp(msg))
			return;
		break;

	case 8:// 重生查询
		if (!pUser->HeroCChongSheng(msg))
			return;
		break;

	case 9:// 重生
		if (!pUser->HeroChongSheng(msg))
			return;
		break;

	case 11:// 神将合成
		if (!pUser->HeroHeCheng(msg))
			return;
		break;
	case 12:// 神将激活
		if (!pUser->HeroXiuLianJiHuo(msg))
			return;
		break;
	}
	m_socketServer.SendMsg(sock,msg);
}

void CPackageDeal::PetKaiJiaOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 op = 0;		// 1 getKaiJia  2 强化 3 update
	uint8 index = 0;	// 1 护符 2 护肩 3 头饰 4 项圈
	uint8 useTongBao = 0;	// 1 使用 0 不使用
//	uint8 stone = 0xff;

	msg>>op;
	if(op == 1)
	{
	}
	else if(op == 2)
	{
		uint8 kaijiaIndex = 0;
		msg>>kaijiaIndex>>index>>useTongBao;
	}
}

void CPackageDeal::HeChengOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	// 1 list
	// 2 饰品 合成
	// 3 饰品 一键合成
	// 4 炼化石 合成
	// 5 炼化石 一键合成
	// 6 拆分 装备属性
	// 7 附着 装备属性
	// 8 饰品升级
	uint8 op = 0;

	msg>>op;

	switch (op)
	{
	case 3:// 4 物品 合成
	{
		uint16 itemId = 0;
		uint16 num = 0;
		msg >> itemId >> num;
		pUser->ItemHeChengNum(itemId, num);
	}
	break;
	case 4:// 4 物品 合成
	{
		uint8 pos = CUser::MAX_PACKAGE_NUM2;
		msg >> pos;
		if (pos == CUser::MAX_PACKAGE_NUM2)
			return;
		pUser->ItemHeCheng(pos, 0);
	}
	break;

	case 5:// 5 物品 一键合成
	{
		uint8 pos = CUser::MAX_PACKAGE_NUM2;
		msg >> pos;
		if (pos == CUser::MAX_PACKAGE_NUM2)
			return;
		pUser->ItemHeCheng(pos, 1);
	}
	break;

	case 6:
	{
		uint8 num = 0;
		msg >> num;
		if (num == 0 || num > CUser::MAX_PACKAGE_NUM2)
			return;

		vector<uint8> poss;
		for (int i=0; i<num; ++i)
		{
			uint8 pos = CUser::MAX_PACKAGE_NUM2;
			msg >> pos;
			if (pos == CUser::MAX_PACKAGE_NUM2)
				return;

			poss.push_back(pos);
		}
		pUser->ItemFenjie(poss);
	}
	break;

	case 8: // 8 装备升阶
	{

	}
	break;

	case 9:// 装备一键升级(装备栏)
	{

	}
	break;

	}
}

void CPackageDeal::FuBenOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER
	//// CHECK_SYSTEM_OPEN(SOT_Fuben)
	uint8 op = 0;	// 1 list 2 单人副本  3 组队 4:退出副本 5:副本结算 6:副本掉落提示 7:副本结算2 8:副本结算2物品抽奖 9:副本更新计时信息 10:副本进入次数显示
					// 11 日常副本列表 12 进入日常副本 13 日常副本进入次数 14 神将副本结算
	msg>>op;
	if(op == 1)
	{
	}
	else if(op == 4) // 退出副本
	{
		CScene *pScene = pUser->GetScene();
		if(pScene != NULL && pScene->GetSrcSceneId() >= KUN_LUN_SHAN_SCENE_ID && pScene->GetSrcSceneId() < KUN_LUN_SHAN_SCENE_ID+30)	// 昆仑山退出扣点
		{
			if(CSceneManager::IsInActivityTime(SOT_Kunlunshan))
			{
				if(pUser->GetExtData16(31) <= 10)
					pUser->SetExtData16(31,0);
				else
					pUser->SetExtData16(31,pUser->GetExtData16(31)-10);
				AddKunLunShanPaiHangScore(pUser);
			}
			// 如果是骑坐骑的则恢复
			SetQiPetUp(pUser);
		}
		else if(pScene != NULL && pScene->GetSrcSceneId() == KUN_LUN_SHAN_TEAM_SCENE_ID)
		{
			if(pUser->GetTeam() > 0 && pUser->GetTeam() != pUser->GetRoleId())
			{
				SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0053,TIPS_FAILURE_COLOR).c_str());
				return;
			}
			// 如果是骑坐骑的则恢复
			SetQiPetUp(pUser);
		}
		else if(pScene != NULL && pScene->GetSrcSceneId() >= FEI_XIAN_SID1 && pScene->GetSrcSceneId() <= FEI_XIAN_SID5)
		{
			if(pUser->GetFeiXianState() > 0)
			{
				// 还原状态
				pUser->SetFeiXianState(0);
				pUser->UpdateFeiXianData();
				// 退出状态转给其他人
				pUser->SetFeiXianState(1);
			}
			SetQiPetUp(pUser);
		}
		else if(pScene != NULL && (pScene->GetSrcSceneId() == BP_FIGHT_SID || pScene->GetSrcSceneId() == KUAFU_BZ_SID))
		{
			if(pUser->GetTeam() > 0)
				pScene->LeaveSceneTeam(pUser->GetTeam(),pUser);
			if(pUser->GetBangPai() > 0)
				EnterBPFightReadyScene(pUser);
			else
#ifndef KUA_FU
				TransportUser(pUser,BP_FIGHT_EXIT_SID,BP_FIGHT_EXIT_X,BP_FIGHT_EXIT_Y,1);
#else
				TransportUser(pUser,KUAFU_EXIT_SID,KUAFU_EXIT_X,KUAFU_EXIT_Y,1);
#endif
			return;
		}
		else if(pScene != NULL && pScene->GetSrcSceneId() == BP_FIGHT_READY_SID)
		{
			if(pUser->GetTeam() > 0)
				pScene->LeaveSceneTeam(pUser->GetTeam(),pUser);
			int sId = BP_FIGHT_EXIT_SID, pX = BP_FIGHT_EXIT_X, pY = BP_FIGHT_EXIT_Y;
			pUser->GetEnterPos(sId,pX,pY);
			TransportUser(pUser,sId,pX,pY,1);
			return;
		}

		pUser->SetMeetEnemy(true);	// 设置遇怪
		if(pScene != NULL)
		{
			if(IsInFishingRoom(pScene->GetSrcSceneId()))
			{
				CFishManager& fishMgr = SingletonFishManager::instance();
				fishMgr.ExitRoom(pUser);
				return;
			}
		}
		pUser->ExitFuBen();
	}
	else if (op == 11) //日常副本列表
	{
		//if (pUser->GetSaoDangFuBenId() != 0) //扫荡中
		//{
		//	pUser->SaoDangFuBen();
		//	pUser->GetSaoDangFuBenInfo();
		//	if (pUser->GetSaoDangFuBenCiShu() == 0) //扫荡已经完成
		//	{
		//		pUser->SetSaoDangFuBenId(0);
		//		pUser->SetSaoDangFuBenCiShu(0);
		//		pUser->SetSaoDangFuBenPerTime(0);
		//		pUser->SetSaoDangFuBenTime(0);
		//		pUser->SetDataStr(5,"");
		//	}
		//	else
		//		pUser->ContinueSaoDang();
		//	return;
		//}
		msg.ReWrite();
		msg.SetType(MSG_FUBEN_OPTION);
		msg<<(uint8)11;
		SingletonCRiChangFuBenManager::instance().ListFuBen(pUser,msg);
		uint8 addHelpPet = 0;		//助战神将 0 无助战 1 助战
		if(!pUser->HaveBitSet(193))	//未通关神将副本
			addHelpPet = 1;
		msg<<addHelpPet<<(uint8)SaoDangLevelLimit;
		m_socketServer.SendMsg(pUser->GetSock(),msg);
	}
	else if (op == 12) // 进入日常副本
	{
		const uint16 petId[] = {25,24,29,26,23};
		uint16 fuBenId = 0;
		uint8 helpPetIndex = 0xff;	// 助战神将index
		msg>>fuBenId>>helpPetIndex;
		msg.ReWrite();
		msg.SetType(MSG_FUBEN_OPTION);
		msg<<(uint8)12;
		uint32 curTime = (uint32)GetSysTime();
		if(curTime - pUser->GetExtData32(114) > OptionTimeSpace)
			pUser->SetExtData32(114,curTime);
		else
			return;
		if(pUser->GetTeam() > 0)
		{
			msg<<PRO_ERROR<<(uint8)3<<MakeStringColor(LANGUAGE_SSJ_0484,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		
		if(pUser->GetFightId() > 0)
		{
			msg<<PRO_ERROR<<(uint8)3<<MakeStringColor(LANGUAGE_SSJ_0476,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		
		if(pUser->GetSaoDangFuBenId() != 0) //扫荡中
			return;

		if(fuBenId == 1)	// 神将副本
		{
			if(helpPetIndex != 0xff && helpPetIndex < sizeof(petId)/sizeof(petId[0]))	// 选择助战神将
			{
				if(pUser->HaveBitSet(193))	// 通关神将副本
					return;
				pUser->SetExtData16(38,petId[helpPetIndex]);
			}
			else
			{
				pUser->SetExtData16(38,0);
			}
		}
		else
		{
			pUser->SetExtData16(38,0);
		}

		if(pUser->GetTeam() != 0)
		{
			if(pUser->GetTeam() != pUser->GetRoleId())	// 归队队员
			{
				msg<<PRO_ERROR<<(uint8)3<<MakeStringColor(LANGUAGE_TRANSFORM_936,TIPS_FAILURE_COLOR);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				return;
			}
		}
		if(!CanJoinActivity(pUser))
			return;

		ERiChangFuBen *pfuBen=SingletonCRiChangFuBenManager::instance().FindFuBen(fuBenId);
		if(!pfuBen)
			return;
		if(pUser->GetFBLevel(pfuBen->id)==0)
		{
			msg<<PRO_ERROR<<(uint8)1<<MakeStringColor(LANGUAGE_TRANSFORM_938,TIPS_FAILURE_COLOR); //未开启
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(!pUser->CanWorldTransPort(pfuBen->sceneId))
		{
			msg<<PRO_ERROR<<(uint8)3<<MakeStringColor(LANGUAGE_SSJ_0475,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}

		uint8 enterLimit = pfuBen->enterLimit;
		/*uint8 monCardValue = pUser->GetMonthCard();
		if((monCardValue & 0x2) > 0)
			enterLimit += 1;
		if((monCardValue & 0x4) > 0)
			enterLimit += 2;*/
		
//		if(!pUser->HaveBitSet(191))		// 存在这个位变量，则不需要校验进入次数和体力
//		{
			int needMoney = 0;
			if (pUser->GetExtData8(pfuBen->extdata8) >= enterLimit)
			{
				msg << PRO_ERROR << (uint8)1 << MakeStringColor(LANGUAGE_TRANSFORM_946, TIPS_FAILURE_COLOR);
				m_socketServer.SendMsg(pUser->GetSock(), msg);
				return;
			}
			needMoney = pUser->GetEnterFBMoney(pfuBen->id,false);

			if(pUser->GetMoney() < needMoney)
			{
				msg<<PRO_ERROR<<(uint8)1<<MakeStringColor(LANGUAGE_TRANSFORM_939,TIPS_FAILURE_COLOR);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				return;
			}
			
			pUser->AddMoney(-needMoney);
			
//		}

		msg<<PRO_SUCCESS;
		m_socketServer.SendMsg(pUser->GetSock(),msg);

		//先记录，后传送
		if (pUser->HaveBitSet(191)) // 存在这个位变量，则不需要校验进入次数和体力
			pUser->ClearBitSet(191);
		else
		{
			pUser->SetExtData8(pfuBen->extdata8,pUser->GetExtData8(pfuBen->extdata8)+1); // 进入次数记录
		}
		pUser->RiChangFuBenSaveEnter(fuBenId);
		pUser->ClearFuBenData();

		if(pUser->GetTeam() > 0)
		{
			if(pUser->GetTeam() == pUser->GetRoleId())	// 队长,则归队成员设置成暂离状态
			{
				CScene *pScene = pUser->GetScene();
				if(pScene == NULL)
					return;
				pScene->SetInTeamMemLeave(pUser);
			}
			else
				return;
		}
		
		SaveDate(pUser,5,fuBenId); // 副本进入记录
		if(fuBenId == 1) // 神将副本
			EnterChongWuFuBen(pUser);
		else if(fuBenId == 2) // 强化副本
			EnterQiangHuaFuBen(pUser);
		else if(fuBenId == 3) // 金币副本
			EnterJinBiFuBen(pUser);
		else if(fuBenId == 4) // 升阶副本
			EnterShengJieFuBen(pUser);
		else if(fuBenId == 5) // 潜能副本
			EnterQianNengFuBen(pUser);
		else if(fuBenId == 100)	// 镶嵌副本
			EnterXiangQianFuBen(pUser);
		else if(fuBenId == 101)	// 淬炼副本
			EnterXiLianFuBen(pUser);
		else if(fuBenId == 102)	// 神将铠副本
			EnterChongKaiFuBen(pUser);
	}
	else if (op == 13) //日常副本进入次数
	{
		msg.ReWrite();
		msg.SetType(MSG_FUBEN_OPTION);
		msg<<(uint8)13;
		SingletonCRiChangFuBenManager::instance().QueryFuBenCiShu(pUser,msg);
		m_socketServer.SendMsg(pUser->GetSock(),msg);
	}
	else if (op == 19) // 扫荡状态请求
	{
		uint16 fuBenId = 0; 
		msg>>fuBenId;
		int enterLv = 0;
		int limit = 0; //进入上限
		int curEnterCnt = 0; //当前进入次数
		int mopTime = 0; //扫荡时间
		string mobs = ""; //怪物
		ERiChangFuBen *pfuBen=SingletonCRiChangFuBenManager::instance().FindFuBen(fuBenId);
		if(!pfuBen)
			return;
		uint8 enterLimit = pfuBen->enterLimit;
		/*uint8 monCardValue = pUser->GetMonthCard();
		if((monCardValue & 0x2) > 0)
			enterLimit += 1;
		if((monCardValue & 0x4) > 0)
			enterLimit += 2;*/
		
		enterLv = pfuBen->level;
		limit = enterLimit;
		curEnterCnt = pUser->GetExtData8(pfuBen->extdata8);
		mopTime = pfuBen->mopTime;
		mobs = pfuBen->mobs;
		if(pUser->GetVipLevel()>=5)
			mopTime=0;
		msg<<(uint8)limit<<(uint8)curEnterCnt<<(uint16)mopTime<<(uint16)enterLv<<(uint8)0<<mobs.c_str();
		m_socketServer.SendMsg(pUser->GetSock(),msg);
	}
	else if (op == 20) //扫荡请求
	{
		uint8 fuBenId = 0; 
		msg>>fuBenId;
		ERiChangFuBen *pfuBen=SingletonCRiChangFuBenManager::instance().FindFuBen(fuBenId);
		if(!pfuBen)
			return;
		uint16 vipLv = pUser->GetVipLevel();
		if (vipLv > MAX_VIP_LEVEL)
		{
			return;
		}
		if (G_VipConfig[vipLv].sweepCopys.find(fuBenId) == G_VipConfig[pUser->GetVipLevel()].sweepCopys.end())
		{
			for (int vi = vipLv; vi < MAX_VIP_LEVEL + 1; ++vi)
			{
				if (G_VipConfig[vi].sweepCopys.find(fuBenId) != G_VipConfig[vi].sweepCopys.end())
				{
					char buf[128];
					snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0027, vi);
					msg << PRO_ERROR << MakeStringColor(buf, TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(), msg);
					return;
				}
			}
			return;
		}

		if(!pUser->GetFBTongGuan(fuBenId))
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_947,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		int curEnterCnt = pUser->GetExtData8(pfuBen->extdata8); // 当前进入次数
		uint8 sweepCnt = pfuBen->enterLimit > curEnterCnt ? pfuBen->enterLimit - curEnterCnt : 0;
		if (sweepCnt == 0)
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_1767, TIPS_FAILURE_COLOR);
		}
		else
		{
			msg << PRO_SUCCESS << sweepCnt;
			pUser->SaoDangFuBen(fuBenId, sweepCnt, msg);
			pUser->SetExtData8(pfuBen->extdata8, pfuBen->enterLimit);
		}
		m_socketServer.SendMsg(pUser->GetSock(), msg);
	}
	else if (op == 21) //取消扫荡
	{
		msg.ReWrite();
		msg.SetType(MSG_FUBEN_OPTION);
		msg<<(uint8)21;
		pUser->SetSaoDangFuBenId(0);
		pUser->SetSaoDangFuBenCiShu(0);
		pUser->SetSaoDangFuBenPerTime(0);
		pUser->SetSaoDangFuBenTime(0);
		pUser->SetDataStr(5,"");
		msg<<PRO_SUCCESS;
		m_socketServer.SendMsg(pUser->GetSock(),msg);
	}
	else if (op == 22) // 获取玩家扫荡信息
	{
		pUser->GetSaoDangFuBenInfo();
	}
	else if(op==23) //扫荡
	{
		/*pUser->SaoDangFuBen();
		if (pUser->GetSaoDangFuBenCiShu()>0) 
			pUser->ContinueSaoDang();*/
	}
	else if (op == 26) // 获取玩家扫荡的时间
	{
		int cnt = pUser->GetSaoDangFuBenCiShu();
		int mopTime = pUser->GetSaoDangFuBenPerTime();
		time_t leftTime = pUser->GetSaoDangFuBenTime();
		if (leftTime > GetSysTime())
			leftTime -= GetSysTime();
		else
			leftTime = 0;
		msg<<(uint8)cnt<<(uint16)mopTime<<(uint16)leftTime;
		m_socketServer.SendMsg(pUser->GetSock(),msg);
	}
	else if(op == 28)	// 在副本中死亡，提示玩家是否花元宝复活，服务器主动推送
	{
	}
	else if(op == 29)	// 副本中死亡，玩家选择
	{
		uint8 choose = 0;	// 0不复活1复活
		msg>>choose;

		CScene *pScene = pUser->GetScene();
		if(pScene == NULL || (pScene->GetSrcSceneId() < COPY_ID_CHONG_WU_1 || pScene->GetSrcSceneId() > COPY_ID_CHONG_WU_4))
			return;
		if(choose == 0)	// 退出副本
		{
			msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_TRANSFORM_954,TIPS_FAILURE_COLOR);
			pUser->ExitFuBen();
		}
		else
		{
			uint8 difficulty = pScene->GetPetCopyDifficulty();
			int useYB = GetPetCopyReviveYB(difficulty,pUser->GetExtData8(120));
			if(useYB == 0)
				return;
			if(pUser->GetTongBao() < useYB)
			{
				msg<<PRO_ERROR<<"";
				ShowJumpNotice(pUser,JUMP_NOTICE_YB);
			}
			else
			{
				pUser->AddTongBao(-useYB);
				if(pScene == NULL)
					return;
				pScene->ClearPetCopyUserDie();
				msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_TRANSFORM_955,TIPS_SUCCESS_COLOR);
				ItemCurrencyLog(pUser->GetRoleId(),1,0,0,useYB,pUser->GetTongBao(),YBL_PETCOPY_REVIVE);
			}
			pScene->SetDropItemTime((uint32)GetSysTime()-PET_COPY_TIMEOUT_LIMIT+5);
		}
		m_socketServer.SendMsg(pUser->GetSock(),msg);
	}
	else if(op == 30)	// 扫荡加速完成
	{
		pUser->AccelerateSaoDangFuBen();
	}
	else if(op == 31)	// 请求扫荡消耗的提示
	{
		if(pUser->GetSaoDangFuBenTime() == 0)
			return;
		int cnt = pUser->GetSaoDangFuBenCiShu();
		int mopTime = pUser->GetSaoDangFuBenPerTime();
		time_t curTime = GetSysTime();
		time_t leftTime = pUser->GetSaoDangFuBenTime();
		if(leftTime > curTime)
			leftTime -= curTime;
		else
			leftTime = 0;
		leftTime += mopTime*cnt;
		int yb = AccelerateSaoDangCostYB(leftTime);

		char buf[256];
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_956,GGCT_RED,yb);
		msg<<buf;
		m_socketServer.SendMsg(pUser->GetSock(),msg);		
	}
}

void CPackageDeal::NPC_AutoTransport(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint32 npcId = 0;
	uint16 nextSceneId = 0;

	msg>>npcId>>nextSceneId;

	const int distance = 150;
	if(nextSceneId == 0)
		return;
	if(npcId == 0)
	{
		CScene *pScene = pUser->GetScene();
		if(pScene == NULL)
			return;
		CNpcManager &npcManager = SingletonNpcManager::instance();
		list<uint16> npcList;
		npcManager.GetSceneNpc(pScene->GetId(),&npcList);
		for(list<uint16>::iterator i = npcList.begin(); i != npcList.end(); i++)
		{
			SNpcInstance *pNPC = npcManager.GetNpcInstance(*i);
			if(pNPC == NULL)
				continue;
			int x = (int)pNPC->x - (int)pUser->GetX();
			int y = (int)pNPC->y - (int)pUser->GetY();
			if(x*x + y*y <= distance*distance)
			{
				npcId = pNPC->id;
				break;
			}
		}
	}
	if(npcId == 0)
		return;

//	CCallScript script(npcId);
	CCallScript *pScript = FindScript(npcId);
	if(pScript == NULL)
		return;
	pScript->Call("AutoTransportUser","ui",pUser,nextSceneId);
}

//坐骑操作
/*
	op:	1: 获取坐骑基础信息
		2: 坐骑强化
		3: 坐骑进阶
		4: 设置乘骑状态
*/
void CPackageDeal::MountOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER
	// CHECK_SYSTEM_OPEN(SOT_Zuoqi)

	uint8 op = 0;
	msg>>op;
	switch (op)
	{
	case 1: // 获取坐骑基础信息
	{
		msg.ReWrite();
		msg.SetType(MSG_MOUNT);
		msg << op;
		pUser->MakeMount(msg);
		m_socketServer.SendMsg(pUser->GetSock(), msg);
		break;
	}
	case 2: // 坐骑强化
	{
		// CHECK_SYSTEM_OPEN(SOT_Zuoqi_Shengxing)

		uint8 type = 0;
		msg >> type;
		if (1 == type)
		{
			msg.ReWrite();
			msg.SetType(MSG_MOUNT);
			msg << op << type;
			pUser->MakeMountStrengthenMsg(msg);
		}
		else if (2 == type)
		{
			int itemID = 0;
			int num = 0;
			msg >> itemID >> num;
			msg.ReWrite();
			msg.SetType(MSG_MOUNT);
			msg << op << type;
			pUser->StrengthenMount(msg, itemID, num);
		}
		m_socketServer.SendMsg(pUser->GetSock(), msg);
		break;
	}
	case 3: // 坐骑进阶
	{
		// CHECK_SYSTEM_OPEN(SOT_Zuoqi_Jinjie)
		msg.ReWrite();
		msg.SetType(MSG_MOUNT);
		msg << op;
		pUser->UpgradeMount(msg);
		m_socketServer.SendMsg(pUser->GetSock(), msg);
		CScene *pScene = pUser->GetScene();
		if (pScene == NULL)
			return;
		pScene->UpdateUserInfo(pUser,ESRT_Mount_State);
		break;
	}
	case 4: // 设置乘骑状态
	{
		uint8 mid = 0xff;	// 设置骑乘的id，oxff设置休息
		msg >> mid;
		msg.ReWrite();
		msg.SetType(MSG_MOUNT);
		msg << op << mid;

		if (pUser->InHuSongMission() != 0)
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_961, TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(), msg);
			return;
		}

		CScene *pScene = pUser->GetScene();
		if (pScene == NULL)
			return;
		int sid = pScene->GetSrcSceneId();
		if (sid >= FEI_XIAN_SID1 && sid <= FEI_XIAN_SID5)
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_962, TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(), msg);
			return;
		}

		if (mid != 0xff)
		{
			int srcId = pScene->GetSrcSceneId();
			if (srcId >= KUN_LUN_SHAN_SCENE_ID && srcId < KUN_LUN_SHAN_SCENE_ID + 30)
			{
				msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_963, TIPS_FAILURE_COLOR);
				m_socketServer.SendMsg(pUser->GetSock(), msg);
				return;
			}
		}

		pUser->SetExtData8(144, 0xff);
		uint8 index = pUser->GetMountIdxById(mid);
		pUser->SetMountState(msg, index);
		m_socketServer.SendMsg(pUser->GetSock(), msg);
		pScene->UpdateUserInfo(pUser,ESRT_Mount_State);
		break;
	}
	case 5:	// 获得所有坐骑列表(客户端读表，不用了)
	{
		uint8 count = 0;
		uint16 countPos = msg.GetDataLen();
		msg << count;

		vector<int> mountList;
		CMountConfigMgr &mgr = SingletonMountCfgMgr::instance();
		mgr.GetMountList(mountList);
		for (uint32 i = 0; i < mountList.size(); i++)
		{
			int mid = mountList[i];
			SMountConfig *pData = mgr.GetCfg(mid);
			if (pData == NULL)
				continue;
			count++;
			uint8 tmp_havemount = (pUser->HaveMount(mid)) ? 1 : 0;
			msg << (uint8)mid << pData->desc << pData->getWay << pData->getWay_num << pData->getWay_itemId;
			msg << pData->moveSpeed << tmp_havemount;
		}
		msg.WriteData(countPos, &count, sizeof(count));
		m_socketServer.SendMsg(pUser->GetSock(), msg);
		break;
	}
	case 6:	// 购买坐骑
	{
		uint8 buyId = 0;
		msg >> buyId;
		if (buyId == 0)
			return;
		SMountConfig *pData = SingletonMountCfgMgr::instance().GetCfg(buyId);
		if (pData == NULL)
			return;

		uint8 type = pData->getWay;
		if (type == 0)	// 进阶获得
		{
			msg << PRO_ERROR << MakeStringColor(pData->error_msg, TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(), msg);
			return;
		}

		uint32 time = pData->buy_time_limit;
		if (type == 1)
		{
			int useYB = pData->getWay_num;
			pUser->BuyMount(buyId, time, useYB, msg);
		}
		else if (type == 2)
		{
			int itemNum = pData->getWay_num;
			int itemId = pData->getWay_itemId;
			pUser->BuyMountByItem(buyId, itemId, itemNum, time, msg);
			pUser->AddSpecialTitle();
		}
		m_socketServer.SendMsg(pUser->GetSock(), msg);
		break;
	}
	case 7:	// 获取坐骑收集属性
	{
		pUser->MakeMountCollect(msg);
		m_socketServer.SendMsg(pUser->GetSock(), msg);
		break;
	}
	case 8:	// 获取玩家坐骑信息
	{
		uint32 roleId = 0;
		msg >> roleId;
		if (roleId == 0)
			return;
		ShareUserPtr other = m_onlineUser.GetUserByRoleId(roleId);
		if (other.get() == NULL)
		{
			CUser *pOther = new CUser;
			if (pOther == NULL)
				return;
			pOther->SetSock(-1);
			if (!pOther->CopyUserData(roleId))
			{
				delete pOther;
				return;
			}
			other.reset(pOther);
		}
		other->MakeMount(msg);
		m_socketServer.SendMsg(pUser->GetSock(), msg);
	}
	break;
	default:
	{
		cout << "Error: CPackageDeal_MountOption: unknown op: " << (int)op << endl;
		break;
	}
	}
}

void CPackageDeal::WingOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER
	//翅膀列表相关配置在utility.h 中winglist中添加
//	const uint8 WingId[] = {SWing::WT_Wing_21,SWing::WT_Wing_1,SWing::WT_Wing_2,SWing::WT_Wing_3,SWing::WT_Wing_4,SWing::WT_Wing_5,SWing::WT_Wing_6,SWing::WT_Wing_7,
//		SWing::WT_Wing_25,SWing::WT_Wing_23,SWing::WT_Wing_22,SWing::WT_Wing_26,SWing::WT_Wing_24,SWing::WT_Wing_27,SWing::WT_Wing_28,SWing::WT_Wing_29,SWing::WT_Wing_30,
//		SWing::WT_Wing_31,SWing::WT_Wing_32,SWing::WT_Wing_33};
	uint8 op = 0;
	msg>>op;
	switch (op)
	{
		case 1: // 获取翅膀基础信息
			{
				// CHECK_SYSTEM_OPEN(SOT_Wing)

				pUser->MakeWing(msg);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				break;
			}
		case 2: // 翅膀进阶
			{
				// CHECK_SYSTEM_OPEN(SOT_Wing_Jinjie)

				uint8 type = 0;
				uint16 itemId = 0;
				uint16 num = 0;
				msg>>type>>itemId>>num;
				pUser->StrengthenWing(type,itemId,num,msg);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				break;
			}
		case 3: // 设置翅膀状态
			{
				// CHECK_SYSTEM_OPEN(SOT_Wing)

				uint8 wid = 0xff;	// 设置使用的id，0xff不使用
				msg >> wid;
				
				CScene *pScene = pUser->GetScene();
				if(pScene == NULL)
					return;
 				uint8 index = pUser->GetWingIdxById(wid);
				pUser->SetWingState(msg,index);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				pScene->UpdateUserInfo(pUser,ESRT_Wing);
				break;
			}
		case 4:	// 获得所有翅膀列表(客户端读表，不用了)
			{
				
			}
		case 5:	// 购买翅膀
			{
				// CHECK_SYSTEM_OPEN(SOT_Wing)

				uint8 buyId = 0;
				msg >> buyId;
				if(buyId == 0)
					return;

				SWingConfig *p = SingletonWingCfgMgr::instance().GetCfg(buyId);
				if(p == NULL)
					return;
				uint8 type = p->getWay;
				if(type == 0)	// 进阶获得
				{					
					msg<<PRO_ERROR<<MakeStringColor(p->err_info,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				else if(type == 1)	// 元宝购买
				{
					int useYB = p->getWay_Num;
					pUser->BuyWing(buyId,useYB,msg);
				}
				else if(type == 2)	// 兑换
				{
					int itemNum = p->getWay_Num;
					int itemId = p->getWay_itemId;
					pUser->BuyWingByItem(buyId,itemId,itemNum,msg);

					pUser->AddSpecialTitle();
				}
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				break;
			}
		case 6:	// 请求强化翅膀信息(客户端读表，不用了)
			{
//				pUser->QueryWingQiangHuaMsg(msg);
//				m_socketServer.SendMsg(pUser->GetSock(),msg);
//				break;
			}
		case 7:	// 请求其他玩家翅膀信息
			{
				uint32 roleId = 0;
				msg>>roleId;
				if(roleId == 0)
					return;
				ShareUserPtr other = m_onlineUser.GetUserByRoleId(roleId);
				if(other.get() == NULL)
				{
					CUser *pOther = new CUser;
					if(pOther == NULL)
						return;
					pOther->SetSock(-1);
					if(!pOther->CopyUserData(roleId))
					{
						delete pOther;
						return;
					}
					other.reset(pOther);
				}
				other->MakeWing(msg);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			break;
		default:
			{
				cout << "Error: CPackageDeal_WingOption: unknown op: " << (int)op << endl;
				break;
			}
	}
}

void CPackageDeal::QueryRolePackageItem(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint32 roleId = 0;
	uint8 itemPos = 0xff;
	msg>>roleId>>itemPos;

	if(roleId == 0 && itemPos > CUser::MAX_PACKAGE_NUM2)
		return;
	ShareUserPtr ptr1 = m_onlineUser.GetUserByRoleId(roleId);
	CUser *pU = ptr1.get();
	if(pU == NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_991,TIPS_FAILURE_COLOR);
		m_socketServer.SendMsg(sock,msg);
		return;
	}

	msg<<PRO_SUCCESS;
	pU->MakePackageItemByPos(itemPos,msg);
	m_socketServer.SendMsg(sock,msg);
}

void CPackageDeal::WorldMapTransport(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint16 sceneId = 0;
	msg>>sceneId;

	if(sceneId > 1000)
		return;
#ifndef KUA_FU
	if(sceneId >= 70 && sceneId <= 77)
		return;
#endif

	if(pUser->GetFightId() != 0)
	{
		SendSysInfoFightEnd(pUser,MakeStringColor(LANGUAGE_SSJ_0479,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	if(!pUser->CanWorldTransPort(sceneId))
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0475,TIPS_FAILURE_COLOR).c_str());
		return;
	}

	CSceneManager &sceneMgr = SingletonSceneManager::instance();
	CScene *pScene = sceneMgr.FindScene(sceneId);
	if(pScene == NULL)
		return;
	if(pScene->GetId() == pUser->GetSceneId())
		return;
	if(pUser->GetKuaFuState() != EKFS_IN_LOCAL)
		return;
	if(pUser->InHuSongMission() == 1)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_992,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	else if(pUser->InHuSongMission() == 2)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_993,TIPS_FAILURE_COLOR).c_str());
		return;
	}

//	if(pUser->GetFightId() != 0)
//	{
//		SendSysInfo(pUser,MakeStringColor("战斗中不能传送",TIPS_FAILURE_COLOR).c_str());
//		return;
//	}
	if(pUser->HaveBitSet(156))
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_994,TIPS_FAILURE_COLOR).c_str());
		//return;
	}
	if(pUser->GetTeam() > 0 && pUser->GetTeam() != pUser->GetRoleId())
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_995,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	
	TransportUser(pUser,sceneId,pScene->GetX(),pScene->GetY(),1);
}

//用户排行
void CPackageDeal::UserRankOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	const int SHOW_NUM = 30;
	uint16 type = 0;
	msg>>type;
	
	SRankData r;
	r.role_id = pUser->GetRoleId();
	
	switch(type)
	{
	case CRankMgr::ERT_Level:
	{
		r.data1 = pUser->GetLevel();
		r.data2 = pUser->GetExp();
		break;
	}
	case CRankMgr::ERT_Pet:
	{
		break;
	}
	case CRankMgr::ERT_Power:
	{
		r.data1 = pUser->GetZhanDouLi();
		break;
	}
	case CRankMgr::ERT_Blood_Today:
	{
		CUserBloodFight *blood = pUser->GetBloodFight();
		if(blood != NULL)
		{
			uint16 star = 0, nodeId = 0;
			blood->GetTodayInfo(star, nodeId);
			r.data1 = star;
			r.value1 = nodeId;
		}
		break;
	}
	case CRankMgr::ERT_Blood_Yesterday:
	{
		break;
	}
	case CRankMgr::ERT_GuanKa_Zhu:
	{
		CUserGuanQia& gq = pUser->GetGuanQia();
		r.data1 = gq.GetGuanQiaStar(1);
		break;
	}
	case CRankMgr::ERT_GuanKa_Zhi:
	{
		CUserGuanQia& gq = pUser->GetGuanQia();
		r.data1 = gq.GetGuanQiaStar(2);
		break;
	}
	case CRankMgr::ERT_BookScore:
	{
		UserBook* book = pUser->GetUserBook();
		if (book != NULL)
			r.data1 = book->GetBookScore();
		break;
	}
	default:
	{
		return;
	}
	}

	SingletonCRankMgr::instance().MakeRankMsg(type, r, msg, SHOW_NUM);
	m_socketServer.SendMsg(sock, msg);
}

void CPackageDeal::ServerRank(CNetMessage *pMsg,int sock)
{
	GET_MSG
	
    if(!m_socketServer.IsServer(sock))
		return;
	int roleId;
	uint8 op;
	uint8 num;
	
	msg>>roleId>>op>>num;
	
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	ShareUserPtr ptr = onlineUser.GetUserByRoleId(roleId);
	CUser *pUser = ptr.get();
    if(!pUser) 
		return;
	
	//CBangPaiManager &bPMgr = SingletonCBangPaiManager::instance();
	//CBangPai *pBangPai = NULL;
	//string bangPaiName = "";
	
	CNetMessage newmsg;
	newmsg.SetType(MSG_USER_RANK);
	newmsg<<op;
	newmsg<<num;  

    for(int i=0;i<num;i++)
	{
		switch (op)
		{

		case 6: // 3v3排行榜
			{ // 角色id，角色名，职业、积分
			    string roleName;
				uint8 xiang = 0;
				int jifen = 0;
			    msg>>roleId;
    			msg.ReadString(roleName);
				msg>>xiang>>jifen;
				newmsg<<roleId<<roleName<<xiang<<jifen;
				break;
			}
		case 7:	// 1v1排行榜
			{
				string roleName;
				uint8 xiang = 0;
				int shenjia = 0;
			    msg>>roleId;
    			msg.ReadString(roleName);
				msg>>xiang>>shenjia;
				newmsg<<roleId<<roleName<<xiang<<shenjia;
				break;
			}
		case 8: // 群仙争霸排行
			{
				string roleName;
				uint8 xiang = 0;
				int floor = 0;
			    msg>>roleId;
    			msg.ReadString(roleName);
				msg>>xiang>>floor;
				newmsg<<roleId<<roleName<<xiang<<floor;
				break;
			}
		default:
			{
				cout << "Error: CPackageDeal_UserRankOption: unknown op: " << (int)op << endl;
				return;
			}
		}
	}
	m_socketServer.SendMsg(pUser->GetSock(),newmsg);
}

void CPackageDeal::CanMeetMonsterOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 canMeetMonster = 0;	// 1 遇怪 2 开始寻路 3 结束寻路
	msg>>canMeetMonster;

	if(canMeetMonster == 1)		// 战斗结束
	{
		pUser->SetMeetEnemy(true);
		pUser->SetClientFightEndTime();
	}
	else if(canMeetMonster == 2)	// 开始寻路
	{
		pUser->SetMeetEnemy(false);
	}
	else if(canMeetMonster== 3)		// 结束寻路
	{
		pUser->SetMeetEnemy(true);
	}
}

// 帮助操作 1:获取所有的title列表 2:获取某个title的对应内容接口
void CPackageDeal::HelpOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 op = 0;
	msg>>op;
	switch (op)
	{
	case 1: // 获取所有的title列表
		{
			GetHelpTitleList(pUser);
			break;
		}
	case 2: // 获取某个title的对应内容接口
		{
			uint8 helpId = 0;
			msg>>helpId;
			GetHelpContent(pUser,helpId);
			break;
		}
	default:
		{
			break;
		}
	}
}

// 获取帮助标题列表
void CPackageDeal::GetHelpTitleList(CUser *pUser)
{
	static int helpIds[HELP_LIMIT] = {0};
	static list<string> helpTitles;

	if(gyu::util::CIniFile::GetValue("local_test","server",gConfigFile) == "1")
	{
		CNetMessage msg;
		msg.SetType(MSG_HELP);
		msg<<(uint8)1<<(uint8)0;
		m_socketServer.SendMsg(pUser->GetSock(),msg);
		return;
	}

	if (helpTitles.size()==0) 
	{
		boost::mutex::scoped_lock lk(m_dbLock);

		char sql[256];
		snprintf(sql,sizeof(sql),"select id,title from help order by 'order',id limit %d", HELP_LIMIT);
		if (!m_loginDb.Query(sql))
		{
			cout << "Error:GetHelpTitleList." << endl;
			return;
		}
		int idx = 0; // 数组索引
		memset(helpIds,0,sizeof(helpIds));
		helpTitles.clear();
		char** row;
		while((row = m_loginDb.GetRow()) != NULL)
		{
			helpIds[idx++] = atoi(row[0]);
			helpTitles.push_back(row[1]);
		}
	}

	int idx = 0; // 数组索引
	CNetMessage msg;
	msg.SetType(MSG_HELP);
	msg<<(uint8)1<<(uint8)helpTitles.size();
	for (list<string>::iterator it = helpTitles.begin(); it != helpTitles.end(); ++it)
	{
		if (idx >= HELP_LIMIT)
			break;
		msg<<(uint8)helpIds[idx++]<<*it;
	}
	m_socketServer.SendMsg(pUser->GetSock(),msg);
	if (helpTitles.size() > 0)
		GetHelpContent(pUser,helpIds[0]);
}

// 获取帮助内容
void CPackageDeal::GetHelpContent(CUser *pUser,int helpId)
{
	static int helpIds[HELP_LIMIT] = {0};
	static list<string> helpContents;

	if(gyu::util::CIniFile::GetValue("local_test","server",gConfigFile) == "1")
	{
		CNetMessage msg;
		msg.SetType(MSG_HELP);
		msg<<(uint8)2<<PRO_ERROR;
		m_socketServer.SendMsg(pUser->GetSock(),msg);
		return;
	}

	if (helpContents.size()==0)
	{
		boost::mutex::scoped_lock lk(m_dbLock);
		char sql[256];
		snprintf(sql,sizeof(sql),"select id,content from help order by `order`,id limit %d", HELP_LIMIT);
		if (!m_loginDb.Query(sql))
		{
			cout << "Error:GetHelpContent." << endl;
			return;
		}
		int idx = 0; // 数组索引
		memset(helpIds,0,sizeof(helpIds));
		helpContents.clear();
		char** row;
		while((row = m_loginDb.GetRow()) != NULL)
		{
			helpIds[idx++] = atoi(row[0]);
			helpContents.push_back(row[1]);
		}
	}

	CNetMessage msg;
	msg.SetType(MSG_HELP);
	msg<<(uint8)2;

	bool found = false;
	int idx = 0;
	for (list<string>::iterator it = helpContents.begin(); it != helpContents.end(); ++it)
	{
		if ((idx < HELP_LIMIT) && (helpIds[idx] == helpId))
		{
			found = true;
			msg<<PRO_SUCCESS<<(uint8)helpId<<*it;
			break;
		}
		++idx;
	}
	if (!found)
		msg<<PRO_ERROR;
	m_socketServer.SendMsg(pUser->GetSock(),msg);
}

// 每日玩法
void CPackageDeal::DailyActivityOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 op = 0;
	msg>>op;
	switch (op)
	{
	case 1: // 获取活跃度状态信息及列表
		{
			GetHuoYueDuInfo(pUser);
		}
		break;
	case 2: // 获取活跃度对应的礼包
		{
			uint8 huoYueDu = 0;
			msg>>huoYueDu;
			GetHuoYueDuRewardInfo(pUser,huoYueDu);
		}
		break;
	case 3: // 获取活跃度对应的礼包
		{
			uint8 huoYueDu = 0;
			msg>>huoYueDu;
			GetHuoYueDuReward(pUser,huoYueDu);
		}
		break;
	case 4:	// 部分玩法一键完成
		{
			uint16 huodongId = 0;
			msg>>huodongId;
			int res = 0,leftNum = 0;
			CompleteHuoDong(pUser,huodongId,res,leftNum);
			if(res == 1)
				msg<<PRO_SUCCESS<<(uint8)leftNum;
			else
				msg<<PRO_ERROR;
			m_socketServer.SendMsg(sock,msg);
		}
		break;
	default:
		break;
	}
}

void CPackageDeal::OpenPackageOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 isOpen = 0;	// 1 开启
	msg>>isOpen;

	if(isOpen == 1)
	{
		const int NEED_YB = 290;
		uint8 openNum = 0;
		msg>>openNum;
		if(pUser->GetMaxPackageNum() < CUser::MAX_PACKAGE_NUM2)
		{
			uint16 unOpenNum = (uint16)CUser::MAX_PACKAGE_NUM2 - pUser->GetMaxPackageNum();
			if(openNum > unOpenNum)
				openNum = unOpenNum;
			int YB = NEED_YB * openNum; 
			if(pUser->GetTongBao() >= YB)
			{
				pUser->AddTongBao(-YB);
				ItemCurrencyLog(pUser->GetRoleId(),0,(int)openNum,0,YB,pUser->GetTongBao(),YBL_OPENPACKAGE);
				pUser->AddMaxPackageNum(openNum);
				msg<<PRO_SUCCESS<<(uint16)(pUser->GetMaxPackageNum() - 1);

				SingletonCMissionManager::instance().UpdateDCMissionComplate(pUser, EMISS_DC_53, openNum);
			}
			else
			{
				msg<<PRO_ERROR<<"";
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				ShowJumpNotice(pUser,JUMP_NOTICE_YB);
				return;
			}
		}
		else
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_996,TIPS_FAILURE_COLOR);
		}
		m_socketServer.SendMsg(pUser->GetSock(),msg);
	}
}

void CPackageDeal::HuoDongOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER
	if(pUser->GetKuaFuState() != EKFS_IN_LOCAL)
		return;

	uint16 op = 0;
	msg>>op;
	if (op != 18)
	{
		// CHECK_SYSTEM_OPEN(SOT_Huodong)
	}

	if(op == 1)		// 百花仙子
	{
		// CHECK_SYSTEM_OPEN(SOT_Baihua)
		if (InFightHuoDong())
			msg<<(uint8)1;
		else
			msg<<(uint8)2;
		m_socketServer.SendMsg(pUser->GetSock(),msg);
	}
	else if(op == 2)	// 百花传送
	{
		// CHECK_SYSTEM_OPEN(SOT_Baihua)
		if (pUser->InHuSongMission() == 1)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_997,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		else if(pUser->InHuSongMission() == 2)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_998,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}

		if(InFightHuoDong())
		{
			if(pUser->GetFightId() == 0)
			{
				if(pUser->GetTeam() != 0)
				{
					if(pUser->GetTeam() != pUser->GetRoleId())	// 队员
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_999,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						return;
					}
				}
				if(!pUser->CanWorldTransPort(3))
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0475,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				if(pUser->GetSceneId() != 3 && pUser->GetSceneId() != 2)
				{
					int r = Random(1,2);
					if(r == 1)
						TransportUser(pUser,2,830,826,3);
					else if(r == 2)
						TransportUser(pUser,3,2173,930,2);
				}
				ChangeClientGuaJiState(pUser,1);
			}
			else
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1001,TIPS_FAILURE_COLOR);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
		}
		else
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1002,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
		}
	}
	else if(op == 3)	// 昆仑山活动
	{
		// CHECK_SYSTEM_OPEN(SOT_Kunlunshan)
		uint8 op1 = 0;
		msg>>op1;
		if(op1 == 1)
		{
			if(CSceneManager::IsInActivityTime(SOT_Kunlunshan))
			{
				if(pUser->GetFightId() > 0)
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0481,TIPS_FAILURE_COLOR).c_str());
					return;
				}
				if(!pUser->CanWorldTransPort(KUN_LUN_SHAN_SCENE_ID))
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0475,TIPS_FAILURE_COLOR).c_str());
					return;
				}
				
				if(!CanJoinActivity(pUser))
					return;
				if(pUser->HaveTeam())
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1007,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				
				int index = 1;
				CScene *pScene = m_sceneManager.GetKunLunShanFirstScene();
				if(pScene == NULL)
					return;
				while(pScene->GetUserNum() >= KUN_LUN_SHAN_ROOM_LIMIT)
				{
					index++;
					pScene = m_sceneManager.GetKunLunShanSceneByIndex(index);
					if(pScene == NULL)
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1008,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						return;
					}
				}

				SetQiPetDown(pUser);

				if(!pUser->HaveBitSet(301))
				{
					pUser->SetBitSet(301);
					pUser->SetExtData16(31,pUser->GetExtData16(31)+10);
					AddKunLunShanPaiHangScore(pUser);
					pUser->CheckMissionHuoYueDu();
				}

				uint16 x=0,y=0;
				int times = 100;
				while(times > 0)
				{
					if(!pScene->GetCanWalkPos(x,y))
						return;
//					if(x <= 400 || x >= 2160 || y <= 240 || y >= 1136)
//						times--;
//					else
						break;
				}
				if(x == 0 || y == 0)
					return;
				pUser->SaveEnterPos(pUser->GetSceneId(),pUser->GetX(),pUser->GetY());
				CNetMessage msg1;
				msg1.ReWrite();
				msg1.SetType(PRO_JUMP_SCENE);
				msg1<<(uint16)pScene->GetSrcSceneId()<<x<<y<<(uint8)0<<(uint8)0;
				m_socketServer.SendMsg(pUser->GetSock(),msg1);
				pUser->SetPos(x,y);
				pUser->SetFace(0);
				pUser->EnterScene(pScene);

				SendPKNotice(pUser);
			}
			else
			{
				char buf[128];
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1009,KUN_LUN_SHAN_TIME,KUN_LUN_SHAN_TIME);
				msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				return;
			}
		}
		else if(op1 == 2)	// 排行榜
		{
			GetKunLunShanPaiHang(pUser,msg);
		}
		else if(op1 == 3)	// 个人活动信息
		{
			uint16 flushSecond = 0xffff;
			//int hour = GetHour();
			int minute = GetMinute();
			int sec = GetSysTime()%60;
			if(CSceneManager::IsInActivityTime(SOT_Kunlunshan))	// 5分钟刷新
				flushSecond = (4 - minute%5)*60 + (60 - sec);
			uint16 killRoleNum = pUser->GetExtData16(32);
			uint16 killMonsterNum = pUser->GetExtData16(33);

			//           历险点					杀敌数			杀怪数	下次怪物刷新时间  总时间间隔	杀敌任务数
			msg<<pUser->GetExtData16(31)<<killRoleNum<<killMonsterNum<<flushSecond<<(uint16)(5*60)<<(uint8)3
			//		杀敌task1		目标			奖励1			奖励2			是否完成
				<<LANGUAGE_TRANSFORM_1010<<LANGUAGE_TRANSFORM_1011<<(uint16)1<<LANGUAGE_TRANSFORM_1012<<LANGUAGE_TRANSFORM_1013<<(uint8)((killRoleNum>=1) ? 1 : 0)
			//		杀敌task2		目标			奖励1			奖励2			是否完成
				<<LANGUAGE_TRANSFORM_1014<<LANGUAGE_TRANSFORM_1015<<(uint16)4<<LANGUAGE_TRANSFORM_1016<<LANGUAGE_TRANSFORM_1017<<(uint8)((killRoleNum>=4) ? 1 : 0)
			//		杀敌task3		目标			奖励1			奖励2			是否完成
				<<LANGUAGE_TRANSFORM_1018<<LANGUAGE_TRANSFORM_1019<<(uint16)7<<LANGUAGE_TRANSFORM_1020<<LANGUAGE_TRANSFORM_1021<<(uint8)((killRoleNum>=7) ? 1 : 0)
			// 	杀怪任务数	杀怪task1		目标			奖励1			奖励2			是否完成
				<<(uint8)3<<LANGUAGE_TRANSFORM_1022<<LANGUAGE_TRANSFORM_1023<<(uint16)1<<LANGUAGE_TRANSFORM_1024<<LANGUAGE_TRANSFORM_1025<<(uint8)((killMonsterNum>=1) ? 1 : 0)
			//		杀怪task2		目标			奖励1			奖励2			是否完成
				<<LANGUAGE_TRANSFORM_1026<<LANGUAGE_TRANSFORM_1027<<(uint16)3<<LANGUAGE_TRANSFORM_1028<<LANGUAGE_TRANSFORM_1029<<(uint8)((killMonsterNum>=3) ? 1 : 0)
			//		杀怪task3		目标			奖励1			奖励2			是否完成
				<<LANGUAGE_TRANSFORM_1030<<LANGUAGE_TRANSFORM_1031<<(uint16)6<<LANGUAGE_TRANSFORM_1032<<LANGUAGE_TRANSFORM_1033<<(uint8)((killMonsterNum>=6) ? 1 : 0);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
		}
		else if(op1 == 4)	// 获取房间信息
		{
			CScene *pScene = pUser->GetScene();
			if(pScene == NULL)
				return;
			if(pScene->GetSrcSceneId() < KUN_LUN_SHAN_SCENE_ID || pScene->GetSrcSceneId() >= KUN_LUN_SHAN_SCENE_ID+30)
				return;
			msg<<(uint16)(pScene->GetId()-KUN_LUN_SHAN_SCENE_ID_BEGIN+1);
			m_sceneManager.GetKunLunShanRoomInfo(msg);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
		}
		else if(op1 == 5)	// 切换房间
		{
			uint16 index = 0;
			msg>>index;
			if(index == 0)
				return;
			if(index > m_sceneManager.GetKunLunShanSceneNum())
				return;
			CScene *pScene = pUser->GetScene();
			if(pScene == NULL)
				return;
			if(index == pScene->GetId()-KUN_LUN_SHAN_SCENE_ID_BEGIN+1)
			{
				msg<<MakeStringColor(LANGUAGE_TRANSFORM_1034,TIPS_WARNING_COLOR);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				return;
			}
			if(pUser->GetFightId() > 0)
			{
				msg<<MakeStringColor(LANGUAGE_SSJ_0482,TIPS_WARNING_COLOR);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				return;
			}
			if(!pUser->CanWorldTransPort(KUN_LUN_SHAN_SCENE_ID))
			{
				msg<<MakeStringColor(LANGUAGE_SSJ_0475,TIPS_WARNING_COLOR);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				return;
			}

			pScene = m_sceneManager.GetKunLunShanSceneByIndex(index);
			if(pScene == NULL)
				return;
			if(pScene->GetUserNum() >= KUN_LUN_SHAN_ROOM_LIMIT)
			{
				msg<<MakeStringColor(LANGUAGE_TRANSFORM_1035,TIPS_WARNING_COLOR);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				return;
			}

			uint16 x=0,y=0;
			if(!pScene->GetCanWalkPos(x,y))
				return;
			CNetMessage msg1;
			msg1.ReWrite();
			msg1.SetType(PRO_JUMP_SCENE);
			msg1<<(uint16)pScene->GetSrcSceneId()<<x<<y<<(uint8)0<<(uint8)0;
			m_socketServer.SendMsg(pUser->GetSock(),msg1);
			pUser->SetPos(x,y);
			pUser->SetFace(0);
			pUser->EnterScene(pScene);
		}
	}
	else if(op == 4)	// 昆仑山图标
	{

	}
	else if(op == 5)	// 昆仑山数据更新,type=1历险点,2杀敌数,3杀怪数,4杀敌任务(index)完成标识,5杀怪任务(index)完成标志,6刷怪时间更新
	{

	}
	else if(op == 6) //灵气捐献，请求数据
	{
		// CHECK_SYSTEM_OPEN(SOT_Lingqijuanxian)
		int lingqizhi = 0;
		{
			boost::recursive_mutex::scoped_lock lk(lingQiJuanXian_mutex);
			lingqizhi = lingQiValue;
		}
		int level = pUser->GetLevel();
		int64 exp[5] = {0};	// 橙，紫，蓝，绿，白
		CHuoDongExpManage &expManager = SingletonHuoDongExpManager::instance();
		exp[0] = expManager.GetHuoDongExp(8,level,1.15/3);
		exp[1] = expManager.GetHuoDongExp(8,level,1.0/3);
		exp[2] = expManager.GetHuoDongExp(8,level,0.85/3);
		exp[3] = expManager.GetHuoDongExp(8,level,0.7/3);
		exp[4] = expManager.GetHuoDongExp(8,level,0.6/3);

		int useTimes = G_VipConfig[pUser->GetVipLevel()].lingqi - pUser->GetLingqiJuanxian();
		if(useTimes < 0)
			useTimes = 0;
		msg<<lingqizhi<<(uint8)useTimes<<(uint16)2357<<exp[0]<<(uint16)2356<<exp[1]<<(uint16)2355<<exp[2]<<(uint16)2354<<exp[3]
			<<(uint16)0<<exp[4];
		m_socketServer.SendMsg(pUser->GetSock(),msg);
	}
	else if(op == 7)	// 灵气捐献
	{
		// CHECK_SYSTEM_OPEN(SOT_Lingqijuanxian)
		uint8 type = 0;
		int itemId = 0;
		int level = pUser->GetLevel();
		int point = 0;
		msg>>type;
		if(type == 0 || type > 5)
			return;

		int64 exp = GetLevelUpExp(level);
		if(pUser->GetLingqiJuanxian() >= G_VipConfig[pUser->GetVipLevel()].lingqi)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1037,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}

		CHuoDongExpManage &expManager = SingletonHuoDongExpManager::instance();
		if(type == 1)	// 先锋令(橙)
		{
			point = 5;
			itemId = 2357;
			exp = expManager.GetHuoDongExp(8,level,1.15/3);
		}
		else if(type == 2)	// 先锋令(紫)
		{
			point = 4;
			itemId = 2356;
			exp = expManager.GetHuoDongExp(8,level,1.0/3);
		}
		else if(type == 3)	// 先锋令(蓝)
		{
			point = 3;
			itemId = 2355;
			exp = expManager.GetHuoDongExp(8,level,0.85/3);
		}
		else if(type == 4)	// 先锋令(绿)
		{
			point = 2;
			itemId = 2354;
			exp = expManager.GetHuoDongExp(8,level,0.7/3);
		}
		else	// 无
		{
			point = 1;
			exp = expManager.GetHuoDongExp(8,level,0.6/3);
		}

		if(itemId > 0)
		{
			if(pUser->GetItemNum(itemId) > 0)
			{
				pUser->DelPackageById(itemId,1);
				pUser->AddExp(exp, true);
				pUser->IncLingqiJuanxian();
				pUser->CheckMissionHuoYueDu();
				SaveDate(pUser, 27, 1);
				boost::recursive_mutex::scoped_lock lk(lingQiJuanXian_mutex);
				if(lingQiValue < 1000)
				{
					lingQiValue += point;
					if(lingQiValue > 1000)
						lingQiValue = 1000;
				}
				msg<<PRO_SUCCESS<<lingQiValue<<MakeStringColor(LANGUAGE_TRANSFORM_1038,TIPS_WARNING_COLOR);

				pUser->SetExtData8(577,pUser->GetExtData8(577) + 1);
				if (type == 1)
					pUser->SetExtData8(579,pUser->GetExtData8(579) + 1);
				else if (type == 2)
					pUser->SetExtData8(578,pUser->GetExtData8(578) + 1);
			}
			else
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1039,TIPS_FAILURE_COLOR);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				return;
			}
		}
		else
		{
			pUser->AddExp(exp, true);
			pUser->IncLingqiJuanxian();
			pUser->CheckMissionHuoYueDu();
			SaveDate(pUser, 27, 1);
			boost::recursive_mutex::scoped_lock lk(lingQiJuanXian_mutex);
			if(lingQiValue < 1000)
			{
				lingQiValue += point;
				if(lingQiValue > 1000)
					lingQiValue = 1000;
			}
			msg<<PRO_SUCCESS<<lingQiValue<<MakeStringColor(LANGUAGE_TRANSFORM_1040,TIPS_WARNING_COLOR);
		}
		m_socketServer.SendMsg(pUser->GetSock(),msg);

		// =====================
		// 更新灵气捐献任务
		if(pUser->GetExtData8(66) < 0xff)
			pUser->SetExtData8(66,pUser->GetExtData8(66)+1);
		SingletonCMissionManager::instance().VerifyNewBranchMissionFinish(pUser, EMISS_DC_31); // TODO
	}
	else if(op == 8)	// 每日签到
	{
		static int day = 0;
		static vector<SDailySignData> dailySign[2];
		bool readSign = false;
		int curDay = GetDay();
		if(day == 0)
		{
			day = curDay;
			readSign = true;
		}
		else
		{
			if(day != curDay)
			{
				day = curDay;
				if(day == 1)
				{
					CGetDbConnect getDb;
					CDatabaseSql *pDb = getDb.GetDbConnect();
					if(pDb == NULL)
						return;
					// 拷贝下个月的奖励内容
					pDb->Query("delete from dailysign where mon_type=1");
					pDb->Query("insert into dailysign(mon_type,day_idx,award_type,award_num,award_value,vip_lv,vip_multiple) select 1,day_idx,award_type,award_num,award_value,vip_lv,vip_multiple from dailysign where mon_type=2 order by day_idx asc");
					readSign = true;
				}
			}
		}
		if(dailySign[0].empty())
			readSign = true;
		if(readSign)
		{
			char sql[256];
			char **row = NULL;
			for(uint8 i=0;i < 2;i++)
			{
				dailySign[i].clear();

				CGetDbConnect getDb;
				CDatabaseSql *pDb = getDb.GetDbConnect();
				if(pDb == NULL)
					return;
				//									0		 1			2		3		   4         5
				snprintf(sql,sizeof(sql),"select day_idx,award_type,award_num,vip_lv,vip_multiple, award_value from dailysign where mon_type=%d order by day_idx asc",(int)(i+1));
				if(!pDb->Query(sql))
					return;
				while((row = pDb->GetRow()) != NULL)
				{
					SDailySignData temp;
					temp.monType = i+1;
					temp.dayIdx = (uint8)atoi(row[0]);
					temp.awardType = atoi(row[1]);
					temp.awardNum = atoi(row[2]);
					temp.vipLv = (uint8)atoi(row[3]);
					temp.vipMultiple = (uint8)atoi(row[4]);
					temp.awardValue = (uint8)atoi(row[5]);
					dailySign[i].push_back(temp);
				}
			}
		}

		uint8 type = 0;	// 0获取签到信息1签到
		msg>>type;
		if(type == 0)	//获取签到信息
		{
			if(dailySign[0].empty())
			{
				cout<<"dailySign[0] is empty , error!!!"<<endl;
				return;
			}
			uint8 dayNum = (uint8)GetMonthDayNum();
			uint8 num = (dayNum > dailySign[0].size()) ? dailySign[0].size() : dayNum;
			//           当天是否已签到               累计签到天数
			msg<<(uint8)pUser->HaveBitSet(504)<<pUser->GetExtData8(62)<<num;
			for(uint8 i=0;i < num;i++)
				msg<<dailySign[0][i].dayIdx<<dailySign[0][i].awardType<<dailySign[0][i].awardNum<< dailySign[0][i].awardValue <<dailySign[0][i].vipLv<<dailySign[0][i].vipMultiple;
			m_socketServer.SendMsg(pUser->GetSock(),msg);
		}
		else if(type == 1)	// 签到
		{
			if(pUser->HaveBitSet(504))
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1041,TIPS_FAILURE_COLOR);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				return;
			}
			
			uint8 dayNum = (uint8)GetMonthDayNum();
			uint8 num = (dayNum > dailySign[0].size()) ? dailySign[0].size() : dayNum;
			uint8 signDay = pUser->GetExtData8(62);
			if(signDay >= num)
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1042,TIPS_FAILURE_COLOR);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				return;
			}
			pUser->SetBitSet(504);
			pUser->SetExtData8(62,signDay+1);

			uint32 awardType = dailySign[0][signDay].awardType;
			uint32 awardNum = dailySign[0][signDay].awardNum;
			uint32 awardValue = dailySign[0][signDay].awardValue;
			uint8 vip = pUser->GetVipLevel();
			if(vip >= dailySign[0][signDay].vipLv)
				awardNum *= dailySign[0][signDay].vipMultiple;
			pUser->AddMaterial(awardType,awardNum,false,true, awardValue);
			msg<<PRO_SUCCESS;				
			m_socketServer.SendMsg(pUser->GetSock(),msg);
		}
	}
	else if(op == 12)	// 灵魔活动传送
	{
		if(pUser->InHuSongMission() == 1)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1048,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		else if(pUser->InHuSongMission() == 2)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1049,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}

		if(!IsInLingMoActivity() || topBangPai.empty())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1050,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}

		if(CSceneManager::IsInActivityTime(SOT_Bangpailingmo))	// 活动时间
		{
			// CHECK_SYSTEM_OPEN(SOT_Bangpailingmo)
			if (pUser->GetFightId() == 0)
			{
				//if(pUser->GetLevel() >= 30)
				{
					if(pUser->GetTeam() != 0)
					{
						if(pUser->GetTeam() != pUser->GetRoleId())	// 队员
						{
							msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1051,TIPS_FAILURE_COLOR);
							m_socketServer.SendMsg(pUser->GetSock(),msg);
							return;
						}
					}

					uint32 bangPaiId = topBangPai[Random(1,topBangPai.size())-1];
					CNetMessage msg1;
					msg1.SetType(PRO_BANGPAI);
					msg1<<(uint8)27<<bangPaiId;
					BangPai(&msg1,sock);
				}
				/*else
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1052,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
				}*/
			}
			else
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1053,TIPS_FAILURE_COLOR);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
		}
		else
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1054,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
		}
	}
	else if(op == 13)	// 飞仙
	{

	}
	else if(op == 14)	// 六界 巡察使
	{
		int hour = GetHour();
		const int SceneId[] = {11, 2, 3, 4};
		const uint8 allNumPerScene = 6;
		if(hour >= 10)
		{
			msg<<PRO_SUCCESS;
			uint8 size = sizeof(SceneId)/sizeof(SceneId[0]);
			uint8 num = 0;
			uint16 pos = msg.GetDataLen();
			msg<<num;
			for(uint8 i=0;i < size;i++)
			{
				const char *pName = GetSceneName(SceneId[i]);
				if(pName == NULL)
					continue;
				uint32 data = pUser->GetExtData32(116);
				uint8 killNum = 0;
				for(uint32 k=i*6; k < (uint32)((i+1)*6); k++)
				{
					if((data & (1<<k)) > 0)
						killNum++;
				}
				num++;
				msg<<(uint16)SceneId[i]<<pName<<killNum<<allNumPerScene;
			}
			msg.WriteData(pos,&num,sizeof(num));
		}
		else
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1055,TIPS_FAILURE_COLOR);
		}
		m_socketServer.SendMsg(sock,msg);
	}
	else if(op == 15)	// 活动兑换豪礼,获得兑换信息
	{
		if(!MakeExchangeMsg(pUser,msg))
			return;
		m_socketServer.SendMsg(pUser->GetSock(),msg);
		return;
	}
	else if(op == 16)	// 活动兑换豪礼,兑换
	{
		if(!ExchangeItem(pUser,msg))
			return;
		m_socketServer.SendMsg(pUser->GetSock(),msg);
		return;
	}
	else if(op == 17)	// 活动兑换豪礼,领取礼包
	{
		GetExchangeAward(pUser,msg);
		return;
	}
	else if (op == 18)	// 活动兑换豪礼,领取礼包
	{
		string str;
		msg >> str;
		CCallScript *pScript = FindScript(1);
		if (pScript == NULL)
			return;
		pScript->Call("CheckNewUser_JHM_all", "us", pUser, str.c_str());
	}
	else if (op == 19)	// 年兽传送
	{
		// CHECK_SYSTEM_OPEN(SOT_Nianshou)
		if (pUser->InHuSongMission() == 1)
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_997, TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(), msg);
			return;
		}
		else if (pUser->InHuSongMission() == 2)
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_998, TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(), msg);
			return;
		}

		if (InFightHuoDong())
		{
			if (pUser->GetFightId() == 0)
			{
				if (pUser->GetTeam() != 0)
				{
					if (pUser->GetTeam() != pUser->GetRoleId())	// 队员
					{
						msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_999, TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(), msg);
						return;
					}
				}
				if (pUser->GetSceneId() != 3)
				{
					int r = Random(1, 2);
					if (r == 1)
						TransportUser(pUser, 3, 830, 826, 3);
					else if (r == 2)
						TransportUser(pUser, 3, 2173, 930, 2);

				}
				ChangeClientGuaJiState(pUser, 1);
			}
			else
			{
				msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_1001, TIPS_FAILURE_COLOR);
				m_socketServer.SendMsg(pUser->GetSock(), msg);
			}
		}
		else
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_1002, TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(), msg);
		}
	}
	else if (op == 20)
	{
		uint16 day = SingletonCHuoDongAwardManager::instance().ServerOpenDay();
		msg << day << pUser->GetRegDay();

		m_socketServer.SendMsg(pUser->GetSock(), msg);
	}
}

//答题 1: 获取问题 2: 提供答案 3: 关闭界面完成答题 4: 通知开始答题 5：通知结束答题
void CPackageDeal::AnswerQuestionOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 op = 0;
	msg>>op;
	static uint8 MaxTiMuCnt = 10;
	static uint8 MaxDaTiTimes = 1;
	switch (op)
	{
	case 1: // 获取问题
		{
			msg.ReWrite();
			msg.SetType(MSG_ANSWER_QUESION);
			msg<<op;
			if (pUser->GetExtData8(ED8_6) >= MaxDaTiTimes) // 当天答题场次已满
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1057,TIPS_FAILURE_COLOR);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				return;
			}

			if (pUser->GetExtData8(ED8_35) >= MaxTiMuCnt) // 阶段答题完成
			{
				pUser->SetExtData8(ED8_35,0);
				pUser->ClearQuestionId();
			}

			CCallScript *pCallScript = FindScript(200);
			if(pCallScript != NULL)
			{
				char *pQuestion = NULL;
				char *pAnswer = NULL;
				pCallScript->Call("GetQuestionAnswer","u>ss",pUser,&pQuestion,&pAnswer);
				if (pAnswer == NULL)
				{
					msg<<PRO_ERROR<<"";
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				uint8 curVal = pUser->AddExtData8(ED8_35, 1); // 阶段答题次数
				pUser->m_isInDaTi = true; // 答题状态标记
				msg<<PRO_SUCCESS<< curVal <<(uint8)(MaxTiMuCnt - curVal)<<pQuestion<<pAnswer;
				m_socketServer.SendMsg(pUser->GetSock(),msg);

				pUser->SetExtData32(ED32_6,GetSysTime()); // 记录当前答题时间
				if (pUser->GetExtData8(ED8_35) >= MaxTiMuCnt)
				{
					pUser->AddExtData8(ED8_6, 1); // 增加答题次数
				}
				pUser->SetBitSet(433);
				SingletonCMissionManager::instance().VerifyNewBranchMissionFinish(pUser, EMISS_DC_62); // TODO
			}
			else
			{
				msg<<PRO_ERROR<<"";
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				return;
			}
			break;
		}
	case 2: // 提供答案
		{
			uint8 answer = 0; // 答题结果
			msg>>answer;
			msg.ReWrite();
			msg.SetType(MSG_ANSWER_QUESION);
			msg<<op;
			if (!pUser->m_isInDaTi) // 答题状态校验
			{
				msg<<PRO_ERROR<<(uint8)1<<0<<MakeStringColor(LANGUAGE_TRANSFORM_1059,TIPS_FAILURE_COLOR);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				return;
			}
			pUser->m_isInDaTi = false; // 重置答题状态

			int useTime = GetSysTime() - pUser->GetExtData32(ED32_6); // 答题使用时间
			if ((useTime > 13) || (useTime < 0))
				useTime = 13;
			if (pUser->GetVal(1) == answer) // 回答正确
			{
				msg << PRO_SUCCESS << (int)0;
				pUser->AddExtData8(ED8_683, 1);
			}
			else // 回答错误
			{
				int addMoney = 0;
				msg << PRO_ERROR << (uint8)pUser->GetVal(1) << addMoney << MakeStringColor(LANGUAGE_TRANSFORM_1060, TIPS_FAILURE_COLOR);
			}

			if (pUser->GetExtData8(ED8_35) >= MaxTiMuCnt)
			{
				MultiAward rad;
				sAwardManager.GetRankAward(CRankMgr::ERT_DaTiZhengQueShu, pUser->GetExtData8(ED8_683), rad);
				SendAndMakeAwardMsg(pUser, rad, msg, false, MUT_DaTi);
			}
			m_socketServer.SendMsg(pUser->GetSock(), msg);
			break;
		}
	case 3: // 关闭界面完成答题
		{
			break;
		}
	default:
		{

		}
	}
}

// 客户端同步获取服务器时间
void CPackageDeal::SyncTime(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER
	int todayMinute = 0;
	msg.ReWrite();
	msg.SetType(MSG_SYNC_TIME);
	todayMinute = GetHour()*3600 + GetMinute()*60 + GetSysTime()%60;
	msg<<todayMinute<<(uint32)GetSysTime();
	m_socketServer.SendMsg(pUser->GetSock(),msg);
}

void CPackageDeal::GetMissionList(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER
	uint8 op;

	msg >> op;
	CUserMission& miss = pUser->GetUserMission();
	switch (op)
	{
	case 1:
		CHECK_SYSTEM_OPEN(SOT_10)
		miss.GetQuestMessage(pUser, msg);
		break;

	case 3:
		CHECK_SYSTEM_OPEN(SOT_10)
		miss.GetQuestAward(pUser, msg);
		break;

	case 4:
		CHECK_SYSTEM_OPEN(SOT_11)
		miss.GetHDQuestMessage(msg);
		break;

	case 6:
		CHECK_SYSTEM_OPEN(SOT_11)
		miss.GetHDQuestAward(pUser, msg);
		break;

	case 7:
		miss.GetJiJinQuestMessage(msg);
		break;

	case 9:
		miss.GetJiJinQuestAward(pUser, msg);
		break;
	default:
		break;
	}
	m_socketServer.SendMsg(pUser->GetSock(),msg);
}

void CPackageDeal::GetPetSkill(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint16 petId = 0;
	msg>>petId ;
	pUser->MakePetSkill(petId,msg);
	m_socketServer.SendMsg(pUser->GetSock(),msg);
}

void CPackageDeal::BroadcastChat(CUser *pUser,CNetMessage *msg,int ignoreId)
{
	if(ignoreId > 0 && SingletonCFriendMgr::instance().IsInBlackList(pUser->GetRoleId(), ignoreId))
		return;
	if((pUser->GetChatChannel() & 1) == 1)
		m_socketServer.SendMsg(pUser->GetSock(),*msg);
}

void CPackageDeal::BroadcastChatByZoneId(CUser *pUser,CNetMessage *msg,int ignoreId,int zoneId)
{
	if(pUser == NULL)
		return;
	if(ignoreId > 0 && SingletonCFriendMgr::instance().IsInBlackList(pUser->GetRoleId(), ignoreId))
		return;
	if(GetServerZone(pUser->GetServerId()) != zoneId)
		return;
	m_socketServer.SendMsg(pUser->GetSock(),*msg);
}

void CPackageDeal::ChatChannel(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 chatVal = pUser->GetChatChannel();
	uint8 channel;
	uint8 open;
	msg>>channel>>open;

	if((channel < 1) ||(channel > 6))
		return;
	channel--;
	if(open == 0)
	{
		//关
		chatVal &= ~(1<<channel);
	}
	else if(open == 1)
	{
		//开
		chatVal |= 1<<channel;
	}

	//printf("聊天通道设置:%02x,%d\n",chatVal,channel);

	pUser->SetChatChannel(chatVal);
}

//以前是潜能聊天，后来改为管理员功能
static bool AllowIp(in_addr_t ip)
{
	const in_addr_t ALLOW_IP_LIST[] =
	{
		inet_addr("127.0.0.1"),
		inet_addr("192.168.2.131"),
	};

	for(uint8 i = 0; i < sizeof(ALLOW_IP_LIST)/sizeof(ALLOW_IP_LIST[0]); i++)
	{
		if(ip == ALLOW_IP_LIST[i])
			return true;
	}
	return false;
}

void CPackageDeal::SpecChat(CNetMessage *pMsg,int sock)
{
	GET_MSG
	sockaddr_in addr;
	socklen_t len = sizeof(addr);
	getpeername(sock, (sockaddr*)&addr,&len);
	if(!AllowIp(addr.sin_addr.s_addr))
	{
		GET_USER
		if(pUser->AdminLevel() <= 0)
			return;
	}
	uint32 roleId;
	uint8 type;
	msg>>type>>roleId;

	switch(type)
	{
		case 1:
			{
				CGetDbConnect getDb;
				CDatabaseSql *pDb = getDb.GetDbConnect();
				if(pDb != NULL)
				{
					char buf[64];
					snprintf(buf,sizeof(buf),"update role_info set state=2 where id=%d",roleId);
					pDb->Query(buf);
				}
				ShareUserPtr p = m_onlineUser.GetUserByRoleId(roleId);
				if(p.get() != NULL)
				{
					msg.ReWrite();
					msg.SetType(PRO_MSG_CHAT);
					char buf[64];
					snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1061,p->GetName());
					msg<<(uint8)1<<0<<LANGUAGE_TRANSFORM_1062<<(uint8)0<<buf;
					m_onlineUser.ForEachUser(boost::bind(&CPackageDeal::BroadcastChat,this,_1,&msg,0));
				}
			}
			break;
		case 2:
			{
				ShareUserPtr p = m_onlineUser.GetUserByRoleId(roleId);
				if(p.get() != NULL)
				{
					p->SetChatTime(GetSysTime()+1800);
					msg.ReWrite();
					msg.SetType(PRO_MSG_CHAT);
					char buf[64];
					snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1063,p->GetName());
					msg<<(uint8)1<<0<<LANGUAGE_TRANSFORM_1064<<(uint8)0<<buf;
					m_onlineUser.ForEachUser(boost::bind(&CPackageDeal::BroadcastChat,this,_1,&msg,0));
				}
			}
			break;
		case 3:
			{
				ShareUserPtr p = m_onlineUser.GetUserByRoleId(roleId);
				if(p.get() != NULL)
				{
					shutdown(p->GetSock(),SHUT_RD);
				}
			}
			break;
		case 4:
			{
				//跟新npc脚本
				/*SNpcTemplate *pNpc = m_npcManager.GetNpcTemplate(roleId);
				  if((pNpc != NULL) && (pNpc->pScript != NULL))
				  pNpc->pScript->ReLoad();*/
				CCallScript *pScript = FindScript(roleId);
				if(pScript != NULL)
					pScript->ReLoad();
			}
			break;
		case 5:
			{
				//跟新物品脚本
				CItemTemplateManager &itemMgr = SingletonItemManager::instance();
				SItemTemplate *pItem = itemMgr.GetItem(roleId);
				if((pItem != NULL) && (pItem->pScript != NULL))
				{
					pItem->pScript->ReLoad();
				}
			}
			break;
		case 6:
			{
				string info;
				string adminName;
				msg>>adminName>>info;
//				int adminId = 0;
				if(adminName == "gm1")
				{
					adminName = LANGUAGE_TRANSFORM_1065;
//					adminId = 1;
				}
				else if(adminName == "gm2")
				{
					adminName = LANGUAGE_TRANSFORM_1066;
//					adminId = 2;
				}
				else if(adminName == "gm3")
				{
					adminName = LANGUAGE_TRANSFORM_1067;
//					adminId = 3;
				}
				else if(adminName == "gm4")
				{
					adminName = LANGUAGE_TRANSFORM_1068;
//					adminId = 4;
				}
				else if(adminName == "moyudao")
				{
					adminName = LANGUAGE_TRANSFORM_1069;
//					adminId = 5;
				}
				else if(adminName == "leduo001")
				{
					adminName = LANGUAGE_TRANSFORM_1070;
//					adminId = 6;
				}
				else if(adminName == "leduo002")
				{
					adminName = LANGUAGE_TRANSFORM_1071;
//					adminId = 7;
				}
				else if(adminName == "imod")
				{
					adminName = LANGUAGE_TRANSFORM_1072;
//					adminId = 8;
				}
				else if(adminName == "yang")
				{
					adminName = LANGUAGE_TRANSFORM_1073;
//					adminId = 9;
				}

				SendSystemMail(roleId,info.c_str());
			}
			break;
		case 7:
			/*OP=7 添加称号
			  +-----+-----+-----+
			  | OP  | CID | TID |
			  +-----+-----+-----+
			  |  1  |  4  |  2  |
			  +-----+-----+-----+*/
			{
				uint16 title = 0;
				msg>>title;
				COnlineUser &onlineUser = SingletonOnlineUser::instance();
				ShareUserPtr ptr = onlineUser.GetUserByRoleId(roleId);
				if(ptr.get() != NULL)
				{
					ptr->AddTitle(title);
				}
				else
				{
					CUser *pUser = new CUser;
					auto_ptr<CUser> user(pUser);
					CGetDbConnect getDb;
					CDatabaseSql *pDb = getDb.GetDbConnect();
					if(pDb == NULL)
						return;
					char sql[4096];
					snprintf(sql,sizeof(sql),"select title from role_info where id=%u",roleId);
					if(!pDb->Query(sql))
						return;
					char **row = pDb->GetRow();
					if(row == NULL)
						return;
					pUser->ReadTitle(row[0]);
					pUser->AddTitle(title);
					string str;
					pUser->GetTitleStr(str);
					snprintf(sql,sizeof(sql),"update role_info set title='%s' where id=%u",str.c_str(),roleId);
					pDb->Query(sql);
				}
			}
	}
	msg.ReWrite();
	msg.SetType(PRO_SPEC_CHAT);
	m_socketServer.SendMsg(sock,msg);
}

void CPackageDeal::SendTeamInfoToWorldChat(CUser *pUser,const char *pStr)
{
	if(pUser == NULL || pStr == NULL)
		return;

	CNetMessage msg;
	msg.SetType(PRO_MSG_CHAT);
	uint8 vipLv = pUser->HaveBitSet(604) ? 0 : pUser->GetVipLevel();
#ifndef KUA_FU
	msg<<(uint8)ECT_World;
#else
	msg<<(uint8)ECT_KuaFu;
#endif
	msg<<pUser->GetRoleId()<<pUser->GetName()<<vipLv<<pUser->GetSex()<<pStr;
	m_onlineUser.ForEachUser(boost::bind(&CPackageDeal::BroadcastChat,this,_1,&msg,0));

#ifdef KUA_FU
	KFChatMsgToAllServer(msg);
#endif
}
bool CPackageDeal::DoGMString(CUser *pUser, string chatMsg)
{
#if _DEBUG
	do
	{
		if (chatMsg.length() > 64)
			break;
		char buf[64];
		int num = 0;
		char *p[64];
		strncpy(buf, chatMsg.c_str(), sizeof(buf));
		num = SplitLine(p, buf, ' ');
		if (num != 3)
			break;
		if (strcmp(p[0], "add") != 0)
			break;

		char tbuf[64];
		int tnum = 0;
		char *tp[64];
		strncpy(tbuf, p[2], sizeof(tbuf));
		tnum = SplitLine(tp, tbuf, ',');
		CItemCfgManager& imgr = sCItemCfgManager;
		CPetCfgManager& mgr = sCPetCfgManager;
		if (strcmp(p[1], "lv") == 0 && tnum == 1)
		{
			uint16 gmNum = atoi(tp[0]);
			for (size_t i = 0; i < gmNum; i++)
			{
				uint16 lv = pUser->GetLevel();
				LvCfg* cfg = mgr.GetLvCfgCfg(lv);
				if (cfg != NULL)
					pUser->AddExp(cfg->exp);
			}
		}
		else if (strcmp(p[1], "item") == 0 && tnum == 2)
		{
			pUser->AddMaterial(atoi(tp[0]), atoi(tp[1]));
		}
		else if (strcmp(p[1], "hero") == 0 && tnum == 1)
		{
			AddPet(pUser, atoi(tp[0]), 1);
		}
		else if (strcmp(p[1], "equip") == 0 && tnum == 2)
		{
			uint16 eid = atoi(tp[0]);
			uint16 gmNum = atoi(tp[1]);
			for (size_t i = 0; i < gmNum; i++)
				pUser->AddEquip(eid, 1);
		}
		else if (strcmp(p[1], "fabao") == 0 && tnum == 2)
		{
			uint16 eid = atoi(tp[0]);
			uint16 gmNum = atoi(tp[1]);
			for (size_t i = 0; i < gmNum; i++)
				pUser->AddMaterial(HDAT_FaBao, eid);
		}
		else if (strcmp(p[1], "allequip") == 0)
		{
			uint16 gmNum = atoi(tp[0]);
			ComposeCfgMap* cmap = imgr.GetComposeCfgMap(CPT_EQUIP_HC);
			if (cmap == NULL)
				return false;
			for (ComposeCfgMapIt it = cmap->begin(); it != cmap->end(); ++it)
			{
				for (size_t j = 0; j < gmNum; j++)
					pUser->AddMaterial(it->second.tar.type, it->second.tar.typeId);
			}
		}
		else if (strcmp(p[1], "allhero") == 0)
		{
			ComposeCfgMap* cmap = imgr.GetComposeCfgMap(CPT_HERO_HC);
			if (cmap == NULL)
				return false;
			uint16 gmNum = atoi(tp[0]);
			for (ComposeCfgMapIt it = cmap->begin(); it != cmap->end(); ++it)
			{
				for (size_t j = 0; j < gmNum; j++)
					pUser->AddMaterial(it->second.tar.type, it->second.tar.typeId);
			}
		}
		else if (strcmp(p[1], "allfabao") == 0)
		{
			ComposeCfgMap* cmap = imgr.GetComposeCfgMap(CPT_FABAO_HC);
			if (cmap == NULL)
				return false;
			uint16 gmNum = atoi(tp[0]);
			for (ComposeCfgMapIt it = cmap->begin(); it != cmap->end(); ++it)
			{
				for (size_t j = 0; j < gmNum; j++)
					pUser->AddMaterial(it->second.tar.type, it->second.tar.typeId);
			}
		}
		else if (strcmp(p[1], "quest") == 0 && tnum == 3)
		{
			uint16 type = atoi(tp[0]);
			uint16 num = atoi(tp[1]);
			uint16 cond = atoi(tp[2]);
			sCMissionManager.UpdateQuestState(pUser, type, num, cond);
		}
		else if (strcmp(p[1], "yc") == 0 && tnum == 2)
		{
			uint16 type = atoi(tp[0]);
			uint16 level = atoi(tp[1]);
			CEquipManeger& emgr = pUser->GetPetEquipMgr();
			emgr.QiangHuaAllEquip(pUser, type, level);
		}
		else if (strcmp(p[1], "gq") == 0 && tnum == 2)
		{
			uint16 type = atoi(tp[0]);
			uint16 level = atoi(tp[1]);
			CUserGuanQia& gq = pUser->GetGuanQia();
			gq.GuanQiaGM(pUser, type, level);
		}
		else if (strcmp(p[1], "mail") == 0)
		{
			uint16 type = atoi(tp[0]);
			MultiAward ads;
			if (type == 1)
			{
				SAwardData ad;
				ad.type = HDAT_PET;
				ad.typeId = 13;
				ad.num = 1;
				ads.push_back(ad);
				ad.type = HDAT_MONEY;
				ad.num = 10000;
				ads.push_back(ad);
				ad.type = HDAT_YB;
				ad.num = 1000;
				ads.push_back(ad);
				ad.type = HDAT_PetEquip;
				ad.typeId = 1001;
				ad.num = 10;
				ads.push_back(ad);
				ad.type = HDAT_FaBao;
				ad.typeId = 617;
				ad.num = 10;
				ad.type = HDAT_FaBao;
				ad.typeId = 618;
				ad.num = 10;
				ads.push_back(ad);
				ad.type = HDAT_XingXiuJingHua;
				ad.num = 500;
				ads.push_back(ad);
				ad.type = HDAT_JJCMoney;
				ad.num = 1500;
				ads.push_back(ad);
				ad.type = HDAT_KunLunMoney;
				ad.num = 2000;
				ads.push_back(ad);
				ad.type = HDAT_SHEN_HUN;
				ad.num = 2500;
				ads.push_back(ad);
			}
			SendSystemAwardMail(pUser->GetRoleId(), "测试邮件", ads);
		}
		return true;
	} while (false);
#endif
	return false;
}

void CPackageDeal::UserChat(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER
	//// CHECK_SYSTEM_OPEN(SOT_Social)

	uint32 chatLimit = pUser->GetChatTime();
	uint32 curtime = GetSysTime();
	if(chatLimit > 0 && chatLimit > curtime)
		return;

	uint8 chanel = 0;
	string chatMsg;
	uint32 privateChatRoleId = 0;
	uint8 type = 0;		// 1 id ,  2 name
	string roleName;
	msg>>chanel>>chatMsg>>type;
	if(type == 1)
		msg>>privateChatRoleId;
	else if(type == 2)
		msg>>roleName;
	if(chatMsg.size() <= 0)
		return;

	if (DoGMString(pUser, chatMsg))
		return;
//	if(pUser->IsSendChatMsg(chatMsg))
//		return;
/*
#ifndef KUA_FU
	if (pUser->GetChongzhiTotal() < 30 * 10)
	{
		msg << PRO_ERROR;
		m_socketServer.SendMsg(pUser->GetSock(), msg);
		return;
	}
#endif // !_KUA_FU
*/

	string selfName = pUser->GetName();
	if(chanel == ECT_KuaFu)
	{
#ifndef KUA_FU
		selfName = GetKuaFuRoleName(pUser);
#endif
	}
	msg.ReWrite();
	msg.SetType(PRO_MSG_CHAT);
	ChatCharacterLimit(chatMsg,128);
	uint8 vipLv = pUser->HaveBitSet(604) ? 0 : pUser->GetVipLevel();
	msg<<chanel<<pUser->GetRoleId()<<selfName<<vipLv<<pUser->GetHead()<<pUser->GetSex();

//	if(pUser->GetRoleId() >= 10000) // 角色聊天非法字符过滤
//	{
//		IllegalMsgDeal(chatMsg);
//	}
	if(ExchangeIgnoreCharacter(chatMsg))
		return;

	msg<<chatMsg;
#ifdef _DEBUG_CHY
	char* content = (char*)chatMsg.data();
	if (content[0]=='/' && content[1]=='/')
	{
		Gm::exec(pUser,(char *)content+2);
		return;
	}
#endif

	/***********************************
	  1 世界 服务器收到此条消息 需向全部在线玩家广播
	  2 附近 服务器向当前地图上的玩家广播
	  3 队伍 服务器在队伍中广播
	  4 门派 服务器向同一门派的玩家广播
	  5 帮派 服务器向同一帮派中的玩家广播
	 ************************************/
	switch(chanel)
	{
		case ECT_World://世界
			{
/*				if(pUser->AdminLevel() > 0)
				{
					if(strncmp(chatMsg.c_str(),LANGUAGE_TRANSFORM_1074,8) == 0)
					{
						chanel = 0;
						msg.ReWrite();
						msg.SetType(PRO_MSG_CHAT);
						msg<<chanel<<pUser->GetRoleId()<<pUser->GetName()<<vipLv<<(chatMsg.c_str() + 8);
						SendMsgToAllUser(msg);
					}
					else if(strncmp(chatMsg.c_str(),LANGUAGE_TRANSFORM_1075,8) == 0)
					{
						SysInfoToAllUser(chatMsg.c_str()+8,1);
					}
					else if(strncmp(chatMsg.c_str(),LANGUAGE_TRANSFORM_1076,8) == 0)
					{
						SysInfoToAllUser(chatMsg.c_str()+8);
					}
					else
					{
						m_onlineUser.ForEachUser(boost::bind(&CPackageDeal::BroadcastChat,this,_1,&msg,0));
					}
					return;
				}
*/
				int leftTime = pUser->CanChat();
				if(leftTime == 0)
				{
					//// CHECK_SYSTEM_OPEN(SOT_WorldChat)
//					pUser->InsertChatMsg(chatMsg);
//					pUser->SetChatTime(GetSysTime());

					int zoneId = GetServerZone(pUser->GetServerId());
					m_onlineUser.ForEachUser(boost::bind(&CPackageDeal::BroadcastChatByZoneId,this,_1,&msg,pUser->GetRoleId(),zoneId));
//					m_onlineUser.ForEachUser(boost::bind(&CPackageDeal::BroadcastChat,this,_1,&msg,pUser->GetRoleId()));

					CNetMessage omsg;
					omsg.SetType(PRO_MSG_CHAT);
					omsg<<(uint8)ECT_World_SameZone<<GetServerZone(pUser->GetServerId())<<pUser->GetRoleId()<<selfName<<vipLv<<pUser->GetHead()<<pUser->GetSex()<<chatMsg;
					KFChatMsgToAllServer(omsg);

					SaveChatLog(pUser,chanel,chatMsg.c_str());
					pUser->SetExtData32(720, GetSysTime());
				}
				else
				{
					char buf[128];
					snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1078,leftTime);
					
					msg.ReWrite();
					msg.SetType(PRO_MSG_CHAT);
					msg<<(uint8)8<<chanel<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
				}
				SingletonCMissionManager::instance().VerifyNewBranchMissionFinish(pUser, EMISS_DC_16); // TODO
#ifdef KUA_FU
				SingletonCMissionManager::instance().FinishKuaFuRiChang(pUser, 1);
#endif
			}
			break;
		case ECT_Near:// 附近/当前
			{
				const int TIME_GAP = 5;
				int leftTime = GetSysTime() - pUser->GetExtData32(46);
				if(leftTime > TIME_GAP)
					leftTime = 0;
				else
					leftTime = TIME_GAP - leftTime;
				if(leftTime == 0)
				{
					/*if(pUser->GetLevel() < 5)
					{
						msg.ReWrite();
						msg.SetType(PRO_MSG_CHAT);
						msg<<(uint8)8<<chanel<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1079,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						return;
					}*/
//					if(chatMsg.size() > 40)
//					{
//						msg.ReWrite();
//						msg.SetType(PRO_MSG_CHAT);
//						msg<<(uint8)8<<chanel<<PRO_ERROR<<MakeStringColor("字数不能超过40个字符!",TIPS_FAILURE_COLOR);
//						m_socketServer.SendMsg(pUser->GetSock(),msg);
//						return;
//					}
					CScene *pScene = pUser->GetScene();
					if(pScene == NULL)
						return;
					pUser->SetExtData32(46,GetSysTime());
					pScene->SceneChat(msg,pUser->GetRoleId());

					SaveChatLog(pUser,chanel,chatMsg.c_str());
				}
				else
				{
					char buf[128];
					snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1080,leftTime);

					msg.ReWrite();
					msg.SetType(PRO_MSG_CHAT);
					msg<<(uint8)8<<chanel<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
				}
				break;
			}
		case ECT_Team://队伍
			{
				CScene *pScene = pUser->GetScene();
				if(pScene == NULL)
					return;
				int teamId = pUser->GetTeam();
				if(teamId == 0)
					teamId = pUser->TempLeaveTeam();
				if(teamId != 0)
				{
					pScene->TeamChat(teamId,msg,pUser->GetRoleId());

					SaveChatLog(pUser,chanel,chatMsg.c_str());
				}
				else
				{
					msg.ReWrite();
					msg.SetType(PRO_MSG_CHAT);
					msg<<(uint8)8<<chanel<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1081,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
				}
				break;
			}
		case ECT_BangPai:// 帮派 服务器向同一帮派中的玩家广播
			{
				if(pUser->GetBangPai() == 0)
				{
					msg.ReWrite();
					msg.SetType(PRO_MSG_CHAT);
					msg<<(uint8)8<<chanel<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1082,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					break;
				}
				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(pUser->GetBangPai());
				if(pBangPai == NULL)
					break;
				list<uint32> userList;
				pBangPai->GetMember(userList);
				for(list<uint32>::iterator i = userList.begin(); i != userList.end(); i++)
				{
					ShareUserPtr ptr = m_onlineUser.GetUserByRoleId(*i);
					if((ptr.get() != NULL) && ((ptr->GetChatChannel() & (1<<3)) == (1<<3)))
					{
						if(SingletonCFriendMgr::instance().IsInBlackList(ptr->GetRoleId(), pUser->GetRoleId()))
							continue;
						if(ptr->GetBangPai() != pUser->GetBangPai())
							pBangPai->DelMember(*i);
						else
							m_socketServer.SendMsg(ptr->GetSock(),msg);
					}
				}

				SaveChatLog(pUser,chanel,chatMsg.c_str());
				break;
			}
/*		case 5:
			{
				if(chatMsg.size() > 20)
				{
					msg.ReWrite();
					msg.SetType(PRO_MSG_CHAT);
					msg<<(uint8)8<<chanel<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1083,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				uint32 fightId = pUser->GetFightId();
				if(fightId != 0)
				{
					ShareFightPtr ptr = SingletonFightManager::instance().FindFight(fightId);
					if(ptr.get() != NULL)
					{
						ptr->BroadcastMsg(msg);
					}

					msg.ReWrite();
					msg.SetType(PRO_MSG_CHAT);
					msg<<(uint8)8<<chanel<<PRO_SUCCESS;
					m_socketServer.SendMsg(pUser->GetSock(),msg);
				}
				else
				{
					CScene *pScene = pUser->GetScene();
					if(pScene == NULL)
						return;
					msg.ReWrite();
					msg.SetType(PRO_MSG_CHAT);
					msg<<(uint8)3<<pUser->GetRoleId()<<pUser->GetName()<<pUser->GetVipLevel()<<chatMsg;
					if(pUser->GetTeam() != 0)
						pScene->TeamChat(pUser->GetTeam(),msg,pUser->GetRoleId());
				}
				break;
			}*/
		case ECT_Private:	// 私聊
			{
				//// CHECK_SYSTEM_OPEN(SOT_SocialChat)

				/*if(pUser->GetLevel() < 5)
				{
					msg.ReWrite();
					msg.SetType(PRO_MSG_CHAT);
					msg<<(uint8)8<<chanel<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1084,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}*/

				msg.ReWrite();
				msg.SetType(PRO_MSG_CHAT);

				if((type == 2 && roleName.size() == 0) ||(privateChatRoleId == 0 && type == 1))
					return;
				if(type == 2)	// name
				{
					uint8 level = 0;
					privateChatRoleId = GetRoleId(roleName.c_str(),level);

					if(privateChatRoleId == 0)
					{
						msg<<(uint8)8<<chanel<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1085,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						return;
					}
				}

				if(SingletonCFriendMgr::instance().IsInBlackList(pUser->GetRoleId(), privateChatRoleId))
				{
					msg<<(uint8)8<<chanel<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1086,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				ShareUserPtr ptr = m_onlineUser.GetUserByRoleId(privateChatRoleId);
				CUser *pU = ptr.get();
				if(pU == NULL)
				{
					msg<<(uint8)8<<chanel<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1087,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
				}
				else
				{
					if(SingletonCFriendMgr::instance().IsInBlackList(pU->GetRoleId(), pUser->GetRoleId()))
					{
						msg<<(uint8)8<<chanel<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1088,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						return;
					}
					uint32 teamId = pUser->GetTeam();
					if(teamId == 0)
						teamId = pUser->TempLeaveTeam();
					msg<<(uint8)7<<pUser->GetRoleId()<<selfName<<vipLv<<pUser->GetHead()<<pUser->GetSex()<<pUser->GetLevel()<<teamId<<pUser->GetBangPai();
					msg<<pU->GetRoleId()<<(uint32)GetSysTime()<<chatMsg;
					m_socketServer.SendMsg(pU->GetSock(),msg);
					m_socketServer.SendMsg(pUser->GetSock(),msg);

					SaveChatLog(pUser,chanel,chatMsg.c_str());
				}
			}
			break;
		case 9:
			{


			}
			break;
		case ECT_KuaFu:	// 跨服聊天
			{
#ifndef KUA_FU
				if(!IsOpenKuaFu())
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0518,TIPS_FAILURE_COLOR).c_str());
					return;
				}
#endif

				int CD = 20;
				int curTime = GetSysTime();
				int leftTime = curTime - pUser->GetExtData32(293);
				if(leftTime >= CD)
				{
					pUser->SetExtData32(293,GetSysTime());
					m_onlineUser.ForEachUser(boost::bind(&CPackageDeal::BroadcastChat,this,_1,&msg,pUser->GetRoleId()));
					KFChatMsgToAllServer(msg);

					SaveChatLog(pUser,chanel,chatMsg.c_str());
				}
				else
				{
					char buf[256];
					snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0517,CD - leftTime);

					msg.ReWrite();
					msg.SetType(PRO_MSG_CHAT);
					msg<<(uint8)8<<chanel<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
				}
			}
			break;
		default:
			break;
	}
}

void CPackageDeal::FuQi(CNetMessage *pMsg,int sock)
{
	GET_MSG
		GET_USER

		uint32 roleId = pUser->GetData32(6);
	if(roleId == 0)
	{
		msg<<(uint8)0;
		m_socketServer.SendMsg(pUser->GetSock(),msg);
		return;
	}
	else
	{
		msg<<(uint8)1;
		ShareUserPtr ptr = m_onlineUser.GetUserByRoleId(roleId);
		CUser *pUser = ptr.get();
		if(pUser == NULL)
		{
			CGetDbConnect getDb;
			CDatabaseSql *pDb = getDb.GetDbConnect();
			char sql[128];
			snprintf(sql,sizeof(sql),"select name,sex from role_info where id=%d",roleId);
			if ((pDb != NULL) && (pDb->Query(sql)))
			{
				char **row = pDb->GetRow();
				if(row == NULL)
				{
					return;
				}
				msg<<(uint8)atoi(row[1])<<roleId<<row[0]<<(uint16)0;
			}
		}
		else
		{
			msg<<pUser->GetSex()<<roleId<<pUser->GetName()<<pUser->GetSceneId();
		}
	}
	m_socketServer.SendMsg(pUser->GetSock(),msg);
}

void CPackageDeal::FriendOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

//	// CHECK_SYSTEM_OPEN(SOT_SocialChat)

	CFriendMgr &friendMgr = SingletonCFriendMgr::instance();
	uint32 selfId = pUser->GetRoleId();
	uint8 op = 0;
	msg>>op;

	switch(op)
	{
	case 1:	// 获取好友列表
	{
		friendMgr.GetFriendList(msg, selfId);
		break;
	}
	case 2:	// 获取好友申请列表
	{
		friendMgr.GetAddApplyList(msg, selfId);
		break;
	}
	case 3:	// 申请添加好友
	{
		uint32 roleId = 0;
		msg>>roleId;
		friendMgr.ApplyAddFriend(msg, selfId, roleId);
		break;
	}
	case 4:	// 接受或拒绝添加好友请求
	{
		uint32 roleId = 0;
		uint8 accept = 0;	// 0拒绝 1接受
		msg>>roleId>>accept;
		bool isAccept = (accept == 0) ? false : true;
		friendMgr.DealFriendAddApply(msg, selfId, roleId, isAccept);
		break;
	}
	case 5:	// 赠送礼物
	{
		CHECK_SYSTEM_OPEN(SOT_SocialChat)
		uint32 roleId = 0;
		msg>>roleId;
		friendMgr.SendGift(pUser, msg, selfId, roleId);
		break;
	}
	case 6:	// 一键赠送礼物
	{
		CHECK_SYSTEM_OPEN(SOT_12)
		friendMgr.SendAllFriendGift(pUser, msg, selfId);
		break;
	}
	case 7:	// 领取礼物
	{
		CHECK_SYSTEM_OPEN(SOT_12)
		uint32 roleId = 0;
		msg>>roleId;
		friendMgr.GetGift(msg, pUser, roleId);
		break;
	}
	case 8:	// 一键领取礼物
	{
		CHECK_SYSTEM_OPEN(SOT_12)
		friendMgr.GetAllRecvGift(msg, pUser);
		break;
	}
	case 9:	// 获取礼物列表
	{
		friendMgr.GetGiftList(msg, pUser);
		break;
	}
	case 10:	// 删除好友
	{
		uint32 roleId = 0;
		msg>>roleId;
		friendMgr.DeleteFriend(msg, selfId, roleId);
		break;
	}
	case 11:	// 一键接受/拒绝好友申请
	{
		uint8 accept = 0;	// 0拒绝 1接受
		msg>>accept;
		bool isAccept = (accept == 0) ? false : true;
		friendMgr.DealAllApply(msg, selfId, isAccept);
	}
	case 12:	// 获取黑名单列表
	{
		friendMgr.GetBlackList(msg, selfId);
		break;
	}
	case 13:	// 添加黑名单
	{
		uint32 roleId = 0;
		msg>>roleId;
		friendMgr.AddToBlackList(msg, selfId, roleId);
		break;
	}
	case 14:	// 删除黑名单
	{
		uint32 roleId = 0;
		msg>>roleId;
		friendMgr.DeleteBlackList(msg, selfId, roleId);
		break;
	}
	case 15:	// 获取推荐好友列表
	{
		friendMgr.GetPushFriendList(msg, selfId, pUser->GetLevel());
		break;
	}
	case 16:	// 查找玩家
	{
		string name;
		msg>>name;

		if(IllegalStr(name))
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0579, TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock, msg);
			return;
		}

		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		if(pDb == NULL)
			return;
		char sql[256];
		snprintf(sql, sizeof(sql), "select id from role_info where name='%s'", name.c_str());
		if(!pDb->Query(sql))
		{
			cout<<"CPackageDeal::FriendOption op=16, query error sql="<<sql<<endl;
			return;
		}
		char **row = pDb->GetRow();
		if(row == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0579, TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock, msg);
			return;
		}
		SingletonCSimpleRoleDataMgr::instance().MakeRoleDetails(msg, atoi(row[0]));
		break;
	}
	case 17:	// 查找玩家简单信息
	{
		string name;
		msg>>name;

		if(IllegalStr(name))
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0579, TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock, msg);
			return;
		}

		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		if(pDb == NULL)
			return;
		char sql[256];
		snprintf(sql, sizeof(sql), "select id from role_info where name='%s'", name.c_str());
		if(!pDb->Query(sql))
		{
			cout<<"CPackageDeal::FriendOption op=17, query error sql="<<sql<<endl;
			return;
		}
		char **row = pDb->GetRow();
		if(row == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0579, TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock, msg);
			return;
		}
		uint32 roleId = atoi(row[0]);
		SRoleSimpleData data;
		if(!SingletonCSimpleRoleDataMgr::instance().GetRoleData(roleId, data))
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0579, TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock, msg);
			return;
		}

		uint32 curTime = GetSysTime();
		uint32 offLineTime = (data.lastLoginTime == 0) ? 0 : (curTime < data.lastLoginTime ? 0 : (curTime - data.lastLoginTime));
		msg<<PRO_SUCCESS<<data.roleId<<data.name<<data.level<<data.sex<<data.head<<data.power<<offLineTime<<data.bangpaiId<<data.bpName;
		break;
	}

	case 31:	// 添加好友成功数据同步（服务器推送）
		return;
	default:
		return;
	}
	m_socketServer.SendMsg(sock, msg);
}

void CPackageDeal::ChongZhiOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 op = 0;
	msg>>op;
	if(op == 1)		// 获取充值返利信息
	{
		bool isIOS = IsIOSAD(pUser->GetAd());
		uint32 data = pUser->GetExtData32(207);
		uint16 pos = msg.GetDataLen();
		uint8 num = 0;
		msg<<num;

		{
			boost::recursive_mutex::scoped_lock lk(cz_fanli_mutex);
			if(isIOS)
			{
				for(int i=0;i < (int)G_CZ_INFO_IOS.size();i++)
				{
					msg<< (uint8)G_CZ_INFO_IOS[i].type << (uint8)G_CZ_INFO_IOS[i].show_idx << (uint8)G_CZ_INFO_A[i].pic_idx << GetYB_ByMoney(G_CZ_INFO_IOS[i].dang);
					if(i == 0)
						msg<<G_CZ_INFO_IOS[i].fanLi<<(uint8)0<<G_CZ_INFO_IOS[i].itemId<<G_CZ_INFO_IOS[i].itemNum;
					else
					{
						if(G_CZ_INFO_IOS[i].type == 6 || G_CZ_INFO_IOS[i].type == 7 || (data & (1<<i)) != 0)	// 已首充,不显示双倍标识 月卡没有双倍
							msg<<G_CZ_INFO_IOS[i].fanLi<<(uint8)0<<G_CZ_INFO_IOS[i].itemId<<G_CZ_INFO_IOS[i].itemNum;
						else	// 未首充,显示双倍标识
							msg<<G_CZ_INFO_IOS[i].firstFanLi<<(uint8)1<<G_CZ_INFO_IOS[i].firstItemId<<G_CZ_INFO_IOS[i].firstItemNum;
					}
					num++;
				}
			}
			else
			{
				for(int i=0;i < (int)G_CZ_INFO_A.size();i++)
				{
					msg<< (uint8)G_CZ_INFO_A[i].type << (uint8)G_CZ_INFO_A[i].show_idx << (uint8)G_CZ_INFO_A[i].pic_idx << GetYB_ByMoney(G_CZ_INFO_A[i].dang);

					//if (i == 0)
					//	msg << G_CZ_INFO_A[i].fanLi << (uint8)0 << G_CZ_INFO_A[i].itemId << G_CZ_INFO_A[i].itemNum;
					//else
					{
						if(G_CZ_INFO_A[i].type == 6 || G_CZ_INFO_A[i].type == 7 || (data & (1<<i)) != 0)	// 已首充,不显示双倍标识 月卡没有双倍
							msg<<G_CZ_INFO_A[i].fanLi<<(uint8)0<<G_CZ_INFO_A[i].itemId<<G_CZ_INFO_A[i].itemNum;
						else	// 未首充,显示双倍标识
							msg<<G_CZ_INFO_A[i].firstFanLi<<(uint8)1<<G_CZ_INFO_A[i].firstItemId<<G_CZ_INFO_A[i].firstItemNum;
					}
					num++;
				}
			}
		}
		msg.WriteData(pos,&num,sizeof(num));
		m_socketServer.SendMsg(sock,msg);
	}
}

void CPackageDeal::UseSpecialItem(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 op = 0;
	msg >> op;
	CParaMgr& mgr = sCParaMgr;
	if(op == 1)		// 改角色名,2503
	{
		string name;
		msg>>name;

		do
		{
#ifdef KUA_FU
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0014,TIPS_FAILURE_COLOR);
			break;
#endif
			if(name == pUser->GetName())
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1098,TIPS_FAILURE_COLOR);
				break;
			}
			int nameLen = GetCharacterNum(name);
			if((nameLen < 1) || (nameLen > 6) || IllegalStr(name) || IsIllegalMsg(name.c_str()))
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1099,TIPS_FAILURE_COLOR);
				break;
			}

			CGetDbConnect getDb;
			CDatabaseSql *pDb = getDb.GetDbConnect();
			if(pDb == NULL)
				return;
			if(pUser->SubMaterial(mgr.m_gaiMing.type, mgr.m_gaiMing.num))
			{
				ItemCurrencyLog(pUser->GetRoleId(), MUT_GaiMing, 1, mgr.m_gaiMing.type, mgr.m_gaiMing.num, pUser->GetMaterial(mgr.m_gaiMing.type), MUT_GaiMing);
				char sql[128];
				int roleId = pUser->GetRoleId();
				snprintf(sql,sizeof(sql)-1,"update role_info set name='%s' where id=%d",name.c_str(),roleId);
				if(pDb->Query(sql))
				{
					pUser->SetName(name.c_str());
					msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_TRANSFORM_1101,TIPS_WARNING_COLOR);
//					SingletonCRankDataMgr::instance().SetRoleName(roleId,name.c_str());
//					SingletonShopManager::instance().SetRoleName(roleId,name.c_str());

					SingletonCSimpleRoleDataMgr::instance().UpdateRoleData(pUser);

					int bangpai = pUser->GetBangPai();
					if(bangpai > 0)
					{
						CBangPaiManager &bpManager = SingletonCBangPaiManager::instance();
						CBangPai *pBangPai = bpManager.FindBangPai(bangpai);
						if(pBangPai != NULL)
							pBangPai->UpdateMemberName(roleId,name);
					}
				}
				else
				{
					pUser->AddMaterial(mgr.m_gaiMing.type, mgr.m_gaiMing.num, false, false);
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1102,TIPS_FAILURE_COLOR);
				}
			}
			else
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2123,TIPS_FAILURE_COLOR);
		}while(0);
		m_socketServer.SendMsg(sock,msg);
	}
	else if(op == 2)	// 改帮派名,2504
	{
		string name;
		msg>>name;

		do
		{
#ifdef KUA_FU
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0014,TIPS_FAILURE_COLOR);
			break;
#endif
			int roleId = pUser->GetRoleId();
			int bangpai = pUser->GetBangPai();
			if(bangpai == 0)
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1104,TIPS_FAILURE_COLOR);
				break;
			}
			CBangPai *pBangPai = SingletonCBangPaiManager::instance().FindBangPai(bangpai);
			if(pBangPai == NULL)
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1111,TIPS_FAILURE_COLOR);
				break;
			}
			if(pBangPai->GetMemberRank(roleId) != EBRBangZhu)
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1110,TIPS_FAILURE_COLOR);
				break;
			}
			if(name == pBangPai->GetName())
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1109,TIPS_FAILURE_COLOR);
				break;
			}
			int nameLen = GetCharacterNum(name);
			if((nameLen < 1) || (nameLen > 6) || IllegalStr(name) || IsIllegalMsg(name.c_str()))
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1105,TIPS_FAILURE_COLOR);
				break;
			}

			CGetDbConnect getDb;
			CDatabaseSql *pDb = getDb.GetDbConnect();
			if(pDb == NULL)
				return;
			if(!pUser->SubMaterial(mgr.m_bangGaiMing.type, mgr.m_bangGaiMing.num))
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2123,TIPS_FAILURE_COLOR);
				break;
			}
			ItemCurrencyLog(pUser->GetRoleId(), MUT_BGaiMing, 1, mgr.m_bangGaiMing.type, mgr.m_bangGaiMing.num, pUser->GetMaterial(mgr.m_bangGaiMing.type), MUT_BGaiMing);

			char sql[128];
			snprintf(sql,sizeof(sql)-1,"update bang_pai set name='%s' where id=%u",name.c_str(),pBangPai->GetId());
			if(pDb->Query(sql))
			{
				pBangPai->SetName(name.c_str());
				pUser->SetBangPaiName(name);
				msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_TRANSFORM_1107,TIPS_WARNING_COLOR);
				pBangPai->UpdateBangName2Member();
				SingletonCSimpleRoleDataMgr::instance().UpdateRoleData(pUser);
			}
			else
			{
				pUser->AddMaterial(mgr.m_bangGaiMing.type, mgr.m_bangGaiMing.num, false, false);
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1108,TIPS_FAILURE_COLOR);
			}
		}while(0);
		m_socketServer.SendMsg(sock,msg);
	}
//	else if(itemId == 2571)	// 改性别卡,2571
//	{
//		if(pUser->GetItemNum(itemId) > 0)
//		{
//#ifdef KUA_FU
//			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0015,TIPS_FAILURE_COLOR);
//			m_socketServer.SendMsg(sock,msg);
//			return;
//#endif
//			
//			uint8 sex = ((pUser->GetSex() == 0) ? 1 : 0);
//			pUser->SetSex(sex);
//			pUser->DelPackageById(itemId,1);
//			int roleId = pUser->GetRoleId();
//			SaveUseItem(roleId,itemId,LANGUAGE_TRANSFORM_1114,1);
//
//			SingletonCSimpleRoleDataMgr::instance().UpdateRoleData(pUser);
//			msg<<PRO_SUCCESS<<sex<<MakeStringColor(LANGUAGE_TRANSFORM_1115,TIPS_WARNING_COLOR);
//		}
//		else
//		{
//			char buf[128];
//			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1116,GetItemName(itemId));
//			msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
//		}
//		m_socketServer.SendMsg(sock,msg);
//	}
//	else if (itemId == 2815)
//	{
//#ifndef KUA_FU
//		if(!IsOpenKuaFu())
//		{
//			SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0518,TIPS_FAILURE_COLOR).c_str());
//			return;
//		}
//#endif
//		string result;
//		bool isSuccess;
//		if(pUser->GetItemNum(itemId) > 0)
//		{
//			string message;
//			msg>>message;
//
//			if(message.size() <= 0)
//			{
//				isSuccess = false;
//				result = LANGUAGE_LLD_0021;
//			}
//			else
//			{
//				isSuccess = true;
//				result = LANGUAGE_LLD_0022;
//
//				pUser->DelPackageById(itemId,1);
//				SysInfoToAllUserGunDong(pUser,message.c_str());
//				
//				SaveChatLog(pUser,ECT_KuaFuBroadCast,message.c_str());
//			}
//		}
//		else
//		{
//			isSuccess = false;
//			result = LANGUAGE_LLD_0020;
//		}
//
//		msg.ReWrite();
//		msg.SetType(PRO_USE_ITEM);
//		msg << itemId;
//		if (isSuccess)
//			msg << PRO_SUCCESS << MakeStringColor(result,TIPS_WARNING_COLOR);
//		else
//			msg << PRO_ERROR<<MakeStringColor(result,TIPS_WARNING_COLOR);
//
//		m_socketServer.SendMsg(sock,msg);
//	}
}

void CPackageDeal::ZhenFaOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 op = 0;
	msg>>op;
	if(op == 0)
		return;

	if(op == 1)	// 获取已有阵法信息
	{
		// CHECK_SYSTEM_OPEN(SOT_Zhenfa)
		if (pUser->MakeZhenFaMsg(msg))
		{
			m_socketServer.SendMsg(sock,msg);
		}
	}
	else if(op == 2)	// 学习阵法或升级阵法
	{
		// CHECK_SYSTEM_OPEN(SOT_Zhenfa)
		uint16 zhenfaId = 0;
		msg>>zhenfaId;
		if(pUser->ZhenFaLevelUp(zhenfaId,msg))
		{
			m_socketServer.SendMsg(sock,msg);
		}
	}
	else if(op == 3)	// 切换阵法
	{
		// CHECK_SYSTEM_OPEN(SOT_Zhenfa)
		uint16 zhenfaId = 0;
		msg>>zhenfaId;
		if(pUser->SwitchZhenFa(zhenfaId,msg))
		{
			m_socketServer.SendMsg(sock,msg);
		}
	}
	else if(op == 4)	// 单人 神将上阵，或替换
	{
		uint16 petId = 0;
		uint8 pos = 0;	// 阵法位置
		msg>>petId>> pos;
		CHECK_SYSTEM_OPEN(SOT_1030 + pos)
		pUser->ZhenFa_SetPetState(petId, pos);
	}
	else if(op == 5)	// 单人 阵法两单位互换位置
	{
		// CHECK_SYSTEM_OPEN(SOT_Zhenfa)
		uint8 srcPos = 0;
		uint8 tarPos = 0;
		msg>>srcPos>>tarPos;
		pUser->ZhenFa_ChangeUnitPos(srcPos,tarPos);
	}
	else if(op == 11)	// 组队 切换阵法
	{
		// CHECK_SYSTEM_OPEN(SOT_Zhenfa)
		uint16 zhenfaId = 0;
		msg>>zhenfaId;
		CScene *pScene = pUser->GetScene();
		if(pScene == NULL)
			return;
		if(pScene->SwitchTeamZhenFa(pUser,zhenfaId,msg))
		{
			m_socketServer.SendMsg(sock,msg);
		}
	}
	else if(op == 12)	// 组队 神将上阵，下阵
	{
		uint16 petId = 0;
		uint8 state = 0;	// 1上阵 2下阵
		msg>>petId>>state;
		CScene *pScene = pUser->GetScene();
		if(pScene == NULL)
			return;
		if(pScene->TeamZhenFa_SetPetState(pUser,petId,state,msg))
		{
			m_socketServer.SendMsg(sock,msg);
		}
	}
	else if(op == 13)	// 组队 阵法两单位互换位置
	{
		// CHECK_SYSTEM_OPEN(SOT_Zhenfa)
		uint8 srcPos = 0;
		uint8 tarPos = 0;
		msg>>srcPos>>tarPos;
		CScene *pScene = pUser->GetScene();
		if(pScene == NULL)
			return;
		if(pScene->TeamZhenFa_ChangeUnitPos(pUser,srcPos,tarPos,msg))
		{
			m_socketServer.SendMsg(sock,msg);
		}
	}

}

void CPackageDeal::QueryFinishedCMissions(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	vector<int> missList;
	pUser->m_missList.GetCMissionsFinishedList(missList);
	uint32 num = missList.size();
	msg<<num;
	for(uint32 i=0;i < num;i++)
	{
		msg<<missList[i];
	}
	m_socketServer.SendMsg(sock,msg);
}

void CPackageDeal::QueryUserPetInfo(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint32 roleId = 0;
	uint16 petId = 0;
	msg>>roleId>>petId;
	if(roleId == 0 || petId == 0)
		return;
	ShareUserPtr user = m_onlineUser.GetUserByRoleId(roleId);
	CUser *pU = user.get();
	if(pU == NULL)
	{
		pU = new CUser;
		if(pU == NULL)
			return;
		pU->SetSock(-1);
		if (!pU->CopyUserData(roleId))
		{
			delete pU;
			return;
		}
		user.reset(pU);
	}

	msg.ReWrite();
	msg.SetType(PRO_QUERY_PET_INFO);
	msg<<roleId;
	pU->MakePetById(petId,msg);
	m_socketServer.SendMsg(sock,msg);
}

void CPackageDeal::FindResourceOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 op = 0;
	msg>>op;
	if(op == 1)	// 获得找回资源列表
	{
		pUser->ShowFindResourceMsg(msg);
		m_socketServer.SendMsg(sock,msg);
	}
	else if(op == 2)	// 找回对应的玩法资源
	{
		uint32 funcId = 0;
		uint16 findNum = 0;
		msg>>funcId>>findNum;
		if(funcId == 0 || findNum == 0)
			return;
		if(pUser->BuyFindResource(msg, funcId, findNum))
		{
			m_socketServer.SendMsg(sock,msg);
		}
	}
/*	else if(op == 3)	// 一键找回
	{
		uint8 findType = 0;
		msg>>findType;
		if(findType == 0 || findType > 2)
			return;
		if(pUser->BuyAllFindResource(msg,findType))
		{
			m_socketServer.SendMsg(sock,msg);
		}
	}
*/
}

void CPackageDeal::ClientShopReturnCall(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER
	uint8 type = 0;
	msg>>type;
	if(type == 0)
		return;
	else
		DoItem(pUser,(int)type);
}

void CPackageDeal::GetUserDetail(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint32 roleId = 0;
	uint8 type = 0;
	msg>>roleId>>type;

	CSimpleRoleDataMgr &simpleMgr = SingletonCSimpleRoleDataMgr::instance();
	simpleMgr.MakeRoleDetails(msg, roleId, type);
	m_socketServer.SendMsg(sock, msg);
}

static int GetUserName(uint32 id,string &name,uint16 *pLevel = NULL,uint32 *zhandouli=NULL,uint8 *head=NULL,uint8 *sex=NULL)
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return 0;

	char sql[128];
	snprintf(sql,sizeof(sql),"select name,level,save_data,zhanDouLi,head,sex from role_info where id=%u",id);
	if(!pDb->Query(sql))
		return 0;
	char **row =pDb->GetRow();
	int bangGong = 0;
	if(row != NULL)
	{
		name = row[0];
		if(pLevel != NULL)
			*pLevel = atoi(row[1]);
		CUser *pUser = new CUser;
		pUser->ReadSaveData(row[2]);
		bangGong = pUser->GetData32(5);
		if(zhandouli != NULL)
			*zhandouli = atoi(row[3]);
		if(head != NULL)
			*head = atoi(row[4]);
		if(sex != NULL)
			*sex = atoi(row[5]);
		delete pUser;
	}
	return bangGong;
}

// flag: true add,false del
static void UpdateBangPai(uint32 userId,CBangPai *pBangPai,bool flag,CUser *pUser=NULL)
{
	if(pBangPai == NULL)
		return;

	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;

	char sql[128];
	snprintf(sql,sizeof(sql),"select bangpai_id from bang_pai_role where role_id = %u ",userId);
	if(!pDb->Query(sql))
		return;
	char **row =pDb->GetRow();
	if(row != NULL && flag)
	{
		SingletonCBangPaiManager::instance().DelAskJoin(userId);
		return;
	}

	if(flag && row == NULL)
	{
		char buf[4096];
		snprintf(buf,sizeof(buf),"select save_data from role_info where id=%u",userId);
		if(!pDb->Query(buf))
			return;
		char **row = pDb->GetRow();
		if(row == NULL)
			return;
		CUser *p = new CUser;
		p->ReadSaveData(row[0]);
		if(p->GetData32(2) + CBangPai::JOIN_TIME_LIMIT > (uint32)GetSysTime())
		{
			delete p;
			if(pUser != NULL)
			{
				snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_1129, CBangPai::JOIN_TIME_LIMIT/3600);
				SendSysInfo(pUser,MakeStringColor(buf,TIPS_FAILURE_COLOR).c_str());
				pBangPai->DelAskForJoin(userId);
			}
			return;
		}
		delete p;
		if(!pBangPai->AddMemberLocked(userId,EBRBangZhong))
			return;
		SingletonCBangPaiManager::instance().DelAskJoin(userId);
	}
	else if(!flag && row != NULL)
	{
		char buf[4096];
		snprintf(buf,sizeof(buf),"select save_data,bank_item from role_info where id=%u",userId);
		if(!pDb->Query(buf))
			return;
		char **row = pDb->GetRow();
		if(row == NULL)
			return;

		CUser *p = new CUser;
		p->ReadSaveData(row[0]);
		p->SetBankItem(row[1]);
		p->SetData32(2,0);
		string str;
		string bank;
		p->WriteSaveData(str);
		p->GetBankItem(bank);
		snprintf(buf,sizeof(buf),"update role_info set save_data='%s',bank_item='%s',bangpai=0 where id=%u",str.c_str(),bank.c_str(),userId);
		pDb->Query(buf);
		delete p;
	}
}

void CPackageDeal::YaoLingOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 op = 1;	// 1升级妖灵
	msg>>op;
	
	const int YB[YAO_LING_MAX_LV] = {600,600,1200,1700,2400,3000,4000,5000,6000,7000};
	if(op == 1)		// 升级妖灵
	{
		//if(pUser->GetLevel() < YAO_LING_LEVEL_LIMIT)
		/*{
			char buf[128];
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1130,YAO_LING_LEVEL_LIMIT);
			msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}*/
		
		uint8 ylLv = pUser->GetYaoLingLevel();
		if(ylLv >= YAO_LING_MAX_LV)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1131,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		if(pUser->GetTongBao() < YB[ylLv])
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1132,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		pUser->AddTongBao(-YB[ylLv]);

		ylLv++;
		pUser->SetYaoLingLevel(ylLv);
		pUser->InitAndUpdate();
//		pUser->InitChuZhanPet();
		
		msg<<PRO_SUCCESS<<ylLv;
		if(ylLv >= YAO_LING_MAX_LV)
			msg<<(uint16)0;
		else
			msg<<(uint16)YB[ylLv];
		msg<<pUser->GetYaoLingZhanDouLi();
		m_socketServer.SendMsg(sock,msg);
		ItemCurrencyLog(pUser->GetRoleId(),0,0,0,YB[ylLv],pUser->GetTongBao(),YBL_YAO_LING);
	}
	else if(op == 2)	// 获取升级消耗元宝
	{
		uint8 ylLv = pUser->GetYaoLingLevel();
		if(ylLv >= YAO_LING_MAX_LV)
			msg<<(uint16)0<<pUser->GetYaoLingZhanDouLi();
		else
			msg<<(uint16)YB[ylLv]<<pUser->GetYaoLingZhanDouLi();
		m_socketServer.SendMsg(sock,msg);
	}
}

void CPackageDeal::BangPaiZhongZhi(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER
	// CHECK_SYSTEM_OPEN(SOT_Bangpai)

	uint8 op = 0;
	msg>>op;

	int srcSceneId = 0;
	CScene *pScene = pUser->GetScene();
	if(pScene != NULL)
		srcSceneId = pScene->GetSrcSceneId();
	if(srcSceneId != BANG_PAI_SCENE_ID)
		return;
	if((pScene->GetId() & 0xff) != srcSceneId){
		cout<<"pScene->GetId() & 0xff) != srcSceneId"<<endl;
		return;
	}
	uint32 bangpaiId = pScene->GetId() >> 8;
	CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(bangpaiId);
	if(pBangPai == NULL){
		return;
	}

	switch(op)
	{
		case 1:	// 获取帮派种植
			{
				pBangPai->MakeZZMsg(pUser,msg);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			break;
		case 2:	// 获取种植详细信息
			{
				uint8 plantedIdx = 0;
				uint8 cellPos = 0xff;
				uint32 queryBangPaiId = 0;
				msg>>queryBangPaiId>>plantedIdx>>cellPos;
				if(queryBangPaiId != bangpaiId)
					return;
				pBangPai->GetPlantMsgByPosition(pUser,plantedIdx,cellPos,msg);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			break;
		case 3:	// 种植
			{
				uint32 queryBangPaiId = 0;
				uint16 itemId = 0;
				uint8 plantIdx = 0xff;
				uint8 cellPos = 0xff;
				msg>>queryBangPaiId>>itemId>>plantIdx>>cellPos;
				if(queryBangPaiId != bangpaiId)
					return;
				pBangPai->PlantResource(pUser,itemId,plantIdx,cellPos);
				pUser->SendBangPaiPlantCnt();
			}
			break;
		case 4:	// 浇水
			{
				uint32 queryBangPaiId = 0;
				uint8 plantIdx = 0xff;
				uint8 cellPos = 0xff;
				msg>>queryBangPaiId>>plantIdx>>cellPos;
				if(queryBangPaiId != bangpaiId)
					return;
				pBangPai->WateringPlant(pUser,plantIdx,cellPos);
			}
			break;
		case 5:	// 除虫
			{
				uint32 queryBangPaiId = 0;
				uint8 plantIdx = 0xff;
				uint8 cellPos = 0xff;
				msg>>queryBangPaiId>>plantIdx>>cellPos;
				if(queryBangPaiId != bangpaiId)
					return;
				pBangPai->KillPlantBug(pUser,plantIdx,cellPos);
			}
			break;
		case 6:	// 铲除
			{
				uint32 queryBangPaiId = 0;
				uint8 plantIdx = 0xff;
				uint8 cellPos = 0xff;
				msg>>queryBangPaiId>>plantIdx>>cellPos;
				if(queryBangPaiId != bangpaiId)
					return;
				pBangPai->ClearUpPlant(pUser,plantIdx,cellPos);
			}
			break;
		case 7:	// 收获
			{
				uint32 queryBangPaiId = 0;
				uint8 plantIdx = 0xff;
				uint8 cellPos = 0xff;
				msg>>queryBangPaiId>>plantIdx>>cellPos;
				if(queryBangPaiId != bangpaiId)
					return;
				pBangPai->GainPlant(pUser,plantIdx,cellPos);
			}
			break;
		case 8:	// 偷取
			{
				uint32 queryBangPaiId = 0;
				uint8 plantIdx = 0xff;
				uint8 cellPos = 0xff;
				msg>>queryBangPaiId>>plantIdx>>cellPos;
				if(queryBangPaiId != bangpaiId)
					return;
				pBangPai->StealPlant(pUser,plantIdx,cellPos);
			}
			break;
		case 9:	// 设置守卫
			{
				uint32 queryBangPaiId = 0;
				uint8 guardIdx = 0xff;
				msg>>queryBangPaiId>>guardIdx;
				if(queryBangPaiId != bangpaiId)
					return;
				pBangPai->SetGuard(pUser,guardIdx);
			}
			break;
		case 10: // 解除守卫
			{
				uint32 queryBangPaiId = 0;
				uint8 guardIdx = 0xff;
				msg>>queryBangPaiId>>guardIdx;
				if(queryBangPaiId != bangpaiId)
					return;
				pBangPai->RemoveGuard(pUser,guardIdx);
			}
			break;
		case 11: // 更新种植数据,服务器主动推送
			{
			}
			break;
		case 12: // 新增植物信息,服务器主动推送
			{
			}
			break;
		case 13: // 请求帮派护卫信息
			{
				uint32 queryBangPaiId = 0;
				uint8 guardIdx = 0xff;
				uint8 type = 1;	// 1简单信息2详细信息
				msg>>queryBangPaiId>>guardIdx>>type;
				if(queryBangPaiId != bangpaiId)
					return;
				pBangPai->QueryGuardMsg(pUser,guardIdx,type);
			}
			break;
		case 14: // 请求魔火状态
			{
				uint32 queryBangPaiId = 0;
				msg>>queryBangPaiId;
				if(queryBangPaiId != bangpaiId)
					return;
				msg.ReWrite();
				msg.SetType(MSG_BANGPAI_ZHONGZHI);
				msg<<op<<queryBangPaiId<<pBangPai->GetFireState();
				m_socketServer.SendMsg(sock,msg);
			}
			break;
		case 15: // 点燃魔火
			{
				uint32 queryBangPaiId = 0;
				msg>>queryBangPaiId;
				if(queryBangPaiId != bangpaiId)
					return;
				pBangPai->LightFire(pUser);
			}
			break;
		case 16: // 熄灭魔火
			{
				uint32 queryBangPaiId = 0;
				msg>>queryBangPaiId;
				if(queryBangPaiId != bangpaiId)
					return;
				pBangPai->ExtinguishFire(pUser);
			}
			break;
		case 17: // 更新魔火状态,服务器主动推送
			{
			}
			break;
		case 18: // 请求神树信息
			{
				uint32 queryBangPaiId = 0;
				msg>>queryBangPaiId;
				if(queryBangPaiId != bangpaiId)
					return;
				pBangPai->SendTreeMsg(pUser);
			}
			break;
		case 19: // 神树祈福
			{
				uint32 queryBangPaiId = 0;
				uint8 type = 1;	// 1普通2元宝祈福
				msg>>queryBangPaiId>>type;
				if(queryBangPaiId != bangpaiId)
					return;
				pBangPai->TreePray(pUser,type);
			}
			break;
		case 20: // 请求是否可掠夺状态
			{
				uint32 queryBangPaiId = 0;
				msg>>queryBangPaiId;
				if(queryBangPaiId != bangpaiId)
					return;
				pBangPai->QueryTreeRobState(pUser);
			}
			break;
		case 21: // 神树掠夺
			{
				uint32 queryBangPaiId = 0;
				msg>>queryBangPaiId;
				if(queryBangPaiId != bangpaiId)
					return;
				pBangPai->RobTree(pUser);
			}
			break;
		case 22: // 更新守卫信息，服务器主动推送
			{
			}
			break;
		case 23: // 请求帮派任务列表信息
			{
//				pBangPai->GetTaskList(pUser);
			}
			break;
		case 24: // 领取帮派任务奖励
			{
//				uint8 taskType = 0;
//				msg>>taskType;
//				pBangPai->GetTaskReward(pUser,taskType);
			}
			break;
		case 25: // 更新帮派任务进度, 服务器主动推送
			{
			}
			break;
		case 26:	// 获取仙尊阁信息
			{
				if(pUser->GetBangPai() != bangpaiId)
					return;
				
				int nYingXiangLi = 0;
				int nMoney = 0;
				int nRatio = 0;
				int lv = pBangPai->GetXianZhunGeLv();
				int nextLv = lv + 1;
				uint8 showLvUpButton = 0;	// 0不显示 1显示
				GetZhunXianGeLvUpInfo(lv+1,nYingXiangLi,nMoney,nRatio);
				if(nextLv > CBangPai::MAX_XIAN_ZHUN_GE_LV)
					nextLv = CBangPai::MAX_XIAN_ZHUN_GE_LV;
				if(pBangPai->IsAdmin(pUser->GetRoleId()) && lv < CBangPai::MAX_XIAN_ZHUN_GE_LV)
					showLvUpButton = 1;
				msg<<PRO_SUCCESS<<lv<<pBangPai->GetMoney()<<pBangPai->GetYingXiangLi()<<pBangPai->GetSupportRatioByLv()<<nextLv
					<<nYingXiangLi<<nMoney<<showLvUpButton;
				m_bangPaiMgr.MakeHaveShangXianList(bangpaiId,msg);
				SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			}
			break;
		case 27:	// 升级仙尊阁
			{
				if(pUser->GetBangPai() != bangpaiId)
					return;
				if(!(pBangPai->IsAdmin(pUser->GetRoleId())))
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0289,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}
				int lv = pBangPai->GetXianZhunGeLv();
				if(lv >= CBangPai::MAX_XIAN_ZHUN_GE_LV)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0290,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}

				char buf[256];
				char tmp[256];
				int nYingxiangli = 0;
				int nMoney = 0;
				int nRatio = 0;
				GetZhunXianGeLvUpInfo(lv+1,nYingxiangli,nMoney,nRatio);
				if(nMoney == 0)
					return;
				if(pBangPai->GetYingXiangLi() < nYingxiangli)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0291,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}
				if(pBangPai->GetMoney() < nMoney)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0292,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}
				lv++;
				pBangPai->SetYingXiangLi(pBangPai->GetYingXiangLi()-nYingxiangli);
				pBangPai->SetMoney(pBangPai->GetMoney()-nMoney);
				pBangPai->SetXianZhunGeLv(lv);
				snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0362,pUser->GetName(),pBangPai->GetXianZhunGeLv());
				snprintf(tmp,sizeof(tmp),LANGUAGE_SSJ_0354,nYingxiangli,nMoney);
				msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_SSJ_0293,TIPS_WARNING_COLOR);

				int nextLv = lv + 1;
				uint8 showLvUpButton = 0;	// 0不显示 1显示
				GetZhunXianGeLvUpInfo(nextLv,nYingxiangli,nMoney,nRatio);
				if(nextLv > CBangPai::MAX_XIAN_ZHUN_GE_LV)
					nextLv = CBangPai::MAX_XIAN_ZHUN_GE_LV;
				if(pBangPai->IsAdmin(pUser->GetRoleId()) && lv < CBangPai::MAX_XIAN_ZHUN_GE_LV)
					showLvUpButton = 1;
				msg<<lv<<pBangPai->GetMoney()<<pBangPai->GetYingXiangLi()<<pBangPai->GetSupportRatioByLv()<<nextLv
					<<nYingxiangli<<nMoney<<showLvUpButton;
				m_socketServer.SendMsg(sock,msg);

				pBangPai->SaveLog(pUser->GetRoleId(),0,EBLT_LV_UP_ZXG,buf,tmp);
				pBangPai->SendMailToAllMember(buf);
			}
			break;
		case 28:	// 获取上仙列表
			{
				if(pUser->GetBangPai() != bangpaiId)
					return;
				m_bangPaiMgr.MakeShangXianInfo(msg,pUser->GetBangPai(),pUser->GetRoleId());
				m_socketServer.SendMsg(sock,msg);
			}
			break;
		case 29:	// 兑换礼包
			{
				if(pUser->GetBangPai() != bangpaiId)
					return;
				uint16 sxId = 0;
				msg>>sxId;
				if(sxId == 0)
					return;
				uint32 state = pUser->GetExtData32(438);
				if((state & (1 << (sxId-1))) > 0)	// 已兑换
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0296,TIPS_FAILURE_COLOR);
				else
					m_bangPaiMgr.DuiHuanShangXianGift(pUser,msg,sxId);
				m_socketServer.SendMsg(sock,msg);
			}
			break;
		case 30:	// 设定/取消拉拢目标
			{
				if(pUser->GetBangPai() != bangpaiId)
					return;
				if(!pBangPai->IsAdmin(pUser->GetRoleId()))
					return;
				
				uint16 sxId = 0;
				uint8 state = 0;	// 1设定拉拢 0未设置拉拢
				msg>>sxId>>state;
				if(sxId == 0 || state > 1)
					return;
				m_bangPaiMgr.SetShangXianLaLongState(pUser,msg,sxId,state);
				m_socketServer.SendMsg(sock,msg);
			}
			break;
		case 31:	// 获取友好、拉拢、离间、彻查信息
			{
				if(pUser->GetBangPai() != bangpaiId)
					return;

				uint8 type = 0;	// 1友好2拉拢3离间4彻查验生石5彻查堕仙印
				uint16 sxId = 0;
				msg>>type>>sxId;
				if(type == 0 || type > 5)
					return;
				m_bangPaiMgr.GetShangXianModeInfo(pUser,msg,type,sxId);
				m_socketServer.SendMsg(sock,msg);
			}
			break;
		case 32:	// 友好、拉拢、离间
			{
				if(pUser->GetBangPai() != bangpaiId)
					return;

				uint16 sxId = 0;
				uint16 modeId = 0;
				msg>>sxId>>modeId;
				if(sxId == 0 || modeId == 0)
					return;
				m_bangPaiMgr.ShangXianOption(pUser,msg,modeId,sxId);
				m_socketServer.SendMsg(sock,msg);
			}
			break;
		case 33:	// 解除
			{
				if(pUser->GetBangPai() != bangpaiId)
					return;
				
				uint16 sxId = 0;
				msg>>sxId;
				if(sxId == 0)
					return;
				m_bangPaiMgr.ShangXianJieChu(pUser,msg,sxId);
				m_socketServer.SendMsg(sock,msg);
			}
			break;
		case 34:	// 获取帮派任务列表
			{
				if(pUser->GetBangPai() != bangpaiId)
					return;
				
				CNetMessage oms;
				oms.SetType(MSG_BANGPAI_ZHONGZHI);
				oms<<(uint8)34;
				pBangPai->ShowTaskList(pUser, oms);
				m_socketServer.SendMsg(sock, oms);
			}
			break;
		case 35:	// 获取可发布任务列表
			{
				if(pUser->GetBangPai() != bangpaiId)
					return;
				pBangPai->GetPublishTaskList(pUser,msg);
				m_socketServer.SendMsg(sock,msg);
			}
			break;
		case 36:	// 发布任务
			{
				if(pUser->GetBangPai() != bangpaiId)
					return;
				int missionId = 0;
				msg>>missionId;
				pBangPai->PublishTask(pUser,msg,missionId);
				m_socketServer.SendMsg(sock,msg);
			}
			break;
		case 37:	// 领取奖励
			{
				if(pUser->GetBangPai() != bangpaiId)
					return;
				int missionId = 0;
				msg>>missionId;
				pBangPai->TakeTaskAward(pUser,msg,missionId);
				m_socketServer.SendMsg(sock,msg);
			}
			break;
		case 38:	// 获取捐献信息
			{
				if(pUser->GetBangPai() != bangpaiId)
					return;

				pBangPai->GetJuanXianInfo(pUser,msg);
				m_socketServer.SendMsg(sock,msg);
			}
			break;
		case 39:	// 捐献金币
			{
				if(pUser->GetBangPai() != bangpaiId)
					return;
				
				uint8 type = 0;	// 1 10万 2 100万 3 500万
				msg>>type;
				if(type == 0)
					return;
				pBangPai->JuanXian(pUser,msg,type);
				m_socketServer.SendMsg(sock,msg);
			}
			break;
		case 40:	// 获取彻查帮派列表
			{
				if(pUser->GetBangPai() != bangpaiId)
					return;
				
				m_bangPaiMgr.MakeCheckBangPaiList(pUser,msg);
				m_socketServer.SendMsg(sock,msg);
			}
			break;
		case 41:	// 显示仙尊阁面板
			{
				// 服务器主动推送
			}
			break;
		case 42:	// 彻查
			{
				if(pUser->GetBangPai() != bangpaiId)
					return;
				
				uint32 tarBP_id = 0;
				uint16 modeId = 0;
				msg>>modeId>>tarBP_id;
				if(tarBP_id == 0)
					return;
				m_bangPaiMgr.ShangXianOption(pUser,msg,modeId,0,tarBP_id);
				m_socketServer.SendMsg(sock,msg);
			}
			break;
		case 43:	// 设置彻查目标
			{
				if(pUser->GetBangPai() != bangpaiId)
					return;
				
				uint8 type = 0;	// 1设置目标2取消目标
				uint32 tarBP_id = 0;
				msg>>type>>tarBP_id;
				if(type == 0)
					return;
				pBangPai->SetChectBangPaiTarget(pUser,msg,type,tarBP_id);
				m_socketServer.SendMsg(sock,msg);
			}
			break;
		case 44:	// 亲密度排行
			{
				uint16 sxId = 0;
				msg>>sxId;
				if(sxId == 0)
					return;
				m_bangPaiMgr.GetBPQinMiPaiHang(msg,sxId);
				m_socketServer.SendMsg(sock,msg);
			}
			break;
		case 45:	// 获取操作记录(内务信息)
			{
				if(pUser->GetBangPai() != bangpaiId)
					return;
				
				uint8 type = 0;	// 1捐献信息2上仙互动3其他信息
				msg>>type;
				if(type == 0)
					return;
				pBangPai->GetOptionLog(msg,type);
				m_socketServer.SendMsg(sock,msg);
			}
			break;
		case 46:	// 获取捐献金币排行榜
			{
				pBangPai->MakeJuanXianPaiHang(msg);
				m_socketServer.SendMsg(sock,msg);
			}
			break;
		default:
			break;
	}
}

void CPackageDeal::BangZhanOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 op = 0;
	msg>>op;

	switch(op)
	{
		case 1:	// 获取帮战列表信息
#ifdef KUA_FU
		case 11:// 跨服帮战预赛
		case 17:// 跨服帮战决赛
#endif
			{
				string bpLvStr = LANGUAGE_TRANSFORM_1133;
				string bpMemNumStr = LANGUAGE_TRANSFORM_1134;
				string roleLvStr = LANGUAGE_TRANSFORM_1135;
				string enterTimeStr = LANGUAGE_TRANSFORM_1136;
				string timeDesc = LANGUAGE_SSJ_0001;//LANGUAGE_TRANSFORM_1137;
				string desc = LANGUAGE_TRANSFORM_1138;
				int wday = GetWeekDay();
#ifdef KUA_FU
				int type = GetKuaFuBangZhanType();				
				if(op == 11)
				{
					bpLvStr = LANGUAGE_SSJ_0083;
					bpMemNumStr = LANGUAGE_SSJ_0084;
					roleLvStr = LANGUAGE_SSJ_0085;
					enterTimeStr = LANGUAGE_SSJ_0086;
				}
				else if(op == 17)
				{
					bpLvStr = LANGUAGE_SSJ_0089;
					bpMemNumStr = "";
					roleLvStr = LANGUAGE_SSJ_0090;
					enterTimeStr = LANGUAGE_SSJ_0091;
				}
#endif
				uint8 bpLvflag = 0;
				uint8 bpMemNumflag = 0;
				uint8 roleLvflag = 0;
				uint8 enterTimeflag = 0;
				uint8 startFlag = 0;
				if(op == 1)
				{
					if(pUser->GetBangPai() > 0)
					{
						CBangPai *p = m_bangPaiMgr.FindBangPai(pUser->GetBangPai());
						if(p != NULL)
						{
							if(p->GetLevel() >= CBangPaiManager::BP_FIGHT_LIMIT_LV)
								bpLvflag = 1;
							if(p->GetMemberNum() >= CBangPaiManager::BP_FIGHT_LIMIT_MEM_NUM)
								bpMemNumflag = 1;
						}
						if((int)GetSysTime() - GetEnterBangPaiTime(pUser) >= CBangPaiManager::BP_FIGHT_LIMIT_ENTER_TIME)
							enterTimeflag = 1;
					}
					//if(pUser->GetLevel() >= CBangPaiManager::BP_FIGHT_ROLE_LIMIT_LV)
						roleLvflag = 1;
				}
#ifdef KUA_FU
				else if(op == 11)	// 跨服帮战预赛
				{
					if(pUser->GetBangPai() > 0)
					{
						CBangPai *p = m_bangPaiMgr.FindBangPai(pUser->GetBangPai());
						if(p != NULL)
						{
							if(wday <= 2)
							{
								if(m_bangPaiMgr.IsInBangPaiFightList(p->GetId()))	// 条件1
								{
									bpLvflag = 1;
									bpMemNumflag = 1;
								}
							}
							else
							{
								if(m_bangPaiMgr.IsInBangPaiFightListOld(p->GetId()))
								{
									bpLvflag = 1;
									bpMemNumflag = 1;
								}
							}
						}
						if((int)GetSysTime() - GetEnterBangPaiTime(pUser) >= CBangPaiManager::BP_FIGHT_LIMIT_ENTER_TIME)
							enterTimeflag = 1;
					}
					//if(pUser->GetLevel() >= CBangPaiManager::KF_BP_FIGHT_ROLE_LIMIT_LV)
						roleLvflag = 1;
				}
				else if(op == 17)	// 跨服帮战决赛
				{
					if(pUser->GetBangPai() > 0)
					{
						CBangPai *p = m_bangPaiMgr.FindBangPai(pUser->GetBangPai());
						if(p != NULL)
						{
							if(wday >= 3)
							{
								if(m_bangPaiMgr.IsInBangPaiFightList(p->GetId()))	// 条件1
								{
									bpLvflag = 1;
									bpMemNumflag = 1;
								}
							}
						}
						if((int)GetSysTime() - GetEnterBangPaiTime(pUser) >= CBangPaiManager::BP_FIGHT_LIMIT_ENTER_TIME)
							enterTimeflag = 1;
					}
					//if(pUser->GetLevel() >= CBangPaiManager::KF_BP_FIGHT_ROLE_LIMIT_LV)
						roleLvflag = 1;
				}
#endif
				
				int hour = GetHour();
				int minute = GetMinute();
				int time = hour*100 + minute;
				if(op == 1)
				{
					if((wday == 3 || wday == 6) && (time >= BP_FIGHT_READY_START && time < BP_FIGHT_BOX_END))
						startFlag= 1;
				}
#ifdef KUA_FU
				else if(op == 11)
				{
					if(type == 1 && (time >= BP_FIGHT_READY_START && time < BP_FIGHT_BOX_END))
						startFlag= 1;
				}
				else if(op == 17)
				{
					if(type == 2 && (time >= BP_FIGHT_READY_START && time < BP_FIGHT_BOX_END))
						startFlag= 1;
				}
#endif

				msg<<bpLvflag<<bpLvStr;
				msg <<bpMemNumflag<<bpMemNumStr;
				msg<<roleLvflag<<roleLvStr;
				msg<<enterTimeflag<<enterTimeStr;
				msg<<startFlag<<timeDesc<<desc;
#ifdef KUA_FU
				if(wday <= 2)
				{
					if(op == 11)
						m_bangPaiMgr.MakeBangFightMsg(msg);
					else if(op == 17)
						msg<<(uint16)0;
				}
				else
				{
					if(op == 11)
						m_bangPaiMgr.MakeBangFightOldMsg(msg);
					else if(op == 17)
						m_bangPaiMgr.MakeBangFightMsg(msg);
				}
#else
				m_bangPaiMgr.MakeBangFightMsg(msg);
#endif
				m_socketServer.SendMsg(sock,msg);
			}
			break;
		case 2:	// 帮战准备场景请求界面信息
		case 12:
			{
				int hour = GetHour();
				int second = GetSysTime()%60;
				int minute = GetMinute();
				if(op == 2)
				{
					if(pUser->GetSrcSceneId() != BP_FIGHT_READY_SID)
						return;
				}
				else if(op == 12)
				{
					if(pUser->GetSrcSceneId() != KUAFU_BZ_READY_SID)
						return;
				}
				int time = hour*100 + minute;
				if(time >= BP_FIGHT_READY_START && time < BP_FIGHT_READY_END)	// 活动内
					msg<<GetNewTimeSecond(time*100+second,BP_FIGHT_READY_END*100);
				else
					msg<<0;
				m_socketServer.SendMsg(sock,msg);
			}
			break;
		//case 3:	// 帮战场景请求界面信息
		//case 13:
		//	{
		//		if(op == 3)
		//		{
		//			if(pUser->GetSrcSceneId() != BP_FIGHT_SID)
		//				return;
		//		}
		//		else if(op == 13)
		//		{
		//			if(pUser->GetSrcSceneId() != KUAFU_BZ_SID)
		//				return;
		//		}
		//		msg<<pUser->GetExtData16(7);	// 剩余行动力
		//		m_socketServer.SendMsg(sock,msg);
		//	}
		//	break;
		case 4:	// 帮战场景请求积分排行榜
		case 14:
			{
				if(op == 4)
				{
					if(pUser->GetSrcSceneId() != BP_FIGHT_SID)
						return;
				}
				else if(op == 14)
				{
					if(pUser->GetSrcSceneId() != KUAFU_BZ_SID)
						return;
				}
				if(pUser->GetBangPai() == 0)
				{
					int teamId = pUser->GetTeam();
					if(teamId == 0)
						teamId = pUser->TempLeaveTeam();
					if(teamId == 0)
					{
						if(op == 4)
							TransportUser(pUser,BP_FIGHT_EXIT_SID,BP_FIGHT_EXIT_X,BP_FIGHT_EXIT_Y,1);
						else
							TransportUser(pUser,KUAFU_EXIT_SID,KUAFU_EXIT_X,KUAFU_EXIT_Y,1);
					}
					else
					{
						CScene *pScene = pUser->GetScene();
						if(pScene != NULL)
							pScene->LeaveSceneTeam(teamId,pUser);
						if(op == 4)
							TransportUser(pUser,BP_FIGHT_EXIT_SID,BP_FIGHT_EXIT_X,BP_FIGHT_EXIT_Y,1);
						else
							TransportUser(pUser,KUAFU_EXIT_SID,KUAFU_EXIT_X,KUAFU_EXIT_Y,1);
					}
					return;
				}
				m_bangPaiMgr.MakeBangZhanPaiHang(pUser,msg);
			}
			break;
		case 5:	// 开始战斗
		case 15:
			{
				//const int XING_DONG_LI = 6;
				uint32 roleId = 0;	// 被挑战的角色id
				msg>>roleId;
				if(roleId == 0 || pUser->GetRoleId() == roleId)
					return;
				int teamId = pUser->GetTeam();
				if(teamId > 0 && teamId != (int)pUser->GetRoleId())
					return;
				if(pUser->GetKuaFuState() != EKFS_IN_LOCAL)
					return;
				if(pUser->GetFightId() > 0)
					return;
				ShareUserPtr p = m_onlineUser.GetUserByRoleId(roleId);
				CUser *pU = p.get();
				if(pU != NULL)
				{
					if (pUser->GetBangPai() == pU->GetBangPai())
						return;

					CScene *pScene = pUser->GetScene();
					if(pScene == NULL || pScene != pU->GetScene())
						return;
					int tarTeamId = pU->GetTeam();
					if(tarTeamId > 0 && tarTeamId != (int)roleId)
						return;
					if(tarTeamId > 0 && tarTeamId == teamId)
						return;
					if(pU->GetKuaFuState() != EKFS_IN_LOCAL)
						return;

					if (pU->GetFightId() > 0)
					{
						msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_1139, TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(sock, msg);
						return;
					}

					uint16 x, y;
					pUser->GetPos(x, y);
					if (CheckSafeAreaPos(x, y))
					{
						msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0127, TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(sock, msg);
						return;
					}
					pU->GetPos(x, y);
					if (CheckSafeAreaPos(x, y))
					{
						msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0126, TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(sock, msg);
						return;
					}
					ClearCollectState(pU);
					ClearCollectState(pUser);
					msg << PRO_SUCCESS << "";
					m_socketServer.SendMsg(sock, msg);

					ShareFightPtr pFight = SingletonFightManager::instance().CreateFight();
					if (pFight.get() == NULL)
						return;
					pFight->SetFightType(CFight::EFTBangZhan);
					pFight->SetFightChooseMode();
					pFight->AddUserGroupToFight(p);
					pFight->AddUserGroupToFight(ptr, CFight::EGT_GROUP2);
					pFight->BeginFight(pScene);
					SingletonFightManager::instance().AddFight(pFight);

					//pScene->DecBZXingDongLi(pUser,XING_DONG_LI);
				}
				else
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1140,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
				}
			}
			break;
		case 6:	// 进入准备场景
			{
				if(pUser->GetTeam() > 0 && pUser->GetTeam() != pUser->GetRoleId())
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1141,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}
				if(pUser->GetBangPai() == 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1142,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}
				if(!IsOpenBangPaiFight())
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1143,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}
				
				int wday = GetWeekDay();
				int hour = GetHour();
				int minute = GetMinute();
				int time = hour*100 + minute;
				if((wday == 3 || wday == 6) && (time >= BP_FIGHT_READY_START && time <= BP_FIGHT_BOX_END))
				{
					if(!CanEnterBangPaiFightScene(pUser))
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1146,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(sock,msg);
						return;
					}

					vector<ShareUserPtr> pMember;
					GetTeamMemberList(pUser,pMember);
					int roleNum = pMember.size();
					if(roleNum == 0)
						return;
					char buf[256];
					for(int i=0; i < roleNum;i++)
					{
						if(pMember[i].get() != NULL)
						{
							if(pMember[i]->GetLevel() < CBangPaiManager::BP_FIGHT_ROLE_LIMIT_LV)
							{
								if(pMember[i]->GetRoleId() == pUser->GetRoleId())
									snprintf(buf,sizeof(buf)-1,LANGUAGE_TRANSFORM_1144);
								else
									snprintf(buf,sizeof(buf)-1,LANGUAGE_TRANSFORM_1147,pMember[i]->GetName());
								msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
								m_socketServer.SendMsg(sock,msg);
								return;
							}
							if((int)GetSysTime() - GetEnterBangPaiTime(pMember[i].get()) < CBangPaiManager::BP_FIGHT_LIMIT_ENTER_TIME)
							{
								if(pMember[i]->GetRoleId() == pUser->GetRoleId())
									snprintf(buf,sizeof(buf)-1,LANGUAGE_TRANSFORM_1145);
								else
									snprintf(buf,sizeof(buf)-1,LANGUAGE_TRANSFORM_1148,pMember[i]->GetName());
								msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
								m_socketServer.SendMsg(sock,msg);
								return;
							}
						}
					}
					
					msg<<PRO_SUCCESS;
					EnterBPFightReadyScene(pUser);
				}
				else
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1151,TIPS_FAILURE_COLOR);
				}
				m_socketServer.SendMsg(sock,msg);
			}
			break;
		case 16:	// 进入跨服帮战准备场景
		case 18:
			{
#ifdef KUA_FU
				if(pUser->GetTeam() > 0 && pUser->GetTeam() != pUser->GetRoleId())
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1141,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}
				if(pUser->GetBangPai() == 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1142,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}
				if(!IsOpenBangPaiFight())
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1143,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}
				
//				int wday = GetWeekDay();
				int hour = GetHour();
				int minute = GetMinute();
				int time = hour*100 + minute;
				int type = GetKuaFuBangZhanType();
				if(((type == 1 && op == 16) || (type == 2 && op == 18)) && (time >= BP_FIGHT_READY_START && time <= BP_FIGHT_BOX_END))
				{
					if(!CanEnterBangPaiFightScene(pUser))
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1146,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(sock,msg);
						return;
					}
					
					vector<ShareUserPtr> pMember;
					GetTeamMemberList(pUser,pMember);
					int roleNum = pMember.size();
					if(roleNum == 0)
						return;
					
					char buf[256];
					for(int i=0; i < roleNum;i++)
					{
						if(pMember[i].get() != NULL)
						{
							if(pMember[i]->GetLevel() < CBangPaiManager::KF_BP_FIGHT_ROLE_LIMIT_LV)
							{
								if(pMember[i]->GetRoleId() == pUser->GetRoleId())
									snprintf(buf,sizeof(buf)-1,LANGUAGE_TRANSFORM_1144);
								else
									snprintf(buf,sizeof(buf)-1,LANGUAGE_TRANSFORM_1147,pMember[i]->GetName());
								msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
								m_socketServer.SendMsg(sock,msg);
								return;
							}
							if((int)GetSysTime() - GetEnterBangPaiTime(pMember[i].get()) < CBangPaiManager::BP_FIGHT_LIMIT_ENTER_TIME)
							{
								if(pMember[i]->GetRoleId() == pUser->GetRoleId())
									snprintf(buf,sizeof(buf)-1,LANGUAGE_TRANSFORM_1145);
								else
									snprintf(buf,sizeof(buf)-1,LANGUAGE_TRANSFORM_1148,pMember[i]->GetName());
								msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
								m_socketServer.SendMsg(sock,msg);
								return;
							}
						}
					}
					
					msg<<PRO_SUCCESS;
					EnterBPFightReadyScene(pUser);
				}
				else
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1151,TIPS_FAILURE_COLOR);
				}
				m_socketServer.SendMsg(sock,msg);
#endif
			}
			break;

		case 7:
			{
				if (!CSceneManager::IsAfterActivityTime(SOT_BangPaiZhan))
					return;
				int hour = GetHour();
				int minute = GetMinute();
				int sec = GetSecond();
				int curTime = hour * 100 + minute;
				uint16 notifyTm;
				uint16 startTm;
				uint16 endTm;

				if (!sSystemOpenCfgMananger.OpenWeekDay(SOT_BangPaiZhan))
					return;
				if (!sSystemOpenCfgMananger.GetFuncLvTime(SOT_BangPaiZhan, notifyTm, startTm, endTm))
					return;

				int boxStart = endTm + 1;
				if (curTime >= boxStart + 2)
					return;
				int lessTime = boxStart + 2 - curTime;
				if (curTime < boxStart)
					lessTime -= 2;

				msg << (uint16)(lessTime * 60 - sec);
				m_socketServer.SendMsg(sock, msg);
			}
			break;
		case 8:
		{
			uint16 notifyTm;
			uint16 startTm;
			uint16 endTm;

			if (!sSystemOpenCfgMananger.OpenWeekDay(SOT_BangPaiZhan))
				return;
			if (!sSystemOpenCfgMananger.GetFuncLvTime(SOT_BangPaiZhan, notifyTm, startTm, endTm))
				return;

			CSceneManager &scene = SingletonSceneManager::instance();
			CScene *pFightScene = scene.FindScene(BP_FIGHT_SID);
			if (pFightScene == NULL)
				return;
			pFightScene->MakeTowerMsg(pUser, msg);
			m_socketServer.SendMsg(sock, msg);
		}
		case 10: // 取消占塔
		{
			CSceneManager &scene = SingletonSceneManager::instance();
			CScene *pFightScene = scene.FindScene(BP_FIGHT_SID);
			if (pFightScene == NULL)
				return;
			ClearCollectState(pUser);
		}
		case 19: // 占塔排行
		{
			CSceneManager &scene = SingletonSceneManager::instance();
			CScene *pFightScene = scene.FindScene(BP_FIGHT_SID);
			if (pFightScene == NULL)
				return;
			pFightScene->MakeHurtRankMsg(pUser, msg);
			m_socketServer.SendMsg(sock, msg);
		}
		default:
			return;
	}
}

void CPackageDeal::BangPai(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 op = 0;
	msg>>op;
//	// CHECK_SYSTEM_OPEN(SOT_Bangpai)

	switch(op)
	{
		case 0:	// 获得创建帮派面板信息
			{
				CreateBangPaiPanel(pUser);
			}
			break;
		case 1: //创建帮派
			{
#ifdef KUA_FU
				return;
#endif
				string name,gongGao;
				int pic = 0;
				uint16 limitLv = 0;
				msg>>name>>gongGao>>pic>>limitLv;
				msg.ReWrite();
				msg.SetType(PRO_BANGPAI);
				msg<<(uint8)1;
				if(pUser->GetBangPai() > 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1152,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock, msg);
					return;
				}
				if(pUser->GetData32(2) + CBangPai::JOIN_TIME_LIMIT > (uint32)GetSysTime())
				{
					char buf[128];
					snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_1154, (int)(CBangPai::JOIN_TIME_LIMIT/3600));
					msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock, msg);
					return;
				}

				int res = GetCharacterNum(name);
				if(res < 2)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1157,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock, msg);
					return;
				}
				else if(res > 6)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1158,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock, msg);
					return;
				}

				res = CreateBangPai(pUser, name.c_str(), gongGao.c_str(), pic, limitLv);
				if(res == 0)
				{
					msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_TRANSFORM_1159,TIPS_WARNING_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					SingletonCMissionManager::instance().VerifyNewBranchMissionFinish(pUser, EMISS_DC_18);
					pUser->AddBangpaiMission();
					pUser->UpdateBangHuoYue(EBHT_Login);
				}
				else if(res == 2)
				{
					msg<<PRO_ERROR<<"";
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					ShowJumpNotice(pUser,JUMP_NOTICE_YB);
					return;
				}
				else if(res == 4)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1160,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				else
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1161,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				sCMissionManager.UpdateQuestState(pUser, EMQCT_59);
//				CScene *pScene = pUser->GetScene();
//				if(pScene != NULL)
//					pScene->UpdateUserInfo(pUser,ESRT_BangPai);

				char buf[256];
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1162,ROLE_NAME_COLOR,pUser->GetName(),BANG_NAME_COLOR,name.c_str());
				SysInfoToAllUser(buf);
				break;
			}
		case 2://帮派列表
			{
				msg.ReWrite();
				msg.SetType(PRO_BANGPAI);
				msg<<(uint8)2;
				m_bangPaiMgr.MakeBangPaiList(msg,pUser->GetBangPai(),pUser->GetRoleId(),true);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				break;
			}
		case 3://申请加入帮派
			{
#ifdef KUA_FU
				return;
#endif
				uint32 bangpaiId = 0;
				msg>>bangpaiId;
				if(bangpaiId == 0)
					break;
				/*if(pUser->GetLevel() < JOIN_BANGPAI_LEVEL)
				{
					char buf[128];
					snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1163,(int)JOIN_BANGPAI_LEVEL);
					msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}*/
				if(pUser->GetBangPai() != 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1164,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				if(pUser->GetData32(2) + CBangPai::JOIN_TIME_LIMIT > (uint32)GetSysTime())
				{
					char buf[128];
					snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1165,(int)(CBangPai::JOIN_TIME_LIMIT/3600));
					msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(bangpaiId);
				if(pBangPai == NULL)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1166,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				uint16 limitLv = pBangPai->GetAutoAcceptLv();
				if (limitLv > 0)
				{
                    if (pUser->GetLevel() < limitLv)
                    {
                    	msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_CC_0003,TIPS_FAILURE_COLOR);
					    m_socketServer.SendMsg(pUser->GetSock(),msg);
                    	return;
                    }
					if(!pBangPai->AddMember(pUser,EBRBangZhong))
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1177,TIPS_FAILURE_COLOR);
						return;
					}
					msg<<PRO_SUCCESS;
					m_socketServer.SendMsg(pUser->GetSock(),msg);

					pUser->SetBangPai(pBangPai->GetId(),EBRBangZhong,pBangPai->GetName().c_str());
					pUser->UpdateBangPai();

                    char buf[128];
                    snprintf(buf, sizeof(buf), LANGUAGE_CC_0004, pBangPai->GetName().c_str());
                    SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
					

					CScene *pScene = pUser->GetScene();
					if(pScene != NULL)
						pScene->UpdateUserInfo(pUser,ESRT_BangPai);
					pUser->AfterJoinBangPai();
				}
				else
				{
					int res = pBangPai->AddAskJoin(pUser->GetRoleId());
					if(res == -1)
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1167,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						return;
					}
					else if(res == -2)
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1168,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						return;
					}
					else
					{
						msg<<PRO_SUCCESS;
						m_socketServer.SendMsg(pUser->GetSock(),msg);
					}

					ShareUserPtr p = m_onlineUser.GetUserByRoleId(pBangPai->GetBangZhu());
					CUser *pU = p.get();
					if(pU != NULL)
					{
						string str = pUser->GetName();
						str += LANGUAGE_TRANSFORM_1169;
						SendSysInfo(pU,MakeStringColor(str.c_str(),TIPS_WARNING_COLOR).c_str());
					}		
					pBangPai->CheckHotPoint(EHPoint_BP_JoinApply);
					//入帮任务
				    SingletonCMissionManager::instance().VerifyNewBranchMissionFinish(pUser, EMISS_DC_18);
				}               
				break;
			}
		case 4:// 向帮派中有帮众管理权限的玩家请求加入帮派
			{
#ifdef KUA_FU
				return;
#endif
				uint32 userId = 0;
				msg>>userId;
				ShareUserPtr p = m_onlineUser.GetUserByRoleId(userId);
				CUser *pU = p.get();
				msg.ReWrite();
				msg.SetType(PRO_BANGPAI);
				msg<<(uint8)4;
				if((pU == NULL) || (pU->GetBangPai() == 0))
				{
					msg<<PRO_ERROR;
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					break;
				}
				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(userId);
				if((pBangPai == NULL) || (!pBangPai->IsAdmin(userId)))
				{
					msg<<PRO_ERROR;
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					break;
				}
				if(pBangPai->GetMemberNum() >= pBangPai->GetMaxMemberNum())
				{
					msg<<PRO_ERROR;
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_1170,TIPS_FAILURE_COLOR).c_str());
					break;
				}
				msg<<PRO_SUCCESS;
				m_socketServer.SendMsg(pUser->GetSock(),msg);

				msg.ReWrite();
				msg.SetType(PRO_BANGPAI);
				msg<<(uint8)5;
				msg<<pUser->GetRoleId()<<pUser->GetName();
				m_socketServer.SendMsg(pU->GetSock(),msg);

				pBangPai->CheckHotPoint(EHPoint_BP_JoinApply);
				break;
			}
		case 6://帮派中有帮众管理权限的玩家发出邀请
			{
#ifdef KUA_FU
				return;
#endif
				uint8 op1 = 0;
				msg>>op1;
				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(pUser->GetBangPai());
				if(pBangPai == NULL)
					break;
				uint8 srcRank = pBangPai->GetMemberRank(pUser->GetRoleId());
				if(srcRank >= EBRHuFa)
				{
					msg.ReWrite();
					msg.SetType(PRO_BANGPAI);
					msg<<(uint8)6<<(uint8)1;
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1171,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					break;
				}
				if(!(pBangPai->IsAdmin(pUser->GetRoleId())))
					break;
				if(op1 == 1)		// 邀请单个玩家
				{
					uint32 userId;
					msg>>userId;

					ShareUserPtr p = m_onlineUser.GetUserByRoleId(userId);
					CUser *pU = p.get();

					msg.ReWrite();
					msg.SetType(PRO_BANGPAI);
					msg<<(uint8)6<<(uint8)1;
					if(pU == NULL)
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1172,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						break;
					}
					if(pU->GetBangPai() != 0)
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1173,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						break;
					}
					char buf[512];
					snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1174,(int)JOIN_BANGPAI_LEVEL);
					if (!sSystemOpenCfgMananger.CheckSystemOpen(pU, SOT_Bangpai))
					{
						msg << PRO_ERROR << MakeStringColor(buf, TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(), msg);
						break;
					}
					msg<<PRO_SUCCESS;
					m_socketServer.SendMsg(pUser->GetSock(),msg);

					msg.ReWrite();
					msg.SetType(PRO_BANGPAI);
					msg<<(uint8)26;
					msg<<pUser->GetRoleId()<<pUser->GetBangPai()<<pBangPai->GetName()<<pUser->GetName()<<pUser->GetHead()<<pUser->GetSex()<<pUser->GetLevel();
					m_socketServer.SendMsg(pU->GetSock(),msg);
				}
				else if(op1 == 2)	// 邀请多个玩家
				{
					uint8 num = 0;
					uint32 userId;
					msg>>num;
					vector<uint32> userList;
					for(uint8 i=0;i < num;i++)
					{
						msg>>userId;
						userList.push_back(userId);
					}

					for(uint8 i=0;i < num;i++)
					{
						ShareUserPtr p = m_onlineUser.GetUserByRoleId(userList[i]);
						CUser *pU = p.get();
						if(pU == NULL)
							continue;
						if(pU->GetBangPai() != 0 || !sSystemOpenCfgMananger.CheckSystemOpen(pU, SOT_Bangpai))
							continue;
						msg.ReWrite();
						msg.SetType(PRO_BANGPAI);
						msg<<(uint8)26;
						msg<<pUser->GetRoleId()<<pUser->GetBangPai()<<pBangPai->GetName()<<pUser->GetName()<<pUser->GetHead()<<pUser->GetSex()<<pUser->GetLevel();
						m_socketServer.SendMsg(pU->GetSock(),msg);
					}
					msg.ReWrite();
					msg.SetType(PRO_BANGPAI);
					msg<<(uint8)6<<(uint8)2<<PRO_SUCCESS;
					m_socketServer.SendMsg(pUser->GetSock(),msg);
				}
			}
			break;
		case 7:	// 接收入帮(邀请入帮)
			{
#ifdef KUA_FU
				return;
#endif
				uint32 userId;
				uint8 accept = 0;	// 0 拒绝 1 同意
				msg>>userId>>accept;
				msg.ReWrite();
				msg.SetType(PRO_BANGPAI);
				msg<<(uint8)7;

				ShareUserPtr p = m_onlineUser.GetUserByRoleId(userId);
				CUser* pJoin = p.get();
				if (pJoin == NULL)
				{
					msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0104, TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(), msg); return;
				}
				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(p->GetBangPai());
				if((pBangPai == NULL) || !(pBangPai->IsAdmin(userId)))
					break;
				if(accept == 0)
				{
					pBangPai->DelAskForJoin(userId);
					break;
				}

				/*if(pUser->GetLevel() < JOIN_BANGPAI_LEVEL)
				{
					char buf[128];
					snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1174,(int)JOIN_BANGPAI_LEVEL);
					msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}*/
				if(pJoin->GetData32(2) + CBangPai::JOIN_TIME_LIMIT > (uint32)GetSysTime())
				{
					char buf[128];
					snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1175,(int)(CBangPai::JOIN_TIME_LIMIT/3600));
					msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				if(pJoin->GetBangPai() == 0)
				{
					if(pBangPai->AddMember(pJoin,EBRBangZhong))
					{
						pJoin->SetBangPai(pBangPai->GetId(),EBRBangZhong,pBangPai->GetName().c_str());
						pJoin->UpdateBangPai();
						m_bangPaiMgr.DelAskJoin(userId);
						msg<<PRO_SUCCESS;
//						CScene *pScene = pJoin->GetScene();
//						if(pScene != NULL)
//							pScene->UpdateUserInfo(pJoin,ESRT_BangPai);
						pJoin->AfterJoinBangPai();
					}
					else
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1177,TIPS_FAILURE_COLOR);
					}
				}
				else
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1178,TIPS_FAILURE_COLOR);
				}
				m_socketServer.SendMsg(pUser->GetSock(),msg);

				pBangPai->CheckHotPoint(EHPoint_BP_JoinApply);
			}
			break;
		case 8://申请加入帮派列表
			{
#ifdef KUA_FU
				return;
#endif
				if(pUser->GetBangPai() != 0)
				{
					CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(pUser->GetBangPai());
					if(pBangPai == NULL)
						break;
					list<uint32> askJoin;
					pBangPai->GetAskForJoin(askJoin);
					list<uint32>::iterator i = askJoin.begin();
					msg<<(uint8)askJoin.size();
					for(; i != askJoin.end(); i++)
					{
						msg<<*i;
						ShareUserPtr p = m_onlineUser.GetUserByRoleId(*i);
						CUser *pU = p.get();
						if(pU != NULL)
						{
							msg<<pU->GetName()<<pU->GetLevel()<<(uint32)pU->GetZhanDouLi()<<pU->GetHead()<<pU->GetSex();
						}
						else
						{
							string name;
							uint32 zhandouli;
							uint16 level = 0;
							uint8 head = 1;
							uint8 sex = 0;
							GetUserName(*i,name,&level,&zhandouli,&head,&sex);
							msg<<name<<level<<zhandouli<<head<<sex;
						}
					}
					m_socketServer.SendMsg(sock, msg);
				}
				break;
			}
		case 9://批准加入帮派,单个
			{
#ifdef KUA_FU
				return;
#endif
				uint8 res = 0;
				msg>>res;	//0不同意，1同意
				if(res == 1)
				{
					uint32 userId = 0;
					char buf[128];
					msg>>userId;
					CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(pUser->GetBangPai());
					if((pBangPai == NULL) || !(pBangPai->IsAdmin(pUser->GetRoleId())))
						break;
					if(pBangPai->IsAskJoin(userId))
					{
						ShareUserPtr p = m_onlineUser.GetUserByRoleId(userId);
						CUser *pU = p.get();
						if(pU != NULL)
						{
							if(pU->GetBangPai() == 0)
							{
								if(pU->GetData32(2) + CBangPai::JOIN_TIME_LIMIT < (uint32)GetSysTime())
								{
									if(pBangPai->AddMember(pU,EBRBangZhong))
									{
										pU->SetBangPai(pBangPai->GetId(),EBRBangZhong,pBangPai->GetName().c_str());
										pU->UpdateBangPai();
										string str = pUser->GetName();
										str += LANGUAGE_TRANSFORM_1180;
										SendSysInfo(pU,MakeStringColor(str.c_str(),TIPS_WARNING_COLOR).c_str());

//										CScene *pScene = pU->GetScene();
//										if(pScene != NULL)
//											pScene->UpdateUserInfo(pU,ESRT_BangPai);
										pU->AfterJoinBangPai();
									}
									else
									{
										SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_1177,TIPS_FAILURE_COLOR).c_str());
									}
								}
								else
								{
									snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1181,(int)(CBangPai::JOIN_TIME_LIMIT/3600));
									SendSysInfo(pUser,MakeStringColor(buf,TIPS_FAILURE_COLOR).c_str());
								}
							}
							else
							{
								SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_1182,TIPS_FAILURE_COLOR).c_str());
							}
						}
						else
						{
							UpdateBangPai(userId,pBangPai,true,pUser);
						}
						m_bangPaiMgr.DelAskJoin(userId);
					}

					pBangPai->CheckHotPoint(EHPoint_BP_JoinApply);
				}
				else if(res == 0)
				{
					uint32 userId = 0;
					msg>>userId;
					CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(pUser->GetBangPai());
					if((pBangPai == NULL) || !(pBangPai->IsAdmin(pUser->GetRoleId())))
						break;
					if(pBangPai->IsAskJoin(userId))
					{
						ShareUserPtr p = m_onlineUser.GetUserByRoleId(userId);
						CUser *pU = p.get();
						if(pU != NULL)
						{
							string str = pUser->GetName();
							str += LANGUAGE_TRANSFORM_1183;
							SendSysInfo(pU,MakeStringColor(str.c_str(),TIPS_FAILURE_COLOR).c_str());
						}
						pBangPai->DelAskForJoin(userId);
					}

					pBangPai->CheckHotPoint(EHPoint_BP_JoinApply);
				}
				break;
			}
		case 10://帮派成员列表
			{
				if(pUser->GetBangPai() != 0)
				{
					CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(pUser->GetBangPai());
					if(pBangPai == NULL)
						break;
					list<uint32> member;
					pBangPai->GetMember(member);
					
					uint32 numPos = msg.GetDataLen();
					uint8 num = 0;
					msg<<num;
					for(list<uint32>::iterator i = member.begin(); i != member.end(); i++)
					{
						SBangPaiMember memberInfo;
						pBangPai->GetMemberInfoById(*i, memberInfo);

						SRoleSimpleData data;
						if(!SingletonCSimpleRoleDataMgr::instance().GetRoleData(*i, data))
							continue;
						msg<<*i<<data.name<<data.level<<memberInfo.rank<<data.head<<memberInfo.total_gongXian<<data.sex<<data.power<<data.vipLv;
						if(data.lastLoginTime > 0)
							msg<<(uint32)(GetSysTime() - data.lastLoginTime);
						else
							msg<<(uint32)0;
						msg<<memberInfo.huoyue_day; 
						num++;
					}
					msg.WriteData(numPos, &num, sizeof(num));
					m_socketServer.SendMsg(sock ,msg);
				}
				break;
			}
		case 11://逐出帮派
			{
#ifdef KUA_FU
				return;
#endif
				uint32 userId;
				char buf_t[128];
				msg>>userId;
				if(userId == pUser->GetRoleId())
					break;
				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(pUser->GetBangPai());
				if((pBangPai == NULL) || !(pBangPai->HaveRight2DelMember(pUser->GetRoleId(),userId)))
					break;

				ShareUserPtr p = m_onlineUser.GetUserByRoleId(userId);
				CUser *pU = p.get();
				if((pU != NULL) && (pU->GetBangPai() == pUser->GetBangPai()))
				{
					pU->SetBangPai(0);
					pU->SetData32(2,0); // 踢出帮派不加惩罚时间
					SendSysInfo(pU,MakeStringColor(LANGUAGE_TRANSFORM_1184,TIPS_FAILURE_COLOR).c_str());
					pU->UpdateBangPai();
					pUser->UpdateBangPai();

//					LeaveBangPaiTransport(pU);
//					CScene *pScene = pU->GetScene();
//					if(pScene != NULL)
//						pScene->UpdateUserInfo(pU,ESRT_BangPai);
				}
				else
				{
					UpdateBangPai(userId,pBangPai,false);
				}
//				pBangPai->RemoveGuardByRoleId(userId);
				msg<<PRO_SUCCESS;
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				snprintf(buf_t,sizeof(buf_t),LANGUAGE_TRANSFORM_1185,pBangPai->GetName().c_str(),pUser->GetName());
				pBangPai->DelMember(userId, pUser);
				SendSystemMail(userId,buf_t);
				break;
			}
		case 12://退出帮派
			{
#ifdef KUA_FU
				return;
#endif
				msg<<PRO_SUCCESS;
				m_socketServer.SendMsg(pUser->GetSock(),msg);

				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(pUser->GetBangPai());
				if(pBangPai == NULL)
					break;
				pBangPai->RemoveGuardByRoleId(pUser->GetRoleId());

				uint8 rank = pBangPai->GetMemberRank(pUser->GetRoleId());
				if(rank == EBRBangZhu)		// 帮主
				{
					if(pBangPai->GetMemberNum() == 1)	// 解散
					{
						pBangPai->DismissBang_updata();
					}
					else		// 传位
					{
						SBangPaiMember nextBangZhuInfo;
						if(!pBangPai->GetNextBangZhuData(nextBangZhuInfo))
							return;

						pBangPai->SetMemberRank(nextBangZhuInfo.roleId, EBRBangZhu);
						ShareUserPtr p = m_onlineUser.GetUserByRoleId(nextBangZhuInfo.roleId);
						CUser *pU = p.get();
						if(pU != NULL)
						{
							pU->UpdateBangPai();
						}
						pBangPai->DelMember(pUser->GetRoleId());

						pUser->SetBangPai(0);

						SRoleSimpleData data;
						if(!SingletonCSimpleRoleDataMgr::instance().GetRoleData(nextBangZhuInfo.roleId, data))
							return;

						char buf[512];
						snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0009, LANGUAGE_ZQX_0013, pUser->GetName(), data.name.c_str());
						pBangPai->SaveBangPaiLog(pUser, EBPLT_Member_Change, buf);
					}
					pUser->SetData32(2,GetSysTime());
					pUser->UpdateBangPai();
//					LeaveBangPaiTransport(pUser);
					return;
				}

				pBangPai->DelMember(pUser->GetRoleId());
				pUser->SetBangPai(0);
				ShareUserPtr p = m_onlineUser.GetUserByRoleId(pBangPai->GetBangZhu());
				CUser *pU = p.get();
				if(pU != NULL)
				{
					string str = pUser->GetName();
					str += LANGUAGE_TRANSFORM_1187;
					SendSysInfo(pU,MakeStringColor(str.c_str(),TIPS_FAILURE_COLOR).c_str());
				}
				pUser->SetData32(2,GetSysTime());
				pUser->UpdateBangPai();

//				LeaveBangPaiTransport(pUser);
//				CScene *pScene = pUser->GetScene();
//				if(pScene != NULL)
//					pScene->UpdateUserInfo(pUser,ESRT_BangPai);
				break;
			}
		case 13://帮派信息
			{
				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(pUser->GetBangPai());
				if(pBangPai == NULL)
				{
					msg<<PRO_ERROR;
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				string bangzhuName = pBangPai->GetBangZhuName();
				msg<<PRO_SUCCESS<<pBangPai->GetId()<<pBangPai->GetName()
					<<bangzhuName<<pBangPai->GetLevel()<<(uint16)pBangPai->GetId()<<pBangPai->GetMemberNum()
					<<pBangPai->GetFanRong()<<pBangPai->GetGongGao()
					<<pBangPai->GetKouHao()<<pBangPai->GetAutoAcceptLv();
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				break;
			}
		case 14:
			{
				uint32 bangpaiId = 0;
				msg>>bangpaiId;
				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(bangpaiId);
				msg.ReWrite();
				msg.SetType(PRO_BANGPAI);
				msg<<(uint8)14;
				if(pBangPai == NULL)
				{
					msg<<PRO_ERROR;
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				string bangzhu;
				string creater;
				GetUserName(pBangPai->GetBangZhu(),bangzhu);
				GetUserName(pBangPai->GetBangCreater(),creater);
				msg<<PRO_SUCCESS<<pBangPai->GetId()<<pBangPai->GetName()
					<<bangzhu<<pBangPai->GetLevel()<<pBangPai->GetPaiMing()
					<<pBangPai->GetHuoYue()<<pBangPai->GetKouHao();
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				break;
			}
		case 15:	// 修改口号 -- 没在用
			{
#ifdef KUA_FU
				return;
#endif
				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(pUser->GetBangPai());
				if(pBangPai == NULL)
				{
					return;
				}
				if(!pBangPai->IsAdmin(pUser->GetRoleId()))
					return;
				string name;
				msg>>name;
				pBangPai->SetKouHao(name.c_str());
				break;
			}
		case 16:	// 修改公告
			{
#ifdef KUA_FU
				return;
#endif
				string gonggao;
				msg>>gonggao;

				msg.ReWrite();
				msg.SetType(PRO_BANGPAI);
				msg<<(uint8)16;
				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(pUser->GetBangPai());
				if(pBangPai == NULL)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1188,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				if(!pBangPai->IsAdmin(pUser->GetRoleId()))
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1189,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				pBangPai->SetGongGao(gonggao.c_str());
				msg<<PRO_SUCCESS<<gonggao;
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				break;
			}
			break;
		case 17:
			{
				break;
			}
		case 18:	// 解散帮派
			{
#ifdef KUA_FU
				return;
#endif
				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(pUser->GetBangPai());
				if(pBangPai == NULL)
				{
					return;
				}
				if(pBangPai->GetMemberRank(pUser->GetRoleId()) != EBRBangZhu)
					return;
				m_bangPaiMgr.DelBangPai(pUser->GetBangPai());
				break;
			}
		case 19:	// 帮主传位,0 立即传位, 1撤消传位
			{
#ifdef KUA_FU
				return;
#endif
				uint32 roleId = 0;
				msg>>roleId;
				if(roleId == 0)
					return;

				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(pUser->GetBangPai());
				if(pBangPai == NULL)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1190,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				if(pBangPai->GetMemberRank(pUser->GetRoleId()) != EBRBangZhu)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1191,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				if(pBangPai->GetMemberRank(roleId) == 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1192,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				pBangPai->SetMemberRank(roleId,EBRBangZhu);
				ShareUserPtr p = m_onlineUser.GetUserByRoleId(roleId);
				CUser *pU = p.get();
				if(pU != NULL)
				{
					pU->UpdateBangPai();
				}

				pBangPai->SetMemberRank(pUser->GetRoleId(),EBRBangZhong);
				pUser->UpdateBangPai();
				msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_TRANSFORM_1195,TIPS_WARNING_COLOR);
				m_socketServer.SendMsg(pUser->GetSock(),msg);

				char buf[512];
				snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0009, LANGUAGE_ZQX_0013, pUser->GetName(), pBangPai->GetBangZhuName().c_str());
				pBangPai->SaveBangPaiLog(pUser, EBPLT_Member_Change, buf);
			}
			break;
		case 20:	// 调整位阶
			{
#ifdef KUA_FU
				return;
#endif
				uint32 userId;
				uint32 selfRank;
				uint8 rank;
				msg>>userId>>rank;

				msg.ReWrite();
				msg.SetType(PRO_BANGPAI);
				msg<<(uint8)20;
				if((rank <= EBRBangZhu) || (rank > EBRBangZhong))
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1196,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				if(pUser->GetRoleId() == userId)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1197,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(pUser->GetBangPai());
				if(pBangPai == NULL)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1198,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				if(!pBangPai->IsAdmin(pUser->GetRoleId()))
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1199,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				selfRank = pBangPai->GetMemberRank(pUser->GetRoleId());
				if(rank <= selfRank)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1200,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				int targetRank = (int)pBangPai->GetMemberRank(userId); // 被调整玩家的位阶
				if(targetRank <= (int)selfRank) 	// 不可以调整比自己阶级高的角色
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1201,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				int rankNum = pBangPai->GetMemNumByRank(rank);	// 位阶人数
				int rankMaxNum = pBangPai->GetMaxRankNum(rank);	// 本帮该位阶最大人数
				if(rankNum >= rankMaxNum)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1202,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				pBangPai->SetMemberRank(userId,rank);
				ShareUserPtr p = m_onlineUser.GetUserByRoleId(userId);
				CUser *pU = p.get();
				if(pU != NULL)
				{
					pU->SetBangPai(pBangPai->GetId(),rank,pBangPai->GetName().c_str());
					pU->UpdateBangPai();
//					CScene *pScene = pU->GetScene();
//					if(pScene != NULL)
//						pScene->UpdateUserInfo(pU,ESRT_BangPai);

					char buf[512];
					string srcRank = CBangPaiManager::GetRankName(selfRank);
					string dstRank = CBangPaiManager::GetRankName(rank);
					snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0006, pU->GetName(), srcRank.c_str(), pUser->GetName(), dstRank.c_str());
					pBangPai->SaveBangPaiLog(pUser, EBPLT_Member_Change, buf);
				}
				msg<<PRO_SUCCESS<<userId<<rank;
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				break;
			}
		case 21:	// 查询帮派信息
			{
				uint32 userId;
				msg>>userId;
				ShareUserPtr p = m_onlineUser.GetUserByRoleId(userId);
				CUser *pU = p.get();
				if((pU == NULL) || (pU->GetBangPai() == 0))
					break;
				uint32 bangpaiId = pU->GetBangPai();
				msg.ReWrite();
				msg.SetType(PRO_BANGPAI);
				msg<<(uint8)21;
				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(bangpaiId);
				if(pBangPai == NULL)
				{
					msg<<PRO_ERROR;
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					break;
				}
				string bangzhu;
				string creater;
				GetUserName(pBangPai->GetBangZhu(),bangzhu);
				GetUserName(pBangPai->GetBangCreater(),creater);
				msg<<PRO_SUCCESS<<pBangPai->GetId()<<pBangPai->GetName()
					<<bangzhu<<pBangPai->GetLevel()<<pBangPai->GetPaiMing()
					<<pBangPai->GetHuoYue()<<pBangPai->GetKouHao();
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				break;
			}
			break;
		case 22:	// 查询是否是传位状态
			{
				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(pUser->GetBangPai());

				if(pBangPai == NULL)
					return;
				if(pBangPai->GetMemberRank(pUser->GetRoleId()) != EBRBangZhu)
					return;
				if(pBangPai->IsChuangwei() == true)
					msg<<PRO_SUCCESS;
				else
					msg<<PRO_ERROR;
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			break;
		case 23:	// 全部批准加入帮派
			{
#ifdef KUA_FU
				return;
#endif
				uint8 res = 0;
				msg>>res;	//0不同意，1同意
				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(pUser->GetBangPai());
				if((pBangPai == NULL) || !(pBangPai->IsAdmin(pUser->GetRoleId())))
					return;
				pBangPai->AcceptAllAskJoin(pUser,res+1);
				pBangPai->CheckHotPoint(EHPoint_BP_JoinApply);
			}
			break;
		case 24:	// 领取俸禄
			{
#ifdef KUA_FU
				return;
#endif
				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(pUser->GetBangPai());
				if(pBangPai == NULL)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1203,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				uint8 num = pUser->GetExtData8(4);
				if(num >= 1)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1204,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				pUser->SetExtData8(4,num+1);
				msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_TRANSFORM_1205,TIPS_WARNING_COLOR);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			break;
		case 25:	// 捐献
			{
/*
#ifdef KUA_FU
				return;
#endif

				uint32 money = 0;
				msg>>money;
				msg.ReWrite();
				msg.SetType(PRO_BANGPAI);
				msg<<(uint8)25;

				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(pUser->GetBangPai());
				if(pBangPai == NULL)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1206,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				if((int)money < 0)
					return;
				if(pUser->GetMoney() < (int)money)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1207,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				uint32 banggong = money;
				uint32 role_banggong;
				uint32 totolBangGong = pBangPai->AddMemberBangGongById(pUser->GetRoleId(),banggong,role_banggong);
				pUser->AddMoney(-banggong);
				pUser->AddTodayBangGong(banggong);
				msg<<PRO_SUCCESS<<totolBangGong<<role_banggong<<pUser->GetTodayBangGong();
				m_socketServer.SendMsg(pUser->GetSock(),msg);
*/
			}
			break;
		case 26:	// 通知玩家入帮
			{

			}
			break;
		case 27:	// 进入帮派场景
			{
/*
#ifdef KUA_FU
				return;
#endif
				uint32 bangPaiId= 0;
				msg>>bangPaiId;
				if(bangPaiId == 0)
					return;
				
				if(pUser->GetFightId() > 0)
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0477,TIPS_FAILURE_COLOR).c_str());
					return;
				}
				if(!pUser->CanWorldTransPort(BANG_PAI_SCENE_ID))
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0475,TIPS_FAILURE_COLOR).c_str());
					return;
				}
				
				if(pUser->GetSrcSceneId() == LEI_TAI_ID2)
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0013,TIPS_FAILURE_COLOR).c_str());
					return;
				}
				msg.ReWrite();
				msg.SetType(PRO_BANGPAI);
				msg<<(uint8)27<<PRO_SUCCESS;
				m_socketServer.SendMsg(pUser->GetSock(),msg);

				CScene *pScene = pUser->GetScene();
				if(pScene == NULL)
					return;
				CScene *pTarScene = SingletonSceneManager::instance().GetBangPaiScene(BANG_PAI_SCENE_ID,bangPaiId);
				if(pTarScene == NULL)
					return;
				if(pScene == pTarScene)
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_1209,TIPS_FAILURE_COLOR).c_str());
					return;
				}

				if(!TeamCanEnterBangPai(pUser))
					return;
				if(!CanJoinActivity(pUser))
					return;
				EnterBangPaiScene(pUser,bangPaiId);

				SendPKNotice(pUser);
*/
			}
			break;
		case 28:	// 请求帮派操作记录列表
			{
#ifdef KUA_FU
				return;
#endif
				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(pUser->GetBangPai());
				if(pBangPai == NULL)
					return;
				pBangPai->SendBangPaiLogMsg(pUser);
			}
			break;
		case 29:	// 帮主，长老每日领取额外奖励
			{
#ifdef KUA_FU
				return;
#endif
				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(pUser->GetBangPai());
				if(pBangPai == NULL)
					return;
				pBangPai->GetRewardByRank(pUser);
			}
			break;
		case 30:	// 请求本帮派入帮申请状态
			{
#ifdef KUA_FU
				return;
#endif
				uint32 bangpaiId = pUser->GetBangPai();
				if(bangpaiId == 0)
					msg<<(uint8)0;
				else
				{
					CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(bangpaiId);
					if(pBangPai == NULL)
						msg<<(uint8)0;
					else
					{
						list<uint32> askJoin;
						pBangPai->GetAskForJoin(askJoin);
						if(askJoin.empty())
							msg<<(uint8)0;
						else
							msg<<(uint8)1;
					}
				}
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			break;
		case 31:	// 更新入帮申请状态(服务器主动推送)
			{
			}
			break;
		case 32:	// 设置帮派信息是否显示
			{
				uint8 show = 0;	// 1显示0不显示
				msg>>show;

				if(show > 1)
					return;
				uint32 bangpaiId = pUser->GetBangPai();
				CBangPai *pBangPai = NULL;
				if(bangpaiId != 0)
					pBangPai = m_bangPaiMgr.FindBangPai(bangpaiId);
				if(pBangPai == NULL)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1210,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				if(pUser->GetExtData8(379) == show)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1211,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				pUser->SetExtData8(379,show);
				msg<<PRO_SUCCESS<<MakeStringColor((show == 1) ? LANGUAGE_TRANSFORM_1212 : LANGUAGE_TRANSFORM_1213,TIPS_WARNING_COLOR);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				
//				CScene *pScene = pUser->GetScene();
//				if(pScene != NULL)
//					pScene->UpdateUserInfo(pUser,ESRT_BangPai);
			}
			break;
		case 33:
			{
#ifdef KUA_FU
				return;
#endif
				uint32 bid = pUser->GetBangPai();
				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(bid);
				if(pBangPai != NULL){
					pBangPai->ShowTaskList(pUser, msg);
					m_socketServer.SendMsg(pUser->GetSock(), msg);
				}
			}
			break;

		case 34: // 请求神树信息
			{
#ifdef KUA_FU
				return;
#endif
				uint32 bid = pUser->GetBangPai();
				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(bid);
				if(pBangPai != NULL){
					pBangPai->SendTreeMsg(pUser);
				}
			}
			break;
		case 35: // 神树祈福
			{
#ifdef KUA_FU
				return;
#endif
				uint32 queryBangPaiId = 0;
				uint8  type = 1;	// 1普通2元宝祈福
				uint32 bid = pUser->GetBangPai();
				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(bid);
				msg>>queryBangPaiId>>type;
				if(queryBangPaiId != bid){
					return;
				}
				if(pBangPai != NULL){
					pBangPai->TreePray(pUser,type);
				}
			}
			break;
			
		case 36:	// 领取奖励
			{
#ifdef KUA_FU
				return;
#endif
				uint32 bid = pUser->GetBangPai();
				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(bid);
				int missionId = 0;
				msg>>missionId;
				if(pBangPai != NULL){
					pBangPai->TakeTaskAward(pUser, msg, missionId);
					m_socketServer.SendMsg(pUser->GetSock(), msg);
				}
			}
			break;
		case 37:	// 获取捐献信息
			{
#ifdef KUA_FU
				return;
#endif
				uint32 bid = pUser->GetBangPai();
				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(bid);
				if(pBangPai != NULL){
					pBangPai->GetJuanXianInfo(pUser,msg);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
				}
			}
			break;
		case 38:	// 捐献金币
			{
#ifdef KUA_FU
				return;
#endif
				uint8 type = 0;	// 1 10万 2 100万 3 500万
				msg>>type;
				if(type == 0){
					return;
				}
				uint32 bid = pUser->GetBangPai();
				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(bid);
				if(pBangPai != NULL){
					pBangPai->JuanXian(pUser,msg, type);
					m_socketServer.SendMsg(pUser->GetSock(), msg);
				}
			}
			break;
		case 39:	// 获取操作记录(内务信息)
			{
#ifdef KUA_FU
				return;
#endif
				uint8 type = 0;	// 1捐献信息2上仙互动3其他信息
				msg>>type;
				if(type == 0)
					return;

				uint32 bid = pUser->GetBangPai();
				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(bid);
				if(pBangPai != NULL){
					pBangPai->GetOptionLog(msg,type);
					m_socketServer.SendMsg(pUser->GetSock(), msg);
				}
			}
			break;
		case 40://设置自动通过审核
			{
#ifdef KUA_FU
				return;
#endif
				uint16 level = 0;
				msg>>level;
				uint32 bid = pUser->GetBangPai();
				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(bid);
				if(pBangPai != NULL && pBangPai->IsAdmin(pUser->GetRoleId())){
					pBangPai->SetAutoAcceptSign(level);
					pUser->UpdateBangPai();
				}
			}
			break;
		case 41://获取活跃奖励领取情况
			{
				uint32 bid = pUser->GetBangPai();
				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(bid);
				if(pBangPai != NULL)
				{
					msg<<(uint8)2;
					for(int i=1;i<3;i++)
					{
						msg<<(uint8)i;
						vector<SBangPaiHuoYueReward> vec;
						SingletonCBPRewardCfgMgr::instance().GetHuoYueDrawInfo(i,vec);
						uint8 size = vec.size();
						msg<<size;
						for(uint8 j=0;j<size;j++)
						{
							int sign = pUser->HaveBitSet(vec[j].idx)? 1 : 0;
							msg<<(uint32)vec[j].huoyue<<(uint8)sign;
							vector<SAwardData> awvec;
							sAwardManager.GetAwardById(vec[j].rewardid, awvec);
							uint8 cnt = awvec.size();
							msg<<cnt;
							for(uint8 k=0;k<cnt;k++)
							{
								msg<<awvec[k].type<<awvec[k].num;
							}

						}
					}
					m_socketServer.SendMsg(pUser->GetSock(), msg);
				}
			}
			break;
		case 42://领取活跃奖励
			{
#ifdef KUA_FU
				return;
#endif
				uint8 type = 0;
				uint32 huoyue = 0;
				msg>>type>>huoyue;
				uint32 bid = pUser->GetBangPai();
				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(bid);
				if(pBangPai != NULL)
				{
					pBangPai->DrawHuoYue(msg,pUser,type,huoyue);
					m_socketServer.SendMsg(pUser->GetSock(), msg);
				}
			}
			break;
		case 43://升级炼器阁
			{
#ifdef KUA_FU
				return;
#endif			
				uint8 type = 0;
				msg>>type;
				uint32 bid = pUser->GetBangPai();
				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(bid);
				if(pBangPai != NULL && pBangPai->IsAdmin(pUser->GetRoleId()))
				{
					pBangPai->UpgradeLianQiPavilion(pUser,type,msg);
					m_socketServer.SendMsg(pUser->GetSock(), msg);
				}
			}
			break;
		case 44://请求帮派技能
			{
#ifdef KUA_FU
				return;
#endif			
				uint32 bid = pUser->GetBangPai();
				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(bid);
				if(pBangPai != NULL)
				{
					//个人
					if(pUser->MakeBangSkill(msg))
					{
						m_socketServer.SendMsg(pUser->GetSock(), msg);
					}
					
				}
			}
			break;
		case 45://帮派技能升级
			{
#ifdef KUA_FU
				return;
#endif			
				uint8 type = 0;
				uint8 isAuto = 0;
				uint16 skillId = 0;
				
				msg>>type>>skillId>>isAuto;
				if(type != 1 && type != 2)
					return;
				uint32 bid = pUser->GetBangPai();
				
				if(type == 1)
				{
					if (bid <=0)
						return;
					//个人
					bool sign = pUser->UpBangSkillLv(msg,skillId,isAuto == 1);
					m_socketServer.SendMsg(pUser->GetSock(), msg);
					if(sign)
					{
						pUser->InitAllPet();
						pUser->InitAndUpdate();
					}
				}
				else
				{
					CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(bid);
					if(pBangPai != NULL && pBangPai->IsAdmin(pUser->GetRoleId()))
					{
						//帮派
						pBangPai->UpSkillLv(msg,pUser,skillId,isAuto == 1);
						m_socketServer.SendMsg(pUser->GetSock(), msg);
					}
				}
			}
			break;
		default:
			break;
	}
}

void CPackageDeal::BangPaiCopyOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint32 bangId = pUser->GetBangPai();
	if(bangId == 0)
	{
		SendSysInfo(pUser, LANGUAGE_TRANSFORM_353);
		return;
	}
	CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(bangId);
	if(pBangPai == NULL)
		return;

	uint8 op=0;
	msg>>op;
	switch(op)
	{
		case 1:	// 查询帮派副本信息(章节)
		{
			CNetMessage nMsg;
			if(pBangPai->MakeChapterMsg(nMsg, pUser))
			{
				m_socketServer.SendMsg(sock, nMsg);
			}
			break;
		}
/*		case 2:	// 查看副本节点信息
		{
			int chapId = 0;
			int copyId = 0;
			msg>>chapId>>copyId;
			if(chapId == 0 || copyId == 0)
				return;
			
			CNetMessage nMsg;
			if(pBangPai->MakeCopyMsg(nMsg, chapId, copyId))
			{
				m_socketServer.SendMsg(sock, nMsg);
			}
			break;
		}
*/
		case 3:	// 战斗
		{
			int chapId = 0;
			int copyId = 0;
			msg>>chapId>>copyId;
			if(pBangPai->CopyFight(msg, pUser, chapId, copyId))
			{
				m_socketServer.SendMsg(sock, msg);
				sCMissionManager.UpdateQuestState(pUser, EMQCT_60);
			}
			break;
		}
		case 4:	// 扫荡
		{
			int chapId = 0;
			int copyId = 0;
			msg>>chapId>>copyId;
			if(pBangPai->RunMulCopyFight(msg, pUser, chapId, copyId))
			{
				m_socketServer.SendMsg(sock, msg);
			}
			break;
		}
		case 5:	// 副本buff升级
		{
			uint8 buffId = 0;
			msg>>buffId;
			if(pBangPai->UpdateGradeBuff(msg, pUser, buffId))
			{
				m_socketServer.SendMsg(sock, msg);
			}
			break;
		}
		case 6:	// 获取副本buff等级
		{
			pBangPai->GetBuffInfo(msg);
			m_socketServer.SendMsg(sock, msg);
			break;
		}
		case 7:	// 获取章节伤害榜
		{
			int chapId = 0;
			msg>>chapId;
			if(chapId == 0)
				return;
			pBangPai->MakeChapDamRankInfo(msg, chapId);
			m_socketServer.SendMsg(sock, msg);
			break;
		}
		case 8:	// 领取副本通关奖励
		{
			int chapId = 0;
			int copyId = 0;
			msg>>chapId>>copyId;
			if(chapId == 0 || copyId == 0)
				return;
			if(pBangPai->GetCopyNormalAward(msg, pUser, chapId, copyId))
			{
				m_socketServer.SendMsg(sock, msg);
			}
			break;
		}
		case 9:	// 获取帮派每日活跃奖励列表
		{
			if(pBangPai->GetHuoYueInfo(msg, pUser))
			{
				m_socketServer.SendMsg(sock, msg);
			}
			break;
		}		
		case 10:	// 领取帮派每日总活跃奖励，每人每档一次
		{
			uint16 awardId = 0;
			msg>>awardId;
			if(pBangPai->GetHuoYueAward(msg, pUser, awardId))
			{
				m_socketServer.SendMsg(sock, msg);
			}
			break;
		}

		default:
		{
			break;
		}
	}
}

void CPackageDeal::FuncHotPointOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 op = 0;
	msg>>op;
	if(op == 1)	// 查询小红点状态
	{
		uint16 type = 0;
		msg>>type;
		if(gyu::util::CIniFile::GetValue("local_test","server",gConfigFile) == "1")
		{
			msg.ReWrite();
			msg.SetType(PRO_Func_HotPoint);
			msg<<op<<type<<(uint8)EHPointS_NotShow;
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		switch(type)
		{
			// 帮派相关
			case EHPoint_BP_UpgradeSkill:
			case EHPoint_BP_JoinApply:
			case EHPoint_BP_CopyAward:
			{
				uint32 bangId = pUser->GetBangPai();
				if(bangId == 0)
					return;
				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(bangId);
				if(pBangPai == NULL)
					return;
				pBangPai->CheckHotPoint(type, pUser->GetRoleId());
				break;
			}

			// 好友相关
			case EHPoint_Fri_RecvAward:
			case EHPoint_Fri_RecvApply:
			{
				SingletonCFriendMgr::instance().CheckHotPoint(type, pUser->GetRoleId());
				break;
			}

			// 邮件
			case EHPoint_Mail:
			{
				CGetDbConnect getDb;
				CDatabaseSql *pDb = getDb.GetDbConnect();
				if(pDb == NULL)
					return;
				char sql[256];
				snprintf(sql, sizeof(sql), "select id from xin_shi where deleted=0 and to_id=%u and unix_timestamp(time)>%lu limit 1", pUser->GetRoleId(), GetSysTime()-Mail_Time_Limit);
				if(!pDb->Query(sql))
					return;
				uint8 show = (pDb->GetRowNum() == 0) ? EHPointS_NotShow : EHPointS_Show;
				SendHotPointStatus(pUser, EHPoint_Mail, show);
				break;
			}

			case EHPoint_BeiGongji:
			{
				pUser->m_missList.SendHDQuestHotPointStatus(pUser);
				break;
			}

			case EHPoint_XueZhan:
			{
				CUserBloodFight* bf = pUser->GetBloodFight();
				if (bf != NULL)
					bf->SendBFHotPointStatus(pUser);
				break;
			}

			case EHPoint_ChengJiu:
			{
				CUserGuanQia& gq = pUser->GetGuanQia();
				gq.SendCJHotPointStatus(pUser);
				break;
			}

			case EHPoint_XiangZi:
			{
				CUserGuanQia& gq = pUser->GetGuanQia();
				gq.SendFixHotPointStatus(pUser);
				break;
			}

			case EHPoint_FuBen:
			{
				CUserGuanQia& gq = pUser->GetGuanQia();
				gq.SendFuBenHotPointStatus(pUser);
				break;
			}

			case EHPoint_Quest_1:
			case EHPoint_Quest_2:
			case EHPoint_Quest_3:
			case EHPoint_Quest_4:
				pUser->m_missList.SendQuestHotPointStatus(pUser, type);
				break;

			case EHPoint_HDQuest:
				pUser->m_missList.SendHDQuestHotPointStatus(pUser);
				break;

			case EHPoint_TiLi:
			{
				CUserSpirit& sp = pUser->GetUserSpirit();
				sp.SendTiLiHotPointStatus(pUser);
				break;
			}

			case EHPoint_ZhaoHui:
				pUser->SendZhaoHuiHotPointStatus();
				break;

			case EHPoint_TuJian:
			{
				UserBook* book = pUser->GetUserBook();
				if (book != NULL)
					book->SendTuJianHotPointStatus(pUser);
				break;
			}

			case EHPoint_Shop1:
			{
				UserShopManager* shop = pUser->GetShop();
				if (shop != NULL)
					shop->SendShopHotPointStatus(pUser, 4);
				break;
			}
			case EHPoint_Shop2:
			{
				UserShopManager* shop = pUser->GetShop();
				if (shop != NULL)
					shop->SendShopHotPointStatus(pUser, 8);
				break;
			}

			default:
			{
				return;
			}
		}
	}
	else if(op == 2)	// 推送小红点状态(服务器推送)
	{

	}
}

void CPackageDeal::GetNpcState(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 op = 0;	// 1请求npc状态，2更新state，3更新headstate
	uint16 npcId = 0;
	uint16 npcIndex = 0;
	msg>>op>>npcId>>npcIndex;
	if(op != 1)
		return;
	SNpcInstance *pNpc = m_npcManager.GetNpcInstance(npcId);
	CCallScript *pScript = NULL;
	pScript = pUser->FindNpcScript(npcId);

	if((pScript == NULL) && (pNpc != NULL) && (pNpc->pNpc != NULL))
		pScript = pNpc->pNpc->pScript;
	if(pScript == NULL)
	{
		SNpcTemplate *pTNpc = m_npcManager.GetNpcTemplate(npcId);
		if(pTNpc == NULL)
			return;
		pScript = pTNpc->pScript;
		if(pScript == NULL)
			return;
	}
	int state = 0;	// 任务可接、已经、完成等状态显示
	int headState = 0;	// 已击杀等npc头顶标识
	pScript->Call("GetState","u>i",pUser,&state);
	pScript->Call("GetHeadTitle","ui>i",pUser,npcIndex,&headState);
	msg<<(uint8)state<<(uint8)headState;
	m_socketServer.SendMsg(sock,msg);
	
/*
	int npcSayPic = 0;
	pScript->Call("GetChatMsg","u>i",pUser,&npcSayPic);
	if(npcSayPic > 0)
	{
		msg.ReWrite();
		msg.SetType(MSG_SERVER_NPC_SAY);
		msg<<npcId<<npcSayPic;
		m_socketServer.SendMsg(pUser->GetSock(),msg);
	}
*/

	//state == 2任务已接，3任务完成
	if(npcId == 1)
	{
		if(state != 0)
		{
			int mapId = 0;
			int x = 0;
			int y = 0;
			pScript->Call("GetNpcPos","i>iii",state,&mapId,&x,&y);
			if(mapId != 0)
			{
				msg.ReWrite();
				msg.SetType(MSG_NPC_POS);

				msg<<(uint16)mapId<<(uint8)x<<(uint8)y;
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
		}
	}
}

void CPackageDeal::UpdatePackage(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER
	if(pUser->GetKuaFuState() != EKFS_IN_LOCAL)
		return;

	uint8 op = 0xff;
	msg>>op;
	if(op == 0)	//丢弃
	{
		uint8 pos = 0xff;
		uint8 num = 1;
		msg>>pos>>num;
		if(num == 0)
			return;
		if(pUser->CanDelPackage(pos))
		{
			pUser->SaveDelItem(pos,num);
			pUser->DelPackage(pos,num);
			msg<<PRO_SUCCESS;
			m_socketServer.SendMsg(pUser->GetSock(),msg);
		}
		else
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1214,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
		}
	}
	else if(op == 1)	//使用物品
	{
		uint16 pos = 0xff;
		uint8 num = 1;
		uint8 target = 0xff;
		uint8 val= 0;
		uint8 val1=0;
		msg>>pos>>num>>target>>val>>val1;
		if(gyu::util::CIniFile::GetValue("local_test","server",gConfigFile) == "1")
			cout<<"[local] UpdatePackage use pos="<<pos<<" num="<<(int)num
				<<" target="<<(int)target<<endl;
		if(target == 0)
		{
			if(pos >= pUser->GetMaxPackageNum())
				return;
			if(num == 0)
				return;
			SItemInstance *pInst = pUser->GetItem(pos);
			if(pInst == NULL)
				return;
			if(pInst->tmplId >= 2375 && pInst->tmplId <= 2378)
			{
				CNetMessage tempMsg;
				tempMsg.SetType(MSG_PET_RANDOM_DRAW);
				if(pInst->tmplId == 2375)
					tempMsg<<(uint8)2<<(uint8)1<<pos;
				else if(pInst->tmplId == 2376)
					tempMsg<<(uint8)2<<(uint8)2<<pos;
				else if(pInst->tmplId == 2377)
					tempMsg<<(uint8)2<<(uint8)3<<pos;
				else
					tempMsg<<(uint8)3<<pos;
				PetDraw(&tempMsg,pUser->GetSock());
				return;
			}
			if(gyu::util::CIniFile::GetValue("local_test","server",gConfigFile) == "1"
				&& pInst->tmplId >= 3201 && pInst->tmplId <= 3203)
			{
				static const int vipExperience[] = { 10, 50, 100 };
				if(pInst->num < num)
					num = pInst->num;
				pUser->AddExVipExp(vipExperience[pInst->tmplId - 3201] * num);
				pUser->DelPackage(pos, num);
				pUser->UpdateVipInfoEx();
				return;
			}
			pUser->UseItem(pos,NULL,NULL,val,val1,num);
		}
		else if(gyu::util::CIniFile::GetValue("local_test","server",gConfigFile) == "1")
		{
			// The legacy choice-item path holds CUser::m_mutex while awarding an
			// item. Awarding updates mission state after AddPackage and can block
			// the local Windows worker before the authoritative package delete is
			// emitted. Keep production unchanged; local_test performs the same
			// validated award and delete as two public, independently locked steps.
			SItemInstance *pInst = pUser->GetItem(pos);
			SItemTemplate *pItem = pInst == NULL
				? NULL : SingletonItemManager::instance().GetItem(pInst->tmplId);
			cout<<"[local] choice candidate pos="<<pos
				<<" item="<<(pInst == NULL ? 0 : pInst->tmplId)
				<<" type="<<(pItem == NULL ? -1 : (int)pItem->type)
				<<" awards="<<(pItem == NULL ? 0 : pItem->subAward.size())
				<<" target="<<(int)target<<endl;
			if(pInst == NULL || pInst->num == 0)
				return;
			if(pInst->num < num)
				num = pInst->num;
			int rewardId = 0;
			int rewardNum = 0;
			if(GetLocalChoiceItemAward(pInst->tmplId, target, rewardId, rewardNum))
			{
				// The local server JSON predates all six shipped client choice boxes.
				// Never consume a box unless its selected reward was actually added.
				if(!pUser->AddBangDingPackage(rewardId, rewardNum * num))
				{
					cout<<"[local] choice item award failed; box preserved pos="<<pos
						<<" reward="<<rewardId<<" num="<<(rewardNum * num)<<endl;
					return;
				}
			}
			else
			{
				if(pItem == NULL || pItem->type != 6 || pItem->subAward.size() < target)
					return;
				SAwardData award = pItem->subAward[target - 1];
				award.num *= num;
				pUser->AddMaterial(award);
			}
			cout<<"[local] choice item award complete; delete begin pos="<<pos<<endl;
			pUser->DelPackage(pos, num);
			cout<<"[local] choice item delete complete pos="<<pos<<endl;
		}
		else
			pUser->UseItem(pos, num, target);
	}
	else if(op == 2)	//移动包裹
	{
		uint8 srcPos;
		uint8 tarPos;
		msg>>srcPos>>tarPos;
		pUser->MoveItem(srcPos,tarPos);
	}
	else if(op == 6)	// 整理
	{
		msg<<PRO_SUCCESS;
		pUser->SortPackage();
		pUser->MakePack(msg);
		m_socketServer.SendMsg(sock,msg);
	}
	else if(op == 7)//卖出
	{
		uint8 pos = 0xff;
		uint8 num = 1;
		msg>>pos>>num;
		if(num == 0)
			return;
		
		int value = pUser->CanSellPackage(pos,num);
		if(value > 0)
		{
			pUser->SaveSellItem1(pos,num);
			pUser->DelPackage(pos,num);
			msg<<PRO_SUCCESS;
			m_socketServer.SendMsg(pUser->GetSock(),msg);

			pUser->AddTongBao(value,1);

		}
		else
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_CC_0009,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
		}
	}
}

void CPackageDeal::UserJumpOk(CNetMessage *pMsg,int sock)
{
	GET_USER
	pUser->UserJump(false);
}

void CPackageDeal::SwitchInfo(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 mask = pUser->GetChatChannel();
	msg.ReWrite();
	msg.SetType(PRO_SWITCH_INFO);
	msg<<mask;

	m_socketServer.SendMsg(pUser->GetSock(),msg);
}

void CPackageDeal::QueryPetInfo(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER
	uint32 userId = 0;
	uint16 petId = 0;
	msg>>userId>>petId;

	msg.ReWrite();
	msg.SetType(PRO_OTHER_PET);

	ShareUserPtr p = m_onlineUser.GetUserByRoleId(userId);
	CUser *pU = p.get();
	bool online = true;
	if(pU == NULL)
	{
		pU = new CUser;
		online = false;
		if(pU == NULL)
		{
			delete pU;
			msg<<PRO_ERROR;
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		else
		{
			CGetDbConnect getDb;
			CDatabaseSql *pDb = getDb.GetDbConnect();
			if(pDb == NULL)
			{
				delete pU;
				msg<<PRO_ERROR;
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				return;
			}
			char sql[128];
			char **row = NULL;
			snprintf(sql,sizeof(sql),"select pet from role_info where id=%u",userId);
			if(!pDb->Query(sql))
			{
				delete pU;
				msg<<PRO_ERROR;
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				return;
			}
			if((row = pDb->GetRow()) != NULL)
			{
				pU->SetPet(row[0]);
			}
			else
			{
				delete pU;
				msg<<PRO_ERROR;
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				return;
			}
		}
	}

	msg<<PRO_SUCCESS<<userId;
	if(!pU->MakePetById(petId,msg))
	{
		msg.ReWrite();
		msg.SetType(PRO_OTHER_PET);
		msg<<PRO_ERROR;
	}
	m_socketServer.SendMsg(pUser->GetSock(),msg);
	if(!online)
		delete pU;
}

void CPackageDeal::MyBangPai(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 op = 0;
	msg>>op;
	if(op == 1)
	{
		pUser->UpdateBangPai();
	}
	else if(op == 2)	// 帮贡更新,服务器主动发送
	{
		
	}
}

void CPackageDeal::ChangeUserFace(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 face;
	msg>>face;
	pUser->SetFace(face);
}

void CPackageDeal::ItemDesc(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint16 itemId = 0;
	msg>>itemId;
	CItemTemplateManager &itemMgr = SingletonItemManager::instance();
	SItemTemplate *pItem = itemMgr.GetItem(itemId);
	if(pItem == NULL)
		return;
	msg<<pItem->describe;
	m_socketServer.SendMsg(pUser->GetSock(),msg);
}

// 获得充值订单号
void CPackageDeal::GetChargeOrder(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	const int TIME_GAP = 60*2;
	uint16 type = 0;
	msg>>type;
	if(type == 201)	// IOSAppStore
	{
		uint32 curTime = GetSysTime();
		int dt = curTime - pUser->GetExtData32(404);
		if(dt < TIME_GAP)
		{
			char buf[512];
			snprintf(buf,sizeof(buf)-1,LANGUAGE_SSJ_0213,TIME_GAP - dt);
			SendSysInfo(pUser,MakeStringColor(buf,TIPS_FAILURE_COLOR).c_str());
			return;
		}
		pUser->SetExtData32(404,curTime);
		
		char orderId[256];
		snprintf(orderId,sizeof(orderId)-1,"IOS-Store_%d_%u_%u",pUser->GetServerId(),pUser->GetRoleId(),curTime);

		boost::format fmt;
		fmt.parse("INSERT INTO chong_zhi (type,order_id,time,user_id,role_id,state) VALUES (%1%,'%2%',FROM_UNIXTIME(%3%),%4%,%5%,2)");
		fmt % (int)type % orderId % GetSysTime() % pUser->GetUserId() % pUser->GetRoleId();
		if(m_loginDb.Query(fmt.str().c_str()))
		{
			msg<<orderId;
			m_socketServer.SendMsg(sock,msg);
			return;
		}
	}
}

//充值
void CPackageDeal::Charge(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint16 type = 0;
	string orderId;
	string data;
	uint16 money;
	static string serverId;
	string netInfo,mac,IMEI,IDFA;
	msg>>type>>orderId>>data>>money>>netInfo>>mac>>IMEI>>IDFA;

	// 201 IOSAppStore
	if(type != 201)
		return;
	sockaddr_in addr;
	socklen_t len = sizeof(addr);
	getpeername(sock, (sockaddr*)&addr,&len);
	char *ip = inet_ntoa(addr.sin_addr);
	if(ip == NULL)
		return;
	string ip_str = ip;
	msg.ReWrite();
	msg.SetType(PRO_CHARGE);

	boost::format fmt;
	fmt.parse("update chong_zhi set receipt_data='%1%',money=%2%,time=FROM_UNIXTIME(%3%),state=0,ip='%4%',net_info='%5%',mac='%6%',IMEI='%7%',IDFA='%8%' where order_id='%9%' and type=201 and state=2");
	fmt % data % money % GetSysTime() % ip_str % netInfo % mac % IMEI % IDFA % orderId;

	if(m_loginDb.Query(fmt.str().c_str()))
		msg<<PRO_SUCCESS;
	else
	{
		cout<<">> CPackageDeal::Charge error sql : "<<fmt.str()<<endl;
		msg<<PRO_ERROR;
	}
	m_socketServer.SendMsg(sock,msg);
	return;
}

void CPackageDeal::AvailableTask(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 op; // 1: 任务面板可接任务 2：任务追踪可接任务
	msg>>op;
	if (op == 4) //可接任务列表
	{
		SingletonCMissionManager::instance().SendAvailableCMissionList(pUser);
	}
	else if (op == 5) //可接任务详细信息
	{
		uint16 missionId;
		msg>>missionId;
		SingletonCMissionManager::instance().SendAvailableCMissionInfo(pUser,missionId);
	}
}

void CPackageDeal::GetScenePos(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	if((pUser->GetTeam() != 0) && (pUser->GetTeam() != pUser->GetRoleId()))
		return;

	CScene *pScene = pUser->GetScene();
	if(pScene != NULL)
	{
		pUser->SetPos(pScene->GetX(),pScene->GetY());
		msg.ReWrite();
		msg.SetType(PRO_JUMP_SCENE);
		msg<<(uint16)pScene->GetId()<<pScene->GetX()<<pScene->GetY()<<pUser->GetFace()<<(uint8)0;
		m_socketServer.SendMsg(pUser->GetSock(),msg);
	}
}

void CPackageDeal::NPCYinDao(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	CSocketServer &sock1 = SingletonSocket::instance();
	bool localTestLog = (gyu::util::CIniFile::GetValue("local_test","server",gConfigFile) == "1");
	if(localTestLog)
		cout << "[local] NPCYinDao: begin roleId=" << pUser->GetRoleId() << endl;
	uint16 guide19 = pUser->GetExtData16(19);
	uint16 guide112 = pUser->GetExtData16(112);
	uint16 guide113 = pUser->GetExtData16(113);
	if(localTestLog)
		cout << "[local] NPCYinDao: values=" << guide19 << "," << guide112 << "," << guide113 << endl;
	msg.ReWrite();
	msg.SetType(MSG_YINDAO);
	msg<<(uint8)0<<guide19<<guide112<<guide113;
	sock1.SendMsg(sock,msg);
	if(localTestLog)
		cout << "[local] NPCYinDao: sent roleId=" << pUser->GetRoleId() << endl;
}

void CPackageDeal::XinShouYinDao(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 op = 0;
	msg>>op;
	switch (op) // 完成相应引导
	{
	case 1: // 副本ui使用引导
		{
			cout << LANGUAGE_TRANSFORM_1250 << endl;
			//pUser->SetBitSet(?);
			break;
		}
	case 2: // 神将等级转移引导
		{
			cout << LANGUAGE_TRANSFORM_1251 << endl;
			//pUser->SetBitSet(?);
			break;
		}
	case 3: // 洗神将引导
		{
			cout << LANGUAGE_TRANSFORM_1252 << endl;
			//pUser->SetBitSet(?);
			break;
		}
	default:
		{
			break;
		}
	}
}

void CPackageDeal::SendHuoDongInfo(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER
	uint8 c;
	int day;
	uint8 num = 0;
	int time = GetHour()*100 + GetMinute();
	uint8 level = pUser->GetLevel();
	static time_t old_time = GetSysTime();
	msg>>c;
	if(c <= 1)
	{
		day = GetWeekDay() + c;
		if(day > 6)
			day = 0;
	}
	else if(c == 2)
		day = HUODONG_SIZE-1;
	else
		return;
	if(GetSysTime() - old_time > 3600)
	{
		old_time = GetSysTime();
		for(int j=0;j<HUODONG_SIZE;j++)
			huodong[j].clear();
		GetHuoDongConfig();
	}

	for(list<HuoDongInfo>::iterator i = huodong[day].begin();i != huodong[day].end();i++)
		if(level >= i->min_lv && level <= i->max_lv)
			num++;
//	msg.ReWrite();
//	msg.SetType(MSG_HUODONG);
	msg<<num;
	if(c == 0 || c == 2)
	{
		for(list<HuoDongInfo>::iterator i = huodong[day].begin();i != huodong[day].end();i++)
		{
			if((level >= i->min_lv && level <= i->max_lv) && (time >= i->min_time && time < i->max_time))
				msg<<i->name<<i->time<<i->NPC_name<<i->mapid<<(char)i->x<<(char)i->y<<(uint8)1;
		}
		for(list<HuoDongInfo>::iterator i = huodong[day].begin();i != huodong[day].end();i++)
		{
			if(level >= i->min_lv && level <= i->max_lv)
			{
				if(i->min_time == 0 && i->max_time == 0)
				{
					if(i->name == LANGUAGE_TRANSFORM_1253)
						msg<<i->name<<LANGUAGE_TRANSFORM_1254<<i->NPC_name<<i->mapid<<(char)i->x<<(char)i->y<<(uint8)5;
					else
						msg<<i->name<<LANGUAGE_TRANSFORM_1255<<i->NPC_name<<i->mapid<<(char)i->x<<(char)i->y<<(uint8)0;
					continue;
				}
				if(time < i->min_time || time >= i->max_time)
				{
					if(i->name == LANGUAGE_TRANSFORM_1256)
						msg<<i->name<<LANGUAGE_TRANSFORM_1257<<i->NPC_name<<i->mapid<<(char)i->x<<(char)i->y<<(uint8)5;
					else
						msg<<i->name<<i->time<<i->NPC_name<<i->mapid<<(char)i->x<<(char)i->y<<(uint8)0;
				}
			}
		}
	}
	else if(c == 1)
	{
		for(list<HuoDongInfo>::iterator i = huodong[day].begin();i != huodong[day].end();i++)
		{
			if(level >= i->min_lv && level <= i->max_lv)
			{
				if(i->min_time == 0 && i->max_time == 0)
				{
					if(i->name == LANGUAGE_TRANSFORM_1258)
						msg<<i->name<<LANGUAGE_TRANSFORM_1259<<i->NPC_name<<i->mapid<<(char)i->x<<(char)i->y<<(uint8)5;
					else
						msg<<i->name<<LANGUAGE_TRANSFORM_1260<<i->NPC_name<<i->mapid<<(char)i->x<<(char)i->y<<(uint8)0;
					continue;
				}
				else
				{
					if(i->name == LANGUAGE_TRANSFORM_1261)
						msg<<i->name<<LANGUAGE_TRANSFORM_1262<<i->NPC_name<<i->mapid<<(char)i->x<<(char)i->y<<(uint8)5;
					else
						msg<<i->name<<i->time<<i->NPC_name<<i->mapid<<(char)i->x<<(char)i->y<<(uint8)0;
				}
			}
		}
	}
	m_socketServer.SendMsg(sock,msg);
}

void CPackageDeal::GUAJI(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 flag = 0;
	CScene *pScene = pUser->GetScene();
	uint16 num = pUser->GetExtData16(9);
	if(pScene == NULL)
		return;
	msg>>flag;
	if(flag == 1)
	{
		if(num == 0)
			msg<<(uint8)0<<(uint8)0;	//次数为0
		else
		{
			if(pScene->GetMonsterNum() == 0)	//场景不符
				msg<<(uint8)0<<(uint8)1;
			else
			{
				msg<<(uint8)1;		//挂机成功
			}
		}
	}
	else
	{
		msg<<(uint8)0;
	}
	m_socketServer.SendMsg(sock,msg);
}

void CPackageDeal::QueryScene(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER
	
	uint16 sceneId = 0;
	msg>>sceneId;
	char name[32];
	snprintf(name,sizeof(name),"dat/%d.map",sceneId);
	if(access(name,R_OK) != 0)
	{
		// This checkout stores local map data as dat/map<ID>.map.
		// Keep the legacy production path first and use the repository naming as fallback.
		snprintf(name,sizeof(name),"dat/map%d.map",sceneId);
		if(access(name,R_OK) != 0)
			return;
	}
	FILE *file = fopen(name,"r");
	if(file == NULL)
		return;
	const int MAX_MAP_SIZE = 1024*4;
	char buf[MAX_MAP_SIZE];
	int len = fread(buf,1,MAX_MAP_SIZE,file);
	fclose(file);
	msg.WriteData(buf,len);
	m_socketServer.SendMsg(pUser->GetSock(),msg);
}

void CPackageDeal::QueryItem(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER
	uint16 itemId = 0;
	msg>>itemId;
	if(itemId == 0)
		return;
	CItemTemplateManager &itemMgr = SingletonItemManager::instance();
	SItemTemplate *pItem = itemMgr.GetItem(itemId);
	if(pItem == NULL)
		return;
	msg<<pItem->type<<pItem->level<<(uint8)0<<pItem->name<<pItem->pic;
	m_socketServer.SendMsg(pUser->GetSock(),msg);
}

void CPackageDeal::HeartBeat(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER
//	if(pUser->HaveBitSet(0))
//		return;
//	cout<<pUser->GetRoleId()<<" "<<GetSysTime()<<endl;
	const uint8 limitTimes = 12;	// 正常1分钟6次
	uint8 times = pUser->GetHeartTimes();
	if(times == limitTimes)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_1263,TIPS_FAILURE_COLOR).c_str());
	}
	else if(times > limitTimes)
	{
		pUser->SetHeartTimes(0);
		SingletonSocket::instance().CloseConnect(sock);
		return;
	}
	if(GetSysTime() - pUser->GetLastHeartTime() > 60)
	{
		pUser->SetLastHeartTime(GetSysTime());
		if(times > limitTimes)
		{
			SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_1264,TIPS_FAILURE_COLOR).c_str());
			SingletonSocket::instance().CloseConnect(sock);
			return;
		}
		pUser->SetHeartTimes(0);
	}
	else
	{
		pUser->SetHeartTimes((uint8)(times+1));
	}
	msg.ReWrite();
	msg.SetType(MSG_SERVER_HEART_BEAT);
	msg<<250;
	m_socketServer.SendMsg(pUser->GetSock(),msg);
}

void CPackageDeal::GooglePlayRestult(CNetMessage *pMsg,int sock)
{
/*
	//base64	key=?&orderId=?&money=?		key=?&oderString=?&money=?
	//md5		orderId|money|role_id
	GET_MSG
	GET_USER
	const string key = "kaQtg99qMsPv35ks9xOwsaq718akKloO";
	string strBase64,strMd5;
	char key_t[64],orderId[128],money[16];
	msg>>strBase64>>strMd5;

	char strBase64Decode[1024];
	int len = sizeof(strBase64Decode);
	char *cur=NULL;
	char *temp=NULL;
	if(base64_decode((unsigned char*)strBase64Decode,(size_t *)&len,(const unsigned char*)strBase64.c_str(),strBase64.size()) != 0)
	{
		cout<<"GooglePlayRestult: base64_decode Error!"<<endl;
		return;
	}
	strBase64Decode[len] = '\0';
	cout<<"strBase64 = "<<strBase64<<endl<<"strMd5 = "<<strMd5<<endl;
	cout<<"strBase64Decode = "<<strBase64Decode<<endl;

	if((cur = strstr(strBase64Decode,"key=")) == NULL)
	{
		cout<<"GooglePlayRestult: base64 String Error!"<<endl;
		return;
	}
	cur += 4;
	if((temp = strstr(cur,"&")) == NULL)
	{
		cout<<"GooglePlayRestult: base64 String Error!"<<endl;
		return;
	}
	*temp = '\0';
	snprintf(key_t,sizeof(key_t),"%s",cur);
	if(key != key_t)
	{
		cout<<"GooglePlayRestult: Check key Error!"<<endl;
		return;
	}

	cur = temp+1;
	if((cur = strstr(cur,"orderId=")) == NULL)
	{
		cout<<"GooglePlayRestult: base64 String Error!"<<endl;
		return;
	}
	cur += 8;
	if((temp = strstr(cur,"&")) == NULL)
	{
		cout<<"GooglePlayRestult: base64 String Error!"<<endl;
		return;
	}
	*temp = '\0';
	snprintf(orderId,sizeof(orderId),"%s",cur);
//	if(orderId[20] != '.' || orderId[37] != '\0')
//	{
//		cout<<"GooglePlayRestult: base64 OrderId Error!"<<endl;
//		return;
//	}
	cur = temp+1;
	if((cur = strstr(cur,"money=")) == NULL)
	{
		cout<<"GooglePlayRestult: base64 String Error!"<<endl;
		return;
	}
	cur += 6;
	snprintf(money,sizeof(money),"%s",cur);

	char buf[1024];
	snprintf(buf,sizeof(buf),"%s|%s|%u",orderId,money,pUser->GetRoleId());
	string createMD5 = buf;
	MD5String(createMD5);
	if(createMD5 != strMd5)
	{
		cout<<"GooglePlayRestult: Check MD5 Error!"<<endl;
		return;
	}

	char sql[512];
	char msg_info[256];
//	snprintf(msg_info,sizeof(msg_info),"支付成功，订单号:%s,获得魔宝%s",orderId,money);
	snprintf(msg_info,sizeof(msg_info),LANGUAGE_TRANSFORM_1265,money);
	snprintf(sql,sizeof(sql),"insert into cz_complete (user_id,role_id,role_name,role_level,type,card_num,money,state,time,err_msg) VALUES (%u,%u,'%s',%d,101,'%s','%s',0,FROM_UNIXTIME('%u'),'%s')",
		pUser->GetUserId(),pUser->GetRoleId(),pUser->GetName(),pUser->GetLevel(),orderId,money,(uint32)GetSysTime(),msg_info);

	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
	if(!pDb->Query(sql))
	{
		cout<<"sql error! "<<sql<<endl;
		return;
	}
*/
}

void CPackageDeal::ClientNetCheck(CNetMessage *pMsg,int sock)
{
	GET_MSG
	m_socketServer.SendMsg(sock,msg);
}

void CPackageDeal::GetTitleList(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	msg.ReWrite();
	msg.SetType(PRO_GET_TITLE_LIST);
	pUser->GetTitleMsg(msg);
	m_socketServer.SendMsg(pUser->GetSock(),msg);
}

void CPackageDeal::TitleOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 op = 2;	// 2设置显示称号 3使用称号
	uint16 useTitle = 0;
	msg>>op>>useTitle;
	// op = 0 增加称号
	// op = 1 删除称号
	if(op == 2)	// 显示称号
	{
		uint8 show = 0;	// 0不显示 1显示
		msg>>show;
		pUser->SetViewTitle(useTitle,show,&msg);
		m_socketServer.SendMsg(sock,msg);
	}
	else if(op == 3)	// 使用称号
	{
		uint8 use = 0;	// 0不使用 1使用
		msg>>use;
		pUser->SetUseTitle(useTitle,use,&msg);
		m_socketServer.SendMsg(sock,msg);
	}
}

void CPackageDeal::DelRole(CNetMessage *pMsg,int sock)
{
	GET_MSG

	ShareUserPtr ptr = m_onlineUser.GetUserBySock(sock);
	CUser *pUser = ptr.get();
	if(pUser == NULL)
		return;

	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;

	uint32 roleId = 0;
	string checkName;
	msg>>roleId>>checkName;
	uint32 userId = pUser->GetUserId();

	msg.ReWrite();
	msg.SetType(MSG_CLIENT_DEL_CHAR);

	char sql[128];
	char **row = NULL;
	if(roleId == 0)
	{
		msg<<PRO_ERROR<<LANGUAGE_TRANSFORM_1323;
		m_socketServer.SendMsg(sock,msg);
		return;
	}
	snprintf(sql,sizeof(sql),"select name from role_info where id=%d",roleId);
	if(!pDb->Query(sql))
		return;
	if((row = pDb->GetRow()) == NULL || row[0] == NULL)
		return;
	if(checkName == row[0])
	{
		string userTab = GetUserInfoTab(pUser->GetServerId());
		snprintf(sql,sizeof(sql),"select role0 from %s where id=%u",userTab.c_str(),userId);
		if(!pDb->Query(sql))
			return;
		if((row = pDb->GetRow()) == NULL || row[0] == NULL)
			return;
		if((uint32)atoi(row[0]) != roleId)
		{
			msg<<PRO_ERROR<<LANGUAGE_TRANSFORM_1324;
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		snprintf(sql,sizeof(sql),"update %s set role0=0 where id=%u and role0=%u",userTab.c_str(),userId,roleId);
		if(pDb->Query(sql))
		{
			msg<<PRO_SUCCESS;
			m_socketServer.SendMsg(sock,msg);
			return;
		}
	}
	msg<<PRO_ERROR<<LANGUAGE_TRANSFORM_1325;
	m_socketServer.SendMsg(sock,msg);
}

void CPackageDeal::ServerMgr(CNetMessage *pMsg,int sock)
{
	GET_MSG

	ShareUserPtr ptr = m_onlineUser.GetUserBySock(sock);
	CUser *pUser = ptr.get();

	sockaddr_in addr;
	socklen_t len = sizeof(addr);
	getpeername(sock, (sockaddr*)&addr,&len);
//	if(!AllowIp(addr.sin_addr.s_addr))
//	{
//		if((pUser == NULL) || (pUser->GetRoleId() == 0))
//			return;
//	}

	char sql[512];
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;

	uint16 type = 0;//管理类型
	string retMsg;
	msg>>type;
	switch(type)
	{
		case 1://加通宝
			{
				if(pUser == NULL || pUser->AdminLevel() != ADMIN_LEVEL)
					return;
				uint32 roleId = 0;
				int tongbao = 0;
				uint8 bangDing = 0;
				msg>>roleId>>tongbao>>bangDing;
				AddTongBao(roleId,tongbao,bangDing);
				ItemCurrencyLog(roleId,bangDing,0,0,-tongbao,pUser->GetTongBao(),YBL_JIATONGBAO);
				WriteAdminLog(pUser->GetRoleId(),LANGUAGE_TRANSFORM_1332,roleId,tongbao);
				retMsg = LANGUAGE_TRANSFORM_1333;
			}
			break;
		case 2://加物品
			{
				if(pUser == NULL || pUser->AdminLevel() != ADMIN_LEVEL)
					return;
				uint32 roleId = 0;
				uint16 tmplId = 0;
				uint8 num = 0;
				uint8 level = 0;
				msg>>roleId>>tmplId>>num>>level;
				if(num == 0)
				{
					return;
				}
				CItemTemplateManager &itemMgr = SingletonItemManager::instance();
				SItemTemplate *pItem = itemMgr.GetItem(tmplId);
				if(pItem == NULL)
				{
					retMsg = LANGUAGE_TRANSFORM_1334;
				}
				else
				{
					SItemInstance item;
					item.tmplId = tmplId;
					item.num = num;
					item.level = level;
					if(AddPackage(roleId,item))
					{
						retMsg = LANGUAGE_TRANSFORM_1335;
						if(pUser != NULL)
							WriteAdminLog(pUser->GetRoleId(),LANGUAGE_TRANSFORM_1336,roleId,level,tmplId,num);
						else
							WriteAdminLog(0,LANGUAGE_TRANSFORM_1337,roleId,level,tmplId,num);
					}
					else
					{
						retMsg = LANGUAGE_TRANSFORM_1338;
					}
				}
			}
			break;
		case 3://踢下线，并且封号
			{
//				if(pUser == NULL)
//					return;
				uint32 roleId = 0;
				msg>>roleId;
				ShareUserPtr p = m_onlineUser.GetUserByRoleId(roleId);
				if(p.get() != NULL)
				{
					shutdown(p->GetSock(),SHUT_RD);
				}

				snprintf(sql,sizeof(sql),"update role_info set state=2 where id=%d",roleId);
				pDb->Query(sql);
				retMsg = LANGUAGE_TRANSFORM_1339;

				snprintf(sql,sizeof(sql),LANGUAGE_TRANSFORM_1340,roleId);
				pDb->Query(sql);
			}
			break;
		case 4://解封
			{
//				if(pUser == NULL)
//					return;
				uint32 roleId = 0;
				msg>>roleId;
				snprintf(sql,sizeof(sql),"update role_info set state=0 where id=%d",roleId);
				pDb->Query(sql);
				retMsg = LANGUAGE_TRANSFORM_1341;

				snprintf(sql,sizeof(sql),LANGUAGE_TRANSFORM_1342,roleId);
				pDb->Query(sql);
				break;
			}
		case 5://修改等级
			{
				if(pUser == NULL || pUser->AdminLevel() != ADMIN_LEVEL)
					return;
				uint32 roleId = 0;
				uint8 level = 0;
				msg>>roleId>>level;
				retMsg = LANGUAGE_TRANSFORM_1343;
				ShareUserPtr p = m_onlineUser.GetUserByRoleId(roleId);
				if(p.get() != NULL)
				{
					p->SetLevel(level);
					break;
				}
				snprintf(sql,sizeof(sql),"update role_info set level=%d where id=%d",level,roleId);
				pDb->Query(sql);

				snprintf(sql,sizeof(sql),LANGUAGE_TRANSFORM_1344,roleId,(int)level);
				pDb->Query(sql);
			}
			break;
		case 6:
			{
//				if(pUser == NULL)
//					return;
				uint32 roleId = 0;
				uint16 bitset = 0;
				msg>>roleId>>bitset;
				SetBitSet(roleId,bitset,true);
				retMsg = LANGUAGE_TRANSFORM_1345;

				snprintf(sql,sizeof(sql),LANGUAGE_TRANSFORM_1346,roleId,bitset);
				pDb->Query(sql);
			}
			break;
		case 7:
			{
//				if(pUser == NULL)
//					return;
				uint32 roleId = 0;
				uint16 bitset = 0;
				msg>>roleId>>bitset;
				SetBitSet(roleId,bitset,false);
				retMsg = LANGUAGE_TRANSFORM_1347;

				snprintf(sql,sizeof(sql),LANGUAGE_TRANSFORM_1348,roleId,bitset);
				pDb->Query(sql);
			}
			break;
		case 8:
			{

			}
			break;
		case 9:
			{

			}
			break;
		case 10:
			{
				if(pUser == NULL)
					return;
				string info;
				msg>>info;
				SendSysChannelMsg(info.c_str());
				retMsg = LANGUAGE_TRANSFORM_1351;
			}
			break;
		case 11:
			{
				if(pUser == NULL)
					return;
				uint32 userId;
				string pwd;
				msg>>userId>>pwd;
				char buf[256];
				snprintf(buf,sizeof(buf),"select userId,pwd from admin where userID='%u' and pwd=MD5('%s')",userId,pwd.c_str());
				pDb->Query(buf);

				char **row;
				msg.ReWrite();
				msg.SetType(MSG_MGR);
				if((row = pDb->GetRow()) != NULL)
				{
					pUser->SetAdminLevel(ADMIN_LEVEL);
					msg<<(uint8)2<<(uint8)1;		//success
				}
				else
					msg<<(uint8)2<<(uint8)2<<LANGUAGE_TRANSFORM_1352;		//fail
				m_socketServer.SendMsg(sock,msg);
				return;
			}
			break;
		case 12:
			{
				if(pUser == NULL)
					return;
				string user_name;
				string oldpwd;
				string newpwd;
				msg>>user_name>>oldpwd>>newpwd;
				char buf[256];
				snprintf(buf,sizeof(buf),"select name,pwd from admin where name='%s' and pwd=MD5('%s')",user_name.c_str(),oldpwd.c_str());
				pDb->Query(buf);

				char **row;
				msg.ReWrite();
				msg.SetType(MSG_MGR);
				if((row = pDb->GetRow()) != NULL)
				{
					snprintf(buf,sizeof(buf),"update admin set pwd=MD5('%s') where name='%s'",newpwd.c_str(),user_name.c_str());
					pDb->Query(buf);
					snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1353,newpwd.c_str());
					msg<<(uint8)3<<(uint8)1<<buf;	//success
				}
				else
					msg<<(uint8)3<<(uint8)2<<LANGUAGE_TRANSFORM_1354;
				m_socketServer.SendMsg(sock,msg);
				return;
			}
			break;
		case 13:
			{
				string sql;
				msg>>sql;
				if(sql.size() > 0)
					pDb->Query(sql.c_str());
				return;
			}
			break;
		case 14:
			{
				string info;
				msg>>info;
				retMsg = LANGUAGE_TRANSFORM_1355;
				SysInfoToAllUser(info.c_str());
			}
			break;
		case 15:
			{
				uint32 roleId = 0;
				uint16 itemId = 0;
				int num = 0;
				int money = 0;
				int YB = 0;
				string message;
				msg>>roleId>>itemId>>num>>money>>YB>>message;

				SMailData mdata;
				mdata.AddAward(itemId, 0, num);
				mdata.AddAward(HDAT_MONEY, 0, money);
				mdata.AddAward(HDAT_YB, 0, YB);
				SendSystemMail(roleId, message.c_str(), &mdata);

				char buf[512];
				snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_1356, roleId, itemId, num, money, YB);
				pDb->Query(buf);
			}
			break;
		case 16: // 系统邮件所有在线玩家
			{
				string message;
				msg>>message;
				if (message.length() == 0)
					return;
				SysMailToAllUser(message.c_str());
			}
			break;
		case 17: // 系统邮件通知
			{
				uint32 roleId = 0;
				msg>>roleId;
				if (roleId == 0)
					return;
				ShareUserPtr userPtr = m_onlineUser.GetUserByRoleId(roleId);
				CUser *pU = userPtr.get();
				if(pU == NULL)
					return;
				SendHotPointStatus(pU, EHPoint_Mail, EHPointS_Show);
			}
			break;
		case 18:	// 添加妖石
			{
				uint32 roleId = 0;
				int addValue = 0;
				msg>>roleId>>addValue;

				if(roleId == 0 || addValue == 0)
					return;
				ShareUserPtr p = m_onlineUser.GetUserByRoleId(roleId);
				CUser *pU = p.get();
				if(pU != NULL)
				{
					pU->SetExtData32(407,(int)pU->GetExtData32(407)+addValue);
				}
				else
				{
					pU = new CUser;
					if(pU->ReadDataSimple(roleId))
					{
						pU->SetExtData32(407,(int)pU->GetExtData32(407)+addValue);
						pU->SaveDataSimple();
					}
					delete pU;
					pU = NULL;
				}
			}
			break;
		case 19:	// 获取邮件物品信息编码
			{
				uint8 num = 0;
				msg>>num;

				SMailData mdata;
				for(uint8 i=0;i < num;i++)
				{
					uint16 type = 0;
					uint32 id = 0;
					uint32 num = 0;
					msg>>type>>id>>num;
					if(type == 0 || num == 0)
						continue;

					SAwardData t;
					t.type = type;
					t.typeId = id;
					t.num = num;
					mdata.awards.push_back(t);
				}
				MakeMailAttachStr(retMsg,&mdata);
			}
			break;
		case 20:	// 设置禁言时间
			{
				uint8 op = 0;	// 1 设置禁言 2 取消禁言
				uint32 roleId = 0;
				msg>>roleId>>op;
				if(roleId == 0)
				{
					retMsg = "roleId error";
					break;
				}
				if(op == 1)
				{
					int addhour = 0;	// 小时
					msg>>addhour;
					
					uint32 t = 0;
					ShareUserPtr pU = m_onlineUser.GetUserByRoleId(roleId);
					if(pU.get() == NULL)	// 离线
						t = GetUserChatTime(roleId);
					else
						t = pU->GetChatTime();
					uint32 curtime = GetSysTime();
					if(t > curtime)
						t += addhour * 3600;
					else
						t = curtime + (uint32)(addhour * 3600);
					if(pU.get() == NULL)
						UpdateUserChatTime(roleId, t);
					else
						pU->SetChatTime(t);
					snprintf(sql, sizeof(sql), LANGUAGE_SSJ_0534, addhour);
					retMsg = sql;
				}
				else if(op == 2)
				{
					ShareUserPtr pU = m_onlineUser.GetUserByRoleId(roleId);
					if(pU.get() == NULL)	// 离线
						UpdateUserChatTime(roleId, 0);
					else
						pU->SetChatTime(0);
					retMsg = LANGUAGE_SSJ_0535;
				}
			}
			break;
		default:
			break;
	}
	
	msg.ReWrite();
	msg.SetType(MSG_MGR);
	msg<<type<<retMsg;
	m_socketServer.SendMsg(sock,msg);
}

void CPackageDeal::WriteAdminLog(uint32 roleId,const char *fmt, ...)
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb != NULL)
	{
		va_list ap;
		va_start(ap, fmt);
		char msg[512];
		vsnprintf(msg,sizeof(msg),fmt,ap);
		va_end (ap);
		char buf[1024];
		snprintf(buf,sizeof(buf),"INSERT INTO admin_log (role_id,msg) VALUES(%u,'%s')",roleId,msg);
		pDb->Query(buf);
	}
}

void CPackageDeal::XinShi(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER
	// CHECK_SYSTEM_OPEN(SOT_SocialMail)

	uint8 type = 0;	// 1 寄信，2列表，3收信，4删除，5新邮件通知
	msg>>type;

	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;

	char sql[512];
	//邮寄费=邮寄金币*1%+每格道具3000
	if(type == 1) // 寄信
	{
		uint32 chatLimit = pUser->GetChatTime();
		uint32 curtime = GetSysTime();
		if(chatLimit > 0 && chatLimit > curtime)
			return;
	
		msg>>type;
		if(GetSysTime() - pUser->GetLastSendMailTime() <= 3)
			return;
		else
			pUser->UpdateSendMailTime();

		uint32 roleId = 0;
		string roleName;
		if(type == 0)
		{
			msg>>roleId;
			char name[MAX_NAME_LEN] = {0};
			if (roleId == 0)
			{
				roleName = LANGUAGE_TRANSFORM_1358;
			}
			else
			{
				GetRoleName(roleId,name);
				roleName = name;
			}
		}
		else if(type == 1)
		{
			msg>>roleName;
			uint8 level;
			if (strcmp(roleName.c_str(),LANGUAGE_TRANSFORM_1359) == 0)
			{
				roleId = 0;
				level = 0;
			}
			else
			{
				roleId = GetRoleId(roleName.c_str(),level);
				if (roleId == 0)
				{
					MakeXinShiError(LANGUAGE_TRANSFORM_1360,msg);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
			}
		}

		char pos1,pos2,pos3 = -1;
		uint8 num1,num2,num3;
		int money;
		string strMsg;
		msg>>pos1>>num1>>pos2>>num2>>pos3>>num3>>money>>strMsg;
		
		msg.ReWrite();
		msg.SetType(MSG_SERVER_XINSHI);
		msg<<(uint8)1;
		if((roleName.size() <= 0))
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1361,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(roleId > 0)
		{
			if(SingletonCFriendMgr::instance().IsInBlackList(pUser->GetRoleId(), roleId))
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1362,TIPS_FAILURE_COLOR);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				return;
			}
			else
			{
				ShareUserPtr tarUser = m_onlineUser.GetUserByRoleId(roleId);
				if(tarUser.get() != NULL)
				{
					if(SingletonCFriendMgr::instance().IsInBlackList(tarUser->GetRoleId(), pUser->GetRoleId()))
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1363,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						return;
					}
				}
				else
				{
					if(SingletonCFriendMgr::instance().IsInBlackList(roleId, pUser->GetRoleId()))
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1364,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						return;
					}
				}
			}
		}

		msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_TRANSFORM_1379,TIPS_WARNING_COLOR);
		m_socketServer.SendMsg(pUser->GetSock(),msg);

		SendMailToUser(pUser->GetRoleId(),pUser->GetName(),roleId,strMsg.c_str());
		return;
	}
	else if (type == 2) // 获取邮件列表
	{
		if(gyu::util::CIniFile::GetValue("local_test","server",gConfigFile) == "1")
		{
			snprintf(sql, sizeof(sql),
				"select id,from_id,from_name,unix_timestamp(time)+%u,message,attachment "
				"from xin_shi where deleted=0 and to_id=%u and unix_timestamp(time)>%u order by id desc limit 30",
				(uint32)Mail_Time_Limit, pUser->GetRoleId(), (uint32)(GetSysTime()-Mail_Time_Limit));
			if(!pDb->Query(sql))
				return;
			uint8 count = (uint8)pDb->GetRowNum();
			msg.ReWrite();
			msg.SetType(MSG_SERVER_XINSHI);
			msg<<(uint8)2<<count;
			char **row = NULL;
			while((row = pDb->GetRow()) != NULL)
			{
				msg<<(uint32)atoi(row[0])<<(uint32)atoi(row[1])<<(row[2] == NULL ? "" : row[2])
					<<(uint32)atoi(row[3])<<(row[4] == NULL ? "" : row[4]);
				MultiAward awards;
				if(row[5] != NULL && strlen(row[5]) > 2)
				{
					uint8 pBuf[4096];
					uint32 pos = 0;
					uint32 bufLen = StrToHex(row[5], pBuf, sizeof(pBuf));
					uint8 awardNum = pos < bufLen ? pBuf[pos++] : 0;
					for(uint8 i=0; i<awardNum && pos <= bufLen; ++i)
					{
						SAwardData award;
						ReadDataFromBuf((char *)pBuf, &award.type, sizeof(award.type), pos, bufLen);
						ReadDataFromBuf((char *)pBuf, &award.typeId, sizeof(award.typeId), pos, bufLen);
						ReadDataFromBuf((char *)pBuf, &award.num, sizeof(award.num), pos, bufLen);
						if(pos <= bufLen) awards.push_back(award);
					}
				}
				MakeMultiAwardMsg(awards, msg);
			}
			m_socketServer.SendMsg(pUser->GetSock(),msg);
		}
		else
			ListXinShi(pUser);
	}
	else if(type == 3) // 收信
	{
		uint32 id = 0;
		uint8 clientUse = 0;
		msg>>id>>clientUse;
		//                          0   1   2      3        4    5     6           7             8
		snprintf(sql,sizeof(sql),"select money,YB,bdYB,attachment,from_id,to_id,gmtime,unix_timestamp(time),shenhun from xin_shi where deleted=0 and id=%u and to_id=%u",id,pUser->GetRoleId());
		if(!pDb->Query(sql))
			return;

		msg.ReWrite();
		msg.SetType(MSG_SERVER_XINSHI);
		msg<<(uint8)3<<id<<clientUse;
		char **row = pDb->GetRow();
		if(row == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor("邮件不存在或已处理",TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		// CEquipManeger& peMgr = pUser->GetPetEquipMgr();
		if (GetSysTime() - (time_t)atoi(row[7]) > Mail_Time_Limit)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1380,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(pUser->GetMoney() + atoi(row[0]) > CUser::MAX_MONEY)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_1005,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		if((int)pUser->GetShenhun() + atoi(row[8]) > CUser::MAX_SHEN_HUN)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_1015,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		
		// 添加物品和神将
		if(row[3] != NULL && strlen(row[3]) > 2)
		{
			uint8 pBuf[4096];
			uint32 pos = 0;
			uint32 bufLen = StrToHex(row[3],pBuf,sizeof(pBuf));
			uint8 num = pBuf[pos++];
			for(uint8 i=0;i < num;i++)
			{
				SAwardData award;
				ReadDataFromBuf((char *)pBuf, &award.type, sizeof(award.type), pos, bufLen);
				ReadDataFromBuf((char *)pBuf, &award.typeId, sizeof(award.typeId), pos, bufLen);
				ReadDataFromBuf((char *)pBuf, &award.num, sizeof(award.num), pos, bufLen);
				pUser->AddMaterial(award);
			}
		}
		snprintf(sql, sizeof(sql), "update xin_shi set deleted=1 where id=%u and to_id=%u", id, pUser->GetRoleId());
		pDb->Query(sql);
		msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_TRANSFORM_1383,TIPS_WARNING_COLOR);
		m_socketServer.SendMsg(pUser->GetSock(),msg);
	}
	else if(type == 4) // 已读无附件邮件并从服务端待领取列表移除
	{
		uint32 id = 0;
		uint8 clientUse = 0;
		msg>>id>>clientUse;

		msg.ReWrite();
		msg.SetType(MSG_SERVER_XINSHI);
		msg<<(uint8)4<<id<<clientUse;

		snprintf(sql,sizeof(sql),"select id from xin_shi where deleted=0 and id=%u and to_id=%u",id,pUser->GetRoleId());
		if(!pDb->Query(sql))
			return;
		if(pDb->GetRow() == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor("邮件不存在或已处理",TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}

		snprintf(sql,sizeof(sql),"update xin_shi set deleted=1 where id=%u and to_id=%u",id,pUser->GetRoleId());
		if(!pDb->Query(sql))
		{
			msg<<PRO_ERROR<<MakeStringColor("邮件状态更新失败",TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_TRANSFORM_1383,TIPS_WARNING_COLOR);
		m_socketServer.SendMsg(pUser->GetSock(),msg);
	}
}

void CPackageDeal::ServerXinShi(CNetMessage *pMsg,int sock)
{
	GET_MSG
	
    if(!m_socketServer.IsServer(sock))
		return;
	int roleId;
	uint8 op;
	uint8 num;
	msg>>roleId>>op;

	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	ShareUserPtr ptr = onlineUser.GetUserByRoleId(roleId);
	CUser *pUser = ptr.get();
    if(!pUser)
		return;

	if(op == 1)
	{
		SendHotPointStatus(pUser, EHPoint_Mail, EHPointS_Show);
	}
	else if(op == 2)
	{
		msg>>num;

		vector<int> delList;
		uint32 curTime = GetSysTime();
		CNetMessage newmsg;
		newmsg.SetType(MSG_SERVER_XINSHI);
		newmsg<<(uint8)2<<num;
		for(int i=0;i<num;i++)
		{
			int id = 0;
			int fromId = 0;
			string fromName;
			int money = 0;
			int YB = 0;
			int bdYB = 0;
			int shenhun = 0;
			uint32 leftTime = 0;
			string attachment;
			string xinshimsg;
			msg>>id>>fromId;
			msg.ReadString(fromName);
			msg>>money>>YB>>bdYB>>shenhun>>leftTime;
			msg.ReadString(attachment);
			msg.ReadString(xinshimsg);

			uint32 t = curTime + leftTime;
			newmsg << id << fromId << fromName << t << xinshimsg;
			MultiAward awards;
			uint8 pBuf[4096];
			uint32 pos = 0;
			uint32 bufLen = StrToHex(attachment.c_str(), pBuf, sizeof(pBuf));
			uint8 awardNum = pBuf[pos++];
			for (int j = 0; j < awardNum; j++)
			{
				SAwardData award;
				ReadDataFromBuf((char *)pBuf, &award.type, sizeof(award.type), pos, bufLen);
				ReadDataFromBuf((char *)pBuf, &award.typeId, sizeof(award.typeId), pos, bufLen);
				ReadDataFromBuf((char *)pBuf, &award.num, sizeof(award.num), pos, bufLen);
				awards.push_back(award);
				if (pos > bufLen)
				{
					return;
				}
			}
			MakeMultiAwardMsg(awards, newmsg);

			if(awards.empty())
				delList.push_back(id);
		}
		m_socketServer.SendMsg(pUser->GetSock(),newmsg);

		if(!delList.empty())
		{
			CGetDbConnect getDb;
			CDatabaseSql *pDb = getDb.GetDbConnect();
			if(pDb == NULL)
				return;
			string sql = "update xin_shi set deleted=1 where id in (";
			for(uint16 i=0; i < delList.size(); i++)
			{
				int id = delList[i];
				if(i != 0)
					sql += ",";
				sql += IntToStr(id);
			}
			sql += ");";
			pDb->Query(sql.c_str());
		}
	}
}

void CPackageDeal::GuanZhan(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	if(pUser->GetKuaFuState() != EKFS_IN_LOCAL)
		return;
	uint32 roleId = 0;
	msg>>roleId;
	msg.ReWrite();
	msg.SetType(GUANZHAN_ENTER_BATTLE);

	if(pUser->GetFightId() != 0)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1387,TIPS_FAILURE_COLOR);
		m_socketServer.SendMsg(pUser->GetSock(),msg);
		return;
	}
	ShareUserPtr p = m_onlineUser.GetUserByRoleId(roleId);
	if(p.get() == NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1388,TIPS_FAILURE_COLOR);
		m_socketServer.SendMsg(pUser->GetSock(),msg);
		return;
	}
	if(p->GetScene() != pUser->GetScene())
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1389,TIPS_FAILURE_COLOR);
		m_socketServer.SendMsg(pUser->GetSock(),msg);
		return;
	}
	uint32 fightId = p->GetFightId();
	if(fightId == 0)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1390,TIPS_FAILURE_COLOR);
		m_socketServer.SendMsg(pUser->GetSock(),msg);
		return;
	}
	ShareFightPtr pFight = SingletonFightManager::instance().FindFight(fightId);
	if(pFight.get() == NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1391,TIPS_FAILURE_COLOR);
		m_socketServer.SendMsg(pUser->GetSock(),msg);
		return;
	}
	msg<<PRO_SUCCESS;
	m_socketServer.SendMsg(pUser->GetSock(),msg);
	pFight->GuanZhan(pUser);
	pUser->SetGuanZhan(fightId);
}

void CPackageDeal::LeaveGuanZhan(CNetMessage *pMsg,int sock)
{
	GET_USER

	uint32 fightId = pUser->GetGuanZhan();
	if(fightId == 0)
		return;

	ShareFightPtr pFight = SingletonFightManager::instance().FindFight(fightId);
	if(pFight.get() != NULL)
	{
		pFight->LeaveGuanZhan(pUser);
	}
}

void CPackageDeal::SetSaveVal(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 ind = 0;
	int val = 0;
	msg>>ind>>val;
	if(ind >= AUTO_USER_HP && ind <= AUTO_PET_MP)
		val -= AUTO_DEFAULT_HP_MP_SET;
	pUser->SetClientData(ind,val);
//	if(ind == AUTO_GUAJI)
//		UpdateUserInfo(pUser);
}

void CPackageDeal::GetSaveVal(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 ind = 0;
	uint8 flag = 0;
	uint8 i;
	int val;
	msg>>ind>>flag;
	if(flag == 0)
	{
		val = pUser->GetClientData(ind);
		if(ind >= AUTO_USER_HP && ind <= AUTO_PET_MP)
			val += AUTO_DEFAULT_HP_MP_SET;
		msg<<val;
	}
	else
	{
		for(i=0;i<ind;i++)
		{
			val = pUser->GetClientData(i);
			if(i >= AUTO_USER_HP && i <= AUTO_PET_MP)
				val += AUTO_DEFAULT_HP_MP_SET;
			msg<<val;
		}
	}
	m_socketServer.SendMsg(pUser->GetSock(),msg);
}

void CPackageDeal::ClientDataOperation(CNetMessage *pMsg, int sock)
{
	GET_MSG
	GET_USER

	uint8 op = 0;
	msg >> op;
	uint8 ind = 0;
	uint8 type = 0;
	string val = "";
	switch (op)
	{
	case 1: // 存
	{
		msg >> ind >> val;
		pUser->SetClientStrData(ind, val);
	}
	break;

	case 2: // 读
	{
		msg >> type;
		if (type == 1)
		{
			msg >> ind;
			val = pUser->GetClientStrData(ind);
			msg << val;
		}
		else if (type == 0)
		{
			map<uint8, string>& data = pUser->GetClientStrData();
			msg << (uint8)data.size();
			for (map<uint8, string>::iterator it = data.begin();
				it != data.end(); ++it)
			{
				msg << it->first << it->second;
			}
		}
	}
	break;

	}
	m_socketServer.SendMsg(pUser->GetSock(), msg);
}

void CPackageDeal::DOptionCallBack(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint32 id;
	msg>>id;
	pUser->DoptionCall(id);
}

void CPackageDeal::ArenaOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER
	CHECK_SYSTEM_OPEN(SOT_6)

#ifdef KUA_FU
	return;
#endif
	// CHECK_SYSTEM_OPEN(SOT_Arena)
	int fightCD=120;
	if(pUser->GetVipLevel()>=4)
		fightCD=0;
	uint8 op = 0xff;
	char sql[512];
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	CArenaManager &arenaManage = SingletonCArenaManager::instance();
	CSimpleRoleDataMgr &simpleMgr = SingletonCSimpleRoleDataMgr::instance();

	msg>>op;
	snprintf(sql,sizeof(sql),"ArenaOption op=%d",(int)op);
	gyu::util::TimePrint arenaTime(sql,sock);
	if(pDb == NULL)
		goto HError1;

	if(op == 0)		//挑战榜
	{
		uint8 type=0;
		msg>>type;		// 1普通2越级
		if(type != 1 && type != 2)
			return;
		
		do
		{
			ArenaPaiHangData data;
			bool res = arenaManage.GetUserData(pUser->GetRoleId(), data);
			if(res)
			{
				if (pUser->GetExtData32(ED32_JingJiZuiGaoMing) == 0)
					pUser->SetExtData32(ED32_JingJiZuiGaoMing, data.rank);
				if(pUser->GetExtData32(ED32_JingJiRand) == 0)
				{
					int interval = SingletonCArenaCfgMgr::instance().GetRandIntervalByRank(data.rank);
					pUser->SetExtData32(ED32_JingJiRand, interval);
				}

				list<ArenaPaiHangData> query;
				uint32 rank = (data.rank > CArenaManager::DefaultShowNum) ? (CArenaManager::DefaultShowNum) : data.rank;
				int interval = pUser->GetExtData32(ED32_JingJiRand);

				// 前10名
				for(uint32 i=1; i <= 10; i++)
				{
					ArenaPaiHangData tmp;
					if(!arenaManage.GetDataByRank(i, tmp))
						continue;
					query.push_back(tmp);
				}

				const int showNum = 5;		// 显示的成员数
				const int showBackNum = 2;	// 自己后面要显示的成员数
				uint32 otherRank = 0;
				// 可挑战前5名
				for(int i=0;i < showNum;i++)
				{
					otherRank = rank - interval * (showNum - i);
					if(otherRank <= 10)
						continue;
					ArenaPaiHangData other;
					if(!arenaManage.GetDataByRank(otherRank, other))
						continue;
					query.push_back(other);
				}

				if(data.rank > 10)
				{
					query.push_back(data); // 添加自己
				}

				// 后两名
				otherRank = 0;
				for(int i=0;i < showBackNum;i++)
				{
					otherRank = rank + i + 1;
					if(otherRank > CArenaManager::DefaultShowNum)
						continue;
					ArenaPaiHangData other;
					if(!arenaManage.GetDataByRank(otherRank, other))
						break;
					query.push_back(other);
				}

				if(query.empty())
					goto HError1;

				msg<<(uint8)PRO_SUCCESS;
				uint32 numPos = msg.GetDataLen();
				uint8 num = 0;
				msg<<num;
				for(list<ArenaPaiHangData>::iterator it = query.begin(); it != query.end(); it++)
				{
					ArenaPaiHangData &t = *it;
					if(t.type == EUT_Robot)
					{
						msg<<t.rank<<t.type<<t.roleId;
					}
					else
					{
						SRoleSimpleData r;
						if(!simpleMgr.GetRoleData(t.roleId, r))
							continue;
						msg<<t.rank<<t.type<<r.roleId<<r.name<<r.level<<r.power<<r.sex<<r.model<<r.vipLv;
					}
					num++;
				}
				msg.WriteData(numPos, &num, sizeof(num));
				msg<<(uint32)rank;

				msg << pUser->GetExtData16(ED16_69) << (uint16)pUser->GetExtData16(ED16_72) << pUser->GetArenaBuyNum() << (int)pUser->GetArenaJiFen();
				m_socketServer.SendMsg(sock, msg);
				return;
			}
			else	//  第一次开启竞技场，添加玩家信息
			{
				arenaManage.AddUser(pUser);
				res = arenaManage.GetUserData(pUser->GetRoleId(), data);
				if(res)
				{
//					if(pData->rank <= MOBAI_SHOW_NUM)
//						UpdateMoBaiData(MOBAI_SHOW_NUM);
					if (pUser->GetExtData32(ED32_JingJiZuiGaoMing) == 0)
						pUser->SetExtData32(ED32_JingJiZuiGaoMing, data.rank);
				}
				else
				{
					return;
				}
			}
		}while(1);
	}
	else if(op == 2)		//前20名信息
	{
		list<ArenaPaiHangData> query;
		for(uint32 i=1; i <= 30; i++)
		{
			ArenaPaiHangData tmp;
			if(!arenaManage.GetDataByRank(i, tmp))
				break;
			query.push_back(tmp);
		}

		if(query.empty())
			goto HError1;

		ArenaPaiHangData data;
		uint32 rank = 0;
		bool res = arenaManage.GetUserData(pUser->GetRoleId(), data);
		if (res)
			rank = (data.rank > CArenaManager::DefaultShowNum) ? (CArenaManager::DefaultShowNum) : data.rank;
		msg << (uint8)PRO_SUCCESS << rank;

		uint32 numPos = msg.GetDataLen();
		uint8 num = 0;
		msg<<num;
		for(list<ArenaPaiHangData>::iterator it = query.begin(); it != query.end(); it++)
		{
			ArenaPaiHangData &t = *it;
			if(t.type == EUT_Robot)
			{
				msg<<t.rank<<t.type<<t.roleId;
			}
			else
			{
				SRoleSimpleData r;
				if(!simpleMgr.GetRoleData(t.roleId, r))
					continue;
				msg<<t.rank<<t.type<<r.roleId<<r.name<<r.level<<r.power<<r.sex<<r.head<<r.jingJie<<r.vipLv<<r.bangpaiId<<r.bpName;
			}
			num++;
		}
		msg.WriteData(numPos, &num, sizeof(num));
		m_socketServer.SendMsg(sock, msg);
		return;
	}
	else if(op == 3)		//记录
	{
		QueryArenaLog(pUser);
		return;
	}
	else if(op == 4)		// 通知客户端重新请求竞技场数据
	{
		// 服务器主动推送
	}
	else if(op == 5)		//开始挑战
	{
		int tarRank = 0;
		uint32 tarRoleId = 0;
		uint8 tarRobot = 0;
		msg>>tarRank>>tarRoleId>>tarRobot;
		if(tarRank == 0 || tarRoleId == 0)
			return;
		ShareUserPtr ptr = SingletonOnlineUser::instance().GetUserByRoleId(pUser->GetRoleId());
		if(ptr.get() == NULL)
			goto HError2;
		if(pUser->GetTeam() != 0)
		{
			msg.ReWrite();
			msg.SetType(MSG_ARENA);
			msg<<(uint8)5<<(uint8)PRO_ERROR<<(uint8)0<<MakeStringColor(LANGUAGE_TRANSFORM_1396,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock, msg);
			return;
		}
		if(pUser->GetFightId() != 0)
			return;
		if(pUser->GetRoleId() == tarRoleId)
		{
			msg.ReWrite();
			msg.SetType(MSG_ARENA);
			msg<<(uint8)5<<(uint8)PRO_ERROR<<(uint8)0<<MakeStringColor(LANGUAGE_TRANSFORM_1398,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock, msg);
			return;
		}
		if(pUser->GetExtData16(ED16_69) == 0)
		{
			msg.ReWrite();
			msg.SetType(MSG_ARENA);
			msg<<(uint8)5<<(uint8)PRO_ERROR<<(uint8)0<<MakeStringColor(LANGUAGE_TRANSFORM_1399,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock, msg);
			return;
		}
		
		ArenaPaiHangData self;
		if(!arenaManage.GetUserData(pUser->GetRoleId(), self))
			return;
		ArenaPaiHangData other;
		if(!arenaManage.GetDataByRank(tarRank, other))
			return;
		if(other.roleId != tarRoleId || other.type != tarRobot)	// 数据已发生改变
		{
			CNetMessage nMsg;
			nMsg.SetType(MSG_ARENA);
			nMsg<<(uint8)4;
			m_socketServer.SendMsg(sock, nMsg);
			return;
		}

		if(other.rank <= 10 && self.rank > 30)
		{
			msg.ReWrite();
			msg.SetType(MSG_ARENA);
			msg << (uint8)5 << (uint8)PRO_ERROR << (uint8)0 << MakeStringColor(LANGUAGE_ZQX_0206, TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock, msg);
			return;
		}

		uint32 srcRank = self.rank;
		ShareUserPtr ptr2;
		ShareFightPtr pFight = SingletonFightManager::instance().CreateFight();
		pFight->SetFightType(CFight::EFTJingJiChang);
		if(other.type == EUT_Robot)	// 机器人
		{
			if(!SingletonCRobotMgr::instance().AddRobotToFight(pFight.get(), EROT_Arena, other.roleId))
			{
				msg.ReWrite();
				msg.SetType(MSG_ARENA);
				msg<<(uint8)5<<(uint8)PRO_ERROR<<(uint8)0<<MakeStringColor(LANGUAGE_TRANSFORM_1407,TIPS_FAILURE_COLOR);
				m_socketServer.SendMsg(sock, msg);
				return;
			}
		}
		else	// 玩家
		{
			CUser *tarUser = new CUser;
			if(tarUser == NULL)
				goto HError2;
			tarUser->SetSock(-1);
			if(!tarUser->CopyUserData(other.roleId))
			{
				delete tarUser;
				goto HError2;
			}
			tarUser->SetExtData8(85,0);
			ptr2.reset(tarUser);
			pFight->AddUserGroupToFight(ptr2, CFight::EGT_GROUP2);
		}
		pUser->SubMaterial(HDAT_ArenaCnt, 1);
		SaveDate(pUser, 33, 1);

		pUser->SetArenaTime((uint32)GetSysTime());
		pUser->CheckMissionHuoYueDu();
		pUser->SetExtData8(584,pUser->GetExtData8(584)+1);

		pFight->AddUserGroupToFight(ptr);
		SFastFightResult result;
		pFight->BeginFastFight(result, true, sock);
		int star = 0;
		if(result.win)
			star = pFight->CalculateFightStar(CFight::EGT_GROUP1, result.win);
		arenaManage.ArenaSaveData(pUser, self, other, result.win, star);

		if(result.win)
		{
			if(srcRank != self.rank)
				pUser->SetExtData32(ED32_JingJiRand, 0);
			sCMissionManager.UpdateQuestState(pUser, EMQCT_43, self.rank);
			if (self.rank <= 5 && self.rank < srcRank)
			{
				char buf[128];
				snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0240, pUser->GetName(), self.rank);
				SysInfoToAllUser(buf);
			}
		}
		arenaManage.SaveArenaLog(pFight.get(), self, other, result.win, srcRank);

		if(pUser->GetExtData8(620) < 0xff)
			pUser->SetExtData8(620,pUser->GetExtData8(620)+1);
		pUser->AddExtData16(ED16_72, 1);
		// ===========================
		// 更新挑战竞技场任务
		SingletonCMissionManager::instance().UpdateQuestState(pUser, EMQCT_9);
		if (other.type != EUT_Robot)
		{
			ShareUserPtr otherUser = m_onlineUser.GetUserByRoleId(other.roleId);
			if (otherUser.get() != NULL)
				SendHotPointStatus(otherUser.get(), EHPoint_BeiGongji, true);
		}
		return;
	}
	else if (op == 6)		// client请求播放动画
	{
		uint32 tarRoleId = 0;
		msg >> tarRoleId;
		if (tarRoleId == 0)
			return;
		ShareUserPtr ptr = SingletonOnlineUser::instance().GetUserByRoleId(pUser->GetRoleId());
		if (ptr.get() == NULL)
			goto HError2;
		if (pUser->GetTeam() != 0)
		{
			msg.ReWrite();
			msg.SetType(MSG_ARENA);
			msg << (uint8)5 << (uint8)PRO_ERROR << (uint8)0 << MakeStringColor(LANGUAGE_TRANSFORM_1396, TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock, msg);
			return;
		}
		if (pUser->GetFightId() != 0)
			return;
		if (pUser->GetRoleId() == tarRoleId)
		{
			msg.ReWrite();
			msg.SetType(MSG_ARENA);
			msg << (uint8)6 << (uint8)PRO_ERROR << (uint8)0 << MakeStringColor(LANGUAGE_TRANSFORM_1398, TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock, msg);
			return;
		}
		if (!pUser->SubMaterial(HDAT_ArenaCnt, 5))
		{
			msg.ReWrite();
			msg.SetType(MSG_ARENA);
			msg << (uint8)6 << (uint8)PRO_ERROR << (uint8)0 << MakeStringColor(LANGUAGE_TRANSFORM_1399, TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock, msg);
			return;
		}
		msg << PRO_SUCCESS << (uint8)5;
		AwardManager& amgr = sAwardManager;
		for (size_t i = 0; i < 5; i++)
		{
			MultiAward awwards;
			amgr.GetActivityDrop(pUser, 6, 1, awwards);
			SendAndMakeAwardMsg(pUser, awwards, msg, false, MUT_JingJiChang);
		}
		pUser->AddExtData16(ED16_72, 5);
		m_socketServer.SendMsg(sock, msg);
		// ===========================
		// 更新挑战竞技场任务
		SingletonCMissionManager::instance().UpdateQuestState(pUser, EMQCT_9, 5);
		return;
	}
	else if (op == 7)
	{
		uint32 uid;
		msg >> uid;
		CRobotMgr& mgr = SingletonCRobotMgr::instance();
		// 读机器人
		SRobotData robot;
		mgr.GetRobot(EROT_Arena, uid, robot);
		if (robot.id == 0)
			return;
		msg << robot.zhenfaId << robot.zhenfaLv << (uint8)5;
		for (size_t i = 0; i < 5; i++)
			msg << robot.monsterId[i];
		SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);
	}
	else if(op == 11)
	{
		int rank = arenaManage.GetUserRank(pUser->GetRoleId());
		if(rank == 0)
			return;

		vector<SAwardData> awvec;
		sAwardManager.GetRankAward(CRankMgr::ERT_Blood_Yesterday, rank, awvec);
		stringstream allmsg;
		stringstream awardStr;
		char head[256];
		char body[128];
		for (size_t i = 0; i < awvec.size(); ++i)
		{
			awardStr << GetItemName(awvec[i].type) << "*" << awvec[i].num;
			if (i < awvec.size() - 1)
			{
				awardStr << "，";
			}
		}
		snprintf(head, sizeof(head), LANGUAGE_ZQX_0045, rank, awardStr.str().c_str());
		allmsg << head;
		typeRankRewards* rewards = sAwardManager.GetAllRankAwards(CRankMgr::ERT_Blood_Yesterday);
		if (rewards == NULL || rewards->ranks.size() != rewards->rewards.size())
			return;

		for (size_t i = 0; i < rewards->ranks.size(); i++)
		{
			rankInterval& rk = rewards->ranks[i];
			if (rk.first == rk.second)
			{
				if (rk.first == 1)
					snprintf(body, sizeof(body), LANGUAGE_ZQX_0046, 4, rk.first);
				else if (rk.first == 2)
					snprintf(body, sizeof(body), LANGUAGE_ZQX_0046, 7, rk.first);
				else if (rk.first == 3)
					snprintf(body, sizeof(body), LANGUAGE_ZQX_0046, 2, rk.first);
				else
					snprintf(body, sizeof(body), LANGUAGE_ZQX_0047, rk.first);
			}
			else
			{
				snprintf(body, sizeof(body), LANGUAGE_ZQX_0048, rk.first, rk.second);
			}
			MultiAward& ra = rewards->rewards[i];
			stringstream bodyStr;
			for (size_t ai = 0; ai < ra.size(); ++ai)
			{
				bodyStr << GetItemName(ra[ai].type) << "*" << ra[ai].num;
				if (ai < ra.size() - 1)
				{
					bodyStr << "，";
				}
			}
			allmsg << body << bodyStr.str().c_str() << "|";
		}

		msg<< allmsg.str().c_str();
		m_socketServer.SendMsg(sock, msg);
		return;
	}
/*	else if(op == 12)
	{
		msg<<(uint8)(pUser->GetExtData32(25) > 0 ? 1 : 0);
		m_socketServer.SendMsg(pUser->GetSock(),msg);
		return;
	}
*/
	else if(op == 13)
	{
		int leftCount = (int)(pUser->GetArenaFightMaxNum() - pUser->GetExtData16(ED16_72));
		if(leftCount < 0)
			leftCount = 0;
		msg<<(uint8)leftCount;
		m_socketServer.SendMsg(sock, msg);
		return;
	}
	else if (op == 16)	// 全服前10记录
	{
		arenaManage.GetTopArenaFightData(msg);
		m_socketServer.SendMsg(sock, msg);
		return;
	}

HError1:
	msg<<(uint8)PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1406,TIPS_FAILURE_COLOR);
	m_socketServer.SendMsg(sock, msg);
	return;
HError2:
	msg.ReWrite();
	msg.SetType(MSG_ARENA);
	msg<<(uint8)5<<(uint8)PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1407,TIPS_FAILURE_COLOR);
	m_socketServer.SendMsg(sock, msg);
	return;
}

void CPackageDeal::ServerArena(CNetMessage *pMsg,int sock)
{
	GET_MSG
	
    if(!m_socketServer.IsServer(sock))
		return;
	int roleId = 0;
	const int max_show_num = 10;
	uint8 op = 0xff;
	msg>>roleId>>op;
	
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	ShareUserPtr ptr = onlineUser.GetUserByRoleId(roleId);
	CUser *pUser = ptr.get();
    if(!pUser) 
		return;
	if(op==3)
	{
		uint8 num = 0;
		msg>>num;
		CNetMessage newmsg;
		newmsg.SetType(MSG_ARENA);
		newmsg << (uint8)op << (uint8)PRO_SUCCESS << num;
		for (int i = 0; i < num && i < max_show_num; i++)
		{
			ArenaFightData data;
			uint8 jingJie = 0;
			msg >> data.fightData;
			msg >> data.l_roleId >> data.l_type;
			msg.ReadString(data.l_Name);
			msg >> data.l_Head >> data.l_VipLv >> data.l_Lv >> data.l_Power >> data.rank1;
			msg >> data.r_roleId >> data.r_type;

			jingJie = 0;
			msg.ReadString(data.r_Name);
			msg >> data.r_Head >> data.r_VipLv >> data.r_Lv >> data.r_Power >> data.rank2;
			msg >> data.state >> data.time;
			data.MakeMsg(newmsg);
		}
		m_socketServer.SendMsg(pUser->GetSock(),newmsg);
	}
}

void CPackageDeal::ClientLogOut(CNetMessage *pMsg,int sock)
{
	if(pMsg == NULL)
		return;
	SingletonSocket::instance().CloseConnect(sock);
}

void CPackageDeal::Get360Token(CNetMessage *pMsg,int sock)
{
	ShareUserPtr ptr = m_onlineUser.GetUserBySock(sock);
	CUser *pUser = ptr.get();
	if(pUser == NULL)
		return;
	pUser->Get360LoginInfo();
	time_t expiresTime = pUser->Get360ExpiresInTime();
	if(expiresTime == 0)
	{
		CNetMessage msg;
		msg.SetType(MSG_GET_360_TOKEN);
		msg<<(uint8)0;
		m_socketServer.SendMsg(sock,msg);
		return;
	}

/*	if (expiresTime < GetSysTime())
	{
		//cout << "Get360Token:Try360Token\n";
		if (mdCheckSock == 0)
		{
			CNetMessage msg;
			msg.SetType(MSG_GET_360_TOKEN);
			msg<<(uint8)0;
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		++mdCheckIndex;
		mdCheckIndexArr[sock] = mdCheckIndex;
		string refreshToken = "";
		pUser->Get360RefreshToken(refreshToken);
		CNetMessage msg;
		msg.SetType(PRO_USER_LOGIN_360);
		msg<<2<<mdCheckIndex<<sock<<refreshToken;
		m_socketServer.SendMsg(mdCheckSock,msg);
		return;
	}
*/

	Send360Token(pUser);
}

// 参数合理，向客户端发送token信息
void CPackageDeal::Send360Token(CUser *pUser)
{
	if(pUser == NULL)
		return;
	string accessToken;
	pUser->Get360AccessToken(accessToken);
	//cout << "Send360Token,360id:" << pUser->Get360Id() << ",accessToken:"<<accessToken<<",time:"<<pUser->Get360ExpiresInTime() << endl;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_GET_360_TOKEN);
	msg<<(uint8)1<<pUser->Get360Id()<<accessToken<<(int)pUser->Get360ExpiresInTime()<<pUser->GetServerId();
	sock.SendMsg(pUser->GetSock(),msg);
}

// 魔道2 金币副本 切换地图
int CPackageDeal::TryRiChangJinBiFuBenJump(CUser *pUser, SJumpTo* pJump)
{
	if ((pUser == NULL) || (pJump == NULL))
		return -1;
	CScene *pCur = pUser->GetScene();
	if(pCur == NULL)
		return -1;
	int curId = pCur->GetSrcSceneId();
	if (curId != COPY_ID_MONEY)
		return -1;

	int curNum = pCur->GetVisibleMonsterBossNum();
	if (curNum > 0)
	{
		SMessage(pUser,LANGUAGE_TRANSFORM_1419);
		return 1;
	}

	CScene *pNxt = NULL;
	int mapId = 0;
	int posX = 0;
	int posY = 0;
	if (curId == COPY_ID_MONEY) // 第一层
	{
		pNxt = m_sceneManager.Find2Scene(pCur->GetNextFuBenId(),pCur->GetGroupId());
		if (pNxt != NULL)
			mapId = pNxt->GetSrcSceneId();
		posX = 178;
		posY = 368;
	}

	if (pNxt == NULL)
		return -1;

	CNetMessage msg;
	msg.SetType(PRO_JUMP_SCENE);
	msg<<(uint16)mapId<<(uint16)posX<<(uint16)posY<<(uint8)0<<(uint8)0;
	m_socketServer.SendMsg(pUser->GetSock(),msg);
	pUser->SetPos(posX,posY);
	pUser->SetFace(0);
	pUser->EnterScene(pNxt);
	return 0;
}

// 魔道2 道具副本 切换地图
int CPackageDeal::TryRiChangDaoJuFuBenJump(CUser *pUser, SJumpTo* pJump)
{
	if ((pUser == NULL) || (pJump == NULL))
		return -1;
	CScene *pCur = pUser->GetScene();
	if(pCur == NULL)
		return -1;
	int curId = pCur->GetSrcSceneId();
	if (curId != COPY_ID_SHENG_JIE)
		return -1;

	int curNum = pCur->GetVisibleMonsterBossNum();
	if (curNum > 0)
	{
		SMessage(pUser,LANGUAGE_TRANSFORM_1420);
		return 1;
	}

	CScene *pNxt = NULL;
	int mapId = 0;
	int posX = 0;
	int posY = 0;
	if (curId == COPY_ID_SHENG_JIE) // 第一层
	{
		pNxt = m_sceneManager.Find2Scene(pCur->GetNextFuBenId(),pCur->GetGroupId());
		if (pNxt != NULL)
			mapId = pNxt->GetSrcSceneId();
		posX = 178;
		posY = 368;
	}
	else if (curId == COPY_ID_SHENG_JIE + 1) // 第二层
	{
		pNxt = m_sceneManager.Find2Scene(pCur->GetNextFuBenId(),pCur->GetGroupId());
		if (pNxt != NULL)
			mapId = pNxt->GetSrcSceneId();
		posX = 178;
		posY = 368;
	}
	else if (curId == COPY_ID_SHENG_JIE + 2) // 第三层
	{
		pUser->GetEnterPos(mapId,posX,posY);
		pNxt = m_sceneManager.FindScene(mapId);
	}

	if (pNxt == NULL)
		return -1;

	CNetMessage msg;
	msg.SetType(PRO_JUMP_SCENE);
	msg<<(uint16)mapId<<(uint16)posX<<(uint16)posY<<(uint8)0<<(uint8)0;
	m_socketServer.SendMsg(pUser->GetSock(),msg);
	pUser->SetPos(posX,posY);
	pUser->SetFace(0);
	pUser->EnterScene(pNxt);
	return 0;
}

// 魔道2 潜能副本 切换地图
int CPackageDeal::TryRiChangQianNengFuBenJump(CUser *pUser, SJumpTo* pJump)
{
	if ((pUser == NULL) || (pJump == NULL))
		return -1;
	CScene *pCur = pUser->GetScene();
	if(pCur == NULL)
		return -1;
	int curId = pCur->GetSrcSceneId();
	if (curId != COPY_ID_QIAN_NENG)
		return -1;

	int curNum = pCur->GetVisibleMonsterBossNum();
	if (curNum > 0)
	{
		SMessage(pUser,LANGUAGE_TRANSFORM_1421);
		return 1;
	}

	CScene *pNxt = NULL;
	int mapId = 0;
	int posX = 0;
	int posY = 0;
	if (curId == COPY_ID_QIAN_NENG) // 第一层
	{
		pNxt = m_sceneManager.Find2Scene(pCur->GetNextFuBenId(),pCur->GetGroupId());
		if (pNxt != NULL)
			mapId = pNxt->GetSrcSceneId();
		posX = 178;
		posY = 368;
	}
	else if (curId == COPY_ID_QIAN_NENG + 1) // 第二层
	{
		pUser->GetEnterPos(mapId,posX,posY);
		pNxt = m_sceneManager.FindScene(mapId);
	}

	if (pNxt == NULL)
		return -1;

	CNetMessage msg;
	msg.SetType(PRO_JUMP_SCENE);
	msg<<(uint16)mapId<<(uint16)posX<<(uint16)posY<<(uint8)0<<(uint8)0;
	m_socketServer.SendMsg(pUser->GetSock(),msg);
	pUser->SetPos(posX,posY);
	pUser->SetFace(0);
	pUser->EnterScene(pNxt);
	return 0;
}

void CPackageDeal::GetHuoYueDuRewardInfo(CUser *pUser,int huoYueDu)
{
	//char buf[128];
	CNetMessage msg;
	msg.SetType(MSG_DAILY_ACTIVITY);
	msg<<(uint8)2;
	const vitalityAIdMap& aids = SingletonAwardManager::instance().GetVitalityAIds();
	msg << PRO_SUCCESS;
	msg << (uint32)aids.size();// 阶段总数
	for (vitalityAIdMapCIt it = aids.begin(); it != aids.end(); ++it)
	{
		uint8 astate = 0;
		switch (it->first) {
		case 20:
			if (pUser->HaveBitSet(160))
				astate = 1;
			break;

		case 40:
			if (pUser->HaveBitSet(161))
				astate = 1;
			break;

		case 60:
			if (pUser->HaveBitSet(162))
				astate = 1;
			break;

		case 80:
			if (pUser->HaveBitSet(163))
				astate = 1;
			break;

		case 100:
			if (pUser->HaveBitSet(164))
				astate = 1;
			break;
		}
		msg << (uint8)astate; // 阶段领奖状态 0 未领奖 1已经领奖
		msg << it->first; // 阶段
		std::vector<SAwardData> awvec;
		SingletonAwardManager::instance().GetAwardById(it->second, awvec);
		msg << (uint32)awvec.size(); // 本阶段奖励的数量
		for (size_t j = 0; j < awvec.size(); j++)
		{
			msg << awvec[j].type;
			msg << awvec[j].num;
		}
	}

	m_socketServer.SendMsg(pUser->GetSock(), msg);
}

void CPackageDeal::CompleteHuoDong(CUser *pUser,uint16 huodongId,int &res,int &leftNum)
{
	res = 0;
	leftNum = 0;
	
	CCallScript *pCallScript = FindScript(200);
	if(pCallScript == NULL)
		return;
	pCallScript->Call("CompleteHuoDongWithYB","ui>ii",pUser,(int)huodongId,&res,&leftNum);
}

// 获取活跃度对应的礼包
void CPackageDeal::GetHuoYueDuReward(CUser *pUser, int huoYueDuIdx)
{
	CNetMessage msg;
	msg.SetType(MSG_DAILY_ACTIVITY);
	msg<<(uint8)3;
	CCallScript *pCallScript = FindScript(200);
	if(pCallScript == NULL){
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0473,TIPS_FAILURE_COLOR);
		m_socketServer.SendMsg(pUser->GetSock(),msg);
		return;
	}

	int huoYueDu = 0;
	char *huoYueDuInfo = NULL;
	pCallScript->Call("GetHuoYueDuInfo","u>is",pUser,&huoYueDu,&huoYueDuInfo);
	if (huoYueDuInfo == NULL){
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0473,TIPS_FAILURE_COLOR);
		m_socketServer.SendMsg(pUser->GetSock(),msg);
		return;
	}
	
	if(huoYueDu <= 0){
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0473,TIPS_FAILURE_COLOR);
		m_socketServer.SendMsg(pUser->GetSock(),msg);
		return;
	}
	if(huoYueDuIdx<20 || huoYueDuIdx >100){
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0473,TIPS_FAILURE_COLOR);
		m_socketServer.SendMsg(pUser->GetSock(),msg);
		return;
	}
	if(huoYueDuIdx == 20 ){
		if (pUser->HaveBitSet(160)){
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1424,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
	}
	if(huoYueDuIdx == 40 ){
		if (pUser->HaveBitSet(161)){
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1424,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
	}

	if(huoYueDuIdx == 60 ){
		if (pUser->HaveBitSet(162)){
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1424,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
	}

	if(huoYueDuIdx == 80 ){
		if (pUser->HaveBitSet(163)){
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1424,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
	}

	if(huoYueDuIdx == 100 ){
		if (pUser->HaveBitSet(164)){
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1424,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
	}


	std::vector<SAwardData> awvec;
	SingletonAwardManager::instance().SendVitalityAward(pUser, huoYueDuIdx, &msg);
	m_socketServer.SendMsg(pUser->GetSock(), msg);

	if(huoYueDuIdx == 20 ){
		pUser->SetBitSet(160);
	}
	if(huoYueDuIdx == 40 ){
		pUser->SetBitSet(161);
	}

	if(huoYueDuIdx == 60 ){
		pUser->SetBitSet(162);
	}

	if(huoYueDuIdx == 80 ){
		pUser->SetBitSet(163);
	}

	if(huoYueDuIdx == 100 ){
		pUser->SetBitSet(164);
	}
	//给予节日活动-彩带
	pUser->CheckFestivalDrop(2);
}

// 播放动画
void CPackageDeal::AnimationOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	int animationId = 0;
	msg>>animationId;

	CCallScript *pScript = GetScript();
	if(pScript != NULL)
		pScript->Call("CgCallBack","ui",pUser,animationId);
}

void CPackageDeal::XiuXianLiLianOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER
	// CHECK_SYSTEM_OPEN(SOT_XiuXianLiLian)
	uint8 op = 0;
	msg>>op;
	if(op == 0)
	{
		return;
	}
	else if(op == 1)	// 查询修仙历练信息
	{
		msg<<PRO_SUCCESS;
		pUser->MakeXiuXianMsg(msg);
		m_socketServer.SendMsg(sock,msg);
	}
	else if(op == 2)	// 战斗
	{
		uint16 index = 0;
		msg>>index;

		char buf[256];
		do
		{
			if(pUser->GetKuaFuState() != EKFS_IN_LOCAL)
				return;
			if(pUser->GetFightId() > 0)
			{
				snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0480);
				break;
			}
/*			if(pUser->GetTeam() == 0)
			{
				if(pUser->TempLeaveTeam() > 0)
					snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1442);
				else
					snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1443);
				break;
			}
*/
			if(pUser->GetTeam() > 0 && pUser->GetTeam() != pUser->GetRoleId())
			{
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1444);
				break;
			}
/*			if(GetTeamMemNum(pUser) < 2)
			{
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1445);
				break;
			}
*/
			if(!pUser->IsOpenXiuXianByIdx(index))
			{
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1446);
				break;
			}
			if (!pUser->CanFightXiuXianByIdx(index))
			{
				snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_1447);
				break;
			}

			CScene *pScene = pUser->GetScene();
			if(pScene == NULL)
				return;
			pScene->XiuXianTeamFight(ptr,index);
			msg<<PRO_SUCCESS<<"";
			m_socketServer.SendMsg(sock,msg);
			return;
		}while(0);
		msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
		m_socketServer.SendMsg(sock,msg);
	}
	else if(op == 3)	// 无用
	{

	}
	else if(op == 4)	// 更新修仙信息
	{
		// 服务器主动发送
	}
	else if(op == 5)	// 打开修仙界面
	{
		// 服务器主动发送
	}
}

const uint8 TONGTIANTA_MIN_LEVEL = 29;
void CPackageDeal::TongTianTa(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER
	// CHECK_SYSTEM_OPEN(SOT_TongTianTa)
	uint8 op = 0;	// 1 霸主显示 2 可用次数，奖励
	msg>>op;
	if(op == 0)
		return;

	const uint8 times = 1;
	if(op == 1)
	{

	}
	else if(op == 2)	// 霸主挑战面板
	{
		uint8 bazhuNum = sizeof(tongTianTaBaZhuFloor)/sizeof(tongTianTaBaZhuFloor[0]);
		msg.ReWrite();
		msg.SetType(MSG_SERVER_TONGTIANTA);
		msg<<pUser->GetRoleId();
		msg<<bazhuNum;
		for(uint8 i=0;i < bazhuNum;i++)
		{
			uint32 roleId = tongTianTaBaZhuData[i];
			msg<<roleId;
		}
		m_socketServer.SendServerMsg(EST_LONG, msg);
	}
	else if(op == 3)	// 通天塔怪战斗
	{
		CScene *pScene = pUser->GetScene();
		if(pScene == NULL)
			return;
		int res = pScene->TongTianTaFight(ptr);
		if(res < 0)
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1455,TIPS_FAILURE_COLOR);
		else if(res == 1)
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1456,TIPS_FAILURE_COLOR);
		else if(res == 2)
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1457,TIPS_FAILURE_COLOR);
		else if(res == 3)
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0478,TIPS_FAILURE_COLOR);
		else if(res == 4)
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0501,TIPS_FAILURE_COLOR);
		else if(res == 0)
			msg<<PRO_SUCCESS;
		else
			return;
		m_socketServer.SendMsg(pUser->GetSock(),msg);
	}
	else if (op == 4) // 扫荡
	{
		int roleTopFloor = pUser->GetExtData16(52);
		if (roleTopFloor == 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1459,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		int roleCurFloor = pUser->GetExtData16(51);
		if (roleCurFloor == roleTopFloor)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1460,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		msg<<PRO_SUCCESS;
		pUser->TongTianTaSaoDang(msg);
		m_socketServer.SendMsg(pUser->GetSock(), msg);
	}
	else if (op == 5) // 挑战霸主
	{
		uint8 bazhuIndex = 0xff;
		msg>>bazhuIndex;	// 0 ~ bazhuNum-1
		msg.ReWrite();
		msg.SetType(MSG_TONG_TIAN_TA);
		msg<<(uint8)op;

		uint8 bazhuNum = sizeof(tongTianTaBaZhuFloor)/sizeof(tongTianTaBaZhuFloor[0]);
		if(bazhuIndex > bazhuNum - 1)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1462,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}

		int roleTopFloor = pUser->GetExtData16(52);
		if(tongTianTaBaZhuFloor[bazhuIndex] >= roleTopFloor)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1463,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}

		int baZhuId = GetTongTianTaBaZhuId(bazhuIndex);
		if(baZhuId == 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1464,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		pUser->m_curTongTianTaFightFloor = tongTianTaBaZhuFloor[bazhuIndex];
		int res = TongTianTaBaZhuFight(pUser,bazhuIndex);
		if (res == -1)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1465,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		else if (res == -2)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1466,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		else if (res == -3)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1467,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		else if(res == -4)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0478,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		else
		{
			msg<<PRO_SUCCESS;
			m_socketServer.SendMsg(pUser->GetSock(),msg);
		}
	}
	else if (op == 6) // 请求玩家所在层数和下几层的怪物信息
	{
		SendTongTianTaInfo(pUser);
	}
	else if (op == 7)
	{
		// 请求信息刷新界面
	}
	else if (op == 8) // 显示通天塔进入次数
	{
		uint8 enterNum = pUser->GetExtData8(61); // 每日重置次数
		uint8 maxNum = 2; // 进入上限数
		if (maxNum > enterNum)
			msg<<(uint8)(maxNum-enterNum);
		else
			msg<<(uint8)0;
		m_socketServer.SendMsg(pUser->GetSock(),msg);
	}
	else if(op == 9)	// 显示第一次通关奖励
	{
		// 服务器主动发送第一次通关奖励
	}
	else if(op == 10)	// 重置通天塔
	{
		if(pUser->GetExtData8(61) < times)
		{
			if(pUser->GetExtData16(51) > 1)
			{
				pUser->SetExtData8(61,pUser->GetExtData8(61)+1);
				pUser->SetExtData16(51,1);
				SendTongTianTaInfo(pUser);
				pUser->CheckMissionHuoYueDu();
				msg<<PRO_SUCCESS;
			}
			else
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1468,TIPS_FAILURE_COLOR);
			}
		}
		else
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1469,TIPS_FAILURE_COLOR);
		}
		m_socketServer.SendMsg(pUser->GetSock(),msg);
	}
}

void CPackageDeal::ServerTongTianTa(CNetMessage *pMsg,int sock)
{
	GET_MSG

    if(!m_socketServer.IsServer(sock))
		return;
	int roleId;
	uint8 bazhuNum;
	
	msg>>roleId>>bazhuNum;
	
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	ShareUserPtr ptr = onlineUser.GetUserByRoleId(roleId);
	CUser *pUser = ptr.get();
    if(!pUser) 
		return;
	// CHECK_SYSTEM_OPEN(SOT_TongTianTa)
	CNetMessage newmsg;
	newmsg.SetType(MSG_TONG_TIAN_TA);
	uint8 op=2;
	newmsg<<op;
	const uint16 award[][2] = {{2370,15},{2370,30},{2370,45},{2370,60},{2370,90}};
	uint8 enterNum = pUser->GetExtData8(61);	// 重置次数
	uint8 maxNum = 2;
	//if (pUser->GetLevel() < TONGTIANTA_MIN_LEVEL) //没到等级无法进入
	//	enterNum = maxNum;
	newmsg<<enterNum<<maxNum<<pUser->GetExtData16(52); // 历史最高层    
	newmsg<<bazhuNum;
    uint32 bazhu;
	string name;
	string sequip;
	string wing;
	uint8 sex;
	uint8 xiang;
	uint16 wuqi;
	uint8 wingId = 0;
    for(int i=0;i<bazhuNum;i++)
	{
		msg>>bazhu;
		msg.ReadString(name);
		msg>>sex>>xiang>>sequip>>wing;
	    if(bazhu>0)
		{
			SItemInstance equipment[CUser::EQUIPMENT_NUM];
			memset(&equipment,0,sizeof(equipment));
			char buf[4096];
			uint32 len = StrToHex(sequip.c_str(),(uint8 *)buf,sizeof(buf));
			uint32 pos = 0;
			for(uint8 i = 0; i <= EETWuQi; i++)
				pos += ReadItemBuf(&equipment[i],(uint8 *)(buf+pos),len-pos);
			wuqi = equipment[EETWuQi].tmplId;

			SWing tempWing;
			tempWing.SetWing((char *)wing.c_str());
			uint8 useIdx = tempWing.m_useIndex;
			if(useIdx >= tempWing.m_num)
				wingId = 0;
			else
				wingId = tempWing.m_id[useIdx];
		}

		newmsg<<(uint16)tongTianTaBaZhuFloor[i];
		uint8 itemNum = 1;
		newmsg<<itemNum;
		newmsg<<award[i][0]<<(uint8)award[i][1];
		newmsg<<bazhu;
		if(bazhu > 0)
			newmsg<<name<<(uint8)sex<<(uint8)xiang<<(uint16)wuqi<<wingId;
	}
	m_socketServer.SendMsg(pUser->GetSock(),newmsg);
}

// 多人闯关
void CPackageDeal::ChuangGuanOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER
	/*
		ECGOp_Join: 加入活动
		ECGOp_Sync: 获取闯关数据
		ECGOp_Roll: roll点
		ECGOp_MoveEnd: 移动完成
		ECGOp_Msg: 提示消息
		ECGOp_Hand: 手头剪刀布协议消息
	*/
	uint8 op = 0;
	msg>>op;
	CXunBaoManage& xunBao = pUser->GetXunbaoManage();
	switch (op)
	{
	case CXunBaoManage::ECGOp_QueryInfo:	// 闯关入口
		{
			CHECK_SYSTEM_OPEN(SOT_21)
			int joinCnt = pUser->GetExtData8(21); // 当天进入次数
			if (joinCnt >= CXunBaoManage::JOIN_LIMIT)
			{
				SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_3,TIPS_FAILURE_COLOR).c_str());
				return;
			}
			xunBao.NotifyMapInfo();
			break;
		}
	case CXunBaoManage::ECGOp_MoveEnd: // 移动停止
		xunBao.DoStopEvt();
		break;

	case CXunBaoManage::ECGOp_Roll:
		xunBao.Roll();
		break;

/*	case CXunBaoManage::ECGOp_Hand:
		xunBao.PlayHand();
		break;
*/
	case CXunBaoManage::ECGOp_Robber:
		{
			if(pUser->GetFightId() > 0)
			{
				SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0480,TIPS_FAILURE_COLOR).c_str());
				return;
			}

			uint8 type = 0;
			msg>>type;
			xunBao.FightPvP();
			break;
		}

	case CXunBaoManage::ECGOp_EnableCount:
		{
			int joinCnt = pUser->GetExtData8(21); // 当天进入次数
			int enableCnt = CXunBaoManage::JOIN_LIMIT - joinCnt;
			if (enableCnt < 0)
				enableCnt = 0;
			if (pUser->HaveBitSet(180)) // 已经在房间中了，加一次算作当前进入次数
				++enableCnt;
			msg<<(uint8)enableCnt;
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			break;
		}

	case CXunBaoManage::ECGOp_Reset:
		xunBao.ResetMap();
		SingletonSocket::instance().SendMsg(sock, msg);
		break;

	case CXunBaoManage::ECGOp_BuyRollTimes:
		xunBao.UserBuyRollTimes();
		break;

	case CXunBaoManage::ECGOp_QueryBuyRollInfo:
		xunBao.UserQueryBuyRollInfo();
		break;

	case CXunBaoManage::ECGOp_KunLunInfo:
		xunBao.GetKunLunMsg(msg);
		break;

	case CXunBaoManage::ECGOp_KunLunFight:
		xunBao.TryKunLunFight(msg);
		break;

	case CXunBaoManage::ECGOp_KunLunBuy:
		xunBao.BuyFightCnt(msg);
		break;

	case CXunBaoManage::ECGOp_KunLunLianChuang:
		xunBao.LianXuFight(msg);
		break;

	case CXunBaoManage::ECGOp_KunLunRobot:
		xunBao.GetRobotMsg(msg);
		break;

	default:
		break;
	}
}

// 钓鱼
void CPackageDeal::FishOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER
	// CHECK_SYSTEM_OPEN(SOT_Fish)
	uint8 op = 0;
	msg>>op;

	CFishManager& fishMgr = SingletonFishManager::instance();
	switch (op)
	{
	case CFishManager::EFOP_RoomList: // 获取房间列表
		{
			fishMgr.GetRoomList(pUser);
			break;
		}
	case CFishManager::EFOP_Join: // 加入房间
		{
			int roomId = 0;
			msg>>roomId;
			fishMgr.JoinRoom(pUser,roomId);
			break;
		}
	case CFishManager::EFOP_FisherList: // 房间内钓鱼的玩家列表
		{
			fishMgr.GetRoomFisherList(pUser);
			break;
		}
	case CFishManager::EFOP_FishList: // 鱼篓数据
		{
			int tarRoleId = 0;
			msg>>tarRoleId;
			CFishRoom* pRoom = pUser->GetFishRoom();
			if (pRoom == NULL)
			{
				SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_1470,TIPS_FAILURE_COLOR).c_str());
				return;
			}
			pRoom->GetFishList(pUser,tarRoleId);
			break;
		}
	case CFishManager::EFOP_Fish: // 开始钓鱼
		{
			uint8 face = 0;
			msg>>face;
			CFishRoom* pRoom = pUser->GetFishRoom();
			if (pRoom == NULL)
			{
				SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_1471,TIPS_FAILURE_COLOR).c_str());
				return;
			}
			pRoom->StartFish(pUser,face);
			break;
		}
	case CFishManager::EFOP_GetFish: // 收获鱼
		{
			uint8 fishIdx = 0;
			msg>>fishIdx;
			CFishRoom* pRoom = pUser->GetFishRoom();
			if (pRoom == NULL)
			{
				SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_1472,TIPS_FAILURE_COLOR).c_str());
				return;
			}
			pRoom->GetFish(pUser,fishIdx);
			break;
		}
	case CFishManager::EFOP_GrabFish: // 抢夺鱼
		{
			int tarRoleId = 0;
			uint8 fishIdx = 0;
			msg>>tarRoleId>>fishIdx;
			CFishRoom* pRoom = pUser->GetFishRoom();
			if (pRoom == NULL)
			{
				SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_1473,TIPS_FAILURE_COLOR).c_str());
				return;
			}
			pRoom->GrabFish(pUser,tarRoleId,fishIdx);
			break;
		}
	case CFishManager::EFOP_FishTime: // 通知客户端收获鱼的倒计时
		{
			CFishRoom* pRoom = pUser->GetFishRoom();
			if (pRoom == NULL)
			{
				SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_1474,TIPS_FAILURE_COLOR).c_str());
				return;
			}
			pRoom->SyncFishTime(pUser);
			break;
		}
	case CFishManager::EFOP_Exit: // 离开房间
		{
			fishMgr.ExitRoom(pUser);
			break;
		}
	case CFishManager::EFOP_StopFish: // 停止钓鱼
		{
			CFishRoom* pRoom = pUser->GetFishRoom();
			if (pRoom == NULL)
			{
				SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_1475,TIPS_FAILURE_COLOR).c_str());
				return;
			}
			pRoom->StopFish(pUser);
			break;
		}
	case CFishManager::EFOP_PlayerList: // 获取房间成员列表
		{
			int roomId = 0;
			msg>>roomId;
			fishMgr.GetRoomPlayerList(pUser,roomId);
			break;
		}
	default:
		{
			break;
		}
	}
}

void CPackageDeal::UserVIPOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER
	// CHECK_SYSTEM_OPEN(SOT_VIP)
	const int MountCardYB[] = {2000,3000,400};
	const int cardTypeNum = 2;

	uint8 op = 0;
	msg>>op;
	if(op == 1)	// 获取各级vip信息(至尊)
	{
		msg.ReWrite();
		msg.SetType(MSG_VIP_OPTION);
		msg<<op;
		msg<<(uint8)15;
		for (int i = 1; i < 16; ++i)
		{
			msg<<G_VipConfig[i].yuanbao;
			for(int j=0;j<3;j++)
			{
				msg<<G_VipConfig[i].awardt[j];
				msg<<G_VipConfig[i].awardn[j];
			}
		}
		msg << (uint8)cardTypeNum;
		for (uint8 i = 0; i < cardTypeNum; i++)
		{
			msg << (uint8)(i + 1);
			if (i == 0)
				msg << (uint16)0;
			else if (i == 1)
				msg << (uint16)HDAT_CHENGHAO << (uint16)E2UT_88;
			msg << MountCardYB[i];
		}
		m_socketServer.SendMsg(pUser->GetSock(),msg);
	}
	//else if(op == 7)//月卡玩家每日领取元宝(特权卡)
	//{
	//	msg.ReWrite();
	//	msg.SetType(MSG_VIP_OPTION);
	//	msg<<(uint8)7;
 //       if(pUser->GetMonthCard()==0)
	//	{
	//		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1482,TIPS_FAILURE_COLOR);
	//		m_socketServer.SendMsg(pUser->GetSock(),msg);
	//		return;
	//	}
	//	if(pUser->HaveBitSet(347))
	//	{
	//		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1483,TIPS_FAILURE_COLOR);
	//		m_socketServer.SendMsg(pUser->GetSock(),msg);
	//		return;
	//	}

	//	pUser->AddTongBao(MCDayYB);
	//	snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1484,MCDayYB);
	//	msg<<PRO_SUCCESS<<MakeStringColor(buf,TIPS_WARNING_COLOR);
	//	pUser->SetBitSet(347);
	//	pUser->UpdateVipInfo();
	//	m_socketServer.SendMsg(pUser->GetSock(),msg);
	//}
	else if(op == 8) // 领取月卡每日元宝(特权卡)
	{
		int YB = 0;		// 可领的元宝数
		uint8 type;
		msg >> type;
		uint8 monCardValue = pUser->GetMonthCard();
		uint8 getValue = pUser->GetExtData8(108);
		int curTime = GetSysTime();
		uint8 canGet = 0;	// 0不可领 1可领
		uint8 flag = 0;
		bool isHave = (monCardValue & (1 << (type - 1))) > 0 ? true : false;
		if (!isHave)
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_1482, TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(), msg);
			return;
		}

		int endTime = pUser->GetMCEndTime(type - 1);
		int leftTime = (endTime > 0 && endTime > curTime) ? (endTime - curTime) : 0;
		if (type == 2 || leftTime > 0)	// 已获得的特权且还生效
		{
			if ((getValue & (1 << (type - 1))) == 0)	// 还未领取
			{
				canGet = 1;
				if (type - 1 == UPT_White_Gold)
				{
					YB += MountCardYB[UPT_White_Gold];
					flag |= 1 << (type - 1);
				}
				else if (type - 1 == UPT_Diamond)
				{
					YB += MountCardYB[UPT_Diamond];
					flag |= 1 << (type - 1);
				}
				else if (type - 1 == UPT_King)
				{
					YB += MountCardYB[UPT_King];
					flag |= 1 << (type - 1);
				}
			}
		}

		if(canGet == 0 || YB == 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1485,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		pUser->AddTongBao(YB);
		pUser->SetExtData32(71,(int)GetSysTime());
		getValue |= flag;
		pUser->SetExtData8(108,getValue);

		char buf[256];
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1486,YB);
		string lastTime;
		lastTime = GetMonthCardLastTime((time_t)pUser->GetExtData32(71));
		msg<<PRO_SUCCESS<<MakeStringColor(buf,TIPS_WARNING_COLOR)<<lastTime.c_str();
		m_socketServer.SendMsg(pUser->GetSock(),msg);
	}
	else if(op == 9)	// 获取玩家月卡信息(特权卡)
	{
		msg.ReWrite();
		msg.SetType(MSG_VIP_OPTION);
		msg<<op;
		
		int YB = 0;		// 可领的元宝数
		uint8 num = UPT_MAX+1;
		uint8 monCardValue = pUser->GetMonthCard();
		uint8 getValue = pUser->GetExtData8(108);
		int curTime = GetSysTime();
		time_t lastGetTime = pUser->GetExtData32(71);
		string lastTime;
		uint8 canGet = 0;	// 0不可领 1可领

		lastTime = GetMonthCardLastTime((uint32)lastGetTime);
		msg<<lastTime.c_str()<<num;
		for(uint8 id=1;id <= num;id++)
		{
			bool isHave = (monCardValue & (1<<(id-1))) > 0 ? true : false;
			msg<<id<<PrivilegePrice[id-1]<<(uint8)isHave;
			int leftTime= 0;
			if(!isHave)
			{
				msg<<leftTime;
			}
			else
			{
				int endTime = pUser->GetMCEndTime(id-1);
				leftTime = (endTime > 0 && endTime > curTime) ? (endTime - curTime) : 0;
				msg<<leftTime;
				if(leftTime > 0)	// 已获得的特权且还生效
				{
					if((getValue & (1<<(id-1))) == 0)	// 还未领取
					{
						canGet = 1;
						if(id-1 == UPT_White_Gold)
							YB += MountCardYB[UPT_White_Gold];
						else if(id-1 == UPT_Diamond)
							YB += MountCardYB[UPT_Diamond];
						else if(id-1 == UPT_King)
							YB += MountCardYB[UPT_King];
					}
				}
			}
		}
		msg<<canGet<<YB;
		m_socketServer.SendMsg(pUser->GetSock(),msg);
	}
}

// 离线经验
void CPackageDeal::OfflineExpOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	/*
		op:
		1:获取打开界面基础信息
		2:兑换离线经验
	*/

	uint8 op = 0;
	msg>>op;
	switch (op)
	{
	case 1: // 获取打开界面基础信息
		{
			uint16 expRate = 100;
			// 如果是vip则发送其他比率
			msg.ReWrite();
			msg.SetType(MSG_OFFLINE_EXP);
			msg<<op<<(int)pUser->GetOfflineExpTime()<<(uint16)75<<pUser->GetOfflineExp(CUser::EOET_FREE)<<(uint16)(expRate)<<pUser->GetOfflineExp(CUser::EOET_CURRENCY);
			if(pUser->GetVipLevel() > 0)
				msg<<G_VipConfig[pUser->GetVipLevel()].offline<<pUser->GetOfflineExp(CUser::EOET_VIP);
			else
				msg<<G_VipConfig[15].offline<<0;
			int needCurrency = (pUser->GetOfflineExpTime()/60) * 16 * 3;
			msg<<needCurrency;
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			break;
		}
	case 2: // 兑换离线经验
		{
			uint8 type = 0;
			msg>>type;
			msg.ReWrite();
			msg.SetType(MSG_OFFLINE_EXP);
			msg<<op;
			int addExp = pUser->GetOfflineExp(type);
			if (addExp == 0)
			{
				SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_1487,TIPS_FAILURE_COLOR).c_str());
				return;
			}
			// 消耗金币处理
			if (type == CUser::EOET_CURRENCY)
			{
				int needCurrency = (pUser->GetOfflineExpTime()/60) * 16 * 3 * 5;
				if (needCurrency > pUser->GetMoney())
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_1488,TIPS_FAILURE_COLOR).c_str());
					return;
				}
				pUser->AddMoney(-needCurrency); // 消耗金币
			}
			pUser->SetBitSet(168); // 每日活跃度 离线经验
			pUser->ResetOfflineExpTime();
			addExp = pUser->AddExp(addExp, true);
			msg<<PRO_SUCCESS<<addExp;
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			//char info[64];
			//snprintf(info,sizeof(info),"获得经验:%d",addExp);
			//SendSysInfo(pUser,MakeStringColor(info,TIPS_WARNING_COLOR).c_str());
			break;
		}
	default:
		{
			break;
		}
	}
}


// 临时活动，开服活动等
void CPackageDeal::HuoDongTmpOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 op = 0;
	msg>>op;
	switch (op)
	{
	case HD_LIANXU_CHONGZHI_ORI:
	case HD_LIANXU_CHONGZHI_DELUXE:
	case HD_LEVEL_JIJIN1:
	case HD_SHENJIANG_ZHEKOU:
	case HD_ZHEKOU_LIBAO1:
	case HD_ZHEKOU_LIBAO2:
	case HD_ZHEKOU_LIBAO3:
		// CHECK_SYSTEM_OPEN(SOT_Huodong)
		break;

	default:
		// CHECK_SYSTEM_OPEN(SOT_Huodong)
		break;
	}

	switch (op)
	{
	case HD_HAOHUALIBAO: // 豪华礼包
		{
			uint8 op1 = 0;
			msg>>op1;
			if (op1 == 1) // 状态获取
			{
				if (pUser->GetLevel() < 30) // 等级不满足
				{
					msg<<(uint8)PRO_ERROR<<(uint8)1;
				}
				else if (pUser->GetExtData16(35) < 3) // 天数不满足
				{
					msg<<(uint8)PRO_ERROR<<(uint8)2;
				}
				else if (pUser->HaveBitSet(184)) // 不满足 已经领取过了
				{
					msg<<(uint8)PRO_ERROR<<(uint8)3;
				}
				else // 满足条件
				{
					msg<<(uint8)PRO_SUCCESS;
				}
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			else if (op1 == 2) // 领取
			{
				if (pUser->GetLevel() < 30) // 等级不满足
				{
					msg<<(uint8)PRO_ERROR<<(uint8)1;
				}
				else if (pUser->GetExtData16(35) < 3) // 天数不满足
				{
					msg<<(uint8)PRO_ERROR<<(uint8)2;
				}
				else if (pUser->HaveBitSet(184)) // 不满足 已经领取过了
				{
					msg<<(uint8)PRO_ERROR<<(uint8)3;
				}
				else // 满足条件
				{
					string code = GetJiHuoMa(2); // 获取一个激活码
					if (code == "") // 没有激活码了
					{
						msg<<(uint8)PRO_ERROR<<4; // 没有激活码了
					}
					else
					{
						pUser->SetBitSet(184);
						pUser->SetDataStr(3,code.c_str());
						msg<<(uint8)PRO_SUCCESS<<code.c_str();
						SendSysNotice(pUser);
					}
				}
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			else if (op1 == 3) // 获取已经领取到的激活码
			{
				string code = pUser->GetDataStr(3);
				msg<<code.c_str();
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			break;
		}
	case HD_MEIRIGONGZI: // 每日工资
		{
			uint8 op1 = 0;
			msg>>op1;
			if (op1 == 1) // 状态查询
			{
				if (pUser->HaveBitSet(183)) // 已经领取过了
					msg<<PRO_ERROR<<(uint8)1;
				else if (pUser->GetLevel() < 30) // 30级等级限制
					msg<<PRO_ERROR<<(uint8)2;
				else
					msg<<PRO_SUCCESS; // 可以领取
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			else if (op1 == 2) // 领取
			{
				if (pUser->HaveBitSet(183)) // 已经领取过了
				{
					msg<<PRO_ERROR<<(uint8)1;
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				else if (pUser->GetLevel() < 30) // 30级等级限制
				{
					msg<<PRO_ERROR<<(uint8)2;
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				pUser->SetBitSet(183);
				pUser->AddTongBao(1000,1);
				msg<<PRO_SUCCESS;
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_1489,TIPS_WARNING_COLOR).c_str());
				SendSysNotice(pUser);
			}
			break;
		}
	case HD_MIANFEIZUOQI: // 免费坐骑
		{
			/*
			uint8 op1 = 0;
			msg>>op1;
			if (op1 == 1) // 状态查询
			{
				if (pUser->HaveBitSet(185))
				{
					msg<<PRO_ERROR<<(uint8)1; // 已经领取过了
				}
				else if (!pUser->IsAddHuoDongMountEnable())
				{
					msg<<PRO_ERROR<<(uint8)4; // 没有坐骑
				}
				else
				{
					bool isEnable = false;
					if (pUser->GetLevel() >= 50)
						isEnable = true;
					else
					{
						CCallScript *pCallScript = FindScript(200);
						if(pCallScript != NULL)
						{
							string accountName = "";
							int enable = 0;
							pUser->GetAccountName(accountName);
							pCallScript->Call("IsFreeUpgradeMountHuoDongUser","us>i",pUser,accountName.c_str(),&enable);
							if (enable == 1)
								isEnable = true;
						}
					}
					if (isEnable)
						msg<<PRO_SUCCESS; // 可以领取
					else
						msg<<PRO_ERROR<<(uint8)2; // 不满足领取条件
				}
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			else if (op1 == 2) // 领取
			{
				// 条件判断
				if (pUser->HaveBitSet(185))
				{
					msg<<PRO_ERROR<<(uint8)1; // 已经领取过了
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				if (!pUser->IsAddHuoDongMountEnable())
				{
					msg<<PRO_ERROR<<(uint8)4; // 没有坐骑
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				bool isEnable = false;
				if (pUser->GetLevel() >= 50)
					isEnable = true;
				else
				{
					CCallScript *pCallScript = FindScript(200);
					if(pCallScript != NULL)
					{
						string accountName = "";
						int enable = 0;
						pUser->GetAccountName(accountName);
						pCallScript->Call("IsFreeUpgradeMountHuoDongUser","us>i",pUser,accountName.c_str(),&enable);
						if (enable == 1)
							isEnable = true;
					}
				}
				// 给坐骑进阶丹
				if (!isEnable)
				{
					msg<<PRO_ERROR<<(uint8)2; // 不满足领取条件
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				//if (pUser->EmptyPackage() < 2)
				//{
				//	msg<<PRO_ERROR<<(uint8)3; // 背包空间不足
				//	m_socketServer.SendMsg(pUser->GetSock(),msg);
				//	return;
				//}

				pUser->SetBitSet(185);
				pUser->AddHuoDongMount();
				//pUser->AddBangDingPackage(2301,10);
				//pUser->AddBangDingPackage(2302,15);
				msg<<PRO_SUCCESS;
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_1490,TIPS_WARNING_COLOR).c_str());
			}
			else
				return;
			*/
			break;
		}
	case HD_ZAIXIANLINGHAOLI: // 在线奖励
		{
			uint8 op1 = 0;
			msg>>op1;
			if (op1 == 1) // 状态请求
			{
				QueryOnlineAward(pUser, msg, pUser->GetSock());
			}
			else if (op1 == 2) // 领取奖励
			{
				GetOnlineAward(pUser, msg);
			}
			break;
		}
	case HD_LIANXUDENGLUJIANGLI: // 7日登陆奖励
		{
			CHuoDongManage& hdMgr = sCHuoDongManage;
			uint8 op1 = 0;
			msg>>op1;
			if(op1 == 1) // 打开界面
			{
				U8MultiAwardMap& qiAwards = hdMgr.GetQiRiAwards();
				msg << pUser->GetExtData8(75);
				msg<<(uint8)qiAwards.size();
				for (U8MultiAwardMapIt it = qiAwards.begin(); it != qiAwards.end(); ++it)
				{
					msg << (uint8)pUser->HaveBitSet(281 + it->first);
					MakeMultiAwardMsg(it->second, msg);
				}
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				return;
			}
			else if(op1 == 2) // 领取奖励
			{
				uint8 curDay = 0;
				msg >> curDay;
				U8MultiAwardMap& qiAwards = hdMgr.GetQiRiAwards();
				uint8 logonNum = qiAwards.size();
				curDay = curDay > logonNum ? logonNum : curDay;

				if(curDay+1 > pUser->GetExtData8(75))
					return;
				if(pUser->HaveBitSet(281 + curDay))
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1496,TIPS_FAILURE_COLOR);	// 今天已经领取过了
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				MultiAward* awards = hdMgr.GetQiRiAward(curDay + 1);
				if (awards == NULL)
				{
					msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0153, TIPS_FAILURE_COLOR);	// 不能领取
					m_socketServer.SendMsg(pUser->GetSock(), msg);
					return;
					return;
				}
				pUser->SetBitSet(281 + curDay);
				msg << PRO_SUCCESS;
				SendAndMakeAwardMsg(pUser, *awards, msg, false, MUT_QiRiDengLu);
				m_socketServer.SendMsg(pUser->GetSock(), msg);
				SendSysNotice(pUser);
				pUser->Send_HuoDongMsg();
				return;
			}
			break;
		}
	case HD_CHENGZHANGLIBAO: // 成长礼包(除魔卫道大礼包)
		{
			uint8 op1 = 0;
			msg>>op1;
			if (op1 == 1) // 是否可以领取
			{
				msg<<(uint8)pUser->HaveBitSet(11);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				return;
			}
			else if (op1 == 2) // 领取
			{
				if (pUser->HaveBitSet(11))
				{
					msg<<PRO_ERROR<<(uint8)1; // 已经领取过了
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				pUser->SetBitSet(11);
				pUser->AddBangDingPackage(2363,1);
				msg<<PRO_SUCCESS;
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				SendSysNotice(pUser);
				return;
			}
			break;
		}
	case HD_SHENGJILIBAO:
		{
			const int sj_type_pet = HDAT_PET; // 神将
			static int sj_max_stage = 0; // 最多可以领取的段数
			static int sj_item_num = 0; // 每档奖励物品数
			static bool init = true;
			if (init && m_dengJiLiBao.size() > 0)
			{
				sj_max_stage = (int)m_dengJiLiBao.size();
				sj_item_num = (int)sizeof(m_dengJiLiBao[0].goods)/sizeof(m_dengJiLiBao[0].goods[0]);
				init = false;
			}

			uint8 op1 = 0;
			msg>>op1;
			if (op1 == 1) // 状态查询
			{
				bool isEnable = false;
				int curStage = pUser->GetExtData32(87);
				bitset<32> bt(curStage);
				for (int i = 0; i < sj_max_stage; ++i)
				{
					if (!bt.test(i))
					{
						isEnable = true;
						break;
					}
				}
				msg<<(uint8)isEnable;
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				return;
			}
			else if (op1 == 2) // 领取礼包
			{
				uint8 rewardStage = 0;
				msg>>rewardStage;
				msg.ReWrite();
				msg.SetType(MSG_TMP_HUODONG);
				msg<<(uint8)HD_SHENGJILIBAO<<op1;
				int curStage = pUser->GetExtData32(87);
				bitset<32> bt(curStage);
				if (rewardStage >= sj_max_stage) // 到70级
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1506,TIPS_FAILURE_COLOR);
				}
				else if (bt.test(rewardStage))
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1507,TIPS_FAILURE_COLOR);
				}
				else
				{
					if ((m_dengJiLiBao[rewardStage].level) > pUser->GetLevel())
					{
						char showMsg[64];
						snprintf(showMsg,sizeof(showMsg),LANGUAGE_TRANSFORM_1508,m_dengJiLiBao[rewardStage+1].level);
						msg<<PRO_ERROR<<MakeStringColor(showMsg,TIPS_FAILURE_COLOR);
					}
					else
					{
						bt.set(rewardStage);
						pUser->SetExtData32(87,(uint32)(bt.to_ulong()));
						int itemId;
						int itemNum;
						int itemValue;
						char sysInfostr[32];
						for (int i = 0; i < sj_item_num; ++i)
						{
							itemId = m_dengJiLiBao[rewardStage].goods[i][0];
							itemNum = m_dengJiLiBao[rewardStage].goods[i][1];
							itemValue = m_dengJiLiBao[rewardStage].goods[i][2];
							if (itemId == sj_type_pet)
							{
								::AddPet(pUser,itemNum,1);
								SaveDate(pUser,9,itemNum);
								snprintf(sysInfostr,sizeof(sysInfostr),LANGUAGE_TRANSFORM_1510,GetPetName(itemNum));
								SendSysInfo(pUser,MakeStringColor(sysInfostr,TIPS_WARNING_COLOR).c_str());
							}
							else
							{
								if (itemId == 0) // 没有道具就不处理
									continue;
								pUser->AddMaterial(itemId, itemNum, false, true, itemValue);
							}
						}
						msg<<PRO_SUCCESS<<rewardStage;
						pUser->Send_HuoDongMsg();
						SendSysNotice(pUser);
					}
				}
				m_socketServer.SendMsg(pUser->GetSock(),msg);
//				pUser->Send_HuoDongMsg();
				return;
			}
			else if (op1 == 3) // 查询奖励物品的内容
			{
				int curStage = pUser->GetExtData32(87);
				bitset<32> bt(curStage);
				msg<<(uint8)sj_max_stage;
				for (int i = 0; i < sj_max_stage; ++ i)
				{
					msg<<(uint8)m_dengJiLiBao[i].id;
					msg<<(uint8)bt.test(i);
					msg<<(uint8)m_dengJiLiBao[i].level;
					msg<<(uint8)sj_item_num;
					for (int j = 0; j < sj_item_num; ++j)
					{
						msg<<(uint16)m_dengJiLiBao[i].goods[j][0];
						if ((int)m_dengJiLiBao[i].goods[j][0] == sj_type_pet) // 神将
							MakePetMsg(pUser,msg,m_dengJiLiBao[i].goods[j][1]);
						else // 普通道具
							msg<<m_dengJiLiBao[i].goods[j][1]<< m_dengJiLiBao[i].goods[j][2];
					}
				}
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			break;
		}
	case HD_SHOUCHONG:
	case HD_CICHONG:
		{
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
			uint32 type = CHuoDongAwardManager::SHOU_CHONG;
			uint32 chongDataId = 200;
			uint32 getDataId = 304;

			if (op == HD_CICHONG)
			{
				type = CHuoDongAwardManager::CI_CHONG;
				chongDataId = 556;
				getDataId = 557;
			}


			uint8 op1 = 0;
			msg>>op1;
			if (op1 == 1) //查询首充奖励是否已经领取
			{
				msg<<(uint8)pUser->HaveBitSet(getDataId);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			else if (op1 == 2) //查询领取的奖励内容  非台湾版
			{
				vector<HDPeiZhiInfo> info;
				awardManager.GetPeiZhiInfo(info,type);
				if (info.size() < 1)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1511,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
			
				SHuoDongAward award;
				awardManager.GetAwardData(type,1,award);
				msg<<(uint8)pUser->HaveBitSet(chongDataId)<<(uint8)pUser->HaveBitSet(getDataId)<<(uint32)info[0].YB;
			
				uint16 pos = msg.GetDataLen();
				uint8 typeNum = 0;
				msg<<typeNum;
				typeNum = MakeAwardMsg(pUser,award,type,msg);
				msg.WriteData(pos,&typeNum,sizeof(typeNum));

				if (type == CHuoDongAwardManager::CI_CHONG)
				{
					msg<<(uint32)GetYB_ByMoney(pUser->GetExtData32(18));//元宝
					msg<<(uint32)GetYB_ByMoney(info[0].price);//元宝
				}
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			else if (op1 == 3) //领取奖励内容
			{
				vector<HDPeiZhiInfo> info;
				awardManager.GetPeiZhiInfo(info,type);
				if (info.size() < 1)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1512,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				if (!pUser->HaveBitSet(chongDataId))
				{
					if (type == CHuoDongAwardManager::SHOU_CHONG)
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1513,TIPS_FAILURE_COLOR);
					else
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1514,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				if (pUser->HaveBitSet(getDataId))
				{
					if (type == CHuoDongAwardManager::SHOU_CHONG)
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1515,TIPS_FAILURE_COLOR);
					else
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1516,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				pUser->SetBitSet(getDataId);

				uint32 idx = 1;
				SHuoDongAward award;
				awardManager.GetAwardData(type,idx,award);

				uint16 petId = 0;
				uint16 itemId = 0;
				uint16 wingId = 0;
				char buf[256];

				for(uint8 j=0;j < SHuoDongAward::AWARD_NUM;j++)
				{
					AddHuoDongAward(pUser,type,award.award[j],award.num[j],award.petQuality[j],award.petQualityLv[j]);
					if (petId == 0 && award.award[j] == HDAT_PET)
					{
						petId = award.num[j];
//						petQuality = award.petQuality[j];
					}
					
					if (itemId == 0 && award.award[j] < HDAT_MONEY)
						itemId = award.award[j];

					if (wingId == 0 && award.award[j] == HDAT_WING)
						wingId = award.num[j];
				}

				if (type == CHuoDongAwardManager::SHOU_CHONG && petId > 0)
					SaveDate(pUser,11,petId); // 首充获得神将记录

				msg<<PRO_SUCCESS;
				m_socketServer.SendMsg(pUser->GetSock(),msg);

				if (type == CHuoDongAwardManager::SHOU_CHONG)
				{
//					int size = sizeof(PetQualityColor)/sizeof(PetQualityColor[0]);
					if (petId > 0 && itemId > 0)
					{
						SPetBasicData *pCfg = SingletonCPetCfgMgr::instance().GetPetCfg(petId);
						if(pCfg != NULL)
						{
							snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1517,
								ROLE_NAME_COLOR,pUser->GetName(),ITEM_NAME_COLOR,PetQualityColor[pCfg->quality],QualityColorName[pCfg->quality].c_str(),pCfg->name.c_str(),ITEM_NAME_COLOR,GetItemName(itemId));
							SysInfoToAllUser(buf);
						}
					}
				}
				else
				{
					if (wingId > 0 && itemId > 0)
					{
						snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1518,
							ROLE_NAME_COLOR,pUser->GetName(),ITEM_NAME_COLOR,ITEM_NAME_COLOR,GetWingName(wingId),ITEM_NAME_COLOR,GetItemName(itemId));
						SysInfoToAllUser(buf);
					}
				}
				SendSysNotice(pUser);
			}
			else if (op1 == 4) //查询领取的奖励内容  台湾版
			{				
				vector<HDPeiZhiInfo> info;
				awardManager.GetPeiZhiInfo(info,type);
				if (info.size() < 1)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1519,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				msg<<(uint8)pUser->HaveBitSet(chongDataId)<<(uint8)pUser->HaveBitSet(getDataId)<<(uint32)pUser->GetExtData32(290);
				uint16 pos1 = msg.GetDataLen();
				uint8 typeNum1 = 0;
				msg<<typeNum1;
				for (uint32 i = 0; i < info.size(); i++)
				{
					if (info[i].index != 1)
					{
						msg<<info[i].price<<info[i].YB;
						SHuoDongAward award;
						awardManager.GetAwardData(type,info[i].index,award);

						uint16 pos = msg.GetDataLen();
						uint8 typeNum = 0;
						msg<<typeNum;
						typeNum = MakeAwardMsg(pUser,award,type,msg);
						msg.WriteData(pos,&typeNum,sizeof(typeNum));
						typeNum1++;
					}				
				}
				msg.WriteData(pos1,&typeNum1,sizeof(typeNum1));
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			break;
		}
	case HD_TAOCAN:
		{
			const uint8 TAO_CAN_NUM = 8; // 套餐数量
			const uint8 ITEM_SIZE = 6; // 套餐物品数量
			const uint8 ITEM_PROP_NUM = 2; // 套餐物品属性数量

			const char *taocanName[TAO_CAN_NUM] = {LANGUAGE_TRANSFORM_1520,LANGUAGE_TRANSFORM_1521,LANGUAGE_TRANSFORM_1522,LANGUAGE_TRANSFORM_1523,LANGUAGE_TRANSFORM_1524,LANGUAGE_TRANSFORM_1525,LANGUAGE_TRANSFORM_1526,LANGUAGE_TRANSFORM_1527};
			const uint16 TAO_CAN_LIST[TAO_CAN_NUM][ITEM_SIZE][ITEM_PROP_NUM] = { // 套餐奖励的内容
				{
					{851,15},{501,2},{0,0},{0,0},{0,0},{0,0}
				},
				{
					// pet  id
					{HDAT_PET,1},{2370,6},{0,0},{0,0},{0,0},{0,0}
				},
				{
					{2310,40},{2319,1},{0,0},{0,0},{0,0},{0,0}
				},
				{
					{HDAT_PET,2},{2310,10},{0,0},{0,0},{0,0},{0,0}
				},
				{
					{HDAT_EQUIP,1},{804,1},{0,0},{0,0},{0,0},{0,0}
				},
				{
					{2301,8},{2251,40},{2252,30},{2253,20},{0,0},{0,0}
				},
				{
					{HDAT_PET,3},{0,0},{0,0},{0,0},{0,0},{0,0}
				},
				{
					{HDAT_EQUIP,2},{805,1},{0,0},{0,0},{0,0},{0,0}
				},
			};

			const int TAO_CAN_PRICE[TAO_CAN_NUM][ITEM_PROP_NUM] = { // 套餐价格和购买bitset
				{80,305},
				{180,306},
				{680,307},
				{1980,308},
				{3980,309},
				{5980,310},
				{8980,311},
				{12880,334}
			};

			static bool isInit = false;
			// 熊猫人
			// 冰魇
			// 巨猿
			static SItemInstance item398_5; // 30衣服 战
			static SItemInstance item398_1; // 30衣服 法
			static SItemInstance item398_2; // 30衣服 刺
			static SItemInstance item1288_5; // 40武器 战
			static SItemInstance item1288_1; // 40武器 法
			static SItemInstance item1288_2; // 40武器 刺
			if (!isInit)
			{
				isInit = true;
			}

			uint8 op1 = 0;
			double offSell = 1.0;

			msg>>op1;
			if (op1 == 1) // 是否可以购买套餐
			{
//				bool canBuy = false;
//				for (int i = 0; i < TAO_CAN_NUM; ++i)
//				{
//					if (!pUser->HaveBitSet(TAO_CAN_PRICE[i][1]))
//					{
//						canBuy = true;
//						break;
//					}
//				}
				msg<<(uint8)1;
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			else if (op1 == 2) // 查看套餐内容
			{
				msg<<(uint8)TAO_CAN_NUM;
				for (int i = 0; i < TAO_CAN_NUM; ++i)
				{
					msg<<(uint8)i<<(int)(TAO_CAN_PRICE[i][0]*offSell)<<(uint8)pUser->HaveBitSet(TAO_CAN_PRICE[i][1]); // 价格、是否已经购买
					for (int j = 0; j < ITEM_SIZE; ++j)
					{
						msg<<TAO_CAN_LIST[i][j][0];
						if (TAO_CAN_LIST[i][j][0] == HDAT_PET) // 神将
						{
							if (TAO_CAN_LIST[i][j][1] == 1)
							{
								MakePetMsg(pUser,msg,28);	// 紫熊猫人
							}
							else if (TAO_CAN_LIST[i][j][1] == 2)
							{
								MakePetMsg(pUser,msg,38);
							}
							else if (TAO_CAN_LIST[i][j][1] == 3)
							{
								MakePetMsg(pUser,msg,39);
							}
						}
						else if (TAO_CAN_LIST[i][j][0] == HDAT_EQUIP) // 装备
						{

						}
						else // 普通物品
							msg<<TAO_CAN_LIST[i][j][1]; // 物品类型、物品数量
					}
				}
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			else if (op1 == 3) // 购买套餐
			{
				uint8 taoCanId = TAO_CAN_NUM;
				msg>>taoCanId;

				msg.ReWrite();
				msg.SetType(MSG_TMP_HUODONG);
				msg<<(uint8)HD_TAOCAN<<op1;
				if (taoCanId >= TAO_CAN_NUM)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1528,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				if (pUser->HaveBitSet(TAO_CAN_PRICE[taoCanId][1]))
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1529,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				int useYuanBao = (int)(TAO_CAN_PRICE[taoCanId][0]*offSell);
				if (pUser->GetTongBao() < useYuanBao)
				{
					msg<<PRO_ERROR<<"";
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					ShowJumpNotice(pUser,JUMP_NOTICE_YB);
					return;
				}

				pUser->SetBitSet(TAO_CAN_PRICE[taoCanId][1]); // 设置已购买
				pUser->AddTongBao(-useYuanBao); // 扣费
				ItemCurrencyLog(pUser->GetRoleId(),0,taoCanId,0,useYuanBao,pUser->GetTongBao(),YBL_TAOCAN);

				int itemId;
				int itemNum;
				char sysInfo[512];
				for (int i = 0; i < ITEM_SIZE; ++i)
				{
					itemId = TAO_CAN_LIST[taoCanId][i][0];
					itemNum = TAO_CAN_LIST[taoCanId][i][1];
					if (itemId > 0 && itemId < HDAT_MONEY && itemNum != 0)
					{
						snprintf(sysInfo,sizeof(sysInfo),LANGUAGE_TRANSFORM_1531,GetItemName(itemId),itemNum);
						while(itemNum > EItemDieJiaNum)
						{
							pUser->AddBangDingPackage(itemId,EItemDieJiaNum);
							itemNum -= EItemDieJiaNum;
						}
						pUser->AddBangDingPackage(itemId,itemNum);
						SendSysInfo(pUser,MakeStringColor(sysInfo,TIPS_WARNING_COLOR).c_str());
					}
					else if (itemId == HDAT_PET) // 神将
					{
						if (itemNum == 1)
						{
							::AddPet(pUser,28,1);
							SaveDate(pUser,7,28);
							SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_1532,TIPS_WARNING_COLOR).c_str());
						}
						else if (itemNum == 2)
						{
							::AddPet(pUser,38,1);
							SaveDate(pUser,7,38);
							SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_1533,TIPS_WARNING_COLOR).c_str());
						}
						else if (itemNum == 3)
						{
							::AddPet(pUser,39,1);
							SaveDate(pUser,7,39);
							SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_1534,TIPS_WARNING_COLOR).c_str());
						}
					}
					else if (itemId == HDAT_EQUIP) // 装备
					{
						if (itemNum == 1)
						{

						}
						else if (itemNum == 2)
						{

						}
					}
				}
				msg<<PRO_SUCCESS<<taoCanId;
				m_socketServer.SendMsg(pUser->GetSock(),msg);

				snprintf(sysInfo,sizeof(sysInfo),LANGUAGE_TRANSFORM_1541,ROLE_NAME_COLOR,pUser->GetName(),ITEM_NAME_COLOR,taocanName[taoCanId]);
				SysInfoToAllUser(sysInfo);
				SendSysNotice(pUser);
			}
			break;
		}
	case HD_DENGLULIBAO:
		{
			const uint8 dl_max_reward = 3; // 最多可以领取的奖励数
			const uint16 dl_type_yuanbao = HDAT_BANG_YB; // 类型 绑定元宝
//			const uint16 AWARD_LIST[][2] = {{1800,2},{dl_type_yuanbao,20},{dl_type_yuanbao,30}};
			const uint16 AWARD_LIST[dl_max_reward][2] = {{1800,2},{852,1},{614,2}};

//			const uint16 ItemId = 1800;
//			const uint16 ItemNum = 2;
//			const uint16 YB_Num1 = 20;
//			const uint16 YB_Num2 = 30;
			uint8 op1 = 0;
			msg>>op1;
			if (op1 == 1) // 状态请求
			{
				//int curDay = GetDay();
				//int lastDay = pUser->GetExtData8(91); // 上次登陆天数
				int sumDay = pUser->GetExtData8(92); // 连续登陆天数
				if (sumDay > 3)
					sumDay = 3;
				msg<<(uint8)sumDay<<(uint8)pUser->HaveBitSet(312)<<(uint8)pUser->HaveBitSet(313)<<(uint8)pUser->HaveBitSet(314);
				msg<<AWARD_LIST[0][0]<<AWARD_LIST[0][1]<<AWARD_LIST[1][0]<<AWARD_LIST[1][1]<<AWARD_LIST[2][0]<<AWARD_LIST[2][1];
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			else if (op1 == 2) // 礼包领取
			{
				uint8 pos = dl_max_reward;
				msg>>pos;
				msg.ReWrite();
				msg.SetType(MSG_TMP_HUODONG);
				msg<<(uint8)HD_DENGLULIBAO<<op1;
				if (pos >= dl_max_reward)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1542,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				int sumDay = pUser->GetExtData8(92); // 连续登陆天数
				if (pos > sumDay)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1543,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				if (pUser->HaveBitSet(312+pos))
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1544,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				pUser->SetBitSet(312+pos);
				char buf[128];
				if(AWARD_LIST[pos][0] == dl_type_yuanbao)
				{
					pUser->AddTongBao(AWARD_LIST[pos][1],1);
					snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1545,AWARD_LIST[pos][1]);
					SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
				}
				else
				{
					pUser->AddBangDingPackage(AWARD_LIST[pos][0],AWARD_LIST[pos][1]);
					snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1546,GetItemName(AWARD_LIST[pos][0]),AWARD_LIST[pos][1]);
					SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
				}

				msg<<PRO_SUCCESS<<pos;
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				pUser->Send_HuoDongMsg();
				SendSysNotice(pUser);
			}
			break;
		}
	case HD_CHONGZHISONGLI:
		{
			const uint8 czsl_max_stage = 10; // 奖励档次数
			const uint8 czsl_reward_num = 3; // 奖励物品个数
			const uint8 czsl_parm_num = 2; // 奖励参数个数
			static uint16 czsl_type_pet = HDAT_PET; // 神将类型
			static uint16 czsl_type_equip = HDAT_EQUIP; // 装备类型
			static uint16 CZSL_STAGE_REWARD[czsl_max_stage][czsl_reward_num][czsl_parm_num] = { // 阶段档次奖励
				{
					{2377,1},{851,8},{0,0}
				},
				{
					{851,12},{502,1},{0,0}
				},
				{
					{2370,25},{2310,10},{0,0}
				},
				{
					{2378,1},{802,2},{0,0}
				},
				{
					{czsl_type_pet,37},{2370,15},{0,0}
				},
				{
					{804,4},{503,2},{2251,25}
				},
				{
					{czsl_type_pet,32},{2370,90},{804,1}
				},
				{
					{805,5},{2311,40},{0,0}
				},
				{
					{czsl_type_pet,38},{806,1},{2312,10}
				},
				{
					{czsl_type_pet,39},{2312,15},{0,0}
				}
			};

			static int CZSL_STAGE_CONDITION[czsl_max_stage][czsl_parm_num] = { // 阶段奖励条件
				{100,315},
				{200,316},
				{500,317},
				{1000,318},
				{2000,319},
				{5000,320},
				{10000,321},
				{20000,322},
				{50000,323},
				{100000,324},
//				{100000,325}
			};

			static bool czsl_isInit = false;
			static SItemInstance item50000_5; // 战士
			static SItemInstance item50000_1; // 法师
			static SItemInstance item50000_2; // 刺客
			if (!czsl_isInit)
			{
				czsl_isInit = true;
			}

			uint8 op1 = 0;
			msg>>op1;
			if (op1 == 1) // 查看状态
			{
				int curCZ = pUser->GetExtData32(14); // 当前累计充值RMB数
				msg<<curCZ<<czsl_max_stage;
				uint16 itemId = 0;
				uint16 itemNum = 0;
				for (int i = 0; i < czsl_max_stage; ++i)
				{
					msg<<CZSL_STAGE_CONDITION[i][0]<<(uint8)pUser->HaveBitSet(CZSL_STAGE_CONDITION[i][1]); // 金额、是否已经领取
					for (int j = 0; j < czsl_reward_num; ++j)
					{
						itemId = CZSL_STAGE_REWARD[i][j][0];
						itemNum = CZSL_STAGE_REWARD[i][j][1];
						msg<<itemId;
						if (itemId == czsl_type_pet)
						{
							MakePetMsg(pUser,msg,itemNum);
						}
						else if (itemId == czsl_type_equip)
						{
							if (itemNum == 1)
							{

							}
						}
						else
							msg<<itemNum;
					}
				}
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			else if (op1 == 2) // 领取奖励
			{
				uint8 getStage = czsl_max_stage;
				msg>>getStage;

				msg.ReWrite();
				msg.SetType(MSG_TMP_HUODONG);
				msg<<(uint8)HD_CHONGZHISONGLI<<op1;
				if (getStage >= czsl_max_stage)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1547,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				int curCZ = pUser->GetExtData32(14); // 当前累计充值RMB数
				if (CZSL_STAGE_CONDITION[getStage][0] > curCZ)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1548,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				if (pUser->HaveBitSet(CZSL_STAGE_CONDITION[getStage][1]))
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1549,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				pUser->SetBitSet(CZSL_STAGE_CONDITION[getStage][1]);
				int itemId = 0;
				int itemNum = 0;
				char sysInfo[32];
				for (int i = 0; i < czsl_reward_num; ++i)
				{
					itemId = CZSL_STAGE_REWARD[getStage][i][0];
					itemNum = CZSL_STAGE_REWARD[getStage][i][1];
					if (itemId == 0)
						continue;
					else if (itemId == czsl_type_pet)
					{
						::AddPet(pUser,itemNum,1);
						SaveDate(pUser,10,itemNum);
						snprintf(sysInfo,sizeof(sysInfo),LANGUAGE_TRANSFORM_1551,GetPetName(itemNum));
						SendSysInfo(pUser,MakeStringColor(sysInfo,TIPS_WARNING_COLOR).c_str());
					}
					else if (itemId == czsl_type_equip)
					{
						if (itemNum == 1)
						{

						}
					}
					else
					{
						snprintf(sysInfo,sizeof(sysInfo),LANGUAGE_TRANSFORM_1555,GetItemName(itemId),itemNum);
						while(itemNum > EItemDieJiaNum)
						{
							pUser->AddBangDingPackage(itemId,EItemDieJiaNum);
							itemNum -= EItemDieJiaNum;
						}
						pUser->AddBangDingPackage(itemId,itemNum);
						SendSysInfo(pUser,MakeStringColor(sysInfo,TIPS_WARNING_COLOR).c_str());
					}
				}
				msg<<PRO_SUCCESS<<getStage;
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				SendSysNotice(pUser);
			}
			break;
		}
	case HD_KAIFUCHONGJI:
		{
			const uint32 plusTime = 30*60; // 多余半小时
			const int kfcj_num = 10; // 开服冲级活动人数
			uint32 type = CHuoDongAwardManager::KAI_FU_CHONGJISAI;
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
			uint32 leijiTime = awardManager.GetHuoDongLeijiTime(type); // 更新榜单结束时间
			uint32 endTime = leijiTime+plusTime;

			// CGetDbConnect getDb;
			// CDatabaseSql *pDb = getDb.GetDbConnect();
			// if(pDb == NULL)
			// 	return;
			uint32 curTime = GetSysTime(); // 当前时间

			//static uint32 lastCheckTime = 0; // 上次检查数据库的时间
			int roleIdArr[kfcj_num] = {0};
			int roleLvArr[kfcj_num] = {0};
			string roleNameArr[kfcj_num];
			int idx = 0;
			if(curTime < endTime) // 即时更新
			{
				// if(!pDb->Query("select role_id,level,role_name,xiang,bang,data from level_rank where type=1 and rank<=10 order by rank asc"))
				// 	return;
				memset(roleIdArr,0,sizeof(roleIdArr));
				memset(roleLvArr,0,sizeof(roleLvArr));
				//char** row = NULL;
				vector<SLRankData> vecRankData;
	    		//改为内存数据
//				SingletonCRankDataMgr::instance().GetRankData(ECRT_Level,kfcj_num,vecRankData);
				for(int i=0;i<(int)vecRankData.size();i++)
				{
					roleIdArr[i] = vecRankData[i].role_id;
					roleLvArr[i] = vecRankData[i].level;
					roleNameArr[i] = vecRankData[i].role_name;		
				}
				idx = (int)vecRankData.size();
				//lastCheckTime = curTime;
			}

			if(curTime >= endTime) // 活动已经完全结束
			{
				string res = GetGlobalVaribleData(EGV_KFCJS);
				if(res.length() == 0)
					return;
				char buf[1024];
				strncpy(buf,res.c_str(),sizeof(buf));
				char *p[kfcj_num*3];
				int limit = SplitLine(p, kfcj_num*3, buf);
				msg<<(int)0<<(uint8)(limit/3);
				for(int i = 0; i < (limit/3); ++i)
				{
					msg<<atoi(p[i*3])<<(uint16)atoi(p[i*3+1])<<p[i*3+2]<<KaiFuChongJiSaiGetReward(i+1);
				}
				SendSysNotice(pUser);
			}
			else
			{
				if(curTime >= leijiTime) // 活动刚刚结束
					msg<<(int)0;
				else		// 活动进行中
					msg<<(int)(leijiTime-curTime);
				msg<<(uint8)idx;
				for(int i = 0; i < idx; ++i)
				{
					msg<<roleIdArr[i]<<(uint16)roleLvArr[i]<<roleNameArr[i]<<KaiFuChongJiSaiGetReward(i+1);
				}
				SendSysNotice(pUser);
			}
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			break;
		}
	case HD_XINFUZHANLIBANG:
		{
			const int plusTime = 30*60; // 多余一个小时十五分钟
			const int xfzlb_num = 10; // 开服冲级活动人数
			uint32 type = CHuoDongAwardManager::XIN_FU_ZHANLIBANG;
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
			uint32 leijiTime = awardManager.GetHuoDongLeijiTime(type); // 更新榜单结束时间
			uint32 endTime = leijiTime+plusTime;

			// CGetDbConnect getDb;
			// CDatabaseSql *pDb = getDb.GetDbConnect();
			// if(pDb == NULL)
			// 	return;
			uint32 curTime = GetSysTime(); // 当前时间

			//static uint32 lastCheckTime = 0; // 上次检查数据库的时间
			int roleIdArr[xfzlb_num] = {0};
			int rolePowerArr[xfzlb_num] = {0};
			string roleNameArr[xfzlb_num];
			int idx = 0;
			if(curTime < endTime) // 即时更新、读内存数据
			{
				// //						   0	  1       2	      3    4    5
				// if(!pDb->Query("select role_id,level,role_name,xiang,bang,data from level_rank where type=21 order by rank limit 10"))
				// 	return;
				memset(roleIdArr,0,sizeof(roleIdArr));
				memset(rolePowerArr,0,sizeof(rolePowerArr));
				memset(roleNameArr,0,sizeof(roleNameArr));
				idx = 0;
				//char **row = NULL;
				vector<SLRankData> vecRankData;
	    		//改为内存数据
//				SingletonCRankDataMgr::instance().GetRankData(ECRT_Power,xfzlb_num,vecRankData);
				for(int i=0;i<(int)vecRankData.size();i++)
				{
					roleIdArr[i] = vecRankData[i].role_id;
					rolePowerArr[i] = (uint32)(1.5f*vecRankData[i].data);
					roleNameArr[i] = vecRankData[i].role_name;		
				}
				idx = (int)vecRankData.size();
				//lastCheckTime = curTime;
			}

			if(curTime >= endTime) // 活动已经完全结束
			{
				string res = GetGlobalVaribleData(EGV_XFZLB);
				if(res.length() == 0)
					return;
				char buf[512];
				strncpy(buf,res.c_str(),sizeof(buf));
				char *p[xfzlb_num*3];
				int limit = SplitLine(p, xfzlb_num*3, buf);
				msg<<(int)0<<(uint8)(limit/3);
				for (int i = 0; i < (limit/3); ++i)
				{
					msg<<atoi(p[i*3])<<atoi(p[i*3+1])<<p[i*3+2]<<XinFuZhanLiBangGetReward(i+1);
				}
				SendSysNotice(pUser);
			}
			else
			{
				if(curTime >= leijiTime) // 活动刚刚结束
					msg<<(int)0;
				else	// 活动进行中
					msg<<(int)(leijiTime-curTime);
				msg<<(uint8)idx;
				for(int i = 0; i < idx; ++i)
				{
					msg<<roleIdArr[i]<<rolePowerArr[i]<<roleNameArr[i]<<XinFuZhanLiBangGetReward(i+1);
				}
				SendSysNotice(pUser);
			}
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			break;
		}
	case HD_XIANCHONGDASHOUJI:
		{
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
			uint8 xcdsj_max_stage = 0; // 档次数
			uint8 xcdsj_item_num = 0; // 每档次物品个数

			GetXCDSJArrayInfo(xcdsj_max_stage, xcdsj_item_num);
			
			int endTime = awardManager.GetHuoDongEndTime(CHuoDongAwardManager::XIAN_CHONG_DASHOUJI);
			int leftTime = endTime - (int)GetSysTime(); // 剩余有效时间 秒
			if(leftTime < 0)
				leftTime = 0;

			uint8 op1 = 0;
			msg>>op1;
			if (op1 == 1) // 查看状态
			{
				msg<<leftTime<<xcdsj_max_stage;
				uint16 itemId = 0;
				uint16 itemNum = 0;
				for (int i = 0; i < xcdsj_max_stage; ++i)
				{
					msg<<(uint8)GetXCDSJConditionInfo(i,0)<<(uint8)pUser->GetPetQualityNum(GetXCDSJConditionInfo(i,0))<<(uint8)GetXCDSJConditionInfo(i,1)<<(uint8)pUser->HaveBitSet(GetXCDSJConditionInfo(i,2));
					for (int j = 0; j < xcdsj_item_num; ++j)
					{
						itemId = GetXCDSJRewardInfo(i,j,0);
						itemNum = GetXCDSJRewardInfo(i,j,1);
						msg<<itemId<<itemNum;
					}
				}
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			else if (op1 ==2) // 领取
			{
				uint8 getReward = xcdsj_max_stage;
				msg>>getReward;
				msg.ReWrite();
				msg.SetType(MSG_TMP_HUODONG);
				msg<<(uint8)HD_XIANCHONGDASHOUJI<<op1;

				if(!awardManager.InHuoDongTime(CHuoDongAwardManager::XIAN_CHONG_DASHOUJI))
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1556,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				if(getReward >= xcdsj_max_stage)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1557,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				int hasCnt = pUser->GetPetQualityNum(GetXCDSJConditionInfo(getReward,0));
				int needCnt = GetXCDSJConditionInfo(getReward,1);
				bool isGot = pUser->HaveBitSet(GetXCDSJConditionInfo(getReward,2));
				if (hasCnt < needCnt)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1558,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				if (isGot)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1559,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				pUser->SetBitSet(GetXCDSJConditionInfo(getReward,2));
				int itemId = 0;
				int itemNum = 0;
				char sysInfo[32];
				for (int i = 0; i < xcdsj_item_num; ++i)
				{
					itemId = GetXCDSJRewardInfo(getReward,i,0);
					itemNum = GetXCDSJRewardInfo(getReward,i,1);
					if (itemId != 0)
					{
						pUser->AddBangDingPackage(itemId,itemNum);
						snprintf(sysInfo,sizeof(sysInfo),LANGUAGE_TRANSFORM_1560,GetItemName(itemId),itemNum);
						SendSysInfo(pUser,MakeStringColor(sysInfo,TIPS_WARNING_COLOR).c_str());

						SaveDate(pUser,CHuoDongAwardManager::XIAN_CHONG_DASHOUJI,1,sysInfo);
					}
				}
				msg<<PRO_SUCCESS<<getReward;
				m_socketServer.SendMsg(pUser->GetSock(),msg);

				NoticeHuoDongHotPoint(pUser, CHuoDongAwardManager::XIAN_CHONG_DASHOUJI);
				SendSysNotice(pUser);
			}
			break;
		}
	case HD_QIANGZHUANGLINGHAOLI:
		{
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
			uint8 qzlhl_max_stage = 0; // 档次数
			uint8 qzlhl_item_num = 0; // 每档次物品个数
			GetQZLHLArrayInfo(qzlhl_max_stage,qzlhl_item_num);

			int endTime = awardManager.GetHuoDongEndTime(CHuoDongAwardManager::QIANG_ZHUANG_LINGHAOLI);
			int leftTime = endTime - (int)GetSysTime(); // 剩余有效时间 秒
			if(leftTime < 0)
				leftTime = 0;

			uint8 op1 = 0;
			msg>>op1;
			if (op1 == 1) // 查看状态
			{
				msg<<leftTime<<qzlhl_max_stage;
				uint16 itemId = 0;
				uint16 itemNum = 0;
				for (int i = 0; i < qzlhl_max_stage; ++i)
				{
//					msg<<(uint8)GetQZLHLConditionInfo(i,0)<<(uint8)pUser->GetEquipStrengthLvNum(GetQZLHLConditionInfo(i,0))<<(uint8)GetQZLHLConditionInfo(i,1)<<(uint8)pUser->HaveBitSet(GetQZLHLConditionInfo(i,2));
					for (int j = 0; j < qzlhl_item_num; ++j)
					{
						itemId = GetQZLHLRewardInfo(i,j,0);
						itemNum = GetQZLHLRewardInfo(i,j,1);
						msg<<itemId<<itemNum;
					}
				}
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			else if (op1 ==2) // 领取
			{
				uint8 getReward = qzlhl_max_stage;
				msg>>getReward;
				msg.ReWrite();
				msg.SetType(MSG_TMP_HUODONG);
				msg<<(uint8)HD_QIANGZHUANGLINGHAOLI<<op1;

				if(!awardManager.InHuoDongTime(CHuoDongAwardManager::QIANG_ZHUANG_LINGHAOLI))
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1561,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				if (getReward >= qzlhl_max_stage)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1562,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
//				int hasCnt = pUser->GetEquipStrengthLvNum(GetQZLHLConditionInfo(getReward,0));
//				int needCnt = GetQZLHLConditionInfo(getReward,1);
				bool isGot = pUser->HaveBitSet(GetQZLHLConditionInfo(getReward,2));
//				if (hasCnt < needCnt)
//				{
//					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1563,TIPS_FAILURE_COLOR);
//					m_socketServer.SendMsg(pUser->GetSock(),msg);
//					return;
//				}
				if (isGot)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1564,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				pUser->SetBitSet(GetQZLHLConditionInfo(getReward,2));
				int itemId = 0;
				int itemNum = 0;
				char sysInfo[32];
				for (int i = 0; i < qzlhl_item_num; ++i)
				{
					itemId = GetQZLHLRewardInfo(getReward,i,0);
					itemNum = GetQZLHLRewardInfo(getReward,i,1);
					if (itemId != 0)
					{
						pUser->AddBangDingPackage(itemId,itemNum);
						snprintf(sysInfo,sizeof(sysInfo),LANGUAGE_TRANSFORM_1565,GetItemName(itemId),itemNum);
						SendSysInfo(pUser,MakeStringColor(sysInfo,TIPS_WARNING_COLOR).c_str());

						SaveDate(pUser,CHuoDongAwardManager::QIANG_ZHUANG_LINGHAOLI,1,sysInfo);
					}
				}
				msg<<PRO_SUCCESS<<getReward;
				m_socketServer.SendMsg(pUser->GetSock(),msg);

				NoticeHuoDongHotPoint(pUser, CHuoDongAwardManager::QIANG_ZHUANG_LINGHAOLI);
				SendSysNotice(pUser);
			}
			break;
		}
	case HD_YAO_QIAN_SHU:	// 摇钱树
		{
			// CHECK_SYSTEM_OPEN(SOT_MoneyTree)
			CYaoQianShuMgr &mgr = SingletonCYaoQianShuMgr::instance();
			uint8 op1=0;
			msg>>op1;

			if(op1 == 1)	// 获取摇钱树信息
			{
				const uint8 num = 2;
				msg << PRO_SUCCESS << num;
				for (uint8 i = 0; i < num; i++)
				{
					uint8 type = i+1;
					uint8 joinNum = pUser->GetExtData8(type == 1 ? 377 : 378);
					uint8 freeNum = G_VipConfig[pUser->GetVipLevel()].yaoqianshuNum[i];
					uint8 maxNum = mgr.GetTypeTimes(type);
					SYaoQianShuData data;
					if (joinNum < maxNum) // 还能进入的时候查配置
					{
						if (!mgr.GetCfg(type, joinNum + 1, data))
						{
							msg << PRO_ERROR << MakeStringColor(LANGUAGE_SSJ_0416, TIPS_FAILURE_COLOR);
							m_socketServer.SendMsg(sock, msg);
							return;
						}
					}
					if (joinNum < freeNum)
					{
						data.cost_value = 0;
					}
					msg<<type<<joinNum<<freeNum<<maxNum<<data.cost_type<<data.cost_value<<data.get_type<<data.get_value;
				}
				m_socketServer.SendMsg(sock,msg);
			}
			else if(op1 == 2)	// 摇钱
			{
				uint8 type = 0;
				msg>>type;
				if(type == 0 || type > 2)
					return;

				uint8 joinNum = pUser->GetExtData8(type == 1 ? 377 : 378);
				uint8 freeNum = G_VipConfig[pUser->GetVipLevel()].yaoqianshuNum[type == 1 ? 0 : 1];
				uint8 maxNum = mgr.GetTypeTimes(type);
				SYaoQianShuData data;
				if (joinNum >= maxNum)
				{
					data.get_value = 0;
				}
				else
				{
					if (!mgr.GetCfg(type, joinNum + 1, data))
					{
						msg << PRO_ERROR << MakeStringColor(LANGUAGE_SSJ_0416, TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(sock, msg);
						return;
					}
				}

				if(!mgr.GetCfg(type,joinNum+1,data))
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0416,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}
				if (joinNum < freeNum)
				{
					data.cost_value = 0;
				}
				if(joinNum >= maxNum)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0417,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}
				if(data.cost_type == HDAT_MONEY)
				{
					if(pUser->GetMoney() < (int)data.cost_value)
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0418,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(sock,msg);
						return;
					}
					pUser->AddMoney(-data.cost_value);
				}
				else if(data.cost_type == HDAT_BANG_YB)
				{
					if(pUser->GetTongBao(1) < (int)data.cost_value)
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0419,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(sock,msg);
						return;
					}
					pUser->AddTongBao(-data.cost_value,1);
				}
				else if(data.cost_type == HDAT_YB)
				{
					if(pUser->GetTongBao() < (int)data.cost_value)
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0420,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(sock,msg);
						return;
					}
					pUser->AddTongBao(-data.cost_value);
				}
				else
				{
					return;
				}

				char buf[256];
				if(data.get_type == HDAT_MONEY)
				{
					pUser->AddMoney(data.get_value);
					snprintf(buf,sizeof(buf),"%s%u",LANGUAGE_SSJ_0421,data.get_value);
					SaveDate(pUser,24,data.get_value,LANGUAGE_LLD_0106);
				}
				else if(data.get_type == HDAT_BANG_YB)
				{
					pUser->AddTongBao(data.get_value,1);
					snprintf(buf,sizeof(buf),"%s%u",LANGUAGE_SSJ_0422,data.get_value);
					SaveDate(pUser,24,data.get_value,LANGUAGE_LLD_0107);
				}
				else if(data.get_type == HDAT_YB)
				{
					pUser->AddTongBao(data.get_value);
					snprintf(buf,sizeof(buf),"%s%u",LANGUAGE_SSJ_0423,data.get_value);
					SaveDate(pUser,24,data.get_value,LANGUAGE_LLD_0108);
				}
				else
					return;

				if(type == 1)
					pUser->SetExtData8(377,pUser->GetExtData8(377)+1);
				else if(type == 2)
					pUser->SetExtData8(378,pUser->GetExtData8(378)+1);

				pUser->SetExtData8(576,pUser->GetExtData8(576) + 1);
				pUser->SetBitSet(508);

				joinNum++;
				if (joinNum < freeNum)
				{
					data.cost_value = 0;
				}
				if (joinNum >= maxNum)
				{
					data.Clear();
				}
				else
				{
					if (!mgr.GetCfg(type, joinNum + 1, data))
					{
						msg << PRO_ERROR << MakeStringColor(LANGUAGE_SSJ_0416, TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(sock, msg);
						return;
					}

					if (joinNum+1 <= freeNum)
					{
						data.cost_value = 0;
					}
				}
				msg<<PRO_SUCCESS<<joinNum<<freeNum<<maxNum<<data.cost_type<<data.cost_value<<data.get_type<<data.get_value;
				m_socketServer.SendMsg(sock,msg);
				SingletonCMissionManager::instance().UpdateDCMissionComplate(pUser, EMISS_DC_58);
			}
		}
		break;

	case HD_MEIRI_SHOUCHONG:    //每日首充活动
		{
			uint32 type = CHuoDongAwardManager::MEIRI_SHOUCHONG;
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
			uint32 isFirstWXDataId = 595;
			uint32 isGetWxDataId = 596;
			
			if (awardManager.InHuoDongTime(type)) {
				uint32 curDay = GetDay();
				
				uint8 op1 = 0;
				msg>>op1;
				if (op1 == 1)
				{
					SHuoDongAward award;
					awardManager.GetAwardData(type,curDay,award);
					msg<<PRO_SUCCESS;
					msg<<(uint8)1;	 //打开微信首冲
					msg<<(uint8)pUser->HaveBitSet(550)<<(uint8)pUser->HaveBitSet(551);
					msg<<(uint8)pUser->HaveBitSet(isFirstWXDataId)<<(uint8)pUser->HaveBitSet(isGetWxDataId);
					
					uint16 pos = msg.GetDataLen();
					uint8 typeNum = 0;
					msg<<typeNum;

					typeNum = MakeAwardMsg(pUser, award, type, msg);
					msg.WriteData(pos,&typeNum,sizeof(typeNum));
					m_socketServer.SendMsg(pUser->GetSock(),msg);
				}
				else if (op1 == 2)
				{
					if (!pUser->HaveBitSet(550))
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1569,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						return;
					}
					else if (pUser->HaveBitSet(551))
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1570,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						return;
					}
					else if (pUser->HaveBitSet(550) && !pUser->HaveBitSet(551))
					{
						pUser->SetBitSet(551);
						pUser->SetExtData32(204, 0);
						SHuoDongAward award;
						awardManager.GetAwardData(type,curDay, award);
						for(uint8 i=0;i < CHuoDongAwardManager::SHOUCHONG_AWARD_NUM && i < SHuoDongAward::AWARD_NUM;i++)
							AddHuoDongAward(pUser,type,award.award[i],award.num[i],award.petQuality[i],award.petQualityLv[i]);
						msg<<PRO_SUCCESS;
						m_socketServer.SendMsg(pUser->GetSock(),msg);

						NoticeHuoDongHotPoint(pUser, type);
					}
				}
				else if (op1 == 3)
				{
					if (!pUser->HaveBitSet(isFirstWXDataId))
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1569,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						return;
					}
					else if (pUser->HaveBitSet(isGetWxDataId))
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1570,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						return;
					}
					else if (pUser->HaveBitSet(isFirstWXDataId) && !pUser->HaveBitSet(isGetWxDataId))
					{
						pUser->SetBitSet(isGetWxDataId);
						pUser->SetExtData32(409, 0);
						SHuoDongAward award;
						awardManager.GetAwardData(type,curDay, award);
						uint32 idx = CHuoDongAwardManager::SHOUCHONG_WEIXIN_IDX - 1;
						AddHuoDongAward(pUser,type,award.award[idx],award.num[idx],award.petQuality[idx],award.petQualityLv[idx]);
						msg<<PRO_SUCCESS;
						m_socketServer.SendMsg(pUser->GetSock(),msg);

						NoticeHuoDongHotPoint(pUser, type);
					}
				}
				else
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1571,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);	
				}
			}
			else
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1572,TIPS_FAILURE_COLOR);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
		}
		break;
	case HD_JIERI_LIBAO:	//节日礼包
	case HD_JIERI_LIBAO2:	//节日礼包2
		{
			uint32 type = CHuoDongAwardManager::JIERI_LIBAO;
			int YBL_RECORD = YBL_JIERI_LIBAO;
			if (op == HD_JIERI_LIBAO2)
			{
				type = CHuoDongAwardManager::JIERI_LIBAO2;
				YBL_RECORD = YBL_JIERI_LIBAO2;
			}
			
			uint32 curTime = GetSysTime();
			uint32 pic = 0;
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();

			if (awardManager.InHuoDongTime(type)) {
				pUser->JieRiLiBaoClearData(type);
				uint8 op1 = 0;
				msg>>op1;
				if (op1 == 1)
				{
					vector<HDPeiZhiInfo> libaoInfo;
					awardManager.GetPeiZhiInfo(libaoInfo,type);
					if (libaoInfo.size() <= 0)
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1573,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						return;
					}
					
					pic = awardManager.GetHuoDongPic(type);
					msg<<PRO_SUCCESS << pic << awardManager.GetHuoDongEndTime(type)- curTime;
					msg<<(uint8)libaoInfo.size();
					for (uint32 i = 0; i < libaoInfo.size(); i++)
					{
						uint32 lastTime = pUser->GetExtData32(libaoInfo[i].saveLastTimeId);
						uint32 cdTime = (lastTime == 0 || curTime > lastTime) ? 0 : (lastTime - curTime);
						uint8 getTimes = libaoInfo[i].num - pUser->GetExtData8(libaoInfo[i].saveCountId);
						//     颜色                      cd       price                      times
						msg<<(uint8)libaoInfo[i].index<<cdTime<<(uint32)libaoInfo[i].price<<getTimes;

						uint32 index = libaoInfo[i].firstId + pUser->GetExtData8(libaoInfo[i].saveCountId);
						SHuoDongAward award;
						awardManager.GetAwardData(type,index, award);
						
						uint16 pos = msg.GetDataLen();
						uint8 typeNum = 0;
						msg<<typeNum;
						typeNum = MakeAwardMsg(pUser,award,type,msg);
						msg.WriteData(pos,&typeNum,sizeof(typeNum));
					}	
					m_socketServer.SendMsg(pUser->GetSock(),msg);
				}
				else if (op1 == 2)
				{
					uint8 color = 0;
					bool isFind = false;
					vector<HDPeiZhiInfo> libaoInfo;
					awardManager.GetPeiZhiInfo(libaoInfo,type);
					if (libaoInfo.size() <= 0)
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1574,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						return;
					}
					
					msg >> color;
					for (uint32 i = 0; i < libaoInfo.size(); i++)
					{
						if (libaoInfo[i].index == color) {
							uint32 lastTime = pUser->GetExtData32(libaoInfo[i].saveLastTimeId);
							uint32 cdTime = (lastTime == 0 || curTime > lastTime) ? 0 : (lastTime - curTime); 
							if (cdTime > 0)
							{
								msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1575,TIPS_FAILURE_COLOR);
							}
							else if (pUser->GetExtData8(libaoInfo[i].saveCountId) >= libaoInfo[i].num)
							{
								msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1576,TIPS_FAILURE_COLOR);
							}
							else if(pUser->GetTongBao() < (int)libaoInfo[i].price)
							{
								msg<<PRO_ERROR<<"";
								m_socketServer.SendMsg(pUser->GetSock(),msg);
								ShowJumpNotice(pUser,JUMP_NOTICE_YB);
								return;
							}
							else
							{
								pUser->AddTongBao(-libaoInfo[i].price);
								uint32 index = libaoInfo[i].firstId + pUser->GetExtData8(libaoInfo[i].saveCountId);
								SHuoDongAward award;
								awardManager.GetAwardData(type,index, award);
								for(uint8 j=0;j < SHuoDongAward::AWARD_NUM;j++)
								{
									AddHuoDongAward(pUser,type,award.award[j],award.num[j],award.petQuality[j],award.petQualityLv[j]);

									if (award.award[j] > 0 && award.num[j] > 0)
									{	
										ItemCurrencyLog(pUser->GetRoleId(),award.award[j],award.num[j],0,libaoInfo[i].price,pUser->GetTongBao(),YBL_RECORD);
									}
								}
								msg<<PRO_SUCCESS;
								
								pUser->SetExtData8(libaoInfo[i].saveCountId, pUser->GetExtData8(libaoInfo[i].saveCountId) + 1);
								pUser->SetExtData32(libaoInfo[i].saveLastTimeId, GetSysTime() + libaoInfo[i].cd);
							}
							isFind = true;
							break;
						}
					}

					if (! isFind)
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1577,TIPS_FAILURE_COLOR);

					m_socketServer.SendMsg(pUser->GetSock(),msg);

					NoticeHuoDongHotPoint(pUser, type);
				}
			}
			else
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1578,TIPS_FAILURE_COLOR);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
		}
		break;
	case HD_LEI_JI_CHONGZHI:	// 累计充值
	case HD_LEI_JI_CHONGZHI2:	// 累计充值2
		{
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
			uint32 type = CHuoDongAwardManager::LEI_JI_CHONGZHI;
			uint32 totalCZDataId = 119;
			uint32 maskDataId = 121;
			if (op == HD_LEI_JI_CHONGZHI2)
			{
				type = CHuoDongAwardManager::LEI_JI_CHONGZHI2;
				totalCZDataId = 137;
				maskDataId = 139;
			}
			
			uint8 op1=0;	// 0获取列表信息，1领取奖励
			msg>>op1;

			if(!awardManager.InHuoDongTime(type))
				return;
			
			if(op1 == 0)	// 获取列表
			{
				vector<uint32> idxList;
				awardManager.GetAwardIdxList(type,idxList);
				if(idxList.empty())
					return;
				uint32 totalChongZhi = pUser->GetExtData32(totalCZDataId);
				uint32 getMask = pUser->GetExtData32(maskDataId);
				uint8 num = idxList.size();
				if(num > 32)
					num = 32;
				msg<<totalChongZhi<<awardManager.GetHuoDongTimeDesc(type)<<num;
				for(uint8 i=0;i < num;i++)
				{
					SHuoDongAward award;
					uint8 isGet = ((getMask&(1<<i)) == 0) ? (uint8)0 : (uint8)1;
					uint32 needYB = awardManager.GetNeedYB(type,idxList[i]);
					awardManager.GetAwardData(type,idxList[i],award);
					msg<<i<<needYB<<isGet;
					uint16 pos = msg.GetDataLen();
					uint8 typeNum = 0;
					msg<<typeNum;
					typeNum = MakeAwardMsg(pUser, award, type, msg);
					msg.WriteData(pos,&typeNum,sizeof(typeNum));
				}
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			else if(op1 == 1)	// 领取奖励
			{
				uint8 index = 0xff;	// 领奖
				msg>>index;
				
				if(index > 31)	// 32位标识
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1579,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				uint32 getMask = pUser->GetExtData32(maskDataId);
				if((getMask & (1<<index)) == 0)		// 未领取
				{
					vector<uint32> idxList;
					awardManager.GetAwardIdxList(type,idxList);
					if((uint8)(index+1) > idxList.size())
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1580,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						return;
					}
					uint32 totalChongZhi = pUser->GetExtData32(totalCZDataId);
					uint32 needYB = awardManager.GetNeedYB(type,idxList[index]);
					if(totalChongZhi < needYB)
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1581,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						return;
					}

					SHuoDongAward award;
					awardManager.GetAwardData(type,idxList[index],award);
					string awardStr = "";
					char buf[256];
					for (uint8 i = 0; i < SHuoDongAward::AWARD_NUM; i++)
					{
						AddHuoDongAward(pUser, type, award.award[i], award.num[i], award.petQuality[i], award.petQualityLv[i]);
						MakeAwardString(award.award[i], award.num[i], awardStr);
					}
					snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0033, pUser->GetName(), awardStr.c_str());
					SysInfoToAllUser(buf);

					getMask |= (1<<index);
					pUser->SetExtData32(maskDataId,getMask);
					msg<<PRO_SUCCESS;
					m_socketServer.SendMsg(pUser->GetSock(),msg);

					NoticeHuoDongHotPoint(pUser, type);
				}
				else
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1582,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
			}
		}
		break;
	case HD_LEI_JI_XIAO_FEI:	// 累计消费
	case HD_LEI_JI_XIAO_FEI2:	// 累计消费2
		{
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
			uint32 type = CHuoDongAwardManager::LEI_JI_XIAOFEI;
			uint32 totalCZDataId = 122;
			uint32 maskDataId = 124;
			if (op == HD_LEI_JI_XIAO_FEI2)
			{
				type = CHuoDongAwardManager::LEI_JI_XIAOFEI2;
				totalCZDataId = 140;
				maskDataId = 142;
			}
			
			uint8 op1=0;	// 0获取列表信息，1领取奖励
			msg>>op1;

			if(!awardManager.InHuoDongTime(type))
				return;
			
			if(op1 == 0)	// 获取列表
			{
				vector<uint32> idxList;
				awardManager.GetAwardIdxList(type,idxList);
				if(idxList.empty())
					return;
				uint32 totalXiaoFei = pUser->GetExtData32(totalCZDataId);
				uint32 getMask = pUser->GetExtData32(maskDataId);
				uint8 num = idxList.size();
				if(num > 32)
					num = 32;
				msg<<totalXiaoFei<<awardManager.GetHuoDongTimeDesc(type)<<num;
				for(uint8 i=0;i < num;i++)
				{
					SHuoDongAward award;
					uint32 needYB = awardManager.GetNeedYB(type,idxList[i]);
					uint8 isGet = ((getMask&(1<<i)) == 0) ? (uint8)0 : (uint8)1;
					awardManager.GetAwardData(type,idxList[i],award);
					msg<<i<<needYB<<isGet;
					uint16 pos = msg.GetDataLen();
					uint8 typeNum = 0;
					msg<<typeNum;
					typeNum = MakeAwardMsg(pUser, award, type, msg);
					msg.WriteData(pos,&typeNum,sizeof(typeNum));
				}
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			else if(op1 == 1)	// 领取奖励
			{
				uint8 index = 0xff;	// 领奖
				msg>>index;
				
				if(index > 31)	// 32位标识
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1583,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				uint32 getMask = pUser->GetExtData32(maskDataId);
				if((getMask & (1<<index)) == 0)		// 未领取
				{
					vector<uint32> idxList;
					awardManager.GetAwardIdxList(type,idxList);
					if((uint8)(index+1) > idxList.size())
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1584,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						return;
					}
					uint32 totalXiaoFei = pUser->GetExtData32(totalCZDataId);
					uint32 needYB = awardManager.GetNeedYB(type,idxList[index]);
					if(totalXiaoFei < needYB)
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1585,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						return;
					}

					SHuoDongAward award;
					awardManager.GetAwardData(type,idxList[index],award);
					for(uint8 i=0;i < SHuoDongAward::AWARD_NUM;i++)
						AddHuoDongAward(pUser,type,award.award[i],award.num[i],award.petQuality[i],award.petQualityLv[i]);
					getMask |= (1<<index);
					pUser->SetExtData32(maskDataId,getMask);
					msg<<PRO_SUCCESS;
					m_socketServer.SendMsg(pUser->GetSock(),msg);

					NoticeHuoDongHotPoint(pUser, type);
				}
				else
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1586,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
			}
		}
		break;
	case HD_CHONGZHIFANYB: //单日充值返元宝
	case HD_CHONGZHIFANYB2: //单日充值返元宝2
	case HD_CHONGZHIFANYB3: //单日充值返元宝3
	case HD_CHONGZHIFANYB4: //单日充值返元宝4
	case HD_CHONGZHIFANYB5: //单日充值返元宝5
	case HD_CHONGZHIFANYB6:
	case HD_CHONGZHIFANYB7:
	case HD_CHONGZHIFANYB8:
	case HD_CHONGZHIFANYB9:
	case HD_CHONGZHIFANYB10:
		{
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
			uint8 op1=0;	// 0获取列表信息，1领取奖励
			msg>>op1;

			uint32 type = 0;
			uint32 totalCZDataId = 0;
			uint32 maskDataId = 0;
			switch (op)
			{
				case HD_CHONGZHIFANYB:
					type = CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO;
					break;
				case HD_CHONGZHIFANYB2:
					type = CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO2;
					break;
				case HD_CHONGZHIFANYB3:
					type = CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO3;
					break;
				case HD_CHONGZHIFANYB4:
					type = CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO4;
					break;
				case HD_CHONGZHIFANYB5:
					type = CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO5;
					break;
				case HD_CHONGZHIFANYB6:
					type = CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO6;
					break;
				case HD_CHONGZHIFANYB7:
					type = CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO7;
					break;
				case HD_CHONGZHIFANYB8:
					type = CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO8;
					break;
				case HD_CHONGZHIFANYB9:
					type = CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO9;
					break;
				case HD_CHONGZHIFANYB10:
					type = CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO10;
					break;
				default:
					return;
			}

			if ( ! GetChongZhiFanYBDataId(type,totalCZDataId,maskDataId) )
				return;
			
			if(!awardManager.InHuoDongTime(type))
				return;

			if(op1 == 0)	// 获取列表
			{
				vector<uint32> idxList;
				awardManager.GetAwardIdxList(type,idxList);
				if(idxList.empty())
					return;
				uint32 totalChongZhi = pUser->GetExtData32(totalCZDataId);
				uint32 getMask = pUser->GetExtData32(maskDataId);
				uint8 num = idxList.size();
				if(num > 32)
					num = 32;
				msg<<totalChongZhi<<awardManager.GetHuoDongTimeDesc(type)<<num;
				for(uint8 i=0;i < num;i++)
				{
					SHuoDongAward award;
					uint8 isGet = ((getMask&(1<<i)) == 0) ? (uint8)0 : (uint8)1;
					uint32 needYB = awardManager.GetNeedYB(type,idxList[i]);
					awardManager.GetAwardData(type,idxList[i],award);
					msg<<i<<needYB<<isGet;
					uint16 pos = msg.GetDataLen();
					uint8 typeNum = 0;
					msg<<typeNum;
					typeNum = MakeAwardMsg(pUser, award, type, msg);
					msg.WriteData(pos,&typeNum,sizeof(typeNum));
				}
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			else if(op1 == 1)	// 领取奖励
			{
				uint8 index = 0xff; // 领奖
				msg>>index;
			
				if(index > 31)	// 32位标识
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1587,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
	
				uint32 getMask = pUser->GetExtData32(maskDataId);
				if((getMask & (1<<index)) == 0) 	// 未领取
				{
					vector<uint32> idxList;
					awardManager.GetAwardIdxList(type,idxList);
					if((uint8)(index+1) > idxList.size())
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1588,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						return;
					}
					uint32 totalChongZhi = pUser->GetExtData32(totalCZDataId);
					uint32 needYB = awardManager.GetNeedYB(type,idxList[index]);
					if(totalChongZhi < needYB)
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1589,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						return;
					}
	
					SHuoDongAward award;
					awardManager.GetAwardData(type,idxList[index],award);
					for(uint8 i=0;i < SHuoDongAward::AWARD_NUM;i++)
						AddHuoDongAward(pUser,type,award.award[i],award.num[i],award.petQuality[i],award.petQualityLv[i]);
					getMask |= (1<<index);
					pUser->SetExtData32(maskDataId,getMask);
					msg<<PRO_SUCCESS;
					m_socketServer.SendMsg(pUser->GetSock(),msg);

					NoticeHuoDongHotPoint(pUser, type);
				}
				else
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1590,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
			}
		}
		break;
	case HD_HONGLICHONGZHI: //红利大放送 充值
	case HD_HONGLICHONGZHI2: //红利大放送2 充值
	case HD_HONGLICHONGZHI3: //红利大放送3 充值
	case HD_HONGLICHONGZHI4: //红利大放送4 充值
	case HD_HONGLICHONGZHI5: //红利大放送5 充值
	case HD_HONGLICHONGZHI_RMB: //红利大放送 充值 RMB
		{
			uint8 op1=0;	// 0获取列表信息，1领取奖励
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
			uint32 type = 0;
			uint32 timeDataId = 0;
			uint32 leijiDataId = 0;
			uint32 maskDataId = 0;

			switch(op)
			{
				case HD_HONGLICHONGZHI:
					type = CHuoDongAwardManager::HONGLI_CHONGZHI;
					break;
				case HD_HONGLICHONGZHI2:
					type = CHuoDongAwardManager::HONGLI_CHONGZHI2;
					break;
				case HD_HONGLICHONGZHI3:
					type = CHuoDongAwardManager::HONGLI_CHONGZHI3;
					break;
				case HD_HONGLICHONGZHI4:
					type = CHuoDongAwardManager::HONGLI_CHONGZHI4;
					break;
				case HD_HONGLICHONGZHI5:
					type = CHuoDongAwardManager::HONGLI_CHONGZHI5;
					break;
				case HD_HONGLICHONGZHI_RMB:
					type = CHuoDongAwardManager::HONGLI_CHONGZHI_RMB;
					break;
				default:
					return;
			}

			if (!GetHongLiDataId(type,timeDataId,leijiDataId,maskDataId))
				return;
	
			msg>>op1;

			if(!awardManager.InHuoDongTime(type))
				return;

			if(op1 == 0)	// 获取列表
			{
				vector<HDPeiZhiInfo> info;
				uint32 nextTime = 0;
				uint32 hongliLeijiTime = awardManager.GetHuoDongLeijiTime(type);
				uint32 curTime = GetSysTime();
				uint32 curDay = 0;
				uint32 maxDay = 0;
				uint32 cdTime = (curTime > hongliLeijiTime) ? 0 : hongliLeijiTime - curTime;
				uint32 leijiYB = pUser->GetExtData32(leijiDataId);
				uint32 getMask = pUser->GetExtData32(maskDataId);
				uint8 showType = 0;        //玩家当前的档次
				uint8 canGet = 0;          // 0 没有奖励可以领取；1 可以领取 ；2 已经领取完

				if (cdTime == 0)
					curDay = (curTime - hongliLeijiTime) / (24 * 3600) + 1;

				awardManager.GetPeiZhiInfo(info, type);
				if (info.size() <= 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1591,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				msg<<PRO_SUCCESS;
				if (type == CHuoDongAwardManager::HONGLI_CHONGZHI_RMB)
					msg << GetMoney_ByYB(leijiYB);
				else
					msg << leijiYB;
				msg << cdTime << (uint8)info.size();
				for (uint8 i = 0; i < info.size(); i++)
				{
					vector<uint32> idxList;
					awardManager.GetAwardIdxList(type,info[i].index,idxList);
	
					msg << (uint8)info[i].index;
					if (type == CHuoDongAwardManager::HONGLI_CHONGZHI_RMB)
						msg << GetMoney_ByYB(info[i].YB);
					else
						msg << info[i].YB;
						
					uint16 pos = msg.GetDataLen();
					uint32 totalYB = 0;
					msg<<totalYB<<(uint8)idxList.size();

					if (info[i].YB <= leijiYB)
					{
						showType = info[i].index;
					}

					for (uint32 k = 0; k < idxList.size(); k++)
					{
						uint32 day = awardManager.GetIdx3(type, idxList[k]);
						uint8 getState = ((getMask&(1<<day)) == 0) ? (uint8)0 : (uint8)1;

						if (showType != 0 && cdTime == 0 && curDay < day && nextTime == 0)
						{
							nextTime = hongliLeijiTime + 24 * 3600 * (day - 1) - curTime;
						}
						
						if (maxDay < day)
							maxDay = day;
							
						if (cdTime == 0 && getState == 0 && (curDay > day))
							getState = 2;

						if (showType != 0 && cdTime == 0 && getState == 0 && curDay == day)
							canGet = 1;
		
						msg<<day<<getState;

						SHuoDongAward award;
						awardManager.GetAwardData(type,idxList[k],award);

						uint16 pos2 = msg.GetDataLen();
						uint8 typeNum = 0;
						msg << typeNum;
						typeNum = MakeAwardMsg(pUser, award, type, msg, &totalYB);
						msg.WriteData(pos2,&typeNum,sizeof(typeNum));
					}
						
					msg.WriteData(pos,&totalYB,sizeof(totalYB));
				}
	
				uint8 isGet = ((getMask&(1<<maxDay)) == 0) ? (uint8)0 : (uint8)1;
				if (curDay > maxDay || ((curDay == maxDay) && (isGet == 1)))
					canGet = 2;
					
				msg<<showType<<canGet<<curDay<<nextTime;
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			else if(op1 == 1)	// 领取奖励
			{
				vector<HDPeiZhiInfo> info;
				uint32 hongliLeijiTime = awardManager.GetHuoDongLeijiTime(type);
				uint32 curTime = GetSysTime();
				uint32 leijiYB = pUser->GetExtData32(leijiDataId);
				uint32 getMask = pUser->GetExtData32(maskDataId);
				uint32 cdTime = (curTime > hongliLeijiTime) ? 0 : hongliLeijiTime - curTime;
				uint32 curDay = 0;
				uint8 index = 0;
				uint32 nextTime = 0;

				if (cdTime > 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1592,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				awardManager.GetPeiZhiInfo(info,type);
				if (info.size() <= 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1593,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
				}
					
				for (uint8 i = 0; i < info.size(); i++)
				{
					if (info[i].YB <= leijiYB)
						index = info[i].index;
				}

				if (index == 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1594,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
		
				curDay = (curTime - hongliLeijiTime) / (24 * 3600) + 1; 

				vector<uint32> idxList;
				awardManager.GetAwardIdxList(type,index,idxList);
				bool isFind = false;
				for (uint32 i = 0; i < idxList.size(); i++)
				{
					uint32 getDay = awardManager.GetIdx3(type, idxList[i]);
					if (getDay == curDay)
					{
						if ((getMask & (1<<curDay)) == 0)
						{
							SHuoDongAward award;
							awardManager.GetAwardData(type,idxList[i],award);
							for(uint8 j=0;j < SHuoDongAward::AWARD_NUM;j++)
								AddHuoDongAward(pUser,type,award.award[j],award.num[j],award.petQuality[j],award.petQualityLv[j]);
							getMask |= (1<<curDay);
							pUser->SetExtData32(maskDataId,getMask);
							msg<<PRO_SUCCESS<<index<<curDay;
							isFind = true;
						}
						else
						{
							msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1595,TIPS_FAILURE_COLOR);
							m_socketServer.SendMsg(pUser->GetSock(),msg);
							return;
						}
					}

					if (cdTime == 0 && curDay < getDay && nextTime == 0)
					{
						nextTime = hongliLeijiTime + 24 * 3600 * (getDay - 1) - curTime;
					}

				}

				if (isFind)
				{
					msg<<nextTime;
					NoticeHuoDongHotPoint(pUser, type);
				}
				else
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1596,TIPS_FAILURE_COLOR);
				}
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				return;
			}
		}
		break;
	case HD_HONGLIXIAOFEI: //红利大放送 消费
	case HD_HONGLIXIAOFEI2:
	case HD_HONGLIXIAOFEI3:
	case HD_HONGLIXIAOFEI4:
	case HD_HONGLIXIAOFEI5:
		{
			uint8 op1=0;	// 0获取列表信息，1领取奖励
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
			uint32 type = 0;
			uint32 timeDataId = 0;
			uint32 leijiDataId = 0;
			uint32 maskDataId = 0;

			switch(op)
			{
				case HD_HONGLIXIAOFEI:
					type = CHuoDongAwardManager::HONGLI_XIAOFEI;
					break;
				case HD_HONGLIXIAOFEI2:
					type = CHuoDongAwardManager::HONGLI_XIAOFEI2;
					break;
				case HD_HONGLIXIAOFEI3:
					type = CHuoDongAwardManager::HONGLI_XIAOFEI3;
					break;
				case HD_HONGLIXIAOFEI4:
					type = CHuoDongAwardManager::HONGLI_XIAOFEI4;
					break;
				case HD_HONGLIXIAOFEI5:
					type = CHuoDongAwardManager::HONGLI_XIAOFEI5;
					break;
				default:
					return;
			}

			if (!GetHongLiDataId(type,timeDataId,leijiDataId,maskDataId))
				return;

			msg>>op1;

			if(!awardManager.InHuoDongTime(type))
				return;
					
			if(op1 == 0)	// 获取列表
			{
				msg<<PRO_SUCCESS;

				vector<HDPeiZhiInfo> info;
				uint32 nextTime = 0;
				uint32 hongliLeijiTime = awardManager.GetHuoDongLeijiTime(type);
				uint32 curTime = GetSysTime();
				uint32 curDay = 0;
				uint32 maxDay = 0;
				uint32 cdTime = (curTime > hongliLeijiTime) ? 0 : hongliLeijiTime - curTime;
				uint32 leijiYB = pUser->GetExtData32(leijiDataId);
				uint32 getMask = pUser->GetExtData32(maskDataId);
				uint8 showType = 0;
				uint8 canGet = 0;

				if (cdTime == 0)
					curDay = (curTime - hongliLeijiTime) / (24 * 3600) + 1;
			
				awardManager.GetPeiZhiInfo(info, type);
				msg << leijiYB << cdTime << (uint8)info.size();
				for (uint8 i = 0; i < info.size(); i++)
				{
					vector<uint32> idxList;
					awardManager.GetAwardIdxList(type,info[i].index,idxList);
	
					msg << (uint8)info[i].index << info[i].YB;
					uint16 pos = msg.GetDataLen();
					uint32 totalYB = 0;
					msg<<totalYB<<(uint8)idxList.size();

					if (info[i].YB <= leijiYB)
					{
						showType = info[i].index;
					}
			
					for (uint32 k = 0; k < idxList.size(); k++)
					{
						uint32 day = awardManager.GetIdx3(type, idxList[k]);
						uint8 getState = ((getMask&(1<<day)) == 0) ? (uint8)0 : (uint8)1;

						if (showType != 0 && cdTime == 0 && curDay < day && nextTime == 0)
						{
							nextTime = hongliLeijiTime + 24 * 3600 * (day - 1) - curTime;
						}
			
						if (maxDay < day)
							maxDay = day;
	
						if (cdTime == 0 && getState == 0 && (curDay > day))
							getState = 2;
			
						if (showType != 0 && cdTime == 0 && getState == 0 && curDay == day)
							canGet = 1;
									
						msg<<day<<getState;

						SHuoDongAward award;
						awardManager.GetAwardData(type,idxList[k],award);
								
						uint16 pos2 = msg.GetDataLen();
						uint8 typeNum = 0;
						msg << typeNum;
						typeNum = MakeAwardMsg(pUser, award, type, msg, &totalYB);
						msg.WriteData(pos2,&typeNum,sizeof(typeNum));
					}
							
					msg.WriteData(pos,&totalYB,sizeof(totalYB));
				}
	
				uint8 isGet = ((getMask&(1<<maxDay)) == 0) ? (uint8)0 : (uint8)1;
				if (curDay > maxDay || ((curDay == maxDay) && (isGet == 1)))
					canGet = 2;
						
				msg<<showType<<canGet<<curDay<<nextTime;
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			else if(op1 == 1)	// 领取奖励
			{
				vector<HDPeiZhiInfo> info;
				uint32 hongliLeijiTime = awardManager.GetHuoDongLeijiTime(type);
				uint32 curTime = GetSysTime();
				uint32 leijiYB = pUser->GetExtData32(leijiDataId);
				uint32 getMask = pUser->GetExtData32(maskDataId);
				uint32 cdTime = (curTime > hongliLeijiTime) ? 0 : hongliLeijiTime - curTime;
				uint32 curDay = 0;
				uint8 index = 0;
				uint32 nextTime = 0;
			
				if (cdTime > 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1597,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				awardManager.GetPeiZhiInfo(info,type);
				for (uint8 i = 0; i < info.size(); i++)
				{
					if (info[i].YB <= leijiYB)
						index = info[i].index;
				}

				if (index == 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1598,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
		
				curDay = (curTime - hongliLeijiTime) / (24 * 3600) + 1; 

				vector<uint32> idxList;
				awardManager.GetAwardIdxList(type,index,idxList);
				bool isFind = false;
				for (uint32 i = 0; i < idxList.size(); i++)
				{
					uint32 getDay = awardManager.GetIdx3(type, idxList[i]);
					if (getDay == curDay)
					{
						if ((getMask & (1<<curDay)) == 0)
						{
							SHuoDongAward award;
							awardManager.GetAwardData(type,idxList[i],award);
							for(uint8 j=0;j < SHuoDongAward::AWARD_NUM;j++)
								AddHuoDongAward(pUser,type,award.award[j],award.num[j],award.petQuality[j],award.petQualityLv[j]);
							getMask |= (1<<curDay);
							pUser->SetExtData32(maskDataId,getMask);
							msg<<PRO_SUCCESS<<index<<curDay;
							isFind = true;
						}
						else
						{
							msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1599,TIPS_FAILURE_COLOR);
							m_socketServer.SendMsg(pUser->GetSock(),msg);
							return;
						}
					}

					if (cdTime == 0 && curDay < getDay && nextTime == 0)
					{
						nextTime = hongliLeijiTime + 24 * 3600 * (getDay - 1) - curTime;
					}
				}

				if (isFind)
				{
					msg<<nextTime;
					NoticeHuoDongHotPoint(pUser, type);
				}
				else
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1600,TIPS_FAILURE_COLOR);
				}
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				return;
			}
		}
		break;
	case HD_SHEN_CHONG_BANG:	// 最强神将榜
		{
			uint32 type = CHuoDongAwardManager::SHEN_CHONG_BANG;
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();

			if (!awardManager.InHuoDongTime(type))
				return;

			uint32 leijiTime = awardManager.GetHuoDongLeijiTime(type); // 更新榜单结束时间
			uint32 curTime = GetSysTime(); // 当前时间	
			vector<PaiHangBangInfo> bangInfo; //榜单数据
			vector<uint32> idxList;
			uint32 endTime = leijiTime;
			
			if(curTime < endTime)// 即时更新
			{
				idxList.clear();
				awardManager.GetAwardIdxList(type,idxList);
//				int bang_num = idxList.size(); // 活动人数

				vector<SLRankData> vecRankData;
 //               SingletonCRankDataMgr::instance().GetRankData(ECRT_MaxPet,bang_num,vecRankData);
				bangInfo.clear();
				for(int i=0;i<(int)vecRankData.size();i++)
				{
					PaiHangBangInfo info;
					info.role_name = vecRankData[i].role_name;
					info.wingId = vecRankData[i].pet_id;
					info.pet_name = vecRankData[i].pet_name;
					info.role_id = vecRankData[i].role_id;
					info.data = vecRankData[i].data;
					bangInfo.push_back(info);
				}
			}

			string desc = awardManager.GetHuoDongLeiJiTimeDesc(type);
			uint32 cdTime = (curTime > leijiTime) ? 0 : leijiTime - curTime;
			uint8 myPaiHang = 0;

			msg<<PRO_SUCCESS;
			if (cdTime > 24 * 3600)  // 未开始
				msg<<(uint8)0;
			else if (cdTime > 0)	// 进行中
				msg<<(uint8)1;
			else                    // 已结束
				msg<<(uint8)2;
			msg<<desc<<cdTime;

			if (curTime >= endTime)   // 活动结束
			{
				string res = GetGlobalVaribleData(EGV_ZQSCB);
				if(res.length() == 0)
				{
					msg<<(uint8)0;
				}
				else
				{	
					static const int base = 29;
					char buf[2048];
					char *p[15 * base];
				
					strncpy(buf,res.c_str(),sizeof(buf));
				
					int limit = SplitLine(p, buf, '|');
					msg<<(uint8)(limit/base);
					for(int i = 0; i < (limit/base); ++i)
					{
						uint32 role_id = (uint32)atoi(p[i*base + 0]);
						msg<<role_id<<p[i*base+2]<<p[i*base+3]<<atoi(p[i*base+4]);

						if (role_id == pUser->GetRoleId())
							myPaiHang = i + 1;

						uint16 pos = msg.GetDataLen();
						uint8 typeNum = 0;
						msg << typeNum;

						int awardBase = i * base + 5;
						for (uint8 j=0;j < SHuoDongAward::AWARD_NUM;j++)
						{
							uint32 awardId = (uint32)atoi(p[awardBase]);
							uint32 awardNum = (uint32)atoi(p[awardBase + 1]);
							if(awardId > 0 && awardNum > 0)
							{
								UniversalMakeAwardMsg(awardId, awardNum, 0, 0, msg);
								typeNum++;
							}
							awardBase += 4;
						}
						msg.WriteData(pos,&typeNum,sizeof(typeNum));
					}
				}
			}
			else
			{
				msg<<(uint8)bangInfo.size();
				for (uint32 i = 0; i < bangInfo.size(); i++)
				{
					SHuoDongAward award;
					awardManager.GetAwardData(type,i + 1,award);

					msg<<bangInfo[i].role_id<<bangInfo[i].role_name.c_str()<<bangInfo[i].pet_name.c_str()<<bangInfo[i].data;

					if (bangInfo[i].role_id == pUser->GetRoleId())
						myPaiHang = i + 1;

					uint16 pos = msg.GetDataLen();
					uint8 typeNum = 0;
					msg << typeNum;
					typeNum = MakeAwardMsg(pUser, award, type, msg);
					msg.WriteData(pos,&typeNum,sizeof(typeNum));
				}
			}
//			SRankPet myMaxPet;
//			pUser->GetPetMaxFightId(myMaxPet);
//			msg<<IntToStr(myMaxPet.pet_id).c_str()<<(uint8)myPaiHang;
			m_socketServer.SendMsg(pUser->GetSock(),msg);
		}
		break;
	case HD_EQUIP_QIANG_HUA:	// 仙甲强化榜
		{
			uint32 type = CHuoDongAwardManager::EQUIP_QIANGHUA_BANG;
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();

			if (!awardManager.InHuoDongTime(type))
				return;

			uint32 leijiTime = awardManager.GetHuoDongLeijiTime(type); // 更新榜单结束时间
			uint32 curTime = GetSysTime(); // 当前时间
			vector<PaiHangBangInfo> bangInfo; //榜单数据
			vector<uint32> idxList;
			uint32 endTime = leijiTime;
			
			if(curTime < endTime) // 即时从内存读取数据
			{
				idxList.clear();
				awardManager.GetAwardIdxList(type,idxList);
//				int bang_num = (int)idxList.size(); // 活动人数
				
				bangInfo.clear();
				//char **row = NULL;
				vector<SLRankData> vecRankData;
				//改为内存数据
//				SingletonCRankDataMgr::instance().GetRankData(ECRT_EquipQHLv,bang_num,vecRankData);
				for(int i=0;i<(int)vecRankData.size();i++)
				{
					PaiHangBangInfo info;
					info.role_name = vecRankData[i].role_name;
					info.role_id = vecRankData[i].role_id;
					info.data = vecRankData[i].data;
					bangInfo.push_back(info);
				}			
			}

			string desc = awardManager.GetHuoDongLeiJiTimeDesc(type);
			uint32 cdTime = (curTime > leijiTime) ? 0 : leijiTime - curTime;
			uint8 myPaiHang = 0;

			msg<<PRO_SUCCESS;
			if (cdTime > 24 * 3600)  // 未开始
				msg<<(uint8)0;
			else if (cdTime > 0)	// 进行中
				msg<<(uint8)1;
			else                    // 已结束
				msg<<(uint8)2;
			msg<<desc<<cdTime;

			if (curTime >= endTime)   // 活动结束
			{
				string res = GetGlobalVaribleData(EGV_XJQHB);
				if(res.length() == 0)
				{
					msg<<(uint8)0;
				}
				else
				{
					static const int base = 28;
					char buf[2048];
					char *p[15 * base];
				
					strncpy(buf,res.c_str(),sizeof(buf));
				
					int limit = SplitLine(p, buf, '|');
					msg<<(uint8)(limit/base);
					for(int i = 0; i < (limit/base); ++i)
					{
						uint32 role_id = (uint32)atoi(p[i*base + 0]);
						msg<<role_id<<p[i*base+2]<<""<<(uint32)atoi(p[i*base+3]);

						if (role_id == pUser->GetRoleId())
							myPaiHang = i + 1;

						uint16 pos = msg.GetDataLen();
						uint8 typeNum = 0;
						msg << typeNum;

						int awardBase = i * base + 4;
						for (uint8 j=0;j < SHuoDongAward::AWARD_NUM;j++)
						{
							uint32 awardId = (uint32)atoi(p[awardBase]);
							uint32 awardNum = (uint32)atoi(p[awardBase + 1]);
							if(awardId > 0 && awardNum > 0)
							{
								UniversalMakeAwardMsg(awardId, awardNum, 0, 0, msg);
								typeNum++;
							}
							awardBase += 4;
						}
						msg.WriteData(pos,&typeNum,sizeof(typeNum));
					}
				}
			}
			else
			{
				msg<<(uint8)bangInfo.size();
				for (uint32 i = 0; i < bangInfo.size(); i++)
				{
					SHuoDongAward award;
					awardManager.GetAwardData(type,i + 1,award);

					msg<<bangInfo[i].role_id<<bangInfo[i].role_name.c_str()<<""<<bangInfo[i].data;

					if (bangInfo[i].role_id == pUser->GetRoleId())
						myPaiHang = i + 1;

					uint16 pos = msg.GetDataLen();
					uint8 typeNum = 0;
					msg << typeNum;
					typeNum = MakeAwardMsg(pUser, award, type, msg);
					
					msg.WriteData(pos,&typeNum,sizeof(typeNum));
				}
			}
//			msg<<IntToStr(pUser->GetAllEquipStrengthLv())<<(uint8)myPaiHang;
			m_socketServer.SendMsg(pUser->GetSock(),msg);
		}
		break;
	case HD_ROLE_LEVEL_BANG:	// 等级冲刺榜
		{
			uint32 type = CHuoDongAwardManager::ROLE_LEVEL_BANG;
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();

			if (!awardManager.InHuoDongTime(type))
				return;

			uint32 leijiTime = awardManager.GetHuoDongLeijiTime(type); // 更新榜单结束时间
			uint32 curTime = GetSysTime(); // 当前时间
			vector<PaiHangBangInfo> bangInfo; //榜单数据
			vector<uint32> idxList;
			uint32 endTime = leijiTime;
			
			if(curTime < endTime) // 即时更新
			{
				idxList.clear();
				awardManager.GetAwardIdxList(type,idxList);
//				int bang_num = idxList.size(); // 活动人数
				
				bangInfo.clear();
				vector<SLRankData> vecRankData;
	    		//改为内存数据
//				SingletonCRankDataMgr::instance().GetRankData(ECRT_Level,bang_num,vecRankData);
				for(int i=0;i<(int)vecRankData.size();i++)
				{
					PaiHangBangInfo info;
					info.role_name = vecRankData[i].role_name;
					info.role_id = vecRankData[i].role_id;
					info.data = vecRankData[i].data;
					bangInfo.push_back(info);	
				}		
			}

			string desc = awardManager.GetHuoDongLeiJiTimeDesc(type);
			uint32 cdTime = (curTime > leijiTime) ? 0 : leijiTime - curTime;
			uint8 myPaiHang = 0;

			msg<<PRO_SUCCESS;
			if (cdTime > 24 * 3600)  // 未开始
				msg<<(uint8)0;
			else if (cdTime > 0)	// 进行中
				msg<<(uint8)1;
			else                    // 已结束
				msg<<(uint8)2;
			
			msg<<desc<<cdTime;

			if (curTime >= endTime)   // 活动结束
			{
				string res = GetGlobalVaribleData(EGV_DJCCB);
				if(res.length() == 0)
				{
					msg<<(uint8)0;
				}
				else
				{
					static const int base = 28;
					char buf[2048];
					char *p[15 * base];
				
					strncpy(buf,res.c_str(),sizeof(buf));
				
					int limit = SplitLine(p, buf, '|');
					msg<<(uint8)(limit/base);
					for(int i = 0; i < (limit/base); ++i)
					{
						uint32 role_id = (uint32)atoi(p[i*base + 0]);
						msg<<role_id<<p[i*base+2]<<""<<(uint32)atoi(p[i*base+1]);

						if (role_id == pUser->GetRoleId())
							myPaiHang = i + 1;

						uint16 pos = msg.GetDataLen();
						uint8 typeNum = 0;
						msg << typeNum;

						int awardBase = i * base + 4;
						for (uint8 j=0;j < SHuoDongAward::AWARD_NUM;j++)
						{
							uint32 awardId = (uint32)atoi(p[awardBase]);
							uint32 awardNum = (uint32)atoi(p[awardBase + 1]);
							if(awardId > 0 && awardNum > 0)
							{
								UniversalMakeAwardMsg(awardId, awardNum, 0, 0, msg);
								typeNum++;
							}
							awardBase += 4;
						}
						msg.WriteData(pos,&typeNum,sizeof(typeNum));
					}
				}
			}
			else
			{
				msg<<(uint8)bangInfo.size();
				for (uint32 i = 0; i < bangInfo.size(); i++)
				{
					SHuoDongAward award;
					awardManager.GetAwardData(type,i + 1,award);

					msg<<bangInfo[i].role_id<<bangInfo[i].role_name.c_str()<<""<<bangInfo[i].data;

					if (bangInfo[i].role_id == pUser->GetRoleId())
						myPaiHang = i + 1;

					uint16 pos = msg.GetDataLen();
					uint8 typeNum = 0;
					msg << typeNum;
					typeNum = MakeAwardMsg(pUser, award, type, msg);
					msg.WriteData(pos,&typeNum,sizeof(typeNum));
				}
			}
			msg<<IntToStr(pUser->GetLevel())<<(uint8)myPaiHang;
			m_socketServer.SendMsg(pUser->GetSock(),msg);
		}
		break;
	case HD_ZHAN_LI_BANG:		// 群仙战力榜
		{
			uint32 type = CHuoDongAwardManager::ZHAN_LI_BANG;
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();

			if (!awardManager.InHuoDongTime(type))
				return;

			CGetDbConnect getDb;
			CDatabaseSql *pDb = getDb.GetDbConnect();
			if(pDb == NULL)
				return;

			uint32 leijiTime = awardManager.GetHuoDongLeijiTime(type); // 更新榜单结束时间
			uint32 curTime = GetSysTime(); // 当前时间	
			vector<PaiHangBangInfo> bangInfo; //榜单数据
			vector<uint32> idxList;
			uint32 endTime = leijiTime;
			
			if(curTime < endTime) // 即时更新
			{
				idxList.clear();
				awardManager.GetAwardIdxList(type,idxList);
//				int bang_num = idxList.size(); // 活动人数
				
				bangInfo.clear();
				vector<SLRankData> vecRankData;
//                SingletonCRankDataMgr::instance().GetRankData(ECRT_Power,bang_num,vecRankData);
				for(int i=0;i<(int)vecRankData.size();i++)
				{
					PaiHangBangInfo info;
					info.role_name = vecRankData[i].role_name;
					info.role_id = vecRankData[i].role_id;
					info.data = vecRankData[i].data;
					bangInfo.push_back(info);
				}			
			}

			string desc = awardManager.GetHuoDongLeiJiTimeDesc(type);
			uint32 cdTime = (curTime > leijiTime) ? 0 : leijiTime - curTime;
			uint8 myPaiHang = 0;

			msg<<PRO_SUCCESS;
			if (cdTime > 24 * 3600)  // 未开始
				msg<<(uint8)0;
			else if (cdTime > 0) // 进行中
				msg<<(uint8)1;
			else	// 已结束
				msg<<(uint8)2;
			msg<<desc<<cdTime;

			if (curTime >= endTime)   // 活动结束
			{
				string res = GetGlobalVaribleData(EGV_QXZLB);
				if(res.length() == 0)
				{
					msg<<(uint8)0;
				}
				else
				{
					static const int base = 28;
					char buf[2048];
					char *p[15 * base];
				
					strncpy(buf,res.c_str(),sizeof(buf));
				
					int limit = SplitLine(p, buf, '|');
					msg<<(uint8)(limit/base);
					for(int i = 0; i < (limit/base); ++i)
					{
						uint32 role_id = (uint32)atoi(p[i*base + 0]);
						msg<<role_id<<p[i*base+2]<<""<<atoi(p[i*base+3]);

						if (role_id == pUser->GetRoleId())
							myPaiHang = i + 1;

						uint16 pos = msg.GetDataLen();
						uint8 typeNum = 0;
						msg << typeNum;

						int awardBase = i * base + 4;
						for (uint8 j=0;j < SHuoDongAward::AWARD_NUM;j++)
						{
							uint32 awardId = (uint32)atoi(p[awardBase]);
							uint32 awardNum = (uint32)atoi(p[awardBase + 1]);
							if(awardId > 0 && awardNum > 0)
							{
								UniversalMakeAwardMsg(awardId, awardNum, 0, 0, msg);
								typeNum++;
							}
							awardBase += 4;
						}
						msg.WriteData(pos,&typeNum,sizeof(typeNum));
					}
				}
			}
			else
			{
				msg<<(uint8)bangInfo.size();
				for (uint32 i = 0; i < bangInfo.size(); i++)
				{
					SHuoDongAward award;
					awardManager.GetAwardData(type,i + 1,award);

					msg<<bangInfo[i].role_id<<bangInfo[i].role_name.c_str()<<""<<bangInfo[i].data;

					if (bangInfo[i].role_id == pUser->GetRoleId())
						myPaiHang = i + 1;

					uint16 pos = msg.GetDataLen();
					uint8 typeNum = 0;
					msg << typeNum;
					typeNum = MakeAwardMsg(pUser, award, type, msg);
					msg.WriteData(pos,&typeNum,sizeof(typeNum));
				}
			}
			msg<<IntToStr(pUser->GetZhanDouLi())<<(uint8)myPaiHang;
			m_socketServer.SendMsg(pUser->GetSock(),msg);
		}
		break;
	case HD_CHONG_ZHI_BANG:		// 新服充值榜
		{
			uint32 type = CHuoDongAwardManager::CHONG_ZHI_BANG;
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();

			if (!awardManager.InHuoDongTime(type))
				return;
			uint32 leijiTime = awardManager.GetHuoDongLeijiTime(type); // 更新榜单结束时间
			uint32 curTime = GetSysTime(); // 当前时间	
			vector<PaiHangBangInfo> bangInfo; //榜单数据
			vector<uint32> idxList;
			uint32 endTime = leijiTime;
			
			if(curTime < endTime) // 即时更新
			{
				idxList.clear();
				awardManager.GetAwardIdxList(type,idxList);
//				int bang_num = idxList.size(); // 活动人数
				vector<SLRankData> vecRankData;
				//改为内存数据
//				SingletonCRankDataMgr::instance().GetRankData(ECRT_Chong,bang_num,vecRankData);
				
				bangInfo.clear();
				for(int i=0;i<(int)vecRankData.size();i++)
				{
					PaiHangBangInfo info;
					info.role_name = vecRankData[i].role_name;
					info.role_id = vecRankData[i].role_id;
					info.data = vecRankData[i].data;
					bangInfo.push_back(info);
				}
			}

			string desc = awardManager.GetHuoDongLeiJiTimeDesc(type);
			uint32 cdTime = (curTime > leijiTime) ? 0 : leijiTime - curTime;
			uint8 myPaiHang = 0;

			msg<<PRO_SUCCESS;
			if (cdTime > 24 * 3600)  // 未开始
			{
				msg<<(uint8)0;
			}
			else if (cdTime > 0)
			// 进行中
			{
				msg<<(uint8)1;
			}
			else                    // 已结束
			{
				msg<<(uint8)2;
			}
			
			msg<<desc<<cdTime;

			if (curTime >= endTime)   // 活动结束
			{
				string res = GetGlobalVaribleData(EGV_XFCZB);
				if(res.length() == 0)
				{
					msg<<(uint8)0;
				}
				else
				{
					static const int base = 28;
					char buf[2048];
					char *p[15 * base];
				
					strncpy(buf,res.c_str(),sizeof(buf));
				
					int limit = SplitLine(p, buf, '|');
					msg<<(uint8)(limit/base);
					for(int i = 0; i < (limit/base); ++i)
					{
						uint32 role_id = (uint32)atoi(p[i*base + 0]);
						msg<<role_id<<p[i*base+2]<<""<<(uint32)atoi(p[i*base+3]);

						if (role_id == pUser->GetRoleId())
							myPaiHang = i + 1;

						uint16 pos = msg.GetDataLen();
						uint8 typeNum = 0;
						msg << typeNum;

						int awardBase = i * base + 4;
						for (uint8 j=0;j < SHuoDongAward::AWARD_NUM;j++)
						{
							uint32 awardId = (uint32)atoi(p[awardBase]);
							uint32 awardNum = (uint32)atoi(p[awardBase + 1]);
							if(awardId > 0 && awardNum > 0)
							{
								UniversalMakeAwardMsg(awardId, awardNum, 0, 0, msg);
								typeNum++;
							}
							awardBase += 4;
						}
						msg.WriteData(pos,&typeNum,sizeof(typeNum));
					}
				}

			}
			else
			{
				msg<<(uint8)bangInfo.size();
				for (uint32 i = 0; i < bangInfo.size(); i++)
				{
					SHuoDongAward award;
					awardManager.GetAwardData(type,i + 1,award);

					msg<<bangInfo[i].role_id<<bangInfo[i].role_name.c_str()<<""<<bangInfo[i].data;

					if (bangInfo[i].role_id == pUser->GetRoleId())
						myPaiHang = i + 1;

					uint16 pos = msg.GetDataLen();
					uint8 typeNum = 0;
					msg << typeNum;
					typeNum = MakeAwardMsg(pUser,award, type, msg);
					msg.WriteData(pos,&typeNum,sizeof(typeNum));
				}
			}
			msg<<IntToStr(pUser->GetExtData32(126))<<(uint8)myPaiHang;
			m_socketServer.SendMsg(pUser->GetSock(),msg);
		}
		break;
	case HD_WING_BANG:
		{
			uint32 type = CHuoDongAwardManager::WING_BANG;
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();

			if (!awardManager.InHuoDongTime(type))
				return;

			uint32 leijiTime = awardManager.GetHuoDongLeijiTime(type); // 更新榜单结束时间
			uint32 curTime = GetSysTime(); // 当前时间	
			vector<PaiHangBangInfo> bangInfo; //榜单数据
			vector<uint32> idxList;
			uint32 endTime = leijiTime;
			
			if(curTime < endTime) //即时更新
			{
				idxList.clear();
				awardManager.GetAwardIdxList(type,idxList);
//				int bang_num = (int)idxList.size(); // 活动人数
				
				bangInfo.clear();
				vector<SLRankData> vecRankData;
				//改为内存数据
//				SingletonCRankDataMgr::instance().GetRankData(ECRT_Wing,bang_num,vecRankData);
				for(int i=0;i<(int)vecRankData.size();i++)
				{
					PaiHangBangInfo info;
					info.role_name = vecRankData[i].role_name;
					info.role_id =  vecRankData[i].role_id;
					info.wingId =  vecRankData[i].pet_id;
					info.data = vecRankData[i].data;
					bangInfo.push_back(info);
				}
			}

			string desc = awardManager.GetHuoDongLeiJiTimeDesc(type);
			uint32 cdTime = (curTime > leijiTime) ? 0 : leijiTime - curTime;
			uint8 myPaiHang = 0;

			msg<<PRO_SUCCESS;
			if (cdTime > 24 * 3600)  // 未开始
				msg<<(uint8)0;
			else if (cdTime > 0)	// 进行中
				msg<<(uint8)1;
			else                    // 已结束
				msg<<(uint8)2;
			msg<<desc<<cdTime;

			if (curTime >= endTime)   // 活动结束
			{
				string res = GetGlobalVaribleData(EGV_WING);
				if(res.length() == 0)
				{
					msg<<(uint8)0;
				}
				else
				{
					static const int base = 29;
					char buf[2048];
					char *p[15 * base];
				
					strncpy(buf,res.c_str(),sizeof(buf));
				
					int limit = SplitLine(p, buf, '|');
					msg<<(uint8)(limit/base);
					for(int i = 0; i < (limit/base); ++i)
					{
						uint32 role_id = (uint32)atoi(p[i*base + 0]);
						msg<<role_id<<p[i*base+2]<<p[i*base+3]<<atoi(p[i*base+4]);

						if (role_id == pUser->GetRoleId())
							myPaiHang = i + 1;

						uint16 pos = msg.GetDataLen();
						uint8 typeNum = 0;
						msg << typeNum;

						int awardBase = i * base + 5;
						for (uint8 j=0;j < SHuoDongAward::AWARD_NUM;j++)
						{
							uint32 awardId = (uint32)atoi(p[awardBase]);
							uint32 awardNum = (uint32)atoi(p[awardBase + 1]);
							if(awardId > 0 && awardNum > 0)
							{
								UniversalMakeAwardMsg(awardId, awardNum, 0, 0, msg);
								typeNum++;
							}
							awardBase += 4;
						}
						msg.WriteData(pos,&typeNum,sizeof(typeNum));
					}
				}
			}
			else
			{
				msg<<(uint8)bangInfo.size();
				for (uint32 i = 0; i < bangInfo.size(); i++)
				{
					SHuoDongAward award;
					awardManager.GetAwardData(type,i + 1,award);

					msg<<bangInfo[i].role_id<<bangInfo[i].role_name.c_str()<<IntToStr(bangInfo[i].wingId).c_str()<<(uint32)bangInfo[i].data;

					if (bangInfo[i].role_id == pUser->GetRoleId())
						myPaiHang = i + 1;

					uint16 pos = msg.GetDataLen();
					uint8 typeNum = 0;
					msg << typeNum;
					typeNum = MakeAwardMsg(pUser, award, type, msg);
					msg.WriteData(pos,&typeNum,sizeof(typeNum));
				}
			}
			msg<<IntToStr(pUser->GetWingId()).c_str()<<(uint8)myPaiHang;
			m_socketServer.SendMsg(pUser->GetSock(),msg);
		}
		break;
	case HD_QIANGHUA_KUANGHUAN:		// 强化狂欢礼
		{
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
			uint32 type = CHuoDongAwardManager::QIANGHUA_KUANGHUAN;
			vector<HDPeiZhiInfo> huodong_info;
			uint32 getMask = pUser->GetExtData32(214);
			uint8 max_stage = 0; // 档次数

			if (!awardManager.InHuoDongTime(type))
				return;
			
			awardManager.GetPeiZhiInfo(huodong_info,type);
			max_stage = huodong_info.size();

			int endTime = awardManager.GetHuoDongEndTime(type);
			int leftTime = endTime - (int)GetSysTime(); // 剩余有效时间 秒
			if(leftTime < 0)
				leftTime = 0;

			uint8 op1 = 0;
			msg>>op1;
			if (op1 == 1) // 查看状态
			{
				msg<<PRO_SUCCESS<<(uint32)leftTime<<(uint8)max_stage;

				for (int i = 0; i < max_stage; ++i)
				{
//					uint8 isGet = ((getMask&(1<<huodong_info[i].index)) == 0) ? (uint8)0 : (uint8)1;
//					msg<<(uint8)huodong_info[i].index<<(uint8)huodong_info[i].lv<<(uint8)pUser->GetEquipStrengthLvNum(huodong_info[i].lv)<<huodong_info[i].count<<isGet;
					
					SHuoDongAward award;
					awardManager.GetAwardData(type,huodong_info[i].index,award);
					
					uint16 pos = msg.GetDataLen();
					uint8 typeNum = 0;
					msg << typeNum;
					typeNum = MakeAwardMsg(pUser, award, type, msg);
					msg.WriteData(pos,&typeNum,sizeof(typeNum));
				}
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			else if (op1 ==2) // 领取
			{
				uint8 index = 0;
				msg>>index;
				
				uint8 isGet = ((getMask&(1<<index)) == 0) ? (uint8)0 : (uint8)1;
				if (isGet == 1)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1601,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				bool isFind = false;
				for (int i = 0; i < max_stage; ++i)
				{
					if (huodong_info[i].index == index)
					{
						isFind = true;
/*						if (pUser->GetEquipStrengthLvNum(huodong_info[i].lv) < huodong_info[i].count)
						{
							msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1602,TIPS_FAILURE_COLOR);
						}
						else
						{
							SHuoDongAward award;
							awardManager.GetAwardData(type,huodong_info[i].index,award);
							for(uint8 j=0;j < SHuoDongAward::AWARD_NUM;j++)
								AddHuoDongAward(pUser,type,award.award[j],award.num[j],award.petQuality[j],award.petQualityLv[j]);
							getMask |= (1<<index);
							pUser->SetExtData32(214,getMask);
							msg<<PRO_SUCCESS;

							NoticeHuoDongHotPoint(pUser, type);
						}
*/
						break;
					}
				}

				if (! isFind)
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1603,TIPS_FAILURE_COLOR);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				return;
			}
		}
		break; 
	case HD_SHENGJIE_LETIAN:		// 升阶乐翻天
		{
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
			uint32 type = CHuoDongAwardManager::SHENGJIE_LETIAN;
			vector<HDPeiZhiInfo> huodong_info;
			uint32 getMask = pUser->GetExtData32(216);
			uint8 max_stage = 0; // 档次数

			if (!awardManager.InHuoDongTime(type))
				return;
			
			awardManager.GetPeiZhiInfo(huodong_info,type);
			max_stage = huodong_info.size();

			int endTime = awardManager.GetHuoDongEndTime(type);
			int leftTime = endTime - (int)GetSysTime(); // 剩余有效时间 秒
			if(leftTime < 0)
				leftTime = 0;

			uint8 op1 = 0;
			msg>>op1;
			if (op1 == 1) // 查看状态
			{
				msg<<PRO_SUCCESS<<(uint32)leftTime<<(uint8)max_stage;

				for (int i = 0; i < max_stage; ++i)
				{
//					uint8 isGet = ((getMask&(1<<huodong_info[i].index)) == 0) ? (uint8)0 : (uint8)1;
//					msg<<(uint8)huodong_info[i].index<<(uint8)huodong_info[i].lv<<(uint8)pUser->GetEquipQualityLvNum(huodong_info[i].lv)<<huodong_info[i].count<<isGet;
					
					SHuoDongAward award;
					awardManager.GetAwardData(type,huodong_info[i].index,award);
					
					uint16 pos = msg.GetDataLen();
					uint8 typeNum = 0;
					msg << typeNum;
					typeNum = MakeAwardMsg(pUser, award, type, msg);
					msg.WriteData(pos,&typeNum,sizeof(typeNum));
				}
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			else if (op1 ==2) // 领取
			{
				uint8 index = 0;
				msg>>index;
				
				uint8 isGet = ((getMask&(1<<index)) == 0) ? (uint8)0 : (uint8)1;
				if (isGet == 1)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1604,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				bool isFind = false;
				for (int i = 0; i < max_stage; ++i)
				{
					if (huodong_info[i].index == index)
					{
						isFind = true;
/*						if (pUser->GetEquipQualityLvNum(huodong_info[i].lv) < huodong_info[i].count)
						{
							msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1605,TIPS_FAILURE_COLOR);
						}
						else
						{
							SHuoDongAward award;
							awardManager.GetAwardData(type,huodong_info[i].index,award);
							for(uint8 j=0;j < SHuoDongAward::AWARD_NUM;j++)
								AddHuoDongAward(pUser,type,award.award[j],award.num[j],award.petQuality[j],award.petQualityLv[j]);
							getMask |= (1<<index);
							pUser->SetExtData32(216,getMask);
							msg<<PRO_SUCCESS;
							
							NoticeHuoDongHotPoint(pUser, type);
						}
*/
						break;
					}
				}


				if (! isFind)
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1606,TIPS_FAILURE_COLOR);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				return;
				
			}
		}
		break;
	case HD_ZHA_DAN:		// 砸蛋
	case HD_ZHA_DAN_COPY:
		{
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
			uint32 ext32Idx = 0;
			if (awardManager.InHuoDongTime(CHuoDongAwardManager::ZHA_DAN))
				ext32Idx = 12;
			else if (awardManager.InHuoDongTime(CHuoDongAwardManager::ZHA_DAN_COPY))
				ext32Idx = 468;
			uint32 type = CHuoDongAwardManager::ZHA_DAN;
			uint32 awardType = 1;
			if (op == HD_ZHA_DAN_COPY)
			{
				type = CHuoDongAwardManager::ZHA_DAN_COPY;
				awardType = 0;
			}
			const uint32 AWARD_NUM = 10;
			const uint16 YAO_SHI = 2384;
	
			if (!awardManager.InHuoDongTime(type))
				return;
			uint32 endTime = awardManager.GetHuoDongEndTime(type);
			uint32 curTime = GetSysTime();
			if (pUser->GetExtData32(469) <= curTime)
			{
				pUser->ClearZhaDanHistory();
				pUser->SetExtData32(469, endTime);
			}
			HDPeiZhiInfo zhaDanCostInfo;
			awardManager.GetPeiZhiInfo(zhaDanCostInfo, type, 1);
			if (zhaDanCostInfo.index != 1)
			{
				msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_1607, TIPS_FAILURE_COLOR);
				m_socketServer.SendMsg(pUser->GetSock(), msg);
				return;
			}
			vector<SZhaDanInfo> zhaDanInfo;
			awardManager.GetZhaDanShowInfo(zhaDanInfo, awardType);
			if (zhaDanInfo.size() < AWARD_NUM)
			{
				msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_1607, TIPS_FAILURE_COLOR);
				m_socketServer.SendMsg(pUser->GetSock(), msg);
				return;
			}

			uint8 op1 = 0;
			msg>>op1;
			if (op1 == 1) // 查看状态
			{
				int hour = GetHour();
				int minute = GetMinute();
				int second = GetSysTime()%60;
				int leftTime = 24*3600 - hour*3600 - minute*60 - second;
				
				int endSec = endTime > curTime ? endTime - curTime : 0;
				leftTime = endSec;
				msg<<PRO_SUCCESS<<pUser->GetExtData32(ext32Idx)<< leftTime << endSec;

				msg<<(uint8)(AWARD_NUM);
				for (uint32 i = 0; i < zhaDanInfo.size(); i++)
				{
					if (zhaDanInfo[i].isJinPin == 0)
					{
						UniversalMakeAwardMsg(zhaDanInfo[i].award, zhaDanInfo[i].num, zhaDanInfo[i].petQt, zhaDanInfo[i].petQtLv, msg);
						msg << zhaDanInfo[i].isJinPin;
					}
				}

				msg<<(uint8)1 << (uint32)zhaDanCostInfo.count << zhaDanCostInfo.YB;
				pUser->InitZhaDanHistory();
				vector<string> myHistory, publicHistory;
				pUser->GetZhaDanHistory(myHistory);
				msg<<(uint8)myHistory.size();
				for (uint32 i = 0; i < myHistory.size(); i++)
				{
					msg<<myHistory[i].c_str();
				}

				awardManager.GetZhaDanPubHistory(publicHistory);
				msg<<(uint8)publicHistory.size();
				for (uint32 i = 0; i < publicHistory.size(); i++)
				{
					msg<<publicHistory[i].c_str();
				}
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			else if (op1 ==2) // 领取
			{
				const uint8 MAX_LOG_NUM = 10;
				uint8 op_type = 0xff;  // 0 单抽  1 十连
				msg>>op_type;
				uint32 count = op_type == 0 ? 1 : 10;

				int needNum = 0;
				if (op_type == 0)
					needNum = 1;
				else
					needNum = 9;
				int hasNum = pUser->GetItemNum(YAO_SHI);
				int needBuy = hasNum < needNum ? needNum - hasNum : 0;

				int costYB = zhaDanCostInfo.YB * needBuy;
				int myYB = pUser->GetTongBao();
				if (costYB > myYB)
				{
					msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_1611, TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(), msg);
					return;
				}

				vector<string> myHistory, publicHistory;
				int awardIdx = 0;
				if (!awardManager.AddZhaDanAward(pUser, count, awardType, myHistory, publicHistory, costYB, awardIdx))
					return;

				pUser->DelPackageById(YAO_SHI, needNum);
				pUser->AddTongBao(-costYB);
				pUser->SetExtData32(ext32Idx,pUser->GetExtData32(ext32Idx)+count*10);
				msg<<PRO_SUCCESS<<pUser->GetExtData32(ext32Idx)<<(uint8)awardIdx;

				if (myHistory.size() > 0)
					pUser->SetZhaDanHistory(myHistory);	
				
				uint8 size = (uint8)myHistory.size();
				uint8 index;
				if (size > MAX_LOG_NUM)
				{
					msg<<MAX_LOG_NUM;
					index = size - MAX_LOG_NUM;
				}
				else
				{
					msg<<size;
					index = 0;
				}

				for (uint32 i = index; i < myHistory.size(); i++)
				{
					msg<<myHistory[i].c_str();
				}

				size = (uint8)publicHistory.size();
				if (size > MAX_LOG_NUM)
				{
					msg<<MAX_LOG_NUM;
					index = size - MAX_LOG_NUM;
				}
				else
				{
					msg<<size;
					index = 0;
				}

				for (uint32 i = 0; i < publicHistory.size(); i++)
				{
					msg<<publicHistory[i].c_str();
				}
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
		}
		break;
	case HD_FESTIVAL:   //节日活动
		{
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
			uint32 type = CHuoDongAwardManager::FESTIVAL;
			//const uint8 bangSize = 2;
	
			if (!awardManager.InHuoDongTime(type))
				return;

			uint8 op1 = 0;
			msg>>op1;
			if (op1 == 1) // 查看排行
			{
				uint8 festival_type = 0xff;
				msg>>festival_type;

				if (festival_type == 0 || festival_type > 2)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1612,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				uint32 pic = awardManager.GetHuoDongPic(type);
				vector<GoodsInfo> goodsInfo;
				awardManager.GetHDBangGoods(pic, goodsInfo,type);
				if (goodsInfo.size() < 1)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1613,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				vector<SLRankData> vecData;
//				SingletonCRankDataMgr::instance().GetRankData(ECRT_FestivalF+festival_type-1,MAX_RANK_NUM,vecData);

				uint32 leijiTime = awardManager.GetHuoDongLeijiTime(type); // 更新榜单结束时间
				uint32 curTime = GetSysTime(); // 当前时间
				uint32 cdTime = (curTime > leijiTime) ? 0 : leijiTime - curTime;
				
				msg<<PRO_SUCCESS<<cdTime;

				uint8 myPaiHang = 0;
				//uint32 myAwardId = 0;
				//uint32 myAwardNum = 0;
				uint32 festivalScore = 0;
				vector<SAttrTypeValue> myAwards;
				msg<<(uint8)vecData.size();
				for (uint32 j = 0; j < vecData.size(); j++)
				{
					msg<<vecData[j].role_id<<vecData[j].role_name<<vecData[j].xiang<<vecData[j].vipLv<<vecData[j].data;
					
					SHuoDongAward awardInfo;
					awardManager.GetFestivalRankAward(festival_type-1,j+1,vecData[j].data,awardInfo);

					uint8 awardNum = 0;
					uint16 msgPos = msg.GetDataLen();
					msg<<awardNum;
					for(int k=0;k<SHuoDongAward::AWARD_NUM;k++)
					{
						if(awardInfo.award[k] > 0 && awardInfo.num[k] >0)
						{
							msg<<awardInfo.award[k]<<awardInfo.num[k];
							awardNum++;
							if(pUser->GetRoleId() == vecData[j].role_id)
							{
								SAttrTypeValue val;
								val.type = awardInfo.award[k];
								val.value = awardInfo.num[k];
								myAwards.push_back(val);
							}
						}
					}
					msg.WriteData(msgPos,&awardNum,sizeof(awardNum));
					if (pUser->GetRoleId() == vecData[j].role_id)
					{
						myPaiHang = j + 1;
						//myAwardId = awardInfo.award[0];
						//myAwardNum = awardInfo.num[0];
						festivalScore = vecData[j].data;
					}
				}			
				msg<<myPaiHang<<festivalScore<<(uint8)myAwards.size();
				for(uint8 j=0;j<myAwards.size();j++)
				{
					msg<<myAwards[j].type<<myAwards[j].value;
				}
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
		}
		break;
	case HD_LIANXU_CHONGZHI_ORI:  //连续充值-普通
	case HD_LIANXU_CHONGZHI_DELUXE:  //连续充值-豪华
		{
			uint8 op1=0;	// 1获取列表信息，2领取奖励
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
			const int ORI = 1;
			const int SPE = 2;
			uint32 type = CHuoDongAwardManager::LIANXU_CHONGZHI_ORI;
			uint32 YBDataId = 261;
			//uint32 firstTimeDataId = 262;
			uint32 YBMaskDataId = 263;
			uint32 getOriMaskDataId = 264;
			uint32 getSpeMaskDataId = 265;

			if (op == HD_LIANXU_CHONGZHI_DELUXE)
			{
				type = CHuoDongAwardManager::LIANXU_CHONGZHI_DELUXE;
				YBDataId = 267;
				//firstTimeDataId = 268;
				YBMaskDataId = 269;
				getOriMaskDataId = 270;
				getSpeMaskDataId = 271;
			}
	
			msg>>op1;

			if(!awardManager.InHuoDongTime(type))
				return;

			if(op1 == 1)	// 获取列表
			{
				//pUser->UpdateLianXuChongZhiState(type);
				msg<<PRO_SUCCESS;

				uint32 YB = pUser->GetExtData32(YBDataId);
				//uint32 lastTime = pUser->GetExtData32(firstTimeDataId);  // 不按照首充时间计算

				uint32 firstTime = awardManager.GetHuoDongZeroStartTime(type);
				uint32 YBMask = pUser->GetExtData32(YBMaskDataId);
				uint32 getOriMask = pUser->GetExtData32(getOriMaskDataId);
				uint32 getSpeMask = pUser->GetExtData32(getSpeMaskDataId);
				uint32 curTime = GetSysTime();
				uint8 costDay = 1;
				uint32 endTime = awardManager.GetHuoDongEndTime(type);

				if (firstTime != 0)
				{
					costDay = curTime > firstTime ? ((curTime - firstTime) / (24 * 3600) + 1) : 1;
				}
				msg<<costDay<< endTime - curTime <<YB;

				vector<uint32> idxList;
				awardManager.GetAwardIdxList(type,ORI,idxList);
				msg<<(uint8)idxList.size();
				uint8 starNum = 0;
				for (uint32 i = 0; i < idxList.size(); i++)
				{
					SHuoDongAward award;
					awardManager.GetAwardData(type,idxList[i],award);

					uint8 state = 1;  // 1 不满足领取条件，2 可领取 3已经领取
					uint8 YBState = ((YBMask&(1<<award.idx3)) == 0) ? (uint8)0 : (uint8)1;
					if (YBState == 1)
					{
						starNum++;
						state = 2;
						uint8 getState = ((getOriMask&(1<<award.idx3)) == 0) ? (uint8)0 : (uint8)1;
						if (getState == 1)
							state = 3;
					}

					msg<<(uint8)award.idx3<<(uint32)award.needYB<<state;
					uint16 pos = msg.GetDataLen();
					uint8 typeNum = 0;
					msg << typeNum;
					typeNum = MakeAwardMsg(pUser, award, type, msg);
					msg.WriteData(pos,&typeNum,sizeof(typeNum));
				}

				awardManager.GetAwardIdxList(type,SPE,idxList);
				msg<<(uint8)idxList.size();
				for (uint32 i = 0; i < idxList.size(); i++)
				{
					SHuoDongAward award;
					awardManager.GetAwardData(type,idxList[i],award);

					uint8 state = 1;
					if (starNum >= award.idx3)
					{
						state = 2;
					}
					/*uint8 YBState = ((YBMask&(1<<award.idx3)) == 0) ? (uint8)0 : (uint8)1;
					if (YBState == 1)
						state = 2;*/

					uint8 getState = ((getSpeMask&(1<<award.idx3)) == 0) ? (uint8)0 : (uint8)1;
					if (getState == 1)
						state = 3;

					msg<<(uint8)award.idx3<<state;
					uint16 pos = msg.GetDataLen();
					uint8 typeNum = 0;
					msg << typeNum;
					typeNum = MakeAwardMsg(pUser, award, type, msg);
					msg.WriteData(pos,&typeNum,sizeof(typeNum));
				}
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			else if(op1 == 2)	// 领取奖励
			{
				uint8 op_type = 0;
				uint8 getDay = 0;
				msg>>op_type >> getDay;

				if (op_type < 1 || op_type > 2)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1622,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				if (getDay > 31)
					getDay = 31;

				//uint32 firstTime = GetExtData32(firstTimeDataId);  不按照首充时间计算
				uint32 firstTime = awardManager.GetHuoDongZeroStartTime(type);
				uint32 YBMask = pUser->GetExtData32(YBMaskDataId);
				uint32 getOriMask = pUser->GetExtData32(getOriMaskDataId);
				uint32 getSpeMask = pUser->GetExtData32(getSpeMaskDataId);
				uint32 curTime = GetSysTime();

				uint8 today = curTime > firstTime ? ((curTime - firstTime) / (24 * 3600) + 1) : 1;

				if (today < getDay)
				{
					msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_1605, TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(), msg);
					return;
				}
			
				SHuoDongAward award;	
				uint32 idx = awardManager.GetAwardIdx(type,op_type, getDay);
				if (idx == 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1624,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				uint8 getState = 1;
				if (op_type == 1)
					getState = ((getOriMask&(1<< getDay)) == 0) ? (uint8)0 : (uint8)1;
				else
				{
					uint8 starNum = 0;
					getState = ((getSpeMask&(1 << getDay)) == 0) ? (uint8)0 : (uint8)1;
					for (uint8 i = 0; i < sizeof(YBMask) * 4; i++)
					{
						uint8 YBState = ((YBMask&(1 << i)) == 0) ? (uint8)0 : (uint8)1;
						if (YBState == 1)
						{
							starNum++;
						}
					}

					if (firstTime == 0 || starNum < getDay)
					{
						msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_1605, TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(), msg);
						return;
					}
				}

				if (getState == 1)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1625,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				
				awardManager.GetAwardData(type,idx,award);
				for(uint8 j=0;j < SHuoDongAward::AWARD_NUM;j++)
					AddHuoDongAward(pUser,type,award.award[j],award.num[j],award.petQuality[j],award.petQualityLv[j]);

				if (op_type == 1)
				{
					getOriMask |= (1<< getDay);
					pUser->SetExtData32(getOriMaskDataId, getOriMask);
				}	
				else
				{
					getSpeMask |= (1<< getDay);
					pUser->SetExtData32(getSpeMaskDataId, getSpeMask);
				}
				msg<<PRO_SUCCESS;

				m_socketServer.SendMsg(pUser->GetSock(),msg);
				NoticeHuoDongHotPoint(pUser, type);
			}
		}
		break;
	case HD_HONGLI_JIFEN:
	case HD_HONGLI_JIFEN2:
	case HD_HONGLI_JIFEN3:
	case HD_HONGLI_JIFEN4:
	case HD_HONGLI_JIFEN5:
		{
			uint8 op1=0;	// 1获取列表信息
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
			uint32 type =0;
			uint32 timeDataId = 0;
			uint32 jifenDataId = 0;

			switch(op)
			{
				case HD_HONGLI_JIFEN:
					type = CHuoDongAwardManager::HONGLI_JIFEN;
					break;
				case HD_HONGLI_JIFEN2:
					type = CHuoDongAwardManager::HONGLI_JIFEN2;
					break;
				case HD_HONGLI_JIFEN3:
					type = CHuoDongAwardManager::HONGLI_JIFEN3;
					break;
				case HD_HONGLI_JIFEN4:
					type = CHuoDongAwardManager::HONGLI_JIFEN4;
					break;
				case HD_HONGLI_JIFEN5:
					type = CHuoDongAwardManager::HONGLI_JIFEN5;
					break;
				default:
					return;
			}

			if (!GetHongLiJiFenDataId(type,timeDataId,jifenDataId))
				return;

			if(!awardManager.InHuoDongTime(type))
				return;

			msg >> op1;
			if (op1 == 1)
			{
				string timeDesc = awardManager.GetHuoDongTimeDesc(type);
				uint32 jifen = pUser->GetExtData32(jifenDataId);
				uint32 pic = awardManager.GetHuoDongPic(type);
				msg<<PRO_SUCCESS<<timeDesc.c_str()<<pic<<jifen<<type;

				vector<uint32> idxList;
				uint8 typeNum = 0;
				uint16 pos = msg.GetDataLen();
				msg<<typeNum;

				SHuoDongAward award;
				awardManager.GetAwardData(type,1,award);
				typeNum = MakeAwardMsg(pUser, award, type, msg);
				
				msg.WriteData(pos,&typeNum,sizeof(typeNum));
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
		}
		break;
	case HD_JIJIN_FANLI:
	case HD_JIJIN_FANLI2:
	case HD_JIJIN_FANLI3:
		{
			uint8 op1=0;	// 1获取列表信息
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
			uint32 type = CHuoDongAwardManager::JIJIN_FANLI;
			uint32 buyRecordDataId;
			uint32 startTimeDataId;
			uint32 buyFirstTimeDataId;
			uint32 getMaskDataId;

			switch(op)
			{
				case HD_JIJIN_FANLI:
					type = CHuoDongAwardManager::JIJIN_FANLI;
					break;
				case HD_JIJIN_FANLI2:
					type = CHuoDongAwardManager::JIJIN_FANLI2;
					break;
				case HD_JIJIN_FANLI3:
					type = CHuoDongAwardManager::JIJIN_FANLI3;
					break;
				default:
					return;
			}

			if (!GetJiJinFanLiDataId(type,buyRecordDataId,startTimeDataId,buyFirstTimeDataId,getMaskDataId))
				return;

			if(!awardManager.InHuoDongTime(type))
				return;
			
			msg >> op1;
			if (op1 == 1)
			{
				string leijiTimeDesc = awardManager.GetHuoDongLeiJiTimeDesc(type);
				string hdTimeDesc = awardManager.GetHuoDongTimeDesc(type);
				uint8 buyRecord = pUser->GetExtData8(buyRecordDataId);
				uint32 buyFirstTime = pUser->GetExtData32(buyFirstTimeDataId);
				uint32 getMask = pUser->GetExtData32(getMaskDataId);
				uint32 curTime = GetSysTime();
				uint32 leiJiTime = awardManager.GetHuoDongLeijiTime(type);

				uint8 costDay = 1;
				if (buyFirstTime != 0)
				{
					costDay = curTime > buyFirstTime ? ((curTime - buyFirstTime) / (24 * 3600) + 1) : 1;
					if (costDay > 31)
						costDay = 31;
				}
				uint32 cdTime = (curTime > leiJiTime) ? 0 : leiJiTime - curTime;

				vector<HDPeiZhiInfo> peizhiInfo;
				awardManager.GetPeiZhiInfo(peizhiInfo,type);
				if (peizhiInfo.size() == 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1626,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				msg<<PRO_SUCCESS<<hdTimeDesc<<leijiTimeDesc<<costDay<<cdTime<<(uint8)peizhiInfo.size();
				for (uint32 i = 0; i < peizhiInfo.size(); i++)
				{
					vector<uint32> idxList;
					awardManager.GetAwardIdxList(type,peizhiInfo[i].index,idxList);
					
					uint8 buyState = ((buyRecord&(1<<peizhiInfo[i].index)) == 0) ? (uint8)0 : (uint8)1;
					msg << (uint8)peizhiInfo[i].index << buyState << peizhiInfo[i].YB<< peizhiInfo[i].price << (uint8)idxList.size();
					
					for (uint32 j = 0; j < idxList.size(); j++)
					{
						SHuoDongAward award;
						awardManager.GetAwardData(type,idxList[j],award);

						if (award.idx3 > 0 && award.idx3 < 32)
						{
							uint8 state = 1;
							uint8 getState = ((getMask&(1<<award.idx3)) == 0) ? (uint8)0 : (uint8)1;
							if (buyState == 1 && costDay == award.idx3)
								state = 2;
							if (buyState == 1 && getState == 1)
								state = 3;
							msg << (uint8)award.idx3<<state;
							
							uint16 pos = msg.GetDataLen();
							uint8 typeNum = 0;
							msg << typeNum;
							typeNum = MakeAwardMsg(pUser, award, type, msg);
							msg.WriteData(pos,&typeNum,sizeof(typeNum));
						}
						else
						{
							msg << (uint32)0;
						}
					}
				}
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			else if (op1 == 2)
			{
				uint8 jijinId = 0;
				uint8 day = 0;
				msg>>jijinId>>day;
				if ((jijinId <= 0 && jijinId > 7) || (day <= 0 && day > 31))
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1627,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				uint8 buyRecord = pUser->GetExtData8(buyRecordDataId);
				uint32 buyFirstTime = pUser->GetExtData32(buyFirstTimeDataId);
				uint32 getMask = pUser->GetExtData32(getMaskDataId);
				uint32 curTime = GetSysTime();
				if (buyFirstTime == 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1628,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				uint8 buyState = ((buyRecord&(1<<jijinId)) == 0) ? (uint8)0 : (uint8)1;
				if (buyState == 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1629,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				uint8 costDay = 1;
				costDay = curTime > buyFirstTime ? ((curTime - buyFirstTime) / (24 * 3600) + 1) : 1;
				if (costDay > 31)
					costDay = 31;
				uint8 getState = (getMask&(1<<costDay)) == 0 ? (uint8)0 : (uint8)1;
				if (getState == 1)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1630,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				uint32 idx = awardManager.GetAwardIdx(type,jijinId,costDay);
				if (idx == 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1631,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				SHuoDongAward award;
				awardManager.GetAwardData(type,idx,award);
				for(uint8 j=0;j < SHuoDongAward::AWARD_NUM;j++)
					AddHuoDongAward(pUser,type,award.award[j],award.num[j],award.petQuality[j],award.petQualityLv[j]);

				getMask |= (1<<costDay);
				pUser->SetExtData32(getMaskDataId, getMask);
				
				msg<<PRO_SUCCESS;
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				NoticeHuoDongHotPoint(pUser, type);
			}
		}
		break;
	case HD_SHENJIANG_ZHEKOU:
		DealShenJiangZheKou(msg, pUser);
		break;

	case HD_LEVEL_JIJIN1:
		{
			uint8 op1 = 0;	// 1获取列表信息
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
			uint32 type = CHuoDongAwardManager::LEVEL_JIJIN1_FANLI;
			uint32 dataId;
			uint32 maskDataId;
			if (!GetLevelFanLiDataId(type, dataId, maskDataId))
				return;

			uint8 buyRecord = pUser->GetExtData8(dataId);
			uint32 getMask;// = pUser->GetExtData32(maskDataId);

			msg >> op1;
			if (op1 == 1)
			{
				vector<HDPeiZhiInfo> peizhiInfo;
				awardManager.GetPeiZhiInfo(peizhiInfo,type);
				if (peizhiInfo.size() == 0)
				{
					if (gyu::util::CIniFile::GetValue("local_test","server",gConfigFile) == "1")
					{
						msg << PRO_SUCCESS << pUser->GetRegDayToAfterDaySec(7) << buyRecord << (uint8)2;
						for (uint8 fundId = 1; fundId <= 2; ++fundId)
						{
							msg << fundId << (uint8)0 << (uint32)(fundId * 100) << (uint32)(fundId * 300)
								<< (uint32)(fundId * 3000) << (uint8)3;
							for (uint8 tier = 1; tier <= 3; ++tier)
								msg << (uint8)(tier * 20) << (uint8)1 << (uint8)1 << (uint16)1 << (uint32)(tier * fundId * 100);
						}
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						return;
					}
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1626,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				msg<<PRO_SUCCESS<< pUser->GetRegDayToAfterDaySec(7) << buyRecord <<(uint8)peizhiInfo.size();
				for (uint32 i = 0; i < peizhiInfo.size(); i++)
				{
					if (peizhiInfo[i].index == 1)
						maskDataId = 458;
					else if (peizhiInfo[i].index == 2)
						maskDataId = 475;

					getMask = pUser->GetExtData32(maskDataId);
					vector<uint32> idxList;
					awardManager.GetAwardIdxList(type,peizhiInfo[i].index,idxList);
					
					uint8 buyState = ((buyRecord&(1<<peizhiInfo[i].index)) == 0) ? (uint8)0 : (uint8)1;
					msg << (uint8)peizhiInfo[i].index << buyState << peizhiInfo[i].YB<< peizhiInfo[i].price << peizhiInfo[i].water_cz << (uint8)idxList.size();
					
					for (uint32 j = 0; j < idxList.size(); j++)
					{
						SHuoDongAward award;
						awardManager.GetAwardData(type,idxList[j],award);

						uint8 state = 1;
						uint8 getState = ((getMask&(1 << (j + 1))) == 0) ? (uint8)0 : (uint8)1;
						if (buyState == 1)
						{
							if (getState == 1)
							{
								state = 3;
							}
							else if (award.idx3 <= pUser->GetLevel())
							{
								state = 2;
							}
						}
						msg << (uint8)award.idx3 << (uint8)state;

						uint16 pos = msg.GetDataLen();
						uint8 typeNum = 0;
						msg << typeNum;
						typeNum = MakeAwardMsg(pUser, award, type, msg);
						msg.WriteData(pos, &typeNum, sizeof(typeNum));
					}
				}
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			else if (op1 == 2)
			{
				uint8 jijinId = 0;
				uint8 idx = 0;
				msg>> jijinId >> idx;

				if (jijinId == 1)
					maskDataId = 458;
				else if (jijinId == 2)
					maskDataId = 475;
				getMask = pUser->GetExtData32(maskDataId);

				uint8 buyState = ((buyRecord&(1<<jijinId)) == 0) ? (uint8)0 : (uint8)1;
				if (buyState == 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1629,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				// 领取状态
				uint8 getState = (getMask&(1<< idx)) == 0 ? (uint8)0 : (uint8)1;
				if (getState == 1)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1630,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				uint32 jijinIdx = awardManager.GetLevelJiJinAwardIdx(type,jijinId, idx, pUser->GetLevel());
				if (jijinIdx == 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1631,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				SHuoDongAward award;
				awardManager.GetAwardData(type, jijinIdx,award);
				for(uint8 j=0;j < SHuoDongAward::AWARD_NUM;j++)
					AddHuoDongAward(pUser,type,award.award[j],award.num[j],award.petQuality[j],award.petQualityLv[j]);

				getMask |= (1<< idx);
				pUser->SetExtData32(maskDataId, getMask);
				
				msg<<PRO_SUCCESS;
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				NoticeHuoDongHotPoint(pUser, type);
			}
		}
		break;

	case HD_HUOUE_JIJIN1:
		{
			uint8 op1=0;	// 1获取列表信息
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
			uint32 type = CHuoDongAwardManager::HUOYUE_JIJIN_FANLI;

			msg >> op1;
			pUser->HuoYueDataChange();
			uint8 buyRecord = pUser->GetExtData8(680);
			uint32 buyTime = 0;
			uint32 getMask = 0;
			uint32 dayMark = 0;
			if (op1 == 1)
			{
				vector<HDPeiZhiInfo> peizhiInfo;
				awardManager.GetPeiZhiInfo(peizhiInfo,type);
				if (peizhiInfo.size() == 0)
				{
					if (gyu::util::CIniFile::GetValue("local_test","server",gConfigFile) == "1")
					{
						msg << PRO_SUCCESS << (uint32)(7 * 24 * 60 * 60) << buyRecord << (uint8)2;
						for (uint8 fundId = 1; fundId <= 2; ++fundId)
						{
							msg << fundId << (uint8)0 << (uint32)0 << (uint8)0 << (uint32)(fundId * 100)
								<< (uint32)(fundId * 300) << (uint32)(fundId * 3000) << (uint8)3;
							for (uint8 tier = 1; tier <= 3; ++tier)
								msg << (uint8)(tier * 3) << (uint8)1 << (uint8)1 << (uint16)1 << (uint32)(tier * fundId * 100);
						}
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						return;
					}
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1626,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				uint32 endTime = awardManager.GetHuoDongEndTime(type);
				uint32 now = GetSysTime();
				uint32 desc = endTime > now ? endTime - now : 0;
				msg << PRO_SUCCESS << desc << buyRecord << (uint8)peizhiInfo.size();
				for (uint32 i = 0; i < peizhiInfo.size(); i++)
				{
					vector<uint32> idxList;
					awardManager.GetAwardIdxList(type, peizhiInfo[i].index, idxList);
					uint32 maskDataId;
					uint32 dateId;
					if (peizhiInfo[i].index == 1)
					{
						dateId = 470;
						maskDataId = 471;
						dayMark = 681;
					}
					else if (peizhiInfo[i].index == 2)
					{
						dateId = 472;
						maskDataId = 473;
						dayMark = 682;
					}
					
					uint8 buyState = ((buyRecord&(1<<peizhiInfo[i].index)) == 0) ? (uint8)0 : (uint8)1;
					uint8 canGetDay = pUser->GetExtData8(dayMark);
					getMask = pUser->GetExtData32(maskDataId);
					msg << (uint8)peizhiInfo[i].index << buyState << buyTime << canGetDay << peizhiInfo[i].YB << peizhiInfo[i].price << peizhiInfo[i].water_cz << (uint8)idxList.size();
					for (uint32 j = 0; j < idxList.size(); j++)
					{
						SHuoDongAward award;
						awardManager.GetAwardData(type,idxList[j],award);

						uint8 state = 1;
						uint8 getState = ((getMask&(1 << (j + 1))) == 0) ? (uint8)0 : (uint8)1;
						if (buyState == 1)
						{
							if (getState == 1)
							{
								state = 3;
							}
							else if (award.idx3 <= canGetDay)
							{
								state = 2;
							}
						}
						msg << (uint8)award.idx3 << (uint8)state;

						uint16 pos = msg.GetDataLen();
						uint8 typeNum = 0;
						msg << typeNum;
						typeNum = MakeAwardMsg(pUser, award, type, msg);
						msg.WriteData(pos, &typeNum, sizeof(typeNum));
					}
				}
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			else if (op1 == 2)
			{
				uint8 jijinId = 0;
				uint8 idx = 0;
				msg>> jijinId >> idx;
				uint32 maskDataId;
				uint32 dateId;
				uint32 dayMark;
				if (jijinId == 1)
				{
					dateId = 470;
					maskDataId = 471;
					dayMark = 681;
				}
				else if (jijinId == 2)
				{
					dateId = 472;
					maskDataId = 473;
					dayMark = 682;
				}
				buyTime = pUser->GetExtData32(dateId);
				getMask = pUser->GetExtData32(maskDataId);
				uint8 getDay = pUser->GetExtData8(dayMark);
				uint8 buyState = ((buyRecord&(1<<jijinId)) == 0) ? (uint8)0 : (uint8)1;
				if (buyState == 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1629,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				// 领取状态
				uint8 getState = (getMask&(1<< idx)) == 0 ? (uint8)0 : (uint8)1;
				if (getState == 1)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1630,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				if (getDay < idx)
				{
					msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_1558, TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(), msg);
					return;
				}
				uint32 jijinIdx = awardManager.GetAwardIdx(type,jijinId, idx);
				if (jijinIdx == 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1631,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				SHuoDongAward award;
				awardManager.GetAwardData(type, jijinIdx,award);
				for(uint8 j=0;j < SHuoDongAward::AWARD_NUM;j++)
					AddHuoDongAward(pUser,type,award.award[j],award.num[j],award.petQuality[j],award.petQualityLv[j]);

				getMask |= (1<< idx);
				pUser->SetExtData32(maskDataId, getMask);
				
				msg<<PRO_SUCCESS;
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				NoticeHuoDongHotPoint(pUser, type);
			}
		}
		break;
	case HD_DAOJUHUISHOU:
		{
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
			uint32 hd_type = CHuoDongAwardManager::DAOJUHUISHOU;

			uint8 type = 0;
			msg>>type;
			if( 0 == type )// C->S 请求界面信息
			{
				msg.ReWrite();
				msg.SetType(MSG_TMP_HUODONG);

				if(!awardManager.InHuoDongTime(hd_type))
				{
					msg<<op<<type<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1632,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				std::vector<HDExchangeInfo> infoVec;
				infoVec.clear();
				awardManager.GetExchangeInfo(hd_type,infoVec);
				if( infoVec.empty())
				{
					msg<<op<<type<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1633,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				msg<<op<<type<<PRO_SUCCESS<<awardManager.GetHuoDongTimeDesc(hd_type);
				msg<<(uint32)infoVec.size();
				std::vector<HDExchangeInfo>::iterator vec_iter = infoVec.begin();
				for( ; vec_iter != infoVec.end(); ++vec_iter )
				{
					MakeExchangeInfoMsg(pUser,*vec_iter,msg,hd_type);
				}//end of for
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				NoticeHuoDongHotPoint(pUser,hd_type);
			}
			else if( 1 == type ) //C->S 请求
			{
				if(!awardManager.InHuoDongTime(hd_type))
				{
					return;
				}
				uint32 id = 0;
				msg>>id;
				msg.ReWrite();
				msg.SetType(MSG_TMP_HUODONG);
				HDExchangeInfo info;
				awardManager.GetExchangeInfo(hd_type,id,info);
				if( info.idx !=0 && info.material[0] !=0 && info.award[0] !=0 )
				{
					//扣除需求材料，默认只扣一种
					if((uint32)pUser->GetItemNum(info.material[0]) >= info.material_num[0])
					{
						pUser->DelPackageById(info.material[0],info.material_num[0]);
					}
					else
					{
						return;
					}
					//发道具，默认只发一种
					char buf[256];
					snprintf(buf,sizeof(buf),"%s*%d%s",GetItemName(info.material[0]),info.material_num[0],LANGUAGE_SSJ_1002);
					AddHuoDongAward(pUser,hd_type,info.award[0],info.num[0],info.petQuality[0],info.petQualityLv[0],true,true,buf);	
					msg<<op<<type<<PRO_SUCCESS;
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					NoticeHuoDongHotPoint(pUser,hd_type);
				}
			}
			return;
		}
		break;
	case HD_MEIRI_HUAN_HAOLI:
		{
			uint8 op1 = 0;
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
			uint32 type = CHuoDongAwardManager::MEIRI_HUANHAOLI;
			string desc = awardManager.GetHuoDongTimeDesc(type);

			if (!awardManager.InHuoDongTime(type))
				return;
			
			msg>>op1;
			if (op1 == 1)
			{
				vector<HDExchangeInfo> infoList;
				map<uint32,uint32> goods;
				awardManager.GetExchangeInfo(type,infoList);
				if (infoList.size() <= 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1634,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				msg<<PRO_SUCCESS<<desc.c_str();
		
				uint16 pos = msg.GetDataLen();
				uint8 typeNum = 0;
				msg << typeNum;
				for (uint32 i = 0; i < infoList.size(); i++)
				{
					if (infoList[i].isShow == 1)
					{
						MakeExchangeInfoMsg(pUser,infoList[i],msg,type,&goods);
						typeNum++;
					}
				}
				msg.WriteData(pos,&typeNum,sizeof(typeNum));

				msg<<(uint8)goods.size();
				map<uint32,uint32>::iterator it = goods.begin();
				for (;it != goods.end(); it++)
				{
					msg<<it->first;
					if (it->first < HDAT_MONEY)
						msg<<pUser->GetItemNum(it->first);
					else if (it->first == HDAT_MONEY)
						msg<<pUser->GetMoney();
					else if (it->first == HDAT_BANG_YB)
						msg<<pUser->GetTongBao(1);
					else if (it->first == HDAT_YB)
						msg<<pUser->GetTongBao();
				}
				
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			else if (op1 == 2)
			{
				uint32 idx = 0;
				uint8 index = 0;//任一
				msg>>idx>>index;
				if (idx == 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1635,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(), msg);
					return;
				}

				HDExchangeInfo info;
				bool isGetInfo = awardManager.GetExchangeInfo(type,idx,info);
				if (!isGetInfo)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1636,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(), msg);
					return;
				}

				uint8 count = 0;
				if (info.saveExt8 != 0 && info.exchange_num_limit > 0)
					count = pUser->GetExtData8(info.saveExt8);

				if (info.exchange_num_limit > 0 && count >= info.exchange_num_limit)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1637,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(), msg);
					return;
				}
				if(info.materialIsOr == 1 && (index == 0 || index > HDExchangeInfo::MATERIAL_NUM || info.material[index-1] < 1 || info.material_num[index-1] < 1))
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_CC_0010,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(), msg);
					return;
				}
                
				bool isSuccess = MakeDoExchangeMsg(pUser, info, msg,type,index);
				if (isSuccess)
					NoticeHuoDongHotPoint(pUser, type);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
		}
		break;
	case HD_XIAN_SHI_CHOU:
		{
			uint8 op1 = 0;
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
			uint32 type = CHuoDongAwardManager::XIANSHI_CHOU;
			const uint32 lastTimeDataId = 298;
			const uint32 curScoreDataId = 299;
			const uint32 getMaskDataId = 300;
			const uint32 SHOW_IDX2 = 3;
			const uint32 SHOW_IDX3 = 0;
			const uint32 PAIHANG_IDX2 = 1;
			const uint32 JIFEN_IDX2 = 2;
			const uint32 PAIHANG_MAXSIZE = 20;
			
			uint32 endTime = awardManager.GetHuoDongEndTime(type);
			uint32 lastChouTime = pUser->GetExtData32(lastTimeDataId);
			uint32 curScore = pUser->GetExtData32(curScoreDataId);
			uint32 getMask = pUser->GetExtData32(getMaskDataId);
			uint32 curTime = GetSysTime();
			
			if (!awardManager.InHuoDongTime(type))
				return;

			vector<HDPeiZhiInfo> peizhiInfo;
			awardManager.GetPeiZhiInfo(peizhiInfo,type);
			if (peizhiInfo.size() == 0)
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1626,TIPS_FAILURE_COLOR);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				return;
			}

			uint32 freeCdTime = 0;
			for (uint32 i = 0; i < peizhiInfo.size(); i++)
			{
				if (peizhiInfo[i].count == 0)
					freeCdTime = peizhiInfo[i].cd;
			}

			if (freeCdTime == 0)
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0028,TIPS_FAILURE_COLOR);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				return;
			}

			msg >> op1;
			if (op1 == 1)
			{
				vector<HDPaiHangInfo> paihangInfo;
				awardManager.GetHDPaiHangInfo(type,paihangInfo);
				if (paihangInfo.size() == 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0029,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				bool isFree = (lastChouTime == 0 || (lastChouTime + freeCdTime) < curTime) ? true : false;
				msg << PRO_SUCCESS << (endTime - curTime) << (uint8)isFree;

				// 购买档次
				uint16 pos = msg.GetDataLen();
				uint8 size = 0;
				msg<<size;
				for (uint32 i = 0; i < peizhiInfo.size(); i++)
				{
					if (peizhiInfo[i].count == 0)
						continue;

					msg<<peizhiInfo[i].count<<peizhiInfo[i].YB;
					size++;
				}
				msg.WriteData(pos,&size,sizeof(size));

				// 翅膀 坐骑 神将 等数据
				uint32 idx = awardManager.GetAwardIdx(type,SHOW_IDX2,SHOW_IDX3);
				SHuoDongAward award;
				awardManager.GetAwardData(type,idx,award);
				MakeAwardMsg(pUser, award, type, msg);

				// 排行榜奖励
				msg<<(uint8)paihangInfo.size();
				for (uint32 i = 0; i < paihangInfo.size(); i++)
				{
					msg<<(uint8)paihangInfo[i].startId<<(uint8)paihangInfo[i].endId;

					uint32 idx3 = paihangInfo[i].idx;
					idx = awardManager.GetAwardIdx(type,PAIHANG_IDX2,idx3);
					awardManager.GetAwardData(type,idx,award);
					
					pos = msg.GetDataLen();
					size = 0;
					msg << size;
					size = MakeAwardMsg(pUser, award, type, msg);
					msg.WriteData(pos,&size,sizeof(size));
				}

				// 积分奖励
				vector<uint32> idxList;
				awardManager.GetAwardIdxList(type,JIFEN_IDX2,idxList);
				msg<<(uint8)idxList.size();
				for (uint32 i = 0; i < idxList.size(); i++)
				{
					uint8 state = 1;  // 1 不满足领取条件，2 可领取 3已经领取
					awardManager.GetAwardData(type,idxList[i],award);
					msg<<award.idx3<<award.needYB;

					if (curScore >= award.needYB)
						state = 2;

					uint8 getState = ((getMask&(1<<award.idx3)) == 0) ? (uint8)0 : (uint8)1;
					if (getState == 1)
						state = 3;
					msg << state;
					pos = msg.GetDataLen();
					size = 0;
					msg << size;
					size = MakeAwardMsg(pUser, award, type, msg);
					msg.WriteData(pos,&size,sizeof(size));
				}

				// 积分排行榜
				uint32 myBang = 0;
				uint32 myRoleId = pUser->GetRoleId();
				vector<HDPaiHangRecordInfo> recordInfo;
				awardManager.GetHDPaiHangRecord(type,recordInfo);
				size = recordInfo.size();
				if (size > PAIHANG_MAXSIZE)
					size = PAIHANG_MAXSIZE;
				msg<<(uint8)size;
				for (uint32 i = 0; i < size; i++)
				{
					msg<<(uint8)(i+1)<<recordInfo[i].data<<recordInfo[i].bang_name;
					if (recordInfo[i].role_id == myRoleId)
						myBang = i + 1;
				}
				msg<<curScore<<myBang;
				
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			else if (op1 == 2)
			{
				uint8 count = 0;
				int costYB = 0;
				int getScore = 0;
				
				msg>>count;
				if (count == 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1635,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(), msg);
					return;
				}

				for (uint32 i = 0; i < peizhiInfo.size(); i++)
				{
					if (peizhiInfo[i].count == count)
					{
						costYB = peizhiInfo[i].YB;
						getScore = peizhiInfo[i].price;
						break;
					}
				}

				if (costYB == 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1635,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(), msg);
					return;
				}
				
				bool isFree = ((count == 1) && (lastChouTime == 0 || (lastChouTime + freeCdTime) < curTime)) ? true : false;
				if (isFree)
				{
					costYB = 0;
					getScore = 0;
					pUser->SetExtData32(lastTimeDataId,curTime);
					isFree = false;
				}
				else
				{
					//modified by zhudaolong
					//if (pUser->GetTongBao() < costYB)
					if (pUser->GetItemNum(2010) < costYB)
					{
						msg<<PRO_ERROR<<"";
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						ShowJumpNotice(pUser,JUMP_NOTICE_YB);
						return;
					}
				}
				//modified by zhudaolong
				//pUser->AddTongBao(-costYB);
				pUser->DelPackageById(2010, costYB);
				pUser->SetExtData32(curScoreDataId,curScore + getScore);
				awardManager.AddHDRandAward(pUser,type,count,costYB);
				awardManager.UpdatePaiHang(pUser, type,pUser->GetExtData32(curScoreDataId));
				msg<<PRO_SUCCESS<<pUser->GetExtData32(curScoreDataId)<<(uint8)isFree;
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			else if (op1 == 3)
			{
				uint32 idx3 = 0;
				msg>>idx3;
				if (idx3 == 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1635,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(), msg);
					return;
				}

				uint32 idx = awardManager.GetAwardIdx(type,JIFEN_IDX2,idx3);
				if (idx == 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0030,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(), msg);
					return;
				}

				SHuoDongAward award;
				awardManager.GetAwardData(type,idx,award);

				uint8 state = 1;
				if (curScore >= award.needYB)
					state = 2;

				uint8 getState = ((getMask&(1<<award.idx3)) == 0) ? (uint8)0 : (uint8)1;
				if (getState == 1)
					state = 3;

				if (state == 1)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0031,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(), msg);
					return;
				}
				else if (state == 3)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0032,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(), msg);
					return;
				}

				getMask |= (1<<award.idx3);
				pUser->SetExtData32(getMaskDataId, getMask);
				for(uint8 j=0;j < SHuoDongAward::AWARD_NUM;j++)
				{
					AddHuoDongAward(pUser,type,award.award[j],award.num[j],award.petQuality[j],award.petQualityLv[j]);
				}
				msg<<PRO_SUCCESS;
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
		}
		break;
	case HD_XINCHUN_HAPPY:	//新春快乐
		{
			uint32 type = CHuoDongAwardManager::XINCHUN_HAPPY;
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
			uint32 getMaskDataId = 535;
			uint32 scoreDataId = 381;

			if (!awardManager.InHuoDongTime(type))
				return;

			vector<HDPeiZhiInfo> peizhiInfo;
			awardManager.GetPeiZhiInfo(peizhiInfo,type);
			if (peizhiInfo.size() == 0)
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0183,TIPS_FAILURE_COLOR);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				return;
			}

			uint8 op1 = 0;
			msg>>op1;

			if (op1 == 1)  // 界面
			{
				char buff[512];

				msg<<PRO_SUCCESS;
				msg<<awardManager.GetHuoDongTimeDesc(type);

				uint32 limitScore = awardManager.GetPaiHangLimitScore(type);
				snprintf(buff,sizeof(buff),LANGUAGE_LLD_0184,limitScore);
				msg<<buff<<pUser->GetExtData32(scoreDataId);
				msg<<(uint32)peizhiInfo.size();

				map<uint32,string> ziti;
				map<uint32,uint8> zitiState;
				for (uint32 i = 0; i < peizhiInfo.size(); i++)
				{
					uint32 itemid = peizhiInfo[i].YB;
					uint32 numDataId = peizhiInfo[i].saveLastTimeId;
					uint32 style = peizhiInfo[i].lv;
					uint32 zitiNum = pUser->GetExtData32(numDataId);
					msg<<itemid<<zitiNum;

					const char *itemName = GetItemName(itemid);
					if (itemName == NULL)
					{
						msg.ReWrite();
						msg.SetType(MSG_TMP_HUODONG);
						msg<<HD_XINCHUN_HAPPY<<op1<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0185,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						return;
					}

					if (style != 0)
					{
						map<uint32,uint8>::iterator it = zitiState.find(style);
						if (it == zitiState.end())
							zitiState.insert(make_pair(style,1));

						if (zitiNum == 0)
							zitiState[style] = 0;
					}

					string strItemName = itemName;
					if (style != 0)
					{
						map<uint32,string>::iterator it = ziti.find(style);
						if (it == ziti.end())
							ziti.insert(make_pair(style,strItemName));
						else
							it->second = it->second + itemName;
					}
				}

				vector<uint32> zitiIdxList;
				awardManager.GetAwardIdxList(type,CHuoDongAwardManager::XINCHUN_HAPPY_IDX2_ZITI,zitiIdxList);
				msg<<(uint32)zitiIdxList.size();
				for (uint32 i = 0; i < zitiIdxList.size(); i++)
				{
					SHuoDongAward award;
					awardManager.GetAwardData(type,zitiIdxList[i],award);

					msg<<award.idx;
					map<uint32,string>::iterator it = ziti.find(award.idx3);
					if (it == ziti.end())
						msg<<"";
					else
						msg<<it->second;

					msg<<zitiState[award.idx3];

					uint16 awardNumPos = msg.GetDataLen();
					uint8 awardNum = 0;
					msg<<awardNum;
					awardNum = MakeAwardMsg(pUser,award,type,msg);
					msg.WriteData(awardNumPos,&awardNum,sizeof(awardNum));
				}

				vector<uint32> jifenIdxList;
				awardManager.GetAwardIdxList(type,CHuoDongAwardManager::XINCHUN_HAPPY_IDX2_JIFEN,jifenIdxList);
				msg<<(uint32)jifenIdxList.size();
				for (uint32 i = 0; i < jifenIdxList.size(); i++)
				{
					SHuoDongAward award;
					awardManager.GetAwardData(type,jifenIdxList[i],award);

					msg<<award.idx;
					msg<<award.needYB;

					uint8 getMask = pUser->GetExtData8(getMaskDataId);
					uint8 getState = ((getMask&(1<<award.idx3)) == 0) ? (uint8)0 : (uint8)2;
					if (getState == 0 && pUser->GetExtData32(scoreDataId) >= award.needYB)
						getState = 1;
					msg<<getState;

					uint16 awardNumPos = msg.GetDataLen();
					uint8 awardNum = 0;
					msg<<awardNum;
					awardNum = MakeAwardMsg(pUser,award,type,msg);
					msg.WriteData(awardNumPos,&awardNum,sizeof(awardNum));
				}

				vector<uint32> paihangIdxList;
				awardManager.GetAwardIdxList(type,CHuoDongAwardManager::XINCHUN_HAPPY_IDX2_PAIHANG,paihangIdxList);
				msg<<(uint32)paihangIdxList.size();
				for (uint32 i = 0; i < paihangIdxList.size(); i++)
				{
					SHuoDongAward award;
					awardManager.GetAwardData(type,paihangIdxList[i],award);

					msg<<award.idx3;

					uint16 awardNumPos = msg.GetDataLen();
					uint8 awardNum = 0;
					msg<<awardNum;
					awardNum = MakeAwardMsg(pUser,award,type,msg);
					msg.WriteData(awardNumPos,&awardNum,sizeof(awardNum));
				}
			}
			else if (op1 == 2)   //排行榜
			{
				vector<HDPaiHangRecordInfo> info;
				awardManager.GetHDPaiHangRecord(type,info);
				msg<<PRO_SUCCESS<<(uint32)info.size();
				for (uint32 i = 0; i< info.size(); i++)
				{
					msg<<i+1;
					msg<<info[i].role_id;
					msg<<info[i].role_name;
					msg<<info[i].role_lv;
					msg<<info[i].xiang;
					msg<<info[i].sex;
					msg<<info[i].bang_name;
					msg<<info[i].data;

					uint32 idx = awardManager.GetAwardIdx(type,CHuoDongAwardManager::XINCHUN_HAPPY_IDX2_PAIHANG,i+1);
					SHuoDongAward award;
					awardManager.GetAwardData(type,idx,award);

					uint16 awardNumPos = msg.GetDataLen();
					uint8 awardNum = 0;
					msg<<awardNum;
					awardNum = MakeAwardMsg(pUser,award,type,msg);
					msg.WriteData(awardNumPos,&awardNum,sizeof(awardNum));
				}
			}
			else if (op1 == 3) //点击字体
			{
				uint32 itemId = 0;
				int num = 0;
				msg>>itemId;
				msg>>num;

				msg.ReWrite();
				msg.SetType(MSG_TMP_HUODONG);
				msg<<op<<op1;

				if (num <= 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0186,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				vector<HDPeiZhiInfo> peizhiInfo;
				awardManager.GetPeiZhiInfo(peizhiInfo,type);
				if (peizhiInfo.size() == 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0183,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				vector<uint32> idxList;
				awardManager.GetAwardIdxList(type,idxList);
				if (idxList.size() == 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0194,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
									
				uint32 numDataId = 0;
//				uint32 style = 0;
				bool isFind = false;
				for (uint32 i = 0; i < peizhiInfo.size(); i++)
				{
					uint32 peizhiItemid = peizhiInfo[i].YB;
					if (peizhiItemid == itemId)
					{
						numDataId = peizhiInfo[i].saveLastTimeId;
//						style = peizhiInfo[i].lv;
						isFind = true;
						break;
					}
				}

				if (!isFind)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0187,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				if (pUser->GetItemNum(itemId) < num)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0188,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				HDItemScoreExchangeInfo exchangeInfo;
				if (!awardManager.GetHDExchangeScoreInfoByItem(itemId,exchangeInfo))
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0190,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				uint32 score = num * exchangeInfo.giveScore;
				pUser->DelPackageById(itemId,num);
				pUser->SetExtData32(numDataId,pUser->GetExtData32(numDataId) + num);
				pUser->SetExtData32(scoreDataId,pUser->GetExtData32(scoreDataId) + score);

				awardManager.UpdatePaiHang(pUser,type,pUser->GetExtData32(scoreDataId));

				char buff[512];
				snprintf(buff,sizeof(buff),LANGUAGE_LLD_0189,itemId,num,score);
				SaveDate(pUser->GetRoleId(),type+500,itemId * 10000 + num,buff);

				msg<<PRO_SUCCESS<<itemId<<pUser->GetExtData32(numDataId)<<pUser->GetExtData32(scoreDataId);

				uint16 awardListPos = msg.GetDataLen();
				uint32 awardListNum = 0;
				msg<<awardListNum;
				for (uint32 i = 0; i < idxList.size(); i++)
				{
					SHuoDongAward award;
					awardManager.GetAwardData(type,idxList[i],award);

					if (award.idx2 == CHuoDongAwardManager::XINCHUN_HAPPY_IDX2_ZITI)
					{
						msg << award.idx;
						awardListNum++;
						
						uint8 canGetAward = 1;
						for (uint32 j = 0; j < peizhiInfo.size(); j++)
						{
							if ((peizhiInfo[j].lv == award.idx3) && (pUser->GetExtData32(peizhiInfo[j].saveLastTimeId) == 0))
							{
								canGetAward = 0;
								break;
							}
						}

						msg<<canGetAward;
					}
					else if (award.idx2 == CHuoDongAwardManager::XINCHUN_HAPPY_IDX2_JIFEN)
					{
						msg << award.idx;
						awardListNum++;
						
						uint8 getMask = pUser->GetExtData8(getMaskDataId);
						uint8 getState = ((getMask&(1<<award.idx3)) == 0) ? (uint8)0 : (uint8)2;
						if (getState == 0 && pUser->GetExtData32(scoreDataId) >= award.needYB)
							getState = 1;
						msg<<getState;
					}
				}
				msg.WriteData(awardListPos,&awardListNum,sizeof(awardListNum));
				
			}
			else if (op1 == 4) //领取奖励
			{
				uint32 idx = 0;			
				msg>>idx;

				msg.ReWrite();
				msg.SetType(MSG_TMP_HUODONG);
				msg<<op<<op1;

				if (idx == 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0191,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				vector<HDPeiZhiInfo> peizhiInfo;
				awardManager.GetPeiZhiInfo(peizhiInfo,type);
				if (peizhiInfo.size() == 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0183,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				SHuoDongAward award;
				awardManager.GetAwardData(type,idx,award);
				uint8 getState = 1;   // 0 不可领取，1 可领取  2 已领取
				if (award.idx2 == CHuoDongAwardManager::XINCHUN_HAPPY_IDX2_ZITI)
				{
					for (uint32 i = 0; i < peizhiInfo.size(); i++)
					{
						if ((peizhiInfo[i].lv == award.idx3) && (pUser->GetExtData32(peizhiInfo[i].saveLastTimeId) <= 0))
						{
							msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0193,TIPS_FAILURE_COLOR);
							m_socketServer.SendMsg(pUser->GetSock(),msg);
							return;
						}
					}

					for (uint32 i = 0; i < peizhiInfo.size(); i++)
					{
						if (peizhiInfo[i].lv == award.idx3)
						{
							pUser->SetExtData32(peizhiInfo[i].saveLastTimeId,pUser->GetExtData32(peizhiInfo[i].saveLastTimeId) - 1);
							if (pUser->GetExtData32(peizhiInfo[i].saveLastTimeId) <= 0)
								getState = 0;
						}
					}	
				}
				else if (award.idx2 == CHuoDongAwardManager::XINCHUN_HAPPY_IDX2_JIFEN)
				{
					uint8 getMask = pUser->GetExtData8(getMaskDataId);
					getState = ((getMask&(1<<award.idx3)) == 0) ? (uint8)0 : (uint8)2;
					if (getState == 0 && pUser->GetExtData32(scoreDataId) >= award.needYB)
						getState = 1;
		
					if (getState == 0)
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0195,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						return;
					}
					else if (getState == 2)
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0196,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						return;
					}

					getMask = getMask | (1 << award.idx3);
					pUser->SetExtData8(getMaskDataId,getMask);
					getState = 2;
				}
				else
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0192,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				for(int i=0; i < SHuoDongAward::AWARD_NUM; ++i ) 
				{ 
					AddHuoDongAward(pUser,type,award.award[i],award.num[i],award.petQuality[i],award.petQualityLv[i]); 
				}

				msg<<PRO_SUCCESS<<idx<<getState;
				msg<<(uint32)peizhiInfo.size();
				for (uint32 i = 0; i < peizhiInfo.size(); i++)
				{
					uint32 itemid = peizhiInfo[i].YB;
					uint32 numDataId = peizhiInfo[i].saveLastTimeId;
					uint32 zitiNum = pUser->GetExtData32(numDataId);
					msg<<itemid<<zitiNum;
				}

			}
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			break;
		}
	case HD_ZHENYING_PK:
		{
			uint32 hd_main_type = CHuoDongAwardManager::ZHENYING_PK;
			uint32 hd_pk1_type = CHuoDongAwardManager::ZHENYING_PK1;
			uint32 hd_pk2_type = CHuoDongAwardManager::ZHENYING_PK2;
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
			uint32 myZhenYingDataId = 383;

			if (!awardManager.InHuoDongTime(hd_main_type))
				return;

			uint8 op1 = 0;
			msg>>op1;
			if (op1 == 1)  // 初始界面和选择阵营操作
			{
				uint32 chooseZhenYing = 0;
				msg >> chooseZhenYing;

				msg.ReWrite();
				msg.SetType(MSG_TMP_HUODONG);
				msg<<op<<op1;

				uint32 zhenying1Score = awardManager.GetZhenYingScore(hd_pk1_type);
				uint32 zhenying2Score = awardManager.GetZhenYingScore(hd_pk2_type);
				uint32 myZhenYingId = pUser->GetExtData32(myZhenYingDataId);
				uint32 myZhenYingScore = 0;

				vector <HDPeiZhiInfo> peizhiInfo;
				awardManager.GetPeiZhiInfo(peizhiInfo,hd_main_type);
				if (peizhiInfo.size() != 1)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0216,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
					
				
				if (chooseZhenYing == hd_pk1_type || chooseZhenYing == hd_pk2_type)  // 选择阵营
				{
					if (myZhenYingId == hd_pk1_type || myZhenYingId == hd_pk2_type)
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0197,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						return;
					}

					bool overScore = false;
					if ((chooseZhenYing == hd_pk1_type)
						&& (zhenying1Score > zhenying2Score) 
						&& (zhenying1Score > zhenying2Score * 2))
						overScore = true;

					if ((chooseZhenYing == hd_pk2_type)
						&& (zhenying2Score > zhenying1Score) 
						&& (zhenying2Score > zhenying1Score * 2))
						overScore = true;

					if (overScore)
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0200,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						return;
					}

					SysInfo(pUser,LANGUAGE_LLD_0201);
					pUser->SetExtData32(myZhenYingDataId,chooseZhenYing);
					myZhenYingId = chooseZhenYing;
				}

				if (myZhenYingId != 0)
				{
					vector<GoodsInfo> goodsInfo;
					awardManager.GetHDBangGoods(myZhenYingId, goodsInfo, hd_main_type);
					if (goodsInfo.size() != 2)
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1615,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						return;
					}

					for (uint32 i = 0; i < goodsInfo.size(); i++)
					{
						myZhenYingScore += pUser->GetExtData32(goodsInfo[i].get_data_id) * goodsInfo[i].score_get;
					}
				}

				msg<<PRO_SUCCESS;
				if (myZhenYingId == hd_pk1_type || myZhenYingId == hd_pk2_type)
				{
					msg<<LANGUAGE_LLD_0199;
				}
				else
				{
					msg<<LANGUAGE_LLD_0198;
				}
				
				msg<<peizhiInfo[0].zhenYing1Name<<zhenying1Score<<peizhiInfo[0].zhenYing2Name<<zhenying2Score<<awardManager.GetHuoDongTimeDesc(hd_main_type)<<myZhenYingId<<myZhenYingScore;

				if (myZhenYingId == hd_pk1_type || myZhenYingId == hd_pk2_type)
				{
					vector<HDPaiHangRecordInfo> info;
					awardManager.GetHDPaiHangRecord(hd_main_type,info);
					msg<<(uint32)info.size();
					for (uint32 i = 0; i< info.size(); i++)
					{
						msg<<i+1;
						msg<<info[i].role_id;
						msg<<info[i].role_name;
						msg<<info[i].role_lv;
						msg<<info[i].xiang;
						msg<<info[i].sex;
						msg<<info[i].bang_name;
						msg<<info[i].data;

						uint32 idx3 = awardManager.GetHDPaiHangAwardIdxByRank(hd_main_type,i+1);
						uint32 idx = awardManager.GetAwardIdx(hd_main_type,CHuoDongAwardManager::ZHENYING_PK_ALL_IDX2,idx3);
						SHuoDongAward award;
						awardManager.GetAwardData(hd_main_type,idx,award);

						uint16 awardNumPos = msg.GetDataLen();
						uint8 awardNum = 0;
						msg<<awardNum;
						awardNum = MakeAwardMsg(pUser,award,hd_main_type,msg);
						msg.WriteData(awardNumPos,&awardNum,sizeof(awardNum));
					}
				}
				else
				{
					msg<<(uint32)0;  //不在阵营无排行
				}
			}
			else if(op1 == 2)	//排行界面
			{
				uint32 paihangType = 0;
				msg>>paihangType;
				if ((paihangType != hd_main_type) && (paihangType != hd_pk1_type) && (paihangType != hd_pk2_type))
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0202,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				
				uint32 myZhenYingId = pUser->GetExtData32(myZhenYingDataId);
				if (myZhenYingId != hd_pk1_type && myZhenYingId != hd_pk2_type)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0203,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				msg<<PRO_SUCCESS;
				vector<HDPaiHangRecordInfo> info;
				awardManager.GetHDPaiHangRecord(paihangType,info);
				msg<<(uint32)info.size();
				for (uint32 i = 0; i< info.size(); i++)
				{
					msg<<i+1;
					msg<<info[i].role_id;
					msg<<info[i].role_name;
					msg<<info[i].role_lv;
					msg<<info[i].xiang;
					msg<<info[i].sex;
					msg<<info[i].bang_name;
					msg<<info[i].data;

					uint32 idx3 = awardManager.GetHDPaiHangAwardIdxByRank(hd_main_type,i+1);
//					uint32 idx2 = 0;
//					if (paihangType == hd_main_type)
//						idx2 = CHuoDongAwardManager::ZHENYING_PK_ALL_IDX2;
//					else
//						idx2 = CHuoDongAwardManager::ZHENYING_PK_MEM_IDX2;
					uint32 idx = awardManager.GetAwardIdx(hd_main_type,CHuoDongAwardManager::ZHENYING_PK_ALL_IDX2,idx3);
					SHuoDongAward award;
					awardManager.GetAwardData(hd_main_type,idx,award);

					uint16 awardNumPos = msg.GetDataLen();
					uint8 awardNum = 0;
					msg<<awardNum;
					awardNum = MakeAwardMsg(pUser,award,hd_main_type,msg);
					msg.WriteData(awardNumPos,&awardNum,sizeof(awardNum));
				}
			}
			else if (op1 == 3) //阵营奖励
			{
				uint32 myZhenYingId = pUser->GetExtData32(myZhenYingDataId);
				if (myZhenYingId != hd_pk1_type && myZhenYingId != hd_pk2_type)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0203,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				
				msg<<PRO_SUCCESS;

				vector<HDPaiHangInfo> paihangInfo;
				awardManager.GetHDPaiHangInfo(hd_main_type,paihangInfo);
				if (paihangInfo.size() == 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0204,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				const uint32 ZHENYING_IDXS[] = {CHuoDongAwardManager::ZHENYING_PK_ALL_IDX2,CHuoDongAwardManager::ZHENYING_PK_MEM_IDX2};
				uint32 zhenyingIdxsSize = sizeof(ZHENYING_IDXS)/sizeof(ZHENYING_IDXS[0]);
				msg << (uint8)zhenyingIdxsSize;

				for (uint32 i = 0; i < zhenyingIdxsSize; i++)
				{
					msg<<ZHENYING_IDXS[i];
					uint16 paihangSizePos = msg.GetDataLen();
					uint32 paihangSize = 0;
					msg<<paihangSize;
					for (uint32 j = 0; j < paihangInfo.size(); j++)
					{
						if (ZHENYING_IDXS[i] == CHuoDongAwardManager::ZHENYING_PK_ALL_IDX2 && paihangInfo[j].startId == 0)
							continue;

						msg<<paihangInfo[j].startId;
						msg<<paihangInfo[j].endId;
						msg<<paihangInfo[j].score;
		
						uint32 idx3 = paihangInfo[j].idx;
										
						uint32 idx = awardManager.GetAwardIdx(hd_main_type,ZHENYING_IDXS[i],idx3);
						SHuoDongAward award;
						awardManager.GetAwardData(hd_main_type,idx,award);
										
						uint16 awardNumPos = msg.GetDataLen();
						uint8 awardNum = 0;
						msg<<awardNum;
						awardNum = MakeAwardMsg(pUser,award,hd_main_type,msg);
						msg.WriteData(awardNumPos,&awardNum,sizeof(awardNum));

						paihangSize++;
					}

					msg.WriteData(paihangSizePos,&paihangSize,sizeof(paihangSize));
				}
			}
			else if (op1 == 4)
			{
				const uint8 bangSize = 2;
				uint32 myZhenYingId = pUser->GetExtData32(myZhenYingDataId);

				if (myZhenYingId != hd_pk1_type && myZhenYingId != hd_pk2_type)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0203,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				vector<GoodsInfo> info;
				awardManager.GetHDBangGoods(myZhenYingId, info, hd_main_type);
				if (info.size() != 2)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1615,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				msg<<PRO_SUCCESS;
				for (uint32 i = 0; i< info.size(); i++)
					msg<<info[i].award;

				int curTime = GetSysTime();
				msg<<bangSize;
				for (uint8 i = 0; i < bangSize; i++)
				{
					vector<HdShowHistoryNode> history;
					pUser->InitHDShowHIstory(hd_main_type);
					pUser->GetHDShowHIstory(i, history,hd_main_type);
					
					msg<<i<<(uint8)history.size();
					for (uint32 j = (history.size()); j > 0; j--)
					{
						int time = curTime - (int)history[j-1].time;
						if(time < 0)
							time = 0;
						msg<<time<<history[j-1].data;
					}
				}
			}
			else if (op1 == 5)
			{
				uint32 roleId = 0;
				uint8 size = 2;
				string name;
				vector<Goods> goods;
				uint8 op_type = 0xff;
				
				msg>>op_type;		
				if (op_type > 1)
				{
					msg.ReWrite();
					msg.SetType(MSG_TMP_HUODONG);
					msg<<(uint8)op<<(uint8)op1;
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1616,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				if (op_type == 0)
					msg>>roleId;
				else if (op_type == 1)
					msg>>name;
				for (uint32 i = 0; i < size; i++)
				{
					Goods g;
					msg>>g.id;
					msg>>g.num;
					goods.push_back(g);
				}
				
				msg.ReWrite();
				msg.SetType(MSG_TMP_HUODONG);
				msg<<(uint8)op<<(uint8)op1;

				uint32 myZhenYingId = pUser->GetExtData32(myZhenYingDataId);
				if (myZhenYingId != hd_pk1_type && myZhenYingId != hd_pk2_type)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0203,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				
				CGetDbConnect getDb;
				CDatabaseSql *pDb = getDb.GetDbConnect();
				if(pDb == NULL)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0011,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}
				
				if (op_type == 1)
				{
					roleId = GetRoleIdByName(name);
					if (roleId == 0)
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1618,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						return;
					}
				}

				if (goods[0].num == 0 && goods[1].num == 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0205,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				char sql[256];
				ShareUserPtr p = SingletonOnlineUser::instance().GetUserByRoleId(roleId);
				CUser *pUserGet = p.get();
				uint32 pUserZhenYing = 0;
				if(pUserGet == NULL)
				{
					pUserGet = new CUser;
					if(pUserGet == NULL)
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_244,TIPS_FAILURE_COLOR);
						return;
					}

					snprintf(sql,sizeof(sql)-1,"select kuafu_state,bank_item from role_info where id = %d",roleId);
					char **row = NULL;
					if(pDb->Query(sql) && (row = pDb->GetRow()) != NULL)
					{
						if (atoi(row[0]) == 1)
						{
							msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0057,TIPS_FAILURE_COLOR);
							m_socketServer.SendMsg(sock,msg);
							return;
						}

						pUserGet->SetBankItem(row[1]);
						pUserZhenYing = pUserGet->GetExtData32(myZhenYingDataId);
						delete pUserGet;
						pUserGet = NULL;
					}
					else
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0011,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(sock,msg);
						return;
					}
				}
				else
				{
					pUserZhenYing = pUserGet->GetExtData32(myZhenYingDataId);
				}

				if (pUserZhenYing != myZhenYingId)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0206,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}

				vector<GoodsInfo> info;
				awardManager.GetHDBangGoods(myZhenYingId, info, hd_main_type);
				if (info.size() != 2)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1615,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				for (uint32 i = 0; i < info.size(); i++)
				{
					bool isFind = false;
					for (uint32 j = 0; j < goods.size(); j++)
					{
						if ((uint32)goods[j].id == info[i].award)
						{
							if ((uint32)pUser->GetItemNum(goods[j].id) < goods[j].num)
							{
								msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1620,TIPS_FAILURE_COLOR);
								m_socketServer.SendMsg(pUser->GetSock(),msg);
								return;
							}
				
							info[i].num = goods[j].num;
							isFind = true;
							break;
						}
					}

					if (! isFind)
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1621,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						return;
					}
				}

				HDGivePresent(pUser,roleId,info,msg,hd_main_type);
			}
			else if (op1 == 6)
			{
				msg<<PRO_SUCCESS;
/*
				list<uint32> idList;
				for(list<HotInfo>::iterator i = hotList.begin(); i != hotList.end(); i++)
				{
					idList.push_back(i->hotId);
				}
				
				uint32 myZhenYingId = pUser->GetExtData32(myZhenYingDataId);
				GetZhenYingPKList(idList,myZhenYingId,msg);
*/
			}
			else if (op1 == 7)
			{
				uint32 myZhenYingId = pUser->GetExtData32(myZhenYingDataId);
				CBangPai *pBangPai = m_bangPaiMgr.FindBangPai(pUser->GetBangPai());
				if(pBangPai == NULL)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0213,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				msg<<PRO_SUCCESS;
				list<uint32> idList;
				pBangPai->GetMember(idList);
				
				GetZhenYingPKList(idList, myZhenYingId,msg);
			}
		
			m_socketServer.SendMsg(pUser->GetSock(),msg);
		}
		break;
	case HD_QIANG_HONGBAO:
		{
			uint32 hd_type = CHuoDongAwardManager::QIANG_HONGBAO;
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
			uint32 leijiDataId = 406;
			uint32 isSendHongBaoBitId = 583;
			char buff[512];

			uint8 op1 = 0;
			msg>>op1;

			if (op1 != 5 && !awardManager.InHuoDongTime(hd_type))
				return;

			vector<HDPeiZhiInfo> info;
			awardManager.GetPeiZhiInfo(info,hd_type);
			if (info.size() != 1)
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1511,TIPS_FAILURE_COLOR);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				return;
			}

			if (op1 == 1)  // 红包说明界面
			{

				uint32 myMoney = pUser->GetExtData32(leijiDataId);
				uint32 needMoney = info[0].price;

				HDHongBaoGetRecord record;
				awardManager.GetHDHongBaoRecord(pUser->GetRoleId(),record);

				snprintf(buff,sizeof(buff),LANGUAGE_LLD_0244,info[0].cd/60);
				msg<<PRO_SUCCESS<<buff<<myMoney<<needMoney<<record.sendHBCount<<record.renQiKingCount;

				snprintf(buff,sizeof(buff),LANGUAGE_LLD_0217,awardManager.GetHuoDongTimeDesc(hd_type).c_str(),info[0].price,info[0].cd/60);
				msg<<buff;

				if (pUser->HaveBitSet(isSendHongBaoBitId))
					msg << 2;
				else
				{
					if (myMoney >= needMoney)
						msg << 1;
					else
						msg << 0;
				}
			}
			else if (op1 == 2) //发红包
			{
				uint32 myMoney = pUser->GetExtData32(leijiDataId);
				uint32 needMoney = info[0].price;
		
				if (pUser->HaveBitSet(isSendHongBaoBitId))
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0218,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				} else if (myMoney < needMoney)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0219,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				uint32 sendHBCount = awardManager.FaBuHongBao(pUser,info[0]);
				if (sendHBCount > 0)
				{
					pUser->SetBitSet(isSendHongBaoBitId);
					msg<<PRO_SUCCESS<<2<<sendHBCount; // 状态已经领取

					snprintf(buff,sizeof(buff),LANGUAGE_LLD_0221,pUser->GetName());
//					SysInfoToAllUserGunDong(pUser,buff);
					SaveDate(pUser->GetRoleId(),hd_type+500,0,buff);

					QiangHongBaoZhuDong(CHuoDongAwardManager::QIANGHB_HONGDIAN);
					NoticeHuoDongHotPoint(pUser,hd_type);
				}
				else
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0220,TIPS_FAILURE_COLOR);
				}
			}
			else if (op1 == 3) //红包列表
			{
				vector<HDHongBaoInfo> infos;
				awardManager.GetHongBaoList(infos);
				msg<<PRO_SUCCESS<<(uint32)infos.size();
				for (uint32 i = 0; i < infos.size(); i++)
				{
					msg<<infos[i].send_player_info.role_id;
					msg<<infos[i].send_player_info.role_name;
					msg<<infos[i].send_player_info.sex;
					msg<<infos[i].send_player_info.xiang;
					msg<<infos[i].send_player_info.end_time;

					bool isGet = false;
					vector<HDHongBaoPlayerInfo> &get_player_infos = infos[i].get_player_infos;
					uint32 myRoleId = pUser->GetRoleId();
					for (uint32 j = 0; j < get_player_infos.size(); j++)
					{
						if (get_player_infos[j].role_id == myRoleId)
						{
							isGet = true;
							break;
						}
					}

					if (isGet)
					{
						msg<<(uint8)1; //已领取
					}
					else if (get_player_infos.size() >= info[0].count)
					{
						msg<<(uint8)2;//已领完
					}
					else
					{
						msg<<(uint8)0; //可以领取
					}
				}
			}
			else if (op1 == 4) //点击红包
			{
				uint32 role_id = 0;
				msg>>role_id;

				if (role_id == 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1616,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				awardManager.ClickHongBao(info[0],role_id,pUser,msg);
			}
			else if (op1 == 5)
			{
				if (awardManager.InHuoDongTime(hd_type))
				{
					QiangHongBaoZhuDong(CHuoDongAwardManager::QIANGHB_UP,pUser);
					return;
				}
				else
					msg<<PRO_ERROR;
			}

			m_socketServer.SendMsg(pUser->GetSock(),msg);
		}
		break;
	case HD_HUOYUE_TASK:
		{
			uint32 hd_type = CHuoDongAwardManager::HUOYUE_TASK;
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();

			uint8 op1 = 0;
			msg>>op1;
			if (op1 == 1)
			{
				CCallScript *pScript = GetScript235();
				if(pScript != NULL)
				{
					pUser->SetCallScript(pScript->GetScriptId());
					pScript->Call("ShowTask","u",pUser);
				}
				return;
			}
			else if (op1 == 2) // 活跃任务点击
			{
				uint8 id = 0xff;
				msg>>id;
				if (id >= HUOYUE_MAX_TASK)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_80,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				if (GetHuoYueTaskState(pUser->GetExtData32(HUOYUE_TASK_DATA_ID[id])) > 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0248,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				vector<HuoYueTaskInfo> taskInfos;
				pUser->GetHuoYueTaskList(taskInfos);
				if (id >= taskInfos.size())
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0249,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				if (taskInfos[id].taskCount < taskInfos[id].taskNeedCount)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0250,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				uint32 idx = awardManager.GetAwardIdx(hd_type,CHuoDongAwardManager::HUOYUE_TASK_COMPLETE_IDX2,taskInfos[id].level);
				SHuoDongAward award;
				awardManager.GetAwardData(hd_type,idx,award);
				for(uint8 i=0;i < CHuoDongAwardManager::SHOUCHONG_AWARD_NUM && i < SHuoDongAward::AWARD_NUM;i++)
					AddHuoDongAward(pUser,hd_type,award.award[i],award.num[i],award.petQuality[i],award.petQualityLv[i],true);

				uint32 data = UpdateHuoYueTaskState(pUser->GetExtData32(HUOYUE_TASK_DATA_ID[id]));
				pUser->SetExtData32(HUOYUE_TASK_DATA_ID[id], data);

				msg<<PRO_SUCCESS<<GetHuoYueTaskState(data)<<GetHuoYueTaskCompleteCount(pUser);
			}
			else if (op1 == 3) // 宝箱点击
			{
				uint32 needCount = 0;
				msg>>needCount;
				if (needCount == 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_80,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				vector<uint32> idxList;
				awardManager.GetAwardIdxList(hd_type,CHuoDongAwardManager::HUOYUE_TASK_BOX_IDX2,idxList);
				if (idxList.size() == 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0246,TIPS_FAILURE_COLOR);
					SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
					return;
				}
			
				uint32 getMask = pUser->GetExtData32(420);
				for (uint32 i = 0; i < idxList.size(); i++)
				{
					SHuoDongAward award;
					awardManager.GetAwardData(hd_type,idxList[i],award);

					if (award.needYB == needCount)
					{
						uint8 isGet = ((getMask&(1<<award.needYB)) == 0) ? (uint8)0 : (uint8)1;
						if (isGet == 1)
						{
							msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0251,TIPS_FAILURE_COLOR);
							SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
							return;
						}

						if (GetHuoYueTaskCompleteCount(pUser) < needCount)
						{
							msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0252,TIPS_FAILURE_COLOR);
							SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
							return;
						}

						for(uint8 i=0;i < CHuoDongAwardManager::SHOUCHONG_AWARD_NUM && i < SHuoDongAward::AWARD_NUM;i++)
							AddHuoDongAward(pUser,hd_type,award.award[i],award.num[i],award.petQuality[i],award.petQualityLv[i],true);

						getMask |= 1 << award.needYB;
						pUser->SetExtData32(420,getMask);
						isGet = ((getMask&(1<<award.needYB)) == 0) ? (uint8)0 : (uint8)1;
						msg<<PRO_SUCCESS<<isGet;
						SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
						return;
					}
					
				}
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0253,TIPS_FAILURE_COLOR);
			}
			else if (op1 == 4) // 兑换
			{
				uint32 id = 0;
				msg>>id;
		
				HDExchangeInfo info;
				awardManager.GetExchangeInfo(hd_type,id,info);
				if( info.idx !=0 && info.material[0] !=0 && info.award[0] !=0 )
				{
					//扣除需求材料，默认只扣一种
					if((uint32)pUser->GetItemNum(info.material[0]) >= info.material_num[0])
					{
						pUser->DelPackageById(info.material[0],info.material_num[0]);
					}
					else
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0253,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						return;
					}
					//发道具，默认只发一种
					AddHuoDongAward(pUser,hd_type,info.award[0],info.num[0],info.petQuality[0],info.petQualityLv[0],true);	
					msg<<PRO_SUCCESS;
				}

			}
			else if (op1 == 5) //跳过
			{
				uint8 id = 0xff;
				msg>>id;
				if (id >= HUOYUE_MAX_TASK)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_80,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}

				if (pUser->GetTongBao() < HUOYUE_TASK_FLUSH_YB)
				{
					msg<<PRO_ERROR<<"";
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					ShowJumpNotice(pUser,JUMP_NOTICE_YB);
					return;
				}

				pUser->CreateHuoYueTaskById(id);
				pUser->AddTongBao(-HUOYUE_TASK_FLUSH_YB);
				msg<<PRO_SUCCESS;

				ItemCurrencyLog(pUser->GetRoleId(),0,1,0,HUOYUE_TASK_FLUSH_YB,pUser->GetYaoShi(),YBL_HUOYUE_PASS);
			}
			
			m_socketServer.SendMsg(pUser->GetSock(),msg);
		}
		break;
	case HD_MEIRI_XIAOHAO1:
	case HD_MEIRI_XIAOHAO2:
	case HD_MEIRI_XIAOHAO3:
	case HD_MEIRI_XIAOHAO4:
	case HD_MEIRI_XIAOHAO5:
		{
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
			uint8 op1=0;	// 0获取列表信息，1领取奖励
			msg>>op1;

			uint32 type = 0;
			uint32 totalXFDataId = 0;
			uint32 maskDataId = 0;
			switch (op)
			{
				case HD_MEIRI_XIAOHAO1:
					type = CHuoDongAwardManager::MEIRI_XIAOFEI1;
					break;
				case HD_MEIRI_XIAOHAO2:
					type = CHuoDongAwardManager::MEIRI_XIAOFEI2;
					break;
				case HD_MEIRI_XIAOHAO3:
					type = CHuoDongAwardManager::MEIRI_XIAOFEI3;
					break;
				case HD_MEIRI_XIAOHAO4:
					type = CHuoDongAwardManager::MEIRI_XIAOFEI4;
					break;
				case HD_MEIRI_XIAOHAO5:
					type = CHuoDongAwardManager::MEIRI_XIAOFEI5;
					break;
				default:
					return;
			}
			if (!GetMeiRiXiaoFeiYBDataId(type,totalXFDataId,maskDataId))
				return;
			if(!awardManager.InHuoDongTime(type))
				return;

			if(op1 == 0)	// 获取列表
			{
				vector<uint32> idxList;
				awardManager.GetAwardIdxList(type,idxList);
				if(idxList.empty())
					return;
				uint32 totalXF = pUser->GetExtData32(totalXFDataId);
				uint32 getMask = pUser->GetExtData32(maskDataId);
				uint8 num = idxList.size();
				if(num > 32)
					num = 32;
				msg<<totalXF<<awardManager.GetHuoDongTimeDesc(type)<<num;
				for(uint8 i=0;i < num;i++)
				{
					SHuoDongAward award;
					uint8 isGet = ((getMask&(1<<i)) == 0) ? (uint8)0 : (uint8)1;
					uint32 needYB = awardManager.GetNeedYB(type,idxList[i]);
					awardManager.GetAwardData(type,idxList[i],award);
					msg<<i<<needYB<<isGet;
					uint16 pos = msg.GetDataLen();
					uint8 typeNum = 0;
					msg<<typeNum;
					typeNum = MakeAwardMsg(pUser, award, type, msg);
					msg.WriteData(pos,&typeNum,sizeof(typeNum));
				}
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			else if(op1 == 1)	// 领取奖励
			{
				uint8 index = 0xff; // 领奖
				msg>>index;
			
				if(index > 31)	// 32位标识
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1587,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
	
				uint32 getMask = pUser->GetExtData32(maskDataId);
				if((getMask & (1<<index)) == 0) 	// 未领取
				{
					vector<uint32> idxList;
					awardManager.GetAwardIdxList(type,idxList);
					if((uint8)(index+1) > idxList.size())
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1588,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						return;
					}
					uint32 totalXF = pUser->GetExtData32(totalXFDataId);
					uint32 needYB = awardManager.GetNeedYB(type,idxList[index]);
					if(totalXF < needYB)
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1589,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						return;
					}
	
					SHuoDongAward award;
					awardManager.GetAwardData(type,idxList[index],award);
					for(uint8 i=0;i < SHuoDongAward::AWARD_NUM;i++)
						AddHuoDongAward(pUser,type,award.award[i],award.num[i],award.petQuality[i],award.petQualityLv[i]);
					getMask |= (1<<index);
					pUser->SetExtData32(maskDataId,getMask);
					msg<<PRO_SUCCESS;
					m_socketServer.SendMsg(pUser->GetSock(),msg);

					NoticeHuoDongHotPoint(pUser, type);
				}
				else
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1590,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
			}
		}
		break;
	case HD_MOGU:
		{
			uint8 op1 = 0;
			msg>>op1;
			char buf[256];
			uint32 hd_type = CHuoDongAwardManager::MOGU;
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
			if(op1 == 1)	// 获取活动信息
			{
				if(!awardManager.InHuoDongTime(hd_type))
					return;
				int waterDay = awardManager.GetMoGuWaterDay();
				int awardDay = awardManager.GetMoGuAwardDay();
				int curDayIdx = GetMoGuCurrentDayIdx(awardManager.GetHuoDongStartTime(hd_type));
				uint8 getAward = 0;	// 0 不可领取 1 可领取
				int waterTimes = pUser->GetMoGuWaterTimes();
				int bugTimes = pUser->GetMoGuBugTimes();
				if(curDayIdx > waterDay)
				{
					waterTimes = 0;
					bugTimes = 0;
					if(!pUser->HaveBitSet(602))
						getAward = 1;
				}
				msg<<waterDay<<awardDay<<curDayIdx<<pUser->GetMoGuCZ()<<awardManager.GetMoGuStep1CZ()<<awardManager.GetMoGuStep2CZ();
				msg<<getAward<<waterTimes<<bugTimes<<(uint8)(pUser->HaveBitSet(601) ? 1 : 0);

				vector<uint32> idxList0;
				vector<uint32> idxList1;
				awardManager.GetAwardIdxList(hd_type,0,idxList0);
				awardManager.GetAwardIdxList(hd_type,1,idxList1);
				if(idxList0.empty() || idxList1.empty())
					return;

				int size = idxList0.size();
				msg<<(uint16)awardDay;
				for(int i=0;i < awardDay;i++)
				{
					int idx = i;
					if(idx > size-1)
						idx = size-1;
					SHuoDongAward award;
					awardManager.GetAwardData(hd_type,idxList0[idx],award);
					uint16 pos = msg.GetDataLen();
					uint8 typeNum = 0;
					msg<<typeNum;
					typeNum = MakeAwardMsg(pUser,award,hd_type,msg);
					msg.WriteData(pos,&typeNum,sizeof(typeNum));
				}

				size = idxList1.size();
				msg<<(uint16)awardDay;
				for(int i=0;i < awardDay;i++)
				{
					int idx = i;
					if(idx > size-1)
						idx = size-1;
					SHuoDongAward award;
					awardManager.GetAwardData(hd_type,idxList1[idx],award);
					uint16 pos = msg.GetDataLen();
					uint8 typeNum = 0;
					msg<<typeNum;
					typeNum = MakeAwardMsg(pUser,award,hd_type,msg);
					msg.WriteData(pos,&typeNum,sizeof(typeNum));
				}
				m_socketServer.SendMsg(sock,msg);
			}
			else if(op1 == 2)	// 浇水
			{
				if(!awardManager.InHuoDongTime(hd_type))
					return;
				int waterDay = awardManager.GetMoGuWaterDay();
				int curDayIdx = GetMoGuCurrentDayIdx(awardManager.GetHuoDongStartTime(hd_type));
				int waterTimes = pUser->GetMoGuWaterTimes();
				if(curDayIdx > waterDay)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0258,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}
				if(waterTimes == 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0259,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}
				int waterCZ = awardManager.GetMoGuWaterCZ();
				int moguCZ = pUser->GetMoGuCZ() + waterCZ;
				pUser->SetMoGuCZ(moguCZ);
				pUser->DelMoGuWaterTimes();
				msg<<PRO_SUCCESS<<pUser->GetMoGuWaterTimes()<<moguCZ<<MakeStringColor(LANGUAGE_SSJ_0260,TIPS_WARNING_COLOR);
				m_socketServer.SendMsg(sock,msg);
				snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0267,waterCZ);
				SendSysInfo(pUser,MakeStringColor(buf,TIPS_SUCCESS_COLOR).c_str());

				SaveDate(pUser,715,waterCZ,LANGUAGE_SSJ_0268);
			}
			else if(op1 == 3)	// 除虫
			{
				if(!awardManager.InHuoDongTime(hd_type))
					return;
				int waterDay = awardManager.GetMoGuWaterDay();
				int curDayIdx = GetMoGuCurrentDayIdx(awardManager.GetHuoDongStartTime(hd_type));
				int bugTimes = pUser->GetMoGuBugTimes();
				if(curDayIdx > waterDay)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0261,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}
				if(bugTimes == 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0262,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}
				int bugCZ = awardManager.GetMoGuBugCZ();
				int moguCZ = pUser->GetMoGuCZ() + bugCZ;
				pUser->SetMoGuCZ(moguCZ);
				pUser->DelMoGuBugTimes();
				msg<<PRO_SUCCESS<<pUser->GetMoGuBugTimes()<<moguCZ<<MakeStringColor(LANGUAGE_SSJ_0263,TIPS_WARNING_COLOR);
				m_socketServer.SendMsg(sock,msg);
				snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0267,bugCZ);
				SendSysInfo(pUser,MakeStringColor(buf,TIPS_SUCCESS_COLOR).c_str());
				
				SaveDate(pUser,716,bugCZ,LANGUAGE_SSJ_0269);
			}
			else if(op1 == 4)	// 领奖
			{
				if(!awardManager.InHuoDongTime(hd_type))
					return;
				int waterDay = awardManager.GetMoGuWaterDay();
				int curDayIdx = GetMoGuCurrentDayIdx(awardManager.GetHuoDongStartTime(hd_type));
				if(curDayIdx <= waterDay)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0264,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}
				if(pUser->HaveBitSet(602))
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0265,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}
				int moguCZ = pUser->GetMoGuCZ();
				int step1CZ = awardManager.GetMoGuStep1CZ();
				int step2CZ = awardManager.GetMoGuStep2CZ();
				vector<uint32> idxList;
				if(moguCZ < step1CZ)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0266,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}
				else if(moguCZ >= step1CZ && moguCZ < step2CZ)
				{
					awardManager.GetAwardIdxList(hd_type,0,idxList);
				}
				else if(moguCZ >= step2CZ)
				{
					awardManager.GetAwardIdxList(hd_type,1,idxList);
				}
				if(idxList.empty())
					return;

				int awardIdx = curDayIdx-waterDay-1;
				if(awardIdx > (int)idxList.size()-1)
					awardIdx = (int)idxList.size()-1;
				SHuoDongAward award;
				awardManager.GetAwardData(hd_type,idxList[awardIdx],award);
				for(uint8 i=0;i < SHuoDongAward::AWARD_NUM;i++)
					AddHuoDongAward(pUser,hd_type,award.award[i],award.num[i],award.petQuality[i],award.petQualityLv[i]);
				pUser->SetBitSet(602);

				msg<<PRO_SUCCESS;
				m_socketServer.SendMsg(sock,msg);
			}
			NoticeHuoDongHotPoint(pUser,hd_type);
		}
		break;

	//add by zhudaolong 2017.11.01
	case HD_TAOHUAGENG:
		{
			uint8 op1 = 0;
			const uint8 num_material_make = 4;
			msg>>op1;
			uint32 hd_type = CHuoDongAwardManager::TAOHUAGENG;
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();

			if(!awardManager.InHuoDongTime(hd_type))
				return;
			if(op1 == 1)	//进入活动界面
			{
				pUser->InitTHGHistory();

				map<uint32,uint32> temp_materialinfo;
				awardManager.GetMaterialInfo(temp_materialinfo);
				uint32 num_kinds_material = temp_materialinfo.size();
				msg<<num_kinds_material;

				map<uint32,uint32>::iterator iter = temp_materialinfo.begin();
				for(;iter != temp_materialinfo.end();iter++)
				{
					uint32 material_id = 0;
					uint32 material_num = 0;
					uint32 material_per_num = 0;
					material_id = iter->first;
					material_per_num = iter->second;
					material_num = pUser->GetItemNum(material_id);

					msg<<material_id<<material_num<<material_per_num;
				}
				m_socketServer.SendMsg(sock,msg);
			}
			else if(op1 == 2)	//开始制作
			{
				map<uint32,uint32> temp_materialinfo;
				awardManager.GetMaterialInfo(temp_materialinfo);
				uint32 num_kinds_material = temp_materialinfo.size();
				
				//获得当前菜品顺序
				uint32  current_material[num_material_make];
				uint32  current_material_num[num_material_make];
				for(uint8 i = 0; i< num_material_make; i++)
				{
					msg>>current_material[i];
					msg>>current_material_num[i];
					
					map<uint32,uint32>::iterator iter = temp_materialinfo.find(current_material[i]);
					if(iter == temp_materialinfo.end())
					{
						msg.ReWrite();
						msg.SetType(MSG_TMP_HUODONG);
						msg<<op<<op1;
						msg<<num_kinds_material;

						map<uint32,uint32>::iterator iter = temp_materialinfo.begin();
						for(;iter != temp_materialinfo.end();iter++)
						{
							uint32 material_id = 0;
							uint32 material_num = 0;
							uint32 material_per_num = 0;
							material_id = iter->first;
							material_per_num = iter->second;
							material_num = pUser->GetItemNum(material_id);
							msg<<material_id<<material_num<<material_per_num;
						}
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_ZDL_0821,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(pUser->GetSock(),msg);
						return;
					}
				}
				
				//先检测用户是否有足够的材料数
				//如果足够删除用户对应的材料
				uint32 check = 0;
				for(;check< num_material_make; check++)
				{
					if(pUser->GetItemNum((int)current_material[check]) < (int)current_material_num[check])
						break;
				}
				if(check == num_material_make)
				{
					for(uint32 del = 0; del < num_material_make; del++)
						pUser->DelPackageById((int)current_material[del],(int)current_material_num[del]);
				}
				else
				{
					msg.ReWrite();
					msg.SetType(MSG_TMP_HUODONG);
					msg<<op<<op1;
					msg<<num_kinds_material;

					map<uint32,uint32>::iterator iter = temp_materialinfo.begin();
					for(;iter != temp_materialinfo.end();iter++)
					{
						uint32 material_id = 0;
						uint32 material_num = 0;
						uint32 material_per_num = 0;
						material_id = iter->first;
						material_per_num = iter->second;
						material_num = pUser->GetItemNum(material_id);
						msg<<material_id<<material_num<<material_per_num;
					}
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_ZDL_0822,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				
				//获得正确的菜品顺序集
				std::vector<HDExchangeInfo> correct_material;
				correct_material.clear();
				awardManager.GetExchangeInfo(hd_type,correct_material);
				
				//比较当前菜品和菜品数据集中的某一个是否一样
				uint8 isSuccess = PRO_ERROR;
				uint32 award,award_num;
				std::vector<HDExchangeInfo>::iterator iter_cor = correct_material.begin();
				for(; iter_cor != correct_material.end(); iter_cor++)
				{
					uint32 i = 0;
					for(; i < num_material_make; i++)
					{
						if(iter_cor->material[i] != current_material[i] || iter_cor->material_num[i] != current_material_num[i])
						{
							break;
						}
					}
					award = iter_cor->award[1];
					award_num = iter_cor->num[1];
					if(i == num_material_make)
					{
						isSuccess = PRO_SUCCESS;
						award = iter_cor->award[0];
						award_num = iter_cor->num[0];
						break;
					}
				}
				AddHuoDongAward(pUser,hd_type,award,award_num,0,0,false);

				//保存合成历史
				pUser->AddTHGHistory(award, award_num);
				
				msg.ReWrite();
				msg.SetType(MSG_TMP_HUODONG);
				msg<<op<<op1;
				msg<<num_kinds_material;

				map<uint32,uint32>::iterator iter = temp_materialinfo.begin();
				for(;iter != temp_materialinfo.end();iter++)
				{
					uint32 material_id = 0;
					uint32 material_num = 0;
					uint32 material_per_num = 0;
					material_id = iter->first;
					material_per_num = iter->second;
					material_num = pUser->GetItemNum(material_id);
					msg<<material_id<<material_num<<material_per_num;
				}
				msg<<PRO_SUCCESS<<isSuccess;
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			else if(op1 == 3)	//制作记录
			{
				vector<HdShowHistoryNode> history;
				pUser->GetTHGHistory(history);
				
				msg<<(uint32)history.size();
				vector<HdShowHistoryNode>::iterator iter_h;
				uint32 curTime = GetSysTime();
				for(iter_h = history.begin(); iter_h != history.end(); iter_h++)
				{
					uint32 time = 0;
					if(curTime > iter_h->time)
						time = curTime - iter_h->time;
					msg<<time<<iter_h->data;
				}
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
		}
		break;
	case HD_ROLE_INFO:
		{
			uint32 roleId = 0;
			msg>>roleId;
			MakeTitleRoleData(roleId,msg);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
		}
		break;
	case HD_ALL_LIST:
		{
			MakeHuoDongList(msg, pUser);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		break;
	case HD_MEILI_HUODONG:
		{
			SingletonShopManager::instance().ShowMeiLiPaiHang(pUser, msg);
			m_socketServer.SendMsg(pUser->GetSock(), msg);
			return;
		}
	break;

	case HD_ZHEKOU_LIBAO1:
	case HD_ZHEKOU_LIBAO2:
	case HD_ZHEKOU_LIBAO3:
		{
			int type = CHuoDongAwardManager::ZHEKOU_HUODONG1 + op - HD_ZHEKOU_LIBAO1;
			DealZheKouHuoDong(msg, pUser, type);
		}
		break;

	case HD_ROUND_ZHEKOU_LIBAO1:
	case HD_ROUND_ZHEKOU_LIBAO2:
	case HD_ROUND_ZHEKOU_LIBAO3:
	{
		int type = CHuoDongAwardManager::ROUND_ZHEKOU_HUODONG1 + op - HD_ROUND_ZHEKOU_LIBAO1;
		DealXunHuanZheKouHuoDong(msg, pUser, type);
	}
	break;
		
	default:
		{
			break;
		}
	}
}

// 护送，押镖
void CPackageDeal::HuSongShenShouOption(CNetMessage *pMsg,int sock)
{
/*
	GET_MSG
	GET_USER
	const float qualityRatio[] = {0.3f,0.5f,0.7f,0.85f,1.0f};
	const char *qualityName[] = {LANGUAGE_TRANSFORM_1638,LANGUAGE_TRANSFORM_1639,LANGUAGE_TRANSFORM_1640,LANGUAGE_TRANSFORM_1641,LANGUAGE_TRANSFORM_1642};
	const int upRatio[] = {0,85,70,55,40};
	const int needMoneyPer = pUser->GetLevel()*10;
	uint8 op = 0;
	msg>>op;
	uint32 type;
	if (op > 8)
		type = SOT_Yabiao;
	else
		type = SOT_Husong;
	// CHECK_SYSTEM_OPEN(type)
	
	if (op == 1)	// 服务器主动发送接取任务信息
	{

	}
	else if(op == 2)	// 刷新任务品质
	{
		uint8 quality = 0;	// 0-4, 0刷一次, 1-4蓝\紫\橙\金
		msg>>quality;
		msg.ReWrite();
		msg.SetType(MSG_HU_SONG);
		msg<<op;
		if(!pUser->HaveCMission(MISSION_ID_HuSong))
		{
			CHuoDongExpManage &expManager = SingletonHuoDongExpManager::instance();
			char buf[128];
			uint8 curQuality = pUser->GetExtData8(78); // 品质
			if(quality == 0)	// 单次刷新
			{
				if(curQuality >= 4)
				{
					snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1643,qualityName[curQuality]);
					msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				if(pUser->GetMoney() >= needMoneyPer)
				{
					pUser->AddMoney(-needMoneyPer);
					if(Random(1,100) < upRatio[curQuality+1])
					{
						curQuality++;
						pUser->SetExtData8(78,curQuality);
						snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1644,qualityName[curQuality]);

						int64 levelUpExp = GetLevelUpExp(pUser->GetLevel());
						float ratio = expManager.GetExpRatio(17,pUser->GetLevel());
						int64 addExp = (int64)(0.2f*levelUpExp*ratio*qualityRatio[curQuality]);
						SaveDate(pUser, 28, 1);
						if(!CSceneManager::IsInActivityTime(SOT_Husong))
							addExp /= 2;
						msg<<PRO_SUCCESS<<MakeStringColor(buf,TIPS_WARNING_COLOR)<<curQuality<<(uint8)5<<(uint8)(5-pUser->GetExtData8(81))<<addExp<<needMoneyPer;
					}
					else
					{
						snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1645,qualityName[curQuality]);
						msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
					}
				}
				else
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1646,TIPS_FAILURE_COLOR);
				}
			}
			else	// 多次刷新
			{
				if(curQuality >= quality || curQuality >= 4)
				{
					snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1647,qualityName[curQuality]);
					msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				int count = 0;
				int totleMoney = pUser->GetMoney();
				if(totleMoney < needMoneyPer)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1648,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(),msg);
					return;
				}
				while(curQuality < quality)
				{
					if(totleMoney >= needMoneyPer*(count+1))
					{
						if(Random(1,100) < upRatio[curQuality+1])
							curQuality++;
						count++;
					}
					else
					{
						break;
					}
				}
				pUser->AddMoney(-count*needMoneyPer);
				pUser->SetExtData8(78,curQuality);
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1649,count*needMoneyPer,qualityName[curQuality]);
				int64 levelUpExp = GetLevelUpExp(pUser->GetLevel());
				float ratio = expManager.GetExpRatio(17,pUser->GetLevel());
				int64 addExp = (int64)(0.2f*levelUpExp*ratio*qualityRatio[curQuality]);
				SaveDate(pUser, 28, 1);
				if(!CSceneManager::IsInActivityTime(SOT_Husong))
					addExp /= 2;
				msg<<PRO_SUCCESS<<MakeStringColor(buf,TIPS_WARNING_COLOR)<<curQuality<<(uint8)5<<(uint8)(5-pUser->GetExtData8(81))<<addExp<<needMoneyPer;
			}
			m_socketServer.SendMsg(pUser->GetSock(),msg);
		}
		else
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1650,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
		}
	}
	else if(op == 3)	// 接护送神将任务
	{
		if(pUser->GetTeam() > 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1651,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(pUser->GetExtData8(81) >= 5)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1653,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(!pUser->HaveCMission(MISSION_ID_HuSong))
		{
			CHuoDongExpManage &expManager = SingletonHuoDongExpManager::instance();
			uint8 quality = pUser->GetExtData8(78);
			
			int64 addExp = expManager.GetHuoDongExp(17,pUser->GetLevel(),0.2*qualityRatio[quality]);
			if(!CSceneManager::IsInActivityTime(SOT_Husong))
				addExp /= 2;
			addExp = addExp - addExp%1000;

			char buf[256];
			//				quality|exp|loseExp|endTime|name
			snprintf(buf,sizeof(buf),"%d|%lld|%d|%u|%d",(int)quality, addExp, 0 , (uint32)(GetSysTime()+3600),1);
			bool ret = pUser->AcceptCMission(MISSION_ID_HuSong, (const char*)buf, qualityName[quality]);
			if(ret){
				// 下跟随神将，坐骑
				SetGenSuiPetDown(pUser);
				SetQiPetDown(pUser);
				UpdateNpcState(pUser,23,2);  // 更新任务npc状态
				pUser->SetBitSet(156);	// 不可组队，不可传送
				pUser->SetBitSet(157);	// 不可观看
				pUser->SetExtData8(78,0);	// 当前任务品质清0
				pUser->SetExtData8(80,0);	// 每次被抢次数清0
				//pUser->SetExtData8(81,pUser->GetExtData8(81)+1);	// 任务次数调整改为任务完成
				pUser->CheckMissionHuoYueDu();
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1654,qualityName[quality]);
				msg<<PRO_SUCCESS<<MakeStringColor(buf,TIPS_WARNING_COLOR)<<(uint16)1<<(uint16)74;

				UpdateUserInfo(pUser,ESRT_HuSong);
			}
			else
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1655,TIPS_FAILURE_COLOR);
			}
		}
		else
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1656,TIPS_FAILURE_COLOR);
		}
		m_socketServer.SendMsg(pUser->GetSock(),msg);
	}
	else if(op == 4)	// 获取已接任务信息
	{
		const char *pMission = GetCMissionInts(pUser, MISSION_ID_HuSong);
		if(pMission == NULL || strlen(pMission) == 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1657,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		char *split[5];
		string str = pMission;
		int num = SplitLine(split,5,(char*)str.c_str());
		if(num < 5)
		{
			cout<<LANGUAGE_TRANSFORM_1658<<endl;
			return;
		}

		//           任务品质       最大可接次数			当前可接次数			 		 经验    					sid		 npcId
		msg<<(uint8)atoi(split[0])<<(uint8)5<<(uint8)(5-pUser->GetExtData8(81))<<strtoll(split[1],NULL,10)<<(uint16)1<<(uint16)74;
		m_socketServer.SendMsg(pUser->GetSock(),msg);
	}
	else if(op == 5)	// 开始战斗
	{
		uint32 tarRoleId = 0;
		msg>>tarRoleId;

		ShareUserPtr tarPtr = m_onlineUser.GetUserByRoleId(tarRoleId);
		CUser *pUserTar = tarPtr.get();
		if(pUserTar == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1659,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(pUser->GetKuaFuState() != EKFS_IN_LOCAL)
			return;
		if(pUser->GetFightId() > 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1660,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
//		if(pUser->GetTeam() > 0)
//		{
//			msg<<PRO_ERROR<<MakeStringColor("组队状态下不能抢夺神将",TIPS_FAILURE_COLOR);
//			m_socketServer.SendMsg(pUser->GetSock(),msg);
//			return;
//		}
		if(pUser->GetTeam() > 0 && pUser->GetTeam() != pUser->GetRoleId())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1661,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(pUser->GetExtData8(79) >= 5)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1662,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		uint8 huSongType = pUser->InHuSongMission();
		if(huSongType == 1)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1663,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		else if(huSongType == 2)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1664,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(pUserTar->InHuSongMission() != 1)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1665,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}

		if (pUserTar->GetLevel() < 40 && pUser->GetLevel() >= 40)
		{
			msg << PRO_ERROR << "对方等级过低，不能进行抢夺";
			m_socketServer.SendMsg(pUser->GetSock(), msg);
			return;
		}
		if(pUserTar->GetExtData8(80) >= 1)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1666,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(pUserTar->GetKuaFuState() != EKFS_IN_LOCAL)
			return;
		if(pUserTar->GetFightId() > 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1667,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		if((time_t)(pUserTar->GetExtData32(101)+30) > GetSysTime())
		{
			int cd = pUserTar->GetExtData32(101) + 30 - (uint32)GetSysTime();
			char buf[256];
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1668,cd);
			msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(pUserTar->GetSceneId() != pUser->GetSceneId())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1669,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}

		int dx = (int)((int)pUserTar->GetX() - (int)pUser->GetX());
		int dy = (int)((int)pUserTar->GetY() - (int)pUser->GetY());
		if(dx*dx + dy*dy > 768*768)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1670,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}

		CScene *pScene = pUser->GetScene();
		if(pScene == NULL)
			return;
		pScene->HuSongFight(ptr,tarPtr);

		msg<<PRO_SUCCESS;
		m_socketServer.SendMsg(pUser->GetSock(),msg);
	}
	else if(op == 6)	// 传送至活动NPC
	{
		if(pUser->GetExtData8(81) >= 5)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1671,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(pUser->HaveCMission(105))
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1672,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(pUser->GetTeam() > 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1673,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		msg<<PRO_SUCCESS;
		m_socketServer.SendMsg(pUser->GetSock(),msg);

		TransportUser(pUser,11,2033,974,23);
	}
	else if(op == 7)	// 请求战斗信息
	{
		uint32 tarRoleId = 0;
		msg>>tarRoleId;

		if(pUser->GetTeam() > 0 && pUser->GetRoleId() != pUser->GetTeam())
			return;
		ShareUserPtr tarPtr = m_onlineUser.GetUserByRoleId(tarRoleId);
		CUser *pUserTar = tarPtr.get();
		if(pUserTar == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1674,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(pUserTar->InHuSongMission() != 1)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1675,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}

		uint32 curTime = GetSysTime();
		uint32 openTime = GetServerOpenTime();
		if((curTime > openTime && (curTime - openTime) > 24*3600))	// 不是第一天
		{
			if(pUserTar->GetLevel() <= 28)
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1676,TIPS_FAILURE_COLOR);	// 空字符串不显示
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				return;
			}
		}
		
		char buf[512];
		char *split[5];
		//	quality|exp|loseExp|endTime|name
		const char *pMission = GetCMissionInts(pUserTar, 105);
		if(pMission == NULL || strlen(pMission) == 0)
			return;
		string str = pMission;
		int num = SplitLine(split,5,(char*)str.c_str());
		if(num < 5)
		{
			cout<<LANGUAGE_TRANSFORM_1677<<endl;
			return;
		}
		int64 exp = strtoll(split[1],NULL,10);
		uint16 level = pUser->GetLevel();
		if(pUser->GetTeam() > 0)
			level = pUser->GetTeamLevel();
		exp = GetHuoDongRobExpRatio(exp*0.25,pUserTar->GetLevel(),level);

		if(pUserTar->GetBangPai() > 0)
		{
			CBangPaiManager &bPMgr = SingletonCBangPaiManager::instance();
			CBangPai *pBangPai = bPMgr.FindBangPai(pUserTar->GetBangPai());
			if(pBangPai != NULL)
			{
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1678,
					pUserTar->GetName(),pBangPai->GetName().c_str(),GGCT_BLUE,(int)pUserTar->GetLevel(),split[4],GGCT_GREEN,exp,(int)pUser->GetExtData8(79));
			}
			else
			{
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1679,
					pUserTar->GetName(),GGCT_BLUE,(int)pUserTar->GetLevel(),split[4],GGCT_GREEN,exp,(int)pUser->GetExtData8(79));
			}
		}
		else
		{
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1680,
				pUserTar->GetName(),GGCT_BLUE,(int)pUserTar->GetLevel(),split[4],GGCT_GREEN,exp,(int)pUser->GetExtData8(79));
		}
		msg<<PRO_SUCCESS<<buf;
		m_socketServer.SendMsg(pUser->GetSock(),msg);
	}
	else if(op == 8)	// 服务器主动发送下一个护送任务接取传送界面
	{

	}
	else if(op == 9)	// 押镖战斗
	{
		uint32 tarRoleId = 0;
		msg>>tarRoleId;

		ShareUserPtr tarPtr = m_onlineUser.GetUserByRoleId(tarRoleId);
		CUser *pUserTar = tarPtr.get();
		if(pUserTar == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1681,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(pUser->GetKuaFuState() != EKFS_IN_LOCAL)
			return;
		if(pUser->GetFightId() > 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1682,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
//		if(pUser->GetTeam() > 0)
//		{
//			msg<<PRO_ERROR<<MakeStringColor("组队状态下不能抢镖",TIPS_FAILURE_COLOR);
//			m_socketServer.SendMsg(pUser->GetSock(),msg);
//			return;
//		}
		if(pUser->GetTeam() > 0 && pUser->GetTeam() != pUser->GetRoleId())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1683,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(pUser->GetExtData8(90) >= 50)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1684,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		uint8 huSongType = pUser->InHuSongMission();
		if(huSongType == 1)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1685,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		else if(huSongType == 2)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1686,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}

		if(pUserTar->InHuSongMission() != 2)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1687,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}

		if(pUserTar->GetLevel() < 40 && pUser->GetLevel() >= 40)
		{
			msg<<PRO_ERROR<<"对方等级过低，不能进行抢镖";
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(pUserTar->GetExtData8(89) >= 1)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1688,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(pUserTar->GetKuaFuState() != EKFS_IN_LOCAL)
			return;
		if(pUserTar->GetFightId() > 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1689,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		if((time_t)(pUserTar->GetExtData32(101)+30) > GetSysTime())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1690,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(pUserTar->GetSceneId() != pUser->GetSceneId())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1691,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		CScene *pScene = pUser->GetScene();
		if(pScene == NULL)
			return;
		pScene->HuSongFight(ptr,tarPtr);
		msg<<PRO_SUCCESS;
		m_socketServer.SendMsg(pUser->GetSock(),msg);
	}
	else if(op == 10)	// 请求押镖信息
	{
		uint32 tarRoleId = 0;
		msg>>tarRoleId;

		if(pUser->GetTeam() > 0 && pUser->GetRoleId() != pUser->GetTeam())
			return;
		ShareUserPtr tarPtr = m_onlineUser.GetUserByRoleId(tarRoleId);
		CUser *pUserTar = tarPtr.get();
		if(pUserTar == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1693,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		
		uint32 curTime = GetSysTime();
		uint32 openTime = GetServerOpenTime();
		if((curTime > openTime && (curTime - openTime) > 24*3600))	// 不是第一天
		{
			if(pUserTar->GetLevel() <= 28)
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1695,TIPS_FAILURE_COLOR);	// 空字符串不显示
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				return;
			}
		}
		char buf[128];
//		const char *qualityName[] = {"白色","绿色","蓝色","紫色","橙色"};
		int64 exp = 0;
		int money = 0;
		uint16 level = pUser->GetLevel();
		if(pUser->GetTeam() > 0)
			level = pUser->GetTeamLevel();
		GetYaYunBiaoCheRobExp(pUserTar,level,exp,money);
		if(exp == 0)
			return;
		if(pUserTar->GetBangPai() > 0)
		{
			CBangPaiManager &bPMgr = SingletonCBangPaiManager::instance();
			CBangPai *pBangPai = bPMgr.FindBangPai(pUserTar->GetBangPai());
			if(pBangPai != NULL)
			{
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1696,
					pUserTar->GetName(),pBangPai->GetName().c_str(),GGCT_BLUE,(int)pUserTar->GetLevel(),GGCT_GREEN,exp,money,(int)pUser->GetExtData8(90));
			}
			else
			{
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1697,
					pUserTar->GetName(),GGCT_BLUE,(int)pUserTar->GetLevel(),GGCT_GREEN,exp,money,(int)pUser->GetExtData8(90));
			}
		}
		else
		{
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1698,
				pUserTar->GetName(),GGCT_BLUE,(int)pUserTar->GetLevel(),GGCT_GREEN,exp,money,(int)pUser->GetExtData8(90));
		}
		msg<<PRO_SUCCESS<<buf;
		m_socketServer.SendMsg(pUser->GetSock(),msg);
	}
	else if(op == 11)	// 押运镖车面板信息
	{
		// 服务器主动发送
	}
	else if(op == 12)	// 押镖完成面板
	{
		// 服务器主动发送
	}
	else if(op == 13)	// 传送至活动NPC
	{
		if(pUser->GetExtData8(88) >= 10)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1699,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(pUser->GetTeam() > 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1701,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		msg<<PRO_SUCCESS;
		m_socketServer.SendMsg(pUser->GetSock(),msg);

		TransportUser(pUser,11,1482,727,8);
	}
	else if(op == 14)	// 重上线客户端主动获取押镖信息
	{
		GetYaYunBiaoCheInfo(pUser,op);
	}
	else if(op == 15)
	{

	}
	else if(op == 16)
	{

	}
	else if(op == 17)
	{

	}
	else if(op == 18)	// 客户端请求
	{
		msg<<pUser->InHuSongMission()<<pUser->GetHuSongMissionQuality();
		m_socketServer.SendMsg(pUser->GetSock(),msg);
	}
*/
}

void CPackageDeal::DailyBossOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER
	// CHECK_SYSTEM_OPEN(SOT_DailyBoss)

	uint8 op = 0;
	msg>>op;
	if(op == 3)		// 3获取每日boss信息
	{
		CCallScript *pScript = GetScript30000();
		if(pScript != NULL)
		{
			int type = 1;	// 0积分任务1每日boss
			pScript->Call("GetRingMissionInfo","ui",pUser,type);
		}
	}
/*	else if(op == 4)	// 领取任务
	{
		uint8 type = 0;	// 0积分1跑环
		uint8 index = 0;
		msg>>type>>index;
		CCallScript *pScript = GetScript30000();
		if(pScript != NULL)
		{
			pUser->SetCallScript(pScript->GetScriptId());
			pScript->Call("AcceptMission","uii",pUser,type,index);
		}
	}
	else if(op == 5)	// 完成任务
	{
		uint8 type = 0;	// 0积分1跑环
		uint8 index = 0;
		msg>>type>>index;
		CCallScript *pScript = GetScript30000();
		if(pScript != NULL)
		{
			pUser->SetCallScript(pScript->GetScriptId());
			pScript->Call("FinishMission","uii",pUser,type,index);
		}
	}
*/
	else if(op == 7) // 挑战boss
	{
		uint8 index;
		msg>>index;
		if(index > 20)
			return;
		uint8 maxNum = pUser->GetCanDoRingBossNum() + pUser->GetBossBuyNum();
		if(pUser->GetBossTZNum() >= maxNum)
		{
			char buf[128];
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1703);
			SendSysInfo(pUser,MakeStringColor(buf,TIPS_FAILURE_COLOR).c_str());
			return;
		}
		if(pUser->GetFightId() > 0)
		{
			SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0481,TIPS_FAILURE_COLOR).c_str());
			return;
		}
		
		if(pUser->GetTeam() != 0)
		{
			SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_1704,TIPS_FAILURE_COLOR).c_str());
			return;
		}
		uint8 userMaxBossIdx = pUser->GetBossMissionTotolStarNum()/3 + 1;
		if(userMaxBossIdx > 0 && index < userMaxBossIdx-1)
		{
			SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_1705,TIPS_FAILURE_COLOR).c_str());
			return;
		}

		if(index > 1)
		{
			uint8 starNum = pUser->GetBossMissionStarNum(index-1);
			if(starNum < 3)	// 前个boss达到3星才可挑战
			{
				SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_1706,TIPS_FAILURE_COLOR).c_str());
				return;
			}
		}

		CScene *pScene = pUser->GetScene();
		if(pScene == NULL)
			return;
		pScene->DailyBossFight(ptr,index);
		pUser->SetExtData16(44,GetYDay());
		pUser->SetExtData32(104,(uint32)GetSysTime());
	}
	else if(op == 8 || op == 9)	// 每日Boss星级奖励
	{
		const int TYPE_ITEM = 1;
		const int TYPE_PET = 2;
		// type,itemId,num  神将放第一个,且不能一次给两只
		// type,petId,quality
		int AwardInfo[][5][3] = {
			{{TYPE_ITEM,2301,1},{0,0,0},{0,0,0},{0,0,0},{0,0,0}},
			{{TYPE_ITEM,2301,2},{0,0,0},{0,0,0},{0,0,0},{0,0,0}},
			{{TYPE_ITEM,2301,3},{0,0,0},{0,0,0},{0,0,0},{0,0,0}},
			{{TYPE_ITEM,2301,4},{0,0,0},{0,0,0},{0,0,0},{0,0,0}},
			{{TYPE_ITEM,2301,5},{0,0,0},{0,0,0},{0,0,0},{0,0,0}},
			{{TYPE_ITEM,2301,6},{0,0,0},{0,0,0},{0,0,0},{0,0,0}},
			{{TYPE_ITEM,2301,7},{0,0,0},{0,0,0},{0,0,0},{0,0,0}},
			{{TYPE_ITEM,2301,8},{0,0,0},{0,0,0},{0,0,0},{0,0,0}},
			{{TYPE_ITEM,2301,9},{0,0,0},{0,0,0},{0,0,0},{0,0,0}},
			{{TYPE_ITEM,2301,10},{0,0,0},{0,0,0},{0,0,0},{0,0,0}},
			{{TYPE_ITEM,2301,10},{0,0,0},{0,0,0},{0,0,0},{0,0,0}},
			{{TYPE_ITEM,2301,10},{0,0,0},{0,0,0},{0,0,0},{0,0,0}},
			{{TYPE_ITEM,2301,10},{0,0,0},{0,0,0},{0,0,0},{0,0,0}},
		};
		//	star,valueYB
		uint16 AwardStar[][2] = {{1,1000},{3,1000},{6,2000},{9,2000},{12,2000},{15,2500},{18,2500},{21,3750},{24,4050},{27,5000},{30,5400},
			{33,6250},{36,8100}};
		uint8 awardNum = sizeof(AwardStar)/sizeof(AwardStar[0]);

		if(op == 8)	// 每日Boss星级奖励信息
		{
			uint32 data = pUser->GetExtData32(103);
			msg<<(uint8)pUser->GetBossMissionTotolStarNum()<<awardNum;

			for(uint8 j=0; j < awardNum; j++)
			{
				msg<<(uint8)AwardStar[j][0]<<AwardStar[j][1]<<(uint8)((data&(1<<j)) == 0 ? 0 : 1);
				uint16 pos = msg.GetDataLen();
				uint8 count = 0;
				msg<<count;
				for(uint8 i=0; i < sizeof(AwardInfo[0])/sizeof(AwardInfo[0][0]); i++)
				{
					if(AwardInfo[j][i][0] == TYPE_ITEM)
					{
						msg<<(uint8)TYPE_ITEM<<(uint16)AwardInfo[j][i][1]<<(uint8)AwardInfo[j][i][2];
						count++;
					}
					else if(AwardInfo[j][i][0] == TYPE_PET)
					{
						msg<<(uint8)TYPE_PET;
						MakePetMsg(pUser,msg,AwardInfo[j][i][1]);
						count++;
					}
					else
					{
						break;
					}
				}
				msg.WriteData(pos,&count,1);
			}
			m_socketServer.SendMsg(sock,msg);
		}
		else	// 领取每日Boss星级奖励
		{
			uint8 index = 0xff;	// 0~awardNum-1
			msg>>index;
			if(index == 0xff || index > awardNum-1)
				return;
			uint32 data = pUser->GetExtData32(103);
			if((data & (1<<index)) == 0)	// 未领取
			{
				string res = "";
				char temp[64];
				uint8 petQuality = 0;
				uint8 curStarNum = pUser->GetBossMissionTotolStarNum();
				if(curStarNum < (uint8)AwardStar[index][0])	// 星级不足
					return;
				for(uint8 i=0; i < sizeof(AwardInfo[0])/sizeof(AwardInfo[0][0]); i++)
				{
					if(AwardInfo[index][i][0] == TYPE_ITEM)
					{
						snprintf(temp,sizeof(temp),"%s*%d",GetItemName(AwardInfo[index][i][1]),AwardInfo[index][i][2]);
						res += temp;
						pUser->AddBangDingPackage(AwardInfo[index][i][1],AwardInfo[index][i][2],"",LANGUAGE_TRANSFORM_1712);
					}
					else if(AwardInfo[index][i][0] == TYPE_PET)
					{
						::AddPet(pUser,AwardInfo[index][i][1],1);
						snprintf(temp,sizeof(temp),LANGUAGE_TRANSFORM_1715,QualityColorName[AwardInfo[index][i][2]].c_str(),GetPetName(AwardInfo[index][i][1]));
						res += temp;
						petQuality = AwardInfo[index][i][2];
					}
					else
					{
						break;
					}
				}

				char gonggao[512];
				msg<<PRO_SUCCESS;
				if(petQuality == 0)
				{
					snprintf(gonggao,sizeof(gonggao),LANGUAGE_TRANSFORM_1716,res.c_str());
					msg<<MakeStringColor(gonggao,TIPS_WARNING_COLOR);
				}
				else
				{
					msg<<"";
				}
				data |= (1<<index);
				pUser->SetExtData32(103,data);

				if(index == 1)	// 3星奖励
				{
					pUser->SetBitSet(337);
				}

				if(petQuality > 0)
					snprintf(gonggao,sizeof(gonggao),LANGUAGE_TRANSFORM_1717,ROLE_NAME_COLOR,pUser->GetName(),PetQualityColor[petQuality],res.c_str());
				else
					snprintf(gonggao,sizeof(gonggao),LANGUAGE_TRANSFORM_1718,ROLE_NAME_COLOR,pUser->GetName(),ITEM_NAME_COLOR,res.c_str());
				SysInfoToAllUser(gonggao);
			}
			else	// 已领取
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1719,TIPS_FAILURE_COLOR);
			}
			m_socketServer.SendMsg(sock,msg);
		}
	}
	else if(op == 10)	// 购买挑战次数
	{
		const uint16 useYB = 500;
		if(pUser->GetBossTZNum()<pUser->GetCanDoRingBossNum() + pUser->GetBossBuyNum())
		{
			msg<<PRO_ERROR<<(uint8)0<<MakeStringColor(LANGUAGE_TRANSFORM_1720,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		if(pUser->GetBossBuyNum() >= G_VipConfig[pUser->GetVipLevel()].bossbuy)
		{
			int nextlv=0;
			int buynum=G_VipConfig[pUser->GetVipLevel()].bossbuy;
			for(int i=pUser->GetVipLevel()+1;i<16;i++)
			{
				if(G_VipConfig[i].bossbuy>buynum)
				{
					nextlv=i;
					break;
				}
			}
			char buf[128];
			if(nextlv==0)
			{
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1721);
				msg<<PRO_ERROR<<(uint8)0<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
			}
			else
			{
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1722,TIPS_SUCCESS_COLOR,nextlv);
				msg<<PRO_ERROR<<(uint8)1<<buf;
			}
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		if(pUser->GetTongBao() < useYB)
		{
			msg<<PRO_ERROR<<"";
			m_socketServer.SendMsg(sock,msg);
			ShowJumpNotice(pUser,JUMP_NOTICE_YB);
			return;
		}
		pUser->AddTongBao(-useYB);
		pUser->IncBossBuyNum();
		msg<<PRO_SUCCESS<<(uint8)(pUser->GetCanDoRingBossNum() + pUser->GetBossBuyNum() - pUser->GetBossTZNum());
		ItemCurrencyLog(pUser->GetRoleId(),1,0,0,useYB,pUser->GetTongBao(),YBL_BUY_BOSS_NUM);
		m_socketServer.SendMsg(sock,msg);
	}
	else if(op == 11)	// 主动推送boss信息，用于主界面图标显示
	{

	}
}

void CPackageDeal::FengShenShiLianOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 op = 0;
	msg>>op;

	CFengShenMgr &mgr = SingletonCFengShenMgr::instance();
	if(op == 1)	// 获取boss列表
	{
		mgr.SendFengShenBossMsg(pUser);
	}
	else if(op == 2)	// 战斗
	{
		uint16 bossId = 0;
		msg>>bossId;

		SFengShenCfg *pCfg = mgr.GetFengShenBossCfg(bossId);
		if(pCfg == NULL)
			return;
		int weekDay = GetWeekDay();
		uint8 flag = 1 << weekDay;
		if((pCfg->open_weekDay & flag) == 0)
		{
			msg<<PRO_ERROR<<(uint8)0<<MakeStringColor(LANGUAGE_SSJ_0490, TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		uint8 haveDoNum = pUser->GetExtData8(478 + pCfg->index);
		int vip = pUser->GetVipLevel();
		if(haveDoNum >= CFengShenMgr::CAN_DO_NUM + G_VipConfig[vip].fengShenNum)
		{
			int nextVip=0;
			int curNum=G_VipConfig[vip].fengShenNum;
			for(int i=vip+1;i <= MAX_VIP_LEVEL;i++)
			{
				if(G_VipConfig[i].fengShenNum > curNum)
				{
					nextVip=i;
					break;
				}
			}
			
			if(vip == MAX_VIP_LEVEL || nextVip == 0)
			{
				msg<<PRO_ERROR<<(uint8)0<<MakeStringColor(LANGUAGE_SSJ_0491,TIPS_FAILURE_COLOR);
			}
			else
			{
				char buf[512];
				snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0500,TIPS_SUCCESS_COLOR,nextVip);
				msg<<PRO_ERROR<<(uint8)1<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
			}
			m_socketServer.SendMsg(sock,msg);
			return;
		}

		if(pUser->GetTeam() > 0)
		{
			msg<<PRO_ERROR<<(uint8)0<<MakeStringColor(LANGUAGE_SSJ_0492, TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}

		CScene *pScene = pUser->GetScene();
		if(pScene == NULL)
			return;
		pScene->FengShenFight(ptr,bossId,pCfg->fightId);
		msg<<PRO_SUCCESS;
		m_socketServer.SendMsg(sock,msg);
	}
	else if(op == 3)	// 获得收益列表
	{
		// 战斗结束主动推送
	}
}

void CPackageDeal::QueryGongGao(CNetMessage *pMsg,int sock)
{
	GET_USER

#ifdef KUA_FU
	return;
#endif

	static uint32 readtime = 0;
	static CNetMessage sendMsg;

	if(pUser->GetLevel() >= 2)
	{
		uint32 curTime = GetSysTime();
		if(curTime - readtime > 300)
		{
			char sql[256];
			char **row = NULL;
			CGetDbConnect getDb;
			CDatabaseSql *pDb = getDb.GetDbConnect();
			//									0	1		2		3
			snprintf(sql,sizeof(sql),"select title,msg,showType,jumpType from notice_login where beginTime<%u and endTime>%u order by id asc",curTime,curTime);
			if((pDb == NULL) || (!pDb->Query(sql)))
				return;
			readtime = curTime;

			uint8 num = (uint8)pDb->GetRowNum();
			sendMsg.ReWrite();
			sendMsg.SetType(PRO_GONGGAO);
			if(num == 0)
				return;
			sendMsg<<num;
			while((row = pDb->GetRow()) != NULL)
			{
				//		 title	  msg			showType			jumpType
				sendMsg<<row[0]<<row[1]<<(uint8)atoi(row[2])<<(uint8)atoi(row[3]);
			}
		}

		if(sendMsg.GetDataLen() <= 4)	// 无公告
			return;
		m_socketServer.SendMsg(sock,sendMsg);
//		gpMain->SendGongGao(sock);
	}
}

void CPackageDeal::GetChongZhiServerId(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	msg<<pUser->GetServerId();
	m_socketServer.SendMsg(sock,msg);
}

void CPackageDeal::SendUserGongGaoMsg(CNetMessage *pMsg,int sock)
{
	GET_USER

	string str;
	if(!pUser->PopGongGao(str))
		return;
	SysInfoToAllUser(str.c_str(),true);
}


void CPackageDeal::UpdateMoBaiData(uint8 showNum)
{
	CSceneManager &sceneMgr = SingletonSceneManager::instance();
	CScene *pScene = sceneMgr.FindScene(11);
	if (pScene == NULL)
		return;

	list<uint32> userList;
	pScene->GetUserList(userList);
	if(userList.empty())
		return;
	CNetMessage msg;
	MakeMoBaiData(showNum,msg);
	CSocketServer &sock = SingletonSocket::instance();
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	for(list<uint32>::iterator iter = userList.begin(); iter != userList.end(); iter++)
	{
		ShareUserPtr ptr = onlineUser.GetUserByRoleId(*iter);
		if(ptr.get() == NULL)
			continue;
		sock.SendMsg(ptr->GetSock(),msg);
	}
}

void CPackageDeal::ErrorProtocolDeal(uint16 protocol,int sock)
{
	const int MAX_ERROR_NUM = 3;
	uint32 roleId = 0;
	COnlineUser &online = SingletonOnlineUser::instance();
	ShareUserPtr user = online.GetUserBySock(sock);
	CUser *pUser = user.get();
	if(pUser != NULL)
	{
		roleId = pUser->GetRoleId();
		pUser->m_errProtocolNum++;
	}
	
	sockaddr_in addr;
	socklen_t len = sizeof(addr);
	getpeername(sock, (sockaddr*)&addr,&len);
	char *p = inet_ntoa(addr.sin_addr);
	string ip;
	if(p != NULL)
		ip = p;
	cout<<"["<<GetYear()+1900<<"."<<GetMonth()+1<<"."<<GetDay()<<" "<<GetHour()<<":"<<GetMinute()<<":"<<GetSecond()<<"]:  CPackageDeal::ErrorProtocolDeal protocolType="<<protocol<<",  roleId="<<roleId<<", ip="<<ip;
	if(pUser != NULL && pUser->m_errProtocolNum >= MAX_ERROR_NUM)
	{
		SingletonSocket::instance().CloseConnect(sock);
		cout<<" and close socket !!!";
	}
	cout<<endl;
}

void CPackageDeal::SendMoBaiData(CUser *pUser,uint8 showNum)
{
	if(pUser == NULL)
		return;
	CScene *pScene = pUser->GetScene();
	if(pScene == NULL || pScene->GetSrcSceneId() != 11)
		return;

	CNetMessage msg;
	MakeMoBaiData(showNum,msg);
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void CPackageDeal::FeiXianOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER
	// CHECK_SYSTEM_OPEN(SOT_FeiXian)
	//	const int EnterNumLimit = 1;
	char buf[128];
	uint8 op = 0;
	msg>>op;

	if(op == 1)	// 进入飞仙战场
	{
		if(!CSceneManager::IsInActivityTime(SOT_FeiXian))
		{
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1724, FENGSHEN_MIN / 100, FENGSHEN_MIN % 100, FENGSHEN_MAX / 100, FENGSHEN_MAX % 100);
			msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		if(pUser->HaveTeam())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1725,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		if(pUser->GetFightId() > 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0481,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		int floor = Random(1,2);
		if(!pUser->CanWorldTransPort(FEI_XIAN_SID1-1+floor))
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0475,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}
			
		if(!CanJoinActivity(pUser))
			return;
		
		uint16 sid = pUser->GetSrcSceneId();
		if(sid >= FEI_XIAN_SID1 && sid <= FEI_XIAN_SID5)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1726,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		msg<<PRO_SUCCESS;
		m_socketServer.SendMsg(sock,msg);

		SetQiPetDown(pUser);
		SetGenSuiPetDown(pUser);

		pUser->SetFeiXianState(0);
		EnterFeiXianScene(pUser,floor);
		SendPKNotice(pUser);
	}
	else if(op == 2)	// 获取玩家飞仙数据
	{
		uint16 srcSceneId = pUser->GetSrcSceneId();
		if(srcSceneId >= FEI_XIAN_SID1 && srcSceneId <= FEI_XIAN_SID5)
		{
			pUser->MakeFeiXianData(msg);
			m_socketServer.SendMsg(sock,msg);
		}
	}
}

void CPackageDeal::FindRoleByNameId(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER
	char sql[512];
	uint8 op = 0;	// 1获取玩家名字 2获得推荐好友列表
	msg>>op;

	if(op == 1)	// 查找玩家信息
	{
		string name;	// 名字或ID
		msg>>name;
		if(name.empty())
			return;
		msg.ReWrite();
		msg.SetType(MSG_QUERY_ROLE_BY_NAME);
		msg<<op;
		
		char **row = NULL;
		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		if(pDb == NULL)
			return;
		bool isId = true;
		for(string::size_type i=0;i < name.size();i++)
		{
			if(!(name[i] >= '0' && name[i] <= '9'))
			{
				isId = false;
				break;
			}
		}

		uint8 findNum = 0;
		uint16 pos = msg.GetDataLen();
		msg<<findNum;
		// 找id相同的
		if(isId)
		{
			ShareUserPtr pOther = m_onlineUser.GetUserByRoleId(atoi(name.c_str()));
			if(pOther.get() != NULL)
			{
				findNum++;
				msg<<pOther->GetRoleId()<<pOther->GetHead()<<pOther->GetSex()<<pOther->GetLevel()<<pOther->GetZhanDouLi()<<pOther->GetName();
			}
			else
			{
				snprintf(sql,sizeof(sql),"select id,head,sex,level,zhanDouLi,name from role_info where id=%s",name.c_str());
				if(!pDb->Query(sql))
					return;
				if((row = pDb->GetRow()) != NULL)
				{
					findNum++;
					msg<<atoi(row[0])<<(uint8)atoi(row[1])<<(uint8)atoi(row[2])<<(uint16)atoi(row[3])<<atoi(row[4])<<row[5];
				}
			}
		}
		// 找名字相同的
		snprintf(sql,sizeof(sql),"select id,head,sex,level,zhanDouLi,name from role_info where name='%s'",name.c_str());
		if(!pDb->Query(sql))
			return;
		if((row = pDb->GetRow()) != NULL)
		{
			findNum++;
			ShareUserPtr pOther = m_onlineUser.GetUserByRoleId(atoi(row[0]));
			if(pOther.get() == NULL)	// 不在线
				msg<<atoi(row[0])<<(uint8)atoi(row[1])<<(uint8)atoi(row[2])<<(uint16)atoi(row[3])<<atoi(row[4])<<row[5];
			else
				msg<<pOther->GetRoleId()<<pOther->GetHead()<<pOther->GetSex()<<pOther->GetLevel()<<pOther->GetZhanDouLi()<<pOther->GetName();
		}
		msg.WriteData(pos,&findNum,sizeof(findNum));
		m_socketServer.SendMsg(sock,msg);
	}
	else if(op == 2)	// 获得推荐好友列表
	{

	}
}

void CPackageDeal::SendWorldLevel(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint16 worldlevel = GetWorldLevel();
	uint16 worldExpPer = GetWorldExpPercent(pUser->GetLevel());
	msg << PRO_SUCCESS << worldlevel << worldExpPer << (uint16)WORLD_LEVEL_DEFAULT;
	m_socketServer.SendMsg(sock,msg);
}

void CPackageDeal::QueryChongZhiNotice(CNetMessage *pMsg,int sock)
{
	
}

void CPackageDeal::ServerChongZhiNotice(CNetMessage *pMsg,int sock)
{
	GET_MSG
	
    if(!m_socketServer.IsServer(sock))
		return;
	int roleId;
	uint8 num;
	msg>>roleId;
	
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	ShareUserPtr ptr = onlineUser.GetUserByRoleId(roleId);
	CUser *pUser = ptr.get();
    if(!pUser) 
		return;
	msg>>num;
	for(int i=0;i<num;i++)
	{
		uint8 isShouChong;
		int money;
		msg>>isShouChong>>money;
		pUser->NoticeChongZhiRet((bool)isShouChong,money); //通知客户端是否是首充和当前充值金额
	}
}

void CPackageDeal::QueryTaskTrack(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint16 missionId = 0;
	msg>>missionId;
	SingletonCMissionManager::instance().SendCMissionTrackMsg(pUser,missionId);
}

void CPackageDeal::ShiLianOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER
	// CHECK_SYSTEM_OPEN(SOT_Shilian)

	uint8 op = 0;
	msg>>op;
	if(op == 1)	// 进入试炼场景
	{
		if(!CanJoinActivity(pUser))
			return;
		if(pUser->GetTeam() > 0 || pUser->TempLeaveTeam() > 0)	
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1729,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
/*
			if(pUser->GetTeam() == pUser->GetRoleId())	// 队长,则归队成员设置成暂离状态
			{
				CScene *pScene = pUser->GetScene();
				if(pScene == NULL)
					return;
				pScene->SetInTeamMemLeave(pUser);
			}
			else
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1730,TIPS_FAILURE_COLOR);
				m_socketServer.SendMsg(sock,msg);
				return;
			}
*/
		}

		
		if(pUser->GetTeam() > 0)	
		{
			if(pUser->GetTeam() == pUser->GetRoleId())	// 队长,则归队成员设置成暂离状态
			{
				CScene *pScene = pUser->GetScene();
				if(pScene == NULL)
					return;
				pScene->SetInTeamMemLeave(pUser);
			}
			else
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1731,TIPS_FAILURE_COLOR);
				m_socketServer.SendMsg(sock,msg);
				return;
			}
		}

		msg<<PRO_SUCCESS;
		m_socketServer.SendMsg(sock,msg);

//		pUser->SetExtData8(135,pUser->GetExtData8(135)+1);
		pUser->SetExtData32(109,0);
		EnterShiLianFuBen(pUser);
	}
	else if(op == 2)	// 离开试炼场景倒计时,服务器主动发送
	{
		
	}
	else if(op == 3)	// 推送抽卡界面信息，服务器主动推送
	{
		
	}
	else if(op == 4)	// 抽奖励
	{
		uint8 idx = 0;	// 1~5
		msg>>idx;
		if(idx == 0 || idx > 5)
			return;
		if(pUser->GetShiLianAwardByIdx(idx,msg))
			m_socketServer.SendMsg(sock,msg);
	}
	else if(op == 5)	// 关闭奖励界面
	{
		if(pUser->ExitChooseShiLianAward(msg))
			m_socketServer.SendMsg(sock,msg);
	}
}

void CPackageDeal::TreasureMapOption(CNetMessage *pMsg,int sock)
{
/*
	GET_MSG
	GET_USER
	uint8 op = 0;
	msg>>op;

	if(op == 1)	// 获取藏宝图信息
	{
		pUser->SendTreasureMapMsg();
	}
	else if(op == 2)	// 参加藏宝图玩法
	{
		//char buf[128];
		uint8 lv = pUser->GetLevel();
		// CHECK_SYSTEM_OPEN(SOT_TreasureMap)
		if(pUser->GetTeam() > 0 || pUser->TempLeaveTeam())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1733,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		
		uint8 res = pUser->InHuSongMission();
		if(res == 1)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1734,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		else if(res == 2)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1735,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}

		uint8 numLimit = TreasureMapNumLimit;
		if(pUser->GetExtData8(134) >= numLimit)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1736,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		if(pUser->GetExtData16(45) > 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1737,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		
		const int posLimit[][24] = {
			{2265,2560,1005,1376,2328,2560,388,488,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
			{1569,2237,0,396,1909,2560,1065,1376,475,813,287,517,0,370,0,252,0,0,0,0,0,0,0,0},
			{1648,1872,1251,1376,2274,2560,861,1106,1050,1350,766,950,429,1113,1143,1376,0,373,0,218,0,0,0,0},
			{189,758,1180,1376,1074,1581,491,836,0,513,0,450,1136,1700,969,1376,2137,2560,1011,1376,2375,2560,0,490},
			{2258,2560,1210,1376,1157,1721,1039,1376,2318,2560,932,1227,0,603,0,470,0,308,868,1111,234,508,1222,1376},
			{0,276,0,477,0,424,1039,1376,981,1363,300,535,2157,2560,0,297,2220,2560,600,820,2184,2560,1214,1376},
			{0,252,1248,1376,0,451,535,687,882,1378,0,566,1489,1914,558,856,1866,2560,0,678,1838,2081,1275,1376},
			{0,888,0,514,1175,1628,0,165,1440,1908,0,425,609,1960,1067,1376,0,0,0,0,0,0,0,0},
			{2160,2560,1090,1376,2170,2560,301,575,1601,1994,0,322,966,1449,416,728,0,550,947,1376,0,371,0,267},
			{2184,2560,1183,1376,0,584,942,1376,0,770,0,311,867,1281,370,647,1647,2560,0,440,0,0,0,0}};

		uint16 sid = (lv-1)/10 + 1;	// 1~10
		SNpcPos point = {0};
		int getNumLimit = 50;
		sid = (int)Random(1,sid);
		if(sid > 10)
			sid = 10;
		uint8 idx = sid - 1;
		while(getNumLimit > 0)
		{
			bool inBlock = false;
			point = GetCanWalkPos(sid);
			if(point.x < 320 || point.x > 2240 || point.y < 224 || point.y > 1152)
				continue;
			for(uint8 i=0;i < sizeof(posLimit[0])/sizeof(posLimit[0][0]);i += 4)
			{
				if(point.x >= posLimit[idx][i*4] && point.x <= posLimit[idx][i*4+1] && point.y >= posLimit[idx][i*4+2] && point.y <= posLimit[idx][i*4+3])
				{
					inBlock = true;
					break;
				}
			}
			if(inBlock)
			{
				getNumLimit--;
				continue;
			}
			else
				break;
		}
		if(point.x == 0)
			return;
		pUser->SetExtData16(45,sid);
		pUser->SetExtData16(46,point.x);
		pUser->SetExtData16(47,point.y);
		msg<<PRO_SUCCESS<<(uint8)TreasureMapNumLimit<<(uint8)pUser->GetExtData8(134)<<(uint16)sid<<(uint16)point.x<<(uint16)point.y;
		m_socketServer.SendMsg(sock,msg);

		pUser->AddMission(505,"0");

	}
	else if(op == 3)	// 挖宝
	{
		char buf[256];
		uint8 lv = pUser->GetLevel();
		if(pUser->GetExtData16(45) == 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1739,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		
//		const int distance = 50;
		uint16 pSid = pUser->GetSceneId();
		uint16 pX=0,pY=0;
		pUser->GetPos(pX,pY);

		uint16 tarSid = pUser->GetExtData16(45);
		uint16 tarX = pUser->GetExtData16(46);
		uint16 tarY = pUser->GetExtData16(47);
		if(pSid == tarSid)
		{
//			int dx = (int)pX - (int)tarX;
//			int dy = (int)pY - (int)tarY;
//			if((dx*dx + dy*dy) <= distance*distance)
//			{
				int r = Random(1,100);
				if(r <= 80)	// 获得奖励
				{
					int num614 = Random(2,3);
					if(InDoubleItemNumHuoDong())
						num614 *= 2;
					pUser->AddBangDingPackage(614,num614);
					snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1740,GetItemName(614),num614);
					SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());

					int64 addExp = SingletonHuoDongExpManager::instance().GetHuoDongExp(25,pUser->GetLevel(),1.0/5);
					if(addExp > 0)
					{
						pUser->AddExp(addExp, true);
						//snprintf(buf,sizeof(buf),"获得：经验%d",(int)addExp);
						//SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
					}
				}
				else	// 出怪
				{
					CScene *pScene = pUser->GetScene();
					if(pScene == NULL)
						return;
					if(pScene->GetId() != tarSid)
						return;
					pScene->AddVisibleMonsterBoss(LANGUAGE_TRANSFORM_1741,38,tarX,tarY,100,EMT_Treasure,GetSysTime());

					snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1742,ROLE_NAME_COLOR,pUser->GetName(),pScene->GetName());
					SysInfoToAllUser(buf,true);
				}
				pUser->SetExtData8(134,pUser->GetExtData8(134)+1);
				pUser->SetExtData16(45,0);
				pUser->SetExtData16(46,0);
				pUser->SetExtData16(47,0);
				msg<<PRO_SUCCESS;

				SaveDate(pUser->GetRoleId(),23,1);
				SingletonCHDExchangeManager::instance().DropExchangeItem(pUser,EEHDT_Treasure);
				SingletonCHDExchangeManager::instance().DropHDItem(pUser,EEHDT_Treasure);

//			}
//			else
//			{
//				msg<<PRO_ERROR<<MakeStringColor("这个地方没有宝藏哦",TIPS_FAILURE_COLOR);
//			}
		}
		else
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1743,TIPS_FAILURE_COLOR);
		}
		m_socketServer.SendMsg(sock,msg);

		if(lv >= TreasureMapLevelLimit)
		{
			pUser->SendTreasureMapMsg();
		}
	}
*/
}

void CPackageDeal::PetCopyOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER
	// CHECK_SYSTEM_OPEN(SOT_Fuben)

	// 0初级1中级2高级3天书 4通天塔5每日boss
	const uint8 PETCOPY_TYPE[] = {0,1,2,4,3};
	const uint8 COST_TYPE[] =  {0,0,2,0,0};	// 0金币1元宝2物品
	const int COST_VALUE[] = {0,0,2974,0,0};
	const string CP_NAME[] = {LANGUAGE_TRANSFORM_1744,LANGUAGE_TRANSFORM_1745,LANGUAGE_TRANSFORM_1746,LANGUAGE_TRANSFORM_1747,LANGUAGE_TRANSFORM_1749};
	const string SHOW_RATIO_TITLE[] = {LANGUAGE_TRANSFORM_1756,LANGUAGE_TRANSFORM_1757,LANGUAGE_TRANSFORM_1758,"",""};
	const string SHOW_RATIO[] = {LANGUAGE_TRANSFORM_1759,LANGUAGE_TRANSFORM_1760,LANGUAGE_TRANSFORM_1761,"",""};
	const uint16 OPEN_LEVEL[] = {1,62,80,35,50};
	const uint8 ENTER_NUM[] = {5,5,10,0xff,1};
	const uint32 TONGGUAN_ID[] = {153,154,155,0,151};
	const uint32 CAN_SHAODANG[] = {1,1,1,0,1};	//0无扫荡，1能扫荡

	uint8 op = 0xff;
	msg>>op;
	switch(op)
	{
		case 1:	// 获取寻神将界面信息
			{
				uint16 lv = pUser->GetLevel();
				uint8 num = sizeof(PETCOPY_TYPE)/sizeof(PETCOPY_TYPE[0]);

				if(pUser->GetExtData8(293) > 10)
					pUser->SetExtData8(293,10);

				msg<<num;
				char buf[256];
				for(uint8 i=0;i < num;i++)
				{
					uint8 isLock = 0;	// 0开启1锁定
					msg<<PETCOPY_TYPE[i]<<CP_NAME[i]<<COST_TYPE[i];
					msg<<COST_VALUE[i];
					snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1753,OPEN_LEVEL[i]);
					msg<<buf;
					if(lv < OPEN_LEVEL[i])
						isLock = 1;
					msg<<isLock;
					if (ENTER_NUM[i] == 0xff)
					{
						msg << ENTER_NUM[i];
					}
					else if(i == 4)
					{
						uint8 n = ENTER_NUM[i] - pUser->GetExtData8(133);
						if(n > ENTER_NUM[i])
							n = 0;
						msg<<n;
					}
					else
					{
						msg << (uint8)(ENTER_NUM[i] - pUser->GetExtData8(291 + PETCOPY_TYPE[i]));
					}

					msg<<SHOW_RATIO_TITLE[i];
					if(i != 0)
						msg<<SHOW_RATIO[i];
					else
					{
						int ratio = GetPrimaryPetCopyRatio(pUser);
						if(ratio == 0)
							msg<<SHOW_RATIO[i];
						else
						{
							char buf[32];
							snprintf(buf,sizeof(buf),"%d%%",ratio);
							msg<<buf;
						}
					}

					if (CAN_SHAODANG[i] == 1)
					{
						uint8 enterCnt = 0;
						if (i == 3)
						{
							enterCnt = pUser->GetExtData8(133);
						}
						else
						{
							enterCnt = pUser->GetExtData8(291 + PETCOPY_TYPE[i]);
						}
						msg << ENTER_NUM[i] << (uint8)enterCnt;
					}
					else
						msg<<(uint8)0<<(uint8)0;

					if (TONGGUAN_ID[i] != 0)
						msg<<(uint8)pUser->HaveBitSet(TONGGUAN_ID[i]);
					else
						msg<<(uint8)2;
					
				}
				if (pUser->GetLevel() < TONGTIANTA_MIN_LEVEL)
					msg << (uint8)0;
				else
				{
					uint8 enterNum = pUser->GetExtData8(61); // 每日重置次数
					uint8 maxNum = 2; // 进入上限数
					if (maxNum > enterNum)
						msg<<(uint8)(maxNum-enterNum);
					else
						msg<<(uint8)0;
				}
				m_socketServer.SendMsg(sock,msg);
			}
			break;
		case 2:	// 进入神将副本
			{
				uint8 type = 0xff;
				msg>>type;
				if(type == 0xff || type > COPY_ID_CHONG_WU_4 - COPY_ID_CHONG_WU_1)
					return;
				uint32 curTime = (uint32)GetSysTime();
				if(curTime - pUser->GetExtData32(114) > OptionTimeSpace)
					pUser->SetExtData32(114,curTime);
				else
					return;

				if(pUser->GetTeam() > 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0484,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}

				uint8 idx = 0xff;
				for(uint8 i=0;i < sizeof(PETCOPY_TYPE)/sizeof(PETCOPY_TYPE[0]);i++)
				{
					if(PETCOPY_TYPE[i] == type)
					{
						idx = i;
						break;
					}
				}
				if(idx == 0xff)
					return;
				if(pUser->GetFightId() > 0)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0476,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}
				if(!pUser->CanWorldTransPort(COPY_ID_CHONG_WU_1+type))
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0475,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}

				if(pUser->GetTeam() > 0 && pUser->GetTeam() != pUser->GetRoleId())
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1762,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}
				if(!CanJoinActivity(pUser))
					return;
				if(pUser->GetLevel() < OPEN_LEVEL[idx])
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1763,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}

				int cost = COST_VALUE[idx];
				if(cost > 0)
				{
					if(COST_TYPE[idx] == 0)	// 金币
					{
						if(pUser->GetMoney() < cost)
						{
							msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1766,TIPS_FAILURE_COLOR);
							m_socketServer.SendMsg(sock,msg);
							return;
						}
					}
					else if(COST_TYPE[idx] == 1)	// 元宝
					{
						if(pUser->GetTongBao() < cost)
						{
							msg<<PRO_ERROR<<"";
							m_socketServer.SendMsg(sock,msg);
							ShowJumpNotice(pUser,JUMP_NOTICE_YB);
							return;
						}
					}
					else if(COST_TYPE[idx] == 2)	// 物品
					{
						if(pUser->GetItemNum(cost) < 1)
						{
							msg<<PRO_ERROR<<"";
							m_socketServer.SendMsg(sock,msg);
//							ShowJumpNotice(pUser,JUMP_NOTICE_YB);
							return;
						}
					}
				}
				if(type == COPY_ID_CHONG_WU_4 - COPY_ID_CHONG_WU_1)
				{
					if(pUser->GetExtData8(133) >= 1)
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1767,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(sock,msg);
						return;
					}
					else
					{
						pUser->SetExtData8(133,pUser->GetExtData8(133)+1);
					}
				}
				else
				{
					if (ENTER_NUM[idx] != 0xff && pUser->GetExtData8(291 + type) >= ENTER_NUM[idx])
					{
						char buf[128];
						snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0018, CP_NAME[idx].c_str());
						msg << PRO_ERROR << MakeStringColor(buf, TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(sock, msg);
						return;
					}
					pUser->SetExtData8(291+type,pUser->GetExtData8(291+type)+1);
				}

				if(cost > 0)
				{
					if(COST_TYPE[idx] == 0)	// 金币
					{
						pUser->AddMoney(-cost);
					}
					else if(COST_TYPE[idx] == 1)	// 元宝
					{
						pUser->AddTongBao(-cost);
						ItemCurrencyLog(pUser->GetRoleId(),0,0,0,cost,pUser->GetTongBao(),YBL_PETCOPY);
					}
					else if(COST_TYPE[idx] == 2)	// 物品
					{
						pUser->DelPackageById(cost,1);
						SaveUseItem(pUser->GetRoleId(),cost,LANGUAGE_SSJ_0224,1);
					}
				}
				
				msg<<PRO_SUCCESS<<"";
				m_socketServer.SendMsg(sock,msg);

				if(pUser->GetTeam() > 0)
				{
					if(pUser->GetTeam() == pUser->GetRoleId())	// 队长,则归队成员设置成暂离状态
					{
						CScene *pScene = pUser->GetScene();
						if(pScene == NULL)
							return;
						pScene->SetInTeamMemLeave(pUser);
					}
					else
						return;
				}
				SaveDate(pUser, 32, type);
				pUser->SaveEnterPos(pUser->GetSceneId(),pUser->GetX(),pUser->GetY());
				EnterChongWuFuBen(pUser,type);
			}
			break;
		case 3: // 扫荡状态请求
			{
				uint8 type = 0xff; 
				msg>>type;

				if(type == 0xff || type > COPY_ID_CHONG_WU_3 - COPY_ID_CHONG_WU_1)
					return;

				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			break;
		case 4: // 扫荡
			{
				uint8 type = 0;
				msg >> type;
				uint8 idx = 0xff;
				for (uint8 i = 0; i < sizeof(PETCOPY_TYPE) / sizeof(PETCOPY_TYPE[0]); i++)
				{
					if (PETCOPY_TYPE[i] == type)
					{
						idx = i;
						break;
					}
				}
				if (idx == 0xff)
					return;

				if (CAN_SHAODANG[idx] != 1)
				{
					msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0031, TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(), msg);
					return;
				}
				uint8 sweepCnt = 0;
				if (PETCOPY_TYPE[idx] == 3) // 天书副本
				{
					sweepCnt = (ENTER_NUM[idx] > pUser->GetExtData8(133)) ? (ENTER_NUM[idx] - pUser->GetExtData8(133)) : 0;
				}
				else
				{
					sweepCnt = (ENTER_NUM[idx] > pUser->GetExtData8(291 + PETCOPY_TYPE[idx])) ? (ENTER_NUM[idx] - pUser->GetExtData8(291 + PETCOPY_TYPE[idx])) : 0;
				}
				uint16 fuBenId = COPY_ID_CHONG_WU_1 + type;
				uint16 vipLv = pUser->GetVipLevel();
				if (vipLv > MAX_VIP_LEVEL)
				{
					return;
				}
				if (G_VipConfig[vipLv].sweepCopys.find(fuBenId) == G_VipConfig[pUser->GetVipLevel()].sweepCopys.end())
				{
					for (int vi = vipLv; vi < MAX_VIP_LEVEL + 1; ++vi)
					{
						if (G_VipConfig[vi].sweepCopys.find(fuBenId) != G_VipConfig[vi].sweepCopys.end())
						{
							char buf[128];
							snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0027, vi);
							msg << PRO_ERROR << MakeStringColor(buf, TIPS_FAILURE_COLOR);
							m_socketServer.SendMsg(pUser->GetSock(), msg);
							return;
						}
					}
					return;
				}

				if (!pUser->HaveBitSet(TONGGUAN_ID[idx]))
				{
					msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_947, TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(), msg);
					return;
				}

				int cost = COST_VALUE[idx];
				do 
				{
					if (cost == 0)
						break;
					if (COST_TYPE[idx] == 0)	// 金币
					{
						int allMoney = pUser->GetMoney();
						int realCnt = allMoney / cost;
						sweepCnt = realCnt > sweepCnt ? sweepCnt : realCnt;
						if (sweepCnt == 0)
							break;
						pUser->AddMoney(-sweepCnt * cost);
					}
					else if (COST_TYPE[idx] == 1)	// 元宝
					{
						int allBao = pUser->GetTongBao();
						int realCnt = allBao / cost;
						sweepCnt = realCnt > sweepCnt ? sweepCnt : realCnt;
						if (sweepCnt == 0)
							break;
						pUser->AddTongBao(-cost * sweepCnt);
						ItemCurrencyLog(pUser->GetRoleId(), 0, 0, 0, cost * sweepCnt, pUser->GetTongBao(), YBL_PETCOPY);
					}
					else if (COST_TYPE[idx] == 2)	// 物品
					{
						sweepCnt = pUser->GetItemNum(cost);
						if (sweepCnt == 0)
							break;
						pUser->DelPackageById(cost, sweepCnt);
						SaveUseItem(pUser->GetRoleId(), cost, LANGUAGE_SSJ_0224, sweepCnt);
					}
				} while (false);
				if (sweepCnt == 0)
				{
					msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_1767, TIPS_FAILURE_COLOR);
				}
				else
				{
					msg << PRO_SUCCESS << sweepCnt;
					if (type == 3)
					{
						pUser->SetExtData8(133, pUser->GetExtData8(133) + sweepCnt);
					}
					else
					{
						pUser->SetExtData8(291 + type, pUser->GetExtData8(291 + type) + sweepCnt);
					}
					pUser->SaoDangFuBen(fuBenId, sweepCnt, msg);
				}
				m_socketServer.SendMsg(pUser->GetSock(), msg);
			}
		default:
			break;
	}
}

void CPackageDeal::MoBaiOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER
	// CHECK_SYSTEM_OPEN(SOT_Arena)

	const uint32 MOBAI_TIME_GAP = 60;
	const uint8 MOBAI_NUM_LIMIT = 5;
	uint8 op = 0xff;
	msg>>op;

	char buf[512];
	switch(op)
	{
		case 1:	// 膜拜基本信息
			{
				SendMoBaiData(pUser,MOBAI_SHOW_NUM);
			}
			break;
		case 2:	// 膜拜界面信息
			{
				const uint8 SHOW_NUM = 3;
				msg<<SHOW_NUM;
				for(uint32 idx=1;idx <= SHOW_NUM;idx++)
				{
					ArenaPaiHangData data;
					if(SingletonCArenaManager::instance().GetDataByRank(idx, data))
					{
//						msg<<data.roleId<<data.type<<data.name<<data.xiang<<data.level<<data.sex<<GetRoleBangPaiName(data.roleId)
//							<<data.bowCount<<data.eggCount;
					}
					else
					{
						msg<<(uint32)0;
					}
				}

				uint32 cdTime = 0;
				if((uint32)GetSysTime() - pUser->GetExtData32(107) < MOBAI_TIME_GAP)
					cdTime = (uint32)GetSysTime() - pUser->GetExtData32(107);
				msg<<pUser->GetMoBaiBowNum()<<pUser->GetMoBaiEggNum()<<MOBAI_NUM_LIMIT<<cdTime;

				uint16 numPos = msg.GetDataLen();
				uint16 num = 0;
				msg<<num;
				for(uint32 idx=1;idx <= SHOW_NUM;idx++)
				{
					ArenaPaiHangData data;
					if(SingletonCArenaManager::instance().GetDataByRank(idx, data))
					{
						list<SBangPaiLog> logList;
						GetMoBaiLogList(data.roleId, logList);
						for(list<SBangPaiLog>::iterator it=logList.begin();it != logList.end();it++)
							msg<<it->option_roleId<<it->log;
						num += logList.size();
					}
				}
				msg.WriteData(numPos,&num,sizeof(num));
				m_socketServer.SendMsg(sock,msg);
			}
			break;
		case 3:	// 扔鸡蛋
			{
				uint32 idx = 0xffff;
				uint32 roleId = 0;
				uint8 robot = 0;
				msg>>idx>>roleId>>robot;
				if(idx == 0xffff || roleId == 0)
					return;

				/*if(pUser->GetLevel() < 25)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1782,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}*/
				if(pUser->GetMoBaiBowNum() + pUser->GetMoBaiEggNum() >= MOBAI_NUM_LIMIT)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1783,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}

				uint32 curTime = (uint32)GetSysTime();
				uint32 lastTime = pUser->GetExtData32(107);
				if(curTime - lastTime < MOBAI_TIME_GAP)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1784,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}

				ArenaPaiHangData data;
				if(!SingletonCArenaManager::instance().GetDataByRank(idx, data))
				{
					if(data.roleId == roleId && data.type == robot)
					{
						data.eggCount++;
						pUser->SetExtData32(107,curTime);
						pUser->AddMoBaiEggNum();
//						snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1785,ROLE_NAME_COLOR,pUser->GetName(),ROLE_NAME_COLOR,data.name.c_str(),PQT_GREEN);
//						SaveMoBaiLog(pUser->GetRoleId(),roleId,buf);
//						msg<<PRO_SUCCESS<<data.eggCount<<pUser->GetRoleId()<<buf;

						int level = pUser->GetLevel();
						int exp = (level+2)*300;
						exp = pUser->AddExp(exp);
						int worldExpPer = GetWorldExpPercent(pUser->GetLevel());
						if (worldExpPer > 0)
							snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1786,exp,worldExpPer, (int)(MOBAI_NUM_LIMIT - pUser->GetMoBaiBowNum() - pUser->GetMoBaiEggNum()),(int)MOBAI_NUM_LIMIT);
						else
							snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1787,exp,(int)(MOBAI_NUM_LIMIT - pUser->GetMoBaiBowNum() - pUser->GetMoBaiEggNum()),(int)MOBAI_NUM_LIMIT);
						msg<<MakeStringColor(buf,TIPS_WARNING_COLOR);
						m_socketServer.SendMsg(sock,msg);
					}
					else
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1788,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(sock,msg);
						return;
					}
				}
				if(pUser->GetMoBaiBowNum() + pUser->GetMoBaiEggNum() >= MOBAI_NUM_LIMIT)
				{
					char buf[128];
					pUser->AddBangDingPackage(1100,1);
					snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1789,(int)MOBAI_NUM_LIMIT,GetItemName(1100));
					SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
				}
				SingletonCMissionManager::instance().UpdateDCMissionComplate(pUser, EMISS_DC_51);
		}
			break;
		case 4:	// 膜拜
			{
				uint32 idx = 0xffff;
				uint32 roleId = 0;
				uint8 robot = 0;
				msg>>idx>>roleId>>robot;
				if(idx == 0xffff || roleId == 0)
					return;
				/*if(pUser->GetLevel() < 25)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1790,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}*/
				if(pUser->GetMoBaiBowNum() + pUser->GetMoBaiEggNum() >= MOBAI_NUM_LIMIT)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1791,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}

				uint32 curTime = (uint32)GetSysTime();
				uint32 lastTime = pUser->GetExtData32(107);
				if(curTime - lastTime < MOBAI_TIME_GAP)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1792,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}

				ArenaPaiHangData data;
				if(SingletonCArenaManager::instance().GetUserDataByRank(idx, data))
				{
					if(data.roleId == roleId && data.type == robot)
					{
						data.bowCount++;
						pUser->SetExtData32(107,curTime);
						pUser->AddMoBaiBowNum();
//						snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1793,ROLE_NAME_COLOR,pUser->GetName(),ROLE_NAME_COLOR,data.name.c_str(),PQT_GREEN);
//						SaveMoBaiLog(pUser->GetRoleId(),roleId,buf);
//						msg<<PRO_SUCCESS<<data.bowCount<<pUser->GetRoleId()<<buf;

						int level = pUser->GetLevel();
						int exp = (level+2)*400;
						exp = pUser->AddExp(exp);
						int worldExpPer = GetWorldExpPercent(pUser->GetLevel());
						if (worldExpPer > 0)
							snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1794,exp,worldExpPer, (int)(MOBAI_NUM_LIMIT - pUser->GetMoBaiBowNum() - pUser->GetMoBaiEggNum()),(int)MOBAI_NUM_LIMIT);
						else
							snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1795,exp,(int)(MOBAI_NUM_LIMIT - pUser->GetMoBaiBowNum() - pUser->GetMoBaiEggNum()),(int)MOBAI_NUM_LIMIT);
						msg<<MakeStringColor(buf,TIPS_WARNING_COLOR);
						m_socketServer.SendMsg(sock,msg);

						ShareUserPtr tarPtr = SingletonOnlineUser::instance().GetUserByRoleId(roleId);
						if(tarPtr.get() != NULL)
						{
							snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1796,pUser->GetName());
							SendSysInfo(tarPtr.get(),MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
						}
					}
					else
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1797,TIPS_FAILURE_COLOR);
						m_socketServer.SendMsg(sock,msg);
						return;
					}
				}

				if(pUser->GetMoBaiBowNum() + pUser->GetMoBaiEggNum() >= MOBAI_NUM_LIMIT)
				{
					char buf[128];
					pUser->AddBangDingPackage(1100,1);
					snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1798,(int)MOBAI_NUM_LIMIT,GetItemName(1100));
					SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
				}
				SingletonCMissionManager::instance().UpdateDCMissionComplate(pUser, EMISS_DC_51);
		}
			break;
		default:
			break;
	}
}

// 擂台赛
void CPackageDeal::LeiTaiSaiOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 op = 0;
	msg>>op;

	if (op == 1) // 活动时间是否开始、结束
	{

	}
	else if (op == 2) // 擂台赛积分
	{
		pUser->SendLeiTaiJifen();
	}
	else if (op == 3) // 擂台排名
	{
		int leftTime = CSceneManager::GetActivityFinishTime(SOT_LeiTaiSai);
		CSceneManager &scene = SingletonSceneManager::instance();
		CScene *pScene = scene.FindScene(LEI_TAI_ID2);
		if (pScene == NULL)
			return;
		CNetMessage leiTaimsg;
		leiTaimsg.SetType(MSG_LEI_TAI_SAI);
		leiTaimsg<<(uint8)3<<leftTime;
		pScene->GetMatchPaiMing(50,leiTaimsg);
		m_socketServer.SendMsg(pUser->GetSock(),leiTaimsg);
	}
	else if(op == 4)	// 寻路或传送
	{
/*		if(pUser->InHuSongMission() == 1)
		{
			msg<<PRO_ERROR<<LANGUAGE_TRANSFORM_1799;
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		else if(pUser->InHuSongMission() == 2)
		{
			msg<<PRO_ERROR<<LANGUAGE_TRANSFORM_1800;
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
*/

		const int npcId = 24;
		SNpcPos npcPos = GetNpcScenePos(npcId);
		if(pUser->GetTeam() != 0)
		{
			msg<<PRO_ERROR<<LANGUAGE_TRANSFORM_1801;
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(pUser->GetSceneId() != npcPos.sceneId)
		{
			TransportUser(pUser,npcPos.sceneId,npcPos.x,npcPos.y,3);
		}
		else
		{
			SendYinDaoNPCPos(pUser,npcPos.sceneId,npcPos.x,npcPos.y,npcId);
		}
	}
}

// 猜拳
void CPackageDeal::CaiQuanOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	static int needYuanBao = 10; // 作弊消耗元宝数
	static int colddownTime = 2*60; // 冷却时间

	uint8 op = 0;
	msg>>op;
	if (op == 1) // 猜拳
	{
		if (pUser->GetCaiQuanCiShu() >= 5)
		{
			msg.ReWrite();
			msg.SetType(MSG_CAI_QUAN);
			msg<<(uint8)1<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1802,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		time_t curTime = GetSysTime();
		if (curTime < pUser->GetCaiQuanEndTime())
		{
			msg.ReWrite();
			msg.SetType(MSG_CAI_QUAN);
			msg<<(uint8)1<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1803,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		uint8 rewardType = 0; // 奖励类型 1：经验；2：潜能；3：金币 4 : 不给奖励，不消耗，必胜
		uint8 caiQuanType = 0; // 猜拳类型 1：普通；2：作弊
		msg>>rewardType>>caiQuanType;
		if(!(rewardType >= 1 && rewardType <= 4))
		{
			msg.ReWrite();
			msg.SetType(MSG_CAI_QUAN);
			msg<<(uint8)1<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1804,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(!(caiQuanType >= 1 && caiQuanType <= 2))
		{
			msg.ReWrite();
			msg.SetType(MSG_CAI_QUAN);
			msg<<(uint8)1<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1805,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(rewardType != 4 && caiQuanType == 2 && pUser->GetTongBao() < needYuanBao)
		{
			msg.ReWrite();
			msg.SetType(MSG_CAI_QUAN);
			msg<<(uint8)1<<PRO_ERROR<<"";
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			ShowJumpNotice(pUser,JUMP_NOTICE_YB);
			return;
		}
		uint8 isWin = 0; // 是否胜利 0：失败；1：胜利；2：平手
		if(rewardType == 4)
		{
			isWin = 1;
		}
		else
		{
			if(caiQuanType == 1) // 普通猜拳
			{
				isWin = Random(0,2);
			}
			else // 作弊猜拳
			{
				isWin = 1;
				pUser->AddTongBao(-needYuanBao); // 扣钱
				ItemCurrencyLog(pUser->GetRoleId(),0,0,0,needYuanBao,pUser->GetTongBao(),YBL_CAI_QUAN);
			}
		}

		msg.ReWrite();
		msg.SetType(MSG_CAI_QUAN);
		msg<<(uint8)1;
		if(isWin == 0) // 失败
		{
			pUser->SetCaiQuanCiShu(pUser->GetCaiQuanCiShu()+1);
			pUser->SetCaiQuanEndTime(curTime+colddownTime);
			int reward = pUser->AddCaiQuanReward(false,rewardType);
			char rewardInfo[64] = {0};
			if (rewardType == 1)
				snprintf(rewardInfo,sizeof(rewardInfo),LANGUAGE_TRANSFORM_1806,reward);
			else if (rewardType == 2)
				snprintf(rewardInfo,sizeof(rewardInfo),LANGUAGE_TRANSFORM_1807,reward);
			else if (rewardType == 3)
				snprintf(rewardInfo,sizeof(rewardInfo),LANGUAGE_TRANSFORM_1808,reward);
			msg<<PRO_SUCCESS<<isWin<<MakeStringColor(rewardInfo,TIPS_WARNING_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			pUser->CheckMissionHuoYueDu(); // 活跃度任务
		}
		else if (isWin == 1) // 成功
		{
			if(rewardType != 4)
			{
				pUser->SetCaiQuanCiShu(pUser->GetCaiQuanCiShu()+1);
				pUser->SetCaiQuanEndTime(curTime+colddownTime);
				int reward = pUser->AddCaiQuanReward(true,rewardType);
				char rewardInfo[64] = {0};
				if (rewardType == 1)
					snprintf(rewardInfo,sizeof(rewardInfo),LANGUAGE_TRANSFORM_1809,reward);
				else if (rewardType == 2)
					snprintf(rewardInfo,sizeof(rewardInfo),LANGUAGE_TRANSFORM_1810,reward);
				else if (rewardType == 3)
					snprintf(rewardInfo,sizeof(rewardInfo),LANGUAGE_TRANSFORM_1811,reward);
				msg<<PRO_SUCCESS<<isWin<<MakeStringColor(rewardInfo,TIPS_WARNING_COLOR);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
				pUser->CheckMissionHuoYueDu(); // 活跃度任务
			}
			else
			{
				msg<<PRO_SUCCESS<<isWin<<MakeStringColor(LANGUAGE_TRANSFORM_1812,TIPS_WARNING_COLOR);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
		}
		else // 平手
		{
			msg<<PRO_SUCCESS<<isWin<<MakeStringColor(LANGUAGE_TRANSFORM_1813,TIPS_WARNING_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
		}

		// ====================
		// 更新猜拳任务
		SingletonCMissionManager::instance().VerifyNewBranchMissionFinish(pUser, EMISS_DC_10); // TODO
	}
}

// 神将抽取
void CPackageDeal::PetDraw(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 op = 0;	// 1抽神将基本信息2抽神将
	msg>>op;

	CChouKaManager* chouKa = pUser->GetChouKa();
	if (chouKa == NULL)
		return;
	if(op == 1)	// 获取抽神将基础信息
	{
		if(chouKa->GetChouKaMsg(msg))
			m_socketServer.SendMsg(pUser->GetSock(),msg);
	}
	else if(op == 2)	// 抽神将
	{
		if(chouKa->ChouKa(pUser,msg))
			m_socketServer.SendMsg(pUser->GetSock(),msg);
	}
}

// 阶段目标
void CPackageDeal::StageGoalOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 op = 0;
	msg>>op;
	switch (op)
	{
	case 1: // 获取阶段目标
		SingletonCMissionManager::instance().GetStageGoalInfo(pUser, msg);
		break;

	case 2: // 领取章节奖励
		{
			uint8 stage = 0;
			msg>>stage;
			SingletonCMissionManager::instance().GetStageGoalAward(pUser, stage, msg);
			break;
		}
	}
}

// 获取阶段目标列表
void CPackageDeal::GetStageGoalInfo(CUser *pUser)
{
	if (pUser == NULL)
		return;
	CCallScript *pCallScript = FindScript(200);
	if(pCallScript == NULL)
		return;
	char *stageGoalInfo = NULL;
	pCallScript->Call("GetStageGoalInfo","u>s",pUser,&stageGoalInfo);
	if (stageGoalInfo == NULL)
		return;
	char buf[2048];
	strncpy(buf,stageGoalInfo,2048);

	CNetMessage msg;
	msg.SetType(MSG_STAGE_GOAL);
	msg<<(uint8)1<<pUser->GetNewShenQiCarryID()<<buf;
	m_socketServer.SendMsg(pUser->GetSock(),msg);
}

// 领取小节奖励
void CPackageDeal::GetSGSectionReward(CUser *pUser,int stage,int section)
{
	if (pUser == NULL)
		return;
	CCallScript *pCallScript = FindScript(200);
	if(pCallScript == NULL)
		return;
	int res = -1;
	pCallScript->Call("GetSGSectionReward","uii>i",pUser,stage,section,&res);
	CNetMessage msg;
	msg.SetType(MSG_STAGE_GOAL);
	msg<<(uint8)2;
	if (res != 0)
	{
		msg<<PRO_ERROR<<(uint8)res;
		m_socketServer.SendMsg(pUser->GetSock(),msg);
		return;
	}
	msg<<PRO_SUCCESS<<(uint8)stage<<(uint8)section;
	m_socketServer.SendMsg(pUser->GetSock(),msg);
	SendSysNotice(pUser, 1);
}

// 领取章节奖励
void CPackageDeal::GetSGStageReward(CUser *pUser,int stage)
{
	if (pUser == NULL)
		return;
	CCallScript *pCallScript = FindScript(200);
	if(pCallScript == NULL)
		return;
	int res = -1;
	pCallScript->Call("GetSGStageReward","ui>i",pUser,stage,&res);
	CNetMessage msg;
	msg.SetType(MSG_STAGE_GOAL);
	msg<<(uint8)3;
	if (res != 0)
	{
		msg<<PRO_ERROR<<(uint8)res;
		m_socketServer.SendMsg(pUser->GetSock(),msg);
		return;
	}
	msg<<PRO_SUCCESS<<(uint8)stage;
	m_socketServer.SendMsg(pUser->GetSock(),msg);
	//把激活的神器加入到新神器记录里--stage123对应神器id
	pUser->ActiveNewShenQi(stage);

	// 更新玩家属性
	pUser->InitAndUpdate();
	SendSysNotice(pUser, 1);
}

// 装备章节奖励
void CPackageDeal::EquipSGStageReward(CUser *pUser,int stage)
{
	if (pUser == NULL)
		return;
	CCallScript *pCallScript = FindScript(200);
	if(pCallScript == NULL)
		return;
	int res = -1;
	pCallScript->Call("EquipSGStageReward","ui>i",pUser,stage,&res);
	CNetMessage msg;
	msg.SetType(MSG_STAGE_GOAL);
	msg<<(uint8)7;
	if (res != 0)
	{
		msg<<PRO_ERROR<<(uint8)res;
		m_socketServer.SendMsg(pUser->GetSock(),msg);
		return;
	}

	msg<<PRO_SUCCESS<<(uint8)stage;
	m_socketServer.SendMsg(pUser->GetSock(),msg);
	pUser->InitAndUpdate();
	UpdateUserInfo(pUser,ESRT_ShenQi);
}

// 加载7日登陆奖励
void CPackageDeal::LoadHd7RiDengLu(vector<HD_7RiDengLu>& rewardArr)
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
	if(!pDb->Query("select type1,num1,type2,num2,type3,num3,value1, value2, value3 from hd_7ridenglu order by id asc"))
		return;

	HD_7RiDengLu reward;
	char **row = NULL;
	while((row = pDb->GetRow()) != NULL)
	{
		reward.type[0] = atoi(row[0]);
		reward.num[0] = atoi(row[1]);
		reward.type[1] = atoi(row[2]);
		reward.num[1] = atoi(row[3]);
		reward.type[2] = atoi(row[4]);
		reward.num[2] = atoi(row[5]);
		reward.value[0] = atoi(row[6]);
		reward.value[1] = atoi(row[7]);
		reward.value[2] = atoi(row[8]);
		rewardArr.push_back(reward);
	}
}

void CPackageDeal::ServerStopProgressBar(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 op=0; 
	int npc_id= 0;
	int index = 0;
	msg>>op>>npc_id>>index;
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	if( npc_id == (int)awardManager.GetHuoDongPic(CHuoDongAwardManager::XTMAS_BOX) )
	{
		SingletonCWaitForFightManager::instance().ClearUserInfo( pUser->GetRoleId());
	}
	else if( npc_id == (int)awardManager.GetHuoDongPic(CHuoDongAwardManager::SHENGDAN_FENGSHOU) )
	{
		SingletonCWaitForFightManager::instance().ClearUserInfo( pUser->GetRoleId());
	}
}

void CPackageDeal::ServerXianYuan(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER
	/*if( pUser->GetLevel() < XIANYUAN_OPEN_LEVEL )
		return;*/
	uint8 op=0;
	msg>>op;
	switch(op)
	{
		case 1:
			{
				pUser->SendAllXianYuanInfo();
				return;
			}
			break;
		case 2:
			{
				uint32 chapter_id = 0;
				msg>>chapter_id;
				pUser->ActiveXianYuanChapter(chapter_id);
				return;
			}
			break;
		case 3:
			{
				uint32 card_id = 0;
				uint32 num = 0;
				msg>>card_id>>num;
				pUser->DecomposeXianYuanCard(card_id,num);
				return;
			}
			break;
		case 4:
			{
				uint8 type = 0;
				uint8 useYB = 0;
				msg>>type>>useYB;
				pUser->LotteryXianYuanCard(type,useYB);
				return;
			}
			break;
		default:break;
	}
}

#ifdef KUA_FU
void CPackageDeal::KuaFu_1VS1_Option(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 op = 0;
	msg>>op;

	// op= 1~20 预赛使用
	// op>= 21  决赛使用
	if(op == 1)//请求面板信息
	{
		if(SingletonCKuaFu1vs1PreliminaryManager::instance().IsInKuaFu1vs1PreliminaryTime() )
		{
			SingletonCKuaFu1vs1PreliminaryManager::instance().HandleKuaFu1vs1PreliminaryReq(pUser);
		}
		else
		{
			//决赛
			MakeKuaFu1V1PanelInfo(pUser,0,msg);
			m_socketServer.SendMsg(sock,msg);
		}
	}
	else if(op == 2)//请求预赛报名
	{
		if(!SingletonCKuaFu1vs1PreliminaryManager::instance().IsInKuaFu1vs1PreliminaryTime())
		{
			SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0526,TIPS_FAILURE_COLOR).c_str());
			return;
		}
		SingletonCKuaFu1vs1PreliminaryManager::instance().ApplyForKuaFu1vs1Preliminary(pUser);
	}
	else if(op == 3)//请求预赛队伍排名
	{
		if(!SingletonCKuaFu1vs1PreliminaryManager::instance().IsInKuaFu1vs1PreliminaryTime() )
			return;
		int sort_id = 0;
		msg>>sort_id;
		SingletonCKuaFu1vs1PreliminaryManager::instance().SendSingleSortInfo(pUser,sort_id);
	}
	else if(op == 4)//请求预赛挑战
	{
		if(!SingletonCKuaFu1vs1PreliminaryManager::instance().IsInKuaFu1vs1PreliminaryTime() )
			return;
		int enemy_seq = 0;
		msg>>enemy_seq;
		SingletonCKuaFu1vs1PreliminaryManager::instance().SelectEnemyToFight(pUser,enemy_seq);
	}
	else if( op == 5)//请求预赛刷新敌人
	{
		if(!SingletonCKuaFu1vs1PreliminaryManager::instance().IsInKuaFu1vs1PreliminaryTime() )
			return;
		SingletonCKuaFu1vs1PreliminaryManager::instance().RefreshEnemy(pUser);
	}
	else if(op == 6)//请求预赛增加挑战次数
	{
		if(!SingletonCKuaFu1vs1PreliminaryManager::instance().IsInKuaFu1vs1PreliminaryTime() )
			return;
		SingletonCKuaFu1vs1PreliminaryManager::instance().AddChallengeNum(pUser);
	}
	else if(op == 7)//请求预赛清除CD时间
	{
		if(!SingletonCKuaFu1vs1PreliminaryManager::instance().IsInKuaFu1vs1PreliminaryTime() )
			return;
		SingletonCKuaFu1vs1PreliminaryManager::instance().ClearChallengeCDTime(pUser);
	}
	else if(op == 21)	// 获得决赛面板信息
	{
		if(GetWeekDay() != 0)
			return;
		uint8 type = 0;	// 0上半场1下半场2总决赛
		msg>>type;
		if(type > 2)
			return;
		MakeKuaFu1V1PanelInfo(pUser,type,msg);
		m_socketServer.SendMsg(sock,msg);
	}
	else if(op == 22)	// 查看节点信息
	{
		if(GetWeekDay() != 0)
			return;
		uint8 type = 0;	// 0上半场1下半场2总决赛
		uint8 nodeIdx = 0;	// 1~15
		msg>>type>>nodeIdx;
		if(type > 2 || nodeIdx > 15)
			return;
		MakeKuaFu1V1NodeInfo(pUser,type,nodeIdx,msg);
		m_socketServer.SendMsg(sock,msg);
	}
	else if(op == 23)	// 下注
	{
		if(GetWeekDay() != 0)
			return;
		uint8 type = 0;	// 0上半场1下半场2总决赛
		uint8 nodeIdx = 0;	// 1~15
		uint32 voteId = 0;
		msg>>type>>nodeIdx>>voteId;
		if(type > 2 || nodeIdx > 15 || voteId == 0)
			return;
		if(pUser->GetMoney() < VOTE_NEED_MONEY)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0062,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}

		KuaFu1V1Vote(pUser,type,nodeIdx,voteId,msg);
		m_socketServer.SendMsg(sock,msg);
	}
	else if(op == 24)	// 进入决赛场景
	{
		if(GetWeekDay() != 0)
			return;
		Enter1V1FinalsScene(pUser);
	}
	else if(op == 25)	// 决赛场景倒计时
	{
		if(GetWeekDay() != 0)
			return;
		if(pUser->GetSrcSceneId() == KUA_FU_1V1_SCENE_ID)
			SendKuaFu1V1SceneLeftTime(pUser->GetScene(),pUser);
		else
			SendKuaFu1V1LeftTime(pUser);
	}
	else if(op == 26)	// 获取本场景比赛积分值
	{
		if(GetWeekDay() != 0)
			return;
		SendKuaFu1V1SceneScore(pUser);
	}
	else if(op == 27)	// 更新本场景比赛积分值
	{
		// 服务器主动推送
	}
	else if(op == 28)	// 获得上次决赛面板信息
	{
		uint8 type = 0;	// 0上半场1下半场2总决赛
		msg>>type;
		if(type > 2)
			return;
		MakeKuaFu1V1PanelInfoOld(pUser,type,msg);
		m_socketServer.SendMsg(sock,msg);
	}
	else if(op == 29)	// 查看上次节点信息
	{
		uint8 type = 0;	// 0上半场1下半场2总决赛
		uint8 nodeIdx = 0;	// 1~15
		msg>>type>>nodeIdx;
		if(type > 2 || nodeIdx > 15)
			return;
		MakeKuaFu1V1NodeInfoOld(pUser,type,nodeIdx,msg);
		m_socketServer.SendMsg(sock,msg);
	}
}
#endif
// 组队昆仑山活动
void CPackageDeal::KunLunShanTeamOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 op = 0;
	msg>>op;
	if(op == 1)	// 参加活动
	{
		EnterTeamKunLunShan(pUser);
	}
	else if(op == 2)	// 排行榜
	{
		GetKunLunShanTeamPaiHang(pUser,msg);
	}
	else if(op == 3)	// 个人活动信息
	{
		const int FLUSH_TIME_GAP = 5;	// min
		const string KillEnemyTaskInfo[TeamKunLunShan_EnemyTaskNum][3] = {
			{LANGUAGE_SSJ_0024,LANGUAGE_SSJ_0025,LANGUAGE_SSJ_0026},
			{LANGUAGE_SSJ_0027,LANGUAGE_SSJ_0028,LANGUAGE_SSJ_0029},
			{LANGUAGE_SSJ_0030,LANGUAGE_SSJ_0031,LANGUAGE_SSJ_0032}};

		const string KillMonsterTaskInfo[TeamKunLunShan_MonsterTaskNum][3] = {
			{LANGUAGE_SSJ_0033,LANGUAGE_SSJ_0034,LANGUAGE_SSJ_0035},
			{LANGUAGE_SSJ_0036,LANGUAGE_SSJ_0037,LANGUAGE_SSJ_0038},
			{LANGUAGE_SSJ_0039,LANGUAGE_SSJ_0040,LANGUAGE_SSJ_0041}};
		
		uint16 flushSecond = 0xffff;
		int minute = GetMinute();
		int sec = GetSysTime()%60;
		if(InFuncionLevelTime(SOT_KuaFuLunDao))
			flushSecond = (FLUSH_TIME_GAP -1 - minute%5)*60 + (60 - sec);
		uint32 jifen = pUser->GetExtData32(292);
		uint16 killRoleNum = pUser->GetExtData16(56);
		uint16 killMonsterNum = pUser->GetExtData16(57);

		//   历险点    杀敌数        杀怪数    下次怪物刷新时间            总时间间隔
		msg<<jifen<<killRoleNum<<killMonsterNum<<flushSecond<<(uint16)(FLUSH_TIME_GAP*60);
		//                杀敌任务数
		msg<<(uint8)TeamKunLunShan_EnemyTaskNum;
		for(int i=0;i < TeamKunLunShan_EnemyTaskNum;i++)
		{
			uint8 complete = ((killRoleNum >= TeamKunLunShan_KillEnemyNum[i]) ? 1 : 0);	// 1完成0未完成
			//        杀敌task                  目标                        奖励
			msg<<KillEnemyTaskInfo[i][0]<<KillEnemyTaskInfo[i][1]<<(uint16)TeamKunLunShan_KillEnemyNum[i]<<KillEnemyTaskInfo[i][2]<<complete;
		}
		//                杀怪任务数
		msg<<(uint8)TeamKunLunShan_MonsterTaskNum;
		for(int i=0;i < TeamKunLunShan_MonsterTaskNum;i++)
		{
			uint8 complete = ((killMonsterNum >= TeamKunLunShan_KillMonsterNum[i]) ? 1 : 0);	// 1完成0未完成
			//        杀怪task                      目标                          奖励
			msg<<KillMonsterTaskInfo[i][0]<<KillMonsterTaskInfo[i][1]<<(uint16)(TeamKunLunShan_KillMonsterNum[i])<<KillMonsterTaskInfo[i][2]<<complete;
		}
		m_socketServer.SendMsg(sock,msg);
	}
	else if(op == 4)	// 获取房间信息
	{
		CScene *pScene = pUser->GetScene();
		if(pScene == NULL)
			return;
		if(pScene->GetSrcSceneId() != KUN_LUN_SHAN_TEAM_SCENE_ID)
			return;
		msg<<(uint16)(pScene->GetId()-KUN_LUN_SHAN_TEAM_SCENE_ID_BEGIN+1);
		m_sceneManager.GetTeamKunLunShanRoomInfo(msg);
		m_socketServer.SendMsg(sock,msg);
	}
	else if(op == 5)	// 切换房间
	{
		uint16 index = 0;
		msg>>index;
		if(index == 0)
			return;
		if(index > m_sceneManager.GetKunLunShanTeamSceneNum())
			return;
		CScene *pScene = pUser->GetScene();
		if(pScene == NULL || pScene->GetSrcSceneId() != KUN_LUN_SHAN_TEAM_SCENE_ID)
			return;
		if(index == pScene->GetId()-KUN_LUN_SHAN_TEAM_SCENE_ID_BEGIN+1)
		{
			msg<<MakeStringColor(LANGUAGE_SSJ_0042,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}

		if(pUser->GetTeam() != pUser->GetRoleId())
		{
			msg<<MakeStringColor(LANGUAGE_SSJ_0052,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}

		int teamNum = GetTeamMemNum(pUser);
		if(teamNum == 0)
		{
			msg<<MakeStringColor(LANGUAGE_SSJ_0052,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		pScene = m_sceneManager.GetKunLunShanTeamSceneByIndex(index);
		if(pScene == NULL)
			return;
		if(pScene->GetUserNum()+teamNum > KUN_LUN_SHAN_TEAM_ROOM_LIMIT)
		{
			msg<<MakeStringColor(LANGUAGE_SSJ_0043,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}

		uint16 x=0,y=0;
		if(!pScene->GetCanWalkPos(x,y))
			return;
		uint16 srcSceneId = pScene->GetSrcSceneId();
		pUser->GetNextSrcSceneId(srcSceneId);
		
		CNetMessage msg1;
		msg1.ReWrite();
		msg1.SetType(PRO_JUMP_SCENE);
		msg1<<(uint16)srcSceneId<<x<<y<<(uint8)0<<(uint8)0;
		m_socketServer.SendMsg(sock,msg1);
		pUser->SetPos(x,y);
		pUser->SetFace(0);
		pUser->EnterScene(pScene);
	}
	else if(op == 6)	// 组队昆仑山数据更新,type=1历险点,2杀敌数,3杀怪数,4杀敌任务(index)完成标识,5杀怪任务(index)完成标志,6刷怪时间更新
	{

	}
}

void CPackageDeal::JingJieOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	if(!sSystemOpenCfgMananger.CheckSystemOpen(pUser, SOT_22))
		return;

	uint8 op=0;
	msg>>op;
	switch(op)
	{
		case 1:
			{
				// 服务器主动推送
			}
			break;
			/*case 2:
				{
					uint8 isShow = 0;
					msg>>isShow;
					bool show = (isShow == 1) ? true : false;
					pUser->ChangeJingJieNameShowState(show,msg);
				}
				break;
			case 3:
				{
					pUser->GetJingJieDailyAward();
				}
				break;*/
		case 4:
			{
				pUser->UpgradeJingJie();
			}
			break;
		default:break;
	}
}

void CPackageDeal::ChongZhiToOtherOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 op=0;
	msg>>op;

	SChongZhi2OtherAward data;
	{
		boost::recursive_mutex::scoped_lock lk(cz_fanli_mutex);
		if(G_CZ_TO_OTHER_INFO.empty())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0011,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}
	}
	data = G_CZ_TO_OTHER_INFO[0];

	if(op == 1)	// 获取代充面板信息
	{
		int itemId = 2919;
		msg<<PRO_SUCCESS<<data.RMB;
		uint8 selfAwardNum = 0;
		uint16 selfPos = msg.GetDataLen();
		msg<<selfAwardNum;
		for(int i=0;i < SChongZhi2OtherAward::AWARD_NUM;i++)
		{
			if(data.self_award[i] > 0 && data.self_num[i] > 0 && data.self_award[i] != itemId)
			{
				msg<<data.self_award[i]<<data.self_num[i];
				selfAwardNum++;
			}
		}
		uint8 otherAwardNum = 0;
		uint16 otherPos = msg.GetDataLen();
		msg<<otherAwardNum;
		for(int i=0;i < SChongZhi2OtherAward::AWARD_NUM;i++)
		{
			if(data.friend_award[i] > 0 && data.friend_num[i] > 0)
			{
				msg<<data.friend_award[i]<<data.friend_num[i];
				otherAwardNum++;
			}
		}
		msg.WriteData(selfPos,&selfAwardNum,sizeof(selfAwardNum));
		msg.WriteData(otherPos,&otherAwardNum,sizeof(otherAwardNum));
		m_socketServer.SendMsg(sock,msg);
	}
	else if(op == 2)	// 赠送好礼
	{
#ifdef KUA_FU
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0061,TIPS_FAILURE_COLOR);
		m_socketServer.SendMsg(sock,msg);
		return;
#endif

		uint32 toId = 0;
		uint32 itemId = 2919; //元宝赠礼道具
		string order;
		msg>>toId;

		if(toId == 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0061,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}

/*		if (! pUser->IsHot(toId))
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0051,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}
*/
		if (pUser->GetItemNum(itemId) <= 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0052,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}

		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		if(pDb == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0011,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}

		char sql[256];
		ShareUserPtr p = SingletonOnlineUser::instance().GetUserByRoleId(toId);
		CUser *pUser1 = p.get();
		if(pUser1 == NULL)
		{
			snprintf(sql,sizeof(sql)-1,"select kuafu_state from role_info where id = %d",toId);
			char **row = NULL;
			if(pDb->Query(sql) && (row = pDb->GetRow()) != NULL)
			{
				if (atoi(row[0]) == 1)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0057,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}
			}
			else
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0011,TIPS_FAILURE_COLOR);
				m_socketServer.SendMsg(sock,msg);
				return;
			}
		}

		snprintf(sql,sizeof(sql)-1,"insert into cz_to_other(user_id,role_id,to_id,orderNum,is_deal) values(%u,%u,%u,'%s',1)",pUser->GetUserId(),pUser->GetRoleId(),toId,order.c_str());
		if(pDb->Query(sql))
		{
			SaveUseItem(pUser->GetRoleId(),itemId,LANGUAGE_LLD_0055,1);
			pUser->DelPackageById(itemId,1);
			ChongZhiToOtherSendAward(pUser->GetRoleId(),toId,data);
			msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_LLD_0056,TIPS_WARNING_COLOR);;
		}
		else
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0011,TIPS_FAILURE_COLOR);
		}
		m_socketServer.SendMsg(sock,msg);
	}
}


#ifdef KUA_FU
void CPackageDeal::KuaFu_QueryBangPaiRet(CNetMessage *pMsg,int sock)
{
	GET_MSG
	uint8 op = 0;	// 1 查询角色帮派信息 2 查询帮派是否存在
	msg>>op;
	
	if(op == 1 || op == 3)
	{
		m_bangPaiMgr.KF_ReadBangPai(msg);
	}
	else if(op == 2)
	{
		uint32 serverId = 0;
		uint32 bangPaiId = 0;
		uint8 exist = 1;	// 1 存在 0 不存在
		msg>>serverId>>bangPaiId>>exist;
		if(bangPaiId == 0)
			return;
		if(exist == 0)
		{
			CBangPai *pBang = m_bangPaiMgr.FindBangPai(bangPaiId);
			if(pBang == NULL)
				return;
			pBang->DismissBang_updata();
		}
	}
}
#else
void CPackageDeal::KuaFu_QueryBangPai(CNetMessage *pMsg,int sock)
{
	GET_MSG
	const uint32 TIME_GAP = 60*10;
	static map<int,uint32> sendTimeMap;	// bangId,time

	uint8 op = 0;	// 1 查询角色帮派信息 2 查询帮派是否存在
	msg>>op;

	if(op == 1)
	{
		uint32 serverId = 0;
		uint32 roleId = 0;
		msg>>serverId>>roleId;

		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		if(pDb == NULL)
			return;
		char buf[256];
		snprintf(buf,sizeof(buf),"select bangpai_id,`rank` from bang_pai_role where role_id=%u",roleId);
		if(pDb->Query(buf))
		{
			char **row = pDb->GetRow();
			if(row == NULL)
			{
				msg<<0;
				m_socketServer.SendMsg(sock,msg);
				return;
			}
			int bangId = atoi(row[0]);
			if(bangId <= 0)
			{
				msg<<0;
				m_socketServer.SendMsg(sock,msg);
				return;
			}
			uint32 curTime = GetSysTime();
			map<int,uint32>::iterator it=sendTimeMap.begin();
			it = sendTimeMap.find(bangId);
			if(it == sendTimeMap.end())
			{
				sendTimeMap.insert(make_pair(bangId,curTime));
			}
			else
			{
				if((curTime - it->second) < TIME_GAP)
					return;
				else
					it->second = curTime;
			}

			CBangPai *pBang = m_bangPaiMgr.FindBangPai(bangId);
			if(pBang == NULL)
			{
				msg<<0;
				m_socketServer.SendMsg(sock,msg);
				return;
			}
			
			vector<int> serverIdList;
			GetServerIdList(serverIdList);
			if(serverIdList.empty())
				return;

			snprintf(buf,sizeof(buf)-1,"s%d.%s",serverIdList[0],pBang->GetName().c_str());
			msg<<bangId<<buf<<pBang->GetLevel()<<pBang->GetExp()<<pBang->GetGongGao()<<pBang->GetBZ_JiFen()<<pBang->GetHuoYue()<<pBang->GetAutoAcceptLv();
			pBang->MakeSkillInfo(msg);

			list<uint32> member;
			pBang->GetMember(member);

			uint32 numPos = msg.GetDataLen();
			uint8 num = 0;
			msg<<num;
			for(list<uint32>::iterator i = member.begin(); i != member.end(); i++)
			{
				SBangPaiMember memberInfo;
				pBang->GetMemberInfoById(*i,memberInfo);

				SRoleSimpleData data;
				if(!SingletonCSimpleRoleDataMgr::instance().GetRoleData(*i, data))
					continue;
				msg<<*i<<data.name<<data.level<<memberInfo.rank<<memberInfo.total_gongXian<<data.lastLoginTime;
				msg<<data.vipLv<<memberInfo.huoyue_day;
				num++;
			}
			msg.WriteData(numPos, &num, sizeof(num));
			m_socketServer.SendMsg(sock,msg);
		}
	}
	else if(op == 2)	// 查询帮派是否存在
	{
		uint32 serverId = 0;
		uint32 bangPaiId = 0;
		msg>>serverId>>bangPaiId;

		uint8 exist = 1;	// 1 存在 0 不存在
		if(bangPaiId == 0)
			return;
		CBangPai *pBang = m_bangPaiMgr.FindBangPai(bangPaiId);
		if(pBang == NULL)
			exist = 0;
		msg<<exist;
		m_socketServer.SendMsg(sock,msg);
	}
	else if(op == 3)
	{
		uint32 serverId = 0;
		uint32 bangId = 0;
		msg>>serverId>>bangId;

		CBangPai *pBang = m_bangPaiMgr.FindBangPai(bangId);
		if(pBang == NULL)
		{
			msg<<0;
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		
		vector<int> serverIdList;
		GetServerIdList(serverIdList);
		if(serverIdList.empty())
			return;
		msg.ReWrite();
		msg.SetType(MSG_SERVER_KF_BANG_PAI);
		msg<<op<<serverId<<0<<bangId;
		
		char buf[256];
		snprintf(buf,sizeof(buf)-1,"s%d.%s",serverIdList[0],pBang->GetName().c_str());
		msg<<buf<<pBang->GetLevel()<<pBang->GetExp()<<pBang->GetGongGao()<<pBang->GetBZ_JiFen()<<pBang->GetHuoYue()<<pBang->GetAutoAcceptLv();
		pBang->MakeSkillInfo(msg);

		list<uint32> member;
		pBang->GetMember(member);

		uint32 numPos = msg.GetDataLen();
		uint8 num = 0;
		msg<<num;
		for(list<uint32>::iterator i = member.begin(); i != member.end(); i++)
		{
			SBangPaiMember memberInfo;
			pBang->GetMemberInfoById(*i, memberInfo);
			
			SRoleSimpleData data;
			if(!SingletonCSimpleRoleDataMgr::instance().GetRoleData(*i, data))
				continue;
			msg<<*i<<data.name<<data.level<<memberInfo.rank<<memberInfo.total_gongXian<<data.lastLoginTime;
			msg<<data.vipLv<<memberInfo.huoyue_day;
			num++;
		}
		msg.WriteData(numPos, &num, sizeof(num));
		m_socketServer.SendMsg(sock,msg);
	}
}

void CPackageDeal::QueryKuaFuState(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 op = 0;	// 1 跨服状态
	msg>>op;
	
	if(op == 1)
	{
		uint8 state = IsOpenKuaFu() ? 1 : 0;
		msg<<state;
		m_socketServer.SendMsg(sock,msg);
	}
}

#endif

void CPackageDeal::RecvServerSysInfo(CNetMessage *pMsg,int sock)
{
	GET_MSG

#ifndef KUA_FU
	if(!IsOpenKuaFu())
		return;
#endif
	uint8 op = 0;
	msg>>op;
	switch(op)
	{
		case ECT_KuaFu:	// 跨服聊天 11
			{
				msg.SetType(PRO_MSG_CHAT);
				m_onlineUser.ForEachUser(boost::bind(&CPackageDeal::BroadcastChat,this,_1,&msg,0));
			}
			break;
		case ECT_KuaFuBroadCast:	// 跨服喇叭
			{
				uint32 roleId = 0;
				string name;
				uint8 vipLv = 0;
				uint8 xiang = 0;
				uint8 sex = 0;
				string message; 
				msg>>roleId>>name>>vipLv>>xiang>>sex>>message;
				if (roleId <= 0 || message.empty() || name.empty() || xiang == 0 || sex > 1)
					return;
				SysInfoToAllUserGunDong(roleId,name.c_str(),vipLv,xiang,sex,message.c_str());
			}
			break;
		case ECT_World_SameZone:	// 世界频道相同zoneId推送
			{
				int zoneId = 0;
				uint32 roleId = 0;
				string name;
				uint8 vipLv = 0;
				uint8 xiang = 0;
				uint8 sex = 0;
				string message;
				msg>>zoneId>>roleId>>name>>vipLv>>xiang>>sex>>message;

#ifndef KUA_FU
				if(GetSelfZoneId() != zoneId)
					return;
#endif

				//pUser->SetE
				CNetMessage omsg;
				omsg.SetType(PRO_MSG_CHAT);
				omsg<<(uint8)ECT_World<<roleId<<name<<vipLv<<xiang<<sex<<message;
				m_onlineUser.ForEachUser(boost::bind(&CPackageDeal::BroadcastChatByZoneId,this,_1,&omsg,roleId,zoneId));
			}
			break;
		default:
			return;
	}
}

void CPackageDeal::ServerNewShenQi(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

		/*if(pUser->GetLevel() < NEW_SHENQI_OPEN_LEVEL )
			return;*/
	uint8 op=0;
	msg>>op;
	switch(op)
	{
		case 1:
			{
				pUser->SendNewShenQiBaseInfo();
			}
			break;
		case 2:
			{
				int shenqi_id = 0;
				msg>>shenqi_id;
					pUser->ChangeNewShenQiCarryState(shenqi_id);
			}
			break;
		case 3:
			{
				pUser->SendNewShenQiEnhanceInfo();
			}
			break;
		case 4:
			{
				// CHECK_SYSTEM_OPEN(SOT_ShenQi_Jinjie)
				int item_id = 0;
				int item_num = 0;
				msg>>item_id>>item_num;
				pUser->EnhanceNewShenQi(item_id,item_num);
			}
			break;
		case 5:
			{
				msg.ReWrite();
				msg.SetType(MSG_NEW_SHENQI);
				msg<<(uint8)5<<pUser->GetNewShenQiCarryID();
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			break;
		case 6://激活神器
			{
				// CHECK_SYSTEM_OPEN(SOT_ShenQi_Shouji)
				int shenqi_id = 0;
				msg>>shenqi_id;
				pUser->ItemActiveNewShenQi(shenqi_id);
			}
			break;
		
		case 7:	// 获取玩家神器信息
			{
				uint32 roleId = 0;
				msg>>roleId;
				if(roleId == 0)
					return;
				ShareUserPtr other = m_onlineUser.GetUserByRoleId(roleId);
				if(other.get() == NULL)
				{
					CUser *pOther = new CUser;
					if(pOther == NULL)
						return;
					pOther->SetSock(-1);
					if(!pOther->CopyUserData(roleId))
					{
						delete pOther;
						return;
					}
					other.reset(pOther);
				}
				other->MakeNewShenQiBaseInfo(msg);
				m_socketServer.SendMsg(pUser->GetSock(),msg);
			}
			break;
		
		default:
			break;
	}
}

void CPackageDeal::ShenJieMiJingOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 op = 0;
	msg>>op;
	CShenJieMiJingManager& mgr = sCShenJieMiJingManager;
	switch (op)
	{
	case 1:
		mgr.JoinIn(pUser);
		break;
	case 2:
		mgr.GetSort(pUser);
		break;
	case 3:
		mgr.GetRoomInfo(pUser);
		break;
	case 4:
		//mgr.SwitchRoom(pUser);
		break;
	case 5:
		mgr.SendPanelInfo(pUser);
		break;
	case 10:
		// 复活
		break;
	case 11:
		mgr.SendBossHpInfoToUser(pUser);
		break;
	default:
		break;
	}
}
#ifdef KUA_FU
void CPackageDeal::KuaFu_BangZhan_Option(CNetMessage *pMsg,int sock)
{
	GET_MSG

	uint8 op = 0;
	msg>>op;
	if(op == 2)	// 每周一0点初始化帮战列表
	{
		int num = 0;
		msg>>num;
		vector<int> idList;
		for(int i=0;i < num;i++)
		{
			int serverId = 0;
			int bangId = 0;
			msg>>serverId>>bangId;
			if(bangId > 0 && serverId > 0)
			{
				QueryGameServer_BangPaiByBangId(serverId,bangId);
				idList.push_back(bangId);
			}
		}
		
		SingletonCBangPaiManager::instance().SetKuaFuBangList(idList);
	}
}

void CPackageDeal::QunXianZhengBaOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	{
		return;
	}

	uint8 op = 0;	// 1
	msg>>op;
	if(op == 0)
		return;

	CQunXianZhengBaManager &manager = SingletonCQunXianZhengBaManager::instance();
	if(op == 1)		// 获得活动主界面信息, 参加活动
	{
		MakeQunXianMsg(pUser,msg);
	}
	else if(op == 2)	// 点击角色
	{
		uint8 curFloor = pUser->GetExtData8(486);	// 0~60
		SQunXianZhengBaConig floorCF;
		manager.GetFloorConfig(curFloor+1,floorCF);
		if(floorCF.type != 1)
			return;
		SQunXianZhengBa_Role cf;
		manager.GetRoleCfgByIdx(floorCF.t_index,cf);
		if(cf.index == 0)
			return;
		uint32 s_roleId = pUser->GetExtData32(357);
		uint32 m_roleId = pUser->GetExtData32(358);
		uint32 h_roleId = pUser->GetExtData32(359);
		if(s_roleId == 0 || m_roleId == 0 || h_roleId == 0)
			return;
		msg<<(uint8)CQunXianZhengBaManager::SHOW_ROLE_NUM;
		
		SQunXianPowerPaiHang info;
		for(uint8 i=0;i < CQunXianZhengBaManager::SHOW_ROLE_NUM;i++)
		{
			uint32 roleId = 0;
			uint8 star = 0;
			if(i == 0)
			{
				star = cf.s_star;
				roleId = s_roleId;
			}
			else if(i == 1)
			{
				star = cf.m_star;
				roleId = m_roleId;
			}
			else
			{
				star = cf.h_star;
				roleId = h_roleId;
			}
			manager.GetRoleDataById(roleId,info);
			if(info.roleId == 0)
				return;
			msg<<info.roleId<<info.xiang<<info.sex<<info.name<<info.vipLv<<info.weapon<<star<<info.zhandouli;
		}
		m_socketServer.SendMsg(sock,msg);
	}
	else if(op == 3)	// 点击buff商店
	{
		uint8 curFloor = pUser->GetExtData8(486);	// 0~60
		uint8 buyFlag = pUser->GetExtData8(489);
		SQunXianZhengBaConig floorCF;
		manager.GetFloorConfig(curFloor+1,floorCF);
		if(floorCF.type != 2)
			return;
		msg<<(uint8)CQunXianZhengBaManager::SHOW_BUFF_NUM;

		SQunXianZhengBa_Buff data;
		manager.GetBuffCfgByIdx(floorCF.t_index,data);
		if(data.index == 0)
			return;
		msg<<data.type1<<(data.type1 >= 17 ? data.value1/100 : data.value1)<<data.star1<<(uint8)((buyFlag & (0x1<<0)) > 0 ? 1 : 0);
		msg<<data.type2<<(data.type2 >= 17 ? data.value2/100 : data.value2)<<data.star2<<(uint8)((buyFlag & (0x1<<1)) > 0 ? 1 : 0);
		msg<<data.type3<<(data.type3 >= 17 ? data.value3/100 : data.value3)<<data.star3<<(uint8)((buyFlag & (0x1<<2)) > 0 ? 1 : 0);
		m_socketServer.SendMsg(sock,msg);
	}
	else if(op == 4)	// 点击宝箱
	{
		uint8 curFloor = pUser->GetExtData8(486);	// 0~60
		SQunXianZhengBaConig floorCF;
		manager.GetFloorConfig(curFloor+1,floorCF);
		if(floorCF.type != 3)
			return;
		SQunXianZhengBa_Box box;
		manager.GetBoxCfgByIdx(floorCF.t_index,box);
		if(box.index == 0)
			return;
		
		int YB = 0;
		uint16 size = sizeof(box.YB)/sizeof(box.YB[0]);
		uint16 buyNum = pUser->GetExtData8(490);
		if(buyNum >= size)
			YB = box.YB[size-1];
		else
			YB = box.YB[buyNum];
		if(pUser->HaveBitSet(578))
		{
			msg<<(uint8)0<<YB;
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		
		pUser->SetBitSet(578);
		uint8 num = 0;
		uint16 pos = msg.GetDataLen();
		msg<<num;
		for(uint8 i=0;i < sizeof(box.freeItemId)/sizeof(box.freeItemId[0]);i++)
		{
			if(box.freeItemId[i] > 0 && box.freeNum[i] > 0)
			{
				if(box.freeItemId[i] == HDAT_MONEY)
					pUser->AddMoney(box.freeNum[i]);
				else if(box.freeItemId[i] == HDAT_BANG_YB)
					pUser->AddTongBao(box.freeNum[i],1);
				else if(box.freeItemId[i] == HDAT_YB)
					pUser->AddTongBao(box.freeNum[i]);
				else if(box.freeItemId[i] < HDAT_MONEY)
					pUser->AddBangDingPackage(box.freeItemId[i],box.freeNum[i]);
				else
					continue;
				num++;
				msg<<box.freeItemId[i]<<box.freeNum[i];
			}
		}
		msg<<YB;
		msg.WriteData(pos,&num,sizeof(num));
		m_socketServer.SendMsg(sock,msg);
	}
	else if(op == 5)	// 开始挑战
	{
		CScene *pScene = pUser->GetScene();
		if(pScene == NULL)
			return;
		
		uint8 fightIdx = 0;
		msg>>fightIdx;
		if(fightIdx >= CQunXianZhengBaManager::SHOW_ROLE_NUM)
			return;
		if(pUser->HaveTeam())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0102,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		if(pUser->GetFightId() > 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0103,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		uint8 curFloor = pUser->GetExtData8(486);	// 0~60
		SQunXianZhengBaConig floorCF;
		manager.GetFloorConfig(curFloor+1,floorCF);
		if(floorCF.type != 1)
			return;
		SQunXianZhengBa_Role cf;
		manager.GetRoleCfgByIdx(floorCF.t_index,cf);
		if(cf.index == 0)
			return;
		
		uint32 tarRoleId = 0;
		if(fightIdx == 0)
			tarRoleId = pUser->GetExtData32(357);
		else if(fightIdx == 1)
			tarRoleId = pUser->GetExtData32(358);
		else
			tarRoleId = pUser->GetExtData32(359);

		SQunXianPowerPaiHang info;
		manager.GetRoleDataById(tarRoleId,info);
		if(info.roleId == 0)
			return;
		
		ShareUserPtr ptrTar;
		CUser *pTar = new CUser;
		if(pTar == NULL)
			return;
		pTar->SetSock(-1);
		if(!pTar->CopyUserData(tarRoleId))
		{
			delete pTar;
			return;
		}
		ptrTar.reset(pTar);
		ShareFightPtr pFight = SingletonFightManager::instance().CreateFight();
		pFight->SetFightType(CFight::EFT_QunXianZhengBa);
		pFight->SetFightChooseMode();
//		pUser->QunXianInitPetBeforeFight();
		pFight->AddUserGroupToFight(ptr, CFight::EGT_GROUP2);
		pFight->AddUserGroupToFight(ptrTar);
		pFight->SetQunXianImageGain(3,fightIdx+1,(float)cf.gainRatio);
		pFight->BeginFight(pScene);
		SingletonFightManager::instance().AddFight(pFight);
	}
	else if(op == 6)	// 购买buff
	{
		uint8 buyIdx = 0xff;
		msg>>buyIdx;
		if(buyIdx >= CQunXianZhengBaManager::SHOW_BUFF_NUM && buyIdx != 0xff)
			return;
		uint8 curFloor = pUser->GetExtData8(486);	// 0~60
		SQunXianZhengBaConig floorCF;
		manager.GetFloorConfig(curFloor+1,floorCF);
		if(floorCF.type != 2)
			return;
		SQunXianZhengBa_Buff cf;
		manager.GetBuffCfgByIdx(floorCF.t_index,cf);
		if(cf.index == 0)
			return;
		if(buyIdx == 0xff)	// 关闭界面，进入下一层
		{
			msg<<PRO_SUCCESS<<(int)pUser->GetExtData16(59);
			m_socketServer.SendMsg(sock,msg);
			
			pUser->SetQunXianCurFloor(curFloor+1);
			SendQunXianMsg(pUser);
			return;
		}
		
		uint8 buyFlag = pUser->GetExtData8(489);
		if((buyFlag & (0x1<<buyIdx)) > 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0110,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}

		int haveStar = pUser->GetExtData16(59);
		int needStar = 0;
		int buffType = 0;
		int buffVal = 0;
		if(buyIdx == 0)
		{
			needStar = cf.star1;
			buffType = cf.type1;
			buffVal = cf.value1;
		}
		else if(buyIdx == 1)
		{
			needStar = cf.star2;
			buffType = cf.type2;
			buffVal = cf.value2;
		}
		else
		{
			needStar = cf.star3;
			buffType = cf.type3;
			buffVal = cf.value3;
		}
		if(haveStar < needStar)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0101,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}

		buyFlag |= 0x1<<buyIdx;
		pUser->SetExtData8(489,buyFlag);
		pUser->SetExtData16(59,haveStar-needStar);
		pUser->AddQunXianBufferState(buffType,buffVal);
		msg<<PRO_SUCCESS<<(haveStar-needStar);
		m_socketServer.SendMsg(sock,msg);
	}
	else if(op == 7)	// 用元宝开宝箱
	{
		if(!pUser->HaveBitSet(578))
			return;
		uint8 useYB = 0;	// 0取消1花元宝开宝箱
		msg>>useYB;

		uint8 curFloor = pUser->GetExtData8(486);	// 0~60
		SQunXianZhengBaConig floorCF;
		manager.GetFloorConfig(curFloor+1,floorCF);
		if(floorCF.type != 3)
			return;
		if(useYB == 0)	// 取消
		{
			msg<<PRO_SUCCESS;
			m_socketServer.SendMsg(sock,msg);
			
			pUser->SetQunXianCurFloor(curFloor+1);
			SendQunXianMsg(pUser);
		}
		else	// 花元宝
		{
			SQunXianZhengBa_Box box;
			manager.GetBoxCfgByIdx(floorCF.t_index,box);

			int YB = 0;
			uint16 size = sizeof(box.YB)/sizeof(box.YB[0]);
			uint16 buyNum = pUser->GetExtData8(490);
			if(buyNum >= size)
				YB = box.YB[size-1];
			else
				YB = box.YB[buyNum];
			if(pUser->GetTongBao() < YB)
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0100,TIPS_FAILURE_COLOR);
				m_socketServer.SendMsg(sock,msg);
				return;
			}
			else
			{
				pUser->AddTongBao(-YB);
				buyNum++;
				pUser->SetExtData8(490,buyNum);

				msg<<PRO_SUCCESS;
				uint8 num = 0;
				uint16 pos = msg.GetDataLen();
				msg<<num;

				const int GET_NUM = 2;
				int itemId[GET_NUM] = {0,0};
				int itemNum[GET_NUM] = {0,0};
				int quality[GET_NUM] = {0,0};
				int findNum = 0;
				for(uint8 j=0;j < 10;j++)
				{
					int r = Random(1,10000);
					for(uint8 i=0;i < sizeof(box.YB_Item)/sizeof(box.YB_Item[0]);i++)
					{
						if(r < box.ratio[i])
						{
							if(box.YB_Item[i] > 0 && box.YB_Num[i] > 0)
							{
								bool isSame = false;
								for(int k=0;k < findNum;k++)
								{
									if(itemId[k] == box.YB_Item[i] && itemNum[k] == box.YB_Num[i])
									{
										isSame = true;
										break;
									}
								}
								if(!isSame)
								{
									itemId[findNum] = box.YB_Item[i];
									itemNum[findNum] = box.YB_Num[i];
									quality[findNum] = box.quality[i];
									findNum++;
									break;
								}
							}
						}
					}
					if(findNum >= GET_NUM)
						break;
				}

				num = findNum;
				for(int i=0;i < findNum;i++)
				{
					if(itemId[i] == HDAT_MONEY)
						pUser->AddMoney(itemNum[i]);
					else if(itemId[i] == HDAT_BANG_YB)
						pUser->AddTongBao(itemNum[i],1);
					else if(itemId[i] == HDAT_YB)
						pUser->AddTongBao(itemNum[i]);
					else if(itemId[i] < HDAT_MONEY)
						pUser->AddBangDingPackage(itemId[i],itemNum[i]);
					else
						continue;
					msg<<itemId[i]<<itemNum[i]<<(uint8)quality[i];
				}
				msg.WriteData(pos,&num,sizeof(num));
				if(buyNum >= size)
					YB = box.YB[size-1];
				else
					YB = box.YB[buyNum];
				msg<<YB;
				m_socketServer.SendMsg(sock,msg);
			}
		}
	}
	else if(op == 8)	// 首通奖励界面信息
	{
		uint8 maxFloor = pUser->GetExtData8(488);
		msg<<maxFloor;
		
		uint8 num = 0;
		uint16 pos = msg.GetDataLen();
		msg<<num;
		for(int f=1;f <= CQunXianZhengBaManager::MAX_FLOOR;f++)
		{
			SQunXianZhengBaConig floorCF;
			manager.GetFloorConfig(f,floorCF);
			if(floorCF.type == 1)
			{
				SQunXianZhengBa_Role role;
				manager.GetRoleCfgByIdx(floorCF.t_index,role);
				if(role.index == 0)
					continue;
				num++;
				msg<<(uint8)f<<role.itemId<<role.itemNum<<role.YB;

				uint8 getType = 1;	// 1已领取2可领取3不可领取
				if((int)maxFloor < f)
					getType = 3;
				else
				{
					uint8 awardIdx = num;
					if(pUser->HaveGetQunXianAward(awardIdx))
						getType = 1;
					else
						getType = 2;
				}
				msg<<getType;
			}
		}
		msg.WriteData(pos,&num,sizeof(num));
		m_socketServer.SendMsg(sock,msg);
	}
	else if(op == 9)	// 领取首通奖励
	{
		uint8 sel_floor = 0;
		msg>>sel_floor;
		if(sel_floor == 0)
			return;
		SQunXianZhengBaConig floorCF;
		manager.GetFloorConfig(sel_floor,floorCF);
		if(floorCF.type == 1)
		{
			uint8 maxFloor = pUser->GetExtData8(488);
			if(sel_floor > maxFloor)
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0104,TIPS_FAILURE_COLOR);
				m_socketServer.SendMsg(sock,msg);
				return;
			}
			int awardIdx = GetQunXianAwardIdx(sel_floor);
			if(awardIdx < 1)
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0104,TIPS_FAILURE_COLOR);
				m_socketServer.SendMsg(sock,msg);
				return;
			}
			SQunXianZhengBa_Role role;
			manager.GetRoleCfgByIdx(floorCF.t_index,role);
			if(role.index == 0)
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0104,TIPS_FAILURE_COLOR);
				m_socketServer.SendMsg(sock,msg);
				return;
			}
			if(role.itemId == HDAT_MONEY)
				pUser->AddMoney(role.itemNum);
			else if(role.itemId == HDAT_BANG_YB)
				pUser->AddTongBao(role.itemNum,1);
			else if(role.itemId == HDAT_YB)
				pUser->AddTongBao(role.itemNum);
			else if(role.itemId < HDAT_MONEY)
				pUser->AddBangDingPackage(role.itemId,role.itemNum);
			else
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0104,TIPS_FAILURE_COLOR);
				m_socketServer.SendMsg(sock,msg);
				return;
			}

			pUser->SetQunXianAwardFlag(awardIdx);
			msg<<PRO_SUCCESS;
		}
		else
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0104,TIPS_FAILURE_COLOR);
		}
		m_socketServer.SendMsg(sock,msg);
	}
	else if(op == 10)	// 排行榜
	{
		manager.MakeRoleFloorHaiHang(msg);
		m_socketServer.SendMsg(sock,msg);
	}
	else if(op == 11)	// 重置
	{
		int curFloor = pUser->GetExtData8(486);
		if(curFloor == 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0107,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		int times = pUser->GetExtData8(485);
		if(times >= 1)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0108,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		msg<<PRO_SUCCESS;
		m_socketServer.SendMsg(sock,msg);

		pUser->SetExtData8(485,1);
		pUser->SetExtData8(487,curFloor);
		pUser->SetExtData8(486,0);
		pUser->ResetQunXianData();
		SendQunXianMsg(pUser);
		pUser->SendQunXianPetList();
	}
	else if(op == 12)	// 跳过层
	{
		int curFloor = pUser->GetExtData8(486);
		int lastMaxFloor = pUser->GetExtData8(487);
		int jumpMaxFloor = lastMaxFloor/2;
		if(jumpMaxFloor == 0 || jumpMaxFloor <= curFloor)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0109,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		msg<<PRO_SUCCESS;
		m_socketServer.SendMsg(sock,msg);
		
		int curStar = pUser->GetExtData16(59);
		int totalStar = pUser->GetExtData16(58);

		pUser->SetQunXianCurFloor(jumpMaxFloor);
		for(int i=curFloor+1;i <= jumpMaxFloor;i++)
		{
			SQunXianZhengBaConig floorCf;
			manager.GetFloorConfig(i,floorCf);
			if(floorCf.type == 1)	// 玩家
			{
				SQunXianZhengBa_Role cf;
				manager.GetRoleCfgByIdx(floorCf.t_index,cf);
				if(cf.index == 0)
					continue;
				curStar += cf.h_star;
				totalStar += cf.h_star;
			}
		}
		pUser->SetExtData16(59,curStar);
		pUser->SetExtData16(58,totalStar);
		SendQunXianMsg(pUser);
	}
	else if(op == 13)	// 设置参加神将
	{
		if(pUser->HaveBitSet(570))
			return;
		uint16 petId[CUser::MAX_QX_PET_NUM];
		memset(petId,0,sizeof(petId));
		uint8 num = 0;
		msg>>num;
		if(num > (uint8)CUser::MAX_QX_PET_NUM)
			return;
		for(uint8 i=0;i < num;i++)
			msg>>petId[i];
		if(!pUser->SetQunXianPets(petId,num))
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0104,TIPS_FAILURE_COLOR);
		else
		{
			pUser->SetBitSet(570);
			msg<<PRO_SUCCESS;
		}
		m_socketServer.SendMsg(sock,msg);

		pUser->SendQunXianPetList();
	}
	else if(op == 14)	// 神将出战，下阵协议
	{
		uint8 type = 0;	// 0出战 1下阵
		uint16 petId = 0xff;
		uint8 zhanweiPos = 0xff;
		msg>>type>>petId>>zhanweiPos;
		pUser->SetQunXianPetChuZhan(type,petId,zhanweiPos,msg);
		m_socketServer.SendMsg(sock,msg);
	}
	else if(op == 15)	// 获得参加神将列表
	{
		pUser->SendQunXianPetList();
	}
	else if(op == 16)	// 规则
	{
		const char *desc = "aaaaaaa";
		msg<<desc;
		m_socketServer.SendMsg(sock,msg);
	}
	else if(op == 17)	// 获得所有buff状态
	{
		pUser->MakeQunXianBuffMsg(msg);
		m_socketServer.SendMsg(sock,msg);
	}
}

#endif

void CPackageDeal::ServerHuoDongMoneyGiftBag(CNetMessage *pMsg,int sock)
{
#ifdef KUA_FU
	return;
#endif
	GET_MSG
	GET_USER

	uint8 op = 0;
	msg>>op;
	if(op == 1)
	{
		SingletonCHuoDongMoneyGiftBag::instance().SendIconInfo(pUser);
	}
	else if(op == 2)	//请求所有活动信息
	{
		msg.ReWrite();
		msg.SetType(MSG_KOREA_MONEY_GIFT);
		msg<<(uint8)2;
		SingletonCHuoDongMoneyGiftBag::instance().MakeHuoDongList(msg);
		m_socketServer.SendMsg(sock,msg);
	}
	else if(op == 3)//请求活动详细信息
	{
		int hd_type = 0;
		msg>>hd_type;
		msg.ReWrite();
		msg.SetType(MSG_KOREA_MONEY_GIFT);
		msg<<(uint8)3;
		SingletonCHuoDongMoneyGiftBag::instance().MakeHuoDongDeatilInfo(msg,hd_type,pUser);
		m_socketServer.SendMsg(sock,msg);
	}
	else if(op == 4) //请求验证购买限制
	{
		int hd_type = 0;
		int gift_id = 0;
		msg>>hd_type>>gift_id;
		SingletonCHuoDongMoneyGiftBag::instance().ReqCheckBuyLimit(pUser,hd_type,gift_id);
	}
}

void CPackageDeal::ServerTransFormOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 op = 0;
	msg>>op;
	switch(op)
	{
		case 1: //请求拥有的卡片信息 
			{
				pUser->SendTransFormCardInfo();
			}
			break;
		case 2: //请求当前变身的信息和时间
			{
				pUser->SendCurTransFormTimeInfo();
			}
			break;
		case 3: //使用变身卡
			{
				int item_id = 0;
				int type = 0;
				msg>>type>>item_id;
				if( type == 1 )
				{
					if(!pUser->CoverCurTransFormCheck(item_id))
						pUser->ActiveTransForm(item_id);
				}
				else if( type == 2 )
				{
					pUser->ActiveTransForm(item_id);
				}
			}
			break;
		case 4: //清除变身
			{
				pUser->ClearTransForm();
			}
			break;
		case 10:	// 显示
			{
				if(!pUser->HaveBitSet(600))
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0254,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}
				pUser->ClearBitSet(600);
				msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_SSJ_0255,TIPS_WARNING_COLOR);
				m_socketServer.SendMsg(sock,msg);

				CScene *pScene = pUser->GetScene();
				if(pScene != NULL)
					pScene->UpdateUserInfo(pUser,ESRT_TransormShape);
			}
			break;
		case 11:	// 隐藏
			{
				if(pUser->HaveBitSet(600))
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0256,TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(sock,msg);
					return;
				}
				pUser->SetBitSet(600);
				msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_SSJ_0257,TIPS_WARNING_COLOR);
				m_socketServer.SendMsg(sock,msg);

				CScene *pScene = pUser->GetScene();
				if(pScene != NULL)
					pScene->UpdateUserInfo(pUser,ESRT_TransormShape);
			}
			break;
		default:
			break;
	}
}

void CPackageDeal::SendWeiXinReward(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER
	const uint32 award[][3] = {{0,0,0},{565,60001,100},{567,0,0},{568,0,0},{571,60001,100},{572,2386,1},{573,2386,1},{0,0,0},{574,2386,1},{0,0,0},{575,60001,100},{576,60001,100}};
	uint8 type = 0;
	msg>>type;

	if (type > WXS_NUM || type >= sizeof(award)/sizeof(award[0]))
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0034,TIPS_FAILURE_COLOR);
		m_socketServer.SendMsg(pUser->GetSock(),msg);
		return;
	}

	string saveStr;
	string message;
	switch(type)
	{
		case WXS_ChongWuShop:
		case WXS_ServerList:	//服务器列表
		case WXS_TongTianTa:	//通天塔成功通关
		case WXS_FuBen:			//副本成功通关
		case WXS_PlayerAttr:	//人物属性
		case WXS_YunBiao:		//运镖结束
		case WXS_PetInfo:		//神将信息页
		case WXS_XianYuanCard:	//仙缘卡抽取
		case WXS_PurplePet:		//副本获得紫神将
			{
#ifdef KUA_FU
				if (type == WXS_ServerList)
					return;
#endif
				int bitset = award[type][0];
				if (bitset > 0 && ! pUser->HaveBitSet(bitset))
				{
					pUser->SetBitSet(bitset);
					saveStr = SendWinXinShareMail(pUser,award[type][1],award[type][2]);
				}
			}
			break;
		case WXS_Arena:
			{
				int bitset = award[type][0];
				int arenCount = pUser->GetExtData8(47);
				if (bitset > 0 && arenCount != 0 && ! pUser->HaveBitSet(bitset))
				{
					pUser->SetBitSet(bitset);
					message = MakeStringColor(LANGUAGE_LLD_0059,TIPS_WARNING_COLOR);
					saveStr = message;
				}
			}
			break;
#ifdef KUA_FU
		case WXS_WeiWoDuXian:
			{


				int bitset = award[type][0];
				if (bitset > 0 && pUser->GetKuaFu1vs1PreliminaryUsedChallengueNum() < MAX_CHALLENGUE_NUM && ! pUser->HaveBitSet(bitset))
				{
					pUser->SetBitSet(bitset);
					message = MakeStringColor(LANGUAGE_LLD_0060,TIPS_WARNING_COLOR);
					pUser->SetKuaFu1vs1PreliminaryUsedChallengueNum(pUser->GetKuaFu1vs1PreliminaryUsedChallengueNum()-1);

					CNetMessage newMsg;
					newMsg.SetType(MSG_KUA_FU_1V1);
					newMsg<<(uint8)6<<(int)(MAX_CHALLENGUE_NUM-pUser->GetKuaFu1vs1PreliminaryUsedChallengueNum())<<MAX_CHALLENGUE_NUM;
					newMsg<<SingletonCKuaFu1vs1PreliminaryManager::instance().GetAddChallengeNumSpendYB(pUser->GetKuaFu1vs1PreliminaryUsedChallengueTotalNum());
					SingletonSocket::instance().SendMsg(pUser->GetSock(),newMsg);
					saveStr = message;
				}
			}
			break;
#endif
		default:
			return;
	}

	SaveDate(pUser->GetRoleId(),46,type,saveStr.c_str());

	msg<<PRO_SUCCESS<<message;
	/*if (type == WXS_Arena)
		msg<<(uint8)(pUser->GetArenaFightMaxNum() - pUser->GetExtData8(47));*/
	m_socketServer.SendMsg(pUser->GetSock(),msg);
}

void CPackageDeal::ServerIgnoreQieCuo(CNetMessage *pMsg,int sock) 
{
    GET_MSG
    GET_USER

    uint8 op = 0;
    msg>>op;
    pUser->SetIgnoreQieCuo(op);
}

void CPackageDeal::ServerIgnoreFunc(CNetMessage *pMsg,int sock) 
{
    GET_MSG
    GET_USER

    uint8 type = 0;
	uint8 flag = 0;	// 1开启2关闭
    msg>>type>>flag;
	if(type == 1)	// vip
	{
	    pUser->SetIgnoreVip(flag);
	}

	CScene *pScene = pUser->GetScene();
	if(pScene == NULL)
		return;
	pScene->UpdateUserInfo(pUser,ESRT_Vip);
}


void CPackageDeal::GetMianZhanPaiCD(CNetMessage *pMsg,int sock)
{
	GET_USER
	SendMianZhanPaiCD(pUser);
}

void CPackageDeal::PK_Notice_Option(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 op = 0;
	msg>>op;
	if(op == 2)	// 设置开关状态
	{
		uint8 state = 0;
		msg>>state;

		if(state == 1)	// 不显示
			pUser->SetBitSet(594);
		else
			pUser->ClearBitSet(594);
		msg<<PRO_SUCCESS;
		m_socketServer.SendMsg(sock,msg);
	}
	else if(op == 3)	// 请求开关状态
	{
		uint8 state = (pUser->HaveBitSet(594) ? 1 : 0);
		msg<<state;
		m_socketServer.SendMsg(sock,msg);
	}
}

void CPackageDeal::SysGongGaoOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	string str;
	msg>>str;
	SysInfoToAllUser(str.c_str());
}

void CPackageDeal::FlowerOption(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 op=0;
	msg>>op;

	if(op == 1)	// 获取鲜花商店列表(弃用)
	{
		SingletonShopManager::instance().ShowFlowerShopItems(pUser,msg);
	}
	else if(op == 2)	// 购买鲜花
	{
		int itemId = 0;
		int buy_num = 0;
		msg>>itemId>>buy_num;
		SingletonShopManager::instance().BuyFlower(pUser,itemId,buy_num,msg);
	}
	else if(op == 3)	// 获取已有鲜花列表
	{
		SingletonShopManager::instance().ShowSelfFlower(pUser,msg);
	}
	else if(op == 4)	// 赠送鲜花
	{
		uint16 itemId=0;
		uint16 num = 0;
		uint32 roleId = 0;
		msg>>itemId>>num>>roleId;
		if(SingletonShopManager::instance().SendFlowerToFriend(pUser,itemId,num,roleId,msg))
		{
			m_socketServer.SendMsg(sock,msg);
			ShowSpecialCartoon(1,itemId);
		}
	}
	else if(op == 5)	// 获取赠送记录
	{
		uint8 type = 0;	// 1赠送 2受赠
		msg>>type;
		if(type == 0 || type > 2)
			return;
		if(SingletonCHuoDongAwardManager::instance().GetMeilLiSendLog(pUser->GetRoleId(),type,msg))
		{
			m_socketServer.SendMsg(sock,msg);
		}
	}
	else if(op == 6)	// 获取魅力排行榜
	{
		SingletonShopManager::instance().ShowHistoryPaiHang(pUser,msg);
		m_socketServer.SendMsg(sock,msg);
	}
	else if(op==7)   //获取鲜花商店OR节日赠送道具列表
	{
		SingletonShopManager::instance().RequestFlowerShopAndSelfFlower(pUser);
	}
	else if(op == 8)    //节日活动赠送
	{
		uint16 itemId=0;
		uint16 num = 0;
		uint32 roleId = 0;
		msg>>itemId>>num>>roleId;
		if(SingletonCHuoDongAwardManager::instance().SendItemToFriend(pUser,itemId,num,roleId,msg))
		{
			m_socketServer.SendMsg(sock,msg);
		}
	}
}

void CPackageDeal::RealNameReg_Option(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

	uint8 op = 0;
	msg>>op;

	if(op == 1)	// 实名
	{
		string personal_name,personal_id;
		msg>>personal_name>>personal_id;

		if(pUser->IsRealNameRegistration())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0217,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		if(personal_name.empty() || personal_id.empty())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0218,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		if(!CheckPersonalName(personal_name))
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0219,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		if(!CheckPersonalID(personal_id.c_str()))
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0220,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		
		CDatabaseSql *pDb = GetLoginDb();
		if(pDb == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0104,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		
		char sql[256];
		snprintf(sql,sizeof(sql)-1,"update user_info set personal_name='%s',personal_id='%s' where id=%u",personal_name.c_str(),personal_id.c_str(),pUser->GetUserId());
		if(!pDb->Query(sql))
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0104,TIPS_FAILURE_COLOR);
		else
		{
			msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_SSJ_0221,TIPS_SUCCESS_COLOR);
			pUser->SetPersonalID(personal_id);
		}
		m_socketServer.SendMsg(sock,msg);
	}
	else if(op == 2)	// 绑定账号
	{
		string name,pwd;
		msg>>name>>pwd;

		if(pUser->GetAccountBinding() != 1)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0012,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		
		uint16 nameLen = name.size();
		uint16 pwdLen = pwd.size();
		if(nameLen < 6 || nameLen > 11)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0008,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		if(pwdLen < 6 || pwdLen > 13)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0015,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		if(!CheckPass((char *)name.c_str()))
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0009,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}

		if(!CheckPass((char *)pwd.c_str()))
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0010,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}

		uint32 uid = pUser->GetUserId();
		CDatabaseSql *pDb = GetLoginDb();
		if(pDb == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0104,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}

		uint32 curTime = GetSysTime();
		string oldName;
		pUser->GetAccountName(oldName);

		char sql[255];
		snprintf(sql,sizeof(sql),"update user_info set name='%s',password=md5('%s'),binding='%d' where id='%u'",name.c_str(),pwd.c_str(),0,uid);
		if(!pDb->Query(sql))
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0013,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}

		pUser->SetAccountName(name.c_str());
		pUser->SetAccountBinding(0);
		snprintf(sql,sizeof(sql),"insert binding_log (`id`,`from_name`,`to_name`,`time`) values ('%d','%s','%s',from_unixtime(%u))",uid,oldName.c_str(),name.c_str(),curTime);
		pDb->Query(sql);
		msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_LLD_0014,TIPS_FAILURE_COLOR);
		m_socketServer.SendMsg(sock,msg);
	}
}


void CPackageDeal::ServerJiaoYiHang(CNetMessage *pMsg,int sock)
{
	GET_MSG
	GET_USER

#ifdef KUA_FU
	msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0126,TIPS_FAILURE_COLOR);
	m_socketServer.SendMsg(pUser->GetSock(),msg);
	return;
#endif

	if (! SingletonCFunctionSwitchManager::instance().IsFunctionSwitchActivity(CFunctionSwitchManager::JIAOYI_SHOP))
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0126,TIPS_FAILURE_COLOR);
		m_socketServer.SendMsg(pUser->GetSock(),msg);
		return;
	}


    uint8 op = 0;
    msg>>op;
	if (op == 1) // 元宝购买界面
	{
		msg<<PRO_SUCCESS;
		
		msg<<LANGUAGE_LLD_0118;
		SingletonCJiaoYiHangManager::instance().ShowJiaoYiInfo(msg);
	}
	else if (op == 2) //元宝购买
	{
		int id = 0;
		int yb = 0;
		msg>>id;
		msg>>yb;

		SingletonCJiaoYiHangManager::instance().JiaoYiBuyYB(pUser,id,yb,msg);
	}
	else if (op == 3) // 元宝寄卖界面
	{
		msg<<PRO_SUCCESS;
		msg<<SingletonCJiaoYiHangManager::instance().GetJiaoYiGoldYuZhi();
		msg<<LANGUAGE_LLD_0119;
		SingletonCJiaoYiHangManager::instance().ShowJiaoYiInfo(msg,pUser->GetRoleId());
	}
	else if (op == 4)  // 元宝寄卖
	{
		int yb = 0;
		int gold = 0;
		msg>>yb>>gold;
		SingletonCJiaoYiHangManager::instance().AddJiaoYiInfo(pUser,yb,gold,msg);
	}
	else if (op == 5)  // 取消寄卖
	{
		int id = 0;
		msg>>id;
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0255,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(sock,msg);
			return;
		}
		SingletonCJiaoYiHangManager::instance().ChannelJiaoYiInfo(pUser,id,msg);
	}
	else if (op == 6) // 交易记录
	{
		msg<<PRO_SUCCESS;
		pUser->InitJiaoYiHangRecord();
		pUser->MakeJiaoYiHangRecord(msg);
	}
	
	m_socketServer.SendMsg(pUser->GetSock(),msg);
}

void CPackageDeal::GetMissonAward( CNetMessage *pMsg,int sock){
	GET_MSG
	GET_USER
	uint16 missionId = 0;
	msg>>missionId;
	SingletonCMissionManager::instance().GetMissionAward(pUser,missionId);
}

void CPackageDeal::QueryOnlineAward(CUser* pUser, CNetMessage& msg, int sock){
	if (pUser->m_zaiXianLingHaoLiTime == 0){
		pUser->m_zaiXianLingHaoLiTime = GetSysTime();
	}
	uint32_t sumt = pUser->GetExtData32(450);
	sumt = sumt + (GetSysTime() - pUser->entergametime_);
	uint32_t idx = pUser->GetExtData32(451);
	msg << (uint8)idx << sumt;
	m_socketServer.SendMsg(pUser->GetSock(), msg);
	//static uint8 sec = 60;
	//uint32_t as = pUser->GetExtData32(451); // 每个阶段的领奖状态 1 领奖 0 未领奖
	//uint32_t cs = 0;  // 当前应该领奖的阶段
	//uint32_t as5 = 0;  // 等待
	//uint32_t as10 = 0; 
	//uint32_t as15 = 0; 
	//uint32_t as20 = 0; 

	//int tick = 0; // 下次可以领奖时间
	//uint32_t endtime = pUser->GetExtData32(452); // 当前奖励的剩余时间
	//if( !(as & 1)){
	//	uint32 mytick = 5 * sec;
	//	as5 = 1;    // 倒计时状态
	//	if(sumt >= mytick){
	//		as5 = 2; // 领奖	
	//	}else{
	//		if(endtime != 0){
	//			if(endtime - sumt > 0 ){
	//				tick = mytick - sumt;
	//				cs = 5;
	//			}else{
	//				as5 = 2;
	//			}
	//		}else{
	//			endtime = sumt + mytick;
	//			pUser->SetExtData32(452, endtime);
	//			tick = mytick;
	//			cs = 5;
	//		}
	//	}
	//}

	//if( (as & 1) && !(as & 2) ){
	//	as5 = 3; // 领过
	//	as10 = 1; 
	//	uint32 mytick = 10 * sec;
	//	if(sumt >= mytick){
	//		as10 = 2; 
	//	}else{
	//		if(endtime != 0){
	//			if(endtime - sumt > 0 ){
	//				tick = mytick - sumt;
	//				cs = 10;
	//			}else{
	//				as10 = 2;
	//			}
	//		}else{
	//			endtime = sumt + mytick;
	//			pUser->SetExtData32(452, endtime);
	//			tick = mytick;
	//			cs = 10;
	//		}
	//	}
	//}

	//if( (as & 1) && (as & 2) && !(as & 4)){
	//	as5 = 3;  // 领过
	//	as10 = 3; // 领过

	//	as15 = 1;
	//	uint32 mytick = 15 * sec;
	//	if(sumt >= mytick ){
	//		as15 = 2;
	//	}else{
	//		if(endtime != 0){
	//			if(endtime - sumt > 0 ){
	//				tick = mytick - sumt;
	//				cs = 15;
	//			}else{
	//				as15 = 2;
	//			}
	//		}else{
	//			endtime = sumt + mytick;
	//			pUser->SetExtData32(452, endtime);
	//			tick = mytick;
	//			cs = 15;
	//		}
	//	}
	//}

	//if( (as & 1) && (as & 2) && (as & 4) && !(as & 8) ){
	//	as5 = 3;
	//	as10 = 3;
	//	as15 = 3;
	//	as20 = 1;
	//	uint32 mytick = 20 * sec;
	//	if(sumt >= mytick){
	//		as20 = 2;
	//	}else{
	//		if(endtime != 0){
	//			if(endtime - sumt > 0){
	//				tick = mytick - sumt;
	//				cs = 20;
	//			}else{
	//				as20 = 2;
	//			}
	//		}else{
	//			endtime = sumt + mytick;
	//			pUser->SetExtData32(452, endtime);
	//			tick = mytick;
	//			cs = 20;
	//		}
	//	}
	//}

	//if( (as & 1) && (as & 2) && (as & 4) && (as & 8) ){
	//	cs = 10000;
	//	as5 = 3;
	//	as10 = 3;
	//	as15 = 3;
	//	as20 = 3;
	//}


	//msg<<PRO_SUCCESS;
	//msg<<(uint8)4;      // 数量
	//msg<<(uint8)cs;     // 当前进入倒计时的
	//msg<<(uint8)0<<(uint32)5<<(uint8)size<<tick<<AWARD_LIST_ONLINE[0][0]<<AWARD_LIST_ONLINE[0][1]<<as5;
	//msg<<(uint8)1<<(uint32)10<<(uint8)size<<tick<<AWARD_LIST_ONLINE[1][0]<<AWARD_LIST_ONLINE[1][1]<<as10;
	//msg<<(uint8)2<<(uint32)15<<(uint8)size<<tick<<AWARD_LIST_ONLINE[2][0]<<AWARD_LIST_ONLINE[2][1]<<as15;
	//msg<<(uint8)3<<(uint32)20<<(uint8)size<<tick<<AWARD_LIST_ONLINE[3][0]<<AWARD_LIST_ONLINE[3][1]<<as20;
	//m_socketServer.SendMsg(pUser->GetSock(), msg);
}

void CPackageDeal::GetOnlineAward(CUser* pUser, CNetMessage& msg)
{
	uint32_t idx = pUser->GetExtData32(451);
	OnlineRewardCfg* cfg = sAwardManager.GetOnlineRewardCfg(idx + 1);
	if (cfg == NULL)
		return;
	uint32_t curSec = pUser->GetExtData32(450);
	curSec += (GetSysTime() - pUser->entergametime_);
	if (curSec < cfg->sec)
	{
		msg << PRO_ERROR << MakeStringColor("领奖失败", TIPS_FAILURE_COLOR);
		return;
	}
	msg << PRO_SUCCESS;
	pUser->SetExtData32(450, 0);             // 今日在线累计 秒
	pUser->SetExtData32(451, idx + 1);
	pUser->entergametime_ = GetSysTime();
	pUser->AddMaterial(cfg->reward);
	m_socketServer.SendMsg(pUser->GetSock(), msg);
}

void CPackageDeal::MatchResult(CNetMessage *pMsg, int sock)
{
	GET_MSG

	if (!m_socketServer.IsServer(sock))
		return;
	uint32 roleId;
	uint8 op;
	uint32 power;
	msg >> op;
	switch (op)
	{
	case 2:
	{
		int percent;
		msg >> roleId >> power >> percent;
		CUser *pUser = m_onlineUser.GetUserByRoleId(roleId).get();
		if (pUser == NULL)
			return;
		CXunBaoManage& manage = pUser->GetXunbaoManage();
		manage.CreateMap();
		manage.LoadMatchFights(msg);
		manage.NotifyMapInfo();
	}
	break;
	case 3:
	{
		uint32 returnId;
		uint32 returnPower;
		string name;
		uint16 level;
		uint8 head;
		msg >> roleId >> power >> returnId;
		if (returnId == 0)
		{
			CUser robot;
			robot.CopyUserData(Random(1, 20), 1);
			returnId = robot.GetRoleId();
			level = robot.GetLevel();
			head = robot.GetHead();
			name = robot.GetName();
		}
		else
		{
			msg >> returnPower >> name >> level >> head;
		}
		CUser *pUser = m_onlineUser.GetUserByRoleId(roleId).get();
		if (pUser == NULL)
			return;
		pUser->SetExtData32(453, returnId);
//		pUser->SetExtData32(454, xiang);
		uint8 floor = pUser->GetExtData8(136);
		if (floor == 0)
		{
			pUser->AddYingYongShiLianNpc();
		}
	}
	break;
	case 4:
	{
		static int pos[][2] = { { 2660,1969 }, { 2358,1290 }, { 3625,1557 } };
		static int maxPosCnt = sizeof(pos) / (sizeof(int) * 2);
		uint32 returnId;
		uint32 returnPower;
		string name;
		uint16 level;
		uint8 head;
		msg >> roleId >> power >> returnId;
		if (returnId == 0)
		{
			CUser robot;
			robot.CopyUserData(Random(1, 20), 1);
			returnId = robot.GetRoleId();
			level = robot.GetLevel();
			head = robot.GetHead();
			name = robot.GetName();
		}
		else
		{
			msg >> returnPower >> name >> level >> head;
		}
		CUser *pUser = m_onlineUser.GetUserByRoleId(roleId).get();
		if (pUser == NULL)
			return;
		pUser->SetExtData32(463, returnId);
		uint16 pic = 70;// + xiang;
		uint16 npcId = 250;// + xiang;
		uint16 sceneId = 70;
		char npcName[128];
		snprintf(npcName, sizeof(npcName), LANGUAGE_ZQX_0069, name.c_str());
		int posIdx = Random(0, maxPosCnt - 1);
		AddNpcWithInfo(pUser, npcId, sceneId, pos[posIdx][0], pos[posIdx][1], 0, pic, npcName, PQT_RED);
		vector<int> var;
		vector<string> vstr;
		var.push_back(3);
		var.push_back(npcId);
		var.push_back(sceneId);
		vstr.push_back(name.c_str());
		pUser->UpdateCMission(MISSION_ID_KuaFuShilian, var, vstr);
		pUser->UpdateCMissionState(MISSION_ID_KuaFuShilian, 0);
		UpdateNpcState(pUser, 250, 2);
		SendYinDaoMissionNPCPos(pUser, sceneId, -1, -1, npcId, MISSION_ID_KuaFuShilian);
	}
	break;
	case 5:
	{
		msg >> roleId >> power >> power;
		CUser *pUser = m_onlineUser.GetUserByRoleId(roleId).get();
		if (pUser == NULL)
			return;
		CXunBaoManage& manage = pUser->GetXunbaoManage();
		manage.LoadKunLunFights(msg);
	}

	default:
		break;
	}
}

void CPackageDeal::DealShenJiangZheKou(CNetMessage& msg, CUser* pUser)
{
	uint8 type = CHuoDongAwardManager::SHENJIANG_ZHEKOU;
	uint8 op = 0;	// 1获取列表信息
	msg >> op;
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();

	if (!awardManager.InHuoDongTime(type))
		return;
	uint32 getMaskDataId = 634;
	uint32 getMask = pUser->GetExtData32(getMaskDataId);

	if (op == 1)
	{
		uint32 curTime = GetSysTime();
		uint32 endTime = awardManager.GetHuoDongEndTime(type);
		vector<uint32> idxList;
		awardManager.GetAwardIdxList(type, 1, idxList);
		if (idxList.size() == 0)
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_1626, TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(), msg);
			return;
		}

		msg << PRO_SUCCESS << endTime - curTime << (uint8)idxList.size();
		for (uint32 j = 0; j < idxList.size(); j++)
		{
			SHuoDongAward award;
			awardManager.GetAwardData(type, idxList[j], award);

			if (award.idx > 0 && award.idx < 32)
			{
				if (award.award[0] != HDAT_PET)
				{
					msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_1626, TIPS_FAILURE_COLOR);
					m_socketServer.SendMsg(pUser->GetSock(), msg);
					return;
				}
				uint8 getState = ((getMask&(1 << award.idx)) == 0) ? (uint8)0 : (uint8)1;
				msg << (uint8)award.idx << getState;
				msg << (uint32)award.idx3 << (uint32)award.needYB << (uint16)award.num[0] << (uint16)award.petQuality[0] << (uint16)award.petQualityLv[0];
			}
			else
			{
				msg << (uint32)0;
			}
		}
		m_socketServer.SendMsg(pUser->GetSock(), msg);
	}
	else if (op == 2)
	{
		uint8 idx = 0;
		msg >> idx;

		uint8 buyState = ((getMask&(1 << idx)) == 0) ? (uint8)0 : (uint8)1;
		if (buyState == 1)
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0030, TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(), msg);
			return;
		}

		SHuoDongAward award;
		awardManager.GetAwardData(type, idx, award);
		if (pUser->GetTongBao() < (int)award.needYB)
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_SSJ_0414, TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);
			return;
		}
		if (!pUser->AddTongBao(-award.needYB, 0))
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_SSJ_0408, TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);
			return;
		}
		for (uint8 j = 0; j < SHuoDongAward::AWARD_NUM; j++)
		{
			AddHuoDongAward(pUser, type, award.award[j], award.num[j], award.petQuality[j], award.petQualityLv[j]);
			if (award.award[j] == HDAT_PET)
			{
				char buf[128];
				snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0034, pUser->GetName(), MakePetColorStr(award.num[j]).c_str());
				SysInfoToAllUser(buf);
				ItemCurrencyLog(pUser->GetRoleId(), HDAT_PET, award.num[j], 0, award.needYB, pUser->GetTongBao(), 1);
			}
		}

		getMask |= (1 << idx);
		pUser->SetExtData32(getMaskDataId, getMask);
		msg << PRO_SUCCESS;
		m_socketServer.SendMsg(pUser->GetSock(), msg);
	}
	else if (op == 3)
	{
		vector<HDPeiZhiInfo> info;
		awardManager.GetPeiZhiInfo(info, type);
		if (info.size() < 1)
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_1511, TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(), msg);
			return;
		}
		msg << PRO_SUCCESS << info[0].YB;
		m_socketServer.SendMsg(pUser->GetSock(), msg);
	}
}

void CPackageDeal::DealZheKouHuoDong(CNetMessage& msg, CUser* pUser, int type)
{
	uint8 op = 0;	// 1获取列表信息
	msg >> op;
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	if (!awardManager.InHuoDongTime(type))
		return;
	if (op == 1)
	{
		awardManager.GetHDSingleAwardMsg(pUser, type, msg);
		m_socketServer.SendMsg(pUser->GetSock(), msg);
	}
	else if (op == 2)
	{
		awardManager.BuyHDSingleAwardMsg(pUser, type, msg);
		m_socketServer.SendMsg(pUser->GetSock(), msg);
	}
}

void CPackageDeal::DealXunHuanZheKouHuoDong(CNetMessage& msg, CUser* pUser, int type)
{
	uint8 op = 0;	// 1获取列表信息
	msg >> op;
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	if (!awardManager.InHuoDongTime(type))
		return;
	if (op == 1)
	{
		awardManager.GetXunHuanHDSingleAwardMsg(pUser, type, msg);
		m_socketServer.SendMsg(pUser->GetSock(), msg);
	}
	else if (op == 2)
	{
		awardManager.BuyXunHuanHDSingleAwardMsg(pUser, type, msg);
		m_socketServer.SendMsg(pUser->GetSock(), msg);
	}
}

void CPackageDeal::DealPetEquipOperate(CNetMessage *pMsg, int sock)
{
	GET_MSG
	GET_USER

	uint8 op;
	msg >> op;
	CEquipManeger& equipMgr = pUser->GetPetEquipMgr();
	const bool localTest = gyu::util::CIniFile::GetValue("local_test","server",gConfigFile) == "1";
	switch (op)
	{
	case 1: // 拉取整个列表
		equipMgr.SendPetEquipList(pUser, msg);
		return;
	case 2: // 穿
		equipMgr.WearPetEquip(pUser, msg);
		break;
	case 3: // 脱
		equipMgr.TakeOffPetEquip(pUser, msg);
		break;
	case 4: // 强化
		if(!localTest) { CHECK_SYSTEM_OPEN(SOT_1120) }
		equipMgr.StrongEquip(pUser, msg);
		break;
	case 5: // 分解
		equipMgr.CFenJiePetEquip(pUser, msg);
		break;
	case 8: // 多件分解
		equipMgr.MutilFenJiePetEquip(pUser, msg);
		break;
	case 11: // 装备合成
		equipMgr.EquipHeCheng(pUser, msg);
		break;
	case 12:
		if (!localTest && !sSystemOpenCfgMananger.CheckSystemOpen(pUser, SOT_1120))
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_LLD_0072, TIPS_FAILURE_COLOR);
			break;
		}
		equipMgr.StrongAllEquip(pUser, msg);
		break;
	case 13:
		if (!localTest && !sSystemOpenCfgMananger.CheckSystemOpen(pUser, SOT_1130))
		{
			uint32 equipId = 0;
			uint8 itemSize = 0;
			msg >> equipId >> itemSize;
			msg.ReWrite();
			msg.SetType(PET_EQUIP_OPERATE);
			msg << (uint8)13 << equipId << PRO_ERROR << MakeStringColor(LANGUAGE_LLD_0072, TIPS_FAILURE_COLOR);
			break;
		}
		equipMgr.JingLianEquip(pUser, msg);
		break;
	case 14:
		if (!localTest && !sSystemOpenCfgMananger.CheckSystemOpen(pUser, SOT_1140))
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_LLD_0072, TIPS_FAILURE_COLOR);
			break;
		}
		equipMgr.JueXingEquip(pUser, msg);
		break;
	case 15:
		if (!localTest && !sSystemOpenCfgMananger.CheckSystemOpen(pUser, SOT_1150))
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_LLD_0072, TIPS_FAILURE_COLOR);
			break;
		}
		equipMgr.ShenZhuEquip(pUser, msg);
		break;
		
	case 17: // 发送法宝列表
		equipMgr.SendFaBaoList(pUser, msg);
		return;
	case 18: // 穿
		if(!localTest) { CHECK_SYSTEM_OPEN(SOT_1180) }
		equipMgr.WearFaBao(pUser, msg);
		break;
	case 19: // 脱
		equipMgr.TakeOffFaBao(pUser, msg);
		break;
	case 20: // 强化
		CHECK_SYSTEM_OPEN(SOT_1182)
		equipMgr.StrongFaBao(pUser, msg);
		break;
	case 21: // 精炼
		CHECK_SYSTEM_OPEN(SOT_1183)
		equipMgr.JingLianFaBao(pUser, msg);
		break;
	case 24://单个强化大师通知
		break;
	case 25://强化大师
		equipMgr.GetQHDSMsg(msg);
		break;
	case 22:// 添加法宝
	case 23:// 删除法宝
	case 26:// 装备强化大师
	case 27:// 法宝强化大师
		break;
	case 28:// 搜索碎片
		CHECK_SYSTEM_OPEN(SOT_9)
		equipMgr.FaBaoSouSuo(pUser, msg);
		break;
	case 29:// 一件搜索
		CHECK_SYSTEM_OPEN(SOT_1181)
		equipMgr.FaBaoAutoSouSuo(pUser, msg);
		break;
	case 30:// 合成法宝
		CHECK_SYSTEM_OPEN(SOT_1180)
		equipMgr.FaBaoHeCheng(pUser, msg);
		break;
	case 31:// 搜索次数
		equipMgr.TrapSouSuoCnt(pUser);
		return;

	case 32:// 装备重生
		equipMgr.EChongShengChaXun(pUser, msg);
		break;
	case 33:// 法宝重生
		equipMgr.EChongSheng(pUser, msg);
		break;
	case 34:// 装备重生
		equipMgr.FChongShengChaXun(pUser, msg);
		break;
	case 35:// 法宝重生
		equipMgr.FChongSheng(pUser, msg);
		break;
	case 36:// 一键法宝
		CHECK_SYSTEM_OPEN(SOT_1180)
		equipMgr.AutoHeChengFaBao(pUser, msg);
		break;
	default:
		break;
	}
	m_socketServer.SendMsg(sock, msg);
}

void CPackageDeal::ClientTestOption(CNetMessage *pMsg, int sock)
{
	GET_MSG
	GET_USER

	msg.ReWrite();
	msg.SetType(PRO_CLIENT_TEST);
	for(uint32 i=0;i < 1024;i++)
		msg<<(uint8)Random(1,200);

	for(uint32 i=0;i < 1000;i++)
		m_socketServer.SendMsg(sock,msg);
}

void CPackageDeal::DealGuanQia(CNetMessage *pMsg, int sock)
{
	GET_MSG
	GET_USER
	
	uint8 op;
	uint8 type;
	uint32 mapId;
	uint32 nodeId;
	uint32 fixId;
	msg >> op;
	CUserGuanQia& gq = pUser->GetGuanQia();
	switch (op)
	{
	case 1: // 请求大地图信息
		msg >> type;  // 1 主线  2 支线
		gq.MakeUserGuanQiaMsg(type, msg);
		break;
	case 2: // 请求当前地图信息
		msg >> type >> mapId;
		gq.MakeSinggleGuanQiaMsg(type, mapId, msg);
		break;
	case 3: // 请求宝箱信息
		msg >> fixId;
		gq.MakeFixMsg(fixId, msg);
		break;
	case 4: // 领取宝箱
		msg >> type >> mapId >> fixId;
		gq.GetFixAward(pUser, type, mapId, fixId, msg);
		break;
	case 5: // 挑战关卡
		msg >> type >> mapId >> nodeId;
		if (type == 1)
		{
			CHECK_SYSTEM_OPEN(SOT_4)
		}
		else
		{
			CHECK_SYSTEM_OPEN(SOT_5)
		}
		gq.EnterGuanQiaFight(pUser, type, mapId, nodeId, msg);
		break;
	case 6: // 扫荡
		msg >> type >> mapId >> nodeId;
		if (type == 1)
		{
			CHECK_SYSTEM_OPEN(SOT_4)
		}
		else
		{
			CHECK_SYSTEM_OPEN(SOT_5)
		}
		gq.GuanQiaSaoDang(pUser, type, mapId, nodeId, msg);
		return;
	case 7: // 重置关卡
		msg >> nodeId;
		gq.GuanQiaReset(pUser, nodeId, msg);
		break;
	case 11: // 成就
		gq.GetChengJiuMsg(pUser, msg);
		break;
	case 12: // 成就奖励
		gq.GetChengJiuAward(pUser, msg);
		break;
	case 21: // 请求试炼信息
		CHECK_SYSTEM_OPEN(SOT_2)
		gq.GetShiLianMsg(pUser, msg);
		break;
	case 22: // 挑战试炼
		CHECK_SYSTEM_OPEN(SOT_2)
		gq.TiaoZhanShiLian(pUser, msg);
		break;
	case 23: // 试炼扫荡
		CHECK_SYSTEM_OPEN(SOT_1021)
		gq.SaoDangShiLian(pUser, msg);
		break;
	case 24: // 请求列传信息
		CHECK_SYSTEM_OPEN(SOT_3)
		gq.GetLieZhuanMsg(pUser, msg);
		break;
	case 25: // 列传挑战
		CHECK_SYSTEM_OPEN(SOT_3)
		gq.TiaoZhanLieZhuan(pUser, msg);
		break;
	case 27: // 查询挑战信息
		gq.MakeNodeMsg(pUser, msg);
		break;
	}
	m_socketServer.SendMsg(sock, msg);
}

void CPackageDeal::DealSpirit(CNetMessage *pMsg, int sock)
{
	GET_MSG
	GET_USER
	
	uint8 op = 0;
	CUserSpirit& spirit = pUser->GetUserSpirit();
	msg >> op;
	switch (op)
	{
	case 1:// 体力信息
		spirit.MakeSpiritMsg(msg);
		break;
	case 2:// 免费体力信息
		spirit.MakeFreeSpiritMsg(msg);
		break;
	case 3:// 领取免费体力
		spirit.GetFreeSpirit(pUser, msg);
		break;
	}
	m_socketServer.SendMsg(sock, msg);
}

void CPackageDeal::DealHeroBook(CNetMessage *pMsg, int sock)
{
	GET_MSG
	GET_USER
	CHECK_SYSTEM_OPEN(SOT_1090)
	uint8 op = 0;
	UserBook* book = pUser->GetUserBook();
	if (book == NULL)
		return;
	msg >> op;
	switch (op)
	{
	case 1:
		book->GetBookMsg(msg);
		break;
	case 2:
		book->BookStarLevelUp(pUser, msg);
		break;
	}
	m_socketServer.SendMsg(sock, msg);
}

void CPackageDeal::DealBloodFight(CNetMessage *pMsg, int sock)
{
	GET_MSG
	GET_USER
	
	CUserBloodFight* fight = pUser->GetBloodFight();
	if (fight == NULL)
		return;
	
	uint8 op = 0;
	msg >> op;
	switch (op)
	{
	case 1:
		fight->GetBloodMsg(pUser, msg);
		break;
	case 2:
		fight->NewBloodFight(pUser, msg);
		return;
	case 3:
		CHECK_SYSTEM_OPEN(SOT_1160)
		fight->TryBloodFight(pUser, msg);
		break;

	case 4:
		fight->GetFiveFixMsg(pUser, msg);
		break;

	case 5:// 已通章节奖励推送
		break;

	case 6: // 重置
		fight->RetryBloodFight(pUser, msg);
		break;

	case 7: // 复活
		fight->ReviveBloodFight(pUser, msg);
		break;

	case 9: // 扫荡
		CHECK_SYSTEM_OPEN(SOT_1161)
		fight->BloodFightSaoDang(pUser, msg);
		return;

	case 10: // 选buf
		fight->SelectBloodBuff(pUser, msg);
		break;

	case 11:// 选buf设置 0 选星最多的 
		fight->SetAutoSltBuff(msg);
		break;

	case 12: // 总buff推送
	case 13: // 扫荡buff推送
		break;
	case 14: // 选择扫荡buff
		fight->SelectSaoDangBloodBuff(pUser, msg);
		break;
	case 15: // 扫荡buff推送
		fight->GetSomeRecord(pUser, msg);
		break;
	case 16: // 推送排名奖励
		fight->GetRankAward(pUser, msg);
		break;
	case 17:	// 获取当前排名
		int rank = SingletonCRankMgr::instance().GetRankIdx(CRankMgr::ERT_Blood_Today, pUser->GetRoleId());
		msg<<rank;
	}
	m_socketServer.SendMsg(sock, msg);
}



// 商城
void CPackageDeal::ShopOption(CNetMessage *pMsg, int sock)
{
	GET_MSG
	GET_USER

	/*
	op:
	1:获取某页的道具
	2:购买某页的道具
	*/

	uint8 op = 0;
	msg >> op;
	UserShopManager* shop = pUser->GetShop();
	switch (op)
	{
	case 1:
		shop->GetShopMsg(pUser, msg);
		break;
	case 2:
		shop->BuyShopItem(pUser, msg);
		break;
	case 3:
		shop->RefreshGrids(pUser, msg);
		break;
	case 4:
		shop->GetItemByCnt(pUser, msg);
		break;
	}
	m_socketServer.SendMsg(sock, msg);
}

void CPackageDeal::DealYouLi(CNetMessage *pMsg, int sock)
{
	GET_MSG
	GET_USER
	uint8 op = 0;
	msg >> op;
	CXunBaoManage& xunBao = pUser->GetXunbaoManage();
	switch (op)
	{
	case 1:
		xunBao.GetYouLiMsg(msg);
		break;
	case 2:
		xunBao.StartYouLi(msg);
		break;
	case 3:
		xunBao.GetYouLiAward(msg);
		break;
	}
	m_socketServer.SendMsg(sock, msg);
}

//void CPackageDeal::DealJiJin(CNetMessage *pMsg, int sock)
//{
//	GET_MSG
//	GET_USER
//		uint8 op = 0;
//	uint8 type = 0;
//	msg >> op >> type;
//	CHuoDongManage &mgr = sCHuoDongManage;
//	//switch (op)
//	//{
//	//case 1:
//	//{
//	//	uint32 type = 0;
//	//	//mgr.GetQiRiAward()  获取活动类型
//	//	// 设置活动结束时间
//
//	//	/*if (pUser->GetExtData32(469) <= curTime)
//	//	{
//	//	pUser->ClearZhaDanHistory();
//	//	pUser->SetExtData32(469, endTime);
//	//	}*/
//	//	uint32 type = CHuoDongAwardManager::ZHA_DAN;
//	//	uint32 awardType = 1;
//	//	//ext32Idx = 12;
//	//	uint8 op1 = 0;
//	//	msg >> op1;
//	//	if (op1 == 1) // 查看状态
//	//	{
//	//		int hour = GetHour();
//	//		int minute = GetMinute();
//	//		int second = GetSysTime() % 60;
//	//		int leftTime = 24 * 3600 - hour * 3600 - minute * 60 - second;
//
//	//		int endSec = endTime > curTime ? endTime - curTime : 0;
//	//		leftTime = endSec;
//	//		msg << PRO_SUCCESS << pUser->GetExtData32(ext32Idx) << leftTime << endSec;
//	//		pUser->InitZhaDanHistory();
//	//		vector<string> myHistory, publicHistory;
//	//		pUser->GetZhaDanHistory(myHistory);
//	//		msg << (uint8)myHistory.size();
//	//		for (uint32 i = 0; i < myHistory.size(); i++)
//	//		{
//	//			msg << myHistory[i].c_str();
//	//		}
//
//	//		awardManager.GetZhaDanPubHistory(publicHistory);
//	//		msg << (uint8)publicHistory.size();
//	//		for (uint32 i = 0; i < publicHistory.size(); i++)
//	//		{
//	//			msg << publicHistory[i].c_str();
//	//		}
//	//		m_socketServer.SendMsg(pUser->GetSock(), msg);
//	//	}
//	//	else if (op1 == 2) // 领取
//	//	{
//	//		static uint16 ItemId = 0;
//	//		int hasNum = pUser->GetItemNum(ItemId);
//	//		vector<string> myHistory, publicHistory;
//	//		int awardIdx = 0;
//	//		pUser->AddMaterial(HDAT_ZhuanPanJiFen);
//
//	//		pUser->SetExtData32(ext32Idx, pUser->GetExtData32(ext32Idx) + count * 10);
//	//		msg << PRO_SUCCESS << pUser->GetExtData32(ext32Idx) << (uint8)awardIdx;
//
//	//		if (myHistory.size() > 0)
//	//			pUser->SetZhaDanHistory(myHistory);
//
//	//		uint8 size = (uint8)myHistory.size();
//	//		uint8 index;
//	//		if (size > MAX_LOG_NUM)
//	//		{
//	//			msg << MAX_LOG_NUM;
//	//			index = size - MAX_LOG_NUM;
//	//		}
//	//		else
//	//		{
//	//			msg << size;
//	//			index = 0;
//	//		}
//
//	//		for (uint32 i = index; i < myHistory.size(); i++)
//	//		{
//	//			msg << myHistory[i].c_str();
//	//		}
//
//	//		size = (uint8)publicHistory.size();
//	//		if (size > MAX_LOG_NUM)
//	//		{
//	//			msg << MAX_LOG_NUM;
//	//			index = size - MAX_LOG_NUM;
//	//		}
//	//		else
//	//		{
//	//			msg << size;
//	//			index = 0;
//	//		}
//
//	//		for (uint32 i = 0; i < publicHistory.size(); i++)
//	//		{
//	//			msg << publicHistory[i].c_str();
//	//		}
//	//		m_socketServer.SendMsg(pUser->GetSock(), msg);
//	//	}
//	//	break;
//	//}
//	//case 2:
//	//{
//	//	break;
//	//}
//	//case 3:
//	//	break;
//	//}
//	m_socketServer.SendMsg(sock, msg);
//}
