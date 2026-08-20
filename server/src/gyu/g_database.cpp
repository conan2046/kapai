#include "g_database.h"
#include <cctype>
#include <cstdio>
#include <cstdlib>
#include <ctime>
#include <iostream>
#include <regex>
#include <sstream>
#include <vector>

#if defined(GYU_ENABLE_SQLITE)
#include <sqlite3.h>
#endif

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

#if defined(GYU_ENABLE_SQLITE)
static bool SqliteEqualsNoCase(const std::string &value, size_t offset, const char *expected)
{
	for(size_t i = 0; expected[i] != '\0'; ++i)
	{
		if(offset + i >= value.size())
			return false;
		if(std::tolower((unsigned char)value[offset + i]) != std::tolower((unsigned char)expected[i]))
			return false;
	}
	return true;
}

static bool SqliteIsWordCharacter(char value)
{
	return std::isalnum((unsigned char)value) != 0 || value == '_';
}

static bool SqliteMatchesWord(const std::string &value, size_t offset, const char *expected)
{
	size_t length = 0;
	while(expected[length] != '\0')
		++length;
	if(!SqliteEqualsNoCase(value, offset, expected))
		return false;
	if(offset > 0 && SqliteIsWordCharacter(value[offset - 1]))
		return false;
	return offset + length >= value.size() || !SqliteIsWordCharacter(value[offset + length]);
}

static size_t SqliteSkipSpaces(const std::string &value, size_t offset)
{
	while(offset < value.size() && std::isspace((unsigned char)value[offset]) != 0)
		++offset;
	return offset;
}

static std::string SqliteEscapeLiteral(const std::string &value)
{
	std::string escaped;
	escaped.reserve(value.size());
	for(size_t i = 0; i < value.size(); ++i)
	{
		escaped.push_back(value[i]);
		if(value[i] == '\'')
			escaped.push_back('\'');
	}
	return escaped;
}

static bool SqliteRewriteShow(const std::string &sql, std::string &rewritten)
{
	static const std::regex showTables("^\\s*show\\s+tables\\s+like\\s+'([^']+)'\\s*;?\\s*$", std::regex::icase);
	static const std::regex showColumns("^\\s*show\\s+columns\\s+from\\s+[`\"]?([A-Za-z_][A-Za-z0-9_]*)[`\"]?\\s+like\\s+'([^']+)'\\s*;?\\s*$", std::regex::icase);
	std::smatch match;
	if(std::regex_match(sql, match, showTables))
	{
		rewritten = "SELECT name FROM sqlite_master WHERE type='table' AND name LIKE '" + SqliteEscapeLiteral(match[1].str()) + "'";
		return true;
	}
	if(std::regex_match(sql, match, showColumns))
	{
		rewritten = "SELECT name FROM pragma_table_info('" + SqliteEscapeLiteral(match[1].str()) + "') WHERE name LIKE '" + SqliteEscapeLiteral(match[2].str()) + "'";
		return true;
	}
	return false;
}

static std::string SqliteTrim(const std::string &value)
{
	const size_t begin = SqliteSkipSpaces(value, 0);
	size_t end = value.size();
	while(end > begin && std::isspace((unsigned char)value[end - 1]) != 0)
		--end;
	return value.substr(begin, end - begin);
}

static std::vector<std::string> SqliteSplitDefinitions(const std::string &body)
{
	std::vector<std::string> definitions;
	size_t begin = 0;
	int depth = 0;
	char quote = '\0';
	for(size_t i = 0; i < body.size(); ++i)
	{
		const char current = body[i];
		if(quote != '\0')
		{
			if(current == quote)
			{
				if(i + 1 < body.size() && body[i + 1] == quote)
					++i;
				else
					quote = '\0';
			}
			else if(current == '\\' && i + 1 < body.size())
				++i;
			continue;
		}
		if(current == '\'' || current == '"' || current == '`')
		{
			quote = current;
			continue;
		}
		if(current == '(')
			++depth;
		else if(current == ')')
			--depth;
		else if(current == ',' && depth == 0)
		{
			definitions.push_back(SqliteTrim(body.substr(begin, i - begin)));
			begin = i + 1;
		}
	}
	definitions.push_back(SqliteTrim(body.substr(begin)));
	return definitions;
}

