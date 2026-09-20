#include "fish_single_player.h"
#include "user.h"
#include "singleton.h"
#include "init.h"
#include "script_call.h"
#include <sstream>
#include <vector>

namespace
{
	const uint8 FISH_OP_JOIN = 2;
	const uint8 FISH_OP_LIST = 4;
	const uint8 FISH_OP_START = 5;
	const uint8 FISH_OP_COLLECT = 6;
	const uint8 FISH_OP_TIME = 8;
	const uint8 FISH_OP_EXIT = 9;
	const uint8 FISH_OP_STOP = 10;
	const uint8 FISH_OP_SUCCESS = 11;

	struct FishSettings
	{
		FishSettings():valid(false),goldCost(0),minSeconds(0),maxSeconds(0),capacity(0),stackLimit(0),autoContinue(false),
			sceneId(0),mapId(0),x(0),y(0),direction(2),flip(false),shapeId(0){}
		bool valid;
		uint32 goldCost;
		uint16 minSeconds;
		uint16 maxSeconds;
		uint16 capacity;
		uint16 stackLimit;
		bool autoContinue;
		int sceneId;
		int mapId;
		int x;
		int y;
		uint8 direction;
		bool flip;
		int shapeId;
	};

	struct BasketSlot
	{
		uint16 slotIndex;
		uint16 itemId;
		uint16 quantity;
	};

	struct CatchResult
	{
		CatchResult():itemId(0),slotIndex(0xffff),quantity(0),discarded(false){}
		uint16 itemId;
		uint16 slotIndex;
		uint16 quantity;
		bool discarded;
	};

	void SendError(CUser* pUser, uint8 op, const char* reason)
	{
		if(pUser == NULL) return;
		CNetMessage response;
		response.SetType(MSG_FISH);
		response << op << PRO_ERROR << (reason == NULL ? "钓鱼操作失败" : reason);
		SingletonSocket::instance().SendMsg(pUser->GetSock(), response);
	}

	bool LoadSettings(FishSettings& settings)
	{
		CGetDbConnect getDb;
		CDatabaseSql* pDb = getDb.GetDbConnect();
		if(pDb == NULL || !pDb->IsSqlite()) return false;
		if(!pDb->Query("select gold_cost,cycle_min_seconds,cycle_max_seconds,basket_capacity,fish_stack_limit,auto_continue from fish_settings where id=1")) return false;
		char** row = pDb->GetRow();
		if(row == NULL || row[0] == NULL || row[1] == NULL || row[2] == NULL || row[3] == NULL || row[4] == NULL || row[5] == NULL) return false;
		const int goldCost = atoi(row[0]);
		const int minSeconds = atoi(row[1]);
		const int maxSeconds = atoi(row[2]);
		const int capacity = atoi(row[3]);
		const int stackLimit = atoi(row[4]);
		const int autoContinue = atoi(row[5]);
		if(goldCost < 1 || minSeconds < 1 || maxSeconds < minSeconds || maxSeconds > 65535
			|| capacity < 1 || capacity > 9999 || stackLimit < 1 || stackLimit > 999) return false;
		if(!pDb->Query("select scene_id,map_id,x,y,dir,flip,fishing_shape_id from fish_position where id=1")) return false;
		row = pDb->GetRow();
		if(row == NULL || row[0] == NULL || row[1] == NULL || row[2] == NULL || row[3] == NULL
			|| row[4] == NULL || row[5] == NULL || row[6] == NULL) return false;
		settings.goldCost = (uint32)goldCost;
		settings.minSeconds = (uint16)minSeconds;
		settings.maxSeconds = (uint16)maxSeconds;
		settings.capacity = (uint16)capacity;
		settings.stackLimit = (uint16)stackLimit;
		settings.autoContinue = autoContinue != 0;
		settings.sceneId = atoi(row[0]);
		settings.mapId = atoi(row[1]);
		settings.x = atoi(row[2]);
		settings.y = atoi(row[3]);
		settings.direction = (uint8)atoi(row[4]);
		settings.flip = atoi(row[5]) != 0;
		settings.shapeId = atoi(row[6]);
		settings.valid = settings.sceneId == 54 && settings.mapId == 33 && settings.shapeId == 2000;
		return settings.valid;
	}

