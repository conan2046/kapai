#ifndef _SCENE_MANAGER_H_
#define _SCENE_MANAGER_H_

#include "self_typedef.h"
#include <string>
#include <list>
#include <vector>
#include <boost/thread.hpp>
#include "script_call.h"
#include "user.h"
#include "fight.h"
#include "utility.h"
using namespace std;

class CNpcManager;
class CUser;
class CUserTeam;
class COnlineUser;
class COnlineUser;
class CFightManager;
class CCallScript;
struct BloodFight;

struct STeamFaBuData;

struct SPoint_int
{
	int x;
	int y;
};

struct SPoint
{
	uint16 x;
	uint16 y;
};

struct SPointFace
{
	uint16 x;
	uint16 y;
	uint8 face;
};

const int MAX_TEAM_MEMBER = 5;
const int MAX_ZHUAIGUI_LIMIT = 90;

class CUserTeam
{
public:
	enum LeaveTeamState
	{
		LTS_LeaveTeam = 0,
		LTS_InTeam = 1,
	};
	
	CUserTeam();
	uint8 GetMemberNum();
	uint8 GetLeaveNum();
	void UpdateTeamData();
	void UpdateMemberLevel(uint32 roleId,uint16 level);
	void SendTeamFaBuData(uint32 memberId=0);
	void SendJoinTeamMemberData(uint32 joinId,uint32 recvId);

	void ReSetTeamZhenRong();
	void AddMemberToZhenRong(uint32 userId,uint8 inTeam=LTS_InTeam);
	bool Join(uint32 userId);
	void Exit(uint32 userId);
	void MakeAllMemberInfo(CNetMessage &msg);
	void AskForJoinTeam(uint32 userId){m_askForJoin.push_back(userId);}
	bool IsAskedForJoin(uint32 userId);
	void DelAskForJoinTeam(uint32 userId){m_askForJoin.remove(userId);}
	void ClearAskForJoinTeamList(){m_askForJoin.clear();}
	
	const char *GetHeadName()
	{
		return m_headName.c_str();
	}
	uint32 GetHeadId()   //队伍id即队长id
	{
		return m_members[0];//队长即队伍里面的第一个
	}
	bool SetNewHead(CUser *pUser);	// 设置新队长，队员都设置成暂离状态
	void GetMember(uint32 *members, uint8 &num);
	void GetMemberByOrder(uint32 *members);
	void GetAllMember(uint32 *members, uint8 &num);
	void GetAllMemberByOrder(uint32 *members);
	void SwapMember();
	void GetLeaveMem(uint32 *members, uint8 &num);
	list<uint32> *GetAskForJoin(){return &m_askForJoin;}
	void AddRequestList(uint32 id){m_requestList.push_back(id);}
	bool InRequest(uint32 id);
	void DelRequest(uint32 id){	m_requestList.remove(id);}
	void ClearRequestList(){m_requestList.clear();}
	uint8 GetHeadXiang(){return m_headXiang;}
	uint8 GetHeadLevel(){return m_headLevel;}
	void ReturnTeam(uint32 roleId);
	void TempLeaveTeam(uint32 roleId);	//暂离队伍
	void SetType(uint8 type,uint16 minLv,uint16 maxLv){m_type = type; m_minLv = minLv; m_maxLv = maxLv;}
	void SetFabuState(bool status) {m_faBu = status;}
	uint8 GetType(){return m_type;}
	void GetLevelInfo(uint16 &minLv,uint16 &maxLv){minLv = m_minLv; maxLv = m_maxLv;}
	bool GetFaBuState(){return m_faBu;}

	void MakeTeamFaBuInfo(CNetMessage &msg);
	bool SwitchZhenFa(uint16 zhenfaId,CNetMessage &msg);
	bool ZhenFa_SetPetState(uint16 petId,uint8 pos,uint16 leaderLevel,CNetMessage &msg);
	bool ZhenFa_ChangeUnitPos(uint8 srcPos, uint8 tarPos, uint16 leaderLevel, CNetMessage &msg);
	
	void GetZhenFaMember(vector<SZhenFaMemData> &zhenfaMember);
	uint16 GetUseZhenFaId();

	uint32 m_lastWorldChatTime;
	// 根据队伍更新任务
	void UpdateMission(CScene *pScene, int type, const char *pInts, const char *pStrs);
private:
	uint8 MakeUserInfo(CNetMessage &msg,uint8 zhenrongIdx,uint8 memberIdx=0xff);
	uint8 MakePetInfo(CNetMessage &msg,uint8 zhenrongIdx);

	uint8 m_leaveFlag[MAX_TEAM_MEMBER];		// 0暂离1跟随
	uint32 m_members[MAX_TEAM_MEMBER];		// 队伍成员id
	vector<SZhenFaMemData> m_tzhenrong;	// 组队阵容
	uint16 m_useZhenFaId;

	string m_headName;
	uint8 m_headXiang;
	uint8 m_headLevel;
	uint8 m_type;		// 发布队伍类型
	uint16 m_minLv;	// 便捷组队入队最小等级
	uint16 m_maxLv;	// 便捷组队入队最大等级
	bool m_faBu;	// true 发布 false 未发布

	list<uint32> m_askForJoin;	//申请列表
	list<uint32> m_requestList;	//邀请列表
};


struct SVisibleMonster
{
	SVisibleMonster()
	{
		id = 0;
		x = 0;
		y = 0;
		face = 0;
		pic = 0;
		type = 0;
		flag = 0;
		pathIndex = 0;
		restTime = 0;
		center_x = 0;
		center_y = 0;
		radius = 0;
		monster_id = 0;
		meetDistance = 50;
		sceneId = 0;
		singleVisiable = 0;
		min_fightId = 0;
		max_fightId = 0;
	}
	uint8 singleVisiable;	// 0所有人可见1仅自己可见
	uint32 id;
	uint16 sceneId;
	uint16 x;
	uint16 y;
	uint8 face;
	uint16 pic;
	uint8 type;
	uint8 flag;		//0正常，1战斗中
	vector<uint8> path;
	uint8 pathIndex;
	time_t restTime;
	string name;
	uint16 center_x;
	uint16 center_y;
	uint16 radius;
	uint16 meetDistance;
	uint16 monster_id;
	int min_fightId;
	int max_fightId;
};