static std::string SqliteStripMysqlColumnOptions(const std::string &definition)
{
	std::string result = definition;
	static const std::regex characterSet("\\s+character\\s+set\\s+[A-Za-z0-9_]+", std::regex::icase);
	static const std::regex collate("\\s+collate\\s+[A-Za-z0-9_]+", std::regex::icase);
	static const std::regex comment("\\s+comment\\s+'(?:''|[^'])*'", std::regex::icase);
	static const std::regex onUpdate("\\s+on\\s+update\\s+current_timestamp(?:\\(\\))?", std::regex::icase);
	result = std::regex_replace(result, characterSet, "");
	result = std::regex_replace(result, collate, "");
	result = std::regex_replace(result, comment, "");
	result = std::regex_replace(result, onUpdate, "");
	return SqliteTrim(result);
}

static bool SqliteGetColumnName(const std::string &definition, std::string &name)
{
	if(definition.empty())
		return false;
	if(definition[0] == '`' || definition[0] == '"')
	{
		const size_t end = definition.find(definition[0], 1);
		if(end == std::string::npos)
			return false;
		name = definition.substr(1, end - 1);
		return !name.empty();
	}
	size_t end = 0;
	while(end < definition.size() && SqliteIsWordCharacter(definition[end]))
		++end;
	if(end == 0)
		return false;
	name = definition.substr(0, end);
	return true;
}

static bool SqliteRewriteCreateTable(const std::string &sql, std::string &rewritten)
{
	static const std::regex createPrefix("^\\s*create\\s+table\\s+if\\s+not\\s+exists\\s+([`\"]?[A-Za-z_][A-Za-z0-9_]*[`\"]?)\\s*\\(", std::regex::icase);
	std::smatch prefix;
	if(!std::regex_search(sql, prefix, createPrefix) || prefix.position() != 0)
		return false;
	const size_t bodyBegin = (size_t)(prefix.position() + prefix.length());
	int depth = 1;
	char quote = '\0';
	size_t bodyEnd = std::string::npos;
	for(size_t i = bodyBegin; i < sql.size(); ++i)
	{
		const char current = sql[i];
		if(quote != '\0')
		{
			if(current == quote)
			{
				if(i + 1 < sql.size() && sql[i + 1] == quote)
					++i;
				else
					quote = '\0';
			}
			else if(current == '\\' && i + 1 < sql.size())
				++i;
			continue;
		}
		if(current == '\'' || current == '"' || current == '`')
			quote = current;
		else if(current == '(')
			++depth;
		else if(current == ')' && --depth == 0)
		{
			bodyEnd = i;
			break;
		}
	}
	if(bodyEnd == std::string::npos)
		return false;
	const std::vector<std::string> sourceDefinitions = SqliteSplitDefinitions(sql.substr(bodyBegin, bodyEnd - bodyBegin));
	std::string autoColumn;
	for(size_t i = 0; i < sourceDefinitions.size(); ++i)
	{
		if(!std::regex_search(sourceDefinitions[i], std::regex("\\bauto_increment\\b", std::regex::icase)))
			continue;
		SqliteGetColumnName(sourceDefinitions[i], autoColumn);
	}
	std::vector<std::string> targetDefinitions;
	for(size_t i = 0; i < sourceDefinitions.size(); ++i)
	{
		const std::string definition = sourceDefinitions[i];
		if(definition.empty())
			continue;
		if(SqliteMatchesWord(definition, 0, "key") || (SqliteMatchesWord(definition, 0, "unique") && SqliteMatchesWord(definition, SqliteSkipSpaces(definition, 6), "key")))
			continue;
		if(SqliteMatchesWord(definition, 0, "primary"))
		{
			if(autoColumn.empty())
				targetDefinitions.push_back(definition);
			continue;
		}
		if(!autoColumn.empty())
		{
			std::string columnName;
			if(SqliteGetColumnName(definition, columnName) && columnName == autoColumn)
			{
				targetDefinitions.push_back("`" + autoColumn + "` INTEGER PRIMARY KEY AUTOINCREMENT");
				continue;
			}
		}
		targetDefinitions.push_back(SqliteStripMysqlColumnOptions(definition));
	}
	if(targetDefinitions.empty())
		return false;
	rewritten = "CREATE TABLE IF NOT EXISTS " + prefix[1].str() + " (";
	for(size_t i = 0; i < targetDefinitions.size(); ++i)
	{
		if(i > 0)
			rewritten += ",";
		rewritten += targetDefinitions[i];
	}
	rewritten += ")";
	return true;
}

