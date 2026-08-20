#include "gyu/g_database.h"

#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iostream>
#include <sstream>

using gyu::db::CDatabaseSql;

static int Fail(CDatabaseSql &db, const char *message)
{
    std::cerr << message << ": " << db.GetErrMsg() << std::endl;
    return EXIT_FAILURE;
}

static int RunSchemaSmoke(const char *databasePath, const char *schemaPath)
{
    std::ifstream input(schemaPath, std::ios::binary);
    if(!input)
    {
        std::cerr << "schema file could not be opened: " << schemaPath << std::endl;
        return EXIT_FAILURE;
    }
    std::ostringstream buffer;
    buffer << input.rdbuf();
    CDatabaseSql db;
    if(!db.ConnectSqlite(databasePath))
        return Fail(db, "ConnectSqlite failed");
    if(!db.ExecuteScript(buffer.str().c_str()))
        return Fail(db, "first schema execution failed");
    if(!db.ExecuteScript(buffer.str().c_str()))
        return Fail(db, "second schema execution failed");
    if(!db.Query("select count(*) from sqlite_master where type='table' and name not like 'sqlite_%'"))
        return Fail(db, "table count query failed");
    char **row = db.GetRow();
    if(row == NULL || row[0] == NULL || std::strcmp(row[0], "174") != 0)
        return Fail(db, "unexpected schema table count");
    if(!db.Query("select count(*) from sqlite_master where type='index' and sql is not null"))
        return Fail(db, "index count query failed");
    row = db.GetRow();
    if(row == NULL || row[0] == NULL || std::strcmp(row[0], "34") != 0)
        return Fail(db, "unexpected explicit index count");
    if(!db.Query("select version,name,source_sha256 from schema_version order by version"))
        return Fail(db, "schema version query failed");
    row = db.GetRow();
    if(row == NULL || row[0] == NULL || row[1] == NULL || row[2] == NULL || std::strcmp(row[0], "1") != 0 || std::strcmp(row[1], "initial-schema") != 0)
        return Fail(db, "unexpected schema version row");
    if(!db.Query("pragma integrity_check"))
        return Fail(db, "integrity check failed");
    row = db.GetRow();
    if(row == NULL || row[0] == NULL || std::strcmp(row[0], "ok") != 0)
        return Fail(db, "integrity check was not ok");
    std::cout << "database_schema_smoke=passed tables=174 indexes=34 version=1 path=" << databasePath << std::endl;
    return EXIT_SUCCESS;
}

