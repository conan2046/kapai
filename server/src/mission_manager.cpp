#include <string.h>
#include "mission_manager.h"
#include "utility.h"
#include "xml.h"
#include "script_call.h"
#include "user.h"
#include "singleton.h"
#include "pack_deal.h"
#include "call_script.h"
#include "init.h"
#include "huo_dong.h"
#include "para_def.h"

uint16 CMissionManager::HDOpenDay = 14;
uint16 CMissionManager::HDCotinueDay = 7;
void InitNewBranchMission(SMissionDoingContent &c, char** p);

static void ReadMissionToDo(vector<SMissionTodo> &missData, string &str)
{
	if(str.empty())
		return;
	
	char buf[4096];
	char subbuf[256];
	int num = 0;
	int subnum = 0;
	char *p[512];
	char *subp[20];

	strncpy(buf,str.c_str(),sizeof(buf));
	num = SplitLine(p,buf,';');
	for(int j=0;j < num;j++)
	{
		if(strlen(p[j]) == 0)
			continue;
		strncpy(subbuf,p[j],sizeof(subbuf));
		subnum = SplitLine(subp,subbuf,'-');
		SMissionTodo data;
		data.op = atoi(subp[0]);
		if(data.op == EMISS_TD_ADD_NPC || data.op == EMISS_TD_DEL_NPC)
		{
			if(subnum != 7)
			{
				cout<<">> ReadMissionToDo config error ... str="<<str<<endl;
				continue;
			}
			data.sceneId = atoi(subp[1]);
			data.posX = atoi(subp[2]);
			data.posY = atoi(subp[3]);
			data.npcId = atoi(subp[4]);
			data.npcIdx = atoi(subp[5]);
			data.direct = atoi(subp[6]);
		}
		else if(data.op == EMISS_TD_ADD_COLLECT || data.op == EMISS_TD_DEL_COLLECT)
		{
			if(subnum != 6)
			{
				cout<<">> ReadMissionToDo config error ... str="<<str<<endl;
				continue;
			}
			data.sceneId = atoi(subp[1]);
			data.posX = atoi(subp[2]);
			data.posY = atoi(subp[3]);
			data.npcId = atoi(subp[4]);
			data.npcIdx = atoi(subp[5]);
		}
		else if(data.op == EMISS_TD_TRANSPORT)
		{
			if(subnum != 4)
			{
				cout<<">> ReadMissionToDo config error ... str="<<str<<endl;
				continue;
			}
			data.sceneId = atoi(subp[1]);
			data.posX = atoi(subp[2]);
			data.posY = atoi(subp[3]);
		}
		else if (data.op == EMISS_TD_ADDTESTCARD)
		{
			if (subnum != 2)
			{
				cout << ">> ReadMissionToDo config error ... str=" << str << endl;
				continue;
			}
			data.itemNum = atoi(subp[1]);  // 持续秒数
		}
		missData.push_back(data);
	}
}

static bool ReadMissionDoingContent(SMissionDoingContent &content,string &str)
{
	if(str.empty())
		return true;

	char buf[512];
	int num = 0;
	char *p[20];

	strncpy(buf,str.c_str(),sizeof(buf));
	num = SplitLine(p,buf,'-');
	if(num < 1)
		return false;
	content.op = atoi(p[0]);
	if(content.op == EMISS_DC_DIALOG)
	{
		if(num != 6)
		{
			cout<<">> ReadMissionDoingContent config error ... str="<<str<<endl;
			return false;
		}
		content.sceneId = atoi(p[1]);
		content.posX = atoi(p[2]);
		content.posY = atoi(p[3]);
		content.npcId = atoi(p[4]);
		content.dialogId = atoi(p[5]);
		if(content.posX == 0)
			content.posX = -1;
		if(content.posY == 0)
			content.posY = -1;
	}
	else if(content.op == EMISS_DC_KILL_MONSTER)
	{
		if(num != 6)
		{
			cout<<">> ReadMissionDoingContent config error ... str="<<str<<endl;
			return false;
		}
		content.sceneId = atoi(p[1]);
		content.posX = atoi(p[2]);
		content.posY = atoi(p[3]);
		content.monsterId = atoi(p[4]);
		content.monsterNum = atoi(p[5]);
		if(content.posX == 0)
			content.posX = -1;
		if(content.posY == 0)
			content.posY = -1;
	}
	else if(content.op == EMISS_DC_MONSTER_DROP)
	{
		if(num != 7)
		{
			cout<<">> ReadMissionDoingContent config error ... str="<<str<<endl;
			return false;
		}
		content.sceneId = atoi(p[1]);
		content.posX = atoi(p[2]);
		content.posY = atoi(p[3]);
		content.monsterId = atoi(p[4]);
		content.dropRatio = atoi(p[5]);
		content.itemNum = atoi(p[6]);
		if(content.posX == 0)
			content.posX = -1;
		if(content.posY == 0)
			content.posY = -1;
	}
	else if(content.op == EMISS_DC_BUY_ITEM)
	{
		if(num != 8)
		{
			cout<<">> ReadMissionDoingContent config error ... str="<<str<<endl;
			return false;
		}
		content.sceneId = atoi(p[1]);
		content.posX = atoi(p[2]);
		content.posY = atoi(p[3]);
		content.npcId = atoi(p[4]);
		content.itemId = atoi(p[5]);
		content.itemNum = atoi(p[6]);
		content.dialogId = atoi(p[7]);
		if(content.posX == 0)
			content.posX = -1;
		if(content.posY == 0)
			content.posY = -1;
	}
	else if(content.op == EMISS_DC_KILL_BOSS)
	{
		if(num != 10)
		{
			cout<<">> ReadMissionDoingContent config error ... str="<<str<<endl;
			return false;
		}
		content.sceneId = atoi(p[1]);
		content.posX = atoi(p[2]);
		content.posY = atoi(p[3]);
		content.npcId = atoi(p[4]);
		content.fightPreDialogId = atoi(p[5]);
		content.fightId = atoi(p[6]);
		content.fightRound = atoi(p[7]);
		content.fightWinDialogId = atoi(p[8]);
		content.fightFailDialogId = atoi(p[9]);
		if(content.posX == 0)
			content.posX = -1;
		if(content.posY == 0)
			content.posY = -1;
	}
	else if(content.op == EMISS_DC_COLLECT)
	{
		if(num != 8)
		{
			cout<<">> ReadMissionDoingContent config error ... str="<<str<<endl;
			return false;
		}
		content.sceneId = atoi(p[1]);
		content.posX = atoi(p[2]);
		content.posY = atoi(p[3]);
		content.npcId = atoi(p[4]);
		content.itemNum = atoi(p[5]);
		content.collectStr = p[6];
		content.collectPic = atoi(p[7]);
		if(content.posX == 0)
			content.posX = -1;
		if(content.posY == 0)
			content.posY = -1;
	}
	else if(content.op == EMISS_DC_COPY)
	{
		if(num != 3)
		{
			cout<<">> ReadMissionDoingContent config error ... str="<<str<<endl;
			return false;
		}
		content.copyId = atoi(p[1]);
		content.copyCompleteNum = atoi(p[2]);
	}
	else if (content.op == EMISS_DC_61)
	{
		if (num != 7)
		{
			cout << ">> ReadMissionDoingContent config error ... str=" << str << endl;
			return false;
		}
		content.isum = atoi(p[1]);
		content.itemId = atoi(p[2]);
		content.sceneId = atoi(p[3]);
		content.posX = atoi(p[4]);
		content.posY = atoi(p[5]);
		content.npcId = atoi(p[6]);
		if (content.posX == 0)
			content.posX = -1;
		if (content.posY == 0)
			content.posY = -1;
	}
	else {
		// ======================
		// 新分支任务
		InitNewBranchMission(content, p);
	}
	return true;
}

void CMissionManager::UpdateQuestState(CUser* pUser, uint16 cond, int num/* = 1*/, int condex/* = 0*/)
{
	UpdateNormalQuestState(pUser, cond, num, condex);
	UpdateHDQuestState(pUser, cond, num, condex);
}

void CMissionManager::UpdateNormalQuestState(CUser* pUser, uint16 qtype, int num, int cond)
{
	vector<TypeValue>* vec = GetCondTypeIds(qtype);
	if (vec == NULL)
		return;

	for (size_t i = 0; i < vec->size(); i++)
	{
		TypeValue& tv = (*vec)[i];
		QuestCfg* cfg = GetQuestCfg(tv.value);
		if (cfg == NULL)
			continue;
		UserQuest* quest = pUser->m_missList.GetUserQuest(tv.type, tv.value);
		if (quest == NULL)
			continue;
		if (quest->num >= cfg->num || quest->state == 1)
			continue;
		if (!CheckQuestState(pUser, quest, cfg, num, cond))
			continue;
		if (quest->num >= cfg->num)
		{
			quest->num = cfg->num;
			quest->state = 1;
		}
		CNetMessage msg;
		msg.SetType(PRO_TASK_LIST);
		msg << uint8(2) << quest->id << quest->num << quest->state;
		SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);
		if (quest->state == 1 && quest->show && cfg->level <= pUser->GetLevel())
		{
			switch (tv.type)
			{
			case 1:
				SendHotPointStatus(pUser, EHPoint_Quest_1, true);
				break;
			case 2:
				SendHotPointStatus(pUser, EHPoint_Quest_2, true);
				break;
			case 3:
				SendHotPointStatus(pUser, EHPoint_Quest_3, true);
				break;
			case 4:
				SendHotPointStatus(pUser, EHPoint_Quest_4, true);
				break;
			}
		}
	}
}

void CMissionManager::UpdateHDQuestState(CUser* pUser, uint16 qtype, int num, int cond)
{
	vector<TypeValue>* vec = GetHDCondTypeIds(qtype);
	if (vec == NULL)
		return;

	for (size_t i = 0; i < vec->size(); i++)
	{
		TypeValue& tv = (*vec)[i];
		UserQuest* quest = pUser->m_missList.GetHDQuest(tv.value);
		if (quest == NULL)
			continue;
		QuestCfg* cfg = GetHDQuestCfg(tv.value);
		if (cfg == NULL)
			continue;
		//if (quest->num >= cfg->num || quest->state == 1)
		if (quest->state > 0)
			continue;
		if (!CheckQuestState(pUser, quest, cfg, num, cond))
			continue;
		if (quest->num >= cfg->num)
		{
			quest->num = cfg->num;
			quest->state = 1;
		}
		CNetMessage msg;
		msg.SetType(PRO_TASK_LIST);
		msg << uint8(5) << quest->id << quest->num << quest->state;
		SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);
		if (quest->state == 1 && quest->show && cfg->level <= pUser->GetLevel())
			SendHotPointStatus(pUser, EHPoint_HDQuest, true);
		if (quest->state == 1)
			UpdateUserRecord(pUser->GetRoleId(), ERT_QiRi, quest->id, quest->state);
	}
}

void CMissionManager::UpdateJJQuestState(CUser* pUser, uint16 qtype, int num, int cond)
{
	vector<TypeValue>* vec = GetJiJinCondTypeIds(qtype);
	if (vec == NULL)
		return;

	for (size_t i = 0; i < vec->size(); i++)
	{
		TypeValue& tv = (*vec)[i];
		QuestCfg* cfg = GetQuestCfg(tv.value);
		if (cfg == NULL)
			continue;

		UserQuest* quest = pUser->m_missList.GetJiJinQuest(cfg->type, tv.value);
		if (quest == NULL)
			continue;
		if (quest->state > 0)
			continue;
		if (!CheckQuestState(pUser, quest, cfg, num, cond))
			continue;
		if (quest->num >= cfg->num)
		{
			quest->num = cfg->num;
			quest->state = 1;
		}
		CNetMessage msg;
		msg.SetType(PRO_TASK_LIST);
		msg << uint8(8) << quest->id << quest->num << quest->state;
		SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);
		/*if (quest->state == 1 && quest->show && cfg->level <= pUser->GetLevel())
			SendHotPointStatus(pUser, EHPoint_HDQuest, true);*/
		/*if (quest->state == 1)
			UpdateUserRecord(pUser->GetRoleId(), ERT_QiRi, quest->id, quest->state);*/
	}
}

void CMissionManager::UpdateJJQuestState(CUser* pUser, uint8 type, uint16 qtype, int num, int cond)
{
	vector<TypeValue>* vec = GetJiJinCondTypeIds(qtype);
	if (vec == NULL)
		return;

	for (size_t i = 0; i < vec->size(); i++)
	{
		TypeValue& tv = (*vec)[i];
		QuestCfg* cfg = GetQuestCfg(tv.value);
		if (cfg == NULL || cfg->type != type)
			continue;

		UserQuest* quest = pUser->m_missList.GetJiJinQuest(cfg->type, tv.value);
		if (quest == NULL)
			continue;
		if (quest->state > 0)
			continue;
		if (!CheckQuestState(pUser, quest, cfg, num, cond))
			continue;
		if (quest->num >= cfg->num)
		{
			quest->num = cfg->num;
			quest->state = 1;
		}
		CNetMessage msg;
		msg.SetType(PRO_TASK_LIST);
		msg << uint8(8) << quest->id << quest->num << quest->state;
		SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);
		/*if (quest->state == 1 && quest->show && cfg->level <= pUser->GetLevel())
		SendHotPointStatus(pUser, EHPoint_HDQuest, true);*/
		/*if (quest->state == 1)
		UpdateUserRecord(pUser->GetRoleId(), ERT_QiRi, quest->id, quest->state);*/
	}
}

bool CMissionManager::CheckQuestState(CUser* pUser, UserQuest* quest, QuestCfg* cfg, int num, int cond)
{
	switch (cfg->type)
	{
	case EMQCT_1:
	case EMQCT_2:
	case EMQCT_3:
	case EMQCT_4:
	case EMQCT_5:
	case EMQCT_6:
	case EMQCT_7:
	case EMQCT_8:
	case EMQCT_9:
	case EMQCT_10:
	case EMQCT_11:
	case EMQCT_12:
	case EMQCT_13:
	case EMQCT_14:
	case EMQCT_16:
	case EMQCT_17:
	case EMQCT_18:
	case EMQCT_32:
	case EMQCT_35:
	case EMQCT_36:
	case EMQCT_40:
	case EMQCT_54:
	case EMQCT_55:
	case EMQCT_56:
	case EMQCT_59:
	case EMQCT_60:
	{// 累加型
		if (cfg->cond == (uint32)cond)
			quest->num += num;
	}
	break;

	case EMQCT_50:
	case EMQCT_46:
	case EMQCT_34:
	{// 包含累加型
		if ((uint32)cond >= cfg->cond)
			quest->num += num;
	}
	break;

	case EMQCT_33:
	case EMQCT_38:
	case EMQCT_39:
	case EMQCT_44:
	case EMQCT_47:
	case EMQCT_51:
	case EMQCT_30:
	case EMQCT_52:
	case EMQCT_31:
	case EMQCT_57:
	{// 直接算当前型
		if (quest->num > (uint32)num)
			return false;
		quest->num = num;
	}
	break;

	case EMQCT_43:
	{// 直接算当前型
		if (cfg->num < (uint32)num)
			return false;
		quest->num = cfg->num;
	}
	break;

	case EMQCT_19:
	{

	}
	break;
	case EMQCT_22:
	{

	}
	break;
	case EMQCT_23:
	{

	}
	break;
	case EMQCT_24:
	{

	}
	break;
	case EMQCT_25:
	{
		quest->num = pUser->GetPowerPetCnt(cfg->cond);
	}
	break;
	case EMQCT_26:
	{

	}
	break;
	case EMQCT_27:
	{

	}
	break;
	case EMQCT_28:
	{

	}
	break;
	case EMQCT_29:
	{

	}
	break;

	case EMQCT_37:
	{
		if ((uint32)cond > cfg->cond)
			return false;
		quest->num += num;
	}
	break;

	case EMQCT_41:
	{
		quest->num = pUser->GetQualityPetCnt(cfg->cond);
	}
	break;

	case EMQCT_20:
	{
		quest->num = pUser->GetHeroBreakNum(cfg->cond);
	}
	break;
	case EMQCT_21:
	{
		quest->num = pUser->GetHeroStarNum(cfg->cond);
	}
	break;
	case EMQCT_42:
	{
		CEquipManeger& mgr = pUser->GetPetEquipMgr();
		quest->num = mgr.GetYCLevelCnt(EST_QIANGHUA, cfg->cond);
	}
	break;

	case EMQCT_45:
	{
		CEquipManeger& mgr = pUser->GetPetEquipMgr();
		quest->num = mgr.GetYCLevelCnt(EST_JINGLIAN, cfg->cond);
	}
	break;

	case EMQCT_48:
	{
		CEquipManeger& mgr = pUser->GetPetEquipMgr();
		quest->num = mgr.GetYCLevelCnt(EST_FBQIANGHUA, cfg->cond);
	}
	break;

	case EMQCT_49:
	{
		CEquipManeger& mgr = pUser->GetPetEquipMgr();
		quest->num = mgr.GetYCLevelCnt(EST_FBJINGLIAN, cfg->cond);
	}
	break;

	default:
		return false;
	}
	return true;
}
/////////////////////////////////////////////////////////////////////////////////////

CUserMission::CUserMission()
	: m_taskValidationFixtureActive(false),
	  m_taskValidationActiveValue(0)
{

}

SAcceptMission *CUserMission::GetAcceptedCMission(int missionId)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return NoLockGetAcceptedCMission(missionId);
}

SAcceptMission *CUserMission::NoLockGetAcceptedCMission(int missionId)
{
	/*for(uint32 i=0;i < m_accept_miss.size();i++)
	{
		if(m_accept_miss[i].missId == missionId)
			return &m_accept_miss[i];
	}*/
	return NULL;
}

bool CUserMission::IsCMissionAccepted(int missionId)
{
	SAcceptMission *pMiss = GetAcceptedCMission(missionId);
	if(pMiss == NULL)
		return false;
	return true;
}

bool CUserMission::IsPreCMissionFinished(SMissionConfig &cfg)
{
	/*if(cfg.id == 0)
		return false;
	
	bool all_finish = true;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint16 i=0;i < cfg.preMissionId.size();i++)
	{
		int preMissId = cfg.preMissionId[i];
		map<int,SFinishedMission>::iterator it = m_finished_miss.find(preMissId);
		if(it == m_finished_miss.end())
		{
			all_finish = false;
			break;
		}
	}
	return all_finish;*/
	return false;
}

bool CUserMission::IsCMissionFinished(int missionId)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	SAcceptMission *pMiss = NoLockGetAcceptedCMission(missionId);
	if(pMiss == NULL)
		return false;
	if(pMiss->state == EMISS_STATE_FINISH)
		return true;
	return false;
}

bool CUserMission::IsInCMissionFinishedList(int missionId)
{
	/*map<int,SFinishedMission>::iterator it = m_finished_miss.find(missionId);
	if(it != m_finished_miss.end())
		return true;*/
	return false;
}

bool CUserMission::AddCMission(int missionId,int type,vector<int> &var,vector<string> &str)
{
	/*boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(NoLockGetAcceptedCMission(missionId) != NULL)
		return false;

	SAcceptMission miss;
	miss.missId = missionId;
	miss.state = EMISS_STATE_ACCEPT;
	miss.time = GetSysTime();
	miss.save_var.assign(var.begin(),var.end());
	miss.save_str.assign(str.begin(),str.end());
	if(type == EMISS_TYPE_MAIN)
		m_accept_miss.insert(m_accept_miss.begin(),miss);
	else
		m_accept_miss.push_back(miss);*/
	return true;
}

bool CUserMission::DelCMission(int missionId,int sock)
{
	bool success = false;
	/*SAcceptMission del_miss;
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(vector<SAcceptMission>::iterator it = m_accept_miss.begin(); it != m_accept_miss.end(); it++)
	{
		if(it->missId == missionId)
		{
			success = true;
			del_miss = *it;
			m_accept_miss.erase(it);
			break;
		}
	}

	if(success)
	{
		CNetMessage msg;
		msg.SetType(PRO_UPDATE_TASK);
		msg<<(uint8)0<<(uint16)missionId;
		SingletonSocket::instance().SendMsg(sock,msg);

		SMissionConfig *pCfg = SingletonCMissionManager::instance().GetMissionCfg(missionId);
		if(pCfg == NULL || pCfg->type == EMISS_TYPE_DAILY || pCfg->type == EMISS_TYPE_KUAFU_DAILY)
			return success;
		map<int,SFinishedMission>::iterator it = m_finished_miss.find(del_miss.missId);
		if(it == m_finished_miss.end())
		{
			SFinishedMission data;
			data.missId = del_miss.missId;
			data.time = GetSysTime();
			m_finished_miss.insert(make_pair(data.missId,data));
		}
	}*/
	return success;
}

void CUserMission::DeleteFinishMissionById(int _mid){
	//SAcceptMission del_miss;
	//boost::recursive_mutex::scoped_lock lk(m_mutex);
	//vector<SAcceptMission>::iterator it = m_accept_miss.begin();
	//for( ; it != m_accept_miss.end(); it++)
	//{
	//	if(it->missId == _mid){
	//		del_miss = *it;
	//		m_accept_miss.erase(it);
	//		break;
	//	}
	//}
}

void CUserMission::UpdateCMisstionState(int missionId,int state)
{
	//boost::recursive_mutex::scoped_lock lk(m_mutex);
	//for(uint32 i=0;i < m_accept_miss.size();i++)
	//{
	//	if(m_accept_miss[i].missId == missionId)
	//	{
	//		m_accept_miss[i].state = state;
	//		return;
	//	}
	//}
}

bool CUserMission::UpdateCMission(int missionId,vector<int> &var,vector<string> &str)
{
	//boost::recursive_mutex::scoped_lock lk(m_mutex);
	//for(uint32 i=0;i < m_accept_miss.size();i++)
	//{
	//	if(m_accept_miss[i].missId == missionId)
	//	{
	//		m_accept_miss[i].save_var.assign(var.begin(),var.end());
	//		m_accept_miss[i].save_str.assign(str.begin(),str.end());
	//		return true;
	//	}
	//}
	return false;
}

void CUserMission::GetAcceptCMissList(vector<int> &missList)
{
	/*missList.clear();
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint32 i=0;i < m_accept_miss.size();i++)
	{
		missList.push_back(m_accept_miss[i].missId);
	}*/
}

void CUserMission::UpdateAvailableCMission(vector<int> &avail_miss)
{
	//m_avail_miss = avail_miss;
}

void CUserMission::GetAvailableCMissions(vector<int> &avail_miss)
{
	avail_miss.clear();
	//avail_miss = m_avail_miss;
}

void CUserMission::DelAvailableCMission(int missId)
{
	/*for(vector<int>::iterator it = m_avail_miss.begin(); it != m_avail_miss.end(); it++)
	{
		if(*it == missId)
		{
			m_avail_miss.erase(it);
			break;
		}
	}*/
}

void CUserMission::SaveData(string &str)
{
	int pos = 0;
	uint8 data[1024 * 10] = { 0 };
	uint16 qSize = m_curQuest.size();
	pos = CopyDataToBuf((char *)data, &qSize, sizeof(qSize), pos);
	for (TypeUserQuestMapIt it = m_curQuest.begin(); it != m_curQuest.end(); ++it)
	{
		UserQuestMap& tmap = it->second;
		uint16 tSize = tmap.size();
		pos = CopyDataToBuf((char *)data, &it->first, sizeof(it->first), pos);
		pos = CopyDataToBuf((char *)data, &tSize, sizeof(tSize), pos);
		for (UserQuestMapIt tit = tmap.begin(); tit != tmap.end(); ++tit)
		{
			UserQuest& quest = tit->second;
			pos = CopyDataToBuf((char *)data, &quest.id, sizeof(quest.id), pos);
			pos = CopyDataToBuf((char *)data, &quest.num, sizeof(quest.num), pos);
			pos = CopyDataToBuf((char *)data, &quest.state, sizeof(quest.state), pos);
		}
	}

	qSize = m_hdQuest.size();
	pos = CopyDataToBuf((char *)data, &qSize, sizeof(qSize), pos);
	for (UserQuestMapIt tit = m_hdQuest.begin(); tit != m_hdQuest.end(); ++tit)
	{
		UserQuest& quest = tit->second;
		pos = CopyDataToBuf((char *)data, &quest.id, sizeof(quest.id), pos);
		pos = CopyDataToBuf((char *)data, &quest.num, sizeof(quest.num), pos);
		pos = CopyDataToBuf((char *)data, &quest.state, sizeof(quest.state), pos);
	}

	uint8 jSize = m_jinJinQuest.size();
	pos = CopyDataToBuf((char *)data, &jSize, sizeof(jSize), pos);
	for (TypeUserQuestMapIt it = m_jinJinQuest.begin(); it != m_jinJinQuest.end(); ++it)
	{
		UserQuestMap& tmap = it->second;
		uint16 tSize = tmap.size();
		pos = CopyDataToBuf((char *)data, &it->first, sizeof(it->first), pos);
		pos = CopyDataToBuf((char *)data, &tSize, sizeof(tSize), pos);
		for (UserQuestMapIt tit = tmap.begin(); tit != tmap.end(); ++tit)
		{
			UserQuest& quest = tit->second;
			pos = CopyDataToBuf((char *)data, &quest.id, sizeof(quest.id), pos);
			pos = CopyDataToBuf((char *)data, &quest.num, sizeof(quest.num), pos);
			pos = CopyDataToBuf((char *)data, &quest.state, sizeof(quest.state), pos);
		}
	}
	jSize = m_buyTime.size();
	pos = CopyDataToBuf((char *)data, &jSize, sizeof(jSize), pos);
	for (U8tU32MapIt it = m_buyTime.begin(); it != m_buyTime.end(); ++it)
	{
		pos = CopyDataToBuf((char *)data, &it->first, sizeof(it->first), pos);
		pos = CopyDataToBuf((char *)data, &it->second, sizeof(it->second), pos);
	}
	Compress(data, pos, str);
}

