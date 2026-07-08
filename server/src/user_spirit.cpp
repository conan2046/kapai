#include "user_spirit.h"
#include "user.h"
#include "script_call.h"
#include "singleton.h"
#include "rapidjson/document.h"
#include "init.h"

uint16 CUserSpirit::SPIRIT_MONEY = 20;
uint16 CUserSpirit::MAX_SPIRIT = 0;
uint16 CUserSpirit::FREE_SPIRIT = 0;
uint16 CUserSpirit::FULL_SPIRIT = 0;
uint16 CUserSpirit::SPIRIT_LINGQU = 50;


CUserSpiritCfg::CUserSpiritCfg()
{

}

CUserSpiritCfg::~CUserSpiritCfg()
{

}

bool CUserSpiritCfg::InitSpiritCfg()
{
	const string file = "stamina.json";
	//                            0      1       2       3
	const char* titleArrs[] = { "id", "time", "value", "cost" };
	const int typeArrs[] = { 0, 2, 2, 2 };  // 0-int 1-string 2-array
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
	{
		cout << "ShopCfgManager::InitSpiritCfg >> LoadJosnValue error " << endl;
		return false;
	}

	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &data = _para[i];
		SpiritCfg cfg;
		cfg.id = data[titleArrs[0]].GetInt();
		const rapidjson::Value &timeArr = data[titleArrs[1]];
		if (timeArr.Size() != 2)
			continue;
		cfg.start = timeArr[0].GetInt();
		cfg.end = timeArr[1].GetInt();

		const rapidjson::Value &addArr = data[titleArrs[2]];
		if (addArr.Size() != 2)
			continue;
		cfg.add = addArr[1].GetInt();

		const rapidjson::Value &costArr = data[titleArrs[3]];
		if (costArr.Size() != 2)
			continue;
		cfg.cost.type = costArr[0].GetInt();
		cfg.cost.num = costArr[1].GetInt();

		m_spritCfgs[cfg.id] = cfg;
	}
	return true;
}


bool CUserSpiritCfg::InHuoDongTime()
{
	uint16 hour = GetHour();
	uint16 min = GetMinute();
	uint32 now = hour * 100 + min;
	for (SpiritCfgMapIt it = m_spritCfgs.begin(); it != m_spritCfgs.end(); ++it)
	{
		SpiritCfg& cfg = it->second;
		if (now >= cfg.start && now < cfg.end)
		{
			return true;
		}
	}
	return false;
}

bool CUserSpiritCfg::AfterHuoDongTime()
{
	uint16 hour = GetHour();
	uint16 min = GetMinute();
	uint32 now = hour * 100 + min;
	bool isIn = false;
	bool isAfter = false;
	for (SpiritCfgMapIt it = m_spritCfgs.begin(); it != m_spritCfgs.end(); ++it)
	{
		SpiritCfg& cfg = it->second;
		if (now >= cfg.start && now < cfg.end)
		{
			isIn = true;
		}
		if (now >= cfg.end)
		{
			isAfter = true;
		}
	}
	return !isIn && isAfter;
}

SpiritCfg* CUserSpiritCfg::GetSpiritCfg(uint8 id)
{
	SpiritCfgMapIt it = m_spritCfgs.find(id);
	if (it != m_spritCfgs.end())
		return &it->second;

	return NULL;
}

CUserSpirit::CUserSpirit()
	: m_spirit(CUserSpirit::FULL_SPIRIT)
{
}

CUserSpirit::~CUserSpirit()
{
}

void CUserSpirit::SaveData(string & str)
{
	int pos = 0;
	uint8 data[1024] = { 0 };

	pos = CopyDataToBuf((char *)data, &m_spirit, sizeof(m_spirit), pos);
	pos = CopyDataToBuf((char *)data, &m_lastSpiritTime, sizeof(m_lastSpiritTime), pos);

	data[pos++] = m_freeGetState.size();
	for (CFreeSpiritStateMapIt it = m_freeGetState.begin(); it != m_freeGetState.end(); ++it)
	{
		data[pos++] = it->first;
		data[pos++] = it->second;
	}

	Compress(data, pos, str);
}

void CUserSpirit::LoadData(const char * str)
{
	if (str == NULL || strlen(str) == 0)
		return;
	uint8 data[1024];
	uint32 len = 1024;
	int pos = 0;
	if (!UnCompress(str, data, len)) return;
	pos = ReadDataFromBuf((char *)data, &m_spirit, sizeof(m_spirit), pos);
	pos = ReadDataFromBuf((char *)data, &m_lastSpiritTime, sizeof(m_lastSpiritTime), pos);
	uint8 size = data[pos++];
	for (size_t i = 0; i < size; i++)
	{
		uint8 type = data[pos++];
		uint8 state = data[pos++];
		m_freeGetState[type] = state;
	}
	CheckAddSpirit();
}


// 领取状态重置
void CUserSpirit::FreeSpiritReset()
{
	m_freeGetState.clear();
	m_freeGetState[1] = 0;
	m_freeGetState[2] = 0;
	m_freeGetState[3] = 0;
}

// 检测定时增加体力
void CUserSpirit::CheckAddSpirit(CUser* pUser/* = NULL*/)
{
	if (m_spirit >= FULL_SPIRIT)
		return;

	uint32 now = GetSysTime();
	uint32 sec = now - m_lastSpiritTime;
	uint8 add = sec / FREE_SPIRIT;
	if (add == 0)
		return;
	m_spirit += add;
	if (add > 0)
		m_lastSpiritTime += add * FREE_SPIRIT;
	if (m_spirit > FULL_SPIRIT)
	{
		m_spirit = FULL_SPIRIT;
		m_lastSpiritTime = 0;
	}
	if (pUser != NULL)
	{
		CNetMessage msg;
		msg.SetType(MSG_SPIRIT);
		msg << (uint8)1 << PRO_SUCCESS << m_spirit << m_lastSpiritTime;
		SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);
	}
}

