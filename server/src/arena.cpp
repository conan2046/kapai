#include "arena.h"
#include "init.h"
#include "role_simple_mgr.h"
#include "utility.h"
#include "rank.h"

using namespace std;
uint8 CArenaCfgMgr::FreeCnt = 0;
uint8 CArenaCfgMgr::BuyCnt = 0;

CRobotMgr::CRobotMgr()
{


}

CRobotMgr::~CRobotMgr()
{


}

bool CRobotMgr::Init()
{
	const string file = "robot.json";
	//                  0         1         2          3         4         5         6        7       8       9        10       11      12
	const char* fields[] = {"id",        "type",      "name",        "head",      "quality",    "zhenfa",    "index1",  "index2",  "index3",   "index4",  "index5",    "zhanli", "mod"};
	const int types[] = {EJPT_INT,  EJPT_INT, EJPT_STRING, EJPT_INT, EJPT_INT, EJPT_ARRAY, EJPT_INT, EJPT_INT, EJPT_INT, EJPT_INT, EJPT_INT, EJPT_INT, EJPT_INT};
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, fields, types, sizeof(types)/sizeof(types[0]), d, _para))
	{
		cout<< ">> CRobotMgr::Init  error " << endl;
		return false;
	}
	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &data = _para[i];
		int type = data[fields[1]].GetInt();
		if(type == 0)
		{
			cout<< ">> CRobotMgr::Init   data error ,  idx="<< i << ",  field=" << fields[1] << endl;
			return false;
		}
		
		SRobotData cfg;
		cfg.id = data[fields[0]].GetInt();
		cfg.name = data[fields[2]].GetString();
		cfg.head = data[fields[3]].GetInt();
		cfg.quality = data[fields[4]].GetInt();
		cfg.model = data[fields[12]].GetInt();

		const rapidjson::Value &zhenfa = data[fields[5]];
		if(zhenfa.Size() != 2 || !zhenfa[0].GetInt() || !zhenfa[1].GetInt())
		{
			cout<< ">> CRobotMgr::Init   data error ,  idx="<< i << ",  field=" << fields[5] << endl;
			return false;
		}
		cfg.zhenfaId = zhenfa[0].GetInt();
		cfg.zhenfaLv = zhenfa[1].GetInt();

		for(uint32 j=6; j <= 10; j++)
			cfg.monsterId[j-6] = data[fields[j]].GetInt();
		cfg.power = data[fields[11]].GetInt();

		// 添加数据
		_RobotTypeMapIt it = m_data.find(type);
		if(it == m_data.end())
		{
			pair<_RobotTypeMapIt, bool> ret = m_data.insert(make_pair(type, _RobotMap()));
			if(!ret.second)
			{
				cout<< ">> CRobotMgr::Init   insert into map error" << endl;
				return false;
			}
			it = ret.first;
		}
		it->second.insert(make_pair(cfg.id, cfg));
	}
	return true;
}

bool CRobotMgr::GetRobot(int type, int id, SRobotData &val)
{
	if(type < 1)
		return false;
	
	_RobotTypeMapIt it = m_data.find(type);
	if(it == m_data.end())
		return false;
	_RobotMap &data = it->second;
	_RobotMapIt dIt = data.find(id);
	if(dIt == data.end())
		return false;
	val = dIt->second;
	return true;
}

