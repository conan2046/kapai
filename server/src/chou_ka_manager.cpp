#include "chou_ka_manager.h"
#include "rapidjson/document.h"
#include "init.h"
#include "utility.h"
#include "user.h"
#include "pet.h"
#include "mission_manager.h"

CChouKaCfgManager::CChouKaCfgManager()
{
}


CChouKaCfgManager::~CChouKaCfgManager()
{
}

bool CChouKaCfgManager::InitChouKaCfg()
{
	return InitChouKaBaseCfg()
		&& InitChouKaDropCfg();
}

bool CChouKaCfgManager::InitChouKaBaseCfg()
{
	const string file = "draw_basic.json";
	//                            0     1        2            3        4          5              6
	const char* titleArrs[] = { "id", "name", "open_level", "type", "must_be", "must_get", "need_item_id",
	//       7                  8                   9             10
		"need_item_num", "must_be_out_times", "free_times", "free_interval" };
	const int typeArrs[] = { 0, 1, 0, 0, 0, 2, 0, 0, 0, 0, 0 };  // 0-int 1-string 2-array
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
	{
		cout << "CHeroCfgManager::InitChouKaBaseCfg >> LoadJosnValue error " << endl;
		return false;
	}

	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &data = _para[i];
		uint16 type = data[titleArrs[0]].GetInt();
		ChouKaBase base;
		base.openLevel = data[titleArrs[2]].GetInt();
		base.normalDrop = data[titleArrs[3]].GetInt();
		base.mustDrop = data[titleArrs[4]].GetInt();
		base.costId = data[titleArrs[6]].GetInt();
		base.costNum = data[titleArrs[7]].GetInt();
		base.bemustCnt = data[titleArrs[8]].GetInt();
		base.freeCnt = data[titleArrs[9]].GetInt();
		base.freeCd = data[titleArrs[10]].GetInt();
		ReadMultiAward(data[titleArrs[5]], base.awards);

		m_chouKaBase[type] = base;
	}
	return true;
}

bool CChouKaCfgManager::InitChouKaDropCfg()
{
	const string file = "draw_config.json";
	//                            0     1        2          3
	const char* titleArrs[] = { "id", "type", "award", "quanzhong" };
	const int typeArrs[] = { 0, 0, 2, 0 };  // 0-int 1-string 2-array
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
	{
		cout << "CHeroCfgManager::InitChouKaBaseCfg >> LoadJosnValue error " << endl;
		return false;
	}

	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &data = _para[i];
		uint16 type = data[titleArrs[1]].GetInt();
		SingleChouKaDrop base;
		ReadSingleAward(data[titleArrs[2]], base.award);
		base.weight = data[titleArrs[3]].GetInt();

		ChouKaDrop* drop = GetChouKaDrop(type);
		if (drop != NULL)
		{
			drop->allWeight += base.weight;
			base.weight = drop->allWeight;
			drop->multiDrop.push_back(base);
		}
		else
		{
			ChouKaDrop nDrop;
			nDrop.allWeight = base.weight;
			nDrop.multiDrop.push_back(base);
			m_chouKaDrop[type] = nDrop;
		}
	}
	return true;
}

ChouKaBase* CChouKaCfgManager::GetChouKaBase(uint8 type)
{
	ChouKaBaseMapIt it = m_chouKaBase.find(type);
	if (it == m_chouKaBase.end())
		return NULL;

	return &it->second;
}

ChouKaDrop* CChouKaCfgManager::GetChouKaDrop(uint8 type)
{
	ChouKaDropMapIt it = m_chouKaDrop.find(type);
	if (it == m_chouKaDrop.end())
		return NULL;

	return &it->second;
}

void CChouKaCfgManager::SingleChouKa(uint8 type, SAwardData& heroAward)
{
	ChouKaDrop* drop = GetChouKaDrop(type);
	if (drop == NULL)
		return;

	int rd = Random(0, drop->allWeight);
	for (size_t si = 0; si < drop->multiDrop.size(); ++si)
	{
		if (rd <= (int)drop->multiDrop[si].weight)
		{
			heroAward = drop->multiDrop[si].award;
			return;
		}
	}
}