void CUserMission::LoadData(const char *str)
{
	if (str == NULL || strlen(str) == 0)
	{
		InitQuest();
		return;
	}
	uint32 len = 1024 * 10;
	uint8 data[1024 * 10];
	int pos = 0;
	if (!UnCompress(str, data, len))
		return;
	uint16 qSize;
	pos = ReadDataFromBuf((char *)data, &qSize, sizeof(qSize), pos);
	for (size_t fi = 0; fi < qSize; ++fi)
	{
		uint16 tSize;
		uint8 type = 0;
		pos = ReadDataFromBuf((char *)data, &type, sizeof(type), pos);
		pos = ReadDataFromBuf((char *)data, &tSize, sizeof(tSize), pos);
		UserQuestMap tmap;
		for (size_t j = 0; j < tSize; j++)
		{
			UserQuest quest;
			pos = ReadDataFromBuf((char *)data, &quest.id, sizeof(quest.id), pos);
			pos = ReadDataFromBuf((char *)data, &quest.num, sizeof(quest.num), pos);
			pos = ReadDataFromBuf((char *)data, &quest.state, sizeof(quest.state), pos);
			quest.show = false;
			tmap[quest.id] = quest;

			if (quest.state == 2)
				m_finishQuest.insert(quest.id);
		}
		m_curQuest[type] = tmap;
	}
	pos = ReadDataFromBuf((char *)data, &qSize, sizeof(qSize), pos);
	for (size_t j = 0; j < qSize; j++)
	{
		UserQuest quest;
		pos = ReadDataFromBuf((char *)data, &quest.id, sizeof(quest.id), pos);
		pos = ReadDataFromBuf((char *)data, &quest.num, sizeof(quest.num), pos);
		pos = ReadDataFromBuf((char *)data, &quest.state, sizeof(quest.state), pos);
		m_hdQuest[quest.id] = quest;
	}
	ChechNewQuest();

	uint8 jSize;
	pos = ReadDataFromBuf((char *)data, &jSize, sizeof(jSize), pos);
	for (size_t fi = 0; fi < jSize; ++fi)
	{
		uint16 tSize;
		uint8 type = 0;
		pos = ReadDataFromBuf((char *)data, &type, sizeof(type), pos);
		pos = ReadDataFromBuf((char *)data, &tSize, sizeof(tSize), pos);
		UserQuestMap tmap;
		for (size_t j = 0; j < tSize; j++)
		{
			UserQuest quest;
			pos = ReadDataFromBuf((char *)data, &quest.id, sizeof(quest.id), pos);
			pos = ReadDataFromBuf((char *)data, &quest.num, sizeof(quest.num), pos);
			pos = ReadDataFromBuf((char *)data, &quest.state, sizeof(quest.state), pos);
			quest.show = false;
			tmap[quest.id] = quest;

		}
		m_jinJinQuest[type] = tmap;
	}
	pos = ReadDataFromBuf((char *)data, &jSize, sizeof(jSize), pos);
	for (size_t fi = 0; fi < qSize; ++fi)
	{
		uint8 jtype = 0;
		uint32 buyTime = 0;
		pos = ReadDataFromBuf((char *)data, &jtype, sizeof(jtype), pos);
		pos = ReadDataFromBuf((char *)data, &buyTime, sizeof(buyTime), pos);
		m_buyTime[jtype] = buyTime;
	}
}

void CUserMission::CheckQuestShow(CUser* pUser)
{
	uint16 regDay = pUser->GetRegDay();
	CMissionManager& mgr = sCMissionManager;
	for (UserQuestMapIt tit = m_hdQuest.begin(); tit != m_hdQuest.end(); tit++)
	{
		QuestCfg* cfg = mgr.GetHDQuestCfg(tit->first);
		if (cfg == NULL) continue;
		tit->second.show = regDay >= cfg->hdcnd;
	}
	for (TypeUserQuestMapIt it = m_curQuest.begin(); it != m_curQuest.end(); ++it)
	{
		UserQuestMap& tmap = it->second;
		for (UserQuestMapIt tit = tmap.begin(); tit != tmap.end(); tit++)
		{
			QuestCfg* cfg = mgr.GetQuestCfg(tit->first);
			if (cfg == NULL) continue;
			tit->second.show = IsFinishQuest(cfg->preId);
		}
	}
}

void CUserMission::GetCMissionsFinishedList(vector<int> &missList)
{
	//missList.clear();
	//boost::recursive_mutex::scoped_lock lk(m_mutex);
	//for(map<int,SFinishedMission>::iterator it = m_finished_miss.begin(); it != m_finished_miss.end();it++)
	//{
	//	missList.push_back(it->first);
	//}
}


void CUserMission::InitQuest()
{
	CMissionManager& qmgr = sCMissionManager;
	QuestCfgMap& qMap = qmgr.GetAllQuest();
	for (QuestCfgMapIt it = qMap.begin(); it != qMap.end(); ++it)
	{
		QuestCfg& qcfg = it->second;
		UserQuest quest;
		quest.id = qcfg.id;
		quest.show = qcfg.preId == 0;
		UserQuestMap* tmap = GetUserQuestMap(qcfg.qtype);
		if (tmap != NULL)
			(*tmap)[qcfg.id] = quest;
		else
		{
			UserQuestMap tmp;
			tmp[qcfg.id] = quest;
			m_curQuest[qcfg.qtype] = tmp;
		}
	}
	CHuoDongAwardManager& hmgr = sCHuoDongAwardManager;
	if (hmgr.CheckServerOpenInDay(CMissionManager::HDOpenDay))
	{
		QuestCfgMap& qmap = qmgr.GetHDQuestMap();
		for (QuestCfgMapIt it = qmap.begin(); it != qmap.end(); ++it)
		{
			QuestCfg& qcfg = it->second;
			UserQuest quest;
			quest.id = qcfg.id;
			m_hdQuest.insert(make_pair(qcfg.id, quest));
		}
	}
}

void CUserMission::ResetQuest(CUser* pUser)
{
	CMissionManager& qmgr = sCMissionManager;
	for (TypeUserQuestMapIt ait = m_curQuest.begin(); ait != m_curQuest.end(); ++ait)
	{
		UserQuestMap& qMap = ait->second;
		for (UserQuestMapIt it = qMap.begin(); it != qMap.end(); ++it)
		{
			UserQuest& quest = it->second;
			if (qmgr.IsMeiRiQuest(quest.id))
			{
				quest.num = 0;
				quest.state = 0;
			}
		}
	}

	CHuoDongAwardManager& hmgr = sCHuoDongAwardManager;
	if (hmgr.CheckServerOpenInDay(CMissionManager::HDOpenDay))
	{
		QuestCfgMap& qmap = qmgr.GetHDQuestMap();
		for (QuestCfgMapIt it = qmap.begin(); it != qmap.end(); ++it)
		{
			QuestCfg& qcfg = it->second;
			UserQuest quest;
			quest.id = qcfg.id;
			m_hdQuest.insert(make_pair(qcfg.id, quest));
		}
	}

	for (TypeUserQuestMapIt ait = m_jinJinQuest.begin(); ait != m_jinJinQuest.end(); ++ait)
	{
		uint32 buyTime = GetBuyTime(ait->first);
		uint32 nextDay = GetTomorrow();
		uint32 nowDay = ceil((nextDay - buyTime) / (3600 * 24.0));
		qmgr.UpdateJJQuestState(pUser, ait->first, EMQCT_61, nowDay, 0);
	}

	if (pUser->GetRegDay() > CMissionManager::HDCotinueDay)
		m_hdQuest.clear();
	CheckQuestShow(pUser);
}

void CUserMission::InitJiJin(CUser* pUser, uint8 type)
{
	CMissionManager& qmgr = sCMissionManager;
	QuestCfgMap* qmap = qmgr.GetJiJinQuestMap(type);
	if (qmap == NULL)
		return;
	for (QuestCfgMapIt it = qmap->begin(); it != qmap->end(); ++it)
	{
		QuestCfg& qcfg = it->second;
		UserQuest quest;
		quest.id = qcfg.id;
		quest.num = 0;

		UserQuestMap* tmap = GetJiJinQuestMap(type);
		if (tmap != NULL)
			tmap->insert(make_pair(qcfg.id, quest));
		else
		{
			UserQuestMap tmp;
			tmp[qcfg.id] = quest;
			m_curQuest[type] = tmp;
		}
	}
	m_buyTime[type] = GetSysTime();
	qmgr.UpdateJJQuestState(pUser, type, EMQCT_61, 1, 0);
}

void CUserMission::ChechNewQuest()
{
	CMissionManager& qmgr = sCMissionManager;
	QuestCfgMap& qMap = qmgr.GetAllQuest();
	for (QuestCfgMapIt it = qMap.begin(); it != qMap.end(); ++it)
	{
		QuestCfg& qcfg = it->second;
		UserQuest quest;
		quest.id = qcfg.id;
		quest.show = qcfg.preId == 0;
		UserQuestMap* tmap = GetUserQuestMap(qcfg.qtype);
		if (tmap != NULL)
			tmap->insert(make_pair(qcfg.id, quest));
		else
		{
			UserQuestMap tmp;
			tmp[qcfg.id] = quest;
			m_curQuest[qcfg.qtype] = tmp;
		}
	}
	CHuoDongAwardManager& hmgr = sCHuoDongAwardManager;
	if (hmgr.CheckServerOpenInDay(CMissionManager::HDOpenDay))
	{
		QuestCfgMap& qmap = qmgr.GetHDQuestMap();
		for (QuestCfgMapIt it = qmap.begin(); it != qmap.end(); ++it)
		{
			QuestCfg& qcfg = it->second;
			UserQuest quest;
			quest.id = qcfg.id;
			m_hdQuest.insert(make_pair(qcfg.id, quest));
		}
	}
}

void CUserMission::ApplyTaskValidationFixture(CUser* pUser, uint32 activeValue)
{
	if (pUser == NULL)
		return;
	m_taskValidationFixtureActive = true;
	m_taskValidationActiveValue = activeValue;

	ChechNewQuest();
	CheckQuestShow(pUser);

	UserQuestMap* dailyMap = GetUserQuestMap(2);
	if (dailyMap != NULL)
	{
		for (UserQuestMapIt it = dailyMap->begin(); it != dailyMap->end(); ++it)
		{
			it->second.num = 0;
			it->second.state = 0;
			it->second.show = true;
		}

		UserQuest* claimable = GetUserQuest(2, 9);
		if (claimable != NULL)
		{
			claimable->num = 1;
			claimable->state = 1;
		}

		UserQuest* claimed = GetUserQuest(2, 12);
		if (claimed != NULL)
		{
			claimed->num = 20;
			claimed->state = 2;
			m_finishQuest.insert(claimed->id);
		}
	}

	UserQuestMap* activityMap = GetUserQuestMap(0);
	if (activityMap != NULL)
	{
		for (UserQuestMapIt it = activityMap->begin(); it != activityMap->end(); ++it)
		{
			it->second.num = activeValue;
			it->second.state = 0;
			it->second.show = true;
		}

		UserQuest* firstBox = GetUserQuest(0, 144);
		if (firstBox != NULL)
		{
			firstBox->num = activeValue;
			firstBox->state = activeValue >= 50 ? 1 : 0;
		}
	}

	pUser->SetExtData32(EData32_HuoYueDu_Day, activeValue);
}


bool CUserMission::IsFinishQuest(uint16 tid)
{
	if (tid == 0) return true;
	return m_finishQuest.find(tid) != m_finishQuest.end();
}

void CUserMission::GetQuestMessage(CUser* pUser, CNetMessage& msg)
{
	uint8 type;
	msg >> type;
	if (m_taskValidationFixtureActive && type == 0)
	{
		UserQuestMap* fixtureMap = GetUserQuestMap(0);
		if (fixtureMap != NULL)
		{
			for (UserQuestMapIt it = fixtureMap->begin(); it != fixtureMap->end(); ++it)
			{
				if (it->second.state != 2)
				it->second.num = m_taskValidationActiveValue;
			}
			UserQuest* firstBox = GetUserQuest(0, 144);
			if (firstBox != NULL && firstBox->state != 2)
			{
				firstBox->num = m_taskValidationActiveValue;
				firstBox->state = m_taskValidationActiveValue >= 50 ? 1 : 0;
			}
		}
		pUser->SetExtData32(EData32_HuoYueDu_Day, m_taskValidationActiveValue);
	}
	CMissionManager& mgr = sCMissionManager;
	UserQuestMap* qMap = GetUserQuestMap(type);
	if (qMap == NULL)
		msg << (uint16)0;
	else
	{
		uint16 lv = pUser->GetLevel();
		uint16 pos = msg.GetDataLen();
		uint16 cnt = qMap->size();
		msg << (uint16)cnt;
		cnt = 0;
		for (UserQuestMapIt it = qMap->begin(); it != qMap->end(); ++it)
		{
			UserQuest& quest = it->second;
			if (!quest.show)
				continue;
			QuestCfg * cfg = mgr.GetQuestCfg(quest.id);
			if (cfg->level > lv)
				continue;
			msg << quest.id << quest.num << quest.state;
			cnt++;
		}
		msg.WriteData(pos, &cnt, sizeof(cnt));
	}
}

void CUserMission::GetHDQuestMessage(CNetMessage& msg)
{
	msg << (uint16)m_hdQuest.size();
	for (UserQuestMapIt it = m_hdQuest.begin(); it != m_hdQuest.end(); ++it)
	{
		UserQuest& quest = it->second;
		msg << quest.id << quest.num << quest.state;
	}
}

void CUserMission::GetHDQuestAward(CUser* pUser, CNetMessage& msg)
{
	uint16 qid;
	msg >> qid;
	CMissionManager& mgr = sCMissionManager;
	QuestCfg* cfg = mgr.GetHDQuestCfg(qid);
	if (cfg == NULL)
		return;
	UserQuest* quest = GetHDQuest(qid);
	if (quest == NULL)
		return;
	if (quest->state != 1)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0205, TIPS_FAILURE_COLOR);
		return;
	}
	if (pUser->GetRegDay() < cfg->hdcnd)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0205, TIPS_FAILURE_COLOR);
		return;
	}
	quest->state = 2;
	msg << PRO_SUCCESS;
	SendAndMakeAwardMsg(pUser, cfg->awards, msg, false, MUT_RenWu);
	if (cfg->hdcnd != 0)
		mgr.UpdateQuestState(pUser, EMQCT_54);
	UpdateUserRecord(pUser->GetRoleId(), ERT_QiRi, quest->id, quest->state, true);
	SendHDQuestHotPointStatus(pUser);
}

void CUserMission::GetJiJinQuestMessage(CNetMessage& msg)
{
	uint8 type;
	msg >> type;
	uint32 buyTime = GetBuyTime(type);
	uint32 startTime = 0;
	uint32 endTime = 0;
	msg << startTime << endTime << buyTime;
	UserQuestMap* jmap = GetJiJinQuestMap(type);
	if (jmap == NULL)
	{
		msg << (uint16)0;
		return;
	}
	msg << (uint16)jmap->size();
	for (UserQuestMapIt it = jmap->begin(); it != jmap->end(); ++it)
	{
		UserQuest& quest = it->second;
		msg << quest.id << quest.num << quest.state;
	}
}

void CUserMission::GetJiJinQuestAward(CUser* pUser, CNetMessage& msg)
{
	uint16 qid;
	msg >> qid;
	CMissionManager& mgr = sCMissionManager;
	QuestCfg* cfg = mgr.GetJiJinQuestCfg(qid);
	if (cfg == NULL)
		return;
	UserQuest* quest = GetJiJinQuest(cfg->type, qid);
	if (quest == NULL)
		return;
	if (quest->state != 1)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0205, TIPS_FAILURE_COLOR);
		return;
	}
	quest->state = 2;
	msg << PRO_SUCCESS;
	SendAndMakeAwardMsg(pUser, cfg->awards, msg, false, MUT_RenWu);
	//UpdateUserRecord(pUser->GetRoleId(), ERT_QiRi, quest->id, quest->state, true);
	//SendHDQuestHotPointStatus(pUser);
}

void CUserMission::SendQuestHotPointStatus(CUser* pUser, uint8 type)
{
	uint8 qtype = 0;
	switch (type)
	{
	case EHPoint_Quest_1:
		qtype = 1;
		break;
	case EHPoint_Quest_2:
		qtype = 2;
		break;
	case EHPoint_Quest_3:
		qtype = 3;
		break;
	case EHPoint_Quest_4:
		qtype = 4;
		break;
	default:
		return;
	}

	UserQuestMap* qmap = GetUserQuestMap(qtype);
	for (UserQuestMapIt it = qmap->begin(); it != qmap->end(); ++it)
	{
		UserQuest& quest = it->second;
		if (quest.show && quest.state == 1)
			return SendHotPointStatus(pUser, type, true);
	}
	return SendHotPointStatus(pUser, type, false);
}

void CUserMission::SendHDQuestHotPointStatus(CUser* pUser)
{
	for (UserQuestMapIt it = m_hdQuest.begin(); it != m_hdQuest.end(); ++it)
	{
		UserQuest& quest = it->second;
		if (quest.show && quest.state == 1)
			return SendHotPointStatus(pUser, EHPoint_HDQuest, true);
	}
	return SendHotPointStatus(pUser, EHPoint_HDQuest, false);
}


UserQuestMap* CUserMission::GetUserQuestMap(uint8 type)
{
	TypeUserQuestMapIt it = m_curQuest.find(type);
	if (it != m_curQuest.end())
		return &it->second;

	return NULL;
}

UserQuest* CUserMission::GetUserQuest(uint8 type, uint16 id)
{
	UserQuestMap* tmap = GetUserQuestMap(type);
	if (tmap == NULL)
		return NULL;

	UserQuestMapIt it = tmap->find(id);
	if (it == tmap->end())
		return NULL;

	return &it->second;
}

UserQuestMap* CUserMission::GetJiJinQuestMap(uint8 type)
{
	TypeUserQuestMapIt it = m_jinJinQuest.find(type);
	if (it != m_jinJinQuest.end())
		return &it->second;

	return NULL;
}

UserQuest* CUserMission::GetJiJinQuest(uint8 type, uint16 id)
{
	UserQuestMap* tmap = GetJiJinQuestMap(type);
	if (tmap == NULL)
		return NULL;

	UserQuestMapIt it = tmap->find(id);
	if (it == tmap->end())
		return NULL;

	return &it->second;
}

uint32 CUserMission::GetBuyTime(uint8 type)
{
	U8tU32MapIt it = m_buyTime.find(type);
	if (it != m_buyTime.end())
	{
		return it->second;
	}
	return 0;
}

UserQuest* CUserMission::GetHDQuest(uint16 id)
{
	UserQuestMapIt it = m_hdQuest.find(id);
	if (it == m_hdQuest.end())
		return NULL;

	return &it->second;
}

void CUserMission::GetQuestAward(CUser* pUser, CNetMessage& msg)
{
	uint8 qtype;
	uint16 qid;
	msg >> qtype >> qid;
	CMissionManager& mgr = sCMissionManager;
	QuestCfg* cfg = mgr.GetQuestCfg(qid);
	if (cfg == NULL)
		return;
	UserQuest* quest = GetUserQuest(cfg->qtype, qid);
	if (quest == NULL)
		return;
	if (quest->state != 1 || cfg->level > pUser->GetLevel())
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0205, TIPS_FAILURE_COLOR);
		return;
	}
	quest->state = 2;
	msg << PRO_SUCCESS << (uint8)cfg->nextIds.size();
	m_finishQuest.insert(qid);
	for (size_t i = 0; i < cfg->nextIds.size(); i++)
	{
		uint16 nId = cfg->nextIds[i];
		QuestCfg* ncfg = mgr.GetQuestCfg(nId);
		bool found = false;
		do 
		{
			if (ncfg == NULL)
				break;
			UserQuest* nQuest = GetUserQuest(ncfg->qtype, nId);
			if (nQuest == NULL)
				break;
			nQuest->show = true;
			msg << nId << nQuest->num << nQuest->state;
			found = true;
		} while (false);
		if (!found)
			msg << (uint16)0;
	}
	SendAndMakeAwardMsg(pUser, cfg->awards, msg, false, MUT_RenWu);
	SendQuestHotPointStatus(pUser, qtype);
}


////////////////////////////////////////////////////////////////////

CMissionManager::CMissionManager()
{

}


void CMissionManager::ReadMissionConfig()
{
	vector<map<string,string> > data;
	//                     0     1         2            3               4               5             6        7           8
	const char *keys[] = {"id","name","accept_script","accept_auto","accept_npc","acceptable_desc","kind","subtype","premission_limit",
	//         9               10           11         12           13                 14         15              16               17
		"profession_limit","sex_limit","min_level","max_level","day_finished_limit","weight","accept_dialog","accept_autorun","accept_todo",
	//        18            19         20                   21         22            23              24
		"doing_target","doing_desc","finish_reward","finish_auto","finish_todo","finish_reward2","open_panel"};
	uint16 size = sizeof(keys)/sizeof(keys[0]);
	CXMLReader reader("mission_config.xml");
	if(!reader.GetAllElements(data,keys,size))
		return;

	char buf[4096];
	int num = 0;
	char *p[512];
	for(uint32 i=0;i < data.size();i++)
	{
		SMissionConfig miss;
		miss.id = atoi(data[i][keys[0]].c_str());
		miss.name = data[i][keys[1]];
		miss.accept_from_script = atoi(data[i][keys[2]].c_str());
		miss.accept_auto = atoi(data[i][keys[3]].c_str());
		
		string accept_npc = data[i][keys[4]];
		if(!accept_npc.empty())
		{
			strncpy(buf,accept_npc.c_str(),sizeof(buf));
			num = SplitLine(p,buf,'-');
			if(num == 4)
			{
				miss.accept_npc.sceneId = atoi(p[0]);
				miss.accept_npc.posX = atoi(p[1]);
				miss.accept_npc.posY = atoi(p[2]);
				miss.accept_npc.npcId = atoi(p[3]);
			}
		}

		miss.accept_desc = data[i][keys[5]];
		miss.type = atoi(data[i][keys[6]].c_str());
		miss.sub_type = atoi(data[i][keys[7]].c_str());

		string idList = data[i][keys[8]];
		if(!idList.empty())
		{
			strncpy(buf,idList.c_str(),sizeof(buf));
			num = SplitLine(p,buf,';');
			for(int j=0;j < num;j++)
				miss.preMissionId.push_back(atoi(p[j]));
		}

		miss.profession_limit = atoi(data[i][keys[9]].c_str());
		miss.sex_limit = atoi(data[i][keys[10]].c_str());
		miss.min_level = atoi(data[i][keys[11]].c_str());
		miss.max_level = atoi(data[i][keys[12]].c_str());
		miss.day_finish_times_limit = atoi(data[i][keys[13]].c_str());
		miss.weight = atoi(data[i][keys[14]].c_str());
		miss.accept_dialog = atoi(data[i][keys[15]].c_str());
		miss.accept_autorun = atoi(data[i][keys[16]].c_str());

		ReadMissionToDo(miss.accept_todo,data[i][keys[17]]);
		if(!ReadMissionDoingContent(miss.doing_content,data[i][keys[18]])){
			cout<<"=>> CMissionManager::Init()  ReadMissionDoingContent() error!!!  miss.id="<<miss.id<<endl;
		}
		miss.doing_desc = data[i][keys[19]];
		SetAwardData(miss.reward1,data[i][keys[20]]);
		miss.finish_auto = atoi(data[i][keys[21]].c_str());
		ReadMissionToDo(miss.finish_todo,data[i][keys[22]]);
		SetAwardData(miss.reward2,data[i][keys[23]]);

		string panel = data[i][keys[24]];
		if(!panel.empty())
		{
			strncpy(buf,panel.c_str(),sizeof(buf));
			num = SplitLine(p,buf,'-');
			if(num == 3)
			{
				miss.open_panel_id = atoi(p[0]);
				miss.open_panel_page = atoi(p[1]);
				miss.open_panel_index = atoi(p[2]);
			}
			else
			{
				cout<<"=>> CMissionManager::Init()  ReadMission Panel error!!!  miss.id="<<miss.id<<", panel="<<panel<<endl;
			}
		}
		
		m_missions.insert(make_pair(miss.id,miss));
	}
}

void CMissionManager::ReadMissionDialogConfig()
{
	vector<map<string,string> > data;
	//                     0      1     2      3       4      5     6      7      8
	const char *keys[] = {"dialogid","order","npcid","position","dialog","scale","speed","delay","showskip"};
	uint16 size = sizeof(keys)/sizeof(keys[0]);
	CXMLReader reader("mission_dialog.xml");
	if(!reader.GetAllElements(data,keys,size))
		return;

	for(uint32 i=0;i < data.size();i++)
	{
		SMissionDialog dialog;
		dialog.id = atoi(data[i][keys[0]].c_str());
		dialog.order = atoi(data[i][keys[1]].c_str());
		dialog.npcId = atoi(data[i][keys[2]].c_str());
		dialog.position = atoi(data[i][keys[3]].c_str());
		dialog.content = data[i][keys[4]];
		dialog.scale = atoi(data[i][keys[5]].c_str());
		dialog.speed = atoi(data[i][keys[6]].c_str());
		dialog.delay = atoi(data[i][keys[7]].c_str());
		dialog.showskip = atoi(data[i][keys[8]].c_str());

		boost::unordered_map<int,list<SMissionDialog> >::iterator it = m_dialogs.find(dialog.id);
		if(it != m_dialogs.end())
		{
			bool isadd = false;
			for(list<SMissionDialog>::iterator t=it->second.begin(); t != it->second.end(); t++)
			{
				if(dialog.order < t->order)
				{
					it->second.insert(t,dialog);
					isadd = true;
					break;
				}
			}
			if(!isadd)
				it->second.push_back(dialog);
		}
		else
		{
			list<SMissionDialog> t;
			t.push_back(dialog);
			m_dialogs.insert(make_pair(dialog.id,t));
		}
	}
}

void CMissionManager::ReadMubiaoConfig()
{
	//                       0        1         2           3          4          5
	const char *keys[] = { "idx", "minlevel", "maxlevel", "missid", "awards", "title" };
	vector<map<string, string> > data;
	uint16 size = sizeof(keys) / sizeof(keys[0]);
	CXMLReader reader("doushen_config.xml");
	if (!reader.GetAllElements(data, keys, size))
		return;

	for (uint32 i = 0; i < data.size(); i++)
	{
		StageTarget stage;
		missMap& misss = stage.missIds;
		misss.clear();
		stage.idx = (uint8_t)atoi(data[i][keys[0]].c_str());
		stage.minlevel = (uint8_t)atoi(data[i][keys[1]].c_str());
		stage.maxlevel = (uint8_t)atoi(data[i][keys[2]].c_str());
		stage.title = data[i][keys[5]];

		// 任务列表
		vector<std::string> missIds;
		if (!SplitString(data[i][keys[3]], missIds, ';'))
			continue;

		for (size_t mi = 0; mi < missIds.size(); mi++)
		{
			uint16 mid = atoi(missIds[mi].c_str());
			misss[mid] = 0;
		}

		// 奖励列表
		SetAwardData(stage.awards, data[i][keys[4]]);
		m_allStages.insert(make_pair(stage.idx, stage));
	}
}

