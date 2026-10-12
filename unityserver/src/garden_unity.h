#ifndef PROJECTX_GARDEN_UNITY_H
#define PROJECTX_GARDEN_UNITY_H
#include <string>
class CUser;
// SQLite Steam/Unity service; never touches Cocos/MySQL accounts.
class CUnityGardenService
{
public:
    static void Handle(CUser* user,unsigned char operation,const std::string& payload);
};
#endif
