#include "g_socket_server.h"
#include <cstring>
#include <iostream>
#include <vector>

#ifdef _WIN32
#include <ws2tcpip.h>
#define CLOSESOCKET closesocket
static bool s_wsa_started = false;
static void ensure_wsa()
{
	if(!s_wsa_started)
	{
		WSADATA wsa;
		WSAStartup(MAKEWORD(2,2), &wsa);
		s_wsa_started = true;
	}
}
#else
#include <arpa/inet.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>
#define CLOSESOCKET close
static void ensure_wsa() {}
#endif

namespace gyu {
namespace net {

CNetMessage *CPackageList::NolockGetMsg(int &sock)
{
	if(m_msgList.empty())
		return NULL;
	std::pair<int, CNetMessage*> item = m_msgList.front();
	m_msgList.pop_front();
	sock = item.first;
	return item.second;
}

CNetMessage *CPackageList::GetMsg(int &sock)
{
	if(m_isMultithread)
	{
		boost::mutex::scoped_lock lk(m_listMutex);
		return NolockGetMsg(sock);
	}
	return NolockGetMsg(sock);
}

bool CPackageList::NolockAddMsg(CNetMessage *pMsg,int sock)
{
	if(pMsg == NULL)
		return false;
	m_msgList.push_back(std::make_pair(sock, pMsg));
	m_listCond.notify_one();
	return true;
}

bool CPackageList::AddMsg(CNetMessage *pMsg,int sock)
{
	if(m_isMultithread)
	{
		boost::mutex::scoped_lock lk(m_listMutex);
		return NolockAddMsg(pMsg, sock);
	}
	return NolockAddMsg(pMsg, sock);
}

void CPackageList::NolockDelMsg(int sock)
{
	for(std::list<std::pair<int, CNetMessage*> >::iterator it = m_msgList.begin(); it != m_msgList.end();)
	{
		if(it->first == sock)
		{
			delete it->second;
			it = m_msgList.erase(it);
		}
		else
			++it;
	}
}

void CPackageList::DelMsg(int sock)
{
	if(m_isMultithread)
	{
		boost::mutex::scoped_lock lk(m_listMutex);
		NolockDelMsg(sock);
		return;
	}
	NolockDelMsg(sock);
}

void CPackageList::Destroy()
{
	if(m_isMultithread)
	{
		boost::mutex::scoped_lock lk(m_listMutex);
		while(!m_msgList.empty())
		{
			delete m_msgList.front().second;
			m_msgList.pop_front();
		}
		return;
	}
	while(!m_msgList.empty())
	{
		delete m_msgList.front().second;
		m_msgList.pop_front();
	}
}

void CPackageList::SetMultiThread(bool isMultiThread)
{
	m_isMultithread = isMultiThread;
}

CSocketServer::CSocketServer()
	:m_epollNum(0), m_epollEvent(NULL), m_isMultithread(false), m_listenSock(0), m_epollFd(0)
{
}

CSocketServer::~CSocketServer()
{
	if(m_listenSock > 0)
		CLOSESOCKET(m_listenSock);
	DestroyPackage();
}

bool CSocketServer::Bind(const char *ip, const char *port)
{
	ensure_wsa();
	m_listenSock = (int)socket(AF_INET, SOCK_STREAM, 0);
	if(m_listenSock <= 0)
		return false;
	int opt = 1;
	setsockopt(m_listenSock, SOL_SOCKET, SO_REUSEADDR, (const char*)&opt, sizeof(opt));
	sockaddr_in addr;
	memset(&addr, 0, sizeof(addr));
	addr.sin_family = AF_INET;
	addr.sin_port = htons((unsigned short)atoi(port));
	addr.sin_addr.s_addr = ip ? inet_addr(ip) : INADDR_ANY;
	if(bind(m_listenSock, (sockaddr*)&addr, sizeof(addr)) != 0)
		return false;
	return listen(m_listenSock, 64) == 0;
}

bool CSocketServer::Init(int maxConnect, bool isMultithread, const char *port, const char *ip)
{
	m_epollNum = maxConnect;
	m_isMultithread = isMultithread;
	m_packageList.SetMultiThread(isMultithread);
	return Bind(ip, port);
}

bool CSocketServer::OnAccept(int, sockaddr_in *)
{
	return true;
}

void CSocketServer::OnRecv(int sock)
{
	char buf[8192];
	int ret = (int)recv(sock, buf, sizeof(buf), 0);
	std::cout << "[local] socket recv sock=" << sock << " ret=" << ret << std::endl;
	if(ret <= 0)
	{
		std::cout << "[local] socket close on recv sock=" << sock << std::endl;
		CloseConnect(sock);
		return;
	}
	CNetMessage *recvMsg = NULL;
	if(!m_recvMsgList.Find(sock, recvMsg) || recvMsg == NULL)
	{
		recvMsg = new CNetMessage;
		recvMsg->GetMsgData()->clear();
		m_recvMsgList.Insert(sock, recvMsg);
	}
	std::string *data = recvMsg->GetMsgData();
	data->append(buf, ret);

	while(data->size() >= CNetMessage::GetHeadLen())
	{
		unsigned int bodyLen = 0;
		if(CNetMessage::GetHeadLen() == 6)
			memcpy(&bodyLen, data->data(), 4);
		else
		{
			unsigned short s = 0;
			memcpy(&s, data->data(), 2);
			bodyLen = s;
		}
		unsigned int packLen = bodyLen + CNetMessage::GetHeadLen();
		if(packLen > CNetMessage::MAX_RECV_PACK_LEN)
		{
			std::cout << "[local] socket invalid packLen sock=" << sock << " bodyLen=" << bodyLen << " totalLen=" << packLen << " buffered=" << data->size() << std::endl;
			data->clear();
			return;
		}
		if(bodyLen == 0)
		{
			unsigned short zeroBodyType = 0;
			if(data->size() >= CNetMessage::GetHeadLen())
				memcpy(&zeroBodyType, data->data() + 4, sizeof(zeroBodyType));
			if(zeroBodyType == 0)
			{
				bool allZero = true;
				for(size_t i = 0; i < data->size(); ++i)
				{
					if((*data)[i] != 0)
					{
						allZero = false;
						break;
					}
				}
				if(allZero)
				{
					std::cout << "[local] socket drop zero padding sock=" << sock << " buffered=" << data->size() << std::endl;
					data->clear();
					return;
				}
				std::cout << "[local] socket invalid zero-body type sock=" << sock << " buffered=" << data->size() << std::endl;
				data->erase(0, CNetMessage::GetHeadLen());
				continue;
			}
		}
		if(data->size() < packLen)
		{
			std::cout << "[local] socket wait full pack sock=" << sock << " bodyLen=" << bodyLen << " totalLen=" << packLen << " buffered=" << data->size() << std::endl;
			return;
		}

		CNetMessage *msg = new CNetMessage;
		msg->SetData((void*)data->data(), packLen);
		std::cout << "[local] socket full pack sock=" << sock << " bodyLen=" << bodyLen << " totalLen=" << packLen << " type=" << msg->GetType() << std::endl;
		if(msg->GetType() == 0 && packLen == CNetMessage::GetHeadLen())
		{
			std::cout << "[local] socket drop empty pack sock=" << sock << std::endl;
			delete msg;
		}
		else
		{
			m_packageList.AddMsg(msg, sock);
		}
		data->erase(0, packLen);
	}
}

void CSocketServer::OnSend(int sock)
{
	if(m_isMultithread)
	{
		boost::mutex::scoped_lock lk(m_sendListMutex);
		NolockOnSend(sock);
		return;
	}
	NolockOnSend(sock);
}

void CSocketServer::NolockOnSend(int sock)
{
	std::list<CNetMessage *> *queue = NULL;
	if(!m_sendMsgList.Find(sock, queue) || queue == NULL || queue->empty())
		return;
	CNetMessage *msg = queue->front();
	std::cout << "[local] socket send sock=" << sock << " type=" << msg->GetType() << " len=" << msg->GetDataLen() << std::endl;
	if(msg->SendMsg(sock) <= 0)
	{
		std::cout << "[local] socket send pending/fail sock=" << sock << std::endl;
		return;
	}
	if(msg->SendComplete())
	{
		std::cout << "[local] socket send complete sock=" << sock << std::endl;
		queue->pop_front();
		delete msg;
		if(queue->empty())
		{
			m_sendMsgList.Erase(sock);
			delete queue;
		}
	}
}

void CSocketServer::DespatchEvent(int timeOut)
{
	fd_set readfds;
	fd_set writefds;
	FD_ZERO(&readfds);
	FD_ZERO(&writefds);
	int maxfd = m_listenSock;
	if(m_listenSock > 0)
		FD_SET(m_listenSock, &readfds);

	std::vector<int> recvSocks;
	m_recvMsgList.ForEach(boost::function<bool(int,CNetMessage*)>([&](int sock, CNetMessage*) {
		FD_SET(sock, &readfds);
		if(sock > maxfd) maxfd = sock;
		return true;
	}));
	if(m_isMultithread)
	{
		boost::mutex::scoped_lock lk(m_sendListMutex);
		m_sendMsgList.ForEach(boost::function<bool(int,std::list<CNetMessage*>*)>([&](int sock, std::list<CNetMessage*>*) {
			FD_SET(sock, &writefds);
			if(sock > maxfd) maxfd = sock;
			return true;
		}));
	}
	else
	{
		m_sendMsgList.ForEach(boost::function<bool(int,std::list<CNetMessage*>*)>([&](int sock, std::list<CNetMessage*>*) {
			FD_SET(sock, &writefds);
			if(sock > maxfd) maxfd = sock;
			return true;
		}));
	}

	timeval tv;
	tv.tv_sec = timeOut / 1000;
	tv.tv_usec = (timeOut % 1000) * 1000;
	int ret = select(maxfd + 1, &readfds, &writefds, NULL, &tv);
	if(ret <= 0)
		return;

	if(m_listenSock > 0 && FD_ISSET(m_listenSock, &readfds))
	{
		sockaddr_in addr;
#ifdef _WIN32
		int len = sizeof(addr);
#else
		socklen_t len = sizeof(addr);
#endif
		int sock = (int)accept(m_listenSock, (sockaddr*)&addr, &len);
		if(sock > 0)
			std::cout << "[local] socket accept sock=" << sock << std::endl;
		if(sock > 0 && OnAccept(sock, &addr))
			SetSock(sock);
	}

	std::vector<int> readReady;
	m_recvMsgList.ForEach(boost::function<bool(int,CNetMessage*)>([&](int sock, CNetMessage*) {
		if(FD_ISSET(sock, &readfds))
			readReady.push_back(sock);
		return true;
	}));
	for(size_t i = 0; i < readReady.size(); ++i)
		OnRecv(readReady[i]);

	std::vector<int> writeReady;
	if(m_isMultithread)
	{
		boost::mutex::scoped_lock lk(m_sendListMutex);
		m_sendMsgList.ForEach(boost::function<bool(int,std::list<CNetMessage*>*)>([&](int sock, std::list<CNetMessage*>*) {
			if(FD_ISSET(sock, &writefds))
				writeReady.push_back(sock);
			return true;
		}));
	}
	else
	{
		m_sendMsgList.ForEach(boost::function<bool(int,std::list<CNetMessage*>*)>([&](int sock, std::list<CNetMessage*>*) {
			if(FD_ISSET(sock, &writefds))
				writeReady.push_back(sock);
			return true;
		}));
	}
	for(size_t i = 0; i < writeReady.size(); ++i)
		OnSend(writeReady[i]);
}

void CSocketServer::NolockSendMsg(int sock, CNetMessage &msg, bool clearOld)
{
	if(clearOld)
		NolockClearSockMsg(sock);
	CNetMessage *copy = new CNetMessage;
	copy->CopyData(msg);
	copy->ReSend();
	std::list<CNetMessage *> *queue = NULL;
	if(!m_sendMsgList.Find(sock, queue) || queue == NULL)
	{
		queue = new std::list<CNetMessage *>;
		queue->push_back(copy);
		m_sendMsgList.Insert(sock, queue);
		NolockOnSend(sock);
	}
	else
	{
		queue->push_back(copy);
	}
}

void CSocketServer::SendMsg(int sock, CNetMessage &msg, bool clearOld)
{
	if(m_isMultithread)
	{
		boost::mutex::scoped_lock lk(m_sendListMutex);
		NolockSendMsg(sock, msg, clearOld);
		return;
	}
	NolockSendMsg(sock, msg, clearOld);
}

void CSocketServer::SendServerMsg(int type, CNetMessage &msg, bool clearOld)
{
	int sock = GetServerSock(type);
	if(sock > 0)
		SendMsg(sock, msg, clearOld);
}

void CSocketServer::ObserveConnectClose(boost::function<void(int)> f)
{
	m_onClose = f;
}

int CSocketServer::Connect(const char *ip, int port)
{
	ensure_wsa();
	int sock = (int)socket(AF_INET, SOCK_STREAM, 0);
	if(sock <= 0)
		return 0;
	sockaddr_in addr;
	memset(&addr, 0, sizeof(addr));
	addr.sin_family = AF_INET;
	addr.sin_port = htons((unsigned short)port);
	addr.sin_addr.s_addr = inet_addr(ip);
	if(connect(sock, (sockaddr*)&addr, sizeof(addr)) != 0)
	{
		CLOSESOCKET(sock);
		return 0;
	}
	SetSock(sock);
	return sock;
}

int CSocketServer::Connect(int type)
{
	std::map<int, ServerCfg>::iterator it = m_serverMap.find(type);
	if(it == m_serverMap.end())
		return 0;
	int sock = Connect(it->second.ip.c_str(), it->second.port);
	if(sock > 0)
	{
		it->second.sock = sock;
		if(it->second.firstRun)
			it->second.firstRun();
	}
	return sock;
}

void CSocketServer::SetSock(int sockId)
{
	CNetMessage *recvMsg = new CNetMessage;
	recvMsg->GetMsgData()->clear();
	m_recvMsgList.Insert(sockId, recvMsg);
}

void CSocketServer::CloseConnect(int sock)
{
	if(sock <= 0)
		return;
	ClearServerSock(sock);
	NolockClearSockMsg(sock);
	CNetMessage *recvMsg = NULL;
	m_recvMsgList.Erase(sock, recvMsg);
	delete recvMsg;
	m_packageList.DelMsg(sock);
	CLOSESOCKET(sock);
	if(m_onClose)
		m_onClose(sock);
}

CNetMessage *CSocketServer::GetPackage(int &sock)
{
	return m_packageList.GetMsg(sock);
}

void CSocketServer::DestroyPackage()
{
	m_packageList.Destroy();
}

bool CSocketServer::AddEvent(int)
{
	return true;
}

bool CSocketServer::AddServerInfo(ServerCfg &data)
{
	m_serverMap[data.type] = data;
	return true;
}

bool CSocketServer::IsServer(int sock)
{
	for(std::map<int, ServerCfg>::iterator it = m_serverMap.begin(); it != m_serverMap.end(); ++it)
		if(it->second.sock == sock)
			return true;
	return false;
}

void CSocketServer::ClearServerSock(int sock)
{
	for(std::map<int, ServerCfg>::iterator it = m_serverMap.begin(); it != m_serverMap.end(); ++it)
		if(it->second.sock == sock)
			it->second.sock = 0;
}

int CSocketServer::GetServerSock(int type)
{
	std::map<int, ServerCfg>::iterator it = m_serverMap.find(type);
	if(it == m_serverMap.end())
		return 0;
	if(it->second.sock <= 0)
		return Connect(type);
	return it->second.sock;
}

void CSocketServer::NolockClearSockMsg(int sock)
{
	std::list<CNetMessage *> *queue = NULL;
	m_sendMsgList.Erase(sock, queue);
	if(queue == NULL)
		return;
	for(std::list<CNetMessage *>::iterator it = queue->begin(); it != queue->end(); ++it)
		delete *it;
	delete queue;
}

}
}
