#pragma once
#include "self_typedef.h"
#include <string>
class CUser;
namespace gyu { namespace db { class CDatabaseSql; } }
class CUnityStoryService {
public:
 static bool Create(uint32 role,gyu::db::CDatabaseSql* db);
 static bool Enabled(CUser* user);
 static void Handle(CUser* user,unsigned char operation,const std::string& payload);
 static void OnEvent(CUser* user,uint16 type,int value,int parameter);
 static bool AllowsChapter(CUser* user,uint32 chapter);
 static int Validate();
private:
 static void Process(CUser* user,uint16 type,int value,int parameter,bool reply);
};
