#include "g_database.h"
#include <cstdlib>
#include <iostream>
#include <sstream>

#ifndef __has_include
#define __has_include(x) 0
#endif

#if __has_include(<mysql/mysql.h>)
#include <mysql/mysql.h>
#elif __has_include(<mysql.h>)
#include <mysql.h>
#else
#define GYU_NO_MYSQL_HEADERS 1
struct st_mysql {};
struct st_mysql_res {};
typedef char **MYSQL_ROW;
static st_mysql *mysql_init(st_mysql *) { return NULL; }
static st_mysql *mysql_real_connect(st_mysql *, const char *, const char *, const char *, const char *, unsigned int, const char *, unsigned long) { return NULL; }
static int mysql_query(st_mysql *, const char *) { return 1; }
static st_mysql_res *mysql_store_result(st_mysql *) { return NULL; }
static void mysql_free_result(st_mysql_res *) {}
static MYSQL_ROW mysql_fetch_row(st_mysql_res *) { return NULL; }
static unsigned int mysql_num_rows(st_mysql_res *) { return 0; }
static const char *mysql_error(st_mysql *) { return "mysql headers are not available"; }
static unsigned int mysql_insert_id(st_mysql *) { return 0; }
static void mysql_close(st_mysql *) {}
static int mysql_set_character_set(st_mysql *, const char *) { return 0; }
#endif