bool CRobotMgr::AddRobotToFight(CFight *pFight, int type, int id)
{
	if(pFight == NULL)
		return false;

	SRobotData robot;
	if(!GetRobot(type, id, robot))
		return false;
	
	CZhenFaCfgMgr &zhenfaMgr = SingletonCZhenFaCfgMgr::instance();
	SZhenFaBasicCfg *pZhenFa = zhenfaMgr.GetBasicCfg(robot.zhenfaId);
	SZhenFaLevelUpData *pZhenFaAttr = zhenfaMgr.GetLevelUpCfg(robot.zhenfaId, robot.zhenfaLv);
	if(pZhenFa == NULL || pZhenFaAttr == NULL)
		return false;
//	pFight->SetCfgFightId(fightId);
	pFight->SetGroupZhenFaData(robot.zhenfaId, robot.zhenfaLv, CFight::EGT_GROUP2);
	pFight->SetGroupShowName(CFight::EGT_GROUP2, robot.name.c_str());
	for(uint16 i=0;i < sizeof(robot.monsterId)/sizeof(robot.monsterId[0]); i++)
	{
		int id = robot.monsterId[i];
		if(id > 0)
		{
			ShareMonsterPtr ptr = SingletonMonsterBossManager::instance().CreateMonsterBossById(id);
			SMonsterInst *pInst = ptr.get();
			if(pInst == NULL || pInst->id == 0)
				return false;
			uint8 pos = pZhenFa->fightPos[i] + CFight::GROUP2_BEGIN;
			uint8 zhenfaPos = i;
			pFight->AddMonster(ptr, pos, zhenfaPos);
		}
	}
	return true;
}

//////////////////////////////////////////////////////////////////////////////////

CArenaCfgMgr::CArenaCfgMgr()
{

}

CArenaCfgMgr::~CArenaCfgMgr()
{

}

bool CArenaCfgMgr::Init()
{
	const string file = "arena.json";
	//                    0            1          2
	const char* fields[] = {"rank",          "interval",        "robot"};
	const int types[] = { EJPT_ARRAY,  EJPT_ARRAY,  EJPT_ARRAY};
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, fields, types, sizeof(types)/sizeof(types[0]), d, _para))
	{
		cout<< ">> CArenaCfgMgr::Init  error " << endl;
		return false;
	}
	for (uint32 i = 0; i < _para.Size(); i++)
	{
		SArenaCfg cfg;
		const rapidjson::Value &data = _para[i];
		const rapidjson::Value &rank = data[fields[0]];
		const rapidjson::Value &interval = data[fields[1]];
		const rapidjson::Value &robot = data[fields[2]];
		if(rank.Size() != 2 || !rank[0].IsInt() || !rank[1].IsInt())
		{
			cout<< ">> CArenaCfgMgr::Init   data error ,  idx="<< i << ",  field=" << fields[0] << endl;
			return false;
		}
		cfg.rankBegin = rank[0].GetInt();
		cfg.rankEnd = rank[1].GetInt();

		if(interval.Size() != 2 || !interval[0].IsInt() || !interval[1].IsInt())
		{
			cout<< ">> CArenaCfgMgr::Init   data error ,  idx="<< i << ",  field=" << fields[1] << endl;
			return false;
		}
		cfg.fightNumBegin = interval[0].GetInt();
		cfg.fightNumEnd = interval[1].GetInt();

		if(robot.Size() == 0)
		{
			cout<< ">> CArenaCfgMgr::Init   data error ,  idx="<< i << ",  field=" << fields[2] << endl;
			return false;
		}
		for(uint8 i=0; i < robot.Size(); i++)
		{
			if(!robot[i].IsInt())
			{
				cout<< ">> CArenaCfgMgr::Init   data error ,  idx="<< i << ",  field=" << fields[2] << endl;
				return false;
			}
			cfg.robotId.push_back(robot[i].GetInt());
		}
		m_cfg.push_back(cfg);
	}
	return true;
}

int CArenaCfgMgr::GetRobotIdByRank(int rank)
{
	if(m_cfg.empty())
		return -1;
	int size = m_cfg.size();
	for(uint16 i=0; i < size; i++)
	{
		if(rank >= m_cfg[i].rankBegin && rank <= m_cfg[i].rankEnd)
		{
			if(m_cfg[i].robotId.empty())
				return -1;
			int num = m_cfg[i].robotId.size();
			return m_cfg[i].robotId[Random(1,num)-1];
		}
	}
	if(m_cfg[size-1].robotId.empty())
		return -1;
	int num = m_cfg[size-1].robotId.size();
	return m_cfg[size-1].robotId[Random(1,num)-1];
}