// 每个掉落物品
struct SVisibleMonsterBossDropItem
{
	SVisibleMonsterBossDropItem()
	{
		rate = 0;
		plusRate = 0;
		itemId = 0;
		itemLv = 0;
		itemNum = 0;
	}
	uint8 rate; // 获取几率
	uint8 plusRate; // 每人增长几率
	uint16 itemId;
	uint8 itemLv;
	uint8 itemNum;
};

// 每个怪的掉落完整记录
struct SVisibleMonsterBossDrop
{
	const static int MAX_ITEM_NUM = 3;

	SVisibleMonsterBossDrop()
	{
		money1 = 0;
		money2 = 0;
		exp1 = 0;
		exp2 = 0;
		qianneng1 = 0;
		qianneng2 = 0;
	}
	int money1;
	int money2;
	int exp1;
	int exp2;
	int qianneng1;
	int qianneng2;
	SVisibleMonsterBossDropItem items[MAX_ITEM_NUM];

	void SetDrop(char* drop); // 设置掉落
};

// BOSS怪战斗类型
enum SVisibleMonsterBossType
{
	MB_NONE = 0, // 默认
	MB_TWICE_TEAM_NUM = 1, // 两倍的队伍数量
	MB_BOSS = 2, // boss
	MB_HEADER = 3, // 小头目
	MB_HEADER1 = 4, // 小头目
};

struct SVisibleMonsterBoss
{
	SVisibleMonsterBoss()
	{
		id = 0;
		x = 0;
		y = 0;
		face = 0;
		pic = 0;
		type = 0;
		step = 0;
		flag = 0;
		pathIndex = 0;
		restTime = 0;
		center_x = 0;
		center_y = 0;
		radius = 0;
		meetDistance = 50;
		isVisible = false;
		create_time = 0;
		fightId = 0;
		monsterId = 0;
		memset(bossId,0,sizeof(bossId));
		memset(scale,0,sizeof(scale));
	}
	uint32 id;
	uint16 x;
	uint16 y;
	uint8 face;
	uint16 pic;
	uint8 type;
	uint8 step; // 副本刷怪步骤
	uint8 flag;		//0正常，1战斗中
	vector<uint8> path;
	uint8 pathIndex;
	time_t restTime;
	uint16 center_x;
	uint16 center_y;
	uint16 radius;
	uint16 meetDistance;
	int monsterId;	// 客户端寻路id
	int fightId;
	string name;
	bool isVisible;
	uint16 bossId[CFight::GROUP2_BEGIN];
	float scale[CFight::GROUP2_BEGIN];
	SVisibleMonsterBossDrop dropItems;
	time_t create_time;
};

struct SMonsterListInfo
{
	SMonsterListInfo()
	{
		index = 0;
	}
	~SMonsterListInfo()
	{
	}
	void removeMonsterById(uint32 id)
	{
		for(list<SVisibleMonster>::iterator i = monsterList.begin();i != monsterList.end();i++)
		{
			if(i->id == id)
			{
				monsterList.erase(i);
				return;
			}
		}
	}
	void AddMonster(SVisibleMonster &monster)
	{
		monsterList.push_back(monster);
	}
	uint16 index;
	list<SVisibleMonster> monsterList;
};

struct SJiFenUser
{
	uint32 roleId;
	string name;
	short jifen;
};

// 副本战斗场次
enum FU_BEN_TOTAL_FIGHT_COUNT
{
	FB_FIGHT_COUNT_HUAN_MIE_QIAN_SHAO = 3,
	FB_FIGHT_COUNT_LAN_RUO_SI = 14,
	FB_FIGHT_COUNT_E_LONG_TAN = 8,
	FB_FIGHT_COUNT_HUAN_MIE_ZHI_CHENG = 12,

	FB_FIGHT_COUNT_RI_CHANG_CHONG_WU = 2,
	FB_FIGHT_COUNT_RI_CHANG_QIANG_HUA = 2,
	FB_FIGHT_COUNT_RI_CHANG_JIN_QIAN = 2,
	FB_FIGHT_COUNT_RI_CHANG_DAO_JU = 2,
	FB_FIGHT_COUNT_RI_CHANG_QIAN_NENG = 2,
	FB_FIGHT_COUNT_RI_CHANG_XIANG_QIAN = 2,
	FB_FIGHT_COUNT_RI_CHANG_XI_LIAN = 2,
	FB_FIGHT_COUNT_RI_CHANG_CHONG_KAI = 2,
};

const uint16 MIN_FU_BEN_ID = 9999; // 副本最小地图 判断合法地图 

//#ifdef KUA_FU
//const uint16 EXIT_FB_SCENE_ID = 70;
//const uint16 EXIT_FB_SCENE_X = 327;
//const uint16 EXIT_FB_SCENE_Y = 1075;
//#else
const uint16 EXIT_FB_SCENE_ID = 1;
const uint16 EXIT_FB_SCENE_X = 345;
const uint16 EXIT_FB_SCENE_Y = 269;
//#endif

const uint16 ENTER_FU_BEN_DEFAULT_MAP_FACE = 1;
const uint16 MODAO2_FUBEN_NUM = 5;		// 魔道2 副本数量
const uint16 FISH_ID2 = 54;				// 钓鱼场景

const uint16 COPY_ID_QIANG_HUA = 161;	// 强化副本
const uint16 COPY_ID_CHONG_WU_1 = 162;	// 神将副本初级
const uint16 COPY_ID_CHONG_WU_2 = 163;	// 神将副本中级
const uint16 COPY_ID_CHONG_WU_3 = 164;	// 神将副本高级

const uint32 COPY_ID_QIANG_HUA_DROP = 40000;	// 神将副本初级
const uint32 COPY_ID_CHONG_WU_1_DROP = 40001;	// 神将副本初级
const uint32 COPY_ID_CHONG_WU_2_DROP = 40002;	// 神将副本中级
const uint32 COPY_ID_CHONG_WU_3_DROP = 40003;	// 神将副本高级

const uint16 COPY_ID_CHONG_WU_4 = 165;	// 神将副本天书
const uint16 COPY_ID_MONEY = 166; 		// 金币副本
const uint16 COPY_ID_SHENG_JIE = 167;	// 升阶副本
const uint16 COPY_ID_QIAN_NENG = 168;	// 潜能副本
const uint16 COPY_ID_XIANG_QIAN = 171;	// 镶嵌副本
const uint16 COPY_ID_CUI_LIAN = 172;	// 淬炼副本
const uint16 COPY_ID_CHONG_KAI = 173;	// 神将铠副本
const uint16 COPY_ID_SHI_LIAN = 174;	// 英勇试炼副本

