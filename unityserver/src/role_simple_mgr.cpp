#include "role_simple_mgr.h"
#include "self_typedef.h"
#include "user.h"
#include "pet_equip_manage.h"
#include "init.h"

CSimpleRoleDataMgr::CSimpleRoleDataMgr()
{

}

CSimpleRoleDataMgr::~CSimpleRoleDataMgr()
{


}

bool CSimpleRoleDataMgr::Init()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_data.clear();

	const int PerRowNum = 200;
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return false;
	char sql[512];
	char **row = NULL;
	int num = 0;
	int page = 0;
	do
	{
		//                         0   1    2    3   4   5   6        7           8         9       10    11   12
		snprintf(sql, sizeof(sql), "select id,name,level,power,sex,head,vipLv,lastLoginTime,huoyue_day,huoyue_week,model,bangId,jingJie from role_simple_list order by id asc limit %d,%d", page*PerRowNum, PerRowNum);
		if(!pDb->Query(sql))
		{
			cout<<">> CSimpleRoleDataMgr::Init query sql Error, sql="<<sql<<endl;
			return false;
		}

		page++;
		num = pDb->GetRowNum();
		while((row = pDb->GetRow()) != NULL)
		{
			SRoleSimpleData data;
			data.roleId = atoi(row[0]);
			data.name = row[1];
			data.level = atoi(row[2]);
			data.power = atoll(row[3]);
			data.sex = atoi(row[4]);
			data.head = atoi(row[5]);
			data.vipLv = atoi(row[6]);
			data.lastLoginTime = atoi(row[7]);
			data.huoyue_day = atoi(row[8]);
			data.huoyue_week = atoi(row[9]);
			data.model = atoi(row[10]);
			data.bangpaiId = atoi(row[11]);
			data.jingJie = atoi(row[12]);
			m_data.insert(make_pair(data.roleId, data));
		}
	}while(num == PerRowNum);
	return true;
}

void CSimpleRoleDataMgr::Save()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
	pDb->Query("truncate role_simple_list_save");
	
	{
		char sql[1024];
		uint32 curTime = GetSysTime();

		boost::recursive_mutex::scoped_lock lk(m_mutex);
		for(map<uint32, SRoleSimpleData>::iterator it = m_data.begin(); it != m_data.end(); it++)
		{
			SRoleSimpleData &data = it->second;
			uint32 loginTime = (data.lastLoginTime == 0) ? curTime : data.lastLoginTime;
			snprintf(sql, sizeof(sql), "insert into role_simple_list_save (id,name,level,power,sex,head,vipLv,lastLoginTime,huoyue_day,huoyue_week,model,bangId,jingJie) " \
				"values(%u,\"%s\",%u,%lld,%d,%d,%d,%u,%u,%u,%d,%u,%u)",
				data.roleId, data.name.c_str(), data.level, data.power, (int)data.sex, (int)data.head, (int)data.vipLv, loginTime, data.huoyue_day, data.huoyue_week,
				(int)data.model, data.bangpaiId, data.jingJie);
			pDb->Query(sql);
		}
	}
	pDb->Query("truncate role_simple_list");
	pDb->Query("insert into role_simple_list select * from role_simple_list_save");
}

void CSimpleRoleDataMgr::UpdateRoleData(CUser *pUser)
{
	if(pUser == NULL || pUser->GetRoleId() == 0)
		return;
	
	SRoleSimpleData data;
	data.roleId = pUser->GetRoleId();
	data.name = pUser->GetName();
	data.power = pUser->GetZhanDouLi();
	data.level = pUser->GetLevel();
	data.head = pUser->GetHead();
	data.model = pUser->GetModel();
	data.sex = pUser->GetSex();
	data.vipLv = pUser->GetVipLevel();
	data.bangpaiId = pUser->GetBangPai();
	data.jingJie = pUser->GetJingJie();
	if(data.bangpaiId > 0)
	{
		CBangPai *p = SingletonCBangPaiManager::instance().FindBangPai(data.bangpaiId);
		if(p != NULL)
			data.bpName = p->GetName();
	}
	data.huoyue_day = pUser->GetExtData32(EData32_HuoYueDu_Day);
	data.huoyue_week = pUser->GetExtData32(EData32_HuoYueDu_Week);
	data.lastLoginTime = 0;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32, SRoleSimpleData>::iterator it = m_data.find(data.roleId);
	if(it == m_data.end())
	{
		m_data.insert(make_pair(data.roleId, data));
		return;
	}
	it->second = data;
}