int CArenaCfgMgr::GetRandIntervalByRank(int rank)
{
	if(m_cfg.empty())
		return -1;
	int size = m_cfg.size();
	for(uint16 i=0; i < size; i++)
	{
		if(rank >= m_cfg[i].rankBegin && rank <= m_cfg[i].rankEnd)
		{
			int begin = m_cfg[i].fightNumBegin;
			int end = m_cfg[i].fightNumEnd;
			return Random(begin, end);
		}
	}

	int begin = m_cfg[size-1].fightNumBegin;
	int end = m_cfg[size-1].fightNumEnd;
	return Random(begin, end);
}


/////////////////////////////////////////////////////////////////////////////////

CArenaManager::CArenaManager()
{
	m_num = 0;
}

CArenaManager::~CArenaManager()
{

}

void CArenaManager::AddUser(CUser *pUser)
{
	if(pUser == NULL)
		return;
	
	ArenaPaiHangData data;
	data.roleId = (int)pUser->GetRoleId();
	AddUser(data);
}

void CArenaManager::AddUser(ArenaPaiHangData &data)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32, ArenaPaiHangData>::iterator it = m_userData.find(data.roleId);
	if(it == m_userData.end())
	{
		m_num++;
		uint32 rank = m_num;
		data.rank = rank;
		m_userData.insert(make_pair(data.roleId, data));

		SArenaUnit d;
		d.roleId = data.roleId;
		d.type = EUT_User;
		m_rank.push_back(d);
	}
}

void CArenaManager::AddRobot(SArenaUnit &data)
{
	if(data.type != EUT_Robot || data.roleId == 0)
		return;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_num++;
	m_rank.push_back(data);
}


bool CArenaManager::NolockChangeUser(uint32 rank1, uint32 rank2)
{
	if(rank1 == 0 || rank2 == 0)
		return false;
	
	if(rank1 > m_num || rank2 > m_num)
		return false;
	CArenaCfgMgr &cfgMgr = SingletonCArenaCfgMgr::instance();
	
	SArenaUnit &d1 = m_rank[rank1-1];
	SArenaUnit &d2 = m_rank[rank2-1];
	_ArenaPHMap::iterator it1 = m_userData.end();
	_ArenaPHMap::iterator it2 = m_userData.end();
	if(d1.type == EUT_User)
	{
		it1 = m_userData.find(d1.roleId);
		if(it1 == m_userData.end())
			return false;
	}
	if(d2.type == EUT_User)
	{
		it2 = m_userData.find(d2.roleId);
		if(it2 == m_userData.end())
			return false;
	}

	if(d1.type == EUT_User && d2.type == EUT_User)	// 都是人，交换
	{
		SArenaUnit tmp = d2;
		d2.type = d1.type;
		d2.roleId = d1.roleId;
		it2->second.rank = rank1;

		d1.type = tmp.type;
		d1.roleId = tmp.roleId;
		it1->second.rank = rank2;
	}
	else if(d1.type == EUT_User && d2.type == EUT_Robot)
	{
		d2.type = d1.type;
		d2.roleId = d1.roleId;
		it1->second.rank = rank2;

		d1.type = EUT_Robot;
		d1.roleId = cfgMgr.GetRobotIdByRank(rank1);
	}
	else if(d1.type == EUT_Robot && d2.type == EUT_User)
	{
		d1.type = d2.type;
		d1.roleId = d2.roleId;
		it2->second.rank = rank1;

		d2.type = EUT_Robot;
		d2.roleId = cfgMgr.GetRobotIdByRank(rank2);
	}
	else	// 都是机器人，异常
	{
		return false;
	}
	return true;
}