void CChouKaCfgManager::MultiChouKa(uint8 type, uint8 cnt, MultiAward& heroAward)
{
	ChouKaDrop* drop = GetChouKaDrop(type);
	if (drop == NULL)
		return;

	for (uint8 i = 0; i < cnt; ++i)
	{
		int rd = Random(0, drop->allWeight);
		for (size_t si = 0; si < drop->multiDrop.size(); ++si)
		{
			if (rd < (int)drop->multiDrop[si].weight)
			{
				heroAward.push_back(drop->multiDrop[si].award);
				break;
			}
		}
	}
}

CChouKaManager::CChouKaManager()
{
}

CChouKaManager::~CChouKaManager()
{
}

void CChouKaManager::InitChouKa()
{
	ChouKaJiLu jilu;
	for (uint8 i = 1; i <= 3; ++i)
	{
		ChouKaBase* base = sCChouKaCfgManager.GetChouKaBase(i);
		if (base == NULL)
			continue;
		jilu.freeTimes = base->freeCnt;
		m_chouKa[i] = jilu;
	}
}

void CChouKaManager::ResetChouKa()
{
	for (ChouKaJiLuMapIt it = m_chouKa.begin(); it != m_chouKa.end(); ++it)
	{
		ChouKaBase* base = sCChouKaCfgManager.GetChouKaBase(it->first);
		if (base == NULL)
			continue;

		it->second.freeTimes = base->freeCnt;
	}
}

void CChouKaManager::SaveData(string & str)
{
	int pos = 0;
	uint8 data[1024 * 10] = { 0 };

	// 挑战次数
	data[pos++] = m_chouKa.size();
	for (ChouKaJiLuMapIt bit = m_chouKa.begin(); bit != m_chouKa.end(); ++bit)
	{
		data[pos++] = bit->first;
		ChouKaJiLu& ck = bit->second;
		pos = CopyDataToBuf((char *)data, &ck.allCnt, sizeof(ck.allCnt), pos);
		pos = CopyDataToBuf((char *)data, &ck.freeCd, sizeof(ck.freeCd), pos);
		data[pos++] = ck.freeTimes;
	}
	Compress(data, pos, str);
}

void CChouKaManager::LoadData(const char * str)
{
	if (str == NULL || strlen(str) == 0)
	{
		InitChouKa();
		return;
	}
	uint32 len = 1024 * 10;
	uint8 data[1024 * 10];
	int pos = 0;
	if (!UnCompress(str, data, len))
		return;

	// 挑战次数
	uint8 nSize = data[pos++];
	for (uint8 ni = 0; ni < nSize; ++ni)
	{
		ChouKaJiLu ck;
		uint8 type = data[pos++];
		pos = ReadDataFromBuf((char *)data, &ck.allCnt, sizeof(ck.allCnt), pos);
		pos = ReadDataFromBuf((char *)data, &ck.freeCd, sizeof(ck.freeCd), pos);
		ck.freeTimes = data[pos++];
		m_chouKa[type] = ck;
	}
}


ChouKaJiLu* CChouKaManager::GetChouKaJiLu(uint8 type)
{
	ChouKaJiLuMapIt bit = m_chouKa.find(type);
	if (bit == m_chouKa.end())
		return NULL;

	return &bit->second;
}

bool CChouKaManager::GetChouKaMsg(CNetMessage & msg)
{
	msg << (uint8)m_chouKa.size();
	uint32 curTime = GetSysTime();
	for (ChouKaJiLuMapIt bit = m_chouKa.begin(); bit != m_chouKa.end(); ++bit)
	{
		ChouKaJiLu& jilu = bit->second;
		msg << (uint8)bit->first << jilu.allCnt;
		if (jilu.freeCd > curTime)
			msg << (uint32)(jilu.freeCd - curTime);
		else
			msg << (uint32)0;

		msg << jilu.freeTimes;
	}
	return true;
}