namespace gyu {
namespace db {

CDbPoolData *CDbPool::m_pData = NULL;

CDatabaseSql::CDatabaseSql()
	:m_result(NULL), m_mysql(NULL), dbPort(0)
{
}

CDatabaseSql::~CDatabaseSql()
{
	if(m_result != NULL)
		mysql_free_result(m_result);
	if(m_mysql != NULL)
		mysql_close(m_mysql);
}

bool CDatabaseSql::Connect(const char *user,const char *passwd,const char *host,const char *database,int port, const char *pCharacter)
{
	if(m_result != NULL)
	{
		mysql_free_result(m_result);
		m_result = NULL;
	}
	if(m_mysql != NULL)
	{
		mysql_close(m_mysql);
		m_mysql = NULL;
	}
	m_mysql = mysql_init(NULL);
	if(m_mysql == NULL)
	{
		std::cout << "CDatabaseSql::Connect mysql_init failed" << std::endl;
		return false;
	}
	if(mysql_real_connect(m_mysql, host, user, passwd, database, (unsigned int)port, NULL, 0) == NULL)
	{
		std::cout << "CDatabaseSql::Connect failed host=" << (host ? host : "")
			<< " port=" << port
			<< " db=" << (database ? database : "")
			<< " user=" << (user ? user : "")
			<< " error=" << mysql_error(m_mysql) << std::endl;
		return false;
	}
	if(pCharacter != NULL)
		mysql_set_character_set(m_mysql, pCharacter);
	dbUser = user ? user : "";
	dbPasswd = passwd ? passwd : "";
	dbHost = host ? host : "";
	dbName = database ? database : "";
	dbCharacter = pCharacter ? pCharacter : "";
	dbPort = port;
	return true;
}

bool CDatabaseSql::Query(const char *sqlSentence)
{
	if(m_mysql == NULL || sqlSentence == NULL)
	{
		std::cout << "CDatabaseSql::Query failed: mysql is not connected or sql is null"
			<< " db=" << dbName
			<< " host=" << dbHost
			<< " sql=" << (sqlSentence ? sqlSentence : "<null>") << std::endl;
		return false;
	}
	if(m_result != NULL)
	{
		mysql_free_result(m_result);
		m_result = NULL;
	}
	if(mysql_query(m_mysql, sqlSentence) != 0)
	{
		std::cout << "CDatabaseSql::Query failed sql=" << sqlSentence
			<< " error=" << mysql_error(m_mysql) << std::endl;
		return false;
	}
	m_result = mysql_store_result(m_mysql);
	return true;
}

char **CDatabaseSql::GetRow()
{
	if(m_result == NULL)
		return NULL;
	return mysql_fetch_row(m_result);
}

bool CDatabaseSql::GetResult(std::map<std::string,const char*> &out)
{
	out.clear();
	char **row = GetRow();
	if(row == NULL)
		return false;
	for(int i = 0; row[i] != NULL; ++i)
	{
		std::stringstream ss;
		ss << i;
		out[ss.str()] = row[i];
	}
	return true;
}

const char *CDatabaseSql::GetErrMsg()
{
	if(m_mysql == NULL)
		return "mysql is not connected";
	return mysql_error(m_mysql);
}

int CDatabaseSql::GetRowNum()
{
	if(m_result == NULL)
		return 0;
	return (int)mysql_num_rows(m_result);
}

unsigned int CDatabaseSql::InsertId()
{
	if(m_mysql == NULL)
		return 0;
	return (unsigned int)mysql_insert_id(m_mysql);
}

CDbPool::CDbPool(bool isMultithread)
{
	if(m_pData == NULL)
		m_pData = new CDbPoolData;
	m_pData->m_isMultithread = isMultithread;
	m_pData->m_pDbPool = this;
}

CDbPool::~CDbPool()
{
}

CDbPool *CDbPool::CreateInstance(bool isMultiThread)
{
	static CDbPool pool(isMultiThread);
	return &pool;
}

void CDbPool::SetDbConfigure(std::string user, std::string passwd, std::string host, std::string dbname, std::string port, std::string character)
{
	if(m_pData == NULL)
		m_pData = new CDbPoolData;
	m_pData->m_user = user;
	m_pData->m_password = passwd;
	m_pData->m_host = host;
	m_pData->m_dbName = dbname;
	m_pData->m_port = atoi(port.c_str());
	m_pData->m_character = character;
}

bool CDbPool::AddDbConnect()
{
	if(m_pData == NULL)
		return false;
	CDatabaseSql *db = new CDatabaseSql;
	if(!db->Connect(m_pData->m_user.c_str(), m_pData->m_password.c_str(), m_pData->m_host.c_str(),
		m_pData->m_dbName.c_str(), m_pData->m_port, m_pData->m_character.c_str()))
	{
		delete db;
		return false;
	}
	m_pData->PushDbConnect(db);
	return true;
}

CDatabaseSql *CDbPoolData::NolockPopDbConnect()
{
	if(!m_dbStack.empty())
	{
		CDatabaseSql *db = m_dbStack.top();
		m_dbStack.pop();
		return db;
	}
	CDatabaseSql *db = new CDatabaseSql;
	if(!db->Connect(m_user.c_str(), m_password.c_str(), m_host.c_str(), m_dbName.c_str(), m_port, m_character.c_str()))
	{
		delete db;
		return NULL;
	}
	return db;
}

CDatabaseSql *CDbPoolData::PopDbConnect()
{
	if(m_isMultithread)
	{
		boost::mutex::scoped_lock lk(m_poolMutex);
		return NolockPopDbConnect();
	}
	return NolockPopDbConnect();
}

void CDbPoolData::NolockPushDbConnect(CDatabaseSql *db)
{
	if(db != NULL)
		m_dbStack.push(db);
}

void CDbPoolData::PushDbConnect(CDatabaseSql *db)
{
	if(m_isMultithread)
	{
		boost::mutex::scoped_lock lk(m_poolMutex);
		NolockPushDbConnect(db);
		return;
	}
	NolockPushDbConnect(db);
}

CGetDbConnect::~CGetDbConnect()
{
	if(m_pDbConnect != NULL && CDbPool::m_pData != NULL)
		CDbPool::m_pData->PushDbConnect(m_pDbConnect);
}

CDatabaseSql *CGetDbConnect::GetDbConnect()
{
	if(m_pDbConnect != NULL)
		return m_pDbConnect;
	if(CDbPool::m_pData == NULL)
		return NULL;
	m_pDbConnect = CDbPool::m_pData->PopDbConnect();
	return m_pDbConnect;
}

}
}