bool CArenaManager::Init()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_rank.clear();
	m_userData.clear();

	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char sql[512];
	char **row = NULL;
	if(pDb == NULL)
		return false;
	//                          0    1       2       3       4        5      6
	snprintf(sql, sizeof(sql), "select `rank`,role_id,win_num,up_down,bow_count,egg_count,robot from arena_paihang order by `rank` asc");
	if(!pDb->Query(sql))
		return false;
	int num = pDb->GetRowNum();
	if(num == 0)	// 初始化
	{
		CArenaCfgMgr &cfgMgr = SingletonCArenaCfgMgr::instance();
		for(uint16 idx=1; idx <= 10000; idx++)
		{
			SArenaUnit data;
			data.type = EUT_Robot;
			data.roleId = cfgMgr.GetRobotIdByRank(idx);
			AddRobot(data);
		}
		return true;
	}

	while((row = pDb->GetRow()) != NULL)
	{
		int robot = atoi(row[6]);
		if(robot == EUT_Robot)
		{
			SArenaUnit data;
			data.type = EUT_Robot;
			data.roleId = (uint32)atoi(row[1]);
			AddRobot(data);
		}
		else if(robot == EUT_User)
		{
			ArenaPaiHangData data;
			data.rank = (uint32)atoi(row[0]);
			data.roleId = (uint32)atoi(row[1]);
			data.winNum = (uint16)atoi(row[2]);
			data.upDown = (uint8)atoi(row[3]);
			data.bowCount = atoi(row[4]);
			data.eggCount = atoi(row[5]);
			AddUser(data);
		}
	}

	//                            0        1          2        3        4        5        6
	snprintf(sql, sizeof(sql), "select role1_id, role1_name, role1_head, role1_lv,  role1_vip, role1_power, type1"\
	//       7        8         9        10     11        12       13   14    15    16   17     18
		"role2_id, role2_name, role2_head, role1_lv, role2_vip, role2_power, type2, result, rank1, rank2, time, fightdata"\
		"from arena_log where rank1 <= 10 or rank2 <= 10 order by time desc limit 20");
	while ((row = pDb->GetRow()) != NULL)
	{
		ArenaFightData data;
		data.l_roleId = atoi(row[0]);
		data.l_Name = row[1];
		data.l_Head = atoi(row[2]);
		data.l_Lv = atoi(row[3]);
		data.l_VipLv = atoi(row[4]);
		data.l_Power = atoi(row[5]);
		data.l_type = atoi(row[6]);

		data.r_roleId = atoi(row[7]);
		data.r_Name = row[8];
		data.r_Head = atoi(row[9]);
		data.r_Lv = atoi(row[10]);
		data.r_VipLv = atoi(row[11]);
		data.r_Power = atoi(row[12]);
		data.r_type = atoi(row[13]);
		data.state = atoi(row[14]);
		data.rank1 = atoi(row[15]);
		data.rank2 = atoi(row[16]);
		data.time = atoi(row[17]);
		data.fightData = atoi(row[18]);
		m_topFightQue.push_front(data);
	}
	return true;
}

void CArenaManager::Save()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
	{
		cout<<LANGUAGE_TRANSFORM_109<<endl;
		return;
	}
	pDb->Query("truncate table arena_paihang_save");

	{
		const int MAX_LEN = 1024*40;
		const int SQL_PER_NUM = 200;
		const char *CONST_SQL = "insert into arena_paihang_save (role_id,robot,win_num,up_down,bow_count,egg_count) values ";
		
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if(m_rank.empty())
			return;
		char *sql = new char[MAX_LEN];
		boost::scoped_array<char> autoDel(sql);
		sql[0] = '\0';
		char buf[128];
		int count = 0;
		for(int i=0; i < (int)m_rank.size(); i++)
		{
			if(count % SQL_PER_NUM == 0)
			{
				snprintf(sql, MAX_LEN, "%s", CONST_SQL);
			}

			SArenaUnit &u = m_rank[i];
			if(u.type == EUT_Robot)
			{
				if(i >= (int)DefaultShowNum)
					continue;
				snprintf(buf, sizeof(buf), "(%u,%d,0,0,0,0)", u.roleId, EUT_Robot);
			}
			else if(u.type == EUT_User)
			{
				_ArenaPHMap::iterator it = m_userData.find(u.roleId);
				if(it == m_userData.end())
					continue;
				ArenaPaiHangData &d = it->second;
				snprintf(buf, sizeof(buf), "(%u,%d,%u,%d,%u,%u)", d.roleId, EUT_User, d.winNum, (int)d.upDown, d.bowCount, d.eggCount);
			}
			else
			{
				continue;
			}

			if((count % SQL_PER_NUM) == SQL_PER_NUM - 1)
			{
				count = 0;
				strcat(sql, ",");
				strcat(sql, buf);
				strcat(sql, ";");
				if(!pDb->Query(sql))
					cout<<LANGUAGE_TRANSFORM_110<<"--1 :"<<sql<<endl;
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
		if(sql[0] != '\0')
		{
			if(!pDb->Query(sql))
				cout<<LANGUAGE_TRANSFORM_110<<"--2 :"<<sql<<endl;
		}
	}

	pDb->Query("truncate table arena_paihang");
	pDb->Query("insert into arena_paihang (select * from arena_paihang_save)");
}

bool CArenaManager::GetUserData(uint32 roleId, ArenaPaiHangData &data)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	_ArenaPHMap::iterator it = m_userData.find(roleId);
	if(it == m_userData.end())
		return false;
	data = it->second;
	return true;
}

