#ifndef _GYU_DESPATCH_COMMAND_H_
#define _GYU_DESPATCH_COMMAND_H_
#include <boost/function.hpp>
#include <list>
#include "g_hash_table.h"
#include "g_net_msg.h"

namespace gyu {
	namespace net {
		struct SCommand
		{
			unsigned int comType;
			boost::function<void(gyu::net::CNetMessage*,int)> comFun;
		};

		class CDespatchCommand
		{
		public:
			CDespatchCommand():m_funMap(512){}
			void AddCommandDeal(SCommand *pBegin,int num);
			bool Despatch(gyu::net::CNetMessage*,int sock);
		private:
			bool AddCommand(unsigned int comType, boost::function<void(gyu::net::CNetMessage*,int)> );
			CHashTable<int, boost::function<void(gyu::net::CNetMessage*,int)> > m_funMap;
		};
	}
}
		
#endif