const uint16 FEI_XIAN_SID1 = 175;	// 飞仙场景1层
const uint16 FEI_XIAN_SID2 = 176;	// 飞仙场景2层
const uint16 FEI_XIAN_SID3 = 177;	// 飞仙场景3层
const uint16 FEI_XIAN_SID4 = 178;	// 飞仙场景4层
const uint16 FEI_XIAN_SID5 = 179;	// 飞仙场景5层

const uint16 LEI_TAI_ID2 = 51;		// 擂台赛
const uint16 EXIT_LEI_TAI_MAP_ID = 11; // 擂台赛 退出地图id
const uint16 EXIT_LEI_TAI_MAP_X = 1264; // 擂台赛 退出地图坐标x
const uint16 EXIT_LEI_TAI_MAP_Y = 432; // 擂台赛 退出地图坐标y

const uint16 BP_FIGHT_READY_SID = 45;
const uint16 BP_FIGHT_SID = 56;
const uint16 BANG_PAI_SCENE_ID = 47;

const uint16 KUA_FU_SCENE_ID = 70;	// 跨服场景
const uint16 KUAFU_BZ_READY_SID = 76;	// 跨服帮战准备场景
const uint16 KUAFU_BZ_SID = 77;			// 跨服帮战场景
const int KUAFU_BZ_SCENE_ID_BEGIN = 5401;	// 跨服帮战第一个房间ID

const uint16 KUN_LUN_SHAN_SCENE_ID = 121;	// 昆仑山
const int KUN_LUN_SHAN_SCENE_ID_BEGIN = 5001;	// 昆仑山第一个房间ID
const int KUN_LUN_SHAN_ROOM_LIMIT = 25;		// 昆仑山每个房间人数上限

const uint16 KUN_LUN_SHAN_TEAM_SCENE_ID = 71;	// 组队昆仑山
const int KUN_LUN_SHAN_TEAM_SCENE_ID_BEGIN = 5501;	// 组队昆仑山第一个房间ID
const int KUN_LUN_SHAN_TEAM_ROOM_LIMIT = 50;	// 组队昆仑山每个房间人数上限

const uint16 SHENJIEMIJING_SCENE_ID = 74;	// 神界秘境
const int SHENJIEMIJING_SCENE_ID_BEGIN = 7001;	// 神界秘境第一个房间ID
const int SHENJIEMIJING_ROOM_LIMIT = 50;	// 神界秘境每个房间人数上限

const int KUA_FU_1V1_SCENE_ID = 73;		// 跨服1V1
const int KUA_FU_1V1_SCENE_FB_BEGIN = 5601;	// 跨服1V1第一个房间ID
const int KUA_FU_1V1_SCENE_NUM = 16;

const int MAX_GUI_YU_NUM    = 80;
const uint16 FUBEN_ID_BEGIN = 1000;		//副本id从1000起始
const int GUI_YU_MAX_MONSTER_NUM = 10;
const int LANRUO_MONSTER_NUM = 5;

const uint16 MATCH_SCENE_ID = 320;

const int MATCH_SCENE_NUM   = 4;

const int MATCH_TIME = 3300;

const int BANG_PAI_TIAO_ZHAN_SPACE = 300; // 补偿时间

struct SMonsterDistribution
{
	SMonsterDistribution()
	{
		scene_id = 0;
		monster_id = 0;
		radius = 0;
		findPath_x = 0;
		findPath_y = 0;
	}	
	uint16 scene_id;
	uint16 monster_id;
	uint16 radius;
	uint16 findPath_x;
	uint16 findPath_y;
};

inline bool IsFuBen(int sceneId)
{
	int scene_Id[] = {
		FISH_ID2,FISH_ID2+1,
		COPY_ID_QIANG_HUA,
		COPY_ID_CHONG_WU_1,COPY_ID_CHONG_WU_2,COPY_ID_CHONG_WU_3,COPY_ID_CHONG_WU_4,
		COPY_ID_MONEY,
		COPY_ID_SHENG_JIE,
		COPY_ID_QIAN_NENG,
		COPY_ID_XIANG_QIAN,
		COPY_ID_CUI_LIAN,
		COPY_ID_CHONG_KAI,
		COPY_ID_SHI_LIAN,
		SHENJIEMIJING_SCENE_ID,
	};
	for(uint8 i = 0; i < sizeof(scene_Id)/sizeof(int); i++)
	{
		if(sceneId == scene_Id[i])
			return true;
	}
	if(sceneId >= KUN_LUN_SHAN_SCENE_ID && sceneId < KUN_LUN_SHAN_SCENE_ID+30)	// 昆仑山
		return true;
	if(sceneId == KUN_LUN_SHAN_TEAM_SCENE_ID)
		return true;
	return false;
}

struct TowerInfo
{
	TowerInfo() : curHp(0)
		, maxHp(0)
		, ownerId(0)
		, maxhurt(0)
		, cdTime(0)
	{
		hpGuilds.clear();
		ownerName = "";
	}
	int curHp;	 	// 当前血量
	int maxHp;	 	// 最大血量
	uint32 ownerId;	// 当前占领者
	int maxhurt;	// 最大伤害
	int maxId;		// 最大伤害帮派
	string ownerName;	// 拥有者名字
	uint32 cdTime;
	map<int, int> hpGuilds;
};

class CScene
{
public:
	static const uint32 NormalMonsterIdPos = 0xffff;
	CScene(uint16 id,uint16 mapId,const char *name,char *monsters,int mapFile);
	CScene(CScene&);

	~CScene();
	bool GetJumpPoint(uint16 x,uint16 y,SJumpTo*&);
	bool HaveNpc(uint16 x,uint16 y);
	bool HaveNpc(uint16 id);