bool CArenaManager::GetUserDataByRank(uint32 rank, ArenaPaiHangData &data)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(rank == 0 || rank > m_num)
		return false;
	
	uint32 roleId = m_rank[rank-1].roleId;
	_ArenaPHMap::iterator it = m_userData.find(roleId);
	if(it == m_userData.end())
		return false;
	data = it->second;
	return true;
}

bool CArenaManager::GetDataByRank(uint32 rank, ArenaPaiHangData &data)
{
	if(rank == 0 || rank > m_num || rank > DefaultShowNum)
		return false;
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	uint32 roleId = m_rank[rank-1].roleId;
	if(m_rank[rank-1].type == EUT_Robot)
	{
		SRobotData robot;
		if(!SingletonCRobotMgr::instance().GetRobot(EROT_Arena, roleId, robot))
			return false;
		data.type = EUT_Robot;
		data.roleId = roleId;
		data.rank = rank;
	}
	else
	{
		_ArenaPHMap::iterator it = m_userData.find(roleId);
		if(it == m_userData.end())
			return false;
		data = it->second;
	}
	return true;
}


uint32 CArenaManager::GetUserRank(uint32 roleId)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	_ArenaPHMap::iterator it = m_userData.find(roleId);
	if(it == m_userData.end())
		return 0;
	return it->second.rank;
}

uint32 CArenaManager::GetUserNum()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return m_num;
}

void CArenaManager::SendAwardToAllUser()
{
	const uint32 SendAwardNum = 10000;
	vector<uint32> roleId;
	vector<uint32> roleRank;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		for(uint32 i=0; i < m_rank.size() && i < SendAwardNum; i++)
		{
			if(m_rank[i].type == EUT_User)
			{
				roleId.push_back(m_rank[i].roleId);
				roleRank.push_back(i+1);
			}
		}
	}
	
	char buf[256];
	for(uint32 i=0;i < roleId.size();i++)
	{
		if(roleId[i] > 0)
		{
			snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_111, (int)roleRank[i]);
			sAwardManager.SendRankAwardMail(CRankMgr::EMRA_JING_JI, roleId[i], roleRank[i], buf);
		}
	}
}

void CArenaManager::UpdateUserData(uint32 roleId, ArenaPaiHangData &data)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	_ArenaPHMap::iterator it = m_userData.find(roleId);
	if(it == m_userData.end())
		return;
	ArenaPaiHangData &d = it->second;
	if(d.roleId == roleId)
	{
		if(data.winNum != 0xffff)
			d.winNum = data.winNum;
		if(data.upDown != 0xff)
			d.upDown = data.upDown;
	}
}

void CArenaManager::UpdateUserData(CUser *pUser)
{
	if(pUser == NULL)
		return;
	uint32 roleId = pUser->GetRoleId();
	ArenaPaiHangData data;
	data.SetInvalid();
	UpdateUserData(roleId, data);
}