	bool LoadBasket(uint32 roleId, std::vector<BasketSlot>& slots)
	{
		slots.clear();
		CGetDbConnect getDb;
		CDatabaseSql* pDb = getDb.GetDbConnect();
		if(pDb == NULL || !pDb->IsSqlite()) return false;
		std::ostringstream sql;
		sql << "select slot_index,item_id,quantity from fish_basket_slots where role_id=" << roleId << " order by slot_index";
		if(!pDb->Query(sql.str().c_str())) return false;
		char** row = NULL;
		while((row = pDb->GetRow()) != NULL)
		{
			if(row[0] == NULL || row[1] == NULL || row[2] == NULL) return false;
			BasketSlot slot;
			slot.slotIndex = (uint16)atoi(row[0]);
			slot.itemId = (uint16)atoi(row[1]);
			slot.quantity = (uint16)atoi(row[2]);
			slots.push_back(slot);
		}
		return true;
	}

	bool PersistMoney(CUser* pUser, uint32 newMoney)
	{
		CGetDbConnect getDb;
		CDatabaseSql* pDb = getDb.GetDbConnect();
		if(pDb == NULL || !pDb->IsSqlite()) return false;
		std::ostringstream sql;
		sql << "BEGIN IMMEDIATE; UPDATE role_info SET money=" << newMoney << " WHERE id=" << pUser->GetRoleId() << "; COMMIT;";
		return pDb->ExecuteScript(sql.str().c_str());
	}

	bool ChargeCast(CUser* pUser, const FishSettings& settings)
	{
		if(pUser == NULL || pUser->GetMoney() < (int)settings.goldCost) return false;
		const uint32 newMoney = (uint32)(pUser->GetMoney() - settings.goldCost);
		if(!PersistMoney(pUser, newMoney)) return false;
		pUser->AddMoney(-((int)settings.goldCost));
		return true;
	}

	uint16 RollDuration(const FishSettings& settings)
	{
		return (uint16)Random((int)settings.minSeconds, (int)settings.maxSeconds);
	}

	bool RollFish(uint16& fishId)
	{
		struct Reward { uint16 itemId; int weight; };
		std::vector<Reward> rewards;
		int totalWeight = 0;
		CGetDbConnect getDb;
		CDatabaseSql* pDb = getDb.GetDbConnect();
		if(pDb == NULL || !pDb->IsSqlite()
			|| !pDb->Query("select item_id,weight from fish_reward where enabled=1 and weight>0 order by sort,id")) return false;
		char** row = NULL;
		while((row = pDb->GetRow()) != NULL)
		{
			if(row[0] == NULL || row[1] == NULL) return false;
			Reward reward = { (uint16)atoi(row[0]), atoi(row[1]) };
			if(reward.itemId == 0 || reward.weight <= 0) continue;
			rewards.push_back(reward);
			totalWeight += reward.weight;
		}
		if(rewards.empty() || totalWeight <= 0) return false;
		int roll = Random(1, totalWeight);
		for(size_t i = 0; i < rewards.size(); ++i)
		{
			roll -= rewards[i].weight;
			if(roll <= 0)
			{
				fishId = rewards[i].itemId;
				return true;
			}
		}
		return false;
	}

