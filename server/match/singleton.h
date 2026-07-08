#ifndef _SINGLETON_H_
#define _SINGLETON_H_
#include "match_manage.h"
#include "self_typedef.h"

typedef boost::details::pool::singleton_default<CDespatchCommand> SingletonDespatch;
typedef boost::details::pool::singleton_default<CSocketServer> SingletonSocket;

#define sCSocketServer SingletonSocket::instance()

#define sMatchManage boost::details::pool::singleton_default<MatchManage>::instance()

#endif

