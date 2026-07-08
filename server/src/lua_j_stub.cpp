#include "lua.hpp"
#include "user.h"
#include "utility.h"
#include "script_call.h"

static CUser *check_user(lua_State *L, int index)
{
	void **ud = static_cast<void **>(luaL_checkudata(L, index, "CUser *"));
	return ud == 0 ? 0 : static_cast<CUser *>(*ud);
}

static int lua_user_HaveBitSet(lua_State *L)
{
	CUser *user = check_user(L, 1);
	int index = (int)luaL_checkinteger(L, 2);
	lua_pushboolean(L, user != 0 && user->HaveBitSet(index));
	return 1;
}

static int lua_user_SetBitSet(lua_State *L)
{
	CUser *user = check_user(L, 1);
	int index = (int)luaL_checkinteger(L, 2);
	if(user != 0)
		user->SetBitSet(index);
	return 0;
}

static int lua_user_ClearBitSet(lua_State *L)
{
	CUser *user = check_user(L, 1);
	int index = (int)luaL_checkinteger(L, 2);
	if(user != 0)
		user->ClearBitSet(index);
	return 0;
}

static int lua_user_GetLevel(lua_State *L)
{
	CUser *user = check_user(L, 1);
	lua_pushinteger(L, user == 0 ? 0 : user->GetLevel());
	return 1;
}

static int lua_user_GetRoleId(lua_State *L)
{
	CUser *user = check_user(L, 1);
	lua_pushinteger(L, user == 0 ? 0 : user->GetRoleId());
	return 1;
}

static int lua_user_GetName(lua_State *L)
{
	CUser *user = check_user(L, 1);
	lua_pushstring(L, user == 0 ? "" : user->GetName());
	return 1;
}

static int lua_user_GetExtData8(lua_State *L)
{
	CUser *user = check_user(L, 1);
	uint16 pos = (uint16)luaL_checkinteger(L, 2);
	lua_pushinteger(L, user == 0 ? 0 : user->GetExtData8(pos));
	return 1;
}

static int lua_user_SetExtData8(lua_State *L)
{
	CUser *user = check_user(L, 1);
	uint16 pos = (uint16)luaL_checkinteger(L, 2);
	uint8 val = (uint8)luaL_checkinteger(L, 3);
	if(user != 0)
		user->SetExtData8(pos, val);
	return 0;
}

static int lua_user_GetExtData16(lua_State *L)
{
	CUser *user = check_user(L, 1);
	uint16 pos = (uint16)luaL_checkinteger(L, 2);
	lua_pushinteger(L, user == 0 ? 0 : user->GetExtData16(pos));
	return 1;
}

static int lua_user_SetExtData16(lua_State *L)
{
	CUser *user = check_user(L, 1);
	uint16 pos = (uint16)luaL_checkinteger(L, 2);
	uint16 val = (uint16)luaL_checkinteger(L, 3);
	if(user != 0)
		user->SetExtData16(pos, val);
	return 0;
}

static int lua_user_GetExtData32(lua_State *L)
{
	CUser *user = check_user(L, 1);
	uint16 pos = (uint16)luaL_checkinteger(L, 2);
	lua_pushinteger(L, user == 0 ? 0 : user->GetExtData32(pos));
	return 1;
}

static int lua_user_SetExtData32(lua_State *L)
{
	CUser *user = check_user(L, 1);
	uint16 pos = (uint16)luaL_checkinteger(L, 2);
	uint32 val = (uint32)luaL_checkinteger(L, 3);
	if(user != 0)
		user->SetExtData32(pos, val);
	return 0;
}

static int lua_user_GetSaveVal(lua_State *L)
{
	CUser *user = check_user(L, 1);
	uint8 index = (uint8)luaL_checkinteger(L, 2);
	lua_pushinteger(L, user == 0 ? 0 : user->GetSaveVal(index));
	return 1;
}

static int lua_user_SetVal(lua_State *L)
{
	CUser *user = check_user(L, 1);
	int id = (int)luaL_checkinteger(L, 2);
	int val = (int)luaL_checkinteger(L, 3);
	if(user != 0)
		user->SetVal(id, val);
	return 0;
}

static int lua_user_GetVal(lua_State *L)
{
	CUser *user = check_user(L, 1);
	int id = (int)luaL_checkinteger(L, 2);
	lua_pushinteger(L, user == 0 ? 0 : user->GetVal(id));
	return 1;
}

static int lua_user_GetBossMissionStarInfo(lua_State *L)
{
	CUser *user = check_user(L, 1);
	lua_pushstring(L, user == 0 ? "" : user->GetBossMissionStarInfo());
	return 1;
}

static int lua_user_SendMailByLevel(lua_State *L)
{
	CUser *user = check_user(L, 1);
	if(user != 0)
		user->SendMailByLevel();
	return 0;
}