	bool AddCatch(uint32 roleId, uint16 fishId, const FishSettings& settings, CatchResult& result)
	{
		result.itemId = fishId;
		std::vector<BasketSlot> slots;
		if(!LoadBasket(roleId, slots)) return false;
		for(size_t i = 0; i < slots.size(); ++i)
		{
			if(slots[i].itemId != fishId || slots[i].quantity >= settings.stackLimit) continue;
			result.slotIndex = slots[i].slotIndex;
			result.quantity = slots[i].quantity + 1;
			CGetDbConnect getDb;
			CDatabaseSql* pDb = getDb.GetDbConnect();
			if(pDb == NULL || !pDb->IsSqlite()) return false;
			std::ostringstream sql;
			sql << "update fish_basket_slots set quantity=" << result.quantity << " where role_id=" << roleId
				<< " and slot_index=" << result.slotIndex << " and item_id=" << fishId
				<< " and quantity=" << slots[i].quantity;
			return pDb->Query(sql.str().c_str());
		}
		if(slots.size() >= settings.capacity)
		{
			result.discarded = true;
			return true;
		}
		std::vector<bool> occupied(settings.capacity, false);
		for(size_t i = 0; i < slots.size(); ++i)
			if(slots[i].slotIndex < settings.capacity) occupied[slots[i].slotIndex] = true;
		uint16 slotIndex = 0;
		while(slotIndex < settings.capacity && occupied[slotIndex]) ++slotIndex;
		if(slotIndex >= settings.capacity)
		{
			result.discarded = true;
			return true;
		}
		CGetDbConnect getDb;
		CDatabaseSql* pDb = getDb.GetDbConnect();
		if(pDb == NULL || !pDb->IsSqlite()) return false;
		std::ostringstream sql;
		sql << "insert into fish_basket_slots(role_id,slot_index,item_id,quantity) values("
			<< roleId << ',' << slotIndex << ',' << fishId << ",1)";
		if(!pDb->Query(sql.str().c_str())) return false;
		result.slotIndex = slotIndex;
		result.quantity = 1;
		return true;
	}
}

CFishSinglePlayerService& CFishSinglePlayerService::Instance()
{
	static CFishSinglePlayerService instance;
	return instance;
}

bool CFishSinglePlayerService::IsEnabled()
{
	CGetDbConnect getDb;
	CDatabaseSql* pDb = getDb.GetDbConnect();
	return pDb != NULL && pDb->IsSqlite();
}

void CFishSinglePlayerService::Join(CUser* pUser)
{
	if(pUser == NULL) return;
	FishSettings settings;
	if(!LoadSettings(settings)) { SendError(pUser, FISH_OP_JOIN, "钓鱼配置缺失"); return; }
	const uint32 openLevel = sSystemOpenCfgMananger.GetFuncOpenLevel(32);
	if(openLevel != 0xffff && pUser->GetLevel() < openLevel) { SendError(pUser, FISH_OP_JOIN, "10级开启钓鱼"); return; }
	uint16 remaining = 0;
	{
		boost::mutex::scoped_lock lock(m_mutex);
		Session& session = m_sessions[pUser->GetRoleId()];
		session.joined = true;
		if(session.fishing && session.finishAt > GetSysTime()) remaining = (uint16)(session.finishAt - GetSysTime());
	}
	CNetMessage response;
	response.SetType(MSG_FISH);
	response << FISH_OP_JOIN << PRO_SUCCESS << settings.sceneId << settings.mapId
		<< settings.x << settings.y << settings.direction << (uint8)(settings.flip ? 1 : 0)
		<< settings.shapeId << (uint32)pUser->GetMoney() << settings.goldCost
		<< settings.minSeconds << settings.maxSeconds << settings.capacity << settings.stackLimit
		<< (uint8)(remaining > 0 ? 1 : 0) << remaining;
	SingletonSocket::instance().SendMsg(pUser->GetSock(), response);
}

void CFishSinglePlayerService::SendBasket(CUser* pUser)
{
	if(pUser == NULL) return;
	std::vector<BasketSlot> slots;
	if(!LoadBasket(pUser->GetRoleId(), slots) || slots.size() > 9999) { SendError(pUser, FISH_OP_LIST, "鱼篓读取失败"); return; }
	CNetMessage response;
	response.SetType(MSG_FISH);
	response << FISH_OP_LIST << PRO_SUCCESS << (uint16)slots.size();
	for(size_t i = 0; i < slots.size(); ++i) response << slots[i].slotIndex << slots[i].itemId << slots[i].quantity;
	SingletonSocket::instance().SendMsg(pUser->GetSock(), response);
}