bool CChouKaManager::ChouKa(CUser * user, CNetMessage & msg)
{
	uint8 type;
	uint8 sType;
	msg >> type >> sType;

	if (type == 3)
	{
		if (!sSystemOpenCfgMananger.CheckSystemOpen(user, SOT_1011))
			return false;
	}
	else
	{
		if (!sSystemOpenCfgMananger.CheckSystemOpen(user, SOT_1010))
			return false;
	}
	ChouKaJiLu* jilu = GetChouKaJiLu(type);
	if (jilu == NULL)
		return false;
	CChouKaCfgManager& ckMgr = sCChouKaCfgManager;
	ChouKaBase* base = ckMgr.GetChouKaBase(type);
	if (base == NULL)
		return false;

	uint32 curTime = GetSysTime();
	SAwardData singleAward;
	switch (sType)
	{
	case 1: // 单抽
		if (jilu->freeTimes != 0 && jilu->freeCd <= curTime)
		{
			jilu->freeCd = curTime + base->freeCd;
			jilu->freeTimes--;
		}
		else
		{
			if (user->GetMaterial(base->costId) < base->costNum)
			{
				char buf[128];
				snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0182, GetItemName(base->costId));
				msg << PRO_ERROR << MakeStringColor(buf, TIPS_FAILURE_COLOR);
				return true;
			}
			user->DelPackageById(base->costId, base->costNum);
		}
		if (jilu->allCnt == 0 && type == 2)
		{
			singleAward.type = HDAT_PET;
			singleAward.typeId = 64;
			singleAward.num = 1;
			jilu->allCnt++;
		}
		else
		{
			if (++jilu->allCnt % base->bemustCnt == 0)
				ckMgr.SingleChouKa(base->mustDrop, singleAward);
			else
				ckMgr.SingleChouKa(base->normalDrop, singleAward);
		}
		if (singleAward.type == HDAT_PET && GetPetDefaultQuality(singleAward.typeId) > 4)
		{
			char buf[128];
			snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0227, user->GetName(), MakePetColorStr(singleAward.typeId).c_str());
			SysInfoToAllUser(buf);
		}
		msg << PRO_SUCCESS << jilu->allCnt << jilu->freeTimes;
		if (jilu->freeCd > curTime)
			msg << (uint32)(jilu->freeCd - curTime);
		else
			msg << (uint32)0;
		MakeMultiAwardMsg(base->awards, msg);
		MakeSingleAwardMsg(user, singleAward, msg);

		user->AddMaterial(singleAward);
		for (uint8 i = 0; i < base->awards.size(); ++i)
		{
			user->AddMaterial(base->awards[i]);
		}
		sCMissionManager.UpdateQuestState(user, EMQCT_2, 1);
		break;

	case 2: // 十连
		if (user->GetMaterial(base->costId) < base->costNum * 10)
		{
			char buf[128];
			snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0182, GetItemName(base->costId));
			msg << PRO_ERROR << MakeStringColor(buf, TIPS_FAILURE_COLOR);
			return true;
		}
		user->DelPackageById(base->costId, base->costNum * 10);
		MultiAward tmpAd = base->awards;
		for (uint8 i = 0; i < tmpAd.size(); ++i)
		{
			tmpAd[i].num *= 10;
		}
		msg << PRO_SUCCESS << jilu->allCnt + 10;
		SendAndMakeAwardMsg(user, tmpAd, msg, false, MUT_ChouKa);
		msg << (uint8)10;
		for (uint8 i = 0; i < 10; ++i)
		{
			if (jilu->allCnt == 0 && type == 2)
			{
				singleAward.type = HDAT_PET;
				singleAward.typeId = 64;
				singleAward.num = 1;
				jilu->allCnt++;
			}
			else
			{
				if (++jilu->allCnt % base->bemustCnt == 0)
					ckMgr.SingleChouKa(base->mustDrop, singleAward);
				else
					ckMgr.SingleChouKa(base->normalDrop, singleAward);
			}
			if (singleAward.type == HDAT_PET && GetPetDefaultQuality(singleAward.typeId) > 4)
			{
				char buf[128];
				snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0228, user->GetName(), MakePetColorStr(singleAward.typeId).c_str());
				SysInfoToAllUser(buf);
			}
			MakeSingleAwardMsg(user, singleAward, msg);
			user->AddMaterial(singleAward);
			if (singleAward.type == HDAT_PET)
			{
				ItemCurrencyLog(user->GetRoleId(), singleAward.type, singleAward.typeId, 1, 1, 1, MUT_ChouKa);
			}
		}
		sCMissionManager.UpdateQuestState(user, EMQCT_2, 10);
		break;
	}
	return true;
}