static bool SqliteParseTruncateTable(const std::string &sql, std::string &tableName)
{
	size_t offset = SqliteSkipSpaces(sql, 0);
	if(!SqliteMatchesWord(sql, offset, "truncate"))
		return false;
	offset = SqliteSkipSpaces(sql, offset + 8);
	if(SqliteMatchesWord(sql, offset, "table"))
		offset = SqliteSkipSpaces(sql, offset + 5);
	if(offset >= sql.size())
		return false;
	const char quote = sql[offset] == '`' || sql[offset] == '"' ? sql[offset++] : '\0';
	const size_t begin = offset;
	while(offset < sql.size())
	{
		if(quote != '\0')
		{
			if(sql[offset] == quote)
				break;
		}
		else if(!SqliteIsWordCharacter(sql[offset]))
			break;
		++offset;
	}
	if(offset == begin || (quote != '\0' && (offset >= sql.size() || sql[offset] != quote)))
		return false;
	tableName.assign(sql, begin, offset - begin);
	if(quote != '\0')
		++offset;
	offset = SqliteSkipSpaces(sql, offset);
	if(offset < sql.size() && sql[offset] == ';')
		offset = SqliteSkipSpaces(sql, offset + 1);
	return offset == sql.size();
}

static std::string SqliteRewriteDialect(const char *sqlSentence)
{
	const std::string sql = sqlSentence ? sqlSentence : "";
	std::string showRewrite;
	if(SqliteRewriteShow(sql, showRewrite))
		return showRewrite;
	std::string output;
	output.reserve(sql.size() + 16);
	char quote = '\0';
	for(size_t i = 0; i < sql.size();)
	{
		const char current = sql[i];
		if(quote != '\0')
		{
			output.push_back(current);
			if(current == quote)
			{
				if(i + 1 < sql.size() && sql[i + 1] == quote)
					output.push_back(sql[++i]);
				else
					quote = '\0';
			}
			else if(current == '\\' && i + 1 < sql.size())
				output.push_back(sql[++i]);
			++i;
			continue;
		}
		if(current == '\'' || current == '"' || current == '`')
		{
			quote = current;
			output.push_back(current);
			++i;
			continue;
		}
		if(current == '&' && i + 1 < sql.size() && sql[i + 1] == '&')
		{
			output += " AND ";
			i += 2;
			continue;
		}
		if(SqliteMatchesWord(sql, i, "div"))
		{
			output.push_back('/');
			i += 3;
			continue;
		}
		if(SqliteMatchesWord(sql, i, "on"))
		{
			const size_t duplicate = SqliteSkipSpaces(sql, i + 2);
			const size_t key = SqliteSkipSpaces(sql, duplicate + 9);
			const size_t update = SqliteSkipSpaces(sql, key + 3);
			if(SqliteMatchesWord(sql, duplicate, "duplicate") && SqliteMatchesWord(sql, key, "key") && SqliteMatchesWord(sql, update, "update"))
			{
				output += "ON CONFLICT DO UPDATE SET";
				i = update + 6;
				continue;
			}
		}
		if(SqliteMatchesWord(sql, i, "from"))
		{
			const size_t dual = SqliteSkipSpaces(sql, i + 4);
			if(SqliteMatchesWord(sql, dual, "dual"))
			{
				i = dual + 4;
				continue;
			}
		}
		if(SqliteMatchesWord(sql, i, "where") || SqliteMatchesWord(sql, i, "and"))
		{
			const size_t wordLength = SqliteMatchesWord(sql, i, "where") ? 5 : 3;
			const size_t binary = SqliteSkipSpaces(sql, i + wordLength);
			if(SqliteMatchesWord(sql, binary, "binary"))
			{
				output.append(sql, i, wordLength);
				output.push_back(' ');
				i = SqliteSkipSpaces(sql, binary + 6);
				continue;
			}
		}
		output.push_back(current);
		++i;
	}

	const size_t insert = SqliteSkipSpaces(output, 0);
	if(SqliteMatchesWord(output, insert, "insert"))
	{
		const size_t next = SqliteSkipSpaces(output, insert + 6);
		if(!SqliteMatchesWord(output, next, "into") && !SqliteMatchesWord(output, next, "or"))
			output.insert(next, "INTO ");
	}
	static const std::regex parenthesizedInsertSelect("^\\s*insert\\s+into\\s+([`\"]?[A-Za-z_][A-Za-z0-9_]*[`\"]?)\\s*\\(\\s*(select[\\s\\S]*)\\)\\s*;?\\s*$", std::regex::icase);
	std::smatch insertSelectMatch;
	if(std::regex_match(output, insertSelectMatch, parenthesizedInsertSelect))
		output = "INSERT INTO " + insertSelectMatch[1].str() + " " + insertSelectMatch[2].str();
	return output;
}