	void Exit(CUser*);
	list<uint16> *GetNpcList()
	{
		return &m_npcList;
	}
	void SetFightType(uint8 type)
	{
		m_fightType = type;
	}
	void SetWidth(uint16 w)
	{
		m_width = w;
	}
	void SetHeight(uint16 h)
	{
		m_height = h;
	}
	void SetWorldTransType(uint8 val)
	{
		m_world_trans_type = val;
	}
	uint8 GetWorldTransType()
	{
		return m_world_trans_type;
	}
	uint8 GetFightType()
	{
		return m_fightType;
	}
	void SetId(int id)
	{
		m_id = id;
	}
	int GetId()
	{
		return m_id;
	}
	uint16 GetMapId()
	{
		return m_mapId;
	}
	void SetMapId(int mapId)
	{
		m_mapId = mapId;
	}
	const char *GetName()
	{
		return m_name.c_str();
	}
	uint16 *GetMonsters()
	{
		return m_monsters;
	}
	uint8 GetMonsterNum()
	{
		return m_monsterNum;
	}
	bool CreateTeam(CUser*,uint32 request = 0);
	void UpdateTeamMemberLevel(uint32 teamId,uint32 roleId);
	bool IsInTeamRequest(CUser *pLeader,uint32 askForJoinId);
	void AskForJoinTeam(CUser*,uint32 headId,uint8 type=0);
	void RefuseJoinTeam(CUser *pUser, uint32 headId);

	CUserTeam *GetTeam(uint32 teamId);
	void AddTeam(uint32 teamId,CUserTeam *pTeam);

	void DecBZXingDongLi(CUser *pUser,int xingDongLi);

	bool CanJoinTeam();

	void GetTeamLeaveMem(CUser *pUser,uint32 *members,uint8 &num);
	uint8 MakeTeamFaBuInfo(CNetMessage &msg,STeamFaBuData &data);
	void GetTeamList(CUser *pUser,uint8 page);
	void UpdateTeamData(uint32 teamId);
	bool AllowJoinTeam(CUser *pUser,uint32 member,bool isMemRecv=false);
	bool AllowJoinTeamWithNoNotice(CUser *pUser,uint32 member);
	void GetAskForUserList(CUser*);
	void GetTeamMembers(CUser*);
	void LeaveTeam(CUser*);
	void TempLeaveTeam(CUser *pUser);
	void ReturnTeam(CUser *pUser);

	void SetTeamType(uint32 teamId,uint8 type,uint16 minLv,uint16 maxLv);
	void SetTeamFaBuStatus(uint32 teamId,bool status);

	bool CanEnterBangPai(CUser *pUser);
	void GetTeamData(CUser *pUser);

	void CallBackTeam(CUser *pUser);
	void NotAllowJoin(CUser*,uint32 member);
	void DelTeamMember(CUser*,uint32 member);

	void UserMove(CUser *,uint16 x,uint16 y);
	void MonsterMove();
	void SendMonsterMove(SVisibleMonster &monster);
	void SendMonsterBossMove(SVisibleMonsterBoss &monster);
	void CreateMonsterMovePath(vector<uint8> &path,int x,int y,int center_x,int center_y,int radius);
	bool CanWalkPos(uint16 x,uint16 y);

	void ChangeScene(CUser *pUser,CScene *pOldScene);
	void SendUserList(CUser *pUser);
	void MeetEnemy(ShareUserPtr pUser);
	void LingChongXianZhongFightNumAdd(ShareUserPtr user);
	void PlayerPk(ShareUserPtr pUser,uint32 roleId,bool yaoqing);
	void MakeNearPlayerList(CUser *pUser,uint8 page,CNetMessage &msg);

	void BossMonsterFight(ShareUserPtr pUser,SVisibleMonsterBoss &boss,int memberNum);
	void PlayerAskForMatch(ShareUserPtr pUser,uint32 roleId);
	bool FindFacePlayer(CUser *pUser,ShareUserPtr &find);
	void AcceptAskForMatch(ShareUserPtr pUser,bool accept,uint32 roleId);

	void TransportOutOfKunLunShan();

	void SceneChat(CNetMessage &msg,int ignoreId=0);
	void TeamChat(uint32 teamId,CNetMessage &msg,int ignoreId=0);

	void NolockUpdateUserInfo(CUser *pUser,uint8 uType);
	void UpdateUserInfo(CUser *pUser,uint8 uType);

	void ResetTeamMember(CUser *pUser);
	bool SwitchTeamZhenFa(CUser *pUser,uint16 zhenfaId,CNetMessage &msg);
	bool TeamZhenFa_SetPetState(CUser *pUser,uint16 petId,uint8 state,CNetMessage &msg);
	bool TeamZhenFa_ChangeUnitPos(CUser *pUser,uint8 srcPos,uint8 tarPos,CNetMessage &msg);

	void GetTeamMemberList(CUser *pHead,vector<ShareUserPtr> &memList);
	int GetTeamAllMemNum(uint32 teamId);
	int GetTeamMemNum(uint32 temdId);
	CUser *GetInTeamMember2(uint32 teamId);
	CUser *GetTeamMember(uint32 teamId,int idx);

	void ShiMenFight(CUser *pUser);
	void WabaoFight(CUser *pUser);

	CCallScript *GetScript()
	{
		return m_pScript;
	}

	void NotInTeamUser(uint8 page,CNetMessage &msg);

	void InitNpcPoint(SPoint *pPoint,uint8 num);
	void AddNpc(uint16 id,bool sendMsg = false);
	void AddNpc(uint16 tmplId,uint16 x,uint16 y,uint8 direct);
	void AddNpc(uint16 tmplId,int n, uint16 x, uint16 y, uint8 direct);
	void AddNpcIndexByFightId(uint16 tmplId,int fightId,uint16 x, uint16 y, uint8 direct,uint16 index,uint16 pic=0,uint8 color=PQT_BLUE);
	void AddNpcWithIndex(uint16 tmplId,uint16 pic,uint16 x, uint16 y,uint8 direct,uint16 index,const char *name=NULL,uint8 type=0,uint8 color=PQT_BLUE);

	void ModifyNpcPos(uint16 id,uint16 x,uint16 y);
	void DelNpc(uint16 id,uint16 index=0);
	void DelDynamicNpc(SNpcInstance *pNpc);
	void DelDynamicNpcWithIndex(int npcId,int npcIdx);
	void ClearDynamicNpc();

	//    void DelNpc(uint16 x,uint16 y,uint16 id);
	SNpcInstance *FindNpc(uint16 id,uint16 index=0);
	SNpcInstance *FindFaceNpc(CUser *pUser);
	SNpcInstance *FindNpcByPos(uint16 x, uint16 y);

	static const int ONE_PAGE_MAX_NUM = 20;
	static const int SEND_MAX_USER_NUM = 50;
	void SetFightStep(uint8 step)
	{
		m_fightStep = step;
	}
	bool CanQieCuo()
	{
		return m_fightStep == 1;
	}