void CSimpleRoleDataMgr::UpdateLastLoginTime(uint32 roleId)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32, SRoleSimpleData>::iterator it = m_data.find(roleId);
	if(it == m_data.end())
		return;
	it->second.lastLoginTime = GetSysTime();
}

bool CSimpleRoleDataMgr::GetRoleData(uint32 roleId, SRoleSimpleData &data)
{
	if(roleId == 0)
		return false;
	data.Clear();
	
//	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32, SRoleSimpleData>::iterator it = m_data.find(roleId);
	if(it == m_data.end())
		return false;
	data = it->second;
	return true;
}

void CSimpleRoleDataMgr::Timer()
{
	static bool dayClearFlag = false;
	static bool weekClearFlag = false;

	int week = GetWeekDay();
	int hour = GetHour();
	int min = GetMinute();
	if(hour == 0 && min < 5)
	{
		if(!dayClearFlag)
		{
			dayClearFlag = true;
			// 每日数据重置
			boost::recursive_mutex::scoped_lock lk(m_mutex);
			for(map<uint32, SRoleSimpleData>::iterator it = m_data.begin(); it != m_data.end(); it++)
			{
				SRoleSimpleData &data = it->second;
				data.huoyue_day = 0;
			}
		}
		if(week == 1)
		{
			if(!weekClearFlag)
			{
				weekClearFlag = true;
				// 每周数据重置
				boost::recursive_mutex::scoped_lock lk(m_mutex);
				for(map<uint32, SRoleSimpleData>::iterator it = m_data.begin(); it != m_data.end(); it++)
				{
					SRoleSimpleData &data = it->second;
					data.huoyue_week = 0;
				}
			}
		}
	}
}

void CSimpleRoleDataMgr::GetRandRoleIdList(uint32 roleId, uint16 level, int maxNum, vector<uint32> &vec, vector<uint32> &friendList)
{
	if(roleId == 0 || level == 0 || maxNum < 1)
		return;
	vec.clear();
	vec.resize(maxNum);

	vector<uint32> matchVec;
	vector<uint32> otherVec;
	int matchNum = 0;
	int otherNum = 0;
	uint16 min_lv = (level > 5) ? (level -5) : 1;
	uint16 max_lv = level + 5;

	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		for(map<uint32, SRoleSimpleData>::iterator it = m_data.begin(); it != m_data.end(); it++)
		{
			SRoleSimpleData &data = it->second;
			if(data.roleId == roleId)
				continue;
			if(data.level >= min_lv && data.level <= max_lv)
			{
				matchVec.push_back(data.roleId);
				matchNum++;
			}
			else
			{
				otherVec.push_back(data.roleId);
				otherNum++;
			}
		}
	}

	int num = 0;
	if(matchNum > 0)
	{
		if(matchNum > 1)
			RandVector(matchVec);
		for(int i=0; i < matchNum; i++)
		{
			if(num >= maxNum)
				return;
			uint32 id = matchVec[i];
			if(std::find(friendList.begin(), friendList.end(), id) == friendList.end())
			{
				vec.push_back(id);
				num++;
			}
		}
	}
	if(otherNum == 0)
		return;
	if(otherNum > 1)
		RandVector(otherVec);
	for(int i=0; i < otherNum; i++)
	{
		if(num >= maxNum)
			return;
		uint32 id = otherVec[i];
		if(std::find(friendList.begin(), friendList.end(), id) == friendList.end())
		{
			vec.push_back(id);
			num++;
		}
	}
}