// 增加体力
bool CUserSpirit::AddSpirit(CUser* pUser, uint16 spirit, bool isLv/* = false*/)
{
	if (m_spirit + spirit > MAX_SPIRIT && !isLv)
		return false;
	
	m_spirit += spirit;
	uint32 now = GetSysTime();
	if (m_spirit < FULL_SPIRIT)
		m_lastSpiritTime = GetSysTime();
	CNetMessage msg;
	msg.SetType(MSG_SPIRIT);
	msg << (uint8)1 << PRO_SUCCESS << m_spirit << now - m_lastSpiritTime;
	SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);
	return true;
}

// 扣除体力
bool CUserSpirit::SubSpirit(CUser* pUser, uint16 spirit)
{
	if (m_spirit < spirit)
		return false;
	
	uint32 now = GetSysTime();
	if (m_spirit >= FULL_SPIRIT && m_spirit - spirit < FULL_SPIRIT)
		m_lastSpiritTime = now;
	m_spirit -= spirit;
	CNetMessage msg;
	msg.SetType(MSG_SPIRIT);
	msg << (uint8)1 << PRO_SUCCESS << m_spirit << now - m_lastSpiritTime;
	SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);
	return true;
}

// 领取免费体力
void CUserSpirit::GetFreeSpirit(CUser* pUser, CNetMessage &msg)
{
	uint8 idx = 0;
	uint8 type = 0;
	msg >> idx >> type;
	if (CUserSpirit::SPIRIT_LINGQU + m_spirit > CUserSpirit::MAX_SPIRIT)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0158,TIPS_FAILURE_COLOR);
		return;
	}
	uint8 state = GetFreeSpiritState(idx);
	switch (state)
	{
	case 0:// 没有体力可以领取
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0160,TIPS_FAILURE_COLOR);
		break;
	case 1:
	{
		CUserSpiritCfg& mgr = sCUserSpiritCfg;
		SpiritCfg* cfg = mgr.GetSpiritCfg(idx);
		if (cfg == NULL)
			return;
		AddSpirit(pUser, cfg->add);
		msg << PRO_SUCCESS << m_spirit;
		m_freeGetState[idx] = 3;
		break;
	}
	case 2:// 元宝领取
		if (type == 0)
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0159,TIPS_FAILURE_COLOR);
		}
		else
		{
			CUserSpiritCfg& mgr = sCUserSpiritCfg;
			SpiritCfg* cfg = mgr.GetSpiritCfg(idx);
			if (cfg == NULL)
				return;
			if (!pUser->SubMaterial(cfg->cost.type, cfg->cost.num))
			{
				msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0162,TIPS_FAILURE_COLOR);
				return;
			}
			AddSpirit(pUser, cfg->add);
			msg << PRO_SUCCESS << m_spirit;
			m_freeGetState[idx] = 3;
		}
		break;
	case 3:// 已经领取
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0161, TIPS_FAILURE_COLOR);
		break;
	}
	SendTiLiHotPointStatus(pUser);
}

// 能否领取判断
bool CUserSpirit::CheckGetFreeSpiritState()
{
	uint16 hour = GetHour();
	uint16 min = GetMinute();
	uint32 now = hour * 100 + min;
	CUserSpiritCfg& mgr = sCUserSpiritCfg;
	bool canGet = false;
	for (CFreeSpiritStateMapIt it = m_freeGetState.begin(); it != m_freeGetState.end(); ++it)
	{
		bool onGetTime = false;
		uint8 state = 0;
		SpiritCfg* cfg = mgr.GetSpiritCfg(it->first);
		if (cfg == NULL)
			continue;

		if (now >= cfg->start && now < cfg->end)
		{
			onGetTime = true;
			state = 1;
		}
		else if (now >= cfg->end)
		{
			onGetTime = true;
			state = 2;
		}
		if (onGetTime && it->second != 3)
		{
			canGet = true;
			it->second = state;
		}
	}
	return canGet;
}

void CUserSpirit::SendTiLiHotPointStatus(CUser* pUser)
{
	SendHotPointStatus(pUser, EHPoint_TiLi, CheckGetFreeSpiritState());
}

// 体力领取状态 0 不可领取 1 可领取 2 元宝领取 3已经领取
int CUserSpirit::GetFreeSpiritState(uint8 idx)
{
	if (!CheckGetFreeSpiritState())
		return 0;
	
	return m_freeGetState[idx];
}

// 体力信息获取
void CUserSpirit::MakeSpiritMsg(CNetMessage &msg)
{
	msg << PRO_SUCCESS << m_spirit << m_lastSpiritTime;
}

// 体力领取信息获取
void CUserSpirit::MakeFreeSpiritMsg(CNetMessage &msg)
{
	CheckGetFreeSpiritState();
	if (m_freeGetState.empty())
		FreeSpiritReset();
	msg << PRO_SUCCESS << (uint8)m_freeGetState.size();
	for (CFreeSpiritStateMapIt it = m_freeGetState.begin(); it != m_freeGetState.end(); ++it)
	{
		msg << it->first << it->second;
	}
}

uint8 CUserSpirit::GetSpiritCnt()
{
	if (m_freeGetState.empty())
		return 3;
	uint8 cnt = 0;
	for (CFreeSpiritStateMapIt it = m_freeGetState.begin(); it != m_freeGetState.end(); ++it)
	{
		if (it->second == 0)
			cnt++;
	}
	return cnt;
}