	void SetFBStep(uint8 step)
	{
		m_fbStep = step;
	}
	uint8 GetFBStep()
	{
		return m_fbStep;
	}

	void SetEmptyTime(time_t empty)
	{
		m_emptyTime = empty;
	}
	time_t GetEmptyTime()
	{
		return m_emptyTime;
	}
	const static int EMPTY_FUBEN_TIMEOUT = 1800; // 副本清除超时时间 30分钟

	// 多人闯关战斗
	void ChuangGuanRobberFight( CUser *pUser ); // 小贼
	void ChuangGuanRobberFightReward( CUser *pUser, bool win ); // 小贼 结束给奖励
	void ChuangGuanUserFight( CUser *pUser, int othRoleId ); // 玩家战斗
	void ChuangGuanUserFightBusy( CUser *pUser, int othRoleId ); // 玩家战斗 玩家在战斗中
	void ChuangGuanUserFightReward(CUser *pUser,CUser *pOther,bool win); // 玩家战斗 结束给奖励

	// 钓鱼战斗 抢夺
	void GrabFishUserFight( CUser *pUser, int othRoleId ); // 玩家战斗

	void CMissionFight(CUser *pU,int missId,int fightCfgId);
	bool AddMonsterByFightId(ShareFightPtr &pFight, int fightId, uint16 level, int visableId = 0);
	bool AddMonsterBySpecFightId(ShareFightPtr &pFight,int specFightId,uint16 level);
	bool AddZhuaguiMonster(ShareFightPtr &pFight, int fightId, uint16 level, const char* name);
	bool AddBloodFightMonster(ShareFightPtr &pFight, BloodFight& fightCfg, double ratio);

	// 新版任务战斗
	uint8 AddMonsterBossToFight(ShareFightPtr &fight,uint32 bossId,uint8 pos,uint8 zhenfaPos,uint16 level = 0,SMonsterInst **ppMonster = NULL); // 添加任务战斗战斗怪物

	void BangZhanSceneAddExp(int expRatio);
	void ExitBangZhan();
	void AddBangZhanBox();
	void ClearBangZhanBox();

	void AddXtmasBox(int npcId,int &index,int pic,int num);

	void AddWeddingGift(CUser *pLeader);

	void AddPetCopyMonsterBoss(int level);
	void AddShengJieMonsterBoss(int level);
	void AddQiangHuaMonsterBoss();
	void AddChongKaiMonsterBoss();
	void AddXiLianMonsterBoss();

	void KuaFuZhuoGuiFight(ShareUserPtr pU);

	void FengShenFight(ShareUserPtr pU,int fengShenId,int fightId);
	void DailyBossFight(ShareUserPtr pU,int taskIndex);

	void MeetSelfMonster(ShareUserPtr pUser,int monsterType,string &monsterName);

	// 获取怪物的战斗位置
	int GetMonsterFightPos(int idx);

	void GetUserList(list<uint32> &userList);
	void SetX(uint16 x)
	{
		m_x = x;
	}
	void SetY(uint16 y)
	{
		m_y = y;
	}
	uint16 GetX()
	{
		return m_x;
	}
	uint16 GetY()
	{
		return m_y;
	}
	uint8 GetTeamMem(uint32 teamId,uint32 members[MAX_TEAM_MEMBER]);

	void AddVisibleBossByFightId(int fightId,int pos_x,int pos_y);

	void AddVisibleMonsterBoss(const char *name,uint16 pic,uint16 center_x,uint16 center_y,uint16 radius,uint8 type=0,time_t createTime=0);

