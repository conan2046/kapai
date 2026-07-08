#ifndef _PROTOCOL_H_
#define _PROTOCOL_H_
#include "self_typedef.h"

// 服务器消息
const int PRO_SERVER_SAVE_PET = 10000;
const int MSG_SERVER_RANK = 10001;
const int MSG_SERVER_TONGTIANTA = 10002;
const int MSG_SERVER_SAVE_USE_ITEM = 10003;
const int MSG_SERVER_SAVE_BUY_ITEM = 10004;
const int MSG_SERVER_SERVER_XINSHI = 10005;
const int MSG_SERVER_ARENA = 10006;
const int MSG_SERVER_HOT = 10007;
const int MSG_SERVER_ROLE_NAME = 10009;
const int MSG_SERVER_SAVE_DATA = 10010;

const int MSG_SERVER_QUERY_SQL = 10020;
const int MSG_SERVER_QUERY_SQL_ALL_DB = 10021;
const int MSG_SERVER_USER_POWER = 10022; // 同步玩家战力

const int MSG_MGR = 0xfffe;
const int MAX_CON_USER = 4096;

#endif