static bool SqliteLocalTime(time_t value, struct tm &result)
{
#if defined(_WIN32)
	return localtime_s(&result, &value) == 0;
#else
	return localtime_r(&value, &result) != NULL;
#endif
}

static bool SqliteParseTimestamp(sqlite3_value *value, sqlite3_int64 &result)
{
	const int type = sqlite3_value_type(value);
	if(type == SQLITE_INTEGER || type == SQLITE_FLOAT)
	{
		result = sqlite3_value_int64(value);
		return true;
	}
	const unsigned char *raw = sqlite3_value_text(value);
	if(raw == NULL)
		return false;
	const char *text = reinterpret_cast<const char*>(raw);
	char *end = NULL;
	const long long numeric = std::strtoll(text, &end, 10);
	if(end != text && end != NULL && *end == '\0')
	{
		result = (sqlite3_int64)numeric;
		return true;
	}
	int year = 0, month = 0, day = 0, hour = 0, minute = 0, second = 0;
	const int fields = std::sscanf(text, "%d-%d-%d %d:%d:%d", &year, &month, &day, &hour, &minute, &second);
	if(fields < 3)
		return false;
	struct tm parsed = {};
	parsed.tm_year = year - 1900;
	parsed.tm_mon = month - 1;
	parsed.tm_mday = day;
	parsed.tm_hour = fields >= 4 ? hour : 0;
	parsed.tm_min = fields >= 5 ? minute : 0;
	parsed.tm_sec = fields >= 6 ? second : 0;
	parsed.tm_isdst = -1;
	const time_t timestamp = std::mktime(&parsed);
	if(timestamp == (time_t)-1)
		return false;
	result = (sqlite3_int64)timestamp;
	return true;
}

static void SqliteUnixTimestamp(sqlite3_context *context, int argc, sqlite3_value **argv)
{
	if(argc == 0)
	{
		sqlite3_result_int64(context, (sqlite3_int64)std::time(NULL));
		return;
	}
	if(argc != 1 || sqlite3_value_type(argv[0]) == SQLITE_NULL)
	{
		sqlite3_result_null(context);
		return;
	}
	sqlite3_int64 timestamp = 0;
	if(!SqliteParseTimestamp(argv[0], timestamp))
		sqlite3_result_null(context);
	else
		sqlite3_result_int64(context, timestamp);
}

