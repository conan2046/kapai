#include "rank.h"
#include "utility.h"
#include "user.h"
#include "pet.h"
#include "init.h"
#include "utility.h"
#include "role_simple_mgr.h"

void SRankList::Sort()
{
	if(!needSort)
		return;
	needSort = false;
	data.sort();

	int size = data.size();
	if(size > CRankMgr::MAX_SAVE_NUM)
	{
		for(int i=0; i < (size - CRankMgr::MAX_SAVE_NUM); i++)
			data.pop_back();
		minVal = data.back().value1;
	}
}

void SRankList::Update(int type, uint32 roleId, uint64 data1, uint64 data2, int value1)
{
	if(roleId == 0)
		return;
	SRankData t;
	t.role_id = roleId;
	t.data1 = data1;
	t.data2 = data2;
	t.value1 = value1;
	t.time = GetSysTime();

	int num = 0;
	for(list<SRankData>::iterator it = data.begin(); it != data.end(); it++)
	{
		SRankData &d = *it;
		if((type != CRankMgr::ERT_Pet && d.role_id == roleId) || (type == CRankMgr::ERT_Pet && d.role_id == roleId && d.value1 == value1))
		{
			d = t;

			if(minVal == 0 || t.data1 < minVal)
				minVal = t.data1;
			needSort = true;
			return;
		}
		num++;
	}

	if(num < CRankMgr::MAX_ForceSort_NUM)
	{
		if(minVal == 0 || t.data1 < minVal)
			minVal = t.data1;
	}
	else
	{
		if(t.data1 < minVal)
			return;
	}

	data.push_back(t);
	needSort = true;
	if((int)data.size() >= CRankMgr::MAX_ForceSort_NUM)
	{
		Sort();
	}
}


bool CRankMgr::Init()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
	{
		cout << "Error:CRankMgr::Init db connect error." << endl;
		return false;
	}

	char sql[512];
	//                         0     1    2    3     4    5
	snprintf(sql,sizeof(sql),"select type,role_id,data1,data2,value1,time from rank_list order by type asc,`rank` asc");
	if(!pDb->Query(sql))
		return false;
	
	boost::recursive_mutex m_mutex;
	m_rank.clear();
	
	char **row = NULL;
	while((row = pDb->GetRow()) != NULL)
	{
		int type = atoi(row[0]);
		if(m_rank.find(type) == m_rank.end())
			m_rank[type] = SRankList();
		
		SRankList &info = m_rank[type];
		SRankData t;
		t.role_id = atoi(row[1]);
		t.data1 = atoll(row[2]);
		t.data2 = atoll(row[3]);
		t.value1 = atoi(row[4]);
		t.time = atoi(row[5]);
		if(info.minVal == 0 || t.data1 < info.minVal)
			info.minVal = t.data1;
		info.needSort = true;
		info.data.push_back(t);
	}
	// 排序
	for(map<int, SRankList>::iterator it = m_rank.begin(); it != m_rank.end(); it++)
		it->second.Sort();
	return true;
}

void CRankMgr::Save()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
	{
		cout << "Error:CRankMgr::Save() db connect error." << endl;
		return;
	}
	if(!pDb->Query("truncate table rank_list_save"))
	{
		cout << "Error:CRankMgr::Save() truncate rank_list error..." << endl;
		return;
	}

	{
		const int MAX_LEN = 1024*40;
		const int SQL_PER_NUM = 200;
		const char *CONST_SQL = "insert into rank_list_save (type,`rank`,role_id,data1,data2,value1,time) values ";
		
		boost::recursive_mutex m_mutex;
		char *sql = new char[MAX_LEN];
		boost::scoped_array<char> autoDel(sql);
		char buf[256];
		int count = 0;
		sql[0] = '\0';
		for(map<int, SRankList>::iterator it = m_rank.begin(); it != m_rank.end(); it++)
		{
			SRankList &info = it->second;
			info.Sort();
			
			int type = it->first;
			int idx = 0;
			for(list<SRankData>::iterator i = info.data.begin(); i != info.data.end(); i++)
			{
				idx++;
				SRankData &d = *i;
				snprintf(buf, sizeof(buf), "(%d,%d,%u,%lld,%lld,%d,%u)", type, idx, d.role_id, d.data1, d.data2, d.value1, d.time);

				if(count % SQL_PER_NUM == 0)
				{
					snprintf(sql, MAX_LEN, "%s", CONST_SQL);
				}			
				if((count % SQL_PER_NUM) == SQL_PER_NUM - 1)
				{
					count = 0;
					strcat(sql, ",");
					strcat(sql, buf);
					strcat(sql, ";");
					if(!pDb->Query(sql))
						cout<<">> CRankMgr::Save() error ,"<<LANGUAGE_TRANSFORM_110<<"--1 :"<<sql<<endl;
					sql[0] = '\0';
				}
				else if((count % SQL_PER_NUM) == 0)
				{
					count++;
					strcat(sql, buf);
				}
				else
				{
					count++;
					strcat(sql, ",");
					strcat(sql, buf);
				}
			}
		}
		if(sql[0] != '\0')
		{
			if(!pDb->Query(sql))
				cout<<">> CRankMgr::Save() error , "<<LANGUAGE_TRANSFORM_110<<"--2 :"<<sql<<endl;
		}
	}

	pDb->Query("truncate table rank_list");
	pDb->Query("insert into rank_list (select * from rank_list_save)");
}