	void AddVisibleMonster(SVisibleMonster &);
	void ClearVisibleMonster();
	void ClearVisibleMonsterBoss();
	bool FindVisibleMonster(uint32 id,SVisibleMonster &,uint8 flag);
	bool FindVisibleMonsterBoss(uint32 id,SVisibleMonsterBoss &,uint8 flag);
	void DelVisibleMonster(uint32 id);
	uint8 GetVisibleMonsterNumById(int beginId,int endId);
	int GetVisibleMonsterNum()
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		return m_visibleMonsters.size();
	}
	int GetVisibleMonsterBossNum()
	{
		boost::recursive_mutex::scoped_lock lk(m_monster_mutex);
		return m_visibleMonstersBoss.size();
	}
	int GetVisibleMonsterBossNum(int step); // 获取某个阶段boss的个数
	void ShowVisibleMonsterBoss(int step); // 显示某个阶段的boss
	SVisibleMonsterBossDrop* GetVisibleMonsterBossDrop(int id); // 获取怪物掉落

	int TongTianTaFight(ShareUserPtr user);	// 通天塔战斗
	void KunLunShanFight(ShareUserPtr user);	// 昆仑山战斗
	void KunLunShanTeamFight(ShareUserPtr user);
	void MatchKuaFu1V1Fight();
	
	void FeiXianFight(ShareUserPtr user);	// 飞仙战场战斗
	void XiuXianTeamFight(ShareUserPtr user,int idx);
	void XtmasTreeFight(int user_id,int enemy_id);	//圣诞树战斗
	void XtmasBoxFight(int user_id,int enemy_id);    //圣诞宝箱战斗
	void KuaFuXueLianFight(int user_id,int enemy_id);    //跨服雪莲战斗
	int AddXueLianNpc(); 
	void KuaFu1vs1PreliminaryFight(int user_id,ShareUserPtr pEnemy);//跨服1vs1预赛

	void RiChangQiangHuaFuBenFight(ShareUserPtr user,SVisibleMonsterBoss& boss); // 日常 强化副本战斗
	void RiChangChongWuFuBenFight(ShareUserPtr user,SVisibleMonsterBoss& boss); // 日常 神将副本战斗
	void RiChangJinBiFuBenFight(ShareUserPtr user,SVisibleMonsterBoss& boss); // 日常 金币副本战斗
	void RiChangShengJieFuBenFight(ShareUserPtr user,SVisibleMonsterBoss& boss); // 日常 道具副本战斗
	void RiChangQianNengFuBenFight(ShareUserPtr user,SVisibleMonsterBoss& boss); // 日常 强化副本战斗
	void RiChangXiangQianFuBenFight(ShareUserPtr user,SVisibleMonsterBoss& boss);	// 镶嵌副本战斗
	void RiChangXiLianFuBenFight(ShareUserPtr user, SVisibleMonsterBoss & boss);	// 洗炼副本战斗
	void RiChangChongKaiFuBenFight(ShareUserPtr user,SVisibleMonsterBoss& boss);	// 神将铠副本战斗

	void XunChaShiFight(ShareUserPtr user,int npcId,int index);
	int LingQiJuanXianFight(ShareUserPtr user);
	void SetNPCMonsterFightFlag(int npcId,int index,bool isfight);

	void KuaFuBossPKFight(ShareUserPtr ptr,ShareUserPtr tarPtr);

	void BangPaiPKFight(ShareUserPtr ptr,ShareUserPtr tarPtr);
	void HuSongFight(ShareUserPtr ptr,ShareUserPtr tarPtr);

	bool TryJoinActivityFight(ShareUserPtr pUser, int type);
	void ZhuoGuiBattle(ShareUserPtr pUser,int fightType,int monPic,string &bossName,int turn,int minMonPic);
	void BaiHuaXianZiBattle(ShareUserPtr);
	void HuodongBattle(ShareUserPtr, int);
	int GetHuodongBitSet(int);
	int GetHuodongFightId(int);
	int GetHuodongFightType(int);
	
	//是否是百花仙子活动地图
	bool IsBaiHuaXianZiFightMap();

	int GetUserNum();

	const char *GetDynamicNpcName(uint32 npcId,uint32 index);

	void ClearTreasureMonster();
	void ClearXunChaShiNPCMonster();
	void ClearLingQiJuanXianNPCMonster();

	void AddXunChaShiNPCMonster(int npcId,vector<SPointFace> &point,vector<int> &fightId,vector<int> &monsterId);
	
	void AddLingQiJuanXianNPCMonster(int refreshValue);
	void AddKunLunShanMonster();
	void AddKunLunShanTeamMonster();
	bool IsFuBen() { return m_usedFuBen; } // 是否是副本

	void FeiXianSceneAddExp();

	bool GetCanWalkPos(uint16 &x,uint16 &y);
	bool GetCanWalkPos_NoLock(uint16 &x, uint16 &y);
	void Match();
	void TeamMatchArrangeFight();
	void BangPaiTiaoZhanSaiTeamMatchArrangeFight();
	void MatchArrangeFight();
	void MatchTiaoZhanSaiFight();
	struct SMatchUser
	{
		uint32 roleId;
		int level;
		int equipQuailty;
	};
	void GetMatchUser(vector<SMatchUser> &userList, bool useCorrection = true);

	void BangPaiTiaoZhanTimer(); // 帮派挑战赛
	void BangPaiTiaoZhanAddPoint(int bang, int point); // 帮派挑战赛 增加积分
	void BangPaiTiaoZhanTongJiPoint(); // 帮派挑战赛 统计、保存积分

	void SetUserJiFen(uint32 roleId,char *name,short jifen);

	void AddJumpPoint(uint16 x,uint16 y,uint16 toX,uint16 toY,uint16 sceneId);

	bool Clear();
	int GetState();
	void SetState(int state);
	void SendKunLunShanTime();
	void SendKunLunShanTeamTime();
	void SendFeiXianAward();

	bool m_usedFuBen;
	time_t m_startTime;
	uint32 m_1V1SceneTime;
	int m_hardType; // 难度等级
	int m_specialRewardPos; // 副本每层特殊奖战斗次数
	int m_specialRewardIdx; // 副本每层特殊奖类型

	void SetGroupId(int gId)
	{
		m_groupId = gId;
	}
	int GetGroupId()
	{
		return m_groupId;
	}
	void SetNewHead(CUser *pUser,uint32 newHead);
	char *GetMatchPaiMing();
	void GetMatchPaiMing(int count, CNetMessage &msg); // 给前几名的积分
	void GetMatchTopRoleName(char* name); // 获取擂台赛第一名名字
	void SetShiYaoLevel(int state)
	{
		m_state = state;//1普通，2英雄
	}

	int GetUserJiFen(uint32 roleId);
	void ClearUserJiFen(uint32 roleId);
	// 擂台积分结算
	void LeiTaiJiFenCalc();

	void SetInTeamMemLeave(CUser *pUser);

	uint8 AddKillMonsterNum(){return ++m_killMonsterNum;}
	void SetFuBenIndex(int t){fubenindex = t;}
	void SetNextMapId(int id){nextMapid = id;}
	int GetNextMapId(){return nextMapid;}
	void SetNextFuBenId(int id){m_nextFuBenId = id;}
	int GetNextFuBenId(){return m_nextFuBenId;}
	void SetPrevFuBenId(int id){m_prevFuBenId = id;}
	int GetPrevFuBenId(){return m_prevFuBenId;}
	int GetFuBenIndex(){return fubenindex;}
	int GetDynamicNpcNum();
	void SendJumpPoint(CUser *pUser);
	bool CheckPos(uint16 x,uint16 y);

	void AddDieCount(int dieCount) { m_dieCount += dieCount; } // 增加一次死亡次数
	int GetDieCount() { return m_dieCount; }; // 获取死亡次数
	void SetDieCount(int dieCount) { m_dieCount = dieCount; } // 设置死亡次数
	CUser *GetCurrentFuBenTeamLeader(); // 获取当前副本队伍队长
	bool LeaveSceneTeam(uint32 teamId,CUser *pUser);
	uint16 AddUserGroupToBattle(ShareFightPtr &fight, ShareUserPtr &pUser, uint8 beginPos = 0, bool isQunXian = false);	// 默认添加1~9
	uint16 AddUserGroupToBattleEx(ShareFightPtr &fight, ShareUserPtr &pUser, vector<uint16>& hpPercent, uint8 beginPos = 0, bool isQunXian = false);	// 默认添加1~9

	void MakeLeiTaiFight(ShareUserPtr &pUserLeft, ShareUserPtr &pUserRight);
	bool CanQieCuoScene(uint16 sceneId);
