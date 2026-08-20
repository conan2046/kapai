#include "user.h"
#include "arena.h"
#include "scene_manager.h"
#include "utility.h"
#include "singleton.h"
#include "call_script.h"
#include "script_call.h"
#include "tower_reward_manager.h"
#include "award_manager.h"
#include <algorithm>
#include <functional>	  // For greater<int>( )
#include <boost/format.hpp>
#include <time.h>
#include <vector>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <boost/scoped_array.hpp>
#include <boost/scoped_array.hpp>
#include <math.h>
#include "main.h"
#include "init.h"
#include "pet_equip_manage.h"
#include "bangpai.h"
#include "rank.h"
#include "hero_cfg_manager.h"
#include "chou_ka_manager.h"
#include "blood_fight_manage.h"
#include "user_shop_manage.h"
#include "role_simple_mgr.h"
using namespace std;

extern CDatabaseSql g_LoginDB;
extern boost::recursive_mutex G_LoginDB_Mutex;

extern std::map<uint16,SkillInfoNode> skillInfoListMap;

extern boost::recursive_mutex tongTianTa_mutex;
extern vector<uint32> tongTianTaBaZhuData;	// 通天塔霸主ID,12/24/36/48/60
extern uint16 tongTianTaBaZhuFloor[5];

extern void TransportUser(CUser *pUser,int sceneId,uint16 x,uint16 y,uint8 face);

struct HeChengItemInfo
{
	int tarItemId;
	int material1;
	int materialNum1;
	int material2;
	int materialNum2;
	int material3;
	int materialNum3;
	int money;
};

static const HeChengItemInfo hechengList[] =
{{1,506,4,0,0,0,0,2000},
{2,506,12,0,0,0,0,6000},
{3,507,12,0,0,0,0,18000},
{4,508,12,0,0,0,0,54000},
{5,509,12,0,0,0,0,162000},
{6,510,12,0,0,0,0,486000},
{7,510,36,0,0,0,0,1458000},
{8,2921,54,0,0,0,0,1749600},
{9,2921,162,0,0,0,0,1800000},
{21,506,4,0,0,0,0,2000},
{22,506,12,0,0,0,0,6000},
{23,507,12,0,0,0,0,18000},
{24,508,12,0,0,0,0,54000},
{25,509,12,0,0,0,0,162000},
{26,510,12,0,0,0,0,486000},
{27,510,36,0,0,0,0,1458000},
{28,2921,54,0,0,0,0,1749600},
{29,2921,162,0,0,0,0,1800000},
{41,506,4,0,0,0,0,2000},
{42,506,12,0,0,0,0,6000},
{43,507,12,0,0,0,0,18000},
{44,508,12,0,0,0,0,54000},
{45,509,12,0,0,0,0,162000},
{46,510,12,0,0,0,0,486000},
{47,510,36,0,0,0,0,1458000},
{48,2921,54,0,0,0,0,1749600},
{49,2921,162,0,0,0,0,1800000},
{61,506,4,0,0,0,0,2000},
{62,506,12,0,0,0,0,6000},
{63,507,12,0,0,0,0,18000},
{64,508,12,0,0,0,0,54000},
{65,509,12,0,0,0,0,162000},
{66,510,12,0,0,0,0,486000},
{67,510,36,0,0,0,0,1458000},
{68,2921,54,0,0,0,0,1749600},
{69,2921,162,0,0,0,0,1800000},
{81,506,4,0,0,0,0,2000},
{82,506,12,0,0,0,0,6000},
{83,507,12,0,0,0,0,18000},
{84,508,12,0,0,0,0,54000},
{85,509,12,0,0,0,0,162000},
{86,510,12,0,0,0,0,486000},
{87,510,36,0,0,0,0,1458000},
{88,2921,54,0,0,0,0,1749600},
{89,2921,162,0,0,0,0,1800000},
{101,506,4,0,0,0,0,2000},
{102,506,12,0,0,0,0,6000},
{103,507,12,0,0,0,0,18000},
{104,508,12,0,0,0,0,54000},
{105,509,12,0,0,0,0,162000},
{106,510,12,0,0,0,0,486000},
{107,510,36,0,0,0,0,1458000},
{108,2921,54,0,0,0,0,1749600},
{109,2921,162,0,0,0,0,1800000},
{121,506,4,0,0,0,0,2000},
{122,506,12,0,0,0,0,6000},
{123,507,12,0,0,0,0,18000},
{124,508,12,0,0,0,0,54000},
{125,509,12,0,0,0,0,162000},
{126,510,12,0,0,0,0,486000},
{127,510,36,0,0,0,0,1458000},
{128,2921,54,0,0,0,0,1749600},
{129,2921,162,0,0,0,0,1800000},
{141,506,4,0,0,0,0,2000},
{142,506,12,0,0,0,0,6000},
{143,507,12,0,0,0,0,18000},
{144,508,12,0,0,0,0,54000},
{145,509,12,0,0,0,0,162000},
{146,510,12,0,0,0,0,486000},
{147,510,36,0,0,0,0,1458000},
{148,2921,54,0,0,0,0,1749600},
{149,2921,162,0,0,0,0,1800000},
{161,506,4,0,0,0,0,2000},
{162,506,12,0,0,0,0,6000},
{163,507,12,0,0,0,0,18000},
{164,508,12,0,0,0,0,54000},
{165,509,12,0,0,0,0,162000},
{166,510,12,0,0,0,0,486000},
{167,510,36,0,0,0,0,1458000},
{168,2921,54,0,0,0,0,1749600},
{169,2921,162,0,0,0,0,1800000},
{181,506,4,0,0,0,0,2000},
{182,506,12,0,0,0,0,6000},
{183,507,12,0,0,0,0,18000},
{184,508,12,0,0,0,0,54000},
{185,509,12,0,0,0,0,162000},
{186,510,12,0,0,0,0,486000},
{187,510,36,0,0,0,0,1458000},
{188,2921,54,0,0,0,0,1749600},
{189,2921,162,0,0,0,0,1800000},
{201,506,4,0,0,0,0,2000},
{202,506,12,0,0,0,0,6000},
{203,507,12,0,0,0,0,18000},
{204,508,12,0,0,0,0,54000},
{205,509,12,0,0,0,0,162000},
{206,510,12,0,0,0,0,486000},
{207,510,36,0,0,0,0,1458000},
{208,2921,54,0,0,0,0,1749600},
{209,2921,162,0,0,0,0,1800000},
{221,506,4,0,0,0,0,2000},
{222,506,12,0,0,0,0,6000},
{223,507,12,0,0,0,0,18000},
{224,508,12,0,0,0,0,54000},
{225,509,12,0,0,0,0,162000},
{226,510,12,0,0,0,0,486000},
{227,510,36,0,0,0,0,1458000},
{228,2921,54,0,0,0,0,1749600},
{229,2921,162,0,0,0,0,1800000},
{241,506,4,0,0,0,0,2000},
{242,506,12,0,0,0,0,6000},
{243,507,12,0,0,0,0,18000},
{244,508,12,0,0,0,0,54000},
{245,509,12,0,0,0,0,162000},
{246,510,12,0,0,0,0,486000},
{247,510,36,0,0,0,0,1458000},
{248,2921,54,0,0,0,0,1749600},
{249,2921,162,0,0,0,0,1800000},
{261,506,4,0,0,0,0,2000},
{262,506,12,0,0,0,0,6000},
{263,507,12,0,0,0,0,18000},
{264,508,12,0,0,0,0,54000},
{265,509,12,0,0,0,0,162000},
{266,510,12,0,0,0,0,486000},
{267,510,36,0,0,0,0,1458000},
{268,2921,54,0,0,0,0,1749600},
{269,2921,162,0,0,0,0,1800000},
{281,506,4,0,0,0,0,2000},
{282,506,12,0,0,0,0,6000},
{283,507,12,0,0,0,0,18000},
{284,508,12,0,0,0,0,54000},
{285,509,12,0,0,0,0,162000},
{286,510,12,0,0,0,0,486000},
{287,510,36,0,0,0,0,1458000},
{288,2921,54,0,0,0,0,1749600},
{289,2921,162,0,0,0,0,1800000},
{303,506,4,0,0,0,0,2000},
{304,506,12,0,0,0,0,6000},
{305,507,12,0,0,0,0,18000},
{306,508,12,0,0,0,0,54000},
{307,509,12,0,0,0,0,162000},
{308,510,12,0,0,0,0,486000},
{309,510,36,0,0,0,0,1458000},
{310,2921,54,0,0,0,0,1749600},
{311,2921,162,0,0,0,0,1800000},
{323,506,4,0,0,0,0,2000},
{324,506,12,0,0,0,0,6000},
{325,507,12,0,0,0,0,18000},
{326,508,12,0,0,0,0,54000},
{327,509,12,0,0,0,0,162000},
{328,510,12,0,0,0,0,486000},
{329,510,36,0,0,0,0,1458000},
{330,2921,54,0,0,0,0,1749600},
{331,2921,162,0,0,0,0,1800000},
{343,506,4,0,0,0,0,2000},
{344,506,12,0,0,0,0,6000},
{345,507,12,0,0,0,0,18000},
{346,508,12,0,0,0,0,54000},
{347,509,12,0,0,0,0,162000},
{348,510,12,0,0,0,0,486000},
{349,510,36,0,0,0,0,1458000},
{350,2921,54,0,0,0,0,1749600},
{351,2921,162,0,0,0,0,1800000},
{363,506,4,0,0,0,0,2000},
{364,506,12,0,0,0,0,6000},
{365,507,12,0,0,0,0,18000},
{366,508,12,0,0,0,0,54000},
{367,509,12,0,0,0,0,162000},
{368,510,12,0,0,0,0,486000},
{369,510,36,0,0,0,0,1458000},
{370,2921,54,0,0,0,0,1749600},
{371,2921,162,0,0,0,0,1800000},
{383,506,4,0,0,0,0,2000},
{384,506,12,0,0,0,0,6000},
{385,507,12,0,0,0,0,18000},
{386,508,12,0,0,0,0,54000},
{387,509,12,0,0,0,0,162000},
{388,510,12,0,0,0,0,486000},
{389,510,36,0,0,0,0,1458000},
{390,2921,54,0,0,0,0,1749600},
{391,2921,162,0,0,0,0,1800000},
{403,506,4,0,0,0,0,2000},
{404,506,12,0,0,0,0,6000},
{405,507,12,0,0,0,0,18000},
{406,508,12,0,0,0,0,54000},
{407,509,12,0,0,0,0,162000},
{408,510,12,0,0,0,0,486000},
{409,510,36,0,0,0,0,1458000},
{410,2921,54,0,0,0,0,1749600},
{411,2921,162,0,0,0,0,1800000},
{423,506,4,0,0,0,0,2000},
{424,506,12,0,0,0,0,6000},
{425,507,12,0,0,0,0,18000},
{426,508,12,0,0,0,0,54000},
{427,509,12,0,0,0,0,162000},
{428,510,12,0,0,0,0,486000},
{429,510,36,0,0,0,0,1458000},
{430,2921,54,0,0,0,0,1749600},
{431,2921,162,0,0,0,0,1800000},
{443,506,4,0,0,0,0,2000},
{444,506,12,0,0,0,0,6000},
{445,507,12,0,0,0,0,18000},
{446,508,12,0,0,0,0,54000},
{447,509,12,0,0,0,0,162000},
{448,510,12,0,0,0,0,486000},
{449,510,36,0,0,0,0,1458000},
{450,2921,54,0,0,0,0,1749600},
{451,2921,162,0,0,0,0,1800000},
{463,506,4,0,0,0,0,2000},
{464,506,12,0,0,0,0,6000},
{465,507,12,0,0,0,0,18000},
{466,508,12,0,0,0,0,54000},
{467,509,12,0,0,0,0,162000},
{468,510,12,0,0,0,0,486000},
{469,510,36,0,0,0,0,1458000},
{470,2921,54,0,0,0,0,1749600},
{471,2921,162,0,0,0,0,1800000}};


CUser::CUser():m_step(1),m_pScene(NULL)//,m_pOleScene(NULL), 
	, m_xunBaoManage(this)
{
	for(int i = 0; i < MAX_SAVE_NUM; i++)
	{
		m_shortArray[i] = 0;
	}

	SetFight(0);

	m_teamId = 0;
	m_face = 0;
	m_gensuiPet = 0xff;
	m_sock = 0;

	m_userOp = 0;
	m_userPara = 0;
	//m_enterSceneCall = 0;
	m_inJump = false;
	m_autoFightTurn =   0;
	m_tongBao = 0;
	m_logout = false;
	m_roleId = 0;
	memset(m_role,0,sizeof(m_role));
	m_admin = 0;
	//timeval tv;
	//gettimeofday(&tv,NULL);
	m_moveTime = 0;
	m_moveErrTimes = 0;
	m_saveDataTime = GetSysTime();
	m_huodongTime = GetSysTime();
	m_lastHeartTime = GetSysTime();
	m_heartTimes = 0;
	m_heartErrTimes = 0;
	MAX_PACKAGE_NUM = MAX_PACKAGE_NUM2;

	for(uint16 i=0;i < sizeof(m_package)/sizeof(m_package[0]);i++)
		m_package[i].Clear();
	reg_time = 0;
	m_tempLeaveTeam = 0;
	m_activityTime = 0;
	m_teamCallTime = 0;
	m_guanFight = 0;
	m_bdTongBao = 0;
	m_NPCState = 0;
	inscriptcall = false;
	m_delLockPassTime = 0;

	have_yindao_item = false;
	m_fightdata.clear();
	m_fightdata_pos = 0;
	m_Doption_root = NULL;
	maxNodeId = 1;
	m_Doption_call.clear();
	m_OtherTitle = 0;
	m_maxHpAddTmp = 0;
	m_version = 0;
	m_360_id = 0;
	m_360_expires_in_time = 0; // 不是expires_in,是access_token的有效值
	m_360_access_token = "";
	m_360_refresh_token = "";
	m_xOrig = 0;
	m_yOrig = 0;
	m_lastFightTime = 0;
	m_clientFightEndTime = 0;
	m_collectIdx = 0;
	m_todayBangGong = 0;
	m_zhanDouLi = 0;
	m_yaolingZhanDouLi = 0;
	memset(&m_FuBenBackPoint,0,sizeof(m_FuBenBackPoint));

	m_attackType = 0;
	m_attr.Clear();
	
	m_nextOpenPackageTime = 0;
	m_meetEnemy = true;
	m_fuBenDrop = "";
	m_curFuBenId = 0;
	m_curFuBenFinishTime = 0;
	m_pFishRoom = NULL;
	m_fishState = CFishRoom::ERS_ERR;
	m_fishSceneSrcId = 0;
	m_grabedTime = 0;
	m_grabedProtectTime = 0;
	m_curTongTianTaFightFloor = 0;
	m_zaiXianLingHaoLiTime = 0;
	m_npcInteractTimeout = 0;
	sendMailTime = 0;
	m_isInDaTi = false;
	memset(m_bossMissionStar,0,sizeof(m_bossMissionStar));

	memset(m_qx_petlist,0xff,sizeof(m_qx_petlist));
	memset(m_qx_chuzhan,0xff,sizeof(m_qx_chuzhan));
	for(uint8 i=0;i < sizeof(m_qx_hpRatio)/sizeof(m_qx_hpRatio[0]);i++)
		m_qx_hpRatio[i] = 10000;
	m_qx_dieFlag = 0;
	m_qx_awardFlag = 0;
	memset(m_qx_addAttrVal,0,sizeof(m_qx_addAttrVal));
	memset(m_qx_addAttrPercent,0,sizeof(m_qx_addAttrPercent));
	
	m_multiExpTime = GetSysTime();
	m_isCreatedRole = false;
	m_lastCheckTitleTime = 0;
	m_bangArea_killNum = 0;
	m_lastLoginOutTime = 0;
	m_celue = 0;
	m_robot = 0;
	m_FX_FirstState = 0;
	m_FX_SetTime = 0;
	m_isLoadMiss = false;
	m_serverId = 0;
	isInit = true;
	isLoadAccountInfo = true;
	m_binding = 0;
	m_recordPhone= 0;
	//add by zhudaolong 2017.11.10
	isInitTHGHistory = false;
	const uint32 LoadHDHisTory[] = {CHuoDongAwardManager::FESTIVAL,CHuoDongAwardManager::ZHENYING_PK,CHuoDongAwardManager::TAOHUAGENG};
	for (uint32 i = 0; i < sizeof(LoadHDHisTory)/sizeof(LoadHDHisTory[0]); i++)
	{
		m_isLoadHistory.insert(make_pair(LoadHDHisTory[i],true));
	}

	m_isLoadJiaoYiHangRecord = true;
	m_kuafuState = EKFS_IN_LOCAL;
	m_lastSrcSceneId = 0;
	moneyGiftBagHuoDongMap.clear();

	m_transformCardMap.clear();
	ex_shanbi = 0;
	m_checkNpc = false;
	m_yaoshiTime = 0;
	m_autoMatchTeamType = 0;
	m_teamUIQTime = 0;
	m_teamUIQType = 0;

	m_useZhenFaIdx = 0xff;
	m_zhenfaMember.clear();
	for(int i=0;i < MAX_TEAM_MEMBER;i++)
	{
		SZhenFaMemData data;
		m_zhenfaMember.push_back(data);
	}
	m_pwoerSynsTime = 0;
	m_kuafu_IconState = false;
	m_errProtocolNum = 0;
	m_loginHuoYueSign = false;
	checkOnLineTime_ = 0;
	m_userBook = new UserBook();
	m_chouKa = new CChouKaManager();
	m_bloodFight = new CUserBloodFight();
	m_shop = new UserShopManager();
	for (int i = 0; i < MAX_TEAM_MEMBER; i++)
	{
		m_chuzhan.push_back(0);
	}
	
}

void CUser::UpdateSGState()
{
	if ((GetRoleId() != 0) && (GetZhanDouLi() >= 250000) && (!HaveSGBitSet(109)))
		FinishStageGoalSection(1,5); // 战斗力达到250000
	if ((GetRoleId() != 0) && (GetZhanDouLi() >= 500000) && (!HaveSGBitSet(119)))
		FinishStageGoalSection(2,5); // 战斗力达到500000
	if ((GetRoleId() != 0) && (GetZhanDouLi() >= 720000) && (!HaveSGBitSet(129)))
		FinishStageGoalSection(3,5); // 战斗力达到720000
}

void CUser::SetVipAddAttr(bool sendUpdate)
{
	if(sendUpdate)
	{
		SendUpdateInfo(EUUT_HP);
		SendUpdateInfo(EAT_QiXue);
		SendUpdateInfo(EUUT_AllAttrType);
	}
}

void CUser::ClearVipAddAttr()
{
	m_attr.attack -= 100;
//	m_fashuDamage -= 100;
//	m_recovery -= 50;
	m_attr.maxHp -= 300;
}

void CUser::GetAllUseTitleAttr(vector<SAttrData> &attr)
{
	// 遍历角色所有称号
	for(titleMapIt it = m_titleList.begin(); it != m_titleList.end(); ++it)
	{
		STitleAttrs* curAttrs = SingletonCTitltAttrCfgManager::instance().GetTitleAttrs(it->first);
		if (curAttrs != NULL)
		{
			// 遍历当前称号属性
			for (uint16 i = 0; i < curAttrs->size(); ++i)
			{
				bool isNew = true;
				SAttrData &tar = (*curAttrs)[i];

				// 对已有的属性进行累加
				for (uint16 j = 0; j < attr.size(); j++)
				{
					SAttrData &src = attr[j];
					if (src.attrType == tar.attrType)
					{
						src.attrValue += tar.attrValue;
						isNew = false;
						break;
					}
				}

				// 新属性新加
				if (isNew)
				{
					attr.push_back(tar);
				}
			}
		}
	}
}

void CUser::NoLockInitAndUpdate()
{
	Init();
	UpdateInfo();
}

void CUser::InitAndUpdate()
{
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		NoLockInitAndUpdate();
	}
}

bool CUser::Init(bool updateSimpleData)
{
	CheckZhenFa();
	if(m_level == 0)
		return false;

/*	
	vector<SAttrData> attr;
	GetAllPartAttr(attr);

	//帮派技能
	vector<SAttrData> bangSkills;
	GetBangSkillAttr(1,bangSkills);
	if(bangSkills.size() > 0)
	{
		MergeAttrList(attr,bangSkills);
	}
*/
    m_vipLevel=::GetVipLevel(GetChongzhiTotal() + GetExVipExp());
	InitChuZhanPet();
	ResetPower(updateSimpleData);
	return true;
}

void CUser::ResetPower(bool updateSimpleData)
{
	m_zhanDouLi = GetAllZhenFaPower();
	for (uint8 i = 0; i < m_zhenfaMember.size(); i++)
	{
		uint16 heroId = m_zhenfaMember[i].mem_id;
		SharePetPtr prePet = NoLockGetPet(heroId);
		SPet* pet = prePet.get();
		if (pet != NULL)
			m_zhanDouLi += pet->zhanDouli;
	}

	UpdateSGState();

	if(NoLockGetExtData64(EData64_MaxZhanDouLi) < m_zhanDouLi)
		NoLockSetExtData64(EData64_MaxZhanDouLi, m_zhanDouLi);

	if(updateSimpleData)
		SingletonCSimpleRoleDataMgr::instance().UpdateRoleData(this);
	SingletonCRankMgr::instance().UpdateData(CRankMgr::ERT_Power, m_roleId, m_zhanDouLi);
	sCMissionManager.UpdateQuestState(this, EMQCT_57, m_zhanDouLi);
}

void CUser::InitZhaDanHistory()
{
	if (isInit)
	{
		m_zhaDanHistory.clear();
	
		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		char sql[512];
		char **row = NULL;
		if(pDb == NULL)
			return;
		uint32 startTime = 0;
		uint32 endTime = 0;
		CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
		if (awardManager.InHuoDongTime(CHuoDongAwardManager::ZHA_DAN))
		{
			startTime = awardManager.GetHuoDongStartTime(CHuoDongAwardManager::ZHA_DAN);
			endTime = awardManager.GetHuoDongEndTime(CHuoDongAwardManager::ZHA_DAN);
		}
		else if (awardManager.InHuoDongTime(CHuoDongAwardManager::ZHA_DAN_COPY))
		{
			startTime = awardManager.GetHuoDongStartTime(CHuoDongAwardManager::ZHA_DAN_COPY);
			endTime = awardManager.GetHuoDongEndTime(CHuoDongAwardManager::ZHA_DAN_COPY);
		}
		snprintf(sql, sizeof(sql), "select data from zha_dan_log where type = 0 and role_id=%d and UNIX_TIMESTAMP(time) >= %u and  UNIX_TIMESTAMP(time) <= %u order by id desc limit 10;", GetRoleId(), startTime, endTime);
		if(!pDb->Query(sql))
			return;
		int num = pDb->GetRowNum();
		if(num > 0)
		{
			boost::recursive_mutex::scoped_lock lk(m_mutex);

			while((row = pDb->GetRow()) != NULL)
			{
				string data = row[0];
				m_zhaDanHistory.push_front(data);
			}
		}

		isInit = false;
	}
}

int CUser::GetAllZhenFaPower()
{
	CZhenFaCfgMgr &zfCfg = SingletonCZhenFaCfgMgr::instance();
	int allPower = 0;
	for(uint16 i=0;i < m_zhenfa.size();i++)
	{
		SZhenFaLevelUpData *p = zfCfg.GetLevelUpCfg(m_zhenfa[i].zhenfaId,m_zhenfa[i].zhenfaLevel);
		if(p == NULL)
			continue;
		allPower += p->zhandouli;
	}
	return allPower;
}

void CUser::SetZhaDanHistory(vector<string> &history)
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;

	char sql[40960];
	snprintf(sql, sizeof(sql), "insert INTO `zha_dan_log` (`id`,`type`, `role_id`, `data`) values ");

	for (uint32 i = 0; i < history.size(); i++)
	{
		int size = strlen(sql);
		snprintf(sql + size, sizeof(sql) - size, " (NULL, '%d','%d','%s'),", 0, GetRoleId(), history[i].c_str());
	}
	sql[strlen(sql) - 1] = ';';
	pDb->Query(sql);

	uint32 size = history.size();
	uint32 list_size = m_zhaDanHistory.size();

	if (size >= 10)
	{
		m_zhaDanHistory.clear();
		for (uint32 i = 0; i < 10; i++)
		{
			m_zhaDanHistory.push_back(history[size - 10 + i]);
		}
	}
	else if ((size + list_size) > 10)
	{
		int pop_num = list_size + size -10;
		for (int i = 0; i< pop_num; i++)
			m_zhaDanHistory.pop_front();

		for (uint32 i = 0; i < history.size(); i++)
			m_zhaDanHistory.push_back(history[i]);
	}
	else
	{
		for (uint32 i = 0; i < history.size(); i++)
			m_zhaDanHistory.push_back(history[i]);
	}

}

void CUser::GetZhaDanHistory(vector<string> &history)
{
	history.clear();
	list<string>::iterator j;
	for (j = m_zhaDanHistory.begin(); j != m_zhaDanHistory.end(); ++j)	 
		history.push_back(*j);
}


//add by zhudaolong 2017.11.02
void CUser::InitTHGHistory()
{
	if( !isInitTHGHistory )
	{
		InitHDShowHIstory(CHuoDongAwardManager::TAOHUAGENG);
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		GetHDShowHIstory(1, m_THGHistory,CHuoDongAwardManager::TAOHUAGENG);
		if( m_THGHistory.size() > 20)
			for(uint32 i = 0;i < (m_THGHistory.size() - 20); i++)		//历史缓存的最高条数为20
				m_THGHistory.erase(m_THGHistory.begin());
		isInitTHGHistory = true;	//证明已经初始化过历史数据
	}
}
void CUser::AddTHGHistory(uint32 item, uint32 item_num)
{
	vector<string> getLog;
	vector<string> giveLog;
	char buff[256];
	snprintf(buff, sizeof(buff), "%s*%d", GetItemName(item), item_num);
	getLog.push_back(buff);
	
	HdShowHistoryNode tmp_history;
	int tmp_time = GetSysTime();
	tmp_history.time = tmp_time;
	tmp_history.data = buff;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(m_THGHistory.size() >= 20)		//历史缓存的最高条数为20
	{
		m_THGHistory.erase(m_THGHistory.begin());
	}
	m_THGHistory.push_back(tmp_history);
	//SetHDShowHIstory(1, getLog,hd_type);
	//添加到数据库中
	AddHDShowLog(GetRoleId(), giveLog, GetRoleId(), getLog,CHuoDongAwardManager::TAOHUAGENG);
}
void CUser::GetTHGHistory(vector<HdShowHistoryNode> &history)
{
	history.clear();
	vector<HdShowHistoryNode>::iterator iter = m_THGHistory.begin();
	for(; iter != m_THGHistory.end(); iter++)
		history.push_back(*iter);
}

void CUser::InitHDShowHIstory(uint32 hd_type)
{
	map<uint32, bool>::iterator it = m_isLoadHistory.find(hd_type);
	if (it == m_isLoadHistory.end())
		return;
	
	if (it->second)
	{
		HDShowHistoryList showList;

		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		char sql[512];
		char **row = NULL;
		if(pDb == NULL)
			return;

		uint32 roleId = GetRoleId();
		uint32 startTime = SingletonCHuoDongAwardManager::instance().GetHuoDongStartTime(hd_type);
		snprintf(sql, sizeof(sql), "(select data,type,time from hd_show_log where hd_type = %d and role_id=%d and type = 0 and start_time = %d order by time desc limit 10) \
								UNION (select data,type,time from hd_show_log where hd_type = %d and role_id=%d and type = 1 and start_time = %d order by time desc limit 10)",
								hd_type,roleId,startTime,hd_type,roleId,startTime);
		if(!pDb->Query(sql))
			return;
		int num = pDb->GetRowNum();
		if(num > 0)
		{
			boost::recursive_mutex::scoped_lock lk(m_mutex);
	
			while((row = pDb->GetRow()) != NULL)
			{
				HdShowHistoryNode history;
				history.data = row[0];
				history.time = (uint32)atoi(row[2]);
				uint32 type = (uint32)atoi(row[1]);
				showList.showHistory[type].push_front(history);
			}
			m_showHistory.insert(make_pair(hd_type,showList));
		}
	
		it->second = false;
	}
}

void CUser::SetHDShowHIstory(uint8 type, vector<string> &history,uint32 hd_type)
{
	map<uint32,HDShowHistoryList>::iterator it = m_showHistory.find(hd_type);
	HDShowHistoryList *historyList = NULL;
	if (it == m_showHistory.end())
	{
		HDShowHistoryList showList;
		m_showHistory.insert(make_pair(hd_type,showList));
		map<uint32,HDShowHistoryList>::iterator it2 = m_showHistory.find(hd_type);
		historyList = &it2->second;
	}
	else
	{
		historyList = &it->second;
	}
	
	uint32 size = history.size();
	uint32 list_size = historyList->showHistory[type].size();

	if ((size + list_size) > 10)
	{
		int pop_num = list_size + size -10;
		for (int i = 0; i< pop_num; i++)
			historyList->showHistory[type].pop_front();

	}
	
	for (uint32 i = 0; i < history.size(); i++)
	{
		HdShowHistoryNode historyNode;
		historyNode.time = GetSysTime();
		historyNode.data = history[i];
		historyList->showHistory[type].push_back(historyNode);
	}
}

void CUser::GetHDShowHIstory(uint8 type, vector<HdShowHistoryNode> &history,uint32 hd_type)
{
	history.clear();
	map<uint32,HDShowHistoryList>::iterator it = m_showHistory.find(hd_type);
	if (it == m_showHistory.end())
		return;

	list<HdShowHistoryNode>::iterator j;
	for (j = it->second.showHistory[type].begin(); j != it->second.showHistory[type].end(); ++j)	 
		history.push_back(*j);
}

void CUser::InitJiaoYiHangRecord()
{
	uint32 myRoleId = GetRoleId();
	if (m_isLoadJiaoYiHangRecord)
	{
		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		char sql[512];
		char **row = NULL;
		if(pDb == NULL)
			return;

		uint32 roleId = GetRoleId();
		//										0         1         2         3          4      5        6    7
		snprintf(sql, sizeof(sql), "(select seller_id,seller_name,buyer_id,buyer_name,sell_yb,buy_gold,unix_timestamp(time),state from jiaoyi_record \
									where (seller_id=%d or buyer_id=%d) and (state = %d or state = %d) order by time desc limit 20) \
								UNION (select seller_id,seller_name,buyer_id,buyer_name,sell_yb,buy_gold,unix_timestamp(time),state from jiaoyi_record \
								where (seller_id=%d or buyer_id=%d) and state = %d order by time desc limit 20);",
									roleId,roleId,CJiaoYiHangManager::CHANNEL_SELL,CJiaoYiHangManager::OVER_TIME,roleId,roleId,CJiaoYiHangManager::SELL);

		if(!pDb->Query(sql))
			return;
		int num = pDb->GetRowNum();
		if(num > 0)
		{
			boost::recursive_mutex::scoped_lock lk(m_mutex);
			m_jiaoYiRecord[0].clear();
			m_jiaoYiRecord[1].clear();
			while((row = pDb->GetRow()) != NULL)
			{
				uint32 seller_id = (uint32)atoi(row[0]);
				string seller_name = row[1];
				uint32 buyer_id = (uint32)atoi(row[2]);
				string buyer_name = row[3];
				int sell_yb = (int)atoi(row[4]);
				int buy_gold = (int)atoi(row[5]);
				uint32 time = (uint32)atoi(row[6]);
				uint32 state = (uint32)atoi(row[7]);

				HdShowHistoryNode record;
				record.time = time;
				if (state == CJiaoYiHangManager::SELL)
				{
					if (seller_id == myRoleId)
					{
						record.data = CreateJiaoYiRecord(buyer_name,sell_yb,buy_gold,CJiaoYiHangManager::SELL);
						m_jiaoYiRecord[CJiaoYiHangManager::SELL_RECORD].push_front(record);
					}

					if (buyer_id == myRoleId)
					{
						record.data = CreateJiaoYiRecord(buyer_name,sell_yb,buy_gold,CJiaoYiHangManager::BUY);
						m_jiaoYiRecord[CJiaoYiHangManager::BUY_RECORD].push_front(record);
					}
				}
				else 
				{
					record.data = CreateJiaoYiRecord(buyer_name,sell_yb,buy_gold,state);
					m_jiaoYiRecord[CJiaoYiHangManager::SELL_RECORD].push_front(record);
				}
			}
		}
	
		m_isLoadJiaoYiHangRecord = false;
	}
}

void CUser::AddJiaoYiHangRecord(HdShowHistoryNode record,uint32 state)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	
	uint32 list_size = m_jiaoYiRecord[state].size();

	if (list_size > 20)
	{
		m_jiaoYiRecord[state].pop_front();
	}
	
	m_jiaoYiRecord[state].push_back(record);
}

void CUser::MakeJiaoYiHangRecord(CNetMessage &msg)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	const int size = 2;
	msg<<size;
	for (int i = 0; i < size; i++)
	{
		msg<<(int)i;
		msg<<(int)m_jiaoYiRecord[i].size();
		list<HdShowHistoryNode>::iterator j;
		for (j = m_jiaoYiRecord[i].begin(); j != m_jiaoYiRecord[i].end(); ++j)	 
			msg<<(uint32)j->time<<j->data;
	}
}

bool CUser::CanWorldTransPort(int trans_sceneId)
{
	if(m_pScene == NULL)
		return false;
	uint8 type = m_pScene->GetWorldTransType();
	if(type == 1)
	{
		return true;
	}
	else if(type == 2)
	{
		uint16 srcSceneId = m_pScene->GetSrcSceneId();
		if(srcSceneId == trans_sceneId)
		{
			return true;
		}
		else
		{
			if((srcSceneId >= KUN_LUN_SHAN_SCENE_ID && srcSceneId < KUN_LUN_SHAN_SCENE_ID+30) 
				&& (trans_sceneId >= KUN_LUN_SHAN_SCENE_ID && trans_sceneId < KUN_LUN_SHAN_SCENE_ID+30))
				return true;
			return false;
		}
	}
	else if(type == 3)
	{
		return false;
	}
	return false;
}

void CUser::UpdateInfo()
{
	SendUpdateInfo(EUUT_LightEffect);
	SendUpdateInfo(EUUT_AllAttrType);
}

void CUser::GetFacePos(uint8 &x,uint8 &y)
{
	x = m_xPos; y = m_yPos;
	switch (m_face)
	{
		case 2:
			y = m_yPos-1;
			break;
		case 4:
			x = m_xPos-1;
			break;
		case 6:
			x = m_xPos + 1;
			break;
		case 8:
			y = m_yPos + 1;
			break;
	}
}

uint16 CUser::GetMoveSpeed()
{
	int speed = 252;
	return speed;
}

bool CUser::Move(uint16 x,uint16 y)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_xPos = x;
	m_yPos = y;
	return true;
}

void CUser::SetOrigPos(uint16 pos_x,uint16 pos_y)
{
	m_xOrig = pos_x;
	m_yOrig = pos_y;
}

void CUser::GetOrigPos(uint16 &pos_x,uint16 &pos_y)
{
	pos_x = m_xOrig;
	pos_y = m_yOrig;
}

void CUser::SetFace(uint8 face)
{
	m_face = face;
}

void CUser::EnterScene(CScene *pScene)
{
	UserJump(true);
	if(pScene == NULL)
		return;
	CCallScript *pScript = pScene->GetScript();
	if(pScript != NULL)
	{
		if((m_teamId == 0) || (m_teamId == m_roleId))
		{
			pScript->Call("EnterScene","u",this);
			SetCallScript(pScript->GetScriptId());
#ifdef DEBUG
			cout<<"call script:"<<pScene->GetId()+10000<<endl;
#endif
		}
	}

	pScene->ChangeScene(this,m_pScene);

	m_pScene = pScene;
	if(m_pScene != NULL)
		SetData32(3,m_pScene->GetId());

	if (pScene->GetId() == 51)
	{
		SetExtData32(461, GetSysTime() + CScene::MATCH_CD);
		SetExtData32(462, 0);
		if (!HaveBitSet(199))
		{
			pScene->SetUserJiFen(GetRoleId(), m_name, 10);
			SetBitSet(199);
		}
	}
}

void CUser::SendLeiTaiJifen()
{
	CSceneManager &scene = SingletonSceneManager::instance();
	CScene *pScene = scene.FindScene(LEI_TAI_ID2);
	if (pScene == NULL)
		return;
	int leftTime = CSceneManager::GetActivityFinishTime(SOT_LeiTaiSai);
	CNetMessage leiTaiMsg;
	leiTaiMsg.SetType(MSG_LEI_TAI_SAI);
	uint32 now = GetSysTime();
	uint32 nextMatch = GetExtData32(461);
	uint32 matchBegin = GetExtData32(462);
	leiTaiMsg << (uint8)2 << pScene->GetUserJiFen(GetRoleId()) << leftTime;
	leiTaiMsg << (uint8)GetExtData8(639) << (uint8)CScene::MATCH_FAILD_CNT << GetData8(1);
	uint16 matchCd = nextMatch > now ? nextMatch - now : 0;
	uint16 matchTime = matchBegin == 0 ? 0 : now - matchBegin;
	leiTaiMsg << matchCd << matchTime;
	CSocketServer &sock = SingletonSocket::instance();
	sock.SendMsg(GetSock(), leiTaiMsg);
}

void CUser::ExitFubenToDefaultPos(uint16 &sceneId)
{
	if(GetKuaFuState() != EKFS_IN_LOCAL)
		return;
	if(GetFightId() > 0)
		return;
	int sId = EXIT_FB_SCENE_ID, pX = EXIT_FB_SCENE_X, pY = EXIT_FB_SCENE_Y;
	GetEnterPos(sId,pX,pY);
	sceneId = sId;
	m_xPos = pX;
	m_yPos = pY;
}

void CUser::ExitBangZhanScene(uint16 &sceneId)
{
	if(GetKuaFuState() != EKFS_IN_LOCAL)
		return;
	if(GetFightId() > 0)
		return;
#ifndef KUA_FU
	if(sceneId != BP_FIGHT_SID && sceneId != BP_FIGHT_READY_SID)
		return;
	
	int wday = GetWeekDay();
	int curTime = GetHour()*100 + GetMinute();
	if((wday == 3 || wday == 6) && (curTime >= BP_FIGHT_READY_START && curTime < BP_FIGHT_BOX_END) && (m_bangpai > 0))
	{
		if(sceneId != BP_FIGHT_READY_SID)
		{
			sceneId = BP_FIGHT_READY_SID;
			m_xPos = 656;
			m_yPos = 432;
		}
	}
	else
	{
		sceneId = BP_FIGHT_EXIT_SID;
		m_xPos = BP_FIGHT_EXIT_X;
		m_yPos = BP_FIGHT_EXIT_Y;
	}
#else
	if(sceneId != KUAFU_BZ_SID && sceneId != KUAFU_BZ_READY_SID)
		return;
	
	int wday = GetWeekDay();
	int curTime = GetHour()*100 + GetMinute();
	if((wday == 2 || wday == 5) && (curTime >= BP_FIGHT_READY_START && curTime < BP_FIGHT_BOX_END) && (m_bangpai > 0))
	{
		if(sceneId != KUAFU_BZ_READY_SID)
		{
			sceneId = KUAFU_BZ_READY_SID;
			m_xPos = 656;
			m_yPos = 432;
		}
	}
	else
	{
		sceneId = KUAFU_EXIT_SID;
		m_xPos = KUAFU_EXIT_X;
		m_yPos = KUAFU_EXIT_Y;
	}
#endif
}

void CUser::EnterLastScene(uint16& sceneId)
{
	uint32 day = GetYDay();
	if (m_shortArray[MAX_SAVE_NUM - 2] != day || !CSceneManager::IsInActivityTime(SOT_LeiTaiSai))
	{
		int outSceneId = 0;
		int outX = 0;
		int outY = 0;
		GetEnterPos(outSceneId, outX, outY);
		m_xPos = outX;
		m_yPos = outY;
		sceneId = outSceneId;
	}
}

void CUser::NoLockBackLastScene()
{
	int outSceneId = 0;
	int outX = 0;
	int outY = 0;
	GetEnterPos(outSceneId, outX, outY);
	TransportUser(this, outSceneId, outX, outY, 0);
}


void CUser::EnterFuBen_IfExit(uint16 &sceneId)
{
	if(GetKuaFuState() != EKFS_IN_LOCAL)
		return;
	if(GetFightId() > 0)
		return;
	CSceneManager &sceneMgr = SingletonSceneManager::instance();
	m_pScene = sceneMgr.FindScene(GetData32(3));
	
	if(sceneId == FISH_ID2) 	// 钓鱼
	{
		ExitFubenToDefaultPos(sceneId);
		return;
	}
	else if(sceneId >= KUN_LUN_SHAN_SCENE_ID && sceneId < KUN_LUN_SHAN_SCENE_ID+30)	// 昆仑山
	{
		if(CSceneManager::IsInActivityTime(SOT_Kunlunshan))
		{
			if(m_pScene != NULL)
				return;
		}
		else
		{
			ExitFubenToDefaultPos(sceneId);
		}
		// 恢复坐骑
		uint8 index = GetExtData8(144);
		if(index != 0xff)
		{
			SetExtData8(144,0xff);
			CNetMessage msg;
			SetMountState(msg,index);
		}
	}

	if(m_pScene == NULL) // 副本地图已经清除了
	{
		ExitFubenToDefaultPos(sceneId);
	}
	else
	{
		if(!m_pScene->IsFuBen())
		{
			ExitFubenToDefaultPos(sceneId);
			return;
		}
		
		// 副本地图还在
		CScene * pNxt = NULL;
		//if (!sceneMgr.IsFuBenEmpty(m_pScene)) // 组队进入副本
		if ((pNxt = sceneMgr.GetCurrentFuBen(m_pScene)) != NULL) // 组队进入副本
		{
			list<uint32> userList;
			pNxt->GetUserList(userList);
			if (userList.size() == 1 && (*userList.begin()) == GetRoleId())
			{
				cout << LANGUAGE_TRANSFORM_1934 << endl;
			}
			else if (GetFightId() != 0)
			{
				cout << LANGUAGE_TRANSFORM_1935 << endl;
			}
			else
			{
				cout << LANGUAGE_TRANSFORM_1936 << endl;
				ExitFubenToDefaultPos(sceneId);
			}
			return;
		}
		
		if (GetSysTime() - GetExtData32(84) > 5*60) // 登出超过五分钟 传出副本
		{
			// 先处理为掉线就踢出副本
//			cout << "副本地图还在 个人超时了" << endl;
			if ( // 目前先踢出副本，以后要回归队伍。
				(sceneId == COPY_ID_QIANG_HUA) || // 日常副本 强化副本
//				(sceneId == COPY_ID_CHONG_WU_1) || // 日常副本 神将副本
				(sceneId == COPY_ID_MONEY) ||		// 金币副本
				(sceneId == COPY_ID_SHENG_JIE) ||	// 升阶副本
				(sceneId == COPY_ID_QIAN_NENG) ||	// 潜能副本
				(sceneId == COPY_ID_XIANG_QIAN) ||	// 镶嵌副本
				(sceneId == COPY_ID_CUI_LIAN) ||	// 洗炼副本
				(sceneId == COPY_ID_CHONG_KAI)	// 神将铠副本
				)
			{
				ExitFubenToDefaultPos(sceneId);
			}
		}
		else	// 5分钟内上线,如果没怪退出指定副本
		{
			if((sceneId == COPY_ID_QIANG_HUA) || // 日常副本 强化副本
//				(sceneId == COPY_ID_CHONG_WU_1) || // 日常副本 神将副本
				(sceneId == COPY_ID_MONEY) ||		// 金币副本
				(sceneId == COPY_ID_SHENG_JIE) ||	// 升阶副本
				(sceneId == COPY_ID_QIAN_NENG) ||	// 潜能副本
				(sceneId == COPY_ID_XIANG_QIAN) ||	// 镶嵌副本
				(sceneId == COPY_ID_CUI_LIAN) ||	// 洗炼副本
				(sceneId == COPY_ID_CHONG_KAI)	// 神将铠副本
				)
			{
				if(m_pScene->GetVisibleMonsterBossNum() == 0)
					ExitFubenToDefaultPos(sceneId);
			}
		}
	}
}

void CUser::EnterFuBen(uint16 sceneId)
{
	CSceneManager &sceneMgr = SingletonSceneManager::instance();
	m_pScene = sceneMgr.FindScene(GetData32(3));
	if(m_pScene == NULL)
	{
		int sid,x,y;
		GetEnterPos(sid,x,y);
		m_pScene = sceneMgr.FindScene(sid);
		if(m_pScene != NULL)
			m_pScene->ChangeScene(this,NULL);
	}
	else
	{
		if(sceneId >= KUN_LUN_SHAN_SCENE_ID && sceneId < KUN_LUN_SHAN_SCENE_ID+30)	// 昆仑山
		{
			if(CSceneManager::IsInActivityTime(SOT_Kunlunshan))
			{
				if(m_pScene->GetUserNum() >= KUN_LUN_SHAN_ROOM_LIMIT)
				{
					CScene *pScene = sceneMgr.GetKunLunShanFirstScene();
					if(pScene == NULL)
						return;
					int idx = 1;
					while(pScene->GetUserNum() >= KUN_LUN_SHAN_ROOM_LIMIT)
					{
						idx++;
						pScene = sceneMgr.GetKunLunShanSceneByIndex(idx);
						if(pScene == NULL)
							return;
					}
					m_pScene = NULL;
					EnterScene(pScene);
					return;
				}
			}
			else
			{
				return;
			}
		}
		else if(sceneId == COPY_ID_SHI_LIAN)
		{
			SendShiLianGetAwardPanel();
		}
		m_pScene->ChangeScene(this,NULL);
	}
}

SharePetPtr CUser::GetPet(uint16 petId)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return NoLockGetPet(petId);
}

SharePetPtr CUser::NoLockGetPet(uint16 petId)
{
	CPetMapIt it = m_pet.find(petId);
	if(it != m_pet.end())
		return it->second;

	SharePetPtr pet;
	return pet;
}

void CUser::SetPetZhongCheng(uint8 pos,int zhongcheng)
{
/*
	boost::recursive_mutex::scoped_lock lk(m_mutex);

	if((pos >= m_petNum) || (m_pet[pos].get() == NULL))
	{
		return;
	}
	m_pet[pos]->zhongcheng = zhongcheng;
	UpdatePetInfo(pos,13,zhongcheng);
*/
}

bool CUser::MakePetById(uint16 petId,CNetMessage &msg)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return NoLockMakePetById(petId,msg);
}

bool CUser::NoLockMakePetById(uint16 petId,CNetMessage &msg)
{
	if(petId == 0)
	{
		msg<<(uint16)0;
		return false;
	}
	
	CPetMapIt it = m_pet.find(petId);
	if(it == m_pet.end())
	{
		msg<<(uint16)0;
		return false;
	}
	SPet *pPet = it->second.get();
	if(pPet == NULL)
	{
		msg<<(uint16)0;
		return false;
	}
	MakePetData(pPet,msg);
	return true;
}

uint8 CUser::GetPetZhenFaIdx(uint16 petId)
{
	if(petId == 0)
		return 0;
	for (uint8 i = 0; i < m_zhenfaMember.size(); i++)
	{
		if (m_zhenfaMember[i].mem_type == EZFMT_PET && m_zhenfaMember[i].mem_id == petId)
			return (i + 1);
	}
	return 0;
}

uint8 CUser::GetChuZhanIdx(uint16 petId)
{
	if(petId == 0)
		return 0;
	for (uint8 i = 0; i < m_chuzhan.size(); i++)
	{
		if (m_chuzhan[i] == petId)
			return (i + 1);
	}
	return 0;
}

bool CUser::MakePetData(SPet *pPet,CNetMessage &msg)
{
	if(pPet == NULL || pPet->id == 0)
	{
		msg<<(uint16)0;
		return false;
	}
	uint8 zhenfaPos = GetPetZhenFaIdx(pPet->id);
	uint32 maxExp = SingletonCPetCfgMgr::instance().GetLevelUpExp(pPet->level);
	msg<<pPet->id<<zhenfaPos<<pPet->name<<pPet->star<<pPet->breakLevel<<pPet->level<<pPet->exp<<maxExp<<pPet->zhanDouli;
	msg<<pPet->basicAttr.attack<<pPet->basicAttr.wufang<<pPet->basicAttr.fafang<<pPet->basicAttr.maxHp<<pPet->basicAttr.speed<<pPet->basicAttr.mingzhong<<pPet->basicAttr.shanbi<<pPet->basicAttr.baoji<<pPet->basicAttr.baojikang;
	msg<<pPet->basicAttr.zengshangLv<<pPet->basicAttr.wumianLv<<pPet->basicAttr.famianLv<<pPet->basicAttr.baojiAdd<<pPet->basicAttr.fanjiLv<<pPet->basicAttr.fanjiAdd;
	msg<<pPet->basicAttr.fanjikangLv<<pPet->basicAttr.lianjiLv<<pPet->basicAttr.lianjiAdd<<pPet->basicAttr.lianjikangLv;
	msg<<pPet->basicAttr.fanzhenLv<<pPet->basicAttr.fanzhenAdd<<pPet->basicAttr.fanzhenkangLv<<pPet->basicAttr.fumianAdd<<pPet->basicAttr.fumianKangAdd;
	msg << pPet->basicAttr.attackRatio << pPet->basicAttr.wufangRatio << pPet->basicAttr.fafangRatio << pPet->basicAttr.maxHpRatio;
	U8tU16Map& xlmap = pPet->curXiuLianCnts;
	uint8 xlSize = xlmap.size();
	msg << pPet->xiuLianLevel << xlSize;
	for (U8tU16MapIt xit = xlmap.begin(); xit != xlmap.end(); ++xit)
	{
		msg << xit->first << xit->second;
	}
	uint16 pos = msg.GetDataLen();
	uint8 skillNum = 0;
	msg<<skillNum;
	for(uint8 i=0;i < sizeof(pPet->skill)/sizeof(pPet->skill[0]);i++)
	{
		if(pPet->skill[i] > 0)
		{
			msg<<i<<pPet->skill[i]<<pPet->skillLevel[i];
			skillNum++;
		}
	}
	msg.WriteData(pos,&skillNum,sizeof(skillNum));
	return true;
}

void CUser::MakePet(CNetMessage &msg)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	msg<<m_gensuiPet;
	uint16 numPos = msg.GetDataLen();
	uint8 petNum = 0;
	msg<<petNum;
	for(CPetMapIt it=m_pet.begin(); it != m_pet.end(); it++)
	{
		SPet *pPet = it->second.get();
		if(pPet == NULL)
			continue;
		if(MakePetData(pPet,msg))
			petNum++;
	}
	msg.WriteData(numPos,&petNum,sizeof(petNum));
}

bool CUser::NoLockAddPet(SharePetPtr &pet,uint16 *toItemId,uint16 *toItemNum)
{
	SPet *pPet = pet.get();
	if(pet.get() == NULL || pPet->id == 0)
		return false;
	if(NoLockHavePet(pPet->id))	// 转化成碎片
	{
		SPetBasicData* pData = SingletonCPetCfgMgr::instance().GetPetCfg(pPet->id);
		if (pData != NULL)
		{
			if (toItemId != NULL && toItemNum != NULL)
			{
				*toItemId = pData->shengxingItemId;
				*toItemNum = pData->transferItemNum;
			}
			AddPackage(pData->shengxingItemId, pData->transferItemNum);
		}
		return true;
	}
	pet->level = 1;
	if(!m_pet.insert(make_pair(pPet->id,pet)).second)
	{
		return false;
	}
	pet->Init(this);
	
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_UPDATE_PET);
	msg<<(uint8)1;
	MakePetData(pPet,msg);
	sock.SendMsg(m_sock,msg);

	uint8 chengPetNum = 0;	// 橙神将数量
	for (CPetMapIt it = m_pet.begin(); it != m_pet.end(); ++it)
	{
		if (it->second->quality > PQT_PURPLE)
			++chengPetNum;
	}

	if (chengPetNum >= 1 && !HaveSGBitSet(101))
		FinishStageGoalSection(1, 1); // 拥有1只橙色神将
	if (chengPetNum >= 4 && !HaveSGBitSet(111))
		FinishStageGoalSection(2, 1); // 拥有4只橙色神将
	if (chengPetNum >= 7 && !HaveSGBitSet(121))
		FinishStageGoalSection(3, 1); // 拥有7只橙色神将

	SingletonCMissionManager::instance().VerifyNewBranchMissionFinish(this, EMISS_DC_68); // TODO
	SingletonCMissionManager::instance().VerifyNewBranchMissionFinish(this, EMISS_DC_80, pPet->id);

	return true;
	

/*
	uint8 ziPetNum = 0;		// 紫神将数量
	uint8 chengPetNum = 0;	// 橙神将数量
	uint8 jinPetNum = 0;	// 金神将数量
	// 用等于判断，减少调用
	if (((ziPetNum + chengPetNum + jinPetNum) >= 3) && (!HaveSGBitSet(101)))
		FinishStageGoalSection(1,1); // 拥有3只紫色神将
	if (((chengPetNum + jinPetNum)>= 2) && (!HaveSGBitSet(111)))
		FinishStageGoalSection(2,1); // 拥有2只橙色神将
	if (((chengPetNum + jinPetNum) >= 4) && (!HaveSGBitSet(121)))
		FinishStageGoalSection(3,1); // 拥有4只橙色神将

	CheckMissionZiPet(ziPetNum); // 任务校验

	if (pPet->quality >= PQT_PURPLE)
		SetExtData8(580,GetExtData8(580) + 1);

	if (pPet->quality >= PQT_ORANGE)
		SetExtData8(581,GetExtData8(581) + 1);

	return true;
*/
}

bool CUser::AddPet(SharePetPtr &pPet,uint16 *toItemId,uint16 *toItemNum)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return NoLockAddPet(pPet,toItemId,toItemNum);
}

void CUser::SetPet(char *petStr,bool useDefName)
{
	CPetCfgManager &mgr = SingletonCPetCfgMgr::instance();

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if((petStr == NULL) || (strlen(petStr) == 0))
	{
		m_gensuiPet = 0;
		m_pet.clear();
		return;
	}

	uint32 size = 300;
	uint32 len = size*sizeof(SPet) + MAX_CHU_ZHAN_NUM*MAX_ZHEN_RONG_NUM + 512;
	uint8 *pTemp = new uint8[len];
	if(!UnCompress(petStr,pTemp,len))
	{
		delete[] pTemp;
		return;
	}
	if(len == 0)
	{
		delete[] pTemp;
		return;
	}

	uint32 pos = 0;
	uint8 petNum = 0;
	ReadDataFromBuf((char *)pTemp,&petNum,sizeof(petNum),pos,len);

	uint8 extNum = pTemp[pos++];
	uint8 num = 0;
	for(uint8 i = 0; i < petNum; i++)
	{
		SPet *pPet = new SPet;
		pPet->Clear();
		uint32 rpos = ReadPetBuf(pPet,pTemp+pos,len-pos,useDefName, extNum);
		if(rpos == 0)
		{
			delete pPet;
			continue;
		}
		pPet->chuzhanFlag = GetChuZhanIdx(pPet->id) > 0;
		pos += rpos;
		
		if(!mgr.InitBasicData(pPet))
		{
			delete pPet;
			continue;
		}
		CPetMapIt it = m_pet.find(pPet->id);
		if(it != m_pet.end())
		{
			delete pPet;
			continue;
		}
		
		if (pPet->chuzhanFlag  == 0)
			pPet->Init(this);
		else
		{
			SPetBasicData *pCfg = mgr.GetPetCfg(pPet->id);
			if (pCfg != NULL)
			{
				for (uint8 bi = 0; bi < pPet->breakLevel; ++bi)
				{
					AddTeamBreakAttr(pCfg->topoAttrs[bi].teamAttrs);
				}
			}
		}

		SharePetPtr pet(pPet);
		if(!m_pet.insert(make_pair(pPet->id,pet)).second)
		{
			delete pPet;
			continue;
		}
		num++;
	}
	delete[] pTemp;
}

void CUser::GetPet(string &str)
{
	uint32 pos = 0;
	uint32 size = 2*m_pet.size();
	uint32 bufLen = size*sizeof(SPet) + MAX_ZHEN_RONG_NUM*MAX_CHU_ZHAN_NUM + 512;
	uint8 *hex = new uint8[bufLen];
	uint8 num = 0;
	CopyDataToBuf((char *)hex,&num,sizeof(num),pos,bufLen);
	hex[pos++] = SPet::extNum;

	for(CPetMapIt it=m_pet.begin(); it != m_pet.end(); it++)
	{
		SPet *pPet = it->second.get();
		if(pPet == NULL)
			continue;
		uint32 wpos = WritePetBuf(pPet,hex+pos,bufLen-pos);
		if(wpos == 0)
			continue;
		pos += wpos;
		num++;
	}
	hex[0] = num;
	if(!Compress(hex,pos,str))
		str.clear();
	delete hex;
}

// 增加基础坐骑
void CUser::AddMount(uint8 mountId)
{
	if (mountId > 0)
	{
		SMountConfig *pCfg = SingletonMountCfgMgr::instance().GetCfg(mountId);
		if(pCfg == NULL)
			return;
		m_mount.AddMount(mountId);

		// 更新个人数据
		CSocketServer &sock = SingletonSocket::instance();
		CNetMessage msg;
		msg.SetType(MSG_MOUNT);
		msg<<(uint8)1;
		MakeMount(msg);
		sock.SendMsg(m_sock, msg);

		// 更新个人数据
		msg.ReWrite();
		msg.SetType(MSG_MOUNT);
		msg << (uint8)9 << mountId;
		sock.SendMsg(m_sock, msg);

		// 更新场景数据
		CScene *pScene = GetScene();
		if(pScene == NULL)
			return;
		pScene->UpdateUserInfo(this,ESRT_Mount_State);
		InitAllPet();
		InitAndUpdate();
		CheckFBLevel();

		SingletonCMissionManager::instance().UpdateDCMissionComplate(this, EMISS_DC_40, mountId);
	}
}

void CUser::SetMount(char *pMount)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_mount.SetMount(pMount);
}

void CUser::GetMount(string &str)
{
	m_mount.GetMount(str);
}

//add by zhudaolong
bool CUser::HaveMount(uint8 id)
{
	return m_mount.HaveMount(id);
}
void CUser::SetWing(char *pWing)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_wing.SetWing(pWing);
}

void CUser::GetWing(string &str)
{
	m_wing.GetWing(str);
}

void CUser::GetZhenFa(string &str)
{
		const uint32 len = 1024;
		uint8 buf[1024];
	uint32 pos = 0;

	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		CopyDataToBuf((char *)buf,&m_useZhenFaIdx,sizeof(m_useZhenFaIdx),pos,len);
		uint8 num = m_zhenfa.size();
		CopyDataToBuf((char *)buf,&num,sizeof(num),pos,len);
		for(uint8 i=0;i < num;i++)
		{
			CopyDataToBuf((char *)buf,&(m_zhenfa[i].zhenfaId),sizeof(m_zhenfa[i].zhenfaId),pos,len);
			CopyDataToBuf((char *)buf,&(m_zhenfa[i].zhenfaLevel),sizeof(m_zhenfa[i].zhenfaLevel),pos,len);
		}

		num = m_zhenfaMember.size();
		CopyDataToBuf((char *)buf,&num,sizeof(num),pos,len);
		for(uint8 i=0;i < num;i++)
		{
			CopyDataToBuf((char *)buf,&(m_zhenfaMember[i].mem_type),sizeof(m_zhenfaMember[i].mem_type),pos,len);
			CopyDataToBuf((char *)buf,&(m_zhenfaMember[i].mem_id),sizeof(m_zhenfaMember[i].mem_id),pos,len);
		}

		num = m_chuzhan.size();
		CopyDataToBuf((char *)buf, &num, sizeof(num), pos, len);
		for (uint8 i = 0; i < num; i++)
		{
			CopyDataToBuf((char *)buf, &(m_chuzhan[i]), sizeof(m_chuzhan[i]), pos, len);
		}
	}
	
	if(!Compress(buf,pos,str))
		str.clear();
}

void CUser::SetZhenFa(char *pStr)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_zhenfa.clear();
	m_useZhenFaIdx = 0xff;
	uint32 zhenfaMemSize = m_zhenfaMember.size();
	for(uint32 i=0;i < zhenfaMemSize;i++)
		m_zhenfaMember[i].Clear();
	if(pStr == NULL || strlen(pStr) == 0)
		return;

	uint32 len = 1024;
	uint8 buf[1024];
	if(!UnCompress(pStr,buf,len))
		return;

	uint32 pos = 0;
	ReadDataFromBuf((char *)buf,&m_useZhenFaIdx,sizeof(m_useZhenFaIdx),pos,len);
	uint8 num = 0;
	ReadDataFromBuf((char *)buf,&num,sizeof(num),pos,len);
	for(uint8 i=0;i < num;i++)
	{
		SZhenFaData data;
		ReadDataFromBuf((char *)buf,&(data.zhenfaId),sizeof(data.zhenfaId),pos,len);
		ReadDataFromBuf((char *)buf,&(data.zhenfaLevel),sizeof(data.zhenfaLevel),pos,len);
		m_zhenfa.push_back(data);
	}
	
	ReadDataFromBuf((char *)buf,&num,sizeof(num),pos,len);
	if(num > zhenfaMemSize)
		return;
	for(uint8 i=0;i < num;i++)
	{
		ReadDataFromBuf((char *)buf,&(m_zhenfaMember[i].mem_type),sizeof(m_zhenfaMember[i].mem_type),pos,len);
		ReadDataFromBuf((char *)buf,&(m_zhenfaMember[i].mem_id),sizeof(m_zhenfaMember[i].mem_id),pos,len);
	}

	ReadDataFromBuf((char *)buf, &num, sizeof(num), pos, len);
	if (num > zhenfaMemSize)
		return;
	for (uint8 i = 0; i < num; i++)
	{
		uint16 petId;
		ReadDataFromBuf((char *)buf, &petId, sizeof(petId), pos, len);
		m_chuzhan[i] = petId;
	}

	if(m_zhenfa.empty() || (m_useZhenFaIdx != 0xff && m_useZhenFaIdx >= m_zhenfa.size()))
	{
		m_useZhenFaIdx = 0xff;
		return;
	}

	SZhenFaBasicCfg *pCfg = SingletonCZhenFaCfgMgr::instance().GetBasicCfg(m_zhenfa[m_useZhenFaIdx].zhenfaId);
	if(pCfg == NULL)
	{
		cout<<">> CUser::SetZhenFa can't find zhenfaId="<<m_zhenfa[m_useZhenFaIdx].zhenfaId<<endl;
		return;
	}
	for(uint8 i=0;i < zhenfaMemSize;i++)
	{
		m_zhenfaMember[i].fightPos = pCfg->fightPos[i];
	}
}

void CUser::CheckZhenFa()
{
	if(!m_zhenfa.empty() || m_zhenfaMember.empty())
		return;
	CZhenFaCfgMgr &mgr = SingletonCZhenFaCfgMgr::instance();
	uint16 addZhenFaId = mgr.GetDefaultId();
	SZhenFaBasicCfg *pCfg = mgr.GetBasicCfg(addZhenFaId);
	if(pCfg == NULL)
		return;

	SZhenFaData data;
	data.zhenfaId = addZhenFaId;
	data.zhenfaLevel = 1;
	m_zhenfa.push_back(data);
	m_useZhenFaIdx = 0;
	for(uint8 i=0;i < m_zhenfaMember.size();i++)
	{
		m_zhenfaMember[i].fightPos = pCfg->fightPos[i];
	}
}

uint16 CUser::GetUseZhenFaId()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(m_useZhenFaIdx >= m_zhenfa.size())
		return 0;
	return m_zhenfa[m_useZhenFaIdx].zhenfaId;
}

uint16 CUser::GetUseZhenFaLevel()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(m_useZhenFaIdx >= m_zhenfa.size())
		return 0;
	return m_zhenfa[m_useZhenFaIdx].zhenfaLevel;
}

uint16 CUser::GetZhenFaLevel(uint16 zhenfaId)
{
	if(zhenfaId == 0)
		zhenfaId = GetUseZhenFaId();
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint16 i=0;i < m_zhenfa.size();i++)
	{
		if(m_zhenfa[i].zhenfaId == zhenfaId)
			return m_zhenfa[i].zhenfaLevel;
	}
	return 0;
}

bool CUser::HaveZhenFa(uint16 zhenfaId)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint8 i=0;i < m_zhenfa.size();i++)
	{
		if(m_zhenfa[i].zhenfaId == zhenfaId)
		{
			return true;
		}
	}
	return false;
}

// 坐骑信息 发消息用
void CUser::MakeMount(CNetMessage &msg)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	int failCount = GetExtData8(3); // 强化失败次数
	int plusRate = 2*failCount; // 强化次数加成概率
	
	msg<<m_mount.m_num;
	for(uint8 i=0;i < m_mount.m_num;i++)
	{
		msg<<m_mount.m_id[i]<<m_mount.m_timeLimit[i]<<m_mount.GetMoveSpeed(i);
	}
	msg<<m_mount.m_useIndex<<m_mount.m_level<<(uint8)plusRate;
}
//发送坐骑强化信息
void CUser::MakeMountStrengthenMsg( CNetMessage &msg )
{
	msg<<m_mount.m_level<<m_mount.m_exp;
	int maxExp = 0;
	if(m_mount.m_level < SMount::MAX_LEVEL)
	{
		SMountQH *p = SingletonMountCfgMgr::instance().GetQHCfg(m_mount.m_level);
		if(p != NULL)
			maxExp = p->needExp;
	}
	msg<<maxExp;
}

// 翅膀信息 发消息用
void CUser::MakeWing(CNetMessage &msg)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	msg<<m_wing.m_useIndex<<m_wing.m_level<<m_wing.m_star<<m_wing.m_qh_exp;
	msg<<m_wing.m_num;
	for(uint8 i=0;i < m_wing.m_num;i++)
	{
		msg<<m_wing.m_id[i];
	}
}

// 坐骑强化 发消息用
bool CUser::StrengthenMount(CNetMessage& msg,int materialID ,int num)
{
	if(materialID < 2251 || materialID > 2254 || num == 0)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1956,TIPS_FAILURE_COLOR);
		return false;
	}

	SItemTemplate *pMaterial = SingletonItemManager::instance().GetItem(materialID);
	if(pMaterial == NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1956,TIPS_FAILURE_COLOR);
		return false;
	}
	{
		CMountConfigMgr &mgr = SingletonMountCfgMgr::instance();
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		// 条件校验
		if(m_mount.m_num == 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1939,TIPS_FAILURE_COLOR);
			return false;
		}
		if(m_mount.m_level >= SMount::MAX_LEVEL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1940,TIPS_FAILURE_COLOR);
			return false;
		}

		if(NoLockGetItemNum(materialID) < num)
		{
			char buf[128];
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1943,GetItemName(materialID));
			msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
			return false;
		}

		SMountQH *pQH = mgr.GetQHCfg(m_mount.m_level);
		if(pQH == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1940,TIPS_FAILURE_COLOR);
			return false;
		}		
		NoLockDelPackageById(materialID,num);
		
		//循环加经验升级
		m_mount.m_exp  += pMaterial->subValue * num;
		int addlevel = 0;
		while( m_mount.m_exp >= (uint32)pQH->needExp)
		{
			m_mount.m_exp -= (uint32)pQH->needExp;
			m_mount.m_level++;
			addlevel++;
			if(m_mount.m_level >= SMount::MAX_LEVEL)
			{
				m_mount.m_exp = 0;
				break;
			}
			if((pQH = mgr.GetQHCfg(m_mount.m_level)) == NULL)
				break;
		}
		if (addlevel > 0)
		{
			SingletonCMissionManager::instance().UpdateDCMissionComplate(this, EMISS_DC_41, addlevel);
		}

		msg<<PRO_SUCCESS<<m_mount.m_level<<m_mount.m_exp;
		int maxExp = 0;
		if(m_mount.m_level < SMount::MAX_LEVEL)
		{
			pQH = mgr.GetQHCfg(m_mount.m_level);
			if(pQH != NULL)
				maxExp = pQH->needExp;
		}
		msg<<maxExp<<MakeStringColor(LANGUAGE_TRANSFORM_1945,TIPS_SUCCESS_COLOR);

		SetExtData32(396,GetExtData32(396) + pMaterial->subValue * num);
	}
	InitAllPet();
	InitAndUpdate();
	CheckFBLevel();
	SetExtData8(20,GetExtData8(20)+1); // 每日活跃度 坐骑强化次数
	return true;
//	if((m_mount.level == 5) && (!HaveSGBitSet(119)))
//		FinishStageGoalSection(3,3); // 坐骑强化+5
}

// 强化翅膀
void CUser::StrengthenWing(uint8 type,uint16 itemId, uint16 num,CNetMessage& msg)
{
	const uint8 ITEM_STRENG = 1;
	const uint8 YB_STRENG = 2;
	
	if (type != ITEM_STRENG && type != YB_STRENG)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1956,TIPS_FAILURE_COLOR);
		return;
	}

	if(type == ITEM_STRENG && (itemId < 2538 || itemId > 2542 || num == 0))
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1951,TIPS_FAILURE_COLOR);
		return;
	}
	/*if(m_level < 30)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1952,TIPS_FAILURE_COLOR);
		return;
	}*/

	// type,itemId,exp,baojiRatio,count,yb
	const int item_exp[][6] = {{ITEM_STRENG,2538,10,20,0,0},{ITEM_STRENG,2539,30,20,0,0},{ITEM_STRENG,2540,90,20,0,0},{ITEM_STRENG,2541,270,20,0,0},{ITEM_STRENG,2542,810,20,0,0},{YB_STRENG,0,10,20,200,2000}};
	char buf[256];
	int addLevel = 0;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		// 条件校验
		if(m_wing.m_num == 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1953,TIPS_FAILURE_COLOR);
			return;
		}
		if(m_wing.m_level > (uint8)SWing::MAX_LEVEL || (m_wing.m_level == (uint8)SWing::MAX_LEVEL && m_wing.m_star >= SWing::MAX_STAR))
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1954,TIPS_FAILURE_COLOR);
			return;
		}
	
		if(type == ITEM_STRENG && GetItemNum(itemId) < num)
		{
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1955,GetItemName(itemId));
			msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
			return;
		}
		
		int totalExp = 0;
		int tarExp = 0;
		int baoJiRatio = 0;
		int baojiNum = 0;
		int count = 0;
		int costYB = 0;
		for(uint8 i=0;i < sizeof(item_exp)/sizeof(item_exp[0]);i++)
		{
			if((item_exp[i][0] == ITEM_STRENG && item_exp[i][1] == itemId) || (item_exp[i][0] == YB_STRENG))
			{
				if (item_exp[i][0] == ITEM_STRENG)
				{
					count = num;
				}
				else
				{
					count = item_exp[i][4];
					costYB = item_exp[i][5];
				}

				tarExp = item_exp[i][2];
				baoJiRatio = item_exp[i][3];
				break;
			}
		}

		if(type == YB_STRENG && GetTongBao() < costYB)
		{
			msg<<PRO_ERROR<<"";
			ShowJumpNotice(this,JUMP_NOTICE_YB);
			return;
		}

		if(tarExp == 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1956,TIPS_FAILURE_COLOR);
			return;
		}
		for(int i=0;i < count;i++)
		{
			if(Random(1,100) < baoJiRatio)
			{
				totalExp += 2*tarExp;
				baojiNum++;
			}
			else
				totalExp += tarExp;
		}

		if (type == ITEM_STRENG)
		{
			NoLockDelPackageById(itemId,count);
			SaveUseItem(m_roleId,itemId,LANGUAGE_TRANSFORM_1957,count);
		}
		else
		{
			AddTongBao(-costYB);
			ItemCurrencyLog(GetRoleId(),0,0,0,costYB,GetTongBao(),YBL_STRENG_WING);
		}

		int srcLevel = m_wing.m_level;
		int srcStar = m_wing.m_star;
		int newWingId = m_wing.AddQiangHuaExp(totalExp);
		if (type == ITEM_STRENG)
		{
			if(baojiNum > 0)
				snprintf(buf,sizeof(buf)-1,LANGUAGE_TRANSFORM_1958,(int)count,totalExp,baojiNum);
			else
				snprintf(buf,sizeof(buf)-1,LANGUAGE_TRANSFORM_1959,(int)count,totalExp);
		}
		else
		{
			if(baojiNum > 0)
				snprintf(buf,sizeof(buf)-1,LANGUAGE_LLD_0039,totalExp,baojiNum);
			else
				snprintf(buf,sizeof(buf)-1,LANGUAGE_LLD_0040,totalExp);
		}
		
		if(srcLevel != m_wing.m_level || srcStar != m_wing.m_star)
			addLevel = m_wing.m_level - srcLevel;
		if(srcLevel == m_wing.m_level && srcStar != m_wing.m_star)
		{
			SendSysInfo(this,MakeStringColor(buf,TIPS_SUCCESS_COLOR).c_str());
			
			int addStar = (int)m_wing.m_star - srcStar;
			if(addStar%2 == 0)
				snprintf(buf,sizeof(buf)-1,LANGUAGE_TRANSFORM_1960,addStar,addStar/2);
			else if(addStar == 1)
				snprintf(buf,sizeof(buf)-1,LANGUAGE_TRANSFORM_1961,addStar);
			else
				snprintf(buf,sizeof(buf)-1,LANGUAGE_TRANSFORM_1962,addStar,addStar/2);
		}
		msg<<PRO_SUCCESS<<m_wing.m_level<<m_wing.m_star<<m_wing.m_qh_exp<<newWingId<<MakeStringColor(buf,TIPS_SUCCESS_COLOR);
		SetExtData32(395,GetExtData32(395) + totalExp);
		if (!HaveBitSet(152))
		{
			SetBitSet(152);
			SingletonCMissionManager::instance().UpdateDCMissionComplate(this, EMISS_DC_52);
		}
	}

	if(addLevel > 0)
	{
		SingletonCMissionManager::instance().UpdateDCMissionComplate(this, EMISS_DC_43, addLevel);
	}
	
	InitAllPet();
	InitAndUpdate();
	SendWingMsg();
}

void CUser::BuyWing(uint8 buyId,int useYB,CNetMessage &msg)
{
	if(buyId == SWing::WT_None || buyId >= SWing::WT_Max || (buyId > SWing::WT_Wing_6 && buyId < SWing::WT_Wing_21))
		return;

	const char *pName[] = {""};
	bool success = false;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if(!m_wing.HaveWing(buyId))
		{
			if(useYB > 0)
			{
				int yb = GetTongBao();
				if(yb < useYB)
				{
					msg<<PRO_ERROR<<"";
					ShowJumpNotice(this,JUMP_NOTICE_YB);
					return;
				}
				if(!m_wing.AddWing(buyId))
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1963,TIPS_FAILURE_COLOR);
					return;
				}
				AddTongBao(-useYB);
				
				char buf[128];
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1964,pName[0]);
				msg<<PRO_SUCCESS<<MakeStringColor(buf,TIPS_SUCCESS_COLOR);
				success = true;

				ItemCurrencyLog(GetRoleId(),0,0,0,useYB,GetTongBao(),YBL_BUY_WING);
			}
		}
		else	// 已经有该翅膀
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1965,TIPS_FAILURE_COLOR);
			return;
		}
	}

	if(success)
	{
		InitAllPet();
		InitAndUpdate();
//		InitChuZhanPet();
		SendWingMsg();
	}
}

void CUser::BuyWingByItem(uint8 buyId,int itemId,int itemNum,CNetMessage &msg)
{
	bool success = false;
	char buf[256];
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if(!m_wing.HaveWing(buyId))
		{
			int haveItemNum = NoLockGetItemNum(itemId);
			if(haveItemNum < itemNum)
			{
				snprintf(buf,sizeof(buf)-1,LANGUAGE_TRANSFORM_1966,(itemNum-haveItemNum),GetItemName(itemId),GetWingName(buyId));
				msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
				return;
			}
			if(!m_wing.AddWing(buyId))
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1967,TIPS_FAILURE_COLOR);
				return;
			}
			NoLockDelPackageById(itemId,itemNum);
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1968,GetWingName(buyId));
			msg<<PRO_SUCCESS<<MakeStringColor(buf,TIPS_SUCCESS_COLOR);
			success = true;

			SaveUseItem(m_roleId,itemId,LANGUAGE_TRANSFORM_1969,itemNum);
		}
		else	// 已经有该翅膀
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1970,TIPS_FAILURE_COLOR);
			return;
		}
	}

	if(success)
	{
		InitAllPet();
		InitAndUpdate();
//		InitChuZhanPet();
		SendWingMsg();
	}
}

// 坐骑进阶 发消息用
bool CUser::UpgradeMount(CNetMessage& msg)
{
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		// 条件判断
		if(m_mount.m_num == 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1971,TIPS_FAILURE_COLOR);
			return false;
		}

		uint8 srcMountId = 0;
		CMountConfigMgr &mgr = SingletonMountCfgMgr::instance();
		for(uint8 i=0;i < m_mount.m_num;i++)
		{
			SMountConfig *pCfg = mgr.GetCfg(m_mount.m_id[i]);
			if(pCfg == NULL)
				continue;
			if(pCfg->jinjieId > 0)
			{
				if(!HaveMount(pCfg->jinjieId))
				{
					srcMountId = m_mount.m_id[i];
					break;
				}
			}
		}
		if(srcMountId == 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1972,TIPS_FAILURE_COLOR);
			return false;
		}

		SMountConfig *pCfg = mgr.GetCfg(srcMountId);
		if(pCfg == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1972,TIPS_FAILURE_COLOR);
			return false;
		}

		string error;
		if(!NoLockCheckCostMaterial(pCfg->jinjie_cost,error))
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1975,TIPS_FAILURE_COLOR);
			return false;
		}
		NoLockDelCostMaterial(pCfg->jinjie_cost);
		uint8 jinjieId = pCfg->jinjieId;
		// 进阶
		if(!m_mount.AddMount(jinjieId))	// 进阶坐骑
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1976,TIPS_FAILURE_COLOR);
			return false;
		}
		msg<<PRO_SUCCESS<<jinjieId;
		msg<<MakeStringColor(LANGUAGE_TRANSFORM_1977,TIPS_SUCCESS_COLOR);
		SingletonCMissionManager::instance().UpdateDCMissionComplate(this, EMISS_DC_40, jinjieId);
	}
	InitAllPet();
	InitAndUpdate();
	CheckFBLevel();
	return true;
}

void CUser::BuyMount(uint8 buyId,uint32 time,int useYB,CNetMessage &msg)
{
	if(buyId == 0)
		return;
	
	bool success = false;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if(!m_mount.HaveMount(buyId))
		{
			if(useYB > 0)
			{
				int yb = GetTongBao();
				if(yb < useYB)
				{
					msg<<PRO_ERROR<<"";
					ShowJumpNotice(this,JUMP_NOTICE_YB);
					return;
				}
				AddTongBao(-useYB);
				if(!m_mount.AddMount(buyId,time))
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1978,TIPS_FAILURE_COLOR);
					return;
				}
				char buf[128];
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1979,GetMountName(buyId));
				msg<<PRO_SUCCESS<<MakeStringColor(buf,TIPS_SUCCESS_COLOR);
				success = true;

				ItemCurrencyLog(GetRoleId(),0,0,0,useYB,GetTongBao(),YBL_BUY_FOX);
				SingletonCMissionManager::instance().UpdateDCMissionComplate(this, EMISS_DC_40, buyId);
			}
		}
		else	// 已经有该坐骑
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1980,TIPS_FAILURE_COLOR);
			return;
		}
	}
	
	if(success)
	{
		InitAllPet();
		InitAndUpdate();
		
		CNetMessage msg1;
		msg1.SetType(MSG_MOUNT);
		msg1<<(uint8)1;
		MakeMount(msg1);
		SingletonSocket::instance().SendMsg(m_sock,msg1);

		SaveDate(m_roleId,15,useYB);
	}
}

void CUser::MakeMountCollect(CNetMessage &msg)
{
	msg<<m_mount.m_num;
	MakeMountCollectMsg(msg);
}

void CUser::BuyMountByItem(uint8 buyId,int itemId,int itemNum,uint32 time,CNetMessage &msg)
{
	if(buyId == 0)
		return;

	bool success = false;
	char buf[256];
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if(!m_mount.HaveMount(buyId))
		{
			int haveItemNum = NoLockGetItemNum(itemId);
			if(haveItemNum < itemNum)
			{
				snprintf(buf,sizeof(buf)-1,LANGUAGE_TRANSFORM_1981,(itemNum-haveItemNum),GetItemName(itemId),GetMountName(buyId));
				msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
				return;
			}
			NoLockDelPackageById(itemId,itemNum);
			if(!m_mount.AddMount(buyId,time))
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1982,TIPS_FAILURE_COLOR);
				return;
			}
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1983,GetMountName(buyId));
			msg<<PRO_SUCCESS<<MakeStringColor(buf,TIPS_SUCCESS_COLOR);
			success = true;

			SaveUseItem(m_roleId,itemId,LANGUAGE_TRANSFORM_1984,itemNum);
			SingletonCMissionManager::instance().UpdateDCMissionComplate(this, EMISS_DC_40, buyId);
		}
		else	// 已经有该坐骑
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1985,TIPS_FAILURE_COLOR);
			return;
		}
	}
	
	if(success)
	{
		InitAllPet();
		InitAndUpdate();
		
		CNetMessage msg1;
		msg1.SetType(MSG_MOUNT);
		msg1<<(uint8)1;
		MakeMount(msg1);
		SingletonSocket::instance().SendMsg(m_sock,msg1);
	}
}

void CUser::UseMount(int mountId)
{
	uint8 idx = GetMountIdxById(mountId);
	if(idx == 0xff)
		return;

	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if(m_mount.m_num == SMount::None)
			return;
		if(!m_mount.SetUseMountIndex(idx))
			return;
	}

	CNetMessage msg;
	msg.SetType(MSG_MOUNT);
	msg<<(uint8)4<<(uint8)mountId<<PRO_SUCCESS<<GetMountMoveSpeed();
	SingletonSocket::instance().SendMsg(m_sock,msg);
}

// 设置乘骑状态 发消息用
void CUser::SetMountState(CNetMessage& msg,int index)
{
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if(m_mount.m_num == SMount::None)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1986,TIPS_FAILURE_COLOR);
			return;
		}
		if(!m_mount.SetUseMountIndex(index))
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1987,TIPS_FAILURE_COLOR);
			return;
		}
		msg<<PRO_SUCCESS<<GetMountMoveSpeed();
	}
	InitAllPet();
	InitAndUpdate();
}

void CUser::QueryWingQiangHuaMsg(CNetMessage &msg)
{
	uint8 srcId = SWing::WT_None;
	uint8 targetId = SWing::WT_None;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint8 i=0;i < m_wing.m_num;i++)
	{
		if(m_wing.m_id[i] <= SWing::WT_Wing_20)
		{
			if(srcId == SWing::WT_None || srcId < m_wing.m_id[i])
				srcId = m_wing.m_id[i];
		}
	}
	if(srcId == SWing::WT_None)
	{
		msg<<srcId;
	}
	else
	{
		if(srcId < SWing::MAX_LEVEL)
			targetId = srcId+1;
		msg<<srcId<<targetId;
//		msg<<m_wing.GetQiangHuaAttack()<<m_wing.GetQiangHuaRecovery()<<m_wing.GetQiangHuaMaxHp()<<m_wing.GetQiangHuaSpeed();
//		msg<<m_wing.GetNextQiangHuaAttack()<<m_wing.GetNextQiangHuaRecovery()<<m_wing.GetNextQiangHuaMaxHp()<<m_wing.GetNextQiangHuaSpeed();
//		msg<<m_wing.GetLevelUpExp();
	}
}

void CUser::UseWing(int wingId)
{
	uint8 idx = GetWingIdxById(wingId);
	if(idx == 0xff)
		return;
	
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if(m_wing.m_num == SWing::WT_None)
			return;
		if(!m_wing.SetUseWingIndex(idx))
			return;
	}
	
	CNetMessage msg;
	msg.SetType(MSG_WING);
	msg<<(uint8)3<<(uint8)wingId<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_TRANSFORM_1991,TIPS_WARNING_COLOR);
	SingletonSocket::instance().SendMsg(m_sock,msg);
}

// 设置翅膀状态
void CUser::SetWingState(CNetMessage& msg,int index)
{
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if(m_wing.m_num == SWing::WT_None)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1988,TIPS_FAILURE_COLOR);
			return;
		}
		if(!m_wing.SetUseWingIndex(index))
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1989,TIPS_FAILURE_COLOR);
			return;
		}
		msg<<PRO_SUCCESS;
		if(index == 0xff)	// 不使用
			msg<<MakeStringColor(LANGUAGE_TRANSFORM_1990,TIPS_WARNING_COLOR);
		else	// 使用
			msg<<MakeStringColor(LANGUAGE_TRANSFORM_1991,TIPS_WARNING_COLOR);
	}
//	InitAndUpdate();
}

void CUser::SendWingMsg()
{
	CNetMessage msg;
	msg.SetType(MSG_WING);
	msg<<(uint8)1;
	MakeWing(msg);
	SingletonSocket::instance().SendMsg(m_sock,msg);
}

void CUser::SendNewWingMsg(uint8 wid)
{

	CNetMessage msg;
	msg.SetType(MSG_WING);
	msg << (uint8)8;
	msg << (uint8)wid;
	MakeWing(msg);
	SingletonSocket::instance().SendMsg(m_sock, msg);
}

int CUser::GetWingZhanDouLi(bool show)
{
	vector<SAttrData> attr;
	CWingConfigMgr &wingMgr = SingletonWingCfgMgr::instance();
	for(uint8 i=0;i < m_wing.m_num;i++)
	{
		if(m_wing.m_id[i] > 0)
		{
			SWingConfig *pCfg = wingMgr.GetCfg(m_wing.m_id[i]);
			if(pCfg == NULL)
				continue;
			MergeAttrList(attr,pCfg->attrList);
		}
	}
	SWingQH *pWingQHCfg = wingMgr.GetQHCfg(m_wing.m_level,m_wing.m_star);
	if(pWingQHCfg != NULL)
	{
		MergeAttrList(attr,pWingQHCfg->attrList);
	}
	
	int zhandouli = GetAttrPower(attr)/10;
	return zhandouli;
}

uint8 CUser::GetMountIdByIdx(int idx)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(idx > SMount::MAX_MOUNT_NUM-1)
		return 0;
	return m_mount.m_id[idx];
}

uint8 CUser::GetMountId()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(m_mount.m_useIndex >= m_mount.m_num)
		return 0;
	return m_mount.m_id[m_mount.m_useIndex];
}

uint8 CUser::GetMountIdxById(int mountId)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint8 i=0;i < SMount::MAX_MOUNT_NUM;i++)
	{
		if(m_mount.m_id[i] > 0 && m_mount.m_id[i] == mountId)
			return i;
		else if(m_mount.m_id[i] == 0)
			return 0xff;
	}
	return 0xff;
}

uint8 CUser::GetWingId()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(m_wing.m_useIndex >= m_wing.m_num)
		return 0;
	return m_wing.m_id[m_wing.m_useIndex];
}

void CUser::AddWing(int id)
{
	bool update = false;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if(m_wing.AddWing(id))
			update = true;
	}

	if(update)
	{
		InitAllPet();
		InitAndUpdate();
		SendWingMsg();
		SendNewWingMsg(id);
		// 更新场景数据
		CScene *pScene = GetScene();
		if(pScene == NULL)
			return;
		pScene->UpdateUserInfo(this,ESRT_Wing);
	}
}

uint8 CUser::GetWingIdxById(int wingId)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint8 i=0;i < SWing::MAX_WING_NUM;i++)
	{
		if(m_wing.m_id[i] > 0 && m_wing.m_id[i] == wingId)
			return i;
		else if(m_wing.m_id[i] == 0)
			return 0xff;
	}
	return 0xff;
}

int CUser::GetMountIndex()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return m_mount.m_useIndex;
}

// 开服活动 坐骑
void CUser::AddHuoDongMount()
{
//	m_mount.AddMount(SMount::JiuWeiHu); // 不需要添加通知客户端的消息，脚本会通知客户端的

	// 更新个人数据
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_MOUNT);
	msg<<(uint8)1;
	MakeMount(msg);
	sock.SendMsg(m_sock,msg);

	// 更新场景数据
	CScene *pScene = GetScene();
	if(pScene == NULL)
		return;
	pScene->UpdateUserInfo(this,ESRT_Mount_State);
	InitAllPet();
	InitAndUpdate();
}

void CUser::SetPackage(char *pPack)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(pPack == NULL || strlen(pPack) == 0)
		return;
	uint32 len = MAX_PACKAGE_NUM2*sizeof(SItemInstance);
	uint32 pos = 0;
	uint8 *buf = new uint8[len];
	memset(buf,0,len);
	if(!UnCompress(pPack,buf,len))
		return;

	m_itemNumMap.clear();
	for(uint16 i = 0; i < MAX_PACKAGE_NUM2; i++)
	{
		pos += ReadItemBuf(&m_package[i],buf+pos,len-pos);
		
		if(!NolockUpdateItemNumMap(m_package[i].tmplId,m_package[i].num,true))
			cout<<">> CUser::SetPackage NolockUpdateItemNumMap error!!!"<<endl;
		if(pos >= len)
			break;
	}
	delete buf;
}

void CUser::SetBankItem(char *pBankItem)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	uint32 len = 10240;
	uint8 *p = new uint8[len];
	boost::scoped_array<uint8> autoDel(p);

	if(!UnCompress(pBankItem,p,len))
	{
//		memset(m_bankItem,0,sizeof(m_bankItem));
//		UnHexify((uint8*)m_bankItem,pBankItem);
		return;
	}

	CNetMessage msg;
	msg.WriteData(p,len);

	uint16 num = 0;
	msg>>num;
	for(uint16 i = 0; i < num; i++)
	{
		uint16 pos = 0;
		uint8 val = 0;
		msg>>pos>>val;
		m_saveData8[pos] = val;
	}

	num = 0;
	msg>>num;
	for(uint16 i = 0; i < num; i++)
	{
		uint16 pos = 0;
		uint16 val = 0;
		msg>>pos>>val;
		m_saveData16[pos] = val;
	}

	num = 0;
	msg>>num;
	for(uint16 i = 0; i < num; i++)
	{
		uint16 pos = 0;
		uint32 val = 0;
		msg>>pos>>val;
		m_saveData32[pos] = val;
	}

	num = 0;
	msg >> num;
	for (uint16 i = 0; i < num; i++)
	{
		uint16 pos = 0;
		uint64 val = 0;
		msg >> pos >> val;
		m_saveData64[pos] = val;
	}
	
	uint8 clientSaveNum = 0;
	msg>>clientSaveNum;
	for(uint8 i = 0; i < clientSaveNum; i++)
	{
		uint8 ind = 0;
		int val = 0;
		msg>>ind>>val;
		m_clientSave[ind] = val;
	}
	msg>>m_delLockPassTime;
	msg>>m_lockPass;
}

void CUser::GetPackage(string &str)
{
	uint32 len = MAX_PACKAGE_NUM2*sizeof(SItemInstance);
	uint32 pos = 0;
	uint8 *buf = new uint8[len];
	if(buf == NULL)
		return;

	for(int i=0;i < MAX_PACKAGE_NUM2;i++)
	{
		pos += WriteItemBuf(&m_package[i],buf+pos,len-pos);
	}
	if(!Compress(buf,pos,str))
		str.clear();
	delete buf;
}

void CUser::GetBankItem(string &str)
{
	CNetMessage msg;
	uint16 num = m_saveData8.size();
	msg<<num;
	for(map<uint16,uint8>::iterator i = m_saveData8.begin(); i != m_saveData8.end(); i++)
	{
		msg<<i->first<<i->second;
	}

	num = m_saveData16.size();
	msg<<num;
	for(map<uint16,uint16>::iterator i = m_saveData16.begin(); i != m_saveData16.end(); i++)
	{
		msg<<i->first<<i->second;
	}

	num = m_saveData32.size();
	msg<<num;
	for(map<uint16,uint32>::iterator i = m_saveData32.begin(); i != m_saveData32.end(); i++)
	{
		msg<<i->first<<i->second;
	}

	num = m_saveData64.size();
	msg << num;
	for (map<uint16, uint64>::iterator i = m_saveData64.begin(); i != m_saveData64.end(); i++)
	{
		msg << i->first << i->second;
	}

	uint8 clientSaveNum = m_clientSave.size();
	msg<<clientSaveNum;
	for(map<uint8,int>::iterator i = m_clientSave.begin(); i != m_clientSave.end(); i++)
	{
		msg<<i->first<<i->second;
	}
	msg<<m_delLockPassTime;
	msg<<m_lockPass;

	if(!Compress((uint8*)(msg.GetMsgData()->c_str() + CNetMessage::GetHeadLen()),msg.GetDataLenExceptHead(), str))
		str.clear();
}

void CUser::MakeBankItemList(CNetMessage &msg)
{
/*
	boost::recursive_mutex::scoped_lock lk(m_mutex);

	uint8 num = 0;
	uint16 pos = msg.GetDataLen();
	msg<<num;
	for(uint8 i = 0; i < MAX_BANK_ITEM_NUM; i++)
	{
		if(m_bankItem[i].tmplId != 0)
		{
			num++;
			msg<<i;
			MakeItemInfo(m_bankItem+i,msg);
			msg<<m_bankItem[i].num;
		}
	}
	msg.WriteData(pos,&num,1);
*/
}

bool CUser::NoLockAddBankItem(SItemInstance &item,uint8 &tolSaveNum)
{
/*
	CItemTemplateManager &itemMgr = SingletonItemManager::instance();
	SItemTemplate *pItem = itemMgr.GetItem(item.tmplId);
	if(pItem == NULL)
		return false;

	uint8 savePos[MAX_BANK_ITEM_NUM] = {0};
	uint8 saveNum[MAX_BANK_ITEM_NUM] = {0};
	int tolNum = 0;
	uint8 pos = 0;
	uint8 maxBankNum = 18;
	uint8 openNum = NoLockGetExtData8(1);
	time_t endTime = NoLockGetExtData32(1);
	if((openNum > 0) && (endTime > GetSysTime()))
	{
		maxBankNum += openNum;
		if(maxBankNum > MAX_BANK_ITEM_NUM)
			maxBankNum = MAX_BANK_ITEM_NUM;
	}

	for(uint8 i = 0; i < maxBankNum; i++)
	{
		if(tolNum >= item.num)
			break;
		if(m_bankItem[i].num >= EBankItemDieJIaNum)
			continue;
		if(((pItem->type == EIT_Normal) || (pItem->type == EIT_PetBook))
				&& (m_bankItem[i] == item))
		{
			savePos[pos] = i;
			saveNum[pos] = EBankItemDieJIaNum - m_bankItem[i].num;
			tolNum += saveNum[pos];
			pos++;
		}
		else if((m_bankItem[i].tmplId == item.tmplId) &&
				(m_bankItem[i] == item) &&
				((pItem->type == EITPKYaoPin) ||
				 (pItem->type == EITNormalYaoPin) ||
				 (pItem->type == EITMission) ||
				 (pItem->type == EITCanDelMiss) ||
				 (pItem->type == EITMissionCanSave) ||
				 ((pItem->type == EIT_Box_3) && (pItem->addXue == 0) && (pItem->id != 1809)
				  && (pItem->id != 1815) && ((pItem->id < 1827) || (pItem->id > 1831)))))
		{
			if((pItem->type == EIT_Box_3) && !(m_bankItem[i] == item))
				continue;
			savePos[pos] = i;
			saveNum[pos] = EBankItemDieJIaNum - m_bankItem[i].num;
			tolNum += saveNum[pos];
			pos++;
		}
	}
	for(uint8 i = 0; i < maxBankNum; i++)
	{
		if(tolNum >= item.num)
			break;
		if(m_bankItem[i].tmplId == 0)
		{
			savePos[pos] = i;
			saveNum[pos] = EBankItemDieJIaNum;
			tolNum += saveNum[pos];
			pos++;
		}
	}
	if(tolNum <= 0)
		return false;
	tolSaveNum = 0;
	for(uint8 i = 0; i < pos; i++)
	{
		if(item.num <= 0)
			break;
		if(m_bankItem[savePos[i]].tmplId == item.tmplId)
		{
			if(item.num > saveNum[i])
			{
				m_bankItem[savePos[i]].num = EBankItemDieJIaNum;
				item.num -= saveNum[i];
				tolSaveNum += saveNum[i];
			}
			else
			{
				m_bankItem[savePos[i]].num += item.num;
				tolSaveNum += item.num;
				return true;
			}
		}
		else
		{
			m_bankItem[savePos[i]] = item;
			tolSaveNum += item.num;
			return true;
		}
	}
*/
	return true;
}

void CUser::NoLockDelBankItem(uint8 bankPos)
{
//	memset(m_bankItem+bankPos,0,sizeof(SItemInstance));
}

bool CUser::MoveItemToBank(uint8 packPos,uint8 num)
{
	if(num == 0)
		return false;
	if(packPos >= MAX_PACKAGE_NUM)
		return false;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(m_package[packPos].tmplId == 0)
		return false;
	if((num == 0) || (num > m_package[packPos].num))
		return false;
	SItemInstance item = m_package[packPos];
	item.num = num;
	if(NoLockAddBankItem(item,num))
	{
		NoLockDelPackage(packPos,num);
		return true;
	}
	return false;
}

bool CUser::MoveItemToPack(uint8 bankPos,uint8 num)
{
/*
	if(num == 0)
		return false;
	if(bankPos >= MAX_BANK_ITEM_NUM)
		return false;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(m_bankItem[bankPos].tmplId == 0)
		return false;
	if(num > m_bankItem[bankPos].num)
		return false;

	bool success = false;
	for(uint8 i = 0; i < MAX_PACKAGE_NUM; i++)
	{
		if(num <= 0)
		{
			break;
		}
		SItemInstance item = m_bankItem[bankPos];
		if(num >= EItemDieJiaNum)
		{
			num -= EItemDieJiaNum;
			item.num = EItemDieJiaNum;
		}
		else
		{
			item.num = num;
			num = 0;
		}
		if(NoLockAddPackage(item))
		{
			success = true;
			if(m_bankItem[bankPos].num > item.num)
				m_bankItem[bankPos].num -= item.num;
			else
				memset(m_bankItem+bankPos,0,sizeof(SItemInstance));
		}
		else
		{
			break;
		}
	}
	return success;
*/
	return false;
}

void CUser::SetBitSet(char *pBitset)
{
	if((pBitset == NULL) || (strlen(pBitset) == 0))
		return;
	uint32 len = MAX_BITSET/8;
	std::vector<uint8> data(len);
	memset(&data[0],0,data.size());
	if(!UnCompress(pBitset,&data[0],len))
		return;
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_bitset.reset();
	HexToBitset(&data[0],m_bitset);
}

void CUser::GetBitSet(string &str)
{
	uint32 len = MAX_BITSET/8;
	std::vector<uint8> data(len);
	memset(&data[0],0,data.size());
	BitsetToHex(m_bitset,&data[0]);
	if(!Compress(&data[0],len,str))
		str.clear();
}

void CUser::SetSGBitSet(const char *pBitset)
{
	if((pBitset == NULL) || (strlen(pBitset) == 0))
		return;
	uint32 len = MAX_STAGE_GOAL_BITSET/8;
	std::vector<uint8> data(len);
	memset(&data[0],0,data.size());
	if(!UnCompress(pBitset,&data[0],len))
		return;
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_stageGoalBitSet.reset();
	HexToBitset(&data[0],m_stageGoalBitSet);
}

void CUser::GetSGBitSet(string &str)
{
	uint32 len = MAX_STAGE_GOAL_BITSET/8;
	std::vector<uint8> data(len);
	memset(&data[0],0,data.size());
	BitsetToHex(m_stageGoalBitSet,&data[0]);
	if(!Compress(&data[0],len,str))
		str.clear();
}

void CUser::SetMysteryData(const char *pStr)
{
	m_mysteryTime = 0;
	m_mysteryItem.clear();
	if(pStr == NULL || strlen(pStr) < 8)
		return;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	int len = sizeof(UserMysteryItem)*ShowMysteryItemNum + sizeof(m_mysteryTime) + 32;
	uint8 *pHex = new uint8[len];
	int size = StrToHex(pStr,pHex,len);
	uint16 pos = 0;
	if(size > 0)
	{
		memcpy(&m_mysteryTime,pHex+pos,sizeof(m_mysteryTime));
		pos += sizeof(m_mysteryTime);

		uint8 num = 0;
		memcpy(&num,pHex+pos,sizeof(num));
		pos += sizeof(num);

		m_mysteryItem.clear();
		for(uint8 i=0;i < num;i++)
		{
			UserMysteryItem item;
			memcpy(&item.id,pHex+pos,sizeof(item.id));
			pos += sizeof(item.id);
			memcpy(&item.itemId,pHex+pos,sizeof(item.itemId));
			pos += sizeof(item.itemId);
			memcpy(&item.itemNum,pHex+pos,sizeof(item.itemNum));
			pos += sizeof(item.itemNum);
			memcpy(&item.extValue, pHex + pos, sizeof(item.extValue));
			pos += sizeof(item.extValue);
			memcpy(&item.price,pHex+pos,sizeof(item.price));
			pos += sizeof(item.price);
			m_mysteryItem.push_back(item);
			if(pos >= size)
				break;
		}
	}
	delete pHex;
	pHex = NULL;
}

void CUser::GetMysteryData(string &str)
{
	uint16 len = sizeof(UserMysteryItem)*ShowMysteryItemNum + sizeof(m_mysteryTime) + 32;
	uint8 *pHex = new uint8[len];
	uint16 pos = 0;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	memcpy(pHex+pos,&m_mysteryTime,sizeof(m_mysteryTime));
	pos += sizeof(m_mysteryTime);
	pHex[pos++] = m_mysteryItem.size();
	for(uint8 i=0;i < m_mysteryItem.size();i++)
	{
		memcpy(pHex+pos,&m_mysteryItem[i].id,sizeof(m_mysteryItem[i].id));
		pos += sizeof(m_mysteryItem[i].id);
		memcpy(pHex+pos,&m_mysteryItem[i].itemId,sizeof(m_mysteryItem[i].itemId));
		pos += sizeof(m_mysteryItem[i].itemId);
		memcpy(pHex+pos,&m_mysteryItem[i].itemNum,sizeof(m_mysteryItem[i].itemNum));
		pos += sizeof(m_mysteryItem[i].itemNum);
		memcpy(pHex + pos, &m_mysteryItem[i].extValue, sizeof(m_mysteryItem[i].extValue));
		pos += sizeof(m_mysteryItem[i].extValue);
		memcpy(pHex+pos,&m_mysteryItem[i].price,sizeof(m_mysteryItem[i].price));
		pos += sizeof(m_mysteryItem[i].price);
		if(pos > len)
			break;
	}

	HexToStr(pHex,pos,str);
	delete[] pHex;
	pHex = NULL;
}

void CUser::SetShenhunShopData(const char *pStr)
{
	m_shenhunTime = 0;
	m_shenhunItem.clear();
	if (pStr == NULL || strlen(pStr) < 8)
		return;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	int len = sizeof(UserMysteryItem)*ShowShenjiangItemNum + sizeof(m_shenhunTime) + 32;
	uint8 *pHex = new uint8[len];
	int size = StrToHex(pStr, pHex, len);
	uint16 pos = 0;
	if (size > 0)
	{
		memcpy(&m_shenhunTime, pHex + pos, sizeof(m_shenhunTime));
		pos += sizeof(m_shenhunTime);
		uint8 num = 0;
		memcpy(&num, pHex + pos, sizeof(num));
		pos += sizeof(num);
		m_shenhunItem.clear();
		for (uint8 i = 0; i < num; i++)
		{
			UserMysteryItem item;
			memcpy(&item.id, pHex + pos, sizeof(item.id));
			pos += sizeof(item.id);
			memcpy(&item.itemId, pHex + pos, sizeof(item.itemId));
			pos += sizeof(item.itemId);
			memcpy(&item.itemNum, pHex + pos, sizeof(item.itemNum));
			pos += sizeof(item.itemNum);
			memcpy(&item.price, pHex + pos, sizeof(item.price));
			pos += sizeof(item.price);
			m_shenhunItem.push_back(item);
			if (pos >= size)
				break;
		}
	}
	delete pHex;
	pHex = NULL;
}
void CUser::GetShenhunShopData(string &str)
{
	uint16 len = sizeof(UserMysteryItem)*ShowMysteryItemNum + sizeof(m_shenhunTime) + 32;
	uint8 *pHex = new uint8[len];
	uint16 pos = 0;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	memcpy(pHex + pos, &m_shenhunTime, sizeof(m_shenhunTime));
	pos += sizeof(m_shenhunTime);
	pHex[pos++] = m_shenhunItem.size();
	for (uint8 i = 0; i < m_shenhunItem.size(); i++)
	{
		memcpy(pHex + pos, &m_shenhunItem[i].id, sizeof(m_shenhunItem[i].id));
		pos += sizeof(m_shenhunItem[i].id);
		memcpy(pHex + pos, &m_shenhunItem[i].itemId, sizeof(m_shenhunItem[i].itemId));
		pos += sizeof(m_shenhunItem[i].itemId);
		memcpy(pHex + pos, &m_shenhunItem[i].itemNum, sizeof(m_shenhunItem[i].itemNum));
		pos += sizeof(m_shenhunItem[i].itemNum);
		memcpy(pHex + pos, &m_shenhunItem[i].price, sizeof(m_shenhunItem[i].price));
		pos += sizeof(m_shenhunItem[i].price);
		if (pos > len)
			break;
	}
	HexToStr(pHex, pos, str);
	delete[] pHex;
	pHex = NULL;
}
void CUser::SetYaoShiData(string saveData)
{
	uint32 len = sizeof(UserYaoShiItem)*GetYaoShiItemNum()+ sizeof(m_yaoshiTime) + 32 + sizeof(SFootPrintData)*100;
	uint8 *p = new uint8[len];
	memset(p,0,len);
	boost::scoped_array<uint8> autoDel(p);

	if(!UnCompress(saveData.c_str(),p,len))
	{
		return;
	}
		
	CNetMessage msg;
	msg.WriteData(p,len);
	
	uint32 num = 0;
	m_yaoshiTime = 0;
	m_yaoshiItem.clear();
	msg>>m_yaoshiTime;
	msg>>num;
	for(uint32 i=0;i < num;i++)
	{
		UserYaoShiItem item;
		msg>>item.id;
		msg>>item.itemId;
		msg>>item.itemNum;
		msg>>item.price;
		m_yaoshiItem.push_back(item);
	}

	num = 0;
	m_footData.clear();
	msg>>num;
	if(num > 100)
		return;
	for(uint32 i=0;i < num;i++)
	{
		SFootPrintData data;
		msg>>data.id>>data.get_time>>data.end_time;
		if(data.id < 1)
			continue;
		m_footData.push_back(data);
	}
}

void CUser::GetYaoShiData(string &str)
{
	CNetMessage msg;
	msg<<m_yaoshiTime;
	msg<<(uint32)m_yaoshiItem.size();
	for(uint32 i=0;i < m_yaoshiItem.size();i++)
	{
		msg<<m_yaoshiItem[i].id;
		msg<<m_yaoshiItem[i].itemId;
		msg<<m_yaoshiItem[i].itemNum;
		msg<<m_yaoshiItem[i].price;
	}

	msg<<(uint32)m_footData.size();
	for(uint32 i=0;i < m_footData.size();i++)
		msg<<m_footData[i].id<<m_footData[i].get_time<<m_footData[i].end_time;

	if(!Compress((uint8*)(msg.GetMsgData()->c_str() + CNetMessage::GetHeadLen()),msg.GetDataLenExceptHead(), str))
		str.clear();
}

void CUser::MakeOtherTitle(CNetMessage &msg)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	msg << (uint8)m_useTitle.size();
	for (titleSetIt it = m_useTitle.begin(); it != m_useTitle.end(); ++it)
	{
		uint32 power = sTitltAttrCfgManager.GetTitleAddPower(*it);
		msg << (uint16)*it << power;
	}
}

void CUser::MakeOtherMount(CNetMessage &msg)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(m_mount.m_useIndex == 0xff)
	{
		msg<<(uint8)0;
	}
	else
	{
		uint8 index = m_mount.m_useIndex;
		if(index < m_mount.m_num)
			msg<<m_mount.m_id[index]<<m_mount.m_level<<m_mount.GetMoveSpeed(index);
		else
			msg<<(uint8)0;
	}
}

void CUser::MakeOtherWing(CNetMessage &msg)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(m_wing.m_useIndex == 0xff)
	{
		msg<<(uint8)0;
	}
	else
	{
		uint8 index = m_wing.m_useIndex;
		if(index < m_wing.m_num)
		{
			msg<<m_wing.m_id[index]<<m_wing.m_level<<m_wing.m_star;
		}
		else
		{
			msg<<(uint8)0;
		}
	}
}

void CUser::MakeOtherChuZhanPet(CNetMessage &msg)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	uint8 num = 0;
	uint16 pos = msg.GetDataLen();
	msg<<num;
	for(uint8 i=0;i < m_zhenfaMember.size();i++)
	{
		if(m_zhenfaMember[i].mem_type == EZFMT_PET)
		{
			uint16 petId = m_zhenfaMember[i].mem_id;
			SPet *pPet = NoLockGetPet(petId).get();
			if(pPet != NULL)
			{
				MakePetData(pPet,msg);
				num++;
			}
		}
	}
	msg.WriteData(pos,&num,sizeof(num));
}

void CUser::PrintPackage()
{
	CItemTemplateManager &itemMgr = SingletonItemManager::instance();
	for(uint16 i=0; i < MAX_PACKAGE_NUM; i++)
	{
		SItemTemplate *pItemSrc = itemMgr.GetItem(m_package[i].tmplId);
		if(pItemSrc == NULL)
			cout<<"["<<(int)i<<"]: id="<<m_package[i].tmplId<<", sortPriority="<<0<<", num="<<(int)m_package[i].num<<endl;
		else
			cout<<"["<<(int)i<<"]: id="<<m_package[i].tmplId<<", sortPriority="<<pItemSrc->sortPriority<<", num="<<(int)m_package[i].num<<endl;
	}
}

void CUser::SortPackage()
{
	CItemTemplateManager &itemMgr = SingletonItemManager::instance();
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint16 i=MAX_PACKAGE_NUM; i > 0 ; i--)
	{
		if(m_package[i-1].tmplId == 0)
			continue;
		SItemTemplate *pItemSrc = itemMgr.GetItem(m_package[i-1].tmplId);
		if(pItemSrc == NULL)
			continue;
		for(uint8 j=0;j < i-1;j++)
		{
			if(m_package[j].tmplId == 0)
				continue;
			if(m_package[j].num >= EItemDieJiaNum)
				continue;
			if(m_package[i-1].tmplId == m_package[j].tmplId)
			{
				SItemTemplate *pItemTar = itemMgr.GetItem(m_package[j].tmplId);
				if(pItemTar == NULL)
					continue;
				bool canDieJia = false;
				if((pItemSrc->id == pItemTar->id) && (m_package[i-1] == m_package[j]))
					canDieJia = IsItemCanMerge(pItemSrc->type);
				if(canDieJia)
				{
					uint16 tolNum = (uint16)m_package[i-1].num + (uint16)m_package[j].num;
					if(tolNum <= EItemDieJiaNum)
					{
						m_package[j].num = (uint8)tolNum;
						m_package[i-1].Clear();
						break;
					}
					else
					{
						m_package[j].num = EItemDieJiaNum;
						m_package[i-1].num = tolNum - EItemDieJiaNum;
					}
				}
				else
				{
					break;
				}
			}
		}
	}

	for(uint16 i=1; i < MAX_PACKAGE_NUM; i++)
	{
		if(m_package[i].tmplId == 0)
			continue;
		SItemTemplate *pItemTar = itemMgr.GetItem(m_package[i].tmplId);
		if(pItemTar == NULL)
			continue;
		for(uint16 j=0;j < i;j++)
		{
			if(m_package[j].tmplId == 0)
			{
				std::swap(m_package[i],m_package[j]);
				break;
			}
			SItemTemplate *pItemSrc = itemMgr.GetItem(m_package[j].tmplId);
			if(pItemSrc == NULL)
			{
				std::swap(m_package[i],m_package[j]);
				break;
			}
			if((pItemTar->sortPriority < pItemSrc->sortPriority) || (pItemTar->sortPriority == pItemSrc->sortPriority && pItemTar->id < pItemSrc->id)
				|| (pItemTar->sortPriority == pItemSrc->sortPriority && pItemTar->id == pItemSrc->id && m_package[i].num > m_package[j].num))
			{
				SItemInstance temp;
				memset(&temp,0,sizeof(SItemInstance));
				std::swap(m_package[i],temp);
				for(uint16 k=i;k > j;k--)
					std::swap(m_package[k],m_package[k-1]);
				std::swap(m_package[j],temp);
				break;
			}
		}
	}
}

void CUser::MakePack(SItemInstance &item, uint16 pos,CNetMessage &msg)
{
	if(pos >= MAX_PACKAGE_NUM2)
		return;
	msg<<pos<<item.tmplId<<item.num;
	MakeItemInfo(m_package+pos,msg);
}

void CUser::MakePackageItemByPos(uint16 pos,CNetMessage &msg)
{
	if(pos >= MAX_PACKAGE_NUM2)
		return;
	MakeItemInfo(m_package+pos,msg);
}

void CUser::MakePack(CNetMessage &msg)
{
	uint16 pos = msg.GetDataLen();
	uint16 packNum = 0;
	msg<<packNum;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint16 i = 0; i < MAX_PACKAGE_NUM; i++)
	{
		if(m_package[i].tmplId == 0)
		{
			continue;
		}
		msg<<i<<m_package[i].tmplId<<m_package[i].num;
		packNum++;
	}
	msg << HaveBitSet(625) << GetExtData8(647);
	msg.WriteData(pos,&packNum,sizeof(packNum));
}

void CUser::SaveEnterPos(int sceneId, int posX, int posY)
{
	if((sceneId < 0) || (sceneId >= MIN_FU_BEN_ID))
		return;
	if((posX < 0) || (posY < 0))
		return;
	SetExtData32(75,sceneId);
	SetExtData32(76,posX);
	SetExtData32(77,posY);
}

void CUser::GetEnterPos(int& sceneId, int& posX, int& posY)
{
	sceneId = GetExtData32(75);
	posX = GetExtData32(76);
	posY = GetExtData32(77);

#ifndef KUA_FU
	if(sceneId == KUA_FU_SCENE_ID)
	{
		sceneId = EXIT_FB_SCENE_ID;
		posX = EXIT_FB_SCENE_X;
		posY = EXIT_FB_SCENE_Y;
	}
#endif
	if((sceneId == 0) || (posX == 0) || (posY == 0) || (sceneId >= 5000) 
		|| (sceneId >= FEI_XIAN_SID1 && sceneId <= FEI_XIAN_SID5))
	{
		sceneId = EXIT_FB_SCENE_ID;
		posX = EXIT_FB_SCENE_X;
		posY = EXIT_FB_SCENE_Y;
	}
}

// 设置当前玩家为之
void CUser::SetCurPos(int sceneId, int posX, int posY)
{
	m_xPos = posX;
	m_yPos = posY;
}

// 获取队伍人数
int CUser::GetTeamMemberNum()
{
	if (GetTeam() > 0)
	{
		return GetScene()->GetTeamMemNum(GetTeam());
	}
	else
		return 1;
}

bool CUser::MakePackInfo(uint8 pos,CNetMessage &msg)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(pos >= MAX_PACKAGE_NUM2)
		return false;

	return MakeItemInfo(m_package+pos,msg);
}

void CUser::SendMailByLevel()
{
/*
	const uint32 MAXNUM = 11;
	const uint8 LEVEL[MAXNUM] = {1,4,7,9,12,14,18,24,26,28,45};
	const uint32 BIT_ID[MAXNUM] = {584,585,586,587,588,589,590,591,592,593,605};
	const char* STR_MAIL[MAXNUM] = {LANGUAGE_LLD_0230,LANGUAGE_LLD_0231,LANGUAGE_LLD_0232,LANGUAGE_LLD_0233,LANGUAGE_LLD_0234,LANGUAGE_LLD_0235,LANGUAGE_LLD_0236,LANGUAGE_LLD_0237
						,LANGUAGE_LLD_0238,LANGUAGE_LLD_0239,LANGUAGE_SSJ_0383};

	for (uint32 i = 0; i < MAXNUM; i++)
	{
		if (m_level>= LEVEL[i] && (!HaveBitSet(BIT_ID[i])))
		{
			SMailData mdata;
			SendSystemMail(GetRoleId(),STR_MAIL[i],&mdata);
			SetBitSet(BIT_ID[i]);
		}
	}
*/
}

void CUser::AddLevel(uint8 tili)		 //等级
{
	m_level++;
	m_userSpirit.AddSpirit(this, tili, true);

	NoLockInitAndUpdate();

	//if(m_level <= 30)
	//{
	//	AllPetLevelUpToMax();
	//}

//	CheckFBLevel();
	ShowHuoDongIcon();

//	if(m_level == 30)
//		sendXtmasTreeInfo();//圣诞树图标
	
	/*uint16 jingjieOpenLv = sSystemOpenCfgMananger.GetFuncOpenLevel(SOT_JingJie);
	if( m_level == jingjieOpenLv)
		ActiveJingJie();
	if( m_level == NEW_SHENQI_OPEN_LEVEL)
		InitNewShenQi();*/
//	if(m_level == 10)
//	{
//		GetAccountInfo();
//		if(m_binding == 1)
//			SendSystemMail(m_roleId,LANGUAGE_SSJ_0094);
//	}
//	if(m_level == 10)
//		AddTitle(E2UT_QIYUXIUXING); // 增加称号
//	else if(m_level == 60)
//		AddTitle(E2UT_XIUXINGDAREN); // 增加称号
//	else if(m_level == 70)
//		AddTitle(E2UT_LIANJIKUANGREN); // 增加称号
//	SendMailByLevel();

	// 更新队伍角色等级
/*	uint32 teamId = 0;
	if(m_teamId > 0)
		teamId = m_teamId;
	if(m_tempLeaveTeam > 0)
		teamId = m_tempLeaveTeam;
	if(teamId == m_roleId)
	{
		if(m_pScene != NULL)
			m_pScene->UpdateTeamMemberLevel(teamId,m_roleId);
	}
	else
	{
		ShareUserPtr ptr = SingletonOnlineUser::instance().GetUserByRoleId(teamId);
		if(ptr.get() != NULL)
		{
			CScene *pScene = ptr->GetScene();
			if(pScene != NULL)
				pScene->UpdateTeamMemberLevel(teamId,m_roleId);
		}
	}
*/
	sCMissionManager.UpdateQuestState(this, EMQCT_30, m_level);
}

// 直升等级到多少级，不会降级
void CUser::UptoLevel(int level)
{
	if (GetLevel() >= level)
		return;
	int cnt = level - GetLevel();
	for (int i = 0; i < cnt; ++i)
	{
		AddLevel(0);
	}
}

//给予绑定物品
bool CUser::AddBangDingPackage(int itemId,int num,const char *name,const char *mailMsg)
{
	if(num <= 0)
		return false;

	CItemTemplateManager &itemMgr = SingletonItemManager::instance();
	SItemTemplate *pItem = itemMgr.GetItem(itemId);
	if(pItem == NULL)
		return false;

	while(num > EItemDieJiaNum)
	{
		SItemInstance item;
		item.tmplId = itemId;
		item.num = EItemDieJiaNum;
		if(!AddPackage(item,name,mailMsg))
			return false;
		num -= EItemDieJiaNum;
	}
	if(num > 0)
	{
		SItemInstance item;
		item.tmplId = itemId;
		item.num = num;
		if(!AddPackage(item,name,mailMsg))
			return false;
	}
	return true;
}

bool CUser::AddBangDingPackageToBank(int itemId,uint8 num)
{
	if(num == 0)
		return false;
	SItemInstance item;
	item.tmplId = itemId;
	item.num = num;
	CItemTemplateManager &itemMgr = SingletonItemManager::instance();
	SItemTemplate *pItem = itemMgr.GetItem(item.tmplId);
	if(pItem == NULL)
		return false;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return NoLockAddBankItem(item,num);
}

//给予等级强化装备
bool CUser::AddLevelPackage(int itemId,int level)
{
	SItemInstance item;
	item.tmplId = itemId;
	item.level = level;
	CItemTemplateManager &itemMgr = SingletonItemManager::instance();
	SItemTemplate *pItem = itemMgr.GetItem(item.tmplId);
	if(pItem == NULL)
		return false;
	return AddPackage(item);
}

bool CUser::AddPackage(SItemInstance &item,const char *name,const char *mailMsg)
{
	if(name != NULL)
		snprintf(item.name,sizeof(item.name),"%s",name);

	CItemTemplateManager &itemMgr = SingletonItemManager::instance();
	SItemTemplate *pItem = itemMgr.GetItem(item.tmplId);
	if(pItem == NULL)
		return false;
	bool addRes = false;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if(mailMsg == NULL)
			addRes = NoLockAddPackage(item);
		else
			addRes = NoLockAddPackage(item,mailMsg);
	}
	if(addRes)
	{
		SingletonCMissionManager::instance().UpdateCMissionItemState(this,item.tmplId);
	}
	return addRes;
}

bool CUser::CanDelPackage(uint8 pos)
{
	if(pos >= MAX_PACKAGE_NUM2)
		return false;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	CItemTemplateManager &itemMgr = SingletonItemManager::instance();
	if(m_package[pos].tmplId == 0)
		return false;

	SItemTemplate *pItem = itemMgr.GetItem(m_package[pos].tmplId);
	if(pItem == NULL)
		return false;
	//if((pItem->type == EIT_TouKui_1) || (pItem->type <= EIT_WuQi_6))
		return false;
	return true;
}

int CUser::CanSellPackage(uint8 pos,uint8 num)
{
	if(pos >= MAX_PACKAGE_NUM2)
		return 0;
	CItemTemplateManager &itemMgr = SingletonItemManager::instance();
	uint32 uid = 0;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if(m_package[pos].tmplId == 0 || m_package[pos].num == 0 || m_package[pos].num < num)
			return 0;
		uid = m_package[pos].tmplId;
    }
    if(uid == 0)
    	return 0;
	SItemTemplate *pItem = itemMgr.GetItem(uid);
	if(pItem == NULL)
		return 0;
	return pItem->jiage*num;
}

bool CUser::DelPackage(uint8 pos,uint16 num)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return NoLockDelPackage(pos,num);
}

bool CUser::AddPackage(int itemId,uint16 num,const char *name,const char *mailMsg)
{
	if(num == 0)
		return false;
	bool addRes = false;
	CItemTemplateManager &itemMgr = SingletonItemManager::instance();
	SItemTemplate *pItem = itemMgr.GetItem(itemId);
	if(pItem == NULL)
		return false;
	do{
		SItemInstance item;
		item.tmplId = itemId;
		if(num > EItemDieJiaNum)
		{
			item.num = EItemDieJiaNum;
			num -= EItemDieJiaNum;
		}
		else
		{
			item.num = num;
			num = 0;
		}
		if (itemId == 2441 || itemId == 2442)
		{
			int mapId = GetLevel() / 10;
			mapId = Random(0, mapId);
			if (mapId == 0)
				mapId = 7;
			item.extData = mapId * 100 + Random(1, 3);
		}
		{
			boost::recursive_mutex::scoped_lock lk(m_mutex);
			if(name != NULL)
			{
				snprintf(item.name,sizeof(item.name),"%s",name);
			}
			addRes = NoLockAddPackage(item,mailMsg);
		}
		if(!addRes)
			return addRes;
	}while(num > 0);
	return addRes;
}

uint8 CUser::GetExtData8(uint16 pos)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return NoLockGetExtData8(pos);
}
void  CUser::SetExtData8(uint16 pos,uint8 val)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	NoLockSetExtData8(pos,val);
}

uint16 CUser::GetDCMissExtData8Id(int miss)
{
	int extData8 = 0;
	switch (miss)
	{
	case EMISS_DC_COPY: // 普通副本
		extData8 = 625;
		break;
	case EMISS_DC_8: // 寻宠
		extData8 = 621;
		break;

	case EMISS_DC_39: // 捉妖
		extData8 = 596;
		break;

	case EMISS_DC_40: // 坐骑进阶
		extData8 = 607;
		break;

	case EMISS_DC_41: // 坐骑强化
		extData8 = 597;
		break;

	case EMISS_DC_43: // 培养羽翼
		extData8 = 598;
		break;

	case EMISS_DC_44: //完成x次宝图任务
		extData8 = 599;
		break;

	case EMISS_DC_45: // 使用藏宝图
		extData8 = 600;
		break;

	case EMISS_DC_46: // 高级藏宝图
		extData8 = 601;
		break;

	case EMISS_DC_47: // 学习天书技能
		extData8 = 602;
		break;

	case EMISS_DC_48: // 护送神将x次
		extData8 = 603;
		break;

	case EMISS_DC_49: // 英勇试炼击败第X关守护者
		extData8 = 604;
		break;

	case EMISS_DC_51: // 膜拜强者x次
		extData8 = 606;
		break;

	case EMISS_DC_53: // 开启背包x次
		extData8 = 609;
		break;

	case EMISS_DC_54: // 帮派捐献
		extData8 = 610;
		break;

	case EMISS_DC_55: // 帮派种植
		extData8 = 611;
		break;

	case EMISS_DC_56: // 普通祈福
		extData8 = 612;
		break;

	case EMISS_DC_57: // 元宝祈福
		extData8 = 613;
		break;

	case EMISS_DC_58: // 摇钱树
		extData8 = 614;
		break;

	case EMISS_DC_63: // 提升x次神将血脉
		extData8 = 635;
		break;

	case EMISS_DC_67: // 角色击杀的怪物数量达到x
		extData8 = 459;
		break;

	case EMISS_DC_70: // 累计充值超过x元
		extData8 = 14;
		break;

	case EMISS_DC_37: // 修仙历练
		extData8 = 640;
		break;

	default:
		extData8 = 0;
		break;
	}
	return extData8;
}

uint32 CUser::GetDailyMissData8Id(int missId)
{
	switch (missId)
	{
	case MISSION_ID_ZhuoGui:
		return 596;

	case MISSION_ID_ShiMen:
		return 615;

	case MISSION_ID_XunBao:
		return 599;

	case MISSION_ID_DanYuan:
		return 638;

	case MISSION_ID_ShaDiDuoBao:
		return 637;

	case MISSION_ID_HuSong:
		return 603;

	case MISSION_ID_ZhouRiChang:
		return 636;
	}
	return 0;
}

uint8 CUser::GetDCMissExtData8(int miss, int level/* = 0*/)
{
	int data8Id = GetDCMissExtData8Id(miss);
	if (data8Id != 0)
		return GetExtData8(data8Id + level);

	return 0;
}

uint8 CUser::GetDailyMissCompleteCnt(int missId)
{
	uint32 dataId = GetDailyMissData8Id(missId);
	if (dataId != 0)
		return GetExtData8(dataId);

	return 0;
}

void CUser::AddDailyMissCompleteCnt(int missId)
{
	uint32 dataId = GetDailyMissData8Id(missId);
	SetExtData8(dataId, GetExtData8(dataId) + 1);
}


uint16 CUser::GetExtData16(uint16 pos)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return NoLockGetExtData16(pos);
}
void  CUser::SetExtData16(uint16 pos,uint16 val)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	NoLockSetExtData16(pos,val);
}

uint8 CUser::AddExtData8(uint16 pos, uint8 val)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	int curVal = NoLockGetExtData8(pos) + val;
	if (curVal > 0xff) curVal = 0xff;
	NoLockSetExtData8(pos, curVal);
	return curVal;
}

uint16 CUser::AddExtData16(uint16 pos, uint16 val)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	int curVal = NoLockGetExtData16(pos) + val;
	if (curVal > 0xffff) curVal = 0xffff;
	NoLockSetExtData16(pos, curVal);
	return curVal;
}

uint16 CUser::SubExtData16(uint16 pos, uint16 val)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	int curVal = NoLockGetExtData16(pos);
	if (curVal > val)
		curVal -= val;
	else
		curVal = 0;
	NoLockSetExtData16(pos, curVal);
	return curVal;
}

uint32 CUser::GetExtData32(uint16 pos)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return NoLockGetExtData32(pos);
}

void CUser::SetExtData32(uint16 pos,uint32 val)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	NoLockSetExtData32(pos,val);
}

uint64 CUser::GetExtData64(uint16 pos)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return NoLockGetExtData64(pos);
}

void CUser::SetExtData64(uint16 pos, uint64 val)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	NoLockSetExtData64(pos, val);
}


uint8 CUser::NoLockGetExtData8(uint16 pos)
{
	map<uint16,uint8>::iterator i = m_saveData8.find(pos);
	if(i != m_saveData8.end())
		return i->second;
	return 0;
}

void  CUser::NoLockSetExtData8(uint16 pos,uint8 val)
{
	m_saveData8[pos] = val;
}

uint16 CUser::NoLockGetExtData16(uint16 pos)
{
	map<uint16,uint16>::iterator i = m_saveData16.find(pos);
	if(i != m_saveData16.end())
		return i->second;
	return 0;
}

void  CUser::NoLockSetExtData16(uint16 pos,uint16 val)
{
	m_saveData16[pos] = val;
}

uint32 CUser::NoLockGetExtData32(uint16 pos)
{
	map<uint16,uint32>::iterator i = m_saveData32.find(pos);
	if(i != m_saveData32.end())
		return i->second;
	return 0;
}

uint64 CUser::NoLockGetExtData64(uint16 pos)
{
	map<uint16, uint64>::iterator i = m_saveData64.find(pos);
	if (i != m_saveData64.end())
		return i->second;
	return 0;
}


void  CUser::NoLockSetExtData32(uint16 pos,uint32 val)
{
	m_saveData32[pos] = val;
}

void CUser::NoLockSetExtData64(uint16 pos, uint64 val)
{
	m_saveData64[pos] = val;
}


bool CUser::NoLockAddPackage(SItemInstance &item,const char *mailMsg)
{
	if(item.num < 1)
		return false;
	CItemTemplateManager &itemMgr = SingletonItemManager::instance();
	SItemTemplate *pItem = itemMgr.GetItem(item.tmplId);
	if(pItem == NULL)
		return false;

	CSocketServer &sock = SingletonSocket::instance();
	uint16 curMaxPackNum = MAX_PACKAGE_NUM2;
	uint16 addNum = item.num;
	//if(pItem->type == EIT_Normal || pItem->type == EIT_Box_1 || pItem->type == EIT_Box_3 || pItem->type == EIT_PetBook || pItem->type == EIT_Special)
	{
		for(int i = 0; i < curMaxPackNum; i++)
		{
			if(m_package[i] == item && m_package[i].num < EItemDieJiaNum)
			{
				if(m_package[i].num + addNum <= EItemDieJiaNum)
				{
					m_package[i].num += addNum;
					addNum = 0;
				}
				else
				{
					addNum -= EItemDieJiaNum - m_package[i].num;
					m_package[i].num = EItemDieJiaNum;
				}
				
				CNetMessage msg;
				msg.SetType(PRO_UPDATE_PACK);
				msg<<(uint8)2;			// update
				MakePack(m_package[i],i,msg);
				sock.SendMsg(m_sock,msg);

				if(addNum == 0)
				{
					NolockUpdateItemNumMap(item.tmplId,item.num,true);
					return true;
				}
			}
		}
	}

	for(int i = 0; i < curMaxPackNum; i++)
	{
		if(m_package[i].tmplId == 0)
		{
			m_package[i] = item;
			m_package[i].num = addNum;
			if(m_package[i].num > EItemDieJiaNum)
			{
				m_package[i].num = EItemDieJiaNum;
				addNum -= EItemDieJiaNum;
			}
			else
			{
				addNum = 0;
			}

			if (m_package[i].tmplId == 2441 || m_package[i].tmplId == 2442)
			{
				int mapId = GetLevel() / 10;
				if (mapId > 7)
					mapId = 7;
				mapId = Random(0, mapId);
				if (mapId == 0)
					mapId = 7;
				m_package[i].extData = mapId * 100 + Random(1, 3);
			}

			CNetMessage msg;
			msg.SetType(PRO_UPDATE_PACK);
			msg<<(uint8)1;			// add
			MakePack(m_package[i],i,msg);
			sock.SendMsg(m_sock,msg);

			if(addNum == 0)
			{
				NolockUpdateItemNumMap(item.tmplId,item.num,true);
				return true;
			}
		}
	}
	
	NolockUpdateItemNumMap(item.tmplId,item.num-addNum,true);
	item.num = addNum;
	// 背包满发邮件
	SMailData mdata;
	mdata.AddAward(item.tmplId, 0, addNum);
	if(mailMsg == NULL)
		SendSystemMail(m_roleId,LANGUAGE_TRANSFORM_1998,&mdata);
	else
		SendSystemMail(m_roleId,mailMsg,&mdata);
	SendSysInfo(this,MakeStringColor(LANGUAGE_TRANSFORM_1999,TIPS_FAILURE_COLOR).c_str());
	return true;
}

void CUser::Multi_Exp_UpdateActiveTime()
{
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 type = CHuoDongAwardManager::EXP_TEN_REWARD;
	int dt = 0;
	int curTime = GetSysTime();
	uint16 doubleType = 0;
	if (awardManager.InHuodongLimit(this,type))
	{
		uint32 startTime = awardManager.GetHuoDongStartTime(type);
		uint32 dailyEndTime = CurlZeroTime(curTime) + CHuoDongAwardManager::EXP_TEN_REWARD_END * 3600;
		SetExtData32(144, startTime);
		dt = dailyEndTime - curTime;
		doubleType = EET_TenTimesFestival;
	}

	if (dt <= 0)
	{
		dt = m_userDoubleEnd - curTime;
		doubleType = m_useDoubleType;
	}

	if(dt <= 0)
		return;

	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_MULTI_EXP_TIME);
	msg<<(uint8)1<<dt<<doubleType;
	sock.SendMsg(m_sock,msg);
}

void CUser::Multi_Exp_DelActiveTime()
{
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_MULTI_EXP_TIME);
	msg<<(uint8)2;
	sock.SendMsg(m_sock,msg);
}

void CUser::Multi_Exp_Notice()
{
	uint8 weekCanUseNum = 28;
	int todayNum = 4 - GetExtData8(83);
	int weekNum = weekCanUseNum - GetExtData8(84);
	char buf[512];
	if(m_useDoubleType == EET_TwoTimes)
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_2000\
			LANGUAGE_TRANSFORM_2001,GGCT_GREEN,GetItemName(1800),GGCT_GREEN,GGCT_GREEN,todayNum,GGCT_GREEN,weekNum);
	else if(m_useDoubleType == EET_FiveTimes)
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_2002\
			LANGUAGE_TRANSFORM_2003,GGCT_GREEN,GetItemName(1801),GGCT_GREEN,GGCT_GREEN,todayNum,GGCT_GREEN,weekNum);
	else if(m_useDoubleType == EET_TenTimes)
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_2004\
			LANGUAGE_TRANSFORM_2005,GGCT_GREEN,GetItemName(1802),GGCT_GREEN,GGCT_GREEN,todayNum,GGCT_GREEN,weekNum);
	else
		return;

	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_MULTI_EXP_TIME);
	msg<<(uint8)3<<buf;
	sock.SendMsg(m_sock,msg);
}

// type = 1 押镖 0 不押镖
void CUser::SendYaBiaoMissionState(uint8 type,uint8 quality)
{
	CNetMessage msg;
	msg.SetType(MSG_HUODONG_OPTION);
	msg<<(uint16)10<<(uint8)type<<quality;
	CSocketServer &sock = SingletonSocket::instance();
	sock.SendMsg(m_sock,msg);
	UpdateUserInfo(this,ESRT_HuSong);
}

bool CUser::NoLockDelPackage(uint8 pos,uint16 num)
{
	if(pos < MAX_PACKAGE_NUM2)
	{
		if(m_package[pos].tmplId != 0)// && (m_package[pos].num >= num))
		{
			if((uint16)m_package[pos].num > num)
			{
				NolockUpdateItemNumMap(m_package[pos].tmplId,num,false);
				m_package[pos].num -= num;
			}
			else
			{
				NolockUpdateItemNumMap(m_package[pos].tmplId,m_package[pos].num,false);
				m_package[pos].Clear();
			}
			CSocketServer &sock = SingletonSocket::instance();
			CNetMessage msg;
			msg.SetType(PRO_UPDATE_PACK);
			msg<<(uint8)2;			// update
			MakePack(m_package[pos],pos,msg);
			sock.SendMsg(m_sock,msg);

			return true;
		}
	}
	return false;
}

bool CanAddShuXing(SItemTemplate *pItem,SItemInstance *pInst)
{
	//if(pItem->type <= EIT_WuQi_6 || pItem->type >= EIT_TouKui_1)
		return true;
	//else
		return false;
}

bool CUser::CanMeetEnemy()
{
	uint32 TIME_SPACE = 3;
	if(m_meetEnemy)
	{
		if(m_pScene != NULL)
		{
			// 副本不做校验
			int srcSid = m_pScene->GetSrcSceneId();
			if(srcSid >= COPY_ID_QIANG_HUA && srcSid <= COPY_ID_CHONG_KAI)
			{
				TIME_SPACE = 1;
				if(m_clientFightEndTime > 0)
					return (GetSysTime() - m_clientFightEndTime > TIME_SPACE);
				return true;
			}
		}
		if(m_clientFightEndTime > 0)
			return (GetSysTime() - m_clientFightEndTime > TIME_SPACE);
		else
			return (GetSysTime() - m_lastFightTime > 30);
	}
	return false;
}

uint8 CUser::GetAttackType()
{
	return m_attackType;
}

void CUser::GetBasicAttr(SUnitBasicAttr &basicAttr)
{
	basicAttr = m_attr;
}

int CUser::GetAttack()
{
	return m_attr.attack;
}

int CUser::GetWuFang()
{
	return m_attr.wufang;
}

int CUser::GetFaFang()
{
	return m_attr.fafang;
}

int CUser::GetMaxHp()
{
	return m_attr.maxHp;
}

int CUser::GetSpeed()
{
	return m_attr.speed;
}

int CUser::GetMingZhong()
{
	return m_attr.mingzhong;
}

int CUser::GetShanBi()
{
	return m_attr.shanbi;
}

int CUser::GetBaoJi()
{
	return m_attr.baoji;
}

int CUser::GetBaoJiKang()
{
	return m_attr.baojikang;
}

int CUser::GetMingZhongLv()
{
	return m_attr.mingzhongLv;
}

int CUser::GetShanBiLv()
{
	return m_attr.shanbiLv;
}

int CUser::GetBaoJiLv()
{
	return m_attr.baojiLv;
}

int CUser::GetBaoJiKangLv()
{
	return m_attr.baojikangLv;
}

int CUser::GetZengShangLv()
{
	return m_attr.zengshangLv;
}

int CUser::GetWuMianLv()
{
	return m_attr.wumianLv;
}

int CUser::GetFaMianLv()
{
	return m_attr.famianLv;
}

int CUser::GetBaoJiAdd()
{
	return m_attr.baojiAdd;
}

int CUser::GetFanJiLv()
{
	return m_attr.fanjiLv;
}

int CUser::GetFanJiKangLv()
{
	return m_attr.fanjikangLv;
}

int CUser::GetFanJiAdd()
{
	return m_attr.fanjiAdd;
}

int CUser::GetLianJiLv()
{
	return m_attr.lianjiLv;
}

int CUser::GetLianJiKangLv()
{
	return m_attr.lianjikangLv;
}

int CUser::GetLianJiAdd()
{
	return m_attr.lianjiAdd;
}

int CUser::GetFanZhenLv()
{
	return m_attr.fanzhenLv;
}

int CUser::GetFanZhenKangLv()
{
	return m_attr.fanzhenkangLv;
}

int CUser::GetFanZhenAdd()
{
	return m_attr.fanzhenAdd;
}

int CUser::GetFuMianAdd()
{
	return m_attr.fumianAdd;
}

int CUser::GetFuMianKangAdd()
{
	return m_attr.fumianKangAdd;
}

void CUser::MakeUpdateInfo(CNetMessage &msg,CUser *pUser,uint8 uType)
{
	if(pUser == NULL || uType > ESRT_MAX || uType == 0)
		return;

	msg<<m_roleId<<uType;
	switch(uType)
	{
		case ESRT_State:
			{
				uint32 state = 0;
				if (m_fightId != 0)
				{
					state |= ENRS_FIGHT;
				}

				int srcSceneId = GetSrcSceneId();
				if(srcSceneId == BANG_PAI_SCENE_ID || srcSceneId == BP_FIGHT_SID || srcSceneId == KUAFU_BZ_SID)
				{
					int bangId = pUser->GetBangPai();
					if((bangId != (int)m_bangpai) || (bangId == 0 && m_bangpai == 0))
						state |= ENRS_CAN_KILL;
				}
				else if(srcSceneId == SHENJIEMIJING_SCENE_ID)
				{
#ifdef KUA_FU
					if(GetServerZone(m_serverId) != GetServerZone(pUser->GetServerId()))
						state |= ENRS_CAN_KILL;
#endif
				}
				
				// 帮派放火，偷窃状态，优先放火状态
				uint32 curTime = (uint32)GetSysTime();
				if(curTime - GetBangPaiFireTime() < FIRE_STATE_TIME_LIMIT)
					state |= ENRS_BANGPAI_FIRE;
				else if(curTime - GetBangPaiStealTime() < STEAL_STATE_TIME_LIMIT)
					state |= ENRS_BANGPAI_STEAL;
				
				if(srcSceneId == FEI_XIAN_SID5)
				{
					if(GetFeiXianState() > 0)
						state |= ENRS_FEI_XIAN;
				}
				int collectIdx = GetCollectIndex();
				if (collectIdx == 76
					|| collectIdx == 77
					|| collectIdx == 78)
					state |= ENRS_COLLECT_TOWER;
				msg<<state;
			}
			break;
		case ESRT_Name:
			{
				msg<<m_name;
			}
			break;
		case ESRT_BangPai:
			{
				msg<<m_bangpai<<m_bangpaiName<<m_bangpaiRank<<GetBangPaiShowInfo();
			}
			break;
		case ESRT_JingJie:
			{
				MakeJingJieTitleMsg(msg);
			}
			break;
		case ESRT_Title:
			{
				GetUseTitleMsg(msg);
			}
			break;
		case ESRT_ShenQi:
			{
				msg<<GetNewShenQiCarryID();
			}
			break;
		case ESRT_Vip:
			{
				uint8 vipLv = HaveBitSet(604) ? 0 : GetVipLevel();
				msg<<vipLv;
			}
			break;
		case ESRT_Pet_Follow:
			{
				uint16 genSuiPetId = GetGenSuiPetId();
				if(genSuiPetId == 0)
				{
					msg<<0;
				}
				else
				{
					SharePetPtr pPet = m_pet[m_gensuiPet];
					if(pPet.get() != NULL)
						msg<<pPet->pic<<pPet->name<<pPet->quality;
					else
						msg<<0;
				}
			}
			break;
		case ESRT_Mount_State:
			{
				if(m_mount.m_useIndex == 0xff)
				{
					msg<<(uint8)0;
				}
				else
				{
					uint8 index = m_mount.m_useIndex;
					if(index < m_mount.m_num)
						msg<<m_mount.m_id[index]<<m_mount.GetMoveSpeed(index);
					else
						msg<<(uint8)0;
				}
			}
			break;
		case ESRT_Fish_State:
			{
				if(m_fishState == CFishRoom::ERS_FISHING)
					msg<<(uint8)m_face;
				else
					msg<<(uint8)0xff;
			}
			break;
		case ESRT_Wing:
			{
				msg<<GetWingId();
			}
			break;
		case ESRT_HuSong:
			{
				msg<<InHuSongMission()<<GetHuSongMissionQuality();
			}
			break;
		case ESRT_TransormShape:
			{
				uint8 tranState = HaveBitSet(600) ? 1 : 0;
				msg<<GetTransFormMonsterID(GetCurTransFormID())<<tranState;
			}
			break;
		case ESRT_Foot:
			{
				msg<<GetUseFootPrintID();
			}
			break;
		default:
			break;
	}
}

// 获取加成属性
int CUser::GetLianTiShuXing(EAttrType type)
{
	//return 30000; // TODO:PJ 测试增加属性
	// 属性类型校验
	if ((type < 1) || (type > 6))
		return 0;

	int oneLv = GetLianTiLevel(type);
	int allLv = GetLianTiQuanLevel();

	// 属性加成值计算
	int oneAdd = 0;
	int allAdd = 0;

	int index1 = oneLv/10;
	int index2 = 0;
	if(oneLv > 0)
	{
		index2 = oneLv%10;
		if(index2 == 0)
			index2 = 10;
	}
	oneAdd = 25*(index1+3)*index1 + (5*index1+10)*index2;
	allAdd = 25*allLv;
	return (oneAdd + allAdd);
}

// 获取等级
int CUser::GetLianTiLevel(EAttrType type)
{
	// 属性类型校验
	if ((type < 1) || (type > 6))
		return 0;

	static int dataIdx = 22; // 起始索引
	return GetExtData16(dataIdx+type);
}

// 获取经验
int CUser::GetLianTiJingYan(EAttrType type)
{
	// 属性类型校验
	if ((type < 1) || (type > 6))
		return 0;

	static int dataIdx = 77; // 起始索引
	return GetExtData32(dataIdx+type);
}

// 获取全属性等级
int CUser::GetLianTiQuanLevel()
{
	return GetExtData16(28);
}

// 获取全属性经验
int CUser::GetLianTiQuanJingYan()
{
	return GetExtData32(83);
}

// 获取升级所需经验
int CUser::GetLianTiNeedExp(int level)
{
	return (level+1)*10; // 等级从0开始
}

// 获取全属性升级所需经验
int CUser::GetLianTiQuanNeedExp(int level)
{
	if (level < 0)
		return 0;
	++level; // 等级从0开始

	/* 小学生的高速算法，经验值如果不规律的话，会出问题。到时可以用后面注释的方法 */
	// 目标计算起始等级，目标计算终止等级
	int startLv = 0, endLv = 0;
	endLv = 5+(level-1)*10;
	startLv = endLv - 10 + 1;
	if (startLv < 0)
		startLv = 0;

	// 首项经验，末项经验
	int startExp = GetLianTiNeedExp(startLv);
	int endExp = GetLianTiNeedExp(endLv);
	int needExp = 3*(startExp+endExp)*(endLv-startLv+1)/2;

	return needExp;

	/* 傻瓜算法，怎么样算都不会出问题
	// 目标计算起始等级，目标计算终止等级
	int startLv = 0, endLv = 0;
	endLv = 5+(level-1)*10;
	startLv = endLv - 10;
	if (startLv < 0)
		startLv = 0;

	// 目标计算起始经验，目标计算终止经验
	int startExp = 0, endExp = 0;
	int tmpLvExp = 0; // 临时储存 当前等级升级所需经验
	for (int i = 1; i <= endLv; ++i)
	{
		tmpLvExp = GetLianTiNeedExp(i);
		if (i <= startLv)
			startExp += tmpLvExp;
		endExp += tmpLvExp;
	}

	return (3*(endExp-startExp));
	*/
}

// 增加炼体经验
void CUser::AddLianTiJingYan(EAttrType type, int exp)
{
	// 对应属性增加经验
	static int dataIdx = 77; // 起始索引
	bool needSyncRoleInfo = false; // 是否需要更新属性
	int addExp = exp;
	int curExp = GetLianTiJingYan(type);
	int needExp = GetLianTiNeedExp(GetLianTiLevel(type));
	if ((curExp + addExp) >= needExp) // 升级了
	{
		addExp = curExp + addExp - needExp;
		if(GetExtData16(22+type)%10 == 0)
			needSyncRoleInfo = true;
		AddLianTiLevel(type);
		SetExtData32(dataIdx+type,addExp);
		needSyncRoleInfo = true;

		int beginQuanShuXingLevel = GetExtData16(28);
		uint16 values[5];
		for(uint8 i=0;i < 5;i++)
			values[i] = GetExtData16(23+i);
		sort(&values[0],&values[4]);
		for(int i=10;i >= 0;i--)
		{
			if(values[2] >= i*10-5)
			{
				SetExtData16(28,i);
				break;
			}
		}
		if(beginQuanShuXingLevel != GetExtData16(28))
			needSyncRoleInfo = true;
		if(needSyncRoleInfo)
		{
			InitAndUpdate();
		}
	}
	else
	{
		SetExtData32(dataIdx+type,curExp+addExp);
	}

/*
	// 全属性增加经验
	addExp = exp;
	curExp = GetLianTiQuanJingYan();
	needExp = GetLianTiQuanNeedExp(GetLianTiQuanLevel());
	if ((curExp + addExp) >= needExp)
	{
		addExp = curExp + addExp - needExp;
		AddLianTiQuanLevel();
		SetExtData32(83,addExp);
		needSyncRoleInfo = true;
	}
	else
		SetExtData32(83,curExp + addExp);
	if (needSyncRoleInfo)
	{
		Init();
		UpdateInfo();
	}
*/
}

// 增加炼体等级
void CUser::AddLianTiLevel(EAttrType type)
{
	static int dataIdx = 22; // 起始索引
	SetExtData16(dataIdx+type,GetExtData16(dataIdx+type)+1);
}

// 增加全属性炼体等级
void CUser::AddLianTiQuanLevel()
{
	SetExtData16(28,GetExtData16(28)+1);
}

// 获取炼体信息
void CUser::MakeLianTiInfo(CNetMessage &msg)
{
//	msg<<(uint16)GetLianTiLevel(EAALiLiang)<<(uint32)GetLianTiJingYan(EAALiLiang);
//	msg<<(uint16)GetLianTiLevel(EAALingXing)<<(uint32)GetLianTiJingYan(EAALingXing);
//	msg<<(uint16)GetLianTiLevel(EAANaiLi)<<(uint32)GetLianTiJingYan(EAANaiLi);
//	msg<<(uint16)GetLianTiLevel(EAATiZhi)<<(uint32)GetLianTiJingYan(EAATiZhi);
//	msg<<(uint16)GetLianTiLevel(EAAMinJie)<<(uint32)GetLianTiJingYan(EAAMinJie);
//	msg<<(uint16)GetLianTiQuanLevel()<<(uint32)GetLianTiQuanJingYan();
}

// 升级炼体
void CUser::UpgredeLianTi(CNetMessage &msg, EAttrType type, int itemPos)
{
	msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2009,TIPS_FAILURE_COLOR);
	return;
	
	if(GetLevel() < 70)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2010,TIPS_FAILURE_COLOR);
		return;
	}

	// 属性类型校验
	if ((type < 1) || (type > 5))
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2011,TIPS_FAILURE_COLOR);
		return;
	}

	// 获取炼体丹
	SItemInstance *pInst = m_package+itemPos;
	if (pInst == NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2012,TIPS_FAILURE_COLOR);
		return;
	}

	// 炼体丹合法性校验
	int addExp = 0; // 炼体丹增加的经验
	if (pInst->tmplId == 2330) // 普通炼体丹
		addExp = 2;
	else if (pInst->tmplId == 2331) // 极品炼体丹
		addExp = 5;
	else
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2013,TIPS_FAILURE_COLOR);
		return;
	}

	// 删除消耗连提丹
	NoLockDelPackage(itemPos);

	// 增加炼体经验
	AddLianTiJingYan(type,addExp);

	// 更新炼体后信息
	msg<<PRO_SUCCESS<<(uint8)type<<(uint16)GetLianTiLevel(type)<<(uint32)GetLianTiJingYan(type)<<(uint16)GetLianTiQuanLevel()<<(uint32)GetLianTiQuanJingYan();

	// 阶段目标
	//if ((GetLianTiQuanLevel() == 1) && (!HaveSGBitSet(127)))
	//	FinishStageGoalSection(3,3); // 炼体达到第一重

}

// 重置闯关通知
void CUser::ResetChuangGuanNotify()
{
	CNetMessage msg;
	msg.SetType(MSG_CHUANG_GUAN);
	msg<<(uint8)CXunBaoManage::ECGOp_Reset;
	SingletonSocket::instance().SendMsg(m_sock,msg);
}

void CUser::SendShiLianGetAwardPanel()
{
	int floor = GetExtData8(136);
	int openBox = GetExtData8(137);
	if(floor == openBox)
		return;

	uint8 chooseNum = GetExtData8(67);
	if(chooseNum > 0)
	{
		CNetMessage msg;
		ExitChooseShiLianAward(msg);
		return;
	}
	if(IsShiLianRandAwardEmpty())
	{
		int subType = openBox/5 + 1;
		int dropId = sCDropMatchingMgr.GetActivityDropId(SOT_Shilian,subType);
		if(dropId == 0)
			return;
		vector<SAwardData> award;
		sAwardManager.GetLevelRandAward(dropId, m_level, award, SHI_LIAN_SHOW_AWARD_NUM);
		if(award.empty())
			return;
		SetShiLianRandAward(award);
	}
	
	uint8 size = m_shilianRandAward.size();
	CNetMessage msg;
	msg.SetType(MSG_SHI_LIAN);
	msg<<(uint8)3<<SHI_LIAN_COST_YB2<<SHI_LIAN_COST_YB3;
	msg<<size;
	for(uint8 i=0;i < size;i++)
	{
		msg<<(uint8)(i+1)<<(uint16)m_shilianRandAward[i].type<<m_shilianRandAward[i].num;
	}
	SingletonSocket::instance().SendMsg(m_sock,msg);
}

bool CUser::GetShiLianAwardByIdx(int idx,CNetMessage &msg)
{
	if(idx < 1 || idx > (int)SHI_LIAN_SHOW_AWARD_NUM)
		return false;
	int floor = GetExtData8(136);
	int openBox = GetExtData8(137);
	if(floor == openBox)
		return false;
	if(IsShiLianRandAwardEmpty())
		return false;

	uint8 chooseNum = GetExtData8(67);
	uint8 size = m_shilianRandAward.size();
	if(chooseNum >= SHI_LIAN_SHOW_AWARD_NUM)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0527,TIPS_FAILURE_COLOR);
		return true;
	}
	if(chooseNum >= size || idx > size)
		return false;
	uint8 mask = GetExtData8(469);
	if((mask & (1<<(idx-1))) > 0)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0528,TIPS_FAILURE_COLOR);
		return true;
	}

	SAwardData &award = m_shilianRandAward[idx-1];
	int YB = 0;
	if(chooseNum == 1)
		YB = SHI_LIAN_COST_YB2;
	else if(chooseNum == 2)
		YB = SHI_LIAN_COST_YB3;
	if(YB > 0)
	{
		if(GetTongBao() < YB)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0529,TIPS_FAILURE_COLOR);
			return true;
		}
		AddTongBao(-YB);
	}
	
	AddMaterial(award);
	mask |= 1<<(idx-1);
	SetExtData8(469,mask);
	SetExtData8(67,chooseNum+1);
	msg<<PRO_SUCCESS;
	return true;
}

bool CUser::ExitChooseShiLianAward(CNetMessage &msg)
{
	int floor = GetExtData8(136);
	int openBox = GetExtData8(137);
	if(floor == openBox)
		return false;
	uint8 chooseNum = GetExtData8(67);
	if(chooseNum == 0)
		return false;
	openBox++;
	
	ClearShiLianRandAward();
	SetExtData8(137,openBox);
	SetExtData8(67,0);
	SetExtData8(469,0);

	if(openBox == 15)
	{	
		SetExtData8(135,GetExtData8(135)+1);
		ShiLianNoticeToExit(this,10);
		SendSysInfo(this,LANGUAGE_SSJ_0530);
	}
	else
	{
		AddYingYongShiLianNpc();
	}
	msg<<PRO_SUCCESS;
	return true;
}

// 登陆礼包处理
void CUser::CheckDengLuLiBao()
{
	// 清除昨天的领取记录
	ClearBitSet(312);
	ClearBitSet(313);
	ClearBitSet(314);

	int cur = GetDay();
	int mon = GetMonth(); // 上个月，不是本月
	if (mon == 0)
		mon = 12;
	int last = GetExtData8(91); // 上次登陆天数
	bool isLianXu = false;
	if (cur == (last+1)) // 连续登陆情况
		isLianXu = true;
	else if ((mon == 2) && ((last == 28) || (last == 29)) && (cur == 1)) // 连续登陆情况 2月份
		isLianXu = true;
	else if (((mon == 4) || (mon == 6) || (mon == 9) || (mon == 11)) && (last == 30) && (cur == 1)) // 连续登陆情况 小月份
		isLianXu = true;
	else if (((mon == 1) || (mon == 3) || (mon == 5) || (mon == 7) || (mon == 8) || (mon == 10) || (mon == 12)) && (last == 31) && (cur == 1)) // 连续登陆情况 大月份
		isLianXu = true;
	if (isLianXu)
	{
		int sumDay = GetExtData8(92); // 连续登陆天数
		if (sumDay < 2)
			SetExtData8(92,sumDay+1);
	}
	else
		SetExtData8(92,0);
	SetExtData8(91,cur);
}

// 获取阶段目标属性奖励
void CUser::GetStageGoalAttr(int& addDamage, int& addRecovery, int& addHp)
{
	CCallScript *pCallScript = FindScript(200);
	if(pCallScript == NULL)
		return;
	pCallScript->Call("GetStageGoalAttr","u>iii",this,&addDamage,&addRecovery,&addHp);
	//cout << "获取阶段目标属性奖励:" << addDamage << "," << addRecovery << ","<<addHp<<endl;
}

// 完成阶段目标 小节 功能已经实现，可以根据bitset优化，防止重复调用
void CUser::FinishStageGoalSection(int stage,int section)
{
	return;
	CCallScript *pCallScript = FindScript(200);
	if(pCallScript == NULL)
		return;
	int needSync = 0;
	pCallScript->Call("FinishStageGoalSection","uii>i",this,stage,section,&needSync);

	if (needSync >= 1) // 是否需要通知客户端
	{
		CNetMessage msg;
		msg.SetType(MSG_STAGE_GOAL);
		msg<<(uint8)4<<(uint8)stage<<(uint8)section;
		CSocketServer &sock = SingletonSocket::instance();
		sock.SendMsg(m_sock,msg);
	}
	if (needSync == 2) // 更新段落目标
		FinishStageGoalStage(stage);
}

// 完成阶段目标 段落
void CUser::FinishStageGoalStage(int stage)
{
	CCallScript *pCallScript = FindScript(200);
	if(pCallScript == NULL)
		return;
	int needSync = 0;
	pCallScript->Call("FinishStageGoalStage","ui>i",this,stage,&needSync);

	if (needSync == 1) // 是否需要通知客户端
	{
		CNetMessage msg;
		msg.SetType(MSG_STAGE_GOAL);
		msg<<(uint8)5<<(uint8)stage;
		CSocketServer &sock = SingletonSocket::instance();
		sock.SendMsg(m_sock,msg);
	}
}

// -------------------------
// 验证是否有num个level的神将
bool CUser::VerifyPetLevelAndNum(uint32 num, uint32 level, uint32& rawnum){
	CPetMapIt it = m_pet.begin();
	for(; it != m_pet.end(); it++){
		SPet *pPet = it->second.get();
		if(pPet != NULL && pPet->level >= level)
		{
			rawnum++;
			if (rawnum >= num) {
				return true;
			}
		}
	}
	return false;
}

// -------------------------
// 验证是否有num个神将的技能
bool CUser::VerifyPetSkillLevelAndNum(uint32 num, uint32 level, uint32& rawnum){
	CPetMapIt it = m_pet.begin();
	for(; it != m_pet.end(); it++){
		SPet *pPet = it->second.get();
		int n = pPet->VerifyLevelAndNum(level);
		if(pPet!= NULL && n > 0)
		{
			rawnum += n;
			if(rawnum >= num)
			{
				return true;
			}
		}
	}
	return false;
}

// -------------------------
// 验证是否有num个神将的星星
bool CUser::VerifyPetStarLevelAndNum(uint32 num, uint32 star, uint32& rawnum){

	CPetMapIt it = m_pet.begin();

	for(; it != m_pet.end(); it++){
		SPet *pPet = it->second.get();
		if (pPet != NULL)
		{
			if (pPet->star < star)
				continue;
			if(++rawnum >= num)
				return true;

		}
	}
	return false;
}

// -------------------------
// 验证血脉
bool CUser::VerifyPetXueMaiLevelAndNum(uint32 num, uint32 level,uint32& rawnum){
	CPetMapIt it = m_pet.begin();
	for(; it != m_pet.end(); it++){
		SPet *pPet = it->second.get();
		rawnum += pPet->VerifyXueMaiLevelAndNum(level);
		if (rawnum >= num) {
			return true;
		}

	}
	return false;
}

// num个quality品质的神将
bool CUser::VerifyUserPetQualityAndNum(uint32 num, uint32 quality, uint32& verifyNum)
{
	verifyNum = 0;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	CPetMapIt it = m_pet.begin();
	for (; it != m_pet.end(); it++)
	{
		SPet *pPet = it->second.get();
		if (pPet->quality >= quality)
		{
			verifyNum++;
			if (verifyNum >= num)
			{
				return true;
			}
		}
	}
	return false;
}

// num个level级阵法
bool CUser::VerifyUserLevelFormationNum(uint32 num, uint32 level, uint32& verifyNum)
{
	verifyNum = 0;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for (size_t i = 0; i < m_zhenfa.size(); i++)
	{
		if (m_zhenfa[i].zhenfaLevel >= level)
		{
			verifyNum++;
			if (verifyNum >= num)
			{
				return true;
			}
		}
	}
	return false;
}

// num个power战力神将
bool CUser::VerifyUserPetPowerNum(uint32 num, uint32 power, uint32& verifyNum)
{
	verifyNum = 0;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	CPetMapIt it = m_pet.begin();
	for (; it != m_pet.end(); it++)
	{
		SPet *pPet = it->second.get();
		if (pPet == NULL)
			continue;
		if (pPet->zhanDouli >= power)
		{
			verifyNum++;
			if (verifyNum >= num)
			{
				return true;
			}
		}
	}
	return false;
}

// 神将装备x件强化超过y级
bool CUser::VerifyUserPetEquipStrongLevelNum(uint32 nums, uint32 level, uint32& verifyNum)
{
	// verifyNum = 0;
	// boost::recursive_mutex::scoped_lock lk(m_mutex);
	// CPetMapIt it = m_pet.begin();
	// for (; it != m_pet.end(); it++)
	// {
		// map<uint16, uint16> suitSum;
		// SPet *pPet = it->second.get();
		// for (EquipMapIt peIt = pPet->equips.begin(); peIt != pPet->equips.end(); ++peIt)
		// {
			// if (peIt->second.level >= level)
				// verifyNum++;

			// if (verifyNum >= nums)
				// return true;
		// }
	// }
	// EquipMap& equipBag = m_petEquipMgr.GetPetEquips();
	// for (EquipMapIt ecit = equipBag.begin(); ecit != equipBag.end(); ++ecit)
	// {
		// if (ecit->second.level >= level)
			// verifyNum++;

		// if (verifyNum >= nums)
			// return true;
	// }
	return false;
}

void CUser::MakePlayerInfo(CNetMessage &msg,CUser *pUser)
{
	int bangId = pUser->GetBangPai();
	uint32 state = 0;
	uint8 weddingType = 0;
	uint32 wed_role1 = 0;
	uint32 wed_role2 = 0;
	
	CBangPai *pBangPai = SingletonCBangPaiManager::instance().FindBangPai(m_bangpai);
	string bangName="";
	uint8 bangRank=0;
	if(pBangPai)
	{
		bangName = pBangPai->GetName();
		bangRank=pBangPai->GetMemberRank(m_roleId);
	}
	
	if(m_fightId != 0)
		state |= ENRS_FIGHT;
	int srcSceneId = GetSrcSceneId();
	if(srcSceneId == BANG_PAI_SCENE_ID || srcSceneId == BP_FIGHT_SID || srcSceneId == KUAFU_BZ_SID)
	{
		if((bangId != (int)m_bangpai) || (bangId == 0 && m_bangpai == 0))
			state |= ENRS_CAN_KILL;
	}
	else if(srcSceneId == SHENJIEMIJING_SCENE_ID)
	{
#ifdef KUA_FU
		if(GetServerZone(m_serverId) != GetServerZone(pUser->GetServerId()))
			state |= ENRS_CAN_KILL;
#endif
	}

	// 帮派放火，偷窃状态，优先放火状态
	uint32 curTime = (uint32)GetSysTime();
	if(curTime - GetBangPaiFireTime() < FIRE_STATE_TIME_LIMIT)
		state |= ENRS_BANGPAI_FIRE;
	else if(curTime - GetBangPaiStealTime() < STEAL_STATE_TIME_LIMIT)
		state |= ENRS_BANGPAI_STEAL;

	if(srcSceneId == FEI_XIAN_SID5)
	{
		if(GetFeiXianState() > 0)
			state |= ENRS_FEI_XIAN;
	}

	//boost::recursive_mutex::scoped_lock lk(m_mutex);
	msg<<m_roleId<<m_name<<m_bangpai<<bangName<<bangRank;
	MakeJingJieTitleMsg(msg);
	msg<<m_sex<<m_level;

	msg<<state;
	uint16 genSuiPetId = GetGenSuiPetId();
	uint8 vipLv = HaveBitSet(604) ? 0 : GetVipLevel();
	GetUseTitleMsg(msg);
	//		 神器				      vip
	msg<<GetNewShenQiCarryID()<<vipLv;
	if(genSuiPetId == 0)
	{
		msg<<0;
	}
	else
	{
		SharePetPtr pPet = m_pet[m_gensuiPet];
		if(pPet.get() != NULL)
			msg<<pPet->pic<<pPet->name<<pPet->quality;
		else
			msg<<0;
	}

	// 坐骑相关
	if(m_mount.m_useIndex == 0xff)
	{
		msg<<(uint8)0;
	}
	else
	{
		uint8 index = m_mount.m_useIndex;
		if(index < m_mount.m_num)
			msg<<m_mount.m_id[index]<<m_mount.GetMoveSpeed(index);
		else
			msg<<(uint8)0;
	}

	if(m_fishState == CFishRoom::ERS_FISHING)
		msg<<(uint8)m_face;
	else
		msg<<(uint8)0xff;
	msg<<InHuSongMission()<<GetHuSongMissionQuality()<<GetWingId();

	uint8 tranState = HaveBitSet(600) ? 1 : 0;
	msg<<GetTransFormMonsterID(GetCurTransFormID())<<tranState;
	msg<<weddingType<<wed_role1<<wed_role2<<GetUseFootPrintID();
#ifdef KUA_FU
	msg<<GetServerZone(GetServerId())<<GetServerId();
#endif

}

uint16 CUser::GetGenSuiPetId()
{
	return m_gensuiPet;
}

void CUser::SetBangPai(uint32 bangpai,uint8 rank,const char *name)
{
	if(bangpai > 0)
	{
		if(m_bangpai == 0)
			SetBangPaiShow();
	}
	else
	{
		ReSetBangPaiShow();
		//离开帮派帮派任务删除
		DelBangpaiMission();
		if (GetBangPai() == SingletonCBangPaiManager::instance().GetFirstBang())
			DelTitle(E2UT_TIANXIADIYIBANG);
	}
	m_bangpai = bangpai;
	m_bangpaiRank = rank;
	if(name != NULL)
		m_bangpaiName = name;
	else
		m_bangpaiName.clear();
	
	if(bangpai == 0)
	{
		SetData32(5,0);
		//帮派活跃次数记录
		for (int i=651;i<676;++i)
		{
			SetExtData8(i,0);
		}
	}
}

void CUser::SetBangPaiName(string name)
{
	m_bangpaiName = name;
}

uint8 CUser::InHuSongMission()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return NoLockInHuSongMission();
}

uint8 CUser::NoLockInHuSongMission()
{
	if(NoLockHaveCMission(105))	// 护送任务
		return 1;
	else	// 正常
		return 0;
}

bool CUser::InTreasure()
{
	return (GetExtData16(45) > 0 ? true : false);
}

uint8 CUser::GetHuSongMissionQuality()
{
	char *split[10];
	
	const char *pMission = GetCMissionContent(this, MISSION_ID_HuSong);
	if(pMission != NULL)
	{
		if(strlen(pMission) == 0)
			return 0xff;
		string str = pMission;
		int num = SplitLine(split,5,(char*)str.c_str());
		if(num < 3)
		{
			cout<<LANGUAGE_TRANSFORM_2041<<endl;
			return 0xff;
		}
		uint8 quality = (uint8)atoi(split[0]);
		return quality;
	}
	return 0xff;
}

void CUser::ReadBangPai()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb != NULL)
	{
		char buf[128];
		snprintf(buf,sizeof(buf),"select bangpai_id,`rank` from bang_pai_role where role_id=%u",m_roleId);
		if(pDb->Query(buf))
		{
			char **row = pDb->GetRow();
			if(row != NULL)
			{
				m_bangpai = atoi(row[0]);

				CBangPai *pBangPai = SingletonCBangPaiManager::instance().FindBangPai(m_bangpai);
				if(pBangPai != NULL)
				{
					m_bangpaiName = pBangPai->GetName();
					m_bangpaiRank = pBangPai->GetMemberRank(m_roleId);
					return;
				}
			}
		}
	}
	m_bangpai = 0;
	m_bangpaiRank = 0;
	m_bangpaiName.clear();
	SetData32(5,0);
}

void CUser::AfterJoinBangPai()
{
	// ==================
	// 更新加入帮派任务
	SingletonCMissionManager::instance().VerifyNewBranchMissionFinish(this, EMISS_DC_18);
	AddBangpaiMission();//离开重新加帮处理
	char buf[256];
	snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0040, m_bangpaiName.c_str());
	SendSystemMail(GetRoleId(), buf);
	if (GetBangPai() == SingletonCBangPaiManager::instance().GetFirstBang())
		AddTitle(E2UT_TIANXIADIYIBANG);
	UpdateBangHuoYue(EBHT_Login);
}

bool CUser::SetGenSuiPet(uint16 petId)
{
	if(petId > 0)
	{
		if(GetPet(petId).get() == NULL)
			return false;
	}
	m_gensuiPet = petId;
	return true;
}

void CUser::InitChuZhanPet()
{
	for (size_t i = 1; i <= 5; i++)
	{
		UpdateZhenFaPetInfo(i, false);
	}
}

// 召回（取消观看）
void CUser::SetPetHide(uint16 petId)
{
	if(m_gensuiPet == petId)
		m_gensuiPet = 0;

	SharePetPtr pet;
	SPet *pPet = GetPet(petId).get();
	if(pPet != NULL)
	{
//		uint8 state = 0;
//		if(pPet->chuzhanFlag == 1)
//			state |= 0x2;
//		UpdatePetInfo(petId,1,state);
	}
}

void CUser::SendItemTimeOut()
{
	bool delTime = true;
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 type = CHuoDongAwardManager::EXP_TEN_REWARD;

	if (GetExtData32(144) != 0)
	{
		if (! awardManager.InHuodongLimit(this,type))
			SetExtData32(144, 0);
		else
			delTime = false;
	}

	if(m_userDoubleEnd != 0)
	{
		if (m_userDoubleEnd < GetSysTime())
		{
			char buf[64] = {0};
			m_userDoubleEnd = 0;
			if(m_useDoubleType == EET_TwoTimes)
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_2050,GetItemName(1800));
			else if(m_useDoubleType == EET_FiveTimes)
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_2051,GetItemName(1801));
			m_useDoubleType = EET_NoTimes;
		}
		else
			delTime = false;
	}
	else
		delTime = false;

	if (delTime)
		Multi_Exp_DelActiveTime();
}

const char *pLiHuaMsg[] =
{
	LANGUAGE_TRANSFORM_2052,
	LANGUAGE_TRANSFORM_2053,
	LANGUAGE_TRANSFORM_2054,
	LANGUAGE_TRANSFORM_2055,
	LANGUAGE_TRANSFORM_2056,
	LANGUAGE_TRANSFORM_2057,
	LANGUAGE_TRANSFORM_2058,
	LANGUAGE_TRANSFORM_2059,
	LANGUAGE_TRANSFORM_2060,
	LANGUAGE_TRANSFORM_2061,
	LANGUAGE_TRANSFORM_2062,
	LANGUAGE_TRANSFORM_2063,
	LANGUAGE_TRANSFORM_2064,
	LANGUAGE_TRANSFORM_2065,
	LANGUAGE_TRANSFORM_2066,
	LANGUAGE_TRANSFORM_2067,
	LANGUAGE_TRANSFORM_2068,
	LANGUAGE_TRANSFORM_2069,
	LANGUAGE_TRANSFORM_2070,
	LANGUAGE_TRANSFORM_2071,
	LANGUAGE_TRANSFORM_2072,
	LANGUAGE_TRANSFORM_2073,
	LANGUAGE_TRANSFORM_2074,
};

CCallScript *CUser::NoLockUseItem(uint8 pos,int *pAddHp,int *pAddMp,uint8 val,uint8 val1,uint8 num)
{
	if(pos >= MAX_PACKAGE_NUM)
		return NULL;
	if(num == 0)
		return NULL;
	SItemInstance *pInst = m_package+pos;
	if(pInst == NULL || pInst->num == 0)
		return NULL;
	if (pInst->num < num)
		num = pInst->num;
	SItemTemplate *pItem = SingletonItemManager::instance().GetItem(pInst->tmplId);
	if(pItem == NULL)
		return NULL;
	if(pAddHp != NULL)
		*pAddHp = -1;
	if(pAddMp != NULL)
		*pAddMp = -1;

	if (NoLockGetItemNum(pInst->tmplId) < num)
		return NULL;
	if(pItem->id == 1801 || pItem->id == 1800 || pItem->id == 1802)	// 5倍经验丹，2倍经验丹,10倍经验丹
	{
		uint8 weekCanUseNum = 24;
		if(GetExtData8(83) >= 4)	// 每天使用次数上限
		{
			SendSysInfo(this,MakeStringColor(LANGUAGE_TRANSFORM_2075,TIPS_FAILURE_COLOR).c_str());
			return NULL;
		}
		if(GetExtData8(84) >= weekCanUseNum)
		{
			SendSysInfo(this,MakeStringColor(LANGUAGE_TRANSFORM_2076,TIPS_FAILURE_COLOR).c_str());
			return NULL;
		}

		if(pItem->id == 1800)	// 2倍
		{
			if(m_useDoubleType != EET_TwoTimes && m_useDoubleType != EET_NoTimes)
			{
				SendSysInfo(this,MakeStringColor(LANGUAGE_TRANSFORM_2077,TIPS_FAILURE_COLOR).c_str());
				return NULL;
			}
		}
		else if(pItem->id == 1801)	// 5倍
		{
			if(m_useDoubleType != EET_FiveTimes && m_useDoubleType != EET_NoTimes)
			{
				SendSysInfo(this,MakeStringColor(LANGUAGE_TRANSFORM_2078,TIPS_FAILURE_COLOR).c_str());
				return NULL;
			}
		}
		else if(pItem->id == 1802)	// 10倍
		{
			if(m_useDoubleType != EET_TenTimes && m_useDoubleType != EET_NoTimes)
			{
				SendSysInfo(this,MakeStringColor(LANGUAGE_TRANSFORM_2079,TIPS_FAILURE_COLOR).c_str());
				return NULL;
			}
		}

		SetExtData8(83,GetExtData8(83)+1);
		SetExtData8(84,GetExtData8(84)+1);

		if(m_userDoubleEnd < GetSysTime())
			m_userDoubleEnd = GetSysTime()+3600;
		else
			m_userDoubleEnd += 3600;
		if(pItem->id == 1800)
			m_useDoubleType = EET_TwoTimes;
		else if(pItem->id == 1801)
			m_useDoubleType = EET_FiveTimes;
		else if(pItem->id == 1802)
			m_useDoubleType = EET_TenTimes;
		NoLockDelPackage(pos);
		Multi_Exp_UpdateActiveTime();
		Multi_Exp_Notice();
	}
	else if(SingletonCFestivalRandomBoxManager::instance().isFestivalRandomBox(pItem->id))
	{
		SingletonCFestivalRandomBoxManager::instance().UseBox(this,pItem->id,pos,num);
	}
	else if( SingletonCXianYuanManager::instance().isCardItemID(pItem->id))
	{
		SingletonCXianYuanManager::instance().XianYuanItemToCard( this,pItem->id,pos ,num);
	}
	else if( SingletonCTransFormManager::instance().IsTransFormCardID(pItem->id))
	{
		UseTransFormCard(pItem->id,pos ,num);
	}
	else
	{
		int dropId = sCDropMatchingMgr.GetItemDropId(pItem->id);
		if (dropId == 0)
		{
			if (pItem->pScript != NULL)
				return pItem->pScript;
			if (pItem->useType == 0 || pItem->subVec.empty())
				return NULL;

			pair<uint16, uint16>& tv = pItem->subVec[0];
			if (tv.first == HDAT_TiLi)
			{
				if (!m_userSpirit.AddSpirit(this, tv.second * num))
				{
					SendSysInfo(this, MakeStringColor(LANGUAGE_ZQX_0216, TIPS_FAILURE_COLOR).c_str());
					return NULL;
				}
			}
			else
			{
				AddMaterial(tv.first, tv.second * num);
			}
		}
		else
		{
			AwardManager& amgr = sAwardManager;
			CItemCfgManager& imgr = sCItemCfgManager;
			MultiAward awards;
			for (int i = 0; i < num; ++i)
			{
				std::vector<SAwardData> award;
				amgr.GetLevelAward(dropId, GetLevel(), award);
				MergeAwardList(awards, award);
				for (uint16 i = 0; i < award.size(); ++i)
				{
					SAwardData& sad = award[i];
					if (sad.type == HDAT_EQUIP)
					{
						CEquipCfg* ecfg = imgr.GetEquipCfg(sad.typeId);
						if (ecfg != NULL && ecfg->quality >= 5)
						{
							char buf[128];
							snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0232, GetName(), GetItemName(pItem->id), MakeColorString(ecfg->quality, ecfg->name).c_str());
							SysInfoToAllUser(buf);
						}
					}
				}
			}
			AddMultiAward(awards, false, true);
		}
		NoLockDelPackage(pos, num);
	}
	return NULL;
}

void CUser::UpdatePackage(uint8 pos)
{
	if(pos >= MAX_PACKAGE_NUM2)
		return;

	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_UPDATE_PACK);
	msg<<(uint8)2;		// update
	MakePack(m_package[pos],pos,msg);
	sock.SendMsg(m_sock,msg);
}

void CUser::StopGuaJi()
{
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_GUAJI);
	msg<<(uint8)3;
	sock.SendMsg(m_sock,msg);
}

void CUser::ClearAskForJoinTeam()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_askForJoinTeam.clear();

	// 成功加入队伍，清空邀请列表
	CNetMessage msg;
	msg.SetType(PRO_USER_TEAM);
	msg<<(uint8)19<<PRO_SUCCESS;
	CSocketServer &sock = SingletonSocket::instance();
	sock.SendMsg(m_sock,msg);
}

void CUser::UseItem(uint8 pos,int *pAddHp,int *pAddMp,uint8 val,uint8 val1,uint8 num)
{
	/*if(m_fightId != 0)
		return;*/
	CCallScript *pScript = NULL;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		pScript = NoLockUseItem(pos,pAddHp,pAddMp,val,val1,num);
	}
	if(pScript != NULL)
	{
		pScript->Call("Main","uii",this,pos,num);
		SetCallScript(pScript->GetScriptId());
	}
}

void CUser::UseItem(uint8 pos, uint8 num, uint8 tar)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	NoLockUseItem(pos, num, tar);
}

void CUser::NoLockUseItem(uint8 pos, uint8 num, uint8 tar)
{
	if (pos >= MAX_PACKAGE_NUM || tar == 0)
		return;
	if (num == 0)
		return;
	SItemInstance *pInst = m_package + pos;
	if (pInst == NULL || pInst->num == 0)
		return;
	if (pInst->num < num)
		num = pInst->num;
	SItemTemplate *pItem = SingletonItemManager::instance().GetItem(pInst->tmplId);
	if (pItem == NULL)
		return;

	if (pItem->type != 6 || pItem->subAward.size() < tar)
		return;
	if (NoLockGetItemNum(pInst->tmplId) < num)
		return;
	SAwardData ad = pItem->subAward[tar - 1];
	ad.num *= num;
	AddMaterial(ad);


	if (ad.type == HDAT_EQUIP)
	{
		CItemCfgManager& mgr = sCItemCfgManager;
		CEquipCfg* cfg = mgr.GetEquipCfg(ad.typeId);
		if (cfg != NULL && cfg->quality >= 5)
		{
			char buf[128];
			snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0232, GetName(), GetItemName(pInst->tmplId), MakeColorString(cfg->quality, cfg->name).c_str());
			SysInfoToAllUser(buf);
		}
	}
	NoLockDelPackage(pos, num);
}

uint8 CUser::GetPetMaxSkillNumByQuality(uint8 petQuality)
{
	uint8 maxSkillNum = 0;
	if(petQuality <= PQT_PURPLE)
		maxSkillNum = 1;
	else if(petQuality <= PQT_ORANGE)
		maxSkillNum = 2;
	else if(petQuality <= PQT_GOLD)
		maxSkillNum = 3;
	else if(petQuality <= PQT_PINK)
		maxSkillNum = 5;
	else if(petQuality <= PQT_RED)
		maxSkillNum = 7;
	else
		maxSkillNum = 7;
	maxSkillNum++;
	return maxSkillNum;
}

bool CUser::PetCanLearnSkillBook(SPet *pPet,int skillId,uint8 skillPos)	// 更加神将类型判定是否可学特定技能
{
	if(pPet == NULL)
		return false;
	if(skillPos < 1 || skillPos >= (uint8)PET_MAX_SKILL_NUM)	// 第0个技能为天生技能
		return false;
	if(pPet->skill[skillPos] >= 170)
	{
		if(pPet->skill[skillPos] == skillId)
			return false;
	}
	else if(pPet->skill[skillPos] > 0)	// 非正常技能id
		return false;

	// 无技能或与相应位置上的技能类型不同
	for(uint8 idx=1;idx < (uint8)PET_MAX_SKILL_NUM;idx++)
	{
		if(idx == skillPos)
			continue;
		if(pPet->skill[idx] == 0)
			continue;
		if(pPet->skill[idx] >= 170)
		{
			if(pPet->skill[idx] == skillId)
				return false;
		}
	}
	return true;

/*
	if(pPet == NULL)
		return false;
	int canLearnFlag = true;
	const uint8 notLearnSkill_T1[] = {60,61,62,104,105,63,64,57};
	const uint8 notLearnSkill_T2[] = {60,61,62,104,105,63,64,57};
	const uint8 notLearnSkill_T3[] = {104,105,63,64,57};
	const uint8 notLearnSkill_T4[] = {60,61,62,104,105,57};
	const uint8 notLearnSkill_T5[] = {60,61,62,63,64};
	uint8 listSize = 0;
	const uint8 *pNotLearnSkill = NULL;
	if(petType == 1)	// 物攻
	{
		pNotLearnSkill = notLearnSkill_T1;
		listSize = sizeof(notLearnSkill_T1)/sizeof(notLearnSkill_T1[0]);
	}
	else if(petType == 2)	// 法攻
	{
		pNotLearnSkill = notLearnSkill_T2;
		listSize = sizeof(notLearnSkill_T2)/sizeof(notLearnSkill_T2[0]);
	}
	else if(petType == 3)	// 防御神将
	{
		pNotLearnSkill = notLearnSkill_T3;
		listSize = sizeof(notLearnSkill_T3)/sizeof(notLearnSkill_T3[0]);
	}
	else if(petType == 4)	// 气血神将
	{
		pNotLearnSkill = notLearnSkill_T4;
		listSize = sizeof(notLearnSkill_T4)/sizeof(notLearnSkill_T4[0]);
	}
	else if(petType == 5)	// 速度神将
	{
		pNotLearnSkill = notLearnSkill_T5;
		listSize = sizeof(notLearnSkill_T5)/sizeof(notLearnSkill_T5[0]);
	}
	else
		return false;

	for(uint8 i=0;i < listSize;i++)
	{
		if(skillId == pNotLearnSkill[i])
		{
			canLearnFlag = false;
			break;
		}
	}
	if(!canLearnFlag)
	{
		CNetMessage msg;
		msg.ReWrite();
		msg.SetType(MSG_SERVER_USE_RESULT);
		msg<<(uint8)1<<PRO_ERROR;
		switch(skillId)
		{
			case 57:
				msg<<LANGUAGE_TRANSFORM_2094;
				break;
			case 60:
				msg<<LANGUAGE_TRANSFORM_2095;
				break;
			case 61:
				msg<<LANGUAGE_TRANSFORM_2096;
				break;
			case 62:
				msg<<LANGUAGE_TRANSFORM_2097;
				break;
			case 63:
				msg<<LANGUAGE_TRANSFORM_2098;
				break;
			case 64:
				msg<<LANGUAGE_TRANSFORM_2099;
				break;
			case 104:
				msg<<LANGUAGE_TRANSFORM_2100;
				break;
			case 105:
				msg<<LANGUAGE_TRANSFORM_2101;
				break;
			default:
				return false;
		}
		CSocketServer &sock = SingletonSocket::instance();
		sock.SendMsg(m_sock,msg);
		return false;
	}
	return true;
*/
}

bool CUser::UseItemToPet(uint16 petId,uint8 itemPos,int *pAddHp,int *pAddMp,int val)
{
	if(m_fightId != 0)
		return false;

	//{
	//	boost::recursive_mutex::scoped_lock lk(m_mutex);
	//	SItemInstance *pInst = GetItem(itemPos);
	//	if(pInst == NULL)
	//		return false;
	//	SItemTemplate *pItem = SingletonItemManager::instance().GetItem(pInst->tmplId);
	//	if(pItem == NULL)
	//		return false;
	//	SPet *pPet = NoLockGetPet(petId).get();
	//	if(pPet == NULL)
	//		return false;

	//	if(pItem->type == EIT_PetBook)	//神将天书,无该技能
	//	{
	//		int skillPos = val; // 位置
	//		int maxSkillNum = 1;
	//		if(skillPos < 4 || skillPos >= maxSkillNum)
	//		{
	//			CNetMessage msg;
	//			msg.SetType(MSG_SERVER_USE_RESULT);
	//			if(skillPos < 4)
	//				msg<<(uint8)1<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2103,TIPS_FAILURE_COLOR);
	//			else
	//				msg<<(uint8)1<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2104,TIPS_FAILURE_COLOR);
	//			CSocketServer &sock = SingletonSocket::instance();
	//			sock.SendMsg(m_sock,msg);
	//			return false;
	//		}
	//		if(m_level < 52)
	//		{
	//			CNetMessage msg;
	//			msg.SetType(MSG_SERVER_USE_RESULT);
	//			msg<<(uint8)1<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2105,TIPS_FAILURE_COLOR);
	//			CSocketServer &sock = SingletonSocket::instance();
	//			sock.SendMsg(m_sock,msg);
	//			return false;
	//		}

	//		int OtherSkills[] = {912,189,915,192,918,195,921,198,924,201,927,204,930,207,936,213,948,225,951,228,957,234,564,170,565,171,566,172,567,173,597,236,598,237,599,238};
	//		int skillId = 0;
	//		uint32 i = 0;
	//		for(i = 0; i < sizeof(OtherSkills)/sizeof(OtherSkills[0]); i += 2)
	//		{
	//			if(pItem->id == OtherSkills[i])
	//			{
	//				skillId = OtherSkills[i+1];
	//				break;
	//			}
	//		}
	//		if(skillId == 0)
	//			return false;
	//		if(!PetCanLearnSkillBook(pPet,skillId,skillPos))	// 神将是否可学该天书
	//		{
	//			CNetMessage msg;
	//			msg.SetType(MSG_SERVER_USE_RESULT);
	//			msg<<(uint8)1<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2106,TIPS_FAILURE_COLOR);
	//			CSocketServer &sock = SingletonSocket::instance();
	//			sock.SendMsg(m_sock,msg);
	//			return false;
	//		}
	//	}
	//}
	UpdatePet(petId);
	return true;
}

int CUser::GetPetNextLevelZhanDouLi(uint16 petId)
{
	SPet *tarPet = GetPet(petId).get();
	if(tarPet == NULL)
		return -1;

	SPet tPet = *tarPet;
	tPet.level++;
	tPet.Init(this);
	return tPet.GetZhanDouLi();
}

bool CUser::PetXiuLianLevelUp(uint16 petId,uint8 xiulianIdx,CNetMessage &msg)
{
	if(petId == 0 || xiulianIdx == 0 || xiulianIdx > PET_XIU_LIAN_MAX_NUM)
		return false;

	// CPetCfgManager &petMgr = SingletonCPetCfgMgr::instance();
	// {
		// boost::recursive_mutex::scoped_lock lk(m_mutex);
		// SPet *pPet = NoLockGetPet(petId).get();
		// if(pPet == NULL)
		// {
			// msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0424,TIPS_FAILURE_COLOR);
			// return true;
		// }
		
		// int xiulianLv = pPet->xueMaiLevel[xiulianIdx-1];
		// SPetXiuLianData *pXLCfg = petMgr.GetXiuLianCfg(pPet->quality,xiulianLv);
		// if(pXLCfg == NULL)
		// {
			// msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0416,TIPS_FAILURE_COLOR);
			// return true;
		// }
		// SPetXiuLianAttr &attr = pXLCfg->xiulianData[xiulianIdx-1];
		// if(attr.level_limit == 0)
		// {
			// msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0435,TIPS_FAILURE_COLOR);
			// return true;
		// }
		// if(pPet->level < attr.level_limit)
		// {
			// msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0436,TIPS_FAILURE_COLOR);
			// return true;
		// }
		// // 消耗
		// if(!pXLCfg->cost.empty())
		// {
			// vector<SCostData> &cost = pXLCfg->cost;
			// for(uint16 i=0;i < cost.size();i++)
			// {
				// if(cost[i].costType < HDAT_MONEY)
				// {
					// if(NoLockGetItemNum(cost[i].costType) < cost[i].costValue)
					// {
						// msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0425,TIPS_FAILURE_COLOR);
						// return true;
					// }
				// }
			// }
			// for(uint16 i=0;i < cost.size();i++)
			// {
				// if(cost[i].costType < HDAT_MONEY)
				// {
					// NoLockDelPackageById(cost[i].costType,cost[i].costValue);
					// pPet->AddCost(SPet::PCT_Xiulian, cost[i].costType, cost[i].costValue);
				// }
			// }
		// }
		// pPet->xueMaiLevel[xiulianIdx-1]++;
		// pPet->Init(this);
		// msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_SSJ_0437,TIPS_SUCCESS_COLOR);

		// // =========================
		// // 更新神将修炼任务
		// int lv = pPet->xueMaiLevel[xiulianIdx-1];
		// SingletonCMissionManager::instance().VerifyNewBranchMissionFinish(this,EMISS_DC_23,1,lv); // TODO
		// SingletonCMissionManager::instance().VerifyNewBranchMissionFinish(this, EMISS_DC_63);
	// }
	// UpdatePet(petId);
	// SendUpdateInfo(EUUT_TotalZhanDouLi);

	// if(!HaveBitSet(360))	// 修炼完成标记
		// SetBitSet(360);
	return true;
}

bool CUser::PetForgetSkill(uint16 petId,uint8 skillPos,CNetMessage &msg)
{
	if(skillPos < PET_BORN_SKILL_NUM || skillPos >= PET_MAX_SKILL_NUM)
		return false;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		SPet *pPet = NoLockGetPet(petId).get();
		if(pPet== NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0424,TIPS_FAILURE_COLOR);
			return true;
		}
		uint16 skillId = 0;
		uint16 skillLevel = 0;
		pPet->GetSkillInfoByPos(skillPos,skillId,skillLevel);
		if(skillId == 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0453,TIPS_FAILURE_COLOR);
			return true;
		}
		pPet->ForgetSkill(skillPos);

		msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_SSJ_0454,TIPS_SUCCESS_COLOR);
		pPet->Init(this);
	}

	UpdatePet(petId);
	SendUpdateInfo(EUUT_TotalZhanDouLi);
	return true;
}

bool CUser::MakeZhenFaMsg(CNetMessage &msg)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(m_zhenfa.empty())
		return false;
	
	uint8 num = m_zhenfa.size();
	if(m_useZhenFaIdx >= num)
		m_useZhenFaIdx = 0;
	msg<<m_zhenfa[m_useZhenFaIdx].zhenfaId;
	msg<<num;
	for(uint8 i=0;i < num;i++)
	{
		msg<<m_zhenfa[i].zhenfaId<<m_zhenfa[i].zhenfaLevel;
	}
	num = m_chuzhan.size();
	msg << num;
	for (uint8 i = 0; i < num; i++)
	{
		msg << m_chuzhan[i];
	}
	msg << num;
	num = m_zhenfaMember.size();
	for (uint8 i = 0; i < num; i++)
	{
		msg << (uint16)m_zhenfaMember[i].mem_id;
	}
	return true;
}

bool CUser::ZhenFaLevelUp(uint16 zhenfaId,CNetMessage &msg)
{
	if(zhenfaId == 0)
		return false;
	CZhenFaCfgMgr &zhenfaMgr = SingletonCZhenFaCfgMgr::instance();
	SZhenFaBasicCfg *pBasicCfg = zhenfaMgr.GetBasicCfg(zhenfaId);
	if(pBasicCfg == NULL)
		return false;

	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		uint8 idx = 0xff;
		for(uint8 i=0;i < m_zhenfa.size();i++)
		{
			if(m_zhenfa[i].zhenfaId == zhenfaId)
			{
				idx = i;
				break;
			}
		}
		bool islearn = (idx == 0xff) ? true : false;
		uint8 level = islearn ? 0 : m_zhenfa[idx].zhenfaLevel;
		SZhenFaLevelUpData *pUpCfg = zhenfaMgr.GetLevelUpCfg(zhenfaId,level);
		if(pUpCfg == NULL || pUpCfg->costs.empty())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0438,TIPS_FAILURE_COLOR);
			return true;
		}
		if(!DelCostMaterial(pUpCfg->costs))
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0425,TIPS_FAILURE_COLOR);
			return true;
		}

		if(islearn)
		{
			SZhenFaData data;
			data.zhenfaId = zhenfaId;
			data.zhenfaLevel = 1;
			m_zhenfa.push_back(data);
			msg<<PRO_SUCCESS<<data.zhenfaLevel<<MakeStringColor(LANGUAGE_SSJ_0439,TIPS_SUCCESS_COLOR);
		}
		else
		{
			m_zhenfa[idx].zhenfaLevel++;
			msg<<PRO_SUCCESS<<m_zhenfa[idx].zhenfaLevel<<MakeStringColor(LANGUAGE_SSJ_0440,TIPS_SUCCESS_COLOR);
		}

		SingletonCMissionManager::instance().UpdateDCMissionComplate(this, EMISS_DC_71);
	}

	SendUpdateInfo(EUUT_TotalZhanDouLi);
	return true;
}

bool CUser::SwitchZhenFa(uint16 zhenfaId,CNetMessage &msg)
{
	if(zhenfaId == 0)
		return false;
	CZhenFaCfgMgr &zhenfaMgr = SingletonCZhenFaCfgMgr::instance();
	SZhenFaBasicCfg *pBasicCfg = zhenfaMgr.GetBasicCfg(zhenfaId);
	if(pBasicCfg == NULL)
		return false;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	uint8 tarIdx = 0xff;
	for(uint8 i=0;i < m_zhenfa.size();i++)
	{
		if(m_zhenfa[i].zhenfaId == zhenfaId)
		{
			tarIdx = i;
			break;
		}
	}
	if(tarIdx == 0xff)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0441,TIPS_SUCCESS_COLOR);
		return true;
	}
	if(m_useZhenFaIdx == tarIdx)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0442,TIPS_SUCCESS_COLOR);
		return true;
	}
	m_useZhenFaIdx = tarIdx;
	msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_SSJ_0443,TIPS_SUCCESS_COLOR);

	// 新阵法初始化数据
	for(uint8 i=0;i < m_zhenfaMember.size();i++)
	{
		m_zhenfaMember[i].fightPos = pBasicCfg->fightPos[i];
	}
	return true;
}

void CUser::GetUseZhenFa(SZhenFaData &data)
{
	data.Clear();
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(m_useZhenFaIdx >= m_zhenfa.size())
		return;
	data = m_zhenfa[m_useZhenFaIdx];
}

void CUser::GetZhenFaMember(vector<SZhenFaMemData> &zhenfaMembers)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	zhenfaMembers = m_zhenfaMember;
}

bool CUser::ZhenFa_SetPetState(uint16 petId,uint8 pos,bool synPower)
{
	if(petId == 0 || pos == 0 || pos > m_zhenfaMember.size())
		return false;

	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_ZHEN_FA);
	msg<<(uint8)4<<petId<< pos;

	uint64 power = 0;
	uint16 otherPetId = 0;
	uint64 otherPower = 0;
	bool otherCZFlag = true;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		SharePetPtr pet = NoLockGetPet(petId);
		SPet *pPet = pet.get();
		if(pPet == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0424,TIPS_FAILURE_COLOR);
			sock.SendMsg(m_sock,msg);
			return true;
		}

/*
		// 异常处理
		if(m_zhenfa.empty())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0446,TIPS_FAILURE_COLOR);
			return true;
		}
		if(m_useZhenFaIdx >= m_zhenfa.size())
			m_useZhenFaIdx = 0;
		SZhenFaBasicCfg *pBasicCfg = SingletonCZhenFaCfgMgr::instance().GetBasicCfg(m_zhenfa[m_useZhenFaIdx].zhenfaId);
		if(pBasicCfg == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0447,TIPS_FAILURE_COLOR);
			return true;
		}
*/

		uint16 lpetId = m_chuzhan[pos - 1];
		uint8 lposA = pos;
		uint8 lposA1 = GetPetZhenFaIdx(lpetId);

		uint16 rpetId = petId;
		uint8 rposA = GetChuZhanIdx(rpetId);
		uint8 rposA1 = GetPetZhenFaIdx(rpetId);

		if (lpetId == rpetId) return true;
/*		if (rposA > 0 && lpetId == 0)
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0224, TIPS_FAILURE_COLOR);
			sock.SendMsg(m_sock, msg);
			return true;
		}
*/
		m_chuzhan[lposA - 1] = rpetId;
		if(lposA1 == 0)
		{
			for(uint8 i=0;i < m_zhenfaMember.size(); i++)
			{
				if(m_zhenfaMember[i].mem_type == EZFMT_NONE)
				{
					m_zhenfaMember[i].mem_type = EZFMT_PET;
					m_zhenfaMember[i].mem_id = rpetId;
					break;
				}
			}
		}
		else
		{
			m_zhenfaMember[lposA1 - 1].mem_type = EZFMT_PET;
			m_zhenfaMember[lposA1 - 1].mem_id = rpetId;
		}
		pPet->chuzhanFlag = 1;
		pPet->Init(this);
		power = pPet->GetZhanDouLi();

		if (rposA > 0)
		{
			if(lpetId > 0)
			{
				m_chuzhan[rposA - 1] = lpetId;
				m_zhenfaMember[rposA1 - 1].mem_type = EZFMT_PET;
				m_zhenfaMember[rposA1 - 1].mem_id = lpetId;
			}
			else
			{
				m_chuzhan[rposA - 1] = 0;
				m_zhenfaMember[rposA1 - 1].mem_type = EZFMT_NONE;
				m_zhenfaMember[rposA1 - 1].mem_id = 0;
			}
		}
		if(lpetId > 0)
		{
			otherPetId = lpetId;
			SharePetPtr lpet = NoLockGetPet(lpetId);
			SPet *plPet = lpet.get();
			if(plPet != NULL)
			{
				if(rposA == 0)
				{
					pPet->chuzhanFlag = 0;
					otherCZFlag = false;
				}
				plPet->Init(this);
				otherPower = plPet->GetZhanDouLi();
			}
		}

		msg << PRO_SUCCESS << MakeStringColor(LANGUAGE_SSJ_0450, TIPS_SUCCESS_COLOR);
		sock.SendMsg(m_sock,msg);
		sCMissionManager.UpdateQuestState(this, EMQCT_41);
	}
	TrapShangZhenMsg();
	UpdatePet(petId);
	UpdatePet(otherPetId);
	ResetPower();
	if (synPower)
		SendUpdateInfo(EUUT_TotalZhanDouLi);

	SingletonCRankMgr::instance().UpdateData(CRankMgr::ERT_Pet, m_roleId, power, 0, petId);
	if(otherPetId > 0)
	{
		if(otherCZFlag)
			SingletonCRankMgr::instance().UpdateData(CRankMgr::ERT_Pet, m_roleId, otherPower, 0, otherPetId);
		else
			SingletonCRankMgr::instance().RemoveRankByValue(CRankMgr::ERT_Pet, m_roleId, otherPetId);
	}
	return true;
}

void CUser::TrapShangZhenMsg()
{
	CNetMessage trap;
	trap.SetType(PRO_ZHEN_FA);
	trap << (uint8)1;
	MakeZhenFaMsg(trap);
	SingletonSocket::instance().SendMsg(m_sock, trap);
}

bool CUser::ZhenFa_ChangeUnitPos(uint8 srcPos,uint8 tarPos,bool synTeam)
{
	if(srcPos == 0 || tarPos == 0 || srcPos == tarPos || srcPos > ZHEN_FA_POS_NUM || tarPos > ZHEN_FA_POS_NUM)
		return false;

	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_ZHEN_FA);
	msg<<(uint8)5<<srcPos<<tarPos;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
//		if(m_zhenfaMember[srcPos-1].mem_type == EZFMT_NONE)
//		{
//			return false;
//		}
		if(m_zhenfa.empty() || m_useZhenFaIdx >= m_zhenfa.size())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0446,TIPS_FAILURE_COLOR);
			sock.SendMsg(m_sock,msg);
			return true;
		}
		
		SZhenFaBasicCfg *pBasicCfg = SingletonCZhenFaCfgMgr::instance().GetBasicCfg(m_zhenfa[m_useZhenFaIdx].zhenfaId);
		if(pBasicCfg == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0447,TIPS_FAILURE_COLOR);
			sock.SendMsg(m_sock,msg);
			return true;
		}
		if(m_level < pBasicCfg->open_level[srcPos-1] || m_level < pBasicCfg->open_level[tarPos-1])
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0449,TIPS_FAILURE_COLOR);
			sock.SendMsg(m_sock,msg);
			return true;
		}

		SZhenFaMemData t;
		t = m_zhenfaMember[srcPos-1];
		m_zhenfaMember[srcPos-1].mem_type = m_zhenfaMember[tarPos-1].mem_type;
		m_zhenfaMember[srcPos-1].mem_id = m_zhenfaMember[tarPos-1].mem_id;
		m_zhenfaMember[tarPos - 1].mem_type = t.mem_type;
		m_zhenfaMember[tarPos-1].mem_id = t.mem_id;
	}
	msg<<PRO_SUCCESS;
	sock.SendMsg(m_sock,msg);
	sCMissionManager.UpdateQuestState(this, EMQCT_41);

	//TrapShangZhenMsg();
	return true;
}

void CUser::PetXueMai(uint16 petId,uint8 xueMaiIdx,CNetMessage &msg)
{
	// if(m_level < 36)
	// {
		// msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2131,TIPS_FAILURE_COLOR);
		// SingletonSocket::instance().SendMsg(m_sock,msg);
		// return;
	// }

	// boost::recursive_mutex::scoped_lock lk(m_mutex);
	// if(petId == 0 || (int)xueMaiIdx > PET_XUEMAI_MAX_NUM-1)
	// {
		// msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2132,TIPS_FAILURE_COLOR);
		// SingletonSocket::instance().SendMsg(m_sock,msg);
		// return;
	// }
	
	// char buf[256];
	// SPet *pPet = NoLockGetPet(petId).get();
	// if(pPet == NULL)
		// return;
// //	if(xueMaiIdx == SPet::MAX_XUE_MAI_NUM-1 && pPet->skill[3] == 0)	// 觉醒神将开启
// //		return;
	// if(pPet->quality < PQT_PURPLE)
	// {
		// msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2133,TIPS_FAILURE_COLOR);
		// SingletonSocket::instance().SendMsg(m_sock,msg);
		// return;
	// }
	// if((int)xueMaiIdx == PET_XUEMAI_MAX_NUM-1)
		// return;
	// if((int)(pPet->quality - PQT_PURPLE) < (int)xueMaiIdx)
	// {
		// snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_2134,QualityColorName[xueMaiIdx+PQT_PURPLE].c_str());
		// msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
		// SingletonSocket::instance().SendMsg(m_sock,msg);
		// return;
	// }
// //	if(pPet->xueMaiLevel[xueMaiIdx] >= SPet::MAX_XUE_MAI_LEVEL)
// //	{
// //		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2135,TIPS_FAILURE_COLOR);
// //		SingletonSocket::instance().SendMsg(m_sock,msg);
// //		return;
// //	}

	// uint8 nextXMLv = 0,nextXMExp = 0,xmExp = 0;
	// int item1 = 0,itemNum1 = 0;
	// int item2 = 0,itemNum2 = 0;
	// pPet->GetXueMaiLevelUpItem(pPet->xueMaiLevel[xueMaiIdx],xmExp,nextXMLv,nextXMExp,item1,itemNum1,item2,itemNum2);
	// if(nextXMLv == 0 || item1 == 0 || itemNum1 == 0 || item2 == 0 || itemNum2 == 0)
		// return;
	// int money = 250*itemNum1;
	// if(money > 90000)
		// money = 90000;
	// if(GetItemNum(item2) < itemNum2)	// 魄石
	// {
		// snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_2136,GetItemName(item2));
		// msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
		// SingletonSocket::instance().SendMsg(m_sock,msg);
		// return;
	// }
	// if(GetItemNum(item1) < itemNum1)	// 灵石
	// {
		// snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_2137,GetItemName(item1));
		// msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
		// SingletonSocket::instance().SendMsg(m_sock,msg);
		// return;
	// }
	// if(GetMoney() < money)
	// {
		// snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_2138);
		// msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
		// SingletonSocket::instance().SendMsg(m_sock,msg);
		// return;
	// }
	// NoLockDelPackageById(item1,itemNum1);
	// NoLockDelPackageById(item2,itemNum2);
	// AddMoney(-money);
	// msg<<PRO_SUCCESS;

	// // uint8 srcLv = pPet->xueMaiLevel[xueMaiIdx];
	// uint8 srcLv = 0;
	// uint8 srcExp = 0;	//pPet->xueMaiExp[xueMaiIdx];
	// int Attack=0,Recovery=0,Speed=0,MaxHp=0;
	// pPet->GetXueMaiAddVal(xueMaiIdx,srcLv,srcExp,Attack,Recovery,MaxHp,Speed);
	// msg<<srcLv<<srcExp<<Attack<<Recovery<<MaxHp<<Speed;
	// // 血脉觉醒
	// // pPet->xueMaiLevel[xueMaiIdx] = nextXMLv;
// //	pPet->xueMaiExp[xueMaiIdx] = nextXMExp;
	// pPet->Init(this);
	// pPet->GetXueMaiAddVal(xueMaiIdx,nextXMLv,nextXMExp,Attack,Recovery,MaxHp,Speed);
	// msg<<nextXMLv<<nextXMExp<<Attack<<Recovery<<MaxHp<<Speed;

	// NoLockUpdatePet(petId);
	// SingletonSocket::instance().SendMsg(m_sock,msg);
	// if(srcLv != nextXMLv && nextXMLv >= 4)
	// {
		// const char *NAME[] = {LANGUAGE_TRANSFORM_2139,LANGUAGE_TRANSFORM_2140,LANGUAGE_TRANSFORM_2141,LANGUAGE_TRANSFORM_2142};
		// snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_2143,ROLE_NAME_COLOR,GetName(),
			// PetQualityColor[pPet->quality],GetPetName(pPet->id),GGCT_BLUE,NAME[xueMaiIdx],(int)nextXMLv);
		// SysInfoToAllUser(buf,true);
	// }

	// if(!HaveBitSet(360))
		// SetBitSet(360);
	// if(!HaveBitSet(501))
	// {
		// const char *pMission501 = GetMission(501);
		// if(pMission501 != NULL)
		// {
			// if(atoi(pMission501) == 0)
				// UpdateMission(501,"2");
		// }
	// }

}

bool CUser::PetLevelUp(uint16 petId,uint16 costItemId,uint8 costItemNum,CNetMessage &msg)
{
	if(petId == 0 || costItemId == 0 || costItemNum == 0)
		return false;
	if(GetItemNum(costItemId) < (int)costItemNum)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0425,TIPS_FAILURE_COLOR);
		return true;
	}
	
	SItemTemplate *pItem = SingletonItemManager::instance().GetItem(costItemId);
	if(pItem == NULL)
		return false;

	bool isLevelUp = false;
	bool updatePower = false;
	SPet *pPet = NULL;
	CPetCfgManager &petMgr = SingletonCPetCfgMgr::instance();
 	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		pPet = NoLockGetPet(petId).get();
		if(pPet == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0424,TIPS_FAILURE_COLOR);
			return true;
		}
		if(pPet->level >= m_level)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0426,TIPS_FAILURE_COLOR);
			return true;
		}
		DelPackageById(costItemId,costItemNum);
//		SaveUseItem(m_roleId,costItemId,LANGUAGE_SSJ_0427,costItemNum);
		
		uint32 addexp = pItem->subValue * costItemNum;
		pPet->exp += addexp;
		uint32 levelUpExp = petMgr.GetLevelUpExp(pPet->level);
		while(pPet->exp >= levelUpExp)
		{
			pPet->exp -= levelUpExp;
			pPet->level++;
			levelUpExp = petMgr.GetLevelUpExp(pPet->level);
			isLevelUp = true;
		}
		if(isLevelUp)
		{
			pPet->Init(this);
			char buf[256];
			snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0428,PetQualityColor[pPet->quality],pPet->name.c_str(),GGCT_GREEN,pPet->level);
			SendSysInfo(this,buf);

			if (pPet->chuzhanFlag == 1)
			{
				updatePower = true;
			}
		}
 		msg<<PRO_SUCCESS;
	}
	UpdatePet(petId);
	if(updatePower)
		SendUpdateInfo(EUUT_TotalZhanDouLi);
	
	if(isLevelUp)
		SingletonCMissionManager::instance().VerifyNewBranchMissionFinish(this, EMISS_DC_21, 1, pPet->level);
	if(pPet->chuzhanFlag == 1)
	{
		if(GetTeam() > 0 && GetTeam() == GetRoleId())
		{
			if(m_pScene != NULL)
				m_pScene->UpdateTeamData(GetTeam());
		}
	}

	// =============================
	// 更新神将升级任务
	// 参数: 任务id  数量 等级
//	cout<<"call VerifyNewBranchMissionFinish mid = 208 , level = "<<pPet->level<<", pet id = "<<petId<<endl;

//heckFBLevel();
	return true;
}

bool CUser::AllPetLevelUpToMax()
{
	list<uint16> levelUpPetId;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		for(CPetMapIt it=m_pet.begin();it != m_pet.end();it++)
		{
			SPet *pPet = it->second.get();
			if(pPet != NULL && pPet->level < m_level)
			{
				pPet->level = m_level;
				pPet->Init(this);
				levelUpPetId.push_back(pPet->id);
			}
		}
	}
	for(list<uint16>::iterator i = levelUpPetId.begin(); i != levelUpPetId.end(); i++)
	{
		UpdatePet(*i);
	}
	if(levelUpPetId.size() > 0)
		return true;
	else
		return false;
}

void CUser::InitAllPet()
{
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		for(CPetMapIt it=m_pet.begin();it != m_pet.end();it++)
		{
			SPet *pPet = it->second.get();
			if(pPet != NULL)
				pPet->Init(this);
		}
	}
	UpdateAllPetInfo();
}

void CUser::RecoveryAllPetHp()
{
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		for(CPetMapIt it=m_pet.begin();it != m_pet.end();it++)
		{
			SPet *pPet = it->second.get();
			if(pPet != NULL)
				pPet->hp = pPet->basicAttr.maxHp;
		}
	}
//	UpdateAllPetInfo(EUUT_HP);
}


uint8 CUser::GetFightMaxSpeedLevel()
{
	if(m_level >= 22)
	{
		if(GetMonthCard() > 0)
			return 3;
		else
			return 2;
	}
	else
		return 1;
}

// 洗神将功能
bool CUser::ResetPet(uint8 petPos)
{
	return false;
}

// 记录进入部分信息
void CUser::SaveEnter2FuBen(int fuBenIdx)
{
	if(m_pScene == NULL)
		return;

	uint32 members[MAX_TEAM_MEMBER];
	uint8 num = m_pScene->GetTeamMem(m_teamId,members);
	if (num == 0) // 没有队伍
	{
		SaveEnter2FuBen(this,fuBenIdx);
	}
	else // 组队
	{
		COnlineUser &m_onlineUser = SingletonOnlineUser::instance();
		for(uint8 i = 0; i < num; i++)
		{
			ShareUserPtr ptr = m_onlineUser.GetUserByRoleId(members[i]);
			CUser *pUser = ptr.get();
			SaveEnter2FuBen(pUser,fuBenIdx);
			if (pUser != NULL)
				pUser->SetBitSet(167); // 每日活跃度 组队副本
		}
	}
}

// 记录进入部分信息
void CUser::SaveEnter2FuBen(CUser *pUser, int fuBenIdx)
{
	if(pUser == NULL)
		return;
	//cout << "保存副本进入信息：" << pUser->GetName() << ",idx:" << fuBenIdx << endl;
	pUser->SetExtData8((8+fuBenIdx),pUser->GetExtData8(8+fuBenIdx)+1);
	pUser->SaveEnterPos(pUser->GetSceneId(),pUser->GetX(),pUser->GetY()); // 进入副本位置信息保存
	pUser->SetExtData8(14,pUser->GetExtData8(14)+1); // 每日活跃度 通关副本次数
}

// 退出副本
void CUser::ExitFuBen(int loadingType)
{
	if(m_fightId > 0)
		return;
	if ((GetTeam() != 0) && (GetTeam() != GetRoleId())) // 组队不是队长
	{
		// 退出队伍
		m_pScene->LeaveTeam(this);
		//cout << "组队 不是队长 退出副本" << endl;
	}
//	int sceneId = 0;
//	if (m_pScene != NULL)
//		sceneId = m_pScene->GetSrcSceneId();

	//cout << "退出副本：" << sceneId << endl;
	int sId = EXIT_FB_SCENE_ID, pX = EXIT_FB_SCENE_X, pY = EXIT_FB_SCENE_Y;
	GetEnterPos(sId,pX,pY);
	CSceneManager &sceneMgr = SingletonSceneManager::instance();
	CScene *pNxt = sceneMgr.FindScene(sId);
	if (pNxt == NULL)
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_JUMP_SCENE);
	msg<<(uint16)sId<<(uint16)pX<<(uint16)pY<<(uint8)0<<(uint8)loadingType;
	sock.SendMsg(m_sock,msg);
	SetPos(pX,pY);
	SetFace(0);
	EnterScene(pNxt);
}

// 记录进入信息
void CUser::RiChangFuBenSaveEnter(int fuBenId)
{
	SaveEnterPos(GetSceneId(),GetX(),GetY()); // 进入副本位置信息保存
	SetExtData8(14,GetExtData8(14)+1); // 每日活跃度 通关副本次数
}

void CUser::DelPet(uint16 petId,bool sendMsg)
{
	if(petId == 0)
		return;
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	SaveDelPet(m_roleId,NoLockGetPet(petId).get());
	NoLockDelPet(petId,sendMsg);
}

bool CUser::DelPetWithNoLock(uint16 petId)
{
	if(petId == 0)
		return false;
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	SaveDelPet(m_roleId,NoLockGetPet(petId).get());
	NoLockDelPet(petId);
	return true;
}

void CUser::NoLockDelPet(uint16 petId,bool sendMsg)
{
	if(petId == 0)
		return;
	// if(m_gensuiPet == petId)
		// m_gensuiPet = 0;
	for(uint8 i=0;i < m_zhenfaMember.size();i++)
	{
		if(m_zhenfaMember[i].mem_type == EZFMT_PET && m_zhenfaMember[i].mem_id == petId)
		{
			m_zhenfaMember[i].mem_type = EZFMT_NONE;
			m_zhenfaMember[i].mem_id = 0;
		}
	}

	if(sendMsg)
	{
		CSocketServer &sock = SingletonSocket::instance();
		CNetMessage msg;
		msg.SetType(PRO_UPDATE_PET);
		msg<<(uint8)0<<petId;
		sock.SendMsg(m_sock,msg);
	}

	CPetMapIt it = m_pet.find(petId);
	if(it == m_pet.end())
		return;
	m_pet.erase(it);
}

void CUser::UpdatePet(uint16 petId)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	NoLockUpdatePet(petId);
}

void CUser::NoLockUpdatePet(uint16 petId)
{
	if(petId == 0)
		return;

	SharePetPtr pet = NoLockGetPet(petId);
	if(pet.get() == NULL)
		return;
	CNetMessage msg;
	msg.SetType(PRO_UPDATE_PET);
	msg<<(uint8)2;
	MakePetData(pet.get(),msg);
	SingletonSocket::instance().SendMsg(m_sock,msg);
}

int CUser::GetPetZhanDouLi()
{
	int totalZhanDouLi = 0;
	vector<SharePetPtr> petList;
	GetChuZhanPetList(petList);
	for (vector<SharePetPtr>::iterator it = petList.begin(); it != petList.end(); ++it)
	{
		if((*it).get() != NULL)
			totalZhanDouLi += (*it)->zhanDouli;
	}
	return totalZhanDouLi;
}

void CUser::GetChuZhanPetList(vector<SharePetPtr> &petList)
{
	petList.clear();
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint8 i=0;i < m_zhenfaMember.size();i++)
	{
		if(m_zhenfaMember[i].mem_type == EZFMT_PET)
		{
			uint16 petId = m_zhenfaMember[i].mem_id;
			if(petId > 0)
			{
				SharePetPtr pet = NoLockGetPet(petId);
				if(pet.get() != NULL && pet->chuzhanFlag == 1)
				{
					petList.push_back(pet);
					continue;
				}
			}
		}
	}
}

void CUser::GetQXChuZhanPetList(vector<SharePetPtr> &petList)
{
	petList.clear();
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint8 i=0;i < MAX_CHU_ZHAN_NUM;i++)
	{
		uint16 petId = m_qx_chuzhan[i];
		if(petId > 0)
		{
			SharePetPtr pet = NoLockGetPet(petId);
			if(pet.get() != NULL)
			{
				petList.push_back(pet);
				continue;
			}
		}
//		SharePetPtr temp;
//		petList.push_back(temp);
//		petPosList.push_back(0xff);
	}
}

bool CUser::IsQXPetDie(uint8 pos)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint8 i=0;i < MAX_QX_PET_NUM;i++)
	{
		if(pos == m_qx_petlist[i])
		{
			if((m_qx_dieFlag & (1<<i)) > 0)
				return true;
			else
				return false;
		}
	}
	return true;
}

bool CUser::AcceptCMission(int id,const char *pInts,const char *pStrs)
{
	if(id == 0 || pInts == NULL || pStrs == NULL)
		return false;

	vector<int> var;
	vector<string> str;
	GetCMissionPara(var,str,pInts,pStrs);
	
	CMissionManager &mgr = SingletonCMissionManager::instance();
	SMissionConfig *pCfg = mgr.GetMissionCfg(id);
	if(pCfg == NULL){
		cout<<"c++ accept mission not find mission from config misid = "<<id<<endl;
		return false;

	}
	mgr.AcceptCMission(this, *pCfg, &var, &str);
	return true;
}

bool CUser::AcceptCMission(int id,vector<int> &var,vector<string> &str)
{
	if(id == 0)
		return false;
	
	CMissionManager &mgr = SingletonCMissionManager::instance();
	SMissionConfig *pCfg = mgr.GetMissionCfg(id);
	if(pCfg == NULL)
		return false;
	mgr.AcceptCMission(this,*pCfg,&var,&str);
	return true;
}


bool CUser::GetCMissionInts(int id,vector<int> &ints)
{
	ints.clear();
	if(id == 0)
		return false;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	SAcceptMission *pMission = m_missList.GetAcceptedCMission(id);
	if(pMission == NULL)
		return false;

	ints = pMission->save_var;
	SMissionConfig *pCfg = SingletonCMissionManager::instance().GetMissionCfg(id);
	if (pCfg != NULL && pCfg->doing_content.op == EMISS_DC_61 && !ints.empty())
	{
		ints[0] = 2;
	}
	return true;
}


const char* CUser::GetCMissionContent(CUser *pUser,int id)
{
	if(pUser == NULL || !pUser->HaveCMission(id))
		return "";

	vector<int> ints;
	if(!pUser->GetCMissionInts(id,ints))
		return "";
	string res;
	for(uint16 i=0;i < ints.size();i++)
	{
		if(!res.empty())
			res += "|";
		res += IntToStr(ints[i]);
	}
	return res.c_str();
}

bool CUser::GetCMissionStrs(int id,vector<string> &strs)
{
	strs.clear();
	if(id == 0)
		return false;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	SAcceptMission *pMission = m_missList.GetAcceptedCMission(id);
	if(pMission == NULL)
		return false;
	strs = pMission->save_str;
	return true;
}

bool CUser::UpdateCMission(int id,const char *pInts,const char *pStrs)
{
	if(id == 0 || pInts == NULL || pStrs == NULL)
		return false;
	SMissionConfig *pCfg = SingletonCMissionManager::instance().GetMissionCfg(id);
	if(pCfg == NULL)
		return false;

	vector<int> var;
	vector<string> str;
	GetCMissionPara(var,str,pInts,pStrs);
	bool res = false;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		res = m_missList.UpdateCMission(id,var,str);
	}
	SingletonCMissionManager::instance().SendCMissionTrackMsg(this,id);
	return res;
}

bool CUser::UpdateCMissionEx(int id, const char *pInts, const char *pStrs, int idx)
{
	if (id == 0 || pInts == NULL || pStrs == NULL)
		return false;
	SMissionConfig *pCfg = SingletonCMissionManager::instance().GetMissionCfg(id);
	if (pCfg == NULL)
		return false;

	vector<int> var;
	vector<string> str;
	GetCMissionPara(var, str, pInts, pStrs);
	var[0] = idx;
	bool res = false;
	if (HaveCMission(id))
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		res = m_missList.UpdateCMission(id, var, str);
	}
	else
	{
		CMissionManager &mgr = SingletonCMissionManager::instance();
		SMissionConfig *pCfg = mgr.GetMissionCfg(id);
		if (pCfg == NULL)
		{
			cout << "c++ accept mission not find mission from config misid = " << id << endl;
			return false;

		}
		mgr.AcceptCMission(this, *pCfg, &var, &str);
	}
	SingletonCMissionManager::instance().SendCMissionTrackMsg(this, id);
	return res;
}


bool CUser::UpdateCMission(int id,vector<int> &var,vector<string> &str)
{
	if(id == 0 || var.empty())
		return false;
	SMissionConfig *pCfg = SingletonCMissionManager::instance().GetMissionCfg(id);
	if(pCfg == NULL)
		return false;

	bool res = false;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		res = m_missList.UpdateCMission(id,var,str);
	}
	SingletonCMissionManager::instance().SendCMissionTrackMsg(this,id);
	return res;
}

bool CUser::HaveCMission(int id)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return NoLockHaveCMission(id);
}

bool CUser::NoLockHaveCMission(int id)
{
	SAcceptMission *pMission = m_missList.GetAcceptedCMission(id);
	if(pMission == NULL)
		return false;
	return true;
}


bool CUser::AddTeamCMission(int id,const char *pInts,const char *pStrs)
{
	if(id == 0 || pInts == NULL || pStrs == NULL)
		return false;
	if(!AcceptCMission(id,pInts,pStrs))
		return false;

	vector<ShareUserPtr> pMember;
	GetTeamMemberList(this,pMember);
	int roleNum = pMember.size();
	for(int i=0;i < roleNum;i++)
	{
		if(pMember[i].get() != NULL && pMember[i]->GetRoleId() != m_roleId)
			pMember[i]->AcceptCMission(id,pInts,pStrs);
	}
	return true;
}

bool CUser::DelCMission(int id)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return m_missList.DelCMission(id,m_sock);
}

void CUser::DeleteFinishMissionById(int _mid){
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_missList.DeleteFinishMissionById(_mid);
}

void CUser::UpdateCMissionState(int missId,int state)
{
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		m_missList.UpdateCMisstionState(missId,state);
	}
	SingletonCMissionManager::instance().SendCMissionTrackMsg(this,missId);
}

bool CUser::IsCMissionFinished(int missId)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return m_missList.IsCMissionFinished(missId);
}

void CUser::MakeMission(CNetMessage &msg)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	uint16 pos = msg.GetDataLen();
	uint8 num = 0;
	msg<<num;

	vector<int> missList;
	m_missList.GetAcceptCMissList(missList);
	CMissionManager &mgr = SingletonCMissionManager::instance();
	for(uint32 i = 0; i < missList.size(); i++)
	{
		if(missList[i] != 0)
		{
			SMissionConfig *p = mgr.GetMissionCfg(missList[i]);
			if(p == NULL)
				continue;
			msg<<(uint16)missList[i]<<p->name;
			num++;
		}
	}
	msg.WriteData(pos,&num,sizeof(num));
}

//离开帮派时，删除帮派任务
void CUser::DelBangpaiMission()
{
	std::vector<uint32 > midvec;
    CMissionManager &mgr = SingletonCMissionManager::instance();

	mgr.GetMissionIdByOp(this, EMISS_DC_19, midvec);
	mgr.GetMissionIdByOp(this, EMISS_DC_54, midvec);
	mgr.GetMissionIdByOp(this, EMISS_DC_55, midvec);
	mgr.GetMissionIdByOp(this, EMISS_DC_56, midvec);
	if(midvec.empty()){
//		cout<<"VerifyNewBranchMissionFinish op error , op = "<<mtype<< endl;
		return ;
	}

	std::vector<uint32>::iterator it = midvec.begin();
	for(; it != midvec.end(); it++){
		uint32 mid = *it;
    	//只删除不加入完成列表
    	DeleteFinishMissionById(mid);
    	CSocketServer &sock = SingletonSocket::instance();
		CNetMessage msg;
		msg.SetType(PRO_UPDATE_TASK);
		msg<<(uint8)0<<(uint16)mid;
		sock.SendMsg(m_sock,msg);
	}
}

//进入帮派时，添加帮派任务
void CUser::AddBangpaiMission()
{
    std::vector<uint32 > midvec;
    CMissionManager &mgr = SingletonCMissionManager::instance();
	
	for (int i=0;i<4;i++)
	{
		midvec.push_back(MISSION_IDS_BangPai[i]);
	}
	if(midvec.empty()){
//		cout<<"VerifyNewBranchMissionFinish op error , op = "<<mtype<< endl;
		return ;
	}
	std::vector<uint32>::iterator it = midvec.begin();
	for(; it != midvec.end(); it++){
		uint32 mid = *it;
		SMissionConfig *pCfg = mgr.GetMissionCfg(mid);
		if(pCfg == NULL){
			continue;
		}
	    if (mgr.CheckCMissionCanAccepted(this,*pCfg))
	    {
	    	AcceptCMission(mid,"","");
	    }
	}
}

int CUser::EmptyPackage()
{
	uint8 num = 0;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint16 i = 0; i < MAX_PACKAGE_NUM; i++)
	{
		if(m_package[i].tmplId == 0)
		{
			num++;
		}
	}
	return num;
}

bool CUser::CanSavePackage(SItemInstance **pItem,uint8 num)
{
	if(num == 0)
		return true;

	uint8 emptyNum = 0;
	for(uint16 i = 0; i < MAX_PACKAGE_NUM; i++)
	{
		if(m_package[i].tmplId == 0)
		{
			emptyNum++;
		}
	}
	return emptyNum >= num;
}

int CUser::AddExp(int64 exp, bool isSend, bool fightEnd, int shuangbei/* = 0*/)			//经验
{
	if(exp == 0)
		return 0;
	m_exp += exp;
	CPetCfgManager& mgr = sCPetCfgManager;
	bool update = false;

	uint64 oldZhanDouLi = GetZhanDouLi();
	static uint16 maxLevel = 0;
	if (maxLevel == 0)
		maxLevel = mgr.GetPetMaxLevel();
	while (m_level < maxLevel)
	{
		LvCfg* cfg = mgr.GetLvCfgCfg(m_level);
		if (cfg == NULL) break;
		if (m_exp < cfg->exp) break;
		m_exp -= cfg->exp;
		AddLevel(cfg->tili);
		update = true;
	} 

	SingletonCRankMgr::instance().UpdateData(CRankMgr::ERT_Level, m_roleId, m_level, m_exp);
	
	uint64 oldPetZhanDouli = GetChuZhanPet_AllZhanDouLi();

	SendUpdateInfo(EUUT_Exp, exp);
	if (update)
		UpdateUserLevelUpInfo(oldZhanDouLi, oldPetZhanDouli);

	if (isSend)
	{
		char buf[512];
		snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_2210, exp);
		int needDouHao = false;
		if (shuangbei > 0)
		{
			if (needDouHao)
				strcat(buf, LANGUAGE_ZQX_0101);
			char temp[128];
			snprintf(temp, sizeof(temp), LANGUAGE_ZQX_0099, shuangbei*100);
			strcat(buf, temp);
		}
		if (needDouHao)
			strcat(buf, LANGUAGE_ZQX_0102);
		if (fightEnd)
		{
			SendSysInfoFightEnd(this, MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
		}
		else
		{
			SendSysInfo(this, MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
		}
	}
	return exp;
}

int CUser::AddPetExp(int64 exp)
{
	CNetMessage msg;
	msg.SetType(PRO_UPDATE_CHAR);
	uint8 num = m_zhenfaMember.size();
	msg << (uint8)3;
	uint16 pos = msg.GetDataLen();
	msg << num;
	CPetCfgManager &petMgr = SingletonCPetCfgMgr::instance();
	for (size_t i = 0; i < m_zhenfaMember.size(); i++)
	{
		uint16 petId = m_zhenfaMember[i].mem_id;
		SPet* pPet = GetPet(petId).get();
		if (pPet != NULL)
		{
			pPet->exp += exp;
			uint32 levelUpExp = petMgr.GetLevelUpExp(pPet->level);
			bool isLevelUp = false;
			while (pPet->exp >= levelUpExp && levelUpExp > 0 && pPet->level < m_level)
			{
				pPet->exp -= levelUpExp;
				pPet->level++;
				levelUpExp = petMgr.GetLevelUpExp(pPet->level);
				isLevelUp = true;
			}
			if (isLevelUp)
			{
				pPet->Init(this);
				UpdatePet(petId);
			}
			msg << petId << pPet->exp;
			num++;
		}
	}
	if (num > 0)
	{
		msg.WriteData(pos, &num, sizeof(num));
		SingletonSocket::instance().SendMsg(m_sock, msg);
	}
	return 0;
}


void CUser::AddExpByItemWithTips(int64 exp,bool sendTipsFightEnd)
{
	//char buf[64];
	AddExp(exp, true, sendTipsFightEnd);
//	snprintf(buf,sizeof(buf),"获得经验%lld",exp);
//	if(sendTipsFightEnd)
//		SendSysInfoFightEnd(this,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
//	else
//		SendSysInfo(this,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());

/*
	uint16 item1W_num = 0;
	uint16 item1K_num = 0;
	if(exp < 1000)
		return;
	item1W_num = (uint16)(exp/10000);
	item1K_num = (uint16)(exp%10000/1000);

	char buf[128];
	if(item1W_num > 0)
	{
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_2212,GetItemName(2342),item1W_num);
		if(sendTipsFightEnd)
			SendSysInfoFightEnd(this,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
		else
			SendSysInfo(this,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
		AddBangDingPackage(2342,item1W_num);
	}
	if(item1K_num > 0)
	{
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_2213,GetItemName(2341),item1K_num);
		if(sendTipsFightEnd)
			SendSysInfoFightEnd(this,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
		else
			SendSysInfo(this,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
		AddBangDingPackage(2341,item1K_num);
	}
*/
}

void CUser::SendChuZhanPetId(CNetMessage &msg)
{
	vector<uint16> petList;
	GetPetIdList(petList);
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	uint8 num = 0;
	uint16 pos = msg.GetDataLen();
	msg<<num;
	for(uint8 i=0;i < petList.size();i++)
	{
		SPet *pPet = NoLockGetPet(petList[i]).get();
		if(pPet != NULL)
		{
			if(pPet->chuzhanFlag == 1)
			{
				num++;
				msg<<pPet->id<<pPet->quality;
			}
		}
	}
	msg.WriteData(pos,&num,sizeof(num));
}

uint64 CUser::GetChuZhanPet_AllZhanDouLi()
{
	uint64 val = 0;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint8 i=0;i < m_zhenfaMember.size();i++)
	{
		if(m_zhenfaMember[i].mem_type == EZFMT_PET)
		{
			uint16 petId = m_zhenfaMember[i].mem_id;
			if(petId > 0)
			{
				SPet *pPet = NoLockGetPet(petId).get();
				if(pPet != NULL)
					val += pPet->GetZhanDouLi();
			}
		}
	}
	return val;
}

void CUser::SendMsgToTeamMember(const char *msg)
{
	if(m_pScene == NULL)
		return;
	uint32 members[MAX_TEAM_MEMBER];
	uint8 num = m_pScene->GetTeamMem(m_teamId,members);

	for(uint8 i = 0; i < num; i++)
	{
		COnlineUser &m_onlineUser = SingletonOnlineUser::instance();
		ShareUserPtr ptr = m_onlineUser.GetUserByRoleId(members[i]);
		CUser *pUser = ptr.get();
		if((pUser != NULL) && (pUser->GetRoleId() != m_roleId))
			SendSysInfo(pUser,msg);
	}
}

void CUser::UpdateUserLevelUpInfo(uint64 oldZhanDouLi, uint64 oldPetZhanDouLi)
{
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_UPDATE_USER_LEVELUP_INFO);
	//			老等级			老战斗力	老神将总战斗力
	msg<<(uint8)(m_level-1)<<oldZhanDouLi<<oldPetZhanDouLi;
	//		等级	战斗力		当前战斗力
	msg<<m_level<<GetZhanDouLi()<<GetChuZhanPet_AllZhanDouLi();
	SendChuZhanPetId(msg);
//	msg<<GetMaxChuZhanPetNum();
	sock.SendMsg(m_sock,msg);
}

void CUser::SendUpdateInfo(int type,int addValue)
{
	/*
	type < 500: attrType
	type=500: send all attrType data
	type=501: 潜能
	type=502: exp
	type=503: hp
	type=504: 金币
	type=505: 元宝
	type=506: 绑定元宝
	type=507: 战斗力
	type=508: 新开启背包格子数
	type=509: 下一个背包格子开启时间
	type=510: 竞技场积分	GetExtData32(97)
	type=511: 武器特效
	*/
	CNetMessage msg;
	msg.SetType(PRO_UPDATE_CHAR);
	uint16 num = 0;
	msg << (uint8)1;
	uint16 pos = msg.GetDataLen();
	msg << num;
	if(type == EUUT_AllAttrType)
	{
		msg<<(int)EAT_Attack<<m_attr.attack; num++;
		msg<<(int)EAT_WuFang<<m_attr.wufang; num++;
		msg<<(int)EAT_FaFang<<m_attr.fafang; num++;
		msg<<(int)EAT_QiXue<<m_attr.maxHp; num++;
		msg<<(int)EAT_SuDu<<m_attr.speed; num++;
		msg<<(int)EAT_MingZhong<<m_attr.mingzhong; num++;
		msg<<(int)EAT_ShanBi<<m_attr.shanbi; num++;
		msg<<(int)EAT_BaoJi<<m_attr.baoji; num++;
		msg<<(int)EAT_BaoJiKang<<m_attr.baojikang; num++;
		msg<<(int)EAT_MingZhongLv<<m_attr.mingzhongLv; num++;
		msg<<(int)EAT_ShanBiLv<<m_attr.shanbiLv; num++;
		msg<<(int)EAT_BaoJiLv<<m_attr.baojiLv; num++;
		msg<<(int)EAT_BaoJiKangLv<<m_attr.baojikangLv; num++;
		msg<<(int)EAT_ZengShangLv<<m_attr.zengshangLv; num++;
		msg<<(int)EAT_WuMianLv<<m_attr.wumianLv; num++;
		msg<<(int)EAT_FaMianLv<<m_attr.famianLv; num++;
		msg<<(int)EAT_BaoJiAdd<<m_attr.baojiAdd; num++;
		msg<<(int)EAT_FanJiLv<<m_attr.fanjiLv; num++;
		msg<<(int)EAT_FanJiKangLv<<m_attr.fanjikangLv; num++;
		msg<<(int)EAT_FanJiAdd<<m_attr.fanjiAdd; num++;
		msg<<(int)EAT_LianJiLv<<m_attr.lianjiLv; num++;
		msg<<(int)EAT_LianJiKangLv<<m_attr.lianjikangLv; num++;
		msg<<(int)EAT_LianJiAdd<<m_attr.lianjiAdd; num++;
		msg<<(int)EAT_FanZhenLv<<m_attr.fanzhenLv; num++;
		msg<<(int)EAT_FanZhenKangLv<<m_attr.fanzhenkangLv; num++;
		msg<<(int)EAT_FanZhenAdd<<m_attr.fanzhenAdd; num++;
		msg<<(int)EAT_FuMianAdd<<m_attr.fumianAdd; num++;
		msg<<(int)EAT_FuMianKangAdd<<m_attr.fumianKangAdd; num++;
		msg<<(int)EUUT_ZhanDouLi<<m_zhanDouLi; num++;
		msg<<(int)EUUT_TotalZhanDouLi<<m_zhanDouLi; num++;
	}
	else
	{
		num++;
		msg<<type;
		if (type == EAT_Attack)
			msg << m_attr.attack;
		else if (type == EAT_WuFang)
			msg << m_attr.wufang;
		else if (type == EAT_FaFang)
			msg << m_attr.fafang;
		else if (type == EAT_QiXue)
			msg << m_attr.maxHp;
		else if (type == EAT_SuDu)
			msg << m_attr.speed;
		else if (type == EAT_MingZhong)
			msg << m_attr.mingzhong;
		else if (type == EAT_ShanBi)
			msg << m_attr.shanbi;
		else if (type == EAT_BaoJi)
			msg << m_attr.baoji;
		else if (type == EAT_BaoJiKang)
			msg << m_attr.baojikang;
		else if (type == EAT_MingZhongLv)
			msg << m_attr.mingzhongLv;
		else if (type == EAT_ShanBiLv)
			msg << m_attr.shanbiLv;
		else if (type == EAT_BaoJiLv)
			msg << m_attr.baojiLv;
		else if (type == EAT_BaoJiKangLv)
			msg << m_attr.baojikangLv;
		else if (type == EAT_ZengShangLv)
			msg << m_attr.zengshangLv;
		else if (type == EAT_WuMianLv)
			msg << m_attr.wumianLv;
		else if (type == EAT_FaMianLv)
			msg << m_attr.famianLv;
		else if (type == EAT_BaoJiAdd)
			msg << m_attr.baojiAdd;
		else if (type == EAT_FanJiLv)
			msg << m_attr.fanjiLv;
		else if (type == EAT_FanJiKangLv)
			msg << m_attr.fanjikangLv;
		else if (type == EAT_FanJiAdd)
			msg << m_attr.fanjiAdd;
		else if (type == EAT_LianJiLv)
			msg << m_attr.lianjiLv;
		else if (type == EAT_LianJiKangLv)
			msg << m_attr.lianjikangLv;
		else if (type == EAT_LianJiAdd)
			msg << m_attr.lianjiAdd;
		else if (type == EAT_FanZhenLv)
			msg << m_attr.fanzhenLv;
		else if (type == EAT_FanZhenKangLv)
			msg << m_attr.fanzhenkangLv;
		else if (type == EAT_FanZhenAdd)
			msg << m_attr.fanzhenAdd;
		else if (type == EAT_FuMianAdd)
			msg << m_attr.fumianAdd;
		else if (type == EAT_FuMianKangAdd)
			msg << m_attr.fumianKangAdd;

		else if (type == EUUT_QianNeng)
			msg << m_qianneng;
		else if (type == EUUT_Exp)
			msg << addValue;
//		else if (type == EUUT_HP)
//			msg << m_hp;
		else if (type == EUUT_Money)
			msg << m_money;
		else if (type == EUUT_YB)
			msg << m_tongBao;
		else if (type == EUUT_BangDingYB)
			msg << m_bdTongBao;
		else if (type == EUUT_OpenPackageNum)
			msg << (uint32)MAX_PACKAGE_NUM;
		else if (type == EUUT_NextOpenPackageTime)
			msg << m_nextOpenPackageTime;
		else if (type == EUUT_ArenaScore)
			msg << NoLockGetExtData32(97);
//		else if (type == EUUT_LightEffect)
//			msg << (uint32)GetLightEffect();
		else if (type == EUUT_HuSongState)
			msg << (uint32)NoLockInHuSongMission();
		else if (type == EUUT_TotalZhanDouLi)
			msg << m_zhanDouLi;
		else if (type == EUUT_Shenhun)
			msg << NoLockGetShenhun();
		else if (type == EUUT_MeiLi)
			msg << GetExtData32(465);
		else if (type == EUUT_Jifen)
		{
			msg << GetJifen();
		}
		else if (type == EUUT_XingXiuJingHua)
		{
			msg << GetExtData32(466);
		}
		else
			return;
	}
	msg.WriteData(pos,&num,sizeof(num));
	SingletonSocket::instance().SendMsg(m_sock,msg);
}

void CUser::SendUpdateMoney(int type)
{
	CNetMessage msg;
	msg.SetType(PRO_UPDATE_CHAR);
	msg << (uint8)2 << (uint16)type;
	switch (type)
	{
	case HDAT_MONEY:
		msg << m_money;
		break;
	case HDAT_BANG_YB:
	case HDAT_YB:
		msg << m_tongBao;
		break;
	case HDAT_XingXiuJingHua:
		msg << GetExtData32(ED32_XZMoney);
		break;
	case HDAT_JJCMoney:
		msg << GetExtData32(ED32_JJCMoney);
		break;
	case HDAT_KunLunMoney:
		msg << GetExtData32(ED32_KLMoney);
		break;
	case HDAT_SHEN_HUN:
		msg << GetExtData32(ED32_ShenHunMoney);
		break;
	case HDAT_BANG_GONG:
		msg << GetBangGong();
		break;
	case HDAT_HuoYue:
		msg << GetExtData32(EData32_HuoYueDu_Day);
		break;
	case HDAT_ArenaCnt:
		msg << (uint32)GetExtData16(ED16_69);
		break;
	default:
		return;
	}
	SingletonSocket::instance().SendMsg(m_sock, msg);
}


void CUser::UpdateJifenInfo()
{
	SendUpdateInfo(EUUT_Jifen);
}

void CUser::UpdateAllPetInfo(int type)
{
	vector<uint16> petList;
	GetPetIdList(petList);
	for(uint16 i=0;i < petList.size();i++)
	{
		SPet *pPet = GetPet(petList[i]).get();
		if(pPet != NULL)
		{
			if(type == 0)
				UpdatePetInfo(petList[i]);
			else
				SendPetUpdateInfo(petList[i],type);
		}
	}
}

void CUser::UpdatePetInfo(uint16 petId)
{
	SendPetUpdateInfo(petId,EUUT_AllAttrType);
	SendPetUpdateInfo(petId,EUUT_HP);
	SendUpdateInfo(EUUT_TotalZhanDouLi);
}

void CUser::UpdateZhenFaPetInfo(uint8 pos, bool notify/* = true*/)
{
	if (pos == 0 || pos > m_chuzhan.size())
		return;
	uint16 petId = m_chuzhan[pos - 1];
	SPet *pPet = GetPet(petId).get();
	if (pPet == NULL)
		return;
	pPet->Init(this);
	if (notify)
		ResetPower();
	UpdatePetInfo(petId);
	SingletonCRankMgr::instance().UpdateData(CRankMgr::ERT_Pet, GetRoleId(), pPet->zhanDouli, 0, petId);
}

void CUser::SendPetUpdateInfo(uint16 petId,int type)
{
	/*
	type < 500: attrType
	type=500: send all attrType data
	type=501: 潜能
	type=502: exp
	type=503: hp
	type=504: 金币
	type=505: 元宝
	type=506: 绑定元宝
	type=507: 战斗力
	type=508: 新开启背包格子数
	type=509: 下一个背包格子开启时间
	type=510: 竞技场积分	GetExtData32(97)
	type=511: 武器特效
	*/
	if(petId == 0)
		return;
	SPet *pPet = GetPet(petId).get();
	if(pPet == NULL)
		return;
	
	CNetMessage msg;
	msg.SetType(PRO_UPDATE_PET_INFO);
	msg<<petId;
	uint16 pos = msg.GetDataLen();
	uint16 num = 0;
	msg<<num;
	if(type == EUUT_AllAttrType)
	{
		msg<<(int)EAT_Attack<<pPet->basicAttr.attack; num++;
		msg<<(int)EAT_WuFang<<pPet->basicAttr.wufang; num++;
		msg<<(int)EAT_FaFang<<pPet->basicAttr.fafang; num++;
		msg<<(int)EAT_QiXue<<pPet->basicAttr.maxHp; num++;
		msg<<(int)EAT_SuDu<<pPet->basicAttr.speed; num++;
		msg<<(int)EAT_MingZhong<<pPet->basicAttr.mingzhong; num++;
		msg<<(int)EAT_ShanBi<<pPet->basicAttr.shanbi; num++;
		msg<<(int)EAT_BaoJi<<pPet->basicAttr.baoji; num++;
		msg<<(int)EAT_BaoJiKang<<pPet->basicAttr.baojikang; num++;
		msg<<(int)EAT_MingZhongLv<<pPet->basicAttr.mingzhongLv; num++;
		msg<<(int)EAT_ShanBiLv<<pPet->basicAttr.shanbiLv; num++;
		msg<<(int)EAT_BaoJiLv<<pPet->basicAttr.baojiLv; num++;
		msg<<(int)EAT_BaoJiKangLv<<pPet->basicAttr.baojikangLv; num++;
		msg<<(int)EAT_ZengShangLv<<pPet->basicAttr.zengshangLv; num++;
		msg<<(int)EAT_WuMianLv<<pPet->basicAttr.wumianLv; num++;
		msg<<(int)EAT_FaMianLv<<pPet->basicAttr.famianLv; num++;
		msg<<(int)EAT_BaoJiAdd<<pPet->basicAttr.baojiAdd; num++;
		msg<<(int)EAT_FanJiLv<<pPet->basicAttr.fanjiLv; num++;
		msg<<(int)EAT_FanJiKangLv<<pPet->basicAttr.fanjikangLv; num++;
		msg<<(int)EAT_FanJiAdd<<pPet->basicAttr.fanjiAdd; num++;
		msg<<(int)EAT_LianJiLv<<pPet->basicAttr.lianjiLv; num++;
		msg<<(int)EAT_LianJiKangLv<<pPet->basicAttr.lianjikangLv; num++;
		msg<<(int)EAT_LianJiAdd<<pPet->basicAttr.lianjiAdd; num++;
		msg<<(int)EAT_FanZhenLv<<pPet->basicAttr.fanzhenLv; num++;
		msg<<(int)EAT_FanZhenKangLv<<pPet->basicAttr.fanzhenkangLv; num++;
		msg<<(int)EAT_FanZhenAdd<<pPet->basicAttr.fanzhenAdd; num++;
		msg<<(int)EAT_FuMianAdd<<pPet->basicAttr.fumianAdd; num++;
		msg<<(int)EAT_FuMianKangAdd<<pPet->basicAttr.fumianKangAdd; num++;
		msg<<(int)EUUT_ZhanDouLi<<pPet->zhanDouli; num++;
		msg<<(int)EUUT_HP<<pPet->hp; num++;
	}
	else
	{
		num++;
		msg<<type;
		if (type == EAT_Attack)
			msg << pPet->basicAttr.attack;
		else if (type == EAT_WuFang)
			msg << pPet->basicAttr.wufang;
		else if (type == EAT_FaFang)
			msg << pPet->basicAttr.fafang;
		else if (type == EAT_QiXue)
			msg << pPet->basicAttr.maxHp;
		else if (type == EAT_SuDu)
			msg << pPet->basicAttr.speed;
		else if (type == EAT_MingZhong)
			msg << pPet->basicAttr.mingzhong;
		else if (type == EAT_ShanBi)
			msg << pPet->basicAttr.shanbi;
		else if (type == EAT_BaoJi)
			msg << pPet->basicAttr.baoji;
		else if (type == EAT_BaoJiKang)
			msg << pPet->basicAttr.baojikang;
		else if (type == EAT_MingZhongLv)
			msg << pPet->basicAttr.mingzhongLv;
		else if (type == EAT_ShanBiLv)
			msg << pPet->basicAttr.shanbiLv;
		else if (type == EAT_BaoJiLv)
			msg << pPet->basicAttr.baojiLv;
		else if (type == EAT_BaoJiKangLv)
			msg << pPet->basicAttr.baojikangLv;
		else if (type == EAT_ZengShangLv)
			msg << pPet->basicAttr.zengshangLv;
		else if (type == EAT_WuMianLv)
			msg << pPet->basicAttr.wumianLv;
		else if (type == EAT_FaMianLv)
			msg << pPet->basicAttr.famianLv;
		else if (type == EAT_BaoJiAdd)
			msg << pPet->basicAttr.baojiAdd;
		else if (type == EAT_FanJiLv)
			msg << pPet->basicAttr.fanjiLv;
		else if (type == EAT_FanJiKangLv)
			msg << pPet->basicAttr.fanjikangLv;
		else if (type == EAT_FanJiAdd)
			msg << pPet->basicAttr.fanjiAdd;
		else if (type == EAT_LianJiLv)
			msg << pPet->basicAttr.lianjiLv;
		else if (type == EAT_LianJiKangLv)
			msg << pPet->basicAttr.lianjikangLv;
		else if (type == EAT_LianJiAdd)
			msg << pPet->basicAttr.lianjiAdd;
		else if (type == EAT_FanZhenLv)
			msg << pPet->basicAttr.fanzhenLv;
		else if (type == EAT_FanZhenKangLv)
			msg << pPet->basicAttr.fanzhenkangLv;
		else if (type == EAT_FanZhenAdd)
			msg << pPet->basicAttr.fanzhenAdd;
		else if (type == EAT_FuMianAdd)
			msg << pPet->basicAttr.fumianAdd;
		else if (type == EAT_FuMianKangAdd)
			msg << pPet->basicAttr.fumianKangAdd;

//		else if (type == EUUT_Exp)
//			msg << addValue;
		else if (type == EUUT_HP)
			msg << pPet->hp;
		else if(type == EUUT_ZhanDouLi)
			msg << pPet->zhanDouli;
		else
			return;
	}
	msg.WriteData(pos,&num,sizeof(num));
	SingletonSocket::instance().SendMsg(m_sock,msg);
}


void CUser::AddHp(int hp,int maxHp)//气血
{

}

void CUser::AddDamage(int damage)
{
//	m_damage += damage;
}

void CUser::AddSkillDamage(int skillDamage)
{
//	atomic_exchange_and_add((int*)&m_skillDamage,skillDamage);
}

void CUser::AddRecovery(int recovery)
{
//	atomic_exchange_and_add((int*)&m_recovery,recovery);
}

void CUser::AddSpeed(int speed)
{
//	atomic_exchange_and_add((int*)&m_speed,speed);
}

void CUser::SetVal(int id,int val)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_intMap[id] = val;
	//m_intMap.insert(pair <int, int> (id,val));
}

// 保存记录信息 每个玩家的type具有唯一性会覆盖
bool CUser::SetDataStr(int type, const char* data)
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if (pDb == NULL)
		return false;
	char sql[512];
	if (strlen(data) == 0)
		snprintf(sql,sizeof(sql),"delete from script_save_role where role_id = %d and type = %d",(int)GetRoleId(),type);
	else
	{
		snprintf(sql,sizeof(sql),"select id from script_save_role where role_id = %d and type = %d",(int)GetRoleId(),type);
		if (!pDb->Query(sql))
			return false;
		if (pDb->GetRowNum() == 0) // 没有以前的老数据
			snprintf(sql,sizeof(sql),"insert into script_save_role (role_id,type,data) values (%d,%d,'%s')",(int)GetRoleId(),type,data);
		else
			snprintf(sql,sizeof(sql),"update script_save_role set data = '%s' where role_id = %d and type = %d",data,(int)GetRoleId(),type);
	}
	//cout << "sql:" << sql << endl;
	return pDb->Query(sql);
}

// 获取已经保存的记录
const char* CUser::GetDataStr(int type)
{
	static char data[512];
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if (pDb == NULL)
		return "";
	char sql[255];
	snprintf(sql,sizeof(sql),"select data from script_save_role where role_id = %d and type = %d",(int)GetRoleId(),type);
	if (!pDb->Query(sql))
		return "";
	char **row = pDb->GetRow();
	if (row == NULL)
		return "";
	snprintf(data,sizeof(data),"%s",row[0]);
	return data;
}

// 获取已经保存的记录 玩家初始化的时候，存在没有roleid就读取数据的可能
const char* CUser::GetDataStr(int roleId, int type)
{
	static char data[383];
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if (pDb == NULL)
		return "";
	char sql[255];
	snprintf(sql,sizeof(sql),"select data from script_save_role where role_id = %d and type = %d",(int)roleId,type);
	if (!pDb->Query(sql))
		return "";
	char **row = pDb->GetRow();
	if (row == NULL)
		return "";
	strcpy(data,row[0]);
	return data;
}

int CUser::GetVal(int id)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<int,int>::iterator i = m_intMap.find(id);
	if(i != m_intMap.end())
		return i->second;
	return 0;
}

void CUser::Clear()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_userOp = 0;
	m_userPara = 0;
	m_autoFightTurn = 0;
	SetFight(0);

	m_logout = false;
	m_step = 0;
	m_roleId = 0;
	m_inJump = false;
	memset(m_role,0,sizeof(m_role));
	m_pet.clear();
	m_gensuiPet = 0;//跟随神将

	memset(m_qx_petlist,0,sizeof(m_qx_petlist));
	memset(m_qx_chuzhan,0,sizeof(m_qx_chuzhan));
	for(uint8 i=0;i < sizeof(m_qx_hpRatio)/sizeof(m_qx_hpRatio[0]);i++)
		m_qx_hpRatio[i] = 10000;
	m_qx_dieFlag = 0;
	m_qx_awardFlag = 0;
	memset(m_qx_addAttrVal,0,sizeof(m_qx_addAttrVal));
	memset(m_qx_addAttrPercent,0,sizeof(m_qx_addAttrPercent));

	list<SNpcInstance>::iterator i = m_npcList.begin();
	for(; i != m_npcList.end(); i++)
	{
		if(i->pNpc != NULL)
		{
			delete i->pNpc;
			i->pNpc = NULL;
		}
		if(i->pHumanData != NULL)
		{
			delete i->pHumanData;
			i->pHumanData = NULL;
		}
	}
	m_npcList.clear();

	list<SNpcInstance>::iterator it = m_collectList.begin();
	for(; it != m_collectList.end(); it++)
	{
		if(it->pNpc != NULL)
		{
			delete it->pNpc;
			it->pNpc = NULL;
		}
		if(it->pHumanData != NULL)
		{
			delete it->pHumanData;
			it->pHumanData = NULL;
		}
	}
	m_collectList.clear();

	m_bitset.reset();
	m_saveDataTime = GetSysTime();
	memset(m_bossMissionStar,0,sizeof(m_bossMissionStar));
	m_multiExpTime = GetSysTime();
	m_mysteryTime = 0;
	m_shenhunTime = 0;
	m_bangArea_killNum = 0;
	memset(m_xiuxian,0,sizeof(m_xiuxian));
	m_kuafuState = EKFS_IN_LOCAL;
	m_sigId = 0;
	m_sigStr.clear();
	m_lastSrcSceneId = 0;
	m_checkNpc = false;
	m_yaoshiTime = 0;
	m_useZhenFaIdx = 0xff;

	m_zhenfaMember.clear();
	for(int i=0;i < MAX_TEAM_MEMBER;i++)
	{
		SZhenFaMemData data;
		m_zhenfaMember.push_back(data);
	}
}

void CUser::SetNpc(char *row)
{
	if(row == NULL)
		return;

	boost::recursive_mutex::scoped_lock lk(m_mutex);

	list<SNpcInstance>::iterator i = m_npcList.begin();
	for(; i != m_npcList.end(); i++)
	{
		delete i->pNpc;
		delete i->pHumanData;
		i->pNpc = NULL;
		i->pHumanData = NULL;
	}
	m_npcList.clear();

	char *p[80];
	uint8 num = SplitLine(p,80,row);

	SNpcInstance npc;
	CNpcManager &npcManager = SingletonNpcManager::instance();

	for(uint8 i = 0; (i+8) <= num; i+=8)
	{
		npc.id = atoi(p[i]);
		npc.sceneId = atoi(p[i+1]);
		npc.x = atoi(p[i+2]);
		npc.y = atoi(p[i+3]);
		npc.timeOut = atoi(p[i+4]);
		SNpcTemplate *pNpc = npcManager.GetNpcTemplate(npc.id);
		if(pNpc == NULL)
			continue;
		npc.pNpc = new SNpcTemplate;
		*(npc.pNpc) = *pNpc;
		npc.name = p[i+5];
		npc.direct = atoi(p[i+7]);
//		uint32 roleId = atoi(p[i+6]);
		if (npc.id >= 251 && npc.id <= 256)
			npc.nameColor = PQT_RED;
		m_npcList.push_back(npc);
	}
}

void CUser::SetMonster(char *row)
{
	if(row == NULL)
		return;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_monsterList.clear();
	char *p[140];
	uint8 num = SplitLine(p,140,row);

	for(uint8 i = 0; (i+7) <= num; i+=7)
	{
		SVisibleMonster temp;
		temp.id = (uint32)atoi(p[i]);
		temp.sceneId = (uint16)atoi(p[i+1]);
		temp.x = (uint16)atoi(p[i+2]);
		temp.y = (uint16)atoi(p[i+3]);
		temp.face = (uint8)atoi(p[i+4]);
		temp.pic = (uint16)atoi(p[i+5]);
		temp.name = p[i+6];
		m_monsterList.push_back(temp);
	}
}

void CUser::SetBossMissionStar(char *str)
{
	if(str == NULL || strlen(str) == 0)
		return;
	char *p[20];
	uint8 num = SplitLine(p,DAILY_BOSS_MAX_NUM,str);
	if(num < DAILY_BOSS_MAX_NUM)
		return;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint8 i = 0; i < sizeof(m_bossMissionStar)/sizeof(m_bossMissionStar[0]); i++)
	{
		m_bossMissionStar[i] = (uint8)atoi(p[i]);
	}
}

void CUser::SetBossMissionData(int index,int starNum)
{
	if(index < 1 || index > DAILY_BOSS_MAX_NUM)
		return;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(m_bossMissionStar[index-1] < (uint8)starNum)
		m_bossMissionStar[index-1] = (uint8)starNum;
}

void CUser::GetBossMissionStar(string &str)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	str.clear();

	char buf[64] = {0};
	uint8 pos = 0;
	for(uint8 i = 0; i < sizeof(m_bossMissionStar)/sizeof(m_bossMissionStar[0]); i++)
	{
		buf[pos++] = '0' + (char)m_bossMissionStar[i];
		buf[pos++] = '|';
	}
	buf[pos-1] = '\0';
	str = buf;
}

void CUser::GetXiuXianInfo(string &str)
{
	str.clear();
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint8 i = 0; i < sizeof(m_xiuxian)/sizeof(m_xiuxian[0]); i++)
	{
		str += IntToStr(m_xiuxian[i].winFlag) + "|";
		str += IntToStr(m_xiuxian[i].fightNum) + "|";
	}
}

void CUser::SetXiuXianInfo(char *str)
{
	if(str == NULL || strlen(str) < 2)
		return;
	char *p[500];
	uint8 num = SplitLine(p,500,str);
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint8 i = 0; i < sizeof(m_xiuxian)/sizeof(m_xiuxian[0]) && i < num/2; i++)
	{
		m_xiuxian[i].winFlag = atoi(p[2*i]);
		m_xiuxian[i].fightNum = atoi(p[2*i+1]);
	}
}

// idx: 1 ~ max
bool CUser::IsOpenXiuXianByIdx(int idx)
{
	if(idx < 1 || idx > (int)(sizeof(m_xiuxian)/sizeof(m_xiuxian[0])))
		return false;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(idx > 5)
	{
		for(int i=((idx-1)/5 - 1)*5+1; i <= ((idx-1)/5)*5; i++)
		{
			if(m_xiuxian[i-1].winFlag == 0)
				return false;
		}
	}
	return true;
}

bool CUser::CanFightXiuXianByIdx(int idx)
{
	if(idx < 1 || idx > (int)(sizeof(m_xiuxian)/sizeof(m_xiuxian[0])))
		return false;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return !IsXiuXianWinByIdx(idx);
}

bool CUser::IsXiuXianWinByIdx(int idx)
{
	if(idx < 1 || idx > (int)(sizeof(m_xiuxian)/sizeof(m_xiuxian[0])))
		return false;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return (m_xiuxian[idx-1].winFlag == 1) ? true : false;
}

void CUser::SetXiuXianData(int idx,bool win)
{
	if(idx < 1 || idx > (int)(sizeof(m_xiuxian)/sizeof(m_xiuxian[0])))
		return;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_xiuxian[idx-1].fightNum++;
	if(m_xiuxian[idx-1].winFlag == 0)
		m_xiuxian[idx-1].winFlag = (win ? 1 : 0);
}

void CUser::UpdateXiuXian(int idx)
{
	if(idx < 1 || idx > MAX_XIU_XIAN_NUM)
		return;
	CNetMessage msg;
	msg.SetType(MSG_XIU_XIAN_LI_LIAN);
	msg<<(uint8)4;
	msg<<(uint16)idx;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		uint8 canFight = (m_xiuxian[idx-1].fightNum >= (uint8)XIUXIAN_PER_NODE_FNUM) ? 0 : 1;	// 0不可战斗1可战斗
		msg<<m_xiuxian[idx-1].winFlag<<canFight;
	}

	int lockUpdateIdx = 5*(1+(idx-1)/5) + 1;
	if(lockUpdateIdx > MAX_XIU_XIAN_NUM)
	{
		msg<<(uint8)0;
		SingletonSocket::instance().SendMsg(m_sock,msg);
		return;
	}

	uint8 lock = 0;
	bool allWin = true;
	for(int i = 5*((idx-1)/5)+1;i <= 5*(1+(idx-1)/5);i++)
	{
		if(i > MAX_XIU_XIAN_NUM)
			return;
		if(m_xiuxian[i-1].winFlag == 0)	// 未战胜
		{
			allWin = false;
			break;
		}
	}
	if(allWin)
		lock = 0;
	else
		lock = 1;
	msg<<(uint8)5;
	for(int i = lockUpdateIdx;i < lockUpdateIdx+5;i++)
	{
		if(i > MAX_XIU_XIAN_NUM)
			return;
		msg<<(uint16)i<<lock;
	}
	SingletonSocket::instance().SendMsg(m_sock,msg);
}

void CUser::MakeXiuXianMsg(CNetMessage &msg)
{
	const uint16 PerChapNum = 5;
	const char *Chapter[] = {LANGUAGE_TRANSFORM_2214,LANGUAGE_TRANSFORM_2215,LANGUAGE_TRANSFORM_2216,LANGUAGE_TRANSFORM_2217,LANGUAGE_TRANSFORM_2218,
		LANGUAGE_TRANSFORM_2219,LANGUAGE_TRANSFORM_2220,LANGUAGE_TRANSFORM_2221,LANGUAGE_TRANSFORM_2222,LANGUAGE_TRANSFORM_2223};
	const char *Name[][PerChapNum]  = {
		{LANGUAGE_TRANSFORM_2224,LANGUAGE_TRANSFORM_2225,LANGUAGE_TRANSFORM_2226,LANGUAGE_TRANSFORM_2227,LANGUAGE_TRANSFORM_2228},
		{LANGUAGE_TRANSFORM_2229,LANGUAGE_TRANSFORM_2230,LANGUAGE_TRANSFORM_2231,LANGUAGE_TRANSFORM_2232,LANGUAGE_TRANSFORM_2233},
		{LANGUAGE_TRANSFORM_2234,LANGUAGE_TRANSFORM_2235,LANGUAGE_TRANSFORM_2236,LANGUAGE_TRANSFORM_2237,LANGUAGE_TRANSFORM_2238},
		{LANGUAGE_TRANSFORM_2239,LANGUAGE_TRANSFORM_2240,LANGUAGE_TRANSFORM_2241,LANGUAGE_TRANSFORM_2242,LANGUAGE_TRANSFORM_2243},
		{LANGUAGE_TRANSFORM_2244,LANGUAGE_TRANSFORM_2245,LANGUAGE_TRANSFORM_2246,LANGUAGE_TRANSFORM_2247,LANGUAGE_TRANSFORM_2248},
		{LANGUAGE_TRANSFORM_2249,LANGUAGE_TRANSFORM_2250,LANGUAGE_TRANSFORM_2251,LANGUAGE_TRANSFORM_2252,LANGUAGE_TRANSFORM_2253},
		{LANGUAGE_TRANSFORM_2254,LANGUAGE_TRANSFORM_2255,LANGUAGE_TRANSFORM_2256,LANGUAGE_TRANSFORM_2257,LANGUAGE_TRANSFORM_2258},
		{LANGUAGE_TRANSFORM_2259,LANGUAGE_TRANSFORM_2260,LANGUAGE_TRANSFORM_2261,LANGUAGE_TRANSFORM_2262,LANGUAGE_TRANSFORM_2263},
		{LANGUAGE_TRANSFORM_2264,LANGUAGE_TRANSFORM_2265,LANGUAGE_TRANSFORM_2266,LANGUAGE_TRANSFORM_2267,LANGUAGE_TRANSFORM_2268},
		{LANGUAGE_TRANSFORM_2269,LANGUAGE_TRANSFORM_2270,LANGUAGE_TRANSFORM_2271,LANGUAGE_TRANSFORM_2272,LANGUAGE_TRANSFORM_2273}};
	// 1 monPic 2 roleHead
	const uint16 monsterPic[][PerChapNum][2] = {
		{{1,59}, {1,107},{1,39}, {1,31}, {1,0}},
		{{1,41}, {1,37}, {1,38}, {1,26}, {1,0}},
		{{1,23}, {1,104},{1,112},{1,117},{1,0}},
		{{1,58}, {1,120},{1,110},{1,118},{1,0}},
		{{1,36}, {1,101},{1,36}, {1,104},{1,0}},
		{{1,41}, {1,10}, {1,104},{1,114},{1,0}},
		{{1,111},{1,104},{1,37}, {1,15}, {1,0}},
		{{1,101},{1,111},{1,114},{1,114},{1,0}}};

	CMonsterBossManager &bossManager = SingletonMonsterBossManager::instance();
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	uint16 size = sizeof(m_xiuxian)/sizeof(m_xiuxian[0]);
	uint16 ChapNum = size/PerChapNum;
	uint8 lock = 0;	// 0未锁 1锁定
	bool allWin = true;
	msg<<ChapNum;
	for(uint16 i=0;i < ChapNum;i++)
	{
		allWin = true;
		msg<<(uint16)(i+1)<<Chapter[i]<<PerChapNum;
		for(uint16 j=0;j < PerChapNum;j++)
		{
			uint16 index = i*PerChapNum+j+1;
			uint16 type = monsterPic[i][j][0];
			uint8 canFight = (m_xiuxian[index-1].fightNum >= (uint8)XIUXIAN_PER_NODE_FNUM) ? 0 : 1;	// 0不可战斗1可战斗
			if(m_xiuxian[index-1].winFlag == 0)
				allWin = false;
			msg<<index<<Name[i][j]<<m_xiuxian[index-1].winFlag<<canFight<<lock<<(uint8)type;
			if(type == 1)	// monster
			{
				int pic = 0;
				string name;
				int monsterId = 11700+5*index;
				if(!bossManager.GetMonsterBossInfo(monsterId,pic,name))
					return;
				msg<<(uint16)pic;
			}
			else	// role
			{
				uint8 xiang = 1;
				uint8 sex = 1;
				GetXiuXianRobotData(index,xiang,sex);
				msg<<xiang<<sex;
			}
		}
		if(allWin)
			lock = 0;
		else
			lock = 1;
	}
}

uint8 CUser::GetBossMissionStarNum(int index)
{
	if(index < 0 || index > DAILY_BOSS_MAX_NUM)
		return 0xff;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return m_bossMissionStar[index-1];
}

uint8 CUser::GetBossMissionTotolStarNum()
{
//	boost::recursive_mutex::scoped_lock lk(m_mutex);
	uint8 num = 0;
	for(uint8 i=0;i < DAILY_BOSS_MAX_NUM;i++)
		num += m_bossMissionStar[i];
	return num;
}

const char *CUser::GetBossMissionStarInfo()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	static char buf[64] = {0};
	uint8 pos = 0;
	for(uint8 i = 0; i < sizeof(m_bossMissionStar)/sizeof(m_bossMissionStar[0]); i++)
	{
		buf[pos++] = '0' + (char)m_bossMissionStar[i];
		buf[pos++] = '|';
	}
	buf[pos-1] = '\0';
	return buf;
}

void CUser::SetCollect(char *row)
{
	if(row == NULL)
		return;

	boost::recursive_mutex::scoped_lock lk(m_mutex);

	list<SNpcInstance>::iterator i = m_collectList.begin();
	for(; i != m_collectList.end(); i++)
	{
		delete i->pNpc;
		delete i->pHumanData;
		i->pNpc = NULL;
		i->pHumanData = NULL;
	}
	m_collectList.clear();

	char *p[8*20];
	uint8 num = SplitLine(p,8*20,row);

	SNpcInstance npc;
	CNpcManager &npcManager = SingletonNpcManager::instance();

	for(uint8 i = 0; (i+8) <= num; i+=8)
	{
		npc.id = atoi(p[i]);
		npc.sceneId = atoi(p[i+1]);
		npc.x = atoi(p[i+2]);
		npc.y = atoi(p[i+3]);
		npc.timeOut = atoi(p[i+4]);
		SNpcTemplate *pNpc = npcManager.GetNpcTemplate(npc.id);
		if(pNpc == NULL)
			continue;
		npc.pNpc = new SNpcTemplate;
		*(npc.pNpc) = *pNpc;
		npc.pNpc->name = p[i+5];
//		uint32 roleId = atoi(p[i+6]);
		npc.index = atoi(p[i+7]);
		m_collectList.push_back(npc);
	}
}

uint16 CUser::GetOriAd()
{
	char sql[128];
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return 0;
	snprintf(sql,sizeof(sql),"select ad from %s where id = %d",GetUserInfoTab(m_serverId).c_str(),(int)m_userId);
	if(!pDb->Query(sql))
		return 0;
	char** row;
	if ((row = pDb->GetRow()) == NULL)
		return 0;
	return atoi(row[0]);
}

void CUser::SaveData()
{
	m_saveDataTime = GetSysTime();
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb != NULL)
		NoLockSaveData(pDb);
}

void CUser::SaveDataSimple()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
	string sbitset = "";
	GetBitSet(sbitset);
	string sbankitem = "";
	GetBankItem(sbankitem);

	string koera_money_gift = "";
	SaveMoneyGiftBagHuoDongMap(koera_money_gift);
	boost::format fmt("update role_info set bitset='%1%',bank_item='%2%',korea_money_gift='%4%' where id=%3%");
	fmt % sbitset % sbankitem % koera_money_gift % m_roleId;
	pDb->Query(fmt.str().c_str());
}

void CUser::NoLockSaveData(CDatabaseSql *pDb)
{
	if(m_roleId == 0)
		return;
	SingletonCSimpleRoleDataMgr::instance().UpdateLastLoginTime(m_roleId);

	boost::format fmt("update role_info set state=~1&state,sex=%2%,level=%3%,exp=%4%,package='%5%',money=%6%,pet='%7%',title='%8%',hots='%9%',bitset='%10%',"\
		"save_val='%11%',qianneng=%12%,chat_channel=%13%,bank_item='%14%',chat_time=%15%,save_data='%16%',login_time=%17%,"\
		"mount='%18%',zhanDouLi=%19%,bossFightStar='%20%',sg_bitset='%21%',mysteryShop='%22%', zhenfa='%23%',wing='%24%',xiuxian='%25%',"\
		"xianyuan='%26%',kuafu_state='%27%',shenqi='%28%',kuafu_1vs1='%29%',korea_money_gift='%30%',transform='%31%',mission='%32%',clientstring='%33%',"\
		"shenhunShop='%34%',questIds='%35%',find_res='%36%',xunbao='%37%', pet_equip ='%38%',bang_skills ='%39%',guan_qia ='%40%',user_spirit ='%41%',"\
		"user_book='%42%',chou_ka='%43%',blood_fight='%44%',head='%45%',copyData='%46%',model=%47% where id=%1%");

//	int countTime = m_loginTime;
//	int zeroTime = GetSysTime() - GetHour()*60*60 - GetMinute()*60;
//	if (zeroTime > countTime)
//		countTime = zeroTime;
	
	uint32 sumt = GetExtData32(450);
	sumt = sumt + GetSysTime() - entergametime_;
	SetExtData32(450, sumt);

	string pack;
	string pet;
	string mount;
	string hots;
	string bit;
	string shop;
	string bankItem;
	string savaData;
	string petkaijiaStr;
	string bossStarInfo;
	string xiuxianInfo;
	string mysteryShopStr;
//	string yaoshiShopStr;
	string shenhunShopStr;
	string zhenfa;
	string wing;
	string xianyuan;
	string shenqi;
	string kuafu_1vs1;
	string korea_money_gift;
	string transform;
	string mission;
	string clientstring;
	string questIds;
	string findRes;
	string xunbaoString;
	string petEquipStr;
	string bang_skills_str;
	string guan_qia;
	string user_spirit;
	string userBook;
	string chouKa;
	string bloodFight;
	string bpCopyAward;
	
	stringstream saveShort;
	stringstream monsterScript;

	for(int i = 0; i < MAX_SAVE_NUM; i++)
	{
		saveShort<<(int)m_shortArray[i];
		if(i != MAX_SAVE_NUM - 1)
			saveShort<<'|';
	}

	GetPackage(pack);
	GetPet(pet);
	GetMount(mount);
//	WriteHotsAndIgnore(hots);
	GetBitSet(bit);
	GetBankItem(bankItem);
	GetBossMissionStar(bossStarInfo);
	GetXiuXianInfo(xiuxianInfo);
	WriteSaveData(savaData);
	m_shop->SaveData(mysteryShopStr);
//	GetYaoShiData(yaoshiShopStr);
	GetShenhunShopData(shenhunShopStr);
	GetZhenFa(zhenfa);
	GetWing(wing);
	SaveXianYuan(xianyuan);
	SaveNewShenQi(shenqi);
	SaveKuaFu1vs1SaveEnemy(kuafu_1vs1);
//	SaveTransFormCard(transform);
//	GetQunXianDataStr(qunxian);
	m_missList.SaveData(mission);
	GetClientString(clientstring);
	GetQuestionStr(questIds);
	GetFindResource(findRes);
	m_xunBaoManage.SaveMap(xunbaoString);
	m_petEquipMgr.SaveData(petEquipStr);
	GetBangSkill(bang_skills_str);
	GetBangPaiCopyStr(bpCopyAward);
#ifndef KUA_FU
	SaveMoneyGiftBagHuoDongMap(korea_money_gift);
#endif

	string title;
	GetTitleStr(title);
	string sgBitSet;// 阶段目标保存
	GetSGBitSet(sgBitSet);
//	SingletonCRankDataMgr::instance().UserRankTimeOut(this);//排行榜刷新
	m_userGuanQia.SaveData(guan_qia);
	m_userSpirit.SaveData(user_spirit);
	m_userBook->SaveData(userBook);
	m_chouKa->SaveData(chouKa);
	m_bloodFight->SaveData(bloodFight);

	int kfstate = m_kuafuState;
#ifdef KUA_FU
	kfstate = 3;
#endif

	fmt % (int)m_sex	// 2
		% m_level		// 3
		% m_exp			// 4
		% pack			// 5
		% m_money		// 6
		% pet			// 7
		% title			// 8
		% hots			// 9
		% bit			// 10
		% saveShort.str()	// 11
		% m_qianneng	// 12
		% (int)m_chatChannel	// 13
		% bankItem		// 14
		% m_chatTime	// 15
		% savaData		// 16
		% GetSysTime()	// 17
		% mount			// 18
		% m_zhanDouLi	// 19
		% bossStarInfo	// 20
		% sgBitSet		// 21
		% mysteryShopStr	// 22
		% zhenfa		// 23
		% wing			// 24
		% xiuxianInfo	// 25
		% xianyuan		// 26
		% kfstate		// 27
		% shenqi		// 28
		% kuafu_1vs1	// 29
		% korea_money_gift	// 30
		% transform		// 31
		% mission		// 32
		% clientstring	// 33
		% shenhunShopStr	// 34
		% questIds		// 35
		% findRes		// 36
		% xunbaoString	// 37
		% petEquipStr	// 38
		% bang_skills_str	//39
		% guan_qia		// 40
		% user_spirit	// 41
		% userBook		// 42
		% chouKa		// 43
		% bloodFight	// 44
		% (int)m_head	// 45
		% bpCopyAward	// 46
		% (int)m_model	// 47
		% m_roleId		// 1
		;

	if(pDb != NULL)
	{
		pDb->Query(fmt.str().c_str());
	}
}

void CUser::SaveData(CDatabaseSql *pDb,bool lock)
{
	if(pDb == NULL)
		return;

	uint32 mRoleId = GetData32(6);
	if(mRoleId != 0)
	{
		COnlineUser &onlineUser = SingletonOnlineUser::instance();
		ShareUserPtr ptr = onlineUser.GetUserByRoleId(mRoleId);
		CUser *pMarry = ptr.get();
		if(pMarry != NULL)
		{
			int onlineTime = min(GetSysTime() - m_loginTime,GetSysTime()-pMarry->m_loginTime);
			int add = onlineTime/60/30*10;
			if(add > 0)
			{
				SetData32(10,GetData32(10)+add);
				pMarry->SetData32(10,GetData32(10));
			}
		}
	}

	if(lock)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		NoLockSaveData(pDb);
	}
	else
	{
		NoLockSaveData(pDb);
	}
}

void CUser::SaveLoginLog()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
	SaveLoginLog(pDb);
}


void CUser::SaveLoginLog(CDatabaseSql *pDb)
{
	if(pDb == NULL)
		return;
	if(m_roleId == 0)
		return;
	
	char sql[1024];
	char tab[64];
	sockaddr_in addr;
	socklen_t len = sizeof(addr);
	getpeername(m_sock, (sockaddr*)&addr,&len);
	char *ip = inet_ntoa(addr.sin_addr);
	if(ip == NULL)
		return;
	GetLoginLogTab(tab,sizeof(tab));
	snprintf(sql,sizeof(sql),"INSERT INTO %s (role_id,level,login_time,ip,net_info,mac,IMEI,IDFA,ad) VALUES (%u,%d,from_unixtime(%lu),'%s','%s','%s','%s','%s',%u)",
		tab,m_roleId,m_level,m_loginTime,ip,m_netInfo.c_str(),m_mac.c_str(),m_IMEI.c_str(),m_IDFA.c_str(),m_ad);
	pDb->Query(sql);
}

void CUser::GetPetDrawRatio(double &chengRatio,double &zi3Ratio,double &zi2Ratio)
{
	const double cheng[] = {0.0100,0.0139,0.0193,0.0268,0.0373,0.0518,0.0720,0.1000,0.1390,0.1931,0.2683,0.3728,0.5180,0.7197,1.0000};
	const double zi3[] = {0.0200,0.0277,0.0384,0.0532,0.0737,0.1021,0.1415,0.1960,0.2716,0.3763,0.5213,0.7223,1.0007};
	const double zi2[] = {0.0200,0.0277,0.0384,0.0532,0.0737,0.1021,0.1415,0.1960,0.2716,0.3763,0.5213,0.7223,1.0007};

	uint16 chengDarwNum = GetExtData16(40);
	uint16 zi3DarwNum = GetExtData16(41);
	uint16 zi2DarwNum = GetExtData16(42);
	chengRatio = 0.0;
	zi3Ratio = 0.0;
	zi2Ratio = 0.0;
	if(chengDarwNum >= 20)
	{
		if(chengDarwNum < sizeof(cheng)/sizeof(cheng[0]) + 20)
			chengRatio = cheng[chengDarwNum-20];
		else
			chengRatio = cheng[sizeof(cheng)/sizeof(cheng[0]) - 1];
	}
	if(zi3DarwNum >= 12)
	{
		if(zi3DarwNum < sizeof(zi3)/sizeof(zi3[0]) + 12)
			zi3Ratio = zi3[zi3DarwNum - 12];
		else
			zi3Ratio = zi3[sizeof(zi3)/sizeof(zi3[0]) - 1];
	}
	if(zi2DarwNum >= 5)
	{
		if(zi2DarwNum < sizeof(zi2)/sizeof(zi2[0]) + 5)
			zi2Ratio = zi2[zi2DarwNum - 5];
		else
			zi2Ratio = zi2[sizeof(zi2)/sizeof(zi2[0]) - 1];
	}
}

// type 1 橙神将 2 紫3神将 3 紫2神将
void CUser::SetPetDrawRatio(bool drawSpecPet,uint8 type)
{
	if(!drawSpecPet)	// 未中紫2及以上神将
	{
		SetExtData16(40,GetExtData16(40)+1);
		SetExtData16(41,GetExtData16(41)+1);
		SetExtData16(42,GetExtData16(42)+1);
	}
	else	// 抽到紫2及以上神将
	{
		if(type == 1)	// 橙神将
		{
			SetExtData16(40,0);
			SetExtData16(41,GetExtData16(41)+1);
			SetExtData16(42,GetExtData16(42)+1);
		}
		else if(type == 2)	// 紫3神将
		{
			SetExtData16(40,GetExtData16(40)+1);
			SetExtData16(41,0);
			SetExtData16(42,GetExtData16(42)+1);
		}
		else if(type == 3)	// 紫2神将
		{
			SetExtData16(40,GetExtData16(40)+1);
			SetExtData16(41,GetExtData16(41)+1);
			SetExtData16(42,0);
		}
	}
}

bool CUser::ModifyPetName(uint16 petId,string &name,string &errMsg)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	SPet *pPet = NoLockGetPet(petId).get();
	if(pPet == NULL)
	{
		errMsg = LANGUAGE_TRANSFORM_2307;
		return false;
	}
	if(pPet->level < 35)
	{
		errMsg = LANGUAGE_TRANSFORM_2308;
		return false;
	}
	pPet->name = name;
	return true;
}

void CUser::SetSaveVal(uint8 index,int val)
{
	if(index < MAX_SAVE_NUM - 1)
		m_shortArray[index] = val;
}

int CUser::GetSaveVal(uint8 index)
{
	if(index < MAX_SAVE_NUM - 1)
		return m_shortArray[index];
	return 0;
}

void CUser::SetSaveVal(char *msg)
{
	if(msg == NULL)
		return;
	char *p[MAX_SAVE_NUM] = {NULL};
	SplitLine(p,MAX_SAVE_NUM,msg);
	for(int i = 0; i < MAX_SAVE_NUM; i++)
	{
		if(p[i] == NULL)
			m_shortArray[i] = 0;
		else
			m_shortArray[i] = atoi(p[i]);
	}
}

// 通知客户端主动请求更新数据
// type 1 活动次数(界面显示更新)
void CUser::NoticeClientToQueryNewData(uint8 type)
{
	CNetMessage msg;
	msg.SetType(MSG_NOTICE_TO_UPDATE_CLIENTDATA);
	msg<<type;
	CSocketServer &sock = SingletonSocket::instance();
	sock.SendMsg(m_sock,msg);
}

void CUser::ClearFuBenData()
{
	for(int i=201;i <= 210;i++)
		SetExtData8(i,0);
	SetExtData32(201,0);
	SetExtData32(202,0);
	SetExtData32(203,0);
}

void CUser::ClearDataEveryWeek()
{
	// 活跃度
	SetExtData32(EData32_HuoYueDu_Week, 0);
	// 帮派副本领奖信息
	m_bpCopyAward.clear();

	SetExtData8(84, 0); // 每周5倍经验丹使用次数
	SetExtData8(616, 0); // 每周师门任务次数
	SetExtData8(619, 0);
	SetData32(5,0);	// 帮贡
	SetData16(3,0);	// 3世界大战积分

	SetKuaFu1vs1PreliminaryChallengueCDTime(0);	//跨服1vs1预赛CD
	SetKuaFu1vs1PreliminarySortID(0);			//跨服1vs1预赛分组ID
}

void CUser::ResetQunXianData()
{
	SetExtData16(58,0);
	SetExtData16(59,0);
	SetExtData32(357,0);
	SetExtData32(358,0);
	SetExtData32(359,0);
	SetExtData32(360,0);
	SetExtData32(361,0);
	SetExtData32(362,0);
	SetExtData8(489,0);
	SetExtData8(490,0);
	ClearBitSet(570);
	ClearBitSet(578);
	memset(m_qx_petlist,0,sizeof(m_qx_petlist));
	memset(m_qx_chuzhan,0,sizeof(m_qx_chuzhan));
	for(uint8 i=0;i < sizeof(m_qx_hpRatio)/sizeof(m_qx_hpRatio[0]);i++)
		m_qx_hpRatio[i] = 10000;
	memset(m_qx_addAttrPercent,0,sizeof(m_qx_addAttrPercent));
	memset(m_qx_addAttrVal,0,sizeof(m_qx_addAttrVal));
	m_qx_dieFlag = 0;
}

void CUser::ClearDataEveryDay()
{
	// 资源找回
	CalculateFindResource();

	// 好友领取奖励次数
	SetExtData8(EData8_GetFriendGift, 0);

	// 帮派副本
	SetExtData8(EData8_BPCopyNum, 0);

	// 活跃度
	SetExtData32(EData32_HuoYueDu_Day, 0);

	// 每日帮战首次进入标记
	ClearBitSet(621);
	// 每日礼盒使用表记
	ClearBitSet(625);
	// 清理日常活动数据
	// 师门任务
	if(HaveCMission(101))
	{
		SetSaveVal(3,1);	// 师门任务跨天标识
	}
	else
	{
		SetSaveVal(2,0);	// 师门任务次数
		SetSaveVal(3,0);	// 师门任务跨天标识
	}

	if (HaveCMission(106))
	{
		SetExtData8(617, 1);	// 周师门任务跨周标识
	}
	else
	{
		SetExtData8(616, 0);	// 周师门任务次数
		SetExtData8(617, 0);	// 周师门任务跨周标识
	}

	if(GetExtData32(110) > GetExtData32(111))		// 前一天最高战斗力
		SetExtData32(111,GetExtData32(110));
	// 蘑菇每日首充
	ClearBitSet(601);
	ClearBitSet(602);
	SetExtData8(589,0);
	SetExtData8(590,0);

	// 帮派上仙礼包兑换标记
	SetExtData32(438,0);
	
	// 重置跨服任务标志
	for(int i=801;i <= 805;i++)
		ClearBitSet(i);

	// 组队昆仑山
	SetExtData16(55,0);
	SetExtData16(56,0);
	SetExtData16(57,0);
	SetExtData32(292,0);

	// 跨服1V1
	SetExtData32(295,0);

	// 群仙争霸
	SetExtData8(485,0);
	SetExtData8(487,GetExtData8(486));
	SetExtData8(486,0);
	ResetQunXianData();

	// 婚礼真爱表白记录
	SetExtData8(491,0);
	SetExtData8(492,0);
	SetExtData8(493,0);
	SetExtData32(364,0);
	SetExtData8(494,0);
	
	SetData8(9,0);		// 通缉任务次数
	SetData16(1,0);		// 比赛积分
	SetData8(1,0);		// 比赛次数(擂台赛，跨服战...)

	SetExtData8(4,0);	// 帮派每日领取俸禄次数
//	ClearBitSet(91);	// 每日双倍
	ClearBitSet(92);	// 幻灭前哨
	ClearBitSet(93);	// 奇袭鬼域
	SetExtData8(7,0);	// 每日系统双倍次数

	SetExtData8(60,0);	// 镶嵌保留较高属性次数
	SetExtData8(61,0);	// 通天塔每天重置次数
	ClearBitSet(186);	// 通天塔 是否刚刚进入过 进入次数特殊处理
	SetExtData8(68,0);	// 通天塔每日扫荡次数
	SetExtData16(33,0);	// 昆仑山杀怪数
	SetExtData16(31,0);	// 昆仑山历险点
	SetExtData16(32,0);	// 昆仑山杀人数
	SetExtData16(43,0);	// 昆仑山连胜次数
	ClearBitSet(215);	// 每日第一次进入昆仑山
	SetExtData16(34,0);	// 每日快速战斗次数
	SetExtData8(69,0);	// 每日灵气捐献次数
	SetExtData8(72,0);	// 每日普通抽神将次数
	SetExtData8(73,0);	// 积分任务次数
	SetExtData8(74, 0);	// 伏妖镇魔次数20
	if (GetExtData8(75) < 8)
		SetExtData8(75, GetExtData8(75) + 1);	// 七日登陆次数
	SetExtData32(96,0);	// 每天杀野怪计数
	SetExtData32(98,0);	// 每日在线时间

	SetExtData8(78,0);	// 护送任务当前任务品质
	SetExtData8(79,0);	// 护送任务每天抢夺次数
	SetExtData8(81,0);	// 护送任务每天接取次数
	SetExtData8(82,0);	// 灵气捐献每天获取坐骑强化石数量12

	SetExtData8(76,0); // 开服活动 在线领好礼 重置
	SetExtData16(35,GetExtData16(35)+1); // 开服活动 活跃天数
	ClearBitSet(183); // 开服活动 每日工资是否已经领取
	//ClearBitSet(190); // 开服活动 连续登陆奖励 当天是否已经领取


	SetExtData8(83,0);	// 每日重置5倍经验丹使用次数
	SetExtData16(22,0);	// 每天交易次数限制

	// 多人闯关活动重置
	ClearBitSet(180);
	SetExtData8(21,0);
	SetExtData8(22,0);
	SetExtData8(94,0);

	// 每日活跃度
	ClearBitSet(160); // 每日活跃度 25礼包领取
	ClearBitSet(161); // 每日活跃度 50礼包领取
	ClearBitSet(162); // 每日活跃度 75礼包领取
	ClearBitSet(163); // 每日活跃度 90礼包领取
	ClearBitSet(164); // 每日活跃度 100礼包领取
	ClearBitSet(165); // 每日活跃度 饰品/炼化石合成
	ClearBitSet(166); // 每日活跃度 持续在线30分钟
	ClearBitSet(167); // 每日活跃度 组队副本
	ClearBitSet(168); // 每日活跃度 离线经验
	ClearBitSet(169); // 每日活跃度 参加钓鱼
	ClearBitSet(170); // 每日活跃度 商城消费
	ClearBitSet(181); // 每日活跃度 百花仙子
	ClearBitSet(201); // 每日活跃度 年兽
	SetExtData8(14,0); // 每日活跃度 通关副本次数
	SetExtData8(15,0); // 每日活跃度 强化装备次数
	SetExtData8(16,0); // 每日活跃度 鉴定蓝水晶次数
	SetExtData8(17,0); // 每日活跃度 装备洗练次数
	SetExtData8(18,0); // 每日活跃度 神将归元次数
	SetExtData8(20,0); // 每日活跃度 坐骑强化次数
	SetExtData16(29,0); // 每日活跃度 累计在线时间 分钟
	SetExtData16(30,0); // 每日活跃度 除魔卫道 杀怪数
	SetExtData8(86,0); // 每日活跃度 每日神将寻访次数 记录上限250
	SetExtData8(87,0); // 每日活跃度 小项完成次数 记录上限250

	// 钓鱼相关
	SetExtData8(63,0); // 钓鱼 抢夺他人次数
	SetExtData8(64,0); // 钓鱼 被成功抢夺次数
	SetExtData8(65,0); // 钓鱼 抢夺他人的鱼篓的目标索引

	// 魔道2 副本
	for (int i = 9; i <= 13; ++i)
		SetExtData8(i,0);

	// 魔道2 答题
	SetExtData8(ED8_6,0);
	SetExtData8(ED8_35,0);
	SetExtData32(ED32_6,0);
	//SetExtData32(7,0);
	SetExtData8(ED8_683, 0);

	// 魔道2 日常副本
	SetExtData8(24,0);	// 强化副本
	SetExtData8(25,0);	// 神将副本
	SetExtData8(28,0);	// 金币副本
	SetExtData8(33,0);	// 升阶副本
	SetExtData8(34,0);	// 潜能副本
	SetExtData8(98,0);	// 镶嵌副本
	SetExtData8(99,0);	// 洗炼副本
	SetExtData8(100,0);	// 神将铠副本

	// 押镖
	SetExtData8(88,0);
	SetExtData8(89,0);
	SetExtData8(90,0);

	// 猜拳
	SetExtData8(38,0); // 清空当天猜拳次数

	// 帮战行动力
	//SetExtData16(7,1500);
	SetExtData32(90,0);

	// 帮派个人活跃度领奖记录
	m_bpHuoYueAward.clear();

	// vip 体力恢复次数
	SetExtData8(71,0);
	// 擂台赛参加标记
	ClearBitSet(199);

	// 丹园维护
	SetExtData8(101,0);

	// 修仙
	memset(m_xiuxian,0,sizeof(m_xiuxian));
	SetExtData16(53,0);

	//add by zhudaolong
	//藏宝图
	SetExtData8(608,0);
	
	ClearBitSet(198);
	ClearBitSet(301); // 每日第一次进入昆仑山
	ClearBitSet(303); // 每日是否参与过灵魔战斗


	// 杀敌取宝,重置任务214
	SetExtData16(39,0);

	// 百花碎片掉落计数
	SetExtData8(103,0);
	SetExtData8(104,0);
	SetExtData8(105,0);
	SetExtData8(106,0);
	SetExtData8(107,0);

	// vip玩家每日领取元宝重置
	SetExtData8(121,0);	// 捉鬼扫荡
	SetExtData8(108,0);
	ClearBitSet(347);
	UpdateVipInfo();
	SetExtData8(109,0);	// 购买boss挑战次数
	ClearArenaBuyNum();

	// 帮派种植相关
	SetExtData8(111,0);
	SetExtData8(112,0);
	SetExtData8(113,0);
	SetExtData8(143,0);
	SetExtData8(642,0);

	SetExtData8(114,0);
	SetExtData8(115,0);
	SetExtData8(116,0);
	SetExtData8(117,0);
	SetExtData8(118,0);
	for(uint8 i=0;i < 10;i++)
		SetExtData8(221+i,0);
	SetExtData8(591,0);
	SetExtData8(592,0);
	SetExtData8(593,0);
	SetExtData8(594,0);
	SetExtData32(439,0);
	
	SetExtData32(440,0);
	SetExtData32(441,0);

	ClearBitSet(349);	// 不同位阶每日奖励领取
	ClearBitSet(401);	// 种植任务奖励
	ClearBitSet(402);	// 浇水任务奖励
	ClearBitSet(403);	// 除虫任务奖励
	ClearBitSet(404);	// 偷窃任务奖励
	ClearBitSet(405);	// 杀人任务奖励
	for(uint32 i=411;i <= 432;i++)
		ClearBitSet(i);

	for(uint32 i=565;i <= 576;i++)
	{
		if (i != 566 || i != 569 || i != 570)  // bitset 不连续
			ClearBitSet(i);	// 微信分享奖励
	}

	// 清空藏宝图活动数据
	SetExtData8(134,0);
	SetExtData16(45,0);
	SetExtData16(46,0);
	SetExtData16(47,0);
	SetExtData32(444,0);  // 每日挖宝次数
	SetExtData32(445,0);  // 每日藏宝图使用次数
	SetExtData32(447,0);  // 每日获得的藏宝图数量 低级图
	SetExtData32(448,0);  // 每日获得的藏宝图数量 高级图
	DelCMission(MISSION_ID_XunBao);     // 清理挖宝任务
	DelAllNpc(this, MISSION_NPC_XunBao);
	SetExtData32(449,0);  // 每日购买筛子次数
	//SetExtData32(450,0);  // 清理每日在线时间累积清理
	//SetExtData32(451,0);  // 清理每日在线奖励领奖状态
	SetExtData32(452,0);  // 奖励倒计时记录

	// 捉鬼任务轮次
	SetExtData16(48,0);
	SetExtData16(50,0);
	// 巡察使击杀记录清0
	SetExtData32(116,0);

	// 每日签到
	ClearBitSet(504);

	// 摇钱树
	SetExtData8(377,0);
	SetExtData8(378,0);

	// 封神试炼
	SetExtData8(478,0);
	SetExtData8(479,0);
	SetExtData8(480,0);
	SetExtData8(481,0);
	
	// 矿产数据清空
	for(uint8 type=EUMT_Money;type < EUMT_MAX;type++)
	{
		SetExtData8(251+type,0);	// 领取产出序号
		SetExtData32(251+type,(uint32)GetSysTime());	// 矿领取时间
	}
	SetExtData8(122,0);	// 日常寻神将次数
	SetExtData8(123,0);	// 日常劫镖次数
	
	for(int i=291;i <= 293;i++)	// 寻神将副本进入次数重置
		SetExtData8(i,0);
	SetExtData8(133,0);	// 天书副本

	for(int i=301;i <= 312;i++)	// 副本金币,元宝进入次数重置
		SetExtData8(i,0);

	for(int i=357;i <= 375;i++)	// 兑换豪礼掉落道具数量
		SetExtData8(i,0);
	SetExtData16(49,0);

	for(int i=389;i <= 408;i++)	// 节日活动掉落道具数量
		SetExtData8(i,0);

	for(int i=448;i <= 467;i++)	// 每日换好礼掉落道具数量
		SetExtData8(i,0);

	for(int i=495;i <= 514;i++)	// 圣诞活动掉落道具数量
		SetExtData8(i,0);

	for(int i=515;i <= 534;i++)	// 新春快乐掉落道具数量
		SetExtData8(i,0);

	for(int i=536;i <= 575;i++)	// 阵营pk(pk1 + pk2)掉落道具数量
		SetExtData8(i,0);

	// 初级神将副本抽神将数据重置
	SetExtData8(95,0);
	SetExtData8(96,0);
	SetExtData8(97,0);
	SetExtData8(132,0);

	// 英勇试炼
	SetExtData8(135,0);
	SetExtData8(136,0);
	SetExtData8(137,0);
	SetExtData8(67,0);
	SetExtData8(469,0);
	ClearShiLianRandAward();
	// 在本帮派击杀人数
	SetExtData8(140,0);

	SetExtData8(436, 0);//特权卡扫荡次数

	ClearBitSet(569);//韩版每天登入礼包

#ifdef KUA_FU
	SetBitSet(562);

	ClearBitSet(603);	// 欢乐盛宴每日礼包领取
#endif
	SetKuaFu1vs1PreliminaryRefreshHeroNum(0);   //跨服1vs1预赛刷新次数
	SetKuaFu1vs1PreliminaryUsedChallengueNum(0);//跨服1vs1预赛挑战用掉的次数
	SetKuaFu1vs1PreliminaryUsedChallengueTotalNum(0);//跨服1vs1预赛挑战累计用掉的次数

	if(GetRegTime() + CShopManager::NEW_USER_DISCOUNT_TIME < (int)GetSysTime())	// 每日特惠
		ClearShopDiscountBuyNum();
	SetExtData8(387,0);	//圣诞树每日奖励领取次数
	SetExtData8(476,0);	//神界秘境精英怪每日奖励次数
	SetExtData8(477,0);	//变身卡道具每日掉落次数

	ClearBitSet(610);	// 境界每日领取俸禄标记

	SetExtData32(391,0);//装备强化（含失败，以1级宝石强化为标准）
	SetExtData32(392,0);//进行装备洗炼
	SetExtData32(394,0);//神将进化值
	SetExtData32(395,0);//羽翼仙灵值
	SetExtData32(396,0);//坐骑强化经验
	SetExtData32(397,0);//站位强化（以1级升星石强化为标准）
	SetExtData32(398,0);//神器经验值
	SetExtData32(399,0);//击杀任意六界使者
	SetExtData32(400,0);//击杀灵魔
	SetExtData32(401,0);//帮派种植任意植物

	SetExtData8(576,0);//使用摇钱树获取金币
	SetExtData8(577,0);//任意先锋令
	SetExtData8(578,0);//紫色先锋令
	SetExtData8(579,0);//橙色先锋令
	SetExtData8(580,0);//紫色神将
	SetExtData8(581,0);//橙色神将
	SetExtData8(582,0);//帮派点火次数
	SetExtData8(583,0);//帮派灭火次数
	SetExtData8(584,0);//竞技场挑战
	SetExtData8(587,0);//每日扫荡副本次数
	SetExtData8(588,0);//每日英勇试炼完成次数

	SetExtData32(403,0);//活跃大使任务刷新任务
	SetExtData8(585,0);//活跃大使任务领取记录
	SetExtData8(586,0);//玩家当前活跃大师任务进度

	ClearBitSet(599);//活跃任务是否已刷新

	SetExtData32(453, 0);  // 英勇试炼匹配目标id
	SetExtData32(454, 0); // 英勇试炼匹配目标职业
	SetExtData32(455, GetExtData32(455) + 1); // 累计登陆天数

	SetExtData32(461, 0);   // 擂台赛时间
	SetExtData8(639, 0);    // 擂台赛次数
	SetExtData16(64, 0);
	m_xunBaoManage.ClearMap(true);
	CNetMessage msg;
	msg.SetType(MSG_CHUANG_GUAN);
	msg << (uint8)CXunBaoManage::ECGOp_Quit;
	SingletonSocket::instance().SendMsg(GetSock(), msg);
	SetExtData8(641, 0);    // 跨服试炼
	DelCMission(MISSION_ID_KuaFuShilian);
	for (int i=251; i<=256;++i)
	{
		// 删除昨天的心魔
		DelNpcScript(this, i);
		UpdateNpcState(this, 250, 1);
		SetExtData32(463, 0);
	}
	ClearBitSet(616);

	//帮派活跃记录
	for (int i=651;i<676;++i)
	{
		SetExtData8(i,0);
	}
	for (int i=435;i<455;++i)
	{
		ClearBitSet(i);
	}
	SetExtData16(67,0);//个人活跃度（日清）	
	HuoYueDataChange();
	uint8 buyRecord = GetExtData8(680);
	if (buyRecord > 0)
	{
		SetExtData8(681, GetExtData8(681) + 1);
		SetExtData8(682, GetExtData8(682) + 1);
	}
	// 体力
	m_userSpirit.FreeSpiritReset();
	m_userGuanQia.ResetGuanQia();
	m_chouKa->ResetChouKa();
	m_bloodFight->NewUserBloodFight();
	if (GetExtData16(ED16_69) < 20)
		SetExtData16(ED16_69, 20);
	SetExtData16(ED16_68, 0);
	SetExtData16(ED16_70, 0);
	SetExtData16(ED16_71, 0);
	SetExtData16(ED16_72, 0);
	m_missList.ResetQuest(this);
	m_shop->ResetShop(this);
}

void CUser::HuoYueDataChange()
{
	if (!HaveBitSet(627))
	{
		SetExtData8(680, GetExtData8(644));
		SetExtData8(681, GetExtData8(645));
		SetExtData8(682, GetExtData8(646));
		SetBitSet(627);
	}
}

void CUser::DoTaskEveryDay() // 每天第一次上线调用一次
{
	ResetChuangGuanNotify(); // 重置闯关通知
	CheckDengLuLiBao(); // 登陆礼包处理
}

void CUser::UpdateShopPetDrawState()
{
/*
	if(m_level <= 14)
		return;

	uint32 curTime = GetSysTime();
	bool show = false;
//	if(GetExtData32(92) <= curTime)
//	{
//		if(GetExtData8(72) < 5)
//			show = true;
//	}
	if(GetExtData32(93) <= curTime)
		show = true;
	else if(GetExtData32(94) <= curTime)
		show = true;
*/
//	SendShopCanDrawPetInfo(show);
}

void CUser::TimeOutUpdateUserData()
{
	int day = GetYDay();
	if(day < 0)
		return;

	if (!HaveBitSet(1515))
	{
		SetExtData32(568, 0);
		SetExtData32(569, 0);
		SetBitSet(1515);			// 标记位计算错误bug处理
	}

	UpdateShopPetDrawState();
	m_userSpirit.CheckAddSpirit(this);
	m_petEquipMgr.CheckCnt(this);
	m_shop->CheckShopFreeCnt(this);
	m_xunBaoManage.YouLiAwardCheck();
	time_t endTime = GetExtData32(1);
	if((endTime != 0) && (endTime < GetSysTime()))
	{
		SetExtData32(1,0);
	}
	endTime = GetExtData32(2);
	if((endTime != 0) && (endTime < GetSysTime()))
	{
		SetExtData32(2,0);
	}

#ifndef KUA_FU
	HuoDongClearDataTimeOut();

	if (HaveBitSet(562) || m_shortArray[MAX_SAVE_NUM-2] != (uint32)day)
	{
		HuoDongClearDataEveryDay();
		ClearBitSet(562);
	}
#else
	HuanLeShengYanClearData();
#endif

	if(m_shortArray[MAX_SAVE_NUM-2] != (uint32)day)
	{
		SetBitSet(806);
		ClearDataEveryDay();
		DoTaskEveryDay();
		Send_HuoDongMsg();
		NoticeClientToQueryNewData(1);
		m_shortArray[MAX_SAVE_NUM-2] = day;
		InitAndUpdate();
	}

	if(m_shortArray[MAX_SAVE_NUM-1] < (uint32)GetClearWeekTime())
	{
		ClearDataEveryWeek();
		m_shortArray[MAX_SAVE_NUM-1] = (uint32)GetClearWeekTime();
	}

	uint32 monthTime = GetExtData32(100);
	if(monthTime < (uint32)GetClearMonthTime())
	{
		// 每月签到天数累计
		SetExtData8(62,0);

		SetExtData32(100,(uint32)GetClearMonthTime());
	}

#ifndef KUA_FU
	if(m_loginHuoYueSign)
	{
	    UpdateBangHuoYue(EBHT_Login);
	    m_loginHuoYueSign = false;
	}
#endif
}

void CUser::SendXianShiChouAward()
{
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 huodong_type = CHuoDongAwardManager::XIANSHI_CHOU;

	const uint32 curScoreDataId = 299;
	const uint32 getMaskDataId = 300;
	const uint32 jifen_idx2 = 2;

	vector<uint32> idxList;			
	awardManager.GetAwardIdxList(huodong_type,jifen_idx2,idxList);
	if(!idxList.empty())
	{
		uint32 totalScore = GetExtData32(curScoreDataId);
		uint32 getMask = GetExtData32(getMaskDataId);

		for (uint32 i = 0; i < idxList.size(); i++)
		{
			SHuoDongAward award;
			awardManager.GetAwardData(huodong_type,idxList[i],award);

			uint8 state = 1;
			if (totalScore >= award.needYB)
				state = 2;

			uint8 getState = ((getMask&(1<<award.idx3)) == 0) ? (uint8)0 : (uint8)1;
			if (getState == 1)
				state = 3;

			if (state == 2)
			{
				char buf[255];
				snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_2309,awardManager.GetHuoDongName(huodong_type).c_str());
				SendHuoDongAwardMail(m_roleId,m_level,award,buf,huodong_type);
			}	
		}
	}
}

void CUser::XianShiChouClearData()
{
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 huodong_type = CHuoDongAwardManager::XIANSHI_CHOU;
	
	const uint32 startTimeDataId = 297;
	const uint32 lastTimeDataId = 298;
	const uint32 curScoreDataId = 299;
	const uint32 getMaskDataId = 300;
		
	if(awardManager.InHuoDongTime(huodong_type))
	{
		uint32 cz_time = awardManager.GetHuoDongStartTime(huodong_type);
		if(cz_time != GetExtData32(startTimeDataId))
		{
			// 发送奖励
			SendXianShiChouAward();
			SetExtData32(startTimeDataId,cz_time);
			SetExtData32(lastTimeDataId,0);
			SetExtData32(curScoreDataId,0);
			SetExtData32(getMaskDataId,0);
		}
	}
	else
	{
		if(GetExtData32(startTimeDataId) > 0)
		{
			// 发送奖励
			SendXianShiChouAward();
			SetExtData32(startTimeDataId,0);
			SetExtData32(lastTimeDataId,0);
			SetExtData32(curScoreDataId,0);
			SetExtData32(getMaskDataId,0);
		}
	}
}

void CUser::ChongZhiBangClearData()
{
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 huodong_type = CHuoDongAwardManager::CHONG_ZHI_BANG;
	if (awardManager.InHuoDongTime(huodong_type))
	{
		uint32 xf_time = awardManager.GetHuoDongStartTime(huodong_type);
		if(xf_time != GetExtData32(125))
		{
			SetExtData32(125, xf_time);
			SetExtData32(126,0);
		}
	}
	else if (GetExtData32(125) > 0)
	{
		SetExtData32(125,0);
		SetExtData32(126,0);
	}
}

void CUser::SendLeiJiChongZhiAward(uint32 huodongType)
{
	if (huodongType != CHuoDongAwardManager::LEI_JI_CHONGZHI && huodongType != CHuoDongAwardManager::LEI_JI_CHONGZHI2)
		return;

	uint32 totalCZDataId = 119;
	uint32 maskDataId = 121;
	if (huodongType == CHuoDongAwardManager::LEI_JI_CHONGZHI2)
	{
		totalCZDataId = 137;
		maskDataId = 139;
	}

	vector<uint32> idxList;			
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	awardManager.GetAwardIdxList(huodongType,idxList);
	if(!idxList.empty())
	{
		uint32 totalChongZhi = GetExtData32(totalCZDataId);
		uint32 getMask = GetExtData32(maskDataId);
		uint8 num = idxList.size();
		if(num > 32)
			num = 32;
		for(uint8 i=0;i < num;i++)
		{
			SHuoDongAward award;
			uint8 isGet = ((getMask&(1<<i)) == 0) ? (uint8)0 : (uint8)1;
			if(isGet == 0)	// 未领取
			{
				uint32 needYB = awardManager.GetNeedYB(huodongType,idxList[i]);
				awardManager.GetAwardData(huodongType,idxList[i],award);
				if(totalChongZhi >= needYB)
				{
					char buf[255];
					snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_2309,awardManager.GetHuoDongName(huodongType).c_str());
					SendHuoDongAwardMail(m_roleId,m_level,award,buf,huodongType);
				}
			}
		}
	}
}

void CUser::HuoDongClearDataTimeOut()
{
	LeiJiChongZhiClearData(CHuoDongAwardManager::LEI_JI_CHONGZHI);
	LeiJiChongZhiClearData(CHuoDongAwardManager::LEI_JI_CHONGZHI2);
	LeiJiXiaoFeiClearData(CHuoDongAwardManager::LEI_JI_XIAOFEI);
	LeiJiXiaoFeiClearData(CHuoDongAwardManager::LEI_JI_XIAOFEI2);
		//红利大返送
	HongLiClearData(CHuoDongAwardManager::HONGLI_CHONGZHI);
	HongLiClearData(CHuoDongAwardManager::HONGLI_CHONGZHI2);
	HongLiClearData(CHuoDongAwardManager::HONGLI_CHONGZHI3);
	HongLiClearData(CHuoDongAwardManager::HONGLI_CHONGZHI4);
	HongLiClearData(CHuoDongAwardManager::HONGLI_CHONGZHI5);
	
	HongLiClearData(CHuoDongAwardManager::HONGLI_CHONGZHI_RMB);
	
	HongLiClearData(CHuoDongAwardManager::HONGLI_XIAOFEI);
	HongLiClearData(CHuoDongAwardManager::HONGLI_XIAOFEI2);
	HongLiClearData(CHuoDongAwardManager::HONGLI_XIAOFEI3);
	HongLiClearData(CHuoDongAwardManager::HONGLI_XIAOFEI4);
	HongLiClearData(CHuoDongAwardManager::HONGLI_XIAOFEI5);

	// 红利积分
	HongLiJiFenClearData(CHuoDongAwardManager::HONGLI_JIFEN);
	HongLiJiFenClearData(CHuoDongAwardManager::HONGLI_JIFEN2);
	HongLiJiFenClearData(CHuoDongAwardManager::HONGLI_JIFEN3);
	HongLiJiFenClearData(CHuoDongAwardManager::HONGLI_JIFEN4);
	HongLiJiFenClearData(CHuoDongAwardManager::HONGLI_JIFEN5);

	FestivalClearData();

	QinaghuaKuanghuanClearData();
	ShengjieLetianClearData();
	LianXuChongZhiClearData(CHuoDongAwardManager::LIANXU_CHONGZHI_ORI);
	LianXuChongZhiClearData(CHuoDongAwardManager::LIANXU_CHONGZHI_DELUXE);

	ChongZhiBangClearData();
	XianShiChouClearData();

	ChristmasTreeClearData();
	XinChunHappyClearData();

	ZhenYingPKClearData();

	QiangHongBaoClearData();
	MoGuClearData();
	HuoyueJijinClearData();
}
void CUser::HuoDongClearDataEveryDay()
{
	// 每日首充发邮件
	MeiRiShouChongClearData();
	//单日累计充值返利
	ChongZhiFanYBClearData(CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO);
	ChongZhiFanYBClearData(CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO2);
	ChongZhiFanYBClearData(CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO3);
	ChongZhiFanYBClearData(CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO4);
	ChongZhiFanYBClearData(CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO5);
	ChongZhiFanYBClearData(CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO6);
	ChongZhiFanYBClearData(CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO7);
	ChongZhiFanYBClearData(CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO8);
	ChongZhiFanYBClearData(CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO9);
	ChongZhiFanYBClearData(CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO10);

	LianXuChongZhiClearData(CHuoDongAwardManager::LIANXU_CHONGZHI_ORI, true);
	LianXuChongZhiClearData(CHuoDongAwardManager::LIANXU_CHONGZHI_DELUXE, true);

	JijinFanliClearData(CHuoDongAwardManager::JIJIN_FANLI);//基金返利
	JijinFanliClearData(CHuoDongAwardManager::JIJIN_FANLI2);//基金返利2
	JijinFanliClearData(CHuoDongAwardManager::JIJIN_FANLI3);//基金返利3
	MeiRiHuanHaoLiClearData(); //每日换好礼

	MeiRiXiaoFeiClearData(CHuoDongAwardManager::MEIRI_XIAOFEI1);	// 每日消费1
	MeiRiXiaoFeiClearData(CHuoDongAwardManager::MEIRI_XIAOFEI2);	// 每日消费2
	MeiRiXiaoFeiClearData(CHuoDongAwardManager::MEIRI_XIAOFEI3);	// 每日消费3
	MeiRiXiaoFeiClearData(CHuoDongAwardManager::MEIRI_XIAOFEI4);	// 每日消费4
	MeiRiXiaoFeiClearData(CHuoDongAwardManager::MEIRI_XIAOFEI5);	// 每日消费5
	ZhuanPanLiJiFenClearData();
	DailyFanliData();
}

void CUser::ZhuanPanLiJiFenClearData()
{
	CHuoDongAwardManager& hdmgr = SingletonCHuoDongAwardManager::instance();
	if (!hdmgr.InHuoDongTime(CHuoDongAwardManager::ZHA_DAN))
		SetExtData32(12, 0);
	if (!hdmgr.InHuoDongTime(CHuoDongAwardManager::ZHA_DAN_COPY))
		SetExtData32(468, 0);
}

void CUser::LeiJiChongZhiClearData(uint32 huodongType)
{
	if (huodongType != CHuoDongAwardManager::LEI_JI_CHONGZHI && huodongType != CHuoDongAwardManager::LEI_JI_CHONGZHI2)
		return;

	// 累计充值活动记录处理
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	
	uint32 totalCZDataId = 119;
	uint32 startTimeDataId = 120;
	uint32 maskDataId = 121;
	if (huodongType == CHuoDongAwardManager::LEI_JI_CHONGZHI2)
	{
		totalCZDataId = 137;
		startTimeDataId = 138;
		maskDataId = 139;
	}
	
	if(awardManager.InHuoDongTime(huodongType))
	{
		uint32 cz_time = awardManager.GetHuoDongStartTime(huodongType);
		if (GetExtData32(startTimeDataId) == 0)
		{
			SetExtData32(startTimeDataId,cz_time);
		}	
		else if(cz_time != GetExtData32(startTimeDataId))
		{
			// 发送奖励
			SendLeiJiChongZhiAward(huodongType);
			SetExtData32(startTimeDataId,cz_time);
			SetExtData32(totalCZDataId,0);
			SetExtData32(maskDataId,0);
		}
	}
	else
	{
		if(GetExtData32(startTimeDataId) > 0)
		{
			// 发送奖励
			SendLeiJiChongZhiAward(huodongType);
			SetExtData32(startTimeDataId,0);
			SetExtData32(totalCZDataId,0);
			SetExtData32(maskDataId,0);
		}
	}

}

void CUser::ChristmasTreeClearData()
{
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 huodongType = CHuoDongAwardManager::SHENGDAN_FENGSHOU;
	uint32 startTimeDataId = 368;
	uint32 gongxianDataId = 369;
	uint32 awardChengZhangDataId = 370;

	if(awardManager.InHuoDongTime(huodongType) && awardManager.GetHuoDongPic(huodongType) == CHuoDongAwardManager::CHRISTMAS_TREE_ID)
	{
		uint32 cz_time = awardManager.GetHuoDongStartTime(huodongType);
		if (GetExtData32(startTimeDataId) == 0)
		{
			SetExtData32(startTimeDataId,cz_time);
		}	
		else if(cz_time != GetExtData32(startTimeDataId))
		{
			SetExtData32(startTimeDataId,cz_time);
			SetExtData32(gongxianDataId,0);
			SetExtData32(awardChengZhangDataId,0);
		}
	}
	else
	{
		if(GetExtData32(startTimeDataId) > 0)
		{
			SetExtData32(startTimeDataId,0);
			SetExtData32(gongxianDataId,0);
			SetExtData32(awardChengZhangDataId,0);
		}
	}

}

void CUser::XinChunHappyClearData()
{
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 huodongType = CHuoDongAwardManager::XINCHUN_HAPPY;
	uint32 startTimeDataId = 382;
	uint32 getMaskDataId = 535;
	uint32 zitiDataId[] = {372,373,374,375,376,377,378,379,380};
	uint32 jifenDataId = 381;

	if(awardManager.InHuoDongTime(huodongType))
	{
		uint32 cz_time = awardManager.GetHuoDongStartTime(huodongType);
		if (GetExtData32(startTimeDataId) == 0)
		{
			SetExtData32(startTimeDataId,cz_time);
		}	
		else if(cz_time != GetExtData32(startTimeDataId))
		{
			SetExtData32(startTimeDataId,cz_time);
			SetExtData8(getMaskDataId,0);
			SetExtData32(jifenDataId,0);

			for (uint32 i = 0; i < sizeof(zitiDataId)/sizeof(zitiDataId[0]); i++)
				SetExtData32(zitiDataId[i],0);

			HDClearItem(huodongType);
		}
	}
	else
	{
		if(GetExtData32(startTimeDataId) > 0)
		{
			SetExtData32(startTimeDataId,0);
			SetExtData8(getMaskDataId,0);
			SetExtData32(jifenDataId,0);
			for (uint32 i = 0; i < sizeof(zitiDataId)/sizeof(zitiDataId[0]); i++)
				SetExtData32(zitiDataId[i],0);

			HDClearItem(huodongType);
		}
	}

}

void CUser::ZhenYingPKClearData()
{
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 huodongType = CHuoDongAwardManager::ZHENYING_PK;
	uint32 startTimeDataId = 385;
	uint32 zhenyingDataId = 383;
	uint32 jifenDataId = 384;
	uint32 award1GiveDataId = 386;
	uint32 award1GetDataId = 387;
	uint32 award2GiveDataId = 388;
	uint32 award2GetDataId = 389;

	if(awardManager.InHuoDongTime(huodongType))
	{
		uint32 cz_time = awardManager.GetHuoDongStartTime(huodongType);
		if (GetExtData32(startTimeDataId) == 0)
		{
			SetExtData32(startTimeDataId,cz_time);
		}	
		else if(cz_time != GetExtData32(startTimeDataId))
		{
			SetExtData32(startTimeDataId,cz_time);
			SetExtData32(zhenyingDataId,0);
			SetExtData32(jifenDataId,0);
			SetExtData32(award1GiveDataId,0);
			SetExtData32(award1GetDataId,0);
			SetExtData32(award2GiveDataId,0);
			SetExtData32(award2GetDataId,0);
		}
	}
	else
	{
		if(GetExtData32(startTimeDataId) > 0)
		{
			SetExtData32(startTimeDataId,0);
			SetExtData32(zhenyingDataId,0);
			SetExtData32(jifenDataId,0);
			SetExtData32(award1GiveDataId,0);
			SetExtData32(award1GetDataId,0);
			SetExtData32(award2GiveDataId,0);
			SetExtData32(award2GetDataId,0);
		}
	}
}

void CUser::QiangHongBaoClearData()
{
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 huodongType = CHuoDongAwardManager::QIANG_HONGBAO;
	uint32 startTimeDataId = 405;
	uint32 leijiDataId = 406;
	uint32 isSendHongBaoDataId = 583;

	if(awardManager.InHuoDongTime(huodongType))
	{
		uint32 cz_time = awardManager.GetHuoDongStartTime(huodongType);
		if (GetExtData32(startTimeDataId) == 0)
		{
			SetExtData32(startTimeDataId,cz_time);
		}	
		else if(cz_time != GetExtData32(startTimeDataId))
		{
			SetExtData32(startTimeDataId,cz_time);
			SetExtData32(leijiDataId,0);
			ClearBitSet(isSendHongBaoDataId);
		}
	}
	else
	{
		if(GetExtData32(startTimeDataId) > 0)
		{
			SetExtData32(startTimeDataId,0);
			SetExtData32(leijiDataId,0);
			ClearBitSet(isSendHongBaoDataId);
		}
	}
}


void CUser::SendLeiJiXiaoFeiAward(uint32 huodongType)
{
	if (huodongType != CHuoDongAwardManager::LEI_JI_XIAOFEI&& huodongType != CHuoDongAwardManager::LEI_JI_XIAOFEI2)
		return;

	uint32 totalCZDataId = 122;
	uint32 maskDataId = 124;
	if (huodongType == CHuoDongAwardManager::LEI_JI_XIAOFEI2)
	{
		totalCZDataId = 140;
		maskDataId = 142;
	}

	vector<uint32> idxList;		
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	awardManager.GetAwardIdxList(huodongType,idxList);

	if(!idxList.empty())
	{
		uint32 totalXiaoFei = GetExtData32(totalCZDataId);
		uint32 getMask = GetExtData32(maskDataId);
		uint8 num = idxList.size();
		if(num > 32)
			num = 32;
		for(uint8 i=0;i < num;i++)
		{
			SHuoDongAward award;
			uint8 isGet = ((getMask&(1<<i)) == 0) ? (uint8)0 : (uint8)1;
			if(isGet == 0)	// 未领取
			{
				uint32 needYB = awardManager.GetNeedYB(huodongType,idxList[i]);
				awardManager.GetAwardData(huodongType,idxList[i],award);
				if(totalXiaoFei >= needYB)
				{
					char buf[255];
					snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_2310,awardManager.GetHuoDongName(huodongType).c_str());
					SendHuoDongAwardMail(m_roleId,m_level,award,buf,huodongType);
				}
			}
		}
	}
}

void CUser::LeiJiXiaoFeiClearData(uint32 huodongType)
{
	if (huodongType != CHuoDongAwardManager::LEI_JI_XIAOFEI && huodongType != CHuoDongAwardManager::LEI_JI_XIAOFEI2)
		return;

	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 totalCZDataId = 122;
	uint32 startTimeDataId = 123;
	uint32 maskDataId = 124;
	if (huodongType == CHuoDongAwardManager::LEI_JI_XIAOFEI2)
	{
		totalCZDataId = 140;
		startTimeDataId = 141;
		maskDataId = 142;
	}

	// 累计消费活动记录处理
	if(awardManager.InHuoDongTime(huodongType))
	{
		uint32 xf_time = awardManager.GetHuoDongStartTime(huodongType);
		if (GetExtData32(startTimeDataId) == 0)
		{
			SetExtData32(startTimeDataId,xf_time);
		}
		else if(xf_time != GetExtData32(startTimeDataId))
		{
			// 发送奖励
			SendLeiJiXiaoFeiAward(huodongType);
			SetExtData32(startTimeDataId,xf_time);
			SetExtData32(totalCZDataId,0);
			SetExtData32(maskDataId,0);
		}
	}
	else
	{
		if(GetExtData32(startTimeDataId) > 0)
		{
			// 发送奖励
			SendLeiJiXiaoFeiAward(huodongType);
			SetExtData32(startTimeDataId,0);
			SetExtData32(totalCZDataId,0);
			SetExtData32(maskDataId,0);
		}
	}
}

void CUser::SendMeiRiShouChongAward(bool isWeiXin)
{
	if (isWeiXin)
	{
		uint32 time = GetExtData32(409);
		uint32 day = time & 0xff;
		SHuoDongAward award;
		CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
		awardManager.GetAwardData(CHuoDongAwardManager::MEIRI_SHOUCHONG,day,award);
		for (int i = 0; i < CHuoDongAwardManager::SHOUCHONG_AWARD_NUM; i++)
		{
			award.award[i] = 0;
			award.num[i] = 0;
		}
		SendHuoDongAwardMail(m_roleId,m_level,award,LANGUAGE_LLD_0243,CHuoDongAwardManager::MEIRI_SHOUCHONG);
	}
	else
	{
		uint32 time = GetExtData32(204);
		uint32 year = time >> 16 & 0xffff;
		uint32 mon = time >> 8 & 0xff;
		uint32 day = time & 0xff;
		SHuoDongAward award;
		CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
		awardManager.GetAwardData(CHuoDongAwardManager::MEIRI_SHOUCHONG,day,award);
		char buf[512];
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_2311,year + 1900,mon + 1,day);
		award.award[CHuoDongAwardManager::SHOUCHONG_WEIXIN_IDX - 1] = 0;
		award.num[CHuoDongAwardManager::SHOUCHONG_WEIXIN_IDX - 1] = 0;
		SendHuoDongAwardMail(m_roleId,m_level,award,buf,CHuoDongAwardManager::MEIRI_SHOUCHONG);
	}
}

void CUser::MeiRiShouChongClearData()
{
	if (HaveBitSet(550) || !HaveBitSet(551) || GetExtData32(204) != 0)
	{
		if (HaveBitSet(550) && !HaveBitSet(551) && GetExtData32(204) != 0)
			SendMeiRiShouChongAward();
		
		ClearBitSet(550);
		ClearBitSet(551);
		SetExtData32(204,0);
	}
	if (HaveBitSet(595) || !HaveBitSet(596) || GetExtData32(409) != 0)
	{
		if (HaveBitSet(595) && !HaveBitSet(596) && GetExtData32(409) != 0)
			SendMeiRiShouChongAward(true);
		
		ClearBitSet(595);
		ClearBitSet(596);
		SetExtData32(409,0);
	}
}

void CUser::JieRiLiBaoClearData(uint32 huodongType)
{
	if (huodongType != CHuoDongAwardManager::JIERI_LIBAO && huodongType != CHuoDongAwardManager::JIERI_LIBAO2)
		return;

	uint32 startTimeDataId = 129;
	uint32 blueTimeDataId = 130;
	uint32 purpleTimeDataId = 131;
	uint32 goldTimeDataId = 132;
	uint32 blueGetCount = 380;
	uint32 purpleGetCount = 381;
	uint32 goldGetCount = 382;

	if (huodongType == CHuoDongAwardManager::JIERI_LIBAO2)
	{
		startTimeDataId = 133;
		blueTimeDataId = 134;
		purpleTimeDataId = 135;
		goldTimeDataId = 136;
		blueGetCount = 433;
		purpleGetCount = 434;
		goldGetCount = 435;
	}

	bool isClear = false;
	uint32 xf_time =  SingletonCHuoDongAwardManager::instance().GetHuoDongStartTime(huodongType);
	if(xf_time != GetExtData32(startTimeDataId))
	{
		isClear = true;
		SetExtData32(startTimeDataId,xf_time);
	}
	else
		isClear = false;
	
	if (isClear)
	{
		SetExtData8(blueGetCount,0);
		SetExtData8(purpleGetCount,0);
		SetExtData8(goldGetCount,0);
		SetExtData32(blueTimeDataId,0);
		SetExtData32(purpleTimeDataId,0);
		SetExtData32(goldTimeDataId,0);
	}
}

void CUser::SendMeiRiXiaoFeiMail(uint32 huodongType)
{
	uint32 totalXFDataId = 0;
	uint32 maskDataId = 0;
	if(!GetMeiRiXiaoFeiYBDataId(huodongType,totalXFDataId,maskDataId))
		return;

	vector<uint32> idxList;
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	awardManager.GetAwardIdxList(huodongType,idxList);
	if(!idxList.empty())
	{
		uint32 totalXF = GetExtData32(totalXFDataId);
		uint32 getMask = GetExtData32(maskDataId);
		uint8 num = idxList.size();
		
		if(num > 32)
			num = 32;
		for(uint8 i=0;i < num;i++)
		{
			SHuoDongAward award;
			uint8 isGet = ((getMask&(1<<i)) == 0) ? (uint8)0 : (uint8)1;
			if(isGet == 0)	// 未领取
			{
				uint32 needYB = awardManager.GetNeedYB(huodongType,idxList[i]);
				awardManager.GetAwardData(huodongType,idxList[i],award);
				if(totalXF >= needYB)
				{
					char buf[255];
					snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_2312,awardManager.GetHuoDongName(huodongType).c_str());
					SendHuoDongAwardMail(GetRoleId(), GetLevel(), award, buf,huodongType);
					getMask |= 1<<i;
				}
			}
		}
	}
}

int CUser::GetMoGuCZ()
{
	return GetExtData32(433);
}

void CUser::SetMoGuCZ(int cz)
{
	SetExtData32(433,cz);
}

int CUser::GetMoGuWaterTimes()
{
	const int WATER_LIMIT = 1;
	int left = WATER_LIMIT - (int)GetExtData8(589);
	if(left < 0)
		left = 0;
	return left;
}

void CUser::DelMoGuWaterTimes()
{
	SetExtData8(589,GetExtData8(589)+1);
}

int CUser::GetMoGuBugTimes()
{
	int left = (int)(HaveBitSet(601) ? 1 : 0) - (int)GetExtData8(590);
	if(left < 0)
		left = 0;
	return left;
}

void CUser::DelMoGuBugTimes()
{
	SetExtData8(590,GetExtData8(590)+1);
}


void CUser::SendChongZhiFanYBMail(uint32 huodongType)
{
	uint32 totalCZDataId = 0;
	uint32 maskDataId = 0;
	
	if ( ! GetChongZhiFanYBDataId(huodongType,totalCZDataId,maskDataId) )
		return;
				
	vector<uint32> idxList;		
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	awardManager.GetAwardIdxList(huodongType,idxList);
	if(!idxList.empty())
	{
		uint32 totalChongZhi = GetExtData32(totalCZDataId);
		uint32 getMask = GetExtData32(maskDataId);
		uint8 num = idxList.size();
		
		if(num > 32)
			num = 32;
		for(uint8 i=0;i < num;i++)
		{
			SHuoDongAward award;
			uint8 isGet = ((getMask&(1<<i)) == 0) ? (uint8)0 : (uint8)1;
			if(isGet == 0)	// 未领取
			{
				uint32 needYB = awardManager.GetNeedYB(huodongType,idxList[i]);
				awardManager.GetAwardData(huodongType,idxList[i],award);
				if(totalChongZhi >= needYB)
				{
					char buf[255];
					snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_2312,awardManager.GetHuoDongName(huodongType).c_str());
					SendHuoDongAwardMail(GetRoleId(), GetLevel(), award, buf,huodongType);
					getMask |= 1<<i;
				}
			}
		}
	}
/*	
	if (YB > 0)
	{
		SMailData mdata;
		mdata.YB = YB;
		char buf[255];
		snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_2312,awardManager.GetHuoDongName(huodongType).c_str(),YB);
		buf[254] = '\0';
		SendSystemMail(GetRoleId(),buf,&mdata);
	}
*/
}

void CUser::MeiRiXiaoFeiClearData(uint32 huodongType)
{
	uint32 totalXFDataId = 0;
	uint32 maskDataId = 0;
	if(!GetMeiRiXiaoFeiYBDataId(huodongType,totalXFDataId,maskDataId))
		return;
	if(GetExtData32(totalXFDataId) > 0)
	{
		SendMeiRiXiaoFeiMail(huodongType);
		SetExtData32(totalXFDataId,0);
		SetExtData32(maskDataId,0);
	}
}


void CUser::ChongZhiFanYBClearData(uint32 huodongType)
{
	uint32 totalCZDataId = 0;
	uint32 maskDataId = 0;
	
	if ( ! GetChongZhiFanYBDataId(huodongType,totalCZDataId,maskDataId) )
		return;

	if(GetExtData32(totalCZDataId) > 0)
	{
		SendChongZhiFanYBMail(huodongType);
		SetExtData32(totalCZDataId,0);
		SetExtData32(maskDataId,0);
	}
}

void CUser::HongLiClearData(uint32 type)
{
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 sTimeDataId = 0;
	uint32 leijiDataId = 0;
	uint32 maskDataId = 0;

	if (!GetHongLiDataId(type,sTimeDataId,leijiDataId,maskDataId))
		return;

	if (awardManager.InHuoDongTime(type))
	{
		uint32 xf_time = awardManager.GetHuoDongStartTime(type);
		if(xf_time != GetExtData32(sTimeDataId))
		{
			SetExtData32(leijiDataId,0);
			SetExtData32(maskDataId,0);
			SetExtData32(sTimeDataId, xf_time);
		}
	}
	else if (GetExtData32(sTimeDataId) > 0)
	{
		SetExtData32(leijiDataId,0);
		SetExtData32(maskDataId,0);
		SetExtData32(sTimeDataId,0);
	}
}

void CUser::HongLiJiFenClearData(uint32 type)
{
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 sTimeDataId = 0;
	uint32 leijiDataId = 0;

	if (!GetHongLiJiFenDataId(type,sTimeDataId,leijiDataId))
		return;

	if (awardManager.InHuoDongTime(type))
	{
		uint32 xf_time = awardManager.GetHuoDongStartTime(type);
		if(xf_time != GetExtData32(sTimeDataId))
		{
			SetExtData32(leijiDataId,0);
			SetExtData32(sTimeDataId, xf_time);
		}
	}
	else if (GetExtData32(sTimeDataId) > 0)
	{
		SetExtData32(leijiDataId,0);
		SetExtData32(sTimeDataId,0);
	}
}

void CUser::MoGuClearData()
{
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	if(!awardManager.InHuoDongTime(CHuoDongAwardManager::MOGU))
	{
		SetExtData32(433,0);
	}
}

void CUser::HuoyueJijinClearData()
{
	HuoYueDataChange();
	uint8 buyRecord = GetExtData8(680);
	uint32 maskDataId;
	uint32 dateId;
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 type = CHuoDongAwardManager::HUOYUE_JIJIN_FANLI;
	if (!awardManager.InHuoDongTime(type))
		return;
	vector<HDPeiZhiInfo> peizhiInfo;
	awardManager.GetPeiZhiInfo(peizhiInfo, type);
	uint32 starTime = awardManager.GetHuoDongStartTime(type);
	uint32 buyTime;
	bool clear = false;
	for (uint32 i = 0; i < peizhiInfo.size(); i++)
	{
		uint8 buyState = ((buyRecord&(1 << peizhiInfo[i].index)) == 0) ? (uint8)0 : (uint8)1;
		if (buyState == 0)
			continue;
		if (peizhiInfo[i].index == 1)
		{
			dateId = 470;
			maskDataId = 471;
		}
		else if (peizhiInfo[i].index == 2)
		{
			dateId = 472;
			maskDataId = 473;
		}
		buyTime = GetExtData32(dateId);
		if (starTime - 24 * 3600 < buyTime)
			continue;
		clear = true;
		vector<uint32> idxList;
		awardManager.GetAwardIdxList(type, peizhiInfo[i].index, idxList);
		uint32 getMask = GetExtData32(maskDataId);

		for (uint32 ai = 0; ai < idxList.size(); ++ai)
		{
			uint8 getState = ((getMask&(1 << (ai + 1))) == 0) ? (uint8)0 : (uint8)1;
			if (getState == 0)
			{
				SHuoDongAward award;
				awardManager.GetAwardData(type, idxList[ai], award);
				for (uint8 j = 0; j < SHuoDongAward::AWARD_NUM; j++)
					AddHuoDongAward(this, type, award.award[j], award.num[j], award.petQuality[j], award.petQualityLv[j]);
			}
		}
		SetExtData32(maskDataId, 0);
	}
	if (clear)
	{
		SetExtData8(680, 0);
		SetExtData8(681, 0);
		SetExtData8(682, 0);
	}
}

void CUser::DailyFanliData()
{
	if (HaveBitSet(626))
		return;

	int type = CHuoDongAwardManager::DAILY_CHONGZHI_FANLI;
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	if (!awardManager.InHuoDongTime(type))
		return;
	uint32 money = GetExtData32(474);
	HDPeiZhiInfo cfg;
	if (!awardManager.GetDailyFanliCfg(money, cfg))
		return;

	SMailData mailData;

	uint32 yd = money * YUANBAO_BILV * (cfg.YB / 10000.0);
	mailData.AddAward(HDAT_YB, 0, yd);
	char buf[256];
	snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0149, money, cfg.price, cfg.water_cz, cfg.YB / 100, yd);
	SendSystemMail(GetRoleId(), buf, &mailData);
	ClearBitSet(626);
	SetExtData32(474, 0);
}

void CUser::HuanLeShengYanClearData()
{
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 hdType = CHuoDongAwardManager::ZHOU_NIAN_QING_1;
	if(!awardManager.InHuoDongTime(hdType) || (GetExtData32(437) > 0 && GetExtData32(437) != awardManager.GetHuoDongStartTime(hdType)))
	{
		SetExtData32(434,0);
		SetExtData32(435,0);
		SetExtData32(436,0);
		SetExtData32(437,0);
	}
}

void CUser::QinaghuaKuanghuanClearData()
{
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 huodong_type = CHuoDongAwardManager::QIANGHUA_KUANGHUAN;
	if (awardManager.InHuoDongTime(huodong_type))
	{
		uint32 xf_time = awardManager.GetHuoDongStartTime(huodong_type);
		if(xf_time != GetExtData32(215))
		{
			SetExtData32(214,0);
			SetExtData32(215, xf_time);
		}
	}
	else if (GetExtData32(215) > 0)
	{
		SetExtData32(214,0);
		SetExtData32(215,0);
	}
}

void CUser::ShengjieLetianClearData()
{
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 huodong_type = CHuoDongAwardManager::SHENGJIE_LETIAN;
	if (awardManager.InHuoDongTime(huodong_type))
	{
		uint32 xf_time = awardManager.GetHuoDongStartTime(huodong_type);
		if(xf_time != GetExtData32(217))
		{
			SetExtData32(216,0);
			SetExtData32(217, xf_time);
		}
	}
	else if (GetExtData32(217) > 0)
	{
		SetExtData32(216,0);
		SetExtData32(217,0);
	}
}

void CUser::HDClearItem(uint32 hd_type)
{
	int festivalItemList[] = {2535,2536,2513,2514,2746,2747,2748,2749,2750,2751,2752,2753,2913,2914,2918,2917,2915,2916};
	int xinChunHappyItemList[] = {2935,2936,2937,2938,2939,2940,2941,2942,2943,2944};
	int *itemList = NULL;
	int itemSize = 0;

	if (hd_type == CHuoDongAwardManager::FESTIVAL)
	{
		itemList = festivalItemList;
		itemSize = sizeof(festivalItemList) / sizeof(festivalItemList[0]);
	}
	else if (hd_type == CHuoDongAwardManager::XINCHUN_HAPPY)
	{
		itemList = xinChunHappyItemList;
		itemSize = sizeof(xinChunHappyItemList) / sizeof(xinChunHappyItemList[0]);
	}
		
	if (itemList == NULL)
		return;
	for (int i = 0; i < itemSize; i++)
	{
		int itemNum = GetItemNum(itemList[i]);
		if (itemNum > 0)
			DelPackageById(itemList[i],itemNum);
	}
}

void CUser::FestivalClearData()
{
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 huodong_type = CHuoDongAwardManager::FESTIVAL;
	if (awardManager.InHuoDongTime(huodong_type))
	{
		uint32 xf_time = awardManager.GetHuoDongStartTime(huodong_type);
		if(xf_time != GetExtData32(218))
		{
			SetExtData32(218, xf_time);
			SetExtData32(219,0);
			SetExtData32(220,0);
			SetExtData32(221,0);
			SetExtData32(222,0);
			SetExtData32(223,0);
			SetExtData32(224,0);
			//HDClearItem(huodong_type);
		}
	}
	else if (GetExtData32(218) > 0)
	{
		SetExtData32(218,0);
		SetExtData32(219,0);
		SetExtData32(220,0);
		SetExtData32(221,0);
		SetExtData32(222,0);
		SetExtData32(223,0);
		SetExtData32(224,0);
		//HDClearItem(huodong_type);
	}
}

void CUser::MeiRiHuanHaoLiClearData()
{
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 huodong_type = CHuoDongAwardManager::MEIRI_HUANHAOLI;

	uint32 timeDataId = 289;
	if (awardManager.InHuoDongTime(huodong_type))
	{
		uint32 xf_time = awardManager.GetHuoDongStartTime(huodong_type);
		if(xf_time != GetExtData32(timeDataId))
			SetExtData32(timeDataId, xf_time);

		for (uint32 i = 438; i <=447; i++)
			SetExtData8(i,0);
	}
	else if (GetExtData32(timeDataId) > 0)
	{
		SetExtData32(timeDataId, 0);
		for (uint32 i = 438; i <=447; i++)
			SetExtData8(i,0);
	}
}

void CUser::ClearGuaJi()
{
	SetExtData16(9,AUTO_DEFAULT_FIGHT_NUM_SET);
	
	CNetMessage msg;
	CSocketServer &sock = SingletonSocket::instance();
	msg.SetType(MSG_GUAJI);
	msg<<(uint8)2<<GetExtData16(9);
	sock.SendMsg(GetSock(),msg);
}

bool CUser::DelPackageById(int id,int num)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return NoLockDelPackageById(id,num);
}

bool CUser::NoLockDelPackageById(int id,int num)
{
	if(num == 0)
		return false;
	if(num < 0)
		num = 0xffff;
	for(uint16 pos = 0; pos < MAX_PACKAGE_NUM2; pos++)
	{
		if(m_package[pos].tmplId == id)
		{
			if(m_package[pos].num > num)
			{
				NolockUpdateItemNumMap(id,num,false);
				m_package[pos].num -= num;
				num = 0;
			}
			else
			{
				NolockUpdateItemNumMap(id,m_package[pos].num,false);
				num -= m_package[pos].num;
				m_package[pos].Clear();
			}
			CSocketServer &sock = SingletonSocket::instance();
			CNetMessage msg;
			msg.SetType(PRO_UPDATE_PACK);
			msg<<(uint8)2;		// update
			MakePack(m_package[pos],pos,msg);
			sock.SendMsg(m_sock,msg);
		}
		if(num <= 0)
		{
			return true;
		}
	}
	return false;
}

bool CUser::DelBankPackageById(int id,int num)
{
/*
	if(num == 0)
		return false;
	if(num < 0)
		num = 0xff;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint8 pos = 0; pos < MAX_BANK_ITEM_NUM; pos++)
	{
		if(m_bankItem[pos].tmplId == id)
		{
			if(m_bankItem[pos].num > num)
			{
				m_bankItem[pos].num -= num;
				num = 0;
			}
			else
			{
				num -= m_bankItem[pos].num;
				memset(m_bankItem + pos,0,sizeof(SItemInstance));
			}
		}
		if(num <= 0)
		{
			return true;
		}
	}
*/
	return false;
}

CUser::~CUser()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	list<SNpcInstance>::iterator i = m_npcList.begin();
	for(; i != m_npcList.end(); i++)
	{
		delete i->pNpc;
		delete i->pHumanData;
		i->pNpc = NULL;
		i->pHumanData = NULL;
	}
	list<SNpcInstance>::iterator it = m_collectList.begin();
	for(; it != m_collectList.end(); it++)
	{
		delete it->pNpc;
		delete it->pHumanData;
		it->pNpc = NULL;
		it->pHumanData = NULL;
	}
	m_name[0] = 0;
	DoptionClear();
	m_itemNumMap.clear();

	if(m_Npc.pNpc != NULL)
		delete m_Npc.pNpc;
	if(m_Npc.pHumanData != NULL)
		delete m_Npc.pHumanData;
	
	delete m_userBook;
	m_userBook = NULL;
}

// 添加采集npc
int CUser::AddCollect(int npcId,int npcIdx,int sceneId,int x,int y)
{
	SNpcInstance npc;
	CNpcManager &npcManager = SingletonNpcManager::instance();
	SNpcTemplate *pNpc = npcManager.GetNpcTemplate(npcId);
	if (pNpc == NULL)
		return -1;
	npc.pNpc = new SNpcTemplate;
	*(npc.pNpc) = *pNpc;

	if (npc.pNpc == NULL)
		return -2;

	npc.id = npcId;
	npc.index = npcIdx;
	npc.templateId = npcId;
	npc.x = x;
	npc.y = y;
	npc.sceneId = sceneId;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(list<SNpcInstance>::iterator i = m_collectList.begin(); i != m_collectList.end(); i++)
	{
		if(i->id == npc.id && i->x == npc.x && i->y == npc.y && i->sceneId == npc.sceneId)
			return -4;
	}
	if (m_collectList.size() >= 20)
		return -3;
	m_collectList.push_back(npc);

	if (sceneId == GetScene()->GetMapId())
	{
		CNetMessage msg;
		msg.SetType(PRO_ADD_NPC);
		npc.MakeNpcInfo(msg);
		SingletonSocket::instance().SendMsg(GetSock(),msg);
	}
	return 0;
}

// 删除采集npc
int CUser::DelCollect(int npcId,int npcIdx,int sceneId)
{
//	if (GetScene() == NULL)
//		return -1;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	SNpcInstance npc;
	list<SNpcInstance>::iterator i = m_collectList.begin();
	for(; i != m_collectList.end(); i++)
	{
		if((i->id == npcId) && (i->index == npcIdx) && (i->sceneId == sceneId))
		{
			npc = *i;
			m_collectList.erase(i);
			break;
		}
	}
	if(npc.sceneId > 0)
	{
		CNetMessage msg;
		msg.SetType(PRO_DEL_NPC);
		msg<<(uint16)npcId<<(uint16)npcIdx;
		delete npc.pNpc;
		delete npc.pHumanData;
		SingletonSocket::instance().SendMsg(GetSock(),msg);
	}
	return 0;

//	if (npc.sceneId == GetScene()->GetMapId())
//	{
//		CNetMessage msg;
//		msg.SetType(PRO_DEL_NPC);
//		msg<<(uint16)npcId<<(uint16)npcIdx;
//		delete npc.pNpc;
//		delete npc.pHumanData;
//		SingletonSocket::instance().SendMsg(GetSock(),msg);
//	}
//	return 0;
}

// 登陆显示npc用
int CUser::AddCollectInfo(int sceneId,CNetMessage &msg)
{
	int num = 0;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(m_collectList.empty())
		return 0;
	list<SNpcInstance>::iterator i = m_collectList.begin();
	for(; i != m_collectList.end(); i++)
	{
		if((sceneId == i->sceneId) && (i->pNpc != NULL))
		{
			//pInst = &(i->npc);
			//msg<<i->id<<i->pNpc->name<<i->x<<i->y<<i->pNpc->pic;
			i->MakeNpcInfo(msg);
			num++;
		}
	}
	return num;
}

bool CUser::MakeNpc(int npcId,CNetMessage &msg)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	list<SNpcInstance>::iterator i = m_npcList.begin();
	for(; i != m_npcList.end(); i++)
	{
		if(i->id == npcId)
		{
			SNpcTemplate *pNpc = i->pNpc;
			if(pNpc == NULL)
				return false;
			msg<<pNpc->name<<(uint16)i->sceneId<<i->x<<i->y;
			return true;
		}
	}
	return false;
}

CCallScript *CUser::FindNpcScript(int npcId)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	list<SNpcInstance>::iterator i = m_npcList.begin();
	for(; i != m_npcList.end(); i++)
	{
		if(i->id == npcId)
		{
			return i->pNpc->pScript;
		}
	}
	return NULL;
}

SNpcPos CUser::FindNpcPos(int npcId)
{
	SNpcPos pos = {0};
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	list<SNpcInstance>::iterator i = m_npcList.begin();
	for(; i != m_npcList.end(); i++)
	{
		if(i->id == npcId)
		{
			pos.sceneId = i->sceneId;
			pos.x = i->x;
			pos.y = i->y;
			break;
		}
	}
	
	for(i = m_collectList.begin(); i != m_collectList.end(); i++)
	{
		if(i->id == npcId)
		{
			pos.sceneId = i->sceneId;
			pos.x = i->x;
			pos.y = i->y;
			break;
		}
	}
	return pos;
}

uint32 CUser::GetHumanNcpRoleId(int npcId)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	list<SNpcInstance>::iterator i = m_npcList.begin();
	for(; i != m_npcList.end(); i++)
	{
		if((i->id == npcId) && (i->pHumanData != NULL))
		{
			return i->pHumanData->roleId;
		}
	}
	return 0;
}

bool CUser::GetNpc(int npcId,SNpcInstance &npc)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	list<SNpcInstance>::iterator i = m_npcList.begin();
	for(; i != m_npcList.end(); i++)
	{
		if(i->id == npcId)
		{
			npc = *i;
			return true;
		}
	}
	return false;
}

const char *CUser::GetNpcName(int npcId)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	list<SNpcInstance>::iterator i = m_npcList.begin();
	for(; i != m_npcList.end(); i++)
	{
		if(i->id == npcId)
		{
			return i->pNpc->name.c_str();
		}
	}
	return NULL;
}

int CUser::AddMonster(SVisibleMonster &monster)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(list<SVisibleMonster>::iterator i = m_monsterList.begin(); i != m_monsterList.end(); i++)
	{
		if(i->id == monster.id && i->sceneId == monster.sceneId)
			return 0;
	}
	if(m_monsterList.size() >= 18)
		return -2;
	m_monsterList.push_back(monster);
	return 0;
}

void CUser::DelMonster(int monsterType,int sceneId)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(m_monsterList.size() == 0)
		return;
	for(list<SVisibleMonster>::iterator i = m_monsterList.begin(); i != m_monsterList.end(); i++)
	{
		if(i->id == (uint32)monsterType && i->sceneId == (uint16)sceneId)
		{
			m_monsterList.erase(i);
			return;
		}
	}
}

int CUser::AddNpc(int scenseId,SNpcInstance &npc)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(list<SNpcInstance>::iterator i = m_npcList.begin(); i != m_npcList.end(); i++)
	{
		if(i->id == npc.id && i->x == npc.x && i->y == npc.y && i->sceneId == npc.sceneId)
		{
			cout<<">>> CUser::AddNpc  id="<<m_roleId<<", CUser::AddNpc npc is same. npcId="<<(int)npc.id<<", npc.x="<<npc.x<<", npc.y="<<npc.y<<", npc.sid="<<npc.sceneId<<endl;
			return 0;
		}
	}
	if (m_npcList.size() >= 10)
	{
		cout<<">>> CUser::AddNpc  id="<<m_roleId<<", CUser::AddNpc npc list is full. npcId="<<(int)npc.id<<", npc.x="<<npc.x<<", npc.y="<<npc.y<<", npc.sid="<<npc.sceneId<<endl;
		return -2;
	}
	m_npcList.push_back(npc);
	return 0;
}

uint16 CUser::DelNpc(int npcId,SNpcInstance &npc,int index)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	list<SNpcInstance>::iterator i = m_npcList.begin();
	for(; i != m_npcList.end(); i++)
	{
		if(npcId == i->id && index == i->index)
		{
			npc = *i;
			m_npcList.erase(i);
			return npc.sceneId;
		}
	}
	return 0;
}

int CUser::MeetMonster(string &monsterName)
{
	const int distance = 80;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(list<SVisibleMonster>::iterator i = m_monsterList.begin(); i != m_monsterList.end(); i++)
	{
		int dx = (int)m_xPos - (int)i->x;
		int dy = (int)m_yPos - (int)i->y;
		if(i->sceneId == (uint16)GetSceneId() && dx*dx+dy*dy <= distance*distance)
		{
			monsterName = i->name;
			return i->id;
		}
	}
	return 0;
}

int CUser::MakeMonsterInfo(int scenseId,CNetMessage &msg)
{
	int num = 0;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(m_monsterList.empty())
		return 0;
	list<SVisibleMonster>::iterator i = m_monsterList.begin();
	for(; i != m_monsterList.end(); i++)
	{
		if(scenseId == i->sceneId)
		{
			msg<<i->id<<i->name<<i->pic<<(uint8)0<<i->x<<i->y<<i->face<<(uint8)2;
			num++;
		}
	}
	return num;
}

int CUser::AddNpcInfo(int scenseId,CNetMessage &msg)
{
	int num = 0;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(m_npcList.empty())
		return 0;

	list<SNpcInstance>::iterator i = m_npcList.begin();
	for(; i != m_npcList.end(); i++)
	{
		if((scenseId == i->sceneId) && (i->pNpc != NULL))
		{
			//pInst = &(i->npc);
			//msg<<i->id<<i->pNpc->name<<i->x<<i->y<<i->pNpc->pic;
			i->MakeNpcInfo(msg);
			num++;
		}
	}
	return num;
}

bool CUser::FindNpcNear(SNpcInstance &npc)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	//uint8 x,y;
	//GetFacePos(x,y);
	list<SNpcInstance>::iterator i = m_npcList.begin();
	for(; i != m_npcList.end(); i++)
	{
		//uint8 x,y;
		//x = abs(m_xPos - i->x);
		//y = abs(m_yPos - i->y);
		//if(((m_pScene->GetMapId() == i->sceneId) && (i->pNpc != NULL))
		//&& ((x == i->x) && (y == i->y)))
		if(((m_pScene->GetSrcSceneId() == i->sceneId) && (i->pNpc != NULL)) && (m_xPos-i->x)*(m_xPos-i->x) + (m_yPos - i->y)*(m_yPos - i->y) <= NPC_Distance*NPC_Distance)
		{
			npc = *i;
			return true;
		}
	}
	list<SNpcInstance>::iterator it = m_collectList.begin();
	for(; it != m_collectList.end(); it++)
	{
		//uint8 x,y;
		//x = abs(m_xPos - i->x);
		//y = abs(m_yPos - i->y);
		//if(((m_pScene->GetMapId() == i->sceneId) && (i->pNpc != NULL))
		//&& ((x == i->x) && (y == i->y)))
		if(((m_pScene->GetSrcSceneId() == it->sceneId) && (it->pNpc != NULL)) && (m_xPos-it->x)*(m_xPos-it->x) + (m_yPos - it->y)*(m_yPos - it->y) <= NPC_Distance*NPC_Distance)
		{
			npc = *it;
			return true;
		}
	}
	return false;
}

CCallScript *CUser::GetTimeOutNpcScript()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	list<SNpcInstance>::iterator i = m_npcList.begin();
	for(; i != m_npcList.end(); i++)
	{
		if((i->timeOut > 0) && (i->timeOut < GetSysTime()))
		{
			if(i->pNpc != NULL)
				return i->pNpc->pScript;
			else
				return NULL;
		}
	}
	return NULL;
}

int CUser::GetSceneId()
{
	if(m_pScene != NULL)
		return m_pScene->GetId();
	return 0;
}

uint16 CUser::GetMapId()
{
	if(m_pScene != NULL)
		return m_pScene->GetMapId();
	return 0;
}

uint16 CUser::GetSrcSceneId()
{
	if(m_pScene != NULL)
		return m_pScene->GetSrcSceneId();
	return 0;
}

uint8 CUser::GetCanDoRingBossNum()
{
	if(m_vipLevel >= sizeof(G_VipConfig)/sizeof(G_VipConfig[0]))
		m_vipLevel = sizeof(G_VipConfig)/sizeof(G_VipConfig[0]) - 1;
	return G_VipConfig[m_vipLevel].bosstz;
}

uint16 CUser::GetArenaFightMaxNum()
{
	if(m_vipLevel >= sizeof(G_VipConfig)/sizeof(G_VipConfig[0]))
		m_vipLevel = sizeof(G_VipConfig)/sizeof(G_VipConfig[0]) - 1;
	return G_VipConfig[m_vipLevel].arenatz;
}

bool CUser::ReadBangPaiGuardData()
{
/*
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return false;

	char sql[1024];
	char **row = NULL;
	//                            0	 1	  2		3	  4  5    6		7
	snprintf(sql,sizeof(sql)-1,"select name,sex,level,zhandouli,pet,title,mount,vipLv where bang_id=%u and role_id=%u",GetBangPai(),GetRoleId());
	if(!pDb->Query(sql))
		return false;
	if((row = pDb->GetRow()) == NULL)
		return false;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	SetName(row[0]);
	SetSex(atoi(row[1]));
	SetLevel(atoi(row[2]));
	m_zhanDouLi = atoll(row[3]);
	SetPet(row[4]);
	ReadTitle(row[5]);
	SetMount(row[6]);
	m_vipLevel = atoi(row[7]);
*/
	return true;
}

bool CUser::ReadMirrorRoleData(int type)
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return false;

	char sql[1024];
	char **row = NULL;
	//                           0	 1	  2		3	  4   5   6
	snprintf(sql,sizeof(sql)-1,"select name,sex,level,zhandouli,pet,title,mount from role_mirror where type=%d and role_id=%u",type,GetRoleId());
	if(!pDb->Query(sql))
		return false;
	if((row = pDb->GetRow()) == NULL)
		return false;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	SetName(row[0]);
	SetSex(atoi(row[1]));
	SetLevel(atoi(row[2]));
	m_zhanDouLi = atoll(row[3]);
	SetPet(row[4]);
	ReadTitle(row[5]);
	SetMount(row[6]);
	SetBangPai(0);
	return true;
}

void CUser::SaveBangPaiGuardData(uint8 guardIdx)
{
/*
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;

	//                                         1      2      3     4   5		6	7		8	  9		  10	11		12	  13	14		15
	boost::format fmt("insert into bang_pai_guard (bang_id,guardIdx,role_id,name,sex,xiang,level,maxHp,daohang,liliang,lingli,minjie,naili,tizhi,damage,"\
	//		16		   17		18	  19	  20		21	 22		23		24		25		26		27		28			29				30			31
		"recovery,skillDamage,speed,shanbi,mingzhong,lianji,baoji,fanji,fanshang,jianshang,gedang,renxing,zhaojia,lianjiQiangHua,baojiQiangHua,fanjiQiangHua,"\
	//			32					33			  34			  35               36          37        38     39   40      41     42    43    44
		"fanshangQiangHua,jianshangQiangHua,gedangQiangHua,renxingQiangHua,zhaojiaQiangHua,zhandouli,equipment,skill,pet,petkaijia,title,mount,vipLv) "\
		"values(%1%,%2%,%3%,'%4%',%5%,%6%,%7%,%8%,%9%,%10%,%11%,%12%,%13%,%14%,%15%,%16%,%17%,%18%,%19%,%20%,%21%,%22%,%23%,%24%,%25%,%26%,%27%,"\
		"%28%,%29%,%30%,%31%,%32%,%33%,%34%,%35%,%36%,%37%,'%38%','%39%','%40%','%41%','%42%','%43%',%44%)");

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	string pet;
	string petkaijia;
	string title;
	string mount;
	GetPet(pet);
	GetTitleStr(title);
	GetMount(mount);

	fmt % GetBangPai()
		% (int)guardIdx
		% GetRoleId()
		% GetName()
		% (int)GetSex()
		% 0 //(int)GetXiang()
		% (int)GetLevel()
		% GetMaxHp()
		% 0//GetDaoHang()
		% 0//m_liliang
		% 0//m_lingli
		% 0//m_minjie
		% 0//m_naili
		% 0//m_tizhi
		% 0//m_damage
		% 0//m_recovery
		% 0//m_fashuDamage
		% m_attr.speed
		% 0//m_shanBi
		% 0//m_mingZhong
		% 0//m_lianji
		% m_attr.baoji
		% 0//m_fanji
		% 0//m_fanShang
		% 0//m_jianShang
		% 0//m_geDang
		% 0//m_renXing
		% 0//m_zhaoJia
		% 0//m_lianJiQiangHua
		% 0//m_baoJiQiangHua
		% 0//m_fanJiQiangHua
		% 0//m_fanShangQiangHua
		% 0//m_jianShangQiangHua
		% 0//m_geDangQiangHua
		% 0//m_renXingQiangHua
		% 0//m_zhaoJiaQiangHua
		% m_zhanDouLi
		% ""	// equip
		% ""	// skill
		% pet
		% petkaijia
		% title
		% mount
		% (int)m_vipLevel;

	if(!pDb->Query(fmt.str().c_str()))
	{
		cout<<">> Save bang_pai_guard error... sql="<<fmt.str()<<endl;
	}
*/
}

bool CUser::ReadData(uint32 roleId)
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return false;
	//                      0    1   2   3     4     5  6     7      8   9   10   11     12      13       14         15    16
	boost::format fmt("select state,name,sex,zhenfa,model,level,exp,package,money,title,hots,bitset,save_val,qianneng,chat_channel,chat_time,head,"\
	//    17    18     19      20       21      22   23      24        25       26         27      28    29     30      31
		"model,admin,reg_time,bank_item,save_data,mount,wing,bossFightStar,sg_bitset,mysteryShop,login_time,xiuxian,shenqi,transform,mission,"\
	//      32          33       34     35     36      37       38       39      40       41      42       43       44    45
		"clientstring,shenhunShop,questIds,find_res,xunbao,pet_equip,bang_skills,guan_qia,user_book,chou_ka,blood_fight,copyData,user_spirit,pet,"\
	//         46           47       48
		"korea_money_gift,kuafu_1vs1,xianyuan from role_info where id=%1%");
	fmt % roleId;

	char **row = NULL;
	bool ret = false;
	if((pDb != NULL) && pDb->Query(fmt.str().c_str()) && ((row = pDb->GetRow()) != NULL))
	{
		int state = atoi(row[0]);
		if(state == 2)
			return false;
		
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		m_loginTime = GetSysTime();
		m_curMonthDay = GetDay();
		entergametime_ = GetSysTime();
		checkOnLineTime_ = (uint32)GetSysTime();
		m_callLevelScript = false;
		m_roleId = roleId;
		MAX_PACKAGE_NUM = MAX_PACKAGE_NUM2;
		
		SetName(row[1]);
		SetSex(atoi(row[2]));
		SetZhenFa(row[3]);
//		SetModel(atoi(row[4]));
		SetLevel(atoi(row[5]));
		SetExp(atoll(row[6]));
		SetPackage(row[7]);
		m_money = atoi(row[8]);
		ReadTitle(row[9]);
//		ReadHotsAndIgnore(row[10]);
		SetBitSet(row[11]);
		SetSaveVal(row[12]);
		SetQianNeng(atoi(row[13]));
		m_chatChannel = atoi(row[14]);
		m_chatTime = atoi(row[15]);
		m_head = atoi(row[16]);
		m_model = atoi(row[17]);
		m_admin = atoi(row[18]);
		reg_time = atoi(row[19]);
		SetBankItem(row[20]);
		ReadSaveData(row[21]);
		SetMount(row[22]);
		SetWing(row[23]);
		SetBossMissionStar(row[24]);
		SetSGBitSet(row[25]);
		m_shop->LoadData(this, row[26]);
		m_lastLoginOutTime = atoi(row[27]);
		SetXiuXianInfo(row[28]);
		LoadNewShenQi(row[29]);
		LoadTransFormCard(row[30]);
		m_missList.LoadData(row[31]);
		m_missList.CheckQuestShow(this);
		SetClientString(row[32]);
		SetShenhunShopData(row[33]);
		SetQuestionStr(row[34]);
		SetFindResource(row[35]);
		m_xunBaoManage.LoadMap(row[36]);
		m_petEquipMgr.LoadData(row[37]);
		SetBangSkill(row[38]);
		m_userGuanQia.LoadData(row[39]);
		m_userBook->LoadData(row[40]);
		SetPet(row[45]);        // pet
		m_chouKa->LoadData(row[41]);
		m_bloodFight->LoadData(row[42]);
		SetBangPaiCopy(row[43]);
		m_userSpirit.LoadData(row[44]);
		
#ifndef KUA_FU
		LoadMoneyGiftBagHuoDongMap(row[46]);
#endif
		LoadKuaFu1vs1SaveEnemy(row[47]);
		LoadXianYuan(row[48]);
		InitJingJie();
		SetExtData32(0,GetSysTime());
		// Keep validation queries after all role_info row fields are consumed:
		// querying through the same DB handle invalidates the current row buffer.
		if (gyu::util::CIniFile::GetValue("local_test", "server", "config") == "1" &&
			pDb->Query("SHOW TABLES LIKE 'unity_validation_task_fixture'") &&
			pDb->GetRow() != NULL)
		{
			char fixtureSql[256];
			snprintf(fixtureSql, sizeof(fixtureSql),
				"select active_value from unity_validation_task_fixture where user_id=%u and enabled=1 and applied=0 and (role_id=0 or role_id=%u) limit 1",
				m_userId, m_roleId);
			if (pDb->Query(fixtureSql))
			{
				char** fixtureRow = pDb->GetRow();
				if (fixtureRow != NULL)
				{
					uint32 activeValue = (uint32)atoi(fixtureRow[0]);
					m_missList.ApplyTaskValidationFixture(this, activeValue);
					snprintf(fixtureSql, sizeof(fixtureSql),
						"update unity_validation_task_fixture set role_id=%u,applied=1 where user_id=%u",
						m_roleId, m_userId);
					pDb->Query(fixtureSql);
					cout << "[local] Task validation fixture applied userId=" << m_userId
						<< " roleId=" << m_roleId << " activeValue=" << activeValue << endl;
				}
			}
		}

		if (gyu::util::CIniFile::GetValue("local_test", "server", "config") == "1" &&
			pDb->Query("SHOW TABLES LIKE 'unity_validation_seven_day_fixture'") && pDb->GetRow() != NULL)
		{
			char sevenDaySql[512];
			snprintf(sevenDaySql, sizeof(sevenDaySql),
				"select claimable_quest_id from unity_validation_seven_day_fixture where user_id=%u and enabled=1 and applied=0 and (role_id=0 or role_id=%u) limit 1",
				GetUserId(), GetRoleId());
			if (pDb->Query(sevenDaySql))
			{
				char** sevenDayRow = pDb->GetRow();
				if (sevenDayRow != NULL)
				{
					uint16 questId = (uint16)atoi(sevenDayRow[0]);
					m_missList.ApplySevenDayValidationFixture(this, questId);
					snprintf(sevenDaySql, sizeof(sevenDaySql),
						"update unity_validation_seven_day_fixture set role_id=%u,applied=1 where user_id=%u",
						GetRoleId(), GetUserId());
					pDb->Query(sevenDaySql);
				}
			}
		}
		ret = true;

		
/*		SetNpc(row[18]);
		m_userDoubleEnd = atoi(row[21]);
		m_useDoubleType = (uint16)atoi(row[22]);
		m_pkTime = atoi(row[29]);
		SetCollect(row[35]);
		m_nextOpenPackageTime = atoi(row[36]);
		SetMonster(row[37]);
		SetQunXianData(row[50]);
		SetYaoShiData(row[51]);
*/
	}
	if (!HaveBitSet(901))
	{
		m_petEquipMgr.ClearJingLian(this);
		SetBitSet(901);
	}
	if(ret)
	{
		ReadBangPai();
		RoleOnlineUpdateRank();
		
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		Init(true);
		m_loginHuoYueSign = true;
		//UpdateBangHuoYue(EBHT_Login);
	}
	// 最后检测称号并初始化神将
//	CheckInvalidTitle();
	return ret;
}

bool CUser::CopyUserData(uint32 roleId, uint8 robotType)
{
	bool res = false;
	if(robotType == 0)	// 正常角色
	{
		ShareUserPtr user = SingletonOnlineUser::instance().GetUserByRoleId(roleId);
		CUser *pU = user.get();
		if(pU != NULL)
			res = CopyOnlineUserData(pU);
		else
			res = CopyOfflineUserData(roleId);

		// 容错
//		if (!res)
//		{
//			res = CopyOfflineUserData(Random(1, 20), 1);
//		}
	}
//	else	// 机器人
//	{
//		res = CopyOfflineUserData(roleId, robotType);
//	}
	return res;
}

bool CUser::ReadDataSimple(uint32 roleId)
{
	char sql[256];
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return false;
	snprintf(sql,sizeof(sql),"select bitset,bank_item,level,korea_money_gift,reg_time from role_info where id=%u",roleId);

	if (!pDb->Query(sql))
		return false;

	char **row = NULL;
	if (((row = pDb->GetRow()) == NULL))
		return false;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		SetBitSet(row[0]);
		SetBankItem(row[1]);
		SetLevel((uint8)atoi(row[2]));
		LoadMoneyGiftBagHuoDongMap(row[3]);
		reg_time = atoi(row[4]);
		m_roleId = roleId;
		m_vipLevel = ::GetVipLevel(GetChongzhiTotal() + GetExVipExp());
		return true;
	}
	return false;
}

// robot: 0 正常 1 竞技场机器人 2 试炼机器人 3 修仙机器人
bool CUser::CopyOfflineUserData(uint32 roleId,uint8 robot)
{
	char sql[512];
	char **row = NULL;
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return false;
	if(robot == 0)	// 正常角色
	{
		//                          0   1   2   3     4       5      6     7   8     9     10    11      12      13
		snprintf(sql,sizeof(sql),"select name,sex,level,title,bank_item,mount,sg_bitset,wing,pet,xianyuan,shenqi,zhenfa,user_book,pet_equip from role_info where id=%u",roleId);
	}
/*	else if(robot == 1)	// 竞技场机器人
	{
		//                          0	1	2	 3	  	4	  5		 6	    7  8
		snprintf(sql,sizeof(sql),"select name,sex,level,title,bank_item,mount,sg_bitset,wing,pet from arena_robot where id=%u",roleId);
	}
	else if(robot == 2)	// 试炼机器人
	{
		//							0	1	2	 3	  	4	  5		 6	    7  8
		snprintf(sql,sizeof(sql),"select name,sex,level,title,bank_item,mount,sg_bitset,wing,pet from shilian_robot where id=%u",roleId);
	}
	else if(robot == 3)	// 修仙机器人
	{
		//							0	1	2	 3	  	4	  5		 6	    7  8
		snprintf(sql,sizeof(sql),"select name,sex,level,title,bank_item,mount,sg_bitset,wing,pet from role_xiuxian where id=%u",roleId);
	}
*/
	if(!pDb->Query(sql))
		return false;
	if((row = pDb->GetRow()) != NULL)
	{
		SetRoleId(roleId);
		SetName(row[0]);
		SetSex(atoi(row[1]));
		SetLevel(atoi(row[2]));
		ReadTitle(row[3]);
		SetBankItem(row[4]);
		SetMount(row[5]);
		SetSGBitSet(row[6]);
		SetWing(row[7]);
		if(robot == 0)
		{
			LoadXianYuan(row[9]);
			LoadNewShenQi(row[10]);
			SetZhenFa(row[11]);
		}
		if(m_userBook != NULL)
			m_userBook->LoadData(row[12]);
		m_petEquipMgr.LoadData(row[13]);
		SetPet(row[8], ((robot == 0) ? false : true));
		Init();
		if(robot != 0)
			SetRobot(robot);
		return true;
	}
	return false;
}

void CUser::SetBasicAttrOff()
{
	const float ratio = 0.7f;
	m_attr.attack *= ratio;
	m_attr.wufang *= ratio;
	m_attr.fafang *= ratio;
	m_attr.maxHp *= ratio;
	m_attr.speed *= ratio;
}

// 复制玩家在线数据进行战斗
bool CUser::CopyOnlineUserData(CUser* pSrcUser)
{
	if(pSrcUser == NULL)
		return false;

	m_roleId = pSrcUser->m_roleId;
	memcpy(m_name,pSrcUser->m_name,sizeof(m_name));
	m_sex = pSrcUser->m_sex;
	m_head = pSrcUser->m_head;
	m_model = pSrcUser->m_model;
	m_level = pSrcUser->m_level;
	m_attr.maxHp = pSrcUser->m_attr.maxHp;
	m_bangpai = pSrcUser->m_bangpai;
	m_exp = 0;
	m_sock = -1;

	m_attackType = pSrcUser->m_attackType;
	m_attr = pSrcUser->m_attr;

	m_zhanDouLi = pSrcUser->m_zhanDouLi;

	m_useTitle = pSrcUser->m_useTitle;
	m_titleList = pSrcUser->m_titleList;
	memcpy(&m_mount,&(pSrcUser->m_mount),sizeof(m_mount));

	memcpy(&m_wing,&(pSrcUser->m_wing),sizeof(m_wing));
	
	m_useZhenFaIdx = pSrcUser->m_useZhenFaIdx;
	m_zhenfa.assign(pSrcUser->m_zhenfa.begin(),pSrcUser->m_zhenfa.end());
	m_zhenfaMember.assign(pSrcUser->m_zhenfaMember.begin(),pSrcUser->m_zhenfaMember.end());
	m_chuzhan.assign(pSrcUser->m_chuzhan.begin(), pSrcUser->m_chuzhan.end());
	
	m_vipLevel = pSrcUser->m_vipLevel;
	SetExtData32(13,pSrcUser->GetExtData32(13));

	vector<uint16> petList;
	pSrcUser->GetPetIdList(petList);
	m_pet.clear();
	for(uint8 i=0;i < petList.size();i++)
	{
		SPet *SrcPet = pSrcUser->GetPet(petList[i]).get();
		if(SrcPet != NULL)
		{
			SPet *pPet = new SPet;
			pPet->Clear();
			*pPet = *SrcPet;
			SharePetPtr pet(pPet);
			m_pet[pPet->id] = pet;
		}
	}
	return true;
}

int CUser::CanChat()
{
	int now = GetSysTime();
	int lastSec = GetExtData32(720);
	int needSec = 5;
	int dt = now - lastSec;
	if(dt > needSec || dt < 0)
		return 0;
	else
		return (needSec - dt);
}

void CUser::SetUserDouble(int hour)
{
	if(hour <= 0)
		return;
	if(m_userDoubleEnd == 0)
		m_userDoubleEnd = GetSysTime() + hour*3600;
	else
		m_userDoubleEnd += hour*3600;
}

void CUser::SetUserDoubleTime(int time)
{
	m_userDoubleEnd = time;
}

bool CUser::InScriptCall()
{
	return inscriptcall;
}

void CUser::Set_InScriptCall(bool flag)
{
	inscriptcall = flag;
}

SNpcInstance *CUser::GetInteractNpc(int npcId, int npcIdx)
{
	if (m_pScene == NULL)
		return NULL;

	//场景固定NPC
	if (m_pScene->HaveNpc(npcId))
	{
		return SingletonNpcManager::instance().GetNpcInstance(npcId);
	}
	
	//私有NPC
	for(list<SNpcInstance>::iterator i = m_npcList.begin(); i != m_npcList.end(); i++)
	{
		if(i->id == npcId)
		{
			if(npcIdx == 0 || i->index == npcIdx)
				return &(*i);
		}
	}
	
	// 私有采集NPC
	for(list<SNpcInstance>::iterator it = m_collectList.begin(); it != m_collectList.end(); it++)
	{
		if (it->id == npcId && it->index == npcIdx)
			return &(*it);
	}
	
	// 场景动态NPC,采集NPC
	return m_pScene->FindNpc(npcId, npcIdx);
}

void CUser::NoLockMakePetSkill(uint16 petId,CNetMessage &msg)
{
	uint16 len = msg.GetDataLen();
	uint8 num = 0;
	msg<<num;

	SPet *pPet = GetPet(petId).get();
	if(pPet == NULL)
		return;
	for(uint8 i = 0; i < (uint8)PET_MAX_SKILL_NUM; i++)
	{
		if(pPet->skill[i] != 0)
		{
			num++;
			msg<<i<<pPet->skill[i]<<pPet->skillLevel[i];
		}
	}
	msg.WriteData(len,&num,1);
}

void CUser::MakePetSkill(uint16 petId,CNetMessage &msg)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	NoLockMakePetSkill(petId,msg);
}

int CUser::getValueByPos(int n,int m)		// n阶m星
{
	if(n < 1 && m < 0)
		return 0;
	int basicValue = 101;
	double ratio = 1.3;
	double t = pow(ratio,n-1);
	int val = (int)(basicValue*(m*t + 6.0/(1-ratio) + (1-t*ratio)/pow((1-ratio),2) - (n+6)*t/(1-ratio)));
	return val;
}

void CUser::InsertChatMsg(string &str)
{
	if(m_chatMsg.size() >= (uint32)MAX_CHAR_MSG_NUM)
		m_chatMsg.pop_front();
	m_chatMsg.push_back(str);
}

bool CUser::IsSendChatMsg(string &str)
{
	for(list<string>::iterator i=m_chatMsg.begin();i != m_chatMsg.end();i++)
	{
		if(*i == str)
			return true;
	}
	return false;
}

bool CUser::HaveItem(int id)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(int i = 0; i < MAX_PACKAGE_NUM; i++)
	{
		if(m_package[i].tmplId == id)
		{
			return true;
		}
	}
	return false;
}

bool CUser::HaveLevelItem(int id,int level)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(int i = 0; i < MAX_PACKAGE_NUM; i++)
	{
		if(m_package[i].tmplId == id && m_package[i].level == level)
			return true;
	}
	return false;
}

bool CUser::HaveItem_PackageBank(int id)
{
/*
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(int i = 0; i < MAX_PACKAGE_NUM; i++)
	{
		if(m_package[i].tmplId == id)
		{
			return true;
		}
	}
	for(int i = 0; i < MAX_PACKAGE_NUM; i++)
	{
		if(m_bankItem[i].tmplId == id)
		{
			return true;
		}
	}
*/
	return false;
}

uint8 CUser::HaveEmptyPack()
{
	uint8 num = 0;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(int i = 0; i < MAX_PACKAGE_NUM; i++)
	{
		if(m_package[i].tmplId == 0)
		{
			num++;
		}
	}
	return num;
}

void CUser::TimeOut(int &saveNum,const int limitSaveNum)
{
	uint32 curTime = (uint32)GetSysTime();
	uint16 curDay = GetDay();
	bool clearFlag = false;

	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		uint32 size = m_footData.size();
		for(uint32 i=0;i < size;)
		{
			if(i >= m_footData.size())
				break;
			if((int)curTime >= m_footData[i].end_time)
			{
				if(GetUseFootPrintID() == m_footData[i].id)
					clearFlag = true;
				m_footData.erase(m_footData.begin()+i);
				continue;
			}
			i++;
		}
	}
	if(clearFlag)
		SetUseFootPrintID(0);

	// 跨服图标更新
	if(IsOpenKuaFu())
	{
		if(!m_kuafu_IconState)
		{
			m_kuafu_IconState = true;
			SendKuaFuIconState(m_kuafu_IconState);
		}
	}
	else
	{
		if(m_kuafu_IconState)
		{
			m_kuafu_IconState = false;
			SendKuaFuIconState(m_kuafu_IconState);
		}
	}
	
	if((GetData8(6) != 0) && (curTime - GetData32(8) >= 2*3600))
	{
		SetData8(6,0);
		SendUpdateInfo(44,0);
	}

	if (curTime - m_pwoerSynsTime >= 300)
	{
		SyncPowerToMatch();
		m_pwoerSynsTime = curTime;
	}

	if(!HaveBitSet(363))
	{
		SetBitSet(363);
		SetExtData8(144,0xff);
	}

	if((!HaveBitSet(166)) && (GetOnlineSecond() > 30*60)) // 每日活跃度 持续在线30分钟
		SetBitSet(166);

	if(GetMonthCard() > 0)	//月卡权限
	{
		bool update = false;
		if(GetExtData32(86) > 0 && GetExtData32(86) < curTime)
		{
			ClearMonthCard(UPT_White_Gold);
			update = true;
		}
		/*if(GetExtData32(88) > 0 && GetExtData32(88) < curTime)
		{
			ClearMonthCard(UPT_Diamond);
			update = true;
		}*/
		if(GetExtData32(89) > 0 && GetExtData32(89) < curTime)
		{
			ClearMonthCard(UPT_King);
			update = true;
		}
		if (GetExtData32(467) > 0 && GetExtData32(467) < curTime)
		{
			ClearMonthCard(UPT_TiYan);
			update = true;
		}
		if(update)
			UpdateVipInfo();
	}

	// 帮派放火，偷窃状态更新
/*	bool updateState = false;
	if(GetBangPaiFireTime() > 0 && curTime - GetBangPaiFireTime() >= FIRE_STATE_TIME_LIMIT)
	{
		ClearBangPaiFireTime();
		updateState = true;
	}
	if(GetBangPaiStealTime() > 0 && curTime - GetBangPaiStealTime() >= STEAL_STATE_TIME_LIMIT)
	{
		ClearBangPaiStealTime();
		updateState = true;
	}
	if(updateState)
		m_pScene->UpdateUserInfo(this,ESRT_BangPai);
*/

	TimeOutUpdateUserData();
//	GetHuoYueDuInfo(this);

//	ClearTimeoutTitle();
	TryFishTimeout();
	//SaoDangFuBenTimeout();

	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 type = CHuoDongAwardManager::EXP_TEN_REWARD;
	if((awardManager.InHuodongLimit(this,type) || m_userDoubleEnd > 0) && curTime - m_multiExpTime > 180)	// 3分钟同步多倍经验时间
	{
		m_multiExpTime = curTime;
		Multi_Exp_UpdateActiveTime();
	}
    if(m_curMonthDay != curDay)
    {
    	checkOnLineTime_ = curTime;
    }
	if(curTime - checkOnLineTime_ > 60)//在线时间-分钟更新
	{
		uint32 onLineTime = GetExtData32(98) + curTime - checkOnLineTime_;
		SetExtData32(98,onLineTime);
		checkOnLineTime_ = curTime;
	}
	// 每日在线时间更新
	if(GetExtData32(99) < (uint32)m_loginTime)
	{
		SetExtData32(99,(uint32)m_loginTime);
	}
	else
	{
//		uint32 dt = curTime - GetExtData32(99);
//		uint32 onlineDayTime = GetExtData32(98) + dt;
//		SetExtData32(98,onlineDayTime);
//		SetExtData32(99,curTime);
//		if(m_ad == 5)	// 360
//		{
//			if(!HaveBitSet(198))
//			{
//				if(onlineDayTime > 3*3600)	// 3h 防沉迷
//				{
//					Send_Anti_Addiction();
//					SetBitSet(198);
//				}
//			}
//		}
	}

	if(MAX_PACKAGE_NUM < MAX_PACKAGE_NUM2)
	{
		if(m_nextOpenPackageTime > curTime - GetExtData32(0))
		{
			m_nextOpenPackageTime -= curTime - GetExtData32(0);
			SendUpdateInfo(EUUT_NextOpenPackageTime);
		}
		else
			AddMaxPackageNum();
		SetExtData32(0,curTime);
	}

	if(NoLockGetExtData32(30)!=0 && NoLockGetExtData32(30) < curTime)
	{
		SetExtData32(30,0);
		m_attr.attack -= NoLockGetExtData8(53);
//		m_recovery -= NoLockGetExtData8(53);
		UpdateInfo();
	}
	if(NoLockGetExtData32(34)!=0 && NoLockGetExtData32(34) < curTime)
	{
		SetExtData32(34,0);
		m_attr.attack -= NoLockGetExtData8(57);
//		m_recovery -= NoLockGetExtData8(57);
		UpdateInfo();
	}

	SendItemTimeOut();
	//变身截止时间检测
	TransFormLeftTimeCheck();
	// saveData
	if(saveNum < limitSaveNum)
	{
		if(curTime - (uint32)m_saveDataTime > (uint32)SAVE_DATA_SPACE)
		{
			SaveData();
			saveNum++;
		}
	}
	
	if(m_curMonthDay != curDay)
	{
		m_curMonthDay = curDay;
		SaveLoginLog();
		m_loginTime = curTime;
	}

	// 飞仙战场
	if(CSceneManager::IsInActivityTime(SOT_FeiXian))
	{
		int fx_minute = 0;
		{
			boost::recursive_mutex::scoped_lock lk(m_mutex);
			if(m_FX_FirstState > 0)
			{
				int t = (curTime - m_FX_SetTime)/60;
				if(t%5 == 2)
					fx_minute = 2;
				else if(t != 0 && t%5 == 0)
					fx_minute = 5;
			}
		}
		AddFeiXianFirstAward(fx_minute);
	}

	MountTimer();
	uint32_t maxPower = GetZhanDouLi();
	if (GetExtData32(110) < maxPower)				// 更新今天最高战力
		NoLockSetExtData32(110, maxPower);

	UpdateBangHuoYue(EBHT_OnLineTime1);
	UpdateBangHuoYue(EBHT_OnLineTime2);
	UpdateBangHuoYue(EBHT_OnLineTime3);
}

uint32 CUser::GetMCEndTime(uint8 type)
{
	if(type > UPT_MAX)
		return 0;
	if (type == UPT_White_Gold)
		return GetExtData32(86);
	else if (type == UPT_Diamond)
		return (uint32)-1;
		//return GetExtData32(88);
	else if(type == UPT_King)
		return GetExtData32(89);
	return 0;
}

void CUser::SetMonthCard(uint8 type, uint32 countineTime/* = 0*/)
{
	if(type > UPT_MAX)
		return;

	const uint32 MCTime = 30*3600*24;
//	ClearVipAddAttr();
	uint32 curTime = GetSysTime();
	uint8 dataValue = GetMonthCard();
	if((dataValue & (1<<type)) > 0)
	{
		if(type == UPT_White_Gold)
			SetExtData32(86,GetExtData32(86)+MCTime);
		/*else if(type == UPT_Diamond)
			SetExtData32(88,GetExtData32(88)+MCTime);*/
		else if(type == UPT_King)
			SetExtData32(89,GetExtData32(89)+MCTime);
	}
	else
	{
		dataValue |= 1<<type;
		SetExtData8(70, dataValue);
		if(type == UPT_White_Gold)
			SetExtData32(86,curTime+MCTime);
		/*else if(type == UPT_Diamond)
			SetExtData32(88,curTime+MCTime);*/
		else if(type == UPT_King)
			SetExtData32(89,curTime+MCTime);
		else if (type == UPT_TiYan)
			SetExtData32(467, curTime + countineTime);
	}
//	SetVipAddAttr(true);
}

void CUser::BuyMonthCard(uint8 type/* = UPT_White_Gold*/)
{
	CNetMessage msg;
	char buf[256];
	msg.SetType(MSG_VIP_OPTION);
	if (type == 0)
		snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_1476, LANGUAGE_ZQX_0113, 100);
	else
		snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_1476, LANGUAGE_ZQX_0114, 128);

	SetMonthCard(type);
	ClearBitSet(302);
	UpdateVipInfo();
	msg << (uint8)2 << PRO_SUCCESS << (uint8)1 << MakeStringColor(buf, TIPS_SUCCESS_COLOR);
	SingletonSocket::instance().SendMsg(GetSock(), msg);
	if (type == 0)
		snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_1477, ROLE_NAME_COLOR, GetName());
	else
		snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0112, ROLE_NAME_COLOR, GetName());
	SysInfoToAllUser(buf);
}

void CUser::ClearMonthCard(uint8 type)
{
//	ClearVipAddAttr();
	if(type > UPT_MAX)
		return;
	uint8 value = GetExtData8(70);
	value &= ~(1<<type);
	SetExtData8(70,value);
	if(type == UPT_White_Gold)
		SetExtData32(86,0);
	/*else if(type == UPT_Diamond)
		SetExtData32(88,0);*/
	else if(type == UPT_King)
		SetExtData32(89, 0);
	else if (type == UPT_TiYan)
		SetExtData32(467, 0);

	if (value == 0)
	{
		int speed = 0;
		/*if (sSystemOpenCfgMananger.CheckSystemOpen(this, SOT_FightSpeed2))
			speed = 1;*/
		SetExtData8(85, speed);
	}
}

bool CUser::FindMysteryItem(int id)
{
	for(uint8 i=0;i < m_mysteryItem.size();i++)
	{
		if(m_mysteryItem[i].itemId==id)
			return true;
	}
	return false;
}

bool CUser::FindYaoShiItem(uint32 id)
{
	for(uint32 i=0;i < m_yaoshiItem.size();i++)
	{
		if(m_yaoshiItem[i].itemId==id)
			return true;
	}
	return false;
}

void CUser::CreateYaoShiItem(const vector<UserYaoShiItem> &itemList)
{
	m_yaoshiItem.clear();

	int rateTotal;
	int selInd;
	int r;
    for(uint32 i=0;i<GetYaoShiItemNum();i++)
	{
		vector<int> itemInd;
		vector<int> itemRate;
		rateTotal=0;
		for(uint32 j=0;j<itemList.size();j++)
		{
			if(FindYaoShiItem(itemList[j].itemId))
				continue;

			if (itemList[j].rate[i] == 0)
				continue;
			
			rateTotal+=itemList[j].rate[i];
			itemInd.push_back(j);
			itemRate.push_back(rateTotal);
		}

		if (itemInd.size() == 0)
			continue;

		r=Random(1,rateTotal);
		selInd=0;
		for(uint32 j=0;j<itemInd.size();j++)
		{
			if(r<=itemRate[j])
			{
				selInd=j;
				break;
			}
		}
		m_yaoshiItem.push_back(itemList[itemInd[selInd]]);
	}
}


void CUser::CreateMysteryItem(const vector<UserMysteryItem> &itemList)
{
	m_mysteryItem.clear();

	std::vector<int> itemInd(itemList.size());
	std::vector<int> itemRate(itemList.size());
	int itemTotal;
	int rateTotal;
	int selInd;
	int r;
    for(int i=0;i<ShowMysteryItemNum;i++)
	{
		itemTotal=0;
		rateTotal=0;
		for(int j=0;j<(int)itemList.size();j++)
		{
			if(FindMysteryItem(itemList[j].itemId))
				continue;
			itemInd[itemTotal]=j;
			rateTotal+=itemList[j].rate[i];
			itemRate[itemTotal]=rateTotal;
			itemTotal++;
		}
		r=Random(1,rateTotal);
		selInd=0;
		for(int j=0;j<itemTotal;j++)
		{
			if(r<=itemRate[j])
			{
				selInd=j;
				break;
			}
		}
		m_mysteryItem.push_back(itemList[itemInd[selInd]]);
	}
}

void CUser::ShowYaoShiItems(const vector<UserYaoShiItem> &itemList,vector<HDPeiZhiInfo> &peizhiInfo)
{
	if(m_yaoshiTime < GetNextYaoShiUpdateTime())
	{
		CreateYaoShiItem(itemList);
		m_yaoshiTime=GetNextYaoShiUpdateTime();
	}
	SendYaoShiItemsInfo(peizhiInfo);
}

void CUser::ShowFootPrintItems(const vector<SFootPrintShopData> &itemList)
{
	int curTime = GetSysTime();
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	uint32 size = m_footData.size();
	if(size > 1)
	{
		for(uint32 i=0;i < size;i++)
		{
			for(uint32 j=0;j < itemList.size();j++)
			{
				if(m_footData[i].id == itemList[j].id)
				{
					m_footData[i].rank = itemList[j].rank;
					break;
				}
			}
		}
		SSortFootPrintData sortFun;
		std::sort(m_footData.begin(),m_footData.end(),sortFun);
	}

	uint16 errCount = 0;
	uint16 num = 0;
	CNetMessage msg;
	msg.SetType(MSG_SHOP);
	msg<<(uint8)(CShopManager::ESOP_FootPrintShow);
	uint16 pos = msg.GetDataLen();
	msg<<num;
	for(uint32 i=0;i < size;)
	{
		if(i >= m_footData.size())
			break;
		int idx = -1;
		for(uint32 j=0;j < itemList.size();j++)
		{
			if(itemList[j].id == m_footData[i].id)
			{
				idx = j;
				break;
			}
		}
		if(idx == -1)
		{
			errCount++;
			if(errCount > 200)
				break;
			continue;
		}
		uint8 flag = 2;
		uint8 isEquip = 0;
		int time = itemList[idx].time;
		if(time > 0)
		{
			if(curTime > m_footData[i].end_time)
			{
				if(GetUseFootPrintID() == m_footData[i].id)
					SetUseFootPrintID(0);
				m_footData.erase(m_footData.begin()+i);
				continue;
			}
			else
				time = m_footData[i].end_time - curTime;
		}
		if(GetUseFootPrintID() == m_footData[i].id)
			isEquip = 1;
		msg<<itemList[idx].id<<itemList[idx].name<<itemList[idx].buy_type<<itemList[idx].price<<flag<<time<<isEquip<<itemList[idx].desc;
		i++;
		num++;
	}
	
	for(uint32 i=0;i < itemList.size();i++)
	{
		bool isSend = false;
		for(uint32 j=0;j < m_footData.size();j++)
		{
			if(itemList[i].id == m_footData[j].id)
			{
				isSend = true;
				break;
			}
		}
		if(!isSend)
		{
			msg<<itemList[i].id<<itemList[i].name<<itemList[i].buy_type<<itemList[i].price<<(uint8)1<<itemList[i].time<<(uint8)0<<itemList[i].desc;
			num++;
		}
	}

	msg.WriteData(pos,&num,sizeof(num));
	SingletonSocket::instance().SendMsg(m_sock,msg);
}

void CUser::BuyFootPrint(const vector<SFootPrintShopData> &itemList,int id,CNetMessage &msg)
{
	if(id < 1)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0235,TIPS_FAILURE_COLOR);
		return;
	}
	
	int curTime = GetSysTime();
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	int size = m_footData.size();
	for(int i=0;i < size;i++)
	{
		if(m_footData[i].id == id)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0230,TIPS_FAILURE_COLOR);
			return;
		}
	}

	for(int i=0;i < (int)itemList.size();i++)
	{
		if(itemList[i].id == id)
		{
			int price = itemList[i].price;
			if(itemList[i].buy_type == 1)	// 元宝
			{
				if(GetTongBao() < price)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0232,TIPS_FAILURE_COLOR);
					return;
				}
				AddTongBao(-price);
				ItemCurrencyLog(m_roleId,id,1,1,price,GetTongBao(),YBL_BUY_FOOT_PRINT1);
			}
			else if(itemList[i].buy_type == 2)	// 绑元
			{
				if(GetTongBao(1) < price)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0233,TIPS_FAILURE_COLOR);
					return;
				}
				AddTongBao(-price,1);
				ItemCurrencyLog(m_roleId,id,1,1,price,GetTongBao(1),YBL_BUY_FOOT_PRINT2);
			}
			else if(itemList[i].buy_type == 3)	// 金币
			{
				if(GetMoney() < price)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0234,TIPS_FAILURE_COLOR);
					return;
				}
				AddMoney(-price);
				ItemCurrencyLog(m_roleId,id,1,1,price,GetMoney(),YBL_BUY_FOOT_PRINT3);
			}
			else
			{
				msg<<PRO_ERROR<<"";
				return;
			}

			char buf[512];
			SFootPrintData data;
			data.id = id;
			data.rank = itemList[i].rank;
			data.get_time = curTime;
			if(itemList[i].time > 0)
				data.end_time = curTime + itemList[i].time;
			else
				data.end_time = itemList[i].time;
			m_footData.push_back(data);
			snprintf(buf,sizeof(buf)-1,LANGUAGE_SSJ_0231,itemList[i].name.c_str());
			msg<<PRO_SUCCESS<<MakeStringColor(buf,TIPS_WARNING_COLOR);
			return;
		}
	}
	msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0235,TIPS_FAILURE_COLOR);
}

void CUser::EquipFootPrint(int id,CNetMessage &msg)
{
	if(id < 1)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0235,TIPS_FAILURE_COLOR);
		return;
	}
	if(id == GetUseFootPrintID())
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0237,TIPS_FAILURE_COLOR);
		return;
	}
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	int size = m_footData.size();
	if(size < 1)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0235,TIPS_FAILURE_COLOR);
		return;
	}
	for(int i=0;i < size;i++)
	{
		if(m_footData[i].id == id)
		{
			SetUseFootPrintID(id);
			msg<<PRO_SUCCESS;
			return;
		}
	}

	msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0236,TIPS_FAILURE_COLOR);
}

void CUser::UnEquipFootPrint(int id,CNetMessage &msg)
{
	if(id < 1)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0235,TIPS_FAILURE_COLOR);
		return;
	}
	if(GetUseFootPrintID() != id)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0238,TIPS_FAILURE_COLOR);
		return;
	}
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	int size = m_footData.size();
	if(size < 1)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0235,TIPS_FAILURE_COLOR);
		return;
	}
	for(int i=0;i < size;i++)
	{
		if(m_footData[i].id == id)
		{
			SetUseFootPrintID(0);
			msg<<PRO_SUCCESS;
			return;
		}
	}

	msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0236,TIPS_FAILURE_COLOR);
}


void CUser::SetUseFootPrintID(int id)
{
	NoLockSetExtData32(421,id);

	if(m_pScene != NULL)
		m_pScene->UpdateUserInfo(this,ESRT_Foot);
}

void CUser::ShowMysteryItems(const vector<UserMysteryItem> &itemList)
{
	if(m_mysteryTime<GetNextMysteryUpdateTime())
	{
		CreateMysteryItem(itemList);
		ClearAllMysteryBitSet();
		m_mysteryTime=GetNextMysteryUpdateTime();
	}
	SendMysterItemsInfo();
}

uint32 CUser::GetYaoShi()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return NoLockGetYaoShi();
}


uint32 CUser::NoLockGetYaoShi()
{
	return NoLockGetExtData32(407);
}

void CUser::SetYaoShi(uint32 yaoshi)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return NoLockSetYaoShi(yaoshi);
}


void CUser::NoLockSetYaoShi(uint32 yaoshi)
{
	return NoLockSetExtData32(407,yaoshi);
}

uint32 CUser::GetCostYaoShi()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return NoLockGetCostYaoShi();
}


uint32 CUser::NoLockGetCostYaoShi()
{
	return NoLockGetExtData32(408);
}

void CUser::SetCostYaoShi(uint32 costYaoshi)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return NoLockSetCostYaoShi(costYaoshi);
}


void CUser::NoLockSetCostYaoShi(uint32 costYaoshi)
{
	return NoLockSetExtData32(408,costYaoshi);
}

void CUser::SendYaoShiItemsInfo(vector<HDPeiZhiInfo> &peizhiInfo)
{
	uint32 nextYaoShiTime = GetNextYaoShiUpdateTime();
	uint32 curTime = GetSysTime();
	uint32 cdTime = nextYaoShiTime >= curTime ? nextYaoShiTime - curTime : 0;
	
	CNetMessage msg;
	msg.SetType(MSG_SHOP);
	msg<<(uint8)(CShopManager::ESOP_YaoShiShow);
	msg<<(uint32)CShopManager::REFRESH_YAOSHI_YB;
	msg<<cdTime;
	msg<<GetYaoShi()<<GetCostYaoShi();

	uint32 num = m_yaoshiItem.size();
	msg<<num;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint32 i=0;i < num;i++)
	{
		msg<<GetYaoShiLimitScore(i,peizhiInfo);
		msg<<m_yaoshiItem[i].id<<m_yaoshiItem[i].itemId;
		msg<<m_yaoshiItem[i].itemNum;
		msg<<m_yaoshiItem[i].price;
	}
	SingletonSocket::instance().SendMsg(m_sock,msg);
}


void CUser::SendMysterItemsInfo()
{
	CNetMessage msg;
	msg.SetType(MSG_SHOP);
	msg<<(uint8)(CShopManager::ESOP_MysteryShow);
	msg<<(GetNextMysteryUpdateTime() - (uint32)GetSysTime());

	uint8 num = m_mysteryItem.size();
	msg<<num;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint8 i=0;i < num;i++)
	{
		uint8 openlv=GetMysteryOpenlv(i);
		if(m_vipLevel>=openlv) //已开启
			openlv=0;
		msg<<openlv;
		if(openlv==0)
		{
			uint8 canBuyNum = 0;
			msg << m_mysteryItem[i].id << m_mysteryItem[i].itemId << m_mysteryItem[i].itemNum << m_mysteryItem[i].extValue;
			if (CanBuyMysteryItem(i))
			{
				if (m_mysteryItem[i].itemId == HDAT_PetEquip)
					canBuyNum = 1;
				else
					canBuyNum = m_mysteryItem[i].itemNum;
			}
			msg << (uint8)canBuyNum;
			if (m_mysteryItem[i].itemId == HDAT_PetEquip)
				msg << (uint16)m_mysteryItem[i].price;
			else
				msg << (uint16)(m_mysteryItem[i].price * m_mysteryItem[i].itemNum);
		}
	}
	SingletonSocket::instance().SendMsg(m_sock,msg);
}

void CUser::BuyYaoShiItems(uint32 buyId,uint32 showIndex,uint32 buyNum)
{
	char buf[128];
	if(buyId == 0 || buyNum == 0)
		return;

	vector<HDPeiZhiInfo> peizhiInfo;
	uint32 hd_type = CHuoDongAwardManager::YAOSHI_SHANGDIAN;
	SingletonCHuoDongAwardManager::instance().GetPeiZhiInfo(peizhiInfo,hd_type);
	if (peizhiInfo.size() == 0)
		return;

	CNetMessage msg;
	msg.SetType(MSG_SHOP);
	msg<<(uint8)(CShopManager::ESOP_YaoShiBuy);

	uint32 myYaoShi = GetYaoShi();
	uint32 myCostYaoShi = GetCostYaoShi();
	uint32 price = 0;
	uint32 itemId = 0;
	uint32 remainNum = 0;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	{
		uint32 size = m_yaoshiItem.size();
		if(showIndex >= size)
			return;

		if(m_yaoshiItem[showIndex].id == buyId)
		{
			uint32 limitScore=GetYaoShiLimitScore(showIndex,peizhiInfo);
			if(limitScore > myCostYaoShi)
			{
				snprintf(buf,sizeof(buf),LANGUAGE_LLD_0242,limitScore);
				msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
				SingletonSocket::instance().SendMsg(m_sock,msg);
				return;
			}
			
			if(buyNum <= m_yaoshiItem[showIndex].itemNum)
			{
				itemId = m_yaoshiItem[showIndex].itemId;
				price = buyNum * m_yaoshiItem[showIndex].price;
			
				if(myYaoShi < price)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0241,TIPS_FAILURE_COLOR);
					SingletonSocket::instance().SendMsg(m_sock,msg);
					return;
				}

				NoLockSetYaoShi(myYaoShi - price);
				NoLockSetCostYaoShi(myCostYaoShi + price);
				m_yaoshiItem[showIndex].itemNum -= buyNum;
				remainNum = m_yaoshiItem[showIndex].itemNum;
			}
			else
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0240,TIPS_FAILURE_COLOR);
			}	
		}
		else
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2334,TIPS_FAILURE_COLOR);
		}
	}

	if (itemId > 0)
	{
		AddPackage(itemId,buyNum);
		msg<<PRO_SUCCESS<<GetYaoShi()<<GetCostYaoShi();
		msg<<showIndex<<remainNum;

		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_2330, GetItemColor(itemId), GetItemName(itemId),buyNum);
		SendSysInfo(this, buf);
		ItemCurrencyLog(GetRoleId(),itemId,buyNum,0,price,GetYaoShi(),YBL_SHOP_YAOSHI);
	}
	SingletonSocket::instance().SendMsg(m_sock,msg);
}


void CUser::BuyMysteryItems(uint16 buyId,uint8 showIndex)
{
	if(buyId == 0)
		return;
	uint8 size = m_mysteryItem.size();
	if(showIndex >= size)
		return;

	CNetMessage msg;
	msg.SetType(MSG_SHOP);
	msg<<(uint8)(CShopManager::ESOP_MysteryBuy);

	if(m_mysteryItem[showIndex].id == buyId)
	{
		int openlv=GetMysteryOpenlv(showIndex);
		if(openlv>m_vipLevel)
			return;
		if(CanBuyMysteryItem(showIndex))
		{
			uint16 price = 0;
			if (m_mysteryItem[showIndex].itemId == HDAT_PetEquip)
				price = m_mysteryItem[showIndex].price;
			else
				price = m_mysteryItem[showIndex].itemNum * m_mysteryItem[showIndex].price;
			if(GetTongBao() < price)
			{
				msg<<PRO_ERROR<<"";
				SingletonSocket::instance().SendMsg(m_sock,msg);
				ShowJumpNotice(this,JUMP_NOTICE_YB);
				return;
			}
			AddMaterial(m_mysteryItem[showIndex].itemId,m_mysteryItem[showIndex].itemNum, false, false, m_mysteryItem[showIndex].extValue);
			AddTongBao(-price);
			SetMysteryBitSet(showIndex);

			char buf[512];
			char equipName[64];
			if (m_mysteryItem[showIndex].itemId == HDAT_PetEquip)
			{
				snprintf(equipName, sizeof(equipName), LANGUAGE_ZQX_0086, m_mysteryItem[showIndex].extValue,
					sCItemCfgManager.GetEquipName(m_mysteryItem[showIndex].itemNum));
			}
			if (m_mysteryItem[showIndex].itemId == HDAT_PetEquip)
				snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_2330, sCItemCfgManager.GetEquipColor(m_mysteryItem[showIndex].extValue), equipName, 1);
			else
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_2330, GetItemColor(m_mysteryItem[showIndex].itemId), GetItemName(m_mysteryItem[showIndex].itemId),(int)m_mysteryItem[showIndex].itemNum);
			msg<<PRO_SUCCESS<< buf;
			if (m_mysteryItem[showIndex].itemId == HDAT_PetEquip)
				snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_2331, ROLE_NAME_COLOR, GetName(), sCItemCfgManager.GetEquipColor(m_mysteryItem[showIndex].extValue), equipName, 1);
			else
				snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_2331, ROLE_NAME_COLOR, GetName(), GetItemColor(m_mysteryItem[showIndex].itemId),
					GetItemName(m_mysteryItem[showIndex].itemId), (int)m_mysteryItem[showIndex].itemNum);
			msg<<buf<<showIndex<<(uint8)0;
			ItemCurrencyLog(GetRoleId(),m_mysteryItem[showIndex].itemId,1,0,price,GetTongBao(),YBL_SHOP_MYSTERY);

			if (m_mysteryItem[showIndex].itemId == HDAT_PetEquip)
				snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_2332, ROLE_NAME_COLOR, GetName(), sCItemCfgManager.GetEquipColor(m_mysteryItem[showIndex].extValue), equipName, 1);
			else
				snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_2332, ROLE_NAME_COLOR, GetName(), GetItemColor(m_mysteryItem[showIndex].itemId),
					GetItemName(m_mysteryItem[showIndex].itemId), (int)m_mysteryItem[showIndex].itemNum);
			SysInfoToAllUser(buf);
		}
		else
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2333,TIPS_FAILURE_COLOR);
		}
	}
	else
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2334,TIPS_FAILURE_COLOR);
	}
	SingletonSocket::instance().SendMsg(m_sock,msg);
}

void CUser::SetMysteryBitSet(uint16 idx)	// idx 0~ShowMysteryItemNum-1
{
	SetBitSet(251+idx);
}

bool CUser::CanBuyMysteryItem(uint16 idx)	// idx 0~ShowMysteryItemNum-1
{
	return (!HaveBitSet(251+idx));
}

void CUser::BuyExchangeItem(CNetMessage &msg)
{
	uint8 type = 0;
	uint16 petId = 0xff;
	uint16 itemId = 0;
	uint8 itemNum = 0;
	msg>>type;

	uint16 exchangeItemId = 0;
	uint16 exchangeItemNum = 0;
//	char buf[512];
	if(type == 1)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		msg>>petId;
		if(petId == 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2335,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(m_sock,msg);
			return;
		}
		SPet *pPet = GetPet(petId).get();
		if(pPet == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2336,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(m_sock,msg);
			return;
		}
		if(pPet->quality < PQT_PURPLE)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2337,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(m_sock,msg);
			return;
		}
		if(pPet->chuzhanFlag == 1)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2338,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(m_sock,msg);
			return;
		}

//		uint8 srcNum = 0;
//		int zizhi = pPet->ziZhiCZ;
//		GetExchangeTarItem(1,zizhi,srcNum,exchangeItemId,exchangeItemNum);
		if(exchangeItemNum == 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2339,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(m_sock,msg);
			return;
		}

//		char tBuf[128];
//		snprintf(tBuf,sizeof(tBuf),"%s%d%s%s",QualityColorName[pPet->quality].c_str(),(int)pPet->qualityLevel,LANGUAGE_TRANSFORM_255,GetPetName(pPet->tmplId));
		NoLockDelPet(petId);

//		snprintf(buf,sizeof(buf),LANGUAGE_SSJ_1001,tBuf,1,GetItemName(exchangeItemId),exchangeItemNum);
//		SaveDate(m_roleId,718,1,buf);
	}
	if(exchangeItemNum > 0)
	{
		AddBangDingPackage(exchangeItemId,exchangeItemNum);
		msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_TRANSFORM_2340,TIPS_WARNING_COLOR);
		SingletonSocket::instance().SendMsg(m_sock,msg);
	}
	else if(type == 2)
	{
		char buf[128];
		msg>>itemId>>itemNum;
		if(itemId == 0 || itemNum == 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2341,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(m_sock,msg);
			return;
		}

		int srcItemNum = GetItemNum(itemId);
		uint8 needItemNum = 0;
		GetExchangeTarItem(2,itemId,needItemNum,exchangeItemId,exchangeItemNum);
		if(needItemNum == 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2342,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(m_sock,msg);
			return;
		}
		if(itemNum == 0 || itemNum > srcItemNum)
		{
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_2343,GetItemName(itemId));
			msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(m_sock,msg);
			return;
		}
		if(itemNum%needItemNum != 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2344,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(m_sock,msg);
			return;
		}

		exchangeItemNum *= (uint16)(itemNum/needItemNum);
		DelPackageById(itemId,itemNum);
		AddBangDingPackage(exchangeItemId,exchangeItemNum);
		msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_TRANSFORM_2345,TIPS_WARNING_COLOR);
		SingletonSocket::instance().SendMsg(m_sock,msg);

		snprintf(buf,sizeof(buf),LANGUAGE_SSJ_1001,GetItemName(itemId),(uint32)itemNum,GetItemName(exchangeItemId),exchangeItemNum);
		SaveDate(m_roleId,718,2,buf);
	}
}

void CUser::ClearAllMysteryBitSet()
{
	for(uint8 i=0;i <= ShowMysteryItemNum;i++)
		ClearBitSet(251+i);
}

void CUser::SendShenhunItemsInfo()
{
	CNetMessage msg;
	msg.SetType(MSG_SHOP);
	msg << (uint8)(CShopManager::ESOP_ShenhunShow);
	msg << (GetNextShenhunUpdateTime() - (uint32)GetSysTime());
	uint8 num = m_shenhunItem.size();
	msg << num;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for (uint8 i = 0; i < num; i++)
	{
		msg << m_shenhunItem[i].id << m_shenhunItem[i].itemId;
		if (CanBuyShenhunItem(i))
			msg << m_shenhunItem[i].itemNum;
		else
			msg << (uint8)0;
		msg << (uint16)(m_shenhunItem[i].itemNum * m_shenhunItem[i].price);
	}
	SingletonSocket::instance().SendMsg(m_sock, msg);
}
void CUser::ShowShenhunItems(const vector<UserMysteryItem> &itemList)
{
	if (m_shenhunTime < GetNextShenhunUpdateTime())
	{
		CreateShenhunItem(itemList);
		ClearAllShenhunBitSet();
		m_shenhunTime = GetNextShenhunUpdateTime();
	}
	SendShenhunItemsInfo();
}
void CUser::CreateShenhunItem(const vector<UserMysteryItem> &itemList)
{
	m_shenhunItem.clear();
	std::vector<int> itemInd(itemList.size());
	std::vector<int> itemRate(itemList.size());
	int itemTotal;
	int rateTotal;
	int selInd;
	int r;
	for (int i = 0; i < ShowShenjiangItemNum; i++)
	{
		itemTotal = 0;
		rateTotal = 0;
		for (int j = 0; j < (int)itemList.size(); j++)
		{
			if (FindShenhunItem(itemList[j].itemId))
				continue;
			itemInd[itemTotal] = j;
			rateTotal += itemList[j].rate[i];
			itemRate[itemTotal] = rateTotal;
			itemTotal++;
		}
		r = Random(1, rateTotal);
		selInd = 0;
		for (int j = 0; j < itemTotal; j++)
		{
			if (r <= itemRate[j])
			{
				selInd = j;
				break;
			}
		}
		m_shenhunItem.push_back(itemList[itemInd[selInd]]);
	}
}
bool CUser::FindShenhunItem(int id)
{
	for (uint8 i = 0; i < m_shenhunItem.size(); i++)
	{
		if (m_shenhunItem[i].itemId == id)
			return true;
	}
	return false;
}
void CUser::BuyShenhunItems(uint16 buyId, uint8 showIndex)
{
	if (buyId == 0)
		return;
	uint8 size = m_shenhunItem.size();
	if (showIndex >= size)
		return;
	CNetMessage msg;
	msg.SetType(MSG_SHOP);
	msg << (uint8)(CShopManager::ESOP_ShenhunBuy);
	if (m_shenhunItem[showIndex].id == buyId)
	{
		if (!CanBuyShenhunItem(showIndex))
		{
			msg << PRO_ERROR << LANGUAGE_TRANSFORM_2333;
			SingletonSocket::instance().SendMsg(m_sock, msg);
			return;
		}
		uint16 price = m_shenhunItem[showIndex].itemNum * m_shenhunItem[showIndex].price;
		if (GetShenhun() < price)
		{
			char buf[128];
			snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_2343, GetItemName(60014));
			msg << PRO_ERROR << buf;
			SingletonSocket::instance().SendMsg(m_sock, msg);
			return;
		}
		AddPackage(m_shenhunItem[showIndex].itemId, m_shenhunItem[showIndex].itemNum);
		AddShenhun(-price);
		SetShenhunBitSet(showIndex);
		char buf[512];
		snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_2330, GetItemColor(m_shenhunItem[showIndex].itemId), GetItemName(m_shenhunItem[showIndex].itemId), (int)m_shenhunItem[showIndex].itemNum);
		msg << PRO_SUCCESS << buf;
		snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_2331, ROLE_NAME_COLOR, GetName(), ITEM_NAME_COLOR,
			GetItemName(m_shenhunItem[showIndex].itemId), (int)m_shenhunItem[showIndex].itemNum);
		msg << buf << showIndex << (uint8)0;

		if (m_mysteryItem[showIndex].itemId == HDAT_NumType)
			snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_2332, ROLE_NAME_COLOR, GetName(), ITEM_NAME_COLOR,
				sCItemCfgManager.GetEquipName(m_shenhunItem[showIndex].itemId), 1);
		else
			snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_2332, ROLE_NAME_COLOR, GetName(), GetItemColor(m_shenhunItem[showIndex].itemId),
				GetItemName(m_shenhunItem[showIndex].itemId), (int)m_mysteryItem[showIndex].itemNum);

		SysInfoToAllUser(buf);
	}
	else
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_2334, TIPS_FAILURE_COLOR);
	}
	SingletonSocket::instance().SendMsg(m_sock, msg);
}
void CUser::SetShenhunBitSet(uint16 idx)
{
	SetBitSet(261 + idx);
}
bool CUser::CanBuyShenhunItem(uint16 idx)
{
	return (!HaveBitSet(261 + idx));
}
void CUser::ClearAllShenhunBitSet()
{
	for (uint8 i = 0; i <= ShowShenjiangItemNum; i++)
		ClearBitSet(261 + i);
}
uint8 CUser::GetShopDiscountBuyNum(uint8 idx)
{
	if(idx >= CShopManager::SHOW_DISCOUNT_NUM)
		return 0;
	return GetExtData8(151+idx);
}

void CUser::AddShopDiscountBuyNum(uint8 idx)
{
	if(idx >= CShopManager::SHOW_DISCOUNT_NUM)
		return;
	SetExtData8(151+idx,GetExtData8(151+idx)+1);
}

void CUser::ClearShopDiscountBuyNum()
{
	for(uint8 i=0;i < CShopManager::SHOW_DISCOUNT_NUM;i++)
		SetExtData8(151+i,0);
}

uint16 CUser::GetShopDiscountTotolNum()
{
	uint16 num = 0;
	for(uint8 i=0;i < CShopManager::SHOW_DISCOUNT_NUM;i++)
		num += GetExtData8(151+i);
	return num;
}

void CUser::UpdateVipInfo()
{
	CNetMessage msg;
	msg.SetType(MSG_VIP_OPTION);

	uint32 vipTime = 0;
//	uint8 getAward = 0;	// 0不能领取1可领
//	uint8 getYB = 0;	// 0不可领取1可领
	uint32 tiyanTime = 0;
	if(GetExtData32(86) > (uint32)GetSysTime())
		vipTime = GetExtData32(86) - GetSysTime();
	if (GetExtData32(467) > (uint32)GetSysTime())
		tiyanTime = GetExtData32(467) - GetSysTime();
//	if(!HaveBitSet(302))
//		getAward = 1;
//	if(!HaveBitSet(347))
//		getYB = 1;
	int cardType = GetMonthCard();
	uint8 getValue = GetExtData8(108);
	msg << (uint8)4 << GetVipLevel() << GetChongzhiTotal() + GetExVipExp() << GetChongzhiTotal() << GetMonthCard() << getValue << vipTime;
	if (((cardType >> 3) & 1) == 1)
		msg << tiyanTime;
	SingletonSocket::instance().SendMsg(m_sock, msg);
}

bool CUser::AddBaiHuaChip(uint8 type,int num,uint8 showType)
{
	/*
	type=1	副本
	type=2	师门任务
	type=3	运镖
	type=4	抢镖
	type=5	维护丹园
	*/
	/*
	showType=0 战斗结束之后显示
	showType=1 正常tips
	showType=2 不显示
	*/

	if(m_level < 30)
		return false;

	const uint16 bitset[] = {103,104,105,106,107};
	const uint8 limitNum[] = {10,0,0,15,0};
	const int ratio[] = {50,50,50,20,50};

	if(type == 0 || type > sizeof(bitset)/sizeof(bitset[0]))
		return false;
	if(GetExtData8(bitset[type-1]) + (uint8)num > limitNum[type-1])
		return false;
	if(Random(1,100) <= ratio[type-1])
	{
		SetExtData8(bitset[type-1],GetExtData8(bitset[type-1])+(uint8)num);
		AddBangDingPackage(1099,num);

		if(type != 2 && type != 5)	// 师门和丹园脚本中显示
		{
			char buf[128];
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_2346,GetItemName(1099),num);
			if(showType == 0)
				SendSysInfoFightEnd(this,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
			else if(showType == 1)
				SendSysInfo(this,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
		}
		return true;
	}
	return false;
}

void CUser::AddMoney(int add)
{
	m_money += add;
	if(m_money > MAX_MONEY)
		m_money = MAX_MONEY;
	SendUpdateInfo(EUUT_Money);
}

void CUser::GetDropItem(string &item)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	item = m_dropItem;
	m_dropItem.clear();
}

struct SAddHpMpItem
{
	uint8 pos;
	uint16 id;
};

bool AddHpMpLess(const SAddHpMpItem &item1,const SAddHpMpItem &item2)
{
	return item1.id<item2.id;
}

void CUser::MoveItem(uint8 srcPos,uint8 tarPos)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	uint8 curMaxPackNum = MAX_PACKAGE_NUM;
	if((srcPos >= MAX_PACKAGE_NUM2) || (tarPos >= MAX_PACKAGE_NUM2))
		return;
	if(srcPos == tarPos)
		return;

//	CSocketServer &sock = SingletonSocket::instance();

	if((m_package[srcPos].tmplId == 0) || (m_package[tarPos].tmplId == 0))	//有一个格子是空，交换位置
	{
		if((tarPos >= curMaxPackNum) && (m_package[tarPos].tmplId == 0))
			return;

		if((srcPos >= curMaxPackNum) && (m_package[srcPos].tmplId == 0))
			return;

		std::swap(m_package[srcPos],m_package[tarPos]);
//		CNetMessage msg;
//		msg.SetType(PRO_UPDATE_PACK);
//		msg<<(uint8)2;		// update
//		MakePack(m_package[srcPos],srcPos,msg);
//		sock.SendMsg(m_sock,msg);
//		msg.ReWrite();
//		msg.SetType(PRO_UPDATE_PACK);
//		msg<<(uint8)2;		// update
//		MakePack(m_package[tarPos],tarPos,msg);
//		sock.SendMsg(m_sock,msg);
		return;
	}

	CItemTemplateManager &itemMgr = SingletonItemManager::instance();
	SItemTemplate *pItemSrc = itemMgr.GetItem(m_package[srcPos].tmplId);
	SItemTemplate *pItemTar = itemMgr.GetItem(m_package[tarPos].tmplId);
	if((pItemSrc == NULL) || (pItemTar == NULL))
		return;

	bool canDieJia = false;
	if((pItemSrc->id == pItemTar->id) && (m_package[srcPos] == m_package[tarPos]))	//类型相同
		canDieJia = IsItemCanMerge(pItemSrc->type);
	if(canDieJia)
	{
		if(tarPos >= curMaxPackNum)
			return;
		uint16 tolNum = (uint16)m_package[srcPos].num + (uint16)m_package[tarPos].num;
		if(tolNum <= EItemDieJiaNum)
		{
			m_package[tarPos].num = (uint8)tolNum;
			m_package[srcPos].Clear();
		}
		else
		{
			m_package[tarPos].num = EItemDieJiaNum;
			m_package[srcPos].num = tolNum - EItemDieJiaNum;
		}
	}
	else
	{
		if((srcPos >= curMaxPackNum) || (tarPos >= curMaxPackNum))
			return;
		std::swap(m_package[srcPos],m_package[tarPos]);
	}

//	CNetMessage msg;
//	msg.SetType(PRO_UPDATE_PACK);
//	msg<<(uint8)2;		// update
//	MakePack(m_package[srcPos],srcPos,msg);
//	sock.SendMsg(m_sock,msg);
//	msg.ReWrite();
//	msg.SetType(PRO_UPDATE_PACK);
//	msg<<(uint8)2;		// update
//	MakePack(m_package[tarPos],tarPos,msg);
//	sock.SendMsg(m_sock,msg);
}

bool CUser::InScriptCallOption(int val)
{
	if (val == -1)
		return true;

	for(list<int>::iterator i=m_scriptOption.begin(); i != m_scriptOption.end(); i++)
	{
		if(*i == val)
			return true;
	}
	return false;
}

void CUser::GetScriptCallOption(list<int> &val)
{
	val = m_scriptOption;
}

void CUser::SetScriptCallOption(list<int> *val)
{
	m_scriptOption.clear();
	if(val != NULL)
		m_scriptOption = *val;
}

const char *CUser::GetCall(int &script)
{
	script = m_script;
	return m_scriptCall.c_str();
	/*boost::recursive_mutex::scoped_lock lk(m_mutex);
	  if(m_scriptHeap.size() <= 0)
	  {
	  script = 0;
	  return "";
	  }
	  list<SScriptCall>::iterator i = m_scriptHeap.end();
	  i--;
	  script = i->scriptId;
	  string &val = i->func;
	  if(m_scriptHeap.size() > 1)
	  m_scriptHeap.pop_front();
	  return val.c_str();*/
}

void CUser::SetCall(int script,const char *call)
{
	if (script != 10000)
		m_script = script;
	if(call != NULL)
		m_scriptCall = call;
	/*********
	  boost::recursive_mutex::scoped_lock lk(m_mutex);
	  SScriptCall scriptCall;
	  if(call == NULL)
	  scriptCall.func.clear();
	  else
	  scriptCall.func = call;
	  scriptCall.scriptId = script;
	  m_scriptHeap.push_back(scriptCall);
	 *************/
}

void CUser::SetCallScript(int script)
{
	if (script != 10000)
		m_script = script;
	/************88
	  boost::recursive_mutex::scoped_lock lk(m_mutex);
	  SScriptCall scriptCall;
	  scriptCall.scriptId = 0;
	  if(m_scriptHeap.size() <= 0)
	  {
	  scriptCall.scriptId = script;
	  return;
	  }
	  list<SScriptCall>::iterator i = m_scriptHeap.end();
	  i--;
	  if(i->scriptId == 0)
	  {
	  i->scriptId = script;
	  }
	  else
	  {
	  m_scriptHeap.push_back(scriptCall);
	  }
	 **************/
}

void CUser::SetCallFun(const char *call)
{
	if(call != NULL)
	{
		m_scriptCall = call;
//		cout<<">> NpcInteract SetCallFun="<<call<<endl;
	}
	//cout << "设置回调函数：" << call << endl;
	/*if(call == NULL)
	  return;

	  boost::recursive_mutex::scoped_lock lk(m_mutex);
	  SScriptCall scriptCall;
	  scriptCall.scriptId = 0;
	  scriptCall.func = call;

	  if(m_scriptHeap.size() <= 0)
	  {
	  m_scriptHeap.push_back(scriptCall);
	  return;
	  }
	  list<SScriptCall>::iterator i = m_scriptHeap.end();
	  i--;
	  if(i->func.empty())
	  {
	  i->func = call;
	  }
	  else
	  {
	  m_scriptHeap.push_back(scriptCall);
	  }*/
}

bool CUser::HavePet(uint16 petId)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return NoLockHavePet(petId);
}

bool CUser::NoLockHavePet(uint16 petId)
{
	CPetMapIt it = m_pet.find(petId);
	if(it != m_pet.end())
		return true;
	return false;
}

bool CUser::HaveWing(uint8 id)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return m_wing.HaveWing(id);
}

bool CUser::AddTongBao(int tongbao,uint8 type,int serverId,bool huodongAdd)
{
	char sqlBuf[128];
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return false;
	int sid = serverId;
	if(sid == 0)
		sid = m_serverId;

	if(type == 1)
	{
		snprintf(sqlBuf,sizeof(sqlBuf),"update %s set bd_money=bd_money+%d where id=%u",GetUserInfoTab(sid).c_str(),tongbao,m_userId);
		if(pDb->Query(sqlBuf))
		{
			boost::recursive_mutex::scoped_lock lk(m_mutex);
			m_bdTongBao += tongbao;
			SendUpdateInfo(EUUT_BangDingYB);
			return true;
		}
	}
	else
	{
		snprintf(sqlBuf,sizeof(sqlBuf),"update %s set money=money+%d where id=%u",GetUserInfoTab(sid).c_str(),tongbao,m_userId);
		if(pDb->Query(sqlBuf))
		{
			if(tongbao < 0 && huodongAdd)
			{
				CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
				
				if(awardManager.InHuoDongTime(CHuoDongAwardManager::LEI_JI_XIAOFEI))
					SetExtData32(122,GetExtData32(122)+(-tongbao));
				if(awardManager.InHuoDongTime(CHuoDongAwardManager::LEI_JI_XIAOFEI2))
					SetExtData32(140,GetExtData32(140)+(-tongbao));

				uint32 MRXFList[] = {CHuoDongAwardManager::MEIRI_XIAOFEI1,CHuoDongAwardManager::MEIRI_XIAOFEI2,CHuoDongAwardManager::MEIRI_XIAOFEI3,
					CHuoDongAwardManager::MEIRI_XIAOFEI4,CHuoDongAwardManager::MEIRI_XIAOFEI5};
				for (uint32 i = 0; i < sizeof(MRXFList)/sizeof(MRXFList[0]); i++)
				{
					if(awardManager.InHuoDongTime(MRXFList[i]))
					{
						uint32 totalXFDataId = 0;
						uint32 maskDataId = 0;
						if(GetMeiRiXiaoFeiYBDataId(MRXFList[i],totalXFDataId,maskDataId))
							SetExtData32(totalXFDataId,GetExtData32(totalXFDataId)+(-tongbao));
					}
				}

				uint32 HLXFList[] = {CHuoDongAwardManager::HONGLI_XIAOFEI,CHuoDongAwardManager::HONGLI_XIAOFEI2,CHuoDongAwardManager::HONGLI_XIAOFEI3,
					CHuoDongAwardManager::HONGLI_XIAOFEI4,CHuoDongAwardManager::HONGLI_XIAOFEI5};
				for (uint32 i = 0; i < sizeof(HLXFList)/sizeof(HLXFList[0]); i++)
				{
					uint32 timeDataId = 0;
					uint32 leijiDataId = 0;
					uint32 maskDataId = 0;
					if (GetHongLiDataId(HLXFList[i],timeDataId,leijiDataId,maskDataId))
					{
						uint32 hongliLeijiTime = awardManager.GetHuoDongLeijiTime(HLXFList[i]);
						uint32 curTime = GetSysTime();
						uint32 cdTime = (curTime > hongliLeijiTime) ? 0 : hongliLeijiTime - curTime;
						if (awardManager.InHuoDongTime(HLXFList[i]) && (cdTime > 0))
							SetExtData32(leijiDataId,GetExtData32(leijiDataId)+(-tongbao));
					}
				}
			}
			
			boost::recursive_mutex::scoped_lock lk(m_mutex);
			m_tongBao += tongbao;
			SendUpdateMoney(HDAT_YB);
			return true;
		}
	}
	return false;
}

bool CUser::AddTongBaoEx(int tongbao, uint8 type/* = 0*/, int addtype/* = 1*/)
{
	int curYB = GetTongBao();
	char sql[1024];
	snprintf(sql, sizeof(sql), "INSERT INTO `user_yuanbao_jilu` (`role_id`, `type`, `num`, `befor`, `after`) VALUES (%d, %d, %d, %d, %d)", GetRoleId(), addtype, tongbao, curYB, curYB + tongbao);
	SendLongQuerySql(sql);
	AddTongBao(tongbao, type);
	return true;
}

// 增加竞技场积分
void CUser::AddArenaJiFen(int addJiFen)
{
	int curJiFen = GetExtData32(97);
	if ((addJiFen + curJiFen) > 0)
	{
		SetExtData32(97,curJiFen+addJiFen);
	}
	else
		SetExtData32(97,0);

	// 积分变动会主动同步玩家当前竞技场积分
	SendUpdateInfo(EUUT_ArenaScore); // 更新客户端竞技场积分
}

int CUser::GetBangGong()
{
	int value = GetExtData32(91);
	if(value < 0)
	{
		SetExtData32(91,0);
		value = 0;
	}
	return value;
}

int CUser::GetBangState()
{
	CBangPai *pBangPai = SingletonCBangPaiManager::instance().FindBangPai(m_bangpai);
	if(pBangPai == NULL)
		return 0;
	return (pBangPai->dismissbang_time == 0 ? 1 : 0);
}

int CUser::GetBangRank()
{
	CBangPai *pBangPai = SingletonCBangPaiManager::instance().FindBangPai(m_bangpai);
	if(pBangPai == NULL)
		return 0;
	return pBangPai->GetMemberRank(m_roleId);
}

string CUser::GetBangName()
{
	CBangPai *pBangPai = SingletonCBangPaiManager::instance().FindBangPai(m_bangpai);
	if(pBangPai == NULL)
		return "";
	return pBangPai->GetName();
}

void CUser::DismissBang()// 解散帮派
{
	CBangPai *pBangPai = SingletonCBangPaiManager::instance().FindBangPai(m_bangpai);
	if(pBangPai == NULL)
		return;
	pBangPai->dismissbang_time = GetSysTime();
//	pBangPai->DismissBang(m_roleId);
}

int CUser::GetmissDay()
{
	CBangPai *pBangPai = SingletonCBangPaiManager::instance().FindBangPai(m_bangpai);
	if(pBangPai == NULL)
		return -1;
	return (7 - ((int)(GetSysTime() - pBangPai->dismissbang_time))/(3600*24));
}

void CUser::UndismissBang()// 解除解散状态
{
	CBangPai *pBangPai = SingletonCBangPaiManager::instance().FindBangPai(m_bangpai);
	if(pBangPai == NULL)
		return;
	pBangPai->dismissbang_time = 0;
//	pBangPai->UndismissBang(m_roleId);
}

void CUser::UpdateBangPai()
{
	CBangPai *pBangPai = SingletonCBangPaiManager::instance().FindBangPai(m_bangpai);
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_MY_BANG);
	msg<<(uint8)1;
	if(pBangPai == NULL)
	{
		msg<<0;
		sock.SendMsg(m_sock,msg);
		return;
	}
	uint8 rank = pBangPai->GetMemberRank(m_roleId);
//	uint32 bangGong = GetData32(5);

	msg<<m_bangpai<<pBangPai->GetPic()<<pBangPai->GetName()<<pBangPai->GetLevel()<<pBangPai->GetMemberNum()<<pBangPai->GetMaxMemberNum()
		<<pBangPai->GetGongGao()<<pBangPai->GetExp()<<pBangPai->GetLevelUpExp()<<rank<<GetBangGong()<< pBangPai->GetMoney()<<GetBangPaiShowInfo();
	uint8 canGetAward = (uint8)HaveBitSet(349);	// 0显示小红点 1不显示
	if(!HaveBitSet(349) && pBangPai->GetYesterdayBangGong() == 0)
		canGetAward = 1;
	vector<uint8> vecLianQiLv;
    pBangPai->GetLianQiPavilionLv(vecLianQiLv);
    vector<SAttrTypeValue> vec;
	pBangPai->GetSkillLv(vec);
	msg<<pBangPai->GetBangZhuName()<<canGetAward<<pBangPai->GetAutoAcceptLv()<<pBangPai->GetHuoYue()<<(uint32)GetExtData16(67);
	uint8 size = vecLianQiLv.size();
	uint8 skillSize = vec.size();
	uint8 tNum = size+skillSize;
	msg<<tNum;
	for(uint8 i=0;i<size;i++)
	{
		uint16 type = i+1;
		msg<<type<<vecLianQiLv[i];
	}
	for(uint8 i=0;i<skillSize;i++)
	{
		msg<<(uint16)vec[i].type<<(uint8)vec[i].value;
	}
	sock.SendMsg(m_sock,msg);
}

//发送帮派种植次数
void CUser::SendBangPaiPlantCnt()
{
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_BANGPAI_ZHONGZHI);
	msg<< (uint8)47<<(uint8)ZZGain_MAX_Type;
	int max = ZZGain_MAX_Type+1;
	//std::vector<uint8> vecCnt;
	for(int i=1;i<max;i++)
	{
		uint8 plantSeedCount = GetPlantSeedTypeCount(i);
        uint8 maxCnt = PLANT_SEED_TYPE_COUNT_LIMIT[i]+G_VipConfig[GetVipLevel()].seedtype[i-1];
        msg<<plantSeedCount<<maxCnt;
	}
    sock.SendMsg(m_sock,msg);
}

void CUser::UpdateBangHuoYue(int type,int num)
{
	if (m_bangpai < 1)
		return;
	CBangPai *pBangPai = SingletonCBangPaiManager::instance().FindBangPai(m_bangpai);
	if(pBangPai == NULL)
		return;
	switch (type)
	{
		case EBHT_OnLineTime1:
		case EBHT_OnLineTime2:
		case EBHT_OnLineTime3:
	#ifdef KUA_FU
		pBangPai->UpdateHuoYue_KuaFu(this,type);
    #else
		pBangPai->UpdateHuoYue(this,type);
	#endif
			break;
		case EBHT_Login:
		case EBHT_KillPlayer:
		case EBHT_Skill:
		case EBHT_ShopBuy:
		case EBHT_KillBug:		// 除虫
		case EBHT_Watering:		// 浇水
		case EBHT_Steal:			// 偷菜
			pBangPai->UpdateHuoYue(this,type,num);
			break;
		default:
			break;
	}
}

int CUser::AddBangHuoYue(int value)
{
	int max = SingletonCBPRewardCfgMgr::instance().GetMaxHuoYue(1);
	uint16 cur = GetExtData16(67);
	int huoyue = cur+value;
	if (huoyue > max)
	{
		value = max-cur;
	}
	SetExtData16(67,cur+value);
	return value;
}

//获得当前活跃/总活跃
bool CUser::GetBangHuoYueDesc(int type,SAttrTypeValue &val)
{
	int huoyue = SingletonCBPHuoYueCfgMgr::instance().GetHuoYue(type);
	if (huoyue < 1)
		return false;
	int max = SingletonCBPHuoYueCfgMgr::instance().GetParam(type);
	int index = 650+type;
	uint8 cur = GetExtData8(index);
    
	switch (type)
	{
		case EBHT_OnLineTime1:
		case EBHT_OnLineTime2:
		case EBHT_OnLineTime3:   
			if (cur < max)
			{
				val.type = 0;
				val.value = huoyue;
			}
			else
			{
				val.type = huoyue;
				val.value = huoyue;
			}
			break;
		default:
			val.type = cur*huoyue;
			val.value = max*huoyue;
			break;
	}
	return true;
}

//升级帮派技能(个人）
bool CUser::UpBangSkillLv(CNetMessage &msg,int id,bool isAuto)
{
	if (m_bangpai < 1)
	{
		//提示必须加入帮派
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0297,TIPS_FAILURE_COLOR);
		return false;
	}
	CBangPai *pBangPai = SingletonCBangPaiManager::instance().FindBangPai(m_bangpai);
	if(pBangPai == NULL)
	{
		//提示必须加入帮派
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0297,TIPS_FAILURE_COLOR);
		return false;
	}

	int level = pBangPai->GetSkillLv(id);
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if (level <= m_bangSkills[id])
	{
		//提示不能比帮派内高
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_CC_0006,TIPS_FAILURE_COLOR);
		return false;
	}

	int cur = m_bangSkills[id];
	int max = cur+1;
	if(isAuto)
	{
		max = level;
	}
	bool isSign = false;
	for(int k=cur;k<max;k++)
	{
		SBangPaiSkillData cfgData;
		sCBPSkillCfgMgr.GetCfg(id,m_bangSkills[id],cfgData);
		if (cfgData.id < 1)
		{
			if(!isSign)
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1583,TIPS_FAILURE_COLOR);
				return false;
			}
			break;
		}
		//检查金钱是否足够
		bool isBreak = false;
		for(int i=0;i<(int)cfgData.singleCost.size();i++)
		{
			if(cfgData.singleCost[i].costType == HDAT_MONEY)// 金币
			{
				if(GetMoney() < cfgData.singleCost[i].costValue)
				{
					if(!isSign)
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0418,TIPS_FAILURE_COLOR);
						return false;
					}
					isBreak = true;
					break;
				}
			}
			else if(cfgData.singleCost[i].costType == HDAT_BANG_YB)// 绑元
			{
				if(GetTongBao(1) < cfgData.singleCost[i].costValue)
				{
					if(!isSign)
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0419,TIPS_FAILURE_COLOR);
						return false;
					}
					isBreak = true;
					break;
				}
			}
			else if(cfgData.singleCost[i].costType == HDAT_YB)// 元宝
			{
				if(GetTongBao() < cfgData.singleCost[i].costValue)
				{
					if(!isSign)
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0414,TIPS_FAILURE_COLOR);
						return false;
					}
					isBreak = true;
					break;
				}
			}
			else if(cfgData.singleCost[i].costType == HDAT_BANG_GONG)// 帮贡
			{
				if(GetBangGong() < cfgData.singleCost[i].costValue)
				{
					if(!isSign)
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0298,TIPS_FAILURE_COLOR);
						return false;
					}
					isBreak = true;
					break;
				}
			}
		}
		if(isBreak)
			break;
		//扣除金钱
		for(int i=0;i<(int)cfgData.singleCost.size();i++)
		{
			if(cfgData.singleCost[i].costType == HDAT_MONEY)// 金币
			{
				AddMoney(-1*cfgData.singleCost[i].costValue);
			}
			else if(cfgData.singleCost[i].costType == HDAT_BANG_YB)// 绑元
			{
				AddTongBao(-1*cfgData.singleCost[i].costValue,1);
			}
			else if(cfgData.singleCost[i].costType == HDAT_YB)// 元宝
			{
				AddTongBao(-1*cfgData.singleCost[i].costValue);
			}
			else if(cfgData.singleCost[i].costType == HDAT_BANG_GONG)// 帮贡
			{
				SingletonCBangPaiManager::instance().AddBangGong(this,-1*cfgData.singleCost[i].costValue);
			}
		}
		m_bangSkills[id] += 1;
		isSign = true;
	}
	msg<<PRO_SUCCESS<<(uint8)m_bangSkills[id];
	UpdateBangHuoYue(EBHT_Skill);
    return true;
}

void CUser::SetBangSkill(const char *skills)
{
	char buf[256];
	char *p[10];
	strncpy(buf,skills,sizeof(buf));
	int num = SplitLine(p,buf,'|');
	for(int i=0;i<num;i++)
	{
		char tbuf[64];
		int tnum = 0;
		char *tp[2];
		strncpy(tbuf,p[i],sizeof(tbuf));
		tnum = SplitLine(tp,tbuf,'-');
		if(tnum > 1)
		{
			int id = atoi(tp[0]);
			int level = atoi(tp[1]);
			m_bangSkills[id] = level;
		}
	}
}

void CUser::GetBangSkill(string &str)
{
	str.clear();
	map<int,int>::iterator it;
	for(it = m_bangSkills.begin();it!=m_bangSkills.end();it++)
	{
		if(it != m_bangSkills.begin())
			str += "|";
		str += IntToStr(it->first) + "-" + IntToStr(it->second);
	}
}

bool CUser::MakeBangSkill(CNetMessage &msg)
{
	vector<int> skillIds;
	sCBPSkillCfgMgr.GetSkillIds(skillIds);
	if (skillIds.size() == 0)
	{
		return false;
	}
	//uint16 numPos = msg.GetDataLen();
	uint8 num = skillIds.size();
	msg << num;
	map<int,int>::iterator it;
	for(int i=0;i<num;i++)
	{
		uint16 id = uint16(skillIds[i]);
		uint8 level = uint8(m_bangSkills[id]);
		msg << id << level;
	}
	return true;
	//msg.WriteData(numPos,&num,sizeof(num));
}


//获取帮派技能属性，@param type 1-主角，2-神将
void CUser::GetBangSkillAttr(int type,vector<SAttrData> &attr)
{ 
	attr.clear();
	map<int,int>::iterator it;
	for(it = m_bangSkills.begin();it != m_bangSkills.end();it++)
	{
		SBangPaiSkillData cfgData;
		if(!sCBPSkillCfgMgr.GetCfg(it->first,it->second,cfgData) || (cfgData.type != 3 && cfgData.type != type))
			continue;
		for(int k=0;k<(int)cfgData.attrs.size();k++)
		{
			bool sign = false;
			SAttrData &val = cfgData.attrs[k];
			for(uint16 i=0;i<attr.size();i++)
			{
				if(attr[i].attrType == val.attrType)
				{
					attr[i].attrValue += val.attrValue;
					sign = true;
					break;
				}
			}
			if (!sign)
			{
				attr.push_back(val);
			}
		}
	}
}

int CUser::GetItemNum(int id, int level)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return NoLockGetItemNum(id,level);
}

int CUser::NoLockGetItemNum(int id, int level)
{
	if(level == 0)
	{
		map<uint16,uint32>::iterator it = m_itemNumMap.find(id);
		if(it != m_itemNumMap.end())
			return (int)(it->second);
		else
			return 0;
	}
	else
	{
		int num = 0;
		for(uint8 pos = 0; pos < MAX_PACKAGE_NUM; pos++)
		{
			if(m_package[pos].tmplId == id)
			{
				if(level != 0)
				{
					if(m_package[pos].level == level)
						num += (int)m_package[pos].num;
				}
				else
					num += (int)m_package[pos].num;
			}
		}
		return num;
	}
}

bool CUser::UseMultiCost(MultiCost& cost)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for (uint8 i = 0; i < cost.size(); ++i)
	{
		if (GetMaterial(cost[i].costType) < (uint32)cost[i].costValue)
		{
			return false;
		}
	}
	for (uint8 i = 0; i < cost.size(); ++i)
	{
		SubMaterial(cost[i].costType, cost[i].costValue);
	}
	return true;
}


bool CUser::NolockUpdateItemNumMap(uint16 itemId,uint32 num,bool add)
{
	if(itemId == 0)
		return true;

	map<uint16,uint32>::iterator it = m_itemNumMap.find(itemId);
	if(add)
	{
		if(it != m_itemNumMap.end())
		{
			it->second += num;
		}
		else
		{
			pair<map<uint16,uint32>::iterator,bool> ret = m_itemNumMap.insert(make_pair(itemId,num));
			if(!ret.second)
				return false;
		}
	}
	else
	{
		if(it != m_itemNumMap.end())
		{
			if(m_itemNumMap[itemId] > num)
				m_itemNumMap[itemId] -= num;
			else
				m_itemNumMap.erase(it);
		}
	}
	return true;
}

// 删除特定等级的物品数量
bool CUser::DelPackageByIdLevel(int id, int level, int num)
{
	if(num == 0)
		return false;
	if(num < 0)
		num = 0xffff;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint8 pos = 0; pos < MAX_PACKAGE_NUM2; pos++)
	{
		if(m_package[pos].tmplId == id)
		{
			if ((level != 0) && (m_package[pos].level != level))
				continue;

			if(m_package[pos].num > num)
			{
				NolockUpdateItemNumMap(id,num,false);
				m_package[pos].num -= num;
				num = 0;
			}
			else
			{
				NolockUpdateItemNumMap(id,m_package[pos].num,false);
				num -= m_package[pos].num;
				m_package[pos].Clear();
			}
			CSocketServer &sock = SingletonSocket::instance();
			CNetMessage msg;
			msg.SetType(PRO_UPDATE_PACK);
			msg<<(uint8)2;		// update
			MakePack(m_package[pos],pos,msg);
			sock.SendMsg(m_sock,msg);
		}
		if(num <= 0)
		{
			return true;
		}
	}
	return false;
}

int CUser::GetWeiJianDingShuiJingNum()
{
	int num = 0;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint8 pos = 0; pos < MAX_PACKAGE_NUM; pos++)
	{
		if(m_package[pos].tmplId == 615)
		{
			if(m_package[pos].addAttrNum <= 0)
				num += m_package[pos].num;
		}
	}
	return num;
}

// 删除未鉴定水晶的数量
bool CUser::DelWeiJianDingShuiJing(int num)
{
	if(num == 0)
		return false;
	if(num < 0)
		num = 0xffff;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint8 pos = 0; pos < MAX_PACKAGE_NUM2; pos++)
	{
		if(m_package[pos].tmplId == 615)
		{
			if(m_package[pos].addAttrNum > 0)
				continue;

			if(m_package[pos].num > num)
			{
				m_package[pos].num -= num;
				num = 0;
			}
			else
			{
				num -= m_package[pos].num;
				m_package[pos].Clear();
			}
			CSocketServer &sock = SingletonSocket::instance();
			CNetMessage msg;
			msg.SetType(PRO_UPDATE_PACK);
			msg<<(uint8)2;		// update
			MakePack(m_package[pos],pos,msg);
			sock.SendMsg(m_sock,msg);
		}
		if(num <= 0)
		{
			return true;
		}
	}
	return false;
}

void CUser::SetFight(uint32 fightId)
{
	m_fightId = fightId;
	m_fightPos = 0;
	if(m_fightId > 0)
	{
		SetMeetEnemy(false);
		m_lastFightTime = 0;
		m_clientFightEndTime = 0;
	}
}

uint8 CUser::GetVipLevel()
{
	if(m_vipLevel > MAX_VIP_LEVEL)
		m_vipLevel = MAX_VIP_LEVEL;
	return m_vipLevel;
}

void CUser::SetFightEndTime()
{
	m_lastFightTime = GetSysTime();
}

void CUser::SetClientFightEndTime()
{
	m_clientFightEndTime = GetSysTime();
}

void CUser::SaveSellItem(uint8 pos,uint8 num)
{
	const uint16 itemId[] = {851,611,612,615,616,630,631,632,633,634,635,780,1817,1818,1819,1820,1821,1834,2192,2193,2194,2195};
	if((pos >= MAX_PACKAGE_NUM) || (m_package[pos].tmplId == 0))
		return;

	for(uint16 i=0;i < sizeof(itemId)/sizeof(itemId[0]); i++)
	{
		if(m_package[pos].tmplId == itemId[i])
		{
			boost::recursive_mutex::scoped_lock lk(m_mutex);
			SaveUseItem(m_roleId,m_package[pos].tmplId,LANGUAGE_TRANSFORM_2358,num);
			return;
		}
	}

	CItemTemplateManager &itemMgr = SingletonItemManager::instance();
	SItemTemplate *pItem = itemMgr.GetItem(m_package[pos].tmplId);
	if(pItem == NULL)
		return;
	//if(pItem->type > EIT_WuQi_6 && pItem->type < EIT_TouKui_1)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		SaveUseItem(m_roleId,m_package[pos].tmplId,LANGUAGE_TRANSFORM_2359,num);
	}
}

void CUser::SaveSellItem1(uint8 pos,uint8 num)
{
	if((pos >= MAX_PACKAGE_NUM) || (m_package[pos].tmplId == 0))
		return;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	SaveUseItem(m_roleId,m_package[pos].tmplId,LANGUAGE_CC_0008,num);
	
}

void CUser::SaveDelItem(uint8 pos,uint8 num)
{
	if((pos >= MAX_PACKAGE_NUM) || (m_package[pos].tmplId == 0))
		return;
	boost::recursive_mutex::scoped_lock lk(m_mutex);

	SaveUseItem(m_roleId,m_package[pos].tmplId,LANGUAGE_TRANSFORM_2360,num);
}

void CUser::SetName(const char *name)
{
	if(name != NULL)
	{
		snprintf(m_name,MAX_NAME_LEN-1,"%s",name);
	}
}

void CUser::SetMoveTime(uint64 t)
{
	m_moveTime = t;
}

uint64 CUser::GetMoveTime()
{
	return m_moveTime;
}

void CUser::SetErrMoveTimes(uint8 t)
{
	m_moveErrTimes = t;
}

uint8 CUser::GetMoveErrTimes()
{
	return m_moveErrTimes;
}

bool CUser::CanFightHuoDong(int space)
{
	if(GetSysTime() - m_huodongTime > space)
	{
		return true;
	}
	return false;
}

void CUser::ReadSaveData(char *row)
{
	memset(m_save8,0,sizeof(m_save8));
	memset(m_save16,0,sizeof(m_save16));
	memset(m_save32,0,sizeof(m_save32));
	if(row == NULL)
		return;

	uint8 num = 0;
	CNetMessage msg;
	int len = strlen(row);
	uint8 data[2048];
	StrToHex(row,data,len);
	msg.WriteData(data,len);
	msg>>num;
	if(num <= UINT8_NUM)
	{
		for(uint8 i = 0; i < num; i++)
		{
			msg>>m_save8[i];
		}
	}
	msg>>num;
	if(num <= UINT16_NUM)
	{
		for(uint8 i = 0; i < num; i++)
		{
			msg>>m_save16[i];
		}
	}
	msg>>num;
	if(num <= UINT32_NUM)
	{
		for(uint8 i = 0; i < num; i++)
		{
			msg>>m_save32[i];
		}
	}
}

void CUser::WriteSaveData(string &str)
{
	CNetMessage msg;

	msg<<UINT8_NUM;
	for(uint8 i = 0; i < UINT8_NUM; i++)
	{
		msg<<m_save8[i];
	}
	msg<<UINT16_NUM;
	for(uint8 i = 0; i < UINT16_NUM; i++)
	{
		msg<<m_save16[i];
	}
	msg<<UINT32_NUM;
	for(uint8 i = 0; i < UINT32_NUM; i++)
	{
		msg<<m_save32[i];
	}
	str.clear();
	HexToStr((uint8*)(msg.GetMsgData()->c_str() + CNetMessage::GetHeadLen()), msg.GetDataLenExceptHead(), str);
}

void CUser::SetShengWang(int sw)
{
	int curShengWang = GetData16(0);
	SetData16(0,sw);
	SaveDataEx(this,2,3,curShengWang,sw);
}

void CUser::ClearTimeoutTitle()
{
	time_t curTime = GetSysTime();
	if ((curTime - m_lastCheckTitleTime) > 60) // 1分钟检验一次过期称号
	{
		m_lastCheckTitleTime = curTime;
		titleSet removeTitle;
		bool addTitle = CheckInvalidTitle(&removeTitle);
		if(!removeTitle.empty())
		{
			CNetMessage msg;
			msg.ReWrite();
			msg.SetType(PRO_TITLE_OPTION);
			msg << (uint8)1 << (uint8)removeTitle.size();

			char buf[256];
			CTitltAttrCfgManager &titleMgr = SingletonCTitltAttrCfgManager::instance();
			for (titleSetIt rit = removeTitle.begin(); rit != removeTitle.end(); ++rit)
			{
				const char *pName = titleMgr.GetTitleName(*rit);
				if(pName != NULL)
				{
					snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0532,pName);
					SendSysInfo(this,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
				}
				msg<<(uint16)*rit;
			}
			SingletonSocket::instance().SendMsg(m_sock, msg);
		}
		if(addTitle || !removeTitle.empty())
		{
			InitAllPet();
			InitAndUpdate();
		}
	}
}

void CUser::ShowFindResourceMsg(CNetMessage &msg)
{
	uint32 numPos = msg.GetDataLen();
	uint8 num = 0;
	msg<<num;

	CFindResourceManager &mgr = SingletonCFindResourceMgr::instance();
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(map<int, uint16>::iterator it = m_findResouce.findList.begin(); it != m_findResouce.findList.end(); it++)
	{
		int funcId = it->first;
		uint16 times = it->second;
		if(times == 0)
			continue;

		SCostData cost;
		vector<SAwardData> award;
		if(!mgr.GetAwardInfo(funcId, m_findResouce.level, cost, award))
			continue;

		msg<<funcId<<times<<cost.costType<<cost.typeId<<cost.costValue;
		MakeMultiAwardMsg(award, msg);
		num++;
	}
	msg.WriteData(numPos,&num,sizeof(num));
}

bool CUser::BuyFindResource(CNetMessage &msg, uint16 funcId, uint16 findNum)
{
	if(funcId == 0 || findNum == 0)
		return false;

	CFindResourceManager &mgr = SingletonCFindResourceMgr::instance();
	vector<SAwardData> award;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		map<int, uint16>::iterator it = m_findResouce.findList.find(funcId);
		if(it == m_findResouce.findList.end())
			return false;
		uint16 times = it->second;
		if(findNum > times)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0583, TIPS_FAILURE_COLOR);
			return true;
		}

		SCostData cost;
		if(!mgr.GetAwardInfo(funcId, m_findResouce.level, cost, award))
			return false;
		cost.costValue *= findNum;
		for(uint16 i=0; i < award.size(); i++)
			award[i].num *= findNum;
		
		vector<SCostData> costList;
		costList.push_back(cost);
		string err;
		if(!NoLockCheckCostMaterial(costList, err))
		{
			msg<<PRO_ERROR<<MakeStringColor(err, TIPS_FAILURE_COLOR);
			return true;
		}
		NoLockDelCostMaterial(costList);
		ItemCurrencyLog(GetRoleId(), funcId, findNum, cost.costType, cost.costValue, GetMaterial(cost.costType), MUT_ZhaoHui);
		it->second -= findNum;
	}

	msg<<PRO_SUCCESS;
	SendAndMakeAwardMsg(this, award, msg, false, MUT_ZhaoHui);
	SendZhaoHuiHotPointStatus();
	return true;
}

void CUser::AddTeamBreakAttr(MultiAttr& attr)
{
	if (attr.empty())
		return;
	MergeAttrList(m_breakAttr, attr);
}

MultiAttr& CUser::GetTeamBreak()
{
	return m_breakAttr;
}

bool CUser::BuyAllFindResource(CNetMessage &msg,uint8 findType)
{
	if(findType == 0 || findType > 2)
		return false;
/*
	vector<SAwardData> awardList;
	CItemTemplateManager &itemMgr = SingletonItemManager::instance();
	CFindResourceManager &mgr = SingletonCFindResourceMgr::instance();
	SCostData cost;
	if(findType == 1)	// 普通找回，金币
		cost.costType = HDAT_MONEY;
	else
		cost.costType = HDAT_YB;

	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		for(map<uint16,SResource>::iterator it = m_findResouce.begin(); it != m_findResouce.end(); it++)
		{
			SResource &res = it->second;
			SFindResCfg cfg;
			if(!mgr.GetResourceCfg(it->first,cfg))
				continue;
			if(findType == 1)
				cost.costValue += cfg.money_per * res.findNum;
			else
				cost.costValue += cfg.YB_per * res.findNum;
		}
		if(cost.costValue == 0)
			return false;

		string error;
		vector<SCostData> costList;
		costList.push_back(cost);
		if(!NoLockCheckCostMaterial(costList,error))
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0487,TIPS_FAILURE_COLOR);
			return true;
		}
		NoLockDelCostMaterial(costList);

		for(map<uint16,SResource>::iterator it = m_findResouce.begin(); it != m_findResouce.end(); it++)
		{
			SResource &res = it->second;
			SFindResCfg cfg;
			if(!mgr.GetResourceCfg(it->first,cfg))
				continue;
			res.findNum = 0;
			for(uint16 i=0;i < res.awardList.size();i++)
			{
				if(res.awardList[i].num < 1)
					continue;
				int addValue = res.awardList[i].num;
				res.awardList[i].num = 0;
				
				uint16 itemId = res.awardList[i].type;
				if(itemId < HDAT_MONEY)
				{
					SItemTemplate *p = itemMgr.GetItem(itemId);
					if(p == NULL)
						continue;
				}

				if(findType == 1)	// 普通找回75%
					addValue *= 0.75;
				if(addValue < 1)
					continue;
				SAwardData t;
				t.type = itemId;
				t.num = addValue;
				MergeAwardData(awardList,t);
			}
		}
	}

	uint8 awardNum = awardList.size();
	msg<<PRO_SUCCESS<<awardNum;
	for(uint8 i=0;i < awardNum;i++)
	{
		msg<<(uint16)awardList[i].type<<awardList[i].num;
		AddMaterial(awardList[i].type,awardList[i].num,false,false);
	}
*/
	return true;
}

void CUser::SendZhaoHuiHotPointStatus()
{
	uint8 state = 0;
	for (map<int, uint16>::iterator it = m_findResouce.findList.begin(); it != m_findResouce.findList.end(); it++)
	{
		if (it->second > 0)
		{
			state = 1;
			break;
		}
	}
	SendHotPointStatus(this, EHPoint_ZhaoHui, state);
}

void CUser::CalculateFindResource()
{
	vector<int> funcIds;
	SingletonCFindResourceMgr::instance().GetFindResFuncIds(funcIds);
	CSystemOpenCfgMananger &openMgr = SingletonCSystemOpenCfgMgr::instance();

	uint32 curZeroTime = GetClearDayTime();
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(m_findResouce.initTime == 0)
	{
		m_findResouce.initTime = curZeroTime;
		return;
	}
	m_findResouce.findList.clear();
	if(funcIds.empty())
		return;
	bool findPart = (curZeroTime - m_findResouce.initTime > 24*3600) ? false : true;  // false 找回全部, true找回部分
	for(uint16 i=0; i < funcIds.size(); i++)
	{
		int id = funcIds[i];
		if(!openMgr.CheckSystemOpen(this, id))
			continue;

		uint16 findTimes = 0;
		switch(id)
		{
			case SOT_3:
				findTimes = m_userGuanQia.GetLieZhuanCnt(findPart);
				break;
			case SOT_6:
				// 20 - 
				if (!findPart)
					findTimes = CArenaCfgMgr::FreeCnt;
				else if (findPart && (uint16)CArenaCfgMgr::FreeCnt > GetExtData16(ED16_72))
					findTimes = CArenaCfgMgr::FreeCnt - GetExtData16(ED16_72);
				break;
			case SOT_7:
				// 打了就不找回
				if (!findPart || !m_xunBaoManage.IsTry())
					findTimes = 1;
				break;
			case SOT_8:
				if (!findPart || !m_bloodFight->IsTry())
					findTimes = 1;
				break;
			case SOT_9:
				if (!findPart || GetExtData16(ED16_71) == 0)
					findTimes = 1;

				break;
			case SOT_18:
				if (!findPart)
					findTimes = 3;
				else
					findTimes = m_userSpirit.GetSpiritCnt();
				break;
			case SOT_1022:
				findTimes = m_userGuanQia.GetShiLianCnt(1, findPart);
				break;
			case SOT_1023:
				findTimes = m_userGuanQia.GetShiLianCnt(2, findPart);
				break;
			case SOT_1024:
				findTimes = m_userGuanQia.GetShiLianCnt(3, findPart);
				break;
			case SOT_1025:
				findTimes = m_userGuanQia.GetShiLianCnt(4, findPart);
				break;
			default:
				break;
		}

		if(findTimes == 0)
			continue;
		m_findResouce.findList[id] = findTimes;
	}
	m_findResouce.level = m_level;
	m_findResouce.initTime = curZeroTime;
}

bool CUser::HaveTitle(uint16 title)
{
	if(title == 0)
		return false;
	return m_titleList.find(title) != m_titleList.end();
}

void CUser::SetViewTitle(uint16 title,uint8 show,CNetMessage *msg)
{
	if(title == 0 || show > 1 || !HaveTitle(title))
	{
		if(msg != NULL)
			(*msg)<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2361,TIPS_FAILURE_COLOR);
		return;
	}
	if(show == 0)	// 不显示
	{
		m_useTitle.erase(title);
		if(msg != NULL)
			(*msg)<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_TRANSFORM_2363,TIPS_SUCCESS_COLOR);
	}
	else	// 显示
	{
		if(!HaveTitle(title))
		{
			if(msg != NULL)
				(*msg)<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2361,TIPS_FAILURE_COLOR);
			return;
		}
		m_useTitle.clear();
		m_useTitle.insert(title);

		if(msg != NULL)
			(*msg)<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_TRANSFORM_2365,TIPS_SUCCESS_COLOR);
	}
	UpdateUserInfo(this,ESRT_Title);
}

bool CUser::SetUseTitle(uint16 title,uint8 use,CNetMessage *msg)
{
	if(title == 0 || use > 1 || !HaveTitle(title))
	{
		if(msg != NULL)
			(*msg)<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2366,TIPS_FAILURE_COLOR);
		return false;
	}
	if(use == 0)	// 不使用
	{
		m_useTitle.erase(title);
	}
	else	// 使用
	{
		m_useTitle.clear();
		m_useTitle.insert(title);
	}
	if (msg != NULL)
		(*msg) << PRO_SUCCESS << MakeStringColor(LANGUAGE_TRANSFORM_2370, TIPS_SUCCESS_COLOR);
	return true;
}

void CUser::AddSpecialTitle()
{
	const uint16 titleId [] = {E2UT_BBSL, E2UT_HQZGJ};
	for (uint32 i = 0; i < sizeof(titleId)/sizeof(titleId[0]); i++)
	{
		if (CheckAddTitle(titleId[i]))
			AddTitle(titleId[i]);
	}
}

bool CUser::CheckAddTitle(uint16 title)
{
	if (!HaveTitle(title))
	{
		switch (title)
		{
			case E2UT_BBSL:
				return m_mount.HaveMount(SMount::LianHuaTai) && m_wing.HaveWing(SWing::WT_Wing_26);
			case E2UT_HQZGJ:
				return m_mount.HaveMount(SMount::ZhongGuoJie) && m_wing.HaveWing(SWing::WT_Wing_27);
		}
	}
	return false;
}

bool CUser::InsertTitle(uint16 title, titleSet *pRemoveTitle, bool *haveNewAdd, uint32 endTime/* = 0*/)
{
	bool newAdd = true;
	pair<titleMapIt, bool> bInsert = m_titleList.insert(make_pair(title, endTime));
	if(!bInsert.second)
		newAdd = false;
	if(pRemoveTitle != NULL)
	{
		if(pRemoveTitle->erase(title) > 0)
			newAdd = false;
		if(newAdd)
		{
			char buf[256];
			const char *pName = SingletonCTitltAttrCfgManager::instance().GetTitleName(title);
			if(pName != NULL)
			{
				snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0531,pName);
				SendSysInfo(this,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
			}
		}
	}
	if(haveNewAdd != NULL && !(*haveNewAdd) && newAdd)
	{
		*haveNewAdd = true;
	}
	return bInsert.second;
}

void CUser::RemoveNotForeveryTitle(titleSet *removeTitle)
{
	if(removeTitle != NULL)
		removeTitle->clear();
	uint32 now = GetSysTime();
	for (titleMapIt tit = m_titleList.begin(); tit != m_titleList.end();)
	{
		if (!sTitltAttrCfgManager.IsForeveryTitle(tit->first))
		{
			if (tit->second != 0 && now < tit->second)
				tit++;
			else
			{
				if(removeTitle != NULL)
					removeTitle->insert(tit->first);
				m_titleList.erase(tit++);
			}
		}
		else
		{
			tit++;
		}
	}
}

void CUser::AddTitle(uint16 title, uint32 time/* = 0*/)
{
	CTitltAttrCfgManager &titleMgr = SingletonCTitltAttrCfgManager::instance();
	const char *pName = titleMgr.GetTitleName(title);
	if(pName == NULL)
		return;
	if (!InsertTitle(title, NULL,NULL,titleMgr.GetTitleContinueTime(title, time)))
		return;

	if (m_sock > 0)
	{
		CNetMessage msg;
		msg.SetType(PRO_TITLE_OPTION);
		msg << (uint8)0 << (uint16)title << titleMgr.GetTitleAddPower(title);
		SingletonSocket::instance().SendMsg(m_sock, msg);

		char buf[256];
		snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0531,pName);
		SendSysInfo(this,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
		
		InitAllPet();
		InitAndUpdate();
	}
	return;
}

void CUser::DelTitle(uint16 title)
{
	if(title > (E2UT_MAX-1) || title == 0)
		return;

	CNetMessage msg;
	// 校验正在装备的称号
	m_useTitle.erase(title);
	m_titleList.erase(title);
	msg.ReWrite();
	msg.SetType(PRO_TITLE_OPTION);
	msg<<(uint8)1<<(uint8)1<<title;
	SingletonSocket::instance().SendMsg(m_sock,msg);
	return;
}

void CUser::ReadTitle(const char *row)
{
	m_titleList.clear();
	m_useTitle.clear();
	if(row == NULL || strlen(row) <= 2)
		return;
	uint32 len = 4096;
	std::vector<uint8> data(len);
	uint32 pos = 0;

	if (!UnCompress(row, &data[0], len))
		return;
	uint16 tNum = 0;
	pos = ReadDataFromBuf((char *)&data[0], &tNum, sizeof(tNum), pos);
	uint16 titleId = 0;
	uint32 timeSec = 0;
	for (uint16 i = 0; i < tNum; i++)
	{
		pos = ReadDataFromBuf((char *)&data[0], &titleId, sizeof(titleId), pos);
		pos = ReadDataFromBuf((char *)&data[0], &timeSec, sizeof(timeSec), pos);
		STitleAttrs* title = sTitltAttrCfgManager.GetTitleAttrs(titleId);
		if (title == NULL)
			continue;

		m_titleList.insert(make_pair(titleId, timeSec));
	}

	uint8 uNum = 0;
	uint16 uid = 0;
	pos = ReadDataFromBuf((char *)&data[0], &uNum, sizeof(uNum), pos);
	for (uint16 i = 0; i < uNum; i++)
	{
		pos = ReadDataFromBuf((char *)&data[0], &uid, sizeof(uid), pos);
		if (m_titleList.find(uid) == m_titleList.end())
			continue;
		m_useTitle.insert(uid);
	}
}

void CUser::GetTitleStr(string &str)
{
	int pos = 0;
	uint8 data[4096] = { 0 };
	uint16 tNum = m_titleList.size();
	pos = CopyDataToBuf((char*)data, &tNum, sizeof(tNum), pos);
	uint16 titleId = 0;
	for (titleMapIt tit = m_titleList.begin(); tit != m_titleList.end(); ++tit)
	{
		pos = CopyDataToBuf((char*)data, &tit->first, sizeof(tit->first), pos);
		pos = CopyDataToBuf((char*)data, &tit->second, sizeof(tit->second), pos);
	}

	uint8 uNum = m_useTitle.size();
	pos = CopyDataToBuf((char*)data, &uNum, sizeof(uNum), pos);
	for (titleSetIt uit = m_useTitle.begin(); uit != m_useTitle.end(); ++uit)
	{
		titleId = *uit;
		pos = CopyDataToBuf((char*)data, &titleId, sizeof(titleId), pos);
	}
	Compress(data, pos, str);
}

// 检测称号有效性
bool CUser::CheckInvalidTitle(titleSet *removeTitle)
{
	int zhanDouLiRoleId = 0; // 战斗力
	int dengJiRoleId = 0; // 等级
	int caiFuRoleId = 0; // 财富
	int chongWuRoleId = 0; // 神将
	int bangPaiId = 0; // 帮派
//	GetTopRankId(zhanDouLiRoleId,dengJiRoleId,caiFuRoleId,chongWuRoleId,bangPaiId);

	bangPaiId = SingletonCBangPaiManager::instance().GetFirstBang();
	int myRank = 0; // 自己的竞技场排名
	ArenaPaiHangData data;
	if(SingletonCArenaManager::instance().GetUserData(m_roleId, data));
	{
		myRank = data.rank;
	}

	int lilianRank = 0;	//SingletonCRankMgr::instance().GetRankIdx(CRankMgr::ERT_LiLianTa,m_roleId);
	int xiuxianRank = 0;	//SingletonCRankMgr::instance().GetRankIdx(CRankMgr::ERT_XiuXianLiLian,m_roleId);
	int quality3 = 0;
	int quality4 = 0;
	GetPetQualityNum(quality3,quality4);

	bool haveAddTitle = false;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	RemoveNotForeveryTitle(removeTitle);
	// 判断应有的称号
	if ((int)m_roleId == zhanDouLiRoleId)
		InsertTitle(E2UT_JIUTIANZHIZUN,removeTitle,&haveAddTitle);
	if ((int)m_roleId == dengJiRoleId)
		InsertTitle(E2UT_WEIZHENSANJIE,removeTitle,&haveAddTitle);
	if ((int)m_roleId == caiFuRoleId)
		InsertTitle(E2UT_MINGDONGBAFANG,removeTitle,&haveAddTitle);
	if ((int)m_roleId == chongWuRoleId)
		InsertTitle(E2UT_BUMIESHENGHUANG,removeTitle,&haveAddTitle);
	switch (myRank)
	{
	case 1:
		InsertTitle(E2UT_XIANWANGJIANGHSI,removeTitle,&haveAddTitle);
		break;
	case 2:
		InsertTitle(E2UT_TIANJUNJIANGSHI,removeTitle,&haveAddTitle);
		break;
	case 3:
		InsertTitle(E2UT_WANGZHEJIANGSHI,removeTitle,&haveAddTitle);
		break;
	}

	switch (lilianRank)
	{
	case 1:
		InsertTitle(E2UT_TongTianWangZhe,removeTitle,&haveAddTitle);
		break;
	case 2:
		InsertTitle(E2UT_TongTianZunZhe,removeTitle,&haveAddTitle);
		break;
	case 3:
		InsertTitle(E2UT_TongTianShiZhe,removeTitle,&haveAddTitle);
		break;
	}

	switch (xiuxianRank)
	{
	case 1:
		InsertTitle(E2UT_LiLianWangZhe,removeTitle,&haveAddTitle);
		break;
	case 2:
		InsertTitle(E2UT_LiLianZunZhe,removeTitle,&haveAddTitle);
		break;
	case 3:
		InsertTitle(E2UT_LiLianShiZhe,removeTitle,&haveAddTitle);
		break;
	}
	if (GetExtData16(52) >= 121)
		InsertTitle(E2UT_ZHENYAOYINGHAO,removeTitle,&haveAddTitle);
	if (GetExtData16(52) >= 81)
		InsertTitle(E2UT_ZHENYAODIHAO,removeTitle,&haveAddTitle);
	if ((GetBangPai() != 0) && ((int)GetBangPai() == bangPaiId))
		InsertTitle(E2UT_TIANXIADIYIBANG, removeTitle, &haveAddTitle);
	if (GetExtData32(14) >= 5000)
		InsertTitle(E2UT_WOSHIGAOFUSHUAI,removeTitle,&haveAddTitle);
	if (GetExtData32(102) >= 500)
		InsertTitle(E2UT_WANSHOUZHIWANG,removeTitle,&haveAddTitle);
	if (m_level >= 10)
		InsertTitle(E2UT_QIYUXIUXING,removeTitle,&haveAddTitle);
	if ((myRank >3) && (myRank < 11))
		InsertTitle(E2UT_SHIDAGAOSHOU,removeTitle,&haveAddTitle);
	return haveAddTitle;
}

// 获取神将品质的数量
void CUser::GetPetQualityNum(int& quality3,int& quality4)
{
	quality3 = 0;
	quality4 = 0;

	vector<uint16> petList;
	GetPetIdList(petList);
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint16 i = 0;i < petList.size(); ++i)
	{
		SPet *pPet = NoLockGetPet(petList[i]).get();
		if (pPet != NULL)
		{
			if (pPet->quality == 3)
				++quality3;
			else if (pPet->quality == 4)
				++quality4;
		}
		pPet = NULL;
	}
}

// 获取玩家目标品质的神将数量
int CUser::GetPetQualityNum(int quality)
{
	int num = 0;

	vector<uint16> petList;
	GetPetIdList(petList);
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint16 i = 0;i < petList.size(); ++i)
	{
		SPet *pPet = NoLockGetPet(petList[i]).get();
		if (pPet != NULL)
		{
			if (pPet->quality == quality)
				++num;
		}
		pPet = NULL;
	}
	return num;
}

int CUser::GetPetNumByLimitQuality(int quality)
{
	int num = 0;

	vector<uint16> petList;
	GetPetIdList(petList);
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint16 i = 0;i < petList.size(); ++i)
	{
		SPet *pPet = NoLockGetPet(petList[i]).get();
		if (pPet != NULL)
		{
			if (pPet->quality >= quality)
				++num;
		}
		pPet = NULL;
	}
	return num;
}


string CUser::GetPetMaxFightName()
{
	uint64 maxZhanDouLi = 0;
	string name;

	vector<uint16> petList;
	GetPetIdList(petList);
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint16 i = 0;i < petList.size(); ++i)
	{
		SPet *pPet = NoLockGetPet(petList[i]).get();
		if(pPet != NULL)
		{
			if(pPet->zhanDouli > maxZhanDouLi)
			{
				maxZhanDouLi = pPet->zhanDouli;
				name = pPet->name;
			}
		}
		pPet = NULL;
	}
	return name;
}

void CUser::GetPetMaxFightId(SRankPet &info)
{
	info.power = 0;
	info.pet_id = 0;

	vector<uint16> petList;
	GetPetIdList(petList);
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint16 i = 0;i < petList.size(); ++i)
	{
		SPet *pPet = NoLockGetPet(petList[i]).get();
		if(pPet != NULL)
		{
			if(pPet->zhanDouli > info.power)
			{
				info.power = pPet->zhanDouli;
				info.pet_id = pPet->id;
			}
		}
		pPet = NULL;
	}
}

//获取玩家所有神将战斗力
void CUser::GetPetsPower(vector<SRankPet> &vecData)
{
	vecData.clear();
	vector<uint16> petList;
	GetPetIdList(petList);
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint16 i = 0;i < petList.size(); ++i)
	{
		SPet *pPet = NoLockGetPet(petList[i]).get();
		if(pPet != NULL)
		{		
			SRankPet t;
			t.power = pPet->zhanDouli;
			t.pet_id = pPet->id;
			t.level = pPet->level;
			vecData.push_back(t);
		}
		pPet = NULL;
	}
}

bool CUser::IsUseTitle(uint16 id)
{
	if(id == 0)
		return false;
//	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return m_useTitle.find(id) != m_useTitle.end();
}

void CUser::GetTitleMsg(CNetMessage &msg)
{
	uint16 num = m_titleList.size();
	msg << (uint16)num;
	for (titleMapIt tit = m_titleList.begin(); tit != m_titleList.end(); ++tit)
	{
		msg << (uint16)tit->first;
		if (IsUseTitle(tit->first))
			msg << (uint8)1;
		else
			msg << (uint8)0;
		msg << sTitltAttrCfgManager.GetTitleAddPower(tit->first);
	}
}

void CUser::GetUseTitleMsg(CNetMessage &msg)
{
	uint16 num = m_useTitle.size();
	msg << (uint8)num;
	for (titleSetIt uit = m_useTitle.begin(); uit != m_useTitle.end(); ++uit)
	{
		msg << (uint16)*uit;
	}
}


bool CUser::IsAddHpItem(uint16 itemid)
{
	if(itemid == 1804 || itemid == 1822 || (itemid >= 651 && itemid <= 682))
		return true;
	else
		return false;
}

uint16 CUser::GetHpItem()
{
	uint16 itemid;
	if(GetItemNum(1804) > 0)
		return 1804;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint16 pos = 0; pos < MAX_PACKAGE_NUM; pos++)
	{
		itemid = m_package[pos].tmplId;
		if(itemid == 0)
			continue;
		if(IsAddHpItem(itemid))
			return itemid;
	}
	return 0;
}

void CUser::SetShiFu()
{
	//AddTitle(EUTShiFu);
}

bool CUser::PetStudyBornSkill(uint16 petId,uint8 skillPos,CNetMessage &msg)
{
	if(petId == 0 || skillPos >= PET_BORN_SKILL_NUM)
		return false;
	
	CPetCfgManager &petMgr = SingletonCPetCfgMgr::instance();
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		SPet *pPet = NoLockGetPet(petId).get();
		if(pPet== NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0424,TIPS_FAILURE_COLOR);
			return true;
		}
		
		uint16 skillId = 0;
		uint16 level = 0;
		pPet->GetSkillInfoByPos(skillPos,skillId,level);
		if(skillId == 0 || level == 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2385,TIPS_FAILURE_COLOR);
			return true;
		}
		SSkillLvCost *pSkillcost = petMgr.GetSkillCostData_Born(skillPos,level);
		if(pSkillcost == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2386,TIPS_FAILURE_COLOR);
			return true;
		}
		if(pSkillcost->learnLv_limit > 0 && pPet->level < pSkillcost->learnLv_limit)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0429,TIPS_FAILURE_COLOR);
			return true;
		}

		vector<SCostData> &costList = pSkillcost->costList;
		for(uint16 i=0;i < costList.size();i++)
		{
			if(costList[i].costType < HDAT_MONEY)
			{
				if(GetItemNum(costList[i].costType) < costList[i].costValue)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0425,TIPS_FAILURE_COLOR);
					return true;
				}
			}
			else if(costList[i].costType == HDAT_MONEY)
			{
				if(GetMoney() < costList[i].costValue)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0425,TIPS_FAILURE_COLOR);
					return true;
				}
			}
			else if(costList[i].costType == HDAT_QIANNENG)
			{
				if(GetQianNeng() < costList[i].costValue)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0425,TIPS_FAILURE_COLOR);
					return true;
				}
			}
		}
		// 扣材料
		for(uint16 i=0;i < costList.size();i++)
		{
			if(costList[i].costType < HDAT_MONEY)
				NoLockDelPackageById(costList[i].costType,costList[i].costValue);
			else if(costList[i].costType == HDAT_MONEY)
				AddMoney(-costList[i].costValue);
			else if(costList[i].costType == HDAT_QIANNENG)
				AddQianNeng(-costList[i].costValue);
		}

		msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_TRANSFORM_2389,TIPS_SUCCESS_COLOR);
		pPet->UpgradeSkill(skillId);
		pPet->Init(this);

//		SaveUseItem(m_roleId,itemId,LANGUAGE_TRANSFORM_2390,1);

		// ======================
		// 更新神将技能升级任务
		uint16 lv = 0;
		pPet->GetSkillInfoByPos(skillPos, skillId, lv);
		SingletonCMissionManager::instance().VerifyNewBranchMissionFinish(this,EMISS_DC_22,1, lv); // TODO
		
	}

	UpdatePet(petId);
	SendUpdateInfo(EUUT_TotalZhanDouLi);
	return true;
}

bool CUser::PetStudySkillToMax(uint16 petId, uint8 skillPos, CNetMessage &msg)
{
	CPetCfgManager &petMgr = SingletonCPetCfgMgr::instance();
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		SPet *pPet = NoLockGetPet(petId).get();
		if (pPet == NULL)
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_SSJ_0424, TIPS_FAILURE_COLOR);
			return true;
		}

		uint16 skillId = 0;
		uint16 level = 0;
		pPet->GetSkillInfoByPos(skillPos, skillId, level);
		if (skillId == 0 || level == 0)
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_2385, TIPS_FAILURE_COLOR);
			return true;
		}
		map<uint16, int> allCost;
		int cnt = 0;
		string errStr;
		do 
		{
			SSkillLvCost *pSkillcost = petMgr.GetSkillCostData_Born(skillPos, level + cnt);
			if (pSkillcost == NULL)
			{
				errStr = MakeStringColor(LANGUAGE_TRANSFORM_2386, TIPS_FAILURE_COLOR);
				break;
			}
			if (pSkillcost->learnLv_limit > 0 && pPet->level < pSkillcost->learnLv_limit)
			{
				errStr = MakeStringColor(LANGUAGE_SSJ_0429, TIPS_FAILURE_COLOR);
				break;
			}
			petMgr.MergeCost(allCost, pSkillcost->costList);
			bool enough = true;
			for (map<uint16, int>::iterator ait = allCost.begin(); ait != allCost.end(); ++ait)
			{
				if (ait->first < HDAT_MONEY)
				{
					if (GetItemNum(ait->first) < ait->second)
					{
						errStr = MakeStringColor(LANGUAGE_SSJ_0425, TIPS_FAILURE_COLOR);
						petMgr.SubCost(allCost, pSkillcost->costList);
						enough = false;
						break;
					}
				}
				else if (ait->first == HDAT_MONEY)
				{
					if (GetMoney() < ait->second)
					{
						errStr = MakeStringColor(LANGUAGE_SSJ_0425, TIPS_FAILURE_COLOR);
						petMgr.SubCost(allCost, pSkillcost->costList);
						enough = false;
						break;
					}
				}
				else if (ait->first == HDAT_QIANNENG)
				{
					if (GetQianNeng() < ait->second)
					{
						errStr = MakeStringColor(LANGUAGE_SSJ_0425, TIPS_FAILURE_COLOR);
						petMgr.SubCost(allCost, pSkillcost->costList);
						enough = false;
						break;
					}
				}
			}
			if (!enough)
				break;
			cnt++;
		} while (true);
		if (cnt == 0)
		{
			msg << PRO_ERROR << errStr;
			return true;
		}
		// 扣材料
		for (map<uint16, int>::iterator ait = allCost.begin(); ait != allCost.end(); ++ait)
		{
			if (ait->first < HDAT_MONEY)
				NoLockDelPackageById(ait->first, ait->second);
			else if (ait->first == HDAT_MONEY)
				AddMoney(-ait->second);
			else if (ait->first == HDAT_QIANNENG)
				AddQianNeng(-ait->second);
		}

		msg << PRO_SUCCESS << MakeStringColor(LANGUAGE_TRANSFORM_2389, TIPS_SUCCESS_COLOR);
		pPet->UpgradeSkill(skillId, cnt);
		pPet->Init(this);

		//		SaveUseItem(m_roleId,itemId,LANGUAGE_TRANSFORM_2390,1);

		// ======================
		// 更新神将技能升级任务
		uint16 lv = 0;
		pPet->GetSkillInfoByPos(skillPos, skillId, lv);
		SingletonCMissionManager::instance().VerifyNewBranchMissionFinish(this, EMISS_DC_22, 1, lv); // TODO

	}

	UpdatePet(petId);
	SendUpdateInfo(EUUT_TotalZhanDouLi);
	return true;
}

//神将学习技能,已有该技能
bool CUser::PetStudySkill(uint16 petId,uint16 skillId,CNetMessage &msg)
{
	if(petId == 0 || skillId == 0)
		return false;
	
	CPetCfgManager &petMgr = SingletonCPetCfgMgr::instance();
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		SPet *pPet = NoLockGetPet(petId).get();
		if(pPet== NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0424,TIPS_FAILURE_COLOR);
			return true;
		}
		uint8 skillPos = pPet->GetSkillPos(skillId);
		if(skillPos == 0xff || skillPos < PET_BORN_SKILL_NUM)
			return false;

		uint8 level = pPet->GetSkillLevel(skillId);
		if(level == 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2385,TIPS_FAILURE_COLOR);
			return true;
		}
		SSkillLvCost *pSkillcost = petMgr.GetSkillCostData_Normal(skillId,level);
		if(pSkillcost == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2386,TIPS_FAILURE_COLOR);
			return true;
		}
		if(pSkillcost->learnLv_limit > 0 && pPet->level < pSkillcost->learnLv_limit)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0429,TIPS_FAILURE_COLOR);
			return true;
		}

		vector<SCostData> &costList = pSkillcost->costList;
		for(uint16 i=0;i < costList.size();i++)
		{
			if(costList[i].costType < HDAT_MONEY)
			{
				if(GetItemNum(costList[i].costType) < costList[i].costValue)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0425,TIPS_FAILURE_COLOR);
					return true;
				}
			}
			else if(costList[i].costType == HDAT_MONEY)
			{
				if(GetMoney() < costList[i].costValue)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0425,TIPS_FAILURE_COLOR);
					return true;
				}
			}
			else if(costList[i].costType == HDAT_QIANNENG)
			{
				if(GetQianNeng() < costList[i].costValue)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0425,TIPS_FAILURE_COLOR);
					return true;
				}
			}
		}
		// 扣材料
		for(uint16 i=0;i < costList.size();i++)
		{
			if(costList[i].costType < HDAT_MONEY)
				NoLockDelPackageById(costList[i].costType,costList[i].costValue);
			else if(costList[i].costType == HDAT_MONEY)
				AddMoney(-costList[i].costValue);
			else if(costList[i].costType == HDAT_QIANNENG)
				AddQianNeng(-costList[i].costValue);
		}

		msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_TRANSFORM_2389,TIPS_SUCCESS_COLOR);
		pPet->UpgradeSkill(skillId);
		pPet->Init(this);

//		SaveUseItem(m_roleId,itemId,LANGUAGE_TRANSFORM_2390,1);
		
		// ======================
		// 更新神将技能升级任务
		uint16 lv = pPet->GetSkillLevel(skillId);
		pPet->GetSkillInfoByPos(skillPos, skillId, lv);
		SingletonCMissionManager::instance().VerifyNewBranchMissionFinish(this,EMISS_DC_22,1, lv); // TODO
		
	}

	UpdatePet(petId);
	SendUpdateInfo(EUUT_TotalZhanDouLi);
	return true;
}

bool CUser::PetReplaceSkill(uint16 petId,uint16 itemId,uint8 skillPos,CNetMessage &msg)
{
	if(petId == 0 || itemId == 0)
		return false;
	if(GetItemNum(itemId) == 0)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0430,TIPS_FAILURE_COLOR);
		return true;
	}

	CPetCfgManager &petMgr = SingletonCPetCfgMgr::instance();
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		SPet *pPet = NoLockGetPet(petId).get();
		if(pPet== NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0424,TIPS_FAILURE_COLOR);
			return true;
		}
		if(skillPos < PET_BORN_SKILL_NUM || skillPos >= PET_MAX_SKILL_NUM)
			return false;
		uint16 star_limit = skillPos-PET_BORN_SKILL_NUM+1;
		if(pPet->star < star_limit)
		{
			char buf[256];
			snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0452,star_limit);
			msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
			return true;
		}
		SSkillBookData *pSkillBook = petMgr.GetSkillBookData(itemId);
		if(pSkillBook == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2385,TIPS_FAILURE_COLOR);
			return true;
		}
		
		uint16 srcSkillId = 0;
		uint16 srcSkillLv = 0;
		pPet->GetSkillInfoByPos(skillPos,srcSkillId,srcSkillLv);
		if(srcSkillId == pSkillBook->skillId && srcSkillLv > pSkillBook->skillLv)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0455,TIPS_FAILURE_COLOR);
			return true;
		}
		if(srcSkillId != pSkillBook->skillId && pPet->GetSkillPos(pSkillBook->skillId) < PET_MAX_SKILL_NUM)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0455,TIPS_FAILURE_COLOR);
			return true;
		}
		if(!pPet->AddSkillByPos(skillPos,pSkillBook->skillId,pSkillBook->skillLv))
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0431,TIPS_FAILURE_COLOR);
			return true;
		}
		NoLockDelPackageById(itemId,1);
		
		msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_SSJ_0432,TIPS_SUCCESS_COLOR);
		pPet->Init(this);
		SingletonCMissionManager::instance().UpdateDCMissionComplate(this, EMISS_DC_47);
//		SaveUseItem(m_roleId,itemId,LANGUAGE_TRANSFORM_2390,1);
	}

	UpdatePet(petId);
	SendUpdateInfo(EUUT_TotalZhanDouLi);
	return true;
}

bool CUser::PetQualityLevelUp(uint16 petId,CNetMessage &msg)
{
	if(petId == 0)
		return false;
	
	CPetCfgManager &petMgr = SingletonCPetCfgMgr::instance();
	SPetBasicData *pPetCfg = petMgr.GetPetCfg(petId);
	if(pPetCfg == NULL)
		return false;
	SPet *pPet = NULL;
	// {
		// boost::recursive_mutex::scoped_lock lk(m_mutex);
		// pPet = NoLockGetPet(petId).get();
		// if(pPet== NULL)
		// {
			// msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0424,TIPS_FAILURE_COLOR);
			// return true;
		// }
		// uint8 quality = pPet->quality;
		// uint8 star = pPet->star;
		// uint8 star_step = pPet->star_step;
		// int level_limit = petMgr.GetUpStarLevelLimit(star);
		// if(pPet->level < level_limit)
		// {
			// char buf[512];
			// snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0489,level_limit);
			// msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
			// return true;
		// }
		
		// uint32 shenhun = GetShenhun();
		// int cost = petMgr.GetUpStarCost(quality,star,star_step);
		// if(cost < 0)
		// {
			// msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0431,TIPS_FAILURE_COLOR);
			// return true;
		// }
		// else if(cost == 0)
		// {
			// msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0433,TIPS_FAILURE_COLOR);
			// return true;
		// }

		// if((uint32)cost > shenhun)
		// {
			// msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0425,TIPS_FAILURE_COLOR);
			// return true;
		// }
		// AddShenhun(-cost);
		// pPet->AddCost(SPet::PCT_Star, HDAT_SHEN_HUN, cost);
		// // 升节点
		// uint8 tarStar = star;
		// uint8 tarStar_step = star_step+1;
		// cost = petMgr.GetUpStarCost(quality,tarStar,tarStar_step);
		// if(cost < 0)
		// {
			// tarStar++;
			// tarStar_step = 0;
			// cost = petMgr.GetUpStarCost(quality,tarStar,tarStar_step);
			// if(cost < 0)
			// {
				// return false;
			// }
			// char buf[512];
			// snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0062, GetName(), MakePetColorStr(petId).c_str(), tarStar);
			// SysInfoToAllUser(buf);
		// }
		// else if(cost == 0)
		// {
			// msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0433,TIPS_FAILURE_COLOR);
			// return true;
		// }

		// pPet->star = tarStar;
		// pPet->star_step = tarStar_step;
		
		// msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_SSJ_0434,TIPS_SUCCESS_COLOR);
		// pPet->Init(this);
//		SaveUseItem(m_roleId,itemId,LANGUAGE_TRANSFORM_2390,1);
	// }

	UpdatePet(petId);
	SendUpdateInfo(EUUT_TotalZhanDouLi);

	// 任意神将升星x次任务
	SingletonCMissionManager::instance().VerifyNewBranchMissionFinish(this, EMISS_DC_24); // TODO
	SingletonCMissionManager::instance().VerifyNewBranchMissionFinish(this, EMISS_DC_38); // TODO
	if(pPet->chuzhanFlag == 1)
	{
		if(GetTeam() > 0 && GetTeam() == GetRoleId())
		{
			if(m_pScene != NULL)
				m_pScene->UpdateTeamData(GetTeam());
		}
	}
	return true;
}

//装备神将铠甲
bool CUser::PetKaiJia(uint8 petPos,uint8 kaiJiaPos)
{
	return false;
/*
	if(kaiJiaPos >= MAX_PACKAGE_NUM)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if((petPos >= m_petNum) || (m_pet[petPos].get() == NULL) || (m_pet[petPos]->kaiJia.tmplId == 0))
			return false;
		if(NoLockAddPackage(m_pet[petPos]->kaiJia))
		{
			CItemTemplateManager &itemMgr = SingletonItemManager::instance();
			SItemTemplate *pItem = itemMgr.GetItem(m_pet[petPos]->kaiJia.tmplId);
			if(pItem == NULL)
				return false;
			m_pet[petPos]->kaiJia.tmplId = 0;

			m_pet[petPos]->Init(this);
			CSocketServer &sock = SingletonSocket::instance();
			CNetMessage msg;
			msg.SetType(PRO_UPDATE_PET);
			msg<<(uint8)2<<petPos;
			NoLockMakePetInfo(petPos,msg);
			sock.SendMsg(m_sock,msg);

			return true;
		}
		return false;
	}

	CItemTemplateManager &itemMgr = SingletonItemManager::instance();
	SItemTemplate *pItem = itemMgr.GetItem(m_package[kaiJiaPos].tmplId);
	if(pItem == NULL)
		return false;
	boost::recursive_mutex::scoped_lock lk(m_mutex);

	if((petPos >= m_petNum) || (m_pet[petPos].get() == NULL))
		return false;
	if(m_pet[petPos]->level < pItem->level)
		return false;
	if(m_pet[petPos]->kaiJia.tmplId != 0)
		return false;
	if(m_pet[petPos]->kaiJia.name[0] == 'Q')
		return false;

	m_pet[petPos]->kaiJia = m_package[kaiJiaPos];
	NoLockDelPackage(kaiJiaPos);

	m_pet[petPos]->Init(this);

	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_UPDATE_PET);
	msg<<(uint8)2<<petPos;
	NoLockMakePetInfo(petPos,msg);
	sock.SendMsg(m_sock,msg);
	return true;
*/
}

SItemInstance *CUser::GetItemById(int id)
{
	for(uint16 i = 0; i < MAX_PACKAGE_NUM; i++)
	{
		if(m_package[i].tmplId == id)
			return m_package+i;
	}
	return NULL;
}

int CUser::GetItemPosById(int id)
{
	for(uint16 i = 0; i < MAX_PACKAGE_NUM; i++)
	{
		if(m_package[i].tmplId == id)
			return i;
	}
	return -1;
}

bool CUser::HaveNameItem(uint16 itemId,const char *name)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(int i = 0; i < MAX_PACKAGE_NUM; i++)
	{
		if((m_package[i].tmplId == itemId) && (strcmp(m_package[i].name,name) == 0))
		{
			NoLockDelPackage(i);
			return true;
		}
	}
	return false;
}

uint8 CUser::GetPetNum()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return m_pet.size();
}

void CUser::GetPetIdList(vector<uint16> &petList)
{
	petList.clear();
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(CPetMapIt it = m_pet.begin(); it != m_pet.end(); it++)
	{
		petList.push_back(it->first);
	}
}

bool CUser::SetFightData(char *data)
{
	if(data == NULL)
		return false;
	char *str = new char[20480];
	CNetMessage msg;
	uint32 len;
	char result[512];
	int res_len = 0;
	char *p = NULL,*p1 = NULL;
	if(str == NULL)
		return false;
	if(!UnCompress(data,(uint8*)str,len))
		return false;
	p = str;
	p1 = str;
	while(*p1 != '\0')
	{
		if(*p1 != '|')
			p1++;
		else
		{
			*p1++ = '\0';
			msg.ReWrite();
			res_len = StrToHex(p,(uint8*)result,sizeof(result));
			msg.SetData(result,(uint16)res_len);
			m_fightdata.push_back(msg);
			p = p1;
		}
	}
	delete[] str;
	m_fightdata_pos = 0;
	return true;
}

bool CUser::SendFightData()
{
	if(m_fightdata.size() == 0)
		return false;
	CSocketServer &sock = SingletonSocket::instance();
	sock.SendMsg(m_sock,m_fightdata[m_fightdata_pos]);
	if(m_fightdata_pos == m_fightdata.size()-1)
	{
		m_fightdata_pos = 0;
		m_fightdata.clear();
	}
	else
		m_fightdata_pos++;
	return true;
}

void CUser::ClearFightData()
{
	m_fightdata_pos = 0;
	m_fightdata.clear();
}

CMultiTreeDoptionNode *CUser::findDoptionNodeById(int pid)
{
	CMultiTreeDoptionNode *p = m_Doption_root;
	CMultiTreeDoptionNode *temp = m_Doption_root;
	while(p->id != pid)
	{
		if(p->child[0] != NULL)
			p = p->child[0];
		else
			break;
	}
	while(p->id != pid)
	{
		if(p->child[0] != NULL)
			p = p->child[0];
		else
		{
			bool findnextnode = false;
			while(p->parent != NULL)
			{
				temp = p;
				p = p->parent;
				for(uint8 i=0;i<MAX_OptionNum;i++)
				{
					if(p->child[i] != NULL && p->child[i] == temp)
					{
						if(p->child[i+1] != NULL)
						{
							p = p->child[i+1];
							findnextnode = true;
						}
						break;
					}
				}
				if(findnextnode)
					break;
			}
			if(p->parent == NULL)
				break;
		}
	}
	if(p->id != pid)
		return NULL;
	else
		return p;
}

bool CUser::AddDoptionSubNode(CMultiTreeDoptionNode **pnode,const string op)
{
	if(op.empty() || (*pnode) == NULL)
		return false;

	char *split[20];
	string str_op = op;
	int num = SplitLine(split,20,(char*)str_op.c_str());
	if(num%2 != 0 || num == 0)
		return false;
	num /= 2;

	int maxid = atoi(split[0]);
	for(uint8 i=0;i<num;i++)
	{
		int id_t = atoi(split[2*i]);
		(*pnode)->child[i] = new CMultiTreeDoptionNode;
		(*pnode)->child[i]->id = maxNodeId + id_t;
		(*pnode)->child[i]->parentid = (*pnode)->id;
		(*pnode)->child[i]->label = split[2*i+1];
		(*pnode)->child[i]->parent = (*pnode);
		if(maxid < id_t)
			maxid = id_t;
	}
	maxNodeId += maxid;
	return true;
}

int CUser::InsertDoptionNode(int pid,const char *selectop,const char *name,const char *src,const char *op,uint8 call)	//m_root_interact pid=0
{
	if(pid < 0)
		return -3;				//参数错误
	CMultiTreeDoptionNode *p = NULL;
	if(m_Doption_root == NULL)
	{
		p = new CMultiTreeDoptionNode;
		p->parentid = pid;
		p->title = name;
		p->content = src;
		p->callback = call;
		p->parent = NULL;
		p->id = 1;
		maxNodeId = 1;
		if(*op != '\0')
		{
			if(!AddDoptionSubNode(&p,op))
			{
				delete p;
				return -2;			//error
			}
			p->have_op = 1;
		}
		else
			p->have_op = 0;

		m_Doption_root = p;
	}
	else
	{
		CMultiTreeDoptionNode *pp = findDoptionNodeById(pid);
		if(pp == NULL)
			return -1;				//找不到父节点
		for(uint8 i=0;i<MAX_OptionNum;i++)
		{
			if(pp->child[i] != NULL)
			{
				if(pp->child[i]->label == selectop)
				{
					p = pp->child[i];
					break;
				}
			}
			else
				break;
		}
		if(p != NULL)
		{
			p->title = name;
			p->content = src;
			p->callback = call;
			if(*op != '\0')
			{
				if(!AddDoptionSubNode(&p,op))
				{
					delete p;
					return -2;			//error
				}
				p->have_op = 1;
			}
			else
				p->have_op = 0;
		}
		else
		{
			if(pp->child[0] == NULL)
			{
				p = new CMultiTreeDoptionNode;
				p->parentid = pid;
				p->title = name;
				p->content = src;
				p->callback = call;
				p->parent = pp;
				maxNodeId++;
				p->id = maxNodeId;
				pp->child[0] = p;
				if(*op != '\0')
				{
					if(!AddDoptionSubNode(&p,op))
					{
						delete p;
						return -2;			//error
					}
					p->have_op = 1;
				}
				else
					p->have_op = 0;
			}
			else
				return -2;			//error
		}
	}
	return p->id;
}

void CUser::DoptionClear()
{
	if(m_Doption_root == NULL)
	{
		maxNodeId = 0;
		return;
	}
	CMultiTreeDoptionNode *p = m_Doption_root;
	CMultiTreeDoptionNode *temp = m_Doption_root;
	while(p->child[0] != NULL)
		p = p->child[0];
	while(p->parent != NULL)
	{
		temp = p;
		p = p->parent;
		for(uint8 i=0;i<MAX_OptionNum;i++)
		{
			if(p->child[i] != NULL && p->child[i] == temp)
			{
				p->child[i] = NULL;
				if(p->child[i+1] != NULL)
				{
					p = p->child[i+1];
					while(p->child[0] != NULL)
						p = p->child[0];
				}
				break;
			}
		}
		delete temp;
		temp = NULL;
	}
	delete p;
	p = NULL;
	m_Doption_root = NULL;
	maxNodeId = 1;
	m_Doption_call.clear();
}

void CUser::DoptionEnd()
{
	if(m_Doption_root == NULL)
		return;
	int num = 0;
	CMultiTreeDoptionNode *p = m_Doption_root;
	CMultiTreeDoptionNode *temp = m_Doption_root;
	while(p->child[0] != NULL)
		p = p->child[0];
	num++;
	while(p->parent != NULL)
	{
		temp = p;
		p = p->parent;
		for(uint8 i=0;i<MAX_OptionNum;i++)
		{
			if(p->child[i] != NULL && p->child[i] == temp)
			{
				if(p->child[i+1] != NULL)
				{
					p = p->child[i+1];
					while(p->child[0] != NULL)
						p = p->child[0];
				}
				break;
			}
		}
		num++;
	}

	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_INTERACT);
	msg<<(uint8)37<<(uint16)num;

	p = m_Doption_root;
	temp = m_Doption_root;
	while(p->child[0] != NULL)
		p = p->child[0];
	while(p->parent != NULL)
	{
		temp = p;
		p = p->parent;
		for(uint8 i=0;i<MAX_OptionNum;i++)
		{
			if(p->child[i] != NULL && p->child[i] == temp)
			{
				if(p->child[i+1] != NULL)
				{
					p = p->child[i+1];
					while(p->child[0] != NULL)
						p = p->child[0];
				}
				break;
			}
		}
		msg<<temp->parentid<<temp->id<<temp->title<<temp->label<<temp->content<<(uint8)temp->have_op<<(uint8)temp->callback;
	}
	msg<<p->parentid<<p->id<<p->title<<p->label<<p->content<<(uint8)p->have_op<<(uint8)p->callback;
	sock.SendMsg(m_sock,msg);
}

void CUser::SetDoptionCall(int nodeId,const char *call)
{
	CDoptionCallBack temp;
	temp.id = nodeId;
	temp.script_call = call;
	m_Doption_call.push_back(temp);
}

bool CUser::DoptionCall(int nodeId)
{
	if(nodeId <= 0)
		return false;
	for(list<CDoptionCallBack>::iterator i = m_Doption_call.begin(); i != m_Doption_call.end(); i++)
	{
		if(i->id == nodeId)
		{
			CCallScript *pcall = FindScript(m_script);
			pcall->Call(i->script_call.c_str(),"u",this);
			return true;
		}
	}
	return false;
}

int CUser::DoptionBegin(const char *name,const char *src,const char *op,uint8 call)
{
	DoptionClear();
	return InsertDoptionNode(0,"",name,src,op,call);
}

int CUser::Doption(int pid,const char *selectop,const char *name,const char *src,const char *op,uint8 call)
{
	return InsertDoptionNode(pid,selectop,name,src,op,call);
}

void CUser::DoptionPrint()
{
	if(m_Doption_root == NULL)
		cout<<"---- tree is empty."<<endl;
	CMultiTreeDoptionNode *p = m_Doption_root;
	CMultiTreeDoptionNode *temp = m_Doption_root;
	while(p->child[0] != NULL)
		p = p->child[0];
	while(p->parent != NULL)
	{
		temp = p;
		p = p->parent;
		for(uint8 i=0;i<MAX_OptionNum;i++)
		{
			if(p->child[i] != NULL && p->child[i] == temp)
			{
				if(p->child[i+1] != NULL)
				{
					p = p->child[i+1];
					while(p->child[0] != NULL)
						p = p->child[0];
				}
				break;
			}
		}
		cout<<"---- tree_node id="<<temp->id<<", pid="<<temp->parentid<<", title="<<temp->title<<", label="<<temp->label<<", content="<<temp->content
			<<", have_op="<<(int)temp->have_op<<", callback="<<(int)temp->callback<<endl;
	}
	cout<<"---- tree_node id="<<p->id<<", pid="<<p->parentid<<", title="<<p->title<<", label="<<p->label<<", content="<<p->content
		<<", have_op="<<(int)p->have_op<<", callback="<<(int)p->callback<<endl;
}

//获取扫荡信息
void CUser::GetSaoDangFuBenInfo()
{
	int fbId = GetSaoDangFuBenId();
	int cnt = GetSaoDangFuBenCiShu();
	int mopTime = GetSaoDangFuBenPerTime();
	time_t leftTime = GetSaoDangFuBenTime();
	string reward = GetDataStr(5);
	if (leftTime > GetSysTime())
		leftTime -= GetSysTime();
	else
		leftTime = 0;

	CNetMessage msg;
	msg.SetType(MSG_FUBEN_OPTION);
	msg<<(uint8)22<<(uint16)fbId<<(uint8)cnt<<(uint16)mopTime<<(uint16)leftTime<<reward.c_str();
	SingletonSocket::instance().SendMsg(GetSock(),msg);
}

void CUser::ContinueSaoDang()
{
	int fbId = GetSaoDangFuBenId();
	int cnt = GetSaoDangFuBenCiShu();
	int mopTime = GetSaoDangFuBenPerTime();
	time_t leftTime = GetSaoDangFuBenTime();
	if (leftTime > GetSysTime())
		leftTime -= GetSysTime();
	else
		leftTime = 0;

	CNetMessage msg;
	msg.SetType(MSG_FUBEN_OPTION);
	msg<<(uint8)20<<PRO_SUCCESS<<(uint16)fbId<<(uint8)cnt<<(uint16)mopTime<<(uint16)leftTime;
	SingletonSocket::instance().SendMsg(GetSock(),msg);
}

void CUser::AccelerateSaoDangFuBen()
{
	CNetMessage msg;
	msg.SetType(MSG_FUBEN_OPTION);
	int fbId = GetSaoDangFuBenId();
	msg<<(uint8)30<<(uint16)fbId;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(GetSaoDangFuBenTime() == 0)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2475,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(GetSock(),msg);
		return;
	}
	
	int cnt = GetSaoDangFuBenCiShu();
	int mopTime = GetSaoDangFuBenPerTime();
	time_t curTime = GetSysTime();
	time_t leftTime = GetSaoDangFuBenTime();
	if(leftTime > curTime)
		leftTime -= curTime;
	else
		leftTime = 0;
	leftTime += mopTime*(cnt-1);
	int yb = AccelerateSaoDangCostYB(leftTime);
	if(GetTongBao() < yb)
	{
		msg<<PRO_ERROR<<"";
		SingletonSocket::instance().SendMsg(GetSock(),msg);
		ShowJumpNotice(this,JUMP_NOTICE_YB);
		return;
	}
	AddTongBao(-yb);
	SetSaoDangFuBenTime(curTime-leftTime);
	
	msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_TRANSFORM_2476,TIPS_SUCCESS_COLOR);
	SingletonSocket::instance().SendMsg(GetSock(),msg);

	ItemCurrencyLog(GetRoleId(),1,0,0,yb,GetTongBao(),YBL_ACC_SHAODANG);
}

void CUser::SaoDangFuBen(uint16 fuBenId, int cnt, CNetMessage& msg)
{
	int aid = sCDropMatchingMgr.GetInstanceDropId(fuBenId, GetFBLevel(fuBenId));
	for (uint8 si = 0; si < cnt; ++si)
	{
		msg << si;
		sAwardManager.SendLevelAward(this, aid, &msg);
	}
	// uint32 hdId = 0;
	// if(fuBenId == 2) // 强化副本
	// 	hdId = EEHDT_QiangHuaFB;
	// else if(fuBenId == 102) // 金币副本
	// 	hdId = EEHDT_JinBiFB;
	// else if(fuBenId == 4) // 升阶副本
	// 	hdId = EEHDT_ShenJieFB;
	// else if(fuBenId == 101)	// 淬炼副本
	// 	hdId = EEHDT_CuiLianFB;
	// else if(fuBenId == 162 || fuBenId == 163 || fuBenId == 164 || fuBenId == 165)	// 神将副本
	// 	hdId = EEHDT_XunChong;

	// if(hdId > 0)
	// 	SingletonCHDExchangeManager::instance().DropHDItem_New(this,hdId);
}

// 获取猜拳奖励 返回奖励的数值
int CUser::AddCaiQuanReward(bool isWin, int rewardType)
{
	int level = GetLevel();
	int reward = 0;
	if (rewardType == 1) // 经验
	{
		if (isWin)
			reward = (int)(level*level*30);
		else
			reward = (int)(level*level*16);
		AddExp(reward);
	}
	else if (rewardType == 2) // 潜能
	{
		if (isWin)
			reward = 30*55;
		else
			reward = 30*30;
		AddQianNeng(reward);
	}
	else if (rewardType == 3) // 金钱
	{
		if (isWin)
			reward = 30*30;
		else
			reward = 30*20;
		AddMoney(reward);
	}
	return reward;
}

// 活跃度次数+1并任务完成校验
void CUser::CheckMissionHuoYueDu(bool isAdd)
{
	int add = isAdd ? 1 : -1;
	int curCnt = GetExtData8(87)+add;
	if (curCnt < 0)
		curCnt = 0;
	if (curCnt < 250)
		SetExtData8(87,curCnt);
}

// 紫神将数量任务校验
void CUser::CheckMissionZiPet(int ziPetNum)
{
	if (HaveBitSet(208) && HaveBitSet(209) && HaveBitSet(210) && HaveBitSet(211)) // 对应任务全部完成，则不需要校验
		return;

	if (ziPetNum == -1)
	{
		ziPetNum = 0; // 紫神将数量

		vector<uint16> petList;
		GetPetIdList(petList);
		for(uint8 i = 0; i < petList.size(); ++i)
		{
			SPet *pPet = GetPet(petList[i]).get();
			if(pPet != NULL && pPet->quality == 3)
			{
				++ziPetNum;
			}
		}
	}
}

// 通天塔
// 扫荡
void CUser::TongTianTaSaoDang(CNetMessage &msg)
{
	int roleTopFloor = GetExtData16(52); // 获取最高层数
	SetExtData8(68,GetExtData8(68)+1); // 更新当日扫荡次数
	sTowerRewardManager.SendSweepReward(this, msg);
	SetExtData16(51, roleTopFloor); // 设置当前所在层数

	char buf[128];
	// 通关设置空置霸主
	int bazhuNum = (int)(sizeof(tongTianTaBaZhuFloor)/sizeof(tongTianTaBaZhuFloor[0]));
	{
		boost::recursive_mutex::scoped_lock lk(tongTianTa_mutex);
		if (tongTianTaBaZhuData.size() >= (uint8)bazhuNum)
		{
			int canChangePos = 0xff;
			int selfPos = 0xff;
			for (uint8 i = 0; i < bazhuNum; i++)
			{
				if (tongTianTaBaZhuFloor[i] > roleTopFloor)
					break;
				if (tongTianTaBaZhuData[i] == 0)
					canChangePos = i;
				if (tongTianTaBaZhuData[i] == GetRoleId())
				{
					if (selfPos != 0xff)
					{
						tongTianTaBaZhuData[selfPos] = 0;
					}
					selfPos = i;
				}

			}
			if (canChangePos != 0xff && selfPos < canChangePos)		// 要设置新霸主
			{
				for (uint8 i = 0; i < canChangePos; i++)
				{
					if (tongTianTaBaZhuData[i] == GetRoleId())
					{
						tongTianTaBaZhuData[i] = 0;
						break;
					}
				}
				tongTianTaBaZhuData[canChangePos] = GetRoleId();
				snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_2478, tongTianTaBaZhuFloor[canChangePos]);
				SendSystemMail(GetRoleId(), buf);
			}
		}
	}

	if((roleTopFloor-1 >= 25) && (!HaveSGBitSet(107)))
		FinishStageGoalSection(1,4); // 通关通天塔25层
	if((roleTopFloor-1 >= 50) && (!HaveSGBitSet(117)))
		FinishStageGoalSection(2,4); // 通关通天塔50层
	if((roleTopFloor-1 >= 90) && (!HaveSGBitSet(127)))
		FinishStageGoalSection(3,4); // 通关通天塔90层
}

// 钓鱼定时器
void CUser::TryFishTimeout()
{
	if (!SingletonFishManager::instance().IsInHuoDongTime()) // 活动时间判断
		return;
	if (m_pFishRoom == NULL) // 是否在钓鱼判断
		return;
	CFishData* pFishData = m_pFishRoom->GetFishData(GetRoleId()); // 获取钓鱼数据失败
	if (pFishData == NULL)
		return;
	if (pFishData->m_fishTime == 0) // 没有再钓鱼
		return;
	if ((pFishData->m_fishTime + CFishData::FISH_TIME) > GetSysTime()) // 钓鱼时间不到
		return;

	//cout << "获得鱼了！！！" << endl;
	// 可以获得鱼了
	pFishData->m_fishTime = GetSysTime(); // 重置钓鱼时间
	char info[512];
	int fishId = 580;
	int res = Random(1,100);
	if (res <= 15)
	{
		fishId = 582;
		snprintf(info,sizeof(info),LANGUAGE_TRANSFORM_2479,
			ROLE_NAME_COLOR,GetName(),m_pFishRoom->m_id,ITEM_NAME_COLOR);
		SysInfoToAllUser(info);
	}
	else if (res <= 50)
	{
		fishId = 581;
	}

	// 经验获取
	int lv = GetLevel();
	CHuoDongExpManage &expManager = SingletonHuoDongExpManager::instance();
	int64 addExp = expManager.GetHuoDongExp(11,lv,0.05);
	addExp = AddExp(addExp);
	int worldExpPer = GetWorldExpPercent(m_level);

	pFishData->AddFish(this,fishId);
	if (worldExpPer > 0)
		snprintf(info,sizeof(info),LANGUAGE_TRANSFORM_2480,GetItemName(fishId),addExp, worldExpPer);
	else
		snprintf(info,sizeof(info),LANGUAGE_TRANSFORM_2481,GetItemName(fishId),addExp);

	if (m_fightId != 0) // 战斗中的信息战斗后显示
		SendSysInfoFightEnd(this,MakeStringColor(info,TIPS_WARNING_COLOR).c_str());
	else
		SendSysInfo(this,MakeStringColor(info,TIPS_WARNING_COLOR).c_str());

	CNetMessage msg;
	msg.SetType(MSG_FISH);
	msg<<(uint8)CFishManager::EFOP_FishSuccess<<PRO_SUCCESS<<CFishData::FISH_TIME;
	CSocketServer &sock = SingletonSocket::instance();
	sock.SendMsg(GetSock(),msg);

	SingletonCHDExchangeManager::instance().DropExchangeItem(this,EEHDT_Fish);
	//SingletonCHDExchangeManager::instance().DropHDItem_New(this,EEHDT_Fish);
}

// 获取钓鱼开始的时间
time_t CUser::GetFishTime()
{
	if (m_pFishRoom == NULL)
		return 0;
	CFishData* pFishData = m_pFishRoom->GetFishData(GetRoleId());
	if (pFishData == NULL)
		return 0;
	return pFishData->m_fishTime;
}

// 离开钓鱼房间
void CUser::ExitFishRoom()
{
	if (m_pFishRoom == NULL)
		return;
	m_pFishRoom->ExitByUserLogout(this);
}

// 更新离线经验时间
void CUser::UpdateOfflineExpTime()
{
	static int maxLastTime = 3*24*60*60; // 离线经验上限时间 目前是3天
	if (GetLevel() < 25) // 25级以下不开启
		return;
	time_t lastOutTime = GetRoleLastTime(m_roleId,true); // 玩家上次登出时间
	time_t curTime = GetSysTime(); // 当前时间
	//cout << "上次退出时间：" << lastOutTime << ",当前时间：" << curTime << endl;
	if (lastOutTime >= curTime) // 排除调时间引起的问题
		return;
	time_t curLastTime = curTime - lastOutTime; // 本次离线累计时间
	time_t allLastTime = GetExtData32(85)+curLastTime;
	if (allLastTime > maxLastTime)
		allLastTime = maxLastTime;

	SetExtData32(85,allLastTime); // 更新总离线累计时间
}

// 获取离线经验时间
time_t CUser::GetOfflineExpTime()
{
	return GetExtData32(85);
}

// 重置离线经验时间
void CUser::ResetOfflineExpTime()
{
	SetExtData32(85,0);
}

// 获取某种类型的离线经验
int CUser::GetOfflineExp(int type)
{
	time_t allTime = GetOfflineExpTime();
	int min = allTime/60;
	int freeExp = min * m_level * 15;
	if(type == EOET_FREE)
	{
		return freeExp * 75 / 100;
	}
	else if(type == EOET_CURRENCY)
	{
		return (int)(freeExp * 1);
	}
	else if(type == EOET_VIP)
	{
		if(m_vipLevel==0)
			return 0;
		return (int)((freeExp/100.0)*G_VipConfig[m_vipLevel].offline);
	}
	return 0;
}

void CUser::SendShopCanDrawPetInfo(bool show)
{
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_PET_RANDOM_DRAW);
	msg<<(uint8)4<<(uint8)(show ? 1 : 0);
	sock.SendMsg(m_sock,msg);
}

void CUser::GetAccountInfo()
{
	if (isLoadAccountInfo)
	{
		CDatabaseSql *pDb = GetLoginDb();
		if(pDb == NULL)
			return;
		char sql[255];
		//                                 0     1         2         3
		snprintf(sql,sizeof(sql),"select name,binding,phone_state,personal_id from user_info where id = %d",GetUserId());
		if (!pDb->Query(sql))
			return;
		if (pDb->GetRowNum() == 0)
			return;
		char** row = pDb->GetRow();
		if (row == NULL)
			return;

		m_accountName = row[0];
		m_binding = atoi(row[1]);
		m_recordPhone = atoi(row[2]);
		m_personal_id = row[3];
		isLoadAccountInfo = false;
	}

}

void CUser::SetPersonalID(string &personal_ID)
{
	m_personal_id = personal_ID;
}

bool CUser::IsRealNameRegistration()
{
	GetAccountInfo();
	return (m_personal_id.size() > 0) ? true : false;
}

void CUser::GetPersonalID(string& personal_ID)
{
	GetAccountInfo();
	personal_ID = m_personal_id;
}

// 获取账号名
void CUser::GetAccountName(string& accountName)
{
	GetAccountInfo();
	accountName = m_accountName;
}

// 获取绑定信息
int CUser::GetAccountBinding()
{
	GetAccountInfo();
	return m_binding;
}

int CUser::GetAccountRecordPhone()
{
	GetAccountInfo();
	return m_recordPhone;
}

void CUser::SetAccountName(const char *accountName)
{
	m_accountName = accountName;
}

// 设置是否可以绑定 1 可以绑定，0 不可以
void CUser::SetAccountBinding(int binding)
{
	 m_binding = binding;
}

// 设置是否已经记录phone num， 1 已经记录，0 没有记录
void CUser::SetRecordPhoneState(int state)
{
	 m_recordPhone = state;
}

bool CUser::BackLibaoInfoExist(const char *name)
{
	CDatabaseSql *pDb = GetLoginDb();
	if( pDb == NULL)
		return true;
	
	char sql[255];
	snprintf(sql,sizeof(sql),"select id from back_libao_info where name = \'%s\'",name);
	if (!pDb->Query(sql))
		return true;
	if (pDb->GetRowNum() == 0)
		return false;
	char** row = pDb->GetRow();
	if (row == NULL)
		return false;
	return true;
}

// 获取账号领取回归礼包
bool CUser::CanGetBackLibao(const char *name)
{

	CDatabaseSql *pDb = GetLoginDb();
	if( pDb == NULL)
		return false;

	char sql[255];
	snprintf(sql,sizeof(sql),"select server_id from back_libao_info where name = \'%s\'",name);
	if (!pDb->Query(sql))
		return false;
	if (pDb->GetRowNum() == 0)
		return true;
	char** row = pDb->GetRow();
	if (row == NULL)
		return true;

	return GetServerId() == atoi(row[0]);
}

void CUser::UpdateBackLibaoInfo(const char *name)
{
	if (! BackLibaoInfoExist(name))
	{
		CDatabaseSql *pDb = GetLoginDb();
		if(pDb == NULL)
			return;

		char sql[255];
		snprintf(sql,sizeof(sql),"insert into back_libao_info(name,server_id) values(\'%s\',%d)", name, GetServerId());

		pDb->Query(sql);
	}
}


// 是否可以显示跨服战第一名圣灵之翼奖励
bool CUser::TryKuaFuZhanShengLingZhiYi()
{
	return ((GetSysTime() - GetExtData32(73)) < 7*24*3600); // 圣灵之翼 跨服战各区第一名
}

const char *CUser::GetExpStr()
{
	snprintf(m_expStr,sizeof(m_expStr),"%lld",m_exp);
	return m_expStr;
}

// @param int isAll 默认0：合成一次 1：全部合成
void CUser::ItemHeCheng(int pos, int isAll)
{
	//CSocketServer &sock = SingletonSocket::instance();
	//CNetMessage msg;
	//msg.SetType(MSG_HE_CHENG_OPTION);
	//msg<<(uint8)(isAll+4); // op

	//SItemInstance* pItem = GetItem(pos);
	//if (pItem == NULL) // 没有找到这个道具
	//{
	//	msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2484,TIPS_FAILURE_COLOR);
	//	sock.SendMsg(m_sock,msg);
	//	return;
	//}
	//string before;
	//ItemHexToStr(pItem,before);

	//uint8 reqNum = GetHeChengItemNum(pItem->tmplId);
	//if(reqNum > 0)
	//{
	//	if(EmptyPackage() < 1) // 背包空间校验
	//	{
	//		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2485,TIPS_FAILURE_COLOR);
	//		sock.SendMsg(m_sock,msg);
	//		return;
	//	}

	//	if(pItem->num < reqNum) // 合成材料数量校验
	//	{
	//		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2486,TIPS_FAILURE_COLOR);
	//		sock.SendMsg(m_sock,msg);
	//		return;
	//	}

	//	int heChengCount = 1; // 目标合成数量
	//	if(isAll == 1)
	//		heChengCount = pItem->num/reqNum;
	//	uint16 itemId = pItem->tmplId;
	//	uint16 targetItemId = GetHeChengTargetItemId(itemId);

	//	DelPackage(pos,heChengCount*reqNum); // 删除消耗材料
	//	AddPackage(targetItemId,heChengCount);

	//	string end;
	//	pItem = GetItem(GetItemPosById(targetItemId));
	//	ItemHexToStr(pItem,end);
	//	SaveUseItem(m_roleId,m_package[pos].tmplId,LANGUAGE_TRANSFORM_2487,1,before,end);

	//	msg<<PRO_SUCCESS<<(uint8)heChengCount;
	//	sock.SendMsg(m_sock,msg);

	//	SetBitSet(165); // 每日活跃度 饰品/炼化石合成
	//}
	//else
	//{
	//	msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_2488,TIPS_FAILURE_COLOR);
	//	sock.SendMsg(m_sock,msg);
	//}
}

void CUser::ItemHeChengNum(uint16 itemId, int num)
{
	//CSocketServer &sock = SingletonSocket::instance();
	//CNetMessage msg;
	//msg.SetType(MSG_HE_CHENG_OPTION);
	//msg << (uint8)3; // op

	//uint32 hasNum = NoLockGetItemNum(itemId);
	//uint8 costNum = GetHeChengItemNum(itemId);
	//uint32 needNum = num * costNum;
	//if (costNum > 0)
	//{
	//	if (EmptyPackage() < 1) // 背包空间校验
	//	{
	//		msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_2485, TIPS_FAILURE_COLOR);
	//		sock.SendMsg(m_sock, msg);
	//		return;
	//	}

	//	if (hasNum < needNum) // 合成材料数量校验
	//	{
	//		msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_2486, TIPS_FAILURE_COLOR);
	//		sock.SendMsg(m_sock, msg);
	//		return;
	//	}
	//	NoLockDelPackageById(itemId, needNum);

	//	uint16 targetItemId = GetHeChengTargetItemId(itemId);
	//	AddPackage(targetItemId, num);

	//	string end;
	//	SItemInstance* pItem = GetItem(GetItemPosById(targetItemId));
	//	ItemHexToStr(pItem, end);
	//	SaveUseItem(m_roleId, itemId, LANGUAGE_TRANSFORM_2487, 1);

	//	msg << PRO_SUCCESS << (uint8)num;
	//	sock.SendMsg(m_sock, msg);

	//	SetBitSet(165); // 每日活跃度 饰品/炼化石合成
	//}
	//else
	//{
	//	msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_2488, TIPS_FAILURE_COLOR);
	//	sock.SendMsg(m_sock, msg);
	//}
}

// 分解
void CUser::ItemFenjie(vector<uint8> poss)
{
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_HE_CHENG_OPTION);
	msg << (uint8)6; // op

	map<uint16, uint32> items; // 分解的物品
	for (size_t i=0; i < poss.size(); ++i)
	{
		// SItemInstance* pItem = GetItem(poss[i]);
		// if (pItem == NULL) // 没有找到这个道具
		// {
			// continue;
		// }
		// uint16 tmplId = pItem->tmplId;

		// SComposeCfgData* pData = SingletonCComposeCfgManager::instance().GetFenjieCfg(tmplId);
		// if (pData == NULL)
		// {
			// continue;
		// }

		// uint32 getNum = pItem->num * pData->needNum;
		// char before[128];
		// char end[128];
		// snprintf(before, sizeof(before), "%s*%d", GetItemName(tmplId), pItem->num);
		// DelPackage(poss[i], pItem->num); // 删除消耗材料
		// items[pData->itemId] += getNum;
		// //AddMaterial(pData->itemId, getNum);
		// snprintf(end, sizeof(end), "%s*%d", GetItemName(pData->itemId), getNum);
		// SaveUseItem(m_roleId, tmplId, LANGUAGE_ZQX_0019, 1, before, end);
	}

	for (map<uint16, uint32>::iterator it = items.begin(); it != items.end(); ++it)
	{
		AddMaterial(it->first, it->second);
	}
	msg << PRO_SUCCESS;
	sock.SendMsg(m_sock, msg);
}

// 播放动画
void CUser::SendCgInfo(const char *animation)
{
	if (animation == NULL)
		return;

	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_PLAY_ANIMATION);
	msg<<animation;
	sock.SendMsg(m_sock,msg);
}

// 1 7日礼包
// 2 等级礼包
// 3 每日签到
// 4 连续登陆
// flag 0已完成1可做
void CUser::Send_HuoDongMsg()
{
	uint8 num = 0;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_PUSH_CLIENT_INFO);
	uint16 numPos = msg.GetDataLen();
	msg<<num;
	// index   flag(0已完成1可做)
	static uint8 maxLoginGift = 7;
	for (uint8 i=0; i<maxLoginGift; ++i)
	{
		if (!HaveBitSet(281 + i))
		{
			msg << (uint8)1 << (uint8)1;
			num++;
			break;
		}
	}
	//if(!HaveBitSet(190) && GetExtData8(75) < GetLogonDayNum())	// 7日礼包
	//{
	//	msg<<(uint8)1<<(uint8)1;
	//	num++;
	//}

	{
		// 等级礼包
		uint32 temp = GetExtData32(87);
		uint32 idx = GetLevel()/10;
		for(uint32 i=1;i <= idx;i++)
		{
			if((temp & 1<<(idx-1)) == 0)
			{
				msg<<(uint8)2<<(uint8)1;
				num++;
				break;
			}
		}
	}
	{
		if(!HaveBitSet(504))	// 每日签到
		{
			msg<<(uint8)3<<(uint8)1;
			num++;
		}
	}

/*
	{
		// 连续登陆
		uint8 data = GetExtData8(92);
		if(data > 2)
			data = 2;
		for(uint8 i=0;i <= data;i++)
		{
			if(!HaveBitSet(312+data))
			{
				msg<<(uint8)4<<(uint8)1;
				num++;
				break;
			}
		}
	}
*/
	msg.WriteData(numPos,&num,sizeof(num));
	sock.SendMsg(m_sock,msg);
}

void CUser::GiveVipAward(uint8 newLv)
{
	SMailData mdata;
	char buf[256];
	for(int i=m_vipLevel+1;i<=newLv;i++)
	{
		for(int j=0;j<3;j++)
			mdata.AddAward(G_VipConfig[i].awardt[j], 0, G_VipConfig[i].awardn[j]);
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_2505,i);
		SendSystemMail(GetRoleId(),buf,&mdata);
	}
}

void CUser::GiveVipNewAward()
{
	SItemInstance item;
	SMailData mdata;
	char buf[256];
	for(int i=1;i<=m_vipLevel;i++)
	{
		for(int j=0;j<3;j++)
			mdata.AddAward(G_VipConfig[i].awardt[j], 0, G_VipConfig[i].awardn[j]);
		snprintf(buf,sizeof(buf), LANGUAGE_TRANSFORM_2505,i);
		SendSystemMail(GetRoleId(),buf,&mdata);
	}
}


void CUser::CheckMeiRiShouChong(bool isOnLine,int type)
{
	if(!HaveBitSet(601))
	{
		SetBitSet(601);
		NoticeHuoDongHotPoint(this,CHuoDongAwardManager::MOGU);
	}

	if (!HaveBitSet(550) && SingletonCHuoDongAwardManager::instance().InHuoDongTime(CHuoDongAwardManager::MEIRI_SHOUCHONG))
	{
		uint32 time = 0;
		uint32 curYear = GetYear();
		uint32 curMon = GetMonth();
		uint32 curDay = GetDay();
		time = curYear << 16 | curMon << 8 | curDay;
		SetExtData32(204, time);
		SetBitSet(550);

		if(isOnLine)
			NoticeMeiRiShouChong();
	}
	if (!IsWeiXin(type))
		return;

	if (!HaveBitSet(595) && SingletonCHuoDongAwardManager::instance().InHuoDongTime(CHuoDongAwardManager::MEIRI_SHOUCHONG))
	{
		uint32 time = 0;
		uint32 curYear = GetYear();
		uint32 curMon = GetMonth();
		uint32 curDay = GetDay();
		time = curYear << 16 | curMon << 8 | curDay;
		SetExtData32(409, time);
		SetBitSet(595);
	}
}

void CUser::NoticeMeiRiShouChong()
{
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_MEIRI_SHOUCHONG);
	msg<<(uint8)HaveBitSet(550)<<(uint8)HaveBitSet(551);
	sock.SendMsg(m_sock,msg);
}

void CUser::UpdateVipInfoEx()
{
	int vipLevel = ::GetVipLevel(GetChongzhiTotal() + GetExVipExp());
	if (m_vipLevel != vipLevel)
	{
//		GiveVipAward(vipLevel);
		m_vipLevel = vipLevel;
		CheckFBLevel();
		char successStr[256];
		snprintf(successStr, sizeof(successStr), LANGUAGE_TRANSFORM_2506, ROLE_NAME_COLOR, GetName(), GGCT_ORANGE, m_vipLevel);
		SysInfoToAllUser(successStr);
				
		if(m_pScene != NULL)
			m_pScene->UpdateUserInfo(this,ESRT_Vip);

		sCMissionManager.UpdateQuestState(this, EMQCT_31, m_vipLevel);
	}
	UpdateVipInfo();
}

// 校验充值活动
// @param bool isOnLine 玩家是否在线
// @param uint32 tongbao 充值通宝数
void CUser::CheckChongZhiHuoDong(bool isOnLine,uint32 money,uint32 tongbao,uint32 type)
{
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();

	// 累计充值通宝数量
	AddChongzhiTotal(tongbao);
	UpdateVipInfoEx();
	SetExtData32(14,GetExtData32(14)+money);
	SetExtData32(474, GetExtData32(474) + money);

	if(awardManager.InHuoDongTime(CHuoDongAwardManager::LEI_JI_CHONGZHI))	// 活动累计充值
		SetExtData32(119,GetExtData32(119)+tongbao);

	if(awardManager.InHuoDongTime(CHuoDongAwardManager::LEI_JI_CHONGZHI2))	// 活动累计充值2
		SetExtData32(137,GetExtData32(137)+tongbao);

	if (isOnLine)
	{
		SingletonCMissionManager::instance().UpdateDCMissionComplate(this, EMISS_DC_70, money);
	}
	//单日累计充值1-10
	uint32 CZFYBlist[] = {CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO,CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO2,CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO3,
		CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO4,CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO5,CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO6,
		CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO7,CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO8,CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO9,
		CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO10 };
	uint32 totalCZDataId = 0;
	uint32 maskDataId = 0;
	for (uint32 i = 0; i < sizeof(CZFYBlist)/sizeof(CZFYBlist[0]); i++)
	{
		if (awardManager.InHuoDongTime(CZFYBlist[i]))
		{
			if (GetChongZhiFanYBDataId(CZFYBlist[i],totalCZDataId,maskDataId))
				SetExtData32(totalCZDataId, GetExtData32(totalCZDataId) + tongbao);
		}
	}

	if (awardManager.InHuoDongTime(CHuoDongAwardManager::LIANXU_CHONGZHI_ORI)) //连续充值-普通
		LianXuChongZhi(tongbao, CHuoDongAwardManager::LIANXU_CHONGZHI_ORI);

	if (awardManager.InHuoDongTime(CHuoDongAwardManager::LIANXU_CHONGZHI_DELUXE)) //连续充值-豪华
		LianXuChongZhi(tongbao, CHuoDongAwardManager::LIANXU_CHONGZHI_DELUXE);

	if (awardManager.InHuoDongTime(CHuoDongAwardManager::CHONG_ZHI_BANG)) //新服充值
		SetExtData32(126, GetExtData32(126) + tongbao);

//	SingletonCRankDataMgr::instance().SetChongZhi(this);//充值榜数据同步

	// 红利积分1-5
	AddHongLiJiFen(this,tongbao);

	// 红利大放送1-5,红利RMB
	uint32 HLCZlist[] = {CHuoDongAwardManager::HONGLI_CHONGZHI,CHuoDongAwardManager::HONGLI_CHONGZHI2,CHuoDongAwardManager::HONGLI_CHONGZHI3,CHuoDongAwardManager::HONGLI_CHONGZHI4,
				CHuoDongAwardManager::HONGLI_CHONGZHI5,CHuoDongAwardManager::HONGLI_CHONGZHI_RMB};
	for (uint32 i = 0; i < sizeof(HLCZlist)/sizeof(HLCZlist[0]); i++)
	{
		uint32 timeDataId = 0;
		uint32 leijiDataId = 0;
		uint32 maskDataId = 0;
		if (GetHongLiDataId(HLCZlist[i],timeDataId,leijiDataId,maskDataId))
		{
			uint32 hongliLeijiTime = awardManager.GetHuoDongLeijiTime(HLCZlist[i]);
			uint32 curTime = GetSysTime();
			uint32 cdTime = (curTime > hongliLeijiTime) ? 0 : hongliLeijiTime - curTime;
			if (awardManager.InHuoDongTime(HLCZlist[i]) && (cdTime > 0) )
				SetExtData32(leijiDataId, GetExtData32(leijiDataId) + tongbao);
		}
	}

	if(awardManager.InHuoDongTime(CHuoDongAwardManager::QIANG_HONGBAO))	// 抢红包
	{
		QiangHongBaoClearData();
		SetExtData32(406,GetExtData32(406)+money);
	}
	CheckFestivalDrop(tongbao/100,true);

	if (type == 888)	// 妖石商店
	{
		SetYaoShi(GetYaoShi() + money);
	}

	vector<HDPeiZhiInfo> info;
	uint32 hongdong_type;
	uint32 needMoney = 0;
	// 次充金额累计
//	if (HaveBitSet(200))
	{
		SetExtData32(18, GetExtData32(18) + money);
		hongdong_type = CHuoDongAwardManager::CI_CHONG;
		awardManager.GetPeiZhiInfo(info,hongdong_type);
		if (info.size() == 1)
			needMoney = info[0].price;
		if(!HaveBitSet(556) && GetExtData32(18) >= needMoney) // 是否次充充值完成
			SetBitSet(556);
	}
	
	bool isShouChong = false;
	// 首充
	if(!HaveBitSet(200))
	{
		
		needMoney = 0;
		hongdong_type = CHuoDongAwardManager::SHOU_CHONG;
		awardManager.GetPeiZhiInfo(info,hongdong_type);

		if (info.size() > 0)
		{
			for (uint32 i = 0; i < info.size(); i++)
			{
				if (info[i].index == 1)
				{
					needMoney = info[i].price;
					break;
				}
			}
			if(needMoney > 0 && money >= needMoney) // 是否首次充值完成
			{
				isShouChong = true;
				SetBitSet(200);
				SetExtData32(290, money);
				AddTitle(E2UT_LIUGUANYICAI);
			}
		}
	}

	// 在线的话通知充值信息
	if(isOnLine)
		NoticeChongZhiRet(isShouChong,money);

//	SetYaoShi(GetYaoShi() + money);
}

// 通知客户端充值消息
void CUser::NoticeChongZhiRet(bool isShouChong,uint32 money)
{
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_CHONGZHI_RET);
	msg<<(uint8)1; // op
	int nIsShouChong = 0;
	if (isShouChong)
		nIsShouChong = 1;
	msg<<(uint8)nIsShouChong; // 是否首充
	msg<<(uint32)money; // 本次充值RMB数
	msg<<(uint32)(GetExtData32(14)); // 累计充值RMB数
	sock.SendMsg(m_sock,msg);
}

void CUser::UpdateLianXuChongZhiState(uint32 huodongType)
{
	if (huodongType != CHuoDongAwardManager::LIANXU_CHONGZHI_ORI && huodongType != CHuoDongAwardManager::LIANXU_CHONGZHI_DELUXE)
		return;

	uint32 YBDataId = 261;
//	uint32 firstTimeDataId = 262;
	uint32 YBMaskDataId = 263;

	if (huodongType == CHuoDongAwardManager::LIANXU_CHONGZHI_DELUXE)
	{
		YBDataId = 267;
//		firstTimeDataId = 268;
		YBMaskDataId = 269;
	}

	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	const int ORI = 1;
	//uint32 firstTime = GetExtData32(firstTimeDataId);
	uint32 firstTime = awardManager.GetHuoDongZeroStartTime(huodongType);
	uint32 curTime = GetSysTime();
	uint32 costDay = 1;

	if (firstTime != 0)
	{
		costDay = curTime > firstTime ? ((curTime-firstTime) / (24*3600) + 1) : 1;
		if (costDay > 32)
			costDay = 32;

		uint32 idx = awardManager.GetAwardIdx(huodongType,ORI,costDay);
		if (idx != 0)
		{
			uint32 YB = GetExtData32(YBDataId);
			uint32 YBMask = GetExtData32(YBMaskDataId);
		
			SHuoDongAward award;
			awardManager.GetAwardData(huodongType,idx,award);
			if (YB >= award.needYB)
			{
				YBMask |= (1<<award.idx3);
				SetExtData32(YBMaskDataId, YBMask);
			}
		}
	}
}

void CUser::LianXuChongZhi(uint32 tongbao, uint32 huodongType)
{
	if (huodongType != CHuoDongAwardManager::LIANXU_CHONGZHI_ORI && huodongType != CHuoDongAwardManager::LIANXU_CHONGZHI_DELUXE)
		return;

	uint32 YBDataId = 261;
	uint32 firstTimeDataId = 262;

	if (huodongType == CHuoDongAwardManager::LIANXU_CHONGZHI_DELUXE)
	{
		YBDataId = 267;
		firstTimeDataId = 268;
	}

	uint32 YB = GetExtData32(YBDataId);
	uint32 firstTime = GetExtData32(firstTimeDataId);
	uint32 curTime = GetSysTime();

	if (firstTime == 0)
	{
		uint32 time = curTime - (curTime + 8 * 3600) % 86400;
		SetExtData32(firstTimeDataId, time);
	}

	SetExtData32(YBDataId, YB + tongbao);

	UpdateLianXuChongZhiState(huodongType);
}

void CUser::SendLianXuChongZhiAward(uint32 huodongType)
{
	if (huodongType != CHuoDongAwardManager::LIANXU_CHONGZHI_ORI && huodongType != CHuoDongAwardManager::LIANXU_CHONGZHI_DELUXE)
		return;

	uint32 YBMaskDataId = 263;
	uint32 getOriMaskDataId = 264;
	uint32 getSpeMaskDataId = 265;

	if (huodongType == CHuoDongAwardManager::LIANXU_CHONGZHI_DELUXE)
	{
		YBMaskDataId = 269;
		getOriMaskDataId = 270;
		getSpeMaskDataId = 271;
	}


	vector<uint32> idxList;			
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	const int ORI = 1;
	const int SPE = 2;
	awardManager.GetAwardIdxList(huodongType,ORI,idxList);
	uint32 starNum = 0;
	if(!idxList.empty())
	{
		uint32 YBMask = GetExtData32(YBMaskDataId);
		for (uint32 i = 0; i < idxList.size(); i++)
		{
			SHuoDongAward award;
			awardManager.GetAwardData(huodongType,idxList[i],award);
			uint8 YBState = ((YBMask&(1<<award.idx3)) == 0) ? (uint8)0 : (uint8)1;
			if (YBState == 1)
			{
				starNum++;
				int day = award.idx3;
				uint32 getOriMask = GetExtData32(getOriMaskDataId);
				uint32 getOriState = ((getOriMask&(1 << day)) == 0) ? (uint8)0 : (uint8)1;
				if (getOriState == 0)
				{
					uint32 idx = 0;
					idx = awardManager.GetAwardIdx(huodongType, ORI, day);
					if (idx != 0)
					{
						SHuoDongAward award;
						awardManager.GetAwardData(huodongType, idx, award);
						getOriMask |= (1 << day);
						SetExtData32(getOriMaskDataId, getOriMask);

						char buf[225];
						snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_2507, awardManager.GetHuoDongName(huodongType).c_str(), day);
						SendHuoDongAwardMail(m_roleId, m_level, award, buf, huodongType);
					}
				}
			}
		}
	}

	idxList.clear();
	awardManager.GetAwardIdxList(huodongType, SPE, idxList);
	uint32 getSpeMask = GetExtData32(getSpeMaskDataId);
	if (!idxList.empty())
	{
		for (uint32 i = 0; i < idxList.size(); i++)
		{
			SHuoDongAward award;
			awardManager.GetAwardData(huodongType, idxList[i], award);
			uint32 getSpeState = ((getSpeMask&(1 << award.idx3)) == 0) ? (uint8)0 : (uint8)1;
			if (award.idx3 <= starNum && getSpeState == 0)
			{
				getSpeMask |= (1 << award.idx3);

				char buf[256];
				snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_2508, awardManager.GetHuoDongName(huodongType).c_str(), award.idx3);
				SendHuoDongAwardMail(m_roleId, m_level, award, buf, huodongType);
			}
		}
		SetExtData32(getSpeMaskDataId, getSpeMask);
	}
}

void CUser::LianXuChongZhiClearData(uint32 huodongType,bool isEveryDay)
{
	if (huodongType != CHuoDongAwardManager::LIANXU_CHONGZHI_ORI && huodongType != CHuoDongAwardManager::LIANXU_CHONGZHI_DELUXE)
		return;

	uint32 startTimeDataId = 260;
	uint32 YBDataId = 261;
	uint32 firstTimeDataId = 262;
	uint32 YBMaskDataId = 263;
	uint32 getOriMaskDataId = 264;
	uint32 getSpeMaskDataId = 265;

	if (huodongType == CHuoDongAwardManager::LIANXU_CHONGZHI_DELUXE)
	{
		startTimeDataId = 266;
		YBDataId = 267;
		firstTimeDataId = 268;
		YBMaskDataId = 269;
		getOriMaskDataId = 270;
		getSpeMaskDataId = 271;
	}
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	if (isEveryDay)
	{
		SetExtData32(YBDataId, 0);
	}
	if (!awardManager.InHuoDongTime(huodongType))
	{
		SendLianXuChongZhiAward(huodongType);
	}

	if (awardManager.InHuoDongTime(huodongType))
	{
		uint32 xf_time = awardManager.GetHuoDongStartTime(huodongType);
		if (xf_time != GetExtData32(startTimeDataId))
		{
			SetExtData32(startTimeDataId, xf_time);
			SetExtData32(YBDataId, 0);
			SetExtData32(firstTimeDataId, 0);
			SetExtData32(YBMaskDataId, 0);
			SetExtData32(getOriMaskDataId, 0);
			SetExtData32(getSpeMaskDataId, 0);
		}
		/*else if (isEveryDay)
		{
			uint32 firstTime = GetExtData32(firstTimeDataId);
			uint32 YBMask = GetExtData32(YBMaskDataId);
			uint32 getMask = GetExtData32(getOriMaskDataId);
			uint32 curTime = GetSysTime();
			SendLianXuChongZhiAward(huodongType);
			if (firstTime != 0)
			{
				uint32 costDay = curTime > firstTime ? ((curTime - firstTime) / (24 * 3600) + 1) : 1;
				bool isClear = false;
				if (costDay > 32)
					costDay = 32;
				for (uint32 i = 1; i < costDay; i++)
				{
					uint8 YBState = ((YBMask&(1 << i)) == 0) ? (uint8)0 : (uint8)1;
					if (YBState == 0)
					{
						isClear = true;
						break;
					}
				}

				if (isClear)
				{
					SetExtData32(firstTimeDataId, 0);
					SetExtData32(YBMaskDataId, 0);
					SetExtData32(getOriMaskDataId, 0);
				}
				else
				{
					if (costDay == 8)
					{
						YBMask &= ~(1 << 7);
						getMask &= ~(1 << 7);
						firstTime += 24 * 3600;

						SetExtData32(firstTimeDataId, firstTime);
						SetExtData32(YBMaskDataId, YBMask);
						SetExtData32(getOriMaskDataId, getMask);
					}
				}

				SetExtData32(YBDataId, 0);
			}
		}*/
	}
	else
	{
		if (GetExtData32(startTimeDataId) > 0)
		{
			SendLianXuChongZhiAward(huodongType);
			SetExtData32(startTimeDataId, 0);
			SetExtData32(YBDataId, 0);
			SetExtData32(firstTimeDataId, 0);
			SetExtData32(YBMaskDataId, 0);
			SetExtData32(getOriMaskDataId, 0);
			SetExtData32(getSpeMaskDataId, 0);
		}
	}
}

bool CUser::ChongZhiJiJinFanli(uint32 money)
{
	bool isChong = false;
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 jijinList[] = {CHuoDongAwardManager::JIJIN_FANLI,CHuoDongAwardManager::JIJIN_FANLI2,CHuoDongAwardManager::JIJIN_FANLI3};

	for (uint32 i = 0; i < sizeof(jijinList)/sizeof(jijinList[0]); i++)
	{
		uint32 startTimeDataId;
		uint32 buyRecordDataId;
		uint32 buyFirstTimeDataId;
		uint32 getMaskDataId;
		
		uint32 type = jijinList[i];
	
		if (!GetJiJinFanLiDataId(type,buyRecordDataId,startTimeDataId,buyFirstTimeDataId,getMaskDataId))
			continue;

		uint32 leiJiTime = awardManager.GetHuoDongLeijiTime(type);
		uint32 startTime = awardManager.GetHuoDongStartTime(type);
		
		vector<HDPeiZhiInfo> peizhiInfo;
		awardManager.GetPeiZhiInfo(peizhiInfo,type);
		
		uint32 curTime = GetSysTime();
		uint32 cdTime = (curTime > leiJiTime) ? 0 : leiJiTime - curTime;	
		if(peizhiInfo.size() > 0 && awardManager.InHuoDongTime(type) && cdTime > 0)
		{
			uint8 buyRecord = GetExtData8(buyRecordDataId);
			uint32 buyFirstTime = GetExtData32(buyFirstTimeDataId);
		
			if (buyFirstTime == 0)
			{
				for (uint32 i = 0; i < peizhiInfo.size(); i++)
				{
					if (money == peizhiInfo[i].price)
					{
						uint32 time = curTime - (curTime + 8 * 3600) % 86400;
						buyRecord |= 1 << peizhiInfo[i].index;
						SetExtData8(buyRecordDataId, buyRecord);
						SetExtData32(buyFirstTimeDataId, time);
						isChong = true;
		
						if (GetExtData32(startTimeDataId) == 0)
							SetExtData32(startTimeDataId,startTime);
		
						break;
					}
				}
			}
		}
	}
	
	return isChong;
}

// 循环折扣
bool CUser::RoundZheKouHuoDong(uint32 money)
{
	bool isChong = false;
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 jijinList[] = { CHuoDongAwardManager::ROUND_ZHEKOU_HUODONG1,CHuoDongAwardManager::ROUND_ZHEKOU_HUODONG2,CHuoDongAwardManager::ROUND_ZHEKOU_HUODONG3 };

	for (uint32 i = 0; i < sizeof(jijinList) / sizeof(jijinList[0]); i++)
	{
		uint32 type = jijinList[i];
		uint32 idx = awardManager.GetHuoDongZhouQi(type);
		string name = awardManager.GetHuoDongName(type);
		uint32 clearTime = awardManager.GetHuoDongLeijiTime(type);
		HDPeiZhiInfo peizhi;
		awardManager.GetPeiZhiInfo(peizhi, type, idx);
		if (peizhi.bug_cz == 0)
			continue;
		int hasBitSet = ROUND_ZHEKOU_HUODONG_BITSET + type - CHuoDongAwardManager::ROUND_ZHEKOU_HUODONG1;
		int clearIdx = ROUND_ZHEKOU_HUODONG_CLEAR + type - CHuoDongAwardManager::ROUND_ZHEKOU_HUODONG1;
		int clearData = GetExtData32(clearIdx);
		if (HaveBitSet(hasBitSet) && GetSysTime() > clearData)
		{
			ClearBitSet(hasBitSet);
		}
		if (!HaveBitSet(hasBitSet) && peizhi.water_cz == 1 && peizhi.price == money)
		{
			// 直购成功
			SetBitSet(hasBitSet);
			SetExtData32(clearIdx, clearTime);
			SHuoDongAward award;
			awardManager.GetAwardData(type, idx, award);
			char buf[128];
			snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0108, name.c_str());
			SendHuoDongAwardMail(GetRoleId(), 1, award, buf, type);
			isChong = true;
			CNetMessage msg;
			uint8 op = HD_ROUND_ZHEKOU_LIBAO1 + type - CHuoDongAwardManager::ROUND_ZHEKOU_HUODONG1;
			msg.SetType(MSG_TMP_HUODONG);
			snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0110, name.c_str());
			msg << op << (uint8)2 << PRO_SUCCESS << MakeStringColor(buf);
			SingletonSocket::instance().SendMsg(m_sock, msg);
			break;
		}
	}

	return isChong;
}

void CUser::CheckFestivalDrop(int itemNum,bool isMail)
{
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	if(!awardManager.InHuoDongLeijiTime(CHuoDongAwardManager::FESTIVAL))	//节日活动-彩带掉落
	{
		return;
	}
	int type = CHuoDongAwardManager::FESTIVAL;
	uint32 pic = awardManager.GetHuoDongPic(type);
	vector<GoodsInfo> goodsInfo;
	awardManager.GetHDBangGoods(pic, goodsInfo,type);
	//int itemNum = tongbao/100;
	if(goodsInfo.size() < 1|| itemNum < 1)
		return;

	if(isMail)
	{
		SMailData mdata;
		mdata.AddAward(goodsInfo[0].award, 0, itemNum);
		char buf[256];
		snprintf(buf, sizeof(buf),LANGUAGE_CC_0015,awardManager.GetHuoDongName(type).c_str(),GetItemName(goodsInfo[0].award));
		SendSystemMail(m_roleId,buf,&mdata);
	}
	else
	{
		AddMaterial(goodsInfo[0].award,itemNum);
	}
}

bool CUser::IsInRegDay(int day)
{
	int diffTime = GetSysTime() - Get_RegTime();
	return diffTime < 24 * 3600 * day;
}

int CUser::GetRegDay()
{
	uint32 nextDay = GetTomorrow();
	return ceil((nextDay - reg_time) / (3600 * 24.0));
}

int CUser::GetRegDayToAfterDaySec(int day)
{
	int compareTime = Get_RegTime() + 24 * 3600 * day;
	int now = GetSysTime();
	if (now > compareTime)
	{
		return 0;
	}
	return compareTime - now;
}

bool CUser::ChongZhiLevelJiJinFanli(uint32 money, int addTongBao)
{
	bool isChong = false;
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 jijinList[] = { CHuoDongAwardManager::LEVEL_JIJIN1_FANLI };
	if (!IsInRegDay(7))
	{
		return isChong;
	}
	for (uint32 i = 0; i < sizeof(jijinList) / sizeof(jijinList[0]); i++)
	{
		uint32 dataId = 0;
		uint32 maskDataId = 0;
		uint32 type = jijinList[i];
		if (!GetLevelFanLiDataId(type, dataId, maskDataId))
			continue;

		vector<HDPeiZhiInfo> peizhiInfo;
		awardManager.GetPeiZhiInfo(peizhiInfo, type);

		uint8 buyRecord = GetExtData8(dataId);
		for (uint32 i = 0; i < peizhiInfo.size(); i++)
		{
			if (peizhiInfo[i].index == 1)
				maskDataId = 458;
			else if (peizhiInfo[i].index == 2)
				maskDataId = 475;

			if (money == peizhiInfo[i].price)
			{
				buyRecord |= 1 << peizhiInfo[i].index;
				SetExtData8(dataId, buyRecord);
				SetExtData32(maskDataId, 0);
				isChong = true;
				char showInfo[256];
				snprintf(showInfo, sizeof(showInfo), LANGUAGE_ZQX_0032, GetName(), money);
				SysInfoToAllUser(showInfo);
				AddMaterial(HDAT_YB, addTongBao, false);
				break;
			}
		}
	}

	return isChong;
}

bool CUser::ChongZhiHuoYueJinFanli(uint32 money, int addTongBao)
{
	bool isChong = false;
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 jijinList[] = { CHuoDongAwardManager::HUOYUE_JIJIN_FANLI };
	if (!awardManager.InHuoDongTime(CHuoDongAwardManager::HUOYUE_JIJIN_FANLI))
		return false;
	HuoYueDataChange();
	uint8 buyRecord = GetExtData8(680);
	for (uint32 i = 0; i < sizeof(jijinList) / sizeof(jijinList[0]); i++)
	{
		uint32 type = jijinList[i];

		vector<HDPeiZhiInfo> peizhiInfo;
		awardManager.GetPeiZhiInfo(peizhiInfo, type);

		for (uint32 i = 0; i < peizhiInfo.size(); i++)
		{
			if (money == peizhiInfo[i].price)
			{
				buyRecord |= 1 << peizhiInfo[i].index;
				SetExtData8(680, buyRecord);
				if (peizhiInfo[i].index == 1)
				{
					SetExtData32(470, GetTodayMillsec());
					SetExtData32(471, 0);
					SetExtData8(681, 1);
				}
				else if (peizhiInfo[i].index == 2)
				{
					SetExtData32(472, GetTodayMillsec());
					SetExtData32(473, 0);
					SetExtData8(682, 1);
				}
				isChong = true;
				char showInfo[256];
				snprintf(showInfo, sizeof(showInfo), LANGUAGE_ZQX_0032, GetName(), money);
				SysInfoToAllUser(showInfo);
				AddMaterial(HDAT_YB, addTongBao, false);
				break;
			}
		}
	}

	return isChong;
}

void CUser::SendJijinFanliAward(uint32 type)
{
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();

	uint32 buyRecordDataId;
	uint32 buyFirstTimeDataId;
	uint32 getMaskDataId;
	uint32 startTimeDataId;
	if (!GetJiJinFanLiDataId(type,buyRecordDataId,startTimeDataId,buyFirstTimeDataId,getMaskDataId))
		return;

	uint8 buyRecord = GetExtData8(buyRecordDataId);
	uint32 buyFirstTime = GetExtData32(buyFirstTimeDataId);
	uint32 getMask = GetExtData32(getMaskDataId);
	uint32 curTime = GetSysTime();
	uint32 costDay = curTime > buyFirstTime ? ((curTime - buyFirstTime) / (24 * 3600) + 1) : 1;
	if (costDay > 31)
		costDay = 31;

	if (buyFirstTime <= 0)
		return;
	
	vector<HDPeiZhiInfo> peizhiInfo;
	awardManager.GetPeiZhiInfo(peizhiInfo,type);
	if (peizhiInfo.size() <= 0)
		return;

	for (uint32 i = 0; i < peizhiInfo.size(); i++)
	{
		uint8 buyState = ((buyRecord&(1<<peizhiInfo[i].index)) == 0) ? (uint8)0 : (uint8)1;
		if (buyState == 1)
		{
			vector<uint32> idxList;
			awardManager.GetAwardIdxList(type,peizhiInfo[i].index,idxList);
			for (uint32 j = 0; j < idxList.size(); j++)
			{
				SHuoDongAward award;
				awardManager.GetAwardData(type,idxList[j],award);
				if (award.idx3 > 0 && award.idx3 < 32)
				{
					uint8 getState = ((getMask&(1<<award.idx3)) == 0) ? (uint8)0 : (uint8)1;
					if (getState == 0 && award.idx3 < costDay)
					{
						getMask |= (1<<award.idx3);
						SetExtData32(getMaskDataId, getMask);

						char buf[256];
						snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_2509, award.idx3);
						SendHuoDongAwardMail(m_roleId,m_level,award,buf,type);
					}
				}
			}
			break;
		}
	}
}


void CUser::JijinFanliClearData(uint32 type)
{
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 buyRecordDataId;
	uint32 startTimeDataId;
	uint32 buyFirstTimeDataId;
	uint32 getMaskDataId;
	uint32 curTime = GetSysTime();

	if (!GetJiJinFanLiDataId(type,buyRecordDataId,startTimeDataId,buyFirstTimeDataId,getMaskDataId))
		return;

	if(awardManager.InHuoDongTime(type))
	{
		SendJijinFanliAward(type);

		bool isClear = false;
		uint32 xf_time =  awardManager.GetHuoDongStartTime(type);
		if(xf_time != GetExtData32(startTimeDataId))
		{
			SetExtData32(startTimeDataId, xf_time);
			isClear = true;
		}

		if (! isClear)
		{
			uint32 buyFirstTime = GetExtData32(buyFirstTimeDataId);
			uint32 costDay = curTime > buyFirstTime ? ((curTime - buyFirstTime) / (24 * 3600) + 1) : 1;
			if (costDay >= 8)
				isClear = true;
		}

		if (isClear)
		{
			SetExtData8(buyRecordDataId, 0);
			SetExtData32(buyFirstTimeDataId, 0);
			SetExtData32(getMaskDataId, 0);
		}
	}
	else
	{
		if (GetExtData32(startTimeDataId) > 0)
		{
			SendJijinFanliAward(type);
			SetExtData8(buyRecordDataId, 0);
			SetExtData32(buyFirstTimeDataId, 0);
			SetExtData32(getMaskDataId, 0);
			SetExtData32(startTimeDataId, 0);
		}	
	}
}

void CUser::Send_Anti_Addiction()
{
	Get360LoginInfo();

	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_ANTI_ADDICTION);
	if(m_ad == 5)	// 360
	{
		msg<<m_ad<<m_360_id<<m_360_access_token;
	}
	sock.SendMsg(m_sock,msg);
}

void CUser::Get360LoginInfo()
{
	if(m_ad != 5)
		return;
	if(m_360_expires_in_time == 0)
	{
		char sql[128];
		char **row = NULL;
		snprintf(sql,sizeof(sql),"select token,reflushToken,expiresTime,360Id from 360_LoginInfo where user_Id=%u",m_userId);
		boost::recursive_mutex::scoped_lock lk(G_LoginDB_Mutex);
		if(!g_LoginDB.Query(sql))
			return;
		if((row = g_LoginDB.GetRow()) != NULL)
		{
			m_360_access_token = row[0];
			m_360_refresh_token = row[1];
			m_360_expires_in_time = (time_t)atoi(row[2]);
			m_360_id = atoi(row[3]);
		}
	}
}

void CUser::RecoveryAllHp()
{
//	boost::recursive_mutex::scoped_lock lk(m_mutex);
	vector<uint16> petList;
	GetPetIdList(petList);
	for(uint8 i=0;i < petList.size();i++)
	{
		SPet *pPet = GetPet(petList[i]).get();
		if(pPet != NULL)
		{
			if(pPet->hp < pPet->basicAttr.maxHp)
			{
				pPet->hp = pPet->basicAttr.maxHp;
				SendPetUpdateInfo(petList[i],EUUT_HP);
			}
		}
	}
}

uint8 CUser::GetFeiXianState()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return m_FX_FirstState;
}

void CUser::SetFeiXianState(uint8 val)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_FX_FirstState = val;
	if(val > 0)
		m_FX_SetTime = GetSysTime();
	else
		m_FX_SetTime = 0;
}

uint8 CUser::GetPlantWateringCount()
{
	return GetExtData8(111);
}

void CUser::AddPlantWateringCount()
{
	uint8 t = GetExtData8(111);
	if(t < 255)
		SetExtData8(111,t+1);
}

uint8 CUser::GetPlantKillBugCount()
{
	return GetExtData8(112);
}

void CUser::AddPlantKillBugCount()
{
	uint8 t = GetExtData8(112);
	if(t < 255)
		SetExtData8(112,t+1);
}

uint8 CUser::GetPlantStealCount()
{
	return GetExtData8(113);
}

void CUser::AddPlantStealCount()
{
	uint8 t = GetExtData8(113);
	if(t < 255)
		SetExtData8(113,t+1);
}

uint8 CUser::GetKillPlayerCount()
{
	return GetExtData8(143);
}

void CUser::AddKillPlayerCount()
{
	uint8 t = GetExtData8(143);
	if(t < 255)
		SetExtData8(143,t+1);
}

uint8 CUser::GetPlantSeedTypeCount(uint8 type)
{
	if(type < ZZGain_MIN_Type || type > ZZGain_MAX_Type)
		return 0;
	return GetExtData8(221+type-ZZGain_MIN_Type);
}

void CUser::AddPlantSeedTypeCount(uint8 type)
{
	if(type < ZZGain_MIN_Type || type > ZZGain_MAX_Type)
		return;
	uint16 idx = 221 + type - ZZGain_MIN_Type;
	uint8 t = GetExtData8(idx);
	if(t < 255)
		SetExtData8(idx,t+1);
}

uint8 CUser::GetJiaoYouCount()	// 交游
{
	return GetExtData8(591);
}

void CUser::AddJiaoYouCount()
{
	uint8 t = GetExtData8(591);
	if(t < 255)
		SetExtData8(591,t+1);
}

uint8 CUser::GetCheckYanShengShiCount()	// 查验生石
{
	return GetExtData8(592);
}

void CUser::AddCheckYanShengShiCount()
{
	uint8 t = GetExtData8(592);
	if(t < 255)
		SetExtData8(592,t+1);
}

uint8 CUser::GetCheckDuoXianYinCount()	// 查堕仙印
{
	return GetExtData8(593);
}

void CUser::AddCheckDuoXianYinCount()
{
	uint8 t = GetExtData8(593);
	if(t < 255)
		SetExtData8(593,t+1);
}

uint8 CUser::GetQiMouCount()	// 奇谋
{
	return GetExtData8(594);
}

void CUser::AddQiMouCount()
{
	uint8 t = GetExtData8(594);
	if(t < 255)
		SetExtData8(594,t+1);
}

uint32 CUser::GetJuanXianMoney()	// 捐献金币
{
	return GetExtData32(439);
}

void CUser::AddJuanXianMoney(int money)
{
	if(money <= 0)
		return;
	SetExtData32(439,GetExtData32(439)+money);
}

bool CUser::IsGetBangPaiTaskAward(int taskId)
{
	int maxNum = SingletonCBangPaiManager::instance().GetMaxMissionNum();
	if(taskId > maxNum)
		return true;
	return HaveBitSet(410+taskId);
}

void CUser::SetBangPaiTaskAward(int taskId)
{
	int maxNum = SingletonCBangPaiManager::instance().GetMaxMissionNum();
	if(taskId > maxNum)
		return;
	SetBitSet(410+taskId);
}

bool CUser::HaveGetBangPaiTaskReward(uint8 type)
{
	// type 1 种植 2 浇水 3 除虫 4 偷窃任务
	if(type == 0 || type >= EBTT_MAX)
		return false;
	return HaveBitSet(400+type);
}

void CUser::SetBangPaiTaskReward(uint8 type)
{
	if(type == 0 || type >= EBTT_MAX)
		return;
	SetBitSet(400+type);
}

uint8 CUser::GetPlantPlantsCount()
{
	uint8 num = 0;
	for(uint8 i=ZZGain_MIN_Type;i <= ZZGain_MAX_Type;i++)
		num += GetPlantSeedTypeCount(i);
	return num;
}

void CUser::PushGongGao(const char *pStr)
{
	if(pStr == NULL)
		return;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_gonggao.push_back(pStr);
}

bool CUser::PopGongGao(string &out)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(m_gonggao.size() == 0)
		return false;
	out = m_gonggao.front();
	m_gonggao.pop_front();
	return true;
}

uint8 CUser::GetBangPaiYBPrayNum()
{
	return GetExtData8(114);
}

void CUser::AddBangPaiYBPrayNum()
{
	SetExtData8(114,GetExtData8(114)+1);
}

void CUser::ClearBangPaiYBPrayNum()
{
	SetExtData8(114,0);
}

uint8 CUser::GetBangPaiNormalPrayNum()
{
	return GetExtData8(115);
}

void CUser::AddBangPaiNormalPrayNum()
{
	SetExtData8(115,GetExtData8(115)+1);
}

void CUser::ClearBangPaiNormalPrayNum()
{
	SetExtData8(115,0);
}

uint8 CUser::GetBangPaiRobNum()
{
	return GetExtData8(116);
}

void CUser::AddBangPaiRobNum()
{
	SetExtData8(116,GetExtData8(116)+1);
}

void CUser::ClearBangPaiRobNum()
{
	SetExtData8(116,0);
}

uint8 CUser::GetMoBaiBowNum()
{
	return GetExtData8(117);
}

void CUser::AddMoBaiBowNum()
{
	SetExtData8(117,GetExtData8(117)+1);
}

uint32 CUser::GetShenhun()
{
	return NoLockGetShenhun();
}

uint32 CUser::NoLockGetShenhun()
{
	return NoLockGetExtData32(93);
}

void CUser::AddShenhun(int addNum)
{
	SetExtData32(93, GetExtData32(93) + addNum);
	SendUpdateMoney(HDAT_SHEN_HUN);
}

uint32 CUser::GetJifen()
{
	return NoLockGetJifen();
}

uint32 CUser::NoLockGetJifen()
{
	return NoLockGetExtData32(11);
}

void CUser::AddJifen(int addNum)
{
	SetExtData32(11, GetExtData32(11) + addNum);
	SendUpdateInfo(EUUT_Jifen, addNum);
}

void CUser::AddEquip(uint16 id, uint8 star)
{
	m_petEquipMgr.AddEquip(this, id);
}

void CUser::AddEquipMoney(int addNum)
{
	SetExtData32(466, GetExtData32(466) + addNum);
}

uint32 CUser::GetPetEquipMoney()
{
	return GetExtData32(466);
}

uint8 CUser::GetMoBaiEggNum()
{
	return GetExtData8(118);
}

void CUser::AddMoBaiEggNum()
{
	SetExtData8(118,GetExtData8(118)+1);
}

void CUser::SetBangPaiFireTime()
{
	SetExtData32(105,(uint32)GetSysTime());
}

uint32 CUser::GetBangPaiFireTime()
{
	return GetExtData32(105);
}

void CUser::ClearBangPaiFireTime()
{
	SetExtData32(105,0);
}

void CUser::SetBangPaiStealTime()
{
	SetExtData32(106,(uint32)GetSysTime());
}

uint32 CUser::GetBangPaiStealTime()
{
	return GetExtData32(106);
}

void CUser::ClearBangPaiStealTime()
{
	SetExtData32(106,0);
}

void CUser::SetQunXianData(const char *row)
{
	if(row == NULL || strlen(row) == 0)
		return;
	uint32 len = 512;
	std::vector<uint8> data(len);
	uint32 pos = 0;
	if(!UnCompress(row,&data[0],len))
		return;
	
	uint8 num = data[pos++];
	if(num <= (uint8)MAX_QX_PET_NUM)
		ReadDataFromBuf((char *)&data[0],m_qx_petlist,num*sizeof(m_qx_petlist[0]),pos,len);
	else
		ReadDataFromBuf((char *)&data[0],m_qx_petlist,MAX_QX_PET_NUM*sizeof(m_qx_petlist[0]),pos,len);

	num = data[pos++];
	if(num <= (uint8)MAX_CHU_ZHAN_NUM)
		ReadDataFromBuf((char *)&data[0],m_qx_chuzhan,num*sizeof(m_qx_chuzhan[0]),pos,len);
	else
		ReadDataFromBuf((char *)&data[0],m_qx_chuzhan,MAX_CHU_ZHAN_NUM*sizeof(m_qx_chuzhan[0]),pos,len);

	num = data[pos++];
	if(num <= (uint8)(MAX_QX_PET_NUM+1))
		ReadDataFromBuf((char *)&data[0],m_qx_hpRatio,num*sizeof(m_qx_hpRatio[0]),pos,len);
	else
		ReadDataFromBuf((char *)&data[0],m_qx_hpRatio,(MAX_QX_PET_NUM+1)*sizeof(m_qx_hpRatio[0]),pos,len);

	num = data[pos++];
	if(num <= (uint8)MAX_QX_ATTR_NUM)
		ReadDataFromBuf((char *)&data[0],m_qx_addAttrVal,num*sizeof(m_qx_addAttrVal[0]),pos,len);
	else
		ReadDataFromBuf((char *)&data[0],m_qx_addAttrVal,MAX_QX_ATTR_NUM*sizeof(m_qx_addAttrVal[0]),pos,len);

	num = data[pos++];
	if(num <= (uint8)MAX_QX_ATTR_NUM)
		ReadDataFromBuf((char *)&data[0],m_qx_addAttrPercent,num*sizeof(m_qx_addAttrPercent[0]),pos,len);
	else
		ReadDataFromBuf((char *)&data[0],m_qx_addAttrPercent,MAX_QX_ATTR_NUM*sizeof(m_qx_addAttrPercent[0]),pos,len);

	ReadDataFromBuf((char *)&data[0],&m_qx_dieFlag,sizeof(m_qx_dieFlag),pos,len);
	ReadDataFromBuf((char *)&data[0],&m_qx_awardFlag,sizeof(m_qx_awardFlag),pos,len);
}

void CUser::GetQunXianDataStr(string &str)
{
	int len = 512;
	std::vector<uint8> data(len);
	uint32 pos = 0;

	data[pos++] = MAX_QX_PET_NUM;
	CopyDataToBuf((char *)&data[0],m_qx_petlist,MAX_QX_PET_NUM*sizeof(m_qx_petlist[0]),pos,len);
	data[pos++] = MAX_CHU_ZHAN_NUM;
	CopyDataToBuf((char *)&data[0],m_qx_chuzhan,MAX_CHU_ZHAN_NUM*sizeof(m_qx_chuzhan[0]),pos,len);
	data[pos++] = MAX_QX_PET_NUM+1;
	CopyDataToBuf((char *)&data[0],m_qx_hpRatio,(MAX_QX_PET_NUM+1)*sizeof(m_qx_hpRatio[0]),pos,len);
	data[pos++] = MAX_QX_ATTR_NUM;
	CopyDataToBuf((char *)&data[0],m_qx_addAttrVal,MAX_QX_ATTR_NUM*sizeof(m_qx_addAttrVal[0]),pos,len);
	data[pos++] = MAX_QX_ATTR_NUM;
	CopyDataToBuf((char *)&data[0],m_qx_addAttrPercent,MAX_QX_ATTR_NUM*sizeof(m_qx_addAttrPercent[0]),pos,len);
	CopyDataToBuf((char *)&data[0],&m_qx_dieFlag,sizeof(m_qx_dieFlag),pos,len);
	CopyDataToBuf((char *)&data[0],&m_qx_awardFlag,sizeof(m_qx_awardFlag),pos,len);
	if(!Compress(&data[0],pos,str))
		str.clear();
}

void CUser::SetClientString(char *pStr)    //读档
{
	if (pStr == NULL)
		return;
	uint32 len = strlen(pStr) / 2;
	if (len < 2)
		return;
	char pTemp[1024];
	StrToHex(pStr, (uint8*)pTemp, len);
	int pos = 0;
	int num = 0;
	int ind = 0;
	char val[1024];
	pos = ReadDataFromBuf(pTemp, &num, sizeof(num), pos);
	for (int counter = 0; counter < num; ++counter)
	{
		pos = ReadDataFromBuf(pTemp, &ind, sizeof(int), pos);
		pos = ReadCharFromBuf(pTemp, val, pos);
		SetClientStrData(ind, val);
	}
}
void CUser::GetClientString(string &str)   //存档
{
	int pos = 0;
	uint8 hex[1024];
	int num = m_clientData.size();
	pos = CopyDataToBuf((char*)hex, &num, sizeof(num), pos);
	for (map<uint8, string>::iterator it = m_clientData.begin();
		it != m_clientData.end(); ++it)
	{
		int ind = it->first;
		pos = CopyDataToBuf((char*)hex, &ind, sizeof(int), pos);
		pos = CopyCharToBuf((char*)hex,it->second.c_str(), pos);
	}

	HexToStr(hex, pos, str);
}

void CUser::SetQuestionStr(const char *pStr)
{
	if(pStr == NULL || strlen(pStr) == 0)
		return;
	const int size = 1024;
	uint8 buf[1024];
	uint32 len = StrToHex(pStr, buf, size);
	if(len == 0)
		return;

	uint32 pos = 0;
	uint8 num = 0;
	ReadDataFromBuf((char *)buf,&num,sizeof(num),pos,len);
	m_questionIds.clear();
	for (int counter=0; counter < num; ++counter)
	{
		uint16 ind = 0;
		ReadDataFromBuf((char *)buf, &ind, sizeof(ind), pos, len);
		m_questionIds.push_back(ind);
	}
}

void CUser::GetQuestionStr(string& str)
{
	uint32 pos = 0;
	const int size = 1024;
	uint8 buf[1024];
	uint8 num = m_questionIds.size();
	CopyDataToBuf((char *)buf,&num,sizeof(num),pos,size);
	for (int i = 0; i < num; ++i)
		CopyDataToBuf((char *)buf, &m_questionIds[i], sizeof(uint16), pos, size);

	HexToStr(buf, pos, str);
}

void CUser::GetFindResource(string &str)
{
	str.clear();

	CNetMessage m;
	m<<m_findResouce.level<<m_findResouce.initTime;
	uint32 numPos = m.GetDataLen();
	uint16 num = 0;
	m<<num;
	for(map<int, uint16>::iterator it = m_findResouce.findList.begin(); it != m_findResouce.findList.end(); it++)
	{
		num++;
		m<<it->first<<it->second;
	}
	m.WriteData(numPos, &num, sizeof(num));

	if(!Compress((uint8*)(m.GetMsgData()->c_str() + CNetMessage::GetHeadLen()), m.GetDataLenExceptHead(), str))
	{
		str.clear();
	}
}

void CUser::SetFindResource(const char *pStr)
{
	if(pStr == NULL)
		return;
	uint32 len = 1024*4;
	uint8 *p = new uint8[len];
	memset(p, 0, len);
	boost::scoped_array<uint8> autoDel(p);
	if(!UnCompress(pStr,p,len))
		return;
	m_findResouce.Clear();
	
	CNetMessage m;
	m.WriteData(p, len);
	m>>m_findResouce.level>>m_findResouce.initTime;
	
	uint16 num = 0;
	m>>num;
	for(uint16 i=0;i < num;i++)
	{
		int id = 0;
		uint16 times = 0;
		m>>id>>times;
		m_findResouce.findList[id] = times;
	}
}

void CUser::ClearQuestionId()
{
	m_questionIds.clear();
}

int CUser::GetQuestionId(size_t maxIdx)
{
	static uint32 maxNum = 20;
	if (maxIdx < maxNum)
		return -1;
	if (m_questionIds.empty())
	{
		// 随机idx
		//srand(GetSysTime());
		set<uint16> ids;
		while (ids.size() < maxNum)
		{
			uint16 idx = Random(0, maxIdx);
			ids.insert(idx);
		}
		for (set<uint16>::iterator it = ids.begin(); it != ids.end(); ++it)
		{
			m_questionIds.push_back(*it);
		}
	}

	uint8 idx = GetExtData8(ED8_35);
	if (idx > maxNum)
		return -1;
	return m_questionIds[idx];
}


void CUser::CheckFBLevel()
{
/*	const uint8 QIANGHUA_LV1 = 29;
	const uint8 MONEY_LV1 = 17;
	const uint8 MONEY_LV2 = 38;	// 金币中级需求等级
	const uint8 MONEY_LV3 = 50;	// 金币高级需求等级
	const uint8 SHENGJIE_LV1 = 30;
	const uint8 QIANNENG_LV1 = 32;
	const uint8 CUILIAN_LV1 = 37;
	const uint8 CHONGKAI_LV1 = 40;

	//升级
	uint8 fbLv=GetFBQianghuaLevel();
	if(fbLv == 0 && m_level >= QIANGHUA_LV1)
	{
		IncFBQianghuaLevel();
	}
	fbLv=GetFBJingbiLevel();
	if(fbLv == 0 && m_level >= MONEY_LV1)
	{
		IncFBJingbiLevel();
	}
	if(fbLv==1 && m_level>=MONEY_LV2)
	{
		IncFBJingbiLevel();
		SendSysInfo(this,MakeStringColor(LANGUAGE_TRANSFORM_2529,TIPS_WARNING_COLOR).c_str());
	}
	if(fbLv == 2 && m_level >= MONEY_LV3)
	{
		IncFBJingbiLevel();
		SendSysInfo(this,MakeStringColor(LANGUAGE_TRANSFORM_2530,TIPS_WARNING_COLOR).c_str());
	}
	fbLv=GetFBShengjieLevel();
	if(fbLv == 0 && m_level >= SHENGJIE_LV1)
	{
		IncFBShengjieLevel();
	}
	fbLv=GetFBQiannengLevel();
	if(fbLv == 0 && m_level >= QIANNENG_LV1)
	{
		IncFBQiannengLevel();
	}
	fbLv=GetFBCuilianLevel();
	if(fbLv == 0 && m_level >= CUILIAN_LV1)
	{
		IncFBCuilianLevel();
	}
	fbLv=GetFBZhankaiLevel();
	if(fbLv == 0 && m_level >= CHONGKAI_LV1)
	{
		IncFBZhankaiLevel();
	}

	//人物战斗力
	const int CHONG_KAI_LV2 = 16000;
	const int CHONG_KAI_LV3 = 26000;
	fbLv=GetFBZhankaiLevel();
	int zl=GetZhanDouLi();
	if(fbLv == 1 && zl>= CHONG_KAI_LV2)
	{
		IncFBZhankaiLevel();
		SendSysInfo(this,MakeStringColor(LANGUAGE_TRANSFORM_2531,TIPS_WARNING_COLOR).c_str());
	}
	fbLv=GetFBZhankaiLevel();
	if(fbLv==2 && zl >= CHONG_KAI_LV3)
	{
		IncFBZhankaiLevel();
		SendSysInfo(this,MakeStringColor(LANGUAGE_TRANSFORM_2532,TIPS_WARNING_COLOR).c_str());
	}

	//总战斗力
	zl = GetTotalZhanDouLi();
	const int CUILIAN_LV2 = 77648;
	const int CUILIAN_LV3 = 115700;
	const int QIANNENG_LV2 = 57500;
	const int QIANNENG_LV3 = 73500;
	fbLv=GetFBQiannengLevel();
	if(fbLv == 1 && zl>=QIANNENG_LV2)
	{
		IncFBQiannengLevel();
		SendSysInfo(this,MakeStringColor(LANGUAGE_TRANSFORM_2533,TIPS_WARNING_COLOR).c_str());
	}
    fbLv=GetFBQiannengLevel();
	if(fbLv==2 && zl>=QIANNENG_LV3)
	{
		IncFBQiannengLevel();
		SendSysInfo(this,MakeStringColor(LANGUAGE_TRANSFORM_2534,TIPS_WARNING_COLOR).c_str());
	}
    fbLv=GetFBCuilianLevel();
	if(fbLv==1 && zl>=CUILIAN_LV2)
	{
		IncFBCuilianLevel();
		SendSysInfo(this,MakeStringColor(LANGUAGE_TRANSFORM_2535,TIPS_WARNING_COLOR).c_str());
	}
	fbLv=GetFBCuilianLevel();
	if(fbLv==2 && zl>=CUILIAN_LV3)
	{
		IncFBCuilianLevel();
		SendSysInfo(this,MakeStringColor(LANGUAGE_TRANSFORM_2536,TIPS_WARNING_COLOR).c_str());
	}

	//神将
	const int ZiPetNum_LV2 = 4;
	const int ZiPetNum_LV3 = 5;
	const int ChengPetNum_LV2 = 1;
	const int ChengPetNum_LV3 = 3;
    fbLv=GetFBQianghuaLevel();
	int pn=GetPetNumByLimitQuality(PQT_PURPLE);
	if(fbLv==1 && pn>=ZiPetNum_LV2)
	{
		IncFBQianghuaLevel();
		SendSysInfo(this,MakeStringColor(LANGUAGE_TRANSFORM_2537,TIPS_WARNING_COLOR).c_str());
	}
	fbLv=GetFBQianghuaLevel();
	if(fbLv==2 && pn>= ZiPetNum_LV3)
	{
		IncFBQianghuaLevel();
		SendSysInfo(this,MakeStringColor(LANGUAGE_TRANSFORM_2538,TIPS_WARNING_COLOR).c_str());
	}
	pn=GetPetNumByLimitQuality(PQT_ORANGE);
	fbLv=GetFBShengjieLevel();
	if(fbLv == 1 && pn>=ChengPetNum_LV2)
	{
		IncFBShengjieLevel();
		SendSysInfo(this,MakeStringColor(LANGUAGE_TRANSFORM_2539,TIPS_WARNING_COLOR).c_str());
	}
	fbLv=GetFBShengjieLevel();
	if(fbLv==2 && pn>=ChengPetNum_LV3)
	{
		IncFBShengjieLevel();
		SendSysInfo(this,MakeStringColor(LANGUAGE_TRANSFORM_2540,TIPS_WARNING_COLOR).c_str());
	}
	
	//vip等级
	if(m_vipLevel>=6)
	{
		fbLv=GetFBJingbiLevel();
		if(fbLv==3)
		{
			IncFBJingbiLevel();
			SendSysInfo(this,MakeStringColor(LANGUAGE_TRANSFORM_2541,TIPS_WARNING_COLOR).c_str());
		}
	}
	if(m_vipLevel>=7)
	{
		fbLv=GetFBQianghuaLevel();
		if(fbLv==3)
		{
			IncFBQianghuaLevel();
			SendSysInfo(this,MakeStringColor(LANGUAGE_TRANSFORM_2542,TIPS_WARNING_COLOR).c_str());
		}
	}
	if(m_vipLevel>=8)
	{
		fbLv=GetFBShengjieLevel();
		if(fbLv==3)
		{
			IncFBShengjieLevel();
			SendSysInfo(this,MakeStringColor(LANGUAGE_TRANSFORM_2543,TIPS_WARNING_COLOR).c_str());
		}
	}
	if(m_vipLevel>=9)
	{
		fbLv=GetFBQiannengLevel();
		if(fbLv==3)
		{
			IncFBQiannengLevel();
			SendSysInfo(this,MakeStringColor(LANGUAGE_TRANSFORM_2544,TIPS_WARNING_COLOR).c_str());
		}
	}
	if(m_vipLevel>=10)
	{
		fbLv=GetFBZhankaiLevel();
		if(fbLv==3)
		{
			IncFBZhankaiLevel();
			SendSysInfo(this,MakeStringColor(LANGUAGE_TRANSFORM_2545,TIPS_WARNING_COLOR).c_str());
		}
	}
	if(m_vipLevel>=11)
	{
		fbLv=GetFBCuilianLevel();
		if(fbLv==3)
		{
			IncFBCuilianLevel();
			SendSysInfo(this,MakeStringColor(LANGUAGE_TRANSFORM_2546,TIPS_WARNING_COLOR).c_str());
		}
	}*/
	SingletonCRiChangFuBenManager::instance().CheckFuBenLevel(this);
}

void CUser::SendTreasureMapMsg()
{
	CNetMessage msg;
	msg.SetType(MSG_TREASURE_MAP);

	uint8 completeNum = GetExtData8(134);
	uint16 sid = GetExtData16(45);
	uint16 x = GetExtData16(46);
	uint16 y = GetExtData16(47);
	msg<<(uint8)1;

	uint8 lv = GetLevel();
	uint8 numLimit = TreasureMapNumLimit;
	if(lv < TreasureMapLevelLimit)
	{
		char buf[128];
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_2547,TreasureMapLevelLimit);
		msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
	}
	else
	{
		msg<<PRO_SUCCESS<<numLimit<<completeNum<<sid<<x<<y;
	}
	SingletonSocket::instance().SendMsg(m_sock,msg);
}

// --------------------------------------
// 挖宝任务结束后,通知前端使用藏宝图
// 
//---------------------------------------
void CUser::NotifyUserShowCangBaoTuPanel(){
	uint32 l = GetItemNum(2441);
	uint32 h = GetItemNum(2442);
	if(l == 0 && h == 0)
		return;
	
	CNetMessage msg;
	msg.SetType(MSG_TREASURE_MAP);
	msg<<(uint8)7; 
	msg<<(uint8)PRO_SUCCESS;
	//2441 低阶藏宝图 2442 高级藏宝图
	msg<<l;  // 低级藏宝图数量
	msg<<h;  // 高级藏宝图数量
	SingletonSocket::instance().SendMsg(m_sock,msg);
}



// --------------------------------------
// 使用藏宝图战斗结束后 lua调用,通知前端
// 继续使用藏宝图挖宝
//---------------------------------------
void CUser::NotifyTreasureMapUseResult()
{
	CNetMessage msg;
	msg.SetType(MSG_TREASURE_MAP);
	msg<<(uint8)8; 
	msg<<(uint8)PRO_SUCCESS;
	SingletonSocket::instance().SendMsg(m_sock,msg);
}

uint16 CUser::GetPetExchangeList(CNetMessage &msg)
{
	vector<uint16> petList;
	GetPetIdList(petList);

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	uint16 num = 0;
	uint8 type = 1;	// pet
	for(uint16 i=0;i < petList.size();i++)
	{
		SPet *pPet = NoLockGetPet(petList[i]).get();
		if(pPet != NULL && pPet->chuzhanFlag == 0 && petList[i] != m_gensuiPet && pPet->quality >= PQT_PURPLE)	// 休息,不跟随,紫色以上神将
		{
//			uint8 srcNum = 0;
			uint16 exchangeItemId = 0;
			uint16 exchangeItemNum = 0;
//			GetExchangeTarItem(1,pPet->ziZhiCZ,srcNum,exchangeItemId,exchangeItemNum);
			if(exchangeItemNum == 0)
				continue;
			msg<<type<<i<<(uint16)exchangeItemId<<(uint16)exchangeItemNum;
			num++;
		}
	}
	return num;
}

uint16 CUser::GetItemChipExchangeList(CNetMessage &msg)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	uint16 num = 0;
	uint8 type = 2;	// item
	const uint16 ITEM_ID[] = {2401,2402,2403,2404,2405,2406,2407,2408,2409,2410,2411,2412,2413,2414,2415,2416,2417,2418,2419,2420,2421,2422,2423,2424,2519,2521,2522,2523,2524,2525,2526,2527,2528,2529,2530,2531,2532,2533,2544,2547,
		2563,2565,2567,2569,2824,2826,2909,2911};
	for(uint16 i=0;i <= sizeof(ITEM_ID)/sizeof(ITEM_ID[0]);i++)
	{
		int itemNum = NoLockGetItemNum(ITEM_ID[i]);
		if(itemNum > 0)
		{
			uint8 srcNum = 0;
			uint16 exchangeItemId = 0;
			uint16 exchangeItemNum = 0;
			GetExchangeTarItem(2,ITEM_ID[i],srcNum,exchangeItemId,exchangeItemNum);
			if(exchangeItemNum == 0)
				continue;
			msg<<type<<ITEM_ID[i]<<itemNum<<srcNum;
			msg<<(uint16)exchangeItemId<<(uint16)exchangeItemNum;
			num++;
		}
	}
	return num;
}

void CUser::UpdateFeiXianData()
{
	if(m_robot > 0)
		return;
	uint16 srcSceneId = GetSrcSceneId();
	if(srcSceneId >= FEI_XIAN_SID1 && srcSceneId <= FEI_XIAN_SID5)
	{
		CNetMessage msg;
		msg.SetType(MSG_FEI_XIAN);
		msg<<(uint8)2;
		MakeFeiXianData(msg);
		SingletonSocket::instance().SendMsg(m_sock,msg);
	}
}

void CUser::MakeFeiXianData(CNetMessage &msg)
{
	//uint16 srcSceneId = GetSrcSceneId();
	//if(srcSceneId >= FEI_XIAN_SID1 && srcSceneId <= FEI_XIAN_SID5)
	//{
	//	uint8 feixianState = GetFeiXianState();
	//	uint8 floor = srcSceneId - FEI_XIAN_SID1 + 1;
	//	uint8 winNum = GetExtData8(138);
	//	uint8 failedNum = GetExtData8(139);
	//	uint32 perExp = GetFeiXianExpByFloor(floor,m_level);

	//	//int minute = GetMinute();
	//	int second = GetSysTime()%60;
	//	int huodongLeftTime = 0;
	//	int addExpLeftTime = 60 - second;
	//	if (CSceneManager::IsInActivityTime(SOT_FeiXian))
	//		huodongLeftTime = CSceneManager::GetActivityFinishTime(SOT_FeiXian);
	//	msg<<floor<<feixianState<<winNum<<FeiXian_UpFloorNum<<failedNum<<G_VipConfig[m_vipLevel].fxdown<<perExp<<G_VipConfig[m_vipLevel].fxexp
	//		<<huodongLeftTime<<addExpLeftTime;
	//	vector<SAwardData> awards;
	//	sAwardManager.GetRankAward(EMRA_FENG_SHEN_ZHAN_CHANG, floor, awards);
	//	uint8 size = awards.size();
	//	msg<<size;
	//	for(uint8 i=0;i < size;i++)
	//		msg<< awards[i].type<< awards[i].num;
	//}
}

void CUser::MountTimer()
{
	bool update = false;
	{
		uint32 curTime = (uint32)GetSysTime();
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		uint8 num = m_mount.m_num;
		for(uint8 i=0;i < num;i++)
		{
			if(m_mount.m_id[i] > 0 && m_mount.m_timeLimit[i] > 0 && m_mount.m_timeLimit[i] <= curTime)
			{
				m_mount.RemoveMount(m_mount.m_id[i]);
				update = true;
				break;
			}
		}
	}

	if(update)
	{
		CSocketServer &sock = SingletonSocket::instance();
		CNetMessage msg;
		msg.SetType(MSG_MOUNT);
		msg<<(uint8)1;
		MakeMount(msg);
		sock.SendMsg(m_sock,msg);
	}
}

void CUser::AddFeiXianFirstAward(int minute)
{
	char buf[256];
	if(minute == 2)
	{
		int r = Random(1,3);
		if(r == 1)
		{
			AddMoney(2000);
			snprintf(buf,sizeof(buf), LANGUAGE_TRANSFORM_2553,GetItemName(60000), 2000);
			SendSysInfo(this,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
		}
		else if(r == 2)
		{
			AddBangDingPackage(1100);
			
			snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_2553, GetItemName(1100), 1);
			SendSysInfo(this,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
		}
		else if(r == 3)
		{
			AddBangDingPackage(1105);
			snprintf(buf,sizeof(buf), LANGUAGE_TRANSFORM_2553, GetItemName(1105), 1);
			SendSysInfo(this,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
		}
	}
	else if(minute == 5)
	{
		int r = Random(1, 3);
		if (r == 1)
		{
			AddBangDingPackage(2538, 2);
			snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_2553, GetItemName(2538), 2);
			SendSysInfo(this, MakeStringColor(buf, TIPS_WARNING_COLOR).c_str());
		}
		else if (r == 2)
		{
			AddBangDingPackage(2251, 2);

			snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_2553, GetItemName(2251), 2);
			SendSysInfo(this, MakeStringColor(buf, TIPS_WARNING_COLOR).c_str());
		}
		else if (r == 3)
		{
			AddBangDingPackage(2818, 2);
			snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_2553, GetItemName(2818), 2);
			SendSysInfo(this, MakeStringColor(buf, TIPS_WARNING_COLOR).c_str());
		}
		////                  ratio,itemId,itemNum,公告
		//const int item[][4] = {{1111,1100,1,0},{2222,1105,1,0},{4444,506,1,0},{6667,2310,1,0},{7778,851,2,0},{8222,2376,1,0},
		//	{8444,2377,1,1},{8889,801,1,1},{10000,2370,2,0}};
		//int r = Random(1,10000);
		//for(uint8 i=0;i < sizeof(item)/sizeof(item[0]);i++)
		//{			
		//	if(r <= item[i][0])
		//	{
		//		AddBangDingPackage(item[i][1],item[i][2]);
		//		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_2553,GetItemName(item[i][1]),item[i][2]);
		//		SendSysInfo(this,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());

		//		if(item[i][3] == 1)	// 公告
		//		{
		//			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_2554,ROLE_NAME_COLOR,m_name,ITEM_NAME_COLOR,GetItemName(item[i][1]),item[i][2]);
		//			SysInfoToAllUser(buf,true);
		//		}
		//		break;
		//	}
		//}
	}
}

uint16 CUser::GetTeamLevel()
{
	if(GetTeam() == 0)
		return m_level;
	if(m_pScene == NULL)
		return m_level;
	
	uint8 num = 0;
	uint16 level = 0;
	vector<ShareUserPtr> pMember;
	GetTeamMemberList(this,pMember);
	int roleNum = pMember.size();
	if(roleNum < 1)
		return m_level;
	for(int i=0;i < roleNum;i++)
	{
		if(pMember[i].get() != NULL)
		{
			level += pMember[i]->GetLevel();
			num++;
		}
	}
	level /= num;
	return level;
}

bool CUser::IsXunChaShiKilled(int npcId,int index)
{
	if(index > 6 || index == 0)
		return false;
	index--;
	uint8 pos = GetXunChaShiNpcPos(npcId);
	if(pos == 0xff)
		return false;
	uint32 data = GetExtData32(116);
	if((data & (1 << (pos*6+index))) != 0)
		return true;
	else
		return false;
}

void CUser::SetXunChaShiKilled(int npcId,int index)
{
	if(index > 6 || index == 0)
		return;
	index--;
	uint8 pos = GetXunChaShiNpcPos(npcId);
	if(pos == 0xff)
		return;
	uint32 data = GetExtData32(116);
	data |= (1 << (pos*6+index));
	SetExtData32(116,data);
}

bool CUser::GetFBTongGuan(int fbid)
{
	if(fbid==1)
		return HaveBitSet(193); //神将副本
	else if(fbid==2)
		return HaveBitSet(194); //强化副本
	else if(fbid==3)
		return HaveBitSet(195);
	else if(fbid==4)
		return HaveBitSet(196);
	else if(fbid==5)
		return HaveBitSet(197);
	else if(fbid==101)
		return HaveBitSet(357);
	else if(fbid==102)
		return HaveBitSet(358);
	else if (fbid == COPY_ID_CHONG_WU_1)
		return HaveBitSet(153);
	else if (fbid == COPY_ID_CHONG_WU_2)
		return HaveBitSet(154);
	else if (fbid == COPY_ID_CHONG_WU_3)
		return HaveBitSet(155);
	else if (fbid == COPY_ID_CHONG_WU_4)
		return HaveBitSet(151);
	return false;
}

bool CUser::GetPetFBTongGuan(int idx)
{
	if (idx == 0)
		return HaveBitSet(153);
	else if (idx == 1)
		return HaveBitSet(154);
	else if (idx == 2)
		return HaveBitSet(155);
	else if (idx == 3)
		return HaveBitSet(155);
	else if (idx == 4)
		return HaveBitSet(151);

	return false;
}


uint8 CUser::GetFBLevel(int fbid)
{
	switch (fbid)
	{
	case 2: // 强化副本
		return GetFBQianghuaLevel();

	case 3: 	// 金币副本
		return GetFBJingbiLevel();

	case 4: 	// 升阶副本
		return GetFBShengjieLevel();

	case 5: 	// 潜能副本
		return GetFBQiannengLevel();

	case 101: 	// 淬炼副本
		return GetFBCuilianLevel();

	case 102: 	// 神将铠副本
		return GetFBZhankaiLevel();

	default: 	// 天书副本
		return 1;
	}
	return 0;
}

int CUser::GetFBDorpId(uint32 sceneId)
{
	int fbid = 0;
	switch (sceneId)
	{
	case COPY_ID_QIANG_HUA:// 强化副本
		fbid = 2;
		break;
	case COPY_ID_SHENG_JIE:// 升阶副本
		fbid = 4;
		break;
	case COPY_ID_CUI_LIAN:// 淬炼副本
		fbid = 101;
		break;
	case COPY_ID_CHONG_KAI:// 潜能副本
		fbid = 102;
		break;
	case COPY_ID_CHONG_WU_4:// 天书副本
		fbid = COPY_ID_CHONG_WU_4;
		break;
	default:
		break;
	}
	int level = GetFBLevel(fbid);
	return sCDropMatchingMgr.GetInstanceDropId(fbid, level);
}

int CUser::GetEnterFBMoney(int fbId,bool isExtra)
{
	uint8 level = GetFBLevel(fbId);
	if(level == 0)
		return 0;
	if(level > MAX_FUBEN_LEVEL)
		level = MAX_FUBEN_LEVEL;
	
	int needMoney = 0;
	//if(fbId == 2)	// 强化副本
	//{
	//	const int money[][MAX_FUBEN_LEVEL] = {{0,0,0,0},{0,0,0,0}};
	//	if(!isExtra)
	//		needMoney = money[0][level-1];
	//	else
	//		needMoney = money[1][level-1];
	//}
	//else if(fbId == 4)	// 升阶副本
	//{
	//	const int money[][MAX_FUBEN_LEVEL] = {{2500,3000,3500,4000},{2500,3000,3500,4000}};
	//	if(!isExtra)
	//		needMoney = money[0][level-1];
	//	else
	//		needMoney = money[1][level-1];
	//}
	//else if(fbId == 101)	// 淬炼副本
	//{
	//	const int money[][MAX_FUBEN_LEVEL] = {{3000,3500,4000,4500},{3000,3500,4000,4500}};
	//	if(!isExtra)
	//		needMoney = money[0][level-1];
	//	else
	//		needMoney = money[1][level-1];
	//}
	//else if(fbId == 102)	// 神将铠副本
	//{
	//	const int money[][MAX_FUBEN_LEVEL] = {{2500,3000,3500,4000},{2500,3000,3500,4000}};
	//	if(!isExtra)
	//		needMoney = money[0][level-1];
	//	else
	//		needMoney = money[1][level-1];
	//}
	return needMoney;
}

void CUser::UpgradeFBLevel(int fbid)
{
	if(fbid == 2)// 强化副本
	{
		IncFBQianghuaLevel();
	}
	else if(fbid == 3)	// 金币副本
	{
		IncFBJingbiLevel();
	}
	else if(fbid == 4)	// 升阶副本
	{
		IncFBShengjieLevel();
	}
	else if(fbid == 5)	// 潜能副本
	{
		IncFBQiannengLevel();
	}
	else if(fbid == 101)	// 淬炼副本
	{
		IncFBCuilianLevel();
	}
	else if(fbid == 102)	// 神将铠副本
	{
		IncFBZhankaiLevel();
	}
}

void CUser::ShowHuoDongIcon()
{
//	CSceneManager::NotiyActivityInfo(this, SOT_Baihua);// 白花
//	CSceneManager::NotiyActivityInfo(this, SOT_Kunlunshan);// 昆仑山
//	CSceneManager::NotiyActivityInfo(this, SOT_Husong);// 护送任务
//	CSceneManager::NotiyActivityInfo(this, SOT_FeiXian);// 飞仙
//	CSceneManager::NotiyActivityInfo(this, SOT_BangPaiLueDuo);// 帮派掠夺
//	CSceneManager::NotiyActivityInfo(this, SOT_Bangpailingmo);// 灵魔
//	CSceneManager::NotiyActivityInfo(this, SOT_Fish);// 钓鱼
//	CSceneManager::NotiyActivityInfo(this, SOT_Liujieshizhe);// 六界使者
//	CSceneManager::NotiyActivityInfo(this, SOT_Nianshou);// 年兽
//	CSceneManager::NotiyActivityInfo(this, SOT_Shuangbei);// 双倍
//	CSceneManager::NotiyActivityInfo(this, SOT_BangPaiZhan);// 帮派战
//	CSceneManager::NotiyActivityInfo(this, SOT_LeiTaiSai);// 擂台赛
//	CSceneManager::NotiyActivityInfo(this, SOT_KuaFuLunDao);// 神界论道
//	CSceneManager::NotiyActivityInfo(this, SOT_ShenJieMiJing);// 神界论道
	CSceneManager::NotiyActivityInfo(this, SOT_Spirit);// 领取体力
}


void CUser::UpdatePetAttrInfo( uint8 pos )
{
/*
	vector<SharePetPtr> petList;
	vector<uint8> petPosList;
	GetChuZhanPetList(petList,petPosList);
	if(petPosList.size() > 0 && pos+1 <= (uint8)petPosList.size() && petPosList[pos] != 0xff)
	{
		{
			boost::recursive_mutex::scoped_lock lk(m_mutex);
			int oldPetMaxHp = m_pet[petPosList[pos]]->maxHp;
			m_pet[petPosList[pos]]->Init(this,pos);
			if(m_pet[petPosList[pos]]->maxHp> oldPetMaxHp)
				m_pet[petPosList[pos]]->hp += m_pet[petPosList[pos]]->maxHp - oldPetMaxHp;
		}
		UpdatePet(petPosList[pos]);
	}
*/
}

bool CUser::NoticeClientToKuaFuServer()
{
#ifndef KUA_FU
	if(m_fightId > 0)
		return false;
	if(m_sigId == 0 || m_sigStr.empty() || m_serverId == 0)
		return false;
	m_kuafuState = EKFS_IN_KUAFU;
	return SendKuaFuData(m_serverId,m_sigId,m_sigStr,m_sock);
#else
	return false;
#endif
}

bool CUser::NoticeClientToGameServer()
{
#ifdef KUA_FU
	if(m_fightId > 0)
		return false;
	if(m_sigId == 0 || m_sigStr.empty() || m_serverId == 0)
		return false;
	m_kuafuState = EKFS_RETURN_GAME;
	return SendBackToGameServer(m_serverId,m_sigId,m_sigStr,m_sock);
#else
	return false;
#endif
}

void CUser::SetLoginSig(uint32 sigId,string &sigStr)
{
	if(sigId > 0)
	{
		m_sigId = sigId;
		m_sigStr = sigStr;
	}
}


//////////////////////////////////站位宝石功能END////////////////////////////////

void CUser::ClearAllPackage()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for( int pos= 0; pos< MAX_PACKAGE_NUM2; ++pos )
	{
		if(m_package[pos].tmplId != 0 )
		{
			CItemTemplateManager &itemMgr = SingletonItemManager::instance();
			SItemTemplate *pItem = itemMgr.GetItem(m_package[pos].tmplId);
			if(pItem == NULL)
				continue;
			//if((pItem->type > EIT_WuQi_1) && (pItem->type < EIT_TouKui_1))
				NoLockDelPackage( pos, m_package[pos].num);
		}
	}
}

void CUser::sendXtmasTreeInfo()
{
	if( GetLevel() < 30)
		return;
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 huodong_type = CHuoDongAwardManager::SHENGDAN_FENGSHOU;
	if (!awardManager.InHuoDongTime(huodong_type))
		return;	
	uint8 type = 0;
	switch ( awardManager.GetHuoDongPic(huodong_type))
	{
		case 221:
			{
				type = 1;
			}
			break;
		case 223:
			{
				type = 2;
			}
			break;
		case 224:
			{
				type =3;
			}
			break;
		default:
			break;
	}
	CNetMessage msg;
	msg.SetType(MSG_XTMAS_TREE);
	msg<<(uint8)1<<type;
	uint8 num =0;
	uint32 time = 0;
	int mapID =11;
	int pos_x = 1479;
	int pos_y = 876;
	if( GetExtData8(387)< 5 )
	{
		num = 5 - GetExtData8(387);
		if( (uint32)GetSysTime() < GetExtData32(291) +5*60 )
			time = GetExtData32(291)+5*60 -GetSysTime();
	}
	msg<<num<<time<<mapID<<pos_x<<pos_y;
	SingletonSocket::instance().SendMsg(GetSock(),msg);
}
//////////////////////////////////////////////XIANYUAN START/////////////////////////////////
CXianYuan::CXianYuan()
{
	xy_value = 0;
	cardMap.clear();
	chapterVec.clear();
}

void CUser::LoadXianYuan(char *pStr)  //读档
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);

	if(pStr == NULL)
		return;
	uint32 len = strlen(pStr)/2;
	if(len < 2)
		return;
	char pTemp[1024];
	StrToHex(pStr,(uint8*)pTemp,len);
	int pos = 0;
	int num = 0;
	pos = ReadDataFromBuf(pTemp,&(m_xianyuan.xy_value),sizeof(m_xianyuan.xy_value),pos);
	pos = ReadDataFromBuf(pTemp,&num,sizeof(num),pos);
	m_xianyuan.cardMap.clear();
	for( int counter = 0; counter <num; ++counter )
	{
		uint32 card_id = 0;
		uint32 card_num = 0;
		pos = ReadDataFromBuf(pTemp,&card_id,sizeof(card_id),pos);
		pos = ReadDataFromBuf(pTemp,&card_num,sizeof(card_num),pos);
		m_xianyuan.cardMap.insert(std::make_pair(card_id,card_num));

	}//end of for
	pos = ReadDataFromBuf(pTemp,&num,sizeof(num),pos);
	m_xianyuan.chapterVec.clear();
	for( int counter = 0; counter <num; ++counter )
	{
		 uint32 chapter_id = 0;
		 pos = ReadDataFromBuf(pTemp,&chapter_id,sizeof(chapter_id),pos);
		 m_xianyuan.chapterVec.push_back(chapter_id);
	}//end of for
}
void CUser::SaveXianYuan(string &str) //存档
{
	int pos = 0;
	uint8 hex[1024];
	int num = 0;
	pos = CopyDataToBuf((char*)hex,&(m_xianyuan.xy_value),sizeof(m_xianyuan.xy_value),pos);
	num = m_xianyuan.cardMap.size();
	pos = CopyDataToBuf((char*)hex,&num,sizeof(num),pos);
	map<uint32,uint32>::iterator map_iter = m_xianyuan.cardMap.begin();
	for( ; map_iter != m_xianyuan.cardMap.end(); ++map_iter )	
	{
		uint32 card_id = map_iter->first;
		uint32 card_num = map_iter->second;
		pos = CopyDataToBuf((char*)hex,&card_id,sizeof(card_id),pos);
		pos = CopyDataToBuf((char*)hex,&card_num,sizeof(card_num),pos);
	}

	num = m_xianyuan.chapterVec.size();
	pos = CopyDataToBuf((char*)hex,&num,sizeof(num),pos);
	vector<uint32>::iterator vec_iter = m_xianyuan.chapterVec.begin();
	for( ;vec_iter != m_xianyuan.chapterVec.end();++vec_iter )
	{
		uint32 chapter_id = *vec_iter;
		pos = CopyDataToBuf((char*)hex,&chapter_id,sizeof(chapter_id),pos);
	}
	HexToStr(hex,pos,str);
}
void CUser::MakeXianYuanCardMsg(CNetMessage &msg)
{
	msg<<(int)m_xianyuan.cardMap.size();
	map<uint32,uint32>::iterator map_iter = m_xianyuan.cardMap.begin();
	for( ; map_iter != m_xianyuan.cardMap.end(); ++map_iter )	
	{
		msg<<map_iter->first<<map_iter->second;
	}
}
void CUser::MakeXianYuanChapterMsg(CNetMessage &msg)
{
	msg<<(int)m_xianyuan.chapterVec.size();
	vector<uint32>::iterator vec_iter = m_xianyuan.chapterVec.begin();
	for( ;vec_iter != m_xianyuan.chapterVec.end();++vec_iter )
	{
		msg<<*vec_iter;
	}
}
void CUser::SendAllXianYuanInfo()    //发送仙缘信息
{
	CNetMessage msg;
	msg.SetType(MSG_XIANYUAN);
	msg<<(uint8)1<<(uint8)XIANYUAN_OPEN_CHAPTER<<GetXianYuanValue();
	MakeXianYuanChapterMsg(msg);
	MakeXianYuanCardMsg(msg);
	SingletonCXianYuanManager::instance().MakeDisPlayCardMsg(msg);
	MakeXianYuanMarketMsg(msg);
	SingletonSocket::instance().SendMsg(GetSock(),msg);
}
bool CUser::ActiveXianYuanChapter(uint32 chapter_id) //激活章节
{
	CNetMessage msg;
	msg.SetType(MSG_XIANYUAN);
	msg<<(uint8)2;
	vector<uint32>::iterator vec_iter =std::find(m_xianyuan.chapterVec.begin(),m_xianyuan.chapterVec.end(),chapter_id);
	if( vec_iter != m_xianyuan.chapterVec.end())
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_CHY_28,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(GetSock(),msg);	
		return false;
	}
	//删除道具
	XianYuanChapterInfo info;
	if( !SingletonCXianYuanManager::instance().GetXianYuanChapterInfoByID( chapter_id ,info))
		return false;
	if(  (GetXianYuanCardNum(info.need_card1)|| !info.need_card1 )
		&& (GetXianYuanCardNum(info.need_card2)|| !info.need_card2 )
		&& (GetXianYuanCardNum(info.need_card3)|| !info.need_card3 )
		&& (GetXianYuanCardNum(info.need_card4)|| !info.need_card4 )
		&& (GetXianYuanCardNum(info.need_card5)|| !info.need_card5 ))
	{
		if(info.need_card1)
			SubXianYuanCard(info.need_card1,1);
		if(info.need_card2)
			SubXianYuanCard(info.need_card2,1);
		if(info.need_card3)
			SubXianYuanCard(info.need_card3,1);
		if(info.need_card4)
			SubXianYuanCard(info.need_card4,1);
		if(info.need_card5)
			SubXianYuanCard(info.need_card5,1);

		m_xianyuan.chapterVec.push_back(chapter_id);
		InitAndUpdate();
//		InitChuZhanPet();

		msg<<PRO_SUCCESS<<chapter_id;
		SingletonSocket::instance().SendMsg(GetSock(),msg);
		SendAllXianYuanInfo();
		return true;
	}
	return false;
}

bool CUser::DecomposeXianYuanCard(uint32 card_id,uint32 num)//分解卡片
{
	CNetMessage msg;
	msg.SetType(MSG_XIANYUAN);
	msg<<(uint8)3;
	XianYuanCardInfo info;
	if( !SingletonCXianYuanManager::instance().GetXianYuanCardInfoByID( card_id ,info))
		return false;
	if( GetXianYuanCardNum(card_id) < num || num == 0 )
		return false;
	SubXianYuanCard(card_id ,num);
	uint32 get_xy_value = info.xy_value * num;
	AddXianYuanValue( get_xy_value);
	msg<<PRO_SUCCESS<<card_id<<GetXianYuanCardNum(card_id)<<get_xy_value;
	SingletonSocket::instance().SendMsg(GetSock(),msg);
	SendAllXianYuanInfo();
	return true;
}

bool CUser::LotteryXianYuanCard(uint8 type,uint8 useYB)    //抽取卡片
{
	CNetMessage msg;
	msg.SetType(MSG_XIANYUAN);
	msg<<(uint8)4;
	const uint32 costXY = XY_MARKET_ONCE_COST_XY;
//	const int costYB = XY_MARKET_ONCE_COST_YB;
	const uint32 costXY_10 = XY_MARKET_TEN_COST_XY;
//	const int costYB_10 = XY_MARKET_TEN_COST_YB;
	switch( type)
	{
		case 1:
			{
				if( useYB)	// 抽取券
				{
					if(GetItemNum(2972) > 0)
					{
						DelPackageById(2972,1);
						SaveUseItem(m_roleId,2972,LANGUAGE_SSJ_0222,1);
					}
					else
					{
						return false;
					}

/*
					if( GetTongBao()>= costYB)
					{
						AddTongBao(-costYB);
						SaveBuyShopItem(GetRoleId(),0,0,0,costYB,this->GetTongBao(),YBL_BUY_XIANYUAN_CARD);
					}
					else
					{
						return false;
					}
*/
				}
				else
				{
					if(GetXianYuanValue() >= costXY)
					{
						SubXianYuanValue(costXY);
						ItemCurrencyLog(GetRoleId(),0,0,0,costXY,GetXianYuanValue(),YBL_BUY_XIANYUAN_CARD_XY);
					}
					else
					{
						return false;
					}
				}
				uint32 card_id = 0;
				uint32 quality = 0;
				SingletonCXianYuanManager::instance().DoCardRandom(this,card_id,1,quality);
				if( card_id )
				{
					AddXianYuanCard(card_id,1);
					msg<<GetXianYuanValue()<<(int)1<<card_id;
					SingletonSocket::instance().SendMsg(GetSock(),msg);
					char des[128];
					snprintf(des,sizeof(des),"card_id=%d",card_id);
					SaveDate(GetRoleId(),708,useYB,des);
				}
			}
			break;
		case 2:
			{
				if( useYB)
				{
					if(GetItemNum(2973) > 0)
					{
						DelPackageById(2973,1);
						SaveUseItem(m_roleId,2973,LANGUAGE_SSJ_0223,1);
					}
					else
					{
						return false;
					}
/*
					if( GetTongBao()>= costYB_10)
					{
						AddTongBao(-costYB_10);
						SaveBuyShopItem(GetRoleId(),0,0,0,costYB_10,this->GetTongBao(),YBL_BUY_XIANYUAN_CARD);
					}
					else
					{
						return false;
					}
*/
				}
				else
				{
					if(GetXianYuanValue()>=costXY_10)
					{
						SubXianYuanValue(costXY_10);
						ItemCurrencyLog(GetRoleId(),0,0,0,costXY_10,GetXianYuanValue(),YBL_BUY_XIANYUAN_CARD_XY);
					}
					else
					{
						return false;
					}
				}
				std::vector<uint32> card_vec;
				SingletonCXianYuanManager::instance().DoTenCardRandom(this,card_vec);
				if( !card_vec.empty() )
				{
					msg<<GetXianYuanValue()<<(int)card_vec.size();
					std::vector<uint32>::iterator vec_iter = card_vec.begin();
					std::vector<int> card;
					std::vector<string> card_des;
					card_des.clear();
					for( ;vec_iter != card_vec.end();++vec_iter )
					{
						AddXianYuanCard(*vec_iter,1);
						msg<<*vec_iter;
						card.push_back( (int)*vec_iter);
						card_des.push_back("card_id");
					}//end of for
					SingletonSocket::instance().SendMsg(GetSock(),msg);
					SaveDate(GetRoleId(),709,card,card_des);
				}
			}//end  of switch
	}
	SendAllXianYuanInfo();
	return true;
}

uint32 CUser::GetXianYuanValue()
{
	return m_xianyuan.xy_value;
}

uint32 CUser::AddXianYuanValue(uint32 value)
{
	m_xianyuan.xy_value += value;
	return m_xianyuan.xy_value;
}
uint32 CUser::SubXianYuanValue(uint32 value)
{
	if( m_xianyuan.xy_value >= value )
	{
		m_xianyuan.xy_value  -= value; 
	}
	return m_xianyuan.xy_value;
}

uint32 CUser::GetXianYuanCardNum(uint32 card_id)
{
	uint32 ret = 0;
	std::map<uint32,uint32>::iterator map_iter = m_xianyuan.cardMap.find(card_id);
	if(  map_iter != m_xianyuan.cardMap.end())
	{
		ret = map_iter->second;
	}
	return ret;
}
uint32 CUser::AddXianYuanCard(uint32 card_id,uint32 num)
{
	uint32 ret = 0;
	std::map<uint32,uint32>::iterator map_iter = m_xianyuan.cardMap.find(card_id);
	if(  map_iter != m_xianyuan.cardMap.end())
	{
		map_iter->second += num;
		ret = map_iter->second;
	}
	else
	{
		m_xianyuan.cardMap.insert(std::make_pair(card_id,num));
		ret = num;
	}
	return ret;
}
uint32 CUser::SubXianYuanCard(uint32 card_id,uint32 num)
{
	uint32 ret = 0;
	std::map<uint32,uint32>::iterator map_iter = m_xianyuan.cardMap.find(card_id);
	if(  map_iter != m_xianyuan.cardMap.end())
	{
		if( map_iter->second > num)
		{
			map_iter->second -= num; 
		}
		else if( map_iter->second == num)
		{
			m_xianyuan.cardMap.erase(map_iter);
		}
	}
	return ret;

}
int CUser::GetXianYuanAttrValue(uint32 attr_type)
{
	int attr_value = 0;
//	cout<<GetName()<<",attr_type="<<attr_type;
	std::vector<uint32>::iterator vec_iter = m_xianyuan.chapterVec.begin();
	for( ;vec_iter != m_xianyuan.chapterVec.end();++vec_iter )
	{
		XianYuanChapterInfo info;
		if( !SingletonCXianYuanManager::instance().GetXianYuanChapterInfoByID( *vec_iter ,info))
			continue;
		if( info.attr_type1 == attr_type)
			attr_value += (int)info.attr_value1;
		if( info.attr_type2 == attr_type)
			attr_value += (int)info.attr_value2;
		if( info.attr_type3 == attr_type)
			attr_value += (int)info.attr_value3;
		if( info.attr_type4 == attr_type)
			attr_value += (int)info.attr_value4;
	}
//	cout<<";val="<<attr_value<<"|";
	return attr_value;
}

bool CUser::isXianYuanActived()
{
	return (!m_xianyuan.chapterVec.empty());
}

void CUser::MakeXianYuanMarketMsg(CNetMessage &msg)
{
	uint8 isDiscount = 0;//是否十次抽取在打折期间
	msg<<isDiscount;
	msg<<XY_MARKET_ONCE_COST_YB<<XY_MARKET_TEN_COST_YB<<XY_MARKET_ONCE_COST_XY<<XY_MARKET_TEN_COST_XY;
	msg<<(uint8)(10 - GetExtData8(468));
}

void CUser::GetNextSrcSceneId(uint16 &srcSceneId)
{
	if(srcSceneId == KUN_LUN_SHAN_TEAM_SCENE_ID)
	{
		if(m_lastSrcSceneId == 0 || m_lastSrcSceneId != srcSceneId)
			m_lastSrcSceneId = srcSceneId;
		else
			m_lastSrcSceneId = KUN_LUN_SHAN_TEAM_SCENE_ID+1;
		srcSceneId = m_lastSrcSceneId;
	}
	else if(srcSceneId == SHENJIEMIJING_SCENE_ID)
	{
		if(m_lastSrcSceneId == 0 || m_lastSrcSceneId != srcSceneId)
			m_lastSrcSceneId = srcSceneId;
		else
			m_lastSrcSceneId = SHENJIEMIJING_SCENE_ID+1;
		srcSceneId = m_lastSrcSceneId;
	}
}

///////////////////////////////////////XIANYUAN END///////////////////////////////////////////////////////////

//////////////////////////////////////JINGJIE STAERT//////////////////////////////////////////////////////////

int CUser::GetJingJie()
{
	return GetExtData16(65);
}

void CUser::SetJingJie(int jingjieID)
{
	SetExtData16(65,jingjieID);
}

void CUser::ActiveJingJie()
{
	/*SetJingJie(1);
	SendJingJieInfo();*/
}

void CUser::InitJingJie()   //读档
{
	/*uint16 jingjieOpenLv = sSystemOpenCfgMananger.GetFuncOpenLevel(SOT_JingJie);
	if(GetLevel() >= jingjieOpenLv && GetJingJie() == 0)
		SetJingJie(1);*/
}

void CUser::SendJingJieInfo()
{
	if(!sSystemOpenCfgMananger.CheckSystemOpen(this,SOT_22))
		return;

	uint16 jingjieID = GetJingJie();
	
	CNetMessage msg;
	msg.SetType(MSG_JINGJIE);
	msg<<(uint8)1<<jingjieID;
	SingletonSocket::instance().SendMsg(GetSock(),msg);
}

void CUser::GetJingJieDailyAward()
{
	/*CNetMessage msg;
	msg.SetType(MSG_JINGJIE);
	msg<<(uint8)3;

	SJingJieCfg cfg;
	if(!SingletonCJingJieMgr::instance().GetCfg(GetJingJie(),cfg))
		return;
	if(cfg.id == 0)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0505,TIPS_FAILURE_COLOR);
	}
	else
	{
		if(!HaveBitSet(610))
		{
			SetBitSet(610);
			for(uint16 i=0;i < cfg.dailyAward.size();i++)
				AddMaterial(cfg.dailyAward[i],false,true);
			msg<<PRO_SUCCESS;
		}
		else
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0506,TIPS_FAILURE_COLOR);
		}
	}
	SingletonSocket::instance().SendMsg(m_sock,msg);*/
}

void CUser::UpgradeJingJie()
{
	int curId = GetJingJie();
	int nextId = curId+1;

	CNetMessage msg;
	msg.SetType(MSG_JINGJIE);
	msg<<(uint8)4;

	SJingJieCfg cfg;
	CJingJieManager &mgr = SingletonCJingJieMgr::instance();
	if(!mgr.GetCfg(nextId,cfg))
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0507,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(m_sock,msg);
		return;
	}

	if (cfg.lvCond > m_level)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_64, TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(m_sock, msg);
		return;
	}

	if(!DelCostMaterial(cfg.costs))
		return;

	SetJingJie(nextId);
	SendJingJieInfo();
	InitChuZhanPet();
	ResetPower();
	SendUpdateInfo(EUUT_TotalZhanDouLi);

	if(m_pScene != NULL)
		m_pScene->UpdateUserInfo(this,ESRT_JingJie);
	msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_SSJ_0508,TIPS_SUCCESS_COLOR)<<nextId;
	SingletonSocket::instance().SendMsg(m_sock,msg);
}

bool CUser::ChangeJingJieNameShowState(bool isShow,CNetMessage &msg)
{
	bool curShow = HaveBitSet(609);
	if(curShow != isShow)
	{
		if(isShow)
			SetBitSet(609);
		else
			ClearBitSet(609);
		msg<<PRO_SUCCESS;
		SingletonSocket::instance().SendMsg(m_sock,msg);

		if(m_pScene != NULL)
			m_pScene->UpdateUserInfo(this,ESRT_JingJie);
		return true;
	}
	msg<<PRO_ERROR;
	SingletonSocket::instance().SendMsg(m_sock,msg);
	return false;
}

void CUser::MakeJingJieTitleMsg(CNetMessage &msg)
{
	uint16 jingjieId = GetJingJie();
	uint8 isShow = HaveBitSet(609) ? 1 : 0;
	msg<<jingjieId<<isShow;
}

// idx 0~14 上半场  16~30下半场  31总决赛
uint8 CUser::GetKuaFu1V1VoteState(uint8 idx)
{
	uint32 data = GetExtData32(295);
	uint8 state = (data & (1<<idx)) > 0 ? EKF_1V1_Vote : EKF_1V1_CanVote;
	return state;
}

void CUser::SetKuaFu1V1VoteState(uint8 idx)
{
	uint32 data = GetExtData32(295);
	data |= (1<<idx);
	SetExtData32(295,data);
}

//////////////////////////////////////JINGJIE END//////////////////////////////////////////////////////////
//////////////////////////////////////NEW SHENQI START//////////////////////////////////////////////////////////
CNewShenQi::CNewShenQi()
{
	carry_id = 0;
	sq_level = 0;
	sq_star = 0;
	sq_exp = 0;
	activedVec.clear();
}

void CUser::InitNewShenQi()
{
	if( GetLevel() < NEW_SHENQI_OPEN_LEVEL )
		return;
	SetNewShenQiLevel(1);
	SetNewShenQiStar(0);
}

int CUser::GetNewShenQiCarryID()
{
	return m_shenqi.carry_id;
}
void CUser::SetNewShenQiCarryID(int shenq_id)
{
	m_shenqi.carry_id = shenq_id;
}
int CUser::GetNewShenQiLevel()
{
	return m_shenqi.sq_level;
}
void CUser::SetNewShenQiLevel(int level)
{
	if( level < 0 || level > SHENQI_MAX_LEVEL )
		return;
	m_shenqi.sq_level = level;
}
int CUser::GetNewShenQiStar()
{
	return m_shenqi.sq_star;
}
void CUser::SetNewShenQiStar(int star)
{
	if( star < 0 || star > SHENQI_MAX_STAR)
		return;
	m_shenqi.sq_star = star;
}
int CUser::GetNewShenQiExp()
{
	return m_shenqi.sq_exp;
}
void CUser::SetNewShenQiExp(int exp)
{
	if(exp >=0 )
		m_shenqi.sq_exp = exp;
}
void CUser::InitFromOldShenQi()
{
	if( 0 == GetNewShenQiLevel() )
	{
		InitNewShenQi();
	}
	if( HaveSGBitSet(471))
		return;
	m_shenqi.activedVec.clear();
	SetNewShenQiCarryID((int)GetExtData8(32));
	if( HaveSGBitSet(0))
		m_shenqi.activedVec.push_back(1);
	if( HaveSGBitSet(2))
		 m_shenqi.activedVec.push_back(2);
	if( HaveSGBitSet(4))
		m_shenqi.activedVec.push_back(3);
	SetSGBitSet(471);
}
void CUser::LoadNewShenQi(char *pStr)	//读档
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);

	if(pStr == NULL)
		return;
	uint32 len = strlen(pStr)/2;
	if(len < 2)
		return;
	char pTemp[1024];
	StrToHex(pStr,(uint8*)pTemp,len);
	int pos = 0;
	int num = 0;
	pos = ReadDataFromBuf(pTemp,&(m_shenqi.carry_id),sizeof(m_shenqi.carry_id),pos);
	pos = ReadDataFromBuf(pTemp,&(m_shenqi.sq_level),sizeof(m_shenqi.sq_level),pos);
	pos = ReadDataFromBuf(pTemp,&(m_shenqi.sq_star),sizeof(m_shenqi.sq_star),pos);
	pos = ReadDataFromBuf(pTemp,&(m_shenqi.sq_exp),sizeof(m_shenqi.sq_exp),pos);
	pos = ReadDataFromBuf(pTemp,&num,sizeof(num),pos);
	m_shenqi.activedVec.clear();
	for( int counter = 0; counter <num; ++counter )
	{
		int shenqi_id = 0;
		pos = ReadDataFromBuf(pTemp,&shenqi_id,sizeof(shenqi_id),pos);
		m_shenqi.activedVec.push_back(shenqi_id);
	}//end of for
	if( m_shenqi.sq_level == 0 )
		InitNewShenQi();
}
void CUser::SaveNewShenQi(string &str) //存档
{
	int pos = 0;
	uint8 hex[1024];
	int num = 0;
	pos = CopyDataToBuf((char*)hex,&(m_shenqi.carry_id),sizeof(m_shenqi.carry_id),pos);
	pos = CopyDataToBuf((char*)hex,&(m_shenqi.sq_level),sizeof(m_shenqi.sq_level),pos);
	pos = CopyDataToBuf((char*)hex,&(m_shenqi.sq_star),sizeof(m_shenqi.sq_star),pos);
	pos = CopyDataToBuf((char*)hex,&(m_shenqi.sq_exp),sizeof(m_shenqi.sq_exp),pos);
	num = m_shenqi.activedVec.size();
	pos = CopyDataToBuf((char*)hex,&num,sizeof(num),pos);
	std::vector<int>::iterator vec_iter = m_shenqi.activedVec.begin();
	for( ; vec_iter != m_shenqi.activedVec.end(); ++vec_iter )	
	{
		int data = *vec_iter;
		pos = CopyDataToBuf((char*)hex,&data,sizeof(data),pos);
	}
	HexToStr(hex,pos,str);
}
bool CUser::ActiveNewShenQi(int shenqi_id)
{
	std::vector<int>::iterator vec_iter = std::find(m_shenqi.activedVec.begin(),m_shenqi.activedVec.end(),shenqi_id);
	if( vec_iter == m_shenqi.activedVec.end())
	{
		m_shenqi.activedVec.push_back(shenqi_id);
		SendNewShenQiActiveInfo(shenqi_id);
		SingletonCMissionManager::instance().VerifyNewBranchMissionFinish(this, EMISS_DC_42, shenqi_id);
		return true;
	}
	return false;
}
bool CUser::isNewAShenQiActived(int shenqi_id)
{
	std::vector<int>::iterator vec_iter = std::find(m_shenqi.activedVec.begin(),m_shenqi.activedVec.end(),shenqi_id);
	if( vec_iter != m_shenqi.activedVec.end())
	{
		return true;
	}
	return false;
}
bool CUser::AddNewShenQiExp(int exp)
{
	if( exp <= 0 )
		return false;
	int sq_level = GetNewShenQiLevel();
	int sq_star = GetNewShenQiStar();
	if(sq_level == SHENQI_MAX_LEVEL && sq_star == SHENQI_MAX_STAR)
		return false;
	SetNewShenQiExp( GetNewShenQiExp() + exp);
	//下面升级检测
	SShenQiPeiYang cur_info;
	if(GetShenQiEnhanceInfo(sq_level, sq_star, cur_info))
	{
		while( GetNewShenQiExp() >= cur_info.needExp )
		{
			SetNewShenQiExp( GetNewShenQiExp() - cur_info.needExp );
			if(sq_star == SHENQI_MAX_STAR )
			{
				sq_level++;
				sq_star = 0;
				SetNewShenQiStar(sq_star);
				SetNewShenQiLevel(sq_level);
				if(cur_info.add_shenqi > 0)
					ActiveNewShenQi(cur_info.add_shenqi);
			}
			else
			{
				sq_star++;
				SetNewShenQiStar(sq_star);
			}

			if(sq_level == SHENQI_MAX_LEVEL && sq_star == SHENQI_MAX_STAR)
			{
				SetNewShenQiExp(0);
				return true;
			}

			cur_info.Clear();
			if(!GetShenQiEnhanceInfo(sq_level, sq_star, cur_info))
				break;
		}
		return true;
	}

	return false;
}
bool CUser::ChangeNewShenQiCarryState(int id)
{
	if( 0 == id )//取消当前使用的神器
	{
		if( 0 != GetNewShenQiCarryID())
		{
			SetNewShenQiCarryID(0);
			SendNewShenQiBaseInfo();
			if(m_pScene != NULL)
				m_pScene->UpdateUserInfo(this,ESRT_ShenQi);
			
			CNetMessage msg;
			msg.SetType(MSG_NEW_SHENQI);
			msg<<(uint8)5<<GetNewShenQiCarryID();
			SingletonSocket::instance().SendMsg(GetSock(),msg);
			InitAndUpdate();
			return true;
		}
	}
	else//更换使用神器使用
	{
		if( GetNewShenQiCarryID() != id && isNewAShenQiActived(id))	
		{
			SetNewShenQiCarryID(id);
			SendNewShenQiBaseInfo();
			if(m_pScene != NULL)
				m_pScene->UpdateUserInfo(this,ESRT_ShenQi);

			CNetMessage msg;
			msg.SetType(MSG_NEW_SHENQI);
			msg<<(uint8)5<<GetNewShenQiCarryID();
			SingletonSocket::instance().SendMsg(GetSock(),msg);
			InitAndUpdate();
			return true;
		}
	}
	return false;
}
bool CUser::EnhanceNewShenQi(int item_id,int item_num)
{
	int base_exp = 0;
	switch( item_id)
	{
		case 2818:
			base_exp = 5;
			break;
		case 2819:
			base_exp = 15;
			break;
		case 2820:
			base_exp = 45;
			break;
		case 2821:
			base_exp = 135;
			break;
		default:
			return false;
	}
	if(GetItemNum(item_id) < item_num)
		return false;
	int use_num = 0; //真正使用了的道具数目
	int src_level = GetNewShenQiLevel();
	int src_star = GetNewShenQiStar();
	for(; use_num < item_num; ++use_num )
	{
		if(GetNewShenQiLevel() == SHENQI_MAX_LEVEL && GetNewShenQiStar() == SHENQI_MAX_STAR)
		{
			//已经达到最高等级
			break;
		}
		if(!AddNewShenQiExp(base_exp))
			break;
	}
	//通过真正扣除的道具进行提示
	if(use_num)
	{
		DelPackageById(item_id ,use_num);
		int up_level = GetNewShenQiLevel() - src_level;
		int up_star = 0;
		if( up_level > 0 )
		{
			up_star = up_level * SHENQI_MAX_STAR + GetNewShenQiStar() - src_star;
		}
		else
		{
			up_star = GetNewShenQiStar() - src_star;
		}
		SendNewShenQiEnhanceInfo();
		SendInfoToMe(this,TIPS_SUCCESS_COLOR,LANGUAGE_CHY_45,use_num,use_num * base_exp);
		if( up_star )
			SendInfoToMe(this,TIPS_SUCCESS_COLOR,LANGUAGE_CHY_46,up_star);
		InitAllPet();
		InitAndUpdate();

		SetExtData32(398,GetExtData32(398) + use_num * base_exp);
		return true;
	}

	return false;
}

void CUser::MakeNewShenQiBaseInfo(CNetMessage &msg)
{
	int num = 0;
	uint16 pos = msg.GetDataLen();
	msg<<(int)num;

	vector<int> shenqiList;
	CShenQiConfigMgr &mgr = SingletonShenQiCfgMgr::instance();
	mgr.GetShenQiList(shenqiList);
	for(uint32 i=0; i < shenqiList.size(); i++)
	{
		SShenQiConfig *pShenQi = mgr.GetCfg(shenqiList[i]);
		if(pShenQi == NULL)
			continue;
		msg<<pShenQi->id;
		
		uint8 state = SHENQI_NOT_GET;
		if(isNewAShenQiActived(pShenQi->id))
			state = SHENQI_NOT_USE;
		if( GetNewShenQiCarryID() == pShenQi->id)
			state = SHENQI_USE;
		num++;
		msg<<state;

		StShenQiItemActiveInfo item_info;
		item_info.init();
		if(GetShenQiItemActiveInfo(pShenQi->id,item_info))
			msg<<(uint8)1<<item_info.item_id<<item_info.item_num;
		else
			msg<<(uint8)0<<(uint32)0<<(uint32)0;
	}//end of for

	int sq_level = GetNewShenQiLevel();
	int sq_star = GetNewShenQiStar();
	msg<<sq_level<<sq_star;
	msg.WriteData(pos,&num,sizeof(num));
}

void CUser::SendNewShenQiBaseInfo()
{
	CNetMessage msg;
	msg.SetType(MSG_NEW_SHENQI);
	msg<<(uint8)1;
	MakeNewShenQiBaseInfo(msg);
	SingletonSocket::instance().SendMsg(GetSock(),msg);
}

void CUser::SendNewShenQiEnhanceInfo()
{
	CNetMessage msg;
	msg.SetType(MSG_NEW_SHENQI);
	msg<<(uint8)3;

	int sq_level = GetNewShenQiLevel();
	int sq_star = GetNewShenQiStar();
	SShenQiPeiYang *p = SingletonShenQiCfgMgr::instance().GetPYCfg(sq_level,sq_star);
	if(p == NULL)
		return;
	
	int cur_id = p->cur_shenqi;
	int next_id = p->next_shenqi;
	int next_level = sq_level + 1;
	if(sq_level == SHENQI_MAX_LEVEL)
		next_level = sq_level;
	msg<<cur_id<<sq_level<<next_id<<next_level;
	msg<<sq_star<<GetNewShenQiExp();
	SingletonSocket::instance().SendMsg(GetSock(),msg);
}

void CUser::SendNewShenQiActiveInfo(int shenqi_id)
{
	CNetMessage msg;
	msg.SetType(MSG_NEW_SHENQI);
	msg<<(uint8)4<<shenqi_id;
	SingletonSocket::instance().SendMsg(GetSock(),msg);
}

void CUser::ItemActiveNewShenQi(int shenqi_id)
{
	SShenQiConfig *p = SingletonShenQiCfgMgr::instance().GetCfg(shenqi_id);
	if(p == NULL)
		return;
	
	StShenQiItemActiveInfo item_info;
	item_info.init();
	if(GetShenQiItemActiveInfo(shenqi_id,item_info))
	{
		if(GetItemNum(item_info.item_id)<item_info.item_num)
		{
			SendInfoToMe(this,TIPS_FAILURE_COLOR,LANGUAGE_CHY_87,item_info.item_num-GetItemNum(item_info.item_id),GetItemName(item_info.item_id),p->name.c_str());
		}
		else
		{
			DelPackageById(item_info.item_id,item_info.item_num);
			ActiveNewShenQi(shenqi_id);
			SendInfoToMe(this,TIPS_SUCCESS_COLOR,LANGUAGE_CHY_88);
			InitAllPet();
			InitAndUpdate();
			SendNewShenQiBaseInfo();
		}
	}
	else
	{
		SendInfoToMe(this,TIPS_FAILURE_COLOR,LANGUAGE_CHY_86,p->desc.c_str());
	}
}
//////////////////////////////////////NEW SHENQI END//////////////////////////////////////////////////////////


/////////////////////////////////////KuaFu1vs1Preliminary SATRT///////////////////////////////////////////
bool CUser::IsApplyForKuaFu1vs1Preliminary()
{
	return false;
}
int CUser::GetKuaFu1vs1PreliminaryChallengueCDTime()
{
	return GetExtData32(294);
}
void CUser::SetKuaFu1vs1PreliminaryChallengueCDTime(int data)
{
	SetExtData32(294,data);
}

int CUser::GetKuaFu1vs1PreliminaryUsedChallengueNum()
{
	return GetExtData8(473);
}
void CUser::SetKuaFu1vs1PreliminaryUsedChallengueNum(int data)
{
	SetExtData8(473,(uint8)data);
}

int CUser::GetKuaFu1vs1PreliminaryRefreshHeroNum()
{
	return GetExtData8(474);
}
void CUser::SetKuaFu1vs1PreliminaryRefreshHeroNum(int data)
{
	SetExtData8(474,(uint8)data);
}

int CUser::GetKuaFu1vs1PreliminarySortID()
{
	return GetExtData8(472);
}
void CUser::SetKuaFu1vs1PreliminarySortID(int data)
{
	SetExtData8(472,(uint8)data);
}

#ifdef KUA_FU
void CUser::MakeKuaFu1vs1SaveEnemyInfo(CNetMessage &msg)
{
	for( int counter = 0 ; counter < 5; ++counter )
	{
		msg<<kuaFu1vs1SaveEnemyInfo[counter].role_id;
		msg<<kuaFu1vs1SaveEnemyInfo[counter].name;
		msg<<kuaFu1vs1SaveEnemyInfo[counter].level;
		msg<<kuaFu1vs1SaveEnemyInfo[counter].xiang;
		msg<<kuaFu1vs1SaveEnemyInfo[counter].sex;
		msg<<kuaFu1vs1SaveEnemyInfo[counter].super_level;
		msg<<kuaFu1vs1SaveEnemyInfo[counter].wing_id;
		msg<<kuaFu1vs1SaveEnemyInfo[counter].weapon_id;
		msg<<kuaFu1vs1SaveEnemyInfo[counter].weapon_level;
		msg<<kuaFu1vs1SaveEnemyInfo[counter].zhandouli;
		msg<<kuaFu1vs1SaveEnemyInfo[counter].score;
		msg<<CKuaFu1vs1PreliminaryManager::LOSE_SCORE;
	}
}
#endif

int CUser::GetKuaFu1vs1PreliminaryFightEnemySeq()
{
	return GetExtData8(475);
}
void CUser::SetKuaFu1vs1PreliminaryFightEnemySeq(int data)
{
	SetExtData8(475,(uint8)data);
}

int CUser::GetKuaFu1vs1PreliminaryUsedChallengueTotalNum()
{
	return GetExtData32(296);
}
void CUser::SetKuaFu1vs1PreliminaryUsedChallengueTotalNum(int data)
{
	SetExtData32(296,data);	
}
void CUser::LoadKuaFu1vs1SaveEnemy(char *pStr)    //读档
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);

	if(pStr == NULL)
		return;
	uint32 len = strlen(pStr)/2;
	if(len < 2)
		return;
	char pTemp[1024];
	StrToHex(pStr,(uint8*)pTemp,len);
	int pos = 0;
	int num = 0;
	pos = ReadDataFromBuf(pTemp,&num,sizeof(num),pos);
	for( int counter = 0; counter <num; ++counter )
	{
		char name[128];
		pos = ReadDataFromBuf(pTemp,&kuaFu1vs1SaveEnemyInfo[counter].kind,sizeof(int),pos);
		pos = ReadDataFromBuf(pTemp,&kuaFu1vs1SaveEnemyInfo[counter].role_id,sizeof(int),pos);
		pos = ReadCharFromBuf(pTemp,name,pos);
		kuaFu1vs1SaveEnemyInfo[counter].name = name;
		pos = ReadDataFromBuf(pTemp,&kuaFu1vs1SaveEnemyInfo[counter].level,sizeof(int),pos);
		pos = ReadDataFromBuf(pTemp,&kuaFu1vs1SaveEnemyInfo[counter].xiang,sizeof(int),pos);
		pos = ReadDataFromBuf(pTemp,&kuaFu1vs1SaveEnemyInfo[counter].sex,sizeof(int),pos);
		pos = ReadDataFromBuf(pTemp,&kuaFu1vs1SaveEnemyInfo[counter].super_level,sizeof(int),pos);
		pos = ReadDataFromBuf(pTemp,&kuaFu1vs1SaveEnemyInfo[counter].wing_id,sizeof(int),pos);
		pos = ReadDataFromBuf(pTemp,&kuaFu1vs1SaveEnemyInfo[counter].weapon_id,sizeof(int),pos);
		pos = ReadDataFromBuf(pTemp,&kuaFu1vs1SaveEnemyInfo[counter].weapon_level,sizeof(int),pos);
		pos = ReadDataFromBuf(pTemp,&kuaFu1vs1SaveEnemyInfo[counter].zhandouli,sizeof(int),pos);
		pos = ReadDataFromBuf(pTemp,&kuaFu1vs1SaveEnemyInfo[counter].score,sizeof(int),pos);
		pos = ReadDataFromBuf(pTemp,&kuaFu1vs1SaveEnemyInfo[counter].server_id,sizeof(int),pos);
	}//end of for
}
void CUser::SaveKuaFu1vs1SaveEnemy(string &str)   //存档
{
	int pos = 0;
	uint8 hex[1024];
	int num = 5;
	pos = CopyDataToBuf((char*)hex,&num,sizeof(num),pos);
	for( int counter = 0; counter <num; ++counter )
	{
		pos = CopyDataToBuf((char*)hex,&(kuaFu1vs1SaveEnemyInfo[counter].kind),sizeof(int),pos);
		pos = CopyDataToBuf((char*)hex,&(kuaFu1vs1SaveEnemyInfo[counter].role_id),sizeof(int),pos);
		pos = CopyCharToBuf((char*)hex,kuaFu1vs1SaveEnemyInfo[counter].name.c_str(),pos);
		pos = CopyDataToBuf((char*)hex,&(kuaFu1vs1SaveEnemyInfo[counter].level),sizeof(int),pos);
		pos = CopyDataToBuf((char*)hex,&(kuaFu1vs1SaveEnemyInfo[counter].xiang),sizeof(int),pos);
		pos = CopyDataToBuf((char*)hex,&(kuaFu1vs1SaveEnemyInfo[counter].sex),sizeof(int),pos);
		pos = CopyDataToBuf((char*)hex,&(kuaFu1vs1SaveEnemyInfo[counter].super_level),sizeof(int),pos);
		pos = CopyDataToBuf((char*)hex,&(kuaFu1vs1SaveEnemyInfo[counter].wing_id),sizeof(int),pos);
		pos = CopyDataToBuf((char*)hex,&(kuaFu1vs1SaveEnemyInfo[counter].weapon_id),sizeof(int),pos);
		pos = CopyDataToBuf((char*)hex,&(kuaFu1vs1SaveEnemyInfo[counter].weapon_level),sizeof(int),pos);
		pos = CopyDataToBuf((char*)hex,&(kuaFu1vs1SaveEnemyInfo[counter].zhandouli),sizeof(int),pos);
		pos = CopyDataToBuf((char*)hex,&(kuaFu1vs1SaveEnemyInfo[counter].score),sizeof(int),pos);
		pos = CopyDataToBuf((char*)hex,&(kuaFu1vs1SaveEnemyInfo[counter].server_id),sizeof(int),pos);
	}

	HexToStr(hex,pos,str);

}
/////////////////////////////////////KuaFu1vs1Preliminary END////////////////////////////////////////////////
void CUser::LoadMoneyGiftBagHuoDongMap(char *pStr)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);

	if(pStr == NULL)
		return;
	uint32 len = strlen(pStr)/2;
	if(len < 2)
		return;
	char pTemp[1024];
	StrToHex(pStr,(uint8*)pTemp,len);
	int pos = 0;
	int hd_num = 0;
	StMoneyGiftBagHuoDongInfo info;
	pos = ReadDataFromBuf(pTemp,&hd_num,sizeof(hd_num),pos);
	for( int hd_counter = 0; hd_counter <hd_num; ++hd_counter )
	{
		info.init();
		int hd_type = 0;
		pos = ReadDataFromBuf(pTemp,&hd_type,sizeof(hd_type),pos);
		pos = ReadDataFromBuf(pTemp,&info.huodong_charge,sizeof(info.huodong_charge),pos);
		pos = ReadDataFromBuf(pTemp,&info.huodong_start_time,sizeof(info.huodong_start_time),pos);
		int gift_num = 0;
		pos = ReadDataFromBuf(pTemp,&gift_num,sizeof(gift_num),pos);
		for(int gift_counter = 0;gift_counter<gift_num;++gift_counter)
		{
			int gift_id = 0;
			int buy_num = 0;
			pos = ReadDataFromBuf(pTemp,&gift_id,sizeof(gift_id),pos);
			pos = ReadDataFromBuf(pTemp,&buy_num,sizeof(buy_num),pos);
			info.gift_huodong_map.insert(std::make_pair(gift_id,buy_num));
		}//end of for
		moneyGiftBagHuoDongMap.insert(std::make_pair(hd_type,info));
	}
	
}
void CUser::SaveMoneyGiftBagHuoDongMap(string &str)
{
	int pos = 0;
	uint8 hex[1024];
	int hd_num = 0;
	hd_num = moneyGiftBagHuoDongMap.size();
	pos = CopyDataToBuf((char*)hex,&hd_num,sizeof(hd_num),pos);
	MoneyGiftBagHuoDongMapIter hd_iter = moneyGiftBagHuoDongMap.begin();
	for( ;hd_iter != moneyGiftBagHuoDongMap.end(); ++hd_iter )
	{
		pos = CopyDataToBuf((char*)hex,&hd_iter->first,sizeof(hd_iter->first),pos);
		pos = CopyDataToBuf((char*)hex,&hd_iter->second.huodong_charge,sizeof(hd_iter->second.huodong_charge),pos);
		pos = CopyDataToBuf((char*)hex,&hd_iter->second.huodong_start_time,sizeof(hd_iter->second.huodong_start_time),pos);
		int gift_num = hd_iter->second.gift_huodong_map.size();
		pos = CopyDataToBuf((char*)hex,&gift_num,sizeof(gift_num),pos);
		map<int,int>::iterator gift_iter= hd_iter->second.gift_huodong_map.begin();
		for( ;gift_iter != hd_iter->second.gift_huodong_map.end(); ++gift_iter)
		{
			pos = CopyDataToBuf((char*)hex,&(gift_iter->first),sizeof(gift_iter->first),pos);
			pos = CopyDataToBuf((char*)hex,&(gift_iter->second),sizeof(gift_iter->second),pos);
		}//end of for
	}//end of for
	HexToStr(hex,pos,str);
}

int CUser::GetMoneyGiftBagBuyNum(int hd_type,int gift_id)
{
	int hd_start_time = SingletonCHuoDongAwardManager::instance().GetHuoDongStartTime(hd_type);
	if( !hd_type || !gift_id || !hd_start_time)
		return 0;
	int num = 0;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	MoneyGiftBagHuoDongMapIter hd_iter = moneyGiftBagHuoDongMap.begin();
	for( ;hd_iter != moneyGiftBagHuoDongMap.end(); ++hd_iter )
	{
		if( hd_iter->first == hd_type)
		{
			if( hd_iter->second.huodong_start_time != hd_start_time )
			{
				hd_iter->second.init();
				hd_iter->second.huodong_start_time = hd_start_time;
				return 0;
			}
			else
			{
				map<int,int>::iterator gift_iter= hd_iter->second.gift_huodong_map.begin();
				for( ;gift_iter != hd_iter->second.gift_huodong_map.end(); ++gift_iter)
				{
					if( gift_iter->first == gift_id)
					{
						num = gift_iter->second;
						return num;
					}
				}//end of for
			}
		}
	}//end of for
	return 0;
}
void CUser::AddMoneyGiftBagBuyNum(int hd_type,int gift_id)
{
	int hd_start_time = SingletonCHuoDongAwardManager::instance().GetHuoDongStartTime(hd_type);
	if( !hd_type || !gift_id || !hd_start_time)
		return;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	MoneyGiftBagHuoDongMapIter hd_iter = moneyGiftBagHuoDongMap.begin();
	for( ;hd_iter != moneyGiftBagHuoDongMap.end(); ++hd_iter )
	{
		if( hd_iter->first == hd_type)
		{
			if( hd_iter->second.huodong_start_time != hd_start_time )
			{
				hd_iter->second.init();
				hd_iter->second.huodong_start_time = hd_start_time;
				hd_iter->second.gift_huodong_map.insert(std::make_pair(gift_id,1));
				return;
			}
			else
			{
				map<int,int>::iterator gift_iter= hd_iter->second.gift_huodong_map.begin();
				for( ;gift_iter != hd_iter->second.gift_huodong_map.end(); ++gift_iter)
				{
					if( gift_iter->first == gift_id)
					{
						gift_iter->second +=1;
						return;
					}
				}//end of for
				hd_iter->second.gift_huodong_map.insert(std::make_pair(gift_id,1));
			}
		}
	}//end of for
	StMoneyGiftBagHuoDongInfo info;
	info.huodong_charge = hd_start_time;
	info.gift_huodong_map.insert(std::make_pair(gift_id,1));
	moneyGiftBagHuoDongMap.insert(std::make_pair(hd_type,info));
	return;
}
int CUser::GetMoneyGiftBagChargeNum(int hd_type)
{
	int hd_start_time = SingletonCHuoDongAwardManager::instance().GetHuoDongStartTime(hd_type);
	if( !hd_type || !hd_start_time)
		return 0;
	int num = 0;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	MoneyGiftBagHuoDongMapIter hd_iter = moneyGiftBagHuoDongMap.begin();
	for( ;hd_iter != moneyGiftBagHuoDongMap.end(); ++hd_iter )
	{
		if( hd_iter->first == hd_type)
		{
			if( hd_iter->second.huodong_start_time != hd_start_time )
			{
				hd_iter->second.init();
				hd_iter->second.huodong_start_time = hd_start_time;
				return 0;
			}
			else
			{
				num = hd_iter->second.huodong_charge;
				return num;
			}
		}
	}//end of for
	return 0;
}
void CUser::AddMoneyGiftBagChargeNum(int hd_type,int add_value)
{
	int hd_start_time = SingletonCHuoDongAwardManager::instance().GetHuoDongStartTime(hd_type);
	if( !hd_type || !add_value ||!hd_start_time)
		return;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	MoneyGiftBagHuoDongMapIter hd_iter = moneyGiftBagHuoDongMap.begin();
	for( ;hd_iter != moneyGiftBagHuoDongMap.end(); ++hd_iter )
	{
		if( hd_iter->first == hd_type)
		{
			if( hd_iter->second.huodong_start_time != hd_start_time )
			{
				hd_iter->second.init();
				hd_iter->second.huodong_start_time = hd_start_time;
				hd_iter->second.huodong_charge = add_value;
				return;
			}
			else
			{
				hd_iter->second.huodong_charge += add_value;
				return;
			}
		}
	}//end of for
	StMoneyGiftBagHuoDongInfo info;
	info.huodong_start_time = hd_start_time;
	info.huodong_charge = add_value;
	moneyGiftBagHuoDongMap.insert(std::make_pair(hd_type,info));

}

///////////////////////////////////////TRANDFORM　START////////////////////////////////////////
void CUser::SendTransFormCardInfo()
{
	CNetMessage msg;
	msg.SetType(MSG_TRANSFORM);
	msg<<(uint8)1;
	int num = m_transformCardMap.size();
	msg<<num;
	map<int,int>::iterator map_iter = m_transformCardMap.begin();
	for( ;map_iter!= m_transformCardMap.end(); ++map_iter)
	{
		msg<<map_iter->first<<map_iter->second;
	}//end of for
	SingletonSocket::instance().SendMsg(GetSock(),msg);	
}
void CUser::SendCurTransFormTimeInfo()
{
	CNetMessage msg;
	msg.SetType(MSG_TRANSFORM);
	msg<<(uint8)2;
	int id = GetCurTransFormID();
	int time = GetCurTranFormEndTime();
	uint8 state = HaveBitSet(600) ? 1 : 0;
	if( time <= GetSysTime())
	{
		id = 0;
		time = 0;
	}
	else
	{
		time -= GetSysTime();
	}
	msg<<id<<time<<state;
	SingletonSocket::instance().SendMsg(GetSock(),msg);
}
void CUser::SendUpdateTransFormInfo()
{
	uint8 tranState = HaveBitSet(600) ? 1 : 0;
	CNetMessage msg;
	msg.SetType(MSG_TRANSFORM);
	msg<<(uint8)5;
	msg<<GetTransFormMonsterID( GetCurTransFormID())<<tranState;
	SingletonSocket::instance().SendMsg(GetSock(),msg);
}
void CUser::UseTransFormCard(int item_id,uint8 pos,int num)
{
	if( item_id == 0 || num ==0 )
		return;
	SItemInstance* pItem = GetItem(pos);
	if( pItem && pItem->num >= num)
	{
		DelPackage(pos,num);
		map<int,int>::iterator map_iter = m_transformCardMap.find(item_id);
		if( map_iter!= m_transformCardMap.end() )
		{
			map_iter->second += num;	
		}
		else
		{
			m_transformCardMap.insert(make_pair(item_id,num));
		}
		SendInfoToMe(this,TIPS_WARNING_COLOR,LANGUAGE_CHY_105);
	}
}
void CUser::ClearTransForm()
{
	SetCurTransFormID(0);
	SetCurTranFormEndTime(0);
	ClearBitSet(600);
	
	SendUpdateTransFormInfo();
	SendInfoToMe(this,TIPS_SUCCESS_COLOR,LANGUAGE_CHY_103);
	CScene *pScene = GetScene();
	if(pScene) 
		pScene->UpdateUserInfo(this,ESRT_TransormShape);

	InitAndUpdate();
//	InitChuZhanPet();
}
bool CUser::ActiveTransForm(int item_id)
{
	StTransFormCardInfo info;
	if( !SingletonCTransFormManager::instance().GetTransFormCardInfoByID(item_id,info))
		return false;
	map<int,int>::iterator map_iter = m_transformCardMap.find(item_id);
	if( map_iter!= m_transformCardMap.end() )
	{
		if(item_id != 3165 && item_id != 3166 && item_id != 3167)
			map_iter->second--;
		if(map_iter->second == 0)
		{
			m_transformCardMap.erase(map_iter);
		}
		
		SetCurTransFormID(item_id);
		SetCurTranFormEndTime(info.last_time*60);
		ClearBitSet(600);
		
		SendUpdateTransFormInfo();
		SendInfoToMe(this,TIPS_SUCCESS_COLOR,LANGUAGE_CHY_104,info.monster_name.c_str());
		SendTransFormCardInfo();			
		CScene *pScene = GetScene();
		if(pScene) 
			pScene->UpdateUserInfo(this,ESRT_TransormShape);
		InitAndUpdate();
//		InitChuZhanPet();
	}
	return false;
}
void CUser::GetTransFormAttr( StInitAttrInfo &info,bool isForPet)
{
	if( !GetCurTransFormID())
		return;
	StTransFormCardInfo card_info;
	if( !SingletonCTransFormManager::instance().GetTransFormCardInfoByID(GetCurTransFormID(),card_info))
		return;
	if( !isForPet  && card_info.target_type == 2 )
		return ;
	if( isForPet && card_info.target_type == 1)
		return;
	for(int counter = 0; counter<(int)(sizeof(card_info.attr_type)/sizeof(card_info.attr_type[0]));++counter)
	{
		info.set(card_info.attr_type[counter],card_info.attr_value[counter]);
	}
}
int CUser::GetCurTransFormID()
{
	return GetExtData32(349);
}
void CUser::SetCurTransFormID(int item_id)
{
	SetExtData32(349,item_id);
}
int CUser::GetCurTranFormEndTime()
{
	return GetExtData32(350);
}
void CUser::SetCurTranFormEndTime(int last_time)
{
	SetExtData32(350,GetSysTime()+last_time);
}
int CUser::GetTransFormMonsterID(int item_id)
{
	int monster_id = 0;
	StTransFormCardInfo info;
	if( SingletonCTransFormManager::instance().GetTransFormCardInfoByID(item_id,info))
	{
		monster_id = info.monster_id;
	}
	return monster_id;
}
void CUser::LoadTransFormCard(char *pStr)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(pStr == NULL)
		return;
	uint32 len = strlen(pStr)/2;
	if(len < 2)
		return;
	char pTemp[1024];
	StrToHex(pStr,(uint8*)pTemp,len);
	int pos = 0;
	int num = 0;
	pos = ReadDataFromBuf(pTemp,&num,sizeof(num),pos);
	for( int counter = 0; counter < num; ++counter )
	{
		int item_id = 0;
		int item_num = 0;
		pos = ReadDataFromBuf(pTemp,&item_id,sizeof(item_id),pos);
		pos = ReadDataFromBuf(pTemp,&item_num,sizeof(item_num),pos);
		m_transformCardMap.insert(std::make_pair(item_id,item_num));
	}
}
void CUser::SaveTransFormCard(string &str)
{
	int pos = 0;
	uint8 hex[1024];
	int num = 0;
	num = m_transformCardMap.size();
	pos = CopyDataToBuf((char*)hex,&num,sizeof(num),pos);
	map<int,int>::iterator map_iter = m_transformCardMap.begin();
	for( ;map_iter!= m_transformCardMap.end(); ++map_iter)
	{
		pos = CopyDataToBuf((char*)hex,&map_iter->first,sizeof(map_iter->first),pos);
		pos = CopyDataToBuf((char*)hex,&map_iter->second,sizeof(map_iter->second),pos);
	}//end of for
	HexToStr(hex,pos,str);
}
void CUser::TransFormLeftTimeCheck()
{
	if( GetFightId() != 0 )//战斗中不做处理
		return;
	if(GetCurTransFormID() && GetCurTranFormEndTime()<GetSysTime())
	{
		ClearTransForm();		
	}
}
void CUser::GetTransFormDrop()
{
	return;

/*
	const int day_drop_limit_num = 10;
	if(GetExtData8(477) < day_drop_limit_num)
	{
		int item_id = SingletonCTransFormManager::instance().GetRandomDropTransFormCardID();
		if(item_id)
		{
			SetExtData8(477,GetExtData8(477)+1);
			AddPackage(item_id,1);
			SendInfoToMe(this,TIPS_WARNING_COLOR,LANGUAGE_TRANSFORM_126,GetItemName(item_id),1);
		}
	}
*/
}

bool CUser::CoverCurTransFormCheck(int item_id)
{
	if( GetCurTransFormID() != 0 )
	{
		CNetMessage msg;
		msg.SetType(MSG_TRANSFORM);
		msg<<(uint8)3;
		msg<<GetCurTransFormID()<<item_id;	
		SingletonSocket::instance().SendMsg(GetSock(),msg);
		return true;
	}
	return false;
}
//////////////////////////////////////TRANSFORM END///////////////////////////////////////////



// type 
// 值: 		1攻击 2暴击 3闪避 4反击 5连击 6防御 7速度 8抗性       16血
// 百分比:	17攻击18暴击19闪避20反击21连击22防御23速度24抗性      32血
void CUser::AddQunXianBufferState(int type,uint32 value)
{
	if(type <= MAX_QX_ATTR_NUM)	// 值
		m_qx_addAttrVal[type-1] += value;
	else if(type <= 2*MAX_QX_ATTR_NUM)	// 百分比
		m_qx_addAttrPercent[type-MAX_QX_ATTR_NUM-1] += value;
	else
		return;
}

float CUser::GetQunXianRoleHpRatio()
{
	return GetQunXianHpRatio(m_qx_hpRatio[MAX_QX_PET_NUM]);
}

float CUser::GetQunXianPetHpRatio(uint8 pos)
{
	if(pos == 0xff)
		return 0.0f;
	for(uint8 i=0;i < MAX_QX_PET_NUM;i++)
	{
		if(m_qx_chuzhan[i] == pos)
			return GetQunXianHpRatio(m_qx_hpRatio[i]);
	}
	return 0.0f;
}

// type 1神将 2人
void CUser::SetQunXianHpRatio(uint8 type,uint8 pos,float &val,bool die)
{
	int ratio = val*10000;
	if(ratio > 10000)
		ratio = 10000;
	else if(ratio < 0)
		ratio = 0;
	if(type == 1)	// 神将
	{
		for(int i=0;i < MAX_QX_PET_NUM;i++)
		{
			if(m_qx_petlist[i] == pos)
			{
				if(die)
				{
					m_qx_hpRatio[i] = 0;
					m_qx_dieFlag |= (0x1 << i);
					for(int j=0;j < MAX_CHU_ZHAN_NUM;j++)
					{
						if(m_qx_chuzhan[j] == pos)
						{
							m_qx_chuzhan[j] = 0xff;
							break;
						}
					}
				}
				else
				{
					m_qx_hpRatio[i] = ratio;
				}
				break;
			}
		}
	}
	else if(type == 2)	// 人
	{
		m_qx_hpRatio[MAX_QX_PET_NUM] = ratio;
	}
}

void CUser::CopyQunXianAttrVal(uint32 *addAttrVal,int vsize,uint16 *addAttrPercent,int psize)
{
	if(vsize < MAX_QX_ATTR_NUM || psize < MAX_QX_ATTR_NUM)
		return;
	memcpy(addAttrVal,m_qx_addAttrVal,sizeof(m_qx_addAttrVal));
	memcpy(addAttrPercent,m_qx_addAttrPercent,sizeof(m_qx_addAttrPercent));
}

bool CUser::SetQunXianPets(uint16 *petId,int size)
{
	if(size > MAX_QX_PET_NUM || petId == NULL)
		return false;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(int i=0;i < size;i++)
	{
		if(petId[i] == 0)
			return false;
	}
	memcpy(m_qx_petlist,petId,size);
	for(int i=0;i < MAX_CHU_ZHAN_NUM;i++)
		m_qx_chuzhan[i] = m_qx_petlist[i];
	return true;
}

void CUser::SetQunXianPetChuZhan(uint8 type,uint16 petId,uint8 zhanweiPos,CNetMessage &msg)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(petId == 0 || (type == 0 && zhanweiPos >= MAX_CHU_ZHAN_NUM) || type > 1)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0104,TIPS_FAILURE_COLOR);
		return;
	}
	uint8 listPos = 0xff;
	for(uint8 i=0;i < (uint8)MAX_QX_PET_NUM;i++)
	{
		if(m_qx_petlist[i] == petId)
		{
			listPos = i;
			break;
		}
	}
	if(listPos == 0xff)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0104,TIPS_FAILURE_COLOR);
		return;
	}
	
	if(type == 0)	// 出战
	{
		for(int i=0;i < MAX_CHU_ZHAN_NUM;i++)
		{
			if(m_qx_chuzhan[i] == petId)
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0105,TIPS_FAILURE_COLOR);
				return;
			}
		}
		if(m_qx_chuzhan[zhanweiPos] > 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0106,TIPS_FAILURE_COLOR);
			return;
		}
		m_qx_chuzhan[zhanweiPos] = petId;
		msg<<PRO_SUCCESS;
	}
	else if(type == 1)	// 下阵
	{
		for(int i=0;i < MAX_CHU_ZHAN_NUM;i++)
		{
			if(m_qx_chuzhan[i] == petId)
			{
				m_qx_chuzhan[i] = 0;
				msg<<PRO_SUCCESS;
				return;
			}
		}
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0104,TIPS_FAILURE_COLOR);
	}
}

void CUser::MakeQunXianPetMsg(CNetMessage &msg)
{
	uint8 petNum = 0;
	uint16 numPos = msg.GetDataLen();
	msg<<petNum;
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint8 i=0;i < MAX_QX_PET_NUM;i++)
	{
		if(m_qx_petlist[i] > 0)
		{
			uint8 die = (m_qx_dieFlag & (0x1<<i)) > 0 ? 1 : 0;
			msg<<m_qx_petlist[i]<<die;
			petNum++;
		}
	}
	msg.WriteData(numPos,&petNum,sizeof(petNum));

	numPos = msg.GetDataLen();
	petNum = 0;
	msg<<petNum;
	for(uint8 i=0;i < MAX_CHU_ZHAN_NUM;i++)
	{
		msg<<i<<m_qx_chuzhan[i];
		petNum++;
	}
	msg.WriteData(numPos,&petNum,sizeof(petNum));
}

bool CUser::HaveGetQunXianAward(int idx)
{
	if(idx < 1 || (uint16)idx > sizeof(m_qx_awardFlag)*8)
		return true;
	const uint64 mask = 0x1;
	return ((m_qx_awardFlag & (mask<<(idx-1))) > 0) ? true : false;
}

void CUser::SetQunXianAwardFlag(int idx)
{
	if(idx < 1 || (uint16)idx > sizeof(m_qx_awardFlag)*8)
		return;
	const uint64 mask = 0x1;
	m_qx_awardFlag |= (mask<<(idx-1));
}

void CUser::SendQunXianPetList()
{
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_QUNXIANZHENGBA);
	msg<<(uint8)15;
	MakeQunXianPetMsg(msg);
	SingletonSocket::instance().SendMsg(m_sock,msg);
}

void CUser::MakeQunXianBuffMsg(CNetMessage &msg)
{
	uint8 num = 0;
	uint16 pos = msg.GetDataLen();
	msg<<num;
	for(uint8 i=0;i < MAX_QX_ATTR_NUM;i++)
	{
		if(m_qx_addAttrVal[i] > 0)
		{
			msg<<(uint8)(i+1)<<m_qx_addAttrVal[i];
			num++;
		}
	}

	for(uint8 i=0;i < MAX_QX_ATTR_NUM;i++)
	{
		if(m_qx_addAttrPercent[i] > 0)
		{
			msg<<(uint8)(i+1+16)<<(m_qx_addAttrPercent[i]/100);
			num++;
		}
	}
	msg.WriteData(pos,&num,sizeof(num));
}

void CUser::SetQunXianCurFloor(uint8 floor)
{
	if(floor > (uint8)CQunXianZhengBaManager::MAX_FLOOR)
		return;
	SetExtData8(486,floor);
	if(GetExtData8(488) < floor)	// 首次通关
		SetExtData8(488,floor);	// 更新历史最高层
	SingletonCQunXianZhengBaManager::instance().UpdateRoleFloor(this,floor);
}

void CUser::SetIgnoreVip(uint8 flag) 
{
    if(flag == 2  && HaveBitSet(604))
    {
        ClearBitSet(604);
    }
    else if(flag == 1  && !HaveBitSet(604))
    {
        SetBitSet(604);
    }
    else  
        return;
    SendIgnoreVipInfo(); 
}

bool CUser::GetIgnoreVip()
{
    return HaveBitSet(604);
}

void CUser::SendIgnoreVipInfo()
{
    uint8 ret = GetIgnoreVip()? 1 : 2;
    CNetMessage msg;
    msg.SetType(MSG_IGNORE_FUNC);
    msg<<(uint8)1<<ret;
    SingletonSocket::instance().SendMsg(GetSock(),msg);
}

void CUser::SetIgnoreQieCuo(uint8 type) 
{
    if(type == 0  && HaveBitSet(577))
    {
        ClearBitSet(577);
    }
    else if(type == 1  && !HaveBitSet(577))
    {
        SetBitSet(577);
    }
    else  
        return;
    SendIgnoreQieCuoInfo(); 
}
bool CUser::GetIgnoreQieCuo()
{
    return HaveBitSet(577);
}

void CUser::SendIgnoreQieCuoInfo()
{
    uint8 ret = GetIgnoreQieCuo()?1:0;
    CNetMessage msg;
    msg.SetType(MSG_IGNORE_QIECUO);
    msg<<ret;
    SingletonSocket::instance().SendMsg(GetSock(),msg);
}

void CUser::SetHuoYueTaskList(vector<HuoYueTaskInfo> &infos)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_huoyueTaskList.clear();
	m_huoyueTaskList = infos;
}

void CUser::GetHuoYueTaskList(vector<HuoYueTaskInfo> &infos)
{
	infos.clear();
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for (uint32 i = 0; i < m_huoyueTaskList.size(); i++)
	{
		infos.push_back(m_huoyueTaskList[i]);
	}
}

void CUser::CreateHuoYueTask()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);

	std::vector<int> taskArr(m_huoyueTaskMax);
	RandomSequence(&taskArr[0],m_huoyueTaskMax,m_huoyueTaskMax);

	for (int i = 0; i < HUOYUE_MAX_TASK; i++)
	{
		SetExtData32(HUOYUE_TASK_DATA_ID[i],taskArr[i]);
	}
	SetExtData32(420,0);
}

void CUser::CreateHuoYueTaskById(uint8 id)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);

	while (1)
	{
		uint32 ranNum = Random(1,m_huoyueTaskMax);
		int i = 0;
		for (; i < HUOYUE_MAX_TASK; i++)
		{
			uint32 data = GetHuoYueTaskInfo(GetExtData32(HUOYUE_TASK_DATA_ID[i]));
			if (ranNum == data)
				break;
		}

		if (i == HUOYUE_MAX_TASK)
		{
			SetExtData32(HUOYUE_TASK_DATA_ID[id],ranNum);
			break;
		}
	}
}


void CUser::SetHuoYueTaskMax(uint32 taskMax)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_huoyueTaskMax = taskMax;
}

void CUser::GetCurrentZhenFaData(vector<SZhenFaMemData> &userData)
{
	userData.clear();
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	userData = m_zhenfaMember;
}

void CUser::GetAllPartAttr(vector<SAttrData> &attr)
{
	attr.clear();

	// 坐骑
	CMountConfigMgr &mountMgr = SingletonMountCfgMgr::instance();
	for(uint8 i=0;i < m_mount.m_num;i++)
	{
		if(m_mount.m_id[i] > 0)
		{
			SMountConfig *pCfg = mountMgr.GetCfg(m_mount.m_id[i]);
			if(pCfg == NULL)
				continue;
			MergeAttrList(attr,pCfg->attrList);
		}
	}
	SMountQH *pMountQHCfg = mountMgr.GetQHCfg(m_mount.m_level);
	if(pMountQHCfg != NULL)
	{
		MergeAttrList(attr,pMountQHCfg->attrList);
	}

	// 翅膀
	CWingConfigMgr &wingMgr = SingletonWingCfgMgr::instance();
	for(uint8 i=0;i < m_wing.m_num;i++)
	{
		if(m_wing.m_id[i] > 0)
		{
			SWingConfig *pCfg = wingMgr.GetCfg(m_wing.m_id[i]);
			if(pCfg == NULL)
				continue;
			MergeAttrList(attr,pCfg->attrList);
		}
	}
	SWingQH *pWingQHCfg = wingMgr.GetQHCfg(m_wing.m_level,m_wing.m_star);
	if(pWingQHCfg != NULL)
	{
		MergeAttrList(attr,pWingQHCfg->attrList);
	}

	// 神器
	CShenQiConfigMgr &shenqiMgr = SingletonShenQiCfgMgr::instance();
	for(uint8 i=0;i < m_shenqi.activedVec.size();i++)
	{
		if(m_shenqi.activedVec[i] > 0)
		{
			SShenQiConfig *pCfg = shenqiMgr.GetCfg(m_shenqi.activedVec[i]);
			if(pCfg == NULL)
				continue;
			MergeAttrList(attr,pCfg->attrList);
		}
	}
	SShenQiPeiYang *pShenqiQHCfg = shenqiMgr.GetPYCfg(m_shenqi.sq_level,m_shenqi.sq_star);
	if(pShenqiQHCfg != NULL)
	{
		MergeAttrList(attr,pShenqiQHCfg->attrList);
	}

	// 称号
	GetAllUseTitleAttr(attr);

	// 境界
	SJingJieCfg jingjieCfg;
	if(SingletonCJingJieMgr::instance().GetCfg(GetJingJie(),jingjieCfg))
	{
		MergeAttrList(attr,jingjieCfg.attr);
	}
}

bool CUser::CheckCostMaterial(vector<SCostData> &materials,string &error)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return NoLockCheckCostMaterial(materials,error);
}

bool CUser::NoLockCheckCostMaterial(vector<SCostData> &materials,string &error)
{
	if(materials.empty())
		return true;
	for(uint8 i=0;i < materials.size();i++)
	{
		error = GetItemName(materials[i].costType);
		if(materials[i].costType < HDAT_MONEY)
		{
			if(NoLockGetItemNum(materials[i].costType) < materials[i].costValue)
				return false;
		}
		else
		{
			bool has = true;
			switch (materials[i].costType)
			{
			case HDAT_MONEY:
				has = GetMoney() >= materials[i].costValue;
				break;
			case HDAT_BANG_YB:
			case HDAT_YB:
				has = GetTongBao() >= materials[i].costValue;
				break;
			case HDAT_SHEN_HUN:
				has = GetShenhun() >= (uint32)materials[i].costValue;
				break;
			case HDAT_QIANNENG:
				has = GetQianNeng() >= materials[i].costValue;
				break;
			case HDAT_XingXiuJingHua:
				has = GetExtData32(ED32_XZMoney) >= (uint32)materials[i].costValue;
				break;
			case HDAT_JJCMoney:
				has = GetExtData32(ED32_JJCMoney) >= (uint32)materials[i].costValue;
				break;
			case HDAT_KunLunMoney:
				has = GetExtData32(ED32_KLMoney) >= (uint32)materials[i].costValue;
				break;
			case HDAT_PET:
			case HDAT_EQUIP:
			case HDAT_EXP:
			case HDAT_CHENGHAO:
			case HDAT_WING:
			case HDAT_MOUNT:
			case HDAT_SHENQI:
			case HDAT_CHRISTMASTREE_GROW_VALUE:
			case HDAT_CHRISTMASTREE_PERSON_VALUE:
			case HDAT_VIP_EXP:
			case HDAT_LEITAI_JIFEN:
			case HDAT_JINGLIAN_EXP:
			case HDAT_BANGPAI_MONEY:
			case HDAT_BANG_GONG:
				has = (GetBangGong() >= materials[i].costValue);
				break;
			case HDAT_AttrType:
			case HDAT_PetEquip:
			case HDAT_TiLi:
				break;
			case HDAT_ArenaCnt:
				break;
			case HDAT_FaBao:
				break;
			case HDAT_RoleExp:
				break;
			default:
				break;
			}
			if (!has)
				return false;
		}
	}
	return true;
}

bool CUser::DelCostMaterial(vector<SCostData> &materials)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	string err;
	if (!NoLockCheckCostMaterial(materials, err)) return false;
	return NoLockDelCostMaterial(materials);
}

bool CUser::NoLockDelCostMaterial(vector<SCostData> &materials)
{
	if(materials.empty())
		return true;
	for(uint8 i=0;i < materials.size();i++)
	{
		if(materials[i].costType < HDAT_MONEY)
		{
			NoLockDelPackageById(materials[i].costType,materials[i].costValue);
		}
		else
		{
			switch (materials[i].costType)
			{
			case HDAT_MONEY:
				AddMoney(-materials[i].costValue);
				break;
			case HDAT_BANG_YB:
			case HDAT_YB:
				AddTongBao(-materials[i].costValue);
				break;
			case HDAT_SHEN_HUN:
				AddShenhun(-materials[i].costValue);
				break;
			case HDAT_QIANNENG:
				break;
			case HDAT_TiLi:
				m_userSpirit.SubSpirit(this, materials[i].costValue);
				break;
			case HDAT_ArenaCnt:
				break;

			case HDAT_XingXiuJingHua:
				SetExtData32(ED32_XZMoney, GetExtData32(ED32_XZMoney) - materials[i].costValue);
				SendUpdateMoney(HDAT_XingXiuJingHua);
				break;
			case HDAT_JJCMoney:
				SetExtData32(ED32_JJCMoney, GetExtData32(ED32_JJCMoney) - materials[i].costValue);
				SendUpdateMoney(HDAT_JJCMoney);
				break;
			case HDAT_KunLunMoney:
				SetExtData32(ED32_KLMoney, GetExtData32(ED32_KLMoney) - materials[i].costValue);
				SendUpdateMoney(HDAT_KunLunMoney);
				break;

			case HDAT_PET:
			case HDAT_EQUIP:
			case HDAT_EXP:
			case HDAT_CHENGHAO:
			case HDAT_WING:
			case HDAT_MOUNT:
			case HDAT_SHENQI:
			case HDAT_CHRISTMASTREE_GROW_VALUE:
			case HDAT_CHRISTMASTREE_PERSON_VALUE:
			case HDAT_VIP_EXP:
			case HDAT_LEITAI_JIFEN:
			case HDAT_JINGLIAN_EXP:
			case HDAT_BANGPAI_MONEY:
			case HDAT_BANG_GONG:
				AddBangGong(-materials[i].costValue);
				SendUpdateMoney(HDAT_BANG_GONG);
				break;
			case HDAT_AttrType:
			case HDAT_PetEquip:
			case HDAT_FaBao:
			case HDAT_RoleExp:
			default:
				break;
			}
		}
	}
	return true;
}

bool CUser::CheckCostMaterial(vector<SAwardData> &materials,string &error)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return NoLockCheckCostMaterial(materials,error);
}

bool CUser::NoLockCheckCostMaterial(vector<SAwardData> &materials,string &error)
{
	if(materials.empty())
		return true;
	for(uint8 i=0;i < materials.size();i++)
	{
		error = GetItemName(materials[i].type);
		if(materials[i].type < HDAT_MONEY)
		{
			if(NoLockGetItemNum(materials[i].type) < materials[i].num)
				return false;
		}
		else if(materials[i].type == HDAT_MONEY)
		{
			if(GetMoney() < materials[i].num)
				return false;
		}
		else if(materials[i].type == HDAT_BANG_YB)
		{
			if(GetTongBao(1) < materials[i].num)
				return false;
		}
		else if(materials[i].type == HDAT_PET)
		{

		}
		else if(materials[i].type == HDAT_YB)
		{
			if(GetTongBao() < materials[i].num)
				return false;
		}
		else if(materials[i].type == HDAT_EQUIP)
		{

		}
		else if(materials[i].type == HDAT_EXP)
		{

		}
		else if(materials[i].type == HDAT_QIANNENG)
		{
			if(GetQianNeng() < materials[i].num)
				return false;
		}
		else if(materials[i].type == HDAT_CHENGHAO)
		{

		}
		else if(materials[i].type == HDAT_WING)
		{

		}
		else if(materials[i].type == HDAT_MOUNT)
		{

		}
		else if(materials[i].type == HDAT_SHENQI)
		{

		}
		else if(materials[i].type == HDAT_CHRISTMASTREE_GROW_VALUE)
		{

		}
		else if(materials[i].type == HDAT_CHRISTMASTREE_PERSON_VALUE)
		{

		}
		else if(materials[i].type == HDAT_BANGPAI_MONEY)
		{

		}
	}
	return true;
}

bool CUser::DelCostMaterial(vector<SAwardData> &materials)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return NoLockDelCostMaterial(materials);
}

bool CUser::NoLockDelCostMaterial(vector<SAwardData> &materials)
{
	if(materials.empty())
		return true;
	for(uint8 i=0;i < materials.size();i++)
	{
		if(materials[i].type < HDAT_MONEY)
		{
			NoLockDelPackageById(materials[i].type,materials[i].num);
		}
		else if(materials[i].type == HDAT_MONEY)
		{
			AddMoney(-materials[i].num);
		}
		else if(materials[i].type == HDAT_BANG_YB)
		{
			AddTongBao(-materials[i].num,1);
		}
		else if(materials[i].type == HDAT_PET)
		{

		}
		else if(materials[i].type == HDAT_YB)
		{
			AddTongBao(-materials[i].num);
		}
		else if(materials[i].type == HDAT_EQUIP)
		{
			m_petEquipMgr.AddEquip(this, materials[i].num);
		}
		else if(materials[i].type == HDAT_EXP)
		{

		}
		else if(materials[i].type == HDAT_QIANNENG)
		{
			AddQianNeng(-materials[i].num);
		}
		else if(materials[i].type == HDAT_CHENGHAO)
		{

		}
		else if(materials[i].type == HDAT_WING)
		{

		}
		else if(materials[i].type == HDAT_MOUNT)
		{

		}
		else if(materials[i].type == HDAT_SHENQI)
		{

		}
		else if(materials[i].type == HDAT_CHRISTMASTREE_GROW_VALUE)
		{

		}
		else if(materials[i].type == HDAT_CHRISTMASTREE_PERSON_VALUE)
		{

		}
		else if(materials[i].type == HDAT_BANGPAI_MONEY)
		{

		}
	}
	return true;
}

void CUser::GetAutoUseItemAward(uint16 itemId,uint16 itemNum,vector<SAwardData> &awardList)
{
	awardList.clear();
	if(itemId == 0 || itemNum == 0)
		return;
	//CItemTemplateManager &itemMgr = SingletonItemManager::instance();
	//SItemTemplate *pItem = itemMgr.GetItem(itemId);
	/*if(pItem == NULL || pItem->type != EIT_Box_5)
		return;*/
	
	int dropId = sCDropMatchingMgr.GetItemDropId(itemId);
	if (dropId == 0)
		return;
	for(uint16 i=0;i<itemNum;++i)
		sAwardManager.GetLevelAward(dropId, GetLevel(), awardList);
}

bool CUser::AddMaterial(uint32 type, int value, bool isFight,bool showMsg, int star/* = 1*/)
{
	if(value == 0)
		return true;
	
	switch (type)
	{
	case HDAT_MONEY:
		AddMoney(value);
		break;

	case HDAT_BANG_YB:
		AddTongBao(value);
		//AddTongBao(value, 1);
		break;

	case HDAT_PET:
		::AddPet(this, value, 1);
		break;

	case HDAT_YB:
		AddTongBao(value);
		break;

	case HDAT_SHEN_HUN:
		AddShenhun(value);
		SendUpdateMoney(type);
		break;

	case HDAT_EXP:
		AddPetExp(value);
		break;

	case HDAT_RoleExp:
		AddExp(value, showMsg, isFight);
		break;

	case HDAT_QIANNENG:
		AddQianNeng(value);
		break;

	case HDAT_BANG_GONG:
		AddBangGong(value);
		SendUpdateMoney(type);
		break;

	case HDAT_VIP_EXP:
		AddExVipExp(value);
		UpdateVipInfoEx();
		break;

	case HDAT_CHENGHAO:
		AddTitle(value);
		break;

	case HDAT_SHENQI:
		ActiveNewShenQi(value);
		break;

	case HDAT_LEITAI_JIFEN:
		AddJifen(value);
		break;

	case HDAT_PetEquip:
		AddEquip(value, star);
		break;

	case HDAT_XingXiuJingHua:
		AddEquipMoney(value);
		SendUpdateMoney(type);
		break;

	case HDAT_ArenaCnt:
		SetExtData16(ED16_69, GetExtData16(ED16_69) + value);
		SendUpdateMoney(type);
		break;

	case HDAT_EQUIP:
		m_petEquipMgr.AddEquip(this, value);
		break;

	case HDAT_FaBao:
		m_petEquipMgr.AddFaBao(this, value);
		break;

	case HDAT_TiLi:
		m_userSpirit.AddSpirit(this, value);
		break;

	case HDAT_FaBaoSS:
		m_petEquipMgr.AddSouSuoCnt(this, value);
		break;

	case HDAT_HuoYue:
		AddHuoYue(value);
		SendUpdateMoney(type);
		break;

	case HDAT_BANG_Exp:
		AddBangExp(value);
		break;

	case HDAT_WING:
	case HDAT_MOUNT:
	case HDAT_CHRISTMASTREE_GROW_VALUE:
	case HDAT_CHRISTMASTREE_PERSON_VALUE:
	case HDAT_BANGPAI_MONEY:
		break;

	case HDAT_JJCMoney:
		SetExtData32(ED32_JJCMoney, GetExtData32(ED32_JJCMoney) + value);
		SendUpdateMoney(type);
		break;
	case HDAT_KunLunMoney:
		SetExtData32(ED32_KLMoney, GetExtData32(ED32_KLMoney) + value);
		SendUpdateMoney(type);
		break;

	default:
		if (type < HDAT_MONEY)
		{
			if (value > 0)
				AddBangDingPackage(type, value);
			else
				DelPackageById(type, 0 - value);
		}
		break;
	}

	if (showMsg)
	{
		char buf[256];
		switch (type)
		{
		case HDAT_CHENGHAO:
			snprintf(buf, sizeof(buf), LANGUAGE_SSJ_0493, GetTitleName(value));
			break;

		case HDAT_SHENQI:
			snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0039, GetShenqiName(value));
			break;

		case HDAT_EQUIP:
		{
			CItemCfgManager& emgr = sCItemCfgManager;
			snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0215, emgr.GetEquipColor(value), emgr.GetEquipName(value));
			break;
		}

		case HDAT_PET:
			snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0173, GetPetName(value));
			break;

		case HDAT_FaBao:
			snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0213, GetFaBaoName(value));
			break;

		case HDAT_ArenaCnt:
			snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0221, GetItemName(type), value);
			break;

		case HDAT_FaBaoSS:
			snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0221, GetItemName(type), value);
			break;

		default:
			if (value > 0)
				snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_2477, GetItemColor(type), GetItemName(type), value);
			else
				snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0181, GetItemColor(type), GetItemName(type), 0 - value);
			break;
		}
		if (isFight)
			SendSysInfoFightEnd(this, buf);
		else
			SendSysInfo(this, buf);
	}
	return true;
}

void CUser::AddMaterial(SAwardData& ad, bool isFight/* = false*/, bool showMsg/* = true*/, uint8 num/* = 1*/)
{
	switch (ad.type)
	{
	case HDAT_FaBao:
	case HDAT_EQUIP:
	case HDAT_PET:
		for (int i = 0; i < ad.num; i++)
			AddMaterial(ad.type, ad.typeId, isFight, showMsg);
		break;

	default:
		AddMaterial(ad.type, ad.num * num, isFight, showMsg);
		break;
	}
}


bool CUser::SubMaterial(uint32 type, uint32 value, bool showMsg/* = true*/)
{
	if (value == 0)
		return true;

	uint32 curValue = 0;
	switch (type)
	{
	case HDAT_MONEY:
		if (m_money < (int)value)
			break;
		AddMoney(-value);
		SendUpdateMoney(type);
		return true;

	case HDAT_BANG_YB:
	case HDAT_YB:
		if (m_tongBao < (int)value)
			break;
		AddTongBao(-value);
		SendUpdateMoney(type);
		return true;

	case HDAT_SHEN_HUN:
		curValue = GetExtData32(ED32_ShenHunMoney);
		if (curValue < value)
			break;
		SetExtData32(ED32_ShenHunMoney, curValue - value);
		SendUpdateMoney(type);
		return true;

	case HDAT_BANG_GONG:
		curValue = GetBangGong();
		if (curValue < value)
			break;
		AddBangGong(-((int)value));
		SendUpdateMoney(type);
		return true;
		
	case HDAT_XingXiuJingHua:
		curValue = GetExtData32(ED32_JingJiZuiGaoMing);
		if (curValue < value)
			break;
		SetExtData32(HDAT_XingXiuJingHua, curValue - value);
		SendUpdateMoney(type);
		return true;

	case HDAT_ArenaCnt:
		curValue = GetExtData16(ED16_69);
		if (curValue < value)
			break;
		SetExtData16(ED16_69, curValue - value);
		SendUpdateMoney(type);
		return true;

	case HDAT_TiLi:
		if (!m_userSpirit.SubSpirit(this, value))
			break;
		return true;

	case HDAT_JJCMoney:
		curValue = GetExtData32(ED32_JJCMoney);
		if (curValue < value)
			break;
		SetExtData32(ED32_JJCMoney, curValue - value);
		SendUpdateMoney(type);
		return true;

	case HDAT_KunLunMoney:
		curValue = GetExtData32(ED32_KLMoney);
		if (curValue < value)
			break;
		SetExtData32(ED32_KLMoney, curValue - value);
		SendUpdateMoney(type);
		return true;

	default:
		if (type < HDAT_MONEY && DelPackageById(type, value))
			return true;
		break;
	}

	if (showMsg)
	{
		char buf[256];
		snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0214, GetItemColor(type), GetItemName(type));
		SendSysInfo(this, buf);
	}
	return false;
}


void CUser::AddMultiAward(MultiAward& award, bool isFight/* = false*/, bool showMsg/* = true*/, int addType/* = 0*/)
{
	for (uint16 i = 0; i < award.size(); ++i)
	{
		AddMaterial(award[i], isFight, showMsg);
		if (award[i].type >= HDAT_MONEY)
		{
			ItemCurrencyLog(GetRoleId(), addType, 1, award[i].type, award[i].num, GetMaterial(award[i].type), addType);
		}
	}
}

bool CUser::AddMutilMaterial(vector<SAwardData> &materials, CNetMessage* msg/* = NULL*/, bool isFight/* = false*/, bool showMsg/* = true*/, int addType/* = 0*/)
{
	if (msg != NULL)
		(*msg) << (uint8)materials.size();
	for (size_t i = 0; i < materials.size(); i++)
	{
		SAwardData& ad = materials[i];
		AddMaterial(ad.type, ad.num, isFight, showMsg);
		if (msg != NULL)
			(*msg) << (uint16)ad.type << ad.num;

		if (addType > 0 && ad.type >= HDAT_MONEY)
		{
			ItemCurrencyLog(GetRoleId(), addType, 1, ad.type, ad.num, GetMaterial(ad.type), addType);
		}
	}
	return true;
}


bool CUser::AddMutilMaterial(uint32 type, int value, int star, int num)
{
	switch (type)
	{
	case HDAT_PET:
	case HDAT_EQUIP:
	case HDAT_PetEquip:
	case HDAT_FaBao:
		for (int i = 0; i < num; i++)
		{
			AddMaterial(type, value, false, false, star);
		}
		break;

	default:
		AddMaterial(type, num, false, false, star);
		break;
	}
	return true;
}


void CUser::AddMultiCost(MultiCost& costs, bool isFight/* = false*/, bool showMsg/* = true*/)
{
	for (size_t i = 0; i < costs.size(); i++)
	{
		AddSingleCost(costs[i]);
	}
}

void CUser::AddSingleCost(SCostData& cost, bool isFight/* = false*/, bool showMsg/* = true*/)
{
	if (cost.costType == HDAT_FaBao || cost.costType == HDAT_EQUIP)
		for (int i = 0; i < cost.costValue; i++)
			AddMaterial(cost.costType, cost.typeId);
	else
		AddMaterial(cost.costType, cost.costValue);
}

int CUser::AddArenaRankAward(uint32 rank)
{
	uint32 last = GetExtData32(ED32_JingJiZuiGaoMing);
	if (last < rank)
		return 0;

	double sum = 0.0;
	for (uint32 i = rank; i < last; ++i)
	{
		sum += 1.0 / i;
	}
	SetExtData32(ED32_JingJiZuiGaoMing, rank);
	if (rank > 5 && rank <= 30)
	{
		char buf[128];
		snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0241, GetName(), rank);
		SysInfoToAllUser(buf);
	}
	UserShopManager* shop = GetShop();
	if (shop != NULL)
		shop->SendShopHotPointStatus(this, 4);
	return ceil(sum * ArenaYuanBaoBase);
}

uint32 CUser::GetMaterial(uint32 type)
{
	switch (type)
	{
	case HDAT_MONEY:
		return GetMoney();

	case HDAT_BANG_YB:
	case HDAT_YB:
		return GetTongBao(0);

	case HDAT_SHEN_HUN:
		return GetShenhun();

	case HDAT_EXP:
		return GetExp();

	case HDAT_QIANNENG:
		return GetQianNeng();

	case HDAT_BANG_GONG:
		 return GetBangGong();

	case HDAT_XingXiuJingHua:
		return GetExtData32(ED32_XZMoney);
	case HDAT_JJCMoney:
		return GetExtData32(ED32_JJCMoney);
	case HDAT_KunLunMoney:
		return GetExtData32(ED32_KLMoney);

	case HDAT_VIP_EXP:
	case HDAT_PET:
	case HDAT_CHENGHAO:
	case HDAT_SHENQI:
	case HDAT_EQUIP:
	case HDAT_WING:
	case HDAT_MOUNT:
	case HDAT_CHRISTMASTREE_GROW_VALUE:
	case HDAT_CHRISTMASTREE_PERSON_VALUE:
	case HDAT_BANGPAI_MONEY:
		return 0;

	default:
		if (type < HDAT_MONEY)
		{
			return NoLockGetItemNum(type);
		}
		break;
	}
	return 0;
}


void CUser::SyncPowerToMatch()
{
	uint32 power = GetZhanDouLi();
	if (power == 0)
	{
		return;
	}
	
	CNetMessage synsMsg;
	synsMsg.SetType(MSG_SERVER_USER_POWER);
	synsMsg << (uint8)1 << GetRoleId() << power;
	SingletonSocket::instance().SendServerMsg(EST_MATCH, synsMsg);
}

void CUser::MatchYingYongRobot(int floor)
{
	if (floor > 15)
	{
		SetExtData32(453, 0);
		return;
	}
	const int minPercent[] = { 30, 30, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 90, 100 };
	const int maxPercent[] = { 40, 40, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 100, 110 };
	if (sizeof(minPercent) / sizeof(int) < (uint32)floor - 1)
	{
		return;
	}
	uint32 robotId = GetExtData32(453);
	if (robotId != 0)
	{
		AddYingYongShiLianNpc();
		return;
	}
	int percent = Random(minPercent[floor - 1], maxPercent[floor - 1]);
	uint32 matchPower = GetExtData32(111) * percent / 100;
	CNetMessage synsMsg;
	synsMsg.SetType(MSG_SERVER_USER_POWER);
	synsMsg << (uint8)3 << GetRoleId() << matchPower;
	SingletonSocket::instance().SendServerMsg(EST_MATCH, synsMsg);
}

void CUser::MatchFight(int startPower, int endPower, uint8 cnt)
{
	CNetMessage synsMsg;
	synsMsg.SetType(MSG_SERVER_USER_POWER);
	synsMsg << (uint8)5 << GetRoleId() << startPower << endPower << (uint8)cnt;
	SingletonSocket::instance().SendServerMsg(EST_MATCH, synsMsg);
}


void CUser::AddYingYongShiLianNpc()
{
	char name[128];
	uint8 floor = GetExtData8(136);
	snprintf(name, sizeof(name), LANGUAGE_TRANSFORM_777, floor + 1);

	if (m_pScene == NULL || m_pScene->GetSrcSceneId() != COPY_ID_SHI_LIAN)
		return;

	uint8 xiang = GetExtData32(454);
	uint16 pic = 70 + xiang;
	uint16 npcId = 180 + xiang;
	if(xiang > 3)
		npcId = 241 + xiang - 4;
	m_pScene->AddNpcWithIndex(npcId, pic, 1009, 499, 2, floor + 1, name);
}

void CUser::SendKuaFuIconState(bool show)
{
	CNetMessage msg;
	msg.SetType(MSG_KUAFU_ICON);
	msg<<(uint8)(show ? 1 : 0);
#ifndef KUA_FU
	msg<<(uint8)1;
#else
	msg<<(uint8)2;
#endif

	CSocketServer &sock = SingletonSocket::instance();
	sock.SendMsg(m_sock,msg);
}

void CUser::GetBangPaiCopyStr(string &val)
{
	CNetMessage msg;
	uint8 num = m_bpCopyAward.size();
	msg<<num;
	for(map<uint32, uint8>::iterator it = m_bpCopyAward.begin(); it != m_bpCopyAward.end(); it++)
	{
		msg<<it->first<<it->second;
	}
	
	msg<<(uint8)m_bpHuoYueAward.size();
	for(map<uint16, uint8>::iterator it = m_bpHuoYueAward.begin(); it != m_bpHuoYueAward.end(); it++)
	{
		msg<<it->first<<it->second;
	}

	if(!Compress((uint8*)(msg.GetMsgData()->c_str() + CNetMessage::GetHeadLen()), msg.GetDataLenExceptHead(), val))
	{
		val.clear();
	}
}

void CUser::SetBangPaiCopy(const char *pStr)
{
	if(pStr == NULL)
		return;

	uint32 len = 2048;
	uint8 *p = new uint8[len];
	memset(p, 0, len);
	boost::scoped_array<uint8> autoDel(p);
	if(!UnCompress(pStr, p, len))
		return;
		
	CNetMessage msg;
	msg.WriteData(p, len);
	
	uint8 num = 0;
	msg>>num;
	for(uint8 i=0; i < num; i++)
	{
		uint32 id = 0;
		uint8 flag = 0;
		msg>>id>>flag;
		m_bpCopyAward.insert(make_pair(id, flag));
	}

	num = 0;
	msg>>num;
	for(uint8 i=0; i < num; i++)
	{
		uint16 id = 0;
		uint8 flag = 0;
		msg>>id>>flag;
		m_bpHuoYueAward.insert(make_pair(id, flag));
	}
}

bool CUser::HaveGetBangPaiCopyAward(int copyId)
{
	if(copyId <= 0)
		return true;
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32, uint8>::iterator it = m_bpCopyAward.find(copyId);
	if(it == m_bpCopyAward.end())
	{
		m_bpCopyAward.insert(make_pair(copyId, 0));
		return false;
	}
	return (it->second > 0);
}

void CUser::SetBangPaiCopyAward(int copyId)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32, uint8>::iterator it = m_bpCopyAward.find(copyId);
	if(it != m_bpCopyAward.end())
	{
		it->second = 1;
	}
}

void CUser::AddHuoYue(int huoyue)
{
	if(huoyue <= 0)
		return;
	uint32 h = GetExtData32(EData32_HuoYueDu_Day) + huoyue;
	SetExtData32(EData32_HuoYueDu_Day, h);
	SetExtData32(EData32_HuoYueDu_Week, GetExtData32(EData32_HuoYueDu_Week) + huoyue);

	if(m_bangpai > 0)
	{
		CBangPai *p = SingletonCBangPaiManager::instance().FindBangPai(m_bangpai);
		if(p != NULL)
			p->UpdateMemberHuoYue(m_roleId, h);
	}
	sCMissionManager.UpdateQuestState(this, EMQCT_39, h);
}

void CUser::AddBangExp(int value)
{
	if (m_bangpai > 0)
	{
		CBangPai *p = SingletonCBangPaiManager::instance().FindBangPai(m_bangpai);
		if (p != NULL)
			p->AddExp(value);
	}
}

bool CUser::HaveGetBangPaiHuoYueAward(int id)
{
	if(id <= 0)
		return true;
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint16, uint8>::iterator it = m_bpHuoYueAward.find(id);
	if(it == m_bpHuoYueAward.end())
	{
		m_bpHuoYueAward.insert(make_pair(id, 0));
		return false;
	}
	return (it->second > 0);
}

void CUser::SetBangPaiHuoYueAward(int id)
{
	map<uint16, uint8>::iterator it = m_bpHuoYueAward.find(id);
	if(it != m_bpHuoYueAward.end())
	{
		it->second = 1;
	}
}


//玩家上线时，修仙历练、通天塔活动排行榜数据更新
void CUser::RoleOnlineUpdateRank()
{
	uint16 data = GetExtData16(52);
	if (data > 1)
	{
//		SingletonCRankMgr::instance().RoleOnLineUpdate(CRankMgr::ERT_LiLianTa,GetRoleId(),GetName(),0,GetVipLevel(),data-1);
	}
	data = GetExtData16(53);
	if (data > 0)
	{
//		SingletonCRankMgr::instance().RoleOnLineUpdate(CRankMgr::ERT_XiuXianLiLian,GetRoleId(),GetName(),0,GetVipLevel(),data);
	}
}

bool CUser::CheckGetFreeSpiritState()
{
	return m_userSpirit.CheckGetFreeSpiritState();
}

CUserGuanQia& CUser::GetGuanQia()
{
	return m_userGuanQia;
}

CUserSpirit& CUser::GetUserSpirit()
{
	return m_userSpirit;
}

UserBook* CUser::GetUserBook()
{
	return m_userBook;
}

CChouKaManager* CUser::GetChouKa()
{
	return m_chouKa;
}

CUserBloodFight* CUser::GetBloodFight()
{
	return m_bloodFight;
}

UserShopManager* CUser::GetShop()
{
	return m_shop;
}

bool CUser::HeroLevelUp(CNetMessage &msg)
{
	uint16 petId;
	uint16 costItemId;
	uint8 costItemNum;
	
	msg >> petId >> costItemId >> costItemNum;
	if(petId == 0 || costItemId == 0 || costItemNum == 0)
		return false;
	msg.ReWrite();
	msg.SetType(PRO_PET);
	msg << (uint8)3;
	if(GetItemNum(costItemId) < (int)costItemNum)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0425,TIPS_FAILURE_COLOR);
		return true;
	}
	
	SItemTemplate *pItem = SingletonItemManager::instance().GetItem(costItemId);
	if(pItem == NULL)
		return false;

	bool isLevelUp = false;
	bool updatePower = false;
	SPet *pPet = NULL;
	CPetCfgManager &petMgr = SingletonCPetCfgMgr::instance();
 	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		pPet = NoLockGetPet(petId).get();
		if(pPet == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0424,TIPS_FAILURE_COLOR);
			return true;
		}
		if(pPet->level >= m_level)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0426,TIPS_FAILURE_COLOR);
			return true;
		}
		NoLockDelPackageById(costItemId,costItemNum);
		
		uint32 addexp = pItem->subValue * costItemNum;
		pPet->exp += addexp;
		//pPet->AddCost(SPet::PCT_Level, HDAT_EXP, addexp);
		uint32 levelUpExp = petMgr.GetLevelUpExp(pPet->level);
		while(pPet->exp >= levelUpExp && levelUpExp > 0)
		{
			pPet->exp -= levelUpExp;
			pPet->level++;
			levelUpExp = petMgr.GetLevelUpExp(pPet->level);
			isLevelUp = true;
		}
		if(isLevelUp)
		{
			pPet->Init(this);
			char buf[256];
			snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0428,PetQualityColor[pPet->quality],pPet->name.c_str(),GGCT_GREEN,pPet->level);
			SendSysInfo(this,buf);

			if (pPet->chuzhanFlag == 1)
			{
				updatePower = true;
			}
		}
 		msg<<PRO_SUCCESS;
	}
	UpdatePet(petId);
	if(updatePower)
	{
		ResetPower();
		SendUpdateInfo(EUUT_TotalZhanDouLi);
		SingletonCRankMgr::instance().UpdateData(CRankMgr::ERT_Pet, m_roleId, pPet->zhanDouli, 0, pPet->id);
	}
	
	if(isLevelUp)
		SingletonCMissionManager::instance().VerifyNewBranchMissionFinish(this, EMISS_DC_21, 1, pPet->level);
	return true;
}

bool CUser::HeroAutoLevelUp(CNetMessage &msg)
{
	uint16 petId;
	uint16 level;
	msg >> petId >> level;
	if (petId == 0 || level == 0 || level > m_level)
		return false;

	CPetCfgManager &petMgr = SingletonCPetCfgMgr::instance();
	static uint16 maxLv = petMgr.GetPetMaxLevel();
	if (level > maxLv)
		return false;
	const uint8 expItemCnt = 4;
	static U16tU32Map itemExp;
	if (itemExp.size() == 0)
	{
		uint16 levelItem[4] = { 834, 835, 836, 837 };
		for (uint8 i = 0; i < expItemCnt; ++i)
		{
			uint16 itemId = levelItem[i];
			SItemTemplate *pItem = SingletonItemManager::instance().GetItem(itemId);
			if(pItem == NULL)
				return false;
			itemExp[itemId] = pItem->subValue;
		}
	}
	
	U16tU32Map userCost;
	msg.ReWrite();
	msg.SetType(PRO_PET);
	msg << (uint8)4;
	bool updatePower = false;
	SPet *pPet = NULL;
 	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		pPet = NoLockGetPet(petId).get();
		if(pPet == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0424,TIPS_FAILURE_COLOR);
			return true;
		}
		if(pPet->level >= m_level)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0426,TIPS_FAILURE_COLOR);
			return true;
		}
		if (level == pPet->level) return true;
		double needExp = 0.0;
		for (size_t i = pPet->level; i < level; i++)
		{
			needExp += petMgr.GetLevelUpExp(i);
		}
		needExp -= pPet->exp;
		for (U16tU32MapIt it = itemExp.begin(); it != itemExp.end(); ++it)
		{
			uint16 cid = it->first;
			uint32 addExp = it->second;
			int hasNum = NoLockGetItemNum(cid);
			if (hasNum == 0) continue;
			uint16 needNum = ceil(needExp / addExp);
			if (needNum <= hasNum)
			{
				userCost[cid] = needNum;
				needExp -= needNum * addExp;
				break;
			}
			else
			{
				userCost[cid] = hasNum;
				needExp -= hasNum * addExp;
			}
		}
		if (needExp > 0)
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0179, TIPS_FAILURE_COLOR);
			return true;
		}
		pPet->level = level;
		pPet->exp = 0 - needExp;
		for (U16tU32MapIt uit = userCost.begin(); uit !=  userCost.end(); ++uit)
		{
			NoLockDelPackageById(uit->first,uit->second);
		}
		
		pPet->Init(this);
		if (pPet->chuzhanFlag == 1)
		{
			updatePower = true;
		}
 		msg << PRO_SUCCESS << petId;
	}
	UpdatePet(petId);
	if(updatePower)
	{
		ResetPower();
		SendUpdateInfo(EUUT_TotalZhanDouLi);
		SingletonCRankMgr::instance().UpdateData(CRankMgr::ERT_Pet, m_roleId, pPet->zhanDouli, 0, pPet->id);
	}
	
	SingletonCMissionManager::instance().VerifyNewBranchMissionFinish(this, EMISS_DC_21, 1, pPet->level);
	return true;
}

bool CUser::HeroBreak(CNetMessage &msg)
{
	uint16 petId;
	msg >> petId;
	SPetBasicData* pData = SingletonCPetCfgMgr::instance().GetPetCfg(petId);
	if(pData == NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0424,TIPS_FAILURE_COLOR);
		return true;
	}
	CHeroCfgManager& mgr = sCHeroCfgManager;
	bool updatePower = false;
	SPet* pPet = NULL;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		pPet = NoLockGetPet(petId).get();
		if(pPet == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0424,TIPS_FAILURE_COLOR);
			return true;
		}
		uint8 lvCond = mgr.GetBreakLvCond(pPet->breakLevel + 1);
		if (lvCond > pPet->level)
			return true;
		MultiCost* costs = mgr.GetBreakCost(pData->quality, pPet->breakLevel + 1);
		if(costs == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_ZQX_0166,TIPS_FAILURE_COLOR);
			return true;
		}
		for (uint8 ci = 0; ci < costs->size(); ++ci)
		{
			SCostData& cost = (*costs)[ci];
			if (GetMaterial(cost.costType) < (uint32)cost.costValue)
			{
				char buf[128];
				snprintf(buf,sizeof(buf),LANGUAGE_ZQX_0167, GetItemName(cost.costType));
				msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
				return true;
			}
		}
		for (uint8 ci = 0; ci < costs->size(); ++ci)
		{
			SCostData& cost = (*costs)[ci];
			AddMaterial(cost.costType, 0 - cost.costValue);
		}
		pPet->breakLevel++;
		pPet->Init(this, true);
		NoLockUpdatePet(petId);
 		msg<<PRO_SUCCESS;

		if (pPet->breakLevel >= 5)
		{
			char buf[128];
			snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0231, GetName(), MakePetColorStr(petId).c_str(), pPet->breakLevel);
			SysInfoToAllUser(buf);
		}
	}
	InitChuZhanPet();
	if(updatePower)
	{
		ResetPower();
		SendUpdateInfo(EUUT_TotalZhanDouLi);
		SingletonCRankMgr::instance().UpdateData(CRankMgr::ERT_Pet, m_roleId, pPet->zhanDouli, 0, pPet->id);
	}
	sCMissionManager.UpdateQuestState(this, EMQCT_20);
	return true;
}

bool CUser::HeroXiuLian(CNetMessage &msg)
{
	uint16 petId;
	uint16 cnt;
	msg >> petId >> cnt;
	CHeroCfgManager& hmgr = sCHeroCfgManager;
	
	SPet* pPet = NULL;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		pPet = NoLockGetPet(petId).get();
		if(pPet == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0424,TIPS_FAILURE_COLOR);
			return true;
		}
		
		XiuLianCfg* xcfg = hmgr.GetXiuLianCfg(pPet->xiuLianLevel + 1);
		if(xcfg == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_ZQX_0168,TIPS_FAILURE_COLOR);
			return true;
		}

		if (xcfg->condLv > pPet->level)
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_64, TIPS_FAILURE_COLOR);
			return true;
		}
		uint32 hasCnt = GetMaterial(CHeroCfgManager::g_xlItemId);
		if (hasCnt < cnt)
			cnt = hasCnt;
		uint16 lessCnt = 0;
		vector<uint16> fullCnts;
		U8tU16Map& xlCnts = pPet->curXiuLianCnts;
		for (U8tU16MapIt uit = CHeroCfgManager::g_xiuLianAttrAdd.begin(); uit != CHeroCfgManager::g_xiuLianAttrAdd.end(); ++uit)
		{
			uint16 fullCnt = xcfg->xiuLianCnt;
			U8tU16MapIt cit = xlCnts.find(uit->first);
			if (cit != xlCnts.end())
			{
				fullCnt -= cit->second;
			}
			fullCnts.push_back(fullCnt);
			lessCnt += fullCnt;
		}
		NoLockDelPackageById(CHeroCfgManager::g_xlItemId, cnt);
		if (lessCnt <= cnt)
		{
			// 可以直接升满　不随机了
			cnt = lessCnt;
			pPet->curXiuLianCnts.clear();
			msg << PRO_SUCCESS << (uint8)CHeroCfgManager::g_xiuLianAttrAdd.size();
			for (U8tU16MapIt uit = CHeroCfgManager::g_xiuLianAttrAdd.begin(); uit != CHeroCfgManager::g_xiuLianAttrAdd.end(); ++uit)
			{
				pPet->curXiuLianCnts[uit->first] = xcfg->xiuLianCnt;
				msg << uit->first << xcfg->xiuLianCnt;
			}
		}
		else
		{
			uint16 useCnt = ceil(cnt / 100.0);
			while (cnt > 0)
			{
				vector<uint8> idxs;
				for (size_t i = 0; i < fullCnts.size(); i++)
				{
					if (fullCnts[i] > 0)
					{
						idxs.push_back(i);
					}
				}
				if (idxs.size() == 1)
				{
					fullCnts[idxs[0]] -= cnt;
					cnt = 0;
					break;
				}
				while (cnt > 0)
				{
					uint8 iSize = idxs.size();
					uint8 rd = Random(0, iSize - 1);
					uint8 rIdx = idxs[rd];
					uint16 curLess = fullCnts[rIdx];

					if (useCnt > cnt)
						useCnt = cnt;
					uint16 curUse = useCnt;
					if (curUse > curLess)
						curUse = curLess;
					fullCnts[rIdx] -= curUse;
					cnt -= curUse;
					if (fullCnts[rIdx] == 0)
						break;
				}
			}

			uint8 idx = 0;
			msg << PRO_SUCCESS << (uint8)CHeroCfgManager::g_xiuLianAttrAdd.size();
			for (U8tU16MapIt uit = CHeroCfgManager::g_xiuLianAttrAdd.begin(); uit != CHeroCfgManager::g_xiuLianAttrAdd.end(); ++uit)
			{
				uint16 fullCnt = xcfg->xiuLianCnt;
				uint16 curCnt = fullCnt - fullCnts[idx];
				xlCnts[uit->first] = curCnt;
				idx++;
				msg << uit->first << curCnt;
			}
		}
		pPet->Init(this);
		UpdatePet(petId);
	}
	ResetPower();
	SendUpdateInfo(EUUT_TotalZhanDouLi);
	SingletonCRankMgr::instance().UpdateData(CRankMgr::ERT_Pet, m_roleId, pPet->zhanDouli, 0, pPet->id);
	return true;
}

bool CUser::HeroXiuLianJiHuo(CNetMessage &msg)
{
	uint16 petId;
	msg >> petId;
	CHeroCfgManager& hmgr = sCHeroCfgManager;

	SPet* pPet = NULL;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		pPet = NoLockGetPet(petId).get();
		if (pPet == NULL)
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_SSJ_0424, TIPS_FAILURE_COLOR);
			return true;
		}

		XiuLianCfg* xcfg = hmgr.GetXiuLianCfg(pPet->xiuLianLevel + 1);
		if (xcfg == NULL)
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0168, TIPS_FAILURE_COLOR);
			return true;
		}

		if (xcfg->condLv > pPet->level)
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_64, TIPS_FAILURE_COLOR);
			return true;
		}

		if (!UseMultiCost(xcfg->costs))
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_SSJ_1008, TIPS_FAILURE_COLOR);
			return true;
		}
		U8tU16Map& xlCnts = pPet->curXiuLianCnts;
		for (U8tU16MapIt uit = CHeroCfgManager::g_xiuLianAttrAdd.begin(); uit != CHeroCfgManager::g_xiuLianAttrAdd.end(); ++uit)
		{
			uint16 fullCnt = xcfg->xiuLianCnt;
			U8tU16MapIt cit = xlCnts.find(uit->first);
			if (cit == xlCnts.end() || cit->second < fullCnt)
			{
				msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0245, TIPS_FAILURE_COLOR);
				return true;
			}
		}
		pPet->curXiuLianCnts.clear();
		pPet->xiuLianLevel++;

		msg << PRO_SUCCESS << pPet->xiuLianLevel;
		msg << CHeroCfgManager::g_xiuLianAttrAdd.size();
		for (U8tU16MapIt uit = CHeroCfgManager::g_xiuLianAttrAdd.begin(); uit != CHeroCfgManager::g_xiuLianAttrAdd.end(); ++uit)
		{
			msg << uit->first << (uint16)0;
		}
		pPet->Init(this);
		UpdatePet(petId);

		if (pPet->xiuLianLevel % 5 == 0)
		{
			char buf[128];
			snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0247, GetName(), pPet->xiuLianLevel);
			SysInfoToAllUser(buf);
		}
	}
	ResetPower();
	SendUpdateInfo(EUUT_TotalZhanDouLi);
	SingletonCRankMgr::instance().UpdateData(CRankMgr::ERT_Pet, m_roleId, pPet->zhanDouli, 0, pPet->id);
	return true;
}

bool CUser::HeroStarUp(CNetMessage &msg)
{
	uint16 petId;
	msg >> petId;
	SPet *pPet = NULL;
	bool updatePower = false;
	SPetBasicData* pData = SingletonCPetCfgMgr::instance().GetPetCfg(petId);
	if (pData == NULL)
	{
		return false;
	}
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		pPet = NoLockGetPet(petId).get();
		HeroStarCfg* cfg = sCHeroCfgManager.GetHeroStarCfg(pPet->star + 1);
		if (cfg == NULL)
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0164, TIPS_FAILURE_COLOR);
			return true;
		}
		U8tU16MapIt nit = cfg->starUpCost.find(pData->quality);
		if (nit == cfg->starUpCost.end())
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_80, TIPS_FAILURE_COLOR);
			return true;
		}
		uint32 num = NoLockGetItemNum(pData->shengxingItemId);
		if (num < nit->second)
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0165, TIPS_FAILURE_COLOR);
			return true;
		}
		if (!NoLockDelPackageById(pData->shengxingItemId, nit->second))
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0165, TIPS_FAILURE_COLOR);
			return true;
		}
		pPet->star++;
		for (int i = 0; i < PET_MAX_SKILL_NUM; i++)
			pPet->skillLevel[i] = cfg->skillLevel;
		pPet->Init(this);
		if (pPet->chuzhanFlag == 1)
		{
			updatePower = true;
		}
		else
			NoLockUpdatePet(petId);
		UpdatePet(petId);
		msg << PRO_SUCCESS;

		if (pPet->star >= 4)
		{
			char buf[128];
			snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0230, GetName(), MakePetColorStr(petId).c_str(), pPet->star);
			SysInfoToAllUser(buf);
		}
	}
	ResetPower();
	SendUpdateInfo(EUUT_TotalZhanDouLi);
	SingletonCRankMgr::instance().UpdateData(CRankMgr::ERT_Pet, m_roleId, pPet->zhanDouli, 0, pPet->id);
	sCMissionManager.UpdateQuestState(this, EMQCT_21);
	return true;
}

bool CUser::HeroCChongSheng(CNetMessage &msg)
{
	uint16 petId;
	msg >> petId;
	SPet* pPet = NULL;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	pPet = NoLockGetPet(petId).get();
	if (pPet == NULL || GetChuZhanIdx(petId) > 0)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_SSJ_0424, TIPS_FAILURE_COLOR);
		return true;
	}
	MultiCost allCost;
	pPet->GetChongShengCost(allCost);
	msg << PRO_SUCCESS;
	MakeMultiCostMsg(allCost, msg);
	return true;
}

bool CUser::HeroChongSheng(CNetMessage &msg)
{
	uint16 petId;
	msg >> petId;
	if (GetTongBao() < 50)
		return true;
	SPet* pPet = NULL;
	MultiCost allCost;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		pPet = NoLockGetPet(petId).get();
		if (pPet == NULL || GetChuZhanIdx(petId) > 0)
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_SSJ_0424, TIPS_FAILURE_COLOR);
			return true;
		}
		MultiCost allCost;
		pPet->GetChongShengCost(allCost);
		pPet->level = 1;
		pPet->breakLevel = 0;
		pPet->xiuLianLevel = 0;
		pPet->curXiuLianCnts.clear();
		pPet->exp = 0;
	}
	AddMaterial(HDAT_BANG_YB, -50);
	ItemCurrencyLog(GetRoleId(), MUT_HChongSheng, 1, HDAT_YB, 50, GetMaterial(HDAT_YB), MUT_HChongSheng);
	AddMultiCost(allCost);
	msg << PRO_SUCCESS;
	MakeMultiCostMsg(allCost, msg);
	UpdatePet(petId);
	return true;
}

bool CUser::HeroHeCheng(CNetMessage &msg)
{
	 uint16 itemId = 0;
	 msg >> itemId;
	 ComposeCfg* pData = sCItemCfgManager.GetComposeCfg(CPT_HERO_HC, itemId);
	 do
	 {
		 if (pData == NULL)
		 {
			 msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0001, TIPS_FAILURE_COLOR);
			 break;
		 }
		 // 神将重复检测
		 if (HavePet(pData->tar.typeId))
		 {
			 msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0003, TIPS_FAILURE_COLOR);
			 break;
		 }
		 if (!UseMultiCost(pData->costs))
		 {
			 msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0174, TIPS_FAILURE_COLOR);
			 break;
		 }
		 // 添加神将
		 if (!::AddPet(this, pData->tar.typeId, 1))
		 {
			 msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0005, TIPS_FAILURE_COLOR);
			 break;
		 }

		 char buf[128];
		 snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0229, GetName(), MakePetColorStr(pData->tar.typeId).c_str());
		 SysInfoToAllUser(buf);
		 msg << PRO_SUCCESS;
	 } while (false);
	 return true;
}

uint8 CUser::GetHeroBreakNum(uint8 level)
{
	uint8 cnt = 0;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for (size_t i = 0; i < m_zhenfaMember.size(); i++)
	{
		uint16 prePetId = m_zhenfaMember[i].mem_id;
		SharePetPtr prePet = NoLockGetPet(prePetId);
		SPet* pet = prePet.get();
		if (pet != NULL && pet->breakLevel >= level)
			cnt++;
	}
	return cnt;
}

uint8 CUser::GetQualityPetCnt(uint8 quality)
{
	uint8 cnt = 0;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for (size_t i = 0; i < m_zhenfaMember.size(); i++)
	{
		uint16 prePetId = m_zhenfaMember[i].mem_id;
		SharePetPtr prePet = NoLockGetPet(prePetId);
		SPet* pet = prePet.get();
		if (pet != NULL && pet->quality >= quality)
			cnt++;
	}
	return cnt;
}

uint8 CUser::GetHeroStarNum(uint8 star)
{
	uint8 cnt = 0;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for (size_t i = 0; i < m_zhenfaMember.size(); i++)
	{
		uint16 prePetId = m_zhenfaMember[i].mem_id;
		SharePetPtr prePet = NoLockGetPet(prePetId);
		SPet* pet = prePet.get();
		if (pet != NULL && pet->star >= star)
			cnt++;
	}
	return cnt;
}

uint8 CUser::GetPowerPetCnt(uint32 power)
{
	uint8 cnt = 0;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for (CPetMapIt it = m_pet.begin(); it != m_pet.end(); it++)
	{
		SharePetPtr prePet = it->second;
		SPet* pet = prePet.get();
		if (pet != NULL && pet->zhanDouli >= power)
			cnt++;
	}
	return cnt;
}
