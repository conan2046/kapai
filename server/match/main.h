#ifndef _MAIN_CLASS_H_
#define _MAIN_CLASS_H_

#include <string>
#include "pack_deal.h"
#include "singleton.h"
#include "self_typedef.h"

struct SServerBasicCfg
{
	SServerBasicCfg()
	{
		match_port = 0;
		dbHost.clear();
		dbPort.clear();
		dbName.clear();
		dbUser.clear();
		dbPwd.clear();
	}
	
	int match_port;
	string dbHost;
	string dbPort;
	string dbName;
	string dbUser;
	string dbPwd;
};


class CUser;
class CMainClass
{
public:
	CMainClass():m_despatch(SingletonDespatch::instance()),
		m_socketServer(SingletonSocket::instance())
	{
		m_inBaihua = false;
		m_addMonster = 0;
	}
	bool Init(int port);
	void Run();
private:
	void TimeOut();
	void DealPackThread();
	CPackageDeal packDeal;
	CDespatchCommand &m_despatch;
	CSocketServer &m_socketServer;
	int m_threadNum;
	bool m_inBaihua;

	time_t m_addMonster;
	const static uint8 GONGGAO_GROUP_NUM = 2;

	CNetMessage m_GongGaoMsg;
	int m_sysInfoTimeSpace[GONGGAO_GROUP_NUM];
	time_t m_sendTime[GONGGAO_GROUP_NUM];
	vector<string> m_sysInfo[GONGGAO_GROUP_NUM];
	uint8 m_sendIdx[GONGGAO_GROUP_NUM];
	string m_cxGongGao;

public:
	time_t m_timerTime;   // 定时器间隔
};

int Connect(const char *ip,uint16 port);

#endif