private:
	bool GroupClear(int sceneId,uint16 x,uint16 y);
	void GroupSetState(int state);

	void Init();

	void FindMatchUser(vector<uint32> &userList);
	void BangPaiTiaoZhanFindMatchUser(vector<uint32> &userList);

	void AddGuYuFightMonster(ShareFightPtr pFight,uint8 num,uint8 level);

	void NoLockChangeScene(CUser *pUser,CScene *pOldScene);

	bool InitEpisodeBattle(CUser *p,ShareFightPtr &pFight,ShareUserPtr &pUser);

	void AddSingleUser(ShareFightPtr &fight, ShareUserPtr &user, uint8 begin, bool isQunXian = false);
	void AddSingleUserEx(ShareFightPtr &fight, ShareUserPtr &user, uint8 begin, vector<uint16>& hpPercent);
	uint16 AddTeamToFight(ShareFightPtr &pFight,CUserTeam *pTeam,uint8 begin=0);

	void AddSingleUserWithZhenFaId(ShareFightPtr &fight,ShareUserPtr &user,uint8 begin,uint16 zhenFaId,uint16 zhenFaLv,uint8 userPos);


	void ForEachTeamMember(uint32 teamId,boost::function<void(ShareUserPtr)> f);

public:
	void ForEachUser(boost::function<void(ShareUserPtr)> f);
	int GetSrcSceneId(){return m_srcSceneId;}
	void SetSrcSceneId(int val){m_srcSceneId = val;}
	void BroadcastMsgExcept(CNetMessage &msg,CUser *pUser);
	void SetDropItemTime(uint32 t){boost::recursive_mutex::scoped_lock lk(m_mutex);	m_dropItemTime = t;}
	uint32 GetDropItemTime(){boost::recursive_mutex::scoped_lock lk(m_mutex);	return m_dropItemTime;}
	void SetPetCopyDifficulty(uint8 t){boost::recursive_mutex::scoped_lock lk(m_mutex);	m_petCopyDifficulty = t;}
	uint8 GetPetCopyDifficulty(){boost::recursive_mutex::scoped_lock lk(m_mutex);	return m_petCopyDifficulty;}
	void SetPetCopyUserDie(){boost::recursive_mutex::scoped_lock lk(m_mutex); m_petCopyUserDie = true;}
	void ClearPetCopyUserDie(){boost::recursive_mutex::scoped_lock lk(m_mutex); m_petCopyUserDie = false;}
	uint16 GetVisibleRobotNum(){boost::recursive_mutex::scoped_lock lk(m_mutex); return m_visibleRobot.size();}
	void AddVisibleRobot(CUser *pUser);
	void RemoveVisibleRobot(uint16 num);
	ShareUserPtr GetVisibleRobotPtr(int visibleID);

	void ClearAllNpc(int npcId);
	
	void AddBaoWeiZhanBox();
	void BaoWeiZhaoFight(ShareUserPtr pUser);
	void ClearBaoWeiZhanBox();

	void BroadcastMsg(CNetMessage &msg,bool chatMsg = false,int ignoreId=0);
	void BroadcastMsgDirect(CNetMessage &msg);
	bool GoTo(CUser *pUser,uint16 pos_x,uint16 pos_y);
	void ResetTowers();
	void MakeTowerMsg(CUser *pUser, CNetMessage &msg);
	void MakeHurtRankMsg(CUser *pUser, CNetMessage &msg);
	bool CollectTower(CUser *pUser, uint16 towerId);
	void CalcTowerJifen(map<int, int>& towerCnt);
#ifdef KUA_FU
	void ShenJieMiJingPVEFight(ShareUserPtr pUser,uint16 monsterId,bool isBoss,SVisibleMonsterBoss &boss);//神界秘境PVE
	void AddShenJieMiJingWildMonsterToFight(ShareFightPtr &pFight, uint8 num, uint8 begin, CUser *pUser,uint16 monsterId,int level);
#endif
private:

	void Enter(CUser *pUser);
	void InsertJumpPoint(uint16 x,uint16 y,SJumpTo*);
	bool MakeTeamList(uint32 id,CUserTeam *pTeam,uint8 page,CNetMessage *msg,uint8 *teamNum,uint8 *tolNum);
	void BroadcastMsgExceptSameTeam(CUser *pUser,CNetMessage &msg);

	void SendTeamInfo(CUserTeam *pTeam,CUser *pAddUser);

	uint16 m_x;
	uint16 m_y;
	uint16 m_width;
	uint16 m_height;
	uint8 m_world_trans_type;	// 0不可世界传送 1可世界传送

	uint8 m_fightStep;
	int m_id;
	uint16 m_mapId;
	int m_srcSceneId;	// 副本中使用,源场景Id
	int m_groupId;
	uint8 m_fbStep; // 副本的步骤
	time_t m_emptyTime; // 副本没有人的时间

	string m_name;
	uint8 m_fightType;
	uint8 m_killMonsterNum;
	int m_dieCount; // 队伍内玩家死亡总次数
	bool m_addJump;
	SPoint m_jumpPoint;
	SJumpTo m_jumpToPoint;

	bool m_isPaiMing;
	time_t m_matchBegin;
	int m_state;

	const static int MAX_JIFEN_USER_NUM = 3;
	const static int MAX_PAIMING_INFO = 128;

	vector<SJiFenUser> m_jifenUsers;

	list<uint16> m_npcList;
	list<uint32> m_userList;
	vector<SPoint> m_canWalkPos;		// cell point
	CHashTable<int,bool> *m_canWalkPosHash;	// cell point

	CNetMessage m_pathInfo;

	list<SNpcInstance*> m_dynamicNpc;
	vector<SPoint> m_dynamicNpcPoint;

	list<SVisibleMonster> m_visibleMonsters;	// 暂留
	list<SVisibleMonsterBoss> m_visibleMonstersBoss;

	list<SMonsterListInfo> m_MonsterList;
	uint32 m_monsterIdIndex;
	uint32 m_monsterBossIdIndex;	// 下一个boss的index
	boost::recursive_mutex m_monster_mutex;

	const static int MAX_MONSTER_NUM = 10;
	uint16 m_monsters[MAX_MONSTER_NUM];
	uint8 m_monsterNum;
	//索引为x<<16|y
	struct SJumpPoint
	{
		uint16 x,y;
		SJumpTo *pJumpTo;
	};
	list<SJumpPoint> m_jumpList;

	CHashTable<uint32,CUserTeam*> m_userTeams;

	boost::recursive_mutex m_mutex;

	CSocketServer &m_socketServer;
	COnlineUser &m_onlineUser;
	CFightManager &m_fightManager;

	uint16 m_curVisibleId;
	CCallScript *m_pScript;
	int nextMapid;
	int fubenindex;
	bool GYQX_BossShow;
	int m_nextFuBenId;
	int m_prevFuBenId;
	int m_NPCMonSterIndex;	// 活动NPC怪索引
	uint32 m_dropItemTime;
	bool m_petCopyUserDie;	// 神将副本人物是否死亡
	uint8 m_petCopyDifficulty;	// 神将副本难度1-max

	list<ShareUserPtr> m_visibleRobot;	// 飞仙战场场景机器人列表
	int m_visibleRobotId;

	map<uint16, TowerInfo> m_towers; // 所有占塔贡献
