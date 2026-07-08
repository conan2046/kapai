#include "pack_deal.h"
#include "singleton.h"
#include "protocol.h"
#include "singleton.h"
#include "main.h"
#include <boost/bind.hpp>
#include <boost/format.hpp>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

extern CMainClass *gpMain;
extern char *gConfigFile;

CPackageDeal::CPackageDeal():
	m_socketServer(SingletonSocket::instance())
{
	CDespatchCommand &despatch = SingletonDespatch::instance();

	SCommand cmdFun[] =
	{
		{ MSG_SERVER_USER_POWER,boost::bind(&CPackageDeal::DealServerMatch,this,_1,_2) },
	};
	m_socketServer.ObserveConnectClose(boost::bind(&CPackageDeal::OnSockClose,this,_1));
	despatch.AddCommandDeal(cmdFun,sizeof(cmdFun)/sizeof(SCommand));

	
}

void CPackageDeal::OnSockClose(int sock)
{

}

void CPackageDeal::DealServerMatch(CNetMessage* pMsg, int sock)
{
	if (pMsg == NULL)
		return;

	CNetMessage &msg = *pMsg;
	uint8 op = 0;
	uint32 userId = 0;
	uint32 power = 0;
	msg >> op;
	switch (op)
	{
	case 1:
	{
		msg >> userId >> power;
		sMatchManage.AddUpdatePower(userId, power);
	}
	break;

	case 2:
	{
		msg >> userId >> power;
		vector<aFight> matchs;
		sMatchManage.FindIds(userId, power, msg);
		sCSocketServer.SendMsg(sock, msg);
	}
	break;

	case 3:
	case 4:  // ÐÄÄ§
	{
		uint32 userId = 0;
		uint32 power = 0;
		msg >> userId >> power;
		sMatchManage.FindSingleId(userId, power, msg);
		sCSocketServer.SendMsg(sock, msg);
	}
	break;

	case 5: // À¥ÂØ
	{

		uint32 userId = 0;
		uint32 spower = 0;
		uint32 epower = 0;
		uint8 cnt = 0;
		msg >> userId >> spower >> epower >> cnt;
		sMatchManage.FindIds(userId, spower, epower, cnt, msg);
		sCSocketServer.SendMsg(sock, msg);
	}
	break;

	default:
		break;
	}
}