static void SqliteFromUnixTime(sqlite3_context *context, int argc, sqlite3_value **argv)
{
	if(argc != 1 || sqlite3_value_type(argv[0]) == SQLITE_NULL)
	{
		sqlite3_result_null(context);
		return;
	}
	const time_t timestamp = (time_t)sqlite3_value_int64(argv[0]);
	struct tm local = {};
	if(!SqliteLocalTime(timestamp, local))
	{
		sqlite3_result_null(context);
		return;
	}
	char formatted[20] = {};
	if(std::strftime(formatted, sizeof(formatted), "%Y-%m-%d %H:%M:%S", &local) == 0)
		sqlite3_result_null(context);
	else
		sqlite3_result_text(context, formatted, -1, SQLITE_TRANSIENT);
}

static void SqliteNow(sqlite3_context *context, int, sqlite3_value **)
{
	const time_t timestamp = std::time(NULL);
	struct tm local = {};
	if(!SqliteLocalTime(timestamp, local))
	{
		sqlite3_result_null(context);
		return;
	}
	char formatted[20] = {};
	std::strftime(formatted, sizeof(formatted), "%Y-%m-%d %H:%M:%S", &local);
	sqlite3_result_text(context, formatted, -1, SQLITE_TRANSIENT);
}

static void SqliteConcat(sqlite3_context *context, int argc, sqlite3_value **argv)
{
	std::string result;
	for(int i = 0; i < argc; ++i)
	{
		if(sqlite3_value_type(argv[i]) == SQLITE_NULL)
		{
			sqlite3_result_null(context);
			return;
		}
		const unsigned char *text = sqlite3_value_text(argv[i]);
		if(text != NULL)
			result += reinterpret_cast<const char*>(text);
	}
	sqlite3_result_text(context, result.c_str(), (int)result.size(), SQLITE_TRANSIENT);
}

static void SqliteIf(sqlite3_context *context, int argc, sqlite3_value **argv)
{
	if(argc != 3)
	{
		sqlite3_result_error(context, "if() expects three arguments", -1);
		return;
	}
	const bool condition = sqlite3_value_type(argv[0]) != SQLITE_NULL && sqlite3_value_double(argv[0]) != 0.0;
	sqlite3_result_value(context, condition ? argv[1] : argv[2]);
}

static void SqliteGreatest(sqlite3_context *context, int argc, sqlite3_value **argv)
{
	if(argc < 1)
	{
		sqlite3_result_null(context);
		return;
	}
	bool allInteger = true;
	double greatest = 0.0;
	sqlite3_int64 greatestInteger = 0;
	for(int i = 0; i < argc; ++i)
	{
		if(sqlite3_value_type(argv[i]) == SQLITE_NULL)
		{
			sqlite3_result_null(context);
			return;
		}
		const double current = sqlite3_value_double(argv[i]);
		if(i == 0 || current > greatest)
		{
			greatest = current;
			greatestInteger = sqlite3_value_int64(argv[i]);
		}
		if(sqlite3_value_type(argv[i]) != SQLITE_INTEGER)
			allInteger = false;
	}
	if(allInteger)
		sqlite3_result_int64(context, greatestInteger);
	else
		sqlite3_result_double(context, greatest);
}

static int SqliteRegisterCompatibility(sqlite3 *database)
{
	int rc = sqlite3_create_function_v2(database, "unix_timestamp", -1, SQLITE_UTF8, NULL, SqliteUnixTimestamp, NULL, NULL, NULL);
	if(rc == SQLITE_OK)
		rc = sqlite3_create_function_v2(database, "from_unixtime", 1, SQLITE_UTF8, NULL, SqliteFromUnixTime, NULL, NULL, NULL);
	if(rc == SQLITE_OK)
		rc = sqlite3_create_function_v2(database, "now", 0, SQLITE_UTF8, NULL, SqliteNow, NULL, NULL, NULL);
	if(rc == SQLITE_OK)
		rc = sqlite3_create_function_v2(database, "concat", -1, SQLITE_UTF8 | SQLITE_DETERMINISTIC, NULL, SqliteConcat, NULL, NULL, NULL);
	if(rc == SQLITE_OK)
		rc = sqlite3_create_function_v2(database, "if", 3, SQLITE_UTF8 | SQLITE_DETERMINISTIC, NULL, SqliteIf, NULL, NULL, NULL);
	if(rc == SQLITE_OK)
		rc = sqlite3_create_function_v2(database, "greatest", -1, SQLITE_UTF8 | SQLITE_DETERMINISTIC, NULL, SqliteGreatest, NULL, NULL, NULL);
	return rc;
}
#endif