static int lua_j_PlayFightCG(lua_State *L)
{
	CUser *user = check_user(L, 1);
	int id = (int)luaL_checkinteger(L, 2);
	PlayFightCG(user, id);
	return 0;
}

static int lua_j_GetServerType(lua_State *L)
{
	lua_pushstring(L, GetServerType());
	return 1;
}

static int lua_j_GetSecond(lua_State *L) { lua_pushinteger(L, GetSecond()); return 1; }
static int lua_j_GetMinute(lua_State *L) { lua_pushinteger(L, GetMinute()); return 1; }
static int lua_j_GetHour(lua_State *L) { lua_pushinteger(L, GetHour()); return 1; }
static int lua_j_GetYDay(lua_State *L) { lua_pushinteger(L, GetYDay()); return 1; }
static int lua_j_GetWeekDay(lua_State *L) { lua_pushinteger(L, GetWeekDay()); return 1; }
static int lua_j_GetDay(lua_State *L) { lua_pushinteger(L, GetDay()); return 1; }
static int lua_j_GetMonth(lua_State *L) { lua_pushinteger(L, GetMonth()); return 1; }
static int lua_j_GetYear(lua_State *L) { lua_pushinteger(L, GetYear()); return 1; }

static int lua_j_GetYaoQianShuFreeNum(lua_State *L)
{
	CUser *user = check_user(L, 1);
	lua_pushinteger(L, GetYaoQianShuFreeNum(user));
	return 1;
}

static int lua_j_GetJuanxianMax(lua_State *L)
{
	CUser *user = check_user(L, 1);
	lua_pushinteger(L, user == 0 ? 0 : GetJuanxianMax(user));
	return 1;
}

static int lua_j_GetBangPaiRobTime(lua_State *L)
{
	lua_pushstring(L, GetBangPaiRobTime());
	return 1;
}

static int lua_j_GetFengShenDoNum(lua_State *L)
{
	CUser *user = check_user(L, 1);
	lua_pushinteger(L, GetFengShenDoNum(user));
	return 1;
}

static int lua_j_GetFSBossFightNumPerDay(lua_State *L)
{
	CUser *user = check_user(L, 1);
	lua_pushinteger(L, GetFSBossFightNumPerDay(user));
	return 1;
}

static int lua_j_GetFuncOpenLevel(lua_State *L)
{
	int sysId = (int)luaL_checkinteger(L, 1);
	lua_pushinteger(L, GetFuncOpenLevel(sysId));
	return 1;
}

static int lua_j_GetQuestion(lua_State *L)
{
	CUser *user = 0;
	if(lua_gettop(L) >= 1 && !lua_isnil(L, 1))
		user = check_user(L, 1);
	const char *question = GetQuestion(user);
	lua_pushstring(L, question == 0 ? "" : question);
	return 1;
}

static int lua_j_GetDailyBossExp(lua_State *L)
{
	int idx = (int)luaL_checkinteger(L, 1);
	lua_pushinteger(L, GetDailyBossExp(idx));
	return 1;
}

static int lua_j_MakeDailyBossInfo(lua_State *L)
{
	CUser *user = check_user(L, 1);
	int type = (int)luaL_checkinteger(L, 2);
	int sid = (int)luaL_checkinteger(L, 3);
	int x = (int)luaL_checkinteger(L, 4);
	int y = (int)luaL_checkinteger(L, 5);
	const char *info = luaL_checkstring(L, 6);
	lua_pushinteger(L, MakeDailyBossInfo(user, type, sid, x, y, info));
	return 1;
}

static void register_user(lua_State *L)
{
	static const luaL_Reg methods[] = {
		{"HaveBitSet", lua_user_HaveBitSet},
		{"SetBitSet", lua_user_SetBitSet},
		{"ClearBitSet", lua_user_ClearBitSet},
		{"GetLevel", lua_user_GetLevel},
		{"GetRoleId", lua_user_GetRoleId},
		{"GetName", lua_user_GetName},
		{"GetExtData8", lua_user_GetExtData8},
		{"SetExtData8", lua_user_SetExtData8},
		{"GetExtData16", lua_user_GetExtData16},
		{"SetExtData16", lua_user_SetExtData16},
		{"GetExtData32", lua_user_GetExtData32},
		{"SetExtData32", lua_user_SetExtData32},
		{"GetSaveVal", lua_user_GetSaveVal},
		{"SetVal", lua_user_SetVal},
		{"GetVal", lua_user_GetVal},
		{"GetBossMissionStarInfo", lua_user_GetBossMissionStarInfo},
		{"SendMailByLevel", lua_user_SendMailByLevel},
		{0, 0}
	};
	luaL_newmetatable(L, "CUser *");
	lua_pushvalue(L, -1);
	lua_setfield(L, -2, "__index");
	luaL_register(L, 0, methods);
	lua_pop(L, 1);
}