void CSimpleRoleDataMgr::MakeRoleDetails(CNetMessage &msg, uint32 roleId, uint8 type)
{
	if(roleId == 0)
		return;

	msg.ReWrite();
	msg.SetType(PRO_PLAYER_DETAIL);
	msg<<roleId<<type;

	COnlineUser &onlineMgr = SingletonOnlineUser::instance();
	bool online = true;
	CUser *pTo = onlineMgr.GetUserByRoleId(roleId).get();
	if(pTo == NULL)
	{
		pTo = new CUser;
		online = false;
		if(pTo == NULL)
		{
			delete pTo;
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0016,TIPS_FAILURE_COLOR);
			return;
		}
		else
		{
			pTo->SetRoleId(roleId);
			SRoleSimpleData simpleData;
			if(!GetRoleData(roleId, simpleData))
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0016,TIPS_FAILURE_COLOR);
				return;
			}

			CGetDbConnect getDb;
			CDatabaseSql *pDb = getDb.GetDbConnect();
			if(pDb == NULL)
			{
				delete pTo;
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0016,TIPS_FAILURE_COLOR);
				return;
			}
			
			char sql[256];
			char **row = NULL;
			//                                0    1    2     3     4          5        6       7           8        9      10  11   12   13   14  15   16
			snprintf(sql,sizeof(sql),"select sex,name,level,admin,user_book,zhanDouLi,title,pet_equip,sg_bitset,bank_item,shenqi,pet,bitset,zhenfa,exp,head,model from role_info where id=%u",roleId);
			if(!pDb->Query(sql))
			{
				delete pTo;
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0016,TIPS_FAILURE_COLOR);
				return;
			}
			if((row = pDb->GetRow()) != NULL)
			{
				pTo->SetSex(atoi(row[0]));
				pTo->SetName(row[1]);
				pTo->SetLevel(atoi(row[2]));
				pTo->SetAdminLevel(atoi(row[3]));
				UserBook* book = pTo->GetUserBook();
				if (book != NULL)
					book->LoadData(row[4]);
				pTo->SetZhanDouLi(atoi(row[5]));
				pTo->ReadTitle(row[6]);
				pTo->SetZhenFa(row[13]);
				CEquipManeger& equips = pTo->GetPetEquipMgr();
				equips.LoadData(row[7]);
				pTo->SetSGBitSet(row[8]);
				pTo->SetBankItem(row[9]);
				pTo->InitJingJie();
				pTo->LoadNewShenQi(row[10]);
				pTo->SetBitSet(row[12]);
				pTo->SetExp(atoll(row[14]));
				pTo->SetHead(atoi(row[15]));
				pTo->SetModel(atoi(row[16]));
				pTo->SetBangPai(simpleData.bangpaiId, 0, simpleData.bpName.c_str());
				pTo->SetPet(row[11]);
				pTo->Init();
			}
			else
			{
				delete pTo;
				msg<<PRO_ERROR;
				if(InKuaFu())
					msg<<MakeStringColor(LANGUAGE_SSJ_0017,TIPS_FAILURE_COLOR);
				else
					msg<<MakeStringColor(LANGUAGE_SSJ_0016,TIPS_FAILURE_COLOR);
				return;
			}
		}
	}

	uint8 vipLv = pTo->HaveBitSet(604) ? 0 : pTo->GetVipLevel();
	msg<<PRO_SUCCESS<<vipLv<<pTo->GetName()<<pTo->GetSex()<<pTo->GetModel()<<pTo->GetHead();
	msg<<pTo->GetLevel()<<pTo->GetExp()<<pTo->GetZhanDouLi();
	msg<<pTo->GetBangPai()<<pTo->GetBangPaiName();

	uint8 tranState = pTo->HaveBitSet(600) ? 1: 0;
	msg<<pTo->GetTransFormMonsterID(pTo->GetCurTransFormID())<<tranState;
	msg<<pTo->GetNewShenQiCarryID()<<pTo->GetWingId();
	msg<<pTo->GetUseZhenFaId()<<pTo->GetUseZhenFaLevel();
	
	pTo->MakeOtherChuZhanPet(msg);
	pTo->MakeOtherTitle(msg);
	pTo->MakeZhenFaMsg(msg);
	CEquipManeger& equips = pTo->GetPetEquipMgr();
	equips.MakeEquipMsg(msg);
	if(!online)
		delete pTo;
}

string CSimpleRoleDataMgr::GetUserColorName(uint32 id)
{
	SRoleSimpleData data;
	if (!GetRoleData(id, data))
	{
		return "";
	}

	SJingJieCfg cfg;
	CJingJieManager &mgr = SingletonCJingJieMgr::instance();
	if (mgr.GetCfg(data.jingJie, cfg))
	{
		char buf[32];
		snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0246, GetQualityColor(cfg.quality), cfg.name.c_str());
		return buf + data.name;
	}
	return data.name;
}