void CArenaManager::AddArenaFightData(ArenaFightData &data)
{
	if (m_topFightQue.size() >= 20)
		m_topFightQue.pop_front();
	m_topFightQue.push_back(data);
}

void ArenaFightData::MakeMsg(CNetMessage& msg)
{
	CSimpleRoleDataMgr &simpleMgr = SingletonCSimpleRoleDataMgr::instance();
	SRoleSimpleData r;
	uint8 jingJie = 0;
	msg << l_type << l_roleId;
	if(l_type == EUT_User)
	{
		if (!simpleMgr.GetRoleData(l_roleId, r))
			jingJie = r.jingJie;
		msg << l_Name << l_Head << jingJie << l_Lv << l_VipLv << l_Power;
	}
	
	msg<<r_type<<r_roleId;
	if(r_type == EUT_User)
	{
		if (!simpleMgr.GetRoleData(l_roleId, r))
			jingJie = r.jingJie;
		msg << r_Name << r_Head << jingJie << r_Lv << r_VipLv << r_Power;
	}
	msg << state << rank1 << rank2 << time << fightData;
}

void CArenaManager::GetTopArenaFightData(CNetMessage& msg)
{
	msg << (uint8)m_topFightQue.size();
	for (list<ArenaFightData>::iterator it = m_topFightQue.begin(); it != m_topFightQue.end(); ++it)
	{
		ArenaFightData& data = *it;
		data.MakeMsg(msg);
	}
}

string CArenaManager::GetDataName(ArenaPaiHangData &data)
{
	if(data.roleId == 0)
		return "";
	
	if(data.type == EUT_Robot)
	{
		SRobotData robot;
		if(!SingletonCRobotMgr::instance().GetRobot(EROT_Arena, data.roleId, robot))
			return "";
		return robot.name;
	}
	else
	{
		SRoleSimpleData t;
		if(!SingletonCSimpleRoleDataMgr::instance().GetRoleData(data.roleId, t))
			return "";
		return t.name;
	}
}

void CArenaManager::ArenaSaveData(CUser *pUser, ArenaPaiHangData &self, ArenaPaiHangData &other, bool win, uint8 star)
{
	if(pUser == NULL || self.type == EUT_Robot)
		return;
	char sql[4096];
	int selfRank = self.rank;
	int otherRank = other.rank;
	MultiAward awwards;

	string selfName = GetDataName(self);
	string otherName = GetDataName(other);

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(m_rank[selfRank-1].roleId != self.roleId || m_rank[otherRank-1].roleId != other.roleId)
		return;
	
	_ArenaPHMap::iterator selfIt = m_userData.find(self.roleId);
	if(selfIt == m_userData.end())
		return;

	sAwardManager.GetActivityDrop(pUser, 6, win ? 1 : 2, awwards);
	if(win)
	{
		selfIt->second.winNum++;
		int win_number = selfIt->second.winNum;
		if(selfRank > otherRank)
		{
			NolockChangeUser(selfRank, otherRank);
			self.rank = otherRank;
			other.rank = selfRank;

			if(win_number >= 10 && win_number%10 == 0)
			{
				snprintf(sql,sizeof(sql), LANGUAGE_TRANSFORM_609, ROLE_NAME_COLOR, selfName.c_str(), ROLE_NAME_COLOR, win_number);
				SysInfoToAllUser(sql, true);
			}
			if(otherRank == 1)
			{
				snprintf(sql,sizeof(sql), LANGUAGE_TRANSFORM_610, ROLE_NAME_COLOR, selfName.c_str(), ROLE_NAME_COLOR, otherName.c_str());
				SysInfoToAllUser(sql);
			}
/*
			// 称号添加
			if((selfRank > otherRank) && (otherRank <= 10))
			{
				if(otherRank == 1)
					pUser->AddTitle(E2UT_XIANWANGJIANGHSI);
				else if(otherRank == 2)
					pUser->AddTitle(E2UT_TIANJUNJIANGSHI);
				else if(otherRank == 3)
					pUser->AddTitle(E2UT_WANGZHEJIANGSHI);
				else
					pUser->AddTitle(E2UT_SHIDAGAOSHOU);
			}
*/
			SAwardData ybad;
			ybad.type = HDAT_YB;
			ybad.num = pUser->AddArenaRankAward(otherRank);
			awwards.push_back(ybad);
			ItemCurrencyLog(pUser->GetRoleId(), win, 1, HDAT_YB, ybad.num, pUser->GetMaterial(HDAT_YB), MUT_JingJiChang);
		}
	}
	CNetMessage toMsg;
	toMsg.SetType(MSG_ARENA);
	toMsg<<(uint8)5<<(uint8)PRO_SUCCESS;
	MakeFightEndMsg(pUser, star, toMsg, &awwards, MUT_JingJiChang);
	SingletonSocket::instance().SendMsg(pUser->GetSock(),toMsg);
}

