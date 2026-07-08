#ifndef _NCP_MANAGER_H_
#define _NCP_MANAGER_H_

#include "monster.h"
#include "self_typedef.h"
#include <time.h>
#include <string>
#include <list>
#include <iostream>

using namespace std;
class CCallScript;

struct SNpcTemplate
{
	SNpcTemplate():pScript(NULL)
	{
	}
	uint16 id;
	string name;
	uint16 pic;
	uint8 type;
	//int script;
	CCallScript *pScript;
};

/*
+-----+--------+--------+--------+-------+-------+-------+
| SEX | WEAPON | ULEVEL | HELMET | CLASS | ARMOR | CLASS |
+-----+--------+--------+--------+-------+-------+-------+
|  1  |    2   |    1   |   2    |    1  |   2   |   1   |
+-----+--------+--------+--------+-------+-------+-------+
*/
struct HumanData
{
	uint32 roleId;
	uint16 weapon;
	uint16 helmet;
	uint16 armor;
	uint8 level;
	uint8 sex;
	uint8 helmetClass;
	uint8 armorClass;
};

struct SNpcInstance
{
	SNpcInstance()
	{
		id = 0;
		templateId = 0;
		sceneId = 0;
		x = 0;
		y = 0;
		type = 0;
		direct = 0;
		index = 0;
		isFight = false;
		pic = 0;
		timeOut = 0;
		fightId = 0;
		pNpc = NULL;
		pHumanData = NULL;
		nameColor = PQT_BLUE;
	}

	SNpcInstance& operator=(SNpcInstance &m)
	{
		id = m.id;
		templateId = m.templateId;
		sceneId = m.sceneId;
		x = m.x;
		y = m.y;
		type = m.type;
		direct = m.direct;
		index = m.index;
		isFight = m.isFight;
		pic = m.pic;
		timeOut = m.timeOut;
		fightId = m.fightId;
		nameColor = m.nameColor;
		if(pNpc == NULL)
			pNpc = new SNpcTemplate;
		*pNpc = *(m.pNpc);
		pHumanData = NULL;
		return *this;
	}

	void MakeNpcInfo(CNetMessage &msg);

	bool isFight;	// 是否战斗,活动中使用
	uint8 type;
	uint8 direct;//方向
	uint16 id;
	uint16 templateId;
	uint16 x;
	uint16 y;
	uint16 pic;
	uint16 index;// 索引
	uint8 nameColor;
	int sceneId;
	int fightId;
	time_t timeOut;
	string name;
	SNpcTemplate *pNpc;
	HumanData *pHumanData;
};

class CNpcManager
{
public:
	CNpcManager();
	~CNpcManager();
	void GetSceneNpc(int sceneId,list<uint16>*);
	bool Init();
	SNpcTemplate *GetNpcTemplate(uint16 tempId);
	SNpcInstance *GetNpcInstance(uint16 id);
	SNpcInstance *GetNpcInstanceByTmplId(uint16 tmplId);
private:
	bool m_isInit;
	bool ForEachInsFun(uint16 instanceId,SNpcInstance *,uint16 sceneId,list<uint16>*);
	CHashTable<uint16,SNpcTemplate*> m_npcTemplate;
	CHashTable<uint16,SNpcInstance*> m_npcInstance;
};
#endif