bool CMissionManager::InitQuestCfg()
{
	{
		const string file = "daily.json";
		//                            0     1        2       3         4           5        6
		const char* titleArrs[] = { "id", "type", "daily", "show", "condition", "reward", "level" };
		const int typeArrs[] = { 0, 0, 0, 0, 2, 2 };  // 0-int 1-string 2-array
		rapidjson::Document d;
		rapidjson::Value _para;
		if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
		{
			cout << "CMissionManager::InitQuestCfg >> LoadJosnValue daily.json error " << endl;
			return false;
		}
		for (uint32 i = 0; i < _para.Size(); i++)
		{
			const rapidjson::Value &data = _para[i];
			QuestCfg cfg;
			cfg.id = data[titleArrs[0]].GetInt();
			cfg.qtype = data[titleArrs[1]].GetInt();
			uint8 meiRi = data[titleArrs[2]].GetInt();
			cfg.preId = data[titleArrs[3]].GetInt();
			cfg.level = data.HasMember(titleArrs[6]) ? data[titleArrs[6]].GetInt() : 0;
			const rapidjson::Value &condArr = data[titleArrs[4]];
			uint8 cSize = condArr.Size();
			if (cSize < 2)
				continue;
			cfg.type = condArr[0].GetInt();
			cfg.num = condArr[1].GetInt();
			if (cSize > 2)
				cfg.cond = condArr[2].GetInt();
			if (cSize > 3)
				cfg.condex = condArr[3].GetInt();
			ReadMultiAward(data[titleArrs[5]], cfg.awards);
			m_questCfg[cfg.id] = cfg;
			if (meiRi == 1)
				m_meiRiIds[cfg.id] = meiRi;
			QuestCfgMap* qMap = GetTypeQuest(cfg.qtype);
			if (qMap != NULL)
				(*qMap)[cfg.id] = cfg;
			else
			{
				QuestCfgMap tmp;
				tmp[cfg.id] = cfg;
				m_typeQuestCfg[cfg.qtype] = tmp;
			}
			TypeValue tv;
			tv.type = cfg.qtype;
			tv.value = cfg.id;
			vector<TypeValue>* vec = GetCondTypeIds(cfg.type);
			if (vec != NULL)
				vec->push_back(tv);
			else
			{
				vector<TypeValue> tmp;
				tmp.push_back(tv);
				m_condTypeIds[cfg.type] = tmp;
			}
			if (cfg.preId > 0)
			{
				QuestCfg* preCfg = GetQuestCfg(cfg.preId);
				if (preCfg != NULL)
					preCfg->nextIds.push_back(cfg.id);
			}
		}
	}

	{
		const string file = "sevendays.json";
		//                            0     1        2           3
		const char* titleArrs[] = { "id", "time", "condition", "reward" };
		const int typeArrs[] = { 0, 0, 2, 2 };  // 0-int 1-string 2-array
		rapidjson::Document d;
		rapidjson::Value _para;
		if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
		{
			cout << "CHuodongCfgManager::InitHuoDongQuest >> LoadJosnValue sevendays.json error " << endl;
			return false;
		}
		for (uint32 i = 0; i < _para.Size(); i++)
		{
			const rapidjson::Value &data = _para[i];
			QuestCfg cfg;
			cfg.id = data[titleArrs[0]].GetInt();
			cfg.hdcnd = data[titleArrs[1]].GetInt();
			const rapidjson::Value &condArr = data[titleArrs[2]];
			uint8 cSize = condArr.Size();
			if (cSize < 2)
				continue;
			cfg.type = condArr[0].GetInt();
			cfg.num = condArr[1].GetInt();
			if (cSize > 2)
				cfg.cond = condArr[2].GetInt();
			ReadMultiAward(data[titleArrs[3]], cfg.awards);
			m_hdQuestCfg[cfg.id] = cfg;

			QuestCfgMap* qMap = GetDayQuestMap(cfg.hdcnd);
			if (qMap != NULL)
				(*qMap)[cfg.id] = cfg;
			else
			{
				QuestCfgMap tmp;
				tmp[cfg.id] = cfg;
				m_hdDayQuestCfg[cfg.hdcnd] = tmp;
			}
			TypeValue tv;
			tv.type = cfg.type;
			tv.value = cfg.id;
			vector<TypeValue>* vec = GetHDCondTypeIds(tv.type);
			if (vec != NULL)
				vec->push_back(tv);
			else
			{
				vector<TypeValue> tmp;
				tmp.push_back(tv);
				m_hdCondTypeIds[tv.type] = tmp;
			}
		}
	}
	return true;
}

bool CMissionManager::InitJiJinCfg()
{
	//const string file = "jijin.json";

	////                             0       1         2         3           4
	//const char* titleArrs[] = { "type", "sub_id", "reward", "contidion", "id" };
	//const int typeArrs[] = { EJPT_INT, EJPT_INT, EJPT_ARRAY, EJPT_ARRAY, EJPT_INT };  // 0-int 1-string 2-array
	//rapidjson::Document d;
	//rapidjson::Value _para;
	//if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
	//{
	//	cout << "CMissionManager::InitJiJinCfg >> LoadJosnValue error " << endl;
	//	return false;
	//}

	//for (uint32 i = 0; i < _para.Size(); i++)
	//{
	//	const rapidjson::Value &data = _para[i];
	//	QuestCfg cfg;
	//	cfg.id = data[titleArrs[4]].GetInt();
	//	cfg.qtype = data[titleArrs[0]].GetInt();
	//	const rapidjson::Value &condArr = data[titleArrs[3]];
	//	uint8 cSize = condArr.Size();
	//	if (cSize < 2)
	//		continue;
	//	cfg.type = condArr[0].GetInt();
	//	cfg.num = condArr[1].GetInt();
	//	if (cSize > 2)
	//		cfg.cond = condArr[2].GetInt();
	//	ReadMultiAward(data[titleArrs[2]], cfg.awards);
	//	m_jjQuestCfg[cfg.id] = cfg;

	//	QuestCfgMap* qMap = GetJiJinQuestMap(cfg.qtype);
	//	if (qMap != NULL)
	//		(*qMap)[cfg.id] = cfg;
	//	else
	//	{
	//		QuestCfgMap tmp;
	//		tmp[cfg.id] = cfg;
	//		m_jjTypeQuestCfg[cfg.qtype] = tmp;
	//	}
	//	TypeValue tv;
	//	tv.type = cfg.type;
	//	tv.value = cfg.id;
	//	vector<TypeValue>* vec = GetJiJinCondTypeIds(tv.type);
	//	if (vec != NULL)
	//		vec->push_back(tv);
	//	else
	//	{
	//		vector<TypeValue> tmp;
	//		tmp.push_back(tv);
	//		m_jjCondTypeIds[tv.type] = tmp;
	//	}
	//}
	return true;
}

bool CMissionManager::Init()
{
	gyu::util::TimePrint t("CMissionManager::Init()");
//	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_missions.clear();
	m_dialogs.clear();
	m_allStages.clear();
	m_questCfg.clear();
	m_typeQuestCfg.clear();

	/*ReadMissionConfig();
	ReadMissionDialogConfig();
	ReadMubiaoConfig();*/
	m_questCfg.clear();
	return InitQuestCfg() &&
		InitJiJinCfg();
}

SMissionConfig* CMissionManager::GetMissionCfg(int missId)
{
	boost::unordered_map<int,SMissionConfig>::iterator it = m_missions.find(missId);
	if(it != m_missions.end())
		return &it->second;
	return NULL;
}

list<SMissionDialog> *CMissionManager::GetDialogCfg(int dialogId)
{
	boost::unordered_map<int,list<SMissionDialog> >::iterator it = m_dialogs.find(dialogId);
	if(it != m_dialogs.end())
		return &it->second;
	return NULL;
}

int CMissionManager::GetDialogCfgMaxNum(int dialogId)
{
	boost::unordered_map<int,list<SMissionDialog> >::iterator it = m_dialogs.find(dialogId);
	if(it != m_dialogs.end())
		return it->second.size();
	return 0;
}

SMissionDialog *CMissionManager::GetDialogString(int dialogId,int idx)
{
	list<SMissionDialog> *plist = GetDialogCfg(dialogId);
	if(plist == NULL)
		return NULL;
	int count = -1;
	for(list<SMissionDialog>::iterator it = plist->begin(); it != plist->end(); it++)
	{
		count++;
		if(count == idx)
			return &(*it);
	}
	return NULL;
}

// 前端下载可接任务 
void CMissionManager::SendAvailableCMissionList(CUser *pUser)
{
	if(pUser == NULL)
		return;

	int lv = pUser->GetLevel();
	bool haveMain = HaveMainCMission(pUser);
	SMissionConfig nextMainCfg;
	vector<int> avail_list;
	// 主线
	for(boost::unordered_map<int,SMissionConfig>::iterator it=m_missions.begin();it != m_missions.end(); it++)
	{
		SMissionConfig &cfg = it->second;
		if(cfg.type == EMISS_TYPE_MAIN)
		{
			if(lv >= cfg.min_level && lv <= cfg.max_level)
			{
				if(CheckCMissionCanAccepted(pUser,cfg))
				{
					if(cfg.accept_auto == EMISS_AUTO_ACCEPT)
					{
						AcceptCMission(pUser,cfg);
					}
					else
					{
						avail_list.push_back(it->second.id);
					}
				}
			}
			else if(lv < cfg.min_level)	// 下一个等级主线任务
			{
				if(!haveMain && IsNextMainCMission(pUser,cfg))
				{
					haveMain = true;
					nextMainCfg = cfg;
				}
			}
		}
	}
	// 支线
	for(boost::unordered_map<int,SMissionConfig>::iterator it=m_missions.begin();it != m_missions.end(); it++)
	{
		SMissionConfig &cfg = it->second;
		if(cfg.type == EMISS_TYPE_BRANCH)
		{
			if(lv >= cfg.min_level && lv <= cfg.max_level)
			{
				if(CheckCMissionCanAccepted(pUser,cfg) )
				{
					if(cfg.accept_auto == EMISS_AUTO_ACCEPT)
					{
						AcceptCMission(pUser,cfg);
					}
					else
					{
						avail_list.push_back(it->second.id);
					}
				}
			}
		}
	}
	// 日常
	for(boost::unordered_map<int,SMissionConfig>::iterator it=m_missions.begin();it != m_missions.end(); it++)
	{
		SMissionConfig &cfg = it->second;
		if(cfg.type == EMISS_TYPE_DAILY || cfg.type == EMISS_TYPE_KUAFU_DAILY)
		{
			if(lv >= cfg.min_level && lv <= cfg.max_level)
			{
				if(CheckCMissionCanAccepted(pUser,cfg))
				{
					if(cfg.sub_type == EMISS_STYPE_ShiMen)
					{
						if ((cfg.id == MISSION_ID_ZhouRiChang && pUser->GetExtData8(619) >= 7)
						 || (cfg.id == MISSION_ID_ShiMen && pUser->GetSaveVal(2) >= 10))
								continue;
					}
					else if(cfg.sub_type == EMISS_STYPE_YunBiao)
					{

					}
					else if(cfg.sub_type == EMISS_STYPE_CangBaoTu)
					{
						if(pUser->GetExtData32(444) >= 10)
							continue;
					}
					else if(cfg.sub_type == EMISS_STYPE_ShaDiDuoBao)
					{
						if(pUser->GetExtData16(39) >= 5)
							continue;
					}
					else if(cfg.sub_type == EMISS_STYPE_ZhuoGui)
					{
						if (pUser->GetExtData16(50) >= TASK_MAX_LIMIT)
							continue;
					}
					else if(cfg.sub_type == EMISS_STYPE_DanYuan)
					{
						if(pUser->GetExtData8(101) >= 10)
							continue;
					}
					else if(cfg.sub_type == EMISS_STYPE_HuSongShenJiang)
					{
//						if(pUser->GetExtData8(81) >= 5)
						continue;
					}
					else if (cfg.sub_type == EMISS_STYPE_KuaFuRiChang)
					{
						if (!CanGetKuaFuInfo() || pUser->GetExtData8(641) >= MISSION_MAX_CNT_KuaFuShilian)
							continue;
					}

					
					if(cfg.accept_auto == EMISS_AUTO_ACCEPT)
					{
						AcceptCMission(pUser,cfg);
					}
					else
					{
						avail_list.push_back(it->second.id);
					}
				}
			}
		}
	}
	
	pUser->m_missList.UpdateAvailableCMission(avail_list);

	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(PRO_AVAILABLE_TASK);
	msg<<(uint8)4;
	msg<<(uint8)avail_list.size();
	for(uint8 i = 0; i < avail_list.size(); i++)
		msg<<(uint16)avail_list[i];
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);

	CNetMessage nextMsg;
	nextMsg.ReWrite();
	nextMsg.SetType(PRO_AVAILABLE_TASK);
	nextMsg<<(uint8)3<<(uint16)nextMainCfg.id<<(uint8)EMISS_TYPE_MAIN;
	if(nextMainCfg.id > 0)
	{
		char buf[256];
		snprintf(buf,sizeof(buf),LANGUAGE_SSJ_1014,nextMainCfg.min_level);
		nextMsg<<nextMainCfg.name<<buf<<"-1,100";
	}
	else
	{
		nextMsg<<""<<""<<"";
	}
	SingletonSocket::instance().SendMsg(pUser->GetSock(),nextMsg);
}