void CArenaManager::SaveArenaLog(CFight *pFight, ArenaPaiHangData &self, ArenaPaiHangData &other, bool win, int srcRank)
{
	if(pFight == NULL)
		return;
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if (pDb == NULL)
		return;
	
	CNetMessage fightMsg;
	int fid = 0;
	if(pFight->GetFightAllNetMsg(fightMsg, EFPT_PlayBack_1))
		fid = SaveFightNetMsg(fightMsg, EFPB_ARENA, self.roleId, other.roleId);

	char sql[2048];
	uint32 nowTime = GetSysTime();
	ArenaFightData data;
	data.rank1 = self.rank;
	data.rank2 = srcRank;
	data.time = nowTime;
	data.fightData = fid;
	data.state = (win ? 0:1);
	
	data.l_roleId = self.roleId;
	data.l_type = self.type;
	if(data.l_type == EUT_User)
	{
		SRoleSimpleData selfData;
		if(!SingletonCSimpleRoleDataMgr::instance().GetRoleData(data.l_roleId, selfData))
			return;
		data.l_Name = selfData.name;
		data.l_Head = selfData.head;
		data.l_Lv = selfData.level;
		data.l_VipLv = selfData.vipLv;
		data.l_Power = selfData.power;
	}

	data.r_roleId = other.roleId;
	data.r_type = other.type;
	if(data.r_type == EUT_User)
	{
		SRoleSimpleData otherData;
		if(!SingletonCSimpleRoleDataMgr::instance().GetRoleData(data.r_roleId, otherData))
			return;
		data.r_Name = otherData.name;
		data.r_Head = otherData.head;
		data.r_Lv = otherData.level;
		data.r_VipLv = otherData.vipLv;
		data.r_Power = otherData.power;
	}

	//                                         1         2         3        4       5         6       7
	snprintf(sql, sizeof(sql), "insert into arena_log (role1_id, role1_name, role1_head, role1_lv, role1_vip, role1_power, type1, "\
	//      8        9         10       11      12        13      14    15    16    17   18     19
		"role2_id, role2_name, role2_head, role2_lv, role2_vip, role2_power, type2, result, rank1, rank2, time, fightdata)"\
	//          1   2  3  4	  5	  6  7   8  9  10  11  12   13  14  15  16  17  18 19
		"values(%u,'%s',%d,%u,%d,%lld,%d,%u,'%s',%d, %u, %d, %lld, %d, %d, %u, %u, %u, %d)",
		data.l_roleId, data.l_Name.c_str(), (int)data.l_Head, data.l_Lv, (int)data.l_VipLv, data.l_Power, (int)data.l_type,
		data.r_roleId, data.r_Name.c_str(), (int)data.r_Head, data.r_Lv, (int)data.r_VipLv, data.r_Power, (int)data.r_type,
		(int)data.state, data.rank1, data.rank2, nowTime, fid);
	pDb->Query(sql);
	
	if(self.rank <= 10 || other.rank <= 10)
	{
		SingletonCArenaManager::instance().AddArenaFightData(data);
	}
}


