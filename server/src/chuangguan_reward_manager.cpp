#include "chuangguan_reward_manager.h"
//#include "user.h"
//#include "net_msg.h"
#include "xml.h"
//#include "script_call.h"
//#include "utility.h"
#include <string.h>

ChuangguanRewardManager::ChuangguanRewardManager()
{

}

ChuangguanRewardManager::~ChuangguanRewardManager()
{
	m_dropIds.clear();
}

bool ChuangguanRewardManager::Init()
{
	m_dropIds.clear();
	//                      0          1
	const char *keys[] = { "type", "level_reward"};
	vector<map<string, string> > data;
	uint16 size = sizeof(keys) / sizeof(keys[0]);
	CXMLReader reader("chuangguan_event.xml");
	if (!reader.GetAllElements(data, keys, size))
		return false;

	for (uint32 i = 0; i < data.size(); i++)
	{
		int type = atoi(data[i][keys[0]].c_str());
		int dropId = atoi(data[i][keys[1]].c_str());
		m_dropIds[type] = dropId;
	}
	return true;
}

int ChuangguanRewardManager::GetDropId(int type)
{
	CGDropMapIt it = m_dropIds.find(type);
	if (it != m_dropIds.end())
	{
		return it->second;
	}
	return 0;
}