void CMissionManager::SendAvailableCMissionInfo(CUser *pUser,int missId)
{
	if(pUser == NULL || missId <= 0){
		return;
	}
	boost::unordered_map<int,SMissionConfig>::iterator it = m_missions.find(missId);
	if(it == m_missions.end()){
		cout<<"CMissionManager SendAvailableCMissionInfo  m_missions is not find missid ="<<missId << endl;
		return;
	}

	char buf[256];
	SMissionConfig &cfg = it->second;
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(PRO_AVAILABLE_TASK);
	msg<<(uint8)5;
	msg<<(uint16)missId<<(uint8)cfg.type;
	if(cfg.type == EMISS_TYPE_DAILY || cfg.type == EMISS_TYPE_KUAFU_DAILY)
	{
		if (cfg.sub_type == EMISS_STYPE_ShiMen)
		{
			int val = 0;
			if (cfg.id == MISSION_ID_ZhouRiChang)
			{
				val = pUser->GetExtData8(616);
			}
			else
			{
				val = pUser->GetSaveVal(2);
			}
			snprintf(buf, sizeof(buf), "%s(%d/%d)", cfg.name.c_str(), val, 10);
		}
		else if (cfg.sub_type == EMISS_STYPE_YunBiao)
			snprintf(buf, sizeof(buf), "%s", cfg.name.c_str());
		else if (cfg.sub_type == EMISS_STYPE_CangBaoTu)
			snprintf(buf, sizeof(buf), "%s(%d/%d)", cfg.name.c_str(), pUser->GetExtData32(444), 10);
		else if (cfg.sub_type == EMISS_STYPE_ShaDiDuoBao)
			snprintf(buf, sizeof(buf), "%s(%d/%d)", cfg.name.c_str(), pUser->GetExtData16(39), 5);
		else if (cfg.sub_type == EMISS_STYPE_ZhuoGui)
			snprintf(buf, sizeof(buf), "%s(%d/%d)", cfg.name.c_str(), pUser->GetExtData16(50) % 10, 10);
		else if (cfg.sub_type == EMISS_STYPE_DanYuan)
			snprintf(buf, sizeof(buf), "%s(%d/%d)", cfg.name.c_str(), (int)pUser->GetExtData8(101), 10);
		else if (cfg.sub_type == EMISS_STYPE_HuSongShenJiang)
			snprintf(buf, sizeof(buf), "%s(%d/%d)", cfg.name.c_str(), (int)pUser->GetExtData8(81), 5);
		else if (cfg.sub_type == EMISS_STYPE_KuaFuRiChang)
			if (CanGetKuaFuInfo())
				snprintf(buf, sizeof(buf), "%s(%d/%d)", cfg.name.c_str(), pUser->GetExtData8(641), MISSION_MAX_CNT_KuaFuShilian);
			else
				return;
		else
			snprintf(buf,sizeof(buf),"%s",cfg.name.c_str());
		msg<<buf;
	}
	else
	{
		msg<<cfg.name;
	}

	snprintf(buf,sizeof(buf),"%d,%d,%d,%d",cfg.accept_npc.sceneId,cfg.accept_npc.posX,cfg.accept_npc.posY,cfg.accept_npc.npcId);
//	cout<<"CMissionManager SendAvailableCMissionInfo = "<<buf<<endl;
	msg<<cfg.accept_desc<<buf;
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void CMissionManager::SendCMissionTrackMsg(CUser *pUser,int missId)
{
	if(pUser == NULL)
		return;
	boost::unordered_map<int,SMissionConfig>::iterator it = m_missions.find(missId);
	if(it == m_missions.end())
		return;
	SAcceptMission *pMiss = pUser->m_missList.GetAcceptedCMission(missId);
	if(pMiss == NULL)
		return;

	SMissionConfig &cfg = it->second;
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_TASK_TRACK);
	msg<<(uint16)missId<<(uint8)pMiss->state<<(uint8)cfg.type;
	if(cfg.type == EMISS_TYPE_MAIN || cfg.type == EMISS_TYPE_BRANCH)
	{
		SMissionDoingContent &con = cfg.doing_content;
		vector<SReplaceStringData> replace;
		if(con.op == EMISS_DC_DIALOG)
		{
			replace.push_back(SReplaceStringData("<name>",GetNpcTmplName(con.npcId)));
		}
		else if(con.op == EMISS_DC_KILL_MONSTER)
		{
			replace.push_back(SReplaceStringData("<name>",GetMonsterName(con.monsterId)));
			replace.push_back(SReplaceStringData("<num>",IntToStr(pMiss->save_var[0]).c_str()));
			replace.push_back(SReplaceStringData("<maxnum>",IntToStr(con.monsterNum).c_str()));
		}
		else if(con.op == EMISS_DC_MONSTER_DROP)
		{
			replace.push_back(SReplaceStringData("<name>",GetMonsterName(con.monsterId)));
			replace.push_back(SReplaceStringData("<num>",IntToStr(pMiss->save_var[0]).c_str()));
			replace.push_back(SReplaceStringData("<maxnum>",IntToStr(con.itemNum).c_str()));
		}
		else if(con.op == EMISS_DC_BUY_ITEM)
		{
			replace.push_back(SReplaceStringData("<name>",GetNpcTmplName(con.npcId)));
			replace.push_back(SReplaceStringData("<item>",GetItemName(con.itemId)));
			replace.push_back(SReplaceStringData("<num>",IntToStr(pMiss->save_var[0]).c_str()));
			replace.push_back(SReplaceStringData("<maxnum>",IntToStr(con.itemNum).c_str()));
		}
		else if(con.op == EMISS_DC_KILL_BOSS)
		{
			replace.push_back(SReplaceStringData("<name>",GetNpcTmplName(con.npcId)));
		}
		else if(con.op == EMISS_DC_COLLECT)
		{
			replace.push_back(SReplaceStringData("<name>",GetNpcTmplName(con.npcId)));
			replace.push_back(SReplaceStringData("<num>",IntToStr(pMiss->save_var[0]).c_str()));
			replace.push_back(SReplaceStringData("<maxnum>",IntToStr(con.itemNum).c_str()));
		}
		else if(con.op == EMISS_DC_COPY)
		{
			replace.push_back(SReplaceStringData("<name>",GetFuBenName(con.copyId)));
			replace.push_back(SReplaceStringData("<num>",IntToStr(pMiss->save_var[0]).c_str()));
			replace.push_back(SReplaceStringData("<maxnum>",IntToStr(con.copyCompleteNum).c_str()));
		}
		else
		{
			VerifyNewBranchMissionComplate(pUser, con, pMiss);
			SendNewBranchTrackMsg(con, pMiss, replace);
		}
		
		string tarString;
		ReplaceString(cfg.doing_desc,tarString,replace);
		string content = cfg.name + "|" + tarString + ((pMiss->state == EMISS_STATE_ACCEPT) ? "|0" : "|1");
		msg<<content;

		if(con.op == EMISS_DC_DIALOG)
			msg<<(uint8)EMISS_TT_NPC<<(uint32)con.npcId<<(uint16)con.sceneId<<con.posX<<con.posY;
		else if(con.op == EMISS_DC_KILL_MONSTER)
			msg<<(uint8)EMISS_TT_MONSTER<<(uint32)con.monsterId<<(uint16)con.sceneId<<con.posX<<con.posY;
		else if(con.op == EMISS_DC_MONSTER_DROP)
			msg<<(uint8)EMISS_TT_MONSTER<<(uint32)con.monsterId<<(uint16)con.sceneId<<con.posX<<con.posY;
		else if(con.op == EMISS_DC_BUY_ITEM)
		{
			if(pMiss->state == EMISS_STATE_ACCEPT)
				msg<<(uint8)EMISS_TT_NPC<<(uint32)9<<(uint16)11<<2398<<1172; // 药店老板
			else if(pMiss->state == EMISS_STATE_FINISH)
				msg<<(uint8)EMISS_TT_NPC<<(uint32)con.npcId<<(uint16)con.sceneId<<con.posX<<con.posY;
		}
		else if(con.op == EMISS_DC_KILL_BOSS)
		{
			msg<<(uint8)EMISS_TT_NPC<<(uint32)con.npcId<<(uint16)con.sceneId<<con.posX<<con.posY;
		}
		else if(con.op == EMISS_DC_COLLECT)
		{
			msg<<(uint8)EMISS_TT_NPC<<(uint32)con.npcId<<(uint16)con.sceneId<<-1<<-1;
		}
		else if (con.op == EMISS_DC_61)
		{
			if (pMiss->state == EMISS_STATE_ACCEPT)
			{
				msg << (uint8)EMISS_TT_NPC << con.npcId << (uint16)con.sceneId << con.posX << con.posY;
			}
			else if (pMiss->state == EMISS_STATE_FINISH)
			{
				if (cfg.finish_auto == EMISS_FINISH_AUTO)
				{
					FinishCMission(pUser, missId);
					return;  // 流程截断
				}
				else
				{
					msg << (uint8)EMISS_TT_AWARD << cfg.open_panel_id << cfg.open_panel_page << cfg.open_panel_index;
				}
			}
		}
		else
		{
			if(!pUser->IsCMissionFinished(missId))
			{
				msg<<(uint8)EMISS_TT_PANCL<<cfg.open_panel_id<<cfg.open_panel_page<<cfg.open_panel_index;
			}
			else
			{
				if(cfg.finish_auto == EMISS_FINISH_AUTO)
				{
					FinishCMission(pUser, missId);
					return;  // 流程截断
				}
				else
				{
					msg<<(uint8)EMISS_TT_AWARD<<cfg.open_panel_id<<cfg.open_panel_page<<cfg.open_panel_index;
				}
			}
		}
	}
	else if(cfg.type == EMISS_TYPE_DAILY || cfg.type == EMISS_TYPE_KUAFU_DAILY)
	{
		vector<SReplaceStringData> replace;
		string tarString;
		if(cfg.sub_type == EMISS_STYPE_ShiMen)
		{
			if(pMiss->save_var.empty())
				return;
			char buf[256];
			int curTimes = 0;
			if (cfg.id == MISSION_ID_ZhouRiChang)
				curTimes = pUser->GetExtData8(616) + 1;
			else if (cfg.id == MISSION_ID_ShiMen)
				curTimes = pUser->GetSaveVal(2) + 1;
			int maxTimes = 10;
			int type = pMiss->save_var[0];
			if(type == 1)	// 杀怪
			{
				int monId = pMiss->save_var[1];
				int pic = 0;
				string bossName;
				if(!SingletonMonsterBossManager::instance().GetMonsterBossInfo(monId,pic,bossName))
					return;
				snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0456,curTimes,maxTimes,bossName.c_str(),pMiss->save_var[3],pMiss->save_var[2]);
				string content = cfg.name + buf;
				content += ((pMiss->state == EMISS_STATE_ACCEPT) ? "|0" : "|1");
				msg<<content;

				if(pMiss->state == EMISS_STATE_ACCEPT)
					msg<<(uint8)EMISS_TT_MONSTER<<(uint32)monId<<(uint16)GetMonsterFindPathSidById(monId)<<-1<<-1;
				else
					msg<<(uint8)EMISS_TT_NPC<<(uint32)GetCMissionBackNpcId(cfg.id) <<(uint16)11<<-1<<-1;
			}
			else if(type == 2)	// 买药
			{
				int itemId = pMiss->save_var[1];
				snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0457,curTimes,maxTimes,pMiss->save_var[2],GetItemName(itemId));
				string content = cfg.name + buf;
				content += ((pMiss->state == EMISS_STATE_ACCEPT) ? "|0" : "|1");
				msg<<content;
				if(pMiss->state == EMISS_STATE_ACCEPT)
					msg<<(uint8)EMISS_TT_NPC<<(uint32)9<<(uint16)11<<-1<<-1; // 药店老板
				else if (pMiss->state == EMISS_STATE_FINISH)
				{
					msg << (uint8)EMISS_TT_NPC << (uint32)GetCMissionBackNpcId(cfg.id) << (uint16)11 << -1 << -1;
				}
			}
			else if(type == 3)	// 送信
			{
				int npcId = pMiss->save_var[1];
				int diaIdx = pMiss->save_var[2];
				snprintf(buf,sizeof(buf),((diaIdx == 1) ? LANGUAGE_SSJ_0458 : LANGUAGE_SSJ_0459),curTimes,maxTimes,GetNpcName(npcId));
				string content = cfg.name + buf;
				content += ((pMiss->state == EMISS_STATE_ACCEPT) ? "|0" : "|1");
				msg<<content;
				msg<<(uint8)EMISS_TT_NPC<<(uint32)npcId<<(uint16)11<<-1<<-1;
			}
			else if(type == 4)	// 杀叛徒
			{
				int npcId = pMiss->save_var[1];
				int sceneId = pMiss->save_var[2];
				snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0460,curTimes,maxTimes);
				string content = cfg.name + buf;
				content += ((pMiss->state == EMISS_STATE_ACCEPT) ? "|0" : "|1");
				msg<<content;
				if(pMiss->state == EMISS_STATE_ACCEPT)
					msg<<(uint8)EMISS_TT_NPC<<(uint32)npcId<<(uint16)sceneId<<-1<<-1;
				else
					msg<<(uint8)EMISS_TT_NPC<<(uint32)GetCMissionBackNpcId(cfg.id)<<(uint16)11<<-1<<-1;
			}
		}
		else if(cfg.sub_type == EMISS_STYPE_YunBiao)
		{
		}
		else if(cfg.sub_type == EMISS_STYPE_CangBaoTu)
		{
			int sceneId = pMiss->save_var[0];
			int npcId = pMiss->save_var[1]; // 怪物id
			const char * scenename = GetSceneName(sceneId);
			const char * monsternmae = GetNpcName(npcId);
			replace.push_back(SReplaceStringData("<mapname>", scenename));
			replace.push_back(SReplaceStringData("<name>", monsternmae));
			ReplaceString(cfg.doing_desc, tarString, replace);
			
			char timesDesc[128];
			if(pMiss->state == EMISS_STATE_ACCEPT)
				snprintf(timesDesc,sizeof(timesDesc),"(%d/%d)|",pUser->GetExtData32(444)+1, 10);
			else
				snprintf(timesDesc,sizeof(timesDesc),"(%d/%d)|",pUser->GetExtData32(444), 10);
			string content = cfg.name + timesDesc + tarString;
			content += ((pMiss->state == EMISS_STATE_ACCEPT) ? "|0" : "|1");
			msg<<content;
			if(pMiss->state == EMISS_STATE_ACCEPT){
				msg<<(uint8)EMISS_TT_NPC<<(uint32)npcId<<(uint16)sceneId<<-1<<-1;
			}
			else{
				msg<<(uint8)EMISS_TT_NPC<<(uint32)307<<(uint16)11<<-1<<-1;
			}
		}
		else if(cfg.sub_type == EMISS_STYPE_ZhuoGui)
		{
			uint16 sceneId = GetMonsterFindPathSidById(pMiss->save_var[3]);
			const char * scenename = GetSceneName(sceneId);
			replace.push_back(SReplaceStringData("<scene>", scenename));
			replace.push_back(SReplaceStringData("<name>", pMiss->save_str[0].c_str()));
			//replace.push_back(SReplaceStringData("<num>",IntToStr(pMiss->save_var[0]).c_str()));

			ReplaceString(cfg.doing_desc,tarString,replace);
			char timesDesc[128];
			int curTimes = pUser->GetExtData16(50) % 10;
			if (pMiss->state == EMISS_STATE_ACCEPT)
				curTimes++;
			snprintf(timesDesc, sizeof(timesDesc), "(%d/%d)", curTimes, 10);
			string content = cfg.name + timesDesc + "|" + tarString + ((pMiss->state == EMISS_STATE_ACCEPT) ? "|0" : "|1");
			msg<<content;
			msg<<(uint8)EMISS_TT_MONSTER<<(uint32)pMiss->save_var[3]<<sceneId<<-1<<-1;
		}
		else if(cfg.sub_type == EMISS_STYPE_DanYuan){
			
			int type = pMiss->save_var[0];
			int curTimes = pUser->GetExtData8(101)+1;
			int maxTimes = 10;
			char buf[256];
			if (type ==1 )	// 杀怪
			{
				int mapid = pMiss->save_var[1];
				int monsterid  = pMiss->save_var[2];
				snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0456,curTimes,maxTimes,GetMonsterBossName(monsterid), pMiss->save_var[4], pMiss->save_var[3]);
				string content = cfg.name + buf;
				content += ((pMiss->state == EMISS_STATE_ACCEPT) ? "|0" : "|1");
				msg<<content;
				if(pMiss->state == EMISS_STATE_ACCEPT)
					msg<<(uint8)EMISS_TT_MONSTER<<(uint32)monsterid<<(uint16)mapid<<-1<<-1;
				else
					msg<<(uint8)EMISS_TT_NPC<<(uint32)106<<(uint16)11<<-1<<-1;
			}
			if (type == 2)	// 采集
			{
				int mapid = pMiss->save_var[1];
				int flowerid = pMiss->save_var[2];
				snprintf(buf,sizeof(buf),LANGUAGE_WB_0002,curTimes,maxTimes,GetNpcTmplName(flowerid),pMiss->save_var[4],pMiss->save_var[3]);
				string content = cfg.name + buf;
				content += ((pMiss->state == EMISS_STATE_ACCEPT) ? "|0" : "|1");
				msg<<content;
				if(pMiss->state == EMISS_STATE_ACCEPT){
					msg<<(uint8)EMISS_TT_NPC<<(uint32)flowerid<<(uint16)mapid<<-1<<-1;
				}
				else{
					msg<<(uint8)EMISS_TT_NPC<<(uint32)106<<(uint16)11<<-1<<-1;
				}
			}
		}
		else if(cfg.sub_type == EMISS_STYPE_ShaDiDuoBao){
			int monsterid  = pMiss->save_var[2]; // 怪物id
			int mapid = pMiss->save_var[3];      // 场景id
			int maxwbtimes = pMiss->save_var[8]; // 杀怪数量
			int current_itmemum =pMiss->save_var[5]; // 当前获得奖励数量
			if (current_itmemum>=maxwbtimes){
				pMiss->state = EMISS_STATE_FINISH;
			}

			const char * scenename = GetSceneName(mapid);
			replace.push_back(SReplaceStringData("<mapname>",scenename));
			replace.push_back(SReplaceStringData("<itemname>", GetItemName(pMiss->save_var[4])));
			replace.push_back(SReplaceStringData("<num>", IntToStr(current_itmemum).c_str()));
			replace.push_back(SReplaceStringData("<maxnum>",IntToStr(maxwbtimes).c_str()));
			ReplaceString(cfg.doing_desc, tarString, replace);
			
			char timesDesc[128];
			snprintf(timesDesc,sizeof(timesDesc),"(%d/%d)|",pUser->GetExtData16(39)+1,5);
			string content = cfg.name + timesDesc + tarString + ((pMiss->state == EMISS_STATE_ACCEPT) ? "|0" : "|1");
			msg<<content;
			if(pMiss->state == EMISS_STATE_ACCEPT)
				msg<<(uint8)EMISS_TT_MONSTER<<(uint32)monsterid<<(uint16)mapid<<-1<<-1;
			else
				msg<<(uint8)EMISS_TT_NPC<<(uint32)2<<(uint16)11<<-1<<-1;
		}
		else if(cfg.sub_type == EMISS_STYPE_HuSongShenJiang){
			int mapid = pMiss->save_var[4];      // 场景id
			int today_times = pUser->GetExtData8(81)+1;
			int maxTimes = 5;
			replace.push_back(SReplaceStringData("<monstername>", pMiss->save_str[0].c_str()));
			replace.push_back(SReplaceStringData("<npcname>", GetNpcName(74)));
			ReplaceString(cfg.doing_desc, tarString, replace);

			char buf[64];
			snprintf(buf, sizeof(buf),"(%d/%d)|", today_times, maxTimes);
			string content = cfg.name + buf + tarString + ((pMiss->state == EMISS_STATE_ACCEPT) ? "|0" : "|1");
			msg<<content;
			if(pMiss->state == EMISS_STATE_ACCEPT || pMiss->state == EMISS_STATE_FINISH){
				msg<<(uint8)EMISS_TT_NPC<<(uint32)74<<(uint16)mapid<<-1<<-1;
			}
		}
		else if (cfg.sub_type == EMISS_STYPE_KuaFuRiChang)
		{
			if (CanGetKuaFuInfo())
				MakeKuaFuRiChangMsg(pUser, pMiss, cfg, msg);
			else
				return;
		}
	}

	msg<<pMiss->time;
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void CMissionManager::SendAddCMissionMsg(CUser *pUser,int missId)
{
	if(pUser == NULL || missId <= 0)
		return;

	boost::unordered_map<int,SMissionConfig>::iterator it = m_missions.find(missId);
	if(it == m_missions.end())
		return;
	SMissionConfig &cfg = it->second;

	CNetMessage msg;
	msg.SetType(PRO_UPDATE_TASK);
	msg<<(uint8)1<<(uint16)missId<<cfg.name;
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

bool CMissionManager::CheckCMissionCanAccepted(CUser *pUser,SMissionConfig &cfg)
{
	if(pUser == NULL || cfg.id == 0)
		return false;
	if(cfg.sex_limit > 0 && cfg.sex_limit != (int)pUser->GetSex()+1)
		return false;
	if(pUser->m_missList.IsCMissionAccepted(cfg.id) || pUser->m_missList.IsInCMissionFinishedList(cfg.id))
		return false;
	if(!pUser->m_missList.IsPreCMissionFinished(cfg))
		return false;
	//帮派任务特殊处理
	if(!CheckBangPaiMissionCanAccepted(cfg.id,pUser->GetBangPai()))
	    return false;
	return true;
}

//检查帮派任务可接（特殊处理）
bool CMissionManager::CheckBangPaiMissionCanAccepted(int id,uint32 bangPaiId)
{
	bool isFind = false;
    for (int i=0;i<4;i++)
    {
    	if (MISSION_IDS_BangPai[i] == id )
    	{
    		isFind = true;
    		break;
    	}
    }
    if (!isFind || bangPaiId > 0) 
    	return true;
    return false; 
}

bool CMissionManager::IsNextMainCMission(CUser *pUser,SMissionConfig &cfg)
{
	if(pUser == NULL || cfg.id == 0 || cfg.type != EMISS_TYPE_MAIN)
		return false;
	if(cfg.sex_limit > 0 && cfg.sex_limit != (int)pUser->GetSex()+1)
		return false;
	if(pUser->m_missList.IsCMissionAccepted(cfg.id) || pUser->m_missList.IsInCMissionFinishedList(cfg.id))
		return false;
	if(!pUser->m_missList.IsPreCMissionFinished(cfg))
		return false;
	return true;
}

bool CMissionManager::HaveMainCMission(CUser *pUser)
{
	if(pUser == NULL)
		return false;

	vector<int> miss;
	pUser->m_missList.GetAcceptCMissList(miss);
	if(miss.empty())
		return false;
	for(uint32 i=0; i < miss.size(); i++)
	{
		boost::unordered_map<int,SMissionConfig>::iterator it = m_missions.find(miss[i]);
		if(it == m_missions.end())
			continue;
		SMissionConfig &cfg = it->second;
		if(cfg.type == EMISS_TYPE_MAIN)
			return true;
	}
	return false;
}

void CMissionManager::AcceptCMission(CUser *pUser,SMissionConfig &cfg,vector<int> *pVar,vector<string> *pStr)
{
	if(pUser == NULL || cfg.id == 0)
		return;

	ChangeClientGuaJiState(pUser,2);
	if(cfg.type == EMISS_TYPE_MAIN || cfg.type == EMISS_TYPE_BRANCH)
	{
		bool buyMissFinish = false;
		vector<int> save_var;
		vector<string> save_str;
		SMissionDoingContent & con = cfg.doing_content;
		if(con.op == EMISS_DC_KILL_MONSTER || con.op == EMISS_DC_MONSTER_DROP || con.op == EMISS_DC_COLLECT)
			save_var.push_back(0);
		else if(con.op == EMISS_DC_KILL_BOSS)
		{
			save_var.push_back(0);	// isfightWin
			save_var.push_back(0);	// fightRound
		}
		else if(con.op == EMISS_DC_BUY_ITEM)
		{
			int num = pUser->GetItemNum(con.itemId);
			if(num >= con.itemNum)
			{
				num = con.itemNum;
				buyMissFinish = true;
			}
			save_var.push_back(num);
		}
		else
		{
			buyMissFinish = VerifyAndAcceptBranchMission(pUser,con, save_var, save_str);
		}
		
		pUser->m_missList.AddCMission(cfg.id,cfg.type,save_var,save_str); // 添加到已接任务
		pUser->m_missList.DelAvailableCMission(cfg.id);                   // 从可接任务中删除

		if(con.op == EMISS_DC_DIALOG || buyMissFinish)
		{
			pUser->m_missList.UpdateCMisstionState(cfg.id,EMISS_STATE_FINISH);
//			SendYinDaoNPCPos(pUser,con.sceneId,con.posX,con.posY,con.npcId);
		}


		SendAddCMissionMsg(pUser,cfg.id);
		CMissionToDo(pUser,cfg.accept_todo);
		SendCMissionTrackMsg(pUser,cfg.id);  // 任务状态同步到前端

		if(cfg.accept_autorun == EMISS_RUN_AUTO)
		{
			if(con.op == EMISS_DC_DIALOG || con.op == EMISS_DC_KILL_BOSS || con.op == EMISS_DC_COLLECT)
				SendYinDaoNPCPos(pUser,con.sceneId,con.posX,con.posY,con.npcId);
			else if(con.op == EMISS_DC_KILL_MONSTER || con.op == EMISS_DC_MONSTER_DROP)
				SendYinDaoMonsterPos(pUser,con.sceneId,con.posX,con.posY,con.monsterId);
			else if(con.op == EMISS_DC_BUY_ITEM)
				SendYinDaoNPCPos(pUser, 11, 2398, 1172, 9); // 药店老板
		}
	}
	else if(cfg.type == EMISS_TYPE_DAILY || cfg.type == EMISS_TYPE_KUAFU_DAILY)
	{
		if(pVar == NULL || pStr == NULL)
			return;
		if(cfg.sub_type == EMISS_STYPE_ShiMen)
		{
			if(pVar->size() < 3)
				return;
			pUser->m_missList.AddCMission(cfg.id,cfg.type,*pVar,*pStr);
			pUser->m_missList.DelAvailableCMission(cfg.id);
			
			SendAddCMissionMsg(pUser,cfg.id);
			SendCMissionTrackMsg(pUser,cfg.id);
			if(cfg.accept_autorun == EMISS_RUN_AUTO)
			{
				int shimenType = (*pVar)[0];
				if(shimenType == 1)	// 打怪
				{
					int monId = (*pVar)[1];
					SendYinDaoMonsterPos(pUser,GetMonsterFindPathSidById(monId),-1,-1,monId);
				}
				else if(shimenType == 2)	// 买药
				{
					int itemId = (*pVar)[1];
					int itemNum = (*pVar)[2];
					if(pUser->GetItemNum(itemId) >= itemNum)
					{
						pUser->UpdateCMissionState(cfg.id,EMISS_STATE_FINISH);
						SendYinDaoNPCPos(pUser,11,-1,-1, GetCMissionBackNpcId(cfg.id));
					}
					else
					{
						SendYinDaoNPCPos(pUser,11,-1,-1,9);	// 药店老板
					}
				}
				else if(shimenType == 3)	// 送信
				{
					int npcId = (*pVar)[1];
					SendYinDaoNPCPos(pUser,11,-1,-1,npcId);
				}
				else if(shimenType == 4)	// 杀叛徒
				{
					int npcId = (*pVar)[1];
					int sid = (*pVar)[2];
					SendYinDaoNPCPos(pUser,sid,-1,-1,npcId);
				}
			}
		}
		else if(cfg.sub_type == EMISS_STYPE_ZhuoGui)
		{
			if(pVar->size() < 5)
				return;
			pUser->m_missList.AddCMission(cfg.id,cfg.type,*pVar,*pStr);
			pUser->m_missList.DelAvailableCMission(cfg.id);
			
			SendAddCMissionMsg(pUser,cfg.id);
			SendCMissionTrackMsg(pUser,cfg.id);
			if(cfg.accept_autorun == EMISS_RUN_AUTO)
			{
				uint16 monsterId = (*pVar)[3];
				if(pUser->GetTeam() == pUser->GetRoleId())
					SendYinDaoMonsterPos(pUser,GetMonsterFindPathSidById(monsterId),-1,-1,monsterId);
			}
		}
		else if(cfg.sub_type == EMISS_STYPE_CangBaoTu){
			if(pVar->size() < 5){
				return;
			}

			pUser->m_missList.AddCMission(cfg.id,cfg.type,*pVar,*pStr);
			pUser->m_missList.DelAvailableCMission(cfg.id);
			
			SendAddCMissionMsg(pUser, cfg.id);
			SendCMissionTrackMsg(pUser, cfg.id);
			if(cfg.accept_autorun == EMISS_RUN_AUTO)
			{
				uint16 monsterId = (*pVar)[1];
				SendYinDaoMonsterPos(pUser,GetMonsterFindPathSidById(monsterId),-1,-1,monsterId);
			}
		}
		else if(cfg.sub_type == EMISS_STYPE_DanYuan){
			int todaytimes = pUser->GetExtData8(101) + 1;
			if(todaytimes > 10){
				return;
			}
			pUser->m_missList.AddCMission(cfg.id, cfg.type,*pVar,*pStr);
			pUser->m_missList.DelAvailableCMission(cfg.id);
			SendAddCMissionMsg(pUser, cfg.id);
			SendCMissionTrackMsg(pUser, cfg.id);
			if(cfg.accept_autorun == EMISS_RUN_AUTO)
			{
				uint16 monsterId = (*pVar)[2];
				SendYinDaoMonsterPos(pUser,GetMonsterFindPathSidById(monsterId),-1,-1,monsterId);
			}
		}
		else if(cfg.sub_type == EMISS_STYPE_ShaDiDuoBao){
			pUser->m_missList.AddCMission(cfg.id, cfg.type,*pVar,*pStr);
			pUser->m_missList.DelAvailableCMission(cfg.id);
			SendAddCMissionMsg(pUser, cfg.id);
			SendCMissionTrackMsg(pUser, cfg.id);
			if(cfg.accept_autorun == EMISS_RUN_AUTO)
			{
				uint16 monsterId = (*pVar)[2];
				SendYinDaoMonsterPos(pUser,GetMonsterFindPathSidById(monsterId),-1,-1,monsterId);
			}

		}
		else if(cfg.sub_type == EMISS_STYPE_HuSongShenJiang){
			pUser->m_missList.AddCMission(cfg.id, cfg.type,*pVar,*pStr);
			pUser->m_missList.DelAvailableCMission(cfg.id);
			SendAddCMissionMsg(pUser, cfg.id);
			SendCMissionTrackMsg(pUser, cfg.id);
			if(cfg.accept_autorun == EMISS_RUN_AUTO)
			{
				uint16 monsterId = (*pVar)[2];
				SendYinDaoMonsterPos(pUser,GetMonsterFindPathSidById(monsterId),-1,-1,monsterId);
			}
			
		}
		else if (cfg.sub_type == EMISS_STYPE_KuaFuRiChang && CanGetKuaFuInfo()) {
			pUser->m_missList.AddCMission(cfg.id, cfg.type, *pVar, *pStr);
			pUser->m_missList.DelAvailableCMission(cfg.id);
			SendAddCMissionMsg(pUser, cfg.id);
			SendCMissionTrackMsg(pUser, cfg.id);
		}

	}
}

bool CMissionManager::FinishCMission(CUser *pUser,int missId,bool inFight,int fightRound)
{
	if(pUser == NULL || missId <= 0)
		return false;
	if(!pUser->m_missList.IsCMissionFinished(missId))
		return false;
	boost::unordered_map<int,SMissionConfig>::iterator it = m_missions.find(missId);
	if(it == m_missions.end())
		return false;
	SMissionConfig &cfg = it->second;
	
	pUser->m_missList.DelCMission(missId,pUser->GetSock());
	AddCMissionReward(pUser,missId,inFight,fightRound);
	CMissionToDo(pUser,cfg.finish_todo);
	if (EMISS_STYPE_Mubiao == cfg.sub_type)
	{
		UpdateStageGoalState(pUser, missId);
	}
	return true;
}

void CMissionManager::AddCMissionReward(CUser *pUser,int missId,bool inFight,int fightRound)
{
	if(pUser == NULL || missId <= 0)
		return;
	boost::unordered_map<int,SMissionConfig>::iterator it = m_missions.find(missId);
	if(it == m_missions.end())
		return;

	char buf[256];
	SMissionConfig &cfg = it->second;
	if (cfg.finish_auto
		&& (cfg.doing_content.op == 2
			|| cfg.doing_content.op == 3
			|| cfg.doing_content.op == 5))
	{
		inFight = true;
	}
	vector<SAwardData> *pReward = &cfg.reward1;
	if(fightRound > 0 && cfg.doing_content.fightRound > 0 && fightRound <= cfg.doing_content.fightRound)
		pReward = &cfg.reward2;
	for(uint16 i=0;i < pReward->size();i++)
	{
		SAwardData &data = (*pReward)[i];
		if(data.type == HDAT_MONEY)
		{
			pUser->AddMoney(data.num);
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_580,data.num);
			if(inFight)
				SendSysInfoFightEnd(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
			else
				SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
		}
		else if(data.type == HDAT_BANG_YB)
		{
			pUser->AddTongBao(data.num,1);
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1545,data.num);
			if(inFight)
				SendSysInfoFightEnd(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
			else
				SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
		}
		else if(data.type == HDAT_PET)
		{
			AddPet(pUser, data.typeId, 1);
			pUser->ZhenFa_SetPetState(data.typeId, 1);
		}
		else if(data.type == HDAT_YB)
		{
			pUser->AddTongBao(data.num);
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_235,data.num);
			if(inFight)
				SendSysInfoFightEnd(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
			else
				SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
		}
		else if(data.type == HDAT_EXP)
		{
			pUser->AddExp(data.num, true, inFight);
		}
		else if(data.type == HDAT_QIANNENG)
		{
			pUser->AddQianNeng(data.num);
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_237,data.num);
			if(inFight)
				SendSysInfoFightEnd(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
			else
				SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
		}
		else if(data.type == HDAT_CHENGHAO)
		{

		}
		else if(data.type == HDAT_WING)
		{
			pUser->AddWing(data.num);
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_239,GetWingName(data.num));
			if(inFight)
				SendSysInfoFightEnd(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
			else
				SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
//			pUser->UseWing(data.num);
		}
		else if(data.type == HDAT_MOUNT)
		{
			pUser->AddMount(data.num);
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_240,GetMountName(data.num));
			if(inFight)
				SendSysInfoFightEnd(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
			else
				SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
//			pUser->UseMount(data.num);
		}
		else if(data.type == HDAT_SHENQI)
		{

		}
		else if(data.type == HDAT_SHEN_HUN)
		{
			pUser->AddShenhun(data.num);
			snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0488,data.num);
			if(inFight)
				SendSysInfoFightEnd(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
			else
				SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
		}
		else if(data.type == HDAT_BANGPAI_MONEY)
		{

		}
/*		else if(data.type == HDAT_Profession_1 + (int)pUser->GetXiang() - 1)
		{
			pUser->AddBangDingPackage(data.num,1);
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_126,GetItemName(data.num),1);
			if(inFight)
				SendSysInfoFightEnd(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
			else
				SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
		}
*/
		else if(data.type < HDAT_MONEY)
		{
			pUser->AddBangDingPackage(data.type,data.num);
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_126,GetItemName(data.type),data.num);
			if(inFight)
				SendSysInfoFightEnd(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
			else
				SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
		}
		else
		{
			pUser->AddMaterial(data, inFight);
		}
		
	}
}

void CMissionManager::AddKillMonsterNum(CUser *pUser,int monsterId,int num)
{
	if(pUser == NULL || monsterId < 1 || num < 1)
		return;

	UpdateDCMissionComplate(pUser, EMISS_DC_67, num);
	vector<int> miss;
	pUser->m_missList.GetAcceptCMissList(miss);
	if(miss.empty())
		return;

	for(uint16 i=0; i < miss.size();i++)
	{
		SMissionConfig *pCfg = GetMissionCfg(miss[i]);
		if(pCfg == NULL)
			continue;
		if(pCfg->type == EMISS_TYPE_MAIN || pCfg->type == EMISS_TYPE_BRANCH)
		{
			SMissionDoingContent &con = pCfg->doing_content;
			if(con.op == EMISS_DC_KILL_MONSTER && con.monsterId == monsterId)
			{
				SAcceptMission *pAccept = pUser->m_missList.GetAcceptedCMission(pCfg->id);
				if(pAccept == NULL || pAccept->save_var.empty())
					continue;
				
				pAccept->save_var[0] += num;
				if(pAccept->save_var[0] >= con.monsterNum)
				{
					pAccept->save_var[0] = con.monsterNum;
					pAccept->state = EMISS_STATE_FINISH;
				}
				SendCMissionTrackMsg(pUser,pCfg->id);
				
				if(pCfg->finish_auto == EMISS_FINISH_AUTO)
					FinishCMission(pUser,pCfg->id,true);

			}
			else if(con.op == EMISS_DC_MONSTER_DROP && con.monsterId == monsterId)
			{
				int ratio = Random(1,10000);
				if(ratio <= pCfg->doing_content.dropRatio)
				{
					SAcceptMission *pAccept = pUser->m_missList.GetAcceptedCMission(pCfg->id);
					if(pAccept == NULL || pAccept->save_var.empty())
						continue;
					
					pAccept->save_var[0] += 1;
					if(pAccept->save_var[0] >= con.itemNum)
					{
						pAccept->save_var[0] = con.itemNum;
						pAccept->state = EMISS_STATE_FINISH;
					}
					SendCMissionTrackMsg(pUser,pCfg->id);
					
					if(pCfg->finish_auto == EMISS_FINISH_AUTO)
						FinishCMission(pUser,pCfg->id,true);
				}
			}
		}
		else if(pCfg->type == EMISS_TYPE_DAILY || pCfg->type == EMISS_TYPE_KUAFU_DAILY)
		{
			if(pCfg->sub_type == EMISS_STYPE_ShiMen)	// 师门任务
			{
				SAcceptMission *pAccept = pUser->m_missList.GetAcceptedCMission(pCfg->id);
				if(pAccept == NULL || pAccept->save_var.empty())
					continue;
				int shiMenType = pAccept->save_var[0];
				if(shiMenType == 1)	// 打怪
				{
					int monId = pAccept->save_var[1];
					if(monId == monsterId)
					{
						pAccept->save_var[3] += num;
						if(pAccept->save_var[3] >= pAccept->save_var[2])
						{
							pAccept->save_var[3] = pAccept->save_var[2];
							pAccept->state = EMISS_STATE_FINISH;
							ChangeClientGuaJiState(pUser,2);
							SendYinDaoNPCPos(pUser,11,-1,-1, GetCMissionBackNpcId(pCfg->id));
						}
						SendCMissionTrackMsg(pUser,pCfg->id);
					}
				}
			}
			
			if(pCfg->sub_type == EMISS_STYPE_DanYuan)	// 丹园维护
			{
				SAcceptMission *pAccept = pUser->m_missList.GetAcceptedCMission(pCfg->id);
				if(pAccept == NULL || pAccept->save_var.empty())
					continue;
				int type = pAccept->save_var[0];
				if(type == 1)	// 打怪
				{
					int monId = pAccept->save_var[2];
					if(monId == monsterId)
					{
						pAccept->save_var[4] += num;
						if(pAccept->save_var[4] >= pAccept->save_var[3])
						{
							pAccept->save_var[4] = pAccept->save_var[3];
							pAccept->state = EMISS_STATE_FINISH;
							CCallScript *pCallScript = FindScript(106); // 调用2.lua 脚本
							if (pCallScript == NULL) {
								return;
							}
							pCallScript->Call("DanYuanSelectOpt", "ui", pUser, 2);
						}
						SendCMissionTrackMsg(pUser, pCfg->id);
					}
				}
			}

			if(pCfg->sub_type == EMISS_STYPE_ShaDiDuoBao){
				CCallScript *pCallScript = FindScript(2); // 调用2.lua 脚本
				if(pCallScript == NULL){
					return;
				}
				pCallScript->Call("NotifyRes","uii", pUser, monsterId, num);
			}
			
		}
	}
}

void CMissionManager::AddCollectNum(CUser *pUser,int npcId,int num)
{
	if(pUser == NULL || npcId < 1 || num < 1)
		return;

	vector<int> miss;
	pUser->m_missList.GetAcceptCMissList(miss);
	if(miss.empty())
		return;
	
	for(uint16 i=0; i < miss.size();i++)
	{
		SMissionConfig *pCfg = GetMissionCfg(miss[i]);
		if(pCfg == NULL)
			continue;
		SMissionDoingContent &con = pCfg->doing_content;
		if(con.op == EMISS_DC_COLLECT && con.npcId == npcId)
		{
			SAcceptMission *pAccept = pUser->m_missList.GetAcceptedCMission(pCfg->id);
			if(pAccept == NULL || pAccept->save_var.empty())
				continue;
			pAccept->save_var[0] += num;
			if(pAccept->save_var[0] >= con.itemNum)
			{
				pAccept->save_var[0] = con.itemNum;
				pAccept->state = EMISS_STATE_FINISH;
			}
			else
			{
				SendYinDaoNPCPos(pUser,con.sceneId,-1,-1,con.npcId);
			}
			SendCMissionTrackMsg(pUser,pCfg->id);

			if(pCfg->finish_auto == EMISS_FINISH_AUTO)
				FinishCMission(pUser,pCfg->id);
		}
	}
}

void CMissionManager::AddCompleteCopyNum(CUser *pUser,int copyId)
{
	if(pUser == NULL || copyId < 1)
		return;

	vector<int> miss;
	pUser->m_missList.GetAcceptCMissList(miss);
	if(miss.empty())
		return;
	for(uint16 i=0; i < miss.size();i++)
	{
		SMissionConfig *pCfg = GetMissionCfg(miss[i]);
		if(pCfg == NULL)
			continue;
		SMissionDoingContent &con = pCfg->doing_content;
		if(con.op == EMISS_DC_COPY && con.copyId == copyId)
		{
			SAcceptMission *pAccept = pUser->m_missList.GetAcceptedCMission(pCfg->id);
			if(pAccept == NULL || pAccept->save_var.empty())
				continue;
			pAccept->save_var[0]++;
			if(pAccept->save_var[0] >= con.copyCompleteNum)
			{
				pAccept->save_var[0] = con.copyCompleteNum;
				pAccept->state = EMISS_STATE_FINISH;
			}
			SendCMissionTrackMsg(pUser,pCfg->id);

			if(pCfg->finish_auto == EMISS_FINISH_AUTO)
				FinishCMission(pUser,pCfg->id);
		}
	}
}

bool CMissionManager::CheckCMissionNpcInteract(CUser *pUser,int npcId,int index,int missId)
{
	if(pUser == NULL)
		return false;
	if(npcId == 0)
	{
		if(PlayNpcAct(pUser))
			return true;
		return false;
	}

	bool isFind = false;
	// 已接任务
	vector<int> accept_miss;
	pUser->m_missList.GetAcceptCMissList(accept_miss);
	for(uint16 i=0;i < accept_miss.size();i++)
	{
		boost::unordered_map<int,SMissionConfig>::iterator it = m_missions.find(accept_miss[i]);
		if(it != m_missions.end())
		{
			SMissionConfig &cfg = it->second;
			if(missId != 0 && cfg.id != missId)
				continue;
			SMissionDoingContent &con = cfg.doing_content;
			if(con.npcId == npcId)
			{
				if(con.op == EMISS_DC_DIALOG)
				{
					vector<SNPC_ActData> act;
					if(con.dialogId > 0)
						act.push_back(SNPC_ActData(EMISS_ACT_NOR_DIALOG,con.dialogId,GetDialogCfgMaxNum(con.dialogId)));
					pUser->m_missList.npc_act.SetData(npcId,index,cfg.id,act);
					isFind = true;
				}
				else if(con.op == EMISS_DC_BUY_ITEM)
				{
					vector<SNPC_ActData> act;
					act.push_back(SNPC_ActData(EMISS_ACT_ITEM,con.itemId,con.itemNum));
					if(con.dialogId > 0)
						act.push_back(SNPC_ActData(EMISS_ACT_NOR_DIALOG,con.dialogId,GetDialogCfgMaxNum(con.dialogId)));
					pUser->m_missList.npc_act.SetData(npcId,index,cfg.id,act);
					isFind = true;
				}
				else if(con.op == EMISS_DC_KILL_BOSS)
				{
					SAcceptMission *pMiss = pUser->m_missList.GetAcceptedCMission(cfg.id);
					if(pMiss == NULL || pMiss->save_var.empty())
						continue;
					vector<SNPC_ActData> act;
					if(pMiss->save_var[0] == 1)	// win
					{
						if(con.fightWinDialogId > 0)
							act.push_back(SNPC_ActData(EMISS_ACT_WIN_DIALOG,con.fightWinDialogId,GetDialogCfgMaxNum(con.fightWinDialogId)));
					}
					else
					{
						if(con.fightPreDialogId > 0)
							act.push_back(SNPC_ActData(EMISS_ACT_NOR_DIALOG,con.fightPreDialogId,GetDialogCfgMaxNum(con.fightPreDialogId)));
						act.push_back(SNPC_ActData(EMISS_ACT_FIGHT,con.fightId));
						if(con.fightWinDialogId > 0)
							act.push_back(SNPC_ActData(EMISS_ACT_WIN_DIALOG,con.fightWinDialogId,GetDialogCfgMaxNum(con.fightWinDialogId)));
						if(con.fightFailDialogId > 0)
							act.push_back(SNPC_ActData(EMISS_ACT_FAIL_DIALOG,con.fightFailDialogId,GetDialogCfgMaxNum(con.fightFailDialogId)));
					}
					pUser->m_missList.npc_act.SetData(npcId,index,cfg.id,act);
					isFind = true;
				}
				else if(con.op == EMISS_DC_COLLECT)
				{
					vector<SNPC_ActData> act;
					act.push_back(SNPC_ActData(EMISS_ACT_COLLECT,con.collectPic,0,con.collectStr));
					pUser->m_missList.npc_act.SetData(npcId,index,cfg.id,act);
					isFind = true;
				}
			}
		}
		if(isFind)
			break;
	}

	if(isFind && PlayNpcAct(pUser))
		return true;
	isFind = false;
	
	vector<int> avail_miss;
	pUser->m_missList.GetAvailableCMissions(avail_miss);
	for(uint16 i=0;i < avail_miss.size();i++)
	{
		boost::unordered_map<int,SMissionConfig>::iterator it = m_missions.find(avail_miss[i]);
		if(it != m_missions.end())
		{
			SMissionConfig &cfg = it->second;
			if(missId != 0 && cfg.id != missId)
				continue;
			if(cfg.accept_npc.npcId != npcId)
				continue;
			if(cfg.accept_from_script > 0)	// 脚本接取
				continue;
			if(cfg.accept_dialog > 0)
			{
				vector<SNPC_ActData> act;
				act.push_back(SNPC_ActData(EMISS_ACT_NOR_DIALOG,cfg.accept_dialog,GetDialogCfgMaxNum(cfg.accept_dialog)));
				pUser->m_missList.npc_act.SetData(npcId,index,cfg.id,act);
			}
			else
			{
				AcceptCMission(pUser,cfg);
			}
			isFind = true;
			break;
		}
	}

	if(isFind && PlayNpcAct(pUser))
		return true;
	return false;
}

bool CMissionManager::PlayNpcAct(CUser *pUser,bool skipDialog)
{
	SNPCInteracter &npc_act = pUser->m_missList.npc_act;
	if(npc_act.npcId == 0)
		return false;
	boost::unordered_map<int,SMissionConfig>::iterator it = m_missions.find(npc_act.missId);
	if(it == m_missions.end())
		return false;
	SMissionConfig &cfg = it->second;
	if(npc_act.AllComplete())
	{
		if(!pUser->m_missList.IsCMissionAccepted(npc_act.missId))
		{
			AcceptCMission(pUser,cfg);
			pUser->m_missList.npc_act.Clear();
			return true;
		}
		else
		{
			if(cfg.doing_content.op == EMISS_DC_DIALOG)
			{
				FinishCMission(pUser,npc_act.missId);
			}
			else if(cfg.doing_content.op == EMISS_DC_BUY_ITEM)	// 提交物品
			{
				int num = pUser->GetItemNum(cfg.doing_content.itemId);
				if(num >= cfg.doing_content.itemNum)
				{
					num = cfg.doing_content.itemNum;
					pUser->DelPackageById(cfg.doing_content.itemId,num);
					pUser->m_missList.UpdateCMisstionState(npc_act.missId,EMISS_STATE_FINISH);
					FinishCMission(pUser,npc_act.missId);
				}
				else
				{
					Dialog(pUser,GetNpcTmplName(npc_act.npcId),LANGUAGE_SSJ_1008);
				}
			}
			else if(cfg.doing_content.op == EMISS_DC_KILL_BOSS)
			{
				SAcceptMission *pMiss = pUser->m_missList.GetAcceptedCMission(npc_act.missId);
				if(pMiss == NULL)
					return false;
				if(pMiss->save_var.size() < 2)
					return false;
				if(pMiss->save_var[0] == 1)
				{
					pUser->m_missList.UpdateCMisstionState(npc_act.missId,EMISS_STATE_FINISH);
					FinishCMission(pUser,npc_act.missId,false,pMiss->save_var[1]);
				}
				else
				{
					CloseInteract(pUser);
				}
			}
			else if(cfg.doing_content.op == EMISS_DC_COLLECT)	// 采集
			{
				pUser->DelCollect(npc_act.npcId,npc_act.npcIndex,cfg.doing_content.sceneId);
				AddCollectNum(pUser,npc_act.npcId,1);
			}
			else
			{
				pUser->m_missList.npc_act.Clear();
				return false;
			}
		}

		pUser->m_missList.npc_act.Clear();
		return true;
	}
	
	SNPC_ActData *act = (skipDialog ? npc_act.GetActSkipDialog() : npc_act.GetAct());
	if(act == NULL)
	{
		// Falling back from "skip dialog" to the normal action is valid once.
		// When the normal list is also empty, recursing forever overflows the stack.
		return skipDialog ? PlayNpcAct(pUser, false) : false;
	}
	if(act->act_type == EMISS_ACT_NOR_DIALOG || act->act_type == EMISS_ACT_WIN_DIALOG || act->act_type == EMISS_ACT_FAIL_DIALOG)
	{
		SMissionDialog *pDialog = GetDialogString(act->act_id,act->dialogIdx);
		if(pDialog == NULL)
			return false;
		int npcId = pDialog->npcId;
		const char *pName = GetNpcTmplName(npcId);
		if(npcId == 10000)	// 玩家自己
		{
			npcId = -1;
			pName = pUser->GetName();
		}

		string content;
		{
			vector<SReplaceStringData> replace;
			replace.push_back(SReplaceStringData("<name>",pUser->GetName()));
//			replace.push_back(SReplaceStringData("<profession>",GetProfessionName(pUser->GetXiang())));
			replace.push_back(SReplaceStringData("<sex>",GetSexName(pUser->GetSex())));
			ReplaceString(pDialog->content,content,replace);
		}
		if(act->dialogIdx == 0)
		{
			if(act->num > 1)
				DialogS_Start(pUser,npcId,pName,content.c_str());
			else
				DialogS_End(pUser,npcId,pName,content.c_str());
		}
		else if(act->dialogIdx > 0 && act->dialogIdx < act->num-1)
			DialogS_Doing(pUser,npcId,pName,content.c_str());
		else
			DialogS_End(pUser,npcId,pName,content.c_str());
	}
	else if(act->act_type == EMISS_ACT_FIGHT)
	{
		StartCMissionFight(pUser,npc_act.missId,act->act_id);
	}
	else if(act->act_type == EMISS_ACT_ITEM)
	{
		// 后续需要弹出提交物品界面
		int num = pUser->GetItemNum(act->act_id);
		if(num >= act->num)
			return PlayNpcAct(pUser);
		else
		{
			SAcceptMission *pMiss = pUser->m_missList.GetAcceptedCMission(npc_act.missId);
			if(pMiss != NULL && !pMiss->save_var.empty())
			{
				if(pMiss->save_var[0] != num)
				{
					pMiss->save_var[0] = num;
					pUser->m_missList.UpdateCMisstionState(npc_act.missId,EMISS_STATE_ACCEPT);
					SendCMissionTrackMsg(pUser,npc_act.missId);
				}
			}
			Dialog(pUser,GetNpcTmplName(npc_act.npcId),LANGUAGE_SSJ_1008);
		}
	}
	else if(act->act_type == EMISS_ACT_COLLECT)
	{
		Collect(pUser,npc_act.npcId,npc_act.npcIndex,act->act_id,1,act->str.c_str());
	}
	return true;
}

void CMissionManager::StartCMissionFight(CUser *pUser,int missId,int fightId)
{
	if(pUser != NULL && pUser->GetScene() != NULL)
		pUser->GetScene()->CMissionFight(pUser,missId,fightId);
}

void CMissionManager::UpdateCMissionFightState(CUser *pUser,int missId,int round)
{
	if(pUser == NULL || missId < 1)
		return;

	SAcceptMission *pMiss = pUser->m_missList.GetAcceptedCMission(missId);
	if(pMiss == NULL)
		return;
	if(pMiss->save_var.size() < 2)
		return;
	if(pMiss->save_var[0] == 0)
	{
		pMiss->save_var[0] = 1;
		pMiss->save_var[1] = round;
	}
}

void CMissionManager::UpdateCMissionItemState(CUser *pUser,int itemId)
{
	if(pUser == NULL || itemId < 1)
		return;
	int num = pUser->GetItemNum(itemId);

	vector<int> missList;
	pUser->m_missList.GetAcceptCMissList(missList);
	if(missList.empty())
		return;
	for(uint32 i=0;i < missList.size();i++)
	{
		SMissionConfig *pCfg = GetMissionCfg(missList[i]);
		if(pCfg == NULL)
			continue;
		if(pCfg->type == EMISS_TYPE_MAIN || pCfg->type == EMISS_TYPE_BRANCH)
		{
			if(pCfg->doing_content.op == EMISS_DC_BUY_ITEM && pCfg->doing_content.itemId == itemId)
			{
				int itemNum = (num > pCfg->doing_content.itemNum) ? pCfg->doing_content.itemNum : num;
				SAcceptMission *pMiss = pUser->m_missList.GetAcceptedCMission(missList[i]);
				if(pMiss == NULL || pMiss->save_var.empty())
					continue;
				if(pMiss->save_var[0] != itemNum)
				{
					pMiss->save_var[0] = itemNum;
					if(itemNum >= pCfg->doing_content.itemNum)
						pUser->m_missList.UpdateCMisstionState(missList[i],EMISS_STATE_FINISH);
					SendCMissionTrackMsg(pUser,missList[i]);
				}
			}
		}
		else if(pCfg->type == EMISS_TYPE_DAILY || pCfg->type == EMISS_TYPE_KUAFU_DAILY)
		{
			if(pCfg->sub_type == EMISS_STYPE_ShiMen)	// 师门任务
			{
				SAcceptMission *pMiss = pUser->m_missList.GetAcceptedCMission(missList[i]);
				if(pMiss == NULL || pMiss->save_var.empty())
					continue;
				int shimenType =pMiss->save_var[0];
				if(shimenType == 2 && itemId == pMiss->save_var[1])
				{
					int itemNum = (num > (pMiss->save_var[2])) ? (pMiss->save_var[2]) : num;
					if(pMiss->save_var[3] != itemNum)
					{
						pMiss->save_var[3] = itemNum;
						if(itemNum >= pMiss->save_var[2])
							pUser->m_missList.UpdateCMisstionState(missList[i],EMISS_STATE_FINISH);
						SendCMissionTrackMsg(pUser,missList[i]);
					}
				}
			}
		}
	}
}

void CMissionManager::CMissionToDo(CUser *pUser,vector<SMissionTodo> &todo)
{
	if(pUser == NULL)
		return;
	for(uint16 i=0;i < todo.size();i++)
	{
		SMissionTodo &t = todo[i];
		if(t.op == EMISS_TD_ADD_NPC)
		{
			AddNpcDirect(pUser,t.npcId,t.sceneId,t.posX,t.posY,t.direct,t.npcIdx);
		}
		else if(t.op == EMISS_TD_DEL_NPC)
		{
			DelNpc(pUser,t.npcId,t.npcIdx);
		}
		else if(t.op == EMISS_TD_ADD_COLLECT)
		{
			pUser->AddCollect(t.npcId,t.npcIdx,t.sceneId,t.posX,t.posY);
		}
		else if(t.op == EMISS_TD_DEL_COLLECT)
		{
			pUser->DelCollect(t.npcId,t.npcIdx,t.sceneId);
		}
		else if(t.op == EMISS_TD_TRANSPORT)
		{
			CScene *pScene = pUser->GetScene();
			if(pScene == NULL)
				return;
			if(pScene->GetSrcSceneId() != t.sceneId)
				TransportUser(pUser,t.sceneId,t.posX,t.posY,1);
			else
				pScene->GoTo(pUser,t.posX,t.posY);
		}
		else if (t.op == EMISS_TD_ADDTESTCARD)
		{
			pUser->SetMonthCard(UPT_TiYan, t.itemNum);
			pUser->UpdateVipInfo();
			SendSysInfo(pUser, LANGUAGE_ZQX_0103);
		}
	}
}

void InitNewBranchMission(SMissionDoingContent &c, char** p){
	if(c.op == EMISS_DC_8){
		//  通关寻神将任务类型：8-fubenid（寻神将副本id）-num（通关副本次数）
		c.copyId = atoi(p[1]);
		c.copyCompleteNum = atoi(p[2]);
	}
	else if(c.op == EMISS_DC_9){
		//  神将招募任务类型：9-num（神将招募次数）
		c.isum = atoi(p[1]);

	}
	else if(c.op == EMISS_DC_10){
		//  猜拳玩法任务：10-1
		c.isum = atoi(p[1]);

	}
	else if (c.op == EMISS_DC_16) {
		//  世界频道发言x次：16-num（次数）
		c.isum = atoi(p[1]);
	}
	else if(c.op == EMISS_DC_17){
		//  添加x个好友：17-num（好友数）
		c.isum = atoi(p[1]);
	}
	else if(c.op == EMISS_DC_18){
		//  加入帮派：18-1
		c.isum = atoi(p[1]);

	}
	else if(c.op == EMISS_DC_19){
		//  完成x个帮派活动：19-x
		c.isum = atoi(p[1]);
	}
	else if(c.op == EMISS_DC_21){
		//  升级x个神将至x级：21-num（神将数量）-level（神将等级）
		c.isum = atoi(p[1]);
		c.level  = atoi(p[2]);
	}
	else if(c.op == EMISS_DC_22){
		//  x个神将技能提升至x级：22-num（神将技能数量）-level（技能等级）
		c.isum = atoi(p[1]);
		c.level  = atoi(p[2]);

	}
	else if(c.op == EMISS_DC_23){
		//  x个神将血脉修炼至x级：23-num（神将血脉数量）-level（修炼等级）
		c.isum = atoi(p[1]);
		c.level  = atoi(p[2]);

	}
	else if(c.op == EMISS_DC_24){
		//  任意神将升星x次：24-num
		c.isum = atoi(p[1]);

	}
	else if(c.op == EMISS_DC_25){
		//  x个人物技能提升至x级：25-num（技能数量）-level（技能等级）
		c.isum = atoi(p[1]);
		c.level  = atoi(p[2]);

	}
	else if(c.op == EMISS_DC_26){
		//  x件装备升阶至x级：26-num（装备数量）-level（装备等级）
		c.isum = atoi(p[1]);
		c.level  = atoi(p[2]);

	}
	else if(c.op == EMISS_DC_27){
		//  x件装备强化至x级：27-num（装备数量）-level（强化等级）
		c.isum = atoi(p[1]);
		c.level  = atoi(p[2]);

	}
	else if(c.op == EMISS_DC_28){
		//  装备淬炼x次：28-num
		c.isum = atoi(p[1]);

	}
	else if(c.op == EMISS_DC_29){
		//  装备洗炼x次：29-num
		c.isum = atoi(p[1]);

	}
	else if(c.op == EMISS_DC_30){
		//  挑战竞技场x：30-num
		c.isum = atoi(p[1]);

	}
	else if(c.op == EMISS_DC_31){
		//  灵气捐献x次：31-num
		c.isum = atoi(p[1]);

	}
	else if(c.op == EMISS_DC_32){
		//  参与多人闯关：32-1
		c.isum = atoi(p[1]);
	}
	else if(c.op == EMISS_DC_33){
		//  通关通天塔至x层：33-num（层数）
		c.isum = atoi(p[1]);

	}
	else if(c.op == EMISS_DC_34){
		//  挑战x次日常boss：34-num（次数）
		c.isum = atoi(p[1]);

	}
	else if(c.op == EMISS_DC_35){
		//  参与六界巡查使：35-1
		c.isum = atoi(p[1]);

	}
	else if(c.op == EMISS_DC_36){
		//  参与英勇试炼：36-1
		c.isum = atoi(p[1]);
	}
	else if(c.op == EMISS_DC_37){
		 //  参与修仙历练：37-1
		c.isum = atoi(p[1]);
	}
	else if(c.op == EMISS_DC_38){
		//  x个神将升至x星：24-num（神将数量）-star（星数)
		c.isum = atoi(p[1]);
		c.star  = atoi(p[2]);
	}
	else if (c.op == EMISS_DC_39) {
		//  捉妖 x 次
		c.isum = atoi(p[1]);
	}
	else if (c.op == EMISS_DC_40) {
		//  获得坐骑
		c.isum = atoi(p[1]);
		c.itemId = atoi(p[2]);
	}
	else if (c.op == EMISS_DC_41) {
		// 坐骑强化到 x 级
		c.isum = atoi(p[1]);
	}
	else if (c.op == EMISS_DC_42) {
		// 获得神器 x
		c.isum = atoi(p[1]);
		c.itemId = atoi(p[2]);
	}
	else if (c.op == EMISS_DC_43) {
		//  培养羽翼到 x 阶段
		c.isum = atoi(p[1]);
	}
	else if (c.op == EMISS_DC_44) {
		//  完成x次宝图任务 
		c.isum = atoi(p[1]);
	}
	else if (c.op == EMISS_DC_45) {
		//  使用x次藏宝图
		c.isum = atoi(p[1]);
	}
	else if (c.op == EMISS_DC_46) {
		//  使用x次高级藏宝图
		c.isum = atoi(p[1]);
	}
	else if (c.op == EMISS_DC_47) {
		//  学习天书技能x次
		c.isum = atoi(p[1]);
	}
	else if (c.op == EMISS_DC_48) {
		//  护送神将x次
		c.isum = atoi(p[1]);
	}
	else if (c.op == EMISS_DC_49) {
		//   英勇试炼击败第X关守护者
		c.isum = atoi(p[1]);
	}
	else if (c.op == EMISS_DC_51 // 膜拜强者x次
		|| c.op == EMISS_DC_54   // 帮派捐献
		|| c.op == EMISS_DC_55   // 帮派种植
		|| c.op == EMISS_DC_56   // 普通祈福
		|| c.op == EMISS_DC_57   // 元宝祈福
		|| c.op == EMISS_DC_58   // 摇钱树
		|| c.op == EMISS_DC_60   // 出战x个神将
		|| c.op == EMISS_DC_62   // 参加过答题活动
		|| c.op == EMISS_DC_63 // 提升x次神将血脉

		|| c.op == EMISS_DC_66 // 角色达到x战斗力
		|| c.op == EMISS_DC_67 // 角色击杀的怪物数量达到x
		//|| c.op == EMISS_DC_69 // 今日活跃度超过x点
		|| c.op == EMISS_DC_70 // 累计充值超过x元
		|| c.op == EMISS_DC_72 // 购买任意成长基金
		|| c.op == EMISS_DC_74 // 挑战过封神试炼
		|| c.op == EMISS_DC_75 // 当前穿戴x件宠装
		|| c.op == EMISS_DC_77 // 神将装备强化1次
		|| c.op == EMISS_DC_79 // 分解x件神将装备
		) {
		c.isum = atoi(p[1]);
	}
	else if (c.op == EMISS_DC_52) {
		//  培养过羽翼
		c.isum = atoi(p[1]);
	}
	else if (c.op == EMISS_DC_53) {
		//  开启背包
		c.isum = atoi(p[1]);
	}
	else if (
		c.op == EMISS_DC_59 //  完成x次y任务
		|| c.op == EMISS_DC_64 // x个装备符文提升到x星
		|| c.op == EMISS_DC_65 // 装备洗练获x个x星以上属性（保存到身上才算）

		|| c.op == EMISS_DC_68 // 角色拥有x个y品质以上神将
		|| c.op == EMISS_DC_71 // x个阵法等级超过y级别
		|| c.op == EMISS_DC_73 // x神将的战力超过y点
		|| c.op == EMISS_DC_76 // 当前穿戴x套y件宠装
		|| c.op == EMISS_DC_78 // 神将装备x件强化超过y级
		|| c.op == EMISS_DC_80 // 分解x件神将装备
		|| c.op == EMISS_DC_81 // 领取指定天的登录奖励
		) {
		c.isum = atoi(p[1]);
		c.itemId = atoi(p[2]);
	}
}

bool CMissionManager::VerifyAndAcceptBranchMission(CUser *pUser,SMissionDoingContent & content, vector<int> &ivec,vector<string>& svec){
	if(pUser == NULL)
		return false;
	if (content.op == EMISS_DC_COPY) {
		const int copyIds[] = { 1, 2, 3, 4, 5, 100, 101, 102 };
		int data8Id = pUser->GetDCMissExtData8Id(content.op);
		for (size_t i = 0; i < sizeof(copyIds) / sizeof(int); ++i)
		{
			if (copyIds[i] == content.copyId)
			{
				data8Id += i;
				break;
			}
		}
		int cnt = pUser->GetExtData8(data8Id);
		if (cnt >= content.copyCompleteNum)
		{
			ivec.push_back(content.copyCompleteNum);
			return true;
		}
		ivec.push_back(cnt);
	}
	else if(content.op == EMISS_DC_8){
		//  通关寻神将任务类型：8-fubenid（寻神将副本id）-num（通关副本次数）
		int cnt = pUser->GetDCMissExtData8(content.op, content.copyId);
		if (cnt >= content.copyCompleteNum)
		{
			ivec.push_back(content.copyCompleteNum);
			return true;
		}
		ivec.push_back(cnt);
	}
	else if(content.op == EMISS_DC_9){
		//  神将招募任务类型：9-num（神将招募次数）
		ivec.push_back(0); // 保存当前次数

	}
	else if(content.op == EMISS_DC_10){
		//  猜拳玩法任务：10-1
		ivec.push_back(0); // 保存当前次数

	}
	else if (content.op == EMISS_DC_16) {
		//  世界频道发言x次：16-num（次数）
		ivec.push_back(0); // 保存当前次数

	}
	else if(content.op == EMISS_DC_17){
		//  添加x个好友：17-num（好友数）
		ivec.push_back(0); // 保存当前次数

	}
	else if(content.op == EMISS_DC_18){
		//  加入帮派：18-1
		ivec.push_back(0); // 保存当前次数

	}
	else if(content.op == EMISS_DC_19){
		//  完成x个帮派活动：19-x
		int cur = pUser->GetExtData16(146);
		if (cur > content.isum)
			cur = content.isum;
		ivec.push_back(cur); // 保存当前次数
		if(cur >= content.isum)
			return true;
	}
	else if(content.op == EMISS_DC_21){
		//  升级x个神将至x级：21-num（神将数量）-level（神将等级）
		ivec.push_back(0); // 保存当前次数
		ivec.push_back(0); // 保存当前等级

	}
	else if(content.op == EMISS_DC_22){
		//  x个神将技能提升至x级：22-num（神将技能数量）-level（技能等级）
		ivec.push_back(0); // 保存当前次数
		ivec.push_back(0); // 保存当前等级

	}
	else if(content.op == EMISS_DC_23){
		//  x个神将血脉修炼至x级：23-num（神将血脉数量）-level（修炼等级）
		ivec.push_back(0); // 保存当前次数
		ivec.push_back(0); // 保存当前次数

	}
	else if(content.op == EMISS_DC_24){
		//  任意神将升星x次：24-num
		ivec.push_back(0); // 保存当前次数

	}
	else if(content.op == EMISS_DC_25){
		//  x个人物技能提升至x级：25-num（技能数量）-level（技能等级）
		ivec.push_back(0); // 保存当前次数
		ivec.push_back(0); // 保存当前次数

	}
	else if(content.op == EMISS_DC_26){
		//  x件装备升阶至x级：26-num（装备数量）-level（装备等级）
		ivec.push_back(0); // 保存当前次数
		ivec.push_back(0); // 保存当前次数

	}
	else if(content.op == EMISS_DC_27){
		//  x件装备强化至x级：27-num（装备数量）-level（强化等级）
		ivec.push_back(0); // 保存当前次数
		ivec.push_back(0); // 保存当前次数

	}
	else if(content.op == EMISS_DC_28){
		//  装备淬炼x次：28-num
		ivec.push_back(0); // 保存当前次数

	}
	else if(content.op == EMISS_DC_29){
		//  装备洗炼x次：29-num
		ivec.push_back(0); // 保存当前次数

	}
	else if(content.op == EMISS_DC_30){
		//  挑战竞技场x：30-num
		int cur = pUser->GetExtData8(620);
		if(cur > content.isum)
			cur = content.isum;
		ivec.push_back(cur);	// 保存当前次数
		if(cur >= content.isum)
			return true;
	}
	else if(content.op == EMISS_DC_31){
		// 灵气捐献x次：31-num
		int cur = pUser->GetExtData8(66);
		if(cur > content.isum)
			cur = content.isum;
		ivec.push_back(cur);	// 保存当前次数
		if(cur >= content.isum)
			return true;
	}
	else if(content.op == EMISS_DC_32){
		//  参与多人闯关：32-1
		ivec.push_back(0); // 保存当前次数

	}
	else if(content.op == EMISS_DC_33){
		//  通关通天塔至x层：33-num（层数）
		int topFloor = pUser->GetExtData16(52);
		if(topFloor > 0)
			topFloor -= 1;
		if(topFloor >= content.isum)
			topFloor = content.isum;
		ivec.push_back(topFloor);
		if(topFloor >= content.isum)
			return true;
	}
	else if(content.op == EMISS_DC_34){
		//  挑战x次日常boss：34-num（次数）
		int cur = pUser->GetExtData8(145);
		if (cur > content.isum)
			cur = content.isum;
		ivec.push_back(cur); // 保存当前次数
		if(cur >= content.isum)
			return true;
	}
	else if(content.op == EMISS_DC_35){
		//  参与六界巡查使：35-1
		ivec.push_back(0); // 保存当前次数

	}
	else if(content.op == EMISS_DC_36){
		//  参与英勇试炼：36-1
		ivec.push_back(0); // 保存当前次数

	}
	else if(content.op == EMISS_DC_37){
		 //  参与修仙历练：37-1
		if (pUser->HaveBitSet(436))
		{
			ivec.push_back(content.isum);
			return true;
		}
		ivec.push_back(0); // 保存当前次数
	}
	else if(content.op == EMISS_DC_38){
		//  x个神将升至x星：38-num（神将数量）-star（星数)
		uint32 cur = 0;
		if (pUser->VerifyPetStarLevelAndNum(content.isum, content.star, cur))
		{
			ivec.push_back(cur);
			return true;
		}
		ivec.push_back(cur);
	}
	else if (content.op == EMISS_DC_39) {
		//  捉妖 x 次
		int cnt = pUser->GetExtData8(596);
		if (cnt >= content.isum)
			cnt = content.isum;
		ivec.push_back(cnt);
		if(cnt >= content.isum)
			return true;
	}
	else if (content.op == EMISS_DC_40) {
		//  坐骑进阶到x阶
		uint8 idx = pUser->GetMountIdxById(content.itemId);
		if (idx == 0xff)
		{
			ivec.push_back(0);
		}
		else
		{
			ivec.push_back(content.isum);
			return true;
		}
	}
	else if (content.op == EMISS_DC_41) {
		// 坐骑强化到 x 级
		int cnt = pUser->GetExtData8(597);
		if (cnt > content.isum)
			cnt = content.isum;
		ivec.push_back(cnt);
		if(cnt >= content.isum)
			return true;
	}
	else if (content.op == EMISS_DC_42) {
		// 获得神器 x
		if (pUser->isNewAShenQiActived(content.itemId))
		{
			ivec.push_back(1);
			return true;
		}
		else
		{
			ivec.push_back(0);
		}
	}
	else if (content.op == EMISS_DC_43) {
		//  培养羽翼到 x 阶段
		int cnt = pUser->GetExtData8(598);
		if (cnt > content.isum)
			cnt = content.isum;
		ivec.push_back(cnt);
		if(cnt >= content.isum)
			return true;
	}
	else if (content.op == EMISS_DC_44) {
		//  完成x次宝图任务 
		int cnt = pUser->GetExtData8(599);
		if (cnt > content.isum)
			cnt = content.isum;
		ivec.push_back(cnt);
		if(cnt >= content.isum)
			return true;
	}
	else if (content.op == EMISS_DC_45) {
		//  使用x次藏宝图
		int cnt = pUser->GetExtData8(600);
		if (cnt > content.isum)
			cnt = content.isum;
		ivec.push_back(cnt);
		if(cnt >= content.isum)
			return true;
	}
	else if (content.op == EMISS_DC_46) {
		//  使用x次高级藏宝图
		int cnt = pUser->GetExtData8(601);
		if (cnt > content.isum)
			cnt = content.isum;
		ivec.push_back(cnt);
		if(cnt >= content.isum)
			return true;
	}
	else if (content.op == EMISS_DC_47) {
		//  学习天书技能x次 // 不记录历史
		/*int cnt = pUser->GetExtData8(602);
		if (cnt > content.isum)
			cnt = content.isum;
		ivec.push_back(cnt);
		if(cnt >= content.isum)
			return true;*/
		ivec.push_back(0);
	}
	else if (content.op == EMISS_DC_48) {
		//  护送神将x次
		int cnt = pUser->GetExtData8(603);
		if (cnt > content.isum)
			cnt = content.isum;
		ivec.push_back(cnt);
		if(cnt >= content.isum)
			return true;
	}
	else if (content.op == EMISS_DC_49) {
		//   英勇试炼击败第X关守护者
		int cnt = pUser->GetExtData8(604);
		if (cnt > content.isum)
			cnt = content.isum;
		ivec.push_back(cnt);
		if(cnt >= content.isum)
			return true;

	}
	else if (content.op == EMISS_DC_51 // 膜拜强者x次
		|| content.op == EMISS_DC_54   // 帮派捐献
		|| content.op == EMISS_DC_55   // 帮派种植
		|| content.op == EMISS_DC_56   // 普通祈福
		|| content.op == EMISS_DC_57   // 元宝祈福
		|| content.op == EMISS_DC_58   // 摇钱树
		|| content.op == EMISS_DC_67   // 角色击杀的怪物数量达到x
		) {
		int cnt = pUser->GetDCMissExtData8(content.op);
		if (cnt > content.isum)
			cnt = content.isum;
		ivec.push_back(cnt);
		if(cnt >= content.isum)
			return true;

	}
	else if (content.op == EMISS_DC_70) {
		// 累计充值超过x元
		int cnt = pUser->GetExtData32(14);
		if (cnt > content.isum)
			cnt = content.isum;
		ivec.push_back(cnt);
		if (cnt >= content.isum)
			return true;
	}
	else if (content.op == EMISS_DC_52) {
		//  培养过羽翼
		if (pUser->HaveBitSet(152))
		{
			ivec.push_back(1);
			return true;
		}
		else
			ivec.push_back(0);
	}
	else if (content.op == EMISS_DC_53) {
		//  开启背包
		int cnt = pUser->GetExtData8(609);
		if (cnt > content.isum)
			cnt = content.isum;
		ivec.push_back(cnt);
		if(cnt >= content.isum)
			return true;
	}
	else if (content.op == EMISS_DC_60) {
		//  出战x个神将
		vector<SZhenFaMemData> zhenfaMembers;
		pUser->GetZhenFaMember(zhenfaMembers);
		uint8 size = zhenfaMembers.size();
		int cnt = 0;
		for (uint8 i = 0; i < size; i++)
		{
			if (zhenfaMembers[i].mem_type == EZFMT_PET)
				cnt++;
		}
		if (cnt > content.isum)
			cnt = content.isum;
		ivec.push_back(cnt);
		if(cnt >= content.isum)
			return true;
	}
	else if (content.op == EMISS_DC_61) {
		ivec.push_back(0);
		ivec.push_back(content.itemId);
		ivec.push_back(content.isum);
	}
	else if (content.op == EMISS_DC_59) {//  完成x次y任务
		int cnt = pUser->GetDailyMissCompleteCnt(content.itemId);
		if (cnt > content.isum)
			cnt = content.isum;
		ivec.push_back(cnt);
		if (cnt >= content.isum)
			return true;
	}
	else if (content.op == EMISS_DC_62) {//  参加过答题活动
		int cnt = 0;
		if (pUser->HaveBitSet(433))
			cnt = content.isum;
		ivec.push_back(cnt);
		if (cnt >= content.isum)
			return true;
	}
	else if (content.op == EMISS_DC_63) {//  提升x次神将血脉
		ivec.push_back(0);
	}
	else if (content.op == EMISS_DC_64) {// x个装备符文提升到x星

	}
	else if (content.op == EMISS_DC_65) { // 装备洗练获x个x星以上属性（保存到身上才算）

	}
	// add at 20190308 by zqx
	else if (content.op == EMISS_DC_66) { // 角色达到x战斗力
		int cnt = pUser->GetZhanDouLi();
		if (cnt > content.isum)
			cnt = content.isum;
		ivec.push_back(cnt);
		if (cnt >= content.isum)
			return true;
	}
	else if (content.op == EMISS_DC_68) { // 角色拥有x个y品质以上神将
		uint32 cnt = 0;
		bool isComplate = pUser->VerifyUserPetQualityAndNum(content.isum, content.itemId, cnt);
		ivec.push_back(cnt);
		if (isComplate)
			return true;
	}
	//else if (content.op == EMISS_DC_69) { // 今日活跃度超过x点
	//	int cnt = 0;

	//	if (cnt > content.isum)
	//		cnt = content.isum;
	//	ivec.push_back(cnt);
	//	if (cnt >= content.isum)
	//		return true;
	//}
	else if (content.op == EMISS_DC_71) { // x个阵法等级超过y级别
		uint32 cnt = 0;
		bool isComplate = pUser->VerifyUserLevelFormationNum(content.isum, content.itemId, cnt);
		ivec.push_back(cnt);
		if (isComplate)
			return true;
	}
	else if (content.op == EMISS_DC_72) { // 购买任意成长基金
		int cnt = 0;
		if (pUser->HaveBitSet(434))
		{
			cnt = 1;
		}
		if (cnt > content.isum)
			cnt = content.isum;
		ivec.push_back(cnt);
		if (cnt >= content.isum)
			return true;
	}
	else if (content.op == EMISS_DC_73) { // x神将的战力超过y点
		uint32 cnt = 0;
		bool isComplate = pUser->VerifyUserPetPowerNum(content.isum, content.itemId, cnt);
		ivec.push_back(cnt);
		if (isComplate)
			return true;
	}
	else if (content.op == EMISS_DC_74) {//  挑战过封神试炼
		int cnt = 0;
		if (pUser->HaveBitSet(435))
			cnt = content.isum;
		ivec.push_back(cnt);
		if (cnt >= content.isum)
			return true;
	}
	else if (content.op == EMISS_DC_78) { // 神将装备x件强化超过y级
		uint32 cnt = 0;
		bool isComplate = pUser->VerifyUserPetEquipStrongLevelNum(content.isum, content.itemId, cnt);
		ivec.push_back(cnt);
		if (isComplate)
			return true;
	}
	else if (content.op == EMISS_DC_77) {
		ivec.push_back(0);
	}
	else if (content.op == EMISS_DC_79) { // 分解x件神将装备
		ivec.push_back(0);
	}
	else if (content.op == EMISS_DC_80) { // 获得神将x
		ivec.push_back(0);
		bool isComplate = pUser->HavePet(content.itemId);
		ivec.push_back(isComplate);
		if (isComplate)
			return true;
	}
	else if (content.op == EMISS_DC_81) { // 领取指定天的登录奖励
		bool isComplate = pUser->HaveBitSet(280 + content.itemId);
		ivec.push_back(isComplate);
		if (isComplate)
			return true;
	}
	return false;
}

void CMissionManager::DoVerifyNewBranchMission(CUser *pUser, int mid, int cur, int isum){
//	cout<<"DoVerifyNewBranchMission mid = "<<mid<<endl;
	if(cur >= isum){
		pUser->UpdateCMissionState(mid, EMISS_STATE_FINISH);
	}else{
		SendCMissionTrackMsg(pUser, mid);
	}
}

// ----------------------------------------------
// 更新新支线任务,在其他模块调用
int CMissionManager::GetSMissionDoingContentLevelVal(CUser* pUser, int mid){
	if(pUser == NULL){
//		cout<<"GetSMissionDoingContentLevelVal pUser = NULL"<< endl;
		return 0 ;
	}
	boost::unordered_map<int,SMissionConfig>::iterator it = m_missions.find(mid);
	if(it == m_missions.end()){
//		cout<<"GetSMissionDoingContentLevelVal it = NULL ,mid = "<<mid<<endl;
		return 0 ;
	}
	SMissionConfig &cfg = it->second;
	SMissionDoingContent &content = cfg.doing_content;
	int level = content.level;
	return level;
}

// ----------------------------------------------
// 更新新支线任务,在其他模块调用
void CMissionManager::VerifyNewBranchMissionFinish(CUser* pUser, int mtype, int num , int cond){
//	cout<<"VerifyNewBranchMissionFinish  mtype = "<<mtype<< endl;
	if(pUser == NULL){
//		cout<<"VerifyNewBranchMissionFinish pUser = NULL"<< endl;
		return;
	}

	std::vector<uint32 > midvec;
	GetMissionIdByOp(pUser, mtype, midvec);
	if(midvec.empty()){
//		cout<<"VerifyNewBranchMissionFinish op error , op = "<<mtype<< endl;
		return ;
	}

	std::vector<uint32>::iterator it = midvec.begin();
	for(; it != midvec.end(); it++){
		uint32 mid = *it;
		boost::unordered_map<int,SMissionConfig>::iterator it = m_missions.find(mid);
		if(it == m_missions.end()){
//			cout<<"VerifyNewBranchMissionFinish it  = NULL ,mid = "<<mid<<endl;
			continue;
		}

		SMissionConfig &cfg = it->second;
		SMissionDoingContent &content = cfg.doing_content;
		SAcceptMission *pMiss = pUser->m_missList.GetAcceptedCMission(mid);
		if(pMiss == NULL){
//			cout<<"VerifyNewBranchMissionFinish pMiss = NULL, mid = "<<mid<<endl;
			continue;
		}
		if (content.op == EMISS_DC_COPY) {
			//  通关寻神将任务类型：8-fubenid（寻神将副本id）-num（通关副本次数）
			int cur = pMiss->save_var[0];
			if (cond != content.copyId || cur >= content.copyCompleteNum) {
				// ===============
				// 不是同一个任务 或 任务完成 发奖 删除任务 
				continue;
			}

			cur += num;
			pMiss->save_var[0] = cur;
			DoVerifyNewBranchMission(pUser, mid, cur, content.isum);
		}
		else if (content.op == EMISS_DC_8) {
			//  通关寻神将任务类型：8-fubenid（寻神将副本id）-num（通关副本次数）
			int cur = pMiss->save_var[0];
			if(cond != content.copyId
				&& cur >= content.copyCompleteNum){
				// ===============
				// 不是同一个任务 或  任务完成 发奖 删除任务 
				continue;
			}

			cur += num;
			pMiss->save_var[0] = cur;
			DoVerifyNewBranchMission(pUser, mid, cur, content.isum);
		}
		else if(content.op == EMISS_DC_9){
			//  神将招募任务类型：9-num（神将招募次数）
			int cur = pMiss->save_var[0];
			if(cur >= content.isum){
				// ===============
				// 任务完成 发奖 删除任务 
				continue;
			}
			cur += num; 
			if(cur >= content.isum){
				cur = content.isum;
			}
			pMiss->save_var[0] = cur;
			DoVerifyNewBranchMission(pUser, mid, cur, content.isum);
		}
		else if(content.op == EMISS_DC_10){
			//  猜拳玩法任务：10-1
			int cur = pMiss->save_var[0];
			if(cur >= content.isum){
				// ===============
				// 任务完成 发奖 删除任务 
				continue;
			}
			cur+=num; 
			pMiss->save_var[0] = cur;
			DoVerifyNewBranchMission(pUser, mid, cur, content.isum);
		}
		else if (content.op == EMISS_DC_16) {
			//  世界频道发言x次：16-num（次数）
			int cur = pMiss->save_var[0];
			if(cur >= content.isum){
				// ===============
				// 任务完成 发奖 删除任务 
				continue;
			}
			cur+=num; 
			pMiss->save_var[0] = cur;
			DoVerifyNewBranchMission(pUser, mid, cur, content.isum);

		}
		else if(content.op == EMISS_DC_17){
			//  添加x个好友：17-num（好友数）
			int cur = pMiss->save_var[0];
			if(cur >= content.isum){
				// ===============
				// 任务完成 发奖 删除任务 
				continue;
			}
			cur+=num; 
			pMiss->save_var[0] = cur;
			DoVerifyNewBranchMission(pUser, mid, cur, content.isum);
		}
		else if(content.op == EMISS_DC_18){
			//  加入帮派：18-1
			int cur = pMiss->save_var[0];
			if(cur >= content.isum){
				// ===============
				// 任务完成 发奖 删除任务 
				continue;
			}
			cur+=num; 
			pMiss->save_var[0] = cur;
			DoVerifyNewBranchMission(pUser, mid, cur, content.isum);
		}
		else if(content.op == EMISS_DC_19){
			//  完成x个帮派活动：19-x
			int cur = pMiss->save_var[0];
			if (cur >= content.isum) {
				// ===============
				// 任务完成 发奖 删除任务 
				continue;
			}
			cur += num;
			pMiss->save_var[0] = cur;
			DoVerifyNewBranchMission(pUser, mid, cur, content.isum);
		}
		else if(content.op == EMISS_DC_21){
			uint32 cur = 0;
			if (pUser->VerifyPetLevelAndNum(content.isum, content.level, cur)) {
				pMiss->save_var[0] = cur;
				pMiss->state = EMISS_STATE_FINISH;
			}
			else {
				pMiss->save_var[0] = cur;
			}
			DoVerifyNewBranchMission(pUser, mid, cur, content.isum);
		}
		else if(content.op == EMISS_DC_22){
			//  x个神将技能提升至x级：22-num（神将技能数量）-level（技能等级）
			uint32 cur = 0;
			if (pUser->VerifyPetSkillLevelAndNum(content.isum, content.level, cur)) {
				pMiss->save_var[0] = cur;
				pMiss->state = EMISS_STATE_FINISH;
			}
			else {
				pMiss->save_var[0] = cur;
			}
			DoVerifyNewBranchMission(pUser, mid, cur, content.isum);
		}
		else if(content.op == EMISS_DC_23){
			//  x个神将血脉修炼至x级：23-num（神将血脉数量）-level（修炼等级）
			uint32 cur = 0;
			if (pUser->VerifyPetXueMaiLevelAndNum(content.isum, content.level, cur)) {
				pMiss->save_var[0] = cur;
				pMiss->state = EMISS_STATE_FINISH;
			}
			else {
				pMiss->save_var[0] = cur;
			}
			DoVerifyNewBranchMission(pUser, mid, cur, content.isum);
		}
		else if(content.op == EMISS_DC_24){
			//  任意神将升星x次：24-num 不记录历史
			int cur = pMiss->save_var[0];
			if (cur >= content.isum) {
				continue;
			}

			cur += num;
			pMiss->save_var[0] = cur;
			DoVerifyNewBranchMission(pUser, mid, cur, content.isum);
		}
		else if(content.op == EMISS_DC_25){
			//  x个人物技能提升至x级：25-num（技能数量）-level（技能等级）
			int cur = pMiss->save_var[0];
			if(cur >= content.isum){
				// ===============
				// 任务完成 发奖 删除任务 
				continue;
			}
			
			if(cond != content.level){
				continue;
			}

			cur+=num; 
			pMiss->save_var[0] = cur;
			DoVerifyNewBranchMission(pUser, mid, cur, content.isum);
		}
		else if(content.op == EMISS_DC_26){
			//  x件装备升阶至x级：26-num（装备数量）-level（装备等级）

		}
		else if(content.op == EMISS_DC_27){
			//  x件装备强化至x级：27-num（装备数量）-level（强化等级）

		}
		else if(content.op == EMISS_DC_28){
			//  装备淬炼x次：28-num
			int cur = pMiss->save_var[0];
			if(cur >= content.isum){
				// ===============
				// 任务完成 发奖 删除任务 
				continue;
			}
			cur+=num; 
			pMiss->save_var[0] = cur;
			DoVerifyNewBranchMission(pUser, mid, cur, content.isum);
		}
		else if(content.op == EMISS_DC_29){
			//  装备洗炼x次：29-num
			int cur = pMiss->save_var[0];
			if(cur >= content.isum){
				// ===============
				// 任务完成 发奖 删除任务 
				continue;
			}
			cur+=num; 
			pMiss->save_var[0] = cur;
			DoVerifyNewBranchMission(pUser, mid, cur, content.isum);
		}
		else if(content.op == EMISS_DC_30){
			//  挑战竞技场x：30-num
			int cur = pMiss->save_var[0];
			if(cur >= content.isum){
				// ===============
				// 任务完成 发奖 删除任务 
				continue;
			}
			cur+=num; 
			pMiss->save_var[0] = cur;
			DoVerifyNewBranchMission(pUser, mid, cur, content.isum);
		}
		else if(content.op == EMISS_DC_31){
			// 灵气捐献x次：31-num
			int cur = pMiss->save_var[0];
			if(cur >= content.isum){
				// ===============
				// 任务完成 发奖 删除任务 
				continue;
			}
			cur+=num; 
			pMiss->save_var[0] = cur;
			DoVerifyNewBranchMission(pUser, mid, cur, content.isum);
		}
		else if(content.op == EMISS_DC_32){
			//  参与多人闯关：32-1
			int cur = pMiss->save_var[0];
			if(cur >= content.isum){
				// ===============
				// 任务完成 发奖 删除任务 
				continue;
			}
			cur+=num;  
			pMiss->save_var[0] = cur;
			DoVerifyNewBranchMission(pUser, mid, cur, content.isum);
		}
		else if(content.op == EMISS_DC_33){
			//  通关通天塔至x层：33-num（层数）
			int cur = pMiss->save_var[0];
			if(cur > content.isum)
				cur = content.isum;
			cond -= 1;
			if(cond > cur && cond <= content.isum)
			{
				cur = cond;
				pMiss->save_var[0] = cur;
				DoVerifyNewBranchMission(pUser, mid, cur, content.isum);
			}

/*
			int curlayer = pMiss->save_var[1]; 
			if(level < content.isum && level >= curlayer){
				pMiss->save_var[1] = level; // 本次比历史记录高
			}
			if(level >= content.isum){
				cur = content.isum; 
				pMiss->save_var[1] = content.isum; // 本次比历史记录高
			}
*/
			
		}
		else if(content.op == EMISS_DC_34){
			//  挑战x次日常boss：34-num（次数）
			int cur = pMiss->save_var[0];
			if(cur >= content.isum){
				// ===============
				// 任务完成 发奖 删除任务 
				continue;
			}
			cur+=num; 
			pMiss->save_var[0] = cur;
			DoVerifyNewBranchMission(pUser, mid, cur, content.isum);
		}
		else if(content.op == EMISS_DC_35){
			//  参与六界巡查使：35-1
			int cur = pMiss->save_var[0];
			if(cur >= content.isum){
				// ===============
				// 任务完成 发奖 删除任务 
				continue;
			}
			cur+=num; 
			pMiss->save_var[0] = cur;
			DoVerifyNewBranchMission(pUser, mid, cur, content.isum);
		}
		else if(content.op == EMISS_DC_36){
			//  参与英勇试炼：36-1
			int cur = pMiss->save_var[0];
			if(cur >= content.isum){
				// ===============
				// 任务完成 发奖 删除任务 
				continue;
			}
			cur+=num; 
			pMiss->save_var[0] = cur;
			DoVerifyNewBranchMission(pUser, mid, cur, content.isum);
		}
		else if(content.op == EMISS_DC_37){
			//  参与修仙历练：37-1
			int cur = pMiss->save_var[0];
			if(cur >= content.isum){
				// ===============
				// 任务完成 发奖 删除任务 
				continue;
			}
			cur+=num; 
			pMiss->save_var[0] = cur;
			DoVerifyNewBranchMission(pUser, mid, cur, content.isum);
		}
		else if(content.op == EMISS_DC_38){
			//  x个神将升至x星：38-num（神将数量）-star（星数)
			uint32 cur = 0;
			if (pUser->VerifyPetStarLevelAndNum(content.isum, content.star, cur)) {
				pMiss->save_var[0] = cur;
				pMiss->state = EMISS_STATE_FINISH;
			}
			else {
				pMiss->save_var[0] = cur;
			}
			pMiss->save_var[0] = cur;
			DoVerifyNewBranchMission(pUser, mid, cur, content.isum);
		}
		else if (content.op == EMISS_DC_39  // 捉妖 x 次
			|| content.op == EMISS_DC_41    // 坐骑强化到 x 级
			|| content.op == EMISS_DC_43    // 培养羽翼到 x 阶段
			|| content.op == EMISS_DC_44    // 完成x次宝图任务 
			|| content.op == EMISS_DC_45    // 使用x次藏宝图
			|| content.op == EMISS_DC_46    // 使用x次高级藏宝图
			|| content.op == EMISS_DC_47    // 学习天书技能x次
			|| content.op == EMISS_DC_48    // 护送神将x次
			|| content.op == EMISS_DC_49    // 英勇试炼击败第X关守护者
			|| content.op == EMISS_DC_51    // 膜拜强者x次
			|| content.op == EMISS_DC_53    // 开启背包x次
			|| content.op == EMISS_DC_52    // 培养过羽翼
			|| content.op == EMISS_DC_54    // 帮派捐献
			|| content.op == EMISS_DC_55    // 帮派种植
			|| content.op == EMISS_DC_56    // 普通祈福
			|| content.op == EMISS_DC_57    // 元宝祈福
			|| content.op == EMISS_DC_58    // 摇钱树
			|| content.op == EMISS_DC_60    // 出战x个神将
			|| content.op == EMISS_DC_67    // 角色击杀的怪物数量达到x
			|| content.op == EMISS_DC_77    // 神将装备强化1次
			|| content.op == EMISS_DC_79    // 分解x件神将装备
			) {
			if (pMiss->save_var.empty())
			{
				pMiss->save_var.push_back(0);
			}
			int cur = pMiss->save_var[0];
			if (cur >= content.isum) {
				// ===============
				// 任务完成 发奖 删除任务 
				continue;
			}

			cur += num;
			pMiss->save_var[0] = cur;
			DoVerifyNewBranchMission(pUser, mid, cur, content.isum);
		}
		else if (content.op == EMISS_DC_40) {
			// 获得坐骑
			if (content.itemId == num)
			{
				pMiss->save_var[0] = 1;
				DoVerifyNewBranchMission(pUser, mid, pMiss->save_var[0], content.isum);
			}
		}
		else if (content.op == EMISS_DC_42) {
			// 获得神器 x
			if (content.itemId == num)
			{
				pMiss->save_var[0] = 1;
				DoVerifyNewBranchMission(pUser, mid, pMiss->save_var[0], content.isum);
			}
		}
		else if (content.op == EMISS_DC_61) {
			// 购买物品
			if (content.itemId == num)
			{
				pMiss->save_var[0] += cond;
				DoVerifyNewBranchMission(pUser, mid, pMiss->save_var[0], content.isum);
			}
		}
		else if (content.op == EMISS_DC_59) {
			if (pMiss->save_var.empty())
			{
				pMiss->save_var.push_back(0);
			}
			// 完成x次y任务
			if (content.itemId == cond)
			{
				if (pMiss->save_var.empty())
				{
					pMiss->save_var.push_back(0);
				}
				pMiss->save_var[0] += num;
				if (pMiss->save_var[0] > content.isum)
				{
					pMiss->save_var[0] = content.isum;
				}
				DoVerifyNewBranchMission(pUser, mid, pMiss->save_var[0], content.isum);
			}
		}
		else if (content.op == EMISS_DC_62) {// 参加过答题活动
			if (pMiss->save_var.empty())
			{
				pMiss->save_var.push_back(0);
			}
			int cur = pMiss->save_var[0];
			if (cur >= content.isum) {
				// ===============
				// 任务完成 发奖 删除任务 
				continue;
			}

			cur += num;
			pMiss->save_var[0] = cur;
			DoVerifyNewBranchMission(pUser, mid, cur, content.isum);
		}
		else if (content.op == EMISS_DC_63) {// 提升x次神将血脉
			if (pMiss->save_var.empty())
			{
				pMiss->save_var.push_back(0);
			}
			int cur = pMiss->save_var[0];
			if (cur >= content.isum) {
				// ===============
				// 任务完成 发奖 删除任务 
				continue;
			}

			cur += num;
			pMiss->save_var[0] = cur;
			DoVerifyNewBranchMission(pUser, mid, cur, content.isum);
		}
		else if (content.op == EMISS_DC_64) { // x个装备符文提升到x星

		}
		else if (content.op == EMISS_DC_65) {
			// 装备洗练获x个x星以上属性（保存到身上才算）

		}
		else if (content.op == EMISS_DC_66) {
			// 角色达到x战斗力
			if (pMiss->save_var.empty())
			{
				pMiss->save_var.push_back(0);
			}
			int curNum = pUser->GetZhanDouLi();
			if (curNum > content.isum)
			{
				curNum = content.isum;
			}
			pMiss->save_var[0] = curNum;
			DoVerifyNewBranchMission(pUser, mid, curNum, content.isum);
		}
		else if (content.op == EMISS_DC_68) {
			// 角色拥有x个y品质以上神将
			if (pMiss->save_var.empty())
			{
				pMiss->save_var.push_back(0);
			}
			uint32 curNum = 0;
			pUser->VerifyUserPetQualityAndNum(content.isum, content.itemId, curNum);
			if (curNum > (uint32)content.isum)
			{
				curNum = content.isum;
			}
			pMiss->save_var[0] = curNum;
			DoVerifyNewBranchMission(pUser, mid, curNum, content.isum);
		}
		else if (content.op == EMISS_DC_70) {
			// 累计充值超过x元
			if (pMiss->save_var.empty())
			{
				pMiss->save_var.push_back(0);
			}
			uint32 curNum = pUser->GetExtData32(14);
			if (curNum > (uint32)content.isum)
			{
				curNum = content.isum;
			}
			pMiss->save_var[0] = curNum;
			DoVerifyNewBranchMission(pUser, mid, curNum, content.isum);
		}
		else if (content.op == EMISS_DC_71) {
			// x个阵法等级超过y级别
			if (pMiss->save_var.empty())
			{
				pMiss->save_var.push_back(0);
			}
			uint32 curNum = 0;
			pUser->VerifyUserLevelFormationNum(content.isum, content.itemId, curNum);
			if (curNum > (uint32)content.isum)
			{
				curNum = content.isum;
			}
			pMiss->save_var[0] = curNum;
			DoVerifyNewBranchMission(pUser, mid, curNum, content.isum);
		}
		else if (content.op == EMISS_DC_72) {
			// 购买任意成长基金
			if (pMiss->save_var.empty())
			{
				pMiss->save_var.push_back(0);
			}
			int curNum = 0;
			if (pUser->HaveBitSet(434))
			{
				curNum = content.isum;
			}
			pMiss->save_var[0] = curNum;
			DoVerifyNewBranchMission(pUser, mid, curNum, content.isum);
		}
		else if (content.op == EMISS_DC_73) {
			// x神将的战力超过y点
			if (pMiss->save_var.empty())
			{
				pMiss->save_var.push_back(0);
			}
			uint32 curNum = 0;
			pUser->VerifyUserPetPowerNum(content.isum, content.itemId, curNum);
			if (curNum > (uint32)content.isum)
			{
				curNum = content.isum;
			}
			pMiss->save_var[0] = curNum;
			DoVerifyNewBranchMission(pUser, mid, curNum, content.isum);
		}
		else if (content.op == EMISS_DC_74) {// 挑战过封神试炼
			if (pMiss->save_var.empty())
			{
				pMiss->save_var.push_back(0);
			}
			int cur = pMiss->save_var[0];
			if (cur >= content.isum) {
				// ===============
				// 任务完成 发奖 删除任务 
				continue;
			}

			cur += num;
			pMiss->save_var[0] = cur;
			DoVerifyNewBranchMission(pUser, mid, cur, content.isum);
		}
		else if (content.op == EMISS_DC_78) {// 当前穿戴x套y件宠装
			if (pMiss->save_var.empty())
			{
				pMiss->save_var.push_back(0);
			}
			int cur = pMiss->save_var[0];
			if (cur >= content.isum) {
				// ===============
				// 任务完成 发奖 删除任务 
				continue;
			}

			uint32 cnt = 0;
			pUser->VerifyUserPetEquipStrongLevelNum(content.isum, content.itemId, cnt);
			if (cnt > (uint32)content.isum)
			{
				cnt = content.isum;
			}
			pMiss->save_var[0] = cnt;
			DoVerifyNewBranchMission(pUser, mid, cnt, content.isum);
		}
		else if (content.op == EMISS_DC_80) {
			// 拥有神将
			if (pMiss->save_var.empty())
				pMiss->save_var.push_back(0);
			if (content.itemId == num)
			{
				pMiss->save_var[0] = 1;
				DoVerifyNewBranchMission(pUser, mid, pMiss->save_var[0], content.isum);
			}
		}
		else if (content.op == EMISS_DC_81) { // 领取指定天的登录奖励
			if (pMiss->save_var.empty())
				pMiss->save_var.push_back(0);
			if (pUser->HaveBitSet(280 + content.itemId))
			{
				pMiss->save_var[0] = 1;
				DoVerifyNewBranchMission(pUser, mid, pMiss->save_var[0], content.isum);
			}
		}
	}
}

void CMissionManager::UpdateDCMissionComplate(CUser *pUser, int mid, int num/* = 1*/, int cond/* = 0*/)
{
	if (mid == EMISS_DC_40
		|| mid == EMISS_DC_47
		|| mid == EMISS_DC_52
		|| mid == EMISS_DC_70
		|| mid == EMISS_DC_61)
	{
		VerifyNewBranchMissionFinish(pUser, mid, num, cond);
		return;
	}
	else if (mid == EMISS_DC_59)
	{
		pUser->AddDailyMissCompleteCnt(cond);
		VerifyNewBranchMissionFinish(pUser, mid, num, cond);
		return;
	}
	int extData8 = pUser->GetDCMissExtData8Id(mid);
	if (mid == EMISS_DC_COPY)
	{
		const int copyIds[] = { 1, 2, 3, 4, 5, 100, 101, 102 };
		for (size_t i = 0; i < sizeof(copyIds) / sizeof(int); ++i)
		{
			if (copyIds[i] == cond)
			{
				extData8 += i;
				break;
			}
		}
	}
	else
	{
		extData8 += cond;
	}

	int curNum = pUser->GetExtData8(extData8);
	if (curNum < 255)
	{
		pUser->SetExtData8(extData8, curNum + num);
	}
	VerifyNewBranchMissionFinish(pUser, mid, num, cond);
}

void CMissionManager::SendNewBranchTrackMsg(SMissionDoingContent &content, SAcceptMission *pMiss, vector<SReplaceStringData>& replace){
	//vector<SReplaceStringData> replace;
	
	if(content.op == EMISS_DC_8){
		//  通关寻神将任务类型：8-fubenid（寻神将副本id）-num（通关副本次数）
		replace.push_back(SReplaceStringData("<name>",GetFuBenName(content.copyId)));
		replace.push_back(SReplaceStringData("<num>",IntToStr(pMiss->save_var[0]).c_str()));
		replace.push_back(SReplaceStringData("<maxnum>",IntToStr(content.copyCompleteNum).c_str()));
	}
	else if(content.op == EMISS_DC_9){
		//  神将招募任务类型：9-num（神将招募次数）
		replace.push_back(SReplaceStringData("<num>",IntToStr(pMiss->save_var[0]).c_str()));
		replace.push_back(SReplaceStringData("<maxnum>",IntToStr(content.isum).c_str()));
	}
	else if(content.op == EMISS_DC_10){
		//  猜拳玩法任务：10-1
		replace.push_back(SReplaceStringData("<num>",IntToStr(pMiss->save_var[0]).c_str()));
		replace.push_back(SReplaceStringData("<maxnum>",IntToStr(content.isum).c_str()));

	}
	else if (content.op == EMISS_DC_16) {
		//  世界频道发言x次：16-num（次数）
		replace.push_back(SReplaceStringData("<num>",IntToStr(pMiss->save_var[0]).c_str()));
		replace.push_back(SReplaceStringData("<maxnum>",IntToStr(content.isum).c_str()));

	}
	else if(content.op == EMISS_DC_17){
		//  添加x个好友：17-num（好友数）
		replace.push_back(SReplaceStringData("<num>",IntToStr(pMiss->save_var[0]).c_str()));
		replace.push_back(SReplaceStringData("<maxnum>",IntToStr(content.isum).c_str()));
	}
	else if(content.op == EMISS_DC_18){
		//  加入帮派：18-1
		replace.push_back(SReplaceStringData("<num>",IntToStr(pMiss->save_var[0]).c_str()));
		replace.push_back(SReplaceStringData("<maxnum>",IntToStr(content.isum).c_str()));

	}
	else if(content.op == EMISS_DC_19){
		//  完成x个帮派活动：19-x
		replace.push_back(SReplaceStringData("<num>",IntToStr(pMiss->save_var[0]).c_str()));
		replace.push_back(SReplaceStringData("<maxnum>",IntToStr(content.isum).c_str()));
	}
	else if(content.op == EMISS_DC_21){
		//  升级x个神将至x级：21-num（神将数量）-level (神将等级)
		replace.push_back(SReplaceStringData("<num>",IntToStr(pMiss->save_var[0]).c_str()));
		replace.push_back(SReplaceStringData("<maxnum>",IntToStr(content.isum).c_str()));
		replace.push_back(SReplaceStringData("<level>",IntToStr(content.level).c_str()));
	}
	else if(content.op == EMISS_DC_22){
		//  x个神将技能提升至x级：22-num（神将技能数量）-level（技能等级）
		replace.push_back(SReplaceStringData("<num>",IntToStr(pMiss->save_var[0]).c_str()));
		replace.push_back(SReplaceStringData("<maxnum>",IntToStr(content.isum).c_str()));
		replace.push_back(SReplaceStringData("<level>",IntToStr(content.level).c_str()));
	}
	else if(content.op == EMISS_DC_23){
		//  x个神将血脉修炼至x级：23-num（神将血脉数量）-level（修炼等级）
		replace.push_back(SReplaceStringData("<num>",IntToStr(pMiss->save_var[0]).c_str()));
		replace.push_back(SReplaceStringData("<maxnum>",IntToStr(content.isum).c_str()));
		replace.push_back(SReplaceStringData("<level>",IntToStr(content.level).c_str()));
	}
	else if(content.op == EMISS_DC_24){
		//  任意神将升星x次：24-num
		replace.push_back(SReplaceStringData("<num>",IntToStr(pMiss->save_var[0]).c_str()));
		replace.push_back(SReplaceStringData("<maxnum>",IntToStr(content.isum).c_str()));
	}
	else if(content.op == EMISS_DC_25){
		//  x个人物技能提升至x级：25-num（技能数量）-level（技能等级）
		replace.push_back(SReplaceStringData("<num>",IntToStr(pMiss->save_var[0]).c_str()));
		replace.push_back(SReplaceStringData("<maxnum>",IntToStr(content.isum).c_str()));
		replace.push_back(SReplaceStringData("<level>",IntToStr(content.level).c_str()));
	}
	else if(content.op == EMISS_DC_26){
		//  x件装备升阶至x级：26-num（装备数量）-level（装备等级）
		replace.push_back(SReplaceStringData("<num>",IntToStr(pMiss->save_var[0]).c_str()));
		replace.push_back(SReplaceStringData("<maxnum>",IntToStr(content.isum).c_str()));
		replace.push_back(SReplaceStringData("<level>",IntToStr(content.level).c_str()));
	}
	else if(content.op == EMISS_DC_27){
		//  x件装备强化至x级：27-num（装备数量）-level（强化等级）
		replace.push_back(SReplaceStringData("<num>",IntToStr(pMiss->save_var[0]).c_str()));
		replace.push_back(SReplaceStringData("<maxnum>",IntToStr(content.isum).c_str()));
		replace.push_back(SReplaceStringData("<level>",IntToStr(content.level).c_str()));
	}
	else if(content.op == EMISS_DC_28){
		//  装备淬炼x次：28-num
		replace.push_back(SReplaceStringData("<num>",IntToStr(pMiss->save_var[0]).c_str()));
		replace.push_back(SReplaceStringData("<maxnum>",IntToStr(content.isum).c_str()));
	}
	else if(content.op == EMISS_DC_29){
		//  装备洗炼x次：29-num
		replace.push_back(SReplaceStringData("<num>",IntToStr(pMiss->save_var[0]).c_str()));
		replace.push_back(SReplaceStringData("<maxnum>",IntToStr(content.isum).c_str()));
	}
	else if(content.op == EMISS_DC_30){
		//  挑战竞技场x：30-num
		replace.push_back(SReplaceStringData("<num>",IntToStr(pMiss->save_var[0]).c_str()));
		replace.push_back(SReplaceStringData("<maxnum>",IntToStr(content.isum).c_str()));
	}
	else if(content.op == EMISS_DC_31){
		// 灵气捐献x次：31-num
		replace.push_back(SReplaceStringData("<num>",IntToStr(pMiss->save_var[0]).c_str()));
		replace.push_back(SReplaceStringData("<maxnum>",IntToStr(content.isum).c_str()));
	}
	else if(content.op == EMISS_DC_32){
		//  参与多人闯关：32-1
		replace.push_back(SReplaceStringData("<num>",IntToStr(pMiss->save_var[0]).c_str()));
		replace.push_back(SReplaceStringData("<maxnum>",IntToStr(content.isum).c_str()));
	}
	else if(content.op == EMISS_DC_33){
		//  通关通天塔至x层：33-num（层数）
		replace.push_back(SReplaceStringData("<num>",IntToStr(pMiss->save_var[0]).c_str()));
		replace.push_back(SReplaceStringData("<maxnum>",IntToStr(content.isum).c_str()));
	}
	else if(content.op == EMISS_DC_34){
		//  挑战x次日常boss：34-num（次数）
		replace.push_back(SReplaceStringData("<num>",IntToStr(pMiss->save_var[0]).c_str()));
		replace.push_back(SReplaceStringData("<maxnum>",IntToStr(content.isum).c_str()));
	}
	else if(content.op == EMISS_DC_35){
		//  参与六界巡查使：35-1
		replace.push_back(SReplaceStringData("<num>",IntToStr(pMiss->save_var[0]).c_str()));
		replace.push_back(SReplaceStringData("<maxnum>",IntToStr(content.isum).c_str()));
	}
	else if(content.op == EMISS_DC_36){
		//  参与英勇试炼：36-1
		replace.push_back(SReplaceStringData("<num>",IntToStr(pMiss->save_var[0]).c_str()));
		replace.push_back(SReplaceStringData("<maxnum>",IntToStr(content.isum).c_str()));
	}
	else if(content.op == EMISS_DC_37){
		 //  参与修仙历练：37-1
		replace.push_back(SReplaceStringData("<num>",IntToStr(pMiss->save_var[0]).c_str()));
		replace.push_back(SReplaceStringData("<maxnum>",IntToStr(content.isum).c_str()));
	}
	else if(content.op == EMISS_DC_38){
		//  x个神将升至x星：38-num（神将数量）-star（星数)
		replace.push_back(SReplaceStringData("<num>",IntToStr(pMiss->save_var[0]).c_str()));
		replace.push_back(SReplaceStringData("<maxnum>",IntToStr(content.isum).c_str()));
		replace.push_back(SReplaceStringData("<level>",IntToStr(content.star).c_str()));	
	}
	else if (content.op == EMISS_DC_39  // 捉妖 x 次
		|| content.op == EMISS_DC_16    // 世界频道发言x次：16-num（次数）
		|| content.op == EMISS_DC_41    // 坐骑强化到 x 级
		|| content.op == EMISS_DC_43    // 培养羽翼到 x 阶段
		|| content.op == EMISS_DC_44    // 完成x次宝图任务 
		|| content.op == EMISS_DC_45    // 使用x次藏宝图
		|| content.op == EMISS_DC_46    // 使用x次高级藏宝图
		|| content.op == EMISS_DC_47    // 学习天书技能x次
		|| content.op == EMISS_DC_48    // 护送神将x次
		|| content.op == EMISS_DC_49    // 英勇试炼击败第X关守护者
		|| content.op == EMISS_DC_51    // 膜拜强者x次
		|| content.op == EMISS_DC_53    // 开启背包x次
		|| content.op == EMISS_DC_52    // 培养过羽翼
		|| content.op == EMISS_DC_54    // 帮派捐献
		|| content.op == EMISS_DC_55    // 帮派种植
		|| content.op == EMISS_DC_56    // 普通祈福
		|| content.op == EMISS_DC_57    // 元宝祈福
		|| content.op == EMISS_DC_58    // 摇钱树
		|| content.op == EMISS_DC_60    // 出战x个神将
		|| content.op == EMISS_DC_59    // 师门任务
		|| content.op == EMISS_DC_62    // 参加过答题活动
		|| content.op == EMISS_DC_63    // 提升x次神将血脉
		|| content.op == EMISS_DC_64    // x个装备符文提升到x星
		|| content.op == EMISS_DC_65    // 装备洗练获x个x星以上属性（保存到身上才算）
		|| content.op == EMISS_DC_66    // 角色达到x战斗力
		|| content.op == EMISS_DC_67    // 角色击杀的怪物数量达到x
		|| content.op == EMISS_DC_68    // 角色拥有x个y品质以上神将
		|| content.op == EMISS_DC_70    // 累计充值超过x元
		|| content.op == EMISS_DC_71    // x个阵法等级超过y级别
		|| content.op == EMISS_DC_72    // 购买任意成长基金
		|| content.op == EMISS_DC_73    // x神将的战力超过y点
		|| content.op == EMISS_DC_74    // 挑战过封神试炼
		|| content.op == EMISS_DC_75    // 当前穿戴x件宠装
		|| content.op == EMISS_DC_80    // 获得神将x
		|| content.op == EMISS_DC_81    // 领取指定天的登录奖励
		) {
		replace.push_back(SReplaceStringData("<num>", IntToStr(pMiss->save_var[0]).c_str()));
		replace.push_back(SReplaceStringData("<maxnum>", IntToStr(content.isum).c_str()));
	}
	else if (content.op == EMISS_DC_40) {
		// 获得坐骑
		replace.push_back(SReplaceStringData("<num>", IntToStr(pMiss->save_var[0]).c_str()));
		replace.push_back(SReplaceStringData("<maxnum>", IntToStr(content.isum).c_str()));
		if (content.collectStr.length() == 0)
		{
			SMountConfig* cfg = SingletonMountCfgMgr::instance().GetCfg(content.itemId);
			if (cfg != NULL)
			{
				content.collectStr = cfg->name;
			}
		}
		replace.push_back(SReplaceStringData("<name>", content.collectStr.c_str()));
	}
	else if (content.op == EMISS_DC_42) {
		// 获得神器 x
		replace.push_back(SReplaceStringData("<num>", IntToStr(pMiss->save_var[0]).c_str()));
		replace.push_back(SReplaceStringData("<maxnum>", IntToStr(content.isum).c_str()));
		if (content.collectStr.length() == 0)
		{
			content.collectStr = SingletonShenQiCfgMgr::instance().GetShenQiName(content.itemId);
		}
		replace.push_back(SReplaceStringData("<name>", content.collectStr.c_str()));
	}
	else if (content.op == EMISS_DC_61) {
		replace.push_back(SReplaceStringData("<item>", GetItemName(content.itemId)));
		replace.push_back(SReplaceStringData("<num>", IntToStr(pMiss->save_var[0]).c_str()));
		replace.push_back(SReplaceStringData("<maxnum>", IntToStr(content.isum).c_str()));
	}
	else if (content.op == EMISS_DC_76) {// 当前穿戴x套y件宠装
		replace.push_back(SReplaceStringData("<suitcnt>", GetItemName(content.itemId)));
		replace.push_back(SReplaceStringData("<num>", IntToStr(pMiss->save_var[0]).c_str()));
		replace.push_back(SReplaceStringData("<maxnum>", IntToStr(content.isum).c_str()));
	}
	else if (content.op == EMISS_DC_77) {// 神将装备强化1次
		if (pMiss->save_var.empty())
			pMiss->save_var.push_back(0);
		replace.push_back(SReplaceStringData("<num>", IntToStr(pMiss->save_var[0]).c_str()));
		replace.push_back(SReplaceStringData("<maxnum>", IntToStr(content.isum).c_str()));
	}
	else if (content.op == EMISS_DC_78) {// 神将装备x件强化超过y级
		replace.push_back(SReplaceStringData("<cnt>", IntToStr(content.itemId).c_str()));
		replace.push_back(SReplaceStringData("<num>", IntToStr(pMiss->save_var[0]).c_str()));
		replace.push_back(SReplaceStringData("<maxnum>", IntToStr(content.isum).c_str()));
	}
	else if (content.op == EMISS_DC_79) {// 分解x件神将装备
		if (pMiss->save_var.empty())
			pMiss->save_var.push_back(0);
		replace.push_back(SReplaceStringData("<num>", IntToStr(pMiss->save_var[0]).c_str()));
		replace.push_back(SReplaceStringData("<maxnum>", IntToStr(content.isum).c_str()));
	}
}


// -------------------------------------------
// 接到任务时验证任务是否已经完成
void CMissionManager::VerifyNewBranchMissionComplate(CUser *pUser, SMissionDoingContent &mcnf,  SAcceptMission *pMiss){
	if(mcnf.op == EMISS_DC_21){
		//  升级x个神将至x级：21-num(神将数量)-level(神将等级)
		uint32 rawnum = 0;
		if(pUser->VerifyPetLevelAndNum(mcnf.isum, mcnf.level, rawnum)){
			pMiss->save_var[0] = mcnf.isum;
			pMiss->state = EMISS_STATE_FINISH;
		}else{
			pMiss->save_var[0] = rawnum;
		}
	}
	else if(mcnf.op == EMISS_DC_22){
		//  x个神将技能提升至x级：22-num（神将技能数量）-level（技能等级）
		uint32 rawnum = 0;
		if(pUser->VerifyPetSkillLevelAndNum(mcnf.isum, mcnf.level, rawnum)){
			pMiss->save_var[0] = mcnf.isum;
			pMiss->state = EMISS_STATE_FINISH;
		}else{
			pMiss->save_var[0] = rawnum;
		}
	}
	else if(mcnf.op == EMISS_DC_23){
		//  x个神将血脉修炼至x级：23-num（神将血脉数量）-level（修炼等级）
		uint32 rawnum = 0;
		if(pUser->VerifyPetXueMaiLevelAndNum(mcnf.isum, mcnf.level, rawnum)){
			pMiss->save_var[0] = mcnf.isum;
			pMiss->state = EMISS_STATE_FINISH;
		}else{
			pMiss->save_var[0] = rawnum;
		}
	}
	else if(mcnf.op == EMISS_DC_25){
		//  x个人物技能提升至x级：25-num（技能数量）-level（技能等级）

	}
	else if(mcnf.op == EMISS_DC_26){
		//  x件装备升阶至x级：26-num（装备数量）-level（装备等级）

	}
	else if(mcnf.op == EMISS_DC_27){
		//  x件装备强化至x级：27-num（装备数量）-level（强化等级）

	}
	else if(mcnf.op == EMISS_DC_33){
		//  通关通天塔至x层：33-num（层数）
		int topFloor = pUser->GetExtData16(52);
		if(topFloor > 0)
			topFloor -= 1;
		if(topFloor >= mcnf.isum)
		{
			pMiss->save_var[0] = mcnf.isum;
			pMiss->state = EMISS_STATE_FINISH;
		}
	}
	else if(mcnf.op == EMISS_DC_38){
		//  x个神将升至x星：38-num（神将数量）-star（星数)
		uint32 rawnum = 0;
		if(pUser->VerifyPetStarLevelAndNum(mcnf.isum, mcnf.star,rawnum)){
			pMiss->save_var[0] = mcnf.isum;
			pMiss->state = EMISS_STATE_FINISH;
		}else{
			
			pMiss->save_var[0] = rawnum;
		}
	}
	else if(mcnf.op == EMISS_DC_18 ){
		if(pUser->GetBangPai() != 0){
			pMiss->save_var[0] = mcnf.isum;
			pMiss->state = EMISS_STATE_FINISH;
		}
	}
	else if (mcnf.op == EMISS_DC_19 || mcnf.op == EMISS_DC_34) {
		if (pMiss->save_var[0] == mcnf.isum) {
			pMiss->state = EMISS_STATE_FINISH;
		}
	}
	else if (mcnf.op == EMISS_DC_39  // 捉妖 x 次
		|| mcnf.op == EMISS_DC_41    // 坐骑强化到 x 级
		|| mcnf.op == EMISS_DC_43    // 培养羽翼到 x 阶段
		|| mcnf.op == EMISS_DC_44    // 完成x次宝图任务 
		|| mcnf.op == EMISS_DC_45    // 使用x次藏宝图
		|| mcnf.op == EMISS_DC_46    // 使用x次高级藏宝图
		|| mcnf.op == EMISS_DC_47    // 学习天书技能x次
		|| mcnf.op == EMISS_DC_48    // 护送神将x次
		|| mcnf.op == EMISS_DC_49    // 英勇试炼击败第X关守护者
		|| mcnf.op == EMISS_DC_53    // 开启背包
		|| mcnf.op == EMISS_DC_51    //  膜拜强者x次
		|| mcnf.op == EMISS_DC_54    // 帮派捐献
		|| mcnf.op == EMISS_DC_55    // 帮派种植
		|| mcnf.op == EMISS_DC_56    // 普通祈福
		|| mcnf.op == EMISS_DC_57    // 元宝祈福
		|| mcnf.op == EMISS_DC_67 // 角色击杀的怪物数量达到x
		) {
		int curNum = pUser->GetDCMissExtData8(mcnf.op);
		if (curNum >= mcnf.isum) {
			curNum = mcnf.isum;
			pMiss->state = EMISS_STATE_FINISH;
		}
		if (pMiss->save_var.empty())
			pMiss->save_var.push_back(curNum);
		else			
			pMiss->save_var[0] = curNum;
	}
	else if (mcnf.op == EMISS_DC_70) {
		// 累计充值超过x元
		int curNum = pUser->GetExtData32(14);
		if (curNum >= mcnf.isum) {
			curNum = mcnf.isum;
			pMiss->state = EMISS_STATE_FINISH;
		}
		if (pMiss->save_var.empty())
			pMiss->save_var.push_back(curNum);
		else
			pMiss->save_var[0] = curNum;
	}
	else if (mcnf.op == EMISS_DC_40) {
		// 获得坐骑
		uint8 idx = pUser->GetMountIdxById(mcnf.itemId);
		if (idx != 0xff) {
			pMiss->save_var[0] = 1;
			pMiss->state = EMISS_STATE_FINISH;
		}
		else {
			pMiss->save_var[0] = 0;
		}
	}
	else if (mcnf.op == EMISS_DC_42) {
		if (pUser->isNewAShenQiActived(mcnf.itemId)) {
			pMiss->save_var[0] = 1;
			pMiss->state = EMISS_STATE_FINISH;
		}
		else {
			pMiss->save_var[0] = 0;
		}
	}
	else if (mcnf.op == EMISS_DC_52) {
		if (pUser->HaveBitSet(152)){
			pMiss->save_var[0] = mcnf.isum;
			pMiss->state = EMISS_STATE_FINISH;
		}
		else {
			pMiss->save_var[0] = 0;
		}
	}
	else if (mcnf.op == EMISS_DC_59) { // 完成x次y任务
		int curNum = pUser->GetDailyMissCompleteCnt(mcnf.itemId);
		if (curNum >= mcnf.isum) {
			curNum = mcnf.isum;
			pMiss->state = EMISS_STATE_FINISH;
		}
		if (pMiss->save_var.empty())
			pMiss->save_var.push_back(curNum);
		else
			pMiss->save_var[0] = curNum;
	}
	else if (mcnf.op == EMISS_DC_60) { // 出战x个神将
		vector<SZhenFaMemData> zhenfaMembers;
		pUser->GetZhenFaMember(zhenfaMembers);
		uint8 size = zhenfaMembers.size();
		int cnt = 0;
		for (uint8 i = 0; i < size; i++)
		{
			if (zhenfaMembers[i].mem_type == EZFMT_PET)
			{
				cnt++;
			}
		}

		if (cnt >= mcnf.isum) {
			cnt = mcnf.isum;
			pMiss->state = EMISS_STATE_FINISH;
		}

		if (pMiss->save_var.empty())
			pMiss->save_var.push_back(cnt);
		else
			pMiss->save_var[0] = cnt;
	}
	else if (mcnf.op == EMISS_DC_61) { // 购买物品引导（不用考虑之前购买的）
		if (pMiss->save_var.empty())
			pMiss->save_var.push_back(0);
		if (pMiss->save_var[0] == mcnf.isum) {
			pMiss->state = EMISS_STATE_FINISH;
		}
	}
	else if (mcnf.op == EMISS_DC_62) { // 参加过答题活动
		int curNum = 0;
		if (pUser->HaveBitSet(433))
		{
			curNum = mcnf.isum;
			pMiss->state = EMISS_STATE_FINISH;
		}
		if (pMiss->save_var.empty())
			pMiss->save_var.push_back(curNum);
		else
			pMiss->save_var[0] = curNum;
	}
	else if (mcnf.op == EMISS_DC_63) { // 提升x次神将血脉
		if (pMiss->save_var.empty())
			pMiss->save_var.push_back(0);
		int curNum = pMiss->save_var[0];
		if (curNum >= mcnf.isum)
		{
			curNum = mcnf.isum;
			pMiss->state = EMISS_STATE_FINISH;
		}
	}
	else if (mcnf.op == EMISS_DC_64) { // x个装备符文提升到x星

	}
	else if (mcnf.op == EMISS_DC_65) { // 装备洗练获x个x星以上属性（保存到身上才算）

	}


	else if (mcnf.op == EMISS_DC_66) { // 角色达到x战斗力
		int curNum = pUser->GetZhanDouLi();
		if (curNum >= mcnf.isum)
		{
			curNum = mcnf.isum;
			pMiss->state = EMISS_STATE_FINISH;
		}
		if (pMiss->save_var.empty())
			pMiss->save_var.push_back(curNum);
		else
			pMiss->save_var[0] = curNum;
	}
	else if (mcnf.op == EMISS_DC_68) { // 角色拥有x个y品质以上神将
		uint32 curNum = 0;
		if (pUser->VerifyUserPetQualityAndNum(mcnf.isum, mcnf.itemId, curNum))
		{
			curNum = mcnf.isum;
			pMiss->state = EMISS_STATE_FINISH;
		}
		if (pMiss->save_var.empty())
			pMiss->save_var.push_back(curNum);
		else
			pMiss->save_var[0] = curNum;
	}
	else if (mcnf.op == EMISS_DC_71) { // x个阵法等级超过y级别
		uint32 curNum = 0;
		if (pUser->VerifyUserLevelFormationNum(mcnf.isum, mcnf.itemId, curNum))
		{
			curNum = mcnf.isum;
			pMiss->state = EMISS_STATE_FINISH;
		}
		if (pMiss->save_var.empty())
			pMiss->save_var.push_back(curNum);
		else
			pMiss->save_var[0] = curNum;
	}
	else if (mcnf.op == EMISS_DC_72) { // 购买任意成长基金
		int curNum = 0;
		if (pUser->HaveBitSet(434))
		{
			curNum = mcnf.isum;
			pMiss->state = EMISS_STATE_FINISH;
		}
		if (pMiss->save_var.empty())
			pMiss->save_var.push_back(curNum);
		else
			pMiss->save_var[0] = curNum;
	}
	else if (mcnf.op == EMISS_DC_73) { // x神将的战力超过y点
		uint32 curNum = 0;
		if (pUser->VerifyUserPetPowerNum(mcnf.isum, mcnf.itemId, curNum))
		{
			curNum = mcnf.isum;
			pMiss->state = EMISS_STATE_FINISH;
		}
		if (pMiss->save_var.empty())
			pMiss->save_var.push_back(curNum);
		else
			pMiss->save_var[0] = curNum;
	}
	else if (mcnf.op == EMISS_DC_74) { // 挑战过封神试炼
		int curNum = 0;
		if (pUser->HaveBitSet(435))
		{
			curNum = mcnf.isum;
			pMiss->state = EMISS_STATE_FINISH;
		}
		if (pMiss->save_var.empty())
			pMiss->save_var.push_back(curNum);
		else
			pMiss->save_var[0] = curNum;
	}
	else if (mcnf.op == EMISS_DC_78) { // 神将装备x件强化超过y级
		uint32 cnt = 0;
		bool isComplate = pUser->VerifyUserPetEquipStrongLevelNum(mcnf.isum, mcnf.itemId, cnt);
		if (isComplate)
		{
			cnt = mcnf.isum;
			pMiss->state = EMISS_STATE_FINISH;
		}
		if (pMiss->save_var.empty())
			pMiss->save_var.push_back(cnt);
		else
			pMiss->save_var[0] = cnt;
	}
	else if (mcnf.op == EMISS_DC_80) { // 获得神将x
		if (pMiss->save_var.empty())
			pMiss->save_var.push_back(0);
		if (pUser->HavePet(mcnf.itemId))
		{
			pMiss->save_var[0] = 1;
			pMiss->state = EMISS_STATE_FINISH;
		}
	}
	else if (mcnf.op == EMISS_DC_81) { // 领取指定天的登录奖励
		if (pMiss->save_var.empty())
			pMiss->save_var.push_back(0);
		if (pUser->HaveBitSet(280 + mcnf.itemId))
		{
			pMiss->save_var[0] = 1;
			pMiss->state = EMISS_STATE_FINISH;
		}
	}
}

void CMissionManager::GetMissionAward(CUser *pUser, int missId){
	if(pUser == NULL){
		return;
	}
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_CLIENT_GETMISSIONAWARD);
	boost::unordered_map<int,SMissionConfig>::iterator it = m_missions.find(missId);
	if(it == m_missions.end()){
		msg<<(uint8)PRO_ERROR;
		msg<<"任务领奖失败";
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}


	SAcceptMission *pMiss = pUser->m_missList.GetAcceptedCMission(missId);
	if(pMiss == NULL){
		msg<<(uint8)PRO_ERROR;
		msg<<"任务领奖失败";
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}

	if(!pUser->IsCMissionFinished(missId)){
		msg<<(uint8)PRO_ERROR;
		msg<<"任务未完成";
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}

	FinishCMission(pUser, missId);
	msg<<(uint8)PRO_SUCCESS;
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void CMissionManager::GetMissionIdByOp(CUser *pUser, int op, std::vector<uint32>& vec){
	vector<int> miss;
	pUser->m_missList.GetAcceptCMissList(miss);
	if(miss.empty()){
		return;
	}

	for(uint16 i=0; i < miss.size();i++)
	{
		uint32 mid = 0;
		SMissionConfig *pCfg = GetMissionCfg(miss[i]);
		if(pCfg == NULL){
			continue;
		}

		SMissionDoingContent &con = pCfg->doing_content;
		if(con.op == op)
		{
			mid = pCfg->id;
			vec.push_back(mid);
		}
	}
}


void CMissionManager::Print()
{
	//                  0    1         2           3          4             5         6      7           8
//	const char *keys[] = {"id","name","accept_script","accept_auto","accept_npc","acceptable_desc","kind","subtype","premission_limit",
	//         9          10        11        12           13           14         15           16           17
//		"profession_limit","sex_limit","min_level","max_level","day_finished_limit","weight","accept_dialog","accept_autorun","accept_todo",
	//        18         19         20           21         22
//		"doing_target","doing_desc","finish_reward","finish_auto","finish_todo"};

	for(boost::unordered_map<int,SMissionConfig>::iterator it = m_missions.begin();it != m_missions.end();it++)
	{
		SMissionConfig &data = it->second;
		cout<<"id="<<data.id<<", name="<<data.name<<", accept_script="<<data.accept_from_script<<", accept_auto="<<(int)data.accept_auto;
		cout<<", accept_npc="<<data.accept_npc.sceneId<<"-"<<data.accept_npc.posX<<"-"<<data.accept_npc.posY<<"-"<<data.accept_npc.npcId;
		cout<<", acceptable_desc="<<data.accept_desc<<", kind="<<data.type<<", subtype="<<data.sub_type;
		cout<<", premission_limit=";
		for(uint16 i=0;i < data.preMissionId.size();i++)
			cout<<data.preMissionId[i]<<";";
		cout<<", profession_limit="<<data.profession_limit<<", sex_limit="<<data.sex_limit<<", min_level="<<data.min_level<<", max_level="<<data.max_level;
		cout<<", day_finished_limit="<<data.day_finish_times_limit<<", weight="<<data.weight<<", accept_dialog="<<data.accept_dialog;
		cout<<", accept_autorun="<<(int)data.accept_autorun<<", accept_todo=";
		for(uint16 i=0;i < data.accept_todo.size();i++)
		{
			SMissionTodo &todo = data.accept_todo[i];
			int op = todo.op;
			if(op == EMISS_TD_ADD_NPC)
				cout<<op<<"-"<<todo.sceneId<<"-"<<todo.posX<<"-"<<todo.posY<<"-"<<todo.npcId<<"-"<<todo.npcIdx<<"-"<<todo.direct<<";";
			else if(op == EMISS_TD_DEL_NPC)
				cout<<op<<"-"<<todo.sceneId<<"-"<<todo.posX<<"-"<<todo.posY<<"-"<<todo.npcId<<"-"<<todo.npcIdx<<"-"<<todo.direct<<";";
			else if(op == EMISS_TD_ADD_COLLECT)
				cout<<op<<"-"<<todo.sceneId<<"-"<<todo.posX<<"-"<<todo.posY<<"-"<<todo.npcId<<"-"<<todo.npcIdx<<"-"<<todo.itemId<<"-"<<todo.itemNum<<";";
			else if(op == EMISS_TD_DEL_COLLECT)
				cout<<op<<"-"<<todo.sceneId<<"-"<<todo.posX<<"-"<<todo.posY<<"-"<<todo.npcId<<"-"<<todo.npcIdx<<";";
		}
		cout<<", doing_target=";
		{
			SMissionDoingContent &todo = data.doing_content;
			if(todo.op == EMISS_DC_DIALOG)
				cout<<todo.op<<"-"<<todo.sceneId<<"-"<<todo.posX<<"-"<<todo.posY<<"-"<<todo.npcId<<"-"<<todo.dialogId;
			else if(todo.op == EMISS_DC_KILL_MONSTER)
				cout<<todo.op<<"-"<<todo.sceneId<<"-"<<todo.posX<<"-"<<todo.posY<<"-"<<todo.monsterId<<"-"<<todo.monsterNum;
			else if(todo.op == EMISS_DC_MONSTER_DROP)
				cout<<todo.op<<"-"<<todo.sceneId<<"-"<<todo.posX<<"-"<<todo.posY<<"-"<<todo.monsterId<<"-"<<todo.dropRatio<<"-"<<todo.itemId<<"-"<<todo.itemNum;
			else if(todo.op == EMISS_DC_BUY_ITEM)
				cout<<todo.op<<"-"<<todo.sceneId<<"-"<<todo.posX<<"-"<<todo.posY<<"-"<<todo.npcId<<"-"<<todo.itemId<<"-"<<todo.itemNum;
			else if(todo.op == EMISS_DC_KILL_BOSS)
				cout<<todo.op<<"-"<<todo.sceneId<<"-"<<todo.posX<<"-"<<todo.posY<<"-"<<todo.npcId<<"-"<<todo.fightPreDialogId<<"-"<<todo.fightId<<"-"<<todo.fightWinDialogId<<"-"<<todo.fightFailDialogId;
			else if(todo.op == EMISS_DC_COLLECT)
				cout<<todo.op<<"-"<<todo.sceneId<<"-"<<todo.posX<<"-"<<todo.posY<<"-"<<todo.npcId<<"-"<<todo.itemNum;
			else if(todo.op == EMISS_DC_COPY)
				cout<<todo.op<<"-"<<todo.copyId<<"-"<<todo.copyCompleteNum;
		}
		cout<<", doing_desc="<<data.doing_desc<<", finish_reward=";
		for(uint16 i=0;i < data.reward1.size();i++)
		{
			SAwardData &a = data.reward1[i];
			cout<<a.type<<"-"<<a.num<<";";
		}
		cout<<", finish_auto="<<(int)data.finish_auto<<", finish_todo=";
		for(uint16 i=0;i < data.finish_todo.size();i++)
		{
			SMissionTodo &todo = data.finish_todo[i];
			int op = todo.op;
			if(op == EMISS_TD_ADD_NPC)
				cout<<op<<"-"<<todo.sceneId<<"-"<<todo.posX<<"-"<<todo.posY<<"-"<<todo.npcId<<"-"<<todo.npcIdx<<"-"<<todo.direct<<";";
			else if(op == EMISS_TD_DEL_NPC)
				cout<<op<<"-"<<todo.sceneId<<"-"<<todo.posX<<"-"<<todo.posY<<"-"<<todo.npcId<<"-"<<todo.npcIdx<<"-"<<todo.direct<<";";
			else if(op == EMISS_TD_ADD_COLLECT)
				cout<<op<<"-"<<todo.sceneId<<"-"<<todo.posX<<"-"<<todo.posY<<"-"<<todo.npcId<<"-"<<todo.npcIdx<<"-"<<todo.itemId<<"-"<<todo.itemNum<<";";
			else if(op == EMISS_TD_DEL_COLLECT)
				cout<<op<<"-"<<todo.sceneId<<"-"<<todo.posX<<"-"<<todo.posY<<"-"<<todo.npcId<<"-"<<todo.npcIdx<<";";
		}
		cout<<endl;
	}
	cout<<"==================================================="<<endl;

	//                     0      1     2      3       4      5     6      7      8
//	const char *keys[] = {"dialogid","order","npcid","position","dialog","scale","speed","delay","showskip"};
	for(boost::unordered_map<int,list<SMissionDialog> >::iterator it = m_dialogs.begin();it != m_dialogs.end();it++)
	{
		list<SMissionDialog> &data = it->second;
		for(list<SMissionDialog>::iterator i=data.begin();i != data.end();i++)
		{
			cout<<"dialogid = "<<i->id<<", order="<<i->order<<", npcid="<<i->npcId<<", position="<<i->position<<", dialog="<<i->content;
			cout<<", scale="<<i->scale<<", speed="<<i->speed<<", delay="<<i->delay<<", showskip="<<i->showskip<<endl;
		}
	}
}

int CMissionManager::GetCMissionBackNpcId(int mid)
{
	if (mid == MISSION_ID_ZhouRiChang)
		return 517;
	else if (mid == MISSION_ID_ShiMen)
		return 19;
	return 0;
}

void CMissionManager::GetStageGoalInfo(CUser *pUser, CNetMessage& msg)
{
	/*uint16 breakLevel = pUser->GetLevel() + 1;
	uint8 num = 0;
	uint16 numPos = msg.GetDataLen();
	msg << num;*/

	//map<uint8, uint8>& states = pUser->m_missList.GetStageState();

	//for (stageMapIt it = m_allStages.begin(); it != m_allStages.end(); ++it)
	//{
	//	const StageTarget& staget = it->second;
	//	const missMap& misss = staget.missIds;
	//	msg << staget.idx << staget.title << staget.minlevel << staget.maxlevel;
	//	uint16 statePos = msg.GetDataLen();
	//	msg << (uint8)0 << (uint8)misss.size();
	//	uint8& state = states[staget.idx];
	//	bool complete = true;

	//	// 任务列表
	//	for (missMapCIt mi = misss.begin(); mi != misss.end(); ++mi)
	//	{
	//		bool isFinish = pUser->m_missList.IsInCMissionFinishedList(mi->first);
	//		msg << (uint16)mi->first << (uint8)isFinish;
	//		if (complete && !isFinish) // 未领取 且
	//		{
	//			complete = false;
	//		}
	//	}
	//	if (state != 2)
	//	{
	//		state = complete ? 1 : 0;
	//	}
	//	msg.WriteData(statePos, &state, sizeof(state));
	//	num++;

	//	// 奖励
	//	msg << (uint8)staget.awards.size();
	//	for (size_t ai = 0; ai < staget.awards.size(); ai++)
	//	{
	//		msg << (uint16)staget.awards[ai].type << (uint32)staget.awards[ai].num;
	//	}

	//	if (breakLevel <= staget.minlevel)
	//	{
	//		break;
	//	}
	//}
	//msg.WriteData(numPos, &num, sizeof(num));
	//SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);
}

int CMissionManager::GetStageIdx(int missId)
{
	for (stageMapIt it = m_allStages.begin(); it != m_allStages.end(); ++it)
	{
		const StageTarget& staget = it->second;
		missMapCIt mIt = staget.missIds.find(missId);
		if (mIt != staget.missIds.end())
		{
			return staget.idx;
		}
	}
	return 0;
}

void CMissionManager::UpdateStageGoalState(CUser *pUser, int missId)
{
	/*uint8 idx = GetStageIdx(missId);
	stageMapIt it = m_allStages.find(idx);
	if (it == m_allStages.end())
	{
		return;
	}

	CNetMessage msg;
	msg.SetType(MSG_STAGE_GOAL);
	map<uint8, uint8>& states = pUser->m_missList.GetStageState();
	const StageTarget& staget = it->second;
	const missMap& misss = staget.missIds;
	msg << (uint8)3 << (uint8)idx;
	uint16 statePos = msg.GetDataLen();
	msg << (uint8)0 << (uint8)misss.size();
	uint8& state = states[staget.idx];
	bool complete = true;

	for (missMapCIt mi = misss.begin(); mi != misss.end(); ++mi)
	{
		bool isFinish = pUser->m_missList.IsInCMissionFinishedList(mi->first);
		msg << (uint16)mi->first << (uint8)isFinish;
		if (complete && !isFinish)
		{
			complete = false;
		}
	}
	if (state != 2)
	{
		state = complete ? 1 : 0;
	}
	msg.WriteData(statePos, &state, sizeof(state));
	SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);*/
}

void CMissionManager::GetStageGoalAward(CUser *pUser, uint8 idx, CNetMessage& msg)
{
	/*do 
	{
		stageMapIt it = m_allStages.find(idx);
		if (it == m_allStages.end())
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_1607, TIPS_FAILURE_COLOR);
			break;
		}

		map<uint8, uint8>& states = pUser->m_missList.GetStageState();
		uint8& state = states[idx];
		if (state == 0)
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_1605, TIPS_FAILURE_COLOR);
			break;
		}

		if (state == 2)
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_1601, TIPS_FAILURE_COLOR);
			break;
		}

		state = 2;
		StageTarget& stage = it->second;
		for (size_t i = 0; i < stage.awards.size(); ++i)
		{
			SAwardData& award = stage.awards[i];
			if (award.type == HDAT_PET)
			{
				::AddPet(pUser, award.typeId, 1);
			}
			else
			{
				pUser->AddMaterial(award);
			}
		}
		msg << PRO_SUCCESS;
	} while (false);
	SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);*/
}

void CMissionManager::FinishKuaFuRiChang(CUser *pUser, int type)
{
	SAcceptMission *pMiss = pUser->m_missList.GetAcceptedCMission(MISSION_ID_KuaFuShilian);
	if (pMiss == NULL)
		return;
	if (pMiss->save_var.empty())
		return;
	int mt = pMiss->save_var[0];
	if (mt == 1 && type == mt)	// 世界说话
	{
		pUser->UpdateCMissionState(MISSION_ID_KuaFuShilian, 1);
		CCallScript *pScript = GetScript250();
		if (pScript != NULL)
		{
			pScript->Call("KuaFuShiLianFinish", "ui", pUser, 0);
		}
	}
}

void CMissionManager::MakeKuaFuRiChangMsg(CUser *pUser, SAcceptMission *pMiss, const SMissionConfig& cfg, CNetMessage& msg)
{
#if 1
	if (pMiss->save_var.empty())
		return;
	char buf[256];
	int curTimes = pUser->GetExtData8(641) + 1;
	int type = pMiss->save_var[0];
	if (type == 1)	// 世界说话
	{
		snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0065, curTimes, MISSION_MAX_CNT_KuaFuShilian);
		string content = cfg.name + buf;
		content += ((pMiss->state == EMISS_STATE_ACCEPT) ? "|0" : "|1");
		msg << content;
		msg << (uint8)EMISS_TT_PANCL << 31;
	}
	else if (type == 2)	// 切磋
	{
		int profession = pMiss->save_var[1];
		
		snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0066, curTimes, MISSION_MAX_CNT_KuaFuShilian);
		string content = cfg.name + buf;
		content += ((pMiss->state == EMISS_STATE_ACCEPT) ? "|0" : "|1");
		msg << content;
		if (pMiss->state == EMISS_STATE_ACCEPT)
			msg << (uint8)EMISS_TT_ROLE << (uint32)profession;
		else if (pMiss->state == EMISS_STATE_FINISH)
		{
			msg << (uint8)EMISS_TT_NPC << (uint32)GetCMissionBackNpcId(cfg.id) << (uint16)70 << -1 << -1;
		}
	}
	else if (type == 3)	// 心魔
	{
		int npcId = pMiss->save_var[1];
		int sceneId = pMiss->save_var[2];
		snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0067, curTimes, MISSION_MAX_CNT_KuaFuShilian, pMiss->save_str[0].c_str());
		string content = cfg.name + buf;
		content += ((pMiss->state == EMISS_STATE_ACCEPT) ? "|0" : "|1");
		msg << content;
		if (pMiss->state == EMISS_STATE_ACCEPT)
			msg << (uint8)EMISS_TT_NPC << (uint32)npcId << (uint16)sceneId << -1 << -1;
		else
			msg << (uint8)EMISS_TT_NPC << (uint32)GetCMissionBackNpcId(cfg.id) << (uint16)70 << -1 << -1;
	}