static int lua_bit_and(lua_State *L)
{
	uint32 a = (uint32)luaL_checkinteger(L, 2);
	uint32 b = (uint32)luaL_checkinteger(L, 3);
	lua_pushinteger(L, a & b);
	return 1;
}

static int lua_bit_or(lua_State *L)
{
	uint32 a = (uint32)luaL_checkinteger(L, 2);
	uint32 b = (uint32)luaL_checkinteger(L, 3);
	lua_pushinteger(L, a | b);
	return 1;
}

static int lua_bit_xor(lua_State *L)
{
	uint32 a = (uint32)luaL_checkinteger(L, 2);
	uint32 b = (uint32)luaL_checkinteger(L, 3);
	lua_pushinteger(L, a ^ b);
	return 1;
}

static int lua_bit_rshift(lua_State *L)
{
	uint32 a = (uint32)luaL_checkinteger(L, 2);
	int n = (int)luaL_checkinteger(L, 3);
	lua_pushinteger(L, n >= 32 ? 0 : (a >> n));
	return 1;
}

static int lua_bit_lshift(lua_State *L)
{
	uint32 a = (uint32)luaL_checkinteger(L, 2);
	int n = (int)luaL_checkinteger(L, 3);
	lua_pushinteger(L, n >= 32 ? 0 : (a << n));
	return 1;
}

static void register_legacy_bit(lua_State *L)
{
	static const luaL_Reg methods[] = {
		{"_and", lua_bit_and},
		{"_or", lua_bit_or},
		{"_xor", lua_bit_xor},
		{"_rshift", lua_bit_rshift},
		{"_lshift", lua_bit_lshift},
		{0, 0}
	};
	lua_newtable(L);
	luaL_register(L, 0, methods);
	lua_getglobal(L, "package");
	lua_getfield(L, -1, "loaded");
	lua_pushvalue(L, -3);
	lua_setfield(L, -2, "bit");
	lua_pop(L, 3);
}

extern "C" int luaopen_j(lua_State *L)
{
	register_user(L);
	register_legacy_bit(L);
	lua_newtable(L);
	lua_pushcfunction(L, lua_j_PlayFightCG);
	lua_setfield(L, -2, "PlayFightCG");
	lua_pushcfunction(L, lua_j_GetServerType);
	lua_setfield(L, -2, "GetServerType");
	lua_pushcfunction(L, lua_j_GetSecond);
	lua_setfield(L, -2, "GetSecond");
	lua_pushcfunction(L, lua_j_GetMinute);
	lua_setfield(L, -2, "GetMinute");
	lua_pushcfunction(L, lua_j_GetHour);
	lua_setfield(L, -2, "GetHour");
	lua_pushcfunction(L, lua_j_GetYDay);
	lua_setfield(L, -2, "GetYDay");
	lua_pushcfunction(L, lua_j_GetWeekDay);
	lua_setfield(L, -2, "GetWeekDay");
	lua_pushcfunction(L, lua_j_GetDay);
	lua_setfield(L, -2, "GetDay");
	lua_pushcfunction(L, lua_j_GetMonth);
	lua_setfield(L, -2, "GetMonth");
	lua_pushcfunction(L, lua_j_GetYear);
	lua_setfield(L, -2, "GetYear");
	lua_pushcfunction(L, lua_j_GetYaoQianShuFreeNum);
	lua_setfield(L, -2, "GetYaoQianShuFreeNum");
	lua_pushcfunction(L, lua_j_GetJuanxianMax);
	lua_setfield(L, -2, "GetJuanxianMax");
	lua_pushcfunction(L, lua_j_GetBangPaiRobTime);
	lua_setfield(L, -2, "GetBangPaiRobTime");
	lua_pushcfunction(L, lua_j_GetFengShenDoNum);
	lua_setfield(L, -2, "GetFengShenDoNum");
	lua_pushcfunction(L, lua_j_GetFSBossFightNumPerDay);
	lua_setfield(L, -2, "GetFSBossFightNumPerDay");
	lua_pushcfunction(L, lua_j_GetFuncOpenLevel);
	lua_setfield(L, -2, "GetFuncOpenLevel");
	lua_pushcfunction(L, lua_j_GetQuestion);
	lua_setfield(L, -2, "GetQuestion");
	lua_pushcfunction(L, lua_j_GetDailyBossExp);
	lua_setfield(L, -2, "GetDailyBossExp");
	lua_pushcfunction(L, lua_j_MakeDailyBossInfo);
	lua_setfield(L, -2, "MakeDailyBossInfo");
	lua_pushvalue(L, -1);
	lua_setglobal(L, "j");
	return 1;
}
