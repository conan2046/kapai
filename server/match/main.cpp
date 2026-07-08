#include <iostream>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <signal.h>
#include <boost/bind.hpp>
#include <boost/archive/binary_oarchive.hpp>
#include <boost/archive/text_oarchive.hpp>
#include <fstream>
#include <zlib.h>
#include <boost/thread/thread.hpp>
#include <boost/format.hpp>
#include "pack_deal.h"
#include "main.h"
#include "protocol.h"
#include "singleton.h"
#include "self_typedef.h"
#include "utility.h"

using namespace std;

const char *gConfigFile = "../config";

time_t last_loadFanlicfg_time = 0;

static bool InitSysTime()
{
	time_t t;
	struct timeval tv;
	gettimeofday(&tv, NULL);
	SetSysTime(tv.tv_sec);
	SetSysTimeMs(tv.tv_usec/1000);
	t = GetSysTime();
	tm *pTm = localtime(&t);
	if(pTm == NULL)
		return false;
	SetSysYear(pTm->tm_year);
	SetSysYDay(pTm->tm_yday);
	SetSysWDay(pTm->tm_wday);
	SetSysMonth(pTm->tm_mon);
	SetSysMDay(pTm->tm_mday);
	SetSysHour(pTm->tm_hour);
	SetSysMinute(pTm->tm_min);
	SetSysSecond(pTm->tm_sec);
	return true;
}

static bool sExit = true;
static void SigHandlerCreateCore(int sig)
{
	cout << "SigHandlerCreateCore sig=" << sig << endl;
	abort();
	sExit = false;
}

static void SigHandler(int sig)
{
	cout<<"SigHandler sig="<<sig<<endl;
	sExit = false;
}

bool CMainClass::Init(int port)
{
	gyu::util::SetSignal(&SigHandler, &SigHandlerCreateCore);
	CNetMessage::SetNetMsgEncodeType(MET_Unicode);
	CNetMessage::SetMsgMaxLenSize(MMS_4Byte);

	for(uint8 i=0;i < GONGGAO_GROUP_NUM;i++)
		m_sysInfo[i].clear();
	if(!m_socketServer.Init(MAX_CON_USER, false, IntToStr(port).c_str()))
		return false;

	m_timerTime = 0;
	return true;
}

void CMainClass::DealPackThread()
{
	int sock;
	CNetMessage *pMsg = m_socketServer.GetPackage(sock);
	if(pMsg != NULL)
	{
		m_despatch.Despatch(pMsg,sock);
		delete pMsg;
	}
}


void CMainClass::Run()
{
	int count = 0;
	while(sExit)
	{

		count++;
		m_socketServer.DespatchEvent(1000);
		DealPackThread();

		//if (count >= 1000)
		//{
		//	InitSysTime();
		//	count = 0;
		//	time_t sysTime = GetSysTime();
		//	if (sysTime - m_timerTime > 10)
		//	{
		//		// 定时器
		//		m_timerTime = sysTime;
		//		TimeOut();
		//	}
		//	cout << sysTime << endl;
		//}
		// usleep(1);
	}
	m_socketServer.DestroyPackage();
}



void CMainClass::TimeOut()
{
}