#endif
}

bool CMissionManager::IsMeiRiQuest(uint16 tid)
{
	return m_meiRiIds.find(tid) != m_meiRiIds.end();
}

QuestCfgMap* CMissionManager::GetTypeQuest(uint16 type)
{
	TypeQuestCfgMapIt it = m_typeQuestCfg.find(type);
	if (it != m_typeQuestCfg.end())
		return &it->second;

	return NULL;
}

QuestCfg* CMissionManager::GetQuestCfg(uint16 tid)
{
	QuestCfgMapIt it = m_questCfg.find(tid);
	if (it != m_questCfg.end())
		return &it->second;

	return NULL;
}

vector<TypeValue>* CMissionManager::GetCondTypeIds(uint8 cond)
{
	CondTypeIdMapIt it = m_condTypeIds.find(cond);
	if (it != m_condTypeIds.end())
		return &it->second;

	return NULL;
}

QuestCfgMap* CMissionManager::GetDayQuestMap(uint8 day)
{
	TypeQuestCfgMapIt it = m_hdDayQuestCfg.find(day);
	if (it != m_hdDayQuestCfg.end())
		return &it->second;

	return NULL;
}

QuestCfg* CMissionManager::GetHDQuestCfg(uint16 id)
{
	QuestCfgMapIt it = m_hdQuestCfg.find(id);
	if (it != m_hdQuestCfg.end())
		return &it->second;

	return NULL;
}

vector<TypeValue>* CMissionManager::GetHDCondTypeIds(uint8 cond)
{
	CondTypeIdMapIt it = m_hdCondTypeIds.find(cond);
	if (it != m_hdCondTypeIds.end())
		return &it->second;

	return NULL;
}

QuestCfgMap* CMissionManager::GetJiJinQuestMap(uint8 type)
{
	TypeQuestCfgMapIt it = m_jjTypeQuestCfg.find(type);
	if (it != m_jjTypeQuestCfg.end())
		return &it->second;

	return NULL;
}

QuestCfg* CMissionManager::GetJiJinQuestCfg(uint16 id)
{
	QuestCfgMapIt it = m_jjQuestCfg.find(id);
	if (it != m_jjQuestCfg.end())
		return &it->second;

	return NULL;
}

vector<TypeValue>* CMissionManager::GetJiJinCondTypeIds(uint8 cond)
{
	CondTypeIdMapIt it = m_jjCondTypeIds.find(cond);
	if (it != m_jjCondTypeIds.end())
		return &it->second;

	return NULL;
}
