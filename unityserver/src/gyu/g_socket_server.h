#ifndef _GYU_SOCKET_SERVER_H_
#define _GYU_SOCKET_SERVER_H_

#include <list>
#include <map>
#include <string>
#include <boost/function.hpp>
#include <boost/thread/condition.hpp>
#include "g_hash_table.h"
#include "g_net_msg.h"

#ifdef _WIN32
#include <winsock2.h>
struct epoll_event { int events; int data_fd; };
#else
#include <sys/epoll.h>
#endif

struct sockaddr_in;

namespace gyu {
	namespace net {
		struct ServerCfg {
			ServerCfg()
			{
				Clear();
			}
			void Clear()
			{
				sock = 0;
				type = 0;
				port = 0;
				ip.clear();
				firstRun.clear();
			}

			int sock;
			int type;
			int port;
			std::string ip;
			boost::function<void()> firstRun;
		};

		class CPackageList
		{
		public:
			CPackageList():m_isMultithread(false){}
			CNetMessage *GetMsg(int &sock);
			bool AddMsg(gyu::net::CNetMessage *pMsg,int sock);
			void DelMsg(int sock);
			void Destroy();
			void SetMultiThread(bool isMultiThread=false);

		private:
			CNetMessage *NolockGetMsg(int &sock);
			bool NolockAddMsg(gyu::net::CNetMessage *pMsg,int sock);
			void NolockDelMsg(int sock);

			std::list<std::pair<int, gyu::net::CNetMessage*> > m_msgList;
			boost::condition m_listCond;
			boost::mutex m_listMutex;
			bool m_isMultithread;
		};

		class CSocketServer
		{
		public:
			CSocketServer();
			virtual ~CSocketServer();
			bool Init(int maxConnect, bool isMultithread, const char *port, const char *ip=NULL);
			void DespatchEvent(int timeOut);
			void SendMsg(int sock, gyu::net::CNetMessage &msg, bool clearOld = false);
			void SendServerMsg(int type, gyu::net::CNetMessage &msg, bool clearOld=false);
			void ObserveConnectClose(boost::function<void(int)>);
			int Connect(const char *ip, int port);
			void SetSock(int sockId);
			void CloseConnect(int sock);
			gyu::net::CNetMessage *GetPackage(int &sock);
			void DestroyPackage();
			bool AddEvent(int sock);
			bool AddServerInfo(ServerCfg &data);
			bool IsServer(int sock);

		protected:
			virtual bool OnAccept(int, sockaddr_in *);
			virtual void OnRecv(int sock);
			virtual void OnSend(int sock);

		private:
			bool Bind(const char *ip, const char *port);
			int Connect(int type);
			void ClearServerSock(int sock);
			int GetServerSock(int type);
			virtual void NolockOnSend(int sock);
			void NolockSendMsg(int sock, gyu::net::CNetMessage &msg, bool clearOld = false);
			void NolockClearSockMsg(int sock);

		private:
			int m_epollNum;
			epoll_event *m_epollEvent;
			bool m_isMultithread;
			CHashTable<int, std::list<gyu::net::CNetMessage *> *> m_sendMsgList;
			boost::mutex m_sendListMutex;
			CHashTable<int, gyu::net::CNetMessage*> m_recvMsgList;
			CPackageList m_packageList;
			boost::function<void(int)> m_onClose;
			std::map<int, ServerCfg> m_serverMap;
			int m_listenSock;
			int m_epollFd;
		};
	}
}

#endif