void CFishSinglePlayerService::Start(CUser* pUser, uint8 face)
{
	if(pUser == NULL) return;
	FishSettings settings;
	if(!LoadSettings(settings)) { SendError(pUser, FISH_OP_START, "钓鱼配置缺失"); return; }
	boost::mutex::scoped_lock lock(m_mutex);
	Session& session = m_sessions[pUser->GetRoleId()];
	if(!session.joined) { SendError(pUser, FISH_OP_START, "请先进入钓鱼点"); return; }
	if(session.fishing) { SendError(pUser, FISH_OP_START, "正在垂钓中"); return; }
	if(!ChargeCast(pUser, settings)) { SendError(pUser, FISH_OP_START, "金币不足"); return; }
	session.face = face == 0 ? settings.direction : face;
	session.duration = RollDuration(settings);
	session.finishAt = GetSysTime() + session.duration;
	session.fishing = true;
	CNetMessage response;
	response.SetType(MSG_FISH);
	response << FISH_OP_START << PRO_SUCCESS << session.duration << session.face << (uint32)pUser->GetMoney();
	SingletonSocket::instance().SendMsg(pUser->GetSock(), response);
}

void CFishSinglePlayerService::Collect(CUser* pUser, uint16 slotIndex)
{
	if(pUser == NULL) return;
	CGetDbConnect getDb;
	CDatabaseSql* pDb = getDb.GetDbConnect();
	if(pDb == NULL || !pDb->IsSqlite()) { SendError(pUser, FISH_OP_COLLECT, "鱼篓读取失败"); return; }
	std::ostringstream query;
	query << "select item_id,quantity from fish_basket_slots where role_id=" << pUser->GetRoleId() << " and slot_index=" << slotIndex;
	if(!pDb->Query(query.str().c_str())) { SendError(pUser, FISH_OP_COLLECT, "鱼篓读取失败"); return; }
	char** row = pDb->GetRow();
	if(row == NULL || row[0] == NULL || row[1] == NULL) { SendError(pUser, FISH_OP_COLLECT, "该鱼篓格为空"); return; }
	const uint16 itemId = (uint16)atoi(row[0]);
	const uint16 quantity = (uint16)atoi(row[1]);
	if(itemId == 0 || quantity == 0 || !pUser->AddBangDingPackage(itemId, quantity)) { SendError(pUser, FISH_OP_COLLECT, "背包空间不足"); return; }
	std::ostringstream remove;
	remove << "delete from fish_basket_slots where role_id=" << pUser->GetRoleId() << " and slot_index=" << slotIndex;
	if(!pDb->Query(remove.str().c_str())) { SendError(pUser, FISH_OP_COLLECT, "鱼篓保存失败"); return; }
	CNetMessage response;
	response.SetType(MSG_FISH);
	response << FISH_OP_COLLECT << PRO_SUCCESS << slotIndex << itemId << quantity;
	SingletonSocket::instance().SendMsg(pUser->GetSock(), response);
}

void CFishSinglePlayerService::SyncTime(CUser* pUser)
{
	if(pUser == NULL) return;
	uint16 remaining = 0;
	{
		boost::mutex::scoped_lock lock(m_mutex);
		std::map<uint32, Session>::iterator it = m_sessions.find(pUser->GetRoleId());
		if(it != m_sessions.end() && it->second.fishing && it->second.finishAt > GetSysTime()) remaining = (uint16)(it->second.finishAt - GetSysTime());
	}
	CNetMessage response;
	response.SetType(MSG_FISH);
	response << FISH_OP_TIME << PRO_SUCCESS << remaining;
	SingletonSocket::instance().SendMsg(pUser->GetSock(), response);
}

