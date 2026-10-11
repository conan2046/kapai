#include "npc_manager.h"
#include "call_script.h"
#include <boost/bind.hpp>

CNpcManager::CNpcManager():m_isInit(false)
{
}

void SNpcInstance::MakeNpcInfo(CNetMessage &msg)
{
	msg<<id;
	if(name.empty())
		msg<<pNpc->name;
	else
		msg<<name;
	msg<<nameColor<<x<<y<<direct;
	if(pNpc->type != 0)
		msg<<pNpc->type;
	else
		msg<<type;

	if(pHumanData != NULL)
	{
		msg<<pHumanData->sex<<pHumanData->weapon<<pHumanData->level<<pHumanData->helmet
			<<pHumanData->helmetClass<<pHumanData->armor<<pHumanData->armorClass;//<<(uint8)0;
	}
	else
	{
		if(pic > 0)
			msg<<pic<<index;
		else
			msg<<pNpc->pic<<index;//<<(uint8)state;
	}
}

bool CNpcManager::Init()
{
	if(m_isInit)
		return true;
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	string sql("select id,name,picture,script,npc_type from npc_template");
	if ((pDb != NULL)
		&& (pDb->Query(sql.c_str())))
	{
		char **row;
		while ((row = pDb->GetRow()) != NULL)
		{
			SNpcTemplate *pNpcTmpl = new SNpcTemplate;
			pNpcTmpl->id = (uint16)atoi(row[0]);
			pNpcTmpl->name = row[1];
			pNpcTmpl->pic = atoi(row[2]);
			if(atoi(row[3]) > 0)
				pNpcTmpl->pScript = new CCallScript(atoi(row[3]));
			pNpcTmpl->type = atoi(row[4]);
			m_npcTemplate.Insert(pNpcTmpl->id,pNpcTmpl);
		}
	}
	else
	{
		return false;
	}
#ifndef KUA_FU
	sql = "select id,template_id,scene_id,x_pos,y_pos,face from npc_instance where show_type in(1,3)";
#else
	sql = "select id,template_id,scene_id,x_pos,y_pos,face from npc_instance where show_type in(2,3)";
#endif
	if((pDb != NULL) && (pDb->Query(sql.c_str())))
	{
		char **row;
		while ((row = pDb->GetRow()) != NULL)
		{
			SNpcTemplate *pTmpl;
			uint16 tmplId = (uint16)atoi(row[1]);
			if (m_npcTemplate.Find(tmplId,pTmpl))
			{
				SNpcInstance *pInst = new SNpcInstance;
				pInst->pNpc = pTmpl;
				pInst->id = (uint16)atoi(row[0]);
				pInst->templateId = tmplId;
				pInst->sceneId = atoi(row[2]);
				pInst->x = (uint16)atoi(row[3]);
				pInst->y = (uint16)atoi(row[4]);
				pInst->direct = (uint8)atoi(row[5]);
				m_npcInstance.Insert(pInst->id,pInst);
			}
		}
	}
	else
	{
		return false;
	}
	m_isInit = true;
	return true;
}

CNpcManager::~CNpcManager()
{
	m_npcTemplate.DelAll();
	m_npcInstance.DelAll();
}

bool CNpcManager::ForEachInsFun(uint16 instanceId,SNpcInstance *pIns,uint16 sceneId,list<uint16> *insList)
{
	if (sceneId == pIns->sceneId)
	{
		insList->push_back(instanceId);
	}
	return true;
}

void CNpcManager::GetSceneNpc(int sceneId,list<uint16> *npcList)
{
	m_npcInstance.ForEach(boost::bind(&CNpcManager::ForEachInsFun,this,_1,_2,sceneId,npcList));
}

SNpcTemplate *CNpcManager::GetNpcTemplate(uint16 tempId)
{
	SNpcTemplate *pTmpl = NULL;
	m_npcTemplate.Find(tempId,pTmpl);
	return pTmpl;
}

SNpcInstance *CNpcManager::GetNpcInstance(uint16 id)
{
	SNpcInstance *pIns = NULL;
	m_npcInstance.Find(id,pIns);
	return pIns;
}

bool FindByTmplId(uint16 instanceId,SNpcInstance *pIns,uint16 tmplId,SNpcInstance **ppNpc)
{
	if(pIns->pNpc->id == tmplId)
	{
		*ppNpc = pIns;
		return false;
	}
	return true;
}

SNpcInstance *CNpcManager::GetNpcInstanceByTmplId(uint16 tmplId)
{
	SNpcInstance *pIns = NULL;
	m_npcInstance.ForEach(boost::bind(&FindByTmplId,_1,_2,tmplId,&pIns));
	return pIns;
}

