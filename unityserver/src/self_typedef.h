#ifndef _SELF_TYPEDEF_H_
#define _SELF_TYPEDEF_H_
#include <boost/shared_ptr.hpp>
#include <string>
#include <map>
#include <vector>
#include <gyu.h>
#include "language_transform.h"
#include "para_def.h"

using namespace gyu::db;
using namespace gyu::net;


typedef unsigned char   uint8;
typedef unsigned short  uint16;
typedef short           int16;
typedef unsigned int    uint32;
typedef long long       int64;
typedef unsigned long long uint64;


typedef std::map<uint8, uint16> U8tU16Map;
typedef U8tU16Map::iterator U8tU16MapIt;
typedef std::map<uint16, uint16> U16tU16Map;
typedef U16tU16Map::iterator U16tU16MapIt;
typedef std::map<uint8, uint32> U8tU32Map;
typedef U8tU32Map::iterator U8tU32MapIt;
typedef std::map<uint16, uint32> U16tU32Map;
typedef U16tU32Map::iterator U16tU32MapIt;
typedef U16tU32Map::reverse_iterator U16tU32MapRit;
typedef std::map<uint16, uint8> U16tU8Map;
typedef U16tU8Map::iterator U16tU8MapIt;
typedef std::map<uint8, uint8> U8tU8Map;
typedef U8tU8Map::iterator U8tU8MapIt;
typedef std::map<uint32, uint16> U32tU16Map;
typedef U32tU16Map::iterator U32tU16MapIt;
typedef std::map<uint32, uint32> U32tU32Map;
typedef U32tU32Map::iterator U32tU32MapIt;

typedef std::map<uint16, double> U16tDblMap;
typedef U16tDblMap::iterator U16tDblMapIt;

struct TypeValue
{
	uint32 type;
	uint32 value;
};
typedef std::vector<TypeValue> MultiTypeValue;

struct SAwardData
{
	SAwardData()
	{
		Clear();
	}
	void Clear()
	{
		type = 0;
		typeId = 0;
		num = 0;
	}

	int type;
	int typeId;
	int num;
};
typedef std::vector<SAwardData> MultiAward;

typedef std::map<uint8, MultiAward> U8MultiAwardMap;
typedef std::map<uint8, MultiAward>::iterator U8MultiAwardMapIt;
typedef std::map<uint16, MultiAward> U16MultiAwardMap;
typedef std::map<uint16, MultiAward>::iterator U16MultiAwardMapIt;

#define MAKEUINT32(a, b)      ((uint32)(((uint16)(((uint32&)(a)) & 0xffff)) | ((uint32)((uint16)(((uint32&)(b)) & 0xffff))) << 16))
#define LOUINT16(l)           ((uint16)(((uint32&)(l)) & 0xffff))
#define HIUINT16(l)           ((uint16)((((uint32&)(l)) >> 16) & 0xffff))
#define CHATCH_PET_HUO_DONG 26
const int MAX_INT = 0x7fffffff;

const uint8 MAX_NAME_LEN = 64;

class CUser;
typedef boost::shared_ptr<CUser> ShareUserPtr;

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