public:
	const static uint32 MATCH_CD = 30; // 匹配冷却时间
	const static uint32 MATCH_FAILD_CNT = 5; // 匹配战斗最大失败次数
};

class CSceneManager
{
public:
	CSceneManager();
	~CSceneManager();
	CScene *FindScene(int id);
	CScene *FindScene(int mapId,int groupId);
	CScene *Find2Scene(int mapId,int groupId);
	bool Init();

	CScene *FindMarryHall(int id);

	CScene *GetMarryHall(int id);
	//获得帮派场景
	CScene *GetBangPaiScene(int sceneId,int bangPaiId);
	CScene *FindBangPaiScene(int sid);

	CScene *GetKuaFuBZScene(int groupIdx);

	CScene *GetFuBen(int scendId);
	CScene *GetFishingRoom();

	CScene *GetKunLunShanFirstScene();
	CScene *GetKunLunShanSceneByIndex(int sceneIndex);

	CScene *GetTeamKunLunShanFirstScene();
	CScene *GetKunLunShanTeamSceneByIndex(int sceneIndex);

	CScene *GetShenJieMiJingFirstScene();
	CScene *GetShenJieMiJingSceneByIndex(int sceneIndex);

	CScene *GetKuaFu1V1SceneByIndex(int sceneIndex);
	
	CScene *GetQiangHuaFuBen();	// 强化副本
	CScene *GetChongWuFuBen(int difficulty);	// 神将副本
	CScene *GetJinBiFuBen();	// 金钱副本
	CScene *GetDaoJuFuBen();	// 道具副本
	CScene *GetQianNengFuBen();	// 潜能副本
	CScene *GetXiangQianFuBen();// 镶嵌副本
	CScene *GetXiLianFuBen();	// 洗炼副本
	CScene *GetChongKaiFuBen();	// 神将铠副本
	CScene *GetShiLianFuBen();	// 试炼副本

	void FeiXianSceneAddExp();

	void AddKunLunShanMonster();
	bool GetKunLunShanRoomInfo(CNetMessage &msg);
	void TransportOutOfKunLunShan();
	void TransportOutOfTeamKunLunShan();
	void TransportOutOfFeiXian();
	void SendFeiXianAward();
	void SendKunLunShanTime();

	void AddKunLunShanTeamMonster();
	bool GetTeamKunLunShanRoomInfo(CNetMessage &msg);
	bool GetShenJieMiJingRoomInfo(CNetMessage &msg);
	void SendKunLunShanTeamTime();	

	void DelScene(int id);
	//删除帮派场景
	void DelBangPaiScene(int bangPaiId);
	void Timer();
	void BangZhanTimer();

#ifdef KUA_FU
	void KuaFuBangZhanTimer();
#endif
	
	void UpdateMonster();
	bool UpdateMonsterMove(int id, CScene *pScene);
	void GetGroupScene(int groupId,list<int> &sceneList);
	void RiChangQiangHuaFuBenClearScene();	// 强化副本
	void RiChangChongWuFuBenClearScene();	// 神将副本
	void RiChangJinBiFuBenClearScene();		// 金币副本
	void RiChangShengJieFuBenClearScene();	// 道具副本
	void RiChangQianNengFuBenClearScene();	// 潜能副本
	void NormalFuBenClearScene(int targetSrcId); // 副本清除通用接口
	void HuoDongSceneClear(int targetSrcId);	// 清除活动副本
	void KunLunShanClearScene();
	void FishClearScene();
	void KunLunShanTeamClearScene();

	bool IsFuBenEmpty(CScene* pScene);		// 副本是否没有人了
	CScene *GetCurrentFuBen(CScene* pScene); // 获取当前副本进度的副本地图id
	int GetKunLunShanSceneNum(){return m_kunLunShanSceneNum;}
	int GetKunLunShanTeamSceneNum(){return m_kunLunShanTeamSceneNum;}
	int GetShenJieMiJingSceneNum(){return m_shenjiemijingSceneNum;}

	static bool IsInActivityTime(int type);
	static bool IsNotifyActivityTime(int type);
	static bool IsBeforeActivityTime(int type);
	static bool IsAfterActivityTime(int type);
	static uint32 GetActivityFinishTime(int type);
	static void NotiyActivityInfo(CUser* pUser, int type);
	static int GetSOTTypeByOp(int type);
	bool IsInActivifyScene(int type, uint16 sceneId);

private:
	bool FindGroupScene(int id,CScene *pScene,int groupId,list<int> *sceneList);
	bool FindMapGroupScene(int id,CScene *pScene,int mapId,int groupId,CScene **ppScene);
	bool Find2MapGroupScene(int id,CScene *pScene,int mapId,int groupId,CScene **ppScene);
	bool FindMapSceneList(int id,CScene *pScene,int mapId,list<CScene*> *pSceneList);
	bool FindTongTianTaList(int id, CScene *pScene,int srcId_begin,int srcId_end,list<CScene*> *pSceneList);
	bool FindTongTianTaUnUsedList(int id, CScene *pScene, int srcId_begin,int srcId_end, list<CScene*> *pSceneList);
	bool FindTimeoutFuBenList(int id, CScene *pScene,int targetSrcId,list<CScene*> *pSceneList);
	bool FindHuoDongSceneList(int id, CScene *pScene,int targetSrcId,list<CScene*> *pSceneList);

	time_t m_matchRunTime;
	const static int RUN_MATCH_SPACE = 10; //120;

	int m_curFuBenId;
	int m_kunLunShanSceneNum;
	int m_kunLunShanTeamSceneNum;
	int m_shenjiemijingSceneNum;
	list<CScene*>   m_fuBenScene;
	list<CScene*>   m_marryHall;

	CHashTable<int,CScene*> m_sceneList;

	CHashTable<int,CScene*> m_bangPaiScene;
	boost::mutex m_bpMutex;

	bool m_isInit;
	CNpcManager &m_npcManager;
	int weekday;

	typedef set<int> scenes;
	typedef map<int, scenes> huodongScenes;
	huodongScenes m_huodongMaps;
};

#endif