static bool InitDB(SServerBasicCfg &cfg)
{
	string user = gyu::util::CIniFile::GetValue("username","login_db",gConfigFile);
	string password = gyu::util::CIniFile::GetValue("password","login_db",gConfigFile);
	string host = gyu::util::CIniFile::GetValue("host","login_db",gConfigFile);
	string db = gyu::util::CIniFile::GetValue("dbname","login_db",gConfigFile);
	string port = gyu::util::CIniFile::GetValue("port","login_db",gConfigFile);
	CDatabaseSql loginDB;
	if(!loginDB.Connect(user.c_str(),password.c_str(),host.c_str(),db.c_str(),atoi(port.c_str())))
	{
		cout<<"InitDB() : connect login db error"<<endl;
		return false;
	}

	char sql[512];
	char **row = NULL;
#ifndef KUA_FU
	string str = gyu::util::CIniFile::GetValue("server_id","server",gConfigFile);
	int serverId = atoi(str.c_str());
	if(str.empty() || serverId < 1)
	{
		cout<<"InitDB() : config.server.server_id error! "<<endl;
		return false;
	}
	//                             0      1    2       3        4   5
	snprintf(sql,sizeof(sql),"select s.match_port,d.ip,d.port,d.db_name,d.user,d.pwd from server_list as s,db_config as d where s.server_id=%d and s.db_id=d.id",serverId);
	if(!loginDB.Query(sql))
	{
		cout<<"InitDB() : loginDB.Query(sql) error1 , cannot find server_id  ...  sql="<<sql<<endl;
		return false;
	}
	if((row = loginDB.GetRow()) == NULL)
	{
		cout<<"InitDB() : loginDB.GetRow() error ... "<<endl;
		return false;
	}
	cfg.match_port = atoi(row[0]);
	cfg.dbHost = row[1];
	cfg.dbPort = row[2];
	cfg.dbName = row[3];
	cfg.dbUser = row[4];
	cfg.dbPwd = row[5];
#else
	string str = gyu::util::CIniFile::GetValue("kuafuID","server",gConfigFile);
	int kuafuId = atoi(str.c_str());
	if(str.empty() || kuafuId < 1)
	{
		cout<<"InitDB() : config.server.kuafuID error! "<<endl;
		return false;
	}

	//						       0	    1      2      3      4      5
	snprintf(sql,sizeof(sql),"SELECT match_port,db_host,db_port,db_user,db_pwd,db_name FROM kf_config WHERE id=%d",kuafuId);
	if(!loginDB.Query(sql))
	{
		cout<<"InitDB() : loginDB.Query(sql) error1 , cannot find kuafuID  ...	sql="<<sql<<endl;
		return false;
	}
	if((row = loginDB.GetRow()) == NULL)
	{
		cout<<"InitDB() : loginDB.GetRow() error ... "<<endl;
		return false;
	}
	cfg.match_port = atoi(row[0]);
	cfg.dbHost = row[1];
	cfg.dbPort = row[2];
	cfg.dbUser = row[3];
	cfg.dbPwd = row[4];
	cfg.dbName = row[5];
#endif
	return true;
}


CMainClass *gpMain;
int main(int argc,char **argv)
{
	SServerBasicCfg cfg;
	if(!InitDB(cfg))
		return -1;
	
	CDbPool *pPool = CDbPool::CreateInstance();
	pPool->SetDbConfigure(cfg.dbUser,cfg.dbPwd,cfg.dbHost,cfg.dbName,cfg.dbPort);
	srand(time(NULL));

	if (!InitSysTime())
		return -1;
	if(!sMatchManage.Init())
		return -1;

	CMainClass *pMain = new CMainClass;
	if(pMain->Init(cfg.match_port))
	{
		gpMain = pMain;
		pMain->Run();
	}

	cout<<"-- exit"<<endl;
	delete pMain;
	return 0;
}

int Connect(const char *ip,uint16 port)
{
	CSocketServer &socketServer = SingletonSocket::instance();
	struct sockaddr_in addr;
	memset(&addr,0,sizeof(addr));
	addr.sin_addr.s_addr = inet_addr(ip);
	addr.sin_port = htons(port);
	addr.sin_family = AF_INET;
	int sock = socket(AF_INET,SOCK_STREAM,0);
	if(sock < 0)
		return 0;

	struct timeval timev;
	timev.tv_sec = 6;
	timev.tv_usec = 0;
	setsockopt(sock,SOL_SOCKET,SO_RCVTIMEO,(const char*)&timev,sizeof(timev));
	setsockopt(sock,SOL_SOCKET,SO_SNDTIMEO,(const char*)&timev,sizeof(timev));
	if(connect(sock,(sockaddr*)&addr,sizeof(addr)) != 0)
	{
		close(sock);
		return 0;
	}
	socketServer.SetSock(sock);
	socketServer.AddEvent(sock);
	return sock;
}


