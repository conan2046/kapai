#ifndef _PACK_DEAL_H_
#define _PACK_DEAL_H_

#include <list>
#include <vector>
#include <map>
#include "self_typedef.h"
#include "utility.h"

using namespace std;

class SJumpTo;

const int ANSWER_QUESTION_SAPCE = 2*60*60;
const int USE_QIAN_NENG = 100;
const int USE_TILI_CHAT = 20;
const uint8 ADMIN_LEVEL = 1;
const int HELP_LIMIT = 16; // 帮助限制条目数

void ClearSockLongIdx(int sock);

class CPackageDeal
{
public:
	CPackageDeal();

public:
	void DealServerMatch(CNetMessage*, int sock);
	
private:
	void OnSockClose(int sock);

	CHashTable<uint32,list<uint32>*> m_inOutNotify;

	CSocketServer &m_socketServer;

	string m_version;
	uint8 m_forceUpdate;

	CDatabaseSql m_loginDb;
};
#endif


