#ifndef _CONFIG_PARA_H_
#define _CONFIG_PARA_H_

#include <map>
#include <string>
#include "singleton.h"
#include "self_typedef.h"

struct SParaData
{
	string type;
	string val;
};

class CParaMgr
{
public:
	static const int ErrInt = 0x7fffffff;

	CParaMgr();

	bool Init();

	bool GetData(string key, SParaData &value);

	int GetInt(string key);

	string GetString(string key);
	
	void ReadSpirit(string& val);
	void ReadFaBaoSouSuo(string& val);
	void ReadArena(string& val);
	void ReadAward(string& val, SAwardData& ad);
	void ReadKunLunBuy(string& val);
	void ReadXiuLianAttr(string& val);

public:
	SAwardData m_gaiMing;
	SAwardData m_bangGaiMing;
private:
	bool CheckFieldType(string &type);

	map<string, SParaData> m_data;
};

typedef boost::details::pool::singleton_default<CParaMgr> SingletonCParaMgr;
#define sCParaMgr boost::details::pool::singleton_default<CParaMgr>::instance()

#endif

