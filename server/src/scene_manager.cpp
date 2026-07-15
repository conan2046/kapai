#include "scene_manager.h"
#include "singleton.h"
#include "main.h"
#include "call_script.h"
#include "script_call.h"
#include "init.h"
#include "huo_dong.h"
#include <math.h>
#include <boost/format.hpp>
#include <boost/lambda/lambda.hpp>
#include <boost/lambda/if.hpp>
#include "huo_dong.h"
#include "blood_fight_manage.h"
#include "friend.h"
using namespace boost;

extern time_t sdHuodongMonsterDieTime;

// 帮派挑战赛
int BANG_PAI_TIAO_ZHAN_YEAR; // 年
int BANG_PAI_TIAO_ZHAN_MONTH; // 月
int BANG_PAI_TIAO_ZHAN_DAY; // 日
int BANG_PAI_TIAO_ZHAN_HOUR; // 时
int BANG_PAI_TIAO_ZHAN_MIN; // 分
int BANG_PAI_TIAO_ZHAN_BAO_MING_HOUR; // 报名时间
int BANG_PAI_TIAO_ZHAN_BAO_CHI_XU; // 持续时间
int BANG_PAI_TIAO_ZHAN_LIMIT_TEAM; // 帮派队伍限制数
int BANG_PAI_TIAO_ZHAN_BAOMINGTIME; // 报名时间点
int BANG_PAI_TIAO_ZHAN_STARTTIME; // 开始时间点
int BANG_PAI_TIAO_ZHAN_ENDTIME; // 结束时间点
char BANG_PAI_TIAO_ZHAN_RANK[255]; // 榜排行
vector<BangPaiTiaoZhanData> BANG_PAI_TIAO_ZHAN_DATA; // 帮派挑战赛积分记录
void BangPaiTiaoZhanSaiLoad();
void BangPaiTiaoZhanSaiInitDB();
void BangPaiTiaoZhanSaiSaveResult(int bang1,int bang2,int bang3);
void BangPaiTiaoZhanSaiJinChangNotice();
vector<SMonsterDistribution *> MonsterDistributionList;

extern boost::recursive_mutex tongTianTa_mutex;
extern vector<uint32> tongTianTaBaZhuData;	// 通天塔霸主ID,12/24/36/48/60

static const short Monster_Pos_x[] = {32,0 ,-32,-32,-32,0  ,32 ,32};
static const short Monster_Pos_y[] = {32,32,32 ,0  ,-32,-32,-32, 0};
static const int monsterMoveTimeStep = 5;

//组队
void CUserTeam::GetMember(uint32 *members, uint8 &num)
{
	num = 0;
	for(uint8 i = 0; i < MAX_TEAM_MEMBER; i++)
	{
		if(m_members[i] != 0 && m_leaveFlag[i] == LTS_InTeam)
			members[num++] = m_members[i];
	}
}

void CUserTeam::GetMemberByOrder(uint32 *members)
{
	for(uint8 i = 0; i < MAX_TEAM_MEMBER; i++)
	{
		if(m_members[i] != 0 && m_leaveFlag[i] == LTS_InTeam)
			members[i] = m_members[i];
		else
			members[i] = 0;
	}
}

void CUserTeam::GetAllMember(uint32 *members, uint8 &num)
{
	num = 0;
	for(uint8 i = 0; i < MAX_TEAM_MEMBER; i++)
	{
		if(m_members[i] != 0)
			members[num++] = m_members[i];
	}
}

void CUserTeam::GetAllMemberByOrder(uint32 *members)
{
	for(uint8 i = 0; i < MAX_TEAM_MEMBER; i++)
	{
		if(m_members[i] != 0)
			members[i] = m_members[i];
		else
			members[i] = 0;
	}
}

void CUserTeam::SwapMember()
{
	std::swap(m_members[1], m_members[2]);
	std::swap(m_leaveFlag[1], m_leaveFlag[2]);
}

void CUserTeam::UpdateTeamData()
{
	CNetMessage msg;
	msg.SetType(PRO_USER_TEAM);
	msg<<(uint8)16<<PRO_SUCCESS<<GetType();
	MakeAllMemberInfo(msg);

	CSocketServer &sock = SingletonSocket::instance();
	for(uint8 i=0;i < MAX_TEAM_MEMBER;i++)
	{
		if(m_members[i] > 0)
		{
			ShareUserPtr p = SingletonOnlineUser::instance().GetUserByRoleId(m_members[i]);
			CUser *pU = p.get();
			if(pU != NULL)
				sock.SendMsg(pU->GetSock(),msg);
		}
	}
}

void CUserTeam::UpdateMemberLevel(uint32 roleId,uint16 level)
{
	CNetMessage msg;
	msg.SetType(PRO_USER_TEAM);
	msg<<(uint8)31<<roleId<<level;

	CSocketServer &sock = SingletonSocket::instance();
	for(uint8 i=0;i < MAX_TEAM_MEMBER;i++)
	{
		if(m_members[i] > 0)
		{
			ShareUserPtr p = SingletonOnlineUser::instance().GetUserByRoleId(m_members[i]);
			CUser *pU = p.get();
			if(pU != NULL)
				sock.SendMsg(pU->GetSock(),msg);
		}
	}
}


CUserTeam::CUserTeam()
{
	for(uint8 i = 0; i < MAX_TEAM_MEMBER; i++)
	{
		m_members[i] = 0;
		m_leaveFlag[i] = LTS_LeaveTeam;
	}
	
	m_tzhenrong.clear();
	for(uint8 i = 0; i < ZHEN_FA_POS_NUM; i++)
	{
		SZhenFaMemData d;
		m_tzhenrong.push_back(d);
	}

	m_type = 0;
	m_minLv = 0;
	m_maxLv = 0;
	m_lastWorldChatTime = 0;
	m_useZhenFaId = 0;
}

uint8 CUserTeam::GetMemberNum()
{
	uint8 num = 0;
	for(uint8 i = 0; i < MAX_TEAM_MEMBER; i++)
	{
		if(m_members[i] != 0 && m_leaveFlag[i] == LTS_InTeam)
			num++;
	}
	return num;
}

uint8 CUserTeam::GetLeaveNum()
{
	uint8 num = 0;
	for(uint8 i = 1; i < MAX_TEAM_MEMBER; i++)
	{
		if(m_members[i] != 0 && m_leaveFlag[i] == LTS_LeaveTeam)
			num++;
	}
	return num;
}

bool CUserTeam::IsAskedForJoin(uint32 userId)
{
	list<uint32>::iterator i = m_askForJoin.begin();
	for (; i != m_askForJoin.end(); i++)
	{
		if (*i == userId)
			return true;
	}
	return false;
}

void CUserTeam::GetLeaveMem(uint32 *members, uint8 &num)
{
	num = 0;
	for(uint8 i = 1; i < MAX_TEAM_MEMBER; i++)
	{
		if(m_members[i] != 0 && m_leaveFlag[i] == LTS_LeaveTeam)
		{
			members[num] = m_members[i];
			num++;
		}
	}
}

bool CUserTeam::InRequest(uint32 id)
{
	for(list<uint32>::iterator i = m_requestList.begin(); i != m_requestList.end(); i++)
	{
		if(id == *i)
			return true;
	}
	return false;
}

void CUserTeam::ReturnTeam(uint32 roleId)
{
	for (uint8 i = 1; i < MAX_TEAM_MEMBER; i++)
	{
		if(m_members[i] == roleId)
		{
			if(m_leaveFlag[i] == LTS_LeaveTeam)
				m_leaveFlag[i] = LTS_InTeam;
			AddMemberToZhenRong(roleId,m_leaveFlag[i]);
			break;
		}
	}
}

void CUserTeam::TempLeaveTeam(uint32 roleId)
{
	for (uint8 i = 0; i < MAX_TEAM_MEMBER; i++)
	{
		if(m_members[i] == roleId && m_leaveFlag[i] == LTS_InTeam)
		{
			m_leaveFlag[i] = LTS_LeaveTeam;
			break;
		}
	}
	for(uint8 i=0;i < m_tzhenrong.size();i++)
	{
		if(m_tzhenrong[i].mem_type == EZFMT_USER && m_tzhenrong[i].mem_id == roleId)
		{
			m_tzhenrong[i].mem_type = EZFMT_NONE;
			m_tzhenrong[i].mem_id = 0;
		}
	}
}

void CUserTeam::MakeTeamFaBuInfo(CNetMessage &msg)
{
	uint16 pos = msg.GetDataLen();
	uint8 memNum = 0;
	msg<<memNum;
	for(uint8 i=0;i < MAX_TEAM_MEMBER;i++)
	{
		if(m_members[i] > 0)
		{
			ShareUserPtr p = SingletonOnlineUser::instance().GetUserByRoleId(m_members[i]);
			CUser *pU = p.get();
			if(pU != NULL)
			{
				msg<<pU->GetRoleId()<<pU->GetName()<<m_leaveFlag[i]<<pU->GetHead()<<pU->GetSex()<<(uint16)pU->GetLevel();
				memNum++;
			}
		}
	}
	msg.WriteData(pos,&memNum,sizeof(memNum));
}

bool CUserTeam::SwitchZhenFa(uint16 zhenfaId,CNetMessage &msg)
{
	if(zhenfaId == 0)
		return false;
	if(m_useZhenFaId == zhenfaId)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0442,TIPS_SUCCESS_COLOR);
		return true;
	}
	m_useZhenFaId = zhenfaId;
	msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_SSJ_0443,TIPS_SUCCESS_COLOR);
//	UpdateTeamData();

	CZhenFaCfgMgr &zhenfaMgr = SingletonCZhenFaCfgMgr::instance();
	SZhenFaBasicCfg *pBasicCfg = zhenfaMgr.GetBasicCfg(zhenfaId);
	if(pBasicCfg == NULL)
		return false;
	for(uint8 i=0;i < m_tzhenrong.size();i++)
	{
		m_tzhenrong[i].fightPos = pBasicCfg->fightPos[i];
	}
	return true;
}

bool CUserTeam::ZhenFa_SetPetState(uint16 petId,uint8 pos,uint16 leaderLevel,CNetMessage &msg)
{
	if(petId == 0 || pos == 0 || pos > m_tzhenrong.size())
		return false;


	SZhenFaBasicCfg *pBasicCfg = SingletonCZhenFaCfgMgr::instance().GetBasicCfg(m_useZhenFaId);
	if (pBasicCfg == NULL)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_SSJ_0447, TIPS_FAILURE_COLOR);
		return true;
	}
	if (leaderLevel < pBasicCfg->open_level[pos])
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_SSJ_0444, TIPS_FAILURE_COLOR);
		return true;
	}

	m_tzhenrong[pos].mem_type = EZFMT_PET;
	m_tzhenrong[pos].mem_id = petId;
		
	msg<<PRO_SUCCESS<<(uint8)(pos+1)<<MakeStringColor(LANGUAGE_SSJ_0450,TIPS_SUCCESS_COLOR);

	return true;
}

bool CUserTeam::ZhenFa_ChangeUnitPos(uint8 srcPos,uint8 tarPos,uint16 leaderLevel,CNetMessage &msg)
{
	uint8 size = m_tzhenrong.size();
	if(srcPos == 0 || tarPos == 0 || srcPos == tarPos || srcPos > size || tarPos > size)
		return false;
//	if(m_tzhenrong[srcPos-1].mem_type == EZFMT_NONE)
//		return false;
	
	SZhenFaBasicCfg *pBasicCfg = SingletonCZhenFaCfgMgr::instance().GetBasicCfg(m_useZhenFaId);
	if(pBasicCfg == NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0447,TIPS_FAILURE_COLOR);
		return true;
	}
	if(leaderLevel < pBasicCfg->open_level[srcPos-1] || leaderLevel < pBasicCfg->open_level[tarPos-1])
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0449,TIPS_FAILURE_COLOR);
		return true;
	}
	
	SZhenFaMemData t;
	t = m_tzhenrong[srcPos-1];
	m_tzhenrong[srcPos-1].mem_type = m_tzhenrong[tarPos-1].mem_type;
	m_tzhenrong[srcPos-1].mem_id = m_tzhenrong[tarPos-1].mem_id;
	m_tzhenrong[tarPos-1].mem_type = t.mem_type;
	m_tzhenrong[tarPos-1].mem_id = t.mem_id;

	msg<<PRO_SUCCESS;
	return true;
}


void CUserTeam::GetZhenFaMember(vector<SZhenFaMemData> &zhenfaMember)
{
	zhenfaMember = m_tzhenrong;
}

uint16 CUserTeam::GetUseZhenFaId()
{
	return m_useZhenFaId;
}

// 根据队伍更新任务
void CUserTeam::UpdateMission(CScene *pScene, int type, const char *pInts, const char *pStrs)
{
	bool bContinue = true;
	for (int i = 0; i < MAX_TEAM_MEMBER; ++i)
	{
		if (m_members[i] == 0) continue;
		ShareUserPtr ptr = SingletonOnlineUser::instance().GetUserByRoleId(m_members[i]);
		CUser* user = ptr.get();
		if (user == NULL) continue;

		if (type == MISSION_ID_ZhuoGui)
		{
			uint16 times = user->GetExtData16(50);
			if (i == 0 && times % TASK_NUM_LIMIT == 0) bContinue = false;

			if (times >= TASK_MAX_LIMIT)
			{// 抓满了
				user->DelCMission(MISSION_ID_ZhuoGui);
			}
			else
			{// 没抓满
				if (bContinue)
				{// 没抓
					user->UpdateCMissionEx(MISSION_ID_ZhuoGui, pInts, pStrs, times % TASK_NUM_LIMIT + 1);
				}
				else
				{
					user->DelCMission(MISSION_ID_ZhuoGui);
					SingletonCMissionManager::instance().SendAvailableCMissionInfo(user, EMISS_STYPE_ZhuoGui);
				}
			}
		}
	}
}

void CUserTeam::SendJoinTeamMemberData(uint32 joinId,uint32 recvId)
{
	uint8 flag = 0;
	for(uint8 i=0;i < MAX_TEAM_MEMBER;i++)
	{
		if(m_members[i] == joinId)
		{
			flag = m_leaveFlag[i];
			break;
		}
	}
	CNetMessage msg;
	msg.SetType(PRO_USER_TEAM);
	msg<<(uint8)2<<joinId<<flag;

	CSocketServer &sock = SingletonSocket::instance();
	for(uint8 i=0;i < MAX_TEAM_MEMBER;i++)
	{
		if((recvId == 0 && m_members[i] > 0) || (recvId > 0 && m_members[i] == recvId))
		{
			ShareUserPtr p = SingletonOnlineUser::instance().GetUserByRoleId(m_members[i]);
			CUser *pU = p.get();
			if(pU != NULL)
				sock.SendMsg(pU->GetSock(),msg);
		}
	}
}

void CUserTeam::SendTeamFaBuData(uint32 memberId)
{
	CNetMessage msg;
	msg.SetType(PRO_USER_TEAM);
	
	STeamFaBuData teamData;
	uint8 fabuState = SingletonTeamFaBuCfgMgr::instance().GetFaBuTeamInfo(m_type,m_members[0],teamData) ? 1 : 0;
	msg<<(uint8)27<<fabuState<<m_type<<m_minLv<<m_maxLv;

	CSocketServer &sock = SingletonSocket::instance();
	for(uint8 i=0;i < MAX_TEAM_MEMBER;i++)
	{
		if((memberId == 0 && m_members[i] > 0) || (memberId > 0 && m_members[i] == memberId))
		{
			ShareUserPtr p = SingletonOnlineUser::instance().GetUserByRoleId(m_members[i]);
			CUser *pU = p.get();
			if(pU != NULL)
				sock.SendMsg(pU->GetSock(),msg);
		}
	}
}

void CUserTeam::ReSetTeamZhenRong()
{
	for (uint8 i = 0; i < m_tzhenrong.size(); i++)
		m_tzhenrong[i].Clear();

	ShareUserPtr head = SingletonOnlineUser::instance().GetUserByRoleId(m_members[0]);
	CUser *pHead = head.get();
	if(pHead != NULL)
	{
		pHead->GetCurrentZhenFaData(m_tzhenrong);
	}
	
	SZhenFaBasicCfg *pCfg = SingletonCZhenFaCfgMgr::instance().GetBasicCfg(m_useZhenFaId);
	if(pCfg != NULL)
	{
		for(uint8 i=0;i < m_tzhenrong.size();i++)
			m_tzhenrong[i].fightPos = pCfg->fightPos[i];
	}
	
	for (uint8 i = 0; i < MAX_TEAM_MEMBER; i++)
		AddMemberToZhenRong(m_members[i],m_leaveFlag[i]);
}

void CUserTeam::AddMemberToZhenRong(uint32 userId,uint8 inTeam)
{
	if(userId == 0)
		return;
	if(inTeam == LTS_LeaveTeam)
		return;
	int size = m_tzhenrong.size();
	for(int i=0;i < size;i++)
	{
		if(m_tzhenrong[i].mem_type == EZFMT_USER && m_tzhenrong[i].mem_id == userId)
			return;
	}
	for(int i=size-1;i >= 0;i--)
	{
		if(m_tzhenrong[i].mem_type == EZFMT_NONE)
		{
			m_tzhenrong[i].mem_type = EZFMT_USER;
			m_tzhenrong[i].mem_id = userId;
			return;
		}
	}
	
	for(int i=0;i < size;i++)
	{
		if(m_tzhenrong[i].mem_type != EZFMT_USER)
		{
			m_tzhenrong[i].mem_type = EZFMT_USER;
			m_tzhenrong[i].mem_id = userId;
			return;
		}
	}
}

bool CUserTeam::Join(uint32 userId)
{
	for(uint8 i = 0; i < MAX_TEAM_MEMBER; i++)
	{
		if(m_members[i] == userId)
		{
			return false;
		}
		else if(m_members[i] == 0)
		{
			m_members[i] = userId;
			if(i == 0)	// 加入队长
			{
				m_leaveFlag[i] = LTS_InTeam;
				ShareUserPtr ptr = SingletonOnlineUser::instance().GetUserByRoleId(userId);
				CUser *pUser = ptr.get();
				if(pUser == NULL)
					return true;
				m_headName = pUser->GetName();
//				m_headXiang = pUser->GetXiang();
				m_headLevel = pUser->GetLevel();
				m_useZhenFaId = pUser->GetUseZhenFaId();
				ReSetTeamZhenRong();
			}
			else	// 加入队员
			{
				ShareUserPtr pHead = SingletonOnlineUser::instance().GetUserByRoleId(m_members[0]);
				ShareUserPtr ptr = SingletonOnlineUser::instance().GetUserByRoleId(userId);
				if(pHead.get() == NULL || ptr.get() == NULL)
					return true;
				if(pHead->GetScene() == ptr->GetScene())
					m_leaveFlag[i] = LTS_InTeam;
				else
					m_leaveFlag[i] = LTS_LeaveTeam;
				AddMemberToZhenRong(userId,m_leaveFlag[i]);
			}

			// 满人清除邀请列表和申请列表
			uint8 memNum = 0;
			for(uint8 j = 0; j < MAX_TEAM_MEMBER; j++)
			{
				if(m_members[j] > 0)
					memNum++;
			}
			if(memNum >= MAX_TEAM_MEMBER)
			{
				ClearAskForJoinTeamList();
				ClearRequestList();
			}			
			return true;
		}
	}
	return false;
}

void CUserTeam::Exit(uint32 userId)
{
	bool isLeader = false;
	for(uint8 i = 0; i < MAX_TEAM_MEMBER; i++)
	{
		if(m_members[i] == userId)
		{
			m_members[i] = 0;
			m_leaveFlag[i] = LTS_LeaveTeam;
			if(i == 0)
				isLeader = true;
			break;
		}
	}
	uint32 size = m_tzhenrong.size();
	for(uint8 i = 0; i < size; i++)
	{
		if(m_tzhenrong[i].mem_type == EZFMT_USER && m_tzhenrong[i].mem_id == userId)
		{
			m_tzhenrong[i].mem_type = EZFMT_NONE;
			m_tzhenrong[i].mem_id = 0;
			break;
		}
	}
	
	if(!isLeader)
	{
		ShareUserPtr head = SingletonOnlineUser::instance().GetUserByRoleId(m_members[0]);
		CUser *pHead = head.get();
		if(pHead != NULL)
		{
			vector<SZhenFaMemData> userZhenFa;
			pHead->GetCurrentZhenFaData(userZhenFa);

			uint16 petList[MAX_TEAM_MEMBER] = {0};
			uint8 petNum = 0;
			for(uint8 i=0;i < userZhenFa.size();i++)
			{
				if(userZhenFa[i].mem_type != EZFMT_PET)
					continue;
				bool inTeam = false;
				for(uint8 j=0;j < size;j++)
				{
					if(m_tzhenrong[j].mem_type == EZFMT_PET && m_tzhenrong[j].mem_id == userZhenFa[i].mem_id)
					{
						inTeam = true;
						break;
					}
				}
				
				if(!inTeam)
				{
					petList[petNum++] = userZhenFa[i].mem_id;
				}
			}
			
			for(uint8 i=0,j=0;i < size && j < petNum;i++)
			{
				if(m_tzhenrong[i].mem_type == EZFMT_NONE)
				{
					m_tzhenrong[i].mem_type = EZFMT_PET;
					m_tzhenrong[i].mem_id = petList[j++];
				}
			}
		}
	}
}

bool CUserTeam::SetNewHead(CUser *pUser)
{
	bool res = false;
	uint8 newHeadState = LTS_InTeam;
	for (uint8 i = 1; i < MAX_TEAM_MEMBER; i++)
	{
		if(m_members[i] == pUser->GetRoleId())
		{
			newHeadState = m_leaveFlag[i];
			m_leaveFlag[i] = LTS_InTeam;
			m_headName = pUser->GetName();
//			m_headXiang = pUser->GetXiang();
			m_headLevel = pUser->GetLevel();
			m_useZhenFaId = pUser->GetUseZhenFaId();
			std::swap(m_members[0], m_members[i]);
			std::swap(m_leaveFlag[0], m_leaveFlag[i]);
			res = true;
			break;
		}
	}
	if(newHeadState == LTS_LeaveTeam)
	{
		for (uint8 i = 1; i < MAX_TEAM_MEMBER; i++)
		{
			if(m_members[i] > 0)
				m_leaveFlag[i] = LTS_LeaveTeam;
		}
	}
	
	if(res)
	{
		ReSetTeamZhenRong();
	}
	return res;
}

uint8 CUserTeam::MakeUserInfo(CNetMessage &msg,uint8 zhenrongIdx,uint8 memberIdx)
{
	if(zhenrongIdx >= m_tzhenrong.size() || (memberIdx >= (uint8)MAX_TEAM_MEMBER && memberIdx != 0xff))
		return 0;

	uint32 memId = 0;
	if(m_tzhenrong[zhenrongIdx].mem_type == EZFMT_USER)	// 队伍内
	{
		memId = m_tzhenrong[zhenrongIdx].mem_id;
		if(memId == 0xff)
			return 0;
		memberIdx = 0xff;
		for(int j=0;j < MAX_TEAM_MEMBER;j++)
		{
			if(m_members[j] == memId)
			{
				memberIdx = j;
				break;
			}
		}
		if(memberIdx == 0xff)
			return 0;
	}
	else	// 暂离
	{
		if(memberIdx == 0xff)
			return 0;
		memId = m_members[memberIdx];
		if(memId == 0)
			return 0;
	}

	ShareUserPtr p = SingletonOnlineUser::instance().GetUserByRoleId(memId);
	CUser *pU = p.get();
	if(pU == NULL)
		return 0;
	uint8 isLeader = (memId == m_members[0]) ? 1 : 0;
	msg<<(uint8)EZFMT_USER<<(uint8)(zhenrongIdx+1)<<m_tzhenrong[zhenrongIdx].fightPos;
	msg<<isLeader<<pU->GetRoleId()<<GetServerZone(pU->GetServerId())<<pU->GetServerId();
	msg<<m_leaveFlag[memberIdx]<<pU->GetName()<<pU->GetLevel()<<pU->GetHead()<<pU->GetSex();
	msg<<pU->GetZhanDouLi();
	pU->GetUseTitleMsg(msg);
	msg<<pU->GetTransFormMonsterID(pU->GetCurTransFormID());
	return 1;
}

uint8 CUserTeam::MakePetInfo(CNetMessage &msg,uint8 zhenrongIdx)
{
	if(zhenrongIdx >= m_tzhenrong.size())
		return 0;
	if(m_tzhenrong[zhenrongIdx].mem_type != EZFMT_PET)
		return 0;

	uint16 petId = m_tzhenrong[zhenrongIdx].mem_id;
	if(petId == 0)
		return 0;
	
	ShareUserPtr head = SingletonOnlineUser::instance().GetUserByRoleId(m_members[0]);
	CUser *pHead = head.get();
	if(pHead == NULL)
		return 0;
	SharePetPtr pet = pHead->GetPet(petId);
	SPet *pPet = pet.get();
	if(pPet == NULL)
		return 0;
	
	msg<<m_tzhenrong[zhenrongIdx].mem_type<<(uint8)(zhenrongIdx+1)<<m_tzhenrong[zhenrongIdx].fightPos;
	msg<<(uint32)pPet->id<<pPet->name<<pPet->level<<pPet->star<<pPet->breakLevel<<pPet->GetZhanDouLi();
	return 1;
}

void CUserTeam::MakeAllMemberInfo(CNetMessage &msg)
{
	msg<<m_useZhenFaId;
	
	COnlineUser &m_onlineUser = SingletonOnlineUser::instance();
	if(m_members[0] == 0)
	{
		msg<<(uint8)0;
		return;
	}
	ShareUserPtr head = m_onlineUser.GetUserByRoleId(m_members[0]);
	CUser *pHead = head.get();
	if(pHead == NULL)
	{
		msg<<(uint8)0;
		return;
	}
	
	uint8 num = 0;
	uint16 pos = msg.GetDataLen();
	msg<<num;
	for(uint8 i=0;i < m_tzhenrong.size();i++)
	{
		if(m_tzhenrong[i].mem_type == EZFMT_USER)
			num += MakeUserInfo(msg,i);
		else if(m_tzhenrong[i].mem_type == EZFMT_PET)
			num += MakePetInfo(msg,i);
	}

	for(uint8 i=0,zrIdx=0;i < (uint8)MAX_TEAM_MEMBER && zrIdx < (uint8)MAX_TEAM_MEMBER;i++)
	{
		if(m_members[i] > 0 && m_leaveFlag[i] == 0)	// 暂离
		{
			bool isfind = false;
			for(uint8 j=zrIdx;j < m_tzhenrong.size();j++)
			{
				if(m_tzhenrong[j].mem_type != EZFMT_USER)
				{
					zrIdx = j;
					isfind = true;
					break;
				}
			}
			if(isfind)
			{
				num += MakeUserInfo(msg,zrIdx,i);
				zrIdx++;
			}
		}
	}
	msg.WriteData(pos,&num,sizeof(num));
}

//////////////////////////////////////////////////////////////////////////

CScene::CScene(CScene &scene): m_socketServer(SingletonSocket::instance())
		, m_onlineUser(SingletonOnlineUser::instance())
		, m_fightManager(SingletonFightManager::instance())
{
	m_id = scene.m_id;
	m_mapId = scene.m_mapId;
	m_name = scene.m_name;
	m_npcList = scene.m_npcList;
	m_curVisibleId = 0;
	//m_userList = scene.m_userList;

	memcpy(m_monsters, scene.m_monsters, sizeof(m_monsters));
	m_monsterNum = scene.m_monsterNum;

	m_canWalkPos = scene.m_canWalkPos;

	m_pScript = scene.m_pScript;
	m_killMonsterNum = 0;
	m_dieCount = 0;
	m_addJump = false;
	m_state = 0;
	m_usedFuBen = false;
	m_groupId = scene.m_groupId;
	Init();
	m_fightType = scene.m_fightType;
	m_x = scene.m_x;
	m_y = scene.m_y;
	m_jumpList = scene.m_jumpList;
	m_canWalkPosHash = scene.m_canWalkPosHash;
	GYQX_BossShow = false;
	m_width = scene.m_width;
	m_height = scene.m_height;
	m_monsterBossIdIndex = scene.m_monsterBossIdIndex;
	m_visibleMonstersBoss = scene.m_visibleMonstersBoss;
	m_MonsterList = scene.m_MonsterList;
	m_srcSceneId = scene.m_srcSceneId;
	m_specialRewardPos = 0;
	m_specialRewardIdx = 0;
	m_fbStep = 0;
	m_NPCMonSterIndex = scene.m_NPCMonSterIndex;
	m_emptyTime = 0;
	m_dropItemTime = 0;
	m_petCopyDifficulty = scene.m_petCopyDifficulty;
	m_petCopyUserDie = false;
	m_world_trans_type = scene.m_world_trans_type;
}

bool CScene::HaveNpc(uint16 x, uint16 y)
{
	CNpcManager &npcManager = SingletonNpcManager::instance();
	for (list<uint16>::iterator i = m_npcList.begin(); i != m_npcList.end(); i++)
	{
		SNpcInstance *pNpc = npcManager.GetNpcInstance(*i);
		if ((pNpc != NULL) && (pNpc->x == x) && (pNpc->y == y))
		{
			return true;
		}
	}
	return false;
}

bool CScene::HaveNpc(uint16 id)
{
	for (list<uint16>::iterator i = m_npcList.begin(); i != m_npcList.end(); i++)
	{
		if (*i == id)
			return true;
	}
	return false;
}

CScene::CScene(uint16 id, uint16 mapId, const char *name, char *monsters,int mapFile)
		: m_id(id), m_mapId(mapId), m_name(name), m_userTeams(100)
//		, m_canWalkPosHash(1024)
		, m_socketServer(SingletonSocket::instance())
		, m_onlineUser(SingletonOnlineUser::instance())
		, m_fightManager(SingletonFightManager::instance())
{
	m_canWalkPosHash = new CHashTable<int,bool>;
	m_srcSceneId = m_id;
	m_nextFuBenId = 0;
	m_prevFuBenId = 0;
	nextMapid = 0;
	fubenindex = 0;
	m_isPaiMing = false;
	m_matchBegin = time(NULL);
	m_groupId = m_id;
	m_curVisibleId = 0;
	m_specialRewardPos = 0;
	m_specialRewardIdx = 0;
	m_fbStep = 0;
	m_emptyTime = 0;
	m_dropItemTime = 0;
	m_petCopyDifficulty = 0;
	m_visibleRobotId = 0;
	m_world_trans_type = 0;
	m_petCopyUserDie = false;
	GYQX_BossShow = false;
	char *monster[MAX_MONSTER_NUM];
	if (monsters != NULL)
	{
		m_monsterNum = SplitLine(monster, MAX_MONSTER_NUM, monsters);
		for (uint8 i = 0; i < m_monsterNum; i++)
		{
			m_monsters[i] = (uint16)atoi(monster[i]);
		}
	}
	else
	{
		m_monsterNum = 0;
	}

	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	format fmt("select from_x,from_y,to_scene,to_x,to_y,face from jump_point where from_scene=%1%");
	fmt % (int)m_id;
	if ((pDb != NULL) && (pDb->Query(fmt.str().c_str())))
	{
		char **row;
		while ((row = pDb->GetRow()) != NULL)
		{
			uint16 fromX = (uint16)atoi(row[0]);
			uint16 fromY = (uint16)atoi(row[1]);
			SJumpTo *pJump = new SJumpTo;
			pJump->sceneId = (uint16)atoi(row[2]);
			pJump->x = (uint16)atoi(row[3]);
			pJump->y = (uint16)atoi(row[4]);
			pJump->face = (uint8)atoi(row[5]);
			InsertJumpPoint(fromX, fromY, pJump);
		}
	}

	CNpcManager &npcManager = SingletonNpcManager::instance();
	npcManager.GetSceneNpc(id, &m_npcList);

	m_pScript = NULL;
	char fileName[32];
	snprintf(fileName,sizeof(fileName),"%d.lua", m_id + 10000);
	if (access(fileName, R_OK) == 0)
	{
		m_pScript = new CCallScript(m_id + 10000);
	}

	snprintf(fileName, sizeof(fileName), "dat/map%d.map", mapFile);

	m_addJump = false;
	m_killMonsterNum = 0;
	m_dieCount = 0;
	m_state = 0;
	m_usedFuBen = false;
	m_width = 0;
	m_height = 0;
	m_NPCMonSterIndex = 100;
	m_1V1SceneTime = 0;
	Init();

	FILE *file = fopen(fileName, "r");
	if (file == NULL)
		return;

	const int MAX_MAP_SIZE = 10240;
	uint8 buf[MAX_MAP_SIZE];
	int len = fread(buf, 1, MAX_MAP_SIZE, file);
	fclose(file);

	uint16 width,height,pos = 0;
	uint8 block,count = 8;
	memcpy(&width,&buf[pos],sizeof(width));
	pos += sizeof(width);
	memcpy(&height,&buf[pos],sizeof(height));
	pos += sizeof(height);
	
	if(height > 0xff || width > 0xff || len < height*width/8 + 4)
	{
		cout<<"read "<<fileName<<" error!"<<endl;
		return;
	}

	for(uint16 h=0;h < height;h++)
	{
		for(uint16 w=0;w < width;w++)
		{
			if(count == 8)
			{
				count = 0;
				block = buf[pos++];
			}
			if(!(block & (1<<count)))
			{
				bool res = true;
				SPoint pos;
				pos.x = w;
				pos.y = h;
				m_canWalkPos.push_back(pos);
				m_canWalkPosHash->Insert((w<<8)|h,res);
			}
			count++;
		}
	}
    m_width=width*32;
	m_height=height*32;
	
	char sql[512];
	char **row = NULL;
	const int MAX_MONSTER_POS_NUM = 20;
	snprintf(sql,sizeof(sql),"select monster_id,pos,radius,meetDistance,min_fightId,max_fightId from monster_distribution where scene_id=%d",m_id);

	m_monsterIdIndex = 1;
	if(!pDb->Query(sql))
		return;
	uint16 index = 0;

	CMonsterBossManager &bossMgr = SingletonMonsterBossManager::instance();
	while((row = pDb->GetRow()) != NULL)
	{
		char *monsterPos[MAX_MONSTER_NUM*2];
		if(row[1] == NULL || strncmp(row[1]," ",1) == 0)
			continue;
		int monsterPosNum = SplitLine(monsterPos,MAX_MONSTER_POS_NUM*2,row[1]);
		SMonsterListInfo monsterList;
		monsterList.index = index++;
		for (uint8 i = 0; i < monsterPosNum/2; i++)
		{
			SVisibleMonster VMonster;
			VMonster.id = NormalMonsterIdPos + m_monsterIdIndex;
			m_monsterIdIndex++;
			VMonster.face = (uint8)Random(0,7);
			VMonster.flag = 0;
			VMonster.type = 1;		// 暂定1
//			VMonster.restTime = GetSysTime() - Random(0,monsterMoveTimeStep);
			VMonster.monster_id = (uint16)atoi(row[0]);
			int pic = 0;
			string name;
			if(!bossMgr.GetMonsterBossInfo(VMonster.monster_id,pic,name))
				continue;
			VMonster.pic = pic;
			VMonster.name = name;
			VMonster.radius = (uint16)atoi(row[2]);
			VMonster.center_x = (uint16)atoi(monsterPos[2*i]);
			VMonster.center_y = (uint16)atoi(monsterPos[2*i+1]);
			VMonster.x = VMonster.center_x;
			VMonster.y = VMonster.center_y;
			VMonster.min_fightId = atoi(row[4]);
			VMonster.max_fightId = atoi(row[5]);
			VMonster.meetDistance = (uint16)atoi(row[3]);
			monsterList.AddMonster(VMonster);
			// A monster may legitimately stand beside blocked terrain. Movement path
			// generation already skips blocked directions, so only report positions
			// whose center is invalid or that have no walkable adjacent direction.
			uint8 walkableNeighborCount = 0;
			for(uint8 k = 0;k < 8;k++)
			{
				int nextX = (int)VMonster.center_x + Monster_Pos_x[k];
				int nextY = (int)VMonster.center_y + Monster_Pos_y[k];
				if(nextX > 0 && nextY > 0 && CanWalkPos((uint16)nextX,(uint16)nextY))
					walkableNeighborCount++;
			}
			if(!CanWalkPos(VMonster.center_x,VMonster.center_y) || walkableNeighborCount == 0)
			{
				cout<<"error monster pos:"<<VMonster.id<<","<<m_id<<","<<VMonster.center_x<<","<<VMonster.center_y<<endl;
			}
//			m_visibleMonsters.push_back(VMonster);
		}
		m_MonsterList.push_back(monsterList);
	}

	//                         0     1    2     3       4       5   6  7      8      9     10      11      12       13       14      15      16
	snprintf(sql,sizeof(sql),"select name,pos_x,pos_y,radius,meetDistance,face,pic,type,sayContent,step,fightPos1,fightPos2,fightPos3,fightPos4,fightPos5,fightPos6,dropItem,"\
	//     17   18    19    20    21   22
		"scale1,scale2,scale3,scale4,scale5,scale6 from monster_boss_distribution where sceneId=%d",m_id);
	if(!pDb->Query(sql))
		return;
	index = 0;
	m_monsterBossIdIndex = 1;
	while((row = pDb->GetRow()) != NULL)
	{
		SVisibleMonsterBoss monsterBoss;
		monsterBoss.id = NormalMonsterIdPos - m_monsterBossIdIndex;
		if(monsterBoss.id < 10000)
		{
			monsterBoss.id = NormalMonsterIdPos - 1;
			m_monsterBossIdIndex = 0;
		}
		m_monsterBossIdIndex++;
		monsterBoss.name = row[0];
		monsterBoss.center_x = (uint16)atoi(row[1]);
		monsterBoss.center_y = (uint16)atoi(row[2]);
		monsterBoss.radius = (uint16)atoi(row[3]);
		monsterBoss.meetDistance = (uint16)atoi(row[4]);
		monsterBoss.face = (uint8)atoi(row[5]);
		monsterBoss.pic = (uint16)atoi(row[6]);
		monsterBoss.type = (uint8)atoi(row[7]);
		monsterBoss.step = (uint8)atoi(row[9]);
		monsterBoss.isVisible = true;
		for(int k=0;k < 6;k++)
		{
			monsterBoss.bossId[k] = (uint16)atoi(row[10+k]);
			monsterBoss.scale[k] = (float)atof(row[17+k]);
		}
		monsterBoss.dropItems.SetDrop(row[16]);
		monsterBoss.x = monsterBoss.center_x;
		monsterBoss.y = monsterBoss.center_y;		
		m_visibleMonstersBoss.push_back(monsterBoss);
	}
	if (m_id == BP_FIGHT_SID)
	{
		ResetTowers();
	}
}

CScene::~CScene()
{
	m_userList.clear();
}

void CScene::InsertJumpPoint(uint16 x, uint16 y, SJumpTo *pJump)
{
	SJumpPoint jump;
	jump.x = x;
	jump.y = y;
	jump.pJumpTo = pJump;
	m_jumpList.push_back(jump);
}

void CScene::SendJumpPoint(CUser *pUser)
{
	CNetMessage msg;
	msg.SetType(MSG_JUMP_POINT);
	msg<<(uint8)m_jumpList.size();
	for(list<SJumpPoint>::iterator i = m_jumpList.begin(); i != m_jumpList.end(); i++)
	{
		msg<<i->x<<i->y<<i->pJumpTo->sceneId;
	}
	m_socketServer.SendMsg(pUser->GetSock(), msg);
}

// 获取当前副本队伍队长
CUser * CScene::GetCurrentFuBenTeamLeader()
{
	if (!IsFuBen())
		return NULL;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	for (list<uint32>::iterator i = m_userList.begin(); i != m_userList.end(); i++)
	{
		ShareUserPtr p = onlineUser.GetUserByRoleId(*i);
		if (p.get() != NULL)
		{
			if (p->GetTeam() == p->GetRoleId())
			{
				return p.get();
			}
		}
	}
	return NULL;
}

bool CScene::CheckPos(uint16 x,uint16 y)
{
	if(x >= m_width || y >= m_height)
		return false;
	return true;
}

bool CScene::GetJumpPoint(uint16 x, uint16 y, SJumpTo *&pJump)
{
	const int distance = 50;
	for(list<SJumpPoint>::iterator i = m_jumpList.begin();i != m_jumpList.end();i++)
	{
		int dx = (int)(i->x - x);
		int dy = (int)(i->y - y);
		if(dx*dx + dy*dy <= distance*distance)
		{
			pJump = i->pJumpTo;
			return true;
		}
	}

	if(m_addJump)
	{
		int dx = (int)(m_jumpPoint.x - x);
		int dy = (int)(m_jumpPoint.y - y);
		if(dx*dx + dy*dy <= distance*distance)
		{
			pJump = &m_jumpToPoint;
			return true;
		}
	}
	return false;
}

static void TeamMemberMove(ShareUserPtr ptr, uint16 x, uint16 y, uint8 face)
{
	ptr->SetPos(x, y);
	ptr->SetFace(face);
}

void CScene::MonsterMove()
{
	boost::recursive_mutex::scoped_lock lk1(m_mutex);
	boost::recursive_mutex::scoped_lock lk(m_monster_mutex);
	for(list<SMonsterListInfo>::iterator i = m_MonsterList.begin();i != m_MonsterList.end();i++)
	{
		if(i->monsterList.size() == 0)
			continue;
		int r = Random(0,(int)i->monsterList.size()-1);
		int count = 0;
		list<SVisibleMonster>::iterator t = i->monsterList.begin();
		while(count != r)
		{
			t++;
			count++;
		}
		if(t->path.size() == 0)
		{
			t->pathIndex = 0;
			CreateMonsterMovePath(t->path,t->x,t->y,t->center_x,t->center_y,t->radius);
		}
		SendMonsterMove(*t);
	}

	if(m_visibleMonstersBoss.size() > 0)
	{
		int count = 0;
		int r = Random(0,(int)m_visibleMonstersBoss.size()-1);
		list<SVisibleMonsterBoss>::iterator t = m_visibleMonstersBoss.begin();
		while(count != r)
		{
			t++;
			count++;
		}
		if(t->isVisible && t->radius != 0)
		{
			if(t->path.size() == 0)
			{
				t->pathIndex = 0;
				CreateMonsterMovePath(t->path,t->x,t->y,t->center_x,t->center_y,t->radius);
			}
			SendMonsterBossMove(*t);
		}
	}
}

void CScene::SendMonsterMove(SVisibleMonster &monster)
{
	if(monster.pathIndex >= monster.path.size())
	{
		monster.path.clear();
		monster.pathIndex = 0;
		monster.restTime = GetSysTime();
		return;
	}

	monster.x += Monster_Pos_x[monster.path[monster.pathIndex]];
	monster.y += Monster_Pos_y[monster.path[monster.pathIndex]];
	monster.face = monster.path[monster.pathIndex];
	monster.pathIndex++;
	
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_MONSTER_MOVE);
	msg << monster.id << monster.x << monster.y;
	BroadcastMsg(msg);

	uint32 roleId = 0;
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	{
		for (list<uint32>::iterator iter = m_userList.begin(); iter != m_userList.end(); iter++)
		{
			ShareUserPtr pU = onlineUser.GetUserByRoleId(*iter);
			if(pU.get() != NULL)
			{
				int dx = pU->GetX() - monster.x;
				int dy = pU->GetY() - monster.y;
				if(dx*dx + dy*dy < monster.meetDistance * monster.meetDistance)
				{
					roleId= *iter;
					break;
				}
			}
		}
	}
	if(roleId != 0)
	{
		ShareUserPtr p = onlineUser.GetUserByRoleId(roleId);
		if(p.get() != NULL && p->GetFightId() == 0 && p->CanMeetEnemy())
			MeetEnemy(p);
	}
}

void CScene::SendMonsterBossMove(SVisibleMonsterBoss &monster)
{
	const int distance = 30;
	if(monster.pathIndex >= monster.path.size())
	{
		monster.path.clear();
		monster.pathIndex = 0;
		monster.restTime = GetSysTime();
		return;
	}

	monster.x += Monster_Pos_x[monster.path[monster.pathIndex]];
	monster.y += Monster_Pos_y[monster.path[monster.pathIndex]];
	monster.face = monster.path[monster.pathIndex];
	monster.pathIndex++;
	
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_MONSTER_MOVE);
	msg << monster.id << monster.x << monster.y;
	BroadcastMsg(msg);

	uint32 roleId = 0;
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		for (list<uint32>::iterator iter = m_userList.begin(); iter != m_userList.end(); iter++)
		{
			ShareUserPtr pU = onlineUser.GetUserByRoleId(*iter);
			if(pU.get() != NULL)
			{
				int dx = pU->GetX() - monster.x;
				int dy = pU->GetY() - monster.y;
				if(dx*dx + dy*dy < distance*distance)
				{
					roleId= *iter;
					break;
				}
			}
		}
	}
	if(roleId != 0)
	{
		ShareUserPtr p = onlineUser.GetUserByRoleId(roleId);
		if(p.get() != NULL && p->GetFightId() == 0 && (p->GetTeam() > 0 && p->GetTeam() == roleId) && p->CanMeetEnemy())
		{
			if(p->GetKuaFuState() != EKFS_IN_LOCAL)
				return;
			MeetEnemy(p);
		}
	}
}

void CScene::CreateMonsterMovePath(vector<uint8> &path,int x,int y,int center_x,int center_y,int radius)
{
	uint8 face[8] = {0};
	uint8 count = 0;
	uint8 step = (uint8)Random(1,2);

//	monster.pathIndex = 0;
	path.clear();
	for(uint8 j=0;j < step;j++)
	{
		count = 0;
		for(uint8 i = 0;i < 8;i++)
		{
			int dx = x + Monster_Pos_x[i] - center_x;
			int dy = y + Monster_Pos_y[i] - center_y;
			if(x + Monster_Pos_x[i] < 0 || y + Monster_Pos_y[i] < 0)
				continue;
			if(CanWalkPos(x+Monster_Pos_x[i],y+Monster_Pos_y[i]) && dx*dx + dy*dy <= radius*radius)
			{
				face[count++] = i;
			}
		}
		if(count == 0)
			continue;
		uint8 tface = face[Random(0,count-1)];
		path.push_back(tface);
		x += Monster_Pos_x[tface];
		y += Monster_Pos_y[tface];
	}
}

bool CScene::CanWalkPos(uint16 x,uint16 y)
{
	if(x > m_width || y > m_height || x == 0 || y == 0)
		return false;
	uint16 cellx = x/32;
	uint16 celly = y/32;
	bool res = false;
	m_canWalkPosHash->Find((cellx<<8)|celly,res);
	return res;
}

bool CScene::GetCanWalkPos(uint16 &x, uint16 &y)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(m_canWalkPos.empty())
		return false;
	for(int i=0;i < 10;i++)
	{
		uint32 walkPosNum = Random(0, m_canWalkPos.size() - 1);
		if(walkPosNum >= m_canWalkPos.size())
			return false;
		SPoint pos = m_canWalkPos[walkPosNum];
		x = pos.x*32;
		y = pos.y*32;
		if(x >= m_width || y >= m_height)
			continue;
		return true;
	}
	return false;
}

bool CScene::GetCanWalkPos_NoLock(uint16 &x, uint16 &y)
{
	if (m_canWalkPos.empty())
		return false;
	uint32 walkPosNum = Random(0, m_canWalkPos.size() - 1);
	if (walkPosNum >= m_canWalkPos.size())
		return false;
	SPoint pos = m_canWalkPos[walkPosNum];
	x = pos.x*32;
	y = pos.y*32;
	return true;
}

void CScene::UserMove(CUser *pUser, uint16 x, uint16 y)
{
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(PRO_ROLE_MOVE);
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	msg << pUser->GetRoleId() << x << y;
	BroadcastMsgExcept(msg, pUser);

	if (pUser->GetTeam() == pUser->GetRoleId())
	{
		ForEachTeamMember(pUser->GetTeam(),boost::bind(TeamMemberMove, _1, pUser->GetX(), pUser->GetY(), pUser->GetFace()));
	}
}

void CScene::NolockUpdateUserInfo(CUser *pUser,uint8 uType)
{
	if(pUser == NULL)
		return;
	CNetMessage msg;
	CSocketServer &sock = SingletonSocket::instance();
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	
	list<uint32>::iterator iter = m_userList.begin();
	for (; iter != m_userList.end(); iter++)
	{
		ShareUserPtr p = onlineUser.GetUserByRoleId(*iter);
		CUser *pU = p.get();
		if ((pU != NULL) && (pU->GetRoleId() != pUser->GetRoleId()))
		{
			msg.ReWrite();
			msg.SetType(PRO_UPDATE_PLAYER);
			pUser->MakeUpdateInfo(msg, pU,uType);
			sock.SendMsg(pU->GetSock(), msg);
		}
	}
}

void CScene::UpdateUserInfo(CUser *pUser,uint8 uType)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	NolockUpdateUserInfo(pUser,uType);
}

void CScene::Exit(CUser *pUser)
{
	if(pUser == NULL)
		return;
	
	//LeaveTeam(pUser);
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_userList.remove(pUser->GetRoleId());
	if(m_srcSceneId == FEI_XIAN_SID5)
	{
		if(pUser->GetFeiXianState() > 0)
		{
			pUser->SetFeiXianState(0);
			pUser->UpdateFeiXianData();
			if(!m_userList.empty())
			{
				for(list<uint32>::iterator i=m_userList.begin();i != m_userList.end();i++)
				{
					ShareUserPtr p = m_onlineUser.GetUserByRoleId(*i);
					if(p.get() != NULL)
					{
						p->SetFeiXianState(1);
						p->UpdateFeiXianData();
						NolockUpdateUserInfo(p.get(),ESRT_State);
						break;
					}
				}
			}
		}
	}

	if ((pUser->GetTeam() == 0) || (pUser->GetTeam() == pUser->GetRoleId()))
	{
		CNetMessage msg;
		msg.SetType(PRO_IN_OUT_SCENE);
		//								出场景
		msg << pUser->GetRoleId() << (uint8)0;
		BroadcastMsgExceptSameTeam(pUser, msg);
	}
}

CSceneManager::CSceneManager():m_curFuBenId(time(NULL)),m_isInit(false),
	m_npcManager(SingletonNpcManager::instance())
{
	m_matchRunTime = 0;
	weekday = GetWeekDay();
	m_kunLunShanSceneNum = 0;
	m_kunLunShanTeamSceneNum = 0;
	m_shenjiemijingSceneNum = 0;
}

bool CSceneManager::Init()
{
	if (m_isInit)
		return true;
	if (!m_npcManager.Init())
		return false;

	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	//             0   1     2     3       4        5    6 7    8       9     10   11      12
#ifndef KUA_FU
	string sql("select id,name,map_id,monster,fight_type,fight_step,x,y,pai_ming,group_id,width,height,world_trans from game_scene where show_type in(1,3)");
#else
	string sql("select id,name,map_id,monster,fight_type,fight_step,x,y,pai_ming,group_id,width,height,world_trans from game_scene where show_type in(2,3)");
#endif
	if ((pDb != NULL) && (pDb->Query(sql.c_str())))
	{
		char **row;
		while ((row = pDb->GetRow()) != NULL)
		{
			CScene *pScene = new CScene(atoi(row[0]), atoi(row[2]), row[1], row[3],atoi(row[2]));
			pScene->SetFightType(atoi(row[4]));
			pScene->SetFightStep(atoi(row[5]));
			pScene->SetX(atoi(row[6]));
			pScene->SetY(atoi(row[7]));
			pScene->SetGroupId(atoi(row[9]));
			pScene->SetWidth(atoi(row[10]));
			pScene->SetHeight(atoi(row[11]));
			pScene->SetWorldTransType(atoi(row[12]));
			m_sceneList.Insert(pScene->GetId(), pScene);
		}
	}
	else
	{
		return false;
	}

	scenes baihuaMap;
	baihuaMap.insert(2);
	baihuaMap.insert(3);
	m_huodongMaps.insert(make_pair(SOT_Baihua, baihuaMap));

	scenes nianshouMap;
	nianshouMap.insert(2);
	nianshouMap.insert(3);
	m_huodongMaps.insert(make_pair(SOT_Nianshou, nianshouMap));
	return true;
}


CSceneManager::~CSceneManager()
{

}

CScene *CSceneManager::FindScene(int id)
{
	CScene *pScene = NULL;
	boost::mutex::scoped_lock lk(m_bpMutex);
	m_sceneList.Find(id, pScene);
	return pScene;
}

bool CScene::CreateTeam(CUser *pUser, uint32 request)
{
	CNetMessage msg;
//	msg.SetType(PRO_USER_TEAM);

	uint32 teamId = pUser->GetTeam();
	if(teamId == 0)
		teamId = pUser->TempLeaveTeam();
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	CUserTeam *pTeam = NULL;
	if(teamId != 0)
	{
		m_userTeams.Find(teamId, pTeam);
		if(pTeam == NULL)
			return true;
	}
	else	// 没有队伍则创建队伍
	{
		pTeam = new CUserTeam;
		m_userTeams.Insert(pUser->GetRoleId(), pTeam);

		pTeam->Join(pUser->GetRoleId());
		pUser->SetTeam(pUser->GetRoleId());
		teamId = pUser->GetRoleId();

		msg.ReWrite();
		msg.SetType(PRO_USER_TEAM);
		msg<<(uint8)1<<PRO_SUCCESS;
		m_socketServer.SendMsg(pUser->GetSock(), msg);

//		pTeam->UpdateTeamData();

		msg.ReWrite();
		msg.SetType(PRO_UPDATE_TEAM);
		msg << (uint8)1 << pUser->GetRoleId();
		BroadcastMsg(msg);

		pTeam->SendTeamFaBuData();
	}
	
	if(request != 0)		// 邀请入队
	{
//		if(teamId != pUser->GetRoleId())
//		{
//			SendSysInfo(pUser, MakeStringColor(LANGUAGE_TRANSFORM_2606,TIPS_FAILURE_COLOR).c_str());
//			return true;
//		}
		if(pTeam->GetMemberNum() + pTeam->GetLeaveNum() >= MAX_TEAM_MEMBER)
		{
			SendSysInfo(pUser, MakeStringColor(LANGUAGE_TRANSFORM_2607,TIPS_FAILURE_COLOR).c_str());
			return true;
		}

		/*
		+----+-----+-----+------+-------+-------+
		| OP | CID | LEN | NAME | XIANG | LEVEL |
		+----+-----+-----+------+-------+-------+
		|  1 |  4  |  2  |  Var |   1   |   1   |
		+----+-----+-----+------+-------+-------+
		*/
		int openLevel = sSystemOpenCfgMananger.GetFuncOpenLevel(SOT_Team);
		ShareUserPtr p = m_onlineUser.GetUserByRoleId(request);
		if(p.get() != NULL)
		{
			if(p->GetLevel() < openLevel)
			{
				char buf[128];
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_2608, openLevel);
				SendSysInfo(pUser, MakeStringColor(buf,TIPS_FAILURE_COLOR).c_str());
				return true;
			}
			if(p->InHuSongMission() == 1)
			{
				SendSysInfo(pUser, MakeStringColor(LANGUAGE_TRANSFORM_2609,TIPS_FAILURE_COLOR).c_str());
				return true;
			}
			else if(p->InHuSongMission() == 2)
			{
				SendSysInfo(pUser, MakeStringColor(LANGUAGE_TRANSFORM_2610,TIPS_FAILURE_COLOR).c_str());
				return true;
			}
			
			if(p->GetTeam() == 0)
			{
				if(p->TempLeaveTeam() != 0)
				{
					if (p->TempLeaveTeam() == pUser->GetTeam())
					{
						SendSysInfo(pUser, MakeStringColor(LANGUAGE_TRANSFORM_2611,TIPS_FAILURE_COLOR).c_str());
						
						msg.ReWrite();
						msg.SetType(PRO_USER_TEAM);
						msg << (uint8)14 << pUser->GetRoleId() << pUser->GetName() << pUser->GetHead() << pUser->GetLevel();
						m_socketServer.SendMsg(p->GetSock(), msg);
					}
					else
					{
						SendSysInfo(pUser, MakeStringColor(LANGUAGE_TRANSFORM_2612,TIPS_FAILURE_COLOR).c_str());
					}
					return true;
				}

//				pTeam->AddRequestList(request);
				if(p->FindAskForJoinTeam(teamId))
				{
					char buf[128];
					snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0116);
					SendSysInfo(pUser, MakeStringColor(buf,TIPS_FAILURE_COLOR).c_str());
					return true;
				}
				else
				{
#ifdef KUA_FU
					if( GetSrcSceneId() == SHENJIEMIJING_SCENE_ID || p->GetScene()->GetSrcSceneId() == SHENJIEMIJING_SCENE_ID)
					{
						if( GetServerZone(pUser->GetServerId()) != GetServerZone(p->GetServerId()))
						{
							SendInfoToMe( pUser,TIPS_FAILURE_COLOR,LANGUAGE_CHY_72);
							return false;
						}
					}
#endif
					p->AddAskForJoinTeam(teamId);
					pTeam->AddRequestList(p->GetRoleId());
					msg.ReWrite();
					msg.SetType(PRO_USER_TEAM);
					string roleName = pUser->GetName();
					msg << (uint8)6 << pUser->GetRoleId() << roleName << pUser->GetHead() << pUser->GetSex() << (uint16)pUser->GetLevel() << pUser->GetZhanDouLi();
					m_socketServer.SendMsg(p->GetSock(), msg);
					char buf[128];
					snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_2613, p->GetName());
					SendSysInfo(pUser, MakeStringColor(buf, TIPS_WARNING_COLOR).c_str());
				}
			}
			else
			{
				SendSysInfo(pUser, MakeStringColor(LANGUAGE_TRANSFORM_2614,TIPS_FAILURE_COLOR).c_str());
			}
		}
		else
		{
			SendSysInfo(pUser, MakeStringColor(LANGUAGE_ZQX_0117, TIPS_FAILURE_COLOR).c_str());
		}
	}

	return true;
}

void CScene::RefuseJoinTeam(CUser *pUser, uint32 headId)
{
	if(pUser == NULL)
		return;
	CNetMessage msg;
	msg.SetType(PRO_USER_TEAM);
	msg<<(uint8)19;
	
	ShareUserPtr p = m_onlineUser.GetUserByRoleId(headId);
	CUser *pHead = p.get();
	if(pHead == NULL)
	{
		pUser->DelAskForJoinTeam(headId);
		msg<<PRO_ERROR<<headId;
		m_socketServer.SendMsg(pUser->GetSock(),msg);
		return;
	}
	CScene *pScene = pHead->GetScene();
	if(pScene == NULL)
		return;
	if(pScene == this)
	{
		pUser->DelAskForJoinTeam(headId);
		if(pHead->GetTeam() == 0)
		{
			msg<<PRO_ERROR<<headId;
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}

		boost::recursive_mutex::scoped_lock lk(m_mutex);
		CUserTeam *pTeam = NULL;
		if(!m_userTeams.Find(headId, pTeam))
		{
			msg<<PRO_ERROR<<headId;
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(pTeam == NULL)
		{
			msg<<PRO_ERROR<<headId;
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		pTeam->DelAskForJoinTeam(pUser->GetRoleId());
		pTeam->DelRequest(pUser->GetRoleId());

		char buff[128];
		snprintf(buff,sizeof(buff),LANGUAGE_TRANSFORM_2615,pUser->GetName());
		SendSysInfo(pHead,MakeStringColor(buff,TIPS_FAILURE_COLOR).c_str());
	}
	else
	{
		pScene->RefuseJoinTeam(pUser,headId);
	}
}

void CScene::UpdateTeamMemberLevel(uint32 teamId,uint32 roleId)
{
	if(teamId == 0 || roleId == 0)
		return;
	ShareUserPtr ptr = m_onlineUser.GetUserByRoleId(roleId);
	if(ptr.get() == NULL)
		return;
	uint16 level = ptr->GetLevel();
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	CUserTeam *pTeam = NULL;
	if(!m_userTeams.Find(teamId, pTeam))
		return;
	return pTeam->UpdateMemberLevel(roleId,level);
}

bool CScene::IsInTeamRequest(CUser *pLeader,uint32 askForJoinId)
{
	if(pLeader == NULL)
		return false;
	if(pLeader->GetTeam() == 0 || pLeader->GetTeam() != pLeader->GetRoleId())
		return false;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	CUserTeam *pTeam = NULL;
	if(!m_userTeams.Find(pLeader->GetRoleId(), pTeam))
		return false;
	return pTeam->InRequest(askForJoinId);
}

// type=0 申请入队, 1 同意入队邀请
void CScene::AskForJoinTeam(CUser *pUser, uint32 headId,uint8 type)
{
	if(pUser->GetKuaFuState() != EKFS_IN_LOCAL)
		return;
	if(pUser->GetFightId() != 0)
		return;

	if(pUser->GetTeam() == 0 && pUser->TempLeaveTeam() == 0)
	{
		CNetMessage msg;
		msg.SetType(PRO_USER_TEAM);
		pUser->DelAskForJoinTeam(headId);

		ShareUserPtr pTar = m_onlineUser.GetUserByRoleId(headId);
		if(pTar.get() == NULL)
		{
			SendSysInfo(pUser, MakeStringColor(LANGUAGE_ZQX_0117, TIPS_FAILURE_COLOR).c_str());
			return;
		}
		if(pTar->GetTeam() == 0 && pTar->TempLeaveTeam() > 0)
		{
			if(type == 0)
				SendSysInfo(pUser, MakeStringColor(LANGUAGE_TRANSFORM_2618,TIPS_FAILURE_COLOR).c_str());
			else
				SendSysInfo(pUser, MakeStringColor(LANGUAGE_TRANSFORM_2619,TIPS_FAILURE_COLOR).c_str());
			return;
		}

		uint32 teamId = pTar->GetTeam();
		if(teamId == 0)
			teamId = pTar->TempLeaveTeam();
		if(teamId == 0)
		{
			if(type == 0)
				SendSysInfo(pUser, MakeStringColor(LANGUAGE_TRANSFORM_2620,TIPS_FAILURE_COLOR).c_str());
			else
				SendSysInfo(pUser, MakeStringColor(LANGUAGE_TRANSFORM_2621,TIPS_FAILURE_COLOR).c_str());
			return;
		}
		
		CScene *pHScene = pTar->GetScene();
		if(pHScene == NULL)
			return;
#ifdef KUA_FU
		if( GetSrcSceneId() == SHENJIEMIJING_SCENE_ID || pHScene->GetSrcSceneId() == SHENJIEMIJING_SCENE_ID)
		{
			if( GetServerZone(pUser->GetServerId())!= GetServerZone(pTar->GetServerId()))
			{
				SendInfoToMe( pUser,TIPS_FAILURE_COLOR,LANGUAGE_CHY_72);
				return;
			}
		}
#endif
		if(pHScene == this)
		{
			boost::recursive_mutex::scoped_lock lk(m_mutex);
			CUserTeam *pTeam = NULL;
			if(!m_userTeams.Find(teamId, pTeam))
			{
				if(type == 0)
					SendSysInfo(pUser, MakeStringColor(LANGUAGE_TRANSFORM_2622,TIPS_FAILURE_COLOR).c_str());
				else
					SendSysInfo(pUser, MakeStringColor(LANGUAGE_TRANSFORM_2623,TIPS_FAILURE_COLOR).c_str());
				return;
			}
			if(pTeam->GetMemberNum() + pTeam->GetLeaveNum() >= MAX_TEAM_MEMBER)
			{
				if(type == 0)
					SendSysInfo(pUser, MakeStringColor(LANGUAGE_TRANSFORM_2624,TIPS_FAILURE_COLOR).c_str());
				else
					SendSysInfo(pUser, MakeStringColor(LANGUAGE_TRANSFORM_2625,TIPS_FAILURE_COLOR).c_str());
				return;
			}

			if(pTeam->InRequest(pUser->GetRoleId()))  //队长邀请
			{
				ShareUserPtr pHead = m_onlineUser.GetUserByRoleId(teamId);
				if(pHead.get() == NULL)
					return;
				string strNotice;
				if(!CanJoinTeamInBangPaiScene(pHead.get(),pUser,strNotice))
				{
					pTeam->DelRequest(pUser->GetRoleId());
					SendSysInfo(pUser, MakeStringColor(strNotice,TIPS_FAILURE_COLOR).c_str());
					return;
				}

				pTeam->DelRequest(pUser->GetRoleId());
				pTeam->Join(pUser->GetRoleId());
				pTeam->SendJoinTeamMemberData(pUser->GetRoleId(),pUser->GetRoleId());
				pTeam->UpdateTeamData();
				if(pTeam->GetMemberNum() + pTeam->GetLeaveNum() >= MAX_TEAM_MEMBER)
				{
					SingletonTeamFaBuCfgMgr::instance().RemoveFaBuTeam(pTeam->GetType(),pTeam->GetHeadId());
					pTeam->SendTeamFaBuData();
				}
				else
				{
					pTeam->SendTeamFaBuData(pUser->GetRoleId());
				}
				
				string str = pUser->GetName();
				str += LANGUAGE_TRANSFORM_2626;

				if(pHead->HaveCMission(MISSION_ID_ZhuoGui))
				{
					vector<int> ints;
					vector<string> strs;
					pHead->GetCMissionInts(MISSION_ID_ZhuoGui,ints);
					pHead->GetCMissionStrs(MISSION_ID_ZhuoGui,strs);
					
					if(pUser->HaveCMission(MISSION_ID_ZhuoGui))
					{
						vector<int> srcInts;
						pUser->GetCMissionInts(MISSION_ID_ZhuoGui,srcInts);
						ints[0] = srcInts[0];
						pUser->UpdateCMission(MISSION_ID_ZhuoGui,ints,strs);
					}
					else
					{
						int cutTimes = pUser->GetExtData16(50);
						if (cutTimes < MAX_ZHUAIGUI_LIMIT)
						{
							ints[0] = pUser->GetExtData16(50) % 30;
							pUser->AcceptCMission(MISSION_ID_ZhuoGui, ints, strs);
						}
					}
				}

				SendSysInfo(pHead.get(), MakeStringColor(str.c_str(),TIPS_WARNING_COLOR).c_str());
				SendSysInfo(pUser, MakeStringColor(str.c_str(),TIPS_WARNING_COLOR).c_str());

				if(pHead->GetScene() == pUser->GetScene())	// 相同场景加入队伍
				{
					pUser->SetTeam(teamId);
					pUser->SetTempLeaveTeam(0);

					uint32 members[MAX_TEAM_MEMBER];
					uint8 num = 0;
					uint16 x, y;
					pHead->GetPos(x, y);
					pUser->SetPos(x, y);

					SendTeamInfo(pTeam,pUser);
					
					msg.ReWrite();
					msg.SetType(PRO_UPDATE_TEAM);
					msg<<(uint8)2<<teamId<<pUser->GetRoleId()<<pUser->GetX()<<pUser->GetY()<<pUser->GetFace();
					BroadcastMsg(msg);

					pTeam->GetLeaveMem(members,num);
					for(uint8 i=0;i < num;i++)
					{
						ShareUserPtr pMem = m_onlineUser.GetUserByRoleId(members[i]);
						if(pMem.get() != NULL && pMem->GetScene() != this)
							m_socketServer.SendMsg(pMem->GetSock(),msg);
					}
				}
				else	// 不同场景，新进的队员设置暂离
				{
					pUser->SetTeam(0);
					pUser->SetTempLeaveTeam(teamId);
				
					msg.ReWrite();
					msg.SetType(PRO_UPDATE_TEAM);
					msg << (uint8)10 << teamId << pUser->GetRoleId() << pUser->GetX() << pUser->GetY() << pUser->GetFace();

					uint32 members[MAX_TEAM_MEMBER];
					uint8 num = 0;
					pTeam->GetAllMember(members,num);
					for(uint8 i = 0; i < num; i++)
					{
						ShareUserPtr p = m_onlineUser.GetUserByRoleId(members[i]);
						if(p.get() != NULL)
							m_socketServer.SendMsg(p->GetSock(),msg);
					}
				}
			}
			else	// 发送入队申请
			{
				ShareUserPtr ptr = m_onlineUser.GetUserByRoleId(teamId);
				if (ptr.get() != NULL)
				{
					msg << (uint8)2 << PRO_SUCCESS;
					m_socketServer.SendMsg(pUser->GetSock(), msg);
					char buf[128];
					snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_2627, pTar->GetName());
					if (!pTeam->IsAskedForJoin(pUser->GetRoleId()))
					{
						pTeam->AskForJoinTeam(pUser->GetRoleId());
					}
					else
					{
						SendSysInfo(pUser, MakeStringColor(LANGUAGE_ZQX_0115, TIPS_FAILURE_COLOR).c_str());
						return;
					}

					SendSysInfo(pUser, MakeStringColor(buf, TIPS_WARNING_COLOR).c_str());
					msg.ReWrite();
					msg.SetType(PRO_USER_TEAM);
					string roleName = pUser->GetName();
					msg << (uint8)4 << pUser->GetRoleId() << roleName << pUser->GetHead() << pUser->GetSex() << (uint16)pUser->GetLevel()<<pUser->GetZhanDouLi();
					m_socketServer.SendMsg(ptr->GetSock(), msg);
					return;
				}
				else
				{
					SendSysInfo(pUser, MakeStringColor(LANGUAGE_ZQX_0117, TIPS_FAILURE_COLOR).c_str());
				}
			}
		}
		else
		{
			pHScene->AskForJoinTeam(pUser,teamId,type);
		}
	}
	else
	{
		SendSysInfo(pUser, MakeStringColor(LANGUAGE_TRANSFORM_2628,TIPS_FAILURE_COLOR).c_str());
	}
}

void CScene::SendTeamInfo(CUserTeam *pTeam,CUser *pAddUser)
{
	if(pTeam == NULL || pAddUser == NULL)
		return;
	
	uint32 members[MAX_TEAM_MEMBER];
	uint8 num = 0;
	pTeam->GetMember(members,num);
	if(num > 0)
	{
		CNetMessage msg;
		msg.ReWrite();
		msg.SetType(PRO_UPDATE_TEAM);
		ShareUserPtr pTar = m_onlineUser.GetUserByRoleId(pTeam->GetHeadId());	// 队长
		if(pTar.get() == NULL)
			return;
		msg<<(uint8)11;
		msg<<pTar->GetRoleId()<<pTar->GetX()<<pTar->GetY()<<pTar->GetFace()<<pTar->GetName()<<pTar->GetSex()<<pTar->GetHead();
		uint16 pos = msg.GetDataLen();
		uint8 memNum = 0;
		msg<<memNum;
		for(uint8 i=1;i < num;i++)	// 队员
		{
			if(members[i] != pAddUser->GetRoleId())
			{
				ShareUserPtr pMem = m_onlineUser.GetUserByRoleId(members[i]);
				if(pMem.get() == NULL)
					return;
				msg<<pMem->GetRoleId()<<pMem->GetFace()<<pMem->GetName()<<pMem->GetSex()<<pMem->GetHead();
				memNum++;
			}
		}
		// 入队队员信息
		msg<<pAddUser->GetRoleId()<<pAddUser->GetFace()<<pAddUser->GetName()<<pAddUser->GetSex()<<pAddUser->GetHead();
		msg.WriteData(pos,&memNum,sizeof(memNum));

		pTeam->GetAllMember(members,num);
		for(uint8 i=0;i < num;i++)
		{
			ShareUserPtr pMem = m_onlineUser.GetUserByRoleId(members[i]);
			if(pMem.get() != NULL && pMem->GetScene() == this)
				m_socketServer.SendMsg(pMem->GetSock(),msg);
		}
	}
}

bool CScene::MakeTeamList(uint32 id, CUserTeam *pTeam, uint8 page, CNetMessage *msg, uint8 *teamNum, uint8 *tolNum)
{
	(*tolNum)++;
	if (*teamNum >= ONE_PAGE_MAX_NUM)
		return false;

	if (*tolNum > ONE_PAGE_MAX_NUM * (page + 1))
		return false;

	if (*tolNum < ONE_PAGE_MAX_NUM * page)
	{
		return true;
	}
	/*
	+-----+-----+------+------+
	| CID | LEN | NAME | MNUM |
	+-----+-----+------+------+
	|  4  |  2  |  Var |  1   |
	+-----+-----+------+------+
	*/
	(*teamNum)++;
	*msg << pTeam->GetHeadId() << pTeam->GetHeadName() << pTeam->GetHeadXiang() << pTeam->GetHeadLevel() << pTeam->GetMemberNum();
	return true;
}

void CScene::DecBZXingDongLi(CUser *pUser,int xingDongLi)
{
	if(pUser == NULL || pUser->GetScene() != this || (pUser->GetTeam() > 0 && pUser->GetTeam() != pUser->GetRoleId()))
		return;
	if(pUser->GetTeam() == 0)
	{
		pUser->SetExtData16(7,pUser->GetExtData16(7)-xingDongLi);
	}
	else
	{	
		CUserTeam *pTeam = NULL;
		uint32 member[MAX_TEAM_MEMBER] = {0};
		uint8 num = 0;
		if((pTeam = GetTeam(pUser->GetRoleId())) != NULL)
		{
			pTeam->GetMember(member,num);
			if(num > 0)
			{
				for(uint8 i=0;i < num;i++)
				{
					ShareUserPtr p = m_onlineUser.GetUserByRoleId(member[i]);
					if(p.get() != NULL)
						p->SetExtData16(7,p->GetExtData16(7)-xingDongLi/(int)num);
				}
			}
		}
	}
}

CUserTeam *CScene::GetTeam(uint32 teamId)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	CUserTeam *pTeam = NULL;
	if(!m_userTeams.Find(teamId, pTeam))
		return NULL;
	return pTeam;
}

void CScene::AddTeam(uint32 teamId,CUserTeam *pTeam)
{
	if(teamId == 0 || pTeam == NULL)
		return;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_userTeams.Insert(teamId,pTeam);
}

void CScene::GetTeamLeaveMem(CUser *pUser,uint32 *members,uint8 &num)
{
	num = 0;
	if(pUser == NULL || members == NULL)
		return;
	if(pUser->GetTeam() == 0 || pUser->GetTeam() != pUser->GetRoleId())
		return;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	CUserTeam *pTeam = NULL;
	if(!m_userTeams.Find(pUser->GetTeam(),pTeam))
		return;
	if(pTeam == NULL)
		return;
	pTeam->GetLeaveMem(members,num);
}

void CScene::GetTeamList(CUser *pUser, uint8 page)
{
	page -= 1;
	/*
	+----+------+------+
	| OP | PAGE | TNUM |
	+----+------+------+
	|  1 |  1   |  1   |
	+----+------+------+
	*/

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	CNetMessage msg;
	msg.SetType(PRO_USER_TEAM);
	uint8 teamNum = 0;
	uint8 tolNum = 0;
	msg << (uint8)3 << page;
	uint16 pos = msg.GetDataLen();
	msg << teamNum;

	m_userTeams.ForEach(boost::bind(&CScene::MakeTeamList, this, _1, _2, page, &msg, &teamNum, &tolNum));
	msg.WriteData(pos, &teamNum, sizeof(teamNum));
	SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);
}

uint8 CScene::MakeTeamFaBuInfo(CNetMessage &msg,STeamFaBuData &data)
{
	if(data.teamId == 0)
		return 0;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	CUserTeam *pTeam = NULL;
	if(!m_userTeams.Find(data.teamId,pTeam))
		return 0;
	if(pTeam == NULL)
		return 0;
	msg<<data.minLevel<<data.maxLevel;
	pTeam->MakeTeamFaBuInfo(msg);
	return 1;
}

int CScene::GetDynamicNpcNum()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return m_dynamicNpc.size();
}

void CScene::ForEachUser(boost::function < void(ShareUserPtr) > f)
{
	list<uint32>::iterator iter = m_userList.begin();
	for (; iter != m_userList.end(); iter++)
	{
		ShareUserPtr p = m_onlineUser.GetUserByRoleId(*iter);
		if (p.get() == NULL)
			continue;
		f(p);
	}
}

void CScene::NotInTeamUser(uint8 page, CNetMessage &msg)
{
	if (page < 1)
		return;

	page--;
	boost::recursive_mutex::scoped_lock lk(m_mutex);

	int begin = ONE_PAGE_MAX_NUM * page;

	list<uint32>::iterator iter = m_userList.begin();
	int num = 0;
	uint8 pNum = 0;
	uint8 pos = msg.GetDataLen();
	msg << pNum;
	for (; iter != m_userList.end(); iter++)
	{
		ShareUserPtr p = m_onlineUser.GetUserByRoleId(*iter);
		if (num > begin + ONE_PAGE_MAX_NUM)
			return;
		else if ((num >= begin) && (p.get() != NULL))
		{
			/*
			+----+------+------+-----+-----+------+-------+-------+
			| OP | PAGE | PNUM | MID | LEN | NAME | XIANG | LEVEL |
			+----+------+------+-----+-----+------+-------+-------+
			|  1 |  1   |  1   |  4  |  2  |  Var |   1   |   1   |
			+----+------+------+-----+-----+------+-------+-------+
			*/
			pNum++;
			msg << p->GetRoleId() << p->GetName() << p->GetHead() << p->GetLevel();
		}
		num++;
	}
	msg.WriteData(pos, &pNum, 1);
}

//不给同组队人发
void CScene::BroadcastMsgExceptSameTeam(CUser *pUser, CNetMessage &msg)
{
	list<uint32>::iterator iter = m_userList.begin();
	for (; iter != m_userList.end(); iter++)
	{
		ShareUserPtr p = m_onlineUser.GetUserByRoleId(*iter);
		if (p.get() == NULL)
			continue;
		if ((pUser->GetRoleId() != p->GetRoleId()
				&& ((pUser->GetTeam() == 0) || (p->GetTeam() != pUser->GetTeam()))))
		{
			m_socketServer.SendMsg(p->GetSock(), msg);
		}
	}
}

void CScene::BroadcastMsg(CNetMessage &msg, bool chatMsg,int ignoreId)
{
	list<uint32>::iterator iter = m_userList.begin();

	for (; iter != m_userList.end(); iter++)
	{
		ShareUserPtr p = m_onlineUser.GetUserByRoleId(*iter);
		if (p.get() != NULL)
		{
			if(ignoreId > 0 && SingletonCFriendMgr::instance().IsInBlackList(p->GetRoleId(), ignoreId))
				continue;
			if ((!chatMsg) || ((p->GetChatChannel() & 2) != 0))
				m_socketServer.SendMsg(p->GetSock(), msg);
		}
	}
}

void CScene::BroadcastMsgDirect(CNetMessage &msg)
{
	list<uint32>::iterator iter = m_userList.begin();
	for (; iter != m_userList.end(); iter++)
	{
		ShareUserPtr p = m_onlineUser.GetUserByRoleId(*iter);
		if (p.get() == NULL)
			continue;
		m_socketServer.SendMsg(p->GetSock(), msg);
	}
}
bool CScene::GoTo(CUser *pUser,uint16 pos_x,uint16 pos_y)
{
	if(pUser == NULL || pUser->GetScene() == NULL) 
		return false;
	if( CanWalkPos(pos_x,pos_y) )
	{
		pUser->SetPos(pos_x,pos_y);
		SyncUserScenePos(pUser,pos_x,pos_y,0);
		return true; 
	}
	return false;
}
void CScene::BroadcastMsgExcept(CNetMessage &msg, CUser *pUser)
{
	for(list<uint32>::iterator iter = m_userList.begin(); iter != m_userList.end(); iter++)
	{
		ShareUserPtr p = m_onlineUser.GetUserByRoleId(*iter);
		if (p.get() == NULL)
			continue;
		if (p->GetRoleId() == pUser->GetRoleId())
			continue;
		if (!p->UserInfoIsOpen() && ((p->GetTeam() == 0) || (pUser->GetTeam() != p->GetTeam())))
			continue;
		m_socketServer.SendMsg(p->GetSock(), msg);
	}
}

// 快速入队
bool CScene::AllowJoinTeamWithNoNotice(CUser *pUser,uint32 member)
{
	ShareUserPtr ptr = m_onlineUser.GetUserByRoleId(member);
	if(ptr.get() == NULL)
		return false;
	if(ptr->GetKuaFuState() != EKFS_IN_LOCAL)
		return false;
	if(ptr->GetFightId() != 0 || pUser->GetFightId() != 0)
		return false;
	if(ptr.get() == NULL)
		return false;
	uint32 teamId = pUser->GetTeam();
	if(teamId == 0)
		return false;
	if(ptr->GetTeam() != 0)
		return false;
	if(ptr->HaveBitSet(156))
		return false;

	string strNotice;
	if(!CanJoinTeamInBangPaiScene(pUser,ptr.get(),strNotice))
		return false;

	CNetMessage msg;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	CUserTeam *pTeam = NULL;
	if(!m_userTeams.Find(teamId, pTeam))
		return false;
	if(pTeam == NULL)
		return false;
	pTeam->DelAskForJoinTeam(member);
	if(!pTeam->Join(member))
		return false;
	pTeam->SendJoinTeamMemberData(member,member);
	pTeam->UpdateTeamData();
	if(pTeam->GetMemberNum() + pTeam->GetLeaveNum() >= MAX_TEAM_MEMBER)
	{
		SingletonTeamFaBuCfgMgr::instance().RemoveFaBuTeam(pTeam->GetType(),pTeam->GetHeadId());
		pTeam->SendTeamFaBuData();
	}
	else
	{
		pTeam->SendTeamFaBuData(member);
	}
	
	uint32 members[MAX_TEAM_MEMBER];
	uint8 num = 0;
	pTeam->GetAllMember(members, num);

	string str = ptr->GetName();
	str += LANGUAGE_TRANSFORM_2629;

	if(pUser->HaveCMission(MISSION_ID_ZhuoGui))
	{
		vector<int> ints;
		vector<string> strs;
		pUser->GetCMissionInts(MISSION_ID_ZhuoGui,ints);
		pUser->GetCMissionStrs(MISSION_ID_ZhuoGui,strs);
		int cutTimes = ptr->GetExtData16(50);
		if (cutTimes < MAX_ZHUAIGUI_LIMIT)
		{
			ints[0] = ptr->GetExtData16(50) % 30;
			ptr->AcceptCMission(MISSION_ID_ZhuoGui, ints, strs);
		}
	}
	
	for(uint8 i = 0; i < num; i++)
	{
		ShareUserPtr p = m_onlineUser.GetUserByRoleId(members[i]);
		if(p.get() != NULL)
			SendSysInfo(p.get(), MakeStringColor(str.c_str(),TIPS_WARNING_COLOR).c_str());
	}

	if(ptr->GetScene() == this)	// 相同场景加入队伍
	{
		ptr->SetTeam(teamId);
		ptr->SetTempLeaveTeam(0);
		uint16 x, y;
		pUser->GetPos(x, y);
		ptr->SetPos(x, y);

		SendTeamInfo(pTeam,ptr.get());

		msg.ReWrite();
		msg.SetType(PRO_UPDATE_TEAM);
		msg << (uint8)2 << pUser->GetRoleId() << member << x << y << pUser->GetFace();
		BroadcastMsg(msg);
	}
	else	// 不同场景，新进的队员设置暂离
	{
		ptr->SetTeam(0);
		ptr->SetTempLeaveTeam(teamId);
		
		msg.ReWrite();
		msg.SetType(PRO_UPDATE_TEAM);
		msg << (uint8)10 << teamId << member << ptr->GetX() << ptr->GetY() << ptr->GetFace();
		for(uint8 i = 0; i < num; i++)
		{
			ShareUserPtr p = m_onlineUser.GetUserByRoleId(members[i]);
			if(p.get() != NULL)
				m_socketServer.SendMsg(p->GetSock(),msg);
		}
	}
	return true;
}

bool CScene::CanJoinTeam()
{
	if(m_srcSceneId >= KUN_LUN_SHAN_SCENE_ID && m_srcSceneId < KUN_LUN_SHAN_SCENE_ID+30)
		return false;
	else if(m_srcSceneId == KUN_LUN_SHAN_TEAM_SCENE_ID)
		return false;
	else if(m_srcSceneId == KUA_FU_1V1_SCENE_ID)
		return false;
	else if(m_srcSceneId == LEI_TAI_ID2)
		return false;
	else if(m_srcSceneId >= FEI_XIAN_SID1 && m_srcSceneId <= FEI_XIAN_SID5)
		return false;
	else if(m_srcSceneId >= FISH_ID2 && m_srcSceneId <= FISH_ID2+1)
		return false;
	return true;
}

void CScene::UpdateTeamData(uint32 teamId)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	CUserTeam *pTeam = NULL;
	m_userTeams.Find(teamId, pTeam);
	if(pTeam != NULL)
		pTeam->UpdateTeamData();
}

bool CScene::AllowJoinTeam(CUser *pUser, uint32 member,bool isMemRecv)
{
	if(pUser == NULL)
		return false;
	uint32 teamId = pUser->GetTeam();
	CNetMessage msg;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	CUserTeam *pTeam = NULL;
	m_userTeams.Find(teamId, pTeam);
	if(pTeam == NULL)
	{
		if(!isMemRecv)
			SendSysInfo(pUser, MakeStringColor(LANGUAGE_TRANSFORM_2630,TIPS_FAILURE_COLOR).c_str());
		return false;
	}
	pTeam->DelAskForJoinTeam(member);
	
	ShareUserPtr ptr = m_onlineUser.GetUserByRoleId(member);
	if(ptr.get() == NULL)
	{
		SendSysInfo(pUser, MakeStringColor(LANGUAGE_ZQX_0117, TIPS_FAILURE_COLOR).c_str());
		return false;
	}
	CScene *pMemScene = ptr->GetScene();
	if(pMemScene != NULL && !pMemScene->CanJoinTeam())
	{
		if(isMemRecv)
			SendSysInfo(ptr.get(),MakeStringColor(LANGUAGE_TRANSFORM_2633,TIPS_FAILURE_COLOR).c_str());
		else
			SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_2634,TIPS_FAILURE_COLOR).c_str());
		return false;
	}
	
	if(teamId == 0)
	{
		if(isMemRecv)
			SendSysInfo(ptr.get(), MakeStringColor(LANGUAGE_TRANSFORM_2635,TIPS_FAILURE_COLOR).c_str());
		else
			SendSysInfo(pUser, MakeStringColor(LANGUAGE_TRANSFORM_2636,TIPS_FAILURE_COLOR).c_str());
		return false;
	}
	if(ptr->InHuSongMission() == 1)
	{
		if(isMemRecv)
			SendSysInfo(ptr.get(), MakeStringColor(LANGUAGE_TRANSFORM_2637,TIPS_FAILURE_COLOR).c_str());
		else
			SendSysInfo(pUser, MakeStringColor(LANGUAGE_TRANSFORM_2638,TIPS_FAILURE_COLOR).c_str());
		return false;
	}
	else if(ptr->InHuSongMission() == 2)
	{
		if(isMemRecv)
			SendSysInfo(ptr.get(), MakeStringColor(LANGUAGE_TRANSFORM_2639,TIPS_FAILURE_COLOR).c_str());
		else
			SendSysInfo(pUser, MakeStringColor(LANGUAGE_TRANSFORM_2640,TIPS_FAILURE_COLOR).c_str());
		return false;
	}

	if(ptr->GetKuaFuState() != EKFS_IN_LOCAL)
		return false;
	if(ptr->GetFightId() != 0 || pUser->GetFightId() != 0)
		return false;
	if(ptr.get() == NULL)
	{
		if(isMemRecv)
			SendSysInfo(ptr.get(), MakeStringColor(LANGUAGE_TRANSFORM_2641,TIPS_FAILURE_COLOR).c_str());
		else
			SendSysInfo(pUser, MakeStringColor(LANGUAGE_TRANSFORM_2642,TIPS_FAILURE_COLOR).c_str());
		return false;
	}

	if(ptr->GetTeam() != 0)
	{
		if(isMemRecv)
			SendSysInfo(ptr.get(), MakeStringColor(LANGUAGE_TRANSFORM_2643,TIPS_FAILURE_COLOR).c_str());
		else
			SendSysInfo(pUser, MakeStringColor(LANGUAGE_TRANSFORM_2644,TIPS_FAILURE_COLOR).c_str());
		return false;
	}

	string strNotice;
	if(!CanJoinTeamInBangPaiScene(pUser,ptr.get(),strNotice))
	{
		if(isMemRecv)
			SendSysInfo(ptr.get(), MakeStringColor(strNotice,TIPS_FAILURE_COLOR).c_str());
		else
			SendSysInfo(pUser, MakeStringColor(strNotice,TIPS_FAILURE_COLOR).c_str());
		return false;
	}
	
	if(ptr->HaveBitSet(156))
	{
		if(isMemRecv)
			SendSysInfo(ptr.get(), MakeStringColor(LANGUAGE_TRANSFORM_2645,TIPS_FAILURE_COLOR).c_str());
		else
			SendSysInfo(pUser, MakeStringColor(LANGUAGE_TRANSFORM_2646,TIPS_FAILURE_COLOR).c_str());
		return false;
	}
	
	if(!pTeam->Join(member))
	{
		if(isMemRecv)
			SendSysInfo(ptr.get(), MakeStringColor(LANGUAGE_TRANSFORM_2647,TIPS_FAILURE_COLOR).c_str());
		else
			SendSysInfo(pUser, MakeStringColor(LANGUAGE_TRANSFORM_2648,TIPS_FAILURE_COLOR).c_str());
		return false;
	}
	
	pTeam->SendJoinTeamMemberData(member,member);
	pTeam->UpdateTeamData();
	if(pTeam->GetMemberNum() + pTeam->GetLeaveNum() >= MAX_TEAM_MEMBER)
	{
		SingletonTeamFaBuCfgMgr::instance().RemoveFaBuTeam(pTeam->GetType(),pTeam->GetHeadId());
		pTeam->SendTeamFaBuData();
	}
	else
	{
		pTeam->SendTeamFaBuData(member);
	}
	
	uint32 members[MAX_TEAM_MEMBER];
	uint8 num = 0;
	pTeam->GetAllMember(members, num);

	string str = ptr->GetName();
	str += LANGUAGE_TRANSFORM_2649;

	if(pUser->HaveCMission(MISSION_ID_ZhuoGui))
	{
		vector<int> ints;
		vector<string> strs;
		pUser->GetCMissionInts(MISSION_ID_ZhuoGui,ints);
		pUser->GetCMissionStrs(MISSION_ID_ZhuoGui,strs);
		int cutTimes = ptr->GetExtData16(50);
		if (cutTimes < MAX_ZHUAIGUI_LIMIT)
		{
			ints[0] = ptr->GetExtData16(50) % 30;
			ptr->AcceptCMission(MISSION_ID_ZhuoGui, ints, strs);
		}
	}

	if(ptr->GetScene() == this)	// 相同场景加入队伍
	{
		ptr->SetTeam(teamId);
		ptr->SetTempLeaveTeam(0);

		uint16 x, y;
		pUser->GetPos(x, y);
		ptr->SetPos(x, y);
		
		SendTeamInfo(pTeam,ptr.get());
		
		msg.ReWrite();
		msg.SetType(PRO_UPDATE_TEAM);
		msg << (uint8)2 << pUser->GetRoleId() << member << x << y << pUser->GetFace();
		BroadcastMsg(msg);

		uint32 members[MAX_TEAM_MEMBER];
		uint8 num = 0;
		pTeam->GetLeaveMem(members,num);
		for(uint8 i=0;i < num;i++)
		{
			ShareUserPtr pMem = m_onlineUser.GetUserByRoleId(members[i]);
			if(pMem.get() != NULL && pMem->GetScene() != this)
				m_socketServer.SendMsg(pMem->GetSock(),msg);
		}
	}
	else	// 不同场景，新进的队员设置暂离
	{
		ptr->SetTeam(0);
		ptr->SetTempLeaveTeam(teamId);
		
		msg.ReWrite();
		msg.SetType(PRO_UPDATE_TEAM);
		msg << (uint8)10 << teamId << member << ptr->GetX() << ptr->GetY() << ptr->GetFace();
		for(uint8 i = 0; i < num; i++)
		{
			ShareUserPtr p = m_onlineUser.GetUserByRoleId(members[i]);
			if(p.get() != NULL)
				m_socketServer.SendMsg(p->GetSock(),msg);
		}

		num = 0;
		pTeam->GetLeaveMem(members,num);
		for(uint8 i=0;i < num;i++)
		{
			ShareUserPtr pMem = m_onlineUser.GetUserByRoleId(members[i]);
			if(pMem.get() != NULL)
				m_socketServer.SendMsg(pMem->GetSock(),msg);
		}
	}
	return true;
}

void CScene::GetAskForUserList(CUser *pUser)
{
	//page从1开始
	CNetMessage msg;
	msg.SetType(PRO_USER_TEAM);
	msg << (uint8)5;

	boost::recursive_mutex::scoped_lock lk(m_mutex);

	CUserTeam *pTeam = NULL;
	if ((!m_userTeams.Find(pUser->GetTeam(), pTeam))
		|| (pUser->GetTeam() != pTeam->GetHeadId()))
	{
		msg << (uint8)0;
		m_socketServer.SendMsg(pUser->GetSock(), msg);
		return;
	}
	uint8 askNum = 0;
	uint8 pos = msg.GetDataLen();
	msg << askNum;

	list<uint32> *userList = pTeam->GetAskForJoin();
	list<uint32>::iterator iter = userList->begin();
	int num = 0;
	for (; iter != userList->end(); iter++)
	{
		num++;
		ShareUserPtr p = m_onlineUser.GetUserByRoleId(*iter);
		if (p.get() != NULL)
		{
			askNum++;
			msg << p->GetRoleId() << p->GetName() << p->GetLevel();
		}
		if (askNum >= ONE_PAGE_MAX_NUM)
			break;
	}
	msg.WriteData(pos, &askNum, sizeof(askNum));
	m_socketServer.SendMsg(pUser->GetSock(), msg);
}

uint8 CScene::GetTeamMem(uint32 teamId, uint32 members[MAX_TEAM_MEMBER])
{
	CUserTeam *pTeam = NULL;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if (m_userTeams.Find(teamId, pTeam))
	{
		uint8 num = 0;
		pTeam->GetMember(members, num);
		return num;
	}
	return 0;
}

void CScene::SetNewHead(CUser *pUser, uint32 newHead)
{
	uint32 teamId = pUser->GetTeam();
	if(teamId != pUser->GetRoleId())
		return;

	ShareUserPtr p = m_onlineUser.GetUserByRoleId(newHead);
	CUser *pNewHead = p.get();
	if(pNewHead == NULL)
		return;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	CUserTeam *pTeam = NULL;
	if(!m_userTeams.Find(teamId, pTeam))
		return;
	if(!pTeam->SetNewHead(pNewHead))
		return;

	// 更换发布队伍ID
	SingletonTeamFaBuCfgMgr::instance().ChangeTeamIdByType(pTeam->GetType(),teamId,newHead);
	pNewHead->SetTeam(pNewHead->GetRoleId());
	pNewHead->SetTempLeaveTeam(0);
	m_userTeams.Erase(teamId);
	pTeam->UpdateTeamData();

	CScene *pScene = pNewHead->GetScene();
	CNetMessage msg;
	if(pScene != NULL)
	{
		uint32 leaveMem[MAX_TEAM_MEMBER];
		uint8 leaveNum = 0;
		pTeam->GetLeaveMem(leaveMem, leaveNum);
		if(pScene != this)	// 不同场景
		{
			msg.ReWrite();
			msg.SetType(PRO_UPDATE_TEAM);
			msg << (uint8)4 << teamId << pUser->GetX() << pUser->GetY() << pUser->GetFace();
			BroadcastMsg(msg);

			// 队长不在同个场景, 更换队伍id并且设置队友暂离状态
//			uint8 updateRoleNum = 0;
//			msg.ReWrite();
//			msg.SetType(PRO_UPDATE_TEAM);
//			msg << (uint8)8 << teamId << pNewHead->GetRoleId();
//			uint16 pos = msg.GetDataLen();
//			msg << updateRoleNum;
			for(uint8 i = 0; i < leaveNum; i++)
			{
				ShareUserPtr p = m_onlineUser.GetUserByRoleId(leaveMem[i]);
				if(p.get() != NULL)
				{
					p->SetTempLeaveTeam(pNewHead->GetRoleId());
					p->SetTeam(0);

//					msg << (uint8)6 << pNewHead->GetRoleId() << p->GetRoleId() << p->GetX() << p->GetY() << p->GetFace();	// 暂离
//					if(p->GetScene() == this)	// 队员更新，同个场景
//						BroadcastMsg(msg);
//					else
//						m_socketServer.SendMsg(p->GetSock(),msg);

//					if(p->GetScene() == this)
//					{
//						msg << p->GetRoleId() << p->GetX() << p->GetY() << p->GetFace();
//						updateRoleNum++;
//					}
				}
			}
//			msg.WriteData(pos,&updateRoleNum,sizeof(updateRoleNum));
//			BroadcastMsg(msg);

			// 新建队伍
//			msg.ReWrite();
//			msg.SetType(PRO_UPDATE_TEAM);
//			msg << (uint8)9 << teamId << pNewHead->GetRoleId();
//			pScene->BroadcastMsg(msg);

			msg.ReWrite();
			msg.SetType(PRO_UPDATE_TEAM);
			msg << (uint8)1 << pNewHead->GetRoleId();
			pScene->BroadcastMsg(msg);
			
			pScene->AddTeam(pNewHead->GetRoleId(),pTeam);
		}
		else	// 同个场景
		{
			m_userTeams.Insert(pNewHead->GetRoleId(), pTeam);
			
			// 更换队长
			msg.ReWrite();
			msg.SetType(PRO_UPDATE_TEAM);
			msg << (uint8)5 << pNewHead->GetRoleId() << pUser->GetX() << pUser->GetY() << pUser->GetFace();
			BroadcastMsg(msg);

			for(uint8 i = 0; i < leaveNum; i++)
			{
				ShareUserPtr p = m_onlineUser.GetUserByRoleId(leaveMem[i]);
				if(p.get() != NULL)
				{
					p->SetTempLeaveTeam(pNewHead->GetRoleId());
					p->SetTeam(0);

					msg.ReWrite();
					msg.SetType(PRO_UPDATE_TEAM);
					msg << (uint8)6 << pNewHead->GetRoleId() << p->GetRoleId() << p->GetX() << p->GetY() << p->GetFace();	// 暂离
					if(p->GetScene() == this)	// 队员更新，同个场景
						BroadcastMsg(msg);
//					else
//						m_socketServer.SendMsg(p->GetSock(),msg);
				}
			}
		}
	}

	uint32 member[MAX_TEAM_MEMBER];
	uint8 memNum = 0;
	pTeam->GetMember(member, memNum);
	for(uint8 i = 0; i < memNum; i++)
	{
		ShareUserPtr p = m_onlineUser.GetUserByRoleId(member[i]);
		if(p.get() != NULL)
		{
			p->SetTempLeaveTeam(0);
			p->SetTeam(pNewHead->GetRoleId());
		}
	}
}

void CScene::GetTeamMembers(CUser *pUser)
{
	CNetMessage msg;
	msg.SetType(PRO_USER_TEAM);
	msg << (uint8)8;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	CUserTeam *pTeam = NULL;
	uint32 teamId = pUser->GetTeam();
	if (teamId == 0)
		teamId = pUser->TempLeaveTeam();

	if ((teamId == 0) || (!m_userTeams.Find(teamId, pTeam)))
	{
		msg << (uint8)0;
		m_socketServer.SendMsg(pUser->GetSock(), msg);
		return;
	}

	uint32 members[MAX_TEAM_MEMBER];
	uint32 leaveMem[MAX_TEAM_MEMBER];
	uint8 num = 0;
	uint8 leaveNum = 0;
	pTeam->GetMember(members, num);
	pTeam->GetLeaveMem(leaveMem, leaveNum);
	msg << (uint8)(num + leaveNum);
	for (uint8 i = 0; i < num; i++)
	{
		ShareUserPtr p = m_onlineUser.GetUserByRoleId(members[i]);
		if (p.get() != NULL)  //0在队伍中,1暂离
		{
			msg << p->GetRoleId() << p->GetName() << p->GetHead() << p->GetLevel() << (uint8)0;
		}
	}
	for (uint8 i = 0; i < leaveNum; i++)
	{
		ShareUserPtr p = m_onlineUser.GetUserByRoleId(leaveMem[i]);
		if (p.get() != NULL)  //0在队伍中,1暂离
		{
			msg << p->GetRoleId() << p->GetName() << p->GetHead() << p->GetLevel() << (uint8)1;
		}
	}
	m_socketServer.SendMsg(pUser->GetSock(), msg);
}

void CScene::SetInTeamMemLeave(CUser *pUser)
{
	if(pUser == NULL || pUser->GetTeam() != pUser->GetRoleId())
		return;
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	CUserTeam *pTeam = NULL;
	if(!m_userTeams.Find(pUser->GetTeam(), pTeam))
		return;
	if(pTeam == NULL)
		return;
	
	uint32 members[MAX_TEAM_MEMBER];
	uint8 num = 0;
	pTeam->GetMember(members,num);
	if(num == 1)
		return;
	// 除队长之外都设置成暂离
	for(uint8 i=1;i < num;i++)
	{
		ShareUserPtr mem = m_onlineUser.GetUserByRoleId(members[i]);
		CUser *pMem = mem.get();
		if(pMem != NULL)
		{
			pMem->SetTempLeaveTeam(pUser->GetTeam());
			pMem->SetTeam(0);
			pTeam->TempLeaveTeam(pMem->GetRoleId());
			pTeam->ReSetTeamZhenRong();
			CNetMessage msg;
			msg.SetType(PRO_UPDATE_TEAM);
			msg << (uint8)6 << pTeam->GetHeadId() << pMem->GetRoleId() << pMem->GetX() << pMem->GetY() << pMem->GetFace();
			BroadcastMsg(msg);
			SendSysInfo(pMem,MakeStringColor(LANGUAGE_TRANSFORM_2650,TIPS_FAILURE_COLOR).c_str());
		}
	}
	
	pTeam->UpdateTeamData();
}

void CScene::TempLeaveTeam(CUser *pUser)
{
	uint32 teamId = pUser->GetTeam();
	if(teamId == 0)
		return;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	CUserTeam *pTeam = NULL;
	if(!m_userTeams.Find(pUser->GetTeam(), pTeam))
		return;

	if(pUser->GetTeam() == pUser->GetRoleId())	// 队长
	{
		//队长不得暂离队伍，只有在战斗中队长逃跑才会调用此函数
		//这时候解散队伍
		CNetMessage msg;
		msg.SetType(PRO_UPDATE_TEAM);
		msg << (uint8)4 << teamId << pUser->GetX() << pUser->GetY() << pUser->GetFace();
		BroadcastMsg(msg);
		uint32 members[MAX_TEAM_MEMBER];
		uint8 num = 0;
		pTeam->GetMember(members, num);
		for (uint8 i = 0; i < num; i++)
		{
			ShareUserPtr p = m_onlineUser.GetUserByRoleId(members[i]);
			if (p.get() != NULL)
			{
				SendSysInfo(p.get(), MakeStringColor(LANGUAGE_TRANSFORM_2651,TIPS_WARNING_COLOR).c_str());
				p->SetTeam(0);
				p->SetTempLeaveTeam(0);
			}
		}
		
		uint32 leaveMem[MAX_TEAM_MEMBER];
		uint8 leaveNum = 0;
		pTeam->GetLeaveMem(leaveMem, leaveNum);
		for (uint8 i = 0; i < leaveNum; i++)
		{
			ShareUserPtr p = m_onlineUser.GetUserByRoleId(leaveMem[i]);
			if (p.get() != NULL)
			{
				SendSysInfo(p.get(), MakeStringColor(LANGUAGE_TRANSFORM_2652,TIPS_WARNING_COLOR).c_str());
				p->SetTeam(0);
				p->SetTempLeaveTeam(0);
				m_socketServer.SendMsg(p->GetSock(), msg);
			}
		}
		SingletonTeamFaBuCfgMgr::instance().RemoveFaBuTeam(pTeam->GetType(),teamId);
		
		m_userTeams.Erase(teamId);
		delete pTeam;
	}
	else	// 队员
	{
		pUser->SetTempLeaveTeam(pUser->GetTeam());
		pUser->SetTeam(0);
		pTeam->TempLeaveTeam(pUser->GetRoleId());
		pTeam->ReSetTeamZhenRong();
		CNetMessage msg;
		msg.SetType(PRO_UPDATE_TEAM);
		msg << (uint8)6 << pTeam->GetHeadId() << pUser->GetRoleId() << pUser->GetX() << pUser->GetY() << pUser->GetFace();
		BroadcastMsg(msg);

		pTeam->UpdateTeamData();

		uint32 members[MAX_TEAM_MEMBER];
		uint8 num = 0;
		pTeam->GetLeaveMem(members,num);
		for(uint8 i=0;i < num;i++)
		{
			ShareUserPtr p = m_onlineUser.GetUserByRoleId(members[i]);
			if(p.get() != NULL)
				m_socketServer.SendMsg(p->GetSock(),msg);
		}
	}
}

void CScene::SetTeamType(uint32 teamId,uint8 type,uint16 minLv,uint16 maxLv)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	CUserTeam *pTeam = NULL;
	if(!m_userTeams.Find(teamId,pTeam))
		return;
	if(pTeam == NULL)
		return;
	pTeam->SetType(type,minLv,maxLv);
}

void CScene::SetTeamFaBuStatus(uint32 teamId,bool status)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	CUserTeam *pTeam = NULL;
	if(!m_userTeams.Find(teamId,pTeam))
		return;
	if(pTeam == NULL)
		return;
	pTeam->SetFabuState(status);
}

bool CScene::CanEnterBangPai(CUser *pUser)
{
	if(pUser == NULL)
		return false;
	uint32 teamId = pUser->GetTeam();
	if(teamId == 0)
		teamId = pUser->TempLeaveTeam();
	if(teamId == 0)
		return false;

	ShareUserPtr pHead = m_onlineUser.GetUserByRoleId(teamId);
	if(pHead.get() == NULL)
		return false;
	CScene *pScene = pHead->GetScene();
	if(pScene == NULL)
		return false;
	if(pScene == this)
	{		
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		CUserTeam *pTeam = NULL;
		if(!m_userTeams.Find(teamId,pTeam))
			return false;
		if(pTeam == NULL)
			return false;

		uint32 members[MAX_TEAM_MEMBER];
		uint8 num = 0;
		pTeam->GetAllMember(members,num);
		if(num == 1)
			return true;
		uint32 bangpai = pHead->GetBangPai();
		if(bangpai == 0)
			return false;
		for(uint8 i=1;i < num;i++)
		{
			ShareUserPtr p = m_onlineUser.GetUserByRoleId(members[i]);
			if(p.get() != NULL)
			{
				if(p->GetBangPai() != bangpai)
					return false;
			}
		}
		return true;
	}
	else
	{
		return pScene->CanEnterBangPai(pUser);
	}
}

void CScene::GetTeamData(CUser *pUser)
{
	if(pUser == NULL)
		return;
	CNetMessage msg;
	msg.SetType(PRO_USER_TEAM);
	msg<<(uint8)16;

	uint32 teamId = pUser->GetTeam();
	if(teamId == 0)
		teamId = pUser->TempLeaveTeam();
	if(teamId == 0)
	{
		msg<<PRO_SUCCESS<<(uint8)0xff<<(uint8)0;
		m_socketServer.SendMsg(pUser->GetSock(),msg);		
		return;
	}

	ShareUserPtr p = m_onlineUser.GetUserByRoleId(teamId);
	CUser *pHead = p.get();
	if(pHead == NULL)
	{
		return;
	}
	CScene *pScene = pHead->GetScene();
	if(pScene == NULL)
		return;
	if(pScene == this)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		CUserTeam *pTeam = NULL;
		if(!m_userTeams.Find(teamId,pTeam) || pTeam == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0390,TIPS_FAILURE_COLOR);
			m_socketServer.SendMsg(pUser->GetSock(),msg);
			return;
		}

		msg<<PRO_SUCCESS<<pTeam->GetType();
		pTeam->MakeAllMemberInfo(msg);
		m_socketServer.SendMsg(pUser->GetSock(),msg);
	}
	else
	{
		pScene->GetTeamData(pUser);
	}
}

void CScene::CallBackTeam(CUser *pUser)
{
	if(pUser == NULL)
		return;
	uint32 teamId = pUser->GetTeam();
	if(teamId == 0 || teamId != pUser->GetRoleId())
		return;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	CUserTeam *pTeam = NULL;
	if(!m_userTeams.Find(teamId,pTeam))
		return;
	if(pTeam == NULL)
		return;

	uint32 members[MAX_TEAM_MEMBER];
	uint8 num = 0;
	pTeam->GetLeaveMem(members,num);
	if(num > 0)
	{
		for(uint8 i = 0; i < num; i++)
		{
			ShareUserPtr p = m_onlineUser.GetUserByRoleId(members[i]);
			if(p.get() != NULL)
				SendSysInfo(p.get(), MakeStringColor(LANGUAGE_TRANSFORM_2657,TIPS_WARNING_COLOR).c_str());
		}
	}
	else
	{
		SendSysInfo(pUser, MakeStringColor(LANGUAGE_TRANSFORM_2658,TIPS_WARNING_COLOR).c_str());
	}
}

void CScene::ReturnTeam(CUser *pUser)
{
	if(pUser == NULL)
		return;
	ShareUserPtr p = m_onlineUser.GetUserByRoleId(pUser->TempLeaveTeam());
	CUser *pTeamHead = p.get();
	if(pTeamHead == NULL)
		return;
	
	CScene *pScene = pTeamHead->GetScene();
	if(pScene == NULL)
		return;
	if(pScene == this)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		CUserTeam *pTeam = NULL;
		if(!m_userTeams.Find(pUser->TempLeaveTeam(), pTeam))
			return;
		if(pTeam == NULL)
			return;
		pUser->SetTeam(pUser->TempLeaveTeam());
		pUser->SetTempLeaveTeam(0);
		pUser->SetPos(pTeamHead->GetX(), pTeamHead->GetY());

		pTeam->ReturnTeam(pUser->GetRoleId());
		CNetMessage msg;
		msg.SetType(PRO_UPDATE_TEAM);
		msg << (uint8)7 << pTeam->GetHeadId() << pUser->GetRoleId() << pUser->GetX() << pUser->GetY() << pUser->GetFace();
		BroadcastMsg(msg);

		pTeam->UpdateTeamData();

		uint32 members[MAX_TEAM_MEMBER];
		uint8 num = 0;
		pTeam->GetLeaveMem(members,num);
		for(uint8 i=0;i < num;i++)
		{
			ShareUserPtr pMem = m_onlineUser.GetUserByRoleId(members[i]);
			if(pMem.get() != NULL)
				m_socketServer.SendMsg(pMem->GetSock(),msg);
		}
	}
	else
	{
		uint32 srcSceneId = pScene->GetSrcSceneId();
		if(srcSceneId == BANG_PAI_SCENE_ID)
		{
			if(pUser->GetBangPai() == 0 || pUser->GetBangPai() != pTeamHead->GetBangPai())
			{
				SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_2659,TIPS_FAILURE_COLOR).c_str());
				return;
			}
		}

		if(IsCanReturnTeamScene(pScene->GetSrcSceneId()))	// 先判定该场景是否可归队
		{
			TransportUser(pUser,pScene->GetId(),pTeamHead->GetX(),pTeamHead->GetY(),pTeamHead->GetFace());
			pScene->ReturnTeam(pUser);
		}
		else
		{
			SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_2660,TIPS_FAILURE_COLOR).c_str());
		}
	}
}

bool CScene::LeaveSceneTeam(uint32 teamId, CUser *pUser)
{
	CUserTeam *pTeam = NULL;
	CUser *pNewHead = NULL;
	bool addOtherSceneTeam = false;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if (!m_userTeams.Find(teamId, pTeam))
			return false;
		if(pTeam == NULL)
			return false;
		pUser->SetTeam(0);
		pUser->SetTempLeaveTeam(0);

		CNetMessage msg;
		msg.SetType(PRO_UPDATE_TEAM);
		if (pUser->HaveCMission(MISSION_ID_ZhuoGui))
		{
			pUser->DelCMission(MISSION_ID_ZhuoGui);	// 抓鬼任务
			SingletonCMissionManager::instance().SendAvailableCMissionInfo(pUser, EMISS_STYPE_ZhuoGui);
		}
		if (teamId == pUser->GetRoleId())  //队长离开队伍
		{
			uint8 num = pTeam->GetMemberNum() + pTeam->GetLeaveNum();
			if(num == 1)
			{
				msg << (uint8)4 << teamId << pUser->GetX() << pUser->GetY() << pUser->GetFace();
				BroadcastMsg(msg);
				SendSysInfo(pUser, MakeStringColor(LANGUAGE_TRANSFORM_2661,TIPS_FAILURE_COLOR).c_str());

				SingletonTeamFaBuCfgMgr::instance().RemoveFaBuTeam(pTeam->GetType(),teamId);
				
				pUser->SetTeam(0);
				pUser->SetTempLeaveTeam(0);
				m_userTeams.Erase(teamId);
				SendLeaveTeamMsg(pUser);
				delete pTeam;
			}
			else
			{
				uint32 members[MAX_TEAM_MEMBER];
				uint8 num = 0;
				pTeam->GetAllMember(members,num);
				string str = pUser->GetName();
				str += LANGUAGE_TRANSFORM_2662;

				for(uint8 i = 0; i < num; i++)
				{
					ShareUserPtr p = m_onlineUser.GetUserByRoleId(members[i]);
					if(p.get() != NULL)
					{
						SendSysInfo(p.get(), MakeStringColor(str.c_str(),TIPS_FAILURE_COLOR).c_str());
						if((pNewHead == NULL) && (p->GetRoleId() != pUser->GetRoleId()))
							pNewHead = p.get();
					}
				}
				if(pNewHead == NULL)
					return false;
				m_userTeams.Erase(teamId);
				
				uint32 newTeamId = pNewHead->GetRoleId();

				pTeam->ReturnTeam(newTeamId);
				pNewHead->SetTempLeaveTeam(0);
				pNewHead->SetTeam(newTeamId);
				pTeam->Exit(pUser->GetRoleId());
				pTeam->SetNewHead(pNewHead);
				SingletonTeamFaBuCfgMgr::instance().ChangeTeamIdByType(pTeam->GetType(),teamId,newTeamId);
				pTeam->SendTeamFaBuData();

				msg << (uint8)3 << pTeam->GetHeadId() << pUser->GetRoleId() << pUser->GetX() << pUser->GetY() << pUser->GetFace();	// 离队
				BroadcastMsg(msg);
				
				uint32 leaveMem[MAX_TEAM_MEMBER];
				uint8 leaveNum = 0;
				pTeam->GetLeaveMem(leaveMem, leaveNum);				
				for(uint8 i = 0; i < leaveNum; i++)
				{
					ShareUserPtr p = m_onlineUser.GetUserByRoleId(leaveMem[i]);
					if(p.get() != NULL)
					{
						CScene *pTScene = p->GetScene();
						if(pTScene != this)
							m_socketServer.SendMsg(p->GetSock(),msg);
						p->SetTempLeaveTeam(newTeamId);
						p->SetTeam(0);
					}
				}
				uint32 inTeamMem[MAX_TEAM_MEMBER];
				uint8 inNum = 0;
				pTeam->GetMember(inTeamMem, inNum);				
				for(uint8 i = 0; i < inNum; i++)
				{
					ShareUserPtr p = m_onlineUser.GetUserByRoleId(inTeamMem[i]);
					if(p.get() != NULL)
					{
						m_socketServer.SendMsg(p->GetSock(),msg);
						p->SetTeam(newTeamId);
					}
				}

				CScene *pScene = pNewHead->GetScene();
				if(pScene == NULL)
					return false;
				if(pScene == this)	// 同个场景队长切换
				{
					m_userTeams.Insert(pNewHead->GetRoleId(), pTeam);

					for(uint8 i = 0; i < leaveNum; i++)
					{
						ShareUserPtr p = m_onlineUser.GetUserByRoleId(leaveMem[i]);
						if(p.get() != NULL && p->GetScene() == this)
						{
							msg.ReWrite();
							msg.SetType(PRO_UPDATE_TEAM);
							msg << (uint8)6 << pTeam->GetHeadId() << p->GetRoleId() << p->GetX() << p->GetY() << p->GetFace();	// 暂离
							BroadcastMsg(msg);
						}
					}
				}
				else	// 不同场景队长切换
				{
					addOtherSceneTeam = true;

					// 队长不在同个场景, 更换队伍id并且设置队友暂离状态
					uint8 updateRoleNum = 0;
					msg.ReWrite();
					msg.SetType(PRO_UPDATE_TEAM);
					msg << (uint8)8 << teamId << pNewHead->GetRoleId();
					uint16 pos = msg.GetDataLen();
					msg << updateRoleNum;
					for(uint8 i = 0; i < leaveNum; i++)
					{
						ShareUserPtr p = m_onlineUser.GetUserByRoleId(leaveMem[i]);
						if(p.get() != NULL && p->GetScene() == this)
						{
							msg << p->GetRoleId() << p->GetX() << p->GetY() << p->GetFace();
							updateRoleNum++;
						}
					}
					msg.WriteData(pos,&updateRoleNum,sizeof(updateRoleNum));
					BroadcastMsg(msg);
				}

				pTeam->UpdateTeamData();
				SendLeaveTeamMsg(pUser);
			}
		}
		else  //队员离开队伍
		{
			uint32 members[MAX_TEAM_MEMBER];
			uint8 num = 0;
			pTeam->GetAllMember(members, num);
			string str = pUser->GetName();
			str += LANGUAGE_TRANSFORM_2663;

			pTeam->Exit(pUser->GetRoleId());
			msg << (uint8)3 << pTeam->GetHeadId() << pUser->GetRoleId() << pUser->GetX() << pUser->GetY() << pUser->GetFace();
			BroadcastMsg(msg);

			pTeam->UpdateTeamData();

			for(uint8 i = 0; i < num; i++)
			{
				ShareUserPtr p = m_onlineUser.GetUserByRoleId(members[i]);
				if(p.get() != NULL)
				{
					SendSysInfo(p.get(), MakeStringColor(str.c_str(),TIPS_FAILURE_COLOR).c_str());
					if(p->GetScene() != this)
						m_socketServer.SendMsg(p->GetSock(),msg);
				}
			}
			SendLeaveTeamMsg(pUser);
		}
	}

	if(addOtherSceneTeam)	// 不同场景队长切换
	{
		CScene *pScene = pNewHead->GetScene();
		if(pScene == NULL)
			return false;
		pScene->AddTeam(pNewHead->GetRoleId(),pTeam);

		if(pTeam != NULL)
			pTeam->UpdateTeamData();
		
		CNetMessage msg;
		msg.SetType(PRO_UPDATE_TEAM);
		msg<<(uint8)9<<teamId<<pNewHead->GetRoleId();
		pScene->BroadcastMsg(msg);
	}
	return true;
}

void CScene::LeaveTeam(CUser *pUser)
{
	uint32 teamId = pUser->GetTeam();
	if(teamId == 0)
		teamId = pUser->TempLeaveTeam();
	if(teamId == 0)
		return;

	if(!LeaveSceneTeam(teamId, pUser))
	{
		ShareUserPtr p = m_onlineUser.GetUserByRoleId(teamId);
		if(p.get() != NULL)
		{
//			p->DelCMission(MISSION_ID_ZhuoGui);
			CScene *pScene = p->GetScene();
			if(pScene != this)
			{
				pScene->LeaveTeam(pUser);
				CNetMessage msg;
				msg.SetType(PRO_UPDATE_TEAM);
				msg << (uint8)3 << teamId << pUser->GetRoleId() << pUser->GetX() << pUser->GetY() << pUser->GetFace();
				m_socketServer.SendMsg(pUser->GetSock(), msg);

				SendLeaveTeamMsg(pUser);
			}
		}
	}
}

void CScene::NotAllowJoin(CUser *pUser, uint32 member)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	CUserTeam *pTeam = NULL;
	if((!m_userTeams.Find(pUser->GetTeam(), pTeam)) || (pTeam->GetHeadId() != pUser->GetRoleId()))
		return;
	pTeam->DelAskForJoinTeam(member);
	pTeam->DelRequest(member);

	ShareUserPtr p = m_onlineUser.GetUserByRoleId(member);
	if(p.get() == NULL)
		return;
	p->DelAskForJoinTeam(pUser->GetTeam());
	string str = pUser->GetName();
	str += LANGUAGE_TRANSFORM_2664;
	SendSysInfo(p.get(), MakeStringColor(str.c_str(),TIPS_FAILURE_COLOR).c_str());
}

void CScene::DelTeamMember(CUser *pUser, uint32 member)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	CUserTeam *pTeam = NULL;
	if ((!m_userTeams.Find(pUser->GetTeam(), pTeam))
		|| (member == pTeam->GetHeadId())
		|| (pTeam->GetHeadId() != pUser->GetRoleId()))
	{
		return;
	}


	ShareUserPtr p = m_onlineUser.GetUserByRoleId(member);
	if(p.get() == NULL)
		return;
	SendSysInfo(p.get(), MakeStringColor(LANGUAGE_TRANSFORM_2665,TIPS_FAILURE_COLOR).c_str());

	p->SetTeam(0);
	p->SetTempLeaveTeam(0);
	pTeam->Exit(member);

	CNetMessage msg;
	msg.SetType(PRO_UPDATE_TEAM);
	msg << (uint8)3 << pTeam->GetHeadId() << member << pUser->GetX() << pUser->GetY() << pUser->GetFace();
	BroadcastMsg(msg);

	pTeam->UpdateTeamData();

	SendLeaveTeamMsg(p.get());

	string str = p->GetName();
	str += LANGUAGE_TRANSFORM_2666;
//	p->DelCMission(MISSION_ID_ZhuoGui);
	
	uint32 members[MAX_TEAM_MEMBER];
	uint8 num = 0;
	pTeam->GetAllMember(members, num);
	for(uint8 i = 0; i < num; i++)
	{
		p = m_onlineUser.GetUserByRoleId(members[i]);
		if(p.get() != NULL)
		{
			SendSysInfo(p.get(), MakeStringColor(str.c_str(),TIPS_FAILURE_COLOR).c_str());
			if(p->GetScene() != this)
				m_socketServer.SendMsg(p->GetSock(),msg);
		}
	}
}

int CScene::GetUserNum()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return m_userList.size();
}

void CScene::TransportOutOfKunLunShan()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(list<uint32>::iterator i = m_userList.begin(); i != m_userList.end(); i++)
	{
		ShareUserPtr p = m_onlineUser.GetUserByRoleId(*i);
		if(p.get() != NULL)
			p->ExitFuBen();
	}
}

bool CScene::FindFacePlayer(CUser *pUser, ShareUserPtr &find)
{
	uint8 x, y;
	pUser->GetFacePos(x, y);
	boost::recursive_mutex::scoped_lock lk(m_mutex);

	for (list<uint32>::iterator i = m_userList.begin(); i != m_userList.end(); i++)
	{
		ShareUserPtr p = m_onlineUser.GetUserByRoleId(*i);
		if (p.get() != NULL)
		{
			if ((p->GetX() == x) && (p->GetY() == y))
			{
				find = p;
				return true;
			}
		}
	}
	return false;
}

void CScene::PlayerPk(ShareUserPtr pUser, uint32 roleId, bool yaoqing)
{
	ShareUserPtr p;
	if(roleId == 0)
	{
		if (!FindFacePlayer(pUser.get(), p))
		{
			SendSysInfo(pUser.get(), MakeStringColor(LANGUAGE_TRANSFORM_2667,TIPS_FAILURE_COLOR).c_str());
			return;
		}
	}
	else
	{
		p = m_onlineUser.GetUserByRoleId(roleId);
	}

	if(p.get() == NULL)
	{
		SendSysInfo(pUser.get(), MakeStringColor(LANGUAGE_TRANSFORM_2668,TIPS_FAILURE_COLOR).c_str());
		return;
	}
/*
	if(pUser->HaveIgnore(roleId))
	{
		SendSysInfo(pUser.get(), MakeStringColor(LANGUAGE_TRANSFORM_2669,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	if(p->HaveIgnore(pUser->GetRoleId()))
	{
		SendSysInfo(pUser.get(), MakeStringColor(LANGUAGE_TRANSFORM_2670,TIPS_FAILURE_COLOR).c_str());
		return;
	}
*/
	if(pUser->GetScene() != p->GetScene())
	{
		SendSysInfo(pUser.get(), MakeStringColor(LANGUAGE_TRANSFORM_2671,TIPS_FAILURE_COLOR).c_str());
		return;
	}

	if(p->GetKuaFuState() != EKFS_IN_LOCAL)
		return;
	if(p->GetFightId() != 0)
	{
		SendSysInfo(pUser.get(), MakeStringColor(LANGUAGE_TRANSFORM_2672,TIPS_FAILURE_COLOR).c_str());
		return;
	}

	if((m_fightType & 1) == 0)
	{
		SendSysInfo(pUser.get(), MakeStringColor(LANGUAGE_TRANSFORM_2673,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	if(p->GetLevel() <= 30)
	{
		SendSysInfo(pUser.get(), MakeStringColor(LANGUAGE_TRANSFORM_2674,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	if((p->GetTeam() != 0) && (p->GetTeam() != p->GetRoleId()))
	{
		SendSysInfo(pUser.get(), MakeStringColor(LANGUAGE_TRANSFORM_2675,TIPS_FAILURE_COLOR).c_str());
		return;
	}

	if(yaoqing)
	{
		CNetMessage msg;
		msg.SetType(PRO_USER_PK);
		msg <<(uint8)0<< pUser->GetRoleId() << pUser->GetName();
		m_socketServer.SendMsg(p->GetSock(), msg);
		return;
	}

	ShareFightPtr pFight = m_fightManager.CreateFight();
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);

		if ((pUser->GetTeam() != 0) && (p->GetTeam() == pUser->GetTeam()))
			return;
		pFight->SetFightType(CFight::EFTPlayerPk);
		pFight->SetVisibleMonsterId(0);
		pFight->SetFightChooseMode();

		uint8 fightPos1 = 0;
		uint8 fightPos2 = 0;
		if(!yaoqing)
			fightPos1 = CFight::GROUP2_BEGIN;
		else
			fightPos2 = CFight::GROUP2_BEGIN;
		AddUserGroupToBattle(pFight,pUser,fightPos1);
		AddUserGroupToBattle(pFight,p,fightPos2);
		pFight->BeginFight(this);
	}
	m_fightManager.AddFight(pFight);
}

void CScene::AddSingleUserWithZhenFaId(ShareFightPtr &fight,ShareUserPtr &user,uint8 begin,uint16 zhenFaId,uint16 zhenFaLv,uint8 userPos)
{
	CFight *pFight = fight.get();
	if(pFight == NULL)
		return;
	CUser *pUser = user.get();
	if(pUser == NULL)
		return;
	if(zhenFaId == 0 || zhenFaLv == 0 || userPos == 0 || userPos > 5)
		return;
	
	vector<SZhenFaMemData> zhenfaMem;
	pUser->GetZhenFaMember(zhenfaMem);
	if(zhenfaMem.empty())
		return;
	for(uint8 i=0;i < zhenfaMem.size();i++)
	{
		if(zhenfaMem[i].mem_type == EZFMT_USER)
		{
			if(i == userPos-1)
				break;
			SZhenFaMemData t = zhenfaMem[userPos-1];
			zhenfaMem[userPos-1] = zhenfaMem[i];
			zhenfaMem[i] = t;
			break;
		}
	}

	CZhenFaCfgMgr &zhenfaMgr = SingletonCZhenFaCfgMgr::instance();
	// 重置站位
	SZhenFaBasicCfg *pBasicCfg = zhenfaMgr.GetBasicCfg(zhenFaId);
	for(uint8 i=0;i < zhenfaMem.size();i++)
	{
		zhenfaMem[i].fightPos = pBasicCfg->fightPos[i];
	}
	userPos = zhenfaMem[userPos-1].fightPos + begin;

	uint8 group = (begin >= CFight::GROUP2_BEGIN) ? (CFight::EGT_GROUP2) : (CFight::EGT_GROUP1);
	SZhenFaLevelUpData *pZhenFaAttr = zhenfaMgr.GetLevelUpCfg(zhenFaId,zhenFaLv);
	if(pZhenFaAttr == NULL)
		return;
	pFight->SetGroupZhenFaData(zhenFaId,zhenFaLv,group);
	pFight->AddUser(user, group);
	pUser->SetFight(pFight->GetId());
	for(uint8 i=0;i < zhenfaMem.size();i++)
	{
		SZhenFaMemData &data = zhenfaMem[i];
		if(data.mem_type == EZFMT_NONE)
			continue;
		if(data.mem_type == EZFMT_USER)
		{
//			uint8 fightPos = data.fightPos + begin;
		}
		else if(data.mem_type == EZFMT_PET)
		{
			uint8 fightPos = data.fightPos + begin;
			uint32 petId = data.mem_id;
			SharePetPtr pet = pUser->GetPet(petId);
			if(pet.get() == NULL)
				continue;
			pFight->AddPet(pet,fightPos,userPos,i);
		}
	}
}

void CScene::AddSingleUser(ShareFightPtr &fight,ShareUserPtr &user,uint8 begin,bool isQunXian)
{
	CFight *pFight = fight.get();
	if(pFight == NULL)
		return;
	CUser *pUser = user.get();
	if(pUser == NULL)
		return;

	vector<SZhenFaMemData> zhenfaMem;
	pUser->GetZhenFaMember(zhenfaMem);
	if(zhenfaMem.empty())
		return;
/*	for(uint8 i=0;i < zhenfaMem.size();i++)
	{
		if(zhenfaMem[i].mem_type == EZFMT_USER)
		{
			userPos = zhenfaMem[i].fightPos;
			break;
		}
	}
	if(userPos == 0)	// 机器人等没有阵法的情况
	{
		userPos = CFight::GROUP1_MAIN_POS;
		return;
	}
	userPos += begin;
*/

	uint8 group = (begin >= CFight::GROUP2_BEGIN) ? (CFight::EGT_GROUP2) : (CFight::EGT_GROUP1);
	uint16 zhenFaId = user->GetUseZhenFaId();
	uint16 zhenFaLv = user->GetUseZhenFaLevel();
	SZhenFaLevelUpData *pZhenFaAttr = SingletonCZhenFaCfgMgr::instance().GetLevelUpCfg(zhenFaId,zhenFaLv);
	if(pZhenFaAttr == NULL)
		return;
	pFight->SetGroupZhenFaData(zhenFaId,zhenFaLv,group);
	pFight->AddUser(user, group);
	pUser->SetFight(pFight->GetId());
	for(uint8 i=0;i < zhenfaMem.size();i++)
	{
		SZhenFaMemData &data = zhenfaMem[i];
		if(data.mem_type == EZFMT_NONE)
			continue;
		if(data.mem_type == EZFMT_USER)
		{
//			uint8 fightPos = data.fightPos + begin;
//			pUser->SetFight(pFight->GetId(),pFight->AddUser(user,fightPos,i));
//			pUser->SetFight(pFight->GetId(),pFight->AddUser(user,fightPos,i));
		}
		else if(data.mem_type == EZFMT_PET)
		{
			uint8 fightPos = data.fightPos + begin;
			uint32 petId = data.mem_id;
			SharePetPtr pet = pUser->GetPet(petId);
			if(pet.get() == NULL)
				continue;
			pFight->AddPet(pet,fightPos,pUser->GetRoleId(),i);
		}
	}


//	if(isQunXian)
//	{
//		m_qx_userPos = userPos;
//		pUser->CopyQunXianAttrVal(m_qx_userAttrVal,CUser::MAX_QX_ATTR_NUM,m_qx_userAttrPercent,CUser::MAX_QX_ATTR_NUM);
//	}

//	vector<SharePetPtr> petList;
//	if(isQunXian)
//		pUser->GetQXChuZhanPetList(petList);

//	return userPos;
}

void CScene::AddSingleUserEx(ShareFightPtr &fight, ShareUserPtr &user, uint8 begin, vector<uint16>& hpPercent)
{
	CFight *pFight = fight.get();
	if (pFight == NULL)
		return;
	CUser *pUser = user.get();
	if (pUser == NULL)
		return;

	vector<SZhenFaMemData> zhenfaMem;
	pUser->GetZhenFaMember(zhenfaMem);
	if (zhenfaMem.empty())
		return;

	uint8 group = (begin >= CFight::GROUP2_BEGIN) ? (CFight::EGT_GROUP2) : (CFight::EGT_GROUP1);
	uint16 zhenFaId = user->GetUseZhenFaId();
	uint16 zhenFaLv = user->GetUseZhenFaLevel();
	SZhenFaLevelUpData *pZhenFaAttr = SingletonCZhenFaCfgMgr::instance().GetLevelUpCfg(zhenFaId, zhenFaLv);
	if (pZhenFaAttr == NULL)
		return;
	pFight->SetGroupZhenFaData(zhenFaId, zhenFaLv, group);
	pFight->AddUser(user, group);
	pUser->SetFight(pFight->GetId());
	for (uint8 i = 0; i < zhenfaMem.size(); i++)
	{
		SZhenFaMemData &data = zhenfaMem[i];
		if (data.mem_type == EZFMT_NONE)
			continue;
		if (data.mem_type == EZFMT_USER)
		{
		}
		else if (data.mem_type == EZFMT_PET)
		{
			uint8 fightPos = data.fightPos + begin;
			uint32 petId = data.mem_id;
			SharePetPtr pet = pUser->GetPet(petId);
			SPet* pPet = pet.get();
			if (pPet == NULL)
				continue;
			if (hpPercent.size() >= size_t(i + 1))
			{
				float per = hpPercent[i] * 0.01;
				pPet->hp *= per;
			}
			pFight->AddPet(pet, fightPos, pUser->GetRoleId(), i);
		}
	}

}

uint16 CScene::AddTeamToFight(ShareFightPtr &fight, CUserTeam *pTeam, uint8 begin)
{
	if(pTeam == NULL)
		return 0;
	CFight *pFight = fight.get();
	if(pFight == NULL)
		return 0;
	
	uint16 maxLevel = 1;
	uint16 allLevel = 0;
	uint8 num = 0;
	vector<SZhenFaMemData> zhenfaMem;
	pTeam->GetZhenFaMember(zhenfaMem);
	if(zhenfaMem.empty())
		return 0;
	uint32 leaderId = pTeam->GetHeadId();
	if(leaderId == 0)
		return 0;
	ShareUserPtr leader = m_onlineUser.GetUserByRoleId(leaderId);
	CUser *pLeader = leader.get();
	if(pLeader == NULL)
		return 0;
	uint8 leaderPos = 0;
	for(uint8 i=0;i < zhenfaMem.size();i++)
	{
		if(zhenfaMem[i].mem_type == EZFMT_USER && zhenfaMem[i].mem_id == leaderId)
		{
			leaderPos = zhenfaMem[i].fightPos;
			break;
		}
	}
	if(leaderPos == 0)
		return 0;

	uint8 group = (begin >= CFight::GROUP2_BEGIN) ? (CFight::EGT_GROUP2) : (CFight::EGT_GROUP1);
	uint16 zhenFaId = pTeam->GetUseZhenFaId();
	uint16 zhenFaLv = pLeader->GetZhenFaLevel(zhenFaId);
	pFight->SetGroupZhenFaData(zhenFaId,zhenFaLv,group);
	pFight->AddUser(leader, group);
	leader->SetFight(pFight->GetId());
	for(uint8 i=0;i < zhenfaMem.size();i++)
	{
		SZhenFaMemData &data = zhenfaMem[i];
		if(data.mem_type == EZFMT_NONE)
			continue;
		if(data.mem_type == EZFMT_USER)
		{
//			uint8 fightPos = data.fightPos + begin;
			uint32 roleId = data.mem_id;
			ShareUserPtr p = m_onlineUser.GetUserByRoleId(roleId);
			if((p.get() != NULL) && (p->GetTeam() == leaderId))
			{
//				p->SetFight(pFight->GetId(),pFight->AddUser(p,fightPos,i));
				if(p->GetLevel() > maxLevel)
					maxLevel = p->GetLevel();

				allLevel += p->GetLevel();
				num++;
			}
		}
		else if(data.mem_type == EZFMT_PET)
		{
			uint8 fightPos = data.fightPos + begin;
			uint32 petId = data.mem_id;
			SharePetPtr pet = pLeader->GetPet(petId);
			if(pet.get() == NULL)
				continue;
			pFight->AddPet(pet,fightPos,leaderPos+begin,i);
		}
	}
	int averageLevel = allLevel / num;
	return maxLevel - 10 > averageLevel ? maxLevel - 10 : averageLevel;
}

//脚本触发，遇固定敌人
void CScene::ShiMenFight(CUser *pU)
{
	if(pU == NULL)
		return;
	if(pU->GetKuaFuState() != EKFS_IN_LOCAL)
		return;
	if(pU->GetFightId() != 0)
		return;

	ShareUserPtr pUser = m_onlineUser.GetUserBySock(pU->GetSock());
	if (pUser.get() == NULL)
		return;

	ShareFightPtr pFight = m_fightManager.CreateFight();
	if (pFight.get() == NULL)
		return;
	pFight->SetFightType(CFight::EFTScript);
	pFight->SetTaskId(90);

	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		uint16 level = AddUserGroupToBattle(pFight,pUser);
		int fightId = Random(10801,10806);
		AddMonsterByFightId(pFight,fightId,level);
		pFight->BeginFight(this);
	}
	m_fightManager.AddFight(pFight);
}

// ======================================
// 挖宝
void CScene::WabaoFight(CUser *pU)
{
	if(pU == NULL)
		return;
	if(pU->GetKuaFuState() != EKFS_IN_LOCAL)
		return;
	if(pU->GetFightId() != 0)
		return;
	ShareUserPtr pUser = m_onlineUser.GetUserBySock(pU->GetSock());
	if (pUser.get() == NULL)
		return;
	ShareFightPtr pFight = m_fightManager.CreateFight();
	if (pFight.get() == NULL)
		return;

	pFight->SetFightType(CFight::EFTScript);
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		uint16 level = AddUserGroupToBattle(pFight, pUser);
		int fightId = Random(11001,11006);
		AddMonsterByFightId(pFight,fightId,level);
		pFight->BeginFight(this);
	}
	m_fightManager.AddFight(pFight);
}

void CScene::GetUserList(list<uint32> &userList)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	userList = m_userList;
}

// 副本、boss怪战斗
void CScene::BossMonsterFight(ShareUserPtr pUser,SVisibleMonsterBoss &boss,int memberNum)
{
	if(pUser.get() == NULL)
		return;
	if(pUser->GetKuaFuState() != EKFS_IN_LOCAL)
		return;
	if(pUser->GetFightId() != 0)
		return;
	
	if(m_srcSceneId >= COPY_ID_CHONG_WU_1 && m_srcSceneId <= COPY_ID_CHONG_WU_4)	// 神将副本
		RiChangChongWuFuBenFight(pUser,boss);
	else if(m_srcSceneId == COPY_ID_QIANG_HUA)	// 强化副本
		RiChangQiangHuaFuBenFight(pUser,boss);
	else if(m_srcSceneId == COPY_ID_MONEY)		// 金币副本
		RiChangJinBiFuBenFight(pUser,boss);
	else if(m_srcSceneId == COPY_ID_SHENG_JIE)	// 升阶副本
		RiChangShengJieFuBenFight(pUser,boss);
	else if(m_srcSceneId == COPY_ID_QIAN_NENG)	// 潜能副本
		RiChangQianNengFuBenFight(pUser,boss);
	else if(m_srcSceneId == COPY_ID_XIANG_QIAN)	// 镶嵌副本
		RiChangXiangQianFuBenFight(pUser,boss);
	else if(m_srcSceneId == COPY_ID_CUI_LIAN)	// 洗炼副本
		RiChangXiLianFuBenFight(pUser,boss);
	else if(m_srcSceneId == COPY_ID_CHONG_KAI)	// 神将铠副本
		RiChangChongKaiFuBenFight(pUser,boss);
	else
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		ShareFightPtr pFight = m_fightManager.CreateFight();
		if (pFight.get() == NULL)
			return;
		pFight->SetFightType((CFight::EFightType)GetFightType());
		AddUserGroupToBattle(pFight, pUser);
		if(!AddMonsterByFightId(pFight,boss.fightId,100,boss.id))
			return;
		pFight->BeginFight(this);
		m_fightManager.AddFight(pFight);
	}
}

void CScene::MeetEnemy(ShareUserPtr pUser)
{
	SVisibleMonster monster;
	SVisibleMonsterBoss monsterBoss;
	bool isBoss = false;
	bool isMeetEnemy = false;
	do
	{
		uint16 x = pUser->GetX();
		uint16 y = pUser->GetY();
		string monsterName;
		int monsterType = pUser->MeetMonster(monsterName);
		if(monsterType > 0)	// 仅自己可见明怪
		{
			MeetSelfMonster(pUser,monsterType,monsterName);
			return;
		}
		
		boost::recursive_mutex::scoped_lock lk(m_monster_mutex);
		for(list<SMonsterListInfo>::iterator i = m_MonsterList.begin();i != m_MonsterList.end();i++)
		{
			for(list<SVisibleMonster>::iterator j = i->monsterList.begin(); j != i->monsterList.end();j++)
			{
				int dx = x - j->x;
				int dy = y - j->y;
				if(dx*dx + dy*dy <= j->meetDistance * j->meetDistance)
				{
					isMeetEnemy = true;
					monster = *j;
					
					CNetMessage msg;
					msg.ReWrite();
					msg.SetType(MSG_MONSTER_OPTION);
					msg<<(uint8)3<<j->id;
					BroadcastMsg(msg);

					j->id = NormalMonsterIdPos + m_monsterIdIndex;
					m_monsterIdIndex++;
					j->face = (uint8)Random(0,7);
					j->flag = 0;
					uint8 r = 0;
					r = Random(0,7);
					j->x = j->center_x + Monster_Pos_x[r];
					j->y = j->center_y + Monster_Pos_y[r];
					j->path.clear();
					j->pathIndex = 0;
					uint8 level = (uint8)((j->monster_id - 1)/2*5 + 1);
					msg.ReWrite();
					msg.SetType(MSG_MONSTER_OPTION);
					msg<<(uint8)2<<j->id<<j->name<<(int)j->monster_id<<j->pic<<(uint16)level<<j->x<<j->y<<j->face<<(uint8)1;	// 野怪
					BroadcastMsg(msg);
					break;
				}
			}
		}

		if(isMeetEnemy)
			break;

		// BossMonster
		for(list<SVisibleMonsterBoss>::iterator i = m_visibleMonstersBoss.begin();i != m_visibleMonstersBoss.end();i++)
		{
			int dx = x - i->x;
			int dy = y - i->y;
			if(dx*dx + dy*dy <= i->meetDistance * i->meetDistance)
			{
				if(i->isVisible && i->flag == 0)		// 可见，并没在战斗中
				{
					isBoss = true;
					isMeetEnemy = true;
					monsterBoss = *i;
					if(m_srcSceneId != SHENJIEMIJING_SCENE_ID)	//神界秘境
						i->flag = 1;
					break;
				}
			}
		}
	}while(0);
	if(!isMeetEnemy)
		return;
#ifdef KUA_FU	
	if( m_srcSceneId == SHENJIEMIJING_SCENE_ID)//神界秘境
	{
		if(isBoss)
		{
			ShenJieMiJingPVEFight(pUser,monster.monster_id,isBoss,monsterBoss);
			return;
		}
	}
#endif

	if(isBoss)
	{
		BossMonsterFight(pUser,monsterBoss,pUser->GetTeamMemberNum());
		return;
	}

	if (TryJoinActivityFight(pUser, SOT_Baihua))	// 百花
		return;
	if (TryJoinActivityFight(pUser, SOT_Nianshou))	// 年兽
		return;

	if(pUser->GetTeam() == pUser->GetRoleId())
	{
		// 捉鬼
		if(pUser->HaveCMission(MISSION_ID_ZhuoGui))
		{
			vector<int> ints;
			vector<string> strs;
			pUser->GetCMissionInts(MISSION_ID_ZhuoGui,ints);
			pUser->GetCMissionStrs(MISSION_ID_ZhuoGui,strs);
			if(ints.size() >= 5 || strs.size() >= 1)
			{
				int monId = ints[3];
				if(monster.monster_id == monId)
				{
					int turn = ints[0];
					int monPic = ints[1];
					int fightType = ints[2];
					int minMonPic = ints[4];
					string bossName = strs[0];
					if(Random(1,100) <= 100)
					{
						ZhuoGuiBattle(pUser,fightType,monPic,bossName,turn,minMonPic);
						return;
					}
				}
			}
		}
	}
		
	if(m_monsterNum <= 0)
		return;
	ShareFightPtr pFight = m_fightManager.CreateFight();
	if(pFight.get() == NULL)
	{
		cout << "EFTMeetMonster: Create fight error" << endl;
		return;
	}

	// 野怪
	pFight->SetFightType(CFight::EFTMeetMonster);
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		uint32 level = AddUserGroupToBattle(pFight,pUser);

		uint8 num = pFight->GetGroup2UnitsNum();
		if(num <= 2)
			num = (uint8)Random(1,2);
		else
			num = (uint8)Random((int)(num-1),(int)(num+1));
		if(num > CFight::MAX_MEMBER/2)
			num = CFight::MAX_MEMBER/2;
		int fightId = Random(monster.min_fightId,monster.max_fightId);
		if(fightId == 0)
			return;
		AddMonsterByFightId(pFight,fightId,level,monster.monster_id);
		pFight->BeginFight(this);
	}
	m_fightManager.AddFight(pFight);
}

void CScene::ResetTeamMember(CUser *pUser)
{
	if(pUser == NULL)
		return;
	if(pUser->GetTeam() == 0 || pUser->GetTeam() != pUser->GetRoleId())
		return;
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	CUserTeam *pTeam = NULL;
	if(!m_userTeams.Find(pUser->GetTeam(), pTeam))
		return;
	if(pTeam == NULL)
		return;
	pTeam->ReSetTeamZhenRong();
	pTeam->UpdateTeamData();
}

bool CScene::SwitchTeamZhenFa(CUser *pUser,uint16 zhenfaId,CNetMessage &msg)
{
	if(pUser == NULL || zhenfaId == 0)
		return false;
	uint32 teamId = pUser->GetTeam();
	if(teamId == 0 || teamId != pUser->GetRoleId())
		return false;
	if(!pUser->HaveZhenFa(zhenfaId))
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0441,TIPS_FAILURE_COLOR);
		return true;
	}

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	CUserTeam *pTeam = NULL;
	if(!m_userTeams.Find(teamId, pTeam))
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0390,TIPS_FAILURE_COLOR);
		return true;
	}
	return pTeam->SwitchZhenFa(zhenfaId,msg);
}

bool CScene::TeamZhenFa_SetPetState(CUser *pUser,uint16 petId,uint8 state,CNetMessage &msg)
{
	if(pUser == NULL || petId == 0 || state == 0)
		return false;
	uint32 teamId = pUser->GetTeam();
	if(teamId == 0 || teamId != pUser->GetRoleId())
		return false;
	if(pUser->GetPet(petId).get() == NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0424,TIPS_FAILURE_COLOR);
		return true;
	}
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	CUserTeam *pTeam = NULL;
	if(!m_userTeams.Find(teamId, pTeam))
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0390,TIPS_FAILURE_COLOR);
		return true;
	}
	bool res = pTeam->ZhenFa_SetPetState(petId,state,pUser->GetLevel(),msg);
	if(res)
	{
		pTeam->UpdateTeamData();
		pUser->ZhenFa_SetPetState(petId,state,false);
	}
	return res;
}

bool CScene::TeamZhenFa_ChangeUnitPos(CUser *pUser,uint8 srcPos,uint8 tarPos,CNetMessage &msg)
{
	if(pUser == NULL || srcPos == 0 || tarPos == 0 || srcPos == tarPos || srcPos > ZHEN_FA_POS_NUM || tarPos > ZHEN_FA_POS_NUM)
		return false;
	uint32 teamId = pUser->GetTeam();
	if(teamId == 0 || teamId != pUser->GetRoleId())
		return false;
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	CUserTeam *pTeam = NULL;
	if(!m_userTeams.Find(teamId, pTeam))
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0390,TIPS_FAILURE_COLOR);
		return true;
	}
	bool res = pTeam->ZhenFa_ChangeUnitPos(srcPos,tarPos,pUser->GetLevel(),msg);
	if(res)
	{
		pTeam->UpdateTeamData();
		pUser->ZhenFa_ChangeUnitPos(srcPos,tarPos,false);
	}
	return res;
}

int CScene::GetTeamMemNum(uint32 teamId)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	CUserTeam *pTeam = NULL;
	if (!m_userTeams.Find(teamId, pTeam))
		return 0;

	uint32 members[MAX_TEAM_MEMBER];
	uint8 num = 0;
	pTeam->GetMember(members, num);
	return num;
}

int CScene::GetTeamAllMemNum(uint32 teamId)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	CUserTeam *pTeam = NULL;
	if (!m_userTeams.Find(teamId, pTeam))
		return 0;

	uint32 members[MAX_TEAM_MEMBER];
	uint8 num = 0;
	pTeam->GetAllMember(members, num);
	return num;
}

void CScene::GetTeamMemberList(CUser *pHead,vector<ShareUserPtr> &memList)
{
	memList.clear();
	if(pHead == NULL)
		return;
	if(pHead->GetTeam() == 0)	// 暂离的做为单人
	{
		ShareUserPtr p = m_onlineUser.GetUserByRoleId(pHead->GetRoleId());
		if(p.get() != NULL)
			memList.push_back(p);
	}
	else
	{
		if(pHead->GetTeam() != pHead->GetRoleId())
			return;
		
		uint32 members[MAX_TEAM_MEMBER];
		uint8 num = 0;
		{
			boost::recursive_mutex::scoped_lock lk(m_mutex);
			CUserTeam *pTeam = NULL;
			if (!m_userTeams.Find(pHead->GetTeam(), pTeam))
				return;
			pTeam->GetMember(members, num);
		}

		for(uint8 i=0; i < num; i++)
		{
			ShareUserPtr p = m_onlineUser.GetUserByRoleId(members[i]);
			if(p.get() != NULL)
				memList.push_back(p);
		}
	}
}

CUser *CScene::GetTeamMember(uint32 teamId,int idx) // idx:1-5,队长1
{
	if (idx > MAX_TEAM_MEMBER)
		return NULL;
	uint32 members[MAX_TEAM_MEMBER];
	uint8 num = 0;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		CUserTeam *pTeam = NULL;
		if (!m_userTeams.Find(teamId, pTeam))
			return NULL;

		pTeam->GetMember(members, num);
	}
	if (idx <= num)
	{
		ShareUserPtr p = m_onlineUser.GetUserByRoleId(members[idx-1]);
		if (p.get() != NULL)
		{
			return p.get();
		}
	}
	return NULL;
}

void CScene::ForEachTeamMember(uint32 teamId, boost::function < void(ShareUserPtr) > f)
{
	CUserTeam *pTeam = NULL;
	if (!m_userTeams.Find(teamId, pTeam))
		return;

	uint32 members[MAX_TEAM_MEMBER];
	uint8 num = 0;
	pTeam->GetMember(members, num);
	for (uint8 i = 0; i < num; i++)
	{
		ShareUserPtr p = m_onlineUser.GetUserByRoleId(members[i]);
		if (p.get() != NULL)
		{
			f(p);
		}
	}
	/*num = 0;
	pTeam->GetLeaveMem(members,num);
	for(uint8 i = 0; i < num; i++)
	{
		ShareUserPtr p = m_onlineUser.GetUserByRoleId(members[i]);
		if(p.get() != NULL)
		{
			f(p);
		}
	}*/
}

void CScene::NoLockChangeScene(CUser *pUser, CScene *pOldScene)
{
	if(pOldScene != NULL)
	{
		pOldScene->Exit(pUser);

		CUserTeam *pTeam = NULL;
		if((pUser->GetTeam() == pUser->GetRoleId())	&& (pOldScene->m_userTeams.Find(pUser->GetRoleId(),pTeam)))  //队长切换地图
		{
			uint16 toMapId = GetToMapId(m_id,m_srcSceneId); // 副本地图转换
			if (m_usedFuBen)	// 是副本的话，需要转换地图
				toMapId = GetSrcSceneId();
			
			pOldScene->m_userTeams.Erase(pUser->GetRoleId());
			m_userTeams.Insert(pUser->GetRoleId(), pTeam);
			Enter(pUser);
			if (pTeam->GetHeadId() == pUser->GetRoleId())  //队长跳转，队员也跳转
			{
				uint32 members[MAX_TEAM_MEMBER];
				uint8 num = 0;
				pTeam->GetMember(members, num);
				for (uint8 i = 1; i < num; i++)
				{
					ShareUserPtr p = m_onlineUser.GetUserByRoleId(members[i]);
					if (p.get() != NULL)
					{
						uint16 srcId = toMapId;
						p->GetNextSrcSceneId(srcId);
						
						CNetMessage msg;
						msg.SetType(PRO_JUMP_SCENE);
						msg << (uint16)srcId << pUser->GetX() << pUser->GetY() << pUser->GetFace()<<(uint8)0;
						m_socketServer.SendMsg(p->GetSock(), msg);
						p->SetPos(pUser->GetX(), pUser->GetY());
						p->SetFace(pUser->GetFace());
						p->EnterScene(this);
					}
				}
			}
			return;
		}
	}
	Enter(pUser);
}

void CScene::ChangeScene(CUser *pUser, CScene *pOldScene)
{
//	AddTongTianTaMonster();

	boost::recursive_mutex *pLock1 = NULL;
	boost::recursive_mutex *pLock2 = NULL;
	if (pOldScene != NULL)
	{
		if (m_id < pOldScene->GetId())
		{
			pLock1 = &m_mutex;
			pLock2 = &(pOldScene->m_mutex);
		}
		else
		{
			pLock2 = &m_mutex;
			pLock1 = &(pOldScene->m_mutex);
		}
	}
	else
	{
		pLock1 = &m_mutex;
	}

	if ((pLock1 != NULL) && (pLock2 != NULL))
	{
		boost::recursive_mutex::scoped_lock lk(*pLock1);
		boost::recursive_mutex::scoped_lock lk1(*pLock2);
		NoLockChangeScene(pUser, pOldScene);
	}
	else if (pLock1 != NULL)
	{
		boost::recursive_mutex::scoped_lock lk(*pLock1);
		NoLockChangeScene(pUser, pOldScene);
	}

	if (GetFBStep() != 0)
	{
		//cout << "当前战斗步骤不是0，显示对应步骤的怪" << endl;
		ShowVisibleMonsterBoss(GetFBStep());
	}
}

void CScene::SendUserList(CUser *pUser)
{
/*
	CNetMessage msg;
	msg.SetType(PRO_USER_LIST);
	boost::recursive_mutex::scoped_lock lk(m_mutex);

	list<uint32>::iterator iter = m_userList.begin();

	uint8 num = 0;
	uint8 pos = msg.GetDataLen();
	msg << num;
	for (; iter != m_userList.end(); iter++)
	{
		ShareUserPtr p = m_onlineUser.GetUserByRoleId(*iter);
		if (p.get() != NULL)
		{
			if((p->GetTeam() != 0) && (p->GetTeam() != p->GetRoleId()))
				continue;
			if(num >= SEND_MAX_USER_NUM)
				break;
			num++;
			msg<< p->GetRoleId();

			uint32 teamId = p->GetTeam();
			CUserTeam *pTeam = NULL;
			if(teamId != 0)
				m_userTeams.Find(teamId, pTeam);
			if(pTeam != NULL)
			{
				//     有队伍    在队中
				msg<<(uint8)1<<(uint32)0;
			}
			else
			{
				//		无队伍
				msg<<(uint8)0<<p->TempLeaveTeam();
			}
			msg<<p->GetX()<<p->GetY()<<p->GetFace()<<p->GetName()<<p->GetSex()<<p->GetXiang()<<p->GetLevel();
			msg<<p->GetBangPai()<<p->GetBangPaiRank()<<p->GetBangPaiName()<<p->GetBangPaiShowInfo();
#ifdef KUA_FU
			msg<<GetServerZone(p->GetServerId())<<p->GetServerId();
#endif

			if(pTeam != NULL)
			{
				uint32 members[MAX_TEAM_MEMBER];
				uint8 memNum = 0;
				pTeam->GetMember(members, memNum);
				uint16 pos = msg.GetDataLen();
				uint8 sendNum = 0;
				msg << sendNum;
				for(uint8 i = 1; i < memNum; i++)
				{
					ShareUserPtr p1 = m_onlineUser.GetUserByRoleId(members[i]);
					if(p1.get() != NULL)
					{
						msg<<members[i]<<p1->GetName()<<p1->GetSex()<<p1->GetXiang()<<p1->GetLevel();
						msg<<p1->GetBangPai()<<p1->GetBangPaiRank()<<p1->GetBangPaiName()<<p1->GetBangPaiShowInfo();
#ifdef KUA_FU
						msg<<GetServerZone(p1->GetServerId())<<p1->GetServerId();
#endif
						sendNum++;
					}
				}
				msg.WriteData(pos,&sendNum,sizeof(sendNum));
			}
			else
			{
				msg << (uint8)0;
			}
		}
	}
	// 飞仙角色机器人显示
	if(m_srcSceneId >= FEI_XIAN_SID1 && m_srcSceneId <= FEI_XIAN_SID4)
	{
		for(list<ShareUserPtr>::iterator i=m_visibleRobot.begin();i != m_visibleRobot.end();i++)
		{
			if((*i).get() != NULL)
			{
				if(num >= SEND_MAX_USER_NUM)
					break;
				num++;
				msg<<(*i)->GetRoleId()<<(uint8)0<<(uint32)0<<(*i)->GetX()<<(*i)->GetY()<<(*i)->GetFace()
					<<(*i)->GetName()<<(*i)->GetSex()<<(*i)->GetXiang()<<(*i)->GetLevel()
					<<(*i)->GetBangPai()<<(*i)->GetBangPaiRank()<<(*i)->GetBangPaiName()<<(*i)->GetBangPaiShowInfo();

#ifdef KUA_FU
				msg<<GetServerZone((*i)->GetServerId())<<(*i)->GetServerId();
#endif
				msg<<(uint8)0;
			}
		}
	}
	msg.WriteData(pos, &num, sizeof(num));
	m_socketServer.SendMsg(pUser->GetSock(), msg);

//	if (m_visibleMonsters.size() > 0)
//	{
//		msg.ReWrite();
//		msg.SetType(MSG_SERVER_MONSTER);
//		msg << (uint8)m_visibleMonsters.size();
//		for (list<SVisibleMonster>::iterator i = m_visibleMonsters.begin();
//				i != m_visibleMonsters.end(); i++)
//		{
//			msg << i->id << i->x << i->y << i->face << i->type << i->pic;
//		}
//		m_socketServer.SendMsg(pUser->GetSock(), msg);
//	}

	msg.ReWrite();
	msg.SetType(MSG_MONSTER_OPTION);
	msg<<(uint8)1;
	uint8 monsterNum = 0;
	pos = msg.GetDataLen();
	msg<<monsterNum;
	{
		boost::recursive_mutex::scoped_lock lk(m_monster_mutex);
		for(list<SMonsterListInfo>::iterator i = m_MonsterList.begin();i != m_MonsterList.end();i++)
		{
			for(list<SVisibleMonster>::iterator j = i->monsterList.begin(); j != i->monsterList.end();j++)
			{
				uint8 level = (uint8)((j->monster_id - 1)/2*5 + 1);
				monsterNum++;
				msg<<j->id<<j->name<<(int)j->monster_id<<j->pic<<(uint16)level<<j->x<<j->y<<j->face<<(uint8)1;	// 野怪
//				cout<<">>> scene = "<<GetId()<<", monster: id="<<j->id<<", monsterId="<<j->monster_id<<", x="<<j->x<<", y="<<j->y<<", face="<<(int)j->face<<endl;
			}
		}
		for(list<SVisibleMonsterBoss>::iterator i = m_visibleMonstersBoss.begin();i != m_visibleMonstersBoss.end();i++)
		{
			if(i->isVisible)
			{
				monsterNum++;
				int monsterId = i->monsterId;
				msg<<i->id<<i->name<<monsterId<<i->pic<<(uint16)0<<i->x<<i->y<<i->face<<(uint8)2;		// boss怪
			}
		}
	}
	msg.WriteData(pos,&monsterNum,sizeof(monsterNum));
	m_socketServer.SendMsg(pUser->GetSock(),msg);

//	if (m_npcList.size() <= 0)
//	{
//		msg.ReWrite();
//		msg.SetType(PRO_NPC_LIST);
//		pos = msg.GetDataLen();
//		msg << num;
//		num = pUser->AddNpcInfo(m_mapId, msg);//(m_id,msg);
//
//		if (num > 0)
//		{
//			msg.WriteData(pos, &num, 1);
//			m_socketServer.SendMsg(pUser->GetSock(), msg);
//		}
//		return;
//	}

#ifdef DEBUG
	cout << "send npc list to:" << pUser->GetRoleId() << endl;
#endif

	CNpcManager &npcManager = SingletonNpcManager::instance();
	list<uint16>::iterator i = m_npcList.begin();
	msg.ReWrite();
	msg.SetType(PRO_NPC_LIST);
	pos = msg.GetDataLen();
	msg << (uint8)m_npcList.size();
	for (; i != m_npcList.end(); i++)
	{
		SNpcInstance *pInst = npcManager.GetNpcInstance(*i);
		if (pInst != NULL)
		{
			//msg<<pInst->id<<pInst->pNpc->name<<pInst->x<<pInst->y<<pInst->pNpc->pic;
			pInst->MakeNpcInfo(msg);
		}
	}
	num = pUser->AddNpcInfo(m_srcSceneId, msg);//(m_id,msg);
	num += pUser->AddCollectInfo(m_srcSceneId, msg);
	num += m_npcList.size();
	if (m_dynamicNpc.size() > 0)
	{
		for (list<SNpcInstance*>::iterator i = m_dynamicNpc.begin(); i != m_dynamicNpc.end(); i++)
		{
			num++;
			(*i)->MakeNpcInfo(msg);
		}
	}
	if (num > 0)
	{
		msg.WriteData(pos, &num, 1);
	}
	m_socketServer.SendMsg(pUser->GetSock(), msg);
*/
}

void CScene::Enter(CUser *pUser)
{
/*
	if(pUser == NULL)
		return;
	if(m_srcSceneId == FEI_XIAN_SID5)	// 第一个进入添加飞仙状态
	{
		if(m_userList.empty())
			pUser->SetFeiXianState(1);
	}
	
	CNetMessage msg;
	if (m_addJump)
	{
		msg.ReWrite();
		msg.SetType(MSG_SERVER_JUMP_POINT);
		msg << (uint8)0 << m_jumpPoint.x << m_jumpPoint.y;
		m_socketServer.SendMsg(pUser->GetSock(), msg);
	}

	
	msg.ReWrite();
	msg.SetType(PRO_USER_LIST);
	//boost::recursive_mutex::scoped_lock lk(m_mutex);
	//m_userList.remove(pUser->GetRoleId());
	m_userList.push_front(pUser->GetRoleId());

	uint8 num = 1;
	uint8 pos = msg.GetDataLen();
	msg << num;

	{
		uint32 teamId = pUser->GetTeam();
		CUserTeam *pTeam = NULL;
		if(teamId != 0)
			m_userTeams.Find(teamId, pTeam);
		if(pTeam == NULL)
		{
			msg<<pUser->GetRoleId()<<(uint8)0<<pUser->TempLeaveTeam()<<pUser->GetX()<<pUser->GetY()<<pUser->GetFace()
				<<pUser->GetName()<<pUser->GetSex()<<pUser->GetXiang()<<pUser->GetLevel();
			msg<<pUser->GetBangPai()<<pUser->GetBangPaiRank()<<pUser->GetBangPaiName()<<pUser->GetBangPaiShowInfo();
#ifdef KUA_FU
			msg<<GetServerZone(pUser->GetServerId())<<pUser->GetServerId();
#endif
		}
		else
		{
			msg<<teamId<<(uint8)1<<(uint32)0;
			ShareUserPtr pHead = m_onlineUser.GetUserByRoleId(teamId);
			if(pHead.get() != NULL)
			{
				msg<<pHead->GetX()<<pHead->GetY()<<pHead->GetFace()<<pHead->GetName()<<pHead->GetSex()<<pHead->GetXiang()<<pHead->GetLevel();
				msg<<pHead->GetBangPai()<<pHead->GetBangPaiRank()<<pHead->GetBangPaiName()<<pHead->GetBangPaiShowInfo();
#ifdef KUA_FU
				msg<<GetServerZone(pHead->GetServerId())<<pHead->GetServerId();
#endif
			}
			else
			{
				msg<<pUser->GetX()<<pUser->GetY()<<pUser->GetFace()<<pUser->GetName()<<pUser->GetSex()<<pUser->GetXiang()<<pUser->GetLevel();
				msg<<pUser->GetBangPai()<<pUser->GetBangPaiRank()<<pUser->GetBangPaiName()<<pUser->GetBangPaiShowInfo();
#ifdef KUA_FU
				msg<<GetServerZone(pUser->GetServerId())<<pUser->GetServerId();
#endif
			}
		}
		
		if(pTeam != NULL)
		{
			uint32 members[MAX_TEAM_MEMBER];
			uint8 memNum = 0;
			pTeam->GetMember(members, memNum);
			uint16 pos = msg.GetDataLen();
			uint8 sendNum = 0;
			msg << sendNum;
			for(uint8 i = 1; i < memNum; i++)
			{
				ShareUserPtr p1 = m_onlineUser.GetUserByRoleId(members[i]);
				if(p1.get() != NULL)
				{
					msg<<members[i]<<p1->GetName()<<p1->GetSex()<<p1->GetXiang()<< p1->GetLevel();
					msg<<p1->GetBangPai()<<p1->GetBangPaiRank()<<p1->GetBangPaiName()<<p1->GetBangPaiShowInfo();
#ifdef KUA_FU
					msg<<GetServerZone(p1->GetServerId())<<p1->GetServerId();
#endif
					sendNum++;
				}
			}
			msg.WriteData(pos,&sendNum,sizeof(sendNum));
		}
		else
		{
			msg<<(uint8)0;
		}
	}
	list<uint32>::iterator iter = m_userList.begin();
	iter++;
	for(; iter != m_userList.end(); iter++)
	{
		ShareUserPtr p = m_onlineUser.GetUserByRoleId(*iter);
		if (p.get() != NULL)
		{
			if(pUser->GetTeam() == p->GetRoleId())
				continue;
			if ((p->GetTeam() != 0) && (p->GetTeam() != p->GetRoleId()))
				continue;
			if (num >= SEND_MAX_USER_NUM)
				break;
			num++;
			msg<< p->GetRoleId();

			uint32 teamId = p->GetTeam();
			CUserTeam *pTeam = NULL;
			if(teamId != 0)
				m_userTeams.Find(teamId, pTeam);
			if(pTeam != NULL)
			{
				//     有队伍    在队中
				msg<<(uint8)1<<(uint32)0;
			}
			else
			{
				//		无队伍
				msg<<(uint8)0<<p->TempLeaveTeam();
			}
			msg<<p->GetX()<<p->GetY()<<p->GetFace()<<p->GetName()<<p->GetSex()<<p->GetXiang()<<p->GetLevel();
			msg<<p->GetBangPai()<<p->GetBangPaiRank()<<p->GetBangPaiName()<<p->GetBangPaiShowInfo();
#ifdef KUA_FU
			msg<<GetServerZone(p->GetServerId())<<p->GetServerId();
#endif
			
			if(pTeam != NULL)
			{
				uint32 members[MAX_TEAM_MEMBER];
				uint8 memNum = 0;
				pTeam->GetMember(members, memNum);
				uint16 pos = msg.GetDataLen();
				uint8 sendNum = 0;
				msg << sendNum;
				for(uint8 i = 1; i < memNum; i++)
				{
					ShareUserPtr p1 = m_onlineUser.GetUserByRoleId(members[i]);
					if(p1.get() != NULL)
					{
						msg<<members[i]<<p1->GetName()<<p1->GetSex()<<p1->GetXiang()<<p1->GetLevel();
						msg<<p1->GetBangPai()<<p1->GetBangPaiRank()<<p1->GetBangPaiName()<<p1->GetBangPaiShowInfo();
#ifdef KUA_FU
						msg<<GetServerZone(p1->GetServerId())<<p1->GetServerId();
#endif
						sendNum++;
					}
				}
				msg.WriteData(pos,&sendNum,sizeof(sendNum));
			}
			else
			{
				msg << (uint8)0;
			}
		}
	}
	// 飞仙角色机器人显示
	if(m_srcSceneId >= FEI_XIAN_SID1 && m_srcSceneId <= FEI_XIAN_SID4)
	{
		for(list<ShareUserPtr>::iterator i=m_visibleRobot.begin();i != m_visibleRobot.end();i++)
		{
			if((*i).get() != NULL)
			{
				if(num >= SEND_MAX_USER_NUM)
					break;
				num++;
				msg<<(*i)->GetRoleId()<<(uint8)0<<(uint32)0<<(*i)->GetX()<<(*i)->GetY()<<(*i)->GetFace()
					<<(*i)->GetName()<<(*i)->GetSex()<<(*i)->GetXiang()<<(*i)->GetLevel()
					<<(*i)->GetBangPai()<<(*i)->GetBangPaiRank()<<(*i)->GetBangPaiName()<<(*i)->GetBangPaiShowInfo();
#ifdef KUA_FU
				msg<<GetServerZone((*i)->GetServerId())<<(*i)->GetServerId();
#endif
				msg<<(uint8)0;
			}
		}
	}
	
	msg.WriteData(pos, &num, sizeof(num));
	m_socketServer.SendMsg(pUser->GetSock(), msg);

	if ((pUser->GetTeam() == 0) || (pUser->GetTeam() == pUser->GetRoleId()))
	{
		msg.ReWrite();
		msg.SetType(PRO_IN_OUT_SCENE);
		uint32 teamId = 0;
		if(pUser->GetRoleId() == pUser->GetTeam())
			teamId = pUser->GetTeam();
		//								进入场景
		msg << pUser->GetRoleId() << (uint8)1;
		
		CUserTeam *pTeam = NULL;
		if(teamId != 0)
			m_userTeams.Find(teamId, pTeam);
		if(pTeam != NULL)
			msg<<(uint8)1<<(uint32)0;
		else
			msg<<(uint8)0<<pUser->TempLeaveTeam();
		msg<<pUser->GetX()<<pUser->GetY()<<pUser->GetFace()<<pUser->GetName()<<pUser->GetSex()<<pUser->GetXiang()<<pUser->GetLevel();
		msg<<pUser->GetBangPai()<<pUser->GetBangPaiRank()<<pUser->GetBangPaiName()<<pUser->GetBangPaiShowInfo();
#ifdef KUA_FU
		msg<<GetServerZone(pUser->GetServerId())<<pUser->GetServerId();
#endif
		
		if(pTeam != NULL)
		{
			uint32 members[MAX_TEAM_MEMBER];
			uint8 memNum = 0;
			pTeam->GetMember(members, memNum);
			uint16 pos = msg.GetDataLen();
			uint8 sendNum = 0;
			msg << sendNum;
			for(uint8 i = 1; i < memNum; i++)
			{
				ShareUserPtr p1 = m_onlineUser.GetUserByRoleId(members[i]);
				if(p1.get() != NULL)
				{
					msg<<members[i]<<p1->GetName()<<p1->GetSex()<<p1->GetXiang()<<p1->GetLevel();
					msg<<p1->GetBangPai()<<p1->GetBangPaiRank()<<p1->GetBangPaiName()<<p1->GetBangPaiShowInfo();
#ifdef KUA_FU
					msg<<GetServerZone(p1->GetServerId())<<p1->GetServerId();
#endif
					sendNum++;
				}
			}
			msg.WriteData(pos,&sendNum,sizeof(sendNum));
		}
		else
		{
			msg << (uint8)0;
		}
		BroadcastMsgExceptSameTeam(pUser, msg);
	}
//	if (m_visibleMonsters.size() > 0)
//	{
//		msg.ReWrite();
//		msg.SetType(MSG_SERVER_MONSTER);
//		msg << (uint8)m_visibleMonsters.size();
//		for (list<SVisibleMonster>::iterator i = m_visibleMonsters.begin();i != m_visibleMonsters.end(); i++)
//		{
//			msg << i->id << i->x << i->y << i->face << i->type << i->pic;
//		}
//		m_socketServer.SendMsg(pUser->GetSock(), msg);
//	}


//	msg.ReWrite();
//	msg.SetType(MSG_MONSTER_OPTION);
//	msg<<(uint8)1<<(uint8)m_visibleMonsters.size();

//	for(list<SVisibleMonster>::iterator i = m_visibleMonsters.begin();i != m_visibleMonsters.end();i++)
//	{
//		msg<<i->id<<i->monster_id<<i->x<<i->y<<i->face;

//		cout<<">>> scene = "<<GetId()<<", monster: id="<<i->id<<", monsterId="<<i->monster_id<<", x="<<i->x<<", y="<<i->y<<", face="<<(int)i->face<<endl;
//	}
//	m_socketServer.SendMsg(pUser->GetSock(),msg);

	msg.ReWrite();
	msg.SetType(MSG_MONSTER_OPTION);
	msg<<(uint8)1;
	uint8 monsterNum = 0;
	pos = msg.GetDataLen();
	msg<<monsterNum;
	{
		boost::recursive_mutex::scoped_lock lk(m_monster_mutex);
		for(list<SMonsterListInfo>::iterator i = m_MonsterList.begin();i != m_MonsterList.end();i++)
		{
			for(list<SVisibleMonster>::iterator j = i->monsterList.begin(); j != i->monsterList.end();j++)
			{
				uint8 level = (uint8)((j->monster_id - 1)/2*5 + 1);
				monsterNum++;
				msg<<j->id<<j->name<<(int)j->monster_id<<j->pic<<(uint16)level<<j->x<<j->y<<j->face<<(uint8)1;	// 野怪
				
//				cout<<">>> scene = "<<GetId()<<", monster: id="<<j->id<<", monsterId="<<j->monster_id<<", x="<<j->x<<", y="<<j->y<<", face="<<(int)j->face<<endl;
			}
		}
		for(list<SVisibleMonsterBoss>::iterator i = m_visibleMonstersBoss.begin();i != m_visibleMonstersBoss.end();i++)
		{
			if (i->step != 0) // 配置阶段的怪物不显示在地图上
			{
				i->isVisible = false;
				continue;
			}
			monsterNum++;
			int monId = i->monsterId;
			msg<<i->id<<i->name<<monId<<i->pic<<(uint16)0<<i->x<<i->y<<i->face<<(uint8)2;		// boss怪

			//cout<<">>> Boss scene = "<<GetId()<<", monster: id="<<i->id<<", monsterId="<<i->pic<<", x="<<i->x<<", y="<<i->y<<", face="<<(int)i->face<<",name="<<i->name<<endl;
		}
		monsterNum += pUser->MakeMonsterInfo(m_mapId,msg);
	}
	msg.WriteData(pos,&monsterNum,sizeof(monsterNum));
	m_socketServer.SendMsg(pUser->GetSock(),msg);

	//{ // 魔豹副本问题查询
	//	if (m_srcSceneId != 0)
	//	{
	//		cout << "副本刷怪完成！" << endl;
	//	}
	//}

//	if (m_npcList.size() <= 0)
//	{
//		msg.ReWrite();
//		msg.SetType(PRO_NPC_LIST);
//		pos = msg.GetDataLen();
//		msg << num;
//		num = pUser->AddNpcInfo(m_mapId, msg);//(m_id,msg);

//		if (num > 0)
//		{
//			msg.WriteData(pos, &num, 1);
//			m_socketServer.SendMsg(pUser->GetSock(), msg);
//		}
//		return;
//	}

#ifdef DEBUG
	cout << "send npc list to:" << pUser->GetRoleId() << endl;
#endif

	CNpcManager &npcManager = SingletonNpcManager::instance();
	list<uint16>::iterator i = m_npcList.begin();
	msg.ReWrite();
	msg.SetType(PRO_NPC_LIST);
	pos = msg.GetDataLen();
	msg << (uint8)m_npcList.size();
	for (; i != m_npcList.end(); i++)
	{
		SNpcInstance *pInst = npcManager.GetNpcInstance(*i);
		if (pInst != NULL)
		{
			//msg<<pInst->id<<pInst->pNpc->name<<pInst->x<<pInst->y<<pInst->pNpc->pic;
			pInst->MakeNpcInfo(msg);
		}
	}
	num = pUser->AddNpcInfo(m_srcSceneId, msg);//(m_id,msg);
	num += pUser->AddCollectInfo(m_srcSceneId, msg);
	num += m_npcList.size();
	if (m_dynamicNpc.size() > 0)
	{
		for (list<SNpcInstance*>::iterator i = m_dynamicNpc.begin(); i != m_dynamicNpc.end(); i++)
		{
			num++;
			(*i)->MakeNpcInfo(msg);
		}
	}
	if (num > 0)
	{
		msg.WriteData(pos, &num, 1);
	}
	m_socketServer.SendMsg(pUser->GetSock(), msg);
*/
}

void CScene::MakeNearPlayerList(CUser *pUser, uint8 page, CNetMessage &msg)
{
/*
	page -= 1;

	uint8 num = 0;
	uint8 pos = msg.GetDataLen();
	msg << num;

	boost::recursive_mutex::scoped_lock lk(m_mutex);

	list<uint32>::iterator iter = m_userList.begin();
//	for(int i = 0; i < ONE_PAGE_MAX_NUM * page; i++)
//	{
//		if(iter != m_userList.end())
//		{
//			iter++;
//		}
//		else
//		{
//			return;
//		}
//	}

	for (; iter != m_userList.end(); iter++)
	{
		ShareUserPtr p = m_onlineUser.GetUserByRoleId(*iter);
		if ((p.get() == NULL) || (p->GetRoleId() == pUser->GetRoleId()))
			continue;
		num++;
		msg << p->GetRoleId() << p->GetName() << p->GetLevel();
		if (num >= 50)
			break;
	}
	msg.WriteData(pos, &num, sizeof(num));
*/
}

void CScene::PlayerAskForMatch(ShareUserPtr pUser, uint32 roleId)
{
	if (m_fightStep != 1)
	{
		SendSysInfo(pUser.get(), MakeStringColor(LANGUAGE_TRANSFORM_2678,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	if(roleId == 0)
		return;

	ShareUserPtr p = m_onlineUser.GetUserByRoleId(roleId);
	if(p.get() == NULL)
	{
		SendSysInfo(pUser.get(), MakeStringColor(LANGUAGE_TRANSFORM_2679,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	if(p->GetScene() != this)
	{
		SendSysInfo(pUser.get(), MakeStringColor(LANGUAGE_TRANSFORM_2680,TIPS_FAILURE_COLOR).c_str());
		return;
	}

	uint32 teamId = p->GetTeam();
	if(teamId != 0)
	{
		p = m_onlineUser.GetUserByRoleId(teamId);
		if(p.get() == NULL)
		{
			SendSysInfo(pUser.get(), MakeStringColor(LANGUAGE_TRANSFORM_2681,TIPS_FAILURE_COLOR).c_str());
			return;
		}
	}
/*
	if(pUser->HaveIgnore(roleId))
	{
		SendSysInfo(pUser.get(), MakeStringColor(LANGUAGE_TRANSFORM_2682,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	if(p->HaveIgnore(pUser->GetRoleId()))
	{
		SendSysInfo(pUser.get(), MakeStringColor(LANGUAGE_TRANSFORM_2683,TIPS_FAILURE_COLOR).c_str());
		return;
	}
*/
	if(p->GetKuaFuState() != EKFS_IN_LOCAL)
		return;
	if(p->GetFightId() != 0)
	{
		SendSysInfo(pUser.get(), MakeStringColor(LANGUAGE_TRANSFORM_2684,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	if((pUser->GetTeam() != 0) && (p->GetTeam() == pUser->GetTeam()))
		return;

	{
		uint32 tId = pUser->GetTeam();
		if(tId == 0)
			tId = pUser->TempLeaveTeam();
		uint32 tartId = p->GetTeam();
		if(tartId == 0)
			tartId = p->TempLeaveTeam();
		if(tId != 0 && tId == tartId)
		{
			SendSysInfo(pUser.get(), MakeStringColor(LANGUAGE_TRANSFORM_2685,TIPS_FAILURE_COLOR).c_str());
			return;
		}
	}
#ifdef KUA_FU
	if(pUser->GetScene()->GetSrcSceneId() == SHENJIEMIJING_SCENE_ID)
	{
		if( !SingletonCShenJieMiJingManager::instance().CanFight(pUser.get()))
		{
			SendInfoToMe( pUser.get(),TIPS_FAILURE_COLOR,LANGUAGE_CHY_70);
			return;
		}
		if( !SingletonCShenJieMiJingManager::instance().CanFight(p.get()))
		{
			SendInfoToMe( pUser.get(),TIPS_FAILURE_COLOR,LANGUAGE_CHY_71);
			return;
		}
	}
/*	else if(m_srcSceneId == KUA_FU_SCENE_ID)
	{
		if(abs((int)pUser->GetLevel() - (int)p->GetLevel()) > 10)
		{
			SendInfoToMe(pUser.get(),TIPS_FAILURE_COLOR,LANGUAGE_SSJ_0114);
			return;
		}
	}
*/
#endif
	//屏蔽切磋功能
	if(p->GetIgnoreQieCuo())
	{
		SendInfoToMe( pUser.get(),TIPS_FAILURE_COLOR,LANGUAGE_CHY_125);
		return;
	}
	
	CNetMessage msg;
	msg.SetType(PRO_PLYAER_MATCH);
	msg << (uint8)1 << pUser->GetRoleId() << pUser->GetName();
	m_socketServer.SendMsg(p->GetSock(), msg);

	p->AddAskForMatchUser(pUser->GetRoleId());
}

void CScene::AcceptAskForMatch(ShareUserPtr pUser, bool accept, uint32 roleId)
{
	ShareUserPtr p = m_onlineUser.GetUserByRoleId(roleId);

	if (p.get() == NULL)
	{
		SendSysInfo(pUser.get(), MakeStringColor(LANGUAGE_TRANSFORM_2686,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	if (!pUser->InAskForMatchUser(p->GetRoleId()))
	{
		return;
	}

	if(p->GetKuaFuState() != EKFS_IN_LOCAL)
		return;
	if ((p->GetFightId() != 0) || (pUser->GetFightId() != 0))
	{
		SendSysInfo(pUser.get(), MakeStringColor(LANGUAGE_TRANSFORM_2687,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	if (p->GetScene() != pUser->GetScene())
	{
		SendSysInfo(pUser.get(), MakeStringColor(LANGUAGE_TRANSFORM_2688,TIPS_FAILURE_COLOR).c_str());
		return;
	}

	CNetMessage msg;
	msg.SetType(PRO_PLYAER_MATCH);

	if (!accept)
	{
		msg << (uint8)2 << (uint8)0;
		m_socketServer.SendMsg(p->GetSock(), msg);
		pUser->DelAskForMatchUser(roleId);
		return;
	}
	if ((pUser->GetTeam() != 0) && (pUser->GetTeam() == p->GetTeam()))
	{
		return;
	}

	ShareFightPtr pFight = m_fightManager.CreateFight();
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		pUser->ClearAskForMatchUser();

		pFight->SetFightType(CFight::EFTPlayerQieCuo);
		pFight->SetFightChooseMode();
		AddUserGroupToBattle(pFight,pUser,0);
		AddUserGroupToBattle(pFight,p);
		pFight->BeginFight(this);
	}
	m_fightManager.AddFight(pFight);
}

void CScene::SceneChat(CNetMessage &msg,int ignoreId)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	BroadcastMsg(msg, true, ignoreId);
}

static void SendChatMsg(ShareUserPtr pUser, CSocketServer *pSock, CNetMessage *msg)
{
	if ((pUser->GetChatChannel() & 4) != 0)
		pSock->SendMsg(pUser->GetSock(), *msg);
}

void CScene::TeamChat(uint32 teamId, CNetMessage &msg,int ignoreId)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	//ForEachTeamMember(teamId,boost::bind(SendChatMsg,_1,&m_socketServer,&msg));
	CUserTeam *pTeam = NULL;
	if (!m_userTeams.Find(teamId, pTeam))
		return;

	uint32 members[MAX_TEAM_MEMBER];
	uint8 num = 0;
	pTeam->GetMember(members, num);
	for (uint8 i = 0; i < num; i++)
	{
		ShareUserPtr p = m_onlineUser.GetUserByRoleId(members[i]);
		if (p.get() != NULL)
		{
			if(ignoreId > 0 && SingletonCFriendMgr::instance().IsInBlackList(p->GetRoleId(), ignoreId))
				continue;
			SendChatMsg(p, &m_socketServer, &msg);
		}
	}
	num = 0;
	pTeam->GetLeaveMem(members, num);
	for (uint8 i = 0; i < num; i++)
	{
		ShareUserPtr p = m_onlineUser.GetUserByRoleId(members[i]);
		if (p.get() != NULL)
		{
			if(ignoreId > 0 && SingletonCFriendMgr::instance().IsInBlackList(p->GetRoleId(), ignoreId))
				continue;
			SendChatMsg(p, &m_socketServer, &msg);
		}
	}
}

void CScene::AddNpcIndexByFightId(uint16 tmplId,int fightId,uint16 x, uint16 y, uint8 direct,uint16 index,uint16 pic,uint8 color)
{
	CNpcManager &npcManager = SingletonNpcManager::instance();
	SNpcTemplate *pNpc = npcManager.GetNpcTemplate(tmplId);
	if(pNpc == NULL)
		return;
	int fightIdPic = 0;
	string bossName;
	int bossId = 0;
	if(!SingletonCFightCfgManager::instance().GetFirstBossInfo(fightId,fightIdPic,bossName,bossId))
		return;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	SNpcInstance *pInst = new SNpcInstance();
	pInst->id = tmplId;
	pInst->fightId = fightId;
	pInst->direct = direct;
	pInst->templateId = tmplId;
	pInst->pNpc = pNpc;
	pInst->sceneId = m_mapId;
	pInst->x = x;
	pInst->y = y;
	pInst->index = index;
	if(pic != 0)
		pInst->pic = pic;
	else
		pInst->pic = fightIdPic;
	pInst->type = 2;
	pInst->nameColor = color;
	pInst->name = bossName;
	m_dynamicNpc.push_back(pInst);

	CNetMessage msg;
	msg.SetType(PRO_ADD_NPC);
	pInst->MakeNpcInfo(msg);
	for(list<uint32>::iterator i = m_userList.begin(); i != m_userList.end(); i++)
	{
		ShareUserPtr ptr = m_onlineUser.GetUserByRoleId(*i);
		CUser *pUser = ptr.get();
		if(pUser != NULL)
			m_socketServer.SendMsg(pUser->GetSock(), msg);
	}
}

void CScene::AddNpcWithIndex(uint16 tmplId,uint16 pic, uint16 x, uint16 y, uint8 direct,uint16 index,const char *name,uint8 type,uint8 color)
{
	CNpcManager &npcManager = SingletonNpcManager::instance();
	SNpcTemplate *pNpc = npcManager.GetNpcTemplate(tmplId);
	if(pNpc == NULL)
		return;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	SNpcInstance *pInst = new SNpcInstance();
	pInst->id = tmplId;
	pInst->direct = direct;
	pInst->templateId = tmplId;
	pInst->pNpc = pNpc;
	pInst->sceneId = m_mapId;
	pInst->x = x;
	pInst->y = y;
	pInst->index = index;
	pInst->pic = pic;
	pInst->type = type;
	pInst->nameColor = color;
	if(name != NULL)
		pInst->name = name;
	m_dynamicNpc.push_back(pInst);

	CNetMessage msg;
	msg.SetType(PRO_ADD_NPC);
	pInst->MakeNpcInfo(msg);
	for(list<uint32>::iterator i = m_userList.begin(); i != m_userList.end(); i++)
	{
		ShareUserPtr ptr = m_onlineUser.GetUserByRoleId(*i);
		CUser *pUser = ptr.get();
		if(pUser != NULL)
			m_socketServer.SendMsg(pUser->GetSock(), msg);
	}
}

void CScene::AddNpc(uint16 tmplId, uint16 x, uint16 y, uint8 direct)
{
	CNpcManager &npcManager = SingletonNpcManager::instance();
	SNpcTemplate *pNpc = npcManager.GetNpcTemplate(tmplId);
	if (pNpc == NULL)
		return;

	boost::recursive_mutex::scoped_lock lk(m_mutex);

	SNpcInstance *pInst = new SNpcInstance();
	pInst->id = tmplId;
	pInst->direct = direct;
	pInst->templateId = tmplId;
	pInst->pNpc = pNpc;
	pInst->sceneId = m_mapId;
	pInst->x = x;
	pInst->y = y;
	m_dynamicNpc.push_back(pInst);

	CNetMessage msg;

	for (list<uint32>::iterator i = m_userList.begin(); i != m_userList.end(); i++)
	{
		ShareUserPtr ptr = m_onlineUser.GetUserByRoleId(*i);
		CUser *pUser = ptr.get();
		if (pUser != NULL)
		{
			msg.SetType(PRO_ADD_NPC);
			pInst->MakeNpcInfo(msg);
			m_socketServer.SendMsg(pUser->GetSock(), msg);
		}
	}
}

void CScene::AddNpc(uint16 tmplId,int n, uint16 x, uint16 y, uint8 direct)
{
	CNpcManager &npcManager = SingletonNpcManager::instance();
	SNpcTemplate *pNpc = npcManager.GetNpcTemplate(tmplId);
	if (pNpc == NULL)
		return;

	boost::recursive_mutex::scoped_lock lk(m_mutex);

	SNpcInstance *pInst = new SNpcInstance();
	pInst->id = tmplId+n;
	pInst->direct = direct;
	pInst->templateId = tmplId;
	pInst->pNpc = pNpc;
	pInst->sceneId = m_mapId;
	pInst->x = x;
	pInst->y = y;
	m_dynamicNpc.push_back(pInst);

	CNetMessage msg;

	for (list<uint32>::iterator i = m_userList.begin(); i != m_userList.end(); i++)
	{
		ShareUserPtr ptr = m_onlineUser.GetUserByRoleId(*i);
		CUser *pUser = ptr.get();
		if (pUser != NULL)
		{
			msg.SetType(PRO_ADD_NPC);
			pInst->MakeNpcInfo(msg);
			m_socketServer.SendMsg(pUser->GetSock(), msg);
		}
	}
}

void CScene::ModifyNpcPos(uint16 id, uint16 x, uint16 y)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for (list<SNpcInstance*>::iterator i = m_dynamicNpc.begin(); i != m_dynamicNpc.end(); i++)
	{
		if ((*i)->id == id)
		{
			(*i)->x = x;
			(*i)->y = y;
			return;
		}
	}
}

void CScene::AddNpc(uint16 id, bool sendMsg)
{
	CNpcManager &npcManager = SingletonNpcManager::instance();
	SNpcTemplate *pNpc = npcManager.GetNpcTemplate(id);
	if (pNpc == NULL)
		return;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if (m_dynamicNpcPoint.size() <= 0)
		return;

	uint8 pos = Random(1, m_dynamicNpcPoint.size());
	pos -= 1;
	uint16 x, y;
	x = m_dynamicNpcPoint[pos].x;
	y = m_dynamicNpcPoint[pos].y;
	m_dynamicNpcPoint.erase(m_dynamicNpcPoint.begin() + pos);

	SNpcInstance *pInst = new SNpcInstance();
	pInst->id = id;
	pInst->templateId = id;
	pInst->pNpc = pNpc;
	pInst->sceneId = m_mapId;
	pInst->x = x;
	pInst->y = y;
	m_dynamicNpc.push_back(pInst);

	if (sendMsg)
	{
		CNetMessage msg;

		for (list<uint32>::iterator i = m_userList.begin(); i != m_userList.end(); i++)
		{
			ShareUserPtr ptr = m_onlineUser.GetUserByRoleId(*i);
			CUser *pUser = ptr.get();
			if (pUser != NULL)
			{
				msg.SetType(PRO_ADD_NPC);
				pInst->MakeNpcInfo(msg);
				m_socketServer.SendMsg(pUser->GetSock(), msg);
			}
		}
	}
}

SNpcInstance *CScene::FindFaceNpc(CUser *pUser)
{
	if(pUser == NULL)
		return NULL;
	uint8 x;
	uint8 y;
	pUser->GetFacePos(x,y);
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for (list<SNpcInstance*>::iterator i = m_dynamicNpc.begin(); i != m_dynamicNpc.end(); i++)
	{
		if (((*i)->x == x) && ((*i)->y == y))
		{
			return *i;
		}
	}
	return NULL;
}

SNpcInstance *CScene::FindNpcByPos(uint16 x, uint16 y)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);

	for (list<SNpcInstance*>::iterator i = m_dynamicNpc.begin(); i != m_dynamicNpc.end(); i++)
	{
		if (((*i)->x == x) && ((*i)->y == y))
		{
			return *i;
		}
	}
	return NULL;
}

SNpcInstance *CScene::FindNpc(uint16 id,uint16 index)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);

	for (list<SNpcInstance*>::iterator i = m_dynamicNpc.begin(); i != m_dynamicNpc.end(); i++)
	{
		if ((*i)->id == id && (*i)->index == index)
		{
			return *i;
		}
	}
	return NULL;
}

void CScene::InitNpcPoint(SPoint *pPoint, uint8 num)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_dynamicNpcPoint.clear();
	for (uint8 i = 0; i < num; i++)
	{
		m_dynamicNpcPoint.push_back(pPoint[i]);
	}
}

void CScene::DelNpc(uint16 id,uint16 index)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for (list<SNpcInstance*>::iterator i = m_dynamicNpc.begin(); i != m_dynamicNpc.end(); i++)
	{
		if ((*i)->id == id && (*i)->index == index)
		{
			CNetMessage msg;
			msg.SetType(PRO_DEL_NPC);
			msg <<(*i)->id<<(uint16)index;
			BroadcastMsg(msg);

			delete *i;
			m_dynamicNpc.erase(i);
			return;
		}
	}
}

void CScene::ClearDynamicNpc()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for (list<SNpcInstance*>::iterator i = m_dynamicNpc.begin(); i != m_dynamicNpc.end(); i++)
	{
		delete *i;
	}
	m_dynamicNpc.clear();
}

void CScene::DelDynamicNpc(SNpcInstance *pNpc)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for (list<SNpcInstance*>::iterator i = m_dynamicNpc.begin(); i != m_dynamicNpc.end(); i++)
	{
		if (*i == pNpc)
		{
			CNetMessage msg;
			msg.SetType(PRO_DEL_NPC);
			msg << (*i)->id<<(*i)->index;
			BroadcastMsg(msg);
			delete *i;
			m_dynamicNpc.erase(i);
			return;
		}
	}
}

void CScene::DelDynamicNpcWithIndex(int npcId,int npcIdx)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for (list<SNpcInstance*>::iterator i = m_dynamicNpc.begin(); i != m_dynamicNpc.end(); i++)
	{
		if ((*i)->id == npcId && (*i)->index == npcIdx)
		{
			CNetMessage msg;
			msg.SetType(PRO_DEL_NPC);
			msg << (*i)->id<<(*i)->index;
			BroadcastMsg(msg);
			delete *i;
			m_dynamicNpc.erase(i);
			return;
		}
	}
}
/*
void CScene::DelNpc(uint16 x, uint16 y,uint16 id)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for (list<SNpcInstance*>::iterator i = m_dynamicNpc.begin(); i != m_dynamicNpc.end(); i++)
	{
		if(((*i)->x == x) && ((*i)->y == y))
		{
			if(((*i)->id == id) || id == 0)
			{
				CNetMessage msg;
				msg.SetType(PRO_DEL_NPC);
				msg << (*i)->id<<(*i)->index;
				BroadcastMsg(msg);

				delete *i;
				m_dynamicNpc.erase(i);
				SPoint point = {x, y};
				m_dynamicNpcPoint.push_back(point);
				return;
			}			
		}
	}
	//vector<SPoint> m_dynamicNpcPoint;
}
*/
bool CScene::InitEpisodeBattle(CUser *p, ShareFightPtr &pFight, ShareUserPtr &pUser)
{
	if (p == NULL)
		return false;

	pUser = m_onlineUser.GetUserBySock(p->GetSock());
	if (pUser.get() == NULL)
		return false;

	pFight = m_fightManager.CreateFight();

	if (pFight.get() == NULL)
	{
		return false;
	}
	pFight->SetFightType(CFight::EFTScript);
	return true;
}

uint16 CScene::AddUserGroupToBattle(ShareFightPtr &pFight, ShareUserPtr &pUser,uint8 beginPos,bool isQunXian)
{
	CUser *pU = pUser.get();
	if(pU == NULL)
		return 0;
	uint32 teamId = pU->GetTeam();
	if(teamId > 0)
	{
		if(teamId == pU->GetRoleId())
		{
			CUserTeam *pTeam = NULL;
			if (m_userTeams.Find(teamId, pTeam))
			{
				uint16 level = AddTeamToFight(pFight, pTeam, beginPos);
				return level;
			}
		}
	}
	else
	{
		AddSingleUser(pFight, pUser, beginPos, isQunXian);
		return pU->GetLevel();
	}
	return 0;
}

uint16 CScene::AddUserGroupToBattleEx(ShareFightPtr &pFight, ShareUserPtr &pUser, vector<uint16>& hpPercent, uint8 beginPos/* = 0*/, bool isQunXian/* = false*/)
{
	AddSingleUserEx(pFight, pUser, beginPos, hpPercent);
	return pUser->GetLevel();
}

void CScene::MakeLeiTaiFight(ShareUserPtr &pUserLeft, ShareUserPtr &pUserRight)
{
	ShareFightPtr pFight = m_fightManager.CreateFight();
	pFight->SetFightType(CFight::EFTMatch);
	AddUserGroupToBattle(pFight, pUserLeft, 0);
	AddUserGroupToBattle(pFight, pUserRight);
	pFight->BeginFight(this);
	m_fightManager.AddFight(pFight);
	pUserLeft.get()->SetExtData32(462, 0);
	pUserRight.get()->SetExtData32(462, 0);
}

void CScene::AddVisibleMonster(SVisibleMonster &monster)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if (monster.id == 0)
		monster.id = m_visibleMonsters.size();
	m_visibleMonsters.push_back(monster);
	CNetMessage msg;
	msg.SetType(MSG_SERVER_ADD_MONSTER);
	msg << monster.id << monster.x << monster.y << monster.face << monster.type << monster.pic;
	BroadcastMsg(msg);
}

void CScene::AddVisibleMonsterBoss(const char* name,uint16 pic,uint16 center_x,uint16 center_y,uint16 radius,uint8 type,time_t createTime)
{
	if(name == NULL)
		return;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	SVisibleMonsterBoss monster;
	monster.id = NormalMonsterIdPos - m_monsterBossIdIndex;
	if(monster.id < 10000)
	{
		monster.id = NormalMonsterIdPos - 1;
		m_monsterBossIdIndex = 0;
	}
	m_monsterBossIdIndex++;
	monster.isVisible = true;
	monster.name = name;
	monster.center_x = center_x;
	monster.center_y = center_y;
	monster.radius = radius;
	monster.meetDistance = 100;
	monster.pic = pic;
	monster.x = monster.center_x;
	monster.y = monster.center_y;
	monster.type = type;
	monster.monsterId = monster.id;
	monster.create_time = createTime;
	m_visibleMonstersBoss.push_back(monster);

	CNetMessage msg;
	msg.SetType(MSG_MONSTER_OPTION);
	msg<<(uint8)2<<monster.id<<monster.name<<monster.monsterId<<monster.pic<<(uint16)0<<monster.x<<monster.y<<monster.face<<(uint8)2;	// boss
	BroadcastMsg(msg);
}

void CScene::AddVisibleBossByFightId(int fightId,int pos_x,int pos_y)
{
	int pic = 0;
	string bossName;
	int bossId = 0;
	if(!SingletonCFightCfgManager::instance().GetFirstBossInfo(fightId,pic,bossName,bossId))
		return;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	SVisibleMonsterBoss monster;
	monster.id = NormalMonsterIdPos - m_monsterBossIdIndex;
	if(monster.id < 10000)
	{
		monster.id = NormalMonsterIdPos - 1;
		m_monsterBossIdIndex = 0;
	}
	m_monsterBossIdIndex++;
	monster.isVisible = true;
	monster.name = bossName;
	monster.center_x = pos_x;
	monster.center_y = pos_y;
	monster.radius = 50;
	monster.meetDistance = 100;
	monster.pic = pic;
	monster.x = monster.center_x;
	monster.y = monster.center_y;
	monster.monsterId = bossId;
	monster.type = 2;
	monster.create_time = GetSysTime();
	monster.fightId = fightId;
	m_visibleMonstersBoss.push_back(monster);
	
	CNetMessage msg;
	msg.SetType(MSG_MONSTER_OPTION);
	msg<<(uint8)2<<monster.id<<monster.name<<monster.monsterId<<monster.pic<<(uint16)0<<monster.x<<monster.y<<monster.face<<(uint8)2;	// boss
	BroadcastMsg(msg);
}

void CScene::ClearVisibleMonster()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for (list<SVisibleMonster>::iterator i = m_visibleMonsters.begin();i != m_visibleMonsters.end(); i++)
	{
		CNetMessage msg;
		msg.SetType(MSG_SERVER_REMOVE_MONSTER);
		msg << i->id;
		BroadcastMsg(msg);
	}
	m_visibleMonsters.clear();
}

void CScene::ClearVisibleMonsterBoss()
{
	boost::recursive_mutex::scoped_lock lk(m_monster_mutex);
	for (list<SVisibleMonsterBoss>::iterator i = m_visibleMonstersBoss.begin(); i != m_visibleMonstersBoss.end(); i++)
	{
		CNetMessage msg;
		msg.SetType(MSG_MONSTER_OPTION);
		msg<<(uint8)3<<i->id;
		BroadcastMsg(msg);
	}
	m_visibleMonstersBoss.clear();
}

void CScene::KuaFuBossPKFight(ShareUserPtr ptr,ShareUserPtr tarPtr)
{
	if(ptr.get() == NULL || tarPtr.get() == NULL)
		return;
	ShareFightPtr pFight = SingletonFightManager::instance().CreateFight();
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		pFight->SetFightType(CFight::EFT_KuaFuBossPK);
		pFight->SetFightChooseMode();
		AddUserGroupToBattle(pFight,ptr,0);
		AddUserGroupToBattle(pFight,tarPtr);
		pFight->BeginFight(this);
	}
	SingletonFightManager::instance().AddFight(pFight);
}

void CScene::BangPaiPKFight(ShareUserPtr ptr,ShareUserPtr tarPtr)
{
	if(ptr.get() == NULL || tarPtr.get() == NULL)
		return;
	ShareFightPtr pFight = SingletonFightManager::instance().CreateFight();
	{
		// 不同帮派成员PK
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		pFight->SetFightType(CFight::EFTBangPaiPK);
		pFight->SetFightChooseMode();
		AddUserGroupToBattle(pFight,ptr,0);
		AddUserGroupToBattle(pFight,tarPtr);
		pFight->BeginFight(this);
	}
	SingletonFightManager::instance().AddFight(pFight);
}

void CScene::HuSongFight(ShareUserPtr ptr,ShareUserPtr tarPtr)
{
	if(ptr.get() == NULL || tarPtr.get() == NULL)
		return;
	
	ShareFightPtr pFight = SingletonFightManager::instance().CreateFight();
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		pFight->SetFightType(CFight::EFTHuSong);
		pFight->SetFightChooseMode();
		AddUserGroupToBattle(pFight,ptr,0);
		AddUserGroupToBattle(pFight,tarPtr);
		pFight->BeginFight(this);
	}
	SingletonFightManager::instance().AddFight(pFight);
}

// 必须是组队状态且由队长触发
void CScene::ZhuoGuiBattle(ShareUserPtr pUser,int fightType,int monPic,string &bossName,int turn,int minMonPic)
{
	if(pUser.get() == NULL || pUser->GetTeam() == 0 || pUser->GetTeam() != pUser->GetRoleId())
		return;
	if(pUser->GetFightId() > 0)
		return;
	if (!pUser->HaveCMission(MISSION_ID_ZhuoGui))
		return;
	vector<string> strs;
	pUser->GetCMissionStrs(MISSION_ID_ZhuoGui, strs);
	if (strs.empty())
		return;

	ShareFightPtr pFight = m_fightManager.CreateFight();
	pFight->SetFightType(CFight::EFTZhuoGui);
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		uint16 level = AddUserGroupToBattle(pFight,pUser);
		int fightId = 10951;
		if(turn % 10 != 0)
		{
			fightId = 10901 + 10*Random(0,4);
		}
		AddZhuaguiMonster(pFight,fightId,level, strs[0].c_str());
		pFight->BeginFight(this);
	}
	m_fightManager.AddFight(pFight);
}

void CScene::BaiHuaXianZiBattle(ShareUserPtr pUser)
{
	uint8 maxLevel = 0;
	if (pUser->GetTeam() != 0)
	{
		uint32 members[MAX_TEAM_MEMBER];
		uint8 num = 0;
		CUserTeam *pTeam = NULL;
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if (!m_userTeams.Find(pUser->GetTeam(), pTeam))
			return;
		pTeam->GetMember(members, num);
		for (uint8 i = 0; i < num; i++)
		{
			ShareUserPtr p = m_onlineUser.GetUserByRoleId(members[i]);
			if (p.get() != NULL)
			{
				if (p->GetLevel() > maxLevel)
				{
					maxLevel = p->GetLevel();
				}
				p->SetHuoDongFightTime(GetSysTime());
				if (!p->HaveBitSet(181))
					p->CheckMissionHuoYueDu();
				p->SetBitSet(181); // 每日活跃度 百花仙子
			}
		}
		if (maxLevel < 20)
			return;
	}
	else
	{
		maxLevel = pUser->GetLevel();
		if (maxLevel < 20)
			return;
		pUser->SetHuoDongFightTime(GetSysTime());
		if (!pUser->HaveBitSet(181))
			pUser->CheckMissionHuoYueDu();
		pUser->SetBitSet(181); // 每日活跃度 百花仙子
	}

	ShareFightPtr pFight = m_fightManager.CreateFight();
	pFight->SetFightType(CFight::EFTBaiHua);
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		uint16 level = AddUserGroupToBattle(pFight,pUser);
		int fightId = Random(11201,11206);
		AddMonsterByFightId(pFight,fightId,level);
		pFight->SetHuiCun(true);
		pFight->BeginFight(this);
	}
	m_fightManager.AddFight(pFight);
}

int CScene::GetHuodongBitSet(int type)
{
	switch (type)
	{
	case SOT_Baihua:
		return 181;

	case SOT_Nianshou:
		return 201;
	}
	return 0;
}

int CScene::GetHuodongFightType(int type)
{
	switch (type)
	{
	case SOT_Baihua:
		return CFight::EFTBaiHua;

	case SOT_Nianshou:
		return CFight::EFT_Nianshou;
	}
	return 0;
}


int CScene::GetHuodongFightId(int type)
{
	switch (type)
	{
	case SOT_Baihua:
		return Random(11201, 11206);

	case SOT_Nianshou:
		return Random(21201, 21206);
	}
	return 0;
}

bool CScene::TryJoinActivityFight(ShareUserPtr pUser, int type)
{
	//	if (InFightHuoDong() && (pUser->GetLevel() >= BaiHuaLevelLimit) && IsBaiHuaXianZiFightMap() && (Random(1, 1000) <= 400))
	if (!CSceneManager::IsInActivityTime(type))
		return false;
	if (!sSystemOpenCfgMananger.CheckSystemOpen(pUser.get(), type))
		return false;

	if (!SingletonSceneManager::instance().IsInActivifyScene(type, m_mapId))
		return false;

	if (Random(1, 1000) > 400)
		return false;

	if (!CanJoinActivity(pUser.get()))
		return false;
	HuodongBattle(pUser, type);
	return true;
}

void CScene::HuodongBattle(ShareUserPtr pUser, int type)
{
	CCallScript *pScript = FindScript(200);
	if (pScript == NULL)
		return;
	int bitSet = GetHuodongBitSet(type);
	uint8 maxLevel = 0;
	if (pUser->GetTeam() != 0)
	{
		uint32 members[MAX_TEAM_MEMBER];
		uint8 num = 0;
		CUserTeam *pTeam = NULL;
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if (!m_userTeams.Find(pUser->GetTeam(), pTeam))
			return;
		pTeam->GetMember(members, num);
		for (uint8 i = 0; i < num; i++)
		{
			ShareUserPtr p = m_onlineUser.GetUserByRoleId(members[i]);
			if (p.get() != NULL)
			{
				if (p->GetLevel() > maxLevel)
				{
					maxLevel = p->GetLevel();
				}
				//p->SetHuoDongFightTime(GetSysTime());
				if (!p->HaveBitSet(bitSet))
					p->CheckMissionHuoYueDu();
				p->SetBitSet(bitSet); // 每日活跃度 百花仙子
			}
		}
		if (maxLevel < 20)
			return;
	}
	else
	{
		maxLevel = pUser->GetLevel();
		if (maxLevel < 20)
			return;
		//pUser->SetHuoDongFightTime(GetSysTime());
		if (!pUser->HaveBitSet(bitSet))
			pUser->CheckMissionHuoYueDu();
		pUser->SetBitSet(bitSet); // 每日活跃度 百花仙子
	}

	ShareFightPtr pFight = m_fightManager.CreateFight();
	int fightType = GetHuodongFightType(type);
	pFight->SetFightType((CFight::EFightType)fightType);
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		uint16 level = AddUserGroupToBattle(pFight, pUser);
		int fightId = GetHuodongFightId(type);
		AddMonsterByFightId(pFight, fightId, level);
		pFight->SetHuiCun(true);
		pFight->BeginFight(this);
	}
	m_fightManager.AddFight(pFight);
}

void CScene::FeiXianFight(ShareUserPtr user)
{
	CUser *pUser = user.get();
	if(pUser == NULL || pUser->GetTeam() > 0)
		return;
	const int fightDistance = 50;
	uint32 meetRoleId = 0;

	uint16 x = pUser->GetX();
	uint16 y = pUser->GetY();
	uint32 roleId = pUser->GetRoleId();
	ShareUserPtr tarPtr;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		for(list<uint32>::iterator iter = m_userList.begin();iter != m_userList.end();iter++)
		{
			if(roleId == *iter)
				continue;
			ShareUserPtr p = m_onlineUser.GetUserByRoleId(*iter);
			if(p.get() != NULL && p->GetFightId() == 0 && p->CanMeetEnemy() && p->GetTeam() == 0 && p->GetKuaFuState() == EKFS_IN_LOCAL)
			{
				int dx = x - p->GetX();
				int dy = y - p->GetY();
				if(dx*dx + dy*dy <= fightDistance*fightDistance)
				{
					meetRoleId = *iter;
					break;
				}
			}
		}
		if(meetRoleId == 0)
		{
			if(m_srcSceneId >= FEI_XIAN_SID1 && m_srcSceneId <= FEI_XIAN_SID4)
			{
				for(list<ShareUserPtr>::iterator it = m_visibleRobot.begin();it != m_visibleRobot.end();it++)
				{
					if((*it).get() == NULL)
						continue;
					if((*it)->GetFightId() == 0 && (*it)->GetKuaFuState() == EKFS_IN_LOCAL)
					{
						int dx = x - (*it)->GetX();
						int dy = y - (*it)->GetY();
						if(dx*dx + dy*dy <= fightDistance*fightDistance)
						{
							tarPtr = *it;
							break;
						}
					}
				}
			}
		}
	}

	if(meetRoleId != 0)	// 遇人
	{
		ShareFightPtr pFight = m_fightManager.CreateFight();
		if(pFight.get() == NULL)
			return;
		ShareUserPtr pU = m_onlineUser.GetUserByRoleId(meetRoleId);
		if(pU.get() == NULL || pU->GetFightId() > 0 || pU->GetKuaFuState() != EKFS_IN_LOCAL)
			return;
		pFight->SetFightType(CFight::EFT_FEI_XIAN);
		pFight->SetFightChooseMode();
		AddUserGroupToBattle(pFight,user,0);	// 挑战者
		AddUserGroupToBattle(pFight,pU);		// 被挑战者
		pFight->BeginFight(this);
		SingletonFightManager::instance().AddFight(pFight);
	}
	else if(tarPtr.get() != NULL)
	{
		ShareFightPtr pFight = m_fightManager.CreateFight();
		if(pFight.get() == NULL)
			return;
		if(tarPtr->GetFightId() > 0 || tarPtr->GetKuaFuState() != EKFS_IN_LOCAL)
			return;
		pFight->SetFightType(CFight::EFT_FEI_XIAN);
		pFight->SetFightChooseMode();
		AddUserGroupToBattle(pFight,user,0);	// 挑战者
		AddUserGroupToBattle(pFight,tarPtr);	// 被挑战者
		pFight->BeginFight(this);
		SingletonFightManager::instance().AddFight(pFight);
	}
}

void CScene::KunLunShanFight(ShareUserPtr user)
{
	CUser *pUser = user.get();
	if(pUser == NULL || pUser->GetTeam() > 0)
		return;
	const int fightDistance = 50;
	SVisibleMonsterBoss monsterBoss;
	uint32 meetRoleId = 0;
	bool isUser = false;
	bool isMeetEnemy = false;
	do
	{
		uint16 x = pUser->GetX();
		uint16 y = pUser->GetY();
		uint32 roleId = pUser->GetRoleId();
		boost::recursive_mutex::scoped_lock lk(m_monster_mutex);
		for(list<uint32>::iterator iter = m_userList.begin();iter != m_userList.end();iter++)
		{
			if(roleId == *iter)
				continue;
			ShareUserPtr p = m_onlineUser.GetUserByRoleId(*iter);
			if(p.get() != NULL && p->GetFightId() == 0 && p->CanMeetEnemy() && p->GetKuaFuState() == EKFS_IN_LOCAL)
			{
				int dx = x - p->GetX();
				int dy = y - p->GetY();
				if(dx*dx + dy*dy <= fightDistance*fightDistance)
				{
					isUser = true;
					meetRoleId = *iter;
					break;
				}
			}
		}
		if(isUser)
			break;
		
		for(list<SVisibleMonsterBoss>::iterator i = m_visibleMonstersBoss.begin();i != m_visibleMonstersBoss.end();i++)
		{
			if(i->isVisible && i->flag == 0)		// 可见，并没在战斗中
			{
				int dx = x - i->x;
				int dy = y - i->y;
				if(dx*dx + dy*dy <= fightDistance*fightDistance)
				{
					isMeetEnemy = true;
					monsterBoss = *i;
					break;
				}
			}
		}
	}while(0);

	if(isUser)	// 遇人
	{
		ShareFightPtr pFight = m_fightManager.CreateFight();
		if(pFight.get() == NULL)
			return;
		ShareUserPtr pU = m_onlineUser.GetUserByRoleId(meetRoleId);
		if(pU.get() == NULL || pU->GetFightId() > 0 || pU->GetKuaFuState() != EKFS_IN_LOCAL)
			return;
		if(pU->GetTeam() > 0)
			return;
		pFight->SetFightType(CFight::EFTKunLunShan);
		{
			boost::recursive_mutex::scoped_lock lk(m_mutex);
			AddUserGroupToBattle(pFight,user,0);
			AddUserGroupToBattle(pFight,pU);
			pFight->SetFightChooseMode();
			pFight->BeginFight(this);
		}
		SingletonFightManager::instance().AddFight(pFight);
		return;
	}
	else if(isMeetEnemy)	// 遇怪
	{
		SVisibleMonsterBoss vMonster;
		if(!FindVisibleMonsterBoss(monsterBoss.id,vMonster,1))
			return;
		if(vMonster.flag != 0)
			return;
		ShareFightPtr pFight = m_fightManager.CreateFight();
		if(pFight.get() == NULL)
		{
			FindVisibleMonsterBoss(monsterBoss.id, vMonster, 0);
			return;
		}

		pFight->SetFightType(CFight::EFTKunLunShan);
		{
			boost::recursive_mutex::scoped_lock lk(m_mutex);
			uint16 level = AddUserGroupToBattle(pFight,user);
			int fightId = 0;
			int r = Random(1,100);
			if(r <= 40)
				fightId = Random(11501,11506);
			else if(r <= 70)
				fightId = Random(11511,11516);
			else if(r <= 90)
				fightId = Random(11521,11526);
			else
				fightId = Random(11531,11536);
			AddMonsterByFightId(pFight,fightId,level,monsterBoss.id);
			pFight->BeginFight(this);
		}
		m_fightManager.AddFight(pFight);
		return;
	}
}

void CScene::KunLunShanTeamFight(ShareUserPtr user)
{
#ifdef KUA_FU
	CUser *pUser = user.get();
	if(pUser == NULL || pUser->GetTeam() == 0 || pUser->GetRoleId() != pUser->GetTeam())
		return;
	const int fightDistance = 50;
	SVisibleMonsterBoss monsterBoss;
	uint32 meetRoleId = 0;
	//int serverZoneId = GetServerZone(pUser->GetServerId());
	bool isUser = false;
	bool isMeetEnemy = false;
	do
	{
		uint16 x = pUser->GetX();
		uint16 y = pUser->GetY();
		uint32 roleId = pUser->GetRoleId();
		boost::recursive_mutex::scoped_lock lk(m_monster_mutex);
		for(list<uint32>::iterator iter = m_userList.begin();iter != m_userList.end();iter++)
		{
			if(roleId == *iter)
				continue;
			ShareUserPtr p = m_onlineUser.GetUserByRoleId(*iter);
			if(p.get() != NULL && p->GetFightId() == 0 && p->CanMeetEnemy() && p->GetTeam() > 0 && p->GetRoleId() == p->GetTeam())	// 队长
			{
				int dx = x - p->GetX();
				int dy = y - p->GetY();
				if (dx*dx + dy*dy <= fightDistance*fightDistance)
				{
					isUser = true;
					meetRoleId = *iter;
					break;
				}
			}
		}
		if(isUser)
			break;
		
		for(list<SVisibleMonsterBoss>::iterator i = m_visibleMonstersBoss.begin();i != m_visibleMonstersBoss.end();i++)
		{
			if(i->isVisible && i->flag == 0)		// 可见，并没在战斗中
			{
				int dx = x - i->x;
				int dy = y - i->y;
				if(dx*dx + dy*dy <= fightDistance*fightDistance)
				{
					isMeetEnemy = true;
					monsterBoss = *i;
					break;
				}
			}
		}
	}while(0);

	if(isUser)	// 遇人
	{
		ShareFightPtr pFight = m_fightManager.CreateFight();
		if(pFight.get() == NULL)
			return;
		ShareUserPtr pU = m_onlineUser.GetUserByRoleId(meetRoleId);
		if(pU.get() == NULL || pU->GetFightId() > 0 || pU->GetTeam() == 0)
			return;
		pFight->SetFightType(CFight::EFT_KunLunShanTeam);
		AddUserGroupToBattle(pFight,user,0);
		AddUserGroupToBattle(pFight,pU);
		pFight->SetFightChooseMode();
		pFight->BeginFight(this);
		SingletonFightManager::instance().AddFight(pFight);
		return;
	}
	else if(isMeetEnemy)	// 遇怪
	{
		SVisibleMonsterBoss vMonster;
		if(!FindVisibleMonsterBoss(monsterBoss.id,vMonster,1))
			return;
		if(vMonster.flag != 0)
			return;
		ShareFightPtr pFight = m_fightManager.CreateFight();
		if(pFight.get() == NULL)
		{
			FindVisibleMonsterBoss(monsterBoss.id, vMonster, 0);
			return;
		}

		pFight->SetFightType(CFight::EFT_KunLunShanTeam);
		{
			boost::recursive_mutex::scoped_lock lk(m_mutex);
			uint16 level = AddUserGroupToBattle(pFight,user);
			int fightId = 0;
			int r = Random(1,100);
			if(r <= 40)
				fightId = Random(15001,15006);
			else if(r <= 70)
				fightId = Random(15011,15016);
			else if(r <= 90)
				fightId = Random(15021,15026);
			else
				fightId = Random(15031,15036);
			AddMonsterByFightId(pFight,fightId,level,monsterBoss.id);
			pFight->BeginFight(this);
		}
		m_fightManager.AddFight(pFight);
		return;
	}
#endif
}

void CScene::MatchKuaFu1V1Fight()
{
	if(m_id < KUA_FU_1V1_SCENE_FB_BEGIN || m_id > KUA_FU_1V1_SCENE_FB_BEGIN+KUA_FU_1V1_SCENE_NUM-1)
		return;
	int sceneIdx = m_id - KUA_FU_1V1_SCENE_FB_BEGIN + 1;	// 第几个场景
	int timeIdx = GetKuaFu1V1FinalsTimeIndex();	// 第几轮决赛
	if(timeIdx < 0)
		return;

	string winnerName;
	SKuaFu1V1UserData player1;
	SKuaFu1V1UserData player2;
	GetKuaFu1V1FightPlayers(timeIdx,sceneIdx,player1,player2);
	if(player1.data.role_id == 0 || player2.data.role_id == 0 || player1.data.winNum >= 2 || player2.data.winNum >= 2)
	{
		if(m_fbStep < 6)
		{
			m_fbStep = 6;
			m_1V1SceneTime = GetKuaFu1V1TurnStartTime()+15*60;
		}
		return;
	}

	list<uint32> userList;
	GetUserList(userList);
	// 确认两个人是否都在场景内
	ShareUserPtr p1;
	ShareUserPtr p2;
	for(list<uint32>::iterator it=userList.begin();it != userList.end();it++)
	{
		if(*it == (uint32)player1.data.role_id)
			p1 = m_onlineUser.GetUserByRoleId(*it);
		else if(*it == (uint32)player2.data.role_id)
			p2 = m_onlineUser.GetUserByRoleId(*it);
	}

	do
	{
		if(p1.get() == NULL && p2.get() == NULL)
		{
			if(player1.data.zhandouli >= player2.data.zhandouli)
			{
				AddKuaFu1V1PlayerWinNum(timeIdx,player1.data.role_id);
				player1.data.winNum++;
				winnerName = player1.data.name;
			}
			else
			{
				AddKuaFu1V1PlayerWinNum(timeIdx,player2.data.role_id);
				player2.data.winNum++;
				winnerName = player2.data.name;
			}
			m_fbStep++;
			m_1V1SceneTime = GetSysTime();
			break;
		}
		else if(p1.get() == NULL && p2.get() != NULL)
		{
			AddKuaFu1V1PlayerWinNum(timeIdx,player2.data.role_id);
			player2.data.winNum++;
			winnerName = player2.data.name;
			m_fbStep++;
			m_1V1SceneTime = GetSysTime();
			SendKuaFu1V1SceneLeftTime(this);
			SendKuaFu1V1SceneScore(p2.get());
			break;
		}
		else if(p1.get() != NULL && p2.get() == NULL)
		{
			AddKuaFu1V1PlayerWinNum(timeIdx,player1.data.role_id);
			player1.data.winNum++;
			winnerName = player1.data.name;
			m_fbStep++;
			m_1V1SceneTime = GetSysTime();
			SendKuaFu1V1SceneLeftTime(this);
			SendKuaFu1V1SceneScore(p1.get());
			break;
		}
		else	// 开始战斗
		{
			if(p1->GetFightId() > 0 || p2->GetFightId() > 0)
			{
				if(player1.data.zhandouli >= player2.data.zhandouli)
				{
					AddKuaFu1V1PlayerWinNum(timeIdx,player1.data.role_id);
					player1.data.winNum++;
					winnerName = player1.data.name;
				}
				else
				{
					AddKuaFu1V1PlayerWinNum(timeIdx,player2.data.role_id);
					player2.data.winNum++;
					winnerName = player2.data.name;
				}
				m_fbStep++;
				m_1V1SceneTime = GetSysTime();
				SendKuaFu1V1SceneLeftTime(this);
				SendKuaFu1V1SceneScore(p1.get());
				SendKuaFu1V1SceneScore(p2.get());
				break;
			}
			
			ShareFightPtr pFight = m_fightManager.CreateFight();
			if(pFight.get() == NULL)
				return;
			pFight->SetFightType(CFight::EFT_KuaFu_1V1);
			pFight->SetFightChooseMode();
			AddUserGroupToBattle(pFight,p1,0);
			AddUserGroupToBattle(pFight,p2);
			pFight->BeginFight(this);
			SingletonFightManager::instance().AddFight(pFight);
			return;
		}
	}while(0);

	if(player1.data.winNum >= 2 || player2.data.winNum >= 2)	// 结束本场次
	{
		int winnerId = (player1.data.winNum > player2.data.winNum) ? player1.data.role_id : player2.data.role_id;
		int lossId = (player1.data.winNum > player2.data.winNum) ? player2.data.role_id : player1.data.role_id;
		SetKuaFu1V1WinnerData(timeIdx, sceneIdx, winnerId);
		SendSystemMail(winnerId, GetKuaFu1V1MailString(true).c_str());
		SendSystemMail(lossId, GetKuaFu1V1MailString(false).c_str());

		CUser *pWin = m_onlineUser.GetUserByRoleId(winnerId).get();
		if(pWin != NULL)
			SendSysInfo(pWin,MakeStringColor(LANGUAGE_SSJ_0524,TIPS_SUCCESS_COLOR).c_str());
		CUser *pLose = m_onlineUser.GetUserByRoleId(lossId).get();
		if(pLose != NULL)
			SendSysInfo(pLose,MakeStringColor(LANGUAGE_SSJ_0525,TIPS_FAILURE_COLOR).c_str());
		if(m_fbStep < 6)
		{
			m_fbStep = 6;
			m_1V1SceneTime = GetKuaFu1V1TurnStartTime()+15*60;
		}

		if(!winnerName.empty())
		{
			char buf[512];
			if(timeIdx == 4)
			{
				snprintf(buf,sizeof(buf)-1,LANGUAGE_SSJ_0077,ROLE_NAME_COLOR,winnerName.c_str());
				SysInfoToAllUser(buf);
			}
			else if(timeIdx == 5)
			{
				snprintf(buf,sizeof(buf)-1,LANGUAGE_SSJ_0078,ROLE_NAME_COLOR,winnerName.c_str());
				SysInfoToAllUser(buf);
			}
		}
		
		int sId = EXIT_FB_SCENE_ID, pX = EXIT_FB_SCENE_X, pY = EXIT_FB_SCENE_Y;
		if(p1.get() != NULL)
		{
			p1->GetEnterPos(sId,pX,pY);
			TransportUser(p1.get(),sId,pX,pY,0);
		}
		if(p2.get() != NULL)
		{
			p2->GetEnterPos(sId,pX,pY);
			TransportUser(p2.get(),sId,pX,pY,0);
		}
	}
}

ShareUserPtr CScene::GetVisibleRobotPtr(int visibleID)
{
	ShareUserPtr t;
	if(visibleID <= 0)
		return t;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(list<ShareUserPtr>::iterator i=m_visibleRobot.begin();i != m_visibleRobot.end();i++)
	{
		if((*i).get() != NULL && (*i)->GetRoleId() == (uint32)visibleID)
 			return (*i);
 	}
	return t;
}

void CScene::RemoveVisibleRobot(uint16 num)
{
	if(num == 0)
		return;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	uint16 size = m_visibleRobot.size();
	if(size == 0)
		return;
	else if(size < num)
		num = size;

	uint16 count = 0;
	list<ShareUserPtr>::iterator t=m_visibleRobot.begin();
	for(list<ShareUserPtr>::iterator i=m_visibleRobot.begin();i != m_visibleRobot.end();i++)
	{
		if((*i).get() != NULL)
		{
			CNetMessage msg;
			msg.SetType(PRO_IN_OUT_SCENE);
			//						出场景
			msg<<(*i)->GetRoleId()<<(uint8)0;
			BroadcastMsgExceptSameTeam((*i).get(),msg);
		}

		t = i;
		i++;
		m_visibleRobot.erase(t);
		count++;
		if(count >= num)
			break;
	}
}

void CScene::AddVisibleRobot(CUser *pUser)
{
	if(m_srcSceneId < FEI_XIAN_SID1 || m_srcSceneId > FEI_XIAN_SID4)
		return;
	if(pUser == NULL)
		return;
	const int MAX_USER_NUM_LIMIT = 50;
	const uint8 ADD_ROBOT_PER_NUM = 2;
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	
	// 添加玩家机器人
	for(uint8 i=0;i < ADD_ROBOT_PER_NUM;i++)
	{
		if(m_visibleRobot.size() + m_userList.size() >= (uint16)MAX_USER_NUM_LIMIT)
			return;
		CUser *pRobot = new CUser();
		if(!pRobot->CopyOnlineUserData(pUser))
		{
			delete pRobot;
			return;
		}
		pRobot->SetBasicAttrOff();	// 降低强度

		uint16 x=0,y=0;
		if(!GetCanWalkPos(x,y))
		{
			delete pRobot;
			return;
		}

		char buf[64];
		string robotName;
		GetFastRoleName(pUser->GetSex(),robotName);
		snprintf(buf,sizeof(buf),"%s%c%c",robotName.c_str(),Random(0,25)+'a',Random(0,25)+'a');
		pRobot->SetName(buf);
		pRobot->SetPos(x,y);
		pRobot->SetRobot(1);
//		pRobot->SetUseTitle(0);
		pRobot->SetFace((uint8)Random(0,7));
		m_visibleRobotId++;
		pRobot->SetRoleId(0xff+m_visibleRobotId);

		ShareUserPtr ptr(pRobot);
		m_visibleRobot.push_back(ptr);

		CNetMessage msg;
		msg.SetType(PRO_IN_OUT_SCENE);
		//							进场景	   无队伍   无暂离
		msg<<pRobot->GetRoleId()<<(uint8)1<<(uint8)0<<(uint32)0<<pRobot->GetX()<<pRobot->GetY()<<pRobot->GetFace()
			<<pRobot->GetName()<<pRobot->GetSex()<<pRobot->GetHead()<<pRobot->GetLevel()
			<<pRobot->GetBangPai()<<pRobot->GetBangPaiRank()<<pRobot->GetBangPaiName()<<pRobot->GetBangPaiShowInfo()
			<<(uint8)0;
		BroadcastMsgExceptSameTeam(pRobot,msg);
	}
}

// -1 参数异常 0 成功 1 战斗中 2 组队 3 在副本中 4 已通关最顶层
int CScene::TongTianTaFight(ShareUserPtr user)
{
	CUser *pUser = user.get();
	if(pUser == NULL)
		return -1;
	if(pUser->GetKuaFuState() != EKFS_IN_LOCAL)
		return 1;
	if(pUser->GetFightId() != 0)
		return 1;
	if(pUser->GetTeam() > 0)
		return 2;
	int fbIndex = pUser->GetExtData16(51);
	if(fbIndex > TONG_TIAN_TA_FLOOR_NUM)
		return 4;
	
	ShareFightPtr pFight = m_fightManager.CreateFight();
	if(pFight.get() == NULL)
		return -1;
	if(pUser->GetExtData16(51) == 0)
		pUser->SetExtData16(51,1);

	pFight->SetFightType(CFight::EFTTongTianTa);
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	uint16 level = AddUserGroupToBattle(pFight,user);
	int fightId = 12001 + (fbIndex - 1)*5;
	AddMonsterByFightId(pFight,fightId,level);
	pFight->BeginFight(this);
	m_fightManager.AddFight(pFight);
	return 0;
}

void CScene::XiuXianTeamFight(ShareUserPtr user,int idx)
{
	CUser *pUser = user.get();
	if(pUser == NULL)
		return;
	if(pUser->GetKuaFuState() != EKFS_IN_LOCAL)
		return;
	if(pUser->GetFightId() != 0)
		return;
	if(idx < 1 || idx > CUser::MAX_XIU_XIAN_NUM)
		return;
	ShareFightPtr pFight = m_fightManager.CreateFight();
	if(pFight.get() == NULL)
		return;

	pFight->SetFightType(CFight::EFTXiuXian);
	pFight->SetVisibleMonsterId(idx);
	pFight->SetFightChooseMode();

	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		uint16 level = AddUserGroupToBattle(pFight,user);
/*		if(idx%5 == 0)	// 打人
		{
			ShareUserPtr ptr2 = GetXiuXianRobotByIdx(idx);
			if(ptr2.get() == NULL)
				return;
			AddUserGroupToBattle(pFight,ptr2,0);
		}
*/		
//		else	// 打怪
		{
			int fightId = 11701 + (idx - 1)*5;
			AddMonsterByFightId(pFight,fightId,level);
		}
		pFight->BeginFight(this);
	}
	m_fightManager.AddFight(pFight);
	SaveDate(pUser, 705, idx);

	uint32 teamId = pUser->GetTeam();
	if (teamId > 0 && teamId == pUser->GetRoleId())
	{
		CUserTeam *pTeam = NULL;
		if (!m_userTeams.Find(teamId, pTeam))
			return;
		vector<SZhenFaMemData> zhenfaMem;
		pTeam->GetZhenFaMember(zhenfaMem);
		if (zhenfaMem.empty())
			return;

		for (uint8 i = 0; i < zhenfaMem.size(); i++)
		{
			SZhenFaMemData &data = zhenfaMem[i];
			if (data.mem_type == EZFMT_NONE)
				continue;
			if (data.mem_type == EZFMT_USER)
			{
				uint32 roleId = data.mem_id;
				ShareUserPtr p = m_onlineUser.GetUserByRoleId(roleId);
				if (p.get() == NULL)
					continue;
				p->SetBitSet(436);
				SingletonCMissionManager::instance().VerifyNewBranchMissionFinish(p.get(), EMISS_DC_37);
			}
		}
	}
	else
	{
		pUser->SetBitSet(436);
		SingletonCMissionManager::instance().VerifyNewBranchMissionFinish(pUser, EMISS_DC_37);
	}
}

void CScene::XunChaShiFight(ShareUserPtr user,int npcId,int index)
{
	CUser *pUser = user.get();
	if(pUser == NULL)
		return;
	if(pUser->GetTeam() != pUser->GetRoleId())
		return;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	SNpcInstance *pNpc = NULL;
	int fightId = 0;
	for(list<SNpcInstance*>::iterator i=m_dynamicNpc.begin(); i != m_dynamicNpc.end(); i++)
	{
		if((*i)->id == npcId && (*i)->index == index)
		{
			pNpc = (*i);
			fightId = pNpc->fightId;
			break;
		}
	}
	if(pNpc == NULL || fightId == 0)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_2776,TIPS_FAILURE_COLOR).c_str());
		return;
	}

	uint8 npcPos = GetXunChaShiNpcPos(npcId);
	if(npcPos == 0xff)
		return;
	uint8 monIndex = npcPos*6 + (uint8)(index-1);	// 0~23
	if(monIndex >= 24)
		return;

	ShareFightPtr pFight = m_fightManager.CreateFight();
	if(pFight.get() == NULL)
		return;
	pFight->SetFightType(CFight::EFT_XunChaShi);
	pFight->SetVisibleMonsterId(monIndex);

	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		uint16 level = AddUserGroupToBattle(pFight,user);
//		uint16 level = GetWorldLevel();
		AddMonsterByFightId(pFight,fightId,level);
		pFight->BeginFight(this);
	}
	m_fightManager.AddFight(pFight);
}


extern int refreshLingQiValue;
// -1 出错 1 战斗中 2 找不到NPC怪 0 成功
int CScene::LingQiJuanXianFight(ShareUserPtr user)
{
	CUser *pUser = user.get();
	if(pUser == NULL)
		return -1;
	int index = pUser->GetVal(1);
	if(index == 0)
		return -1;
	ShareFightPtr pFight = m_fightManager.CreateFight();
	if(pFight.get() == NULL)
		return -1;
	int monsterType = 0;
	uint16 fightId = 0;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		bool findFlag = false;
		for(list<SNpcInstance*>::iterator i = m_dynamicNpc.begin(); i != m_dynamicNpc.end();i++)
		{
			if((*i)->id >= 154 && (*i)->id <= 157 && (*i)->index == index)
			{
				monsterType = (*i)->id - 153;
				fightId = (*i)->fightId;
				if((*i)->isFight)
					return 1;
				else
				{
					(*i)->isFight = true;
					findFlag = true;
					break;
				}
			}
		}
		if(!findFlag)
			return 2;
	}
	if(monsterType == 0 || fightId == 0)
		return 2;
	pFight->SetVisibleMonsterId(index);
	pFight->SetFightType(CFight::EFTLingQiJuanXian);
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		uint16 level = AddUserGroupToBattle(pFight,user);
		AddMonsterByFightId(pFight,fightId,level,monsterType);
		pFight->BeginFight(this);
	}
	m_fightManager.AddFight(pFight);
	return 0;
}

// 日常 强化副本战斗
void CScene::RiChangQiangHuaFuBenFight(ShareUserPtr user,SVisibleMonsterBoss& boss)
{
	CUser *pUser = user.get();
	if(pUser == NULL)
		return;
	if(pUser->GetKuaFuState() != EKFS_IN_LOCAL)
		return;
	if(pUser->GetFightId() != 0)
		return;

	ShareFightPtr pFight = m_fightManager.CreateFight();
	if (pFight.get() == NULL)
		return;
	pFight->SetFightType(CFight::EFTFB_QiangHua);

	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		uint16 level = AddUserGroupToBattle(pFight,user);
		if (boss.type == MB_BOSS) // boss战
		{
			pFight->SetVisibleMonsterId(1);	// boss
		}
		else
		{
			pFight->SetVisibleMonsterId(0);
		}
		AddMonsterByFightId(pFight,boss.fightId,level,boss.id);
		pFight->BeginFight(this);
	}
	m_fightManager.AddFight(pFight);
}

// 日常 神将副本战斗
void CScene::RiChangChongWuFuBenFight(ShareUserPtr user,SVisibleMonsterBoss& boss)
{
	CUser *pUser = user.get();
	if(pUser == NULL)
		return;
	if(pUser->GetKuaFuState() != EKFS_IN_LOCAL)
		return;
	if(pUser->GetFightId() != 0)
		return;

	ShareFightPtr pFight = m_fightManager.CreateFight();
	if (pFight.get() == NULL)
		return;
	pFight->SetFightType(CFight::EFTFB_Pet);

	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		uint16 level = AddUserGroupToBattle(pFight,user);
		AddMonsterByFightId(pFight,boss.fightId,level,boss.id);
		pFight->BeginFight(this);
	}
	m_fightManager.AddFight(pFight);
}

// 日常 金币副本战斗
void CScene::RiChangJinBiFuBenFight(ShareUserPtr user,SVisibleMonsterBoss& boss)
{
	CUser *pUser = user.get();
	if(pUser == NULL)
		return;
	if(pUser->GetKuaFuState() != EKFS_IN_LOCAL)
		return;
	if(pUser->GetFightId() != 0)
		return;

	ShareFightPtr pFight = m_fightManager.CreateFight();
	if (pFight.get() == NULL)
		return;
	pFight->SetFightType(CFight::EFTFB_JinQian);
	AddUserGroupToBattle(pFight,user);

	int mobNum = 6; // 参战怪物数
	if(pUser->GetLevel() < 35)
		mobNum = 4;
	if(boss.type == MB_BOSS) // boss
		pFight->SetVisibleMonsterId(1);	// boss
	else if(boss.type == MB_HEADER)	// 头目
		pFight->SetVisibleMonsterId(2);
	else
		pFight->SetVisibleMonsterId(3);

//	const uint16 monsterTmplId[] = {7,10,11,13,14};
//	const char *monsterName[] = {LANGUAGE_TRANSFORM_2786,LANGUAGE_TRANSFORM_2787,LANGUAGE_TRANSFORM_2788,LANGUAGE_TRANSFORM_2789,LANGUAGE_TRANSFORM_2790};
	for (int i = 0; i < mobNum; ++i)
	{
/*
		uint32 monsterId = 0;
		string name;
		if(i == 0)
		{
			monsterId = boss.pic;
			name = boss.name;
		}
		else
		{
			int r = Random(0,sizeof(monsterTmplId)/sizeof(monsterTmplId[0]) - 1);
			monsterId = monsterTmplId[r];
			name = monsterName[r];
		}
*/
//		ShareMonsterPtr	pShareMonster = m_monsterManager.CreateMonster(monsterId,pUser->GetLevel(),EMTNormal);		
//		if (pShareMonster.get() == NULL)
//			continue;
//		pShareMonster->visableId = boss.id;
//		pFight->AddMonster(pShareMonster,GetMonsterFightPos(i+1));
	}
	pFight->BeginFight(this);
	m_fightManager.AddFight(pFight);
}

void CScene::RiChangXiangQianFuBenFight(ShareUserPtr user,SVisibleMonsterBoss& boss)
{
	CUser *pUser = user.get();
	if(pUser == NULL)
		return;
	if(pUser->GetKuaFuState() != EKFS_IN_LOCAL)
		return;
	if(pUser->GetFightId() != 0)
		return;

	ShareFightPtr pFight = m_fightManager.CreateFight();
	if (pFight.get() == NULL)
		return;
	pFight->SetFightType(CFight::EFTFB_XiangQian);
	AddUserGroupToBattle(pFight,user);

	int mobNum = 10; // 参战怪物数
	if(pUser->GetLevel() < 35)
		mobNum = 6;
	else if(pUser->GetLevel() < 40)
		mobNum = 8;
	else
		mobNum = 10;

	if(boss.type == MB_BOSS) // boss
		pFight->SetVisibleMonsterId(1);	// boss
	else if(boss.type == MB_HEADER)	// 头目
		pFight->SetVisibleMonsterId(2);
	else
		pFight->SetVisibleMonsterId(3);

//	const uint16 monsterTmplId[] = {5,8,10,14};
	for (int i = 0; i < mobNum; ++i)
	{
/*
		uint32 monsterId = 0;
		if(i == 0)
			monsterId = boss.pic;
		else
			monsterId = monsterTmplId[Random(0,sizeof(monsterTmplId)/sizeof(monsterTmplId[0]) - 1)];
*/		
//		ShareMonsterPtr	pShareMonster = m_monsterManager.CreateMonster(monsterId,pUser->GetLevel(),EMTNormal);		
//		if (pShareMonster.get() == NULL)
//			continue;

//		pShareMonster->visableId = boss.id;
//		pFight->AddMonster(pShareMonster,GetMonsterFightPos(i+1));
	}
	pFight->BeginFight(this);
	m_fightManager.AddFight(pFight);
}

void CScene::RiChangXiLianFuBenFight(ShareUserPtr user,SVisibleMonsterBoss& boss)
{
	CUser *pUser = user.get();
	if(pUser == NULL)
		return;
	if(pUser->GetKuaFuState() != EKFS_IN_LOCAL)
		return;
	if(pUser->GetFightId() != 0)
		return;

	ShareFightPtr pFight = m_fightManager.CreateFight();
	if (pFight.get() == NULL)
		return;
	pFight->SetFightType(CFight::EFTFB_XiLian);

	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		uint16 level = AddUserGroupToBattle(pFight,user);
		if(boss.type == MB_BOSS) // boss
			pFight->SetVisibleMonsterId(1);	// boss
		else if(boss.type == MB_HEADER)	// 头目
			pFight->SetVisibleMonsterId(2);
		else
			pFight->SetVisibleMonsterId(3);
		AddMonsterByFightId(pFight,boss.fightId,level,boss.id);
		pFight->BeginFight(this);
	}
	m_fightManager.AddFight(pFight);
}

void CScene::RiChangChongKaiFuBenFight(ShareUserPtr user,SVisibleMonsterBoss& boss)
{
	CUser *pUser = user.get();
	if(pUser == NULL)
		return;
	if(pUser->GetKuaFuState() != EKFS_IN_LOCAL)
		return;
	if(pUser->GetFightId() != 0)
		return;

	ShareFightPtr pFight = m_fightManager.CreateFight();
	if (pFight.get() == NULL)
		return;
	pFight->SetFightType(CFight::EFTFB_ChongKai);

	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);	
		uint16 level = AddUserGroupToBattle(pFight,user);
		if(boss.type == MB_BOSS) // boss
			pFight->SetVisibleMonsterId(1);	// boss
		else if(boss.type == MB_HEADER)	// 头目
			pFight->SetVisibleMonsterId(2);
		else
			pFight->SetVisibleMonsterId(3);
		AddMonsterByFightId(pFight,boss.fightId,level,boss.id);
		pFight->BeginFight(this);
	}
	m_fightManager.AddFight(pFight);
}

// 日常 升阶副本战斗
void CScene::RiChangShengJieFuBenFight(ShareUserPtr user,SVisibleMonsterBoss& boss)
{
	CUser *pUser = user.get();
	if(pUser == NULL)
		return;
	if(pUser->GetKuaFuState() != EKFS_IN_LOCAL)
		return;
	if(pUser->GetFightId() != 0)
		return;

	ShareFightPtr pFight = m_fightManager.CreateFight();
	if (pFight.get() == NULL)
		return;
	pFight->SetFightType(CFight::EFTFB_ShengJie);

	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		uint16 level = AddUserGroupToBattle(pFight,user);
		if(boss.type == MB_BOSS) // boss
			pFight->SetVisibleMonsterId(1);	// boss
		else if(boss.type == MB_HEADER)	// 头目
			pFight->SetVisibleMonsterId(2);
		else
			pFight->SetVisibleMonsterId(3);	
		AddMonsterByFightId(pFight,boss.fightId,level,boss.id);
		pFight->BeginFight(this);
	}
	m_fightManager.AddFight(pFight);
}

// 日常 强化副本战斗
void CScene::RiChangQianNengFuBenFight(ShareUserPtr user,SVisibleMonsterBoss& boss)
{
	CUser *pUser = user.get();
	if(pUser == NULL)
		return;
	if(pUser->GetKuaFuState() != EKFS_IN_LOCAL)
		return;
	if(pUser->GetFightId() != 0)
		return;

	ShareFightPtr pFight = m_fightManager.CreateFight();
	if (pFight.get() == NULL)
		return;
	pFight->SetFightType(CFight::EFTFB_QianNeng);
	AddUserGroupToBattle(pFight,user);

	int mobNum = 6; // 参战怪物数
	if(pUser->GetLevel() < 35)
		mobNum = 4;
	if(boss.type == MB_BOSS) // boss
		pFight->SetVisibleMonsterId(1);	// boss
	else if(boss.type == MB_HEADER)	// 头目
		pFight->SetVisibleMonsterId(2);
	else
		pFight->SetVisibleMonsterId(3);

//	const uint16 monsterTmplId[] = {15,16,19,13,18};
//	const char *monsterName[] = {LANGUAGE_TRANSFORM_2795,LANGUAGE_TRANSFORM_2796,LANGUAGE_TRANSFORM_2797,LANGUAGE_TRANSFORM_2798,LANGUAGE_TRANSFORM_2799};
	for (int i = 0; i < mobNum; ++i)
	{
/*
		uint32 monsterId = 0;
		string name;
		if(i == 0)
		{
			monsterId = boss.pic;
			name = boss.name;
		}
		else
		{
			int r = 0;
			if(boss.type == MB_BOSS)
				r = Random(0,sizeof(monsterTmplId)/sizeof(monsterTmplId[0]));
			else
				r = Random(0,sizeof(monsterTmplId)/sizeof(monsterTmplId[0])-1);

			if(r == sizeof(monsterTmplId)/sizeof(monsterTmplId[0]))
			{
				monsterId = 15;
				name = LANGUAGE_TRANSFORM_2800;
			}
			else
			{
				monsterId = monsterTmplId[r];
				name = monsterName[r];
			}
		}
*/
//		ShareMonsterPtr	pShareMonster = m_monsterManager.CreateMonster(monsterId,pUser->GetLevel(),EMTNormal);		
//		if (pShareMonster.get() == NULL)
//			continue;

//		pShareMonster->visableId = boss.id;
//		pFight->AddMonster(pShareMonster,GetMonsterFightPos(i+1));
	}
	pFight->BeginFight(this);
	m_fightManager.AddFight(pFight);
}

void CScene::SetNPCMonsterFightFlag(int npcId,int index,bool isfight)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(list<SNpcInstance*>::iterator i = m_dynamicNpc.begin(); i != m_dynamicNpc.end();i++)
	{
		if((*i)->id == npcId && (*i)->index == index)
		{
			(*i)->isFight = isfight;
			return;
		}
	}
}

bool CScene::FindVisibleMonster(uint32 id, SVisibleMonster &monster, uint8 flag)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if (m_visibleMonsters.size() <= 0)
		return false;
	for (list<SVisibleMonster>::iterator i = m_visibleMonsters.begin();
			i != m_visibleMonsters.end(); i++)
	{
		if (i->id == id)
		{
			monster = *i;
			i->flag = flag;
			return true;
		}
	}
	return false;
}

bool CScene::FindVisibleMonsterBoss(uint32 id, SVisibleMonsterBoss &monster, uint8 flag)
{
	boost::recursive_mutex::scoped_lock lk(m_monster_mutex);
	if (m_visibleMonstersBoss.size() <= 0)
		return false;
	for (list<SVisibleMonsterBoss>::iterator i = m_visibleMonstersBoss.begin();i != m_visibleMonstersBoss.end(); i++)
	{
		if (i->id == id)
		{
			monster = *i;
			i->flag = flag;
			return true;
		}
	}
	return false;
}

// 获取某个阶段boss的个数
int CScene::GetVisibleMonsterBossNum(int step)
{
	int num = 0;
	boost::recursive_mutex::scoped_lock lk(m_monster_mutex);
	for(list<SVisibleMonsterBoss>::iterator i = m_visibleMonstersBoss.begin();i != m_visibleMonstersBoss.end();i++)
	{
		if(i->step == step)
			++num;
	}
	return num;
}

// 显示某个阶段的boss
void CScene::ShowVisibleMonsterBoss(int step)
{
	boost::recursive_mutex::scoped_lock lk(m_monster_mutex);

	// 整理怪物信息
	CNetMessage msg;
	msg.SetType(MSG_MONSTER_OPTION);
	msg<<(uint8)1;
	uint8 monsterNum = 0;
	int pos = msg.GetDataLen();
	msg<<monsterNum;
	for(list<SVisibleMonsterBoss>::iterator i = m_visibleMonstersBoss.begin();i != m_visibleMonstersBoss.end();i++)
	{
		if(i->step == step)
		{
			i->isVisible = true;
			monsterNum++;
			int monsterId = i->monsterId;
			msg<<i->id<<i->name<<monsterId<<i->pic<<(uint16)0<<i->x<<i->y<<i->face<<(uint8)2;		// boss怪
			//cout<<">>> 阶段boss刷新： step:" << step << ",Boss scene = "<<GetId()<<", monster: id="<<i->id<<", monsterId="<<i->pic<<", x="<<i->x<<", y="<<i->y<<", face="<<(int)i->face<<",name="<<i->name<<endl;
		}
	}
	msg.WriteData(pos,&monsterNum,sizeof(monsterNum));

	// 通知所有当前场景玩家
	list<uint32>::iterator iter = m_userList.begin();
	for (; iter != m_userList.end(); iter++)
	{
		ShareUserPtr p = m_onlineUser.GetUserByRoleId(*iter);
		CUser* pUser = p.get();
		if (pUser != NULL)
		{
			m_socketServer.SendMsg(pUser->GetSock(),msg);
		}
	}

	SetFBStep(step);
}

// 获取怪物掉落
SVisibleMonsterBossDrop* CScene::GetVisibleMonsterBossDrop(int id)
{
	boost::recursive_mutex::scoped_lock lk(m_monster_mutex);
	for(list<SVisibleMonsterBoss>::iterator i = m_visibleMonstersBoss.begin();i != m_visibleMonstersBoss.end();i++)
	{
		if((int)i->id == id)
		{
			return &(i->dropItems);
		}
	}
	return NULL;
}

void CScene::DelVisibleMonster(uint32 id)
{
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		for (list<SVisibleMonster>::iterator i = m_visibleMonsters.begin();	i != m_visibleMonsters.end(); i++)
		{
			if (i->id == id)
			{
				m_visibleMonsters.erase(i);
				CNetMessage msg;
				msg.SetType(MSG_SERVER_REMOVE_MONSTER);
				msg << id;
				BroadcastMsg(msg);
				return;
			}
		}
	}

	{
		boost::recursive_mutex::scoped_lock lk(m_monster_mutex);
		for(list<SVisibleMonsterBoss>::iterator i = m_visibleMonstersBoss.begin();i != m_visibleMonstersBoss.end();i++)
		{
			if(i->id == id)
			{
				m_visibleMonstersBoss.erase(i);
				CNetMessage msg;
				msg.ReWrite();
				msg.SetType(MSG_MONSTER_OPTION);
				msg<<(uint8)3<<id;
				BroadcastMsg(msg);
				break;
			}
		}
	}
/*	for(list<SMonsterListInfo>::iterator i = m_MonsterList.begin();i != m_MonsterList.end();i++)
	{
		for(list<SVisibleMonster>::iterator j = i->monsterList.begin(); j != i->monsterList.end();j++)
		{
			msg<<j->id<<j->monster_id<<j->x<<j->y<<j->face;
		}
	}
*/
}

void CScene::AddJumpPoint(uint16 x, uint16 y, uint16 toX, uint16 toY, uint16 sceneId)
{
	m_addJump = true;
	/*
	SJumpTo *pJump = new SJumpTo;
	pJump->sceneId = sceneId;
	pJump->x = toX;
	pJump->y = toY;
	pJump->face = 8;
	InsertJumpPoint(x,y,pJump);
	*/
	m_jumpPoint.x = x;
	m_jumpPoint.y = y;
	m_jumpToPoint.x = toX;
	m_jumpToPoint.y = toY;
	m_jumpToPoint.face = 8;
	m_jumpToPoint.sceneId = sceneId;

	CNetMessage msg;
	msg.SetType(MSG_SERVER_JUMP_POINT);
	msg << (uint8)0 << x << y;
	BroadcastMsg(msg);
}

void CScene::AddXunChaShiNPCMonster(int npcId,vector<SPointFace> &point,vector<int> &fightId,vector<int> &monsterId)
{
	uint16 size = point.size();
	CMonsterBossManager &bossMgr = SingletonMonsterBossManager::instance();
	for(uint16 i=0;i < size;i++)
	{
		int pic = 0;
		string name;
		if(!bossMgr.GetMonsterBossInfo(monsterId[i],pic,name))
			continue;
		AddNpcIndexByFightId(npcId,fightId[i],point[i].x,point[i].y,point[i].face,i+1,pic);
	}
}

// bossType 0-3
void CScene::AddLingQiJuanXianNPCMonster(int refreshValue)
{
	const int limitMonsterNum = 15;
	// 怪点
	const SPoint scenePoint[] = {{598,1123},{923,1096},{1061,958},{496,889},{111,818},{123,624},{536,579},{706,532},{507,373},{931,477},
		{1477,812},{1622,904},{1674,698},{1520,418},{1444,289},{1669,340},{1804,377},{1677,241},{1906,233},{1221,537}};

	SPoint *pScenePoint = (SPoint *)scenePoint;
	uint16 pointSize = sizeof(scenePoint)/sizeof(scenePoint[0]);

	int NPCMonsterNum = 0;	// 灵魔数量
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		for(list<SNpcInstance*>::iterator i = m_dynamicNpc.begin(); i != m_dynamicNpc.end(); i++)
		{
			if((*i)->id >= 154 && (*i)->id <= 157)	// 灵魔
				NPCMonsterNum++;
		}
	}
	if(NPCMonsterNum >= limitMonsterNum)
		return;
	int num = limitMonsterNum - NPCMonsterNum;

	uint16 npcId = 0;
//	uint16 pic = 0;
	if(refreshValue <= 300)
		npcId = 154;
	else if(refreshValue <= 600)
		npcId = 155;
	else if(refreshValue <= 900)
		npcId = 156;
	else
		npcId = 157;

    const int MAX_NUM = 512;
	int sequence[MAX_NUM];
    pointSize = pointSize > MAX_NUM ? MAX_NUM : pointSize;
	if(!RandomSequence(sequence,pointSize,pointSize))
        return;

	uint16 pointCount = 0;
	for(uint16 i=0;i < pointSize;i++)
	{
		if(pointCount >= num)
			break;
		int fightId = 0;
		if(refreshValue <= 300)	// 虚弱的灵魔
			fightId = Random(11101,11106);
		else if(refreshValue <= 600)	// 强壮的灵魔
			fightId = Random(11111,11116);
		else if(refreshValue <= 900)	// 完美的灵魔
			fightId = Random(11121,11126);
		else	// 恐怖的灵魔
			fightId = Random(11131,11136);

		bool samePoint = false;
		{
			boost::recursive_mutex::scoped_lock lk(m_mutex);
			for(list<SNpcInstance*>::iterator j = m_dynamicNpc.begin(); j != m_dynamicNpc.end(); j++)
			{
				if((*j)->id >= 154 && (*j)->id <= 157 && (*j)->x == pScenePoint[sequence[i]-1].x && (*j)->y == pScenePoint[sequence[i]-1].y)
				{
					samePoint = true;
					break;
				}
			}
		}
		if(!samePoint)
		{
			AddNpcIndexByFightId(npcId,fightId,pScenePoint[sequence[i]-1].x,pScenePoint[sequence[i]-1].y,0,m_NPCMonSterIndex++);
			pointCount++;
		}
	}
}

const char *CScene::GetDynamicNpcName(uint32 npcId,uint32 index)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(list<SNpcInstance*>::iterator i=m_dynamicNpc.begin(); i != m_dynamicNpc.end(); i++)
	{
		if((*i)->id == npcId && (*i)->index == index)
			return (*i)->name.c_str();
	}
	return NULL;
}

void CScene::ClearTreasureMonster()
{
	const time_t CLEAR_TIME = 60*10;
	time_t curTime = GetSysTime();
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	list<SVisibleMonsterBoss>::iterator t = m_visibleMonstersBoss.begin();
	for(list<SVisibleMonsterBoss>::iterator i = m_visibleMonstersBoss.begin(); i != m_visibleMonstersBoss.end();)
	{
		t = i;
		i++;
		if(t->type == EMT_Treasure)
		{
			if(curTime - t->create_time >= CLEAR_TIME)
			{
				CNetMessage msg;
				msg.ReWrite();
				msg.SetType(MSG_MONSTER_OPTION);
				msg<<(uint8)3<<t->id;
				BroadcastMsg(msg);
				m_visibleMonstersBoss.erase(t);
			}
		}
	}
}

void CScene::ClearXunChaShiNPCMonster()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	list<SNpcInstance*>::iterator t = m_dynamicNpc.begin();
	for(list<SNpcInstance*>::iterator i = m_dynamicNpc.begin(); i != m_dynamicNpc.end();)
	{
		if((*i)->id >= 185 && (*i)->id <= 190)	// 巡察使
		{
			CNetMessage msg;
			msg.SetType(PRO_DEL_NPC);
			msg <<(*i)->id<<(*i)->index;
			BroadcastMsg(msg);

			t = i;
			i++;
			delete *t;
			m_dynamicNpc.erase(t);
		}
		else
		{
			i++;
		}
	}
}

void CScene::ClearLingQiJuanXianNPCMonster()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	list<SNpcInstance*>::iterator t = m_dynamicNpc.begin();
	for(list<SNpcInstance*>::iterator i = m_dynamicNpc.begin(); i != m_dynamicNpc.end();)
	{
		if((*i)->id >= 154 && (*i)->id <= 157)	// 灵魔
		{
			for(int j=0;j < (int)m_dynamicNpcPoint.size();j++)
			{
				if((*i)->x == m_dynamicNpcPoint[j].x && (*i)->y == m_dynamicNpcPoint[j].y)
				{
					m_dynamicNpcPoint.erase(m_dynamicNpcPoint.begin() + j);
					break;
				}
			}

			CNetMessage msg;
			msg.SetType(PRO_DEL_NPC);
			msg <<(*i)->id<<(*i)->index;
			BroadcastMsg(msg);

			t = i;
			i++;
			delete *t;
			m_dynamicNpc.erase(t);
		}
		else
		{
			i++;
		}
	}
}

void CScene::FeiXianSceneAddExp()
{
	if(m_srcSceneId < FEI_XIAN_SID1 || m_srcSceneId > FEI_XIAN_SID5)
		return;

	int floor = m_srcSceneId - FEI_XIAN_SID1 + 1;

	list<uint32> userList;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		userList = m_userList;
	}
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	//char buf[128];
	for(list<uint32>::iterator i = userList.begin(); i != userList.end(); i++)
	{
		ShareUserPtr ptr = onlineUser.GetUserByRoleId(*i);
		CUser *pUser = ptr.get();
		if(pUser != NULL)
		{
			int exp = GetFeiXianExpByFloor(floor,pUser->GetLevel());
			exp+=exp*G_VipConfig[pUser->GetVipLevel()].fxexp/100;
			pUser->AddExp(exp, true);
			//snprintf(buf,sizeof(buf),"获得%d经验",exp);
			//SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
			pUser->UpdateFeiXianData();
		}
	}
}

void CScene::AddKunLunShanTeamMonster()
{
	if(m_srcSceneId != KUN_LUN_SHAN_TEAM_SCENE_ID)
		return;
	const int monsterNumLimit = 30;
	
	boost::recursive_mutex::scoped_lock lk1(m_mutex);
	boost::recursive_mutex::scoped_lock lk(m_monster_mutex);
	uint16 x=0,y=0;
	uint16 monsterNum = m_visibleMonstersBoss.size();
	if(monsterNum >= monsterNumLimit)
		return;
	for(uint16 i=monsterNum;i < monsterNumLimit;i++)
	{
		SVisibleMonsterBoss monsterBoss;
		monsterBoss.id = NormalMonsterIdPos - m_monsterBossIdIndex;
		if(monsterBoss.id < 10000)
		{
			monsterBoss.id = NormalMonsterIdPos - 1;
			m_monsterBossIdIndex = 0;
		}
		m_monsterBossIdIndex++;
		monsterBoss.name = LANGUAGE_SSJ_0504;
		if(!GetCanWalkPos_NoLock(x,y))
			return;
		monsterBoss.center_x = x;
		monsterBoss.center_y = y;
		monsterBoss.radius = 50;
		monsterBoss.meetDistance = 50;
		monsterBoss.face = 3;
		monsterBoss.pic = 410;
		monsterBoss.type = 0;
		monsterBoss.step = 0;
		for(int k=0;k < CFight::GROUP2_BEGIN;k++)
			monsterBoss.scale[k] = 1.0f;
		monsterBoss.isVisible = true;
		monsterBoss.monsterId = monsterBoss.id;
		monsterBoss.x = monsterBoss.center_x;
		monsterBoss.y = monsterBoss.center_y;
		m_visibleMonstersBoss.push_back(monsterBoss);

		CNetMessage msg;
		msg.ReWrite();
		msg.SetType(MSG_MONSTER_OPTION);
		msg<<(uint8)2<<monsterBoss.id<<monsterBoss.name<<monsterBoss.monsterId<<monsterBoss.pic<<(uint16)0<<monsterBoss.center_x<<monsterBoss.center_y<<monsterBoss.face<<(uint8)2;	// boss怪
		BroadcastMsg(msg);
	}
}

void CScene::AddKunLunShanMonster()
{
	if(m_srcSceneId < KUN_LUN_SHAN_SCENE_ID || m_srcSceneId >= KUN_LUN_SHAN_SCENE_ID+30)
		return;

	boost::recursive_mutex::scoped_lock lk1(m_mutex);
	boost::recursive_mutex::scoped_lock lk(m_monster_mutex);
	uint16 x=0,y=0;
	uint16 monsterNum = m_visibleMonstersBoss.size();
	if(monsterNum >= 30)
		return;
	for(uint16 i=monsterNum;i < 30;i++)
	{
		SVisibleMonsterBoss monsterBoss;
		monsterBoss.id = NormalMonsterIdPos - m_monsterBossIdIndex;
		if(monsterBoss.id < 10000)
		{
			monsterBoss.id = NormalMonsterIdPos - 1;
			m_monsterBossIdIndex = 0;
		}
		m_monsterBossIdIndex++;
		monsterBoss.name = LANGUAGE_TRANSFORM_2801;
		if(!GetCanWalkPos_NoLock(x,y))
			return;
		monsterBoss.center_x = x;
		monsterBoss.center_y = y;
		monsterBoss.radius = 50;
		monsterBoss.meetDistance = 50;
		monsterBoss.face = 3;
		monsterBoss.pic = 107;
		monsterBoss.type = 0;
		monsterBoss.step = 0;
		for(int k=0;k < CFight::GROUP2_BEGIN;k++)
			monsterBoss.scale[k] = 1.0f;
		monsterBoss.isVisible = true;
		monsterBoss.monsterId = monsterBoss.id;
		monsterBoss.x = monsterBoss.center_x;
		monsterBoss.y = monsterBoss.center_y;
		m_visibleMonstersBoss.push_back(monsterBoss);

		CNetMessage msg;
		msg.ReWrite();
		msg.SetType(MSG_MONSTER_OPTION);
		msg<<(uint8)2<<monsterBoss.id<<monsterBoss.name<<monsterBoss.monsterId<<monsterBoss.pic<<(uint16)0<<monsterBoss.center_x<<monsterBoss.center_y<<monsterBoss.face<<(uint8)2;	// boss怪
		BroadcastMsg(msg);
	}
}

CScene *CSceneManager::FindBangPaiScene(int sid)
{
	boost::mutex::scoped_lock lk(m_bpMutex);
	CScene *pScene = NULL;
	m_bangPaiScene.Find(sid,pScene);
	return pScene;
}

//获得帮派场景
CScene *CSceneManager::GetBangPaiScene(int sceneId, int bangPaiId)
{
	CBangPai *pBangPai = SingletonCBangPaiManager::instance().FindBangPai(bangPaiId);
	if(pBangPai == NULL)
		return NULL;
	
	boost::mutex::scoped_lock lk(m_bpMutex);
	CScene *pScene = NULL;
	int bpSceneId = (bangPaiId << 8) | sceneId;
	if(m_bangPaiScene.Find(bpSceneId,pScene))	// 已存在
		return pScene;

	// 不存在，则创建
	m_sceneList.Find(sceneId,pScene);
	if(pScene == NULL)
		return NULL;
	CScene *pBpScene = new CScene(*pScene);
	pBpScene->SetId(bpSceneId);
	pBpScene->SetSrcSceneId(sceneId);
	m_bangPaiScene.Insert(pBpScene->GetId(), pBpScene);
	return pBpScene;
}

//获得跨服帮战场景
CScene *CSceneManager::GetKuaFuBZScene(int groupIdx)
{
	if(groupIdx <= 0 || groupIdx > CBangPaiManager::MAX_KFBZ_GROUP)
		return NULL;
	CScene *pScene = NULL;
	boost::mutex::scoped_lock lk(m_bpMutex);
	m_sceneList.Find(KUAFU_BZ_SCENE_ID_BEGIN+groupIdx-1,pScene);
	if(pScene == NULL)
	{
		m_sceneList.Find(KUAFU_BZ_SID,pScene);
		if(pScene == NULL)
			return NULL;
		pScene = new CScene(*pScene);
		pScene->SetId(KUAFU_BZ_SCENE_ID_BEGIN+groupIdx-1);
		pScene->SetSrcSceneId(KUAFU_BZ_SID);
		pScene->m_startTime = GetSysTime();
		pScene->SetGroupId(pScene->GetId());
		m_sceneList.Insert(pScene->GetId(),pScene);
	}
	return pScene;
}

CScene *CSceneManager::FindMarryHall(int id)
{
	boost::mutex::scoped_lock lk(m_bpMutex);
	for (list<CScene*>::iterator i = m_marryHall.begin(); i != m_marryHall.end(); i++)
	{
		if ((*i)->GetId() == id)
		{
			return *i;
		}
	}
	return NULL;
}

CScene *CSceneManager::GetMarryHall(int id)
{
	boost::mutex::scoped_lock lk(m_bpMutex);
	for (list<CScene*>::iterator i = m_marryHall.begin(); i != m_marryHall.end(); i++)
	{
		if ((*i)->GetId() == id)
		{
			return *i;
		}
	}
	CScene *pScene = NULL;
	m_sceneList.Find(250, pScene);
	if (pScene == NULL)
		return NULL;
	CScene *pMarryScene = new CScene(*pScene);
	pMarryScene->SetId(id);
	m_marryHall.push_back(pMarryScene);
	return pMarryScene;
}

bool CSceneManager::FindMapGroupScene(int id, CScene *pScene, int mapId, int groupId, CScene **ppScene)
{
	if ((pScene->GetMapId() == mapId) && (pScene->GetGroupId() == groupId))
	{
		*ppScene = pScene;
		return false;
	}
	return true;
}

bool CSceneManager::Find2MapGroupScene(int id, CScene *pScene, int mapId, int groupId, CScene **ppScene)
{
	if ((id == mapId) && (pScene->GetGroupId() == groupId))
	{
		*ppScene = pScene;
		return false;
	}
	return true;
}

bool CSceneManager::FindGroupScene(int id, CScene *pScene, int groupId, list<int> *sceneList)
{
	if (pScene->GetGroupId() == groupId)
	{
		sceneList->push_back(id);
	}
	return true;
}

void CSceneManager::GetGroupScene(int groupId, list<int> &sceneList)
{
	boost::mutex::scoped_lock lk(m_bpMutex);
	m_sceneList.ForEach(boost::bind(&CSceneManager::FindGroupScene,this, _1, _2, groupId, &sceneList));
}

// 副本是否没有人了
bool CSceneManager::IsFuBenEmpty(CScene* pScene)
{
	if (pScene == NULL)
		return false;
	if(!IsFuBen(pScene->GetSrcSceneId()))
		return false;
	if (pScene->GetUserNum() > 0)
		return false;

	int countLimit = 10;
	CScene* pNxt = Find2Scene(pScene->GetNextFuBenId(),pScene->GetGroupId());
	while (pNxt != NULL)
	{
		--countLimit;
		if (countLimit <=0)
			return true;

		if (pNxt->GetUserNum() > 0)
			return false;
		pNxt = Find2Scene(pNxt->GetNextFuBenId(),pScene->GetGroupId());
	}

	return true;
}

// 获取当前副本进度的副本地图id
CScene *CSceneManager::GetCurrentFuBen(CScene* pScene)
{
	if (pScene == NULL)
		return NULL;
	if (!pScene->IsFuBen()) // 不是副本
		return NULL;
//	cout << "获取队伍进度信息 当前场景id：" << pScene->GetId() << ",srcId:" << pScene->GetSrcSceneId() << ",grpId:" << pScene->GetGroupId() << endl;
	if (pScene->GetUserNum() > 0)
		return pScene;

	int countLimit = 10; // 循环上限 防止死循环
	CScene* pNxt = Find2Scene(pScene->GetNextFuBenId(),pScene->GetGroupId());
	while (pNxt != NULL)
	{
		--countLimit;
		if (countLimit <=0)
			return NULL;

//		cout << "获取队伍进度信息 下个场景id：" << pNxt->GetId() << ",srcId:" << pNxt->GetSrcSceneId() << ",grpId:" << pNxt->GetGroupId() << endl;;
		if (pNxt->GetUserNum() > 0)
			return pNxt;
		pNxt = Find2Scene(pNxt->GetNextFuBenId(),pScene->GetGroupId());
	}

	return NULL;
}

CScene *CSceneManager::FindScene(int mapId, int groupId)
{
	CScene *pScene = NULL;
	boost::mutex::scoped_lock lk(m_bpMutex);
	m_sceneList.ForEach(boost::bind(&CSceneManager::FindMapGroupScene,
			this, _1, _2, mapId, groupId, &pScene));
	return pScene;
}

CScene *CSceneManager::Find2Scene(int mapId, int groupId)
{
	CScene *pScene = NULL;
	boost::mutex::scoped_lock lk(m_bpMutex);
	m_sceneList.ForEach(boost::bind(&CSceneManager::Find2MapGroupScene,
		this, _1, _2, mapId, groupId, &pScene));
	return pScene;
}

void CSceneManager::DelScene(int id)
{
	boost::mutex::scoped_lock lk(m_bpMutex);
	CScene *pScene = NULL;
	m_sceneList.Erase(id,pScene);
	delete pScene;
}

//删除帮派场景
void CSceneManager::DelBangPaiScene(int bangPaiId)
{
	boost::mutex::scoped_lock lk(m_bpMutex);
	CScene *pScene = NULL;
	m_bangPaiScene.Erase(bangPaiId, pScene);
	delete pScene;
}

void CSceneManager::FeiXianSceneAddExp()
{
	boost::mutex::scoped_lock lk(m_bpMutex);
	CScene *pScene = NULL;
	for(int sid=FEI_XIAN_SID1;sid <= FEI_XIAN_SID5;sid++)
	{
		if(m_sceneList.Find(sid,pScene))
		{
			if(pScene != NULL)
				pScene->FeiXianSceneAddExp();
		}
	}
}

void CSceneManager::AddKunLunShanTeamMonster()
{
	boost::mutex::scoped_lock lk(m_bpMutex);
	CScene *pScene = NULL;
	for(int i=0;i < m_kunLunShanTeamSceneNum;i++)
	{
		m_sceneList.Find(KUN_LUN_SHAN_TEAM_SCENE_ID_BEGIN+i,pScene);
		if(pScene != NULL)
			pScene->AddKunLunShanTeamMonster();
	}
}

void CSceneManager::AddKunLunShanMonster()
{
	boost::mutex::scoped_lock lk(m_bpMutex);
	CScene *pScene = NULL;
	for(int i=0;i < m_kunLunShanSceneNum;i++)
	{
		m_sceneList.Find(KUN_LUN_SHAN_SCENE_ID_BEGIN+i,pScene);
		if(pScene != NULL)
			pScene->AddKunLunShanMonster();
	}
}

CScene *CSceneManager::GetKunLunShanFirstScene()
{
	CScene *pScene = NULL;
	boost::mutex::scoped_lock lk(m_bpMutex);
	m_sceneList.Find(KUN_LUN_SHAN_SCENE_ID_BEGIN,pScene);	// 昆仑山
	if(pScene == NULL)
	{
		m_sceneList.Find(KUN_LUN_SHAN_SCENE_ID,pScene);	// 昆仑山
		if(pScene == NULL)
			return NULL;
		m_kunLunShanSceneNum = 1;
		pScene = new CScene(*pScene);
		pScene->SetId(KUN_LUN_SHAN_SCENE_ID_BEGIN);
		pScene->SetSrcSceneId(KUN_LUN_SHAN_SCENE_ID);
		pScene->m_usedFuBen = true;
		pScene->m_startTime = GetSysTime();
		pScene->SetGroupId(pScene->GetId());
		m_sceneList.Insert(pScene->GetId(),pScene);
	}
	return pScene;
}

CScene *CSceneManager::GetKunLunShanSceneByIndex(int sceneIndex)
{
	if(sceneIndex <= 0 || sceneIndex > m_kunLunShanSceneNum+1)
		return NULL;
	CScene *pScene = NULL;
	boost::mutex::scoped_lock lk(m_bpMutex);
	m_sceneList.Find(KUN_LUN_SHAN_SCENE_ID_BEGIN+sceneIndex-1,pScene);	// 第index个昆仑山场景
	if(pScene == NULL && sceneIndex == m_kunLunShanSceneNum+1)
	{
		m_sceneList.Find(KUN_LUN_SHAN_SCENE_ID+sceneIndex-1,pScene);	// 昆仑山
		if(pScene == NULL)
			return NULL;
		m_kunLunShanSceneNum++;
		pScene = new CScene(*pScene);
		pScene->SetId(KUN_LUN_SHAN_SCENE_ID_BEGIN+sceneIndex-1);
		pScene->SetSrcSceneId(KUN_LUN_SHAN_SCENE_ID+sceneIndex-1);
		pScene->m_usedFuBen = true;
		pScene->m_startTime = GetSysTime();
		pScene->SetGroupId(pScene->GetId());
		pScene->AddKunLunShanMonster();
		m_sceneList.Insert(pScene->GetId(),pScene);
	}
	return pScene;
}

CScene *CSceneManager::GetTeamKunLunShanFirstScene()
{
	CScene *pScene = NULL;
	boost::mutex::scoped_lock lk(m_bpMutex);
	m_sceneList.Find(KUN_LUN_SHAN_TEAM_SCENE_ID_BEGIN,pScene);	// 组队昆仑山
	if(pScene == NULL)
	{
		m_sceneList.Find(KUN_LUN_SHAN_TEAM_SCENE_ID,pScene);	// 组队昆仑山
		if(pScene == NULL)
			return NULL;
		m_kunLunShanTeamSceneNum = 1;
		pScene = new CScene(*pScene);
		pScene->SetId(KUN_LUN_SHAN_TEAM_SCENE_ID_BEGIN);
		pScene->SetSrcSceneId(KUN_LUN_SHAN_TEAM_SCENE_ID);
		pScene->m_usedFuBen = true;
		pScene->m_startTime = GetSysTime();
		pScene->SetGroupId(pScene->GetId());
		m_sceneList.Insert(pScene->GetId(),pScene);
	}
	return pScene;
}

CScene *CSceneManager::GetKunLunShanTeamSceneByIndex(int sceneIndex)
{
	if(sceneIndex <= 0 || sceneIndex > m_kunLunShanTeamSceneNum+1)
		return NULL;
	CScene *pScene = NULL;
	boost::mutex::scoped_lock lk(m_bpMutex);
	m_sceneList.Find(KUN_LUN_SHAN_TEAM_SCENE_ID_BEGIN+sceneIndex-1,pScene);	// 第index个昆仑山场景
	if(pScene == NULL && sceneIndex == m_kunLunShanTeamSceneNum+1)
	{
		m_sceneList.Find(KUN_LUN_SHAN_TEAM_SCENE_ID,pScene);	// 昆仑山
		if(pScene == NULL)
			return NULL;
		m_kunLunShanTeamSceneNum++;
		pScene = new CScene(*pScene);
		pScene->SetId(KUN_LUN_SHAN_TEAM_SCENE_ID_BEGIN+sceneIndex-1);
		pScene->SetSrcSceneId(KUN_LUN_SHAN_TEAM_SCENE_ID);
		pScene->AddKunLunShanTeamMonster();
		pScene->m_usedFuBen = true;
		pScene->m_startTime = GetSysTime();
		pScene->SetGroupId(pScene->GetId());
		m_sceneList.Insert(pScene->GetId(),pScene);
	}
	return pScene;
}

CScene *CSceneManager::GetShenJieMiJingFirstScene()
{
	CScene *pScene = NULL;
	boost::mutex::scoped_lock lk(m_bpMutex);
	m_sceneList.Find(SHENJIEMIJING_SCENE_ID_BEGIN,pScene);
	if(pScene == NULL)
	{
		m_sceneList.Find(SHENJIEMIJING_SCENE_ID,pScene);
		if(pScene == NULL)
			return NULL;
		m_shenjiemijingSceneNum = 1;
		pScene = new CScene(*pScene);
		pScene->SetId(SHENJIEMIJING_SCENE_ID_BEGIN);
		pScene->SetSrcSceneId(SHENJIEMIJING_SCENE_ID);
		pScene->m_usedFuBen = true;
		pScene->m_startTime = GetSysTime();
		pScene->SetGroupId(pScene->GetId());
		m_sceneList.Insert(pScene->GetId(),pScene);
#ifdef KUA_FU
		if (SingletonCShenJieMiJingManager::instance().GetCurrentBossID() != 0)
		{
			SingletonCShenJieMiJingManager::instance().SummonBoss( SingletonCShenJieMiJingManager::instance().GetCurrentBossID(),pScene);
		}
#endif
	}
	return pScene;
}

CScene *CSceneManager::GetShenJieMiJingSceneByIndex(int sceneIndex)
{
	if(sceneIndex <= 0 || sceneIndex > m_shenjiemijingSceneNum+1)
		return NULL;
	CScene *pScene = NULL;
	bool createScene = false;
	{
		boost::mutex::scoped_lock lk(m_bpMutex);
		m_sceneList.Find(SHENJIEMIJING_SCENE_ID_BEGIN+sceneIndex-1,pScene);	
		if(pScene == NULL && sceneIndex == m_shenjiemijingSceneNum+1)
		{
			m_sceneList.Find(SHENJIEMIJING_SCENE_ID,pScene);	
			if(pScene == NULL)
				return NULL;
			++m_shenjiemijingSceneNum;
			pScene = new CScene(*pScene);
			pScene->SetId(SHENJIEMIJING_SCENE_ID_BEGIN+sceneIndex-1);
			pScene->SetSrcSceneId(SHENJIEMIJING_SCENE_ID);
			pScene->m_usedFuBen = true;
			pScene->m_startTime = GetSysTime();
			pScene->SetGroupId(pScene->GetId());
			m_sceneList.Insert(pScene->GetId(),pScene);
			createScene = true;
		}
	}
	
	if(createScene && pScene != NULL)
	{
#ifdef KUA_FU
		int bossId = SingletonCShenJieMiJingManager::instance().GetCurrentBossID();
		if(bossId != 0)
			SingletonCShenJieMiJingManager::instance().SummonBoss(bossId,pScene);
#endif
	}
	return pScene;
}
CScene *CSceneManager::GetKuaFu1V1SceneByIndex(int sceneIndex)
{
	if(sceneIndex < 1 || sceneIndex > KUA_FU_1V1_SCENE_NUM)
		return NULL;
	CScene *pScene = NULL;
	boost::mutex::scoped_lock lk(m_bpMutex);
	m_sceneList.Find(KUA_FU_1V1_SCENE_FB_BEGIN+sceneIndex-1,pScene);	// 第index个1V1场景
	if(pScene == NULL)
	{
		m_sceneList.Find(KUA_FU_1V1_SCENE_ID,pScene);	// 昆仑山
		if(pScene == NULL)
			return NULL;
		pScene = new CScene(*pScene);
		pScene->SetId(KUA_FU_1V1_SCENE_FB_BEGIN+sceneIndex-1);
		pScene->SetSrcSceneId(KUA_FU_1V1_SCENE_ID);
		pScene->m_usedFuBen = true;
		pScene->m_startTime = GetSysTime();
		pScene->m_1V1SceneTime = GetKuaFu1V1TurnStartTime();
		pScene->SetFBStep(0);
		pScene->SetGroupId(pScene->GetId());
		m_sceneList.Insert(pScene->GetId(),pScene);
	}
	return pScene;
}


CScene *CSceneManager::GetShiLianFuBen()
{
	CScene *pScene = NULL;
	boost::mutex::scoped_lock lk(m_bpMutex);
	m_sceneList.Find(COPY_ID_SHI_LIAN,pScene);
	if(pScene == NULL)
		return NULL;

	pScene = new CScene(*pScene);
	pScene->SetId(m_curFuBenId++);
	pScene->SetSrcSceneId(COPY_ID_SHI_LIAN);
	pScene->m_usedFuBen = true;
	pScene->m_startTime = GetSysTime();
	pScene->SetGroupId(pScene->GetId());
	m_sceneList.Insert(pScene->GetId(),pScene);
	return pScene;
}

CScene *CSceneManager::GetQiangHuaFuBen()
{
	CScene *pScene = NULL;
	boost::mutex::scoped_lock lk(m_bpMutex);

	m_sceneList.Find(COPY_ID_QIANG_HUA,pScene);
	if(pScene == NULL)
		return NULL;

	pScene = new CScene(*pScene);
	pScene->SetId(m_curFuBenId++);
	//	pScene->SetMapId(20);
	pScene->SetSrcSceneId(COPY_ID_QIANG_HUA);
	pScene->m_usedFuBen = true;
	pScene->m_startTime = GetSysTime();
	pScene->SetGroupId(pScene->GetId());
	m_sceneList.Insert(pScene->GetId(),pScene);
	return pScene;
}

CScene *CSceneManager::GetChongWuFuBen(int difficulty)
{
	if(difficulty > COPY_ID_CHONG_WU_4 - COPY_ID_CHONG_WU_1)
		return NULL;
	int sceneId = COPY_ID_CHONG_WU_1 + difficulty;
	CScene *pScene = NULL;
	boost::mutex::scoped_lock lk(m_bpMutex);
	m_sceneList.Find(sceneId,pScene);
	if(pScene == NULL)
		return NULL;
	
	pScene = new CScene(*pScene);
	pScene->SetId(m_curFuBenId++);
	//	pScene->SetMapId(20);
	pScene->SetSrcSceneId(sceneId);
	pScene->m_usedFuBen = true;
	pScene->m_startTime = GetSysTime();
	pScene->SetGroupId(pScene->GetId());
	m_sceneList.Insert(pScene->GetId(),pScene);
	return pScene;
}

CScene *CSceneManager::GetJinBiFuBen()
{
	CScene *pScene = NULL;
	boost::mutex::scoped_lock lk(m_bpMutex);

	int startMapId = COPY_ID_MONEY;
	m_sceneList.Find(startMapId,pScene);
	if(pScene == NULL)
		return NULL;

	pScene = new CScene(*pScene);
	pScene->SetId(m_curFuBenId++);
	pScene->SetSrcSceneId(startMapId);
	pScene->m_usedFuBen = true;
	pScene->m_startTime = GetSysTime();
	pScene->SetGroupId(pScene->GetId());
	pScene->SetNextFuBenId(m_curFuBenId);

	m_sceneList.Insert(pScene->GetId(),pScene);
	/* 临时注释，副本调整为1层
	for(uint8 i = 1; i < 2; i++)
	{
		CScene *pDiGong = NULL;
		m_sceneList.Find(startMapId+i, pDiGong);
		if (pDiGong != NULL)
		{
			pDiGong = new CScene(*pDiGong);
			pDiGong->SetId(m_curFuBenId++);
			pDiGong->SetSrcSceneId(startMapId+i);
			pDiGong->SetGroupId(pScene->GetId());
			pDiGong->m_usedFuBen = true;
			pDiGong->m_startTime = GetSysTime();
			m_sceneList.Insert(pDiGong->GetId(), pDiGong);
		}
	}*/
	return pScene;
}

CScene *CSceneManager::GetDaoJuFuBen()
{
	CScene *pScene = NULL;
	boost::mutex::scoped_lock lk(m_bpMutex);

	int startMapId = COPY_ID_SHENG_JIE;
	m_sceneList.Find(startMapId,pScene);
	if(pScene == NULL)
		return NULL;

	pScene = new CScene(*pScene);
	pScene->SetId(m_curFuBenId++);
	pScene->SetSrcSceneId(startMapId);
	pScene->m_usedFuBen = true;
	pScene->m_startTime = GetSysTime();
	pScene->SetGroupId(pScene->GetId());
	pScene->SetNextFuBenId(m_curFuBenId);

	m_sceneList.Insert(pScene->GetId(),pScene);
	/* 临时注释，副本调整为1层
	for(uint8 i = 1; i < 3; i++)
	{
		CScene *pDiGong = NULL;
		m_sceneList.Find(startMapId+i, pDiGong);
		if (pDiGong != NULL)
		{
			pDiGong = new CScene(*pDiGong);
			pDiGong->SetId(m_curFuBenId++);
			pDiGong->SetSrcSceneId(startMapId+i);
			pDiGong->SetGroupId(pScene->GetId());
			pDiGong->m_usedFuBen = true;
			pDiGong->m_startTime = GetSysTime();
			if(i == 1)
				pDiGong->SetNextFuBenId(m_curFuBenId);
			m_sceneList.Insert(pDiGong->GetId(), pDiGong);
		}
	}*/
	return pScene;
}

CScene *CSceneManager::GetChongKaiFuBen()
{
	CScene *pScene = NULL;
	boost::mutex::scoped_lock lk(m_bpMutex);
	int startMapId = COPY_ID_CHONG_KAI;
	m_sceneList.Find(startMapId,pScene);
	if(pScene == NULL)
		return NULL;
	pScene = new CScene(*pScene);
	pScene->SetId(m_curFuBenId++);
	pScene->SetSrcSceneId(startMapId);
	pScene->m_usedFuBen = true;
	pScene->m_startTime = GetSysTime();
	pScene->SetGroupId(pScene->GetId());
	pScene->SetNextFuBenId(m_curFuBenId);
	m_sceneList.Insert(pScene->GetId(),pScene);
	return pScene;
}

CScene *CSceneManager::GetXiangQianFuBen()
{
	CScene *pScene = NULL;
	boost::mutex::scoped_lock lk(m_bpMutex);
	int startMapId = COPY_ID_XIANG_QIAN;
	m_sceneList.Find(startMapId,pScene);
	if(pScene == NULL)
		return NULL;
	pScene = new CScene(*pScene);
	pScene->SetId(m_curFuBenId++);
	pScene->SetSrcSceneId(startMapId);
	pScene->m_usedFuBen = true;
	pScene->m_startTime = GetSysTime();
	pScene->SetGroupId(pScene->GetId());
	pScene->SetNextFuBenId(m_curFuBenId);
	m_sceneList.Insert(pScene->GetId(),pScene);
	return pScene;
}

CScene *CSceneManager::GetXiLianFuBen()
{
	CScene *pScene = NULL;
	boost::mutex::scoped_lock lk(m_bpMutex);
	int startMapId = COPY_ID_CUI_LIAN;
	m_sceneList.Find(startMapId,pScene);
	if(pScene == NULL)
		return NULL;
	pScene = new CScene(*pScene);
	pScene->SetId(m_curFuBenId++);
	pScene->SetSrcSceneId(startMapId);
	pScene->m_usedFuBen = true;
	pScene->m_startTime = GetSysTime();
	pScene->SetGroupId(pScene->GetId());
	pScene->SetNextFuBenId(m_curFuBenId);
	m_sceneList.Insert(pScene->GetId(),pScene);
	return pScene;
}

CScene *CSceneManager::GetQianNengFuBen()
{
	CScene *pScene = NULL;
	boost::mutex::scoped_lock lk(m_bpMutex);

	int startMapId = COPY_ID_QIAN_NENG;
	m_sceneList.Find(startMapId,pScene);
	if(pScene == NULL)
		return NULL;

	pScene = new CScene(*pScene);
	pScene->SetId(m_curFuBenId++);
	pScene->SetSrcSceneId(startMapId);
	pScene->m_usedFuBen = true;
	pScene->m_startTime = GetSysTime();
	pScene->SetGroupId(pScene->GetId());
	pScene->SetNextFuBenId(m_curFuBenId);

	m_sceneList.Insert(pScene->GetId(),pScene);
	/* 临时注释，副本调整为1层
	for(uint8 i = 1; i < 2; i++)
	{
		CScene *pDiGong = NULL;
		m_sceneList.Find(startMapId+i, pDiGong);
		if (pDiGong != NULL)
		{
			pDiGong = new CScene(*pDiGong);
			pDiGong->SetId(m_curFuBenId++);
			pDiGong->SetSrcSceneId(startMapId+i);
			pDiGong->SetGroupId(pScene->GetId());
			pDiGong->m_usedFuBen = true;
			pDiGong->m_startTime = GetSysTime();
			m_sceneList.Insert(pDiGong->GetId(), pDiGong);
		}
	}*/
	return pScene;
}

bool CSceneManager::GetKunLunShanRoomInfo(CNetMessage &msg)
{
	boost::mutex::scoped_lock lk(m_bpMutex);
	uint16 pos = msg.GetDataLen();
	uint16 num = 0;
	msg<<num;
	for(int i = 0;i < m_kunLunShanSceneNum;i++)
	{
		CScene *pScene = NULL;
		m_sceneList.Find(KUN_LUN_SHAN_SCENE_ID_BEGIN+i,pScene);
		if(pScene != NULL)
		{
			num++;
			msg<<(uint16)(i+1)<<pScene->GetUserNum()<<KUN_LUN_SHAN_ROOM_LIMIT;
		}
	}
	if(num > 0)
	{
		msg.WriteData(pos,&num,sizeof(num));
		return true;
	}
	else
	{
		return false;
	}
}

bool CSceneManager::GetTeamKunLunShanRoomInfo(CNetMessage &msg)
{
	boost::mutex::scoped_lock lk(m_bpMutex);
	uint16 pos = msg.GetDataLen();
	uint16 num = 0;
	msg<<num;
	for(int i = 0;i < m_kunLunShanTeamSceneNum;i++)
	{
		CScene *pScene = NULL;
		m_sceneList.Find(KUN_LUN_SHAN_TEAM_SCENE_ID_BEGIN+i,pScene);
		if(pScene != NULL)
		{
			num++;
			msg<<(uint16)(i+1)<<pScene->GetUserNum()<<KUN_LUN_SHAN_TEAM_ROOM_LIMIT;
		}
	}
	if(num > 0)
	{
		msg.WriteData(pos,&num,sizeof(num));
		return true;
	}
	else
	{
		return false;
	}
}

bool CSceneManager::GetShenJieMiJingRoomInfo(CNetMessage &msg)
{
	boost::mutex::scoped_lock lk(m_bpMutex);
	uint16 pos = msg.GetDataLen();
	uint16 num = 0;
	msg<<num;
	for(int i = 0;i < m_shenjiemijingSceneNum;i++)
	{
		CScene *pScene = NULL;
		m_sceneList.Find(SHENJIEMIJING_SCENE_ID_BEGIN+i,pScene);
		if(pScene != NULL)
		{
			num++;
			msg<<(uint16)(i+1)<<pScene->GetUserNum()<<SHENJIEMIJING_ROOM_LIMIT;
		}
	}
	if(num > 0)
	{
		msg.WriteData(pos,&num,sizeof(num));
		return true;
	}
	else
	{
		return false;
	}
}

void CSceneManager::SendFeiXianAward()
{
	for(int sid = FEI_XIAN_SID1;sid <= FEI_XIAN_SID5;sid++)
	{
		CScene *pScene = NULL;
		if(m_sceneList.Find(sid,pScene))
		{
			if(pScene != NULL)
				pScene->SendFeiXianAward();
		}
	}
}

void CSceneManager::TransportOutOfFeiXian()
{
	for(int sid = FEI_XIAN_SID1;sid <= FEI_XIAN_SID5;sid++)
	{
		CScene *pScene = NULL;
		if(m_sceneList.Find(sid,pScene))
		{
			if(pScene != NULL)
				pScene->Clear();
		}
	}
}

void CSceneManager::TransportOutOfKunLunShan()
{
	for(int i = 0;i < m_kunLunShanSceneNum;i++)
	{
		CScene *pScene = NULL;
		m_sceneList.Find(KUN_LUN_SHAN_SCENE_ID_BEGIN+i,pScene);
		if(pScene != NULL)
			pScene->Clear();
	}
	m_kunLunShanSceneNum = 0;
}

void CSceneManager::TransportOutOfTeamKunLunShan()
{
	for(int i = 0;i < m_kunLunShanTeamSceneNum;i++)
	{
		CScene *pScene = NULL;
		m_sceneList.Find(KUN_LUN_SHAN_TEAM_SCENE_ID_BEGIN+i,pScene);
		if(pScene != NULL)
			pScene->Clear();
	}
	m_kunLunShanTeamSceneNum = 0;
}

void CSceneManager::SendKunLunShanTime()
{
	boost::mutex::scoped_lock lk(m_bpMutex);
	for(int i = 0;i < m_kunLunShanSceneNum;i++)
	{
		CScene *pScene = NULL;
		m_sceneList.Find(KUN_LUN_SHAN_SCENE_ID_BEGIN+i,pScene);
		if(pScene != NULL)
		{
			pScene->SendKunLunShanTime();
		}
	}
}

void CSceneManager::SendKunLunShanTeamTime()
{
	boost::mutex::scoped_lock lk(m_bpMutex);
	for(int i = 0;i < m_kunLunShanTeamSceneNum;i++)
	{
		CScene *pScene = NULL;
		m_sceneList.Find(KUN_LUN_SHAN_TEAM_SCENE_ID_BEGIN+i,pScene);
		if(pScene != NULL)
		{
			pScene->SendKunLunShanTeamTime();
		}
	}
}

// 钓鱼房间
CScene *CSceneManager::GetFishingRoom()
{
	CScene *pScene = NULL;
	boost::mutex::scoped_lock lk(m_bpMutex);

	m_sceneList.Find(FISH_ID2,pScene);
	if(pScene == NULL)
		return NULL;

	pScene = new CScene(*pScene);
	pScene->SetId(m_curFuBenId++);
	pScene->SetSrcSceneId(FISH_ID2);
	pScene->m_usedFuBen = true;
	pScene->m_startTime = GetSysTime();
	pScene->SetGroupId(pScene->GetId());
	m_sceneList.Insert(pScene->GetId(),pScene);
	return pScene;
}

CScene *CSceneManager::GetFuBen(int sceneId)
{
	CScene *pScene = NULL;
	boost::mutex::scoped_lock lk(m_bpMutex);
	for (list<CScene*>::iterator i = m_fuBenScene.begin(); i != m_fuBenScene.end(); i++)
	{
		if (((*i)->GetMapId() == sceneId) && (!(*i)->IsFuBen()))
		{
			pScene = *i;
			pScene->m_usedFuBen = true;
			return pScene;
		}
	}

	m_sceneList.Find(sceneId, pScene);
	if (pScene == NULL)
		return NULL;

	pScene = new CScene(*pScene);
	pScene->SetId(m_curFuBenId++);
	pScene->SetMapId(sceneId);
	m_sceneList.Insert(pScene->GetId(), pScene);
	m_fuBenScene.push_back(pScene);
	pScene->m_usedFuBen = true;

	return pScene;
}

void CScene::Init()
{
}

bool CScene::GroupClear(int sceneId, uint16 x, uint16 y)
{
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	ClearVisibleMonster();
	ClearVisibleMonsterBoss();

	list<uint32> userList;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		userList = m_userList;
		for (list<SNpcInstance*>::iterator i = m_dynamicNpc.begin(); i != m_dynamicNpc.end(); i++)
		{
			delete *i;
		}
		m_dynamicNpc.clear();
	}
	for(list<uint32>::iterator i = userList.begin(); i != userList.end(); i++)
	{
		ShareUserPtr ptr = onlineUser.GetUserByRoleId(*i);
		CUser *pUser = ptr.get();
		if (pUser != NULL && pUser->GetFightId() == 0 && (pUser->GetTeam() == 0 || pUser->GetRoleId() == pUser->GetTeam()))	// 昆仑山战斗结束之后踢出
		{
			int sId = EXIT_FB_SCENE_ID, pX = EXIT_FB_SCENE_X, pY = EXIT_FB_SCENE_Y;
			pUser->GetEnterPos(sId,pX,pY);
			if(m_srcSceneId >= KUN_LUN_SHAN_SCENE_ID && m_srcSceneId < KUN_LUN_SHAN_SCENE_ID+30)
			{
				pUser->SetMeetEnemy(true);
				// 如果是骑坐骑的则恢复
				SetQiPetUp(pUser);
			}
			else if(m_srcSceneId >= FEI_XIAN_SID1 && m_srcSceneId <= FEI_XIAN_SID5)
			{
				pUser->SetMeetEnemy(true);
				// 如果是骑坐骑的则恢复
				SetQiPetUp(pUser);
			}
			else if(m_srcSceneId == KUN_LUN_SHAN_TEAM_SCENE_ID)
			{
				pUser->SetMeetEnemy(true);
				// 如果是骑坐骑的则恢复
				SetQiPetUp(pUser);
			}
			TransportUser(pUser, sId, pX, pY, 0);
		}
	}

	if(m_usedFuBen)
	{
		m_usedFuBen = false;
		return false;
	}
	else
	{
		return true;
	}
}

void CScene::GroupSetState(int state)
{
	CSceneManager &scene = SingletonSceneManager::instance();

	CScene *pScene = NULL;
	list<int> sceneList;
	scene.GetGroupScene(m_groupId, sceneList);
	for (list<int>::iterator i = sceneList.begin(); i != sceneList.end(); i++)
	{
		pScene = scene.FindScene(*i);
		if (pScene != NULL)
		{
			//cout<<pScene->GetId()<<":"<<state<<endl;
			pScene->m_state = state;
		}
	}
}

bool CScene::Clear()
{
	CSceneManager &scene = SingletonSceneManager::instance();

	CScene *pScene = NULL;
	list<int> sceneList;
	if(m_groupId > 0)
		scene.GetGroupScene(m_groupId, sceneList);
	else
		sceneList.push_back(m_srcSceneId);

	bool needDel = false;
	for(list<int>::iterator i = sceneList.begin(); i != sceneList.end(); i++)
	{
		pScene = scene.FindScene(*i);
		if(pScene != NULL)
			needDel = pScene->GroupClear(EXIT_FB_SCENE_ID,EXIT_FB_SCENE_X,EXIT_FB_SCENE_Y);
	}
	return needDel;
}

void CScene::SendFeiXianAward()
{
	/*if(m_srcSceneId < FEI_XIAN_SID1 || m_srcSceneId > FEI_XIAN_SID5)
		return;
	list<uint32> userList;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		userList = m_userList;
	}

	int floor = m_srcSceneId - FEI_XIAN_SID1 + 1;
	vector<SAwardData> awards;
	sAwardManager.GetRankAward(EMRA_FENG_SHEN_ZHAN_CHANG, floor, awards);
	for(list<uint32>::iterator i = userList.begin(); i != userList.end(); i++)
	{
		stringstream msg;
		msg << LANGUAGE_TRANSFORM_2805 << floor << LANGUAGE_TRANSFORM_2806;
		SendSystemAwardMail(*i, msg.str().c_str(), awards);
	}*/
}

void CScene::SendKunLunShanTime()
{
	list<uint32> userList;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		userList = m_userList;
	}
	
	uint16 flushSecond = 0xffff;
	//int hour = GetHour();
	int minute = GetMinute();
	int second = GetSysTime()%60;
	if(CSceneManager::IsInActivityTime(SOT_Kunlunshan))	// 5分钟刷新
		flushSecond = (4 - minute%5)*60 + (60 - second);
	
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	for(list<uint32>::iterator i = userList.begin(); i != userList.end(); i++)
	{
		ShareUserPtr ptr = onlineUser.GetUserByRoleId(*i);
		CUser *pUser = ptr.get();
		if(pUser != NULL)
			KunLunShan_UpdateRoleMsg(pUser,6,flushSecond);
	}
}

void CScene::SendKunLunShanTeamTime()
{
	list<uint32> userList;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		userList = m_userList;
	}
	
	uint16 flushSecond = 0xffff;
	int minute = GetMinute();
	int second = GetSysTime()%60;
	if(InFuncionLevelTime(SOT_KuaFuLunDao))
		flushSecond = (4 - minute%5)*60 + (60 - second);
	
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	for(list<uint32>::iterator i = userList.begin(); i != userList.end(); i++)
	{
		ShareUserPtr ptr = onlineUser.GetUserByRoleId(*i);
		CUser *pUser = ptr.get();
		if(pUser != NULL)
			KunLunShanTeam_UpdateRoleMsg(pUser,6,flushSecond);
	}
}

int CScene::GetState()
{
	return m_state;
}
void CScene::SetState(int state)
{
	GroupSetState(state);
}

bool CSceneManager::FindMapSceneList(int id, CScene *pScene, int mapId, list<CScene*> *pSceneList)
{
	if (pScene->GetMapId() == mapId)
	{
		pSceneList->push_back(pScene);
	}
	return true;
}

bool CSceneManager::FindTongTianTaList(int id, CScene *pScene, int srcId_begin,int srcId_end, list<CScene*> *pSceneList)
{
	int srcId = pScene->GetSrcSceneId();
	if(pScene->GetId() != srcId && srcId >= srcId_begin && srcId <= srcId_end && pScene->GetUserNum() == 0)
	{
		pSceneList->push_back(pScene);
	}
	return true;
}

bool CSceneManager::FindTongTianTaUnUsedList(int id, CScene *pScene, int srcId_begin,int srcId_end, list<CScene*> *pSceneList)
{
	int srcId = pScene->GetSrcSceneId();
	if(pScene->GetId() != srcId && srcId >= srcId_begin && srcId <= srcId_end && !pScene->m_usedFuBen)
	{
		pSceneList->push_back(pScene);
	}
	return true;
}

// 查找统计超时副本
bool CSceneManager::FindTimeoutFuBenList(int id, CScene *pScene,int targetSrcId,list<CScene*> *pSceneList)
{
	int srcId = pScene->GetSrcSceneId();
	if (pScene->GetId() == srcId)
		return true;
	if (srcId != targetSrcId)
		return true;	
	if (pScene->GetGroupId() != id) // 副本内，如果不是第一个副本地图，则不作校验，防止重复删除副本和前没有有人后面没有人而清除副本
		return true;
	if (pScene->GetUserNum() != 0)
		return true;
	//if (!IsFuBenEmpty(pScene)) // 统计同一个group里面的地图是否都为空。 这个不能用，因为会导致死锁。真正删除场景的时候在判断
	//	return true;
	time_t curTime = GetSysTime();
	time_t emptyTime = pScene->GetEmptyTime();
	if (emptyTime == 0)
	{
		pScene->SetEmptyTime(curTime);
		return true;
	}
	if ((curTime - emptyTime) < CScene::EMPTY_FUBEN_TIMEOUT)
	{
		return true;
	}
	pSceneList->push_back(pScene);
	return true;
}

// 查找统计超时副本
bool CSceneManager::FindHuoDongSceneList(int id, CScene *pScene,int targetSrcId,list<CScene*> *pSceneList)
{
	int srcId = pScene->GetSrcSceneId();
	if (pScene->GetId() == srcId)
		return true;
	if (srcId != targetSrcId)
		return true;
	if (pScene->GetUserNum() != 0)
		return true;
	pSceneList->push_back(pScene);
	return true;
}

char *CScene::GetMatchPaiMing()
{
	if(!m_isPaiMing)
		return NULL;

	static char paiming[256];
	int num = m_jifenUsers.size();
	num = min(num, 10);
	paiming[0] = 0;

	for(int i = 0; i < num; i++)
	{
		if(i != 0)
			strcat(paiming, "|");
		strcat(paiming, m_jifenUsers[i].name.c_str());
	}
	if(paiming[0] == 0)
		return NULL;
	return paiming;
}

time_t flush_monster_time[5] = {0};
time_t start_fight[20] = {0};
const uint8 time_delay[5] = {5,5,10,10,20};
uint8 settime_flag[5] = {0};

bool CSceneManager::UpdateMonsterMove(int id, CScene *pScene)
{
	if(pScene == NULL)
		return false;
	pScene->MonsterMove();
	return true;
}

void CSceneManager::UpdateMonster()
{
	m_sceneList.ForEach(boost::bind(&CSceneManager::UpdateMonsterMove,this,_1,_2));
}

// 强化副本
void CSceneManager::RiChangQiangHuaFuBenClearScene()
{
	NormalFuBenClearScene(COPY_ID_QIANG_HUA);
}

// 神将副本
void CSceneManager::RiChangChongWuFuBenClearScene()
{
	NormalFuBenClearScene(COPY_ID_CHONG_WU_1);
	NormalFuBenClearScene(COPY_ID_CHONG_WU_2);
	NormalFuBenClearScene(COPY_ID_CHONG_WU_3);
	NormalFuBenClearScene(COPY_ID_CHONG_WU_4);
}

// 金币副本
void CSceneManager::RiChangJinBiFuBenClearScene()
{
	NormalFuBenClearScene(COPY_ID_MONEY);
}

// 道具副本
void CSceneManager::RiChangShengJieFuBenClearScene()
{
	NormalFuBenClearScene(COPY_ID_SHENG_JIE);
}

// 潜能副本
void CSceneManager::RiChangQianNengFuBenClearScene()
{
	NormalFuBenClearScene(COPY_ID_QIAN_NENG);
}

void CSceneManager::KunLunShanClearScene()
{
	for(int sid=KUN_LUN_SHAN_SCENE_ID; sid < KUN_LUN_SHAN_SCENE_ID+30; sid++)
		HuoDongSceneClear(sid);
}

void CSceneManager::KunLunShanTeamClearScene()
{
	HuoDongSceneClear(KUN_LUN_SHAN_TEAM_SCENE_ID);
	m_kunLunShanTeamSceneNum = 0;
}

void CSceneManager::FishClearScene()
{
	HuoDongSceneClear(FISH_ID2);
	HuoDongSceneClear(FISH_ID2+1);
}

void CSceneManager::HuoDongSceneClear(int targetSrcId)
{
	list<CScene*> sceneList;
	{
		boost::mutex::scoped_lock lk(m_bpMutex);
		m_sceneList.ForEach(boost::bind(&CSceneManager::FindHuoDongSceneList,this, _1, _2,targetSrcId, &sceneList));
	}
	for(list<CScene*>::iterator i = sceneList.begin();i != sceneList.end();i++)
	{
		if(((*i) != NULL))
		{
			if (!IsFuBenEmpty(*i))
			{
				(*i)->SetEmptyTime(0); // 重置副本为空的时间
				continue;
			}
			(*i)->Clear();
			boost::mutex::scoped_lock lk(m_bpMutex);
			m_sceneList.Erase((*i)->GetId());
			delete (*i);
		}
	}
	sceneList.clear();
}

// 副本清除通用接口 只处理副本的第一个场景（清第一个场景时会校验后面的是否生效，统一清理）
void CSceneManager::NormalFuBenClearScene(int targetSrcId)
{
	list<CScene*> sceneList;
	{
		boost::mutex::scoped_lock lk(m_bpMutex);
		m_sceneList.ForEach(boost::bind(&CSceneManager::FindTimeoutFuBenList,this, _1, _2,targetSrcId, &sceneList));
	}
	for(list<CScene*>::iterator i = sceneList.begin();i != sceneList.end();i++)
	{
		if(((*i) != NULL))
		{
			if (!IsFuBenEmpty(*i))
			{
				(*i)->SetEmptyTime(0); // 重置副本为空的时间
				continue;
			}
			if((*i)->Clear())
			{
				boost::mutex::scoped_lock lk(m_bpMutex);
				m_sceneList.Erase((*i)->GetId());
				delete (*i);
			}
		}
	}
	sceneList.clear();
}

void CSceneManager::BangZhanTimer()
{
	static bool readyStart = true;
	static bool fightStart = true;
	static bool fightEnd = true;
	static bool flushBox = true;
	static bool endBox = true;

	const int timeSpace = 10;	// 经验产出时间间隔
	int hour = GetHour();
	int minute = GetMinute();
	int curTime = GetSysTime();	
	char buf[512];

	uint16 notifyTm;
	uint16 startTm;
	uint16 endTm;

	if (!sSystemOpenCfgMananger.OpenWeekDay(SOT_BangPaiZhan))
		return;
	if (!sSystemOpenCfgMananger.GetFuncLvTime(SOT_BangPaiZhan, notifyTm, startTm, endTm))
		return;

	if (hour == 0)
	{
		readyStart = true;
		fightStart = true;
		fightEnd = true;
		flushBox = true;
		endBox = true;
	}
	static vector<CScene *> readyScene;
	int time = hour * 100 + minute;
	int readyTm = startTm - 5;
	int boxStart = endTm + 1;
	int boxEnd = endTm + 5;
	if (startTm % 100 < 1)
		readyTm -= 40;
	if (endTm % 100 >= 55)
		boxStart = endTm + 40;
	if (endTm % 100 >= 50)
		boxEnd = endTm + 40;

	if (time >= startTm && time < readyTm)	// 准备阶段
	{
		const int expR = 150;
		static int lastTime = 0;
		if (readyStart)
		{
			readyScene.clear();
			readyStart = false;
			lastTime = curTime;
#ifndef KUA_FU
			SetBZ_WIN_BANG_ID(0);
#endif

			vector<uint32> idList;
			SingletonCBangPaiManager::instance().GetBangZhanBangPaiList(idList);
			for (uint16 j = 0; j < idList.size(); j++)
			{
				CScene *p = GetBangPaiScene(BP_FIGHT_READY_SID, idList[j]);
				if (p != NULL)
				{
					readyScene.push_back(p);
				}
			}
			//SingletonCBangPaiManager::instance().ShowBangZhanIcon(true);
		}

		if (!readyScene.empty())
		{
			if (curTime - lastTime >= timeSpace)
			{
				lastTime = curTime;
				for (int i = 0; i < (int)readyScene.size(); i++)
				{
					if (readyScene[i] != NULL)
						readyScene[i]->BangZhanSceneAddExp(expR);
				}
			}
		}
	}
	else if (time >= startTm && time < endTm)	// 帮战开始
	{
		const int expR = 30;
		static int lastTime = 0;
		if (fightStart)
		{
			fightStart = false;
			lastTime = curTime;
			SysInfoToAllUser(LANGUAGE_TRANSFORM_2809);
			SingletonCBangPaiManager::instance().ClearBangPaiFightJiFen();
			CSceneManager &scene = SingletonSceneManager::instance();
			CScene *pFightScene = scene.FindScene(BP_FIGHT_SID);
			if (pFightScene == NULL)
				return;
			pFightScene->ResetTowers();
		}

		if (curTime - lastTime >= timeSpace)
		{
			lastTime = curTime;
			CScene *pBangZhan = FindScene(BP_FIGHT_SID);
			if (pBangZhan != NULL)
				pBangZhan->BangZhanSceneAddExp(expR);
		}
	}
	else if (time == endTm && fightEnd)	// 帮战结束
	{
		fightEnd = false;
#ifndef KUA_FU
		SetBZ_WIN_BANG_ID(SingletonCBangPaiManager::instance().GetBangZhanFirstBang());
#endif
		CScene *pBangZhan = FindScene(BP_FIGHT_SID);
		if (pBangZhan != NULL)
			pBangZhan->ExitBangZhan();
		SingletonCBangPaiManager::instance().SendBangZhanAward();
		CNetMessage boxMsg;
		boxMsg.SetType(PRO_BANG_ZHAN);
		boxMsg << (uint8)7 << (uint16)60;
		pBangZhan->BroadcastMsg(boxMsg);
	}
	else if (time >= boxStart && time < boxEnd)	// 帮战结束出宝箱
	{
		if ((time == boxStart || time == boxStart + 2) && flushBox)
		{
			flushBox = false;
			CScene *pBangZhan = FindScene(BP_FIGHT_SID);
			if (pBangZhan != NULL)
				pBangZhan->ExitBangZhan();
			pBangZhan->AddBangZhanBox();

			int bangId = 0;
#ifndef KUA_FU
			bangId = GetBZ_WIN_BANG_ID();
#endif
			if (bangId > 0)
			{
				snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_2810, GetBangName(bangId));
				SysInfoToAllUser(buf);
			}
			if (time == boxStart)
			{
				CNetMessage boxMsg;
				boxMsg.SetType(PRO_BANG_ZHAN);
				boxMsg << (uint8)7 << (uint16)120;
				pBangZhan->BroadcastMsg(boxMsg);
			}
		}
		else if (time == boxStart + 1)
		{
			flushBox = true;
		}
	}
	else if (time == boxEnd)	// 宝箱结束
	{
		if (endBox)
		{
			endBox = false;
			//SingletonCBangPaiManager::instance().ShowBangZhanIcon(false);
#ifndef KUA_FU
			SetBZ_WIN_BANG_ID(0);
#endif
			CScene *pBangZhan = FindScene(BP_FIGHT_SID);
			if (pBangZhan != NULL)
			{
				pBangZhan->ExitBangZhan();
				pBangZhan->ClearBangZhanBox();
			}
		}
	}
}

#ifdef KUA_FU
void CSceneManager::KuaFuBangZhanTimer()
{
	static bool readyStart = true;
	static bool fightStart = true;
	static bool fightEnd = true;
	static bool flushBox = true;
	static bool endBox = true;

	const int timeSpace = 10;	// 经验产出时间间隔
	int wday = GetWeekDay();
	int hour = GetHour();
	int minute = GetMinute();
	int curTime = GetSysTime();	
	char buf[512];

	if(wday == 2 || wday == 5)
	{
		static vector<CScene *> readyScene;
		static vector<CScene *> fightScene;
		int time = hour*100 + minute;
		if(time >= BP_FIGHT_READY_START && time < BP_FIGHT_READY_END)	// 准备阶段
		{
			const int expR = 150;
			static int lastTime = 0;
			if(readyStart)
			{
				readyScene.clear();
				readyStart = false;
				lastTime = curTime;
				ClearBZ_WIN_BANG_ID();

				if(readyScene.empty())
				{
					vector<uint32> idList;
					SingletonCBangPaiManager::instance().GetBangZhanBangPaiList(idList);
					for(uint16 j=0;j < idList.size();j++)
					{
						CScene *p = GetBangPaiScene(KUAFU_BZ_READY_SID,idList[j]);
						if(p != NULL)
							readyScene.push_back(p);
					}
				}
				SingletonCBangPaiManager::instance().ShowBangZhanIcon(true);
			}
			
			if(!readyScene.empty())
			{
				if(curTime - lastTime >= timeSpace)
				{
					lastTime = curTime;
					for(int i=0;i < (int)readyScene.size();i++)
					{
						if(readyScene[i] != NULL)
							readyScene[i]->BangZhanSceneAddExp(expR);
					}
				}
			}
		}
		else if(time >= BP_FIGHT_START && time < BP_FIGHT_END)	// 帮战开始
		{
			const int expR = 150;
			static int lastTime = 0;
			if(fightStart)
			{
				fightStart = false;
				lastTime = curTime;
				SysInfoToAllUser(LANGUAGE_TRANSFORM_2809);

//				vector<uint32> idList;
//				SingletonCBangPaiManager::instance().GetBangZhanBangPaiList(idList);
				if(fightScene.empty())
				{
					for(int j=0;j < CBangPaiManager::MAX_KFBZ_GROUP;j++)
					{
						CScene *p = GetKuaFuBZScene(j+1);
						if(p != NULL)
							fightScene.push_back(p);
					}
				}
			}

			if(!fightScene.empty())
			{
				if(curTime - lastTime >= timeSpace)
				{
					lastTime = curTime;
					for(int i=0;i < (int)fightScene.size();i++)
					{
						if(fightScene[i] != NULL)
							fightScene[i]->BangZhanSceneAddExp(expR);
					}
				}
			}
		}
		else if(time == BP_FIGHT_END && fightEnd)	// 帮战结束
		{
			fightEnd = false;
			vector<int> bangpaiList = SingletonCBangPaiManager::instance().GetBangZhanFirstBangList();
			for(uint16 i=0;i < bangpaiList.size();i++)
			{
				int firstBangId = bangpaiList[i];
				if(firstBangId > 0)
					SetBZ_WIN_BANG_ID(i+1,firstBangId);
			}
			for(int i=0;i < (int)fightScene.size();i++)
			{
				if(fightScene[i] != NULL)
					fightScene[i]->ExitBangZhan();
			}
			SingletonCBangPaiManager::instance().SendBangZhanAward();
		}
		else if(time >= BP_FIGHT_BOX_START && time < BP_FIGHT_BOX_END)	// 帮战结束出宝箱
		{
			if((time == BP_FIGHT_BOX_START || time == BP_FIGHT_BOX_START+2) && flushBox)
			{
				flushBox = false;

				for(int i=0;i < (int)fightScene.size();i++)
				{
					if(fightScene[i] != NULL)
					{
						fightScene[i]->ExitBangZhan();
						fightScene[i]->AddBangZhanBox();
					}
				}

				for(int i=0;i < CBangPaiManager::MAX_KFBZ_GROUP;i++)
				{
					int bangId = GetBZ_WIN_BANG_ID(i+1);
					if(bangId > 0)
					{
						snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_2810,GetBangName(bangId));
						SysInfoToAllUser(buf);
					}
				}
			}
			else if(time == BP_FIGHT_BOX_START+1)
			{
				flushBox = true;
			}
		}
		else if(time == BP_FIGHT_BOX_END)	// 宝箱结束
		{
			if(endBox)
			{
				endBox = false;
				SingletonCBangPaiManager::instance().ShowBangZhanIcon(false);
				ClearBZ_WIN_BANG_ID();

				for(int i=0;i < (int)fightScene.size();i++)
				{
					if(fightScene[i] != NULL)
					{
						fightScene[i]->ExitBangZhan();
						fightScene[i]->ClearBangZhanBox();
					}
				}
			}
		}
	}

	if(hour == 0)
	{
		readyStart = true;
		fightStart = true;
		fightEnd = true;
		flushBox = true;
		endBox = true;
	}
}
#endif

void CSceneManager::Timer()
{
#ifndef KUA_FU
	static time_t clearFuBen = GetSysTime();
#endif
	static bool clearHuoDong = false;
	int hour = GetHour();
#ifndef KUA_FU
	if(GetSysTime() - clearFuBen > 60*10)	// 10min
	{
		clearFuBen = GetSysTime();
		RiChangQiangHuaFuBenClearScene();
		RiChangChongWuFuBenClearScene();
		RiChangJinBiFuBenClearScene();
		RiChangShengJieFuBenClearScene();
		RiChangQianNengFuBenClearScene();
	}

	if(GetSysTime() - m_matchRunTime > RUN_MATCH_SPACE)
	{
		m_matchRunTime = GetSysTime();
		{
			CScene *pScene = FindScene(LEI_TAI_ID2);
			if (pScene != NULL)
				pScene->Match();
		}
	}
#endif
	
	if(hour == 4 && !clearHuoDong)
	{
#ifndef KUA_FU
		clearHuoDong = true;
		KunLunShanClearScene();
		FishClearScene();
#else
		KunLunShanTeamClearScene();
#endif
	}
	else if(hour != 4 && clearHuoDong)
	{
		clearHuoDong = false;
	}

#ifndef KUA_FU
	BangZhanTimer();
#else
//	KuaFuBangZhanTimer();
#endif
}

bool CSceneManager::IsBeforeActivityTime(int type)
{
	if (!sSystemOpenCfgMananger.CanShow(type))
		return false;
	uint16 curTime = GetHour() * 100 + GetMinute();
	int second = GetSysTime() % 60;
	uint16 notifyTm;
	uint16 startTm;
	uint16 endTm;
	if (!sSystemOpenCfgMananger.GetFuncLvTime(type, notifyTm, startTm, endTm))
		return false;

	if (curTime == notifyTm && second <= 11)
		return true;
	return false;
}

bool CSceneManager::IsAfterActivityTime(int type)
{
	uint16 hour = GetHour();
	uint16 min = GetMinute();
	uint16 curTime = hour * 100 + min;
	uint16 notifyTm;
	uint16 startTm;
	uint16 endTm;

	if (!sSystemOpenCfgMananger.CanShow(type))
		return false;
	if (!sSystemOpenCfgMananger.GetFuncLvTime(type, notifyTm, startTm, endTm))
		return false;
	switch (type)
	{
	case SOT_Fish:// 钓鱼
	case SOT_Bangpailingmo:// 挑战灵魔
	case SOT_Kunlunshan://诸天幻境
	case SOT_FeiXian://封神战场
	case SOT_Baihua://百花仙子
	case SOT_BangPaiLueDuo://帮派掠夺
	case SOT_Nianshou: // 年兽
	case SOT_Shuangbei: // 双倍
	case SOT_LeiTaiSai: // 擂台赛
	case SOT_BangPaiZhan: // 帮战
		return hour == endTm / 100 && curTime >= endTm;

	case SOT_Liujieshizhe://六界使者
		return hour == 0;

	{
		int time = GetSysDoubleExpEndTime();
		return hour == time / 100 && curTime >= time;
	}

#ifdef KUA_FU
	case SOT_ShenJieMiJing: // 神界秘境
		return hour == 12 || (hour == 11 && SingletonCShenJieMiJingManager::instance().GetCurBossState() > STATE_NOW_FIGFHT);
#else
	case SOT_ShenJieMiJing: // 神界秘境
		return hour == 12;
#endif // KUA_FU

	default:
		return hour == endTm / 100 && curTime >= endTm;

	}
	return false;
}

bool CSceneManager::IsNotifyActivityTime(int type)
{
	uint16 hour = GetHour();
	uint16 min = GetMinute();
	uint16 curTime = hour * 100 + min;
	uint16 notifyTm;
	uint16 startTm;
	uint16 endTm;

	if (!sSystemOpenCfgMananger.CanShow(type))
		return false;
	if (!sSystemOpenCfgMananger.GetFuncLvTime(type, notifyTm, startTm, endTm))
		return false;

	switch (type)
	{
	case SOT_Fish:// 钓鱼
	case SOT_Bangpailingmo:// 挑战灵魔
	case SOT_Kunlunshan://诸天幻境
	case SOT_FeiXian://封神战场
	case SOT_Baihua://百花仙子
	case SOT_Husong://护送任务
	case SOT_BangPaiLueDuo://帮派掠夺
	case SOT_Nianshou: // 年兽
	case SOT_Shuangbei: // 双倍
	case SOT_LeiTaiSai: // 擂台赛
	case SOT_BangPaiZhan: // 帮战
		return curTime >= notifyTm && curTime < startTm;

	case SOT_Liujieshizhe://六界使者
		return (hour == 9 && min > 40);

	case SOT_ShenJieMiJing: // 神界秘境
		return (curTime >= 1100 && curTime < 1130);
	}
	return false;
}

bool CSceneManager::IsInActivityTime(int type)
{
	uint16 hour = GetHour();
	uint16 min = GetMinute();
	uint16 curTime = hour * 100 + min;
	uint16 notifyTm;
	uint16 startTm;
	uint16 endTm;

	if (!sSystemOpenCfgMananger.CanShow(type))
		return false;
	if (!sSystemOpenCfgMananger.GetFuncLvTime(type, notifyTm, startTm, endTm))
		return false;

	switch (type)
	{
	case SOT_Bangpailingmo:// 挑战灵魔
	case SOT_Kunlunshan://诸天幻境
	case SOT_FeiXian://封神战场
	case SOT_Baihua://百花仙子
	case SOT_Husong://护送任务
	case SOT_BangPaiLueDuo://帮派掠夺
	case SOT_Fish:// 钓鱼
	case SOT_Nianshou: // 年兽
	case SOT_Shuangbei: // 双倍
	case SOT_LeiTaiSai: // 擂台赛
	case SOT_BangPaiZhan: // 帮战
		return curTime >= startTm && curTime < endTm;

	case SOT_Liujieshizhe://六界使者
		return (hour >= 10);

	case SOT_ShenJieMiJing: // 神界秘境
		return (hour == 11 && min >= 30 && min <= 59);
		
	case SOT_Spirit: // 体力
		return hour > 11;
	}
	return false;
}

uint32 CSceneManager::GetActivityFinishTime(int type)
{
	uint16 hour = GetHour();
	uint16 min = GetMinute();
	uint32 sec = hour * 60 * 60 + min * 60 + GetSysSecond();
	uint32 finishSec = 0;
	uint16 notifyTm;
	uint16 startTm;
	uint16 endTm;

	if (!sSystemOpenCfgMananger.CanShow(type))
		return false;
	if (!sSystemOpenCfgMananger.GetFuncLvTime(type, notifyTm, startTm, endTm))
		return false;
	bool inSwitch = true;
	switch (type)
	{
	case SOT_Bangpailingmo:// 挑战灵魔
	case SOT_Kunlunshan://诸天幻境
	case SOT_FeiXian://封神战场
	case SOT_Baihua://百花仙子
	case SOT_Husong://护送任务
	case SOT_BangPaiLueDuo://帮派掠夺
	case SOT_Fish://钓鱼
	case SOT_Nianshou: // 年兽
	case SOT_Shuangbei: // 双倍
	case SOT_LeiTaiSai: // 擂台赛
	case SOT_BangPaiZhan: // 帮战
		finishSec = endTm / 100 * 60 * 60 + endTm % 100 * 60;
		break;

	case SOT_Liujieshizhe://六界使者
		if (hour < 13 || (hour == 13 && min < 30))
			finishSec = 13 * 60 * 60 + 30 * 60;
		else if (hour < 15 || (hour == 15 && min < 30))
			finishSec = 15 * 60 * 60 + 30 * 60;
		else if (hour < 17 || (hour == 17 && min < 30))
			finishSec = 17 * 60 * 60 + 30 * 60;
		else
			finishSec = 0;
		break;

	case SOT_ShenJieMiJing: // 神界秘境
			finishSec = 12 * 60 * 60;
		break;

	default:
		inSwitch = false;
		break;
	}

	if(!inSwitch)
	{
		CSystemOpenCfgMananger &openSys = SingletonCSystemOpenCfgMgr::instance();
		if(!openSys.OpenWeekDay(type))
			return 0;
		uint16 readyTime = 0;
		uint16 startTime = 0;
		uint16 endTime = 0;
		if(!openSys.GetFuncLvTime(type,readyTime,startTime,endTime))
			return 0;
		if(readyTime == 0 && startTime == 0 && endTime == 0)
			return 0;
		finishSec = endTime / 100 * 60 * 60 + endTime % 100 * 60;
	}
	return finishSec > sec ? finishSec - sec : 0;
}

void CSceneManager::NotiyActivityInfo(CUser* pUser, int type)
{
	if (!sSystemOpenCfgMananger.CanShow(type))
		return;
	if (sSystemOpenCfgMananger.CheckSystemOpen(pUser, type))
	{
		switch (type)
		{
		case SOT_LeiTaiSai:
			if (!LeiTaiLvCheck(pUser->GetLevel()))
				return;
			break;

		case SOT_BangPaiZhan:
			if(!SingletonCBangPaiManager::instance().IsInBangPaiFightList(pUser->GetBangPai()))
				return;
			break;
			
		case SOT_Spirit:
			if (!pUser->CheckGetFreeSpiritState())
				return;
			break;
		}
		if (CSceneManager::IsNotifyActivityTime(type))
		{
			SendHuoDongFlag_Single(pUser, type, 3);
		}
		else if (CSceneManager::IsInActivityTime(type))
		{
			SendHuoDongFlag_Single(pUser, type, 1, CSceneManager::GetActivityFinishTime(type));
		}
	}
}

int CSceneManager::GetSOTTypeByOp(int type)
{
	int sotType = 0;
	switch (type)
	{
	case 1:// 白花
		sotType = SOT_Baihua;
		break;

	case 4:// 昆仑山
		sotType = SOT_Kunlunshan;
		break;

	case 9:// 护送任务
		sotType = SOT_Husong;
		break;

	case 13:// 飞仙
		sotType = SOT_FeiXian;
		break;

	case 14:// 帮派掠夺
		sotType = SOT_Bangpai;
		break;

	case 27:// 灵魔
		sotType = SOT_Bangpailingmo;
		break;

	case 28:// 钓鱼
		sotType = SOT_Fish;
		break;

	case 29:// 六界使者
		sotType = SOT_Liujieshizhe;
		break;

	case 30:// 年兽
		sotType = SOT_Nianshou;
		break;

	case 51: // 双倍
		sotType = SOT_Shuangbei;
		break;

	case 52: // 擂台赛
		sotType = SOT_LeiTaiSai;
		break;
	}
	return sotType;
}

bool CSceneManager::IsInActivifyScene(int type, uint16 sceneId)
{
	huodongScenes::iterator it = m_huodongMaps.find(type);
	if (it == m_huodongMaps.end())
		return false;

	return it->second.find(sceneId) != it->second.end();
}

void CScene::FindMatchUser(vector<uint32> &userList)
{
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for (list<uint32>::iterator i = m_userList.begin(); i != m_userList.end(); i++)
	{
		ShareUserPtr ptr = onlineUser.GetUserByRoleId(*i);
		CUser *pUser = ptr.get();
		if (pUser != NULL)
		{
			if (pUser->GetFightId() != 0 || pUser->GetKuaFuState() != EKFS_IN_LOCAL)
				continue;
			if (pUser->GetTeam() == 0)
			{
				userList.push_back(pUser->GetRoleId());
			}
			else if (pUser->GetTeam() == pUser->GetRoleId())
			{
				if(GetTeamMemNum(pUser->GetTeam()) < 2)
				{
					i++;
					pUser->NoLockBackLastScene();
					if(i == m_userList.end())
						break;
				}
				else
					userList.push_back(pUser->GetRoleId());
			}
		}
	}
}

void CScene::BangPaiTiaoZhanFindMatchUser(vector<uint32> &userList)
{
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for (list<uint32>::iterator i = m_userList.begin(); i != m_userList.end(); i++)
	{
		ShareUserPtr ptr = onlineUser.GetUserByRoleId(*i);
		CUser *pUser = ptr.get();
		if (pUser != NULL)
		{
			if (pUser->GetFightId() != 0 || pUser->GetKuaFuState() != EKFS_IN_LOCAL) // 战斗的不算
				continue;
//			cout << LANGUAGE_TRANSFORM_2811 << pUser->GetName() << ",bang:" << pUser->GetBangPai() << endl;
			if (pUser->GetTeam() == 0) // 没有队伍的不算
			{
				i++;
//				cout << LANGUAGE_TRANSFORM_2812 << pUser->GetName() << endl;
				pUser->NoLockBackLastScene();
				if(i == m_userList.end())
					break;
			}
			else if (pUser->GetTeam() == pUser->GetRoleId()) // 只计算队长
			{
				if(GetTeamMemNum(pUser->GetTeam()) < 2) // 对内没有其他人了
				{
					i++;
//					cout << LANGUAGE_TRANSFORM_2813 << pUser->GetName() << endl;
					pUser->NoLockBackLastScene();
					if(i == m_userList.end())
						break;
				}
				else
				{
					int roleId1 = pUser->GetRoleId();
					int roleId2 = 0;
					int roleId3 = 0;
					
					vector<ShareUserPtr> pMember;
					GetTeamMemberList(pUser,pMember);
					int roleNum = pMember.size();
					if(roleNum < 2)
						break;
					for(int k=0;k < roleNum;k++)
					{
						if(pMember[k].get() != NULL)
						{
							if(pMember[k]->GetRoleId() != pUser->GetRoleId())
							{
								if(roleId2 == 0)
									roleId2 = pMember[k]->GetRoleId();
								else if(roleId3 == 0)
								{
									roleId3 = pMember[k]->GetRoleId();
									break;
								}
							}
						}
					}
					if (!BangPaiTiaoZhanSaiBangEnterEnable(roleId1,roleId2,roleId3)) // 不合报名结构的队伍要踢出场景
					{
						i++;
//						cout << LANGUAGE_TRANSFORM_2814 << pUser->GetName() << endl;
						pUser->NoLockBackLastScene();
						if(i == m_userList.end())
							break;
					}
					else
					{
//						cout << LANGUAGE_TRANSFORM_2815 << pUser->GetName() << endl;
						userList.push_back(pUser->GetRoleId());
					}
				}
			}
		}
	}
}

struct SSortUserJifen
{
	bool operator()(const SJiFenUser &m1, const SJiFenUser &m2)
	{
		return m1.jifen > m2.jifen;
	}
};

struct SSortTeamJifen
{
	bool operator()(const KuaFu_TeamInfo &m1, const KuaFu_TeamInfo &m2)
	{
		return m1.jifen > m2.jifen;
	}
};

int CScene::GetUserJiFen(uint32 roleId)
{
	int num = m_jifenUsers.size();
	for (int i = 0; i < num; i++)
	{
		if (m_jifenUsers[i].roleId == roleId)
		{
			return m_jifenUsers[i].jifen;
		}
	}
	return 0;
}

void CScene::ClearUserJiFen(uint32 roleId)
{
	int num = m_jifenUsers.size();
	for (int i = 0; i < num; i++)
	{
		if (m_jifenUsers[i].roleId == roleId)
		{
			m_jifenUsers[i].jifen = 0;
		}
	}
}

void CScene::LeiTaiJiFenCalc()
{
	int num = m_jifenUsers.size();
	SSortUserJifen sortJifen;
	std::sort(m_jifenUsers.begin(), m_jifenUsers.end(), sortJifen);
	char formatStr[256];
	int lv = GetLeiTaiLv();
	int aid = GetLeiTaiAId();

	for (int i = 0; i < num; i++)
	{
		uint32 addJifen = m_jifenUsers[i].jifen;
		SAwardData award;
		award.type = HDAT_LEITAI_JIFEN;
		award.num = addJifen;
		m_jifenUsers[i].jifen = 0;
		snprintf(formatStr, sizeof(formatStr), LANGUAGE_ZQX_0049, lv, i + 1);
		sAwardManager.SendRankAwardMailExHb(aid, m_jifenUsers[i].roleId, i + 1, formatStr, award);
	}
	m_jifenUsers.clear();
}

void CScene::SetUserJiFen(uint32 roleId, char *name, short jifen)
{
	int num = m_jifenUsers.size();
	for (int i = 0; i < num; i++)
	{
		if (m_jifenUsers[i].roleId == roleId)
		{
			m_jifenUsers[i].jifen += jifen;
			return;
		}
	}
	SJiFenUser userJifen;
	userJifen.roleId = roleId;
	userJifen.name = name;
	userJifen.jifen = jifen;
	m_jifenUsers.push_back(userJifen);
	/*SSortUserJifen sortJifen;
	std::sort(m_jifenUsers.begin(), m_jifenUsers.end(), sortJifen);*/
}

void CScene::Match()
{
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	int wday = GetWeekDay();
	if (CSceneManager::IsInActivityTime(SOT_LeiTaiSai) && m_matchBegin == 0)
	{
		m_jifenUsers.clear();
		m_isPaiMing = false;
		m_matchBegin = GetSysTime();
		return;
	}
	else if (CSceneManager::IsAfterActivityTime(SOT_LeiTaiSai) && ! m_isPaiMing)
	{
		m_isPaiMing = true;

		static const int leiTaiLevel[] = {40,50,60,70,80};
		static const int leiTaiWDay[] = {2,2,4,4,5};
		static const int leiTaiLen = sizeof(leiTaiWDay)/sizeof(leiTaiWDay[0]);

		int leiTaiIdx = 0;
		for (; leiTaiIdx < leiTaiLen; ++leiTaiIdx)
		{
			if (leiTaiWDay[leiTaiIdx] == wday)
			{
				break;
			}
		}
		int leiTaiLv = leiTaiLevel[leiTaiIdx];

		int num = m_jifenUsers.size();
		if (num <= MAX_JIFEN_USER_NUM)
		{
			if (num > 0)
			{
				// 即使人不足，也正常排名
				SSortUserJifen sortJifen;
				std::sort(m_jifenUsers.begin(), m_jifenUsers.end(), sortJifen);
				CGetDbConnect getDb;
				CDatabaseSql *pDb = getDb.GetDbConnect();
				if (pDb == NULL)
					return;
				stringstream info;
				info<<LANGUAGE_TRANSFORM_2830<<leiTaiLv<<LANGUAGE_TRANSFORM_2831;
				for (int i = 0; i < num; i++)
				{
					format sql("INSERT INTO leitai_paiming (id,map_id,role_id,name,jifen) VALUES (%1%,%2%,%3%,'%4%',%5%)");
					sql % i % m_mapId % m_jifenUsers[i].roleId % m_jifenUsers[i].name.c_str() % m_jifenUsers[i].jifen;
					pDb->Query(sql.str().c_str());
					info<<m_jifenUsers[i].name.c_str();
					if(i < (num-1))
						info<<",";
				}
				info<<LANGUAGE_TRANSFORM_2832;
				SysInfoToAllUser(info.str().c_str());
			}
		}
		else
		{
			SSortUserJifen sortJifen;
			std::sort(m_jifenUsers.begin(), m_jifenUsers.end(), sortJifen);

			format fmt(LANGUAGE_TRANSFORM_2833);
			if (wday == 0)
				fmt % LANGUAGE_TRANSFORM_2834;
			else
				fmt % leiTaiLv;

			for (uint8 i = 0; i < MAX_JIFEN_USER_NUM; i++)
			{
				fmt % m_jifenUsers[i].name.c_str();
				/*if (wday != 0)
				{
					ShareUserPtr ptr = onlineUser.GetUserByRoleId(m_jifenUsers[i].roleId);
					CUser *pUser = ptr.get();
					if (pUser != NULL)
					{
						pUser->AddTitle(i + E2UT_TAPOCANGQIONG);
					}
					else
					{
						SetOffLineTitle(m_jifenUsers[i].roleId, i + E2UT_TAPOCANGQIONG);
					}
				}*/
			}

			SysInfoToAllUser(fmt.str().c_str());

			CGetDbConnect getDb;
			CDatabaseSql *pDb = getDb.GetDbConnect();
			if (pDb == NULL)
				return;
			for (int i = 0; i < num; i++)
			{
				format sql("INSERT INTO leitai_paiming (id,map_id,role_id,name,jifen) VALUES "\
					"(%1%,%2%,%3%,'%4%',%5%)");
				sql % i % m_mapId % m_jifenUsers[i].roleId % m_jifenUsers[i].name.c_str()
					% m_jifenUsers[i].jifen;
				pDb->Query(sql.str().c_str());
			}
		}

		list<uint32> userList;
		{
			boost::recursive_mutex::scoped_lock lk(m_mutex);
			userList = m_userList;
		}
		for (list<uint32>::iterator i = userList.begin(); i != userList.end(); i++)
		{
			ShareUserPtr ptr = onlineUser.GetUserByRoleId(*i);
			CUser *pUser = ptr.get();
			if (pUser != NULL && pUser->GetFightId() == 0 && pUser->GetTeam() == 0)	// 非战斗踢出副本
				pUser->NoLockBackLastScene();
		}
	}

	if(CSceneManager::IsInActivityTime(SOT_LeiTaiSai))
	{
		MatchTiaoZhanSaiFight();//个人擂台赛安排战斗
	}
	//else
	//{
	//	TeamMatchArrangeFight();//组队擂台赛安排战斗
	//}
}

// 给前几名的积分
void CScene::GetMatchPaiMing(int count, CNetMessage &msg)
{
	vector<SJiFenUser> jifenUsersTmp;
	copy(m_jifenUsers.begin(),m_jifenUsers.end(),back_inserter(jifenUsersTmp));
	SSortUserJifen sortJifen;
	std::sort(jifenUsersTmp.begin(), jifenUsersTmp.end(), sortJifen);
	if ((int)jifenUsersTmp.size() > count)
		msg<<(uint8)count;
	else
		msg<<(uint8)jifenUsersTmp.size();

	int i = 0;
	for (vector<SJiFenUser>::iterator it = jifenUsersTmp.begin(); ((it != jifenUsersTmp.end()) && (i < count)); ++it,++i)
	{
		msg<<it->roleId<<it->name.c_str()<<(uint16)it->jifen;
	}
}

// 获取擂台赛第一名名字
void CScene::GetMatchTopRoleName(char* name)
{
	if (name == NULL)
		return;
	vector<SJiFenUser> jifenUsersTmp;
	copy(m_jifenUsers.begin(),m_jifenUsers.end(),back_inserter(jifenUsersTmp));
	SSortUserJifen sortJifen;
	std::sort(jifenUsersTmp.begin(), jifenUsersTmp.end(), sortJifen);
	if (!jifenUsersTmp.empty())
		strncpy(name,jifenUsersTmp.begin()->name.c_str(),MAX_NAME_LEN);
}

struct SSortMatchUser
{
	bool operator()(const CScene::SMatchUser &m1, const CScene::SMatchUser &m2)
	{
		return m1.level > m2.level;
	}
};

//得到个人擂台赛参赛人员，按照装备积分排序
void CScene::GetMatchUser(vector<SMatchUser> &userList, bool useCorrection)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	uint32 now = GetSysTime();
	for (list<uint32>::iterator i = m_userList.begin(); i != m_userList.end(); i++)
	{
		ShareUserPtr ptr = m_onlineUser.GetUserByRoleId(*i);
		CUser *pUser = ptr.get();
		if (pUser != NULL && pUser->GetExtData32(461) <= now)
		{
			if (pUser->GetExtData32(462) == 0)
			{
				pUser->SetExtData32(462, now);
			}
			pUser->SetExtData32(461, 0);
			if (pUser->GetFightId() != 0 || pUser->GetKuaFuState() != EKFS_IN_LOCAL)
				continue;
			SMatchUser user;
			user.roleId = pUser->GetRoleId();
			user.level = pUser->GetLevel();
			user.equipQuailty = pUser->GetZhanDouLi(); // 直接按照战斗力排序吧
			userList.push_back(user);
		}
	}
	SSortMatchUser matchUserSort;
	std::sort(userList.begin(), userList.end(), matchUserSort);
}

void CScene::MatchTiaoZhanSaiFight()
{
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	vector<SMatchUser> userList;
	vector<uint32> matchIdx;
	GetMatchUser(userList);
	if (userList.empty())
	{
		return;
	}
	uint32 matchPos = 0;
	ShareUserPtr user1;
	ShareUserPtr user2;
	int matchLevel = userList[0].level + 5;
	while (matchPos < userList.size())
	{
		// 取匹配区间的角色
		for (; matchPos < userList.size(); ++matchPos)
		{
			if (userList[matchPos].level < matchLevel)
			{
				matchIdx.push_back(matchPos);
			}
			else
			{
				break;
			}
		}

		// 排序打乱
		RandVector(matchIdx);

		// 生成战斗
		for (size_t pi = 0; pi < matchIdx.size(); ++pi)
		{
			uint32 idx = matchIdx[pi];
			ShareUserPtr user = onlineUser.GetUserByRoleId(userList[idx].roleId);
			if (user.get() == NULL)
				continue;

			// 依次给 user1 user2 赋值
			if (user1.get() == NULL)
			{
				user1 = user;
				continue;
			}
			user2 = user;
			
			MakeLeiTaiFight(user1, user2);
			user1.reset();
			user2.reset();
		}

		// 全部遍历完毕 结束
		if (matchPos == userList.size())
			break;
		// 没有轮空的  进行下一轮
		if (user1.get() == NULL)
			continue;

		// 轮空的进行再处理
		int lessIdx = matchIdx.back();
		matchIdx.clear();
		if (matchLevel - userList[lessIdx].level < 5)
		{// 不是最小等级 进行下一次循环
			matchIdx.push_back(lessIdx);
			matchLevel = userList[lessIdx].level;
			user1.reset();
			continue;
		}
		while (user1.get() != NULL && user1.get() == NULL)
		{// 有没有匹配到同等级区间的
			vector<uint32> powerSeqs;
			int minPower = userList[lessIdx].equipQuailty * 0.8;
			int maxPower = userList[lessIdx].equipQuailty * 1.2;

			for (size_t li = matchPos; li < userList.size(); ++li)
			{
				if (userList[li].equipQuailty > minPower &&
					userList[li].equipQuailty < maxPower)
				{
					powerSeqs.push_back(li);
				}
			}

			int rPos = 0;
			if (powerSeqs.empty())
			{// 没有战斗力符合的
				 // 在剩下的里面随机匹配一个玩家
				int lessNum = userList.size() - matchPos;
				uint32 idx = Random(0, lessNum - 1);
				rPos = matchPos + idx;
			}
			else
			{
				uint32 idx = Random(0, powerSeqs.size() - 1);
				rPos = powerSeqs[idx];
			}
			uint32 roleId = userList[rPos].roleId;
			userList.erase(userList.begin() + rPos);
			user2 = onlineUser.GetUserByRoleId(roleId);
			if (user2.get() == NULL) // 找不到角色 继续找
				continue;
			MakeLeiTaiFight(user1, user2);
			user1.reset();
			user2.reset();
		}
	}
}

void CScene::MatchArrangeFight()
{
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	vector<SMatchUser> userList;
	GetMatchUser(userList, false);
	uint32 num = userList.size()/2;
	uint32 userNum = 0;
	uint32 userPos;
	uint32 equipRank;
	for(uint32 i = 0; i < num; i++)
	{
		userNum = userList.size();
		if(userNum <= 1)
			break;
		ShareUserPtr user = onlineUser.GetUserByRoleId(userList[0].roleId);

		equipRank = Random(1, 100);
		if (equipRank < 61)
			userPos = Random(1,userNum - 1);
		else if (equipRank < 81)
			userPos = Random(1,userNum/4);
		else
			userPos = Random(1,userNum/2);
		
		//if(userNum > 8)
		//	userPos = Random(1,userNum/8);
		//else
		//	userPos = Random(1,3);
		if(userPos >= userList.size())
			userPos = 1;

		ShareUserPtr user1 = onlineUser.GetUserByRoleId(userList[userPos].roleId);
		if((user.get() != NULL) && (user1.get() != NULL))
		{
			ShareFightPtr pFight = m_fightManager.CreateFight();
			pFight->SetFightType(CFight::EFTMatch);
			userList.erase(userList.begin()+userPos);
			userList.erase(userList.begin());
			AddUserGroupToBattle(pFight,user,0);
			AddUserGroupToBattle(pFight,user1);
			pFight->BeginFight(this);
			m_fightManager.AddFight(pFight);
		}
	}
}

void CScene::TeamMatchArrangeFight()
{
	vector<uint32> userList;
	FindMatchUser(userList);

	uint32 user1, user2;
	uint32 r;
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	uint32 userNum = userList.size() / 2;
	for (uint32 i = 0; i < userNum; i++)
	{
		r = Random(0, userList.size() - 1);
		if (r >= userList.size())
			return;
		user1 = userList[r];
		userList.erase(userList.begin() + r);
		r = Random(0, userList.size() - 1);
		if (r >= userList.size())
			return;
		user2 = userList[r];
		userList.erase(userList.begin() + r);

		ShareFightPtr pFight = m_fightManager.CreateFight();
		pFight->SetFightType(CFight::EFTMatch);

		{
			boost::recursive_mutex::scoped_lock lk(m_mutex);
			ShareUserPtr ptr = onlineUser.GetUserByRoleId(user1);
			if (ptr.get() == NULL)
				continue;
			AddUserGroupToBattle(pFight,ptr,0);
			
			ShareUserPtr ptr2 = onlineUser.GetUserByRoleId(user2);
			if (ptr2.get() == NULL)
				continue;
			AddUserGroupToBattle(pFight,ptr2);
		}
		pFight->BeginFight(this);
		m_fightManager.AddFight(pFight);
	}
}

void CScene::BangPaiTiaoZhanSaiTeamMatchArrangeFight()
{
	vector<uint32> userList;
	BangPaiTiaoZhanFindMatchUser(userList);

	uint32 user1, user2;
	uint32 r;
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	uint32 userNum = userList.size() / 2;
	for (uint32 i = 0; i < userNum; i++)
	{
		cout << LANGUAGE_TRANSFORM_2835 << i << LANGUAGE_TRANSFORM_2836 << userNum << endl;
		if (userList.size() < 2)
		{
			cout << LANGUAGE_TRANSFORM_2837 << endl;
			return;
		}
		
		r = Random(0, userList.size() - 1);
		if (r >= userList.size())
		{
			cout << 1111 << endl;
			return;
		}
		user1 = userList[r];
		userList.erase(userList.begin() + r);
		{ // 帮派挑战赛对手的选取
			ShareUserPtr ptr1 = onlineUser.GetUserByRoleId(user1);
			if (ptr1.get() == NULL)
			{
				continue;
			}
			int bang1 = ptr1->GetBangPai();
			if (bang1 == 0)
			{
				continue;
			}
			int bang2;
			user2 = 0;
			if (userList.begin() + r == userList.end())
			{
				r -= 1;
				//cout << "随机到最后一个了" << endl;
			}
			
			for (vector<uint32>::iterator it = userList.begin() + r; it != userList.end(); ++it)
			{
				ShareUserPtr ptr2 = onlineUser.GetUserByRoleId(*it);
				if (ptr2.get() == NULL)
				{
					continue;
				}
				bang2 = ptr2->GetBangPai();
				if (bang2 == 0)
				{
					continue;
				}
				if (bang1 == bang2)
				{
					BangPaiTiaoZhanAddPoint(bang1,0);
					continue;
				}
				user2 = ptr2->GetRoleId();
				userList.erase(it);
				break;
			}
			if (user2 == 0)
			{
				for (vector<uint32>::iterator it = userList.begin(); it != userList.end(); ++it)
				{
					ShareUserPtr ptr2 = onlineUser.GetUserByRoleId(*it);
					if (ptr2.get() == NULL)
					{
						continue;
					}
					bang2 = ptr2->GetBangPai();
					if (bang2 == 0)
					{
						continue;
					}
					if (bang1 == bang2)
					{
						continue;
					}
					user2 = ptr2->GetRoleId();
					userList.erase(it);
					break;
				}
			}
		}
		if (user2 == 0)
		{
			cout << LANGUAGE_TRANSFORM_2838 << endl;
			return;
		}
		

		ShareFightPtr pFight = m_fightManager.CreateFight();
		pFight->SetFightType(CFight::EFTMatch);
		{
			boost::recursive_mutex::scoped_lock lk(m_mutex);
			ShareUserPtr ptr = onlineUser.GetUserByRoleId(user1);
			if (ptr.get() == NULL)
				continue;
			AddUserGroupToBattle(pFight,ptr,0);
			
			ShareUserPtr ptr2 = onlineUser.GetUserByRoleId(user2);
			if (ptr2.get() == NULL)
				continue;
			AddUserGroupToBattle(pFight,ptr2);
		}
		pFight->BeginFight(this);
		m_fightManager.AddFight(pFight);
	}
}

// 是否是百花仙子活动地图
bool CScene::IsBaiHuaXianZiFightMap()
{
	static int baiHuaMap[] = {2,3}; // 百花仙子活动地图
	for (uint8 i = 0; i < sizeof(baiHuaMap) / sizeof(baiHuaMap[0]); ++i)
	{
		if (m_mapId == baiHuaMap[i])
			return true;
	}
	return false;
}

// 读取帮派挑战赛配置
void BangPaiTiaoZhanSaiLoad()
{
	CCallScript *pCallScript = FindScript(67);
	if (pCallScript != NULL)
	{
		pCallScript->Call("BangPaiTiaoZhanSaiLoad",">iiiiiiiiiii",&BANG_PAI_TIAO_ZHAN_YEAR,&BANG_PAI_TIAO_ZHAN_MONTH,&BANG_PAI_TIAO_ZHAN_DAY,&BANG_PAI_TIAO_ZHAN_HOUR,&BANG_PAI_TIAO_ZHAN_MIN,&BANG_PAI_TIAO_ZHAN_BAO_MING_HOUR,&BANG_PAI_TIAO_ZHAN_BAO_CHI_XU,&BANG_PAI_TIAO_ZHAN_LIMIT_TEAM,&BANG_PAI_TIAO_ZHAN_BAOMINGTIME,&BANG_PAI_TIAO_ZHAN_STARTTIME,&BANG_PAI_TIAO_ZHAN_ENDTIME);
		//cout << "year:" << BANG_PAI_TIAO_ZHAN_YEAR << ",month:" << BANG_PAI_TIAO_ZHAN_MONTH << ",day:" << BANG_PAI_TIAO_ZHAN_DAY << ",hour:" << BANG_PAI_TIAO_ZHAN_HOUR << ",min:" << BANG_PAI_TIAO_ZHAN_MIN << ",baoming:" << BANG_PAI_TIAO_ZHAN_BAO_MING_HOUR << ",chixu:" << BANG_PAI_TIAO_ZHAN_BAO_CHI_XU << ",limitTeam:" << BANG_PAI_TIAO_ZHAN_LIMIT_TEAM << ",baomingt:" << BANG_PAI_TIAO_ZHAN_BAOMINGTIME << ",startT:" << BANG_PAI_TIAO_ZHAN_STARTTIME << ",endT:" << BANG_PAI_TIAO_ZHAN_ENDTIME << endl;
	}
}

// 帮派挑战赛
void CScene::BangPaiTiaoZhanTimer()
{
	int state = BangPaiTiaoZhanSaiState();

	static bool isState1 = false;
	static bool isState2 = false;
	static bool isState3 = false;
	static bool isState4 = false;
	if (state == 3) // 活动准备报名
	{
		if (!isState3)
		{
			isState3 = true;
			isState1 = false;
			isState2 = false;
			isState4 = false;
			BangPaiTiaoZhanSaiInitDB();
			BANG_PAI_TIAO_ZHAN_DATA.clear(); // 清空帮派数据
			cout << LANGUAGE_TRANSFORM_2839 << endl;
		}
	}
	else if (state == 1) // 活动报名开始
	{
		if (!isState1)
		{
			isState1 = true;
			SysInfoToAllUser(LANGUAGE_TRANSFORM_2840);
		}
		BangPaiTiaoZhanSaiJinChangNotice();
	}
	else if (state == 2) // 第二阶段开始
	{
		if (!isState2)
		{
			isState2 = true;
			SysInfoToAllUser(LANGUAGE_TRANSFORM_2841);
		}

		BangPaiTiaoZhanSaiTeamMatchArrangeFight(); // 战斗
	}
	else if (state == 4) // 活动结束
	{
		if (!isState4)
		{
			isState4 = true;
			isState3 = false;
			SysInfoToAllUser(LANGUAGE_TRANSFORM_2842);
			BangPaiTiaoZhanTongJiPoint();
			BANG_PAI_TIAO_ZHAN_DATA.clear(); // 清空帮派数据
		}
	}
}

// 帮派挑战赛 增加积分
void CScene::BangPaiTiaoZhanAddPoint(int bang, int point)
{
	cout << LANGUAGE_TRANSFORM_2843 << bang << ",+pt:" << point << endl;
	bool isFound = false;
	for (vector<BangPaiTiaoZhanData>::iterator it = BANG_PAI_TIAO_ZHAN_DATA.begin(); it != BANG_PAI_TIAO_ZHAN_DATA.end(); ++it)
	{
		if (it->bang == bang)
		{
			isFound = true;
			it->point += point;
			break;
		}
	}
	if (!isFound)
	{
		BangPaiTiaoZhanData data;
		data.bang = bang;
		data.point = point;
		BANG_PAI_TIAO_ZHAN_DATA.push_back(data);
	}
}

// 帮派挑战赛 统计、保存积分
void CScene::BangPaiTiaoZhanTongJiPoint()
{
	BangPaiTiaoZhanDataSort sorter;
	std::sort(BANG_PAI_TIAO_ZHAN_DATA.begin(),BANG_PAI_TIAO_ZHAN_DATA.end(),sorter);
	//BANG_PAI_TIAO_ZHAN_DATA.sort(greater<BangPaiTiaoZhanData>());
	for (vector<BangPaiTiaoZhanData>::iterator it = BANG_PAI_TIAO_ZHAN_DATA.begin(); it != BANG_PAI_TIAO_ZHAN_DATA.end(); ++it)
	{
		cout << "bang:" << it->bang << ",pt:" << it->point << endl;
	}
	int bang1 = 0;
	int bang2 = 0;
	int bang3 = 0;
	if (BANG_PAI_TIAO_ZHAN_DATA.size() > 2)
	{
		bang1 = BANG_PAI_TIAO_ZHAN_DATA[0].bang;
		bang2 = BANG_PAI_TIAO_ZHAN_DATA[1].bang;
		bang3 = BANG_PAI_TIAO_ZHAN_DATA[2].bang;
	}
	else if (BANG_PAI_TIAO_ZHAN_DATA.size() == 2)
	{
		bang1 = BANG_PAI_TIAO_ZHAN_DATA[0].bang;
		bang2 = BANG_PAI_TIAO_ZHAN_DATA[1].bang;
	}
	else if (BANG_PAI_TIAO_ZHAN_DATA.size() == 1)
	{
		bang1 = BANG_PAI_TIAO_ZHAN_DATA[0].bang;
	}
	cout << LANGUAGE_TRANSFORM_2844 << bang1 << ",bang2:" << bang2 << ",bang3:" << bang3 << endl;
	BangPaiTiaoZhanSaiSaveResult(bang1,bang2,bang3);
}

// 初始化数据库
void BangPaiTiaoZhanSaiInitDB()
{
	cout << LANGUAGE_TRANSFORM_2845 << endl;
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if (pDb == NULL)
		return;
	char sql[512];
	snprintf(sql,sizeof(sql),"CREATE TABLE IF NOT EXISTS `bang_tiaozhan` ("\
		"`id` int(11) NOT NULL AUTO_INCREMENT,"\
		"`bang` int(11) NOT NULL,"\
		"`data1` int(11) NOT NULL,"\
		"`data2` int(11) NOT NULL,"\
		"`data3` int(11) NOT NULL,"\
		"`type` int(11) NOT NULL,"\
		"`time` int(11) NOT NULL,"\
		"PRIMARY KEY (`id`),"\
		"KEY `data1` (`data1`),"\
		"KEY `data2` (`data2`),"\
		"KEY `data3` (`data3`),"\
		"KEY `type` (`type`)"\
		") ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;");
	if (!pDb->Query(sql))
		return;
	snprintf(sql,sizeof(sql),"truncate bang_tiaozhan;");
	if (!pDb->Query(sql))
		return;
	int curTime = GetSysTime();
	snprintf(sql,sizeof(sql),"insert into bang_tiaozhan (id,bang,data1,data2,data3,type,time) values (1,0,0,0,0,1,%d)",curTime);
	if (!pDb->Query(sql))
		return;
}

// 保存帮派挑战赛战斗结果
void BangPaiTiaoZhanSaiSaveResult(int bang1,int bang2,int bang3)
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if (pDb == NULL)
		return;
	char sql[255];
	snprintf(sql,sizeof(sql),"update bang_tiaozhan set data1=%d,data2=%d,data3=%d,time=%d where id = 1",bang1,bang2,bang3,(int)GetSysTime());
	if (!pDb->Query(sql))
		return;
}

// 进场通知
void BangPaiTiaoZhanSaiJinChangNotice()
{
	static int i = 0;
	time_t t = GetSysTime();
	if ((t > (time_t)(BANG_PAI_TIAO_ZHAN_STARTTIME - BANG_PAI_TIAO_ZHAN_SPACE*2)) && (t < (time_t)BANG_PAI_TIAO_ZHAN_STARTTIME))
	{
		if ((i % 2) == 0)
			SysInfoToAllUser(LANGUAGE_TRANSFORM_2846);
		++i;
		if (i > 1000000)
			i = 0;
	}
}

// 多人闯关战斗 小贼
void CScene::ChuangGuanRobberFight( CUser *pU )
{
	if(pU == NULL)
		return;
	if(pU->GetKuaFuState() != EKFS_IN_LOCAL)
		return;
	if(pU->GetFightId() != 0)
	{
		ChuangGuanRobberFightReward(pU,true);
		return;
	}
	if(pU->GetTeam() != 0) // 组队不能参加战斗
	{
		ChuangGuanRobberFightReward(pU,true);
		return;
	}

	ShareUserPtr pUser;
	ShareFightPtr pFight;

	pUser = m_onlineUser.GetUserBySock(pU->GetSock());
	if (pUser.get() == NULL)
		return;

	pFight = m_fightManager.CreateFight();
	if (pFight.get() == NULL)
		return;
	
	pFight->SetFightType(CFight::EFTChuangGuanRobber);

	{
/*
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		uint8 mid = 2*((pUser->GetLevel()-1)/5) + Random(1,2);
		if (mid > 44)
			mid = 44;		
		ShareMonsterPtr ptr = m_monsterManager.CreateMonster(mid,pUser->GetLevel(),EMTNormal); // 同等级野怪强度
		if (ptr.get() == NULL)
			return;
		
		ptr->pic = 57;
		ptr->name = LANGUAGE_TRANSFORM_2847;
		pFight->AddMonster(ptr, GetMonsterFightPos(1));
		AddUserGroupToBattle(pFight, pUser);
		pFight->BeginFight(this);
*/
	}
	m_fightManager.AddFight(pFight);
}

// 小贼 结束给奖励
void CScene::ChuangGuanRobberFightReward( CUser *pUser, bool win )
{
	if (pUser == NULL)
		return;
	if (win)
	{
		//cout << "小贼战斗发奖了" << endl;
		int level = pUser->GetLevel();
		CHuoDongExpManage &expManager = SingletonHuoDongExpManager::instance();
		int64 addExp = expManager.GetHuoDongExp(6,level,0.125);

		int addCurrencty = 500;
		pUser->AddExp(addExp, true, true);
		pUser->AddMoney(addCurrencty);
		char msgStr[128];
		snprintf(msgStr,sizeof(msgStr),LANGUAGE_TRANSFORM_2848,addCurrencty);
		SendSysInfoFightEnd(pUser,MakeStringColor(msgStr,TIPS_WARNING_COLOR).c_str());
	}
}

// 多人闯关战斗 玩家
void CScene::ChuangGuanUserFight( CUser *pUser, int othRoleId )
{
	if(pUser == NULL)
		return;
	if(pUser->GetKuaFuState() != EKFS_IN_LOCAL)
		return;
	if(pUser->GetFightId() != 0)
	{
		ChuangGuanUserFightBusy(pUser, othRoleId);
		return;
	}
	if(pUser->GetTeam() != 0) // 组队不能参加战斗
	{
		ChuangGuanUserFightBusy(pUser, othRoleId);
		return;
	}

	ShareUserPtr ptr = m_onlineUser.GetUserBySock(pUser->GetSock());
	if (ptr.get() == NULL)
		return;
	ShareUserPtr othPtr;
	CUser *pOthUser = new CUser;
	if(pOthUser == NULL)
		return;
	pOthUser->SetSock(-1);
	if(!pOthUser->CopyUserData(othRoleId))
	{
		delete pOthUser;
		return;
	}

	othPtr.reset(pOthUser);
	ShareFightPtr pFight = SingletonFightManager::instance().CreateFight();
	pFight->SetFightType(CFight::EFTChuangGuanUserFight);
	pFight->SetFightChooseMode();
	AddUserGroupToBattle(pFight,ptr,0);
	AddUserGroupToBattle(pFight,othPtr);
	pFight->BeginFight(pUser->GetScene());
	SingletonFightManager::instance().AddFight(pFight);
}

// 玩家战斗 玩家在战斗中
void CScene::ChuangGuanUserFightBusy( CUser *pUser, int othRoleId )
{
	// 处理方式就是直接按战斗力判断结果
	if (pUser == NULL)
		return;

	string othName = "";
	int zhanDouLi = pUser->GetZhanDouLi();
	int othZhanDouLi = 0;
	bool newUser = false;

	ShareUserPtr othPtrR = m_onlineUser.GetUserByRoleId(othRoleId);
	CUser *pOthUserR = othPtrR.get();
	if (pOthUserR != NULL)
	{
		othZhanDouLi = pOthUserR->GetZhanDouLi();
		othName = pOthUserR->GetName();
	}
	else
	{
		pOthUserR = new CUser;
		newUser = true;
		if(!pOthUserR->CopyUserData(othRoleId))
		{
			delete pOthUserR;
			return;
		}
		othZhanDouLi = pOthUserR->GetZhanDouLi();
	}

	// 按战斗力判断战斗是否胜利
	cout<<"Call CScene obj ChuangGuanUserFightBusy "<<endl;
	ChuangGuanUserFightReward(pUser,pOthUserR,(zhanDouLi >= othZhanDouLi));
	if(newUser)
		delete pOthUserR;
}

// 玩家战斗 结束给奖励
void CScene::ChuangGuanUserFightReward(CUser *pUser,CUser *pOther, bool win)
{
	//if(pUser == NULL || pOther == NULL)
	if(pUser == NULL){
		return;
	}
	/*if(win)
	{
		pUser.AddChuangguanMaterial(pUser, 2, true);
		chuangguan_fight_result r;
		r.exp_ = 0;
		r.gold_ = 0;
		r.coin_ = 0;
		r.win_ = true;
		SingletonCXunBaoManage::instance().PvPFightCallBack(pUser, r);
	}
	else
	{
		chuangguan_fight_result r;
		r.exp_ = 0;
		r.gold_ = 0;
		r.coin_ = 0;
		r.win_ = false;
		SingletonCXunBaoManage::instance().PvPFightCallBack(pUser, r);
	}*/
}

// 玩家战斗
void CScene::GrabFishUserFight( CUser *pUser, int othRoleId )
{
	if (pUser == NULL)
		return;
	if(pUser->GetKuaFuState() != EKFS_IN_LOCAL)
		return;
	if (pUser->GetFightId() != 0)
		return;
	if (pUser->GetTeam() != 0) // 组队不能参加战斗
		return;

	ShareUserPtr ptr = m_onlineUser.GetUserBySock(pUser->GetSock());
	if (ptr.get() == NULL)
		return;

	ShareUserPtr othPtr;
	CUser *pOthUser = new CUser;
	if(pOthUser == NULL)
		return;
	pOthUser->SetSock(-1);
	if(!pOthUser->CopyUserData(othRoleId))
	{
		delete pOthUser;
		return;
	}

	othPtr.reset(pOthUser);
	ShareFightPtr pFight = SingletonFightManager::instance().CreateFight();
	pFight->SetFightType(CFight::EFTGrabFish);
	pFight->SetFightChooseMode();
	AddUserGroupToBattle(pFight,ptr,0);
	AddUserGroupToBattle(pFight,othPtr);
	pFight->BeginFight(pUser->GetScene());
	SingletonFightManager::instance().AddFight(pFight);
}

bool CScene::AddMonsterByFightId(ShareFightPtr &pFight,int fightId,uint16 level,int visableId)
{
	if(pFight.get() == NULL || fightId < 1)
		return false;
	CFightCfgManager &fightCfgMgr = SingletonCFightCfgManager::instance();
	SFightCfgData *pFightCfg = fightCfgMgr.GetFightCfg(fightId);
	if(pFightCfg == NULL || pFightCfg->zhenfa_id == 0)
		return false;
	vector<SFightDialogCfg> dialog;
	if(pFightCfg->fight_dialog_id > 0)
	{
		fightCfgMgr.GetFightDialog(dialog,pFightCfg->fight_dialog_id);
		pFight->SetDialog(dialog);
	}
	
	uint16 zhenfaLevel = pFightCfg->GetZhenFaLv(level);
	CZhenFaCfgMgr &zhenfaMgr = SingletonCZhenFaCfgMgr::instance();
	SZhenFaBasicCfg *pZhenFa = zhenfaMgr.GetBasicCfg(pFightCfg->zhenfa_id);
	SZhenFaLevelUpData *pZhenFaAttr = zhenfaMgr.GetLevelUpCfg(pFightCfg->zhenfa_id,zhenfaLevel);
	if(pZhenFa == NULL || pZhenFaAttr == NULL)
		return false;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	pFight->SetCfgFightId(fightId);
	pFight->SetGroupZhenFaData(pFightCfg->zhenfa_id,zhenfaLevel,CFight::EGT_GROUP2);
	for(uint16 i=0;i < sizeof(pFightCfg->bossId)/sizeof(pFightCfg->bossId[0]); i++)
	{
		if(pFightCfg->bossId[i] > 0)
		{
			SMonsterInst *pMonster = NULL;
			AddMonsterBossToFight(pFight,pFightCfg->bossId[i], pZhenFa->fightPos[i]+CFight::GROUP2_BEGIN, i, level, &pMonster);
			if(visableId > 0 && pMonster != NULL)
			{
				pMonster->visableId = visableId;
			}
		}
	}
	return true;
//	pFight->SetMemberFirstCartonType(GetMonsterFightPos(1),CartonType_ShuiGhui);
}

bool CScene::AddBloodFightMonster(ShareFightPtr &pFight, BloodFight& fightCfg, double ratio)
{
	if (pFight.get() == NULL)
		return false;

	CZhenFaCfgMgr &zhenfaMgr = SingletonCZhenFaCfgMgr::instance();
	SZhenFaBasicCfg *pZhenFa = zhenfaMgr.GetBasicCfg(fightCfg.formation);
	SZhenFaLevelUpData *pZhenFaAttr = zhenfaMgr.GetLevelUpCfg(fightCfg.formation, 1);
	if (pZhenFa == NULL || pZhenFaAttr == NULL)
		return false;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	pFight->SetGroupZhenFaData(fightCfg.formation, 1, CFight::EGT_GROUP2);
	for (uint16 i = 0; i < fightCfg.monster.size(); i++)
	{
		if (fightCfg.monster[i] > 0)
		{
			ShareMonsterPtr ptr = SingletonMonsterBossManager::instance().CreateRatioMonster(fightCfg.monster[i], ratio);
			SMonsterInst *pInst = ptr.get();
			if (pInst == NULL || pInst->id == 0)
				return 0;
			pFight->AddMonster(ptr, CFight::GROUP2_BEGIN + pZhenFa->fightPos[i], i);
		}
	}
	return true;
}


bool CScene::AddMonsterBySpecFightId(ShareFightPtr &pFight,int specFightId,uint16 level)
{
	if(pFight.get() == NULL || specFightId < 1)
		return false;
	CFightCfgManager &fightCfgMgr = SingletonCFightCfgManager::instance();
	SFightSpecCfgData *pSpecCfg = fightCfgMgr.GetSpecFightCfg(specFightId);
	if(pSpecCfg == NULL || pSpecCfg->zhenfa_id == 0)
		return false;
	vector<SFightDialogCfg> dialog;
	if(pSpecCfg->fight_dialog_id > 0)
	{
		fightCfgMgr.GetFightDialog(dialog,pSpecCfg->fight_dialog_id);
		pFight->SetDialog(dialog);
	}
	
	uint16 zhenfaLevel = pSpecCfg->GetZhenFaLv(level);
	CZhenFaCfgMgr &zhenfaMgr = SingletonCZhenFaCfgMgr::instance();
	SZhenFaBasicCfg *pZhenFa = zhenfaMgr.GetBasicCfg(pSpecCfg->zhenfa_id);
	SZhenFaLevelUpData *pZhenFaAttr = zhenfaMgr.GetLevelUpCfg(pSpecCfg->zhenfa_id,zhenfaLevel);
	if(pZhenFa == NULL || pZhenFaAttr == NULL)
		return false;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	pFight->SetCfgFightId(specFightId);
	pFight->SetGroupZhenFaData(pSpecCfg->zhenfa_id,zhenfaLevel,CFight::EGT_GROUP1);
	for(uint16 i=0;i < sizeof(pSpecCfg->bossId)/sizeof(pSpecCfg->bossId[0]); i++)
	{
		if(pSpecCfg->bossId[i] > 0)
		{
			AddMonsterBossToFight(pFight,pSpecCfg->bossId[i],pZhenFa->fightPos[i],i,level);
		}
	}
	return true;
}

bool CScene::AddZhuaguiMonster(ShareFightPtr &pFight, int fightId, uint16 level, const char* name)
{
	if (pFight.get() == NULL || fightId < 1)
		return false;
	CFightCfgManager &fightCfgMgr = SingletonCFightCfgManager::instance();
	SFightCfgData *pFightCfg = fightCfgMgr.GetFightCfg(fightId);
	if (pFightCfg == NULL || pFightCfg->zhenfa_id == 0)
		return false;
	vector<SFightDialogCfg> dialog;
	if(pFightCfg->fight_dialog_id > 0)
	{
		fightCfgMgr.GetFightDialog(dialog,pFightCfg->fight_dialog_id);
		pFight->SetDialog(dialog);
	}

	uint16 zhenfaLevel = 1;
	for (uint8 i = 0; i < pFightCfg->zhenfaLevel.size(); i++)
	{
		if (level <= pFightCfg->zhenfaLevel[i].role_level)
		{
			zhenfaLevel = pFightCfg->zhenfaLevel[i].zhenfa_level;
			break;
		}
	}

	CZhenFaCfgMgr &zhenfaMgr = SingletonCZhenFaCfgMgr::instance();
	SZhenFaBasicCfg *pZhenFa = zhenfaMgr.GetBasicCfg(pFightCfg->zhenfa_id);
	SZhenFaLevelUpData *pZhenFaAttr = zhenfaMgr.GetLevelUpCfg(pFightCfg->zhenfa_id, zhenfaLevel);
	if (pZhenFa == NULL || pZhenFaAttr == NULL)
		return false;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	pFight->SetCfgFightId(fightId);
	pFight->SetGroupZhenFaData(pFightCfg->zhenfa_id, zhenfaLevel, CFight::EGT_GROUP1);
	SMonsterInst *pBoss = NULL;
	int minId = 0;
	for (uint16 i = 0; i < sizeof(pFightCfg->bossId) / sizeof(pFightCfg->bossId[0]); i++)
	{
		if (pFightCfg->bossId[i] > 0)
		{
			SMonsterInst *pMonster = NULL;
			AddMonsterBossToFight(pFight, pFightCfg->bossId[i], pZhenFa->fightPos[i], i, level, &pMonster);
			if (minId == 0 || minId > pFightCfg->bossId[i])
			{
				minId = pFightCfg->bossId[i];
				pBoss = pMonster;
			}
		}
	}
	pBoss->name = name;
	return true;
}


// 添加任务战斗战斗怪物
uint8 CScene::AddMonsterBossToFight(ShareFightPtr &pFight,uint32 bossId,uint8 pos,uint8 zhenfaPos,uint16 level,SMonsterInst **ppMonster)
{
	ShareMonsterPtr ptr = SingletonMonsterBossManager::instance().CreateMonsterBossById(bossId,level);
	SMonsterInst *pInst = ptr.get();
	if(pInst == NULL || pInst->id == 0)
		return 0;
	if(ppMonster != NULL)
		*ppMonster = pInst;
//	if(attr != NULL)
//		pInst->AddZhenFaAttr(*attr);
	pFight->AddMonster(ptr, pos,zhenfaPos);
	return pInst->level;
}

void CScene::CMissionFight(CUser *pU,int missId,int fightCfgId)	// 任务战斗
{
	if(pU == NULL || missId < 1 || fightCfgId < 1)
		return;
	if(pU->GetKuaFuState() != EKFS_IN_LOCAL)
		return;
	if(pU->GetFightId() != 0)
		return;

	ShareUserPtr pUser = m_onlineUser.GetUserBySock(pU->GetSock());
	ShareFightPtr pFight = m_fightManager.CreateFight();
	if (pUser.get() == NULL || pFight.get() == NULL)
		return;
	pFight->SetFightType(CFight::EFTCMission);
	pFight->SetTaskId(missId);
	//pFight->SetFightChooseMode();		// 手动模式

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	uint16 level = 1;
	if(fightCfgId < 500000)
	{
		level = AddUserGroupToBattle(pFight, pUser);
		if(level == 0)
			return;
		AddMonsterByFightId(pFight,fightCfgId,level);
	}
	else
	{
		CFightCfgManager &fightCfgMgr = SingletonCFightCfgManager::instance();
		SFightSpecCfgData *pSpecCfg = fightCfgMgr.GetSpecFightCfg(fightCfgId);
		if(pSpecCfg == NULL)
			return;
		if(pSpecCfg->user_zhenfa_id == 0)
		{
			AddUserGroupToBattle(pFight, pUser);
		}
		else
		{
			uint16 zhenfaId = pSpecCfg->user_zhenfa_id;
			uint16 zhenfaLv = pSpecCfg->GetUserZhenFaLv(pU->GetLevel());
			AddSingleUserWithZhenFaId(pFight,pUser,CFight::GROUP2_BEGIN,zhenfaId,zhenfaLv,pSpecCfg->user_pos);
		}
		AddMonsterBySpecFightId(pFight,fightCfgId,level);

		if(pSpecCfg->zhuzhanId > 0)
		{
			vector<SFightZhuZhanCfg> zhuzhan;
			fightCfgMgr.GetZhuZhanCfg(zhuzhan,pSpecCfg->zhuzhanId);
			if(!zhuzhan.empty())
			{
				pFight->SetZhuZhan(zhuzhan);
			}
		}
	}
	pFight->BeginFight(this);
	m_fightManager.AddFight(pFight);
}

void CScene::MeetSelfMonster(ShareUserPtr pUser,int monsterType,string &monsterName)
{
	if(pUser.get() == NULL)
		return;
	switch(monsterType)
	{
		case 1:
			break;
		case 2:
//			RingTaskFight201(pUser,monsterName);
			break;
//		case 1000:
//			KuaFuZhuoGuiFight(pUser);
//			break;
		default:
			break;
	}
}

void CScene::KuaFuZhuoGuiFight(ShareUserPtr pU)
{
/*
	CUser *pUser = pU.get();
	if(pUser == NULL)
		return;
	const char *pMission806 = pUser->GetMission(806);
	if(pMission806 != NULL)
	{
		char *split[8] = {NULL};
		string str = pMission806;
		if(SplitLine(split,8,(char*)str.c_str()) == 8)
		{
			int isComplete = atoi(split[0]);
			if(isComplete == 1)
				return;
			string bossName = split[4];
//			int bossPic = atoi(split[5]);
//			int monPic = atoi(split[6]);
//			int fightType = atoi(split[7]);
//			int idx = pUser->GetExtData16(61)+1;
//			int turn = pUser->GetExtData16(60);
//			uint8 teamLevel = pUser->GetLevel();
			
//			ShareFightPtr pFight = m_fightManager.CreateFight();
//			uint16 monsterId = 30;
//			SMonsterTmpl *pTmpl = m_monsterManager.GetTmpl(monsterId);
//			if(pTmpl == NULL)
//				return;
//			uint16 skillLv = ((int)teamLevel-40)/5 + 1;

			{
				pFight->SetFightType(CFight::EFT_KuaFu_ZhuoGui);
				boost::recursive_mutex::scoped_lock lk(m_mutex);
				float a = 1.0f;
				float b = 1.0f + ((int)teamLevel - 50)/(double)teamLevel;
				if(idx < 10)
				{
					for(uint8 i = 0; i < CFight::GROUP2_BEGIN; i++)
					{
						ShareMonsterPtr	pShareMonster = m_monsterManager.CreateMonster(monsterId,teamLevel,EMTNormal);
						if(i == 0)	// boss
						{
							pShareMonster->name = bossName;
							pShareMonster->ClearSkill();
							if(fightType == 1)
							{
								pShareMonster->attack = (int)(pShareMonster->attack*1.35*a);
								pShareMonster->recovery = (int)(pShareMonster->recovery*2.5*a);
								pShareMonster->maxHp = (int)(pShareMonster->maxHp*4.7*b);
								pShareMonster->speed = ((int)teamLevel)*20;
								pShareMonster->AddSkillWithRatio(63,skillLv,100);
							}
							else if(fightType == 2)
							{
								pShareMonster->attack = (int)(pShareMonster->attack*1.15*a);
								pShareMonster->recovery = (int)(pShareMonster->recovery*5.4*a);
								pShareMonster->maxHp = (int)(pShareMonster->maxHp*4.3*b);
								pShareMonster->speed = ((int)teamLevel)*25;
								pShareMonster->AddSkillWithRatio(62,skillLv,100);
							}
							else if(fightType == 3)
							{
								pShareMonster->attack = (int)(pShareMonster->attack*1.15*a);
								pShareMonster->recovery = (int)(pShareMonster->recovery*5.4*a);
								pShareMonster->maxHp = (int)(pShareMonster->maxHp*4.3*b);
								pShareMonster->speed = ((int)teamLevel)*25;
								pShareMonster->AddSkillWithRatio(61,skillLv,100);
							}
							else if(fightType == 4)
							{
								pShareMonster->attack = (int)(pShareMonster->attack*1.45*a);
								pShareMonster->recovery = (int)(pShareMonster->recovery*2.8*a);
								pShareMonster->maxHp = (int)(pShareMonster->maxHp*4.7*b);
								pShareMonster->speed = ((int)teamLevel)*20;
								pShareMonster->baojilv = 4875;
								pShareMonster->AddSkillWithRatio(17,skillLv,100);
								pShareMonster->AddSkillWithRatio(18,skillLv,100);
								pShareMonster->AddSkillWithRatio(19,skillLv,100);
								pShareMonster->AddSkillWithRatio(20,skillLv,100);
								pShareMonster->AddSkillWithRatio(29,skillLv,100);
							}
							else if(fightType == 5)
							{
								pShareMonster->attack = (int)(pShareMonster->attack*1.45*a);
								pShareMonster->recovery = (int)(pShareMonster->recovery*2.8*a);
								pShareMonster->maxHp = (int)(pShareMonster->maxHp*4.7*b);
								pShareMonster->speed = ((int)teamLevel)*20;
								pShareMonster->lianji = 4875;
								pShareMonster->AddSkillWithRatio(22,skillLv,100);
								pShareMonster->AddSkillWithRatio(24,skillLv,100);
								pShareMonster->AddSkillWithRatio(31,skillLv,100);
							}
							pShareMonster->quality = PQT_PURPLE;
							pShareMonster->tmplId = bossPic;
						}
						else	// 小怪
						{
							pShareMonster->name = LANGUAGE_TRANSFORM_2689;
							pShareMonster->ClearSkill();
							if(fightType == 1)
							{
								pShareMonster->attack = (int)(pShareMonster->attack*1.25*a);
								pShareMonster->recovery = (int)(pShareMonster->recovery*2.8*a);
								pShareMonster->maxHp = (int)(pShareMonster->maxHp*6.5*b);
								pShareMonster->speed = ((int)teamLevel)*25;
								pShareMonster->AddSkillWithRatio(12,skillLv,100);
								pShareMonster->AddSkillWithRatio(15,skillLv,100);
								pShareMonster->AddSkillWithRatio(17,skillLv,100);
								pShareMonster->AddSkillWithRatio(18,skillLv,100);
								pShareMonster->AddSkillWithRatio(19,skillLv,100);
								pShareMonster->AddSkillWithRatio(20,skillLv,100);
								pShareMonster->AddSkillWithRatio(21,skillLv,100);
								pShareMonster->AddSkillWithRatio(22,skillLv,100);
								pShareMonster->AddSkillWithRatio(23,skillLv,100);
								pShareMonster->AddSkillWithRatio(24,skillLv,100);
								pShareMonster->AddSkillWithRatio(25,skillLv,100);
								pShareMonster->AddSkillWithRatio(33,skillLv,100);
							}
							else if(fightType == 2)
							{
								pShareMonster->attack = (int)(pShareMonster->attack*1.35*a);
								pShareMonster->recovery = (int)(pShareMonster->recovery*2.8*a);
								pShareMonster->maxHp = (int)(pShareMonster->maxHp*5.2*b);
								pShareMonster->speed = ((int)teamLevel)*20;
								pShareMonster->AddSkillWithRatio(22,skillLv,100);
								pShareMonster->AddSkillWithRatio(24,skillLv,100);
							}
							else if(fightType == 3)
							{
								pShareMonster->attack = (int)(pShareMonster->attack*1.35*a);
								pShareMonster->recovery = (int)(pShareMonster->recovery*2.8*a);
								pShareMonster->maxHp = (int)(pShareMonster->maxHp*5.2*b);
								pShareMonster->speed = ((int)teamLevel)*20;
								pShareMonster->AddSkillWithRatio(12,skillLv,100);
								pShareMonster->AddSkillWithRatio(15,skillLv,100);
								pShareMonster->AddSkillWithRatio(17,skillLv,100);
								pShareMonster->AddSkillWithRatio(18,skillLv,100);
								pShareMonster->AddSkillWithRatio(19,skillLv,100);
								pShareMonster->AddSkillWithRatio(20,skillLv,100);
								pShareMonster->AddSkillWithRatio(21,skillLv,100);
								pShareMonster->AddSkillWithRatio(23,skillLv,100);
								pShareMonster->AddSkillWithRatio(25,skillLv,100);
								pShareMonster->AddSkillWithRatio(33,skillLv,100);
							}
							else if(fightType == 4)
							{
								pShareMonster->attack = (int)(pShareMonster->attack*1.15*a);
								pShareMonster->recovery = (int)(pShareMonster->recovery*2.5*a);
								pShareMonster->maxHp = (int)(pShareMonster->maxHp*4.7*b);
								pShareMonster->speed = ((int)teamLevel)*30;
								pShareMonster->AddSkillWithRatio(104,skillLv,100);
							}
							else if(fightType == 5)
							{
								pShareMonster->attack = (int)(pShareMonster->attack*1.15*a);
								pShareMonster->recovery = (int)(pShareMonster->recovery*2.5*a);
								pShareMonster->maxHp = (int)(pShareMonster->maxHp*4.7*b);
								pShareMonster->speed = ((int)teamLevel)*30;
								pShareMonster->AddSkillWithRatio(105,skillLv,100);
							}
							pShareMonster->quality = PQT_BLUE;
							pShareMonster->tmplId = monPic;
						}
						pShareMonster->hp = pShareMonster->maxHp;
						
						if(fightType == 1 || fightType == 4 || fightType == 5)
							pFight->AddMonster(pShareMonster,GetMonsterFightPos(i+1));
						else
						{
							if(i == 0)
								pFight->AddMonster(pShareMonster,GetMonsterFightPos(6));
							else
								pFight->AddMonster(pShareMonster,GetMonsterFightPos(i));
						}
					}
				}
				else	// 第10个人任务boss
				{
					ShareMonsterPtr	pShareMonster = m_monsterManager.CreateMonster(monsterId,teamLevel,EMTNormal);
					pShareMonster->name = bossName;
					pShareMonster->attack = (int)(pShareMonster->attack*3*a);
					pShareMonster->recovery = (int)(pShareMonster->recovery*5.0*a);
					pShareMonster->maxHp = (int)(pShareMonster->maxHp*15.0*b);
					pShareMonster->speed = ((int)teamLevel)*30;
					pShareMonster->ClearSkill();
					pShareMonster->AddSkillWithRatio(15,skillLv,100);
					pShareMonster->AddSkillWithRatio(21,skillLv,100);
					pShareMonster->AddSkillWithRatio(25,skillLv,100);
					pShareMonster->AddSkillWithRatio(28,skillLv,100);
					pShareMonster->hp = pShareMonster->maxHp;
					pShareMonster->tmplId = bossPic;
					pShareMonster->quality = PQT_ORANGE;
					pFight->AddMonster(pShareMonster,GetMonsterFightPos(1));
				}
				AddUserGroupToBattle(pFight,pU);
				pFight->BeginFight(this);
			}
			m_fightManager.AddFight(pFight);
		}
	}
*/
}

void CScene::DailyBossFight(ShareUserPtr pU,int taskIndex)
{
	CUser *pUser = pU.get();
	if(pUser == NULL)
		return;
	if(pUser->GetKuaFuState() != EKFS_IN_LOCAL)
		return;
	if(pUser->GetFightId() != 0)
		return;
	if(taskIndex < 1 || taskIndex > 12)
		return;
	
	ShareFightPtr pFight = m_fightManager.CreateFight();
	if(pFight.get() == NULL)
		return;
	pFight->SetFightType(CFight::EFTDailyBoss);
	pFight->SetVisibleMonsterId((uint16)taskIndex);
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		uint16 level = AddUserGroupToBattle(pFight,pU);
		int fightId = 11601 + taskIndex -1;
		AddMonsterByFightId(pFight,fightId,level);
		pFight->BeginFight(this);
	}
	m_fightManager.AddFight(pFight);
}

void CScene::FengShenFight(ShareUserPtr pU,int fengShenId,int fightId)
{
	if(fightId == 0 || fengShenId == 0)
		return;
	CUser *pUser = pU.get();
	if(pUser == NULL)
		return;
	if(pUser->GetKuaFuState() != EKFS_IN_LOCAL)
		return;
	if(pUser->GetFightId() != 0)
		return;
	
	ShareFightPtr pFight = m_fightManager.CreateFight();
	if(pFight.get() == NULL)
		return;
	pFight->SetFightType(CFight::EFT_FengShen);
	pFight->SetVisibleMonsterId(fengShenId);
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		uint16 level = AddUserGroupToBattle(pFight,pU);
		AddMonsterByFightId(pFight,fightId,level);
		pFight->BeginFight(this);
	}
	m_fightManager.AddFight(pFight);
	pUser->SetBitSet(435);
	SingletonCMissionManager::instance().VerifyNewBranchMissionFinish(pUser, EMISS_DC_74);
}

// 获取怪物的战斗位置
int CScene::GetMonsterFightPos(int idx)
{
	const int pos[] = {8,1,2,3,4,5,6,7,9};
	if(idx < 1 || idx > (int)(sizeof(pos)/sizeof(pos[0])))
		return 8;
	return pos[idx-1];
}

// 设置掉落
void SVisibleMonsterBossDrop::SetDrop(char* drop)
{
	if (strlen(drop) == 0)
		return;

	const int size = 64;
	char *tmpStr[size];
	int num = SplitLine(tmpStr, size, drop);
	int type = 0; // 类型
	int itemIdx = 0; // 掉落道具的索引
	for (uint8 i = 0; i < num;)
	{
		type = atoi(tmpStr[i++]);
		if (type == -1) // 钱
		{
			money1 = atoi(tmpStr[i++]);
			money2 = atoi(tmpStr[i++]);
		}
		else if (type == -2) // 经验
		{
			exp1 = atoi(tmpStr[i++]);
			exp2 = atoi(tmpStr[i++]);
		}
		else if (type == -3) // 道行
		{

		}
		else if (type == -4) // 潜能
		{
			qianneng1 = atoi(tmpStr[i++]);
			qianneng2 = atoi(tmpStr[i++]);
		}
		else if (type == -5) // 道具
		{
			items[itemIdx].rate = atoi(tmpStr[i++]);
			items[itemIdx].plusRate = atoi(tmpStr[i++]);
			items[itemIdx].itemId = atoi(tmpStr[i++]);
			items[itemIdx].itemLv = atoi(tmpStr[i++]);
			items[itemIdx].itemNum = atoi(tmpStr[i++]);
			++itemIdx;
		}
	}
	//cout << "掉落：" << money1 << "," << money2 << "," << exp1 << "," << exp2 << "," << (int)items[0].rate << "," << items[0].itemId << endl;
}

void CScene::AddPetCopyMonsterBoss(int level)
{
	const SPoint pos[2] = {{589,630},{1264,637}};
	int difficulty = GetPetCopyDifficulty();
	int fightId[2] = {0,0};
	for(uint8 i=0;i < sizeof(fightId)/sizeof(fightId[0]);i++)
	{
		if(difficulty == 0)
		{
			if(level < 15)
				fightId[i] = Random(10001,10006);
			else if(level >= 15 && level < 25)
				fightId[i] = Random(10011,10016);
			else if(level >= 25 && level < 35)
				fightId[i] = Random(10021,10026);
			else
				fightId[i] = Random(10031,10036);
		}
		else if(difficulty == 1)
		{
			fightId[i] = Random(10101,10106);
		}
		else if(difficulty == 2)
		{
			fightId[i] = Random(10201,10206);
		}
		else if(difficulty == 3)
		{
			fightId[i] = Random(10301,10306);
		}
		AddVisibleBossByFightId(fightId[i],pos[i].x,pos[i].y);
	}
}

void CScene::AddShengJieMonsterBoss(int level)
{
	const SPoint pos[2] = {{603,436},{1070,409}};
	int fightId[2] = {0,0};
	if(level < 25)
		fightId[0] = Random(10401,10406);
	else if(level < 35)
		fightId[0] = Random(10421,10426);
	else
		fightId[0] = Random(10441,10446);
	AddVisibleBossByFightId(fightId[0],pos[0].x,pos[0].y);
	if(level < 25)
		fightId[1] = Random(10411,10416);
	else if(level < 35)
		fightId[1] = Random(10431,10436);
	else
		fightId[1] = Random(10451,10456);
	AddVisibleBossByFightId(fightId[1],pos[1].x,pos[1].y);
}

void CScene::AddQiangHuaMonsterBoss()
{
	const SPoint pos[2] = {{780,534},{1324,600}};
	int fightId[2] = {0,0};
	fightId[0] = Random(10501,10506);
	AddVisibleBossByFightId(fightId[0],pos[0].x,pos[0].y);
	fightId[1] = Random(10511,10516);
	AddVisibleBossByFightId(fightId[1],pos[1].x,pos[1].y);
}

void CScene::AddChongKaiMonsterBoss()
{
	const SPoint pos[2] = {{814,415},{1493,782}};
	int fightId[2] = {0,0};
	fightId[0] = Random(10601,10606);
	AddVisibleBossByFightId(fightId[0],pos[0].x,pos[0].y);
	fightId[1] = Random(10611,10616);
	AddVisibleBossByFightId(fightId[1],pos[1].x,pos[1].y);
}

void CScene::AddXiLianMonsterBoss()
{
	const SPoint pos[2] = {{835,657},{1242,429}};
	int fightId[2] = {0,0};
	fightId[0] = Random(10701,10706);
	AddVisibleBossByFightId(fightId[0],pos[0].x,pos[0].y);
	fightId[1] = Random(10711,10716);
	AddVisibleBossByFightId(fightId[1],pos[1].x,pos[1].y);
}


void CScene::BangZhanSceneAddExp(int expRatio)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(list<uint32>::iterator i = m_userList.begin(); i != m_userList.end(); i++)
	{
		ShareUserPtr ptr = m_onlineUser.GetUserByRoleId(*i);
		CUser *pUser = ptr.get();
		if(pUser != NULL)
		{
			int exp = pUser->GetLevel() * expRatio;
			if(pUser->GetFightId() == 0)
				pUser->AddExp(exp,true,false);
			else
				pUser->AddExp(exp,true,true);
		}
	}
}

void CScene::ExitBangZhan()
{
#ifndef KUA_FU
	if(m_srcSceneId != BP_FIGHT_SID && m_srcSceneId != BANG_PAI_SCENE_ID)
		return;
#else
	if(m_srcSceneId != KUAFU_BZ_SID && m_srcSceneId != KUAFU_BZ_READY_SID)
		return;
#endif
	list<uint32> userList;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		userList = m_userList;
	}
	for(list<uint32>::iterator i=userList.begin(); i != userList.end(); i++)
	{
		ShareUserPtr ptr = m_onlineUser.GetUserByRoleId(*i);
		CUser *pUser = ptr.get();
		if(pUser != NULL && pUser->GetFightId() == 0)	// 不在战斗中先踢出
		{
			if(pUser->GetTeam() > 0 && pUser->GetTeam() != pUser->GetRoleId())
				continue;
#ifndef KUA_FU
			if(pUser->GetBangPai() == (uint32)GetBZ_WIN_BANG_ID())
				continue;
			TransportUser(pUser,BP_FIGHT_EXIT_SID,BP_FIGHT_EXIT_X,BP_FIGHT_EXIT_Y,1);
#else
			if(pUser->GetBangPai() == (uint32)GetBZ_WIN_BANG_ID(SingletonCBangPaiManager::instance().GetKuaFuBangZhanGroupIdx(pUser->GetBangPai())))
				continue;
			TransportUser(pUser,KUAFU_EXIT_SID,KUAFU_EXIT_X,KUAFU_EXIT_Y,1);
#endif
		}
	}
}

void CScene::AddBangZhanBox()
{
	const int ADD_BOX_NUM = 10;
	SPoint scenePoint[ADD_BOX_NUM] = {};

	const int npcId = 178;	// 宝箱
	const int BOX_PIC = 65;

	if(m_srcSceneId != BP_FIGHT_SID && m_srcSceneId != KUAFU_BZ_SID)
		return;
	int pointSize = sizeof(scenePoint)/sizeof(scenePoint[0]);
	int haveBoxNum = 0;
	{
		// 检查上一轮遗留宝箱
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		for(list<SNpcInstance*>::iterator i = m_dynamicNpc.begin(); i != m_dynamicNpc.end(); i++)
		{
			if((*i)->id == npcId)	// 宝箱
				haveBoxNum++;
		}
	}
	if(haveBoxNum >= pointSize)
		return;

	for (int i = 0; i < ADD_BOX_NUM - haveBoxNum; ++i)
	{
		GetCanWalkPos(scenePoint[i].x, scenePoint[i].y);
	}
	for(uint16 i=0;i < ADD_BOX_NUM - haveBoxNum;i++)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		AddNpcWithIndex(npcId, BOX_PIC, scenePoint[i].x, scenePoint[i].y, 0, m_NPCMonSterIndex++);
	}
}

//添加活动宝箱（类型-XTMAS_BOX-41）
void CScene::AddXtmasBox(int npcId,int &index,int pic,int num)
{
	if (npcId < 1 || num < 1)
		return;
	vector<SPoint> scenePoint(num);

	//int npcId = 178;	// 宝箱
	//const int BOX_PIC = 65;

	if(m_srcSceneId < 2 && m_srcSceneId > 4)
		return;

	for (int i = 0; i < num; i++)
	{
		GetCanWalkPos(scenePoint[i].x, scenePoint[i].y);
	}
	for(uint16 i=0;i < num ;i++)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		AddNpcWithIndex(npcId, pic, scenePoint[i].x, scenePoint[i].y, 0, index++);
	}
}

void CScene::AddWeddingGift(CUser *pLeader)
{
	if(pLeader == NULL)
		return;
	if(pLeader->GetScene() != this)
		return;
	if(m_srcSceneId != 11)
		return;
	
	// 出宝箱点
	const SPoint_int scenePoint[] = {{-100,-100},{-100,0},{-100,100},{0,100},{0,-100},{100,-100},{100,0},{100,100},{-200,-200},{-200,-100},
		{-200,0},{-200,100},{-200,200},{-100,-200},{-100,200},{0,-200},{0,200},{100,-200},{100,200},{200,-200},
		{200,-100},{200,0},{200,100},{200,200}};

	const int npcId = 232;	// 喜糖
	const int ADD_GIFT_NUM = 20;
	const int BOX_PIC = 65;
	int x = pLeader->GetX();
	int y = pLeader->GetY();

	int pointSize = sizeof(scenePoint)/sizeof(scenePoint[0]);
	int haveGiftNum = 0;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		for(list<SNpcInstance*>::iterator i = m_dynamicNpc.begin(); i != m_dynamicNpc.end(); i++)
		{
			if((*i)->id == npcId)	// 宝箱
				haveGiftNum++;
		}
	}
	if(haveGiftNum >= ADD_GIFT_NUM)
		return;

	vector<SPoint_int> canwalkPointList;
	for(int i=0;i < pointSize;i++)
	{
		if(CanWalkPos(x+scenePoint[i].x,y+scenePoint[i].y))
			canwalkPointList.push_back(scenePoint[i]);
	}
	pointSize = canwalkPointList.size();

	const int MAX_NUM = 128;
	int sequence[MAX_NUM];
	pointSize = pointSize > MAX_NUM ? MAX_NUM : pointSize;
	if(!RandomSequence(sequence,pointSize,pointSize))
        return;

	int i;
	for(i=0;i < ADD_GIFT_NUM - haveGiftNum && i < pointSize;i++)
	{
		AddNpcWithIndex(npcId,BOX_PIC,x+canwalkPointList[sequence[i]-1].x,y+canwalkPointList[sequence[i]-1].y,0,m_NPCMonSterIndex++);
		haveGiftNum++;
	}
	if(i == ADD_GIFT_NUM - haveGiftNum)
		return;
	for(int j=haveGiftNum;j < ADD_GIFT_NUM;j++)
	{
		int r = Random(1,pointSize)-1;
		AddNpcWithIndex(npcId,BOX_PIC,x+canwalkPointList[sequence[r]-1].x,y+canwalkPointList[sequence[r]-1].y,0,m_NPCMonSterIndex++);
	}
}

void CScene::ClearBangZhanBox()
{
	const int npcId = 178;	// 宝箱
	if(m_srcSceneId != BP_FIGHT_SID && m_srcSceneId != KUAFU_BZ_SID)
		return;
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	list<SNpcInstance*>::iterator t = m_dynamicNpc.begin();
	for(list<SNpcInstance*>::iterator i = m_dynamicNpc.begin(); i != m_dynamicNpc.end();)
	{
		if((*i)->id == npcId)
		{
			CNetMessage msg;
			msg.SetType(PRO_DEL_NPC);
			msg <<(*i)->id<<(*i)->index;
			BroadcastMsg(msg);

			t = i;
			i++;
			delete *t;
			m_dynamicNpc.erase(t);
		}
		else
		{
			i++;
		}
	}
	if( BP_FIGHT_SID == m_srcSceneId )
		m_NPCMonSterIndex = 100;//初始化
}

void CScene::XtmasTreeFight(int user_id,int enemy_id)    //圣诞树战斗
{
	ShareUserPtr pUser,pEnemy;
	pUser = m_onlineUser.GetUserByRoleId(user_id);
	if( pUser.get() == NULL )
		return;
	if( 0 == enemy_id )
	{
		//通过战斗力取试炼机器人
		pEnemy = GetShiLianRobotByZhandouli(pUser->GetZhanDouLi());
		if(pEnemy.get() == NULL)
			return;
	}
	else
	{
		pEnemy = m_onlineUser.GetUserByRoleId(enemy_id);
	}

	if( pEnemy.get() == NULL )
		return;
	ShareFightPtr pFight = m_fightManager.CreateFight();
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		pFight->SetFightType( CFight::EFXtmasTree );
		pFight->SetVisibleMonsterId(0);
		pFight->SetFightChooseMode();
		AddUserGroupToBattle(pFight,pUser);
		AddUserGroupToBattle(pFight,pEnemy,0);
		pFight->BeginFight(this);
	}
	m_fightManager.AddFight(pFight);
}

void CScene::XtmasBoxFight( int user_id,int enemy_id)    //圣诞宝箱战斗
{
	ShareUserPtr pUser,pEnemy;
	pUser = m_onlineUser.GetUserByRoleId(user_id);
	if( pUser.get() == NULL )
		return;
	if( 0 == enemy_id )
	{
		//通过战斗力取试炼机器人
		pEnemy = GetShiLianRobotByZhandouli(pUser->GetZhanDouLi());
		if(pEnemy.get() == NULL)
			return;
	}
	else
	{
		pEnemy = m_onlineUser.GetUserByRoleId(enemy_id);
	}

	if( pEnemy.get() == NULL )
		return;
	ShareFightPtr pFight = m_fightManager.CreateFight();
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		pFight->SetFightType( CFight::EFXtmasBox );
		pFight->SetVisibleMonsterId(0);
		pFight->SetFightChooseMode();
		AddUserGroupToBattle(pFight,pUser);
		AddUserGroupToBattle(pFight,pEnemy,0);
		pFight->BeginFight(this);
	}
	m_fightManager.AddFight(pFight);
}

void CScene::KuaFuXueLianFight(int user_id,int enemy_id)    //跨服雪莲战斗
{
	ShareUserPtr pUser,pEnemy;
	pUser = m_onlineUser.GetUserByRoleId(user_id);
	if( pUser.get() == NULL )
		return;
	if( 0 == enemy_id )
	{
		//通过战斗力取试炼机器人
		pEnemy = GetShiLianRobotByZhandouli(pUser->GetZhanDouLi());
		if(pEnemy.get() == NULL)
			return;
	}
	else
	{
		pEnemy = m_onlineUser.GetUserByRoleId(enemy_id);
	}

	if( pEnemy.get() == NULL )
		return;
	ShareFightPtr pFight = m_fightManager.CreateFight();
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		pFight->SetFightType( CFight::EFKuaFuXueLian );
		pFight->SetVisibleMonsterId(0);
		pFight->SetFightChooseMode();
		AddUserGroupToBattle(pFight,pUser);
		AddUserGroupToBattle(pFight,pEnemy,0);
		pFight->BeginFight(this);
	}
	m_fightManager.AddFight(pFight);
}

int CScene::AddXueLianNpc()
{
	if(m_srcSceneId != KUA_FU_SCENE_ID)
		return 0;
	const uint16 npc_id = 227;
	const int pos[][2]={{157,917},{162,724},{481,462},{737,371},{1059,275},
		{302,169},{394,206},{1506,371},{799,1043},{990,1139},
		{1250,1013},{1698,852},{1911,1201},{2166,1013},{1954,660 },
		{1740,488},{1630,114},{1836,149},{2312,249},{2241,350}};
	int pos_num = sizeof(pos)/sizeof(pos[0]);
	int pos_x = 0;
	int pos_y = 0;
	bool isfind = false;
	int max_random_num = 100;
	int random_num = 0;
	int index = 0;
	do
	{
		int pos_index = Random(1,pos_num);
		pos_x = pos[pos_index-1][0];
		pos_y = pos[pos_index-1][1];
		if( NULL == FindNpcByPos(pos_x,pos_y))
			isfind = true;
		++random_num;
		if( random_num >= max_random_num)
			break;
	}while( !isfind );
	if(isfind )
	{
		index  = m_NPCMonSterIndex++;
		AddNpcWithIndex(npc_id,0,pos_x,pos_y,0,index);
	}
	return index;
}
void CScene::KuaFu1vs1PreliminaryFight(int user_id,ShareUserPtr pEnemy)
{
	ShareUserPtr pUser;
	pUser = m_onlineUser.GetUserByRoleId(user_id);
	if( pUser.get() == NULL )
		return;
	ShareFightPtr pFight = m_fightManager.CreateFight();
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		pFight->SetFightType(CFight::EFKuaFu1vs1Preliminary);
		pFight->SetVisibleMonsterId(0);
		pFight->SetFightChooseMode();
		AddUserGroupToBattle(pFight,pUser);
		AddUserGroupToBattle(pFight,pEnemy,0);
		pFight->BeginFight(this);
	}
	m_fightManager.AddFight(pFight);
}

void CScene::BaoWeiZhaoFight(ShareUserPtr pUser)
{
/*
	if(pUser.get() == NULL)
		return;
	
	const int bossId = 2488;
	const float hpR = 10.0;
//	const float recoverR = 3.0;
	ShareFightPtr pFight = m_fightManager.CreateFight();
	pFight->SetFightType(CFight::EFT_BaoWeiZhanBoss);
	SMonsterInst *pInst = new SMonsterInst();
	if(pInst == NULL)
		return;
	ShareMonsterPtr ptr;
	ptr.reset(pInst);
//	if(pInst->xiang == 0)
//		pInst->xiang = Random(1,5);
	pInst->attr.maxHp = pInst->attr.maxHp*hpR;
//	pInst->recovery = pInst->recovery*recoverR;
	int curHp = GetBaoWeiZhanBossCurHp();
	if(curHp == -1)
	{
		curHp = pInst->attr.maxHp;
		SetBaoWeiZhanBossCurHp(curHp);
	}
	pInst->hp = curHp;
	pUser->SetExtData32(302,pInst->hp);
	pUser->SetExtData32(434,(uint32)GetSysTime());
	pFight->AddMonster(ptr, 3);
	AddUserGroupToBattle(pFight,pUser);
	pFight->BeginFight(this);
	m_fightManager.AddFight(pFight);
*/
}

void CScene::AddBaoWeiZhanBox()
{
	const int npcId = 238;
	const int BOX_PIC = 65;
	const int ADD_GIFT_NUM = 20;
	int haveGiftNum = 0;

	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		for(list<SNpcInstance*>::iterator i = m_dynamicNpc.begin(); i != m_dynamicNpc.end(); i++)
		{
			if((*i)->id == npcId)
				haveGiftNum++;
		}
	}
	if(haveGiftNum >= ADD_GIFT_NUM)
		return;
	for(int i=0;i < ADD_GIFT_NUM-haveGiftNum;i++)
	{
		do
		{
			uint16 x=0,y=0;
			bool same = false;
			if(GetCanWalkPos(x,y))
			{
				{
					boost::recursive_mutex::scoped_lock lk(m_mutex);
					for(list<SNpcInstance*>::iterator i = m_dynamicNpc.begin(); i != m_dynamicNpc.end(); i++)
					{
						if((*i)->x == x && (*i)->y == y)
						{
							same = true;
							break;
						}
					}
				}
				if(!same)
				{
					AddNpcWithIndex(npcId,BOX_PIC,x,y,0,m_NPCMonSterIndex++);
					break;
				}
			}
		}while(1);
	}
}

void CScene::ClearBaoWeiZhanBox()
{
	const int npcId = 238;
	ClearAllNpc(npcId);
}

void CScene::ClearAllNpc(int npcId)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	list<SNpcInstance*>::iterator t = m_dynamicNpc.begin();
	for(list<SNpcInstance*>::iterator i = m_dynamicNpc.begin(); i != m_dynamicNpc.end();)
	{
		if((*i)->id == npcId)
		{
			CNetMessage msg;
			msg.SetType(PRO_DEL_NPC);
			msg <<(*i)->id<<(*i)->index;
			BroadcastMsg(msg);

			t = i;
			i++;
			delete *t;
			m_dynamicNpc.erase(t);
		}
		else
		{
			i++;
		}
	}
}

void CScene::ResetTowers()
{
	m_towers.clear();
	TowerInfo tower;
	tower.maxHp = 20;
	tower.curHp = tower.maxHp;
	m_towers[77] = tower;
	m_towers[79] = tower;
	tower.maxHp = 30;
	tower.curHp = tower.maxHp;
	m_towers[78] = tower;
}

void CScene::MakeTowerMsg(CUser *pUser, CNetMessage &msg)
{
	uint32 now = GetSysTime();
	msg << (uint8)m_towers.size();
	CNpcManager &npcManager = SingletonNpcManager::instance();
	for (map<uint16, TowerInfo>::iterator it = m_towers.begin(); it != m_towers.end(); ++it)
	{
		TowerInfo& tower = it->second;
		uint16 lessTime = tower.cdTime > now ? tower.cdTime - now : 0;
        uint16 npcPic = it->first;
	    SNpcTemplate *pNpc = npcManager.GetNpcTemplate(it->first);
	    if (pNpc != NULL)
	    {
	    	npcPic = pNpc->pic;
	    }
		msg << (uint16)it->first << tower.curHp << tower.maxHp << lessTime << tower.ownerId << tower.ownerName<< npcPic;
	}
}

void CScene::MakeHurtRankMsg(CUser *pUser, CNetMessage &msg)
{
	msg << (uint8)m_towers.size();
	for (map<uint16, TowerInfo>::iterator it = m_towers.begin(); it != m_towers.end(); ++it)
	{
		TowerInfo& tower = it->second;
		msg << (uint8)tower.hpGuilds.size();
		for (map<int, int>::iterator git = tower.hpGuilds.begin(); git != tower.hpGuilds.end(); ++git)
		{
			CBangPai *pBangPai = SingletonCBangPaiManager::instance().FindBangPai(git->first);
			if (pBangPai == NULL)
				msg << 0 << "" << 0;
			else
				msg << git->first << pBangPai->GetName() << git->second;
		}
	}
}

bool CScene::CollectTower(CUser *pUser, uint16 towerId)
{
	uint32 now = GetSysTime();
	uint32 guildId = pUser->GetBangPai();
	int collectJifen = 2;
	int addJifen = 0;
	int ownerId = 0;
	char buf[128];
	if (guildId == 0)
		return false;
	CNetMessage msg;
	msg.SetType(PRO_BANG_ZHAN);
	msg << (uint8)9;
	CBangPai *pBangPai = SingletonCBangPaiManager::instance().FindBangPai(guildId);
	if (pBangPai == NULL)
		return false;

	CNpcManager &npcManager = SingletonNpcManager::instance();
	SNpcInstance *pNpc = npcManager.GetNpcInstance(towerId);
	if (pNpc == NULL)
		return false;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		map<uint16, TowerInfo>::iterator it = m_towers.find(towerId);
		if (it == m_towers.end())
		{
			SendSysInfo(pUser, MakeStringColor(LANGUAGE_TRANSFORM_80, TIPS_FAILURE_COLOR).c_str());
			return false;
		}

		TowerInfo& tower = it->second;
		if (guildId == tower.ownerId)
		{
			SendSysInfo(pUser, MakeStringColor(LANGUAGE_ZQX_0120, TIPS_FAILURE_COLOR).c_str());
			return false;
		}

		if (now < tower.cdTime)
		{
			snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0125, tower.ownerName.c_str());
			SendSysInfo(pUser, MakeStringColor(buf, TIPS_FAILURE_COLOR).c_str());
			return false;
		}

		tower.curHp--;
		tower.hpGuilds[guildId]++;
		int curHurt = tower.hpGuilds[guildId];
		if (curHurt > tower.maxhurt)
		{
			tower.maxhurt = curHurt;
			tower.maxId = guildId;
		}
		if (towerId == 78)
			collectJifen = 5;
		if (tower.curHp==0)
		{
			tower.cdTime = now + 60 * 3;
			tower.hpGuilds.clear();
			tower.ownerId = tower.maxId;
			ownerId = tower.ownerId;
			tower.maxId = 0;
			tower.curHp = tower.maxHp;
			tower.maxhurt = 0;
			if (towerId == 78)
				addJifen = 50;
			else
				addJifen = 30;
		}
		else if (tower.curHp == 10)
		{
			snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0119, pNpc->pNpc->name.c_str());
			SysInfoToAllUser(MakeStringColor(buf, TIPS_WARNING_COLOR).c_str());
		}
		uint16 lessTime = tower.cdTime > now ? tower.cdTime - now : 0;
		msg << (uint16)it->first << tower.curHp << tower.maxHp << lessTime << tower.ownerId;
		if (ownerId == 0)
		{
			msg << tower.ownerName;
			BroadcastMsg(msg);
		}
	}
	SingletonCBangPaiManager::instance().AddBangPaiJiFen(pUser, collectJifen);
	snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0129, pNpc->pNpc->name.c_str(), collectJifen);
	SendSysInfo(pUser, MakeStringColor(buf, TIPS_WARNING_COLOR).c_str());
	string name = "";
	if (ownerId != 0)
	{
		{
			CBangPai *zlGuild = SingletonCBangPaiManager::instance().FindBangPai(ownerId);
			if (zlGuild != NULL)
				name = zlGuild->GetName();
		}
		{
			boost::recursive_mutex::scoped_lock lk(m_mutex);
			map<uint16, TowerInfo>::iterator it = m_towers.find(towerId);
			if (it == m_towers.end())
			{
				msg << it->second.ownerName;
				BroadcastMsg(msg);
				return false;
			}
			it->second.ownerName = name;
		}
		msg << name;
		BroadcastMsg(msg);
		//SingletonCBangPaiManager::instance().AddBangPaiJiFen(ownerId, addJifen);
		snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0118, name.c_str(), pNpc->pNpc->name.c_str());
		SysInfoToAllUser(MakeStringColor(buf, TIPS_WARNING_COLOR).c_str());
		return false;
	}
	return true;
}

void CScene::CalcTowerJifen(map<int, int>& towerCnt)
{
	for (map<uint16, TowerInfo>::iterator it = m_towers.begin(); it != m_towers.end(); ++it)
	{
		if (it->second.ownerId != 0)
			towerCnt[it->second.ownerId] += 1;
	}
}

#ifdef KUA_FU
void CScene::ShenJieMiJingPVEFight(ShareUserPtr user,uint16 monsterId,bool isBoss,SVisibleMonsterBoss &boss)//神界秘境PVE
{
	CUser *pUser = user.get();
	if(pUser == NULL)
		return;
	if(m_srcSceneId != SHENJIEMIJING_SCENE_ID)
		return;
	if(pUser->GetFightId() != 0)
		return;

	CShenJieMiJingManager &shenjieMgr = SingletonCShenJieMiJingManager::instance();
	if(isBoss && !shenjieMgr.CanFight(pUser))
	{
		if((int)(pUser->GetExtData32(305)+3) <= GetSysTime())
		{
			pUser->SetExtData32(305,GetSysTime());
			SendInfoToMe(pUser,TIPS_FAILURE_COLOR,LANGUAGE_CHY_70);
		}
		return;
	}
	
	ShareFightPtr fight = m_fightManager.CreateFight();
	CFight *pFight = fight.get();
	if(pFight == NULL)
		return;
	int fightId = boss.fightId;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	uint16 level = AddUserGroupToBattle(fight,user);
	pFight->SetFightType(CFight::EFKuaFuShenJieMiJingBossPVE);
	AddMonsterByFightId(fight,fightId,level);
	int bossId = SingletonCFightCfgManager::instance().GetFirstBossId(fightId);
	if(bossId < 0)
		return;
	int maxHp = shenjieMgr.GetCurrentBossMaxHp();
	int hp = shenjieMgr.GetCurrentBossHp();
	int ratio = shenjieMgr.GetBossRatio();
	pUser->SetExtData32(302,hp);
	pUser->SetExtData32(303,bossId);
	pFight->SetMonsterHpBeforeFight(bossId,hp,maxHp,ratio,ratio);
	pFight->SetWorldMonsterFlag(bossId);

	//三类战斗普通 精英 BOSS
//	if(isBoss)//BOSS
//	{

//	}
//	else if((Random(1,100) <= 30))//30%遇到精英怪
//	{
//		pFight->SetFightType(CFight::EFKuaFuShenJieMiJingElitePVE);
//		int monsterNum = 6;
//		for(int counter = 0;counter < monsterNum; ++counter)
//		{
//			ShareMonsterPtr pShareMonster = m_monsterManager.CreateMonster(38,monsterlevel,EMTNormal);
//			if(pShareMonster.get() == NULL)
//				continue;
//			pShareMonster->name = LANGUAGE_CHY_69;
//			pShareMonster->hp = pShareMonster->maxHp;
//			pFight->AddMonster(pShareMonster,GetMonsterFightPos(counter+1));
//		}//end of for
//	}
//	else//普通
//	{
//		pFight->SetFightType(CFight::EFKuaFuShenJieMiJingNormalPVE);
//		AddShenJieMiJingWildMonsterToFight(fight,6,1,pUser,monsterId,monsterlevel);
//	}
	
	pFight->BeginFight(this);
	m_fightManager.AddFight(fight);
}


void CScene::AddShenJieMiJingWildMonsterToFight(ShareFightPtr &pFight, uint8 num, uint8 begin, CUser *pUser,uint16 monsterId,int level)
{
/*
//	bool baobao = false;
	uint16 monsterList[3] = {0};
	uint8 listNum = 0;
	uint8 i;
	if(m_monsterNum == 0)
		return;
	for(i = 0;i < m_monsterNum;i++)
	{
		if(monsterId == m_monsters[i])
			break;
	}
	if(i == m_monsterNum)
		return;
	if(i == 0)
	{
		monsterList[listNum++] = m_monsters[i];
		if(m_monsterNum >= 2)
			monsterList[listNum++] = m_monsters[i+1];
	}
	else if(i == m_monsterNum-1)
	{
		monsterList[listNum++] = m_monsters[i-1];
		monsterList[listNum++] = m_monsters[i];
	}
	else
	{
		monsterList[listNum++] = m_monsters[i-1];
		monsterList[listNum++] = m_monsters[i];
		monsterList[listNum++] = m_monsters[i+1];
	}
*/
/*
	CMonsterManager &monsterMgr = SingletonMonsterManager::instance();
	SMonsterTmpl *pMonster = monsterMgr.GetTmpl(monsterId);
	if(pMonster == NULL)
		return;

	uint16 mId = 0;
	int mainMonsterNum = 0;
	for(uint8 i=1;i <= num;i++)
	{
		if(mainMonsterNum + (num-i+1) <= num/2+1)
			mId = monsterId;
		else
		{
			if(i == 1)
				mId = monsterId;
			else
				mId = monsterList[Random(0,listNum-1)];
		}
		if(mId == monsterId)
			mainMonsterNum++;

//		ShareMonsterPtr pShareMonster = CreateWildMonsterById(pUser,baobao,mId,pFight,level);
//		if(pShareMonster.get() == NULL)
//			return;
//		pFight->AddMonster(pShareMonster,begin + GetMonsterFightPos(i) - 1);
	}
*/
}

#endif
