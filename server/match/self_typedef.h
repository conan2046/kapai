#ifndef _SELF_TYPEDEF_H_
#define _SELF_TYPEDEF_H_
#include <string>
#include <gyu.h>

using namespace gyu::db;
using namespace gyu::net;

typedef unsigned char   uint8;
typedef unsigned short  uint16;
typedef short           int16;
typedef unsigned int    uint32;
typedef long long       int64;
typedef unsigned long long uint64;

#define CHATCH_PET_HUO_DONG 26
const int MAX_INT = 0x7fffffff;

const uint8 MAX_NAME_LEN = 64;

struct SKuaFuServerData
{
	SKuaFuServerData()
	{
		port = 0;
		ip.clear();
	}
	int port;
	std::string ip;
};

#endif