void CRankMgr::UpdateData(int type, uint32 roleId, uint64 data1, uint64 data2, int value1)
{
	if(type < 1 || type >= ERT_MAX || roleId < 1)
		return;

	boost::recursive_mutex m_mutex;
	if(m_rank.find(type) == m_rank.end())
		m_rank[type] = SRankList();

	SRankList &info = m_rank[type];
	info.Update(type, roleId, data1, data2, value1);
}

void CRankMgr::GetRankData(int type, uint32 roleId, SRankData &sData)
{
	if(type < 1 || type >= ERT_MAX || roleId == 0)
		return;
	sData.Clear();
	
	boost::recursive_mutex m_mutex;
	if(m_rank.find(type) == m_rank.end())
		return;
	SRankList &info = m_rank[type];
	for(list<SRankData>::iterator it = info.data.begin(); it != info.data.end(); it++)
	{
		SRankData &rankData = *it;
		if(rankData.role_id == roleId)
		{
			sData = rankData;
			return;
		}
	}
}

void CRankMgr::BloodRankToYesterday()
{
	boost::recursive_mutex m_mutex;
	if(m_rank.find(ERT_Blood_Today) == m_rank.end())
		return;
	if(m_rank.find(ERT_Blood_Yesterday) == m_rank.end())
		m_rank[ERT_Blood_Yesterday] = SRankList();
	m_rank[ERT_Blood_Today].Sort();
	m_rank[ERT_Blood_Yesterday].Clear();
	m_rank[ERT_Blood_Yesterday].data.swap(m_rank[ERT_Blood_Today].data);
	m_rank[ERT_Blood_Today].Clear();
}

uint16 CRankMgr::GetRankIdx(int type,uint32 roleId)
{
	if(type < 1 || type >= ERT_MAX || roleId == 0)
		return 0;

	boost::recursive_mutex m_mutex;
	if(m_rank.find(type) == m_rank.end())
		return 0;
	SRankList &info = m_rank[type];
	uint16 idx = 0;
	info.Sort();
	for(list<SRankData>::iterator it = info.data.begin(); it != info.data.end(); it++)
	{
		idx++;
		SRankData &rankData = *it;
		if(rankData.role_id == roleId)
			return idx;
	}
	return 0;
}

void CRankMgr::MakeRankMsg(int type, SRankData &selfData, CNetMessage &msg, int showNum)
{
	if(type < 1 || type >= ERT_MAX || selfData.role_id < 1)
		return;

	CSimpleRoleDataMgr &simpleMgr = SingletonCSimpleRoleDataMgr::instance();
	boost::recursive_mutex m_mutex;
	if(m_rank.find(type) == m_rank.end())
		return;
	uint32 numPos = msg.GetDataLen();
	uint8 num = 0;
	uint16 selfRank = 0;
	msg<<num;

	SRankList &info = m_rank[type];
	info.Sort();
	for(list<SRankData>::iterator it = info.data.begin(); it != info.data.end(); it++)
	{
		if(num >= (uint8)showNum)
			break;
		
		SRankData &d = *it;

		SRoleSimpleData roleData;
		if(!simpleMgr.GetRoleData(d.role_id, roleData))
			continue;
		num++;
		msg<<(uint16)num<<d.role_id<<roleData.name<<roleData.level<<roleData.sex<<roleData.head<<roleData.jingJie<<roleData.power;
		msg<<roleData.bangpaiId<<roleData.bpName;
		msg<<d.data1<<d.value1;
		if(selfData.role_id == d.role_id)
		{
			selfData = d;
			selfRank = num;
		}
	}
	if(num > 0)
		msg.WriteData(numPos,&num,sizeof(num));

	if (selfRank == 0)
		selfRank = GetRankIdx(type, selfData.role_id);

	SRoleSimpleData roleData;
	if(!simpleMgr.GetRoleData(selfData.role_id, roleData))
		return;
	msg<<selfRank<<selfData.data1<<selfData.data2<<selfData.value1;
}

void CRankMgr::RemoveRankByValue(int type, uint32 roleId, int value1)
{
	if(type < 1 || type >= ERT_MAX || roleId < 1)
		return;
	boost::recursive_mutex m_mutex;
	if(m_rank.find(type) == m_rank.end())
		return;
	SRankList &rank = m_rank[type];
	for(list<SRankData>::iterator it = rank.data.begin(); it != rank.data.end(); it++)
	{
		if(it->role_id == roleId && it->value1 == value1)
		{
			rank.data.erase(it);
			return;
		}
	}
}

void CRankMgr::RemoveRank(int type, uint32 roleId)
{
	if(type < 1 || type >= ERT_MAX || roleId < 1)
		return;
	boost::recursive_mutex m_mutex;
	if(m_rank.find(type) == m_rank.end())
		return;
	SRankList &rank = m_rank[type];
	for(list<SRankData>::iterator it = rank.data.begin(); it != rank.data.end(); it++)
	{
		if(it->role_id == roleId)
		{
			rank.data.erase(it);
			return;
		}
	}
}

void CRankMgr::Clear(int type)
{
	if(type < 1 || type >= ERT_MAX)
		return;
	
	boost::recursive_mutex m_mutex;
	if(m_rank.find(type) == m_rank.end())
		return;
	m_rank[type].Clear();
}

void CRankMgr::Timer()
{
	static bool clearFlag = true;
	int hour = GetHour();
	int minute = GetMinute();
	if(hour == 0 && minute < 5 && clearFlag)
	{
		clearFlag = false;
		
		BloodRankToYesterday();
	}
	else if(hour != 0 && !clearFlag)
	{
		clearFlag = true;
	}
}