void CFishSinglePlayerService::Stop(CUser* pUser)
{
	if(pUser == NULL) return;
	FishSettings settings;
	if(!LoadSettings(settings)) { SendError(pUser, FISH_OP_STOP, "钓鱼配置缺失"); return; }
	boost::mutex::scoped_lock lock(m_mutex);
	Session& session = m_sessions[pUser->GetRoleId()];
	if(!session.fishing)
	{
		CNetMessage response;
		response.SetType(MSG_FISH);
		response << FISH_OP_STOP << PRO_SUCCESS << (uint32)pUser->GetMoney();
		SingletonSocket::instance().SendMsg(pUser->GetSock(), response);
		return;
	}

	// 收网按点击时刻结算：已过去的时间占本轮时长的比例就是成功率。
	// 到期但尚未被 Tick 处理时，按 100% 处理，避免边界点击损失奖励。
	time_t now = GetSysTime();
	uint32 elapsed = now > session.finishAt - session.duration
		? (uint32)(now - (session.finishAt - session.duration)) : 0;
	uint32 successPercent = session.duration == 0
		? 0 : elapsed * 100 / session.duration;
	if(successPercent > 100) successPercent = 100;

	CatchResult result;
	bool settled = false;
	if(successPercent >= 100 || Random(1, 100) <= (int)successPercent)
	{
		uint16 fishId = 0;
		if(!RollFish(fishId) || !AddCatch(pUser->GetRoleId(), fishId, settings, result))
		{
			session.fishing = false;
			session.duration = 0;
			session.finishAt = 0;
			SendError(pUser, FISH_OP_SUCCESS, "钓鱼结算失败");
			return;
		}
		settled = true;
	}
	if(!settled)
	{
		result.itemId = 0;
		result.slotIndex = 0xffff;
		result.quantity = 0;
		result.discarded = true;
	}
	session.fishing = false;
	session.duration = 0;
	session.finishAt = 0;

	CNetMessage response;
	response.SetType(MSG_FISH);
	response << FISH_OP_SUCCESS << PRO_SUCCESS << result.itemId << result.slotIndex << result.quantity
		<< (uint8)(result.discarded ? 1 : 0) << (uint16)0 << (uint32)pUser->GetMoney();
	SingletonSocket::instance().SendMsg(pUser->GetSock(), response);
}

void CFishSinglePlayerService::Exit(CUser* pUser)
{
	if(pUser == NULL) return;
	{
		boost::mutex::scoped_lock lock(m_mutex);
		m_sessions.erase(pUser->GetRoleId());
	}
	CNetMessage response;
	response.SetType(MSG_FISH);
	response << FISH_OP_EXIT << PRO_SUCCESS;
	SingletonSocket::instance().SendMsg(pUser->GetSock(), response);
}

void CFishSinglePlayerService::Tick(CUser* pUser)
{
	if(pUser == NULL) return;
	FishSettings settings;
	if(!LoadSettings(settings)) return;
	boost::mutex::scoped_lock lock(m_mutex);
	std::map<uint32, Session>::iterator it = m_sessions.find(pUser->GetRoleId());
	if(it == m_sessions.end() || !it->second.joined || !it->second.fishing || it->second.finishAt > GetSysTime()) return;
	uint16 fishId = 0;
	CatchResult result;
	if(!RollFish(fishId) || !AddCatch(pUser->GetRoleId(), fishId, settings, result))
	{
		it->second.fishing = false;
		it->second.duration = 0;
		it->second.finishAt = 0;
		SendError(pUser, FISH_OP_SUCCESS, "钓鱼结算失败");
		return;
	}
	uint16 nextDuration = 0;
	if(settings.autoContinue && ChargeCast(pUser, settings))
	{
		nextDuration = RollDuration(settings);
		it->second.duration = nextDuration;
		it->second.finishAt = GetSysTime() + nextDuration;
	}
	else
	{
		it->second.fishing = false;
		it->second.duration = 0;
		it->second.finishAt = 0;
	}
	CNetMessage response;
	response.SetType(MSG_FISH);
	response << FISH_OP_SUCCESS << PRO_SUCCESS << result.itemId << result.slotIndex << result.quantity
		<< (uint8)(result.discarded ? 1 : 0) << nextDuration << (uint32)pUser->GetMoney();
	SingletonSocket::instance().SendMsg(pUser->GetSock(), response);
}