struct CSqliteCell
{
	bool isNull;
	std::string value;
};

struct CSqliteState
{
#if defined(GYU_ENABLE_SQLITE)
	sqlite3 *db;
#else
	void *db;
#endif
	std::vector<std::vector<CSqliteCell> > rows;
	std::vector<char*> rowPointers;
	size_t nextRow;
	unsigned int insertId;
	std::string error;

	CSqliteState():db(NULL), nextRow(0), insertId(0) {}
};

CDbPoolData *CDbPool::m_pData = NULL;

CDatabaseSql::CDatabaseSql()
	:m_result(NULL), m_mysql(NULL), m_sqlite(NULL), m_isSqlite(false), dbPort(0)
{
}

CDatabaseSql::~CDatabaseSql()
{
	if(m_result != NULL)
		mysql_free_result(m_result);
	if(m_mysql != NULL)
		mysql_close(m_mysql);
#if defined(GYU_ENABLE_SQLITE)
	if(m_sqlite != NULL && m_sqlite->db != NULL)
		sqlite3_close(m_sqlite->db);
#endif
	delete m_sqlite;
}

bool CDatabaseSql::Connect(const char *user,const char *passwd,const char *host,const char *database,int port, const char *pCharacter)
{
	m_isSqlite = false;
	if(m_sqlite != NULL)
	{
#if defined(GYU_ENABLE_SQLITE)
		if(m_sqlite->db != NULL)
			sqlite3_close(m_sqlite->db);
#endif
		delete m_sqlite;
		m_sqlite = NULL;
	}
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

bool CDatabaseSql::ConnectSqlite(const char *databasePath)
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
	if(m_sqlite != NULL)
	{
#if defined(GYU_ENABLE_SQLITE)
		if(m_sqlite->db != NULL)
			sqlite3_close(m_sqlite->db);
#endif
		delete m_sqlite;
	}
	m_sqlite = new CSqliteState;
	m_isSqlite = true;
	dbName = databasePath ? databasePath : "";
#if defined(GYU_ENABLE_SQLITE)
	if(databasePath == NULL || databasePath[0] == '\0')
	{
		m_sqlite->error = "sqlite database path is empty";
		return false;
	}
	const int flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX;
	int rc = sqlite3_open_v2(databasePath, &m_sqlite->db, flags, NULL);
	if(rc != SQLITE_OK)
	{
		m_sqlite->error = m_sqlite->db != NULL ? sqlite3_errmsg(m_sqlite->db) : "sqlite open failed";
		return false;
	}
	sqlite3_busy_timeout(m_sqlite->db, 5000);
	rc = SqliteRegisterCompatibility(m_sqlite->db);
	if(rc != SQLITE_OK)
	{
		m_sqlite->error = sqlite3_errmsg(m_sqlite->db);
		return false;
	}
	char *error = NULL;
	rc = sqlite3_exec(m_sqlite->db, "PRAGMA journal_mode=WAL; PRAGMA synchronous=NORMAL; PRAGMA foreign_keys=ON;", NULL, NULL, &error);
	if(rc != SQLITE_OK)
	{
		m_sqlite->error = error ? error : sqlite3_errmsg(m_sqlite->db);
		if(error != NULL)
			sqlite3_free(error);
		return false;
	}
	return true;
#else
	m_sqlite->error = "sqlite support is not compiled into kapai";
	return false;
#endif
}

