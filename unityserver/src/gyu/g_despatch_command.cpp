#include "g_despatch_command.h"

namespace gyu {
namespace net {

void CDespatchCommand::AddCommandDeal(SCommand *pBegin,int num)
{
	for(int i = 0; i < num; ++i)
		AddCommand(pBegin[i].comType, pBegin[i].comFun);
}

bool CDespatchCommand::AddCommand(unsigned int comType, boost::function<void(CNetMessage*,int)> fun)
{
	m_funMap.Insert((int)comType, fun);
	return true;
}

bool CDespatchCommand::Despatch(CNetMessage *msg,int sock)
{
	if(msg == NULL)
		return false;
	boost::function<void(CNetMessage*,int)> fun;
	if(!m_funMap.Find((int)msg->GetType(), fun))
		return false;
	fun(msg, sock);
	return true;
}

}
}
