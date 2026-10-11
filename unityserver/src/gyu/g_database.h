#ifndef _GYU_DATABASE_H_
#define _GYU_DATABASE_H_
#include <map>
#include <stack>
#include <string>
#include <boost/thread/mutex.hpp>

#ifndef __has_include
#define __has_include(x) 0
#endif

#if __has_include(<mysql/mysql.h>)
#include <mysql/mysql.h>
#elif __has_include(<mysql.h>)
#include <mysql.h>
#else
struct st_mysql;
struct st_mysql_res;
typedef st_mysql MYSQL;
typedef st_mysql_res MYSQL_RES;
#endif

namespace gyu {
	namespace db {
		class CDbPool;
		class CDbPoolData;
		class CGetDbConnect;
		struct CSqliteState;
		
		class CDatabaseSql
		{
		public:
			bool Query(const char *sqlSentence);
			bool ExecuteScript(const char *sqlScript);
			char **GetRow();
			bool GetResult(std::map<std::string,const char*> &);
			const char *GetErrMsg();	
			int GetRowNum();
			CDatabaseSql();
			~CDatabaseSql();
			bool Connect(const char *user,const char *passwd,const char *host,const char *database,int port, const char *pCharacter="utf8");
			bool ConnectSqlite(const char *databasePath);
			unsigned int InsertId();
			bool IsSqlite() const;

		private:
			CDatabaseSql(const CDatabaseSql &){}
			MYSQL_RES *m_result;
			MYSQL	*m_mysql;
			CSqliteState *m_sqlite;
			bool m_isSqlite;
			std::string dbUser;
			std::string dbPasswd;
			std::string dbHost;
			std::string dbName;
			std::string dbCharacter;
			int dbPort;
		};

		class CGetDbConnect
		{
		public:
			CGetDbConnect():m_pDbConnect(NULL){}
			~CGetDbConnect();
			CDatabaseSql *GetDbConnect();
		private:
			void *operator new(size_t t){return malloc(t);}
			CDatabaseSql *m_pDbConnect;
		};

		class CDbPoolData
		{
		public:
			CDbPoolData();
			CDatabaseSql *PopDbConnect();
			CDatabaseSql *NolockPopDbConnect();
			void PushDbConnect(CDatabaseSql *db);
			void NolockPushDbConnect(CDatabaseSql *db);

			boost::mutex m_poolMutex;
			bool m_isMultithread;
			CDbPool *m_pDbPool;
			std::stack<CDatabaseSql*> m_dbStack;
			std::string m_user;
			std::string m_password;
			std::string m_host;
			std::string m_dbName;
			std::string m_character;
			std::string m_sqlitePath;
			bool m_useSqlite;
			int m_port;
		};

		class CDbPool
		{
		public:
			void SetDbConfigure(std::string user, std::string passwd, std::string host, std::string dbname, std::string port, std::string character="utf8");
			void SetSqliteConfigure(std::string databasePath);
			bool AddDbConnect();
			static CDbPool *CreateInstance(bool isMultiThread=false);
		private:
			CDbPool(bool isMultithread=false);
			~CDbPool();
			static CDbPoolData *m_pData;
			friend class CGetDbConnect;
		};
	}
}

#endif