bool CDatabaseSql::Query(const char *sqlSentence)
{
	if(m_isSqlite)
	{
		if(m_sqlite == NULL || m_sqlite->db == NULL || sqlSentence == NULL)
		{
			if(m_sqlite != NULL)
				m_sqlite->error = "sqlite is not connected or sql is null";
			return false;
		}
#if defined(GYU_ENABLE_SQLITE)
		m_sqlite->rows.clear();
		m_sqlite->rowPointers.clear();
		m_sqlite->nextRow = 0;
		m_sqlite->error.clear();
		std::string truncateTable;
		if(SqliteParseTruncateTable(sqlSentence, truncateTable))
		{
			const std::string script = "BEGIN IMMEDIATE; DELETE FROM `" + truncateTable + "`; DELETE FROM sqlite_sequence WHERE name='" + truncateTable + "'; COMMIT;";
			char *truncateError = NULL;
			const int truncateRc = sqlite3_exec(m_sqlite->db, script.c_str(), NULL, NULL, &truncateError);
			if(truncateRc != SQLITE_OK)
			{
				m_sqlite->error = truncateError ? truncateError : sqlite3_errmsg(m_sqlite->db);
				if(truncateError != NULL)
					sqlite3_free(truncateError);
				sqlite3_exec(m_sqlite->db, "ROLLBACK;", NULL, NULL, NULL);
				std::cout << "CDatabaseSql::Query SQLite TRUNCATE failed sql=" << sqlSentence << " error=" << m_sqlite->error << std::endl;
				return false;
			}
			m_sqlite->insertId = 0;
			return true;
		}
		std::string sqliteSql;
		if(!SqliteRewriteCreateTable(sqlSentence, sqliteSql))
			sqliteSql = SqliteRewriteDialect(sqlSentence);
		sqlite3_stmt *statement = NULL;
		const char *tail = NULL;
		int rc = sqlite3_prepare_v2(m_sqlite->db, sqliteSql.c_str(), -1, &statement, &tail);
		if(rc != SQLITE_OK)
		{
			m_sqlite->error = sqlite3_errmsg(m_sqlite->db);
			std::cout << "CDatabaseSql::Query SQLite prepare failed sql=" << sqlSentence << " rewritten=" << sqliteSql << " error=" << m_sqlite->error << std::endl;
			return false;
		}
		const std::string tailSql = tail ? tail : "";
		if(statement == NULL || SqliteSkipSpaces(tailSql, 0) != tailSql.size())
		{
			m_sqlite->error = "sqlite Query accepts exactly one statement";
			if(statement != NULL)
				sqlite3_finalize(statement);
			std::cout << "CDatabaseSql::Query SQLite statement-count failed sql=" << sqlSentence << " error=" << m_sqlite->error << std::endl;
			return false;
		}
		const int columnCount = sqlite3_column_count(statement);
		while((rc = sqlite3_step(statement)) == SQLITE_ROW)
		{
			std::vector<CSqliteCell> row;
			row.reserve((size_t)columnCount);
			for(int i = 0; i < columnCount; ++i)
			{
				CSqliteCell cell;
				cell.isNull = sqlite3_column_type(statement, i) == SQLITE_NULL;
				if(!cell.isNull)
				{
					const unsigned char *text = sqlite3_column_text(statement, i);
					cell.value = text ? reinterpret_cast<const char*>(text) : "";
				}
				row.push_back(cell);
			}
			m_sqlite->rows.push_back(row);
		}
		if(rc != SQLITE_DONE)
		{
			m_sqlite->error = sqlite3_errmsg(m_sqlite->db);
			sqlite3_finalize(statement);
			std::cout << "CDatabaseSql::Query SQLite step failed sql=" << sqlSentence << " rewritten=" << sqliteSql << " error=" << m_sqlite->error << std::endl;
			return false;
		}
		sqlite3_finalize(statement);
		m_sqlite->insertId = (unsigned int)sqlite3_last_insert_rowid(m_sqlite->db);
		return true;
#else
		m_sqlite->error = "sqlite support is not compiled into kapai";
		return false;
#endif
	}
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

bool CDatabaseSql::ExecuteScript(const char *sqlScript)
{
	if(!m_isSqlite)
		return Query(sqlScript);
	if(m_sqlite == NULL || m_sqlite->db == NULL || sqlScript == NULL)
	{
		if(m_sqlite != NULL)
			m_sqlite->error = "sqlite is not connected or script is null";
		return false;
	}
#if defined(GYU_ENABLE_SQLITE)
	m_sqlite->rows.clear();
	m_sqlite->rowPointers.clear();
	m_sqlite->nextRow = 0;
	m_sqlite->error.clear();
	char *error = NULL;
	const int rc = sqlite3_exec(m_sqlite->db, sqlScript, NULL, NULL, &error);
	if(rc != SQLITE_OK)
	{
		m_sqlite->error = error ? error : sqlite3_errmsg(m_sqlite->db);
		if(error != NULL)
			sqlite3_free(error);
		std::cout << "CDatabaseSql::ExecuteScript SQLite failed error=" << m_sqlite->error << std::endl;
		return false;
	}
	m_sqlite->insertId = (unsigned int)sqlite3_last_insert_rowid(m_sqlite->db);
	return true;
#else
	m_sqlite->error = "sqlite support is not compiled into kapai";
	return false;
#endif
}

char **CDatabaseSql::GetRow()
{
	if(m_isSqlite)
	{
		if(m_sqlite == NULL || m_sqlite->nextRow >= m_sqlite->rows.size())
			return NULL;
		std::vector<CSqliteCell> &row = m_sqlite->rows[m_sqlite->nextRow++];
		m_sqlite->rowPointers.clear();
		m_sqlite->rowPointers.reserve(row.size() + 1);
		for(size_t i = 0; i < row.size(); ++i)
			m_sqlite->rowPointers.push_back(row[i].isNull ? NULL : const_cast<char*>(row[i].value.c_str()));
		m_sqlite->rowPointers.push_back(NULL);
		return m_sqlite->rowPointers.data();
	}
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
	if(m_isSqlite)
		return m_sqlite == NULL ? "sqlite state is unavailable" : m_sqlite->error.c_str();
	if(m_mysql == NULL)
		return "mysql is not connected";
	return mysql_error(m_mysql);
}

int CDatabaseSql::GetRowNum()
{
	if(m_isSqlite)
		return m_sqlite == NULL ? 0 : (int)m_sqlite->rows.size();
	if(m_result == NULL)
		return 0;
	return (int)mysql_num_rows(m_result);
}

unsigned int CDatabaseSql::InsertId()
{
	if(m_isSqlite)
		return m_sqlite == NULL ? 0 : m_sqlite->insertId;
	if(m_mysql == NULL)
		return 0;
	return (unsigned int)mysql_insert_id(m_mysql);
}

bool CDatabaseSql::IsSqlite() const
{
	return m_isSqlite;
}

CDbPoolData::CDbPoolData()
	:m_isMultithread(false), m_pDbPool(NULL), m_useSqlite(false), m_port(0)
{
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
	m_pData->m_useSqlite = false;
	m_pData->m_sqlitePath.clear();
}

void CDbPool::SetSqliteConfigure(std::string databasePath)
{
	if(m_pData == NULL)
		m_pData = new CDbPoolData;
	m_pData->m_useSqlite = true;
	m_pData->m_sqlitePath = databasePath;
}

bool CDbPool::AddDbConnect()
{
	if(m_pData == NULL)
		return false;
	CDatabaseSql *db = new CDatabaseSql;
	bool connected = m_pData->m_useSqlite
		? db->ConnectSqlite(m_pData->m_sqlitePath.c_str())
		: db->Connect(m_pData->m_user.c_str(), m_pData->m_password.c_str(), m_pData->m_host.c_str(),
			m_pData->m_dbName.c_str(), m_pData->m_port, m_pData->m_character.c_str());
	if(!connected)
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
	bool connected = m_useSqlite
		? db->ConnectSqlite(m_sqlitePath.c_str())
		: db->Connect(m_user.c_str(), m_password.c_str(), m_host.c_str(), m_dbName.c_str(), m_port, m_character.c_str());
	if(!connected)
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