static int RunDialectSmoke(const char *databasePath)
{
    CDatabaseSql db;
    if(!db.ConnectSqlite(databasePath))
        return Fail(db, "dialect ConnectSqlite failed");
    if(!db.Query("create table dialect(id integer primary key autoincrement, name text unique, value integer, created text)"))
        return Fail(db, "dialect table creation failed");
    if(!db.Query("insert dialect(name,value,created) values('alpha',7,now())"))
        return Fail(db, "INSERT without INTO compatibility failed");
    if(!db.Query("insert into dialect(name,value,created) values('alpha',9,now()) on duplicate key update value=9"))
        return Fail(db, "ON DUPLICATE KEY compatibility failed");
    if(!db.Query("select value, concat(name,'-',value), if(value=9,'yes','no'), 7 div 2, 1 && 1, unix_timestamp(from_unixtime(1700000000)), greatest(value,12) from dialect"))
        return Fail(db, "function/operator compatibility query failed");
    char **row = db.GetRow();
    if(row == NULL || row[0] == NULL || row[1] == NULL || row[2] == NULL || row[3] == NULL || row[4] == NULL || row[5] == NULL || row[6] == NULL ||
        std::strcmp(row[0], "9") != 0 || std::strcmp(row[1], "alpha-9") != 0 || std::strcmp(row[2], "yes") != 0 ||
        std::strcmp(row[3], "3") != 0 || std::strcmp(row[4], "1") != 0 || std::strcmp(row[5], "1700000000") != 0 || std::strcmp(row[6], "12") != 0)
        return Fail(db, "unexpected MySQL compatibility result");
    if(!db.Query("show tables like 'dialect'") || db.GetRow() == NULL)
        return Fail(db, "SHOW TABLES compatibility failed");
    if(!db.Query("show columns from `dialect` like 'name'") || db.GetRow() == NULL)
        return Fail(db, "SHOW COLUMNS compatibility failed");
    if(!db.Query("select 1 from dual where not exists (select 1 from dialect where name='missing')") || db.GetRow() == NULL)
        return Fail(db, "FROM DUAL compatibility failed");
    if(!db.Query("select value from dialect where binary name='alpha'") || db.GetRow() == NULL)
        return Fail(db, "BINARY comparison compatibility failed");
    if(!db.Query("update dialect set value=10 where rowid=(select rowid from dialect where name='alpha' limit 1)"))
        return Fail(db, "targeted UPDATE LIMIT replacement failed");
    if(!db.Query("CREATE TABLE IF NOT EXISTS `mysql_runtime` (`id` int(11) NOT NULL AUTO_INCREMENT,`name` varchar(32) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL DEFAULT '',PRIMARY KEY (`id`),KEY `name` (`name`)) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1"))
        return Fail(db, "runtime MySQL CREATE TABLE compatibility failed");
    if(!db.Query("insert into mysql_runtime(name) values('created')") || db.InsertId() != 1)
        return Fail(db, "runtime MySQL CREATE TABLE insert failed");
    if(!db.Query("CREATE TABLE IF NOT EXISTS mysql_runtime_unquoted (id int(11) NOT NULL AUTO_INCREMENT,name varchar(32) COLLATE utf8_bin NOT NULL,PRIMARY KEY (id),KEY name (name)) ENGINE=MyISAM"))
        return Fail(db, "unquoted runtime MySQL CREATE TABLE compatibility failed");
    if(!db.Query("insert into mysql_runtime_unquoted(name) values('created')") || db.InsertId() != 1)
        return Fail(db, "unquoted runtime MySQL CREATE TABLE insert failed");
    if(!db.Query("create table mysql_runtime_copy(id integer primary key, name text)"))
        return Fail(db, "insert-select target creation failed");
    if(!db.Query("insert into mysql_runtime_copy (select id,name from mysql_runtime_unquoted)"))
        return Fail(db, "parenthesized INSERT SELECT compatibility failed");
    if(!db.Query("truncate mysql_runtime_copy"))
        return Fail(db, "TRUNCATE without TABLE compatibility failed");
    if(!db.Query("alter table mysql_runtime_unquoted add column extra int not null default 0"))
        return Fail(db, "runtime ALTER TABLE compatibility failed");
    if(!db.Query("replace into mysql_runtime_unquoted(id,name,extra) values(1,'replaced',3)"))
        return Fail(db, "REPLACE INTO compatibility failed");
    if(!db.Query("select id,name,cast(extra as unsigned) from mysql_runtime_unquoted order by id limit 0,1"))
        return Fail(db, "LIMIT offset,count or CAST AS UNSIGNED compatibility failed");
    row = db.GetRow();
    if(row == NULL || row[0] == NULL || row[1] == NULL || row[2] == NULL || std::strcmp(row[0], "1") != 0 || std::strcmp(row[1], "replaced") != 0 || std::strcmp(row[2], "3") != 0)
        return Fail(db, "unexpected native SQLite compatibility result");
    if(!db.Query("truncate table dialect"))
        return Fail(db, "TRUNCATE TABLE compatibility failed");
    if(!db.Query("insert dialect(name,value,created) values('beta',1,now())") || db.InsertId() != 1)
        return Fail(db, "TRUNCATE did not reset the auto-increment sequence");
    if(db.Query("select * from table_that_does_not_exist"))
        return Fail(db, "invalid SQL was incorrectly accepted");
    if(db.GetErrMsg() == NULL || db.GetErrMsg()[0] == '\0')
        return Fail(db, "invalid SQL did not expose an error");
    std::cout << "database_dialect_smoke=passed functions=6 rewrites=12 native_forms=4 errors=explicit path=" << databasePath << std::endl;
    return EXIT_SUCCESS;
}

int main(int argc, char **argv)
{
    if(argc == 4 && std::strcmp(argv[1], "--schema") == 0)
        return RunSchemaSmoke(argv[2], argv[3]);
    if(argc == 3 && std::strcmp(argv[1], "--dialect") == 0)
        return RunDialectSmoke(argv[2]);
    const char *databasePath = argc > 1 ? argv[1] : ":memory:";
    CDatabaseSql db;
    if(!db.ConnectSqlite(databasePath))
        return Fail(db, "ConnectSqlite failed");
    if(!db.IsSqlite())
        return Fail(db, "SQLite driver flag was not set");
    if(!db.Query("create table smoke(id integer primary key autoincrement, name text not null, optional text)"))
        return Fail(db, "create table failed");
    if(!db.Query("insert into smoke(name, optional) values('alpha', null)"))
        return Fail(db, "insert failed");
    if(db.InsertId() != 1)
        return Fail(db, "unexpected insert id");
    if(!db.Query("select id,name,optional from smoke order by id"))
        return Fail(db, "select failed");
    if(db.GetRowNum() != 1)
        return Fail(db, "unexpected row count");
    char **row = db.GetRow();
    if(row == NULL || row[0] == NULL || row[1] == NULL || std::strcmp(row[0], "1") != 0 || std::strcmp(row[1], "alpha") != 0 || row[2] != NULL)
        return Fail(db, "unexpected row data");
    if(db.GetRow() != NULL)
        return Fail(db, "row cursor did not reach the end");
    if(!db.Query("update smoke set name='beta' where id=1"))
        return Fail(db, "update failed");
    if(!db.Query("select name from smoke where id=1"))
        return Fail(db, "verification select failed");
    row = db.GetRow();
    if(row == NULL || row[0] == NULL || std::strcmp(row[0], "beta") != 0)
        return Fail(db, "update was not persisted");
    std::cout << "database_smoke=passed driver=sqlite path=" << databasePath << std::endl;
    return EXIT_SUCCESS;
}
