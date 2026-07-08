#include <algorithm>
#include <boost/scoped_ptr.hpp>
#include <boost/format.hpp>
#include <boost/bind.hpp>
#include "bangpai.h"
#include "user.h"
#include "scene_manager.h"
#include "award_manager.h"
#include "singleton.h"
#include "script_call.h"
#include "init.h"
#include "rank.h"
#include "role_simple_mgr.h"
#include "gyu/g_ini_file.h"

extern const char *gConfigFile;

static const uint32 AddTreeExpPerHour[] = {500,550,600,650,700,750,800,850,900,950};
static const uint8 PLANT_MAX_QUALITY_LIMIT = ZZQT_ORANGE;
//static const char* PLANT_SEED_TYPE_NAME[ZZGain_MAX_Type+1] = {"",LANGUAGE_TRANSFORM_270,LANGUAGE_TRANSFORM_271,LANGUAGE_TRANSFORM_272,LANGUAGE_TRANSFORM_273};

static const uint32 BP_FIRE_TIME_GAP = 600;

static const int WATER_TIMES_LIMIT_GAIN = 10;	// 浇水收益次数限制
static const int KILLBUG_TIMES_LIMIT_GAIN = 10;	// 除虫收益次数限制
static const int STEAL_TIMES_LIMIT_GAIN = 10;	// 偷菜收益次数限制
static const int GAIN_TIMES_LIMIT_GAIN = 10;	// 收获收益次数限制
static const int ROB_TREE_TIMES_LIMIT_GAIN = 20;	// 掠夺收益次数限制
static const int BANG_GONG_ROB_TREE = 50;	// 掠夺神树经验
static const int BANG_GONG_PRAY = 30;		// 每日祈福帮贡
static const int BANG_GONG_WATERING = 5;	// 浇水帮贡
static const int BANG_GONG_KILLBUG = 5;		// 除虫帮贡
static const int BANG_GONG_STEAL = 5;		// 偷菜帮贡
static const int BANG_GONG_GAIN = 5;		// 收获帮贡
static const uint16 STEAL_PLANT_PERCENT = 10;	// 每日偷菜的百分比
static const uint8 BP_PRAY_LOG_MAX_NUM = 5;		// 祈福记录上限
static const uint8 BP_OPTION_LOG_MAX_NUM = 20;	// 帮派操作记录上限
static const uint8 BP_YB_PRAY_LIMIT = 10;		// 元宝祈福次数限制
static const uint8 BP_NORMAL_PRAY_LIMIT = 1;	// 普通祈福次数限制
static const uint8 PLANT_ROLE_WATER_NUM_LIMIT = 60;		// 浇水次数限制
static const uint8 PLANT_ROLE_KILLBUG_NUM_LIMIT = 60;	// 除虫次数限制
static const uint8 PLANT_ROLE_STEAL_NUM_LIMIT = 30;		// 偷窃次数限制

static const uint32 BP_ZZ_CHANGE_PIC_TIME = 29*60;	//树变模型时间
static const uint8 BP_MAX_LEVEL = 10;
//static const uint8 BP_MEMBER_NUM_LIMIT[BP_MAX_LEVEL] = {30,36,42,48,54,60,60,60,60,60};	//每个位阶人数限制
//static const uint8 BP_MEMBER_NUM_LIMIT[BP_MAX_LEVEL] = {30,35,40,45,50,55,60,65,70,75};	//每个位阶人数限制
static const uint8 BP_MEMBER_NUM_LIMIT[BP_MAX_LEVEL] = {60,65,70,75,80,85,90,95,100,105};	//每个位阶人数限制
static const uint8 BP_AREA_TYPE[BP_AREA_MAX_NUM] = {0,0,0,0,0};				//0普通菜地1特殊菜地
static const uint8 BP_AREA_MAX_NUM_LIMIT[BP_AREA_MAX_NUM] = {15,15,10,11,9};	//相应地块最大菜地数量
static const uint8 BP_AREA_CELL_MAX_NUM[BP_MAX_LEVEL][BP_AREA_MAX_NUM] = {
	{15, 15, 10, 11,9},
	{15, 15, 10, 11,9},
	{15, 15, 10, 11,9},
	{15, 15, 10, 11,9},
	{15, 15, 10, 11,9},
	{15, 15, 10, 11,9},
	{15, 15, 10, 11,9},
	{15, 15, 10, 11,9},
	{15, 15, 10, 11,9},
	{15, 15, 10, 11,9}};	// 单个菜地种植上限

/*
	{15, 15, 10, 0, 0},
	{15, 15, 10, 0, 0},
	{15, 15, 10, 0, 0},
	{15, 15, 10, 11,0},
	{15, 15, 10, 11,9},
	{15, 15, 10, 11,9},
	{15, 15, 10, 11,9},
	{15, 15, 10, 11,9},
	{15, 15, 10, 11,9},
	{15, 15, 10, 11,9}};	// 单个菜地种植上限
*/

//										浇水，				除虫，				种植，				偷窃			杀人
static const uint8 TaskType[] = 		{2,					3,					1,					4,				5};
static const char *TaskReward[] = 		{LANGUAGE_TRANSFORM_274,	LANGUAGE_TRANSFORM_275,		LANGUAGE_TRANSFORM_276,		LANGUAGE_TRANSFORM_277,	LANGUAGE_TRANSFORM_278};
static const uint8 TaskCompleteNum[] = 	{10,				10,					6,					10,				5};
static const double TaskExpPercent[] =	{0.15,				0.15,				0.20,				0.25,			0.25};

static uint8 GetPlantAreaCellNum(uint8 index,uint8 bangpaiLv)
{
	if(index >= BP_AREA_MAX_NUM)
		return 0;
	if(bangpaiLv > BP_MAX_LEVEL)
		return 0;
	return BP_AREA_CELL_MAX_NUM[bangpaiLv-1][index];
}

static bool IsSpecialPlantArea(uint8 index)
{
	if(index >= BP_AREA_MAX_NUM)
		return false;
	return (BP_AREA_TYPE[index] == 1 ? true : false);
}

/*
static bool HaveRightToPlant(uint8 rank,uint8 plantIdx)
{
	if(plantIdx >= BP_AREA_MAX_NUM)
		return false;
	if(!IsSpecialPlantArea(plantIdx))
		return true;
	return (rank <= EBRHuFa ? true : false);
}
*/

static uint8 GetPlantAreaOpenLevel(uint8 index)
{
	if(index >= BP_AREA_MAX_NUM)
		return 0;
	for(uint8 lv=1;lv <= BP_MAX_LEVEL;lv++)
	{
		if(BP_AREA_CELL_MAX_NUM[lv-1][index] > 0)
			return lv;
	}
	return 0;
}

static string AddTimeBeforeString(uint32 time,string &str)
{
	uint32 curTime = (uint32)GetSysTime();
	if(time > curTime)
		return "";

	char buf[256];
	int t = curTime - time;
	int day = t/(3600*24);
	int hour = t/3600;
	int minute = t%3600/60;
	if(minute == 0)
		minute = 1;
	if(day > 0)
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_279,day,str.c_str());
	else if(hour > 0)
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_280,hour,str.c_str());
	else
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_281,minute,str.c_str());
	return buf;
}

static uint32 GetBangPaiLevelUpExp(uint8 level)
{
	const uint32 BP_LEVEL_EXP[] = {17000,80080,237600,518700,963480,1587000,2355200,3323500,4512600,5943200};
	if(level == 0 || level > sizeof(BP_LEVEL_EXP)/sizeof(BP_LEVEL_EXP[0]))
		return 0;
	return BP_LEVEL_EXP[level-1];
}


void SBangPai_CopyData::Sort()
{
	if(needSort)
	{
		if(damRank.size() > 1)
		{
			SSortBP_DamRank fun;
			std::sort(damRank.begin(), damRank.end(), fun);
		}
		needSort = false;
	}
}

void SBangPai_CopyData::AddRoleDamage(uint32 roleId, uint64 &damage)
{
	uint32 size = damRank.size();
	for(uint16 i=0; i < size; i++)
	{
		if(damRank[i].role_id == roleId)
		{
			damRank[i].damage += damage;
			return;
		}
	}
	damRank.push_back(SBP_CopyDamage(roleId, damage));
	if(size > 0)
		needSort = true;
}

void SBangPai_CopyData::UpdateMonsterHp(vector<SFastFightUnit> &vec)
{
	for(uint16 i=0; i < vec.size(); i++)
	{
		uint8 pos = vec[i].pos;
		if(pos < ZHEN_FA_POS_NUM)
		{
			monLeftHp[pos] = vec[i].hp;
		}
	}
}

uint32 SBangPai_CopyData::GetMaxDamageRoleId()
{
	Sort();
	if(damRank.empty())
		return 0;
	return damRank[0].role_id;
}


//////////////////////////////////////////////////////////////////////////////


bool CPlantSeedManager::Init()
{
	m_seedData.clear();

	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return false;
	//						  0		1		2	  3			4			5				6				7			8		9		10		11		12
	if(!pDb->Query("select itemId,treeName,pic1,pic2,ripeTimeGap,wateringTimeGap,wateringReduce,killBugTimeGap,stealNum,gainType,gainValue,gainItem,price,"\
		//		13			14				15				16	   17
		"priceType,witheredTimeGap,wateringLimit,killBugLimit,pic3 from bang_pai_seed_config order by itemId asc"))
		return false;

	char **row;
	while((row = pDb->GetRow()) != NULL)
	{
		SPlantSeed *pSeed = new SPlantSeed;
		pSeed->itemId = (uint16)atoi(row[0]);
		pSeed->treeName = row[1];
		pSeed->step_pic1 = (uint16)atoi(row[2]);
		pSeed->step_pic2 = (uint16)atoi(row[3]);
		pSeed->step_pic3 = (uint16)atoi(row[17]);
		pSeed->ripeTimeGap = (uint32)atoi(row[4]);
		pSeed->wateringTimeGap = (uint32)atoi(row[5]);
		pSeed->wateringReduceTime = (uint32)atoi(row[6]);
		pSeed->killBugTimeGap = (uint32)atoi(row[7]);
		pSeed->stealNumLimit = (uint8)atoi(row[8]);
		pSeed->gainType = (uint8)atoi(row[9]);
		pSeed->gainValue = (uint32)atoi(row[10]);
		pSeed->gainItemId = (uint32)atoi(row[11]);
		pSeed->price = (uint32)atoi(row[12]);
		pSeed->priceType = (uint16)atoi(row[13]);
		pSeed->witheredTimeGap = (uint32)atoi(row[14]);
		pSeed->wateringLimit = (uint16)atoi(row[15]);
		pSeed->killBugLimit = (uint16)atoi(row[16]);	
		if(!m_seedData.insert(make_pair(pSeed->itemId,pSeed)).second)
			cout<<"Error:CPlantSeedManager::Init() insert error"<<endl;
	}
	return true;
}

SPlantSeed *CPlantSeedManager::FindSeed(uint32 id)
{
	map<uint16,SPlantSeed *>::iterator it = m_seedData.find(id);
	if(it == m_seedData.end())
		return NULL;
	return it->second;
}

////////////////////////////////////////////////////////////////////////////////

CBP_CfgMgr::CBP_CfgMgr()
{


}

CBP_CfgMgr::~CBP_CfgMgr()
{


}

bool CBP_CfgMgr::Init()
{
	m_buffCfg.clear();
	m_awardCfg.clear();

	{
		const string file = "guild_buff.json";
		//                  0         1           2       3
		const char* fields[] = {"id",        "buff",            "max",     "cost"};
		const int types[] = {EJPT_INT, EJPT_ARRAY,  EJPT_INT,  EJPT_INT};
		rapidjson::Document d;
		rapidjson::Value _para;
		if (!LoadJosnValue(file, fields, types, sizeof(types)/sizeof(types[0]), d, _para))
		{
			cout<< ">> CBP_CfgMgr::Init  error " << endl;
			return false;
		}
		for (uint32 i = 0; i < _para.Size(); i++)
		{
			SBP_BuffCfg cfg;
			const rapidjson::Value &data = _para[i];
			const rapidjson::Value &buff = data[fields[1]];
			if(buff.Size() != 2 || !buff[0].IsInt() || !buff[1].IsInt())
			{
				cout<< ">> CBP_CfgMgr::Init   data error ,  idx="<< i << ",  field=" << fields[1] << endl;
				return false;
			}
			cfg.id = data[fields[0]].GetInt();
			cfg.maxLevel = data[fields[2]].GetInt();
			cfg.cost = data[fields[3]].GetInt();
			cfg.attr.attrType = buff[0].GetInt();
			cfg.attr.attrValue = buff[1].GetInt();
			m_buffCfg.insert(make_pair(cfg.id, cfg));
		}
	}

	{
		const string file = "guild_reward.json";
		//                  0         1          2
		const char* fields[] = {"id",       "activity",  "reward_fix"};
		const int types[] = {EJPT_INT, EJPT_INT,     EJPT_INT};
		rapidjson::Document d;
		rapidjson::Value _para;
		if (!LoadJosnValue(file, fields, types, sizeof(types)/sizeof(types[0]), d, _para))
		{
			cout<< ">> CBP_CfgMgr::Init  error " << endl;
			return false;
		}
		for (uint32 i = 0; i < _para.Size(); i++)
		{
			SBP_HuoYueAwardCfg cfg;
			const rapidjson::Value &data = _para[i];
			cfg.id = data[fields[0]].GetInt();
			cfg.activity = data[fields[1]].GetInt();
			cfg.rewardFixId = data[fields[2]].GetInt();
			m_awardCfg.insert(make_pair(cfg.id, cfg));
		}
	}
	return true;
}

SBP_BuffCfg *CBP_CfgMgr::GetBuffCfg(uint16 id)
{
	map<uint16, SBP_BuffCfg>::iterator it = m_buffCfg.find(id);
	if(it == m_buffCfg.end())
		return NULL;
	return &(it->second);
}

void CBP_CfgMgr::GetBuffIdList(vector<uint16> &vec)
{
	vec.clear();
	for(map<uint16, SBP_BuffCfg>::iterator it = m_buffCfg.begin(); it != m_buffCfg.end(); it++)
	{
		vec.push_back(it->first);
	}
}

SBP_HuoYueAwardCfg *CBP_CfgMgr::GetHuoYueCfg(int id)
{
	map<uint16, SBP_HuoYueAwardCfg>::iterator it = m_awardCfg.find(id);
	if(it == m_awardCfg.end())
		return NULL;
	return &(it->second);
}

void CBP_CfgMgr::GetHuoYueCfgList(vector<uint16> &vec)
{
	vec.clear();
	for(map<uint16, SBP_HuoYueAwardCfg>::iterator it = m_awardCfg.begin(); it != m_awardCfg.end(); it++)
	{
		vec.push_back(it->first);
	}
}

////////////////////////////////////////////////////////////////////////////////


void CBangPai::InitZhongZhi(bool query)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);

	m_totalPlantsNum = 0;
	if(m_plantData.size() == 0)
	{
		for(uint8 i=0;i < BP_AREA_MAX_NUM;i++)
		{
			vector<SPlant> temp;
			temp.resize(GetPlantAreaCellNum(i,m_level));
			m_plantData.push_back(temp);
			m_totalPlantsNum += m_plantData[i].size();
		}
	}
	else
	{
		for(uint8 i=0;i < BP_AREA_MAX_NUM;i++)
		{
			m_plantData[i].resize(GetPlantAreaCellNum(i,m_level));
			m_totalPlantsNum += m_plantData[i].size();
		}
	}

	m_plantAreaLv.clear();
	for(uint8 i=0;i < BP_AREA_MAX_NUM;i++)
		m_plantAreaLv.push_back(m_level);

	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
	char **row = NULL;
	char sql[512];
/*	if(query)
	{
		//									  0		1		2		3	   4	  5		6		7	  8			9		 10			11			12		13		14			15			16
		snprintf(sql,sizeof(sql)-1,"select item_id,state,field_idx,pos,quality,gain,role_id,time,ripe_time,role_name,stealNum,wateringTime,killBugTime,pic,wateringCount,killBugCount,thiefList"\
			" from bang_pai_plant where bang_id=%u and item_id>0 order by field_idx asc,pos asc",m_id);
		if(!pDb->Query(sql))
			return;
		m_havePlantedNum = 0;

		while((row = pDb->GetRow()) != NULL)
		{
			uint16 index = (uint16)atoi(row[2]);
			uint16 pos = (uint16)atoi(row[3]);
			if(index >= m_plantData.size() || pos >= m_plantData[index].size())
				continue;
			SPlant &plant = m_plantData[index][pos];
			plant.itemId = (uint16)atoi(row[0]);
			plant.state = (uint8)atoi(row[1]);
			plant.quality = (uint8)atoi(row[4]);
			plant.gain = (uint32)atoi(row[5]);
			plant.roleId = (uint32)atoi(row[6]);
			plant.time = (uint32)atoi(row[7]);
			plant.ripeTime = (uint32)atoi(row[8]);
			plant.roleName = row[9];
			plant.wateringTime = (uint32)atoi(row[11]);
			plant.killBugTime = (uint32)atoi(row[12]);
			plant.pic = (uint16)atoi(row[13]);
			plant.wateringCount = (uint32)atoi(row[14]);
			plant.killBugCount = (uint32)atoi(row[15]);
			plant.thiefList.clear();

			char *split[PLANT_ROLE_STEAL_NUM_LIMIT];
			string str = row[16];
			int num = SplitLine(split,PLANT_ROLE_STEAL_NUM_LIMIT,(char*)str.c_str());
			for(int k=0;k < num;k++)
			{
				uint32 roleId = (uint32)atoi(split[k]);
				if(roleId > 0)
					plant.thiefList.push_back(roleId);
			}
			// 避免停服时候有人在偷菜次数没有-1
			plant.stealNum = plant.thiefList.size();

			m_havePlantedNum++;
		}
	}

	snprintf(sql,sizeof(sql),"select msg,time from bang_pai_log where bang_id=%u and type=%d order by time desc limit %d",m_id,EBLT_PRAY,(int)BP_PRAY_LOG_MAX_NUM);
	if(!pDb->Query(sql))
		return;
	while((row = pDb->GetRow()) != NULL)
	{
		SBangPaiLog temp;
		temp.log = row[0];
		temp.time = (uint32)atoi(row[1]);
		m_prayLog.push_back(temp);
	}
	for(uint8 i=m_prayLog.size();i < BP_PRAY_LOG_MAX_NUM;i++)
	{
		SBangPaiLog temp;
		m_prayLog.push_back(temp);
	}
*/
	snprintf(sql,sizeof(sql),"select msg,time,time_str,type from bang_pai_log where bang_id=%u order by time desc limit %d",m_id, (int)BP_OPTION_LOG_MAX_NUM);
	if(!pDb->Query(sql))
		return;
	m_optionLog.clear();
	while((row = pDb->GetRow()) != NULL)
	{
		SBangPaiLog temp;
		temp.log = row[0];
		temp.time = (uint32)atoi(row[1]);
		temp.time_str = row[2];
		temp.type = atoi(row[3]);
		m_optionLog.push_back(temp);
	}
}

void CBangPai::InitGuard()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;

	char **row = NULL;
	char sql[512];
	snprintf(sql,sizeof(sql)-1,"select guardIdx,role_id from bang_pai_guard where bang_id=%u",m_id);
	if(!pDb->Query(sql))
		return;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint8 i = 0; i < sizeof(m_guard)/sizeof(m_guard[0]); i++)
		m_guard[i].reset();
	while((row = pDb->GetRow()) != NULL)
	{
		uint8 guard = (uint8)atoi(row[0]);
		if(guard >= sizeof(m_guard)/sizeof(m_guard[0]))
			continue;
		CUser *pUser = new CUser;
		pUser->SetRoleId((uint32)atoi(row[1]));
		pUser->SetBangPai(m_id,EBRHuFa,m_name.c_str());
		pUser->SetSock(-1);
		ShareUserPtr ptr(pUser);
		m_guard[guard] = ptr;
	}

	for(uint8 i=0;i < sizeof(m_guard)/sizeof(m_guard[0]);i++)
	{
		if(m_guard[i].get() != NULL)
			m_guard[i]->ReadBangPaiGuardData();
	}
}

void CBangPai::SaveGuard()
{
	for(uint8 i=0;i < sizeof(m_guard)/sizeof(m_guard[0]);i++)
	{
		if(m_guard[i].get() != NULL)
			m_guard[i]->SaveBangPaiGuardData(i);
	}
}

void CBangPai::SaveBangPaiMember()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;

	char sql[512];
	//	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(map<uint32,SBangPaiMember>::iterator i = m_allMember.begin(); i != m_allMember.end(); i++)
	{
		SBangPaiMember &d = i->second;
		snprintf(sql,sizeof(sql),"insert into bang_pai_role (bangpai_id,role_id,`rank`,join_time,total_bangGong,huoyue) values(%u,%u,%d,%u,%d,%u)",
			m_id, d.roleId, (int)d.rank, d.utime, d.total_gongXian, d.huoyue_day);
		pDb->Query(sql);
	}
}

void CBangPai::SaveZhongZhi()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;

	char sql[512];
	for(uint32 i = 0; i < m_plantData.size(); i++)
	{
		for(uint32 j=0;j < m_plantData[i].size();j++)
		{
			SPlant &seed = m_plantData[i][j];
			if(seed.itemId != 0)
			{
				stringstream thief;
				for(uint8 k=0;k < seed.thiefList.size();k++)
					thief<<seed.thiefList[k]<<"|";
				snprintf(sql,sizeof(sql),"insert into bang_pai_plant(bang_id,item_id,state,field_idx,pos,quality,gain,role_id,time,ripe_time,role_name,stealNum,wateringTime,killBugTime,"\
					" pic,wateringCount,killBugCount,thiefList) values (%u,%u,%u,%u,%u,%d,%u,%u,%u,%u,'%s',%d,%u,%u,%u,%u,%u,'%s')",m_id,seed.itemId,
					seed.state,i,j,(int)seed.quality,seed.gain,seed.roleId,seed.time,seed.ripeTime,seed.roleName.c_str(),(int)seed.stealNum,
					seed.wateringTime,seed.killBugTime,seed.pic,seed.wateringCount,seed.killBugCount,thief.str().c_str());
				if(!pDb->Query(sql))
					cout<<">> CBangPai::SaveZhongZhi error!  sql="<<sql<<endl;
			}
		}
	}
}

void CBangPai::PlantResource(CUser *pUser,uint16 itemId,uint8 plantIdx,uint8 cellPos)
{
/*
	if (pUser == NULL || itemId == 0)
		return;
	uint8 op = 3;
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_BANGPAI_ZHONGZHI);
	msg<<op<<m_id;

	if(!IsSeedItem(itemId))
	{
		msg<<PRO_ERROR<<(uint8)0<<MakeStringColor(LANGUAGE_TRANSFORM_282,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}
	if(pUser->GetBangPai() == 0)
	{
		msg<<PRO_ERROR<<(uint8)0<<MakeStringColor(LANGUAGE_TRANSFORM_283,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}
	else if(pUser->GetBangPai() != m_id)
	{
		msg<<PRO_ERROR<<(uint8)0<<MakeStringColor(LANGUAGE_TRANSFORM_284,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}
	if(pUser->GetItemNum(itemId) == 0)
	{
		msg<<PRO_ERROR<<(uint8)0<<MakeStringColor(LANGUAGE_TRANSFORM_285,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}

	SPlantSeed *pTmpSeed = SingletonCPlantSeedManager::instance().FindSeed(itemId);
	if(pTmpSeed == NULL)
	{
		msg<<PRO_ERROR<<(uint8)0<<MakeStringColor(LANGUAGE_TRANSFORM_286,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}

	bool inhuodong = InHuoDongTime(CHuoDongAwardManager::TAOHUAGENG);
	uint8 plantSeedCount = pUser->GetPlantSeedTypeCount(pTmpSeed->gainType);
	char buf[512];

	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if(plantIdx >= m_plantData.size() || cellPos >= m_plantData[plantIdx].size())
		{
			msg<<PRO_ERROR<<(uint8)0<<MakeStringColor(LANGUAGE_TRANSFORM_287,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}

		SBangPaiMember *pData = NolockGetMemberData(pUser->GetRoleId());
		if(pData == NULL)
		{
			msg<<PRO_ERROR<<(uint8)0<<MakeStringColor(LANGUAGE_TRANSFORM_288,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(pData->plantNum>=G_VipConfig[pUser->GetVipLevel()].bpzhongzhi)
		{
			int nextlv=0;
			int curseed=G_VipConfig[pUser->GetVipLevel()].bpzhongzhi;
			for(int i=pUser->GetVipLevel()+1;i<16;i++)
			{
				if(G_VipConfig[i].bpzhongzhi>curseed)
				{
					nextlv=i;
					break;
				}
			}
			if(pUser->GetVipLevel()==15 || nextlv == 0)
			{
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_289,G_VipConfig[pUser->GetVipLevel()].bpzhongzhi);
				msg<<PRO_ERROR<<(uint8)0<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
			}
			else
			{
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_290,TIPS_SUCCESS_COLOR,G_VipConfig[pUser->GetVipLevel()].bpzhongzhi,
								TIPS_SUCCESS_COLOR,nextlv);
				msg<<PRO_ERROR<<(uint8)1<<buf;
			}
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(!HaveRightToPlant(pData->rank,plantIdx))
		{
			msg<<PRO_ERROR<<(uint8)0<<MakeStringColor(LANGUAGE_TRANSFORM_291,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}

		SPlant &cell = m_plantData[plantIdx][cellPos];
		if(cell.itemId > 0)
		{
			msg<<PRO_ERROR<<(uint8)0<<MakeStringColor(LANGUAGE_TRANSFORM_292,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}

		if(plantSeedCount >= PLANT_SEED_TYPE_COUNT_LIMIT[pTmpSeed->gainType]+G_VipConfig[pUser->GetVipLevel()].seedtype[pTmpSeed->gainType-1])
		{
			int nextlv=0;
			int curseed=G_VipConfig[pUser->GetVipLevel()].seedtype[pTmpSeed->gainType-1];
			for(int i=pUser->GetVipLevel()+1;i<16;i++)
			{
				if(G_VipConfig[i].seedtype[pTmpSeed->gainType-1]>curseed)
				{
					nextlv=i;
					break;
				}
			}
			if(pUser->GetVipLevel()==15 || nextlv == 0)
			{
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_293,G_VipConfig[pUser->GetVipLevel()].seedtype[pTmpSeed->gainType-1]+PLANT_SEED_TYPE_COUNT_LIMIT[pTmpSeed->gainType],PLANT_SEED_TYPE_NAME[pTmpSeed->gainType]);
				msg<<PRO_ERROR<<(uint8)0<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
			}
			else
			{
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_294,TIPS_SUCCESS_COLOR,PLANT_SEED_TYPE_NAME[pTmpSeed->gainType],TIPS_SUCCESS_COLOR,nextlv);
				if(inhuodong)
					strcat(buf,LANGUAGE_SSJ_0389);
				msg<<PRO_ERROR<<(uint8)1<<buf;
			}
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}
		uint32 curTime = (uint32)GetSysTime();
		cell.itemId = itemId;
		cell.killBugTime = curTime;
		cell.pic = pTmpSeed->step_pic1;
		cell.quality = ZZQT_WHITE;
		cell.ripeTime = curTime + pTmpSeed->ripeTimeGap;
		cell.roleId = pUser->GetRoleId();
		cell.roleName = pUser->GetName();
		cell.state = EZZSCanClear;
		cell.stealNum = 0;
		cell.time = curTime;
		cell.wateringTime = curTime;
		if(IsSpecialPlantArea(plantIdx))
			cell.gain = (uint32)(pTmpSeed->gainValue * 1.15);
		else
			cell.gain = pTmpSeed->gainValue;		
		pData->plantNum++;
		m_havePlantedNum++;
	}
	pUser->DelPackageById(itemId,1);
	pUser->AddPlantSeedTypeCount(pTmpSeed->gainType);

	plantSeedCount += 1;
	uint8 leftPlantNum = PLANT_SEED_TYPE_COUNT_LIMIT[pTmpSeed->gainType]+G_VipConfig[pUser->GetVipLevel()].seedtype[pTmpSeed->gainType-1] - plantSeedCount;
	snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_295,pTmpSeed->treeName.c_str(),(int)leftPlantNum);
	SaveDate(pUser, 35,itemId);
	pUser->SetExtData32(401,pUser->GetExtData32(401) + 1);
	msg<<PRO_SUCCESS<<MakeStringColor(buf,TIPS_WARNING_COLOR);
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
	SingletonCMissionManager::instance().UpdateDCMissionComplate(pUser, EMISS_DC_55);
	//	int64 addExp = SingletonHuoDongExpManager::instance().GetHuoDongExp(23,pUser->GetLevel(),0.025);
	//	pUser->AddExp(addExp);
	//	snprintf(buf,sizeof(buf),"获得经验%lld",addExp);
	//	SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());	

	BroadcastAddPlantMsg(plantIdx,cellPos);
	UpdateTaskInfo(pUser,EBTT_ZhongZhi);
	UpdateHuoYue(pUser,EBHT_ZhongZhi);
*/
}

void CBangPai::WateringPlant(CUser *pUser,uint8 plantIdx,uint8 cellPos)
{
/*
	if(pUser == NULL)
		return;
	uint8 op = 4;
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_BANGPAI_ZHONGZHI);
	msg<<op<<m_id;

	if(pUser->GetPlantWateringCount() >= PLANT_ROLE_WATER_NUM_LIMIT)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_296,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}

	char buf[256];
	SPlantSeed *pTmpSeed = NULL;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if(plantIdx >= m_plantData.size() || cellPos >= m_plantData[plantIdx].size())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_297,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}
		SPlant &cell = m_plantData[plantIdx][cellPos];
		if(cell.itemId == 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_298,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}
		if((cell.state & EZZSWatering) == 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_299,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}

		if((pTmpSeed = SingletonCPlantSeedManager::instance().FindSeed(cell.itemId)) == NULL)
			return;
		uint32 curTime = (uint32)GetSysTime();
		if(curTime < cell.wateringTime)
			return;
		if(curTime - cell.wateringTime < pTmpSeed->wateringTimeGap)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_300,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(cell.wateringCount >= pTmpSeed->wateringLimit)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_301,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}

		cell.state &= (~EZZSWatering);	
		cell.wateringTime = curTime;
		cell.wateringCount++;
		cell.ripeTime -= pTmpSeed->wateringReduceTime;
		if(cell.ripeTime < curTime)
		{
			cell.state = EZZSRipe;
			if(cell.pic != pTmpSeed->step_pic3)
				cell.pic = pTmpSeed->step_pic3;
		}

		pUser->AddPlantWateringCount();
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_302,(int)(pTmpSeed->wateringReduceTime/60));
		msg<<PRO_SUCCESS<<MakeStringColor(buf,TIPS_WARNING_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);

		NoLockUpdateZZCell(plantIdx,cellPos);
	}

	string bangName = GetRoleBangPaiName(pUser->GetRoleId());
	if(bangName.size() == 0)
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_303,GGCT_GREEN,pUser->GetName(),GGCT_ORANGE,pTmpSeed->treeName.c_str());
	else
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_304,GGCT_GREEN,bangName.c_str(),GGCT_GREEN,pUser->GetName(),GGCT_ORANGE,pTmpSeed->treeName.c_str());
	SaveBangPaiLog(pUser,EBLT_WATERING,buf);

	//	int64 addExp = SingletonHuoDongExpManager::instance().GetHuoDongExp(23,pUser->GetLevel(),0.01);
	//	pUser->AddExp(addExp);
	//	snprintf(buf,sizeof(buf),"获得经验%lld",addExp);
	//	SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());	

	if(pUser->GetPlantWateringCount() <= WATER_TIMES_LIMIT_GAIN)
	{
		SingletonCBangPaiManager::instance().AddBangGong(pUser,BANG_GONG_WATERING);
	}
	UpdateTaskInfo(pUser,EBTT_Watering);
	pUser->UpdateBangHuoYue(EBHT_Watering);
*/
}

void CBangPai::KillPlantBug(CUser *pUser,uint8 plantIdx,uint8 cellPos)
{
/*
	if(pUser == NULL)
		return;
	const int qualityRatio[ZZQT_NUM] = {20,64,93,98,100,100,100,100};
	const double gainRatio[ZZQT_NUM] = { 1.0, 1.04, 1.1, 1.2, 1.25,1.25,1.25,1.25 };
	uint8 op = 5;
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_BANGPAI_ZHONGZHI);
	msg<<op<<m_id;

	if(pUser->GetPlantKillBugCount() >= PLANT_ROLE_KILLBUG_NUM_LIMIT)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_305,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}

	char buf[256];
	SPlantSeed *pTmpSeed = NULL;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if(plantIdx >= m_plantData.size() || cellPos >= m_plantData[plantIdx].size())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_306,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}
		SPlant &cell = m_plantData[plantIdx][cellPos];
		if(cell.itemId == 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_307,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}
		if((cell.state & EZZSKillingBug) == 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_308,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}

		if((pTmpSeed = SingletonCPlantSeedManager::instance().FindSeed(cell.itemId)) == NULL)
			return;
		uint32 curTime = (uint32)GetSysTime();
		if(curTime < cell.killBugTime)
			return;
		if(curTime - cell.killBugTime < pTmpSeed->killBugTimeGap)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_309,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(cell.killBugCount >= pTmpSeed->killBugLimit)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_310,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}

		bool addQuality = false;
		cell.state &= (~EZZSKillingBug);
		cell.killBugTime = curTime;
		cell.killBugCount++;
		if(cell.quality < PLANT_MAX_QUALITY_LIMIT)
		{
			int r = Random(1,100);
			for(uint8 q=0;q < sizeof(qualityRatio)/sizeof(qualityRatio[0]);q++)
			{
				if(r <= qualityRatio[q])
				{
					if(q > cell.quality)
					{
						cell.quality = q;
						addQuality = true;
						if (cell.quality >= ZZQT_ORANGE)
						{
							snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_311,ROLE_NAME_COLOR,pUser->GetName(),
								ROLE_NAME_COLOR,m_name.c_str(),pTmpSeed->treeName.c_str(),TreeQualityColor[cell.quality],TreeColorName[cell.quality].c_str());
							SysInfoToAllUser(buf,true);
						}
						cell.gain = pTmpSeed->gainValue * gainRatio[cell.quality];
					}
					break;
				}
			}
		}
		pUser->AddPlantKillBugCount();
		msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_TRANSFORM_312,TIPS_WARNING_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		if(addQuality)
		{
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_313,pTmpSeed->treeName.c_str(),TreeColorName[cell.quality].c_str());
			SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
		}

		NoLockUpdateZZCell(plantIdx,cellPos);
	}

	string bangName = GetRoleBangPaiName(pUser->GetRoleId());
	if(bangName.size() == 0)
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_314,GGCT_GREEN,pUser->GetName(),GGCT_ORANGE,pTmpSeed->treeName.c_str());
	else
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_315,GGCT_GREEN,bangName.c_str(),GGCT_GREEN,pUser->GetName(),GGCT_ORANGE,pTmpSeed->treeName.c_str());
	SaveBangPaiLog(pUser,EBLT_KILL_BUG,buf);

	// 	int64 addExp = SingletonHuoDongExpManager::instance().GetHuoDongExp(23,pUser->GetLevel(),0.01);
	//	pUser->AddExp(addExp);
	//	snprintf(buf,sizeof(buf),"获得经验%lld",addExp);
	//	SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());

	if(pUser->GetPlantKillBugCount() <= KILLBUG_TIMES_LIMIT_GAIN)
	{
		SingletonCBangPaiManager::instance().AddBangGong(pUser,BANG_GONG_KILLBUG);
	}
	UpdateTaskInfo(pUser,EBTT_KillBug);
	pUser->UpdateBangHuoYue(EBHT_KillBug);
*/
}

void CBangPai::ClearUpPlant(CUser *pUser,uint8 plantIdx,uint8 cellPos)
{
/*
	if(pUser == NULL)
		return;
	uint8 op = 6;
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_BANGPAI_ZHONGZHI);
	msg<<op<<m_id;

	if(pUser->GetBangPai() == 0 || pUser->GetBangPai() != m_id)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_316,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}

	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		SBangPaiMember *pData = NolockGetMemberData(pUser->GetRoleId());
		if(pData == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_317,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}

		if(plantIdx >= m_plantData.size() || cellPos >= m_plantData[plantIdx].size())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_318,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}
		SPlant &cell = m_plantData[plantIdx][cellPos];
		if(cell.itemId == 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_319,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(cell.roleId != pUser->GetRoleId())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_320,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}
		if((cell.state & EZZSRipe) == EZZSRipe)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_321,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}
		cell.Clear();
		if(m_havePlantedNum > 0)
			m_havePlantedNum--;
		if(pData->plantNum > 0)
			pData->plantNum--;

		msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_TRANSFORM_322,TIPS_WARNING_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);

		NoLockUpdateZZCell(plantIdx,cellPos);
	}
*/
}

void CBangPai::GainPlant(CUser *pUser,uint8 plantIdx,uint8 cellPos)
{
/*
	if(pUser == NULL)
		return;
	uint8 op = 7;
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_BANGPAI_ZHONGZHI);
	msg<<op<<m_id;

	if(pUser->GetBangPai() == 0 || pUser->GetBangPai() != m_id)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_323,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}

	SPlantSeed *pTmpSeed = NULL;
	uint32 awardValue = 0;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		SBangPaiMember *pData = NolockGetMemberData(pUser->GetRoleId());
		if(pData == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_324,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}
		SPlant &cell = m_plantData[plantIdx][cellPos];
		if(cell.itemId == 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_326,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(cell.roleId != pUser->GetRoleId())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_327,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}
		if((cell.state & EZZSRipe) == 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_328,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}
		if((pTmpSeed = SingletonCPlantSeedManager::instance().FindSeed(cell.itemId)) == NULL)
			return;
		awardValue = cell.gain;

		cell.Clear();
		if(m_havePlantedNum > 0)
			m_havePlantedNum--;
		if(pData->plantNum > 0)
			pData->plantNum--;
		NoLockUpdateZZCell(plantIdx,cellPos);
	}
	int addValue = sCBPLianQiCfgMgr.GetValue(m_lianqi_vec[0],1);
	if(addValue > 0)
	{
		awardValue = awardValue*(100+addValue)/100;
	}

	char buf[256];
	if(pTmpSeed->gainType == ZZGain_Money)
	{
		pUser->AddMoney(awardValue);
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_329,awardValue);
	}
	else if(pTmpSeed->gainType == ZZGain_YB)
	{
		pUser->AddTongBao(awardValue,1);
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_330,awardValue);
	}
	else if(pTmpSeed->gainType == ZZGain_Item)
	{
		if(pTmpSeed->gainItemId == 0 || awardValue == 0)
			return;
		pUser->AddBangDingPackage(pTmpSeed->gainItemId,awardValue);
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_331,GetItemName(pTmpSeed->gainItemId),awardValue);
	}
	else if(pTmpSeed->gainType == ZZGain_EXP)
	{
		int exp = pUser->AddExp(awardValue);
		int worldExpPer = GetWorldExpPercent(pUser->GetLevel());
		if (worldExpPer > 0)
		{
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_332,exp, worldExpPer);
		}
		else
		{
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_333,exp);
		}
	}
	else
		return;
	msg<<PRO_SUCCESS<<MakeStringColor(buf,TIPS_WARNING_COLOR);
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);

	//	int64 addExp = SingletonHuoDongExpManager::instance().GetHuoDongExp(23,pUser->GetLevel(),0.025);
	//	pUser->AddExp(addExp);
	//	snprintf(buf,sizeof(buf),"获得经验%lld",addExp);
	//	SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());

	if(pUser->GetExtData8(642) < GAIN_TIMES_LIMIT_GAIN)
	{
		pUser->SetExtData8(642,pUser->GetExtData8(642)+1);
		SingletonCBangPaiManager::instance().AddBangGong(pUser,BANG_GONG_GAIN);
	}
*/
}

void CBangPai::StealPlant(CUser *pUser,uint8 plantIdx,uint8 cellPos)
{
/*
	if(pUser == NULL)
		return;
	CScene *pScene = pUser->GetScene();
	if(pScene == NULL)
		return;

	uint8 op = 8;
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_BANGPAI_ZHONGZHI);
	msg<<op<<m_id;

	if(pUser->GetTeam() != 0)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_334,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}
	if(pUser->GetKuaFuState() != EKFS_IN_LOCAL)
		return;
	if(pUser->GetFightId() != 0)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_335,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}
	if(pUser->GetBangPai() == m_id)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_336,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}
	if(pUser->GetPlantStealCount() >= PLANT_ROLE_STEAL_NUM_LIMIT)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_337,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}

	bool isFight = false;
	uint32 stealValue = 0;
	do
	{
		{
			boost::recursive_mutex::scoped_lock lk(m_mutex);
			if(plantIdx >= m_plantData.size() || cellPos >= m_plantData[plantIdx].size())
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_338,TIPS_FAILURE_COLOR);
				SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
				return;
			}
			SPlant &cell = m_plantData[plantIdx][cellPos];
			if(cell.itemId == 0)
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_339,TIPS_FAILURE_COLOR);
				SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
				return;
			}
			if(cell.roleId == pUser->GetRoleId())
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_340,TIPS_FAILURE_COLOR);
				SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
				return;
			}
			if((cell.state & EZZSRipe) == 0)
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_341,TIPS_FAILURE_COLOR);
				SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
				return;
			}
			for(uint8 i=0;i < cell.thiefList.size();i++)
			{
				if(cell.thiefList[i] == pUser->GetRoleId())
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_342,TIPS_FAILURE_COLOR);
					SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
					return;
				}
			}

			SPlantSeed *pTmpSeed = SingletonCPlantSeedManager::instance().FindSeed(cell.itemId);
			if(pTmpSeed == NULL)
				return;
			if(cell.stealNum >= pTmpSeed->stealNumLimit)
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_343,TIPS_FAILURE_COLOR);
				SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
				return;
			}

			// 偷窃次数先+1，如果战斗失败则次数-1
			cell.stealNum++;
			// 战斗判定
			if(plantIdx < sizeof(m_guard)/sizeof(m_guard[0]))
			{
				if(m_guard[plantIdx].get() != NULL)	// 有守卫
				{
					int hour = GetHour();
					int fightRatio = 30;
					if(hour < 9 || hour >= 22)
						fightRatio = 60;
					if(Random(1,100) <= fightRatio)	// 触发战斗
					{
						isFight = true;
						NoLockUpdateZZCell(plantIdx,cellPos);
						break;
					}
				}
			}
			NolockSetStealData(pUser,plantIdx,cellPos,stealValue);

			// 空字符串，为了统一解析
			msg<<PRO_SUCCESS<<"";
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			NoLockUpdateZZCell(plantIdx,cellPos);
		}

		AddStealAward(pUser,plantIdx,cellPos,stealValue);
		return;
	}while(0);

	// 守卫战斗
	if(isFight)
	{
		ShareUserPtr ptrGuard = m_guard[plantIdx];
		ShareUserPtr ptrUser = SingletonOnlineUser::instance().GetUserByRoleId(pUser->GetRoleId());
		ShareFightPtr pFight = SingletonFightManager::instance().CreateFight();
		if(ptrGuard.get() == NULL || ptrUser.get() == NULL || pFight.get() == NULL)
			return;
		pFight->SetFightType(CFight::EFTBangPaiGuard);
		pFight->SetFightChooseMode();
		pScene->AddUserGroupToBattle(pFight,ptrUser,0);
		pScene->AddUserGroupToBattle(pFight,ptrGuard);

		pFight->AddCacheData(m_id);
		pFight->AddCacheData(plantIdx);
		pFight->AddCacheData(cellPos);
		pFight->BeginFight(pScene);
		SingletonFightManager::instance().AddFight(pFight);
	}
*/
}

void CBangPai::StealFightEnd(CUser *pUser,uint8 plantIdx,uint8 cellPos,bool win)
{
/*
	if(pUser == NULL)
		return;

	uint32 stealValue = 0;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if(plantIdx >= m_plantData.size() || cellPos >= m_plantData[plantIdx].size())
			return;
		SPlant &cell = m_plantData[plantIdx][cellPos];
		if(win)
			NolockSetStealData(pUser,plantIdx,cellPos,stealValue);
		else
			cell.stealNum--;
		NoLockUpdateZZCell(plantIdx,cellPos);
	}

	if(stealValue == 0)	// 失败
	{
		int sId = EXIT_FB_SCENE_ID;
		int posX = EXIT_FB_SCENE_X;
		int posY = EXIT_FB_SCENE_Y;
		pUser->GetEnterPos(sId,posX,posY);
		TransportUser(pUser,sId,posX,posY,0);
		SendSysInfoFightEnd(pUser,MakeStringColor(LANGUAGE_TRANSFORM_344,TIPS_FAILURE_COLOR).c_str());
	}
	else	// 成功
	{
		AddStealAward(pUser,plantIdx,cellPos,stealValue,true);
	}
*/
}

void CBangPai::NolockSetStealData(CUser *pUser,uint8 plantIdx,uint8 cellPos,uint32 &stealValue)
{
	const double gainRatio[ZZQT_NUM] = { 1.0, 1.04, 1.1, 1.2, 1.25,1.0,1.0,1.0 };
	if(pUser == NULL)
		return;
	if(plantIdx >= m_plantData.size() || cellPos >= m_plantData[plantIdx].size())
		return;
	SPlant &cell = m_plantData[plantIdx][cellPos];
	SPlantSeed *pTmpSeed = SingletonCPlantSeedManager::instance().FindSeed(cell.itemId);
	if(pTmpSeed == NULL)
		return;
	cell.thiefList.push_back(pUser->GetRoleId());
	pUser->AddPlantStealCount();
	stealValue = (uint32)(pTmpSeed->gainValue * gainRatio[cell.quality] * STEAL_PLANT_PERCENT / 100.0);
	if(cell.gain > stealValue)
		cell.gain -= stealValue;
	UpdateTaskInfo(pUser,EBTT_Steal);
	pUser->UpdateBangHuoYue(EBHT_Steal);
}

void CBangPai::AddStealAward(CUser *pUser,uint8 plantIdx,uint8 cellPos,uint32 stealValue,bool fightEnd)
{
/*
	SPlantSeed *pTmpSeed = NULL;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if(plantIdx >= m_plantData.size() || cellPos >= m_plantData[plantIdx].size() || stealValue == 0)
			return;
		if((pTmpSeed = SingletonCPlantSeedManager::instance().FindSeed(m_plantData[plantIdx][cellPos].itemId)) == NULL)
			return;
	}

	char buf[256];
	char tmp[256];
	SPlant &seed = m_plantData[plantIdx][cellPos];

	if(seed.quality >= ZZQT_PURPLE)
	{
		string bangName = GetRoleBangPaiName(pUser->GetRoleId());
		if(bangName.size() == 0)
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_345,ROLE_NAME_COLOR,pUser->GetName(),BANG_NAME_COLOR,GetName().c_str(),ITEM_NAME_COLOR,pTmpSeed->treeName.c_str());
		else
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_346,BANG_NAME_COLOR,bangName.c_str(),ROLE_NAME_COLOR,pUser->GetName(),BANG_NAME_COLOR,GetName().c_str(),ITEM_NAME_COLOR,pTmpSeed->treeName.c_str());
		SaveBangPaiLog(pUser,EBLT_STEAL_PLANT,buf);
	}
	if(seed.quality >= ZZQT_PURPLE && Random(1,100) <= 80)
	{
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_347,ROLE_NAME_COLOR,pUser->GetName(),BANG_NAME_COLOR,GetName().c_str(),TreeQualityColor[seed.quality],pTmpSeed->treeName.c_str());
		SysInfoToAllUser(buf,true);
	}

	if(pTmpSeed->gainType == ZZGain_Money)
	{
		pUser->AddMoney(stealValue);
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_348,stealValue);
		snprintf(tmp,sizeof(tmp),LANGUAGE_SSJ_1006,seed.roleId,pTmpSeed->treeName.c_str(),LANGUAGE_LLD_0106,(int)stealValue);
		SaveDate(pUser->GetRoleId(),719,ZZGain_Money,tmp);
	}
	else if(pTmpSeed->gainType == ZZGain_YB)
	{
		pUser->AddTongBao(stealValue,1);
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_349,stealValue);
		snprintf(tmp,sizeof(tmp),LANGUAGE_SSJ_1006,seed.roleId,pTmpSeed->treeName.c_str(),LANGUAGE_LLD_0107,(int)stealValue);
		SaveDate(pUser->GetRoleId(),719,ZZGain_YB,tmp);
	}
	else if(pTmpSeed->gainType == ZZGain_Item)
	{
		if(pTmpSeed->itemId == 0 || stealValue == 0)
			return;
		pUser->AddBangDingPackage(pTmpSeed->gainItemId,stealValue);
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_350,GetItemName(pTmpSeed->gainItemId),stealValue);
		snprintf(tmp,sizeof(tmp),LANGUAGE_SSJ_1006,seed.roleId,pTmpSeed->treeName.c_str(),GetItemName(pTmpSeed->gainItemId),(int)stealValue);
		SaveDate(pUser->GetRoleId(),719,ZZGain_Item,tmp);
	}
	else if(pTmpSeed->gainType == ZZGain_EXP)
	{
		int exp = pUser->AddExp(stealValue);
		int worldExpPer = GetWorldExpPercent(pUser->GetLevel());
		if (worldExpPer > 0)
		{
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_351,exp, worldExpPer);
		}
		else
		{
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_352,exp);
		}

		snprintf(tmp,sizeof(tmp),LANGUAGE_SSJ_1006,seed.roleId,pTmpSeed->treeName.c_str(),LANGUAGE_SSJ_1007,exp);
		SaveDate(pUser->GetRoleId(),719,ZZGain_EXP,tmp);
	}
	else
		return;

	if(fightEnd)
		SendSysInfoFightEnd(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
	else
		SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());

	//	int64 addExp = SingletonHuoDongExpManager::instance().GetHuoDongExp(23,pUser->GetLevel(),0.01);
	//	pUser->AddExp(addExp);
	//	snprintf(buf,sizeof(buf),"获得经验%lld",addExp);
	//	SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());

	if(pUser->GetPlantStealCount() <= STEAL_TIMES_LIMIT_GAIN)
	{
		SingletonCBangPaiManager::instance().AddBangGong(pUser,BANG_GONG_STEAL);
	}

	pUser->SetBangPaiStealTime();
	CScene *pScene = pUser->GetScene();
	if(pScene != NULL)
		pScene->UpdateUserInfo(pUser,ESRT_State);
*/
}

void CBangPai::SetGuard(CUser *pUser,uint8 guardIdx)
{
/*
	if(pUser == NULL || guardIdx >= sizeof(m_guard)/sizeof(m_guard[0]))
		return;
	uint8 op = 9;
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_BANGPAI_ZHONGZHI);
	msg<<op<<m_id;

	if(pUser->GetBangPai() == 0)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_353,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}
	if(pUser->GetBangPai() != m_id)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_354,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	SBangPaiMember *pData = NolockGetMemberData(pUser->GetRoleId());
	if(pData == NULL || pData->rank != EBRHuFa)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_355,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}
	if(m_guard[guardIdx].get() != NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_356,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}
	if(m_plantData[guardIdx].size() == 0)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_357,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}
	for(uint8 i=0;i < sizeof(m_guard)/sizeof(m_guard[0]);i++)
	{
		if(i == guardIdx)
			continue;
		if(m_guard[i].get() == NULL)
			continue;
		if(m_guard[i]->GetRoleId() == pUser->GetRoleId())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_358,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}
	}

	CUser *pGuard = new CUser();
	pGuard->CopyOnlineUserData(pUser);
	ShareUserPtr ptr(pGuard);
	m_guard[guardIdx] = ptr;

	msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_TRANSFORM_359,TIPS_WARNING_COLOR);
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);

	NolockUpdateGuard(guardIdx);
*/
}

void CBangPai::RemoveGuard(CUser *pUser,uint8 guardIdx)
{
/*
	if(pUser == NULL || guardIdx >= sizeof(m_guard)/sizeof(m_guard[0]))
		return;
	uint8 op = 10;
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_BANGPAI_ZHONGZHI);
	msg<<op<<m_id;

	if(pUser->GetBangPai() == 0)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_360,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}
	if(pUser->GetBangPai() != m_id)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_361,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	SBangPaiMember *pData = NolockGetMemberData(pUser->GetRoleId());
	if(pData == NULL || (pData->rank != EBRHuFa && pData->rank != EBRBangZhu))
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_362,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}
	if(m_guard[guardIdx].get() == NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_363,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}
	if(pData->rank == EBRHuFa && m_guard[guardIdx]->GetRoleId() != pUser->GetRoleId())
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_364,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}
	else if(pData->rank == EBRBangZhu)
	{
		ShareUserPtr ptr = SingletonOnlineUser::instance().GetUserByRoleId(m_guard[guardIdx]->GetRoleId());
		if(ptr.get() != NULL)
			SendSysInfo(ptr.get(),MakeStringColor(LANGUAGE_TRANSFORM_365,TIPS_FAILURE_COLOR).c_str());
	}

	m_guard[guardIdx].reset();

	msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_TRANSFORM_366,TIPS_WARNING_COLOR);
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);

	NolockUpdateGuard(guardIdx);
*/
}

void CBangPai::RemoveGuardByRoleId(uint32 roleId)
{
/*
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint8 i=0;i < sizeof(m_guard)/sizeof(m_guard[0]);i++)
	{
		if(m_guard[i].get() != NULL && m_guard[i]->GetRoleId() == roleId)
		{
			m_guard[i].reset();
			NolockUpdateGuard(i);
		}
	}
*/
}

void CBangPai::NolockUpdateGuard(uint8 guardIdx)
{
/*
	if(guardIdx >= sizeof(m_guard)/sizeof(m_guard[0]))
		return;
	uint8 op = 22;
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_BANGPAI_ZHONGZHI);
	msg<<op<<m_id<<guardIdx;

	uint32 roleId = 0;
	CUser *pGuard = m_guard[guardIdx].get();
	if(pGuard == NULL)
		msg<<roleId;
	else
		msg<<pGuard->GetRoleId()<<pGuard->GetSex()<<pGuard->GetName()<<pGuard->GetLevel();

	CScene *pScene = SingletonSceneManager::instance().GetBangPaiScene(BANG_PAI_SCENE_ID,m_id);
	if(pScene != NULL)
	{
		list<uint32> userList;
		pScene->GetUserList(userList);
		COnlineUser &onlineUser = SingletonOnlineUser::instance();
		for(list<uint32>::iterator iter = userList.begin(); iter != userList.end(); iter++)
		{
			ShareUserPtr ptr = onlineUser.GetUserByRoleId(*iter);
			if(ptr.get() == NULL)
				continue;
			SingletonSocket::instance().SendMsg(ptr->GetSock(),msg);
		}
	}
*/
}

void CBangPai::QueryGuardMsg(CUser *pUser,uint8 guardIdx,uint8 type)
{
/*
	if(pUser == NULL || guardIdx >= sizeof(m_guard)/sizeof(m_guard[0]))
		return;
	uint8 op = 13;
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_BANGPAI_ZHONGZHI);
	msg<<op<<m_id<<guardIdx<<type;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	CUser *pTar = m_guard[guardIdx].get();
	if(pTar == NULL)
	{
		msg<<(uint32)0;
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}
	msg<<pTar->GetRoleId();
	if(type == 1)	// 普通信息
	{
		msg<<pTar->GetVipLevel()<<pTar->GetSex()<<pTar->GetName()<<pTar->GetLevel();
	}
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
*/
}

static void UpdateBangGong(CUser *pUser,int bangGong, int money,int huoyue,int memHuoyue)
{
	if(pUser == NULL)
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_MY_BANG);
	msg<<(uint8)2;
	msg<<pUser->GetBangPai()<<bangGong<< money<<huoyue<<memHuoyue;
	sock.SendMsg(pUser->GetSock(),msg);
}

void CBangPai::AddMemberBangGong(CUser *pUser,int banggong,bool showTips)
{
	if(pUser == NULL)
		return;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	SBangPaiMember *pData = NolockGetMemberData(pUser->GetRoleId());
	if(pData == NULL)
		return;
	pData->AddTotalBangGong(banggong);
	pUser->AddBangGong(banggong);

	char buf[64];
	if(banggong > 0)
	{
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_367,banggong);
		m_todayBangGong += (uint32)banggong;
	}
	else
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_368,banggong);
	if(showTips)
		SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
	UpdateBangGong(pUser,pUser->GetBangGong(), GetMoney(),GetHuoYue(),pUser->GetExtData16(67));
}

void CBangPai::LightFire(CUser *pUser)
{
	if(pUser == NULL)
		return;

	uint8 op = 15;
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_BANGPAI_ZHONGZHI);
	msg<<op<<m_id;

	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if(m_fireState != BPFire_OFF)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_369,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(pUser->GetBangPai() == m_id)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_370,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}

		m_fireState = BPFire_ON;
		m_onFireTime = (uint32)GetSysTime();
		msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_TRANSFORM_371,TIPS_WARNING_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		NolockUpdateFireState();
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_372,TIPS_WARNING_COLOR).c_str());
	}

	char buf[256];
	char gonggao[256];
	snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_373,pUser->GetName());
	string bangName = GetRoleBangPaiName(pUser->GetRoleId());
	if(bangName.size() == 0)
		snprintf(gonggao,sizeof(gonggao),LANGUAGE_TRANSFORM_374,ROLE_NAME_COLOR,pUser->GetName(),BANG_NAME_COLOR,GetName().c_str());
	else
		snprintf(gonggao,sizeof(gonggao),LANGUAGE_TRANSFORM_375,BANG_NAME_COLOR,bangName.c_str(),ROLE_NAME_COLOR,pUser->GetName(),BANG_NAME_COLOR,GetName().c_str());
	SysInfoToBangPai_Tips(m_id,MakeStringColor(buf,TIPS_FAILURE_COLOR).c_str());
	SysInfoToAllUser(gonggao,true);
	SaveBangPaiLog(pUser,EBLT_FIRE,buf);
	pUser->SetBangPaiFireTime();
	pUser->SetExtData8(582,pUser->GetExtData8(582) + 1);

	CScene *pScene = pUser->GetScene();
	if(pScene != NULL)
		pScene->UpdateUserInfo(pUser,ESRT_State);
}

void CBangPai::ExtinguishFire(CUser *pUser)
{
	if(pUser == NULL)
		return;

	uint8 op = 16;
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_BANGPAI_ZHONGZHI);
	msg<<op<<m_id;

	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if(m_fireState != BPFire_ON)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_376,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(pUser->GetBangPai() != m_id)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_377,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}

		m_fireState = BPFire_OFF;
		m_onFireTime = 0;
		msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_TRANSFORM_378,TIPS_WARNING_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);

		NolockUpdateFireState();
		pUser->SetExtData8(583,pUser->GetExtData8(583) + 1);
	}
}

uint8 CBangPai::GetTreeMaxRobbedNum()
{
	return 5;
}

void CBangPai::SendTreeMsg(CUser *pUser)
{
	if(pUser == NULL)
		return;

	const uint32 AddExpHourPerDay = 22;
	uint8 op = 18;
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_BANGPAI_ZHONGZHI);
	msg<<op<<m_id;

	uint8 YBPrayNum = 0;
	uint8 normalPrayNum = 0;
	if(pUser->GetBangPaiYBPrayNum() < BP_YB_PRAY_LIMIT)
		YBPrayNum = BP_YB_PRAY_LIMIT - pUser->GetBangPaiYBPrayNum();
	if(pUser->GetBangPaiNormalPrayNum() < BP_NORMAL_PRAY_LIMIT)
		normalPrayNum = BP_NORMAL_PRAY_LIMIT - pUser->GetBangPaiNormalPrayNum();
	uint32 leftTreeExp = GetTreeExp();
	uint32 totalTreeExp = AddTreeExpPerHour[m_level-1]*AddExpHourPerDay;
	msg<<leftTreeExp<<totalTreeExp<<GetPrayExp()<<GetTreeRobbedNum()<<GetTreeMaxRobbedNum()<<GetTreeRobbedExp()
		<<YBPrayNum<<normalPrayNum;
	uint16 useYB = GetYBPrayConsume(pUser->GetBangPaiYBPrayNum());
	msg<<useYB<<"22:00"<< GetBangPaiRobTime();

	uint8 prayNum = 0;
	uint16 pos = msg.GetDataLen();
	msg<<prayNum;
	for(list<SBangPaiLog>::iterator i = m_prayLog.begin(); i != m_prayLog.end(); i++)
	{
		if(i->time == 0 || i->log.size() == 0)
			continue;
		prayNum++;
		msg<<AddTimeBeforeString(i->time,i->log);
	}
	msg.WriteData(pos,&prayNum,sizeof(prayNum));
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

uint32 CBangPai::GetPrayAddExp(uint8 type)
{
	const uint32 PRAY_EXP[] = {400,440,480,520,560,600,640,680,720,760};
	if(type == 0 || m_level > sizeof(PRAY_EXP)/sizeof(PRAY_EXP[0]))
		return 0;
	return PRAY_EXP[m_level-1];
}

void CBangPai::SavePrayLog(CUser *pUser,uint8 prayType,string &log)
{
	if(pUser == NULL)
		return;
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
	char sql[512];
	char buf[256];
	uint32 curTime = GetSysTime();
	if(prayType == 1)	// 普通祈福
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_379,ROLE_NAME_COLOR,pUser->GetName());
	else			// 元宝祈福
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_380,ROLE_NAME_COLOR,pUser->GetName(),GGCT_RED);
	snprintf(sql,sizeof(sql),"insert into bang_pai_log (bang_id,role_id,type,msg,time) values(%u,%u,%d,'%s',%u)",m_id,pUser->GetRoleId(),EBLT_PRAY,buf,curTime);
	if(!pDb->Query(sql))
		return;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(m_prayLog.size() >= BP_PRAY_LOG_MAX_NUM)
	{
		list<SBangPaiLog>::iterator iter = m_prayLog.end();
		iter--;
		m_prayLog.erase(iter);
	}

	SBangPaiLog temp;
	temp.log = buf;
	temp.time = curTime;
	m_prayLog.push_front(temp);
	log = LANGUAGE_TRANSFORM_381;
	log += buf;
}

void CBangPai::SaveBangPaiLog(CUser *pUser,uint16 type,const char *str)
{
	if(str == NULL)
		return;
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
	char sql[512];
	char time_str[64];
	uint32 curTime = GetSysTime();
	snprintf(time_str,sizeof(time_str),"%d%2d",GetYear()+1900,GetMonth()+1);
	if(pUser != NULL)
		snprintf(sql,sizeof(sql),"insert into bang_pai_log (bang_id,role_id,type,msg,time,time_str) values(%u,%u,%d,'%s',%u,'%s')",m_id,pUser->GetRoleId(),(int)type,str,curTime,time_str);
	else
		snprintf(sql,sizeof(sql),"insert into bang_pai_log (bang_id,role_id,type,msg,time,time_str) values(%u,0,%d,'%s',%u,'%s')",m_id,(int)type,str,curTime,time_str);
	if(!pDb->Query(sql))
		return;

	CheckHotPoint(EHPoint_BP_Event);

	SBangPaiLog temp;
	temp.log = str;
	temp.time = curTime;
	temp.time_str = time_str;
	temp.type = type;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(m_optionLog.size() >= BP_OPTION_LOG_MAX_NUM)
		m_optionLog.pop_back();
	m_optionLog.push_front(temp);
}

int CBangPai::GetYBPrayConsume(int ybPrayIndex)
{
	const int PRAY_YB[] = {30,60,120,210,330,480,660,870,1110,1380};
	if(ybPrayIndex >= (int)(sizeof(PRAY_YB)/sizeof(PRAY_YB[0])))
		return 0;
	return PRAY_YB[ybPrayIndex];
}

void CBangPai::TreePray(CUser *pUser,uint8 type)
{
	if(pUser == NULL || type < 1 || type > 2)
		return;


	uint8 op = 19;
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_BANGPAI_ZHONGZHI);
	msg<<op<<m_id<<type;
	if(pUser->GetBangPai() != m_id)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_382,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}

	int addExp = GetPrayAddExp(type);
	char buf[128];
	if(type == 1)	// 普通祈福
	{
		if(pUser->GetBangPaiNormalPrayNum() >= BP_NORMAL_PRAY_LIMIT)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_383,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}
		else
		{
			SingletonCBangPaiManager::instance().AddBangGong(pUser,BANG_GONG_PRAY);
			pUser->AddBangPaiNormalPrayNum();
			AddPrayExp(addExp);
			AddExp(addExp);

			uint8 normalPrayNum = 0;
			if(pUser->GetBangPaiNormalPrayNum() < BP_NORMAL_PRAY_LIMIT)
				normalPrayNum = BP_NORMAL_PRAY_LIMIT - pUser->GetBangPaiNormalPrayNum();
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_384,addExp);
			msg<<PRO_SUCCESS<<normalPrayNum<<MakeStringColor(buf,TIPS_WARNING_COLOR);
			SingletonCMissionManager::instance().UpdateDCMissionComplate(pUser, EMISS_DC_56);
			UpdateHuoYue(pUser,EBHT_Pray);
		}
	}
	else	// 元宝祈福
	{
		int YBPrayNum = pUser->GetBangPaiYBPrayNum();
		int useYb = GetYBPrayConsume(YBPrayNum);
		if(pUser->GetTongBao() < useYb)
		{
			msg<<PRO_ERROR<<"";
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			ShowJumpNotice(pUser,JUMP_NOTICE_YB);
			return;
		}
		if(pUser->GetBangPaiYBPrayNum() >= BP_YB_PRAY_LIMIT)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_385,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}
		else
		{
			SingletonCBangPaiManager::instance().AddBangGong(pUser,BANG_GONG_PRAY);
			pUser->AddBangPaiYBPrayNum();
			pUser->AddTongBao(-useYb);
			AddPrayExp(addExp);
			AddExp(addExp);
			ItemCurrencyLog(pUser->GetRoleId(),0,0,0,useYb,pUser->GetTongBao(),YBL_QI_FU);

			uint8 YBPrayNum = 0;
			if(pUser->GetBangPaiYBPrayNum() < BP_YB_PRAY_LIMIT)
				YBPrayNum = BP_YB_PRAY_LIMIT - pUser->GetBangPaiYBPrayNum();
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_386,addExp);
			msg<<PRO_SUCCESS<<YBPrayNum;
			uint16 useYB = GetYBPrayConsume(pUser->GetBangPaiYBPrayNum());
			msg<<useYB<<MakeStringColor(buf,TIPS_WARNING_COLOR);
			SingletonCMissionManager::instance().UpdateDCMissionComplate(pUser, EMISS_DC_57);
			UpdateHuoYue(pUser,EBHT_TongBaoPray);
		}
	}
	string log;
	SavePrayLog(pUser,type,log);
	AddPrayNum();
	msg<<log<<GetPrayExp();
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

bool CBangPai::IsInRobTime()
{
	return CSceneManager::IsInActivityTime(SOT_BangPaiLueDuo);
}

void CBangPai::QueryTreeRobState(CUser *pUser)
{
	if(pUser == NULL)
		return;
	uint8 op = 20;
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_BANGPAI_ZHONGZHI);
	msg<<op<<m_id;

	if(pUser->GetBangPai() == m_id || pUser->GetBangPai() == 0)
		return;
	if(!IsInRobTime())
	{
		msg<<PRO_ERROR;
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}
	if(pUser->GetKuaFuState() != EKFS_IN_LOCAL)
		return;
	if(pUser->GetFightId() > 0)
	{
		msg<<PRO_ERROR;
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}

	msg<<PRO_SUCCESS;
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void CBangPai::RobTree(CUser *pUser)
{
	if(pUser == NULL)
		return;
	uint8 op = 21;
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_BANGPAI_ZHONGZHI);
	msg<<op<<m_id;

	if(pUser->GetBangPai() == m_id)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_387,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}
	else if(pUser->GetBangPai() == 0)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_388,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}
	if(!IsInRobTime())
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_389,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}
	if(pUser->GetKuaFuState() != EKFS_IN_LOCAL)
		return;
	if(pUser->GetFightId() > 0)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_390,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}

	int robExp = GetTreeCanRobbedExp();
	if(robExp == 0)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_391,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}
	AddTreeRobbedNum(1);
	AddTreeExpWithRobbedExp(-robExp);
	SingletonCBangPaiManager::instance().AddRobTreeExp(pUser,robExp);
	pUser->AddBangPaiRobNum();
	SaveDate(pUser, 29, 1);
	char buf[256];
	snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_392,robExp);
	msg<<PRO_SUCCESS<<MakeStringColor(buf,TIPS_WARNING_COLOR);
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);

	string bangName = GetRoleBangPaiName(pUser->GetRoleId());
	if(bangName.size() == 0)
		return;
	snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_393,GGCT_RED,bangName.c_str(),GGCT_RED,pUser->GetName(),GGCT_RED);
	SaveBangPaiLog(pUser,EBLT_STEAL_TREE,buf);

	snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_394,ROLE_NAME_COLOR,pUser->GetName(),ROLE_NAME_COLOR,GetName().c_str());
	SysInfoToAllUser(buf,true);

	if(pUser->GetBangPaiRobNum() <= ROB_TREE_TIMES_LIMIT_GAIN)
	{
		SingletonCBangPaiManager::instance().AddBangGong(pUser,BANG_GONG_ROB_TREE);
	}
	SingletonCHDExchangeManager::instance().DropExchangeItem(pUser,EEHDT_BP_LueDuo);
	SingletonCHDExchangeManager::instance().DropHDItem(pUser,EEHDT_BP_LueDuo);

}

void CBangPai::GetTaskList(CUser *pUser)
{
	if(pUser == NULL)
		return;
	CNetMessage msg;
	msg.SetType(MSG_BANGPAI_ZHONGZHI);
	msg<<(uint8)23;

	char buf[128];
	uint16 pos = msg.GetDataLen();
	uint8 num = 0;
	msg<<num;
	for(uint8 i=0;i < sizeof(TaskType)/sizeof(TaskType[0]);i++)
	{
		bool haveGetReward = pUser->HaveGetBangPaiTaskReward(TaskType[i]);
		if(haveGetReward)
			continue;
		int exp = SingletonHuoDongExpManager::instance().GetHuoDongExp(23,pUser->GetLevel(),TaskExpPercent[i]);
		snprintf(buf,sizeof(buf),TaskReward[i],exp);
		msg<<TaskType[i]<<buf<<TaskCompleteNum[i];

		uint8 curNum = 0;
		if(TaskType[i] == EBTT_ZhongZhi)
			curNum = pUser->GetPlantPlantsCount();
		else if(TaskType[i] == EBTT_Watering)
			curNum = pUser->GetPlantWateringCount();
		else if(TaskType[i] == EBTT_KillBug)
			curNum = pUser->GetPlantKillBugCount();
		else if(TaskType[i] == EBTT_Steal)
			curNum = pUser->GetPlantStealCount();
		else if(TaskType[i] == EBTT_KillPlayer)
			curNum = pUser->GetKillPlayerCount();
		else
			continue;
		if(curNum > TaskCompleteNum[i])
			curNum = TaskCompleteNum[i];
		msg<<curNum<<(uint8)haveGetReward;
		num++;
	}
	msg.WriteData(pos,&num,sizeof(num));
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void CBangPai::GetTaskReward(CUser *pUser,uint8 type)
{
	if(pUser == NULL)
		return;

	uint8 taskIndex = 0xff;
	for(uint8 i=0;i < sizeof(TaskType)/sizeof(TaskType[0]);i++)
	{
		if(TaskType[i] == type)
		{
			taskIndex = i;
			break;
		}
	}
	if(taskIndex == 0xff)
		return;

	CNetMessage msg;
	msg.SetType(MSG_BANGPAI_ZHONGZHI);
	msg<<(uint8)24<<type;
	bool haveGetReward = pUser->HaveGetBangPaiTaskReward(TaskType[taskIndex]);
	if(haveGetReward)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_395,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}

	uint8 curNum = 0;
	int64 addExp = 0;
	if(TaskType[taskIndex] == EBTT_ZhongZhi)
	{
		curNum = pUser->GetPlantPlantsCount();
		addExp = SingletonHuoDongExpManager::instance().GetHuoDongExp(23,pUser->GetLevel(),TaskExpPercent[TaskType[taskIndex]-1]);
	}
	else if(TaskType[taskIndex] == EBTT_Watering)
	{
		curNum = pUser->GetPlantWateringCount();
		addExp = SingletonHuoDongExpManager::instance().GetHuoDongExp(23,pUser->GetLevel(),TaskExpPercent[TaskType[taskIndex]-1]);
	}
	else if(TaskType[taskIndex] == EBTT_KillBug)
	{
		curNum = pUser->GetPlantKillBugCount();
		addExp = SingletonHuoDongExpManager::instance().GetHuoDongExp(23,pUser->GetLevel(),TaskExpPercent[TaskType[taskIndex]-1]);
	}
	else if(TaskType[taskIndex] == EBTT_Steal)
	{
		curNum = pUser->GetPlantStealCount();
		addExp = SingletonHuoDongExpManager::instance().GetHuoDongExp(23,pUser->GetLevel(),TaskExpPercent[TaskType[taskIndex]-1]);
	}
	else if(TaskType[taskIndex] == EBTT_KillPlayer)
	{
		curNum = pUser->GetKillPlayerCount();
		addExp = SingletonHuoDongExpManager::instance().GetHuoDongExp(23,pUser->GetLevel(),TaskExpPercent[TaskType[taskIndex]-1]);
	}
	else
		return;

	if(curNum < TaskCompleteNum[taskIndex])
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_396,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}

	pUser->SetBangPaiTaskReward(TaskType[taskIndex]);

	char buf[512];
	int64 exp = pUser->AddExp(addExp);
	int worldExpPer = GetWorldExpPercent(pUser->GetLevel());
	if (worldExpPer > 0)
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_397,exp,worldExpPer);
	else
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_398,exp);
	msg<<PRO_SUCCESS<<MakeStringColor(buf,TIPS_WARNING_COLOR);
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void CBangPai::UpdateTaskInfo(CUser *pUser,uint8 type)
{
	uint8 curNum = 0;
	if(type == EBTT_ZhongZhi)
	{
		curNum = pUser->GetPlantPlantsCount();
		if(curNum >= TaskCompleteNum[2])
			curNum = TaskCompleteNum[2];
	}
	else if(type == EBTT_Watering)
	{
		curNum = pUser->GetPlantWateringCount();
		if(curNum >= TaskCompleteNum[0])
			curNum = TaskCompleteNum[0];
	}
	else if(type == EBTT_KillBug)
	{
		curNum = pUser->GetPlantKillBugCount();
		if(curNum >= TaskCompleteNum[1])
			curNum = TaskCompleteNum[1];
	}
	else if(type == EBTT_Steal)
	{
		curNum = pUser->GetPlantStealCount();
		if(curNum >= TaskCompleteNum[3])
			curNum = TaskCompleteNum[3];
	}
	else if(type == EBTT_KillPlayer)
	{
		curNum = pUser->GetKillPlayerCount();
		if(curNum >= TaskCompleteNum[4])
			curNum = TaskCompleteNum[4];
	}
	else
		return;

	bool haveGetReward = pUser->HaveGetBangPaiTaskReward(type);
	CNetMessage msg;
	msg.SetType(MSG_BANGPAI_ZHONGZHI);
	msg<<(uint8)25<<type<<curNum<<(uint8)haveGetReward;
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void CBangPai::NolockUpdateFireState()
{
	CNetMessage msg;
	msg.SetType(MSG_BANGPAI_ZHONGZHI);
	msg<<(uint8)17<<m_id<<m_fireState;

	CScene *pScene = SingletonSceneManager::instance().GetBangPaiScene(BANG_PAI_SCENE_ID,m_id);
	if(pScene != NULL)
	{
		list<uint32> userList;
		pScene->GetUserList(userList);
		COnlineUser &onlineUser = SingletonOnlineUser::instance();
		for(list<uint32>::iterator iter = userList.begin(); iter != userList.end(); iter++)
		{
			ShareUserPtr ptr = onlineUser.GetUserByRoleId(*iter);
			if(ptr.get() == NULL)
				continue;
			SingletonSocket::instance().SendMsg(ptr->GetSock(),msg);
		}
	}
}

bool CBangPai::GetZhongZhiInfo(uint32 idx,uint32 pos,SPlant &zz)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(idx >= m_plantData.size() || pos >= m_plantData[idx].size())
		return false;
	zz = m_plantData[idx][pos];
	return true;
}

void CBangPai::MakeZZMsg(CUser *pUser,CNetMessage &msg)
{
	msg.ReWrite();
	msg.SetType(MSG_BANGPAI_ZHONGZHI);

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	uint8 op = 1;
	msg<<op<<pUser->GetBangPai()<<m_id<<m_name<<m_level<<(uint8)m_plantData.size();
	for(uint8 i = 0; i < m_plantData.size(); i++)
	{
		msg<<(uint8)i<<(uint8)BP_AREA_MAX_NUM_LIMIT[i]<<(uint8)m_plantData[i].size();
		msg<<(uint8)m_plantAreaLv[i]<<GetPlantAreaOpenLevel(i);
		msg<<(uint8)(IsSpecialPlantArea(i) ? 1 : 0);

		uint16 pos = msg.GetDataLen();
		uint8 num = 0;
		msg<<num;
		for(uint8 j=0;j < m_plantData[i].size(); j++)
		{
			if(m_plantData[i][j].itemId != 0)
			{
				num++;
				msg<<(uint8)j<<m_plantData[i][j].itemId;
			}
		}
		msg.WriteData(pos,&num,sizeof(num));
	}

	// 神树信息
	msg<<m_treeLv;
	// 魔火状态
	msg<<m_fireState;
	// 守卫
	uint8 guardNum = sizeof(m_guard)/sizeof(m_guard[0]);
	msg<<guardNum;
	for(uint8 i=0;i < guardNum;i++)
	{
		uint32 roleId = 0;
		if(m_guard[i].get() == NULL)
			msg<<roleId;
		else
			msg<<m_guard[i]->GetRoleId()<<m_guard[i]->GetSex()<<m_guard[i]->GetName()<<m_guard[i]->GetLevel();
	}
}

uint8 CBangPai::GetPlantCanStealNumByRole(CUser *pUser,SPlant &seed)
{
	if(pUser == NULL)
		return 0;
	uint8 canStealNum = 0;

	SPlantSeed *pTmpSeed = SingletonCPlantSeedManager::instance().FindSeed(seed.itemId);
	if(pTmpSeed == NULL)
		return 0;
	if(pUser->GetBangPai() == m_id)
		return 0;
	if(seed.state != EZZSRipe)
		return 0;
	if(seed.stealNum < pTmpSeed->stealNumLimit && pUser->GetPlantStealCount() < PLANT_ROLE_STEAL_NUM_LIMIT)
	{
		bool inThiefList = false;
		for(uint8 i=0;i < seed.thiefList.size();i++)
		{
			if(seed.thiefList[i] == pUser->GetRoleId())
			{
				inThiefList = true;
				break;
			}
		}
		if(!inThiefList)
			canStealNum = 1;	// 每棵植物只可抢夺一次
	}
	return canStealNum;
}

void CBangPai::GetPlantMsgByPosition(CUser *pUser,uint8 plantedIdx,uint8 cellPos,CNetMessage &msg)
{
	if(pUser == NULL)
		return;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(plantedIdx >= BP_AREA_MAX_NUM || (cellPos != 0xff && cellPos >= m_plantData[plantedIdx].size()))
		return;

	uint8 op = 2;
	msg.ReWrite();
	msg.SetType(MSG_BANGPAI_ZHONGZHI);
	msg<<op<<m_id<<plantedIdx;
	uint8 num = 0;
	uint16 msgPos = msg.GetDataLen();
	msg<<num;
	if(cellPos == 0xff)	// 整块地请求
	{
		for(uint8 i=0;i < m_plantData[plantedIdx].size();i++)
		{
			SPlant &seed = m_plantData[plantedIdx][i];
			if(seed.itemId != 0)
			{
				NolockMakePlantCellMsg(plantedIdx,i,msg);
				msg<<GetPlantCanStealNumByRole(pUser,seed);
				num++;
			}
		}
	}
	else	// 单个请求
	{
		SPlant &seed = m_plantData[plantedIdx][cellPos];
		if(seed.itemId != 0)
		{
			NolockMakePlantCellMsg(plantedIdx,cellPos,msg);
			msg<<GetPlantCanStealNumByRole(pUser,seed);
			num++;
		}
	}
	msg.WriteData(msgPos,&num,sizeof(num));
}

bool CBangPai::NolockMakePlantCellMsg(uint8 plantedIdx,uint8 cellPos,CNetMessage &msg)
{
	if(plantedIdx >= BP_AREA_MAX_NUM || cellPos >= m_plantData[plantedIdx].size()) 
		return false;
	msg<<cellPos;
	uint32 curTime = GetSysTime();
	SPlant &seed = m_plantData[plantedIdx][cellPos];
	msg<<seed.itemId;
	if(seed.itemId != 0)
	{
		SPlantSeed *pTmpSeed = SingletonCPlantSeedManager::instance().FindSeed(seed.itemId);
		if(pTmpSeed == NULL)
			return false;
		uint32 ripeTime = 0;
		if(seed.ripeTime > curTime)
			ripeTime = seed.ripeTime - curTime;
		uint32 totalTime = seed.ripeTime - seed.time;
		msg<<seed.roleId<<seed.roleName<<seed.quality<<seed.state<<seed.stealNum<<pTmpSeed->stealNumLimit;
		msg<<ripeTime<<totalTime<<pTmpSeed->treeName<<seed.pic<<pTmpSeed->gainType<<(uint16)pTmpSeed->gainItemId<<seed.gain;
		return true;
	}
	return false;
}

void CBangPai::NoLockUpdateZZCell(uint8 plantedIdx,uint8 cellPos)
{
	if(plantedIdx >= BP_AREA_MAX_NUM || cellPos >= m_plantData[plantedIdx].size()) 
		return;
	SPlant &seed = m_plantData[plantedIdx][cellPos];
	CNetMessage msg;
	msg.SetType(MSG_BANGPAI_ZHONGZHI);
	msg<<(uint8)11<<m_id<<plantedIdx<<cellPos<<seed.itemId;
	if(seed.itemId > 0)
	{
		uint32 ripeTime = 0;
		if(seed.ripeTime > (uint32)GetSysTime())
			ripeTime = seed.ripeTime - (uint32)GetSysTime();
		uint32 totalTime = seed.ripeTime - seed.time;
		msg<<seed.state<<seed.quality<<seed.pic<<ripeTime<<totalTime<<seed.stealNum<<seed.gain;
	}
	uint16 pos = msg.GetDataLen();
	uint8 myCanStealNum = 0;
	msg<<myCanStealNum;

	CScene *pScene = SingletonSceneManager::instance().GetBangPaiScene(BANG_PAI_SCENE_ID,m_id);
	if(pScene != NULL)
	{
		list<uint32> userList;
		pScene->GetUserList(userList);
		COnlineUser &onlineUser = SingletonOnlineUser::instance();
		for(list<uint32>::iterator iter = userList.begin(); iter != userList.end(); iter++)
		{
			ShareUserPtr ptr = onlineUser.GetUserByRoleId(*iter);
			if(ptr.get() == NULL)
				continue;
			if(seed.itemId > 0)
			{
				myCanStealNum = GetPlantCanStealNumByRole(ptr.get(),seed);
				msg.WriteData(pos,&myCanStealNum,sizeof(myCanStealNum));
			}
			SingletonSocket::instance().SendMsg(ptr->GetSock(),msg);
		}
	}
}

void CBangPai::BroadcastAddPlantMsg(uint8 plantedIdx,uint8 cellPos)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(plantedIdx >= BP_AREA_MAX_NUM || cellPos >= m_plantData[plantedIdx].size()) 
		return;
	CNetMessage msg;
	msg.SetType(MSG_BANGPAI_ZHONGZHI);
	msg<<(uint8)12<<m_id<<plantedIdx;
	if(!NolockMakePlantCellMsg(plantedIdx,cellPos,msg))
		return;
	SPlant &seed = m_plantData[plantedIdx][cellPos];
	uint16 pos = msg.GetDataLen();
	msg<<(uint8)0;

	CScene *pScene = SingletonSceneManager::instance().GetBangPaiScene(BANG_PAI_SCENE_ID,m_id);
	if(pScene != NULL)
	{
		list<uint32> userList;
		pScene->GetUserList(userList);
		COnlineUser &onlineUser = SingletonOnlineUser::instance();
		for(list<uint32>::iterator iter = userList.begin(); iter != userList.end(); iter++)
		{
			ShareUserPtr ptr = onlineUser.GetUserByRoleId(*iter);
			if(ptr.get() == NULL)
				continue;
			uint8 myCanstealNum = GetPlantCanStealNumByRole(ptr.get(),seed);
			msg.WriteData(pos,&myCanstealNum,sizeof(myCanstealNum));
			SingletonSocket::instance().SendMsg(ptr->GetSock(),msg);
		}
	}
}

void CBangPai::BroadcastMsg(CNetMessage &msg)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	for(map<uint32,SBangPaiMember>::iterator i = m_allMember.begin(); i != m_allMember.end(); i++)
	{		
		ShareUserPtr ptr = onlineUser.GetUserByRoleId(i->second.roleId);
		if(ptr.get() != NULL)
			SingletonSocket::instance().SendMsg(ptr->GetSock(),msg);
	}
}

void CBangPai::GetRewardByRank(CUser *pUser)
{
	//									帮主，长老，护法，帮众
	const uint8 RankRewardLimit[] = 	{1,		2,		0,		0};
	const float RankRewardPercent[] = 	{0.05f,	0.03f,	0.0f,	0.0f};
	if(pUser == NULL)
		return;

	SBangPaiMember data;
	GetMemberInfoById(pUser->GetRoleId(),data);
	if(data.roleId == 0)
		return;

	CNetMessage msg;
	msg.SetType(PRO_BANGPAI);
	msg<<(uint8)29;
	if(pUser->HaveBitSet(349))
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_399,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}
	uint8 rank = data.rank;
	if(rank < EBRBangZhu || rank > EBRBangZhong)
		return;

	int award = 0;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if(m_memberGetRewardNum[rank-1] >= RankRewardLimit[rank-1])
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_400,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}
		m_memberGetRewardNum[rank-1]++;
		award = (int)(m_yesterdayBangGong * RankRewardPercent[rank-1]);
	}
	if(award == 0)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0485,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}
	
	pUser->SetBitSet(349);

	char buf[128];
	snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_401,award);
	msg<<PRO_SUCCESS<<MakeStringColor(buf,TIPS_WARNING_COLOR);
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);

	SingletonCBangPaiManager::instance().AddBangGong(pUser,award);
}

void CBangPai::SendBangPaiLogMsg(CUser *pUser)
{
	if(pUser == NULL)
		return;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	CNetMessage msg;
	msg.SetType(PRO_BANGPAI);
	msg<<(uint8)28;

	uint32 pos = msg.GetDataLen();
	uint8 logNum = 0;
	msg<<logNum;
	for(list<SBangPaiLog>::iterator it = m_optionLog.begin();it != m_optionLog.end();it++)
	{
		if (it->time == 0)
			continue;
		msg<<it->type<<it->time<<it->log;
		logNum++;
	}
	msg.WriteData(pos,&logNum,sizeof(logNum));
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void CBangPai::SetActivity(int n)
{
	if(n <= 0)
		activity = 0;
	else
		activity = n;
}

void CBangPai::PlantTimer()
{
/*
	// 种植
	static bool resetGuard = true;
	uint32 curTime = GetSysTime();
	uint32 hour = GetHour();
	char buf[512];

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint8 i = 0; i < m_plantData.size(); i++)
	{
		for(uint8 j=0;j < m_plantData[i].size();j++)
		{
			SPlant &seed = m_plantData[i][j];
			if(seed.itemId > 0)
			{
				SPlantSeed *pTmpSeed = SingletonCPlantSeedManager::instance().FindSeed(seed.itemId);
				if(pTmpSeed == NULL)
					continue;
				bool update = false;
				if(curTime > seed.ripeTime)	// 已成熟
				{
					if(seed.state == EZZSRipe)
					{
						if(curTime > seed.ripeTime + pTmpSeed->witheredTimeGap) // 已枯萎,发送收成奖励
						{
							SBangPaiMember *pData = NolockGetMemberData(seed.roleId);
							if(pData == NULL)
							{
								seed.Clear();
								update = true;
							}
							else
							{
								if(pData->plantNum > 0)
									pData->plantNum--;

								uint32 award = (uint32)(seed.gain * 0.8);
								if(award < 1)
									award = 1;
								if(pTmpSeed->gainType == ZZGain_Money)
								{
									snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_402,award);
									SMailData mdata;
									mdata.money = award;
									SendSystemMail(seed.roleId,buf,&mdata);
								}
								else if(pTmpSeed->gainType == ZZGain_YB)
								{
//									AddTongBao(seed.roleId,award,1);
									SMailData mdata;
									mdata.bdYB = award;
									snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_403,award);
									SendSystemMail(seed.roleId,buf,&mdata);
								}
								else if(pTmpSeed->gainType == ZZGain_Item)
								{
									if(pTmpSeed->gainItemId != 0)
									{
										SMailData mdata;
										SItemInstance item;
										item.tmplId = pTmpSeed->gainItemId;
										item.num = award;
										mdata.item.push_back(item);

										snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_404,GetItemName(pTmpSeed->gainItemId),award);
										SendSystemMail(seed.roleId,buf,&mdata);
									}
								}
								else if(pTmpSeed->gainType == ZZGain_EXP)
								{
									AddRoleExp(seed.roleId,award);
									snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_405,award);
									SendSystemMail(seed.roleId,buf);
								}

								if(m_havePlantedNum > 0)
									m_havePlantedNum--;
								seed.Clear();
								update = true;
							}
						}
					}
					else	// 刚刚成熟
					{
						seed.state = EZZSRipe;
						update = true;
						if(seed.pic != pTmpSeed->step_pic3)
							seed.pic = pTmpSeed->step_pic3;

						char buf[256];
						snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_406,pTmpSeed->treeName.c_str());
						SendSystemMail(seed.roleId,buf);
						ShareUserPtr ptr = SingletonOnlineUser::instance().GetUserByRoleId(seed.roleId);
						if(ptr.get() != NULL)
						{
							snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_407,pTmpSeed->treeName.c_str());
							SendSysInfo(ptr.get(),MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
						}
						if(seed.quality >= ZZQT_BLUE && Random(1,100) <= 80)
						{
							snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_408,BANG_NAME_COLOR,m_name.c_str(),TreeQualityColor[seed.quality],pTmpSeed->treeName.c_str());
							SysInfoToAllUser(buf,true);
						}

						if(m_guard[i].get() != NULL)	// 有守卫, 发放奖励
						{
							uint32 award = seed.gain/20;
							if(award < 1)
								award = 1;
							if(pTmpSeed->gainType == ZZGain_Money)
							{
								SMailData mdata;
								mdata.money = award;
								snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_409,pTmpSeed->treeName.c_str(),award);
								SendSystemMail(m_guard[i]->GetRoleId(),buf,&mdata);
							}
							else if(pTmpSeed->gainType == ZZGain_YB)
							{
//								AddTongBao(m_guard[i]->GetRoleId(),award,1);
								SMailData mdata;
								mdata.bdYB = award;
								snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_410,pTmpSeed->treeName.c_str(),award);
								SendSystemMail(m_guard[i]->GetRoleId(),buf,&mdata);
							}
							else if(pTmpSeed->gainType == ZZGain_Item)
							{
								if(pTmpSeed->gainItemId != 0)
								{
									SMailData mdata;
									SItemInstance item;
									item.tmplId = pTmpSeed->gainItemId;
									item.num = award;
									mdata.item.push_back(item);
									snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_411,pTmpSeed->treeName.c_str(),GetItemName(pTmpSeed->gainItemId),award);
									SendSystemMail(m_guard[i]->GetRoleId(),buf,&mdata);
								}
							}
							else if(pTmpSeed->gainType == ZZGain_EXP)
							{
								AddRoleExp(m_guard[i]->GetRoleId(),award);
								snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_412,pTmpSeed->treeName.c_str(),award);
								SendSystemMail(m_guard[i]->GetRoleId(),buf);
							}
						}
					}
				}
				else	// 未成熟
				{
					if((curTime - seed.wateringTime > pTmpSeed->wateringTimeGap) && (seed.wateringCount < pTmpSeed->wateringLimit))	// 可浇水
					{
						if((seed.state & EZZSWatering) != EZZSWatering)
						{
							seed.state |= EZZSWatering;
							update = true;
						}
					}
					if((curTime - seed.killBugTime > pTmpSeed->killBugTimeGap) && (seed.killBugCount < pTmpSeed->killBugLimit))	// 可除虫
					{
						if((seed.state & EZZSKillingBug) != EZZSKillingBug)
						{
							seed.state |= EZZSKillingBug;
							update = true;
						}
					}
					if(curTime - seed.time > BP_ZZ_CHANGE_PIC_TIME)
					{
						if(seed.pic != pTmpSeed->step_pic2)
						{
							seed.pic = pTmpSeed->step_pic2;
							update = true;
						}
					}
				}
				if(update)
				{
					NoLockUpdateZZCell(i,j);
				}
			}
		}
	}
	if(resetGuard && hour == 22)
	{
		resetGuard = false;
		for(uint8 i=0;i > sizeof(m_guard)/sizeof(m_guard[0]);i++)
		{
			if(m_guard[i].get() != NULL)
				m_guard[i].reset();
		}
	}
*/
}

void CBangPai::GodTreeTimer()
{
/*
	const int noAddExpBeginHour = 20;
	const int noAddExpEndHour = 22;

	uint32 curTime = GetSysTime();
	int hour = GetHour();
	int minute = GetMinute();
	if(hour < noAddExpBeginHour || hour >= noAddExpEndHour)
	{
		if(minute <= 5 && !m_isAddTreeExp && curTime > GetAddTreeExpTime()+1800)	// 神树增加经验
		{
			uint32 exp = AddTreeExpPerHour[m_level-1];
			AddTreeTotalExp(exp);
			AddTreeExp(exp);
			m_isAddTreeExp = true;
			SetAddTreeExpTime(curTime);
		}
		else if(minute >= 30)
		{
			m_isAddTreeExp = false;
		}
	}

	if(hour == noAddExpEndHour && !m_clearTreeData)	// 重置神树数据,清除守卫信息
	{
		m_clearTreeData = true;
		int exp = (int)GetTreeExp() + (int)GetTreeRobbedExp();
		if(exp > 0)
			AddExp(exp);
		SetTreeTotalExp(0);
		SetTreeExp(0);
		SetTreeRobbedExp(0);
		SetTreeRobbedNum(0);
		SetPrayExp(0);
		SetPrayNum(0);

		boost::recursive_mutex::scoped_lock lk(m_mutex);
		for(uint8 i=0;i < sizeof(m_guard)/sizeof(m_guard[0]);i++)
		{
			if(m_guard[i].get() != NULL)
				m_guard[i].reset();
			NolockUpdateGuard(i);
		}
	}
	else if (hour == 23 && !m_clearTreeData)
	{
		m_clearTreeData = true; // 防止11点重启服务器时状态不对
	}
	else if(hour == 0 && m_clearTreeData)
	{
		m_clearTreeData = false;

		m_yesterdayBangGong = m_todayBangGong;
		m_todayBangGong = 0;
		memset(m_memberGetRewardNum,0,sizeof(m_memberGetRewardNum));
	}
*/
}

void CBangPai::FireTimer()
{
/*
	const uint32 ADD_AWARD_TIME_GAP = 15;
	const uint32 ADD_RIPE_TIME_GAP = 120;	// 每隔一段时间增加成熟时间
	const uint32 ADD_RIPE_TIME = 60;		// 增加植物成熟时间
	const uint32 FIRE_CONTINUE_TIME = 600;	// 魔火点燃持续时间

	if(m_lastAddRipeTime == 0)
		m_lastAddRipeTime = (uint32)GetSysTime();
	if(m_lastAddAwardTime == 0)
		m_lastAddAwardTime = (uint32)GetSysTime();
	uint32 curTime = (uint32)GetSysTime();

	bool isAddAward = false;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if(m_fireState == BPFire_ON)	// 着火
		{
			if(curTime - m_onFireTime >= FIRE_CONTINUE_TIME)	// 清除魔火时间
			{
				m_fireState = BPFire_OFF;
				m_lastAddAwardTime = curTime;
				m_lastAddRipeTime = curTime;
				NolockUpdateFireState();
				return;
			}

			if(curTime - m_lastAddAwardTime >= ADD_AWARD_TIME_GAP)	// 发放奖励
			{
				isAddAward = true;
				m_lastAddAwardTime += ADD_AWARD_TIME_GAP;
			}

			if(curTime - m_lastAddRipeTime >= ADD_RIPE_TIME_GAP)	// 增加成熟时间
			{
				for(uint8 i = 0; i < m_plantData.size(); i++)
				{
					for(uint8 j=0;j < m_plantData[i].size();j++)
					{
						SPlant &seed = m_plantData[i][j];
						if(seed.itemId > 0 && seed.state != EZZSRipe)
						{
							seed.ripeTime += ADD_RIPE_TIME;
							NoLockUpdateZZCell(i,j);
						}
					}
				}
				m_lastAddRipeTime += ADD_RIPE_TIME_GAP;
			}
		}
		else
		{
			m_lastAddAwardTime = curTime;
			m_lastAddRipeTime = curTime;
		}
	}
	if(isAddAward)	// 发奖励
	{
		CScene *pScene = SingletonSceneManager::instance().GetBangPaiScene(BANG_PAI_SCENE_ID,m_id);
		if(pScene != NULL)
		{
			char buf[512];
			list<uint32> userList;
			pScene->GetUserList(userList);
			COnlineUser &onlineUser = SingletonOnlineUser::instance();
			for(list<uint32>::iterator iter = userList.begin(); iter != userList.end(); iter++)
			{
				ShareUserPtr ptr = onlineUser.GetUserByRoleId(*iter);
				if(ptr.get() == NULL || ptr->GetBangPai() == m_id)
					continue;
				int level = ptr->GetLevel();
				int exp = level*10;
				exp = ptr->AddExp(exp);
				int worldExpPer = GetWorldExpPercent(ptr->GetLevel());
				if (worldExpPer > 0)
				{
					snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_413,exp, worldExpPer);
				}
				else
				{
					snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_414,exp);
				}
				SendSysInfo(ptr.get(),MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
			}
		}
	}
*/
}

void CBangPai::Timer()
{
//	PlantTimer();
//	FireTimer();
//	GodTreeTimer();

	int hour = GetHour();
	if(hour == 23)
		m_updateMission = 0;

	if(hour == 0 && m_clearJXPaiHang)
	{
		ResetHuoYue();
		if (GetWeekDay() == 1)
		{
			// 重置帮派副本
			InitCopy();
		}

		boost::recursive_mutex::scoped_lock lk(m_mutex);
		m_juanxianPaiHang.clear();
		m_clearJXPaiHang = false;
	}
	if(hour > 0 && !m_clearJXPaiHang)
		m_clearJXPaiHang = true;
}

void CBangPai::UpdateAllMemberZhanDouLi()
{
	map<uint32,SBangPaiMember> members;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		members = m_allMember;
	}
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	for(map<uint32,SBangPaiMember>::iterator i = members.begin(); i != members.end(); i++)
	{
		ShareUserPtr ptr = onlineUser.GetUserByRoleId(i->second.roleId);
		CUser *pUser = ptr.get();
		if(pUser != NULL)
		{
			pUser->InitAndUpdate();
		}
	}
}

void CBangPai::SendMailToAllMember(const char *pMsg,SMailData *pMailData)
{
	if(pMsg == NULL)
		return;
	map<uint32,SBangPaiMember> members;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		members = m_allMember;
	}
	for(map<uint32,SBangPaiMember>::iterator i = members.begin(); i != members.end(); i++)
	{
		SendSystemMail(i->second.roleId,pMsg,pMailData);
	}
}


uint32 CBangPai::GetExp()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return m_exp;
}

void CBangPai::SetExp(uint32 t)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_exp = t;
}

void CBangPai::SetTreeLevel(uint8 lv)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_treeLv = lv;
}

uint8 CBangPai::GetTreeLevel()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return m_treeLv;
}

uint32 CBangPai::GetTreeTotalExp()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return m_treeTotalExp;
}

void CBangPai::SetTreeTotalExp(uint32 t)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_treeTotalExp = t;
}

void CBangPai::AddTreeTotalExp(uint32 t)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_treeTotalExp += t;
}

uint32 CBangPai::GetTreeExp()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return m_treeExp;
}

void CBangPai::SetTreeExp(uint32 t)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_treeExp = t;
}

void CBangPai::AddTreeExp(uint32 t)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_treeExp += t;
}

void CBangPai::SetPrayNum(uint32 t)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_prayNum = t;
}

uint32 CBangPai::GetAddTreeExpTime()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return m_addTreeExpTime;
}

void CBangPai::SetAddTreeExpTime(uint32 t)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_addTreeExpTime = t;
}

void CBangPai::SetMemberReward(const char *pStr)
{
	if(pStr == NULL)
		return;

	char *split[100];
	string str = pStr;
	int num = SplitLine(split,100,(char*)str.c_str());
	if(num < 2)
		return;
	m_yesterdayBangGong = (uint32)atoi(split[0]);
	m_todayBangGong = (uint32)atoi(split[1]);
	for(int i=0;i < num-2;i++)
		m_memberGetRewardNum[i] = (uint8)atoi(split[i+2]);
}

void CBangPai::AddPrayNum()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_prayNum++;
}

uint32 CBangPai::GetPrayExp()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return m_prayExp;
}

void CBangPai::SetPrayExp(uint32 t)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_prayExp = t;
}

void CBangPai::AddPrayExp(uint32 t)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_prayExp += t;
}

uint32 CBangPai::GetTreeRobbedExp()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return m_treeRobbedExp;
}

void CBangPai::SetTreeRobbedExp(uint32 t)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_treeRobbedExp = t;
}

void CBangPai::AddTreeRobbedExp(uint32 t)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_treeRobbedExp += t;
}

uint8 CBangPai::GetTreeRobbedNum()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return m_treeRobbedNum;
}

void CBangPai::SetTreeRobbedNum(uint8 t)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_treeRobbedNum = t;
}

void CBangPai::AddTreeRobbedNum(uint8 t)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_treeRobbedNum += t;
}

bool CBangPai::AddTreeExpWithRobbedExp(int robExp)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(robExp < 0)	// 被抢夺经验
	{
		robExp = -robExp;
/* 不扣除掠夺经验
		if(m_treeRobbedExp >= (uint32)robExp)
			m_treeRobbedExp -= (uint32)robExp;
		else if(m_treeRobbedExp > 0)
		{
			robExp -= (int)m_treeRobbedExp;
			m_treeRobbedExp = 0;
		}
*/

		if(robExp > 0)
		{
			int leftRobExp = 0;
			if(m_treeExp > m_treeTotalExp/2)
				leftRobExp = m_treeExp - m_treeTotalExp/2;
			if(leftRobExp == 0)
				return false;
			if(robExp <= leftRobExp)
				m_treeExp -= (uint32)robExp;
			else
				m_treeExp = m_treeTotalExp/2;
		}
	}
	else if(robExp > 0)	// 掠夺获得经验
	{
		m_treeRobbedExp += (uint32)robExp;
	}
	else	// robExp==0
	{
		return false;
	}
	return true;
}

int CBangPai::GetTreeCanRobbedExp()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	int robExp = (int)(m_treeTotalExp/20);
	uint32 leftRobExp = m_treeRobbedExp;
	if(m_treeExp > m_treeTotalExp/2)
		leftRobExp += m_treeExp - m_treeTotalExp/2;
	if((int)leftRobExp < robExp)
		robExp = (int)leftRobExp;
	return robExp;
}

uint32 CBangPai::GetLevelUpExp()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return GetBangPaiLevelUpExp(m_level);
}

void CBangPai::AddExp(uint32 exp)
{
	if(exp == 0 || exp > 100000)
		return;
	bool update = false;
	char buf[128];
	char gonggao[128];
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		uint32 levelExp = GetBangPaiLevelUpExp(m_level);
		m_exp += exp;
		if(m_exp >= levelExp)
		{
			if(m_level >= BP_MAX_LEVEL)
				return;
			m_level++;
			m_treeLv++;
			m_exp -= levelExp;

			update = true;
			snprintf(gonggao,sizeof(gonggao),LANGUAGE_TRANSFORM_415,BANG_NAME_COLOR,m_name.c_str(),(int)m_level);
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_416,GGCT_GREEN,(int)m_level);

			/*char buf[512];
			snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0009, LANGUAGE_ZQX_0013, pUser->GetName(), pBangPai->GetBangZhuName().c_str());
			pBangPai->SaveLog(pUser->GetRoleId(), 0, EBPLT_Member_Change, buf);*/
		}
	}
	if(update)
	{
		InitZhongZhi(false);
		SysInfoToAllUser(gonggao,true);
		SaveBangPaiLog(NULL,EBLT_LEVELUP,buf);
	}
}

int CBangPai::GetMemNumByRank(uint8 rank)
{
	int num = 0;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(map<uint32,SBangPaiMember>::iterator i = m_allMember.begin(); i != m_allMember.end(); i++)
	{
		if(i->second.rank == rank)
			num++;
	}
	return num;
}

uint16 CBangPai::GetMaxMemberNum()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return BP_MEMBER_NUM_LIMIT[m_level-1];
}

int CBangPai::GetMaxRankNum(uint8 rank)
{
	// 帮主，长老，护法
	const int MEMBER_NUM[BP_MAX_LEVEL][EBRRANK_MAX-1] = {
		{1,2,5},
		{1,2,5},
		{1,2,5},
		{1,2,5},
		{1,2,5},
		{1,2,5},
		{1,2,5},
		{1,2,5},
		{1,2,5},
		{1,2,5}};
		if(m_level > sizeof(MEMBER_NUM)/sizeof(MEMBER_NUM[0]))
			return 0;
		if(rank <= EBRHuFa)
			return MEMBER_NUM[m_level-1][rank-1];
		else
			return (int)BP_MEMBER_NUM_LIMIT[m_level-1];
}

bool CBangPai::AddMember(CUser *pUser,uint8 rank)
{
	if(pUser == NULL)
		return false;
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return false;
	char buf[512];

	{
		boost::mutex::scoped_lock lk(m_AskJoinmutex);
		m_askJoinUser.remove(pUser->GetRoleId());
	}

	string name = pUser->GetName();
	SBangPaiMember m;
	m.rank = rank;
	m.roleId = pUser->GetRoleId();
	m.utime = GetSysTime();
	m.huoyue_day = pUser->GetExtData32(EData32_HuoYueDu_Day);
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if(find(m_userList.begin(),m_userList.end(),pUser->GetRoleId()) != m_userList.end())
			return false;
		uint32 maxNum = BP_MEMBER_NUM_LIMIT[m_level-1];
		if(m_userList.size() >= maxNum)
			return false;

		pUser->SetData32(5,0);

		snprintf(buf,sizeof(buf),"insert into bang_pai_role (bangpai_id,role_id,`rank`,join_time,total_bangGong,huoyue) values (%u,%u,%d,%u,%d,%u)",
			m_id, m.roleId, (int)m.rank, (uint32)m.utime, m.total_gongXian, m.huoyue_day);
		if(!pDb->Query(buf))
			return false;
		m_userList.push_back(pUser->GetRoleId());
		if(!m_allMember.insert(make_pair(pUser->GetRoleId(),m)).second)
			return false;
	}
	snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0010, name.c_str());
	SaveBangPaiLog(pUser, EBPLT_Member_Change, buf);

	CNetMessage msg;
	snprintf(buf,sizeof(buf), LANGUAGE_SSJ_0502, name.c_str());
	MakeChatByChannel(msg,ECT_BangPai,buf);
	BroadcastMsg(msg);
	sCMissionManager.UpdateQuestState(pUser, EMQCT_59);
	return true;
}

bool CBangPai::AddMemberLocked(uint32 roleId,uint8 rank)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return AddMemberNoLocked(roleId,rank);
}

bool CBangPai::AddMemberNoLocked(uint32 roleId,uint8 rank)
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return false;
	if(find(m_userList.begin(),m_userList.end(),roleId) != m_userList.end())
		return false;
	uint32 maxNum = BP_MEMBER_NUM_LIMIT[m_level-1];
	if(m_userList.size() >= maxNum)
		return false;
	SRoleSimpleData data;
	if(!SingletonCSimpleRoleDataMgr::instance().GetRoleData(roleId, data))
		return false;

	char buf[256];
	ShareUserPtr p = SingletonOnlineUser::instance().GetUserByRoleId(roleId);
	CUser *pU = p.get();
	
	SBangPaiMember m;
	m.rank = rank;
	m.roleId = roleId;
	m.huoyue_day = data.huoyue_day;
	if(pU != NULL)
	{
		pU->SetData32(5,0);
		m.utime = GetSysTime();
	}
	else
	{
		//                            0        1
		snprintf(buf,sizeof(buf),"select save_data,bank_item from role_info where id=%u",roleId);
		if(!pDb->Query(buf))
			return false;
		char **row = pDb->GetRow();
		if(row == NULL)
			return false;
		CUser *p = new CUser;
		if(p == NULL)
			return false;
		p->ReadSaveData(row[0]);
		p->SetBankItem(row[1]);
		p->SetData32(5,0);
		
		string saveStr;
		p->WriteSaveData(saveStr);
		delete p;
		char sql[4098];
		snprintf(sql,sizeof(sql),"update role_info set save_data='%s' where id=%u",saveStr.c_str(),roleId);
		pDb->Query(buf);
	}

	snprintf(buf,sizeof(buf),"insert into bang_pai_role (bangpai_id,role_id,`rank`,join_time,total_bangGong) values (%u,%u,%d,%u,%d)",
		m_id, m.roleId, (int)m.rank, (uint32)m.utime,m.total_gongXian);
	if(!pDb->Query(buf))
		return false;
	m_userList.push_back(roleId);
	if(!m_allMember.insert(make_pair(roleId, m)).second)
		return false;

	if (rank == EBRBangZhu)
	{
		snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0023, data.name.c_str());
	}
	else
	{
		snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0010, data.name.c_str());
	}
	SaveBangPaiLog(pU, EBPLT_Member_Change, buf);
	return true;
}

void CBangPai::DismissBang_updata()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
	char buf[256];
	snprintf(buf,sizeof(buf),"delete from bang_pai_role where bangpai_id=%u",m_id);
	pDb->Query(buf);

#ifdef KUA_FU
	snprintf(buf,sizeof(buf),"delete from bang_pai where id=%u",m_id);
	pDb->Query(buf);
#else
	snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_417,m_name.c_str(),(uint32)dismissbang_time,(uint32)GetSysTime(),m_id);
	pDb->Query(buf);

	snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_418,GetName().c_str());
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		for(map<uint32,SBangPaiMember>::iterator i = m_allMember.begin(); i != m_allMember.end(); i++)
		{
			SendSystemMail(i->first,buf);
			ShareUserPtr ptr = onlineUser.GetUserByRoleId(i->first);
			CUser *pUser = ptr.get();
			if(pUser == NULL)
				continue;
			pUser->SetBangPai(0);
			pUser->UpdateBangPai();
		}
	}
#endif
	SingletonCBangPaiManager::instance().Erase(m_id);
}

bool CBangPai::IsAdmin(uint32 id)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,SBangPaiMember>::iterator it = m_allMember.find(id);
	if(it == m_allMember.end())
		return false;
	return ((it->second.rank <= EBRZhangLao) ? true : false);
}

// type 1 refuse  2 accept
void CBangPai::AcceptAllAskJoin(CUser *pUser,int type)
{
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
	char buf[128];
	list<uint32>::iterator i = m_askJoinUser.begin();

	if(type == 1)		// refuse
	{
		boost::mutex::scoped_lock lk(m_AskJoinmutex);
		for(; i != m_askJoinUser.end(); i++)
		{
			ShareUserPtr p = onlineUser.GetUserByRoleId(*i);
			CUser *pU = p.get();
			if(pU != NULL)
			{
				string str = pUser->GetName();
				str += LANGUAGE_TRANSFORM_419;
				SendSysInfo(pU,MakeStringColor(str.c_str(),TIPS_FAILURE_COLOR).c_str());
			}
		}
		m_askJoinUser.clear();
	}
	else		// accept
	{
		vector<uint32> joinList;
		{
			boost::mutex::scoped_lock lk(m_AskJoinmutex);
			for(; i != m_askJoinUser.end(); i++)
			{
				joinList.push_back(*i);
				ShareUserPtr p = onlineUser.GetUserByRoleId(*i);
				CUser *pU = p.get();
				if(pU != NULL)
				{
					if(pU->GetBangPai() == 0)
					{
						if(AddMemberNoLocked(*i,EBRBangZhong))
						{
							pU->SetBangPai(m_id,EBRBangZhong,m_name.c_str());
							pU->UpdateBangPai();
							string str = pUser->GetName();
							str += LANGUAGE_TRANSFORM_421;
							SendSysInfo(pU,MakeStringColor(str.c_str(),TIPS_WARNING_COLOR).c_str());
							pU->AfterJoinBangPai();
						}
						else
						{
							string str = pU->GetName();
							str += LANGUAGE_TRANSFORM_1177;
							SendSysInfo(pUser, MakeStringColor(str, TIPS_FAILURE_COLOR).c_str());
						}
					}
				}
				else
				{
					snprintf(buf,sizeof(buf),"select bangpai_id from bang_pai_role where role_id = %u",*i);
					if(!pDb->Query(buf))
						return;
					int num = pDb->GetRowNum();
					if(num != 0)
						continue;
					AddMemberNoLocked(*i,EBRBangZhong);
				}
			}
			m_askJoinUser.clear();
		}

		for(uint16 i=0;i < joinList.size();i++)
		{
			ShareUserPtr p = onlineUser.GetUserByRoleId(joinList[i]);
			CUser *pU = p.get();
			if(pU != NULL)
			{
				CScene *pScene = pU->GetScene();
				if(pScene != NULL)
					pScene->UpdateUserInfo(pU,ESRT_BangPai);
			}
		}
	}
}

bool CBangPai::HaveRight2DelMember(uint32 adminId,uint32 roleId)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,SBangPaiMember>::iterator itAdmin = m_allMember.find(adminId);
	map<uint32,SBangPaiMember>::iterator itRole = m_allMember.find(roleId);
	if(itAdmin == m_allMember.end() || itRole == m_allMember.end())
		return false;
	if(itAdmin->second.rank < itRole->second.rank && itAdmin->second.rank <= EBRHuFa)
		return true;
	else
		return false;
}

void CBangPai::ShowBangZhanIcon(int flag)
{
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	int curTime = GetSysTime();

	int type = SOT_BangPaiZhan;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(map<uint32,SBangPaiMember>::iterator i = m_allMember.begin();i != m_allMember.end();i++)
	{
		if(curTime - (int)(i->second.utime) >= CBangPaiManager::BP_FIGHT_LIMIT_ENTER_TIME)
		{
			ShareUserPtr p = onlineUser.GetUserByRoleId(i->first);
			CUser *pUser = p.get();
			if(pUser != NULL && sSystemOpenCfgMananger.CheckSystemOpen(pUser, type))
			{
				SendHuoDongFlag_Single(pUser, type, flag);
			}
		}
	}
}

void CBangPai::ShowKuaFuBangZhanIcon(bool show)
{
	// 发送type有修改
	/*COnlineUser &onlineUser = SingletonOnlineUser::instance();
	int curTime = GetSysTime();
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(map<uint32,SBangPaiMember>::iterator i = m_allMember.begin();i != m_allMember.end();i++)
	{
		if(curTime - (int)(i->second.utime) >= CBangPaiManager::BP_FIGHT_LIMIT_ENTER_TIME)
		{
			ShareUserPtr p = onlineUser.GetUserByRoleId(i->first);
			CUser *pUser = p.get();
			if(pUser != NULL && pUser->GetLevel() >= CBangPaiManager::KF_BP_FIGHT_ROLE_LIMIT_LV)
			{
				if(show)
					SendHuoDongFlag_Single(pUser,23,1);
				else
					SendHuoDongFlag_Single(pUser,23,2);
			}
		}
	}*/
}

int CBangPai::GetSXQinMi(int sxID)
{
	if(sxID <= 0)
		return 0;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return NoLockGetSXQinMi(sxID);
}

int CBangPai::NoLockGetSXQinMi(int sxID)
{
	if(sxID <= 0)
		return 0;
	map<int,SBPShangXian_SelfData>::iterator it = m_sx_data.find(sxID);
	if(it == m_sx_data.end())
	{
		SBPShangXian_SelfData data;
		m_sx_data.insert(make_pair(sxID,data));
		return 0;
	}
	return it->second.qinmi;
}

void CBangPai::SetSXQinMi(int sxID,int qinmi)
{
	if(sxID <= 0)
		return;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<int,SBPShangXian_SelfData>::iterator it = m_sx_data.find(sxID);
	if(it == m_sx_data.end())
	{
		SBPShangXian_SelfData data;
		data.qinmi = qinmi;
		m_sx_data.insert(make_pair(sxID,data));
		return;
	}
	it->second.qinmi = qinmi;
}

uint8 CBangPai::GetSXTarget(int sxID)
{
	if(sxID <= 0)
		return 0;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<int,SBPShangXian_SelfData>::iterator it = m_sx_data.find(sxID);
	if(it == m_sx_data.end())
	{
		SBPShangXian_SelfData data;
		m_sx_data.insert(make_pair(sxID,data));
		return 0;
	}
	return it->second.setTarget;
}

void CBangPai::SetSXTaget(int sxID,uint8 state)
{
	if(sxID <= 0)
		return;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<int,SBPShangXian_SelfData>::iterator it = m_sx_data.find(sxID);
	if(it == m_sx_data.end())
	{
		SBPShangXian_SelfData data;
		data.setTarget = state;
		m_sx_data.insert(make_pair(sxID,data));
		return;
	}
	it->second.setTarget = state;
}

void CBangPai::ReadSX_Info(const char *str)
{
	m_tarCheChaBangId = 0;
	m_sx_data.clear();
	if(str == NULL || strlen(str) < 3)
		return;

	char *p[103];
	char buf[2048];
	memset(buf,0,sizeof(buf));
	snprintf(buf,sizeof(buf),"%s",str);
	
	int num = SplitLine(p,buf);
	m_tarCheChaBangId = atoi(p[0]);
	for(uint16 i=1;i < num;i += 3)
	{
		int id = atoi(p[i]);
		SBPShangXian_SelfData data;
		data.qinmi = atoi(p[i+1]);
		data.setTarget = atoi(p[i+2]);
		m_sx_data.insert(make_pair(id,data));
	}
}

void CBangPai::GetSX_Info(string &str)
{
	str.clear();
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	str += IntToStr(m_tarCheChaBangId);
	for(map<int,SBPShangXian_SelfData>::iterator it=m_sx_data.begin();it != m_sx_data.end();it++)
		str += "|" + IntToStr(it->first) + "|" + IntToStr(it->second.qinmi) + "|" + IntToStr(it->second.setTarget);
}

void CBangPai::ReadJuanXianPaiHang(const char *str)
{
	const int MAX_RANK_NUM = 100;
	m_juanxianPaiHang.clear();
	if(str == NULL || strlen(str) < 1)
		return;

	uint32 len = sizeof(SBP_JuanXianPaiHang)*MAX_RANK_NUM + 64;
	uint8 *p = new uint8[len];
	memset(p,0,len);
	boost::scoped_array<uint8> autoDel(p);
	if(!UnCompress(str,p,len))
		return;

	CNetMessage msg;
	msg.WriteData(p,len);
	uint32 num = 0;
	msg>>num;
	for(uint32 i=0;i < num;i++)
	{
		SBP_JuanXianPaiHang data;
		msg>>data.roleId>>data.money>>data.name;
		if(data.roleId != 0)
			m_juanxianPaiHang.push_back(data);
	}
}

void CBangPai::GetJuanXianPaiHang(string &str)
{
	str.clear();
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	CNetMessage msg;
	msg<<(uint32)m_juanxianPaiHang.size();
	for(uint32 i=0;i < m_juanxianPaiHang.size();i++)
		msg<<m_juanxianPaiHang[i].roleId<<m_juanxianPaiHang[i].money<<m_juanxianPaiHang[i].name;

	if(!Compress((uint8*)(msg.GetMsgData()->c_str() + CNetMessage::GetHeadLen()),msg.GetDataLenExceptHead(), str))
		str.clear();
}


void CBangPai::ReadMission(const char *str)
{
	m_updateMission = 0;
	m_mission.clear();
	if(str == NULL || strlen(str) < 1)
		return;

	char *p[101];
	char buf[1024];
	memset(buf,0,sizeof(buf));
	snprintf(buf,sizeof(buf),"%s",str);
	int num = SplitLine(p,buf);
	m_updateMission = atoi(p[0]);
	for(uint16 i=1;i < num;i += 2)
	{
		SBPMission_SelfData data;
		data.missionId = atoi(p[i]);
		data.isSelect = 1; //atoi(p[i+1]);
		m_mission.push_back(data);
	}
}

void CBangPai::GetMissionStr(string &str)
{
	str.clear();
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	str += IntToStr(m_updateMission);
	for(uint16 i=0;i < m_mission.size();i++)
		str += "|" + IntToStr(m_mission[i].missionId) + "|" + IntToStr(m_mission[i].isSelect);
}

void CBangPai::UpdateMission(const vector<SBangPaiMission> &mList)
{
	if(m_updateMission == 1)
		return;
	m_mission.clear();
	for(uint16 i=0;i < mList.size();i++)
	{
		if(mList[i].type == 0)
			continue;
		SBPMission_SelfData data;
		data.missionId = mList[i].id;
		data.isSelect = 1;
		m_mission.push_back(data);
	}
	m_updateMission = 1;


/*
	const int STEP1_MISSION_NUM = 3;
	const int ADD_MISSION_NUM = 4;
	if(m_updateMission == 1 || m_xianzhun_lv < ZXG_TASK_OPEN_LV)
	{
		cout<<"UpdateMission  m_updateMission == 1 || m_xianzhun_lv < ZXG_TASK_OPEN_LV return "<<endl;
		cout<<"UpdateMission m_updateMission " << m_updateMission<<endl;
		cout<<"UpdateMission m_xianzhun_lv " << m_xianzhun_lv<<endl;
		cout<<"UpdateMission ZXG_TASK_OPEN_LV " << ZXG_TASK_OPEN_LV<<endl;
		//return;
	}
	m_mission.clear();
	//int maxNum = GetZXG_MaxMissionNum(m_xianzhun_lv);
	int maxNum = GetZXG_MaxMissionNum(3); // TODO 
	if(maxNum == 0){
		cout<<"UpdateMission return maxNum==0 " <<endl;
		return;
	}

	maxNum += ADD_MISSION_NUM;
	maxNum--;
	
	SBPMission_SelfData data;
	data.missionId = Random(1,STEP1_MISSION_NUM);
	m_mission.push_back(data);

	int size = mList.size() - STEP1_MISSION_NUM;
	int t[100];
	if(maxNum > size)
		maxNum = size;
	if(maxNum > 100)
		maxNum = 100;
	RandomSequence(t,maxNum,maxNum);

	for(int i=0;i < maxNum;i++)
	{
		SBPMission_SelfData tdata;
		data.missionId = mList[t[i]+2].id;
		m_mission.push_back(data);
	}
	m_updateMission = 1;
*/
}

void CBangPai::ClearFightJiFen()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
#ifndef KUA_FU
	m_BZ_jifen = 0;
#else
	m_kfBZ_jifen = 0;
	m_kfBZ_jifen_final = 0;
#endif
	for(map<uint32,SBangPaiMember>::iterator i = m_allMember.begin();i != m_allMember.end();i++)
		i->second.bpFightJifen = 0;
}

void CBangPai::ClearKuaFuBZ_FinalJiFen()
{
#ifdef KUA_FU
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_kfBZ_jifen_final = 0;
	for(map<uint32,SBangPaiMember>::iterator i = m_allMember.begin();i != m_allMember.end();i++)
		i->second.bpFightJifen = 0;
#endif
}

void CBangPai::AddAllMemberTitle(int title)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(map<uint32,SBangPaiMember>::iterator i = m_allMember.begin();i != m_allMember.end();i++)
		AddUserTitle(i->first,title);
}

uint8 CBangPai::GetMemberRank(uint32 roleId)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,SBangPaiMember>::iterator it = m_allMember.find(roleId);
	if(it == m_allMember.end())
		return 0;
	return it->second.rank;
}

SBangPaiMember *CBangPai::NolockGetMemberData(uint32 roleId)
{
	map<uint32,SBangPaiMember>::iterator it = m_allMember.find(roleId);
	if(it == m_allMember.end())
		return NULL;
	return &it->second;
}

void CBangPai::UpdateMemberName(int roleId,string &name)
{


}

void CBangPai::GetMemberInfoById(uint32 memberId,SBangPaiMember &memberNode)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,SBangPaiMember>::iterator it = m_allMember.find(memberId);
	if(it == m_allMember.end())
		return;
	memberNode = it->second;
}

void CBangPai::SetMemberRank(uint32 roleId,uint8 rank)
{
//	CGetDbConnect getDb;
//	CDatabaseSql *pDb = getDb.GetDbConnect();
//	if(pDb == NULL)
//		return;
//	char buf[256];
//	snprintf(buf,sizeof(buf),"update bang_pai_role set rank = %d where role_id=%u",(int)rank,roleId);
//	if(!pDb->Query(buf))
//		return;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,SBangPaiMember>::iterator it = m_allMember.find(roleId);
	if(it == m_allMember.end())
		return;
	it->second.rank = rank;

	//SaveLog(roleId, EBLT_RANKCHANGE, "");
}

void CBangPai::CheckChangeBangzhu()
{
	CSimpleRoleDataMgr &simpleMgr = SingletonCSimpleRoleDataMgr::instance();
	
	int curTime = time(NULL);
	SRoleSimpleData bzData;
	SBangPaiMember* bangzhu = NULL;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	// 帮主7天不上线删除
	for (map<uint32, SBangPaiMember>::iterator i = m_allMember.begin(); i != m_allMember.end(); i++)
	{
		SBangPaiMember &mem = i->second;
		if (mem.rank == EBRBangZhu)
		{
			if(!simpleMgr.GetRoleData(mem.roleId, bzData))
				break;
			// 帮主下线超过3天
			if (bzData.lastLoginTime > 0 && (curTime - (int)bzData.lastLoginTime >= 3 * 24 * 3600))
				bangzhu = &mem;
			break;
		}
	}

	if (bangzhu != NULL)
	{
		SRoleSimpleData data;
		SBangPaiMember *nextBangzhu = NULL;
		uint32 maxPower = 0;

		for (int i = EBRBangZhu; i <= EBRBangZhong; ++ i)
		{
			for (map<uint32, SBangPaiMember>::iterator it = m_allMember.begin(); it != m_allMember.end(); it++)
			{
				SBangPaiMember &mem = it->second;
				if (mem.rank != i)
				{
					continue;
				}
				if(!simpleMgr.GetRoleData(mem.roleId, data))
					continue;
				if (data.lastLoginTime > 0 && (curTime - (int)data.lastLoginTime >= 3 * 24 * 3600))
					continue;
				if (maxPower < data.power)
				{
					nextBangzhu = &mem;
					maxPower = data.power;
				}
			}

			if (nextBangzhu != NULL)
			{
				nextBangzhu->rank = EBRBangZhu;
				bangzhu->rank = EBRBangZhong;

				char buf[512];
				snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0007, bzData.name.c_str(), LANGUAGE_ZQX_0013);
				SaveBangPaiLog(NULL, EBPLT_Member_Change, buf);
				snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0008, data.name.c_str(), LANGUAGE_ZQX_0013);
				SaveBangPaiLog(NULL, EBPLT_Member_Change, buf);
				return;
			}
		}
	}
}


bool CBangPai::GetNextBangZhuData(SBangPaiMember &nextBangZhu)
{
	CSimpleRoleDataMgr &simpleMgr = SingletonCSimpleRoleDataMgr::instance();
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	SBangPaiMember *p = NULL;
	for(map<uint32,SBangPaiMember>::iterator i = m_allMember.begin(); i != m_allMember.end(); i++)
	{
		SBangPaiMember &mem = i->second;
		if(mem.rank != EBRBangZhu)
		{
			if(p == NULL)
			{
				p = &mem;
				continue;
			}
			
			if(mem.rank < p->rank)
			{
				p = &mem;
			}
			else if(mem.rank == p->rank)
			{
				SRoleSimpleData memData;
				SRoleSimpleData pData;
				if(!simpleMgr.GetRoleData(mem.roleId, memData))
					continue;
				if(!simpleMgr.GetRoleData(p->roleId, pData))
					continue;
				if((memData.lastLoginTime == 0 && pData.lastLoginTime > 0)	// 最后登录时间晚的优先
					|| (memData.lastLoginTime == 0 && pData.lastLoginTime == 0 && mem.utime < p->utime)	// 最后登录时间一样，入帮时间早的优先
					|| (memData.lastLoginTime > 0 && pData.lastLoginTime > 0 && (memData.lastLoginTime > pData.lastLoginTime))) // 最后登录时间晚的优先
				{
					p = &mem;
				}
			}
		}
	}
	if(p != NULL)
	{
		nextBangZhu = *p;
		return true;
	}
	return false;
}

bool CBangPai::IsAskJoin(uint32 id)
{
	boost::mutex::scoped_lock lk(m_AskJoinmutex);
	return find(m_askJoinUser.begin(),m_askJoinUser.end(),id) != m_askJoinUser.end();
}

// 0 sucess -1 is asked  -2 ask list is full
int CBangPai::AddAskJoin(uint32 id)
{
	boost::mutex::scoped_lock lk(m_AskJoinmutex);
	if(find(m_askJoinUser.begin(),m_askJoinUser.end(),id) != m_askJoinUser.end())
		return -1;

	if(m_askJoinUser.size() >= 0xff)
		return -2;
	m_askJoinUser.push_back(id);
	return 0;
}

void CBangPai::DelMember(uint32 roleId, CUser *pUser/* = NULL*/)
{
//	const double gainRatio[ZZQT_NUM] = { 1.0, 1.04, 1.1, 1.2, 1.25,1.0,1.0,1.0 };
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
	char buf[256];
	snprintf(buf,sizeof(buf),"delete from bang_pai_role where role_id = %u",roleId);
	if(!pDb->Query(buf))
		return;

	SRoleSimpleData data;
	if(!SingletonCSimpleRoleDataMgr::instance().GetRoleData(roleId, data))
		return;

	string name = data.name;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		map<uint32,SBangPaiMember>::iterator it = m_allMember.find(roleId);
		if(it == m_allMember.end())
			return;

		if (pUser == NULL)
		{
			char buf[512];
			snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0011, name.c_str());
			SaveBangPaiLog(pUser, EBPLT_Member_Change, buf);
		}
		else
		{
			uint8 rk = GetMemberRank(pUser->GetRoleId());
			string zhiwei = CBangPaiManager::GetRankName(rk);
			char buf[512];
			snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0012, name.c_str(), zhiwei.c_str(), pUser->GetName());
			SaveBangPaiLog(pUser, EBPLT_Member_Change, buf);
		}

		m_allMember.erase(it);
		m_userList.remove(roleId);

/*
		// 删除植物
		for(uint16 i=0;i < m_plantData.size();i++)
		{
			for(uint16 j=0;j < m_plantData[i].size();j++)
			{
				SPlant &cell = m_plantData[i][j];
				if (cell.itemId > 0 && cell.roleId == roleId)
				{
					SPlantSeed* pTmpSeed = NULL;
					if ((pTmpSeed = SingletonCPlantSeedManager::instance().FindSeed(cell.itemId)) == NULL)
						return;
					cell.gain = (uint32)(pTmpSeed->gainValue * gainRatio[cell.quality]);
					int award = cell.gain * 0.8 * cell.time / cell.ripeTime;
					if (pTmpSeed->gainType == ZZGain_Money)
					{
						snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0091, GetName().c_str(), award);
						SMailData mdata;
						mdata.money = award;
						SendSystemMail(cell.roleId, buf, &mdata);
					}
					else if (pTmpSeed->gainType == ZZGain_YB)
					{
						//									AddTongBao(seed.roleId,award,1);
						SMailData mdata;
						mdata.bdYB = award;
						snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0092, GetName().c_str(), award);
						SendSystemMail(cell.roleId, buf, &mdata);
					}
					else if (pTmpSeed->gainType == ZZGain_Item)
					{
						if (pTmpSeed->gainItemId != 0)
						{
							SMailData mdata;
							SItemInstance item;
							item.tmplId = pTmpSeed->gainItemId;
							item.num = award;
							mdata.item.push_back(item);

							snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0093, GetName().c_str(), GetItemName(pTmpSeed->gainItemId), award);
							SendSystemMail(cell.roleId, buf, &mdata);
						}
					}
					else if (pTmpSeed->gainType == ZZGain_EXP)
					{
						AddRoleExp(cell.roleId, award);
						snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0094, GetName().c_str(), award);
						SendSystemMail(cell.roleId, buf);
					}
					cell.Clear();
					if(m_havePlantedNum > 0)
						m_havePlantedNum--;
					NoLockUpdateZZCell(i,j);
				}
			}
		}
*/
	}

	CNetMessage msg;
	snprintf(buf,sizeof(buf), LANGUAGE_SSJ_0503, name.c_str());
	MakeChatByChannel(msg,ECT_BangPai,buf);
	BroadcastMsg(msg);
}

void CBangPai::Read(char *str)
{
	if(str == NULL || strlen(str) == 0)
		return;

	char *pM[20] = {NULL};
	uint8 count=1;
	uint8 num;
	num = SplitLine(pM,20,str);
	if(num > sizeof(pM)/sizeof(pM[0]))
	{
		cout<<"bang_pai info is out of pM (CBangPai::Read())"<<endl;
		return;
	}
	m_tangzhu_rank = (uint8)atoi(pM[count++]);
	m_bangzhu_old = (uint32)atoi(pM[count++]);
	if(num == 4)
		ZhongZhiMax = (atoi(pM[count++])==1 ? true : false);
}

#ifdef KUA_FU
void CBangPai::KF_ReadMember(CNetMessage &msg)
{
	uint16 num = 0;
	msg>>num;

	char sql[1024];
	list<uint32> oldList;
	list<uint32> newList;
	{
		snprintf(sql,sizeof(sql)-1,"delete from bang_pai_role where bangpai_id=%u",m_id);
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		oldList = m_userList;
		SendLongQuerySql(sql);
		m_userList.clear();
		m_allMember.clear();
		for(uint32 i=0;i < num;i++)
		{
			uint32 roleId = 0;
			string rName;
			uint8 rLevel = 0;
			uint8 rXiang = 0;
			uint8 rRank = 0;
			uint8 vipLv = 0;
			uint32 rTgongxian = 0;
			uint32 time = 0;
			uint32 huoyue = 0;
			msg>>roleId>>rName>>rLevel>>rRank>>rXiang>>rTgongxian>>time>>vipLv>>huoyue;
			m_userList.push_back(roleId);

			SBangPaiMember m;
			m.roleId = roleId;
			m.rank = rRank;
			m.total_gongXian = rTgongxian;
			m.utime = 0;
			m.huoyue_day = huoyue;
			m_allMember.insert(make_pair(roleId,m));
             
			snprintf(sql,sizeof(sql)-1,"delete from bang_pai_role where role_id=%d",m.roleId);
			SendLongQuerySql(sql);
			snprintf(sql,sizeof(sql)-1,"insert into bang_pai_role (bangpai_id,role_id,`rank`,join_time,total_bangGong,huoyue) values(%u,%u,%d,%u,%d,%u)",
				m_id, m.roleId, (int)m.rank, m.utime, m.total_gongXian, (int)huoyue);
			SendLongQuerySql(sql);
		}
		newList = m_userList;
	}

	if(oldList.empty())
		return;
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	list<uint32>::iterator i = oldList.begin();
	for(;i != oldList.end();i++)
	{
		list<uint32>::iterator j = std::find(newList.begin(),newList.end(),*i);
		if(j == newList.end())	// 退出帮派
		{
			ShareUserPtr p = onlineUser.GetUserByRoleId(*j);
			if(p.get() != NULL)
				p->UpdateBangPai();
		}
	}
}

void CBangPai::KF_ReadSkill(CNetMessage &msg)
{
	m_lianqi_vec.clear();
	m_skills.clear();
	uint8 num = 0;
	uint8 skillNum = 0;
	msg>>num;
	for(int i=0;i<num;i++)
	{
		uint8 level = 0;
		msg>>level;
		m_lianqi_vec.push_back(level);
	}
	msg>>skillNum;
	for(int i=0;i<skillNum;i++)
	{
		uint16 id = 0;
		uint8 level = 0;
		msg>>id>>level;
		m_skills[id] = level;
	}
}

#endif

void CBangPai::MakeSkillInfo(CNetMessage &msg)
{
	vector<uint8> lianQiVec;
	GetLianQiPavilionLv(lianQiVec);
	uint8 lianQiSize = lianQiVec.size();
	if(lianQiSize > 0)
	{
		msg<<lianQiSize;
	}
	for(int i=0;i<lianQiSize;i++)
	{
		msg<<lianQiVec[i];
	}
	vector<SAttrTypeValue> skillVec;
	GetSkillLv(skillVec);
	uint8 skillSize = skillVec.size();
	if (skillSize > 0)
	{
		msg<<skillSize;
	}
	for(int i=0;i<skillSize;i++)
	{
		msg<<(uint16)skillVec[i].type<<(uint8)skillVec[i].value;
	}
}

void CBangPai::ReadMember()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
	char buf[256];
	//                           0   1      2         3          4
	snprintf(buf,sizeof(buf),"select role_id,`rank`,join_time,total_bangGong,huoyue from bang_pai_role where bangpai_id=%d order by `rank`",m_id);
	if(pDb->Query(buf))
	{
		char **row = NULL;
		uint32 maxNum = BP_MEMBER_NUM_LIMIT[m_level-1];
		while((row = pDb->GetRow()) != NULL)
		{
			if(m_userList.size() >= maxNum)
				return;
			SBangPaiMember m;
			m.roleId = (uint32)atoi(row[0]);
			m.rank = (uint8)atoi(row[1]);
			m.utime = (uint32)atoi(row[2]);
			m.total_gongXian = (uint32)atoi(row[3]);
			m.huoyue_day = (uint32)atoi(row[4]);
			m_userList.push_back(m.roleId);

			if(!m_allMember.insert(make_pair(m.roleId, m)).second)
				cout<<"Error:CBangPai::ReadMember() insert error"<<endl;
		}
	}
}

void CBangPai::CheckBangZhu()
{
	bool haveBangZhu = false;
	for(map<uint32,SBangPaiMember>::iterator i = m_allMember.begin(); i != m_allMember.end(); i++)
	{
		SBangPaiMember &mem = i->second;
		if(mem.rank == EBRBangZhu)
		{
			haveBangZhu = true;
			break;
		}
	}
	if(!haveBangZhu)
	{
		SRoleSimpleData tdata;
		map<uint32,SBangPaiMember>::iterator t = m_allMember.end();
		for(map<uint32,SBangPaiMember>::iterator i = m_allMember.begin(); i != m_allMember.end(); i++)
		{
			SRoleSimpleData data;
			if(!SingletonCSimpleRoleDataMgr::instance().GetRoleData(i->first, data))
				continue;
			if(t == m_allMember.end())
			{
				t = i;
				tdata = data;
				if(tdata.lastLoginTime == 0)
					break;
				else
					continue;
			}
			
			if(data.lastLoginTime == 0)
			{
				t = i;
				tdata = data;
				break;
			}
			else if(tdata.lastLoginTime < data.lastLoginTime)
			{
				t = i;
				tdata = data;
			}
		}

		if (t != m_allMember.end())
			SetMemberRank(t->second.roleId, EBRBangZhu);
	}
}

bool CBangPai::CheckDeleteBangPai(int time)
{
	uint16 size = m_allMember.size();
	if(size <= 10)
	{
		// 帮主7天不上线删除
		for(map<uint32,SBangPaiMember>::iterator i = m_allMember.begin(); i != m_allMember.end(); i++)
		{
			SBangPaiMember &mem = i->second;
			if(mem.rank == EBRBangZhu)
			{
				SRoleSimpleData data;
				if(!SingletonCSimpleRoleDataMgr::instance().GetRoleData(mem.roleId, data))
					return false;
				if(data.lastLoginTime > 0 && (time - (int)data.lastLoginTime > 7*24*3600))
					return true;
				else
					return false;
			}
		}
	}
	else	// 大于10人
	{
		// 帮派所有成员7天不上线删除
		for(map<uint32,SBangPaiMember>::iterator i = m_allMember.begin(); i != m_allMember.end(); i++)
		{
			SBangPaiMember &mem = i->second;
			SRoleSimpleData data;
			if(!SingletonCSimpleRoleDataMgr::instance().GetRoleData(mem.roleId, data))
				return false;
			if(data.lastLoginTime == 0 || (time - (int)data.lastLoginTime < 7*24*3600))
				return false;
		}
	}
	return true;
}

void CBangPai::Save()
{
	char buf[2048];
	uint8 num = m_userList.size();
	snprintf(buf,sizeof(buf),"%d|%d|%d|%d",(int)num,(int)m_tangzhu_rank,(int)m_bangzhu_old,ZhongZhiMax?1:0);

	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
#ifndef KUA_FU
	boost::format fmt("update bang_pai set info='%1%',level=%2%,fanrong=%3%,money=%4%,kouhao='%5%',gonggao='%6%',copy='%7%',res2=%8%,res3=%9%,res4=%10%,"\
		"chuanwei=%11%,jiesan_time=%12%,activity=%13%,`rank`=%14%,gongXian=%15%,exp=%16%,fireState=%17%,onFireTime=%18%,robNum=%19%,robExp=%20%,"\
		"treeExp=%21%,prayExp=%22%,treeLv=%23%,prayNum=%24%,addTreeExpTime=%25%,memberReward='%26%',treeTotalExp=%27%,bz_jifen=%29%,"\
		"xianzhun_lv=%30%,yingxiangli=%31%,shangxian_info='%32%',mission='%33%',juanxian_rank='%34%',pic=%35%,auto_limit_lv=%36%,huoyue=%37%,lianqi_lv='%38%',skills='%39%' where id=%28%");
	
	stringstream memberReward;
	string shangxianInfo;
	string mission;
	string juanxian;
	string lianqiLv;
	string skills;
	string copy;
	GetSX_Info(shangxianInfo);
	GetMissionStr(mission);
	GetJuanXianPaiHang(juanxian);
	GetLianQiLvStr(lianqiLv);
	GetBangSkill(skills);
	GetCopyStr(copy);
	memberReward<<m_yesterdayBangGong<<'|'<<m_todayBangGong;
	for(uint8 i=0;i < sizeof(m_memberGetRewardNum)/sizeof(m_memberGetRewardNum[0]);i++)
		memberReward<<'|'<<(int)m_memberGetRewardNum[i];

	fmt % buf % (int)m_level % m_fanrong % m_money % m_kouhao % m_gonggao % copy % 0 % 0 % 0
		% m_chuangwei % dismissbang_time % activity % m_rank % m_totolGongXian % m_exp % (int)m_fireState % m_onFireTime % (int)m_treeRobbedNum % m_treeRobbedExp 
		% m_treeExp % m_prayExp % (int)m_treeLv % m_prayNum % m_addTreeExpTime % memberReward.str() % m_treeTotalExp % m_BZ_jifen
		% m_xianzhun_lv % m_yingxiangli % shangxianInfo % mission % juanxian % m_pic % m_autoLimitLv % m_huoyue % lianqiLv % skills
		% m_id; 
#else
	boost::format fmt("update bang_pai set info='%1%',level=%2%,fanrong=%3%,money=%4%,kouhao='%5%',gonggao='%6%',copy='%7%',res2=%8%,res3=%9%,res4=%10%,"\
		"chuanwei=%11%,jiesan_time=%12%,activity=%13%,`rank`=%14%,gongXian=%15%,exp=%16%,fireState=%17%,onFireTime=%18%,robNum=%19%,robExp=%20%,"\
		"treeExp=%21%,prayExp=%22%,treeLv=%23%,prayNum=%24%,addTreeExpTime=%25%,memberReward='%26%',treeTotalExp=%27%,bz_jifen=%29%,kfbz_jifen=%30%,"\
		"kfbz_jifen_final=%31%,auto_limit_lv=%32%,huoyue=%33%,lianqi_lv='%34%',skills='%35%' where id=%28%");
	
	stringstream memberReward;
	memberReward<<m_yesterdayBangGong<<'|'<<m_todayBangGong;
	for(uint8 i=0;i < sizeof(m_memberGetRewardNum)/sizeof(m_memberGetRewardNum[0]);i++)
		memberReward<<'|'<<(int)m_memberGetRewardNum[i];
	string lianqiLv;
	string skills;
	string copy;
	GetLianQiLvStr(lianqiLv);
	GetBangSkill(skills);
	GetCopyStr(copy);

	fmt % buf % (int)m_level % m_fanrong % m_money % m_kouhao % m_gonggao % copy % 0 % 0 % 0
		% m_chuangwei % dismissbang_time % activity % m_rank % m_totolGongXian % m_exp % (int)m_fireState % m_onFireTime % (int)m_treeRobbedNum % m_treeRobbedExp 
		% m_treeExp % m_prayExp % (int)m_treeLv % m_prayNum % m_addTreeExpTime % memberReward.str() % m_treeTotalExp % m_BZ_jifen
		% m_kfBZ_jifen % m_kfBZ_jifen_final % m_autoLimitLv % m_huoyue % lianqiLv % skills
		% m_id;
#endif
	pDb->Query(fmt.str().c_str());
}

// 发送帮派信息
void CBangPai::Say(const char* info)
{
	CNetMessage msg;
	msg.SetType(PRO_MSG_CHAT);
	msg<<(uint8)4<<0<<LANGUAGE_TRANSFORM_422<<(uint8)0<<info;
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	CSocketServer &sock = SingletonSocket::instance();
	for(list<uint32>::iterator i = m_userList.begin(); i != m_userList.end(); i++)
	{
		ShareUserPtr ptr = onlineUser.GetUserByRoleId(*i);
		if(ptr.get() != NULL)
		{
			sock.SendMsg(ptr->GetSock(),msg);
		}
	}
}

void CBangPai::TipsToAllOnLineMembers(const char* info)
{
	if(info == NULL)
		return;

	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(map<uint32,SBangPaiMember>::iterator i = m_allMember.begin(); i != m_allMember.end(); i++)
	{
		ShareUserPtr ptr = onlineUser.GetUserByRoleId(i->first);
		if(ptr.get() != NULL)
			SendSysInfo(ptr.get(),info);
	}
}

void CBangPai::ShowTaskList(CUser *pUser,CNetMessage &msg)
{
	if(pUser == NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0061,TIPS_FAILURE_COLOR);
		return;
	}
	
	const vector<SBangPaiMission> &pMissList = SingletonCBangPaiManager::instance().GetMissionListData();
	if(pMissList.empty())
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0061,TIPS_FAILURE_COLOR);
		return;
	}
	msg<<PRO_SUCCESS;

	vector<SBPMission_SelfData> mission;
	uint16 size = pMissList.size();
	uint16 num = 0;
	//uint16 numPos = msg.GetDataLen();
	//msg<<num;

	CNetMessage omsg;

	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if(m_mission.empty())
		{
			UpdateMission(SingletonCBangPaiManager::instance().GetMissionListData());
		}
		mission = m_mission;
	}

	for(uint16 i=0;i < mission.size();i++)
	{
		//if(mission[i].isSelect == 1)	// 已发布
//		cout<<" bang pai mission open "<< mission[i].isSelect <<endl;
		for(uint16 j=0;j < size;j++)
		{
			const SBangPaiMission &mData = pMissList[j];
			if(mData.id == (uint32)mission[i].missionId)
			{
				omsg<<(uint32)mission[i].missionId<<mData.name<<mData.desc;
				omsg<<(uint32)mData.type<<(uint32)mData.award_itemId<<(uint32)mData.award_itemNum;
				omsg<<(uint32)mData.award_type<<(uint32)mData.award_num;
				omsg<<(uint32)mData.value;
				uint32 completeNum = 0;
				if(mData.type == 1)
					completeNum = pUser->GetJuanXianMoney();
				else if(mData.type == 2)
					completeNum = pUser->GetJiaoYouCount();
				else if(mData.type == 3)
					completeNum = pUser->GetCheckYanShengShiCount();
				else if(mData.type == 4)
					completeNum = pUser->GetCheckDuoXianYinCount();
				else if(mData.type == 5)
					completeNum = pUser->GetQiMouCount();
				else if(mData.type == 6)
					completeNum = pUser->GetPlantWateringCount();
				else if(mData.type == 7)
					completeNum = pUser->GetPlantKillBugCount();
				else if(mData.type == 8)
					completeNum = pUser->GetPlantPlantsCount();
				else if(mData.type == 9)
					completeNum = pUser->GetPlantStealCount();
				else if(mData.type == 10)
					completeNum = pUser->GetKillPlayerCount();

				uint8 buttonState = 0;	// 0未完成1已完成未领奖 2已完成已领奖
				if(completeNum >= mData.value)
				{
					completeNum = mData.value;
					if(pUser->IsGetBangPaiTaskAward(mission[i].missionId))
						buttonState = 2;
					else
						buttonState = 1;
				}

				omsg<<(uint32)completeNum<<(uint8)buttonState;

				SAttrTypeValue huoyueInfo;
				pUser->GetBangHuoYueDesc(mData.id,huoyueInfo);
				omsg<<(uint8)huoyueInfo.type<<(uint8)huoyueInfo.value;
				if(mData.id == EBHT_JoinBangZhan)
				{
					omsg<<(uint32)CBangPaiManager::BP_FIGHT_ROLE_LIMIT_LV; // 开放等级
					omsg<< LANGUAGE_CC_0007;
					omsg<<(uint32)0;
				}
				num++;
				break;
			}
		}
	}
	for(uint16 i=mission.size();i<size;i++)
	{
		const SBangPaiMission &mData = pMissList[i];
		if(mData.type != 0)
			continue;
		SAttrTypeValue huoyueInfo;
		if(!pUser->GetBangHuoYueDesc(mData.id,huoyueInfo))
			continue;
		
		omsg<<(uint32)mData.id<<mData.name<<mData.desc;
		omsg<<(uint32)mData.type<<(uint32)mData.award_itemId<<(uint32)mData.award_itemNum;
		omsg<<(uint32)mData.award_type<<(uint32)mData.award_num;
		omsg<<(uint32)mData.value<<(uint32)0<<(uint8)0;

		omsg<<(uint8)huoyueInfo.type<<(uint8)huoyueInfo.value;
		if(mData.id == EBHT_JoinBangZhan)
		{
			omsg<<(uint32)CBangPaiManager::BP_FIGHT_ROLE_LIMIT_LV; // 开放等级
			omsg<< LANGUAGE_CC_0007;
			omsg<<(uint32)0;
		}
		num++;
	}

	uint8 buttonState = 3 + (uint8)CSceneManager::IsInActivityTime(SOT_BangPaiLueDuo);

	omsg<<(uint32)34<<"帮派掠夺"<<"通过掠夺其他帮派神树，获得大量帮贡，并为所在帮派增加帮派经验。";
	omsg<<(uint32)34<<(uint32)0<<(uint32)0; //TODO 
	omsg<<(uint32)1<<(uint32)10;
	omsg<<(uint32)0;
	omsg<<(uint32)0<<(uint8)buttonState<<(uint8)0<<(uint8)0;
	omsg<<(uint32)30; // 开放等级
	omsg<< GetBangPaiRobTime();
	omsg<<(uint32)1; // 奖励的总数,便于后续解析数据
	omsg<<(uint32)1; // 奖励帮贡
	omsg<<(uint32)1; // 奖励帮贡
	num++;
//	cout<<" bang pai mission num "<< num <<endl;

	msg<<num;
	msg<<omsg;
	//msg.WriteData(numPos,&num,sizeof(num));
}

void CBangPai::GetPublishTaskList(CUser *pUser,CNetMessage &msg)
{
	if(pUser == NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0061,TIPS_FAILURE_COLOR);
		return;
	}
	if(!IsAdmin(pUser->GetRoleId()))
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0289,TIPS_FAILURE_COLOR);
		return;
	}
	char buf[256];
	if(m_xianzhun_lv < ZXG_TASK_OPEN_LV)
	{
		snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0352,ZXG_TASK_OPEN_LV);
		msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
		return;
	}

	const vector<SBangPaiMission> &pMissList = SingletonCBangPaiManager::instance().GetMissionListData();
	if(pMissList.empty())
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0061,TIPS_FAILURE_COLOR);
		return;
	}
	msg<<PRO_SUCCESS;
	vector<SBPMission_SelfData> mission;
	uint16 size = pMissList.size();
	uint16 num = 0;
	uint16 numPos = msg.GetDataLen();
	msg<<(uint16)num;

	int publishNum = 0;
	int canPublishNum = 0;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if(m_mission.empty())
		{
			UpdateMission(SingletonCBangPaiManager::instance().GetMissionListData());
			if(GetHour() == 23)
				m_updateMission = 0;
		}
		mission = m_mission;

		canPublishNum = GetZXG_MaxMissionNum(m_xianzhun_lv);
		for(uint16 i=0;i < size;i++)
		{
			if(m_mission[i].isSelect == 1)
				publishNum++;
		}
	}
	for(uint16 i=0;i < mission.size();i++)
	{
		if(mission[i].isSelect == 0)	// 未发布
		{
			for(uint16 j=0;j < size;j++)
			{
				const SBangPaiMission &mData = pMissList[j];
				if(mData.id == (uint32)mission[i].missionId)
				{
					msg<<mission[i].missionId<<mData.name<<mData.desc<<mData.type<<mData.award_itemId<<mData.award_itemNum<<mData.award_type<<mData.award_num;
					num++;
					break;
				}
			}
		}
	}
	msg<<(canPublishNum-publishNum);
	msg.WriteData(numPos,&num,sizeof(num));
}

void CBangPai::PublishTask(CUser *pUser,CNetMessage &msg,int missionId)
{
	if(pUser == NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0061,TIPS_FAILURE_COLOR);
		return;
	}
	if(!IsAdmin(pUser->GetRoleId()))
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0289,TIPS_FAILURE_COLOR);
		return;
	}
	char buf[256];
	if(m_xianzhun_lv < ZXG_TASK_OPEN_LV)
	{
		snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0352,ZXG_TASK_OPEN_LV);
		msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
		return;
	}

	const vector<SBangPaiMission> &pMissList = SingletonCBangPaiManager::instance().GetMissionListData();
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	uint16 size = m_mission.size();
	int publishNum = 0;
	int canPublishNum = GetZXG_MaxMissionNum(m_xianzhun_lv);
	for(uint16 i=0;i < size;i++)
	{
		if(m_mission[i].isSelect == 1)
			publishNum++;
	}
	if(publishNum >= canPublishNum)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0321,TIPS_FAILURE_COLOR);
		return;
	}
	for(uint16 i=0;i < size;i++)
	{
		if(m_mission[i].missionId == missionId)
		{
			if(m_mission[i].isSelect == 1)	// 已发布
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0320,TIPS_FAILURE_COLOR);
				return;
			}

			m_mission[i].isSelect = 1;
			msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_SSJ_0322,TIPS_WARNING_COLOR);

			for(uint16 j=0;j < pMissList.size();j++)
			{
				if(pMissList[j].id == (uint32)missionId)
				{
					SaveLog(pUser->GetRoleId(),0,EBLT_PUBLISH_TASK,pMissList[j].desc.c_str());
					return;
				}
			}
			return;
		}
	}
	msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0323,TIPS_FAILURE_COLOR);
}


void CBangPai::TakeTaskAward(CUser *pUser,CNetMessage &msg,int missionId)
{
	if(pUser == NULL || missionId < 1)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0061,TIPS_FAILURE_COLOR);
		return;
	}

	const vector<SBangPaiMission> &pMissList = SingletonCBangPaiManager::instance().GetMissionListData();
	if(pMissList.empty())
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0061,TIPS_FAILURE_COLOR);
		return;
	}
	if(pUser->IsGetBangPaiTaskAward(missionId))
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0325,TIPS_FAILURE_COLOR);
		return;
	}

	char buf[512];
	vector<SBPMission_SelfData> missionList;
	uint16 size = pMissList.size();
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		missionList = m_mission;
	}
	for(uint16 i=0;i < missionList.size();i++)
	{
		missionList[i].isSelect = 1; // 强制任务发布
		
		if(missionList[i].missionId == missionId)
		{
			if(missionList[i].isSelect == 0)
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0324,TIPS_FAILURE_COLOR);
				return;
			}

			for(uint16 j=0;j < size;j++)
			{
				const SBangPaiMission &mData = pMissList[j];
				if(mData.id == (uint32)missionId)
				{
					int completeNum = 0;
					if(mData.type == 1)
						completeNum = pUser->GetJuanXianMoney();
					else if(mData.type == 2)
						completeNum = pUser->GetJiaoYouCount();
					else if(mData.type == 3)
						completeNum = pUser->GetCheckYanShengShiCount();
					else if(mData.type == 4)
						completeNum = pUser->GetCheckDuoXianYinCount();
					else if(mData.type == 5)
						completeNum = pUser->GetQiMouCount();
					else if(mData.type == 6)
						completeNum = pUser->GetPlantWateringCount();
					else if(mData.type == 7)
						completeNum = pUser->GetPlantKillBugCount();
					else if(mData.type == 8)
						completeNum = pUser->GetPlantPlantsCount();
					else if(mData.type == 9)
						completeNum = pUser->GetPlantStealCount();
					else if(mData.type == 10)
						completeNum = pUser->GetKillPlayerCount();

					if((uint32)completeNum < mData.value)
					{
						msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0326,TIPS_FAILURE_COLOR);
						return;
					}
					pUser->SetBangPaiTaskAward(missionId);
					pUser->AddBangDingPackage(mData.award_itemId, mData.award_itemNum);
					if(mData.award_type == 1)
					{
						SingletonCBangPaiManager::instance().AddBangGong(pUser, mData.award_num,false);
						snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0327,GetItemName(mData.award_itemId),mData.award_itemNum,LANGUAGE_SSJ_0306,mData.award_num);
					}
					else if(mData.award_type == 3)
					{
						SetMoney(m_money+mData.award_num);
						snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0327,GetItemName(mData.award_itemId),mData.award_itemNum,LANGUAGE_SSJ_0308,mData.award_num);
					}
					else if(mData.award_type == 4)
					{
						SetYingXiangLi(m_yingxiangli+mData.award_num);
						snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0327,GetItemName(mData.award_itemId),mData.award_itemNum,LANGUAGE_SSJ_0309,mData.award_num);
					}
					msg<<PRO_SUCCESS<<MakeStringColor(buf,TIPS_WARNING_COLOR);

					int exp = SingletonHuoDongExpManager::instance().GetHuoDongExp(23,pUser->GetLevel(),0.167);
					pUser->AddExp(exp,true);
					SaveLog(pUser->GetRoleId(),0,EBLT_GET_TASK_AWARD,mData.desc.c_str(),buf);

					// ==================
					// 更新帮派活动任务
					int curCnt = pUser->GetExtData16(146);
					if (curCnt < 65535)
					{
						pUser->SetExtData16(146, curCnt + 1);
					}
					SingletonCMissionManager::instance().VerifyNewBranchMissionFinish(pUser, EMISS_DC_19); // TODO
					return;
				}
			}
			break;
		}
	}
	msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0328,TIPS_FAILURE_COLOR);
}

//	  需要金币，增加帮派资金，个人帮贡
static const int JuanXianData[][3] = {{1,10,25},{5,50,125},{20,200,500}};

void CBangPai::GetJuanXianInfo(CUser *pUser,CNetMessage &msg)
{
	if(pUser == NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0061,TIPS_FAILURE_COLOR);
		return;
	}

	uint8 size = sizeof(JuanXianData)/sizeof(JuanXianData[0]);
	msg<<PRO_SUCCESS<<size;
	for(uint8 i=0;i < size;i++)
		msg<<(uint8)(i+1)<<JuanXianData[i][0]<<JuanXianData[i][1]<<JuanXianData[i][2];
}

void CBangPai::JuanXian(CUser *pUser, CNetMessage &msg, uint8 type)
{
	if(pUser == NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0061,TIPS_FAILURE_COLOR);
		return;
	}

	uint8 size = sizeof(JuanXianData)/sizeof(JuanXianData[0]);
	char buf[512];
	if(type == 0 || type > size)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0061,TIPS_FAILURE_COLOR);
		return;
	}
	int money = MoneyRatio*JuanXianData[type-1][0];
	int bpMoney = JuanXianData[type-1][1];
	if(pUser->GetMoney() < money)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0329,TIPS_FAILURE_COLOR);
		return;
	}
	pUser->AddMoney(-money);
	pUser->AddJuanXianMoney(JuanXianData[type - 1][0]);
	AddMoney(bpMoney);
	SingletonCBangPaiManager::instance().AddBangGong(pUser,JuanXianData[type-1][2]);
	snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0340,bpMoney);
	msg<<PRO_SUCCESS<<MakeStringColor(buf,TIPS_WARNING_COLOR);

	char tmp[512];
	snprintf(tmp,sizeof(tmp),LANGUAGE_SSJ_0361,pUser->GetName(),JuanXianData[type-1][0]);
	SaveLog(pUser->GetRoleId(),0,EBLT_JUANXIAN,tmp,buf);

	AddJuanXianPaiHangData(pUser->GetRoleId(),pUser->GetJuanXianMoney(),pUser->GetName());
	SingletonCMissionManager::instance().UpdateDCMissionComplate(pUser, EMISS_DC_54);
	UpdateHuoYue(pUser,EBHT_JuanXian);
}

void CBangPai::AddJuanXianPaiHangData(uint32 roleId,int money,string name)
{
	if(roleId == 0 || money <= 0)
		return;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint32 i=0;i < m_juanxianPaiHang.size();i++)
	{
		SBP_JuanXianPaiHang &data = m_juanxianPaiHang[i];
		if(data.roleId == roleId)
		{
			data.name = name;
			data.money = money;
			return;
		}
	}
	SBP_JuanXianPaiHang phData;
	phData.roleId = roleId;
	phData.name = name;
	phData.money = money;
	m_juanxianPaiHang.push_back(phData);
}

void CBangPai::MakeJuanXianPaiHang(CNetMessage &msg)
{
	const uint32 SHOW_NUM = 10;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	uint32 size = m_juanxianPaiHang.size();
	if(size > 1)
	{
		SSortBP_JuanXian sortFunc;
		std::sort(m_juanxianPaiHang.begin(),m_juanxianPaiHang.end(),sortFunc);
	}

	size = (size > SHOW_NUM) ? SHOW_NUM : size;
	msg<<size;
	for(uint32 i=0;i < size;i++)
	{
		SBP_JuanXianPaiHang &data = m_juanxianPaiHang[i];
		msg<<data.roleId<<data.name<<data.money;
	}
}

string CBangPai::GetBangZhuName()
{
	uint32 roleId = GetBangZhu();
	if(roleId == 0)
		return "";
	return SingletonCSimpleRoleDataMgr::instance().GetUserColorName(roleId);
}

void CBangPai::SetChectBangPaiTarget(CUser *pUser,CNetMessage &msg,uint8 type,int tarBP_id)
{
	if(pUser == NULL || type == 0 || type > 2)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0061,TIPS_FAILURE_COLOR);
		return;
	}
	if(pUser->GetBangPai() == (uint32)tarBP_id)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0343,TIPS_FAILURE_COLOR);
		return;
	}
	if(tarBP_id != 1 && tarBP_id != 2)
	{
		CBangPai *pTar = SingletonCBangPaiManager::instance().FindBangPai(tarBP_id);
		if(pTar == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0344,TIPS_FAILURE_COLOR);
			return;
		}
	}

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(type == 1)	// 设置
	{
		m_tarCheChaBangId = tarBP_id;
		msg<<PRO_SUCCESS<<LANGUAGE_SSJ_0345;
	}
	else if(type == 2)	// 取消
	{
		m_tarCheChaBangId = 0;
		msg<<PRO_SUCCESS<<LANGUAGE_SSJ_0346;
	}
}

void CBangPai::SetAutoAcceptSign(uint16 level)
{	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_autoLimitLv = level;
}

uint16 CBangPai::GetAutoAcceptLv()
{
	return m_autoLimitLv;
}

void CBangPai::UpdateHuoYue(CUser *pUser,int type,int num)
{
	#ifdef KUA_FU
		return;
	#endif	
	if (pUser == NULL || type < 1 || type >= EBHT_MAX)
		return;
	if (pUser->GetBangPai() != m_id)
		return;
	int index = 650+type;
	uint8 cur = pUser->GetExtData8(index);	
	int max = SingletonCBPHuoYueCfgMgr::instance().GetParam(type);
	bool sign = true;
	if (max > 0 && cur >= max)
	{
		return;
	}
	int huoyue = SingletonCBPHuoYueCfgMgr::instance().GetHuoYue(type);
	if (huoyue < 1)
		return;
	switch(type)
	{
		case EBHT_OnLineTime1:
		case EBHT_OnLineTime2:
		case EBHT_OnLineTime3:
		    cur = pUser->GetExtData32(98)/60;
		    sign = false;
			break;
		case EBHT_ShopBuy:
		    cur += num;
		    break;
		default:
		    cur +=1;
			break;
	}
	if (max > 0 && cur > max)
		cur = max;
	pUser->SetExtData8(index,cur);
	
	if (sign || cur >= max)
	{
		int value = pUser->AddBangHuoYue(huoyue);
		if (value > 0)
		{
			AddHuoYue(value);
			AddMemberHuoYue(pUser->GetRoleId(),value);
			UpdateBangGong(pUser,pUser->GetBangGong(), GetMoney(),GetHuoYue(),pUser->GetExtData16(67));
		}
	}
}

void CBangPai::UpdateMemberHuoYue(uint32 roleId, uint32 huoyue)
{
	if (roleId == 0)
		return;
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,SBangPaiMember>::iterator it = m_allMember.find(roleId);
	if(it == m_allMember.end())
		return;
	it->second.huoyue_day = huoyue;
}

void CBangPai::UpdateHuoYue_KuaFu(CUser *pUser,int type)
{
	#ifndef KUA_FU
		return;
	#endif	
	if (pUser == NULL || type < 1 || type < EBHT_OnLineTime1 || type > EBHT_OnLineTime3)
		return;
	if (pUser->GetBangPai() != m_id)
		return;
	int index = 650+type;
	uint8 cur = pUser->GetExtData8(index);	
	int max = SingletonCBPHuoYueCfgMgr::instance().GetParam(type);
	if (max > 0 && cur >= max-1)
		return;
	int huoyue = SingletonCBPHuoYueCfgMgr::instance().GetHuoYue(type);
	if (huoyue < 1)
		return;
	cur = pUser->GetExtData32(98)/60;
	if (max > 0 && cur >= max)
		cur = max-1;
	pUser->SetExtData8(index,cur);
}
	
void CBangPai::AddMemberHuoYue(uint32 roleid,int huoyue)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,SBangPaiMember>::iterator it = m_allMember.find(roleid);
	if(it == m_allMember.end())
		return;
	it->second.huoyue_day += huoyue;
}

uint16 CBangPai::GetMemberHuoYue(uint32 roleid)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,SBangPaiMember>::iterator it = m_allMember.find(roleid);
	if(it == m_allMember.end())
		return 0;
	return it->second.huoyue_day;
}

void CBangPai::ResetHuoYue()
{
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		m_huoyue = 0;
		for(map<uint32, SBangPaiMember>::iterator it = m_allMember.begin(); it != m_allMember.end(); it++)
		{
			m_huoyue += it->second.huoyue_day;
			it->second.huoyue_day = 0;
		}
	}
	CheckHotPoint(EHPoint_BP_UpgradeSkill);
}

//领取活跃奖励，@type 1-个人，2-帮派
void CBangPai::DrawHuoYue(CNetMessage &msg,CUser *pUser,int type,int huoyue)
{
	if (pUser == NULL || type < 1 ||type > 2)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1583,TIPS_FAILURE_COLOR);
		return;
	}
	if (pUser->GetBangPai() != m_id)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1583,TIPS_FAILURE_COLOR);
		return;
	}
	SBangPaiHuoYueReward cfgData;
	SingletonCBPRewardCfgMgr::instance().GetCfg(type,huoyue,cfgData);
	if (pUser->HaveBitSet(cfgData.idx))
	{
		//提示错误：已领取
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1582,TIPS_FAILURE_COLOR);
		return;
	}
	
	if (type == 1)
	{
		if(pUser->GetExtData16(67) < huoyue)
		{
			//提示错误：活跃不足
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1581,TIPS_FAILURE_COLOR);
			return;
		}   
	}
	else if(type == 2)
	{
		if(m_huoyue < huoyue)
		{
			//提示错误：活跃不足
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1581,TIPS_FAILURE_COLOR);
			return;
		}
	}
	int num = 0;
	for (int i=651;i<676;++i)
	{
		num +=pUser->GetExtData8(i);
	}
	if (num == 0)//排错
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1583,TIPS_FAILURE_COLOR);
		return;
	}
	pUser->SetBitSet(cfgData.idx);
	//发放奖励
	std::vector<SAwardData> awvec;
	SingletonAwardManager::instance().GetAwardById(cfgData.rewardid, awvec);
	for (uint16 i = 0; i < awvec.size(); ++i)
	{
		pUser->AddMaterial(awvec[i], true, true);
	}
	msg<<PRO_SUCCESS;
}

void CBangPai::AddHuoYue(int huoYue)
{
	int max = SingletonCBPRewardCfgMgr::instance().GetMaxHuoYue(2);
	if (max == 0)
		return;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_huoyue += huoYue;
	if (m_huoyue > max)
		m_huoyue = max;
}

void CBangPai::AddUserHuoYue(CUser *pUser, int addHuoYue)
{
	if(pUser == NULL || addHuoYue <= 0)
		return;
	pUser->SetExtData32(EData32_HuoYueDu_Day, pUser->GetExtData32(EData32_HuoYueDu_Day)+addHuoYue);
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,SBangPaiMember>::iterator it = m_allMember.find(pUser->GetRoleId());
	if(it == m_allMember.end())
		return;
	it->second.huoyue_day += addHuoYue;
}


void CBangPai::SetHuoYue(int huoYue)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_huoyue = huoYue;
}

int CBangPai::GetHuoYue()
{
	return m_huoyue;
}

void CBangPai::UpgradeLianQiPavilion(CUser *pUser,uint8 type,CNetMessage &msg)
{
	if (pUser == NULL || type < 1 || type > m_lianqi_vec.size())
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1583,TIPS_FAILURE_COLOR);
		return;
	}
	//炼器阁等级不可以大于帮派等级
	if (m_lianqi_vec[type-1] >= m_level)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_CC_0005,TIPS_FAILURE_COLOR);
		return;
	}
 	SBangPaiLianQiData cfgData;
	if(!sCBPLianQiCfgMgr.GetCfg(m_lianqi_vec[type-1],type,cfgData))
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1583,TIPS_FAILURE_COLOR);
		return;
	}
	//判断资金是否足够
    if (cfgData.money > m_money)
    {
    	msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0292,TIPS_FAILURE_COLOR);
    	return;
    }
	//扣除资金
	AddMoney(-1*cfgData.money);
	//升级炼器阁等级
	AddLianQiPavilionLv(type);
	UpdateBangGong(pUser,pUser->GetBangGong(), GetMoney(),GetHuoYue(),pUser->GetExtData16(67));
	msg<<PRO_SUCCESS<<GetLianQiPavilionLv(type);
}

uint8 CBangPai::GetLianQiPavilionLv(uint8 type)
{
    boost::recursive_mutex::scoped_lock lk(m_mutex);
	if (type == 0 || type > m_lianqi_vec.size())
		return 0;
	return m_lianqi_vec[type-1];
}

void CBangPai::GetLianQiPavilionLv(vector<uint8> &vec)
{
	vec.clear();
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint8 i=0;i<m_lianqi_vec.size();i++)
	{
	    vec.push_back(m_lianqi_vec[i]);
    }
}

void CBangPai::AddLianQiPavilionLv(uint8 type)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if (type > 0 && type <= m_lianqi_vec.size())
		m_lianqi_vec[type-1] += 1;
}

void CBangPai::SetLianQiLv(const char *level)
{
	int max = sCBPLianQiCfgMgr.GetMaxType();
	if(m_lianqi_vec.size() < (uint8)max)
	{
		m_lianqi_vec.assign(max,0);
	}
	char buf[128];
	char *p[10];
	int num = 0;
	strncpy(buf,level,sizeof(buf));
	num = SplitLine(p,buf,'|');
	if (num > max)
		num = max;
	for(int i=0;i<num;i++)
	{
		m_lianqi_vec[i] = (uint8)atoi(p[i]);
	}
}

void CBangPai::InitLianQiLv()
{
	int max = sCBPLianQiCfgMgr.GetMaxType();
	m_lianqi_vec.assign(max,0);
}

void CBangPai::GetLianQiLvStr(string &str)
{
	str.clear();
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	int max = m_lianqi_vec.size();
	for(uint8 i=0;i<max;i++)
	{
		if (i > 0)
		{
			str += "|";
		}
		str += IntToStr(m_lianqi_vec[i]);
	}
}

//升级技能等级
void CBangPai::UpSkillLv(CNetMessage &msg,CUser *pUser,int id,bool isAuto)
{
    if(pUser == NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1583,TIPS_FAILURE_COLOR);
		return;
	}
	
	SBangPaiSkillData cfgData;
	sCBPSkillCfgMgr.GetCfg(id,m_skills[id],cfgData);
	if (cfgData.id < 1)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1583,TIPS_FAILURE_COLOR);
		return;
	}
	for(int i=0;i<(int)cfgData.cost.size();i++)
	{
		if(cfgData.cost[i].costType == HDAT_BANGPAI_MONEY)
		{
			if(m_money < cfgData.cost[i].costValue)
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0292,TIPS_FAILURE_COLOR);
				return;
			}
			AddMoney(-1*cfgData.cost[i].costValue);
		}
	}
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<int,int>::iterator it = m_skills.find(id);
	if (it == m_skills.end())
	{
		m_skills[id] = 1;
	}
	else
	{
		if(m_level < (m_skills[id]+1))
		{
			//提示错误
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_CC_0005,TIPS_FAILURE_COLOR);
			return;
		}
		if (isAuto)
		{
			m_skills[id] = m_level;
		}
		else
		{
			m_skills[id] += 1;
		}
	}
	msg<<PRO_SUCCESS<<(uint8)m_skills[id];
}

int CBangPai::GetSkillLv(int id)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return m_skills[id];
}

void CBangPai::GetSkillLv(vector<SAttrTypeValue> &vec)
{
	vec.clear();
	vector<int> skillIds;
	sCBPSkillCfgMgr.GetSkillIds(skillIds);
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for (int i=0;i<(int)skillIds.size();i++)
	{
		SAttrTypeValue val;
		val.type = skillIds[i];
		val.value = m_skills[val.type];
		vec.push_back(val);
	}
}

void CBangPai::SetBangSkill(const char *skills)
{
	char buf[256];
	char *p[10];
	strncpy(buf,skills,sizeof(buf));
	int num = SplitLine(p,buf,'|');
	for(int i=0;i<num;i++)
	{
		char tbuf[64];
		int tnum = 0;
		char *tp[2];
		strncpy(tbuf,p[i],sizeof(tbuf));
		tnum = SplitLine(tp,tbuf,'-');
		if(tnum > 1)
		{
			int id = atoi(tp[0]);
			int level = atoi(tp[1]);
			if(id > 0)
				m_skills[id] = level;
		}
	}
}

void CBangPai::GetBangSkill(string &str)
{
	str.clear();
	map<int,int>::iterator it;
	for(it = m_skills.begin();it!=m_skills.end();it++)
	{
		if(it != m_skills.begin())
			str += "|";
		str += IntToStr(it->first) + "-" + IntToStr(it->second);
	}
}

void CBangPai::UpdateBangName2Member()
{
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_MY_BANG);
	msg<<(uint8)3;
	msg<<GetName();

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(map<uint32,SBangPaiMember>::iterator i = m_allMember.begin(); i != m_allMember.end(); i++)
	{
		ShareUserPtr ptr = SingletonOnlineUser::instance().GetUserByRoleId(i->first);
		CUser *pUser = ptr.get();
  		if(pUser != NULL)
  		{
  			sock.SendMsg(pUser->GetSock(),msg);
  		}
	}
}

void CBangPai::GetCopyStr(string &str)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	CNetMessage msg;
	// buff
	uint8 num = m_copyData.buffInfo.size();
	msg<<num;
	for(map<uint16, SBangPai_Buff>::iterator it = m_copyData.buffInfo.begin(); it != m_copyData.buffInfo.end(); it++)
	{
		msg<<it->second.id<<it->second.level;
	}
	
	// copy
	num = m_copyData.copyInfo.size();
	msg<<num;
	for(uint8 i = 0; i < num; i++)
	{
		SBangPai_CopyChap &d = m_copyData.copyInfo[i];
		msg<<d.chapId<<d.complete;

		uint8 copyNum = d.info.size();
		msg<<copyNum;
		for(map<int, SBangPai_CopyData>::iterator it=d.info.begin(); it != d.info.end(); it++)
		{
			SBangPai_CopyData &c = it->second;
			msg<<c.id<<c.complete<<c.killerRoleId;

			uint8 hpNum = sizeof(c.monLeftHp)/sizeof(c.monLeftHp[0]);
			msg<<hpNum;
			for(uint8 j=0; j < hpNum; j++)
				msg<<c.monLeftHp[j];
			
			uint8 danNum = c.damRank.size();
			msg<<danNum;
			for(uint8 j=0; j < danNum; j++)
			{
				SBP_CopyDamage &dam = c.damRank[j];
				msg<<dam.role_id<<dam.damage;
			}
		}
	}

	if(!Compress((uint8*)(msg.GetMsgData()->c_str() + CNetMessage::GetHeadLen()), msg.GetDataLenExceptHead(), str))
	{
		str.clear();
	}
}

void CBangPai::SetCopy(const char *pStr)
{
	if(pStr == NULL)
	{
		InitCopy();
		return;
	}
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	uint32 len = 1024*64;
	uint8 *p = new uint8[len];
	memset(p, 0, len);
	boost::scoped_array<uint8> autoDel(p);
	if(!UnCompress(pStr, p, len))
	{
		return;
	}
		
	CNetMessage msg;
	msg.WriteData(p, len);
	
	uint8 num = 0;
	msg>>num;
	for(uint8 i=0; i < num; i++)
	{
		SBangPai_Buff tmp;
		msg>>tmp.id>>tmp.level;
		m_copyData.buffInfo.insert(make_pair(tmp.id, tmp));
	}

	num = 0;
	msg>>num;
	for(uint16 i = 0; i < num; i++)
	{
		uint8 copyNum = 0;
		SBangPai_CopyChap tmp;
		msg>>tmp.chapId>>tmp.complete>>copyNum;

		for(uint8 j=0; j < copyNum; j++)
		{
			SBangPai_CopyData data;
			uint8 hpNum = 0;
			msg>>data.id>>data.complete>>data.killerRoleId>>hpNum;
			
			for(uint8 k=0; k < hpNum; k++)
			{
				if(k >= ZHEN_FA_POS_NUM)
				{
					uint64 hp;
					msg>>hp;
				}
				else
				{
					msg>>data.monLeftHp[k];
				}
			}
			uint8 damNum = 0;
			msg>>damNum;
			for(uint8 k=0; k < damNum; k++)
			{
				SBP_CopyDamage dam;
				msg>>dam.role_id>>dam.damage;
				if(dam.role_id == 0)
					continue;
				data.damRank.push_back(dam);
			}
			if(data.id == 0)
				continue;
			tmp.info.insert(make_pair(data.id, data));
		}

		if(tmp.chapId == 0)
			continue;
		m_copyData.copyInfo.push_back(tmp);
	}
}

bool CBangPai::MakeCopyMsg(CNetMessage &msg, int chapId, int copyId)
{
	CGuanQiaCfgMgr &gqMgr = SingletonCGuanQiaCfgMgr::instance();
	CFightCfgManager &fightMgr = SingletonCFightCfgManager::instance();
//	CMonsterBossManager &monMgr = SingletonMonsterBossManager::instance();
	CSimpleRoleDataMgr &sRoleMgr = SingletonCSimpleRoleDataMgr::instance();

	msg.ReWrite();
	msg.SetType(PRO_BANGPAI_COPY);
	msg<<(uint8)2<<chapId<<copyId;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	uint8 idx = 0xff;
	for(uint8 i=0; i < m_copyData.copyInfo.size(); i++)
	{
		if(m_copyData.copyInfo[i].chapId == chapId)
		{
			idx = i;
			break;
		}
	}
	if(idx == 0xff)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1407, TIPS_FAILURE_COLOR);
		return true;
	}
	
	SBangPai_CopyChap &chap = m_copyData.copyInfo[idx];
	map<int, SBangPai_CopyData>::iterator it = chap.info.find(copyId);
	if(it != chap.info.end())
	{
		SBangPai_CopyData &copy = it->second;
		MapNodeCfg *pNode = gqMgr.GetMapNodeCfg(copyId);
		if(pNode == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1283, TIPS_FAILURE_COLOR);
			cout<<">> CBangPai::MakeCopyMsg, node config error, copyId="<<copyId<<endl;
			return true;
		}
		SFightCfgData *pCfg = fightMgr.GetFightCfg(pNode->fightId);
		if(pCfg == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1283, TIPS_FAILURE_COLOR);
			cout<<">> CBangPai::MakeCopyMsg, fight config error, fightId="<<pNode->fightId<<endl;
			return true;
		}

		copy.Sort();
		msg<<PRO_SUCCESS<<copy.complete;

		uint32 pos = msg.GetDataLen();
		uint8 monsterNum = 0;
		msg<<monsterNum;
		for(uint8 j=0; j < ZHEN_FA_POS_NUM; j++)
		{
			if(pCfg->bossId[j] == 0)
				continue;
			uint8 isDie = (copy.monLeftHp[j] == 0) ? 1 : 0;	// 1 死亡 0 未死亡
			msg<<(uint8)(j+1)<<copy.monLeftHp[j]<<isDie;
			monsterNum++;
		}
		msg.WriteData(pos, &monsterNum, sizeof(monsterNum));

		uint32 rankPos = msg.GetDataLen();
		uint16 rankNum = 0;
		msg<<rankNum;
		for(uint16 j=0; j < copy.damRank.size(); j++)
		{
			SBP_CopyDamage &rank = copy.damRank[j];
			SRoleSimpleData _tmp;
			if(sRoleMgr.GetRoleData(rank.role_id, _tmp))
			{
				msg<<rank.role_id<<rank.damage<<_tmp.name<<_tmp.head<<_tmp.power<<_tmp.level<<_tmp.vipLv;
				rankNum++;
			}
		}
		msg.WriteData(rankPos, &rankNum, sizeof(rankNum));
		msg<<copy.killerRoleId;
	}
	else
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1283, TIPS_FAILURE_COLOR);
	}
	return true;
}

void CBangPai::MakeChapDamRankInfo(CNetMessage &msg, int chapId)
{
	CSimpleRoleDataMgr &sRoleMgr = SingletonCSimpleRoleDataMgr::instance();
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	uint8 idx = 0xff;
	for(uint8 i=0; i < m_copyData.copyInfo.size(); i++)
	{
		if(m_copyData.copyInfo[i].chapId == chapId)
		{
			idx = i;
			break;
		}
	}
	if(idx == 0xff)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1407, TIPS_FAILURE_COLOR);
		return;
	}

	SBangPai_CopyChap &chap = m_copyData.copyInfo[idx];
	msg<<PRO_SUCCESS<<(uint8)chap.info.size();
	for(map<int, SBangPai_CopyData>::iterator it = chap.info.begin(); it != chap.info.end(); it++)
	{
		SBangPai_CopyData &copy = it->second;
		copy.Sort();
		msg<<copy.id;
		
		uint32 rankPos = msg.GetDataLen();
		uint16 rankNum = 0;
		msg<<rankNum;
		for(uint16 j=0; j < copy.damRank.size(); j++)
		{
			SBP_CopyDamage &rank = copy.damRank[j];
			SRoleSimpleData _tmp;
			if(sRoleMgr.GetRoleData(rank.role_id, _tmp))
			{
				msg<<rank.role_id<<rank.damage<<_tmp.name<<_tmp.head<<_tmp.power<<_tmp.level<<_tmp.vipLv;
				rankNum++;
			}
		}
		msg.WriteData(rankPos, &rankNum, sizeof(rankNum));
		msg<<copy.killerRoleId;
	}
}

bool CBangPai::GetCopyNormalAward(CNetMessage &msg, CUser *pUser, int chapId, int copyId)
{
	if(pUser == NULL || chapId == 0 || copyId == 0)
		return false;
	CGuanQiaCfgMgr &gqMgr = SingletonCGuanQiaCfgMgr::instance();
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		uint8 idx = 0xff;
		for(uint8 i=0; i < m_copyData.copyInfo.size(); i++)
		{
			if(m_copyData.copyInfo[i].chapId == chapId)
			{
				idx = i;
				break;
			}
		}
		if(idx == 0xff)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1407, TIPS_FAILURE_COLOR);
			return true;
		}

		SBangPai_CopyChap &chap = m_copyData.copyInfo[idx];
		map<int, SBangPai_CopyData>::iterator it = chap.info.find(copyId);
		if(it == chap.info.end())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1283, TIPS_FAILURE_COLOR);
			return true;
		}
		if(pUser->HaveGetBangPaiCopyAward(copyId))
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0548, TIPS_FAILURE_COLOR);
			return true;
		}

		SBangPai_CopyData &copy = it->second;
		if(copy.complete == 0)	// 未完成
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0547, TIPS_FAILURE_COLOR);
			return true;
		}
		MapNodeCfg *pNode = gqMgr.GetMapNodeCfg(copyId);
		if(pNode == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1283, TIPS_FAILURE_COLOR);
			cout<<">> CBangPai::GetCopyNormalAward, node config error, copyId="<<copyId<<endl;
			return true;
		}

		msg<<PRO_SUCCESS;

		sAwardManager.SendAndMakeAwardMsg(pUser, pNode->allUserAwardId, msg, MUT_BangFuBen);
	}
	pUser->SetBangPaiCopyAward(copyId);

	CheckHotPoint(EHPoint_BP_CopyAward, pUser->GetRoleId());
	return true;
}

bool CBangPai::GetHuoYueInfo(CNetMessage &msg, CUser *pUser)
{
	if(pUser == NULL)
		return false;
	
	uint32 todayHuoYue = GetTodayHuoYue();
	CBP_CfgMgr &mgr = SingletonCBP_CfgMgr::instance();
	vector<uint16> vec;
	mgr.GetBuffIdList(vec);

	msg<<todayHuoYue<<(uint8)vec.size();
	for(uint8 i=0; i < vec.size(); i++)
	{
		SBP_HuoYueAwardCfg *p = mgr.GetHuoYueCfg(vec[i]);
		if(p == NULL)
			continue;
		uint8 isGetAward = pUser->HaveGetBangPaiHuoYueAward(vec[i]) ? 2 : 1;	// 0 不可领取 1 可领取 2 已领取
		if(todayHuoYue < p->activity && isGetAward == 1)
			isGetAward = 0;
		msg<<vec[i]<<isGetAward;
	}
	return true;
}

uint32 CBangPai::GetTodayHuoYue()
{
	uint32 sum = 0;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(map<uint32,SBangPaiMember>::iterator it = m_allMember.begin(); it != m_allMember.end(); it++)
	{
		sum += it->second.huoyue_day;
	}
	return sum;
}

bool CBangPai::GetHuoYueAward(CNetMessage &msg, CUser *pUser, int hyAwardId)
{
	if(pUser == NULL || hyAwardId < 1)
		return false;
	CBP_CfgMgr &mgr = SingletonCBP_CfgMgr::instance();
	SBP_HuoYueAwardCfg *pCfg = mgr.GetHuoYueCfg(hyAwardId);
	if(pCfg == NULL)
		return false;
	if(pUser->HaveGetBangPaiHuoYueAward(hyAwardId))
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0550, TIPS_FAILURE_COLOR);
		return true;
	}
	uint32 todayHuoYue = GetTodayHuoYue();
	if(todayHuoYue < pCfg->activity)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0551, TIPS_FAILURE_COLOR);
		return true;
	}

	MultiAward *award = sCGuanQiaCfgMgr.QueryFixAward(pCfg->rewardFixId);
	if(award == NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_94, TIPS_FAILURE_COLOR);
		return true;
	}
	
	msg<<PRO_SUCCESS;
	pUser->SetBangPaiHuoYueAward(hyAwardId);
	SendAndMakeAwardMsg(pUser, *award, msg);
	return true;
}

void CBangPai::BroadcastOpenChapter(int chapterId)
{
	CNetMessage msg;
	msg.SetType(PRO_BANGPAI_COPY);
	msg<<(uint8)21<<chapterId;

	{
		CGuanQiaCfgMgr &gqMgr = SingletonCGuanQiaCfgMgr::instance();
		CFightCfgManager &fightMgr = SingletonCFightCfgManager::instance();
//		boost::recursive_mutex::scoped_lock lk(m_mutex);
		int idx = 0xff;
		int size = m_copyData.copyInfo.size();
		for(int i=size-1; i >= 0; i--)
		{
			if(m_copyData.copyInfo[i].chapId == chapterId)
			{
				idx = i;
				break;
			}
		}
		if(idx == 0xff)
			return;

		SBangPai_CopyChap &chap = m_copyData.copyInfo[idx];
		uint8 copyNum = chap.info.size();
		msg<<copyNum;
		for(map<int, SBangPai_CopyData>::iterator it = chap.info.begin(); it != chap.info.end(); it++)
		{
			SBangPai_CopyData &copyData = it->second;
			copyData.Sort();
			msg<<copyData.id;
		
			MapNodeCfg *pNode = gqMgr.GetMapNodeCfg(copyData.id);
			if(pNode == NULL)
				return;
			SFightCfgData *pCfg = fightMgr.GetFightCfg(pNode->fightId);
			if(pCfg == NULL)
				return;
		
			uint32 pos = msg.GetDataLen();
			uint8 monsterNum = 0;
			msg<<monsterNum;
			for(uint8 j=0; j < ZHEN_FA_POS_NUM; j++)
			{
				if(pCfg->bossId[j] == 0)
					continue;
				msg<<(uint8)(j+1)<<copyData.monLeftHp[j];
				monsterNum++;
			}
			msg.WriteData(pos, &monsterNum, sizeof(monsterNum));
		}
	}
	BroadcastMsg(msg);
}

void CBangPai::BroadcastUpdateChapter(int chapterId)
{
	CNetMessage msg;
	msg.SetType(PRO_BANGPAI_COPY);
	msg<<(uint8)22<<chapterId;

	{
//		boost::recursive_mutex::scoped_lock lk(m_mutex);
		int idx = 0xff;
		int size = m_copyData.copyInfo.size();
		for(int i=size-1; i >= 0; i--)
		{
			if(m_copyData.copyInfo[i].chapId == chapterId)
			{
				idx = i;
				break;
			}
		}
		if(idx == 0xff)
			return;
		msg<<m_copyData.copyInfo[idx].complete;
	}
	BroadcastMsg(msg);
}

void CBangPai::BroadcastUpdateCopy(int chapterId, int copyId)
{
	CNetMessage msg;
	msg.SetType(PRO_BANGPAI_COPY);
	msg<<(uint8)23<<chapterId;

	uint32 pos = 0xffffffff;
	uint8 isGet = 0;	// 0 不可领取 1 可领取 2 已领取
	uint8 complete = 0;
	{
		CGuanQiaCfgMgr &gqMgr = SingletonCGuanQiaCfgMgr::instance();
		CFightCfgManager &fightMgr = SingletonCFightCfgManager::instance();
		CSimpleRoleDataMgr &sRoleMgr = SingletonCSimpleRoleDataMgr::instance();
//		boost::recursive_mutex::scoped_lock lk(m_mutex);
		int idx = 0xff;
		int size = m_copyData.copyInfo.size();
		for(int i=size-1; i >= 0; i--)
		{
			if(m_copyData.copyInfo[i].chapId == chapterId)
			{
				idx = i;
				break;
			}
		}
		if(idx == 0xff)
			return;

		SBangPai_CopyChap &chap = m_copyData.copyInfo[idx];
		map<int, SBangPai_CopyData>::iterator it = chap.info.find(copyId);
		if(it == chap.info.end())
			return;
		SBangPai_CopyData &copyData = it->second;
		copyData.Sort();
		msg<<copyData.id<<copyData.complete;

		complete = copyData.complete;
		pos = msg.GetDataLen();
		msg<<isGet;
		
		MapNodeCfg *pNode = gqMgr.GetMapNodeCfg(copyData.id);
		if(pNode == NULL)
			return;
		SFightCfgData *pCfg = fightMgr.GetFightCfg(pNode->fightId);
		if(pCfg == NULL)
			return;
		uint32 pos = msg.GetDataLen();
		uint8 monsterNum = 0;
		msg<<monsterNum;
		for(uint8 j=0; j < ZHEN_FA_POS_NUM; j++)
		{
			if(pCfg->bossId[j] == 0)
				continue;
			uint8 isDie = (copyData.monLeftHp[j] == 0) ? 1 : 0;	// 1 死亡 0 未死亡
			msg<<(uint8)(j+1)<<copyData.monLeftHp[j]<<isDie;
			monsterNum++;
		}
		msg.WriteData(pos, &monsterNum, sizeof(monsterNum));

		string firstRankName;
		if(copyData.complete > 0 && !copyData.damRank.empty())	// 完成
		{
			uint32 roleId = copyData.damRank[0].role_id;
			SRoleSimpleData _tmp;
			if(sRoleMgr.GetRoleData(roleId, _tmp))
				firstRankName = _tmp.name;
		}
		msg<<firstRankName;
	}

	{
		list<uint32> memberList;
		GetMember(memberList);
		COnlineUser &onlineUser = SingletonOnlineUser::instance();
		for(list<uint32>::iterator i = memberList.begin(); i != memberList.end(); i++)
		{
			ShareUserPtr ptr = onlineUser.GetUserByRoleId(*i);
			if(ptr.get() != NULL)
			{
				isGet = 0;	// 0 不可领取 1 可领取 2 已领取
				if(complete > 0)	// 完成
					isGet = (ptr->HaveGetBangPaiCopyAward(copyId)) ? 2 : 1;
				msg.WriteData(pos, &isGet, sizeof(isGet));
				SingletonSocket::instance().SendMsg(ptr->GetSock(), msg);
			}
		}
	}
}

bool CBangPai::MakeChapterMsg(CNetMessage &msg, CUser *pUser)
{
	if(pUser == NULL)
		return false;
	CGuanQiaCfgMgr &gqMgr = SingletonCGuanQiaCfgMgr::instance();
	CFightCfgManager &fightMgr = SingletonCFightCfgManager::instance();
	CSimpleRoleDataMgr &sRoleMgr = SingletonCSimpleRoleDataMgr::instance();

	uint8 leftNum = (pUser->GetExtData8(EData8_BPCopyNum) >= BP_COPY_NUM) ? 0 : (BP_COPY_NUM - pUser->GetExtData8(EData8_BPCopyNum));
	msg.ReWrite();
	msg.SetType(PRO_BANGPAI_COPY);
	msg<<(uint8)1<<leftNum<<BP_COPY_NUM;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	uint8 size = m_copyData.copyInfo.size();
	msg<<size;
	for(uint8 i=0; i < size; i++)
	{
		SBangPai_CopyChap &chap = m_copyData.copyInfo[i];
		msg<<chap.chapId<<chap.complete;

		map<int, SBangPai_CopyData> &copyMap = chap.info;
		uint8 copyNum = copyMap.size();
		msg<<copyNum;
		for(map<int, SBangPai_CopyData>::iterator it=copyMap.begin(); it != copyMap.end(); it++)
		{
			SBangPai_CopyData &copyData = it->second;
			copyData.Sort();
			msg<<copyData.id<<copyData.complete;

			uint8 isGetAward = 0;	// 0 不可领取 1 可领取 2 已领取
			if(copyData.complete > 0)	// 完成
				isGetAward = (pUser->HaveGetBangPaiCopyAward(copyData.id)) ? 2 : 1;
			msg<<isGetAward;

			MapNodeCfg *pNode = gqMgr.GetMapNodeCfg(copyData.id);
			if(pNode == NULL)
			{
				cout<<">> CBangPai::MakeChapterMsg, node config error, copyId="<<copyData.id<<endl;
				return false;
			}
			SFightCfgData *pCfg = fightMgr.GetFightCfg(pNode->fightId);
			if(pCfg == NULL)
			{
				cout<<">> CBangPai::MakeChapterMsg, fight config error, fightId="<<pNode->fightId<<endl;
				return false;
			}

			uint32 pos = msg.GetDataLen();
			uint8 monsterNum = 0;
			msg<<monsterNum;
			for(uint8 j=0; j < ZHEN_FA_POS_NUM; j++)
			{
				if(pCfg->bossId[j] == 0)
					continue;
				uint8 isDie = (copyData.monLeftHp[j] == 0) ? 1 : 0;	// 1 死亡 0 未死亡
				msg<<(uint8)(j+1)<<copyData.monLeftHp[j]<<isDie;
				monsterNum++;
			}
			msg.WriteData(pos, &monsterNum, sizeof(monsterNum));

			if(copyData.complete > 0 && !copyData.damRank.empty())	// 完成
			{
				uint32 roleId = copyData.damRank[0].role_id;
				SRoleSimpleData _tmp;
				if(sRoleMgr.GetRoleData(roleId, _tmp))
				{
					msg<<_tmp.name;
					continue;
				}
			}
			msg<<"";
		}
	}
	return true;
}


bool CBangPai::AddNewChapCopy(bool sendMsg)
{
	int curMaxChapId = 0;
	if(!m_copyData.copyInfo.empty())
		curMaxChapId = m_copyData.copyInfo[m_copyData.copyInfo.size() - 1].chapId;

	CGuanQiaCfgMgr &gqMgr = SingletonCGuanQiaCfgMgr::instance();
	CFightCfgManager &fightMgr = SingletonCFightCfgManager::instance();
	CMonsterBossManager &monMgr = SingletonMonsterBossManager::instance();
	CMapIdVec *pMap = gqMgr.GetTypeMapIds(EBMT_BangPaiCopy);
	if(pMap == NULL || pMap->empty())
	{
		if(gyu::util::CIniFile::GetValue("local_test","server",gConfigFile) != "1")
			cout<<">> CBangPai::AddNewChapCopy, config error"<<endl;
		return false;
	}
	
	int nextChapId = (curMaxChapId == 0) ? (*pMap)[0] : (curMaxChapId + 1);
	SingleZhangJieCfg *pCopy = gqMgr.GetZhangJieCfg(nextChapId);
	if(pCopy == NULL)
		return false;

	SBangPai_CopyChap chap;
	chap.chapId = pCopy->id;
	for(CurMapNodeCfgMapIt it = pCopy->nodes.begin(); it != pCopy->nodes.end(); it++)
	{
		SBangPai_CopyData copy;
		copy.id = it->first;

		MapNodeCfg *pNode = gqMgr.GetMapNodeCfg(copy.id);
		if(pNode == NULL)
			return false;
		SFightCfgData *pCfg = fightMgr.GetFightCfg(pNode->fightId);
		if(pCfg == NULL)
			return false;
		for(uint8 j=0; j < ZHEN_FA_POS_NUM; j++)
		{
			if(pCfg->bossId[j] == 0)
				continue;
			SMonsterBossCfg *pBoss = monMgr.GetMonsterBossCfg(pCfg->bossId[j]);
			if(pBoss == NULL)
				return false;
			copy.monLeftHp[j] = pBoss->attr.maxHp;
		}
		chap.info.insert(make_pair(copy.id, copy));
	}
	m_copyData.copyInfo.push_back(chap);

	if(sendMsg)
		BroadcastOpenChapter(nextChapId);
	return true;
}

bool CBangPai::InitCopy()
{
	vector<uint16> buffList;
	SingletonCBP_CfgMgr::instance().GetBuffIdList(buffList);

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_copyData.Clear();
	for(uint16 i=0; i < buffList.size(); i++)
	{
		uint16 id = buffList[i];
		m_copyData.buffInfo.insert(make_pair(id, SBangPai_Buff(id, 0)));
	}
	return AddNewChapCopy();
}

void CBangPai::GetCopyBuffAttr(vector<SAttrData> &vec)
{
	vec.clear();
	
	CBP_CfgMgr &buffMgr = SingletonCBP_CfgMgr::instance();
	for(map<uint16, SBangPai_Buff>::iterator itBuff = m_copyData.buffInfo.begin(); itBuff != m_copyData.buffInfo.end(); itBuff++)
	{
		SBP_BuffCfg *pCfg = buffMgr.GetBuffCfg(itBuff->first);
		if(pCfg == NULL)
			continue;
		SAttrData t;
		t.attrType = pCfg->attr.attrType;
		t.attrValue = pCfg->attr.attrValue * (itBuff->second.level);
		vec.push_back(t);
	}
}

bool CBangPai::CopyFight(CNetMessage &msg, CUser *pUser, int chapId, int copyId)
{
	if(pUser == NULL || chapId == 0 || copyId == 0)
		return false;
	uint8 canFightNum = (pUser->GetExtData8(EData8_BPCopyNum) >= BP_COPY_NUM) ? 0 : (BP_COPY_NUM - pUser->GetExtData8(EData8_BPCopyNum));
	if(canFightNum == 0)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0541, TIPS_FAILURE_COLOR);
		return true;
	}
	
	CGuanQiaCfgMgr &gqMgr = SingletonCGuanQiaCfgMgr::instance();
	bool allMonDie = true;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		uint8 idx = 0xff;
		for(uint8 i=0; i < m_copyData.copyInfo.size(); i++)
		{
			if(m_copyData.copyInfo[i].chapId == chapId)
			{
				idx = i;
				break;
			}
		}
		if(idx == 0xff)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1407, TIPS_FAILURE_COLOR);
			return true;
		}
		SBangPai_CopyChap &chap = m_copyData.copyInfo[idx];
		map<int, SBangPai_CopyData>::iterator it = chap.info.find(copyId);
		if(it == chap.info.end())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0536, TIPS_FAILURE_COLOR);
			return true;
		}
		if(chap.complete > 0)	// 完成
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0537, TIPS_FAILURE_COLOR);
			return true;
		}
		SBangPai_CopyData &copy = it->second;
		if(copy.complete > 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0538, TIPS_FAILURE_COLOR);
			return true;
		}

		// 开始战斗
		MapNodeCfg *pNode = gqMgr.GetMapNodeCfg(copyId);
		if(pNode == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1407, TIPS_FAILURE_COLOR);
			return true;
		}

		ShareUserPtr ptr = SingletonOnlineUser::instance().GetUserByRoleId(pUser->GetRoleId());
		ShareFightPtr fight = SingletonFightManager::instance().CreateFight();
		if(fight.get() == NULL)
			return false;
		msg<<PRO_SUCCESS;

		vector<SAttrData> buff;
		GetCopyBuffAttr(buff);
		fight->SetFightType(CFight::EFT_BangPaiCopy);
		// 人
		fight->AddUserGroupToFight(ptr);
		fight->AddGroupUnitsAttr(CFight::EGT_GROUP1, buff);
		
		// 加怪
		vector<uint64> monLeftHp(copy.monLeftHp, copy.monLeftHp + ZHEN_FA_POS_NUM);
		fight->AddMonsterWithFightId(pNode->fightId, monLeftHp);
		// 结果
		SFastFightResult result;
		fight->BeginFastFight(result, true, pUser->GetSock());
		MakeFightEndMsg(pUser, 0, msg, &(pNode->fightAward));
		
		uint64 damage = 0;
		for(uint8 i=0; i < ZHEN_FA_POS_NUM; i++)
			damage += copy.monLeftHp[i];
		for(uint8 i=0; i < result.group2.size(); i++)
		{
			SFastFightUnit &m = result.group2[i];
			copy.monLeftHp[m.pos] = m.hp;
			damage -= m.hp;
			if(m.hp > 0)
				allMonDie = false;
		}
		copy.complete = allMonDie ? 1 : 0;
		msg<<damage<<(uint8)(canFightNum-1);
		copy.AddRoleDamage(pUser->GetRoleId(), damage);

		BroadcastUpdateCopy(chapId, copyId);

		if(allMonDie)
		{
			// 发放击杀奖励
			char buf[512];
			snprintf(buf, sizeof(buf), LANGUAGE_SSJ_0539, pNode->name.c_str());
			SendSystemAwardMail(pUser->GetRoleId(), buf, pNode->finalKillAward);
			copy.killerRoleId = pUser->GetRoleId();
			
			// 发放最高伤害奖励
			uint32 maxDamRole = copy.GetMaxDamageRoleId();
			if(maxDamRole > 0)
			{
				snprintf(buf, sizeof(buf), LANGUAGE_SSJ_0540, pNode->name.c_str());
				SendSystemAwardMail(maxDamRole, buf, pNode->firstRankAward);
			}
		
			// 检测本章节是否全部完成
			bool chapComplete = true;
			for(map<int, SBangPai_CopyData>::iterator _it = chap.info.begin(); _it != chap.info.end(); _it++)
			{
				if(_it->second.complete == 0)
				{
					chapComplete = false;
					break;
				}
			}
			chap.complete = chapComplete ? 1 : 0;
			if(chapComplete)
			{
				AddNewChapCopy();
				BroadcastUpdateChapter(chapId);
			}
		}
	}

	if(allMonDie)
	{
		CheckHotPoint(EHPoint_BP_CopyAward);
	}
	pUser->SetExtData8(EData8_BPCopyNum, pUser->GetExtData8(EData8_BPCopyNum)+1);
	return true;
}

bool CBangPai::RunMulCopyFight(CNetMessage &msg, CUser *pUser, int chapId, int copyId)
{
	if(pUser == NULL || chapId == 0 || copyId == 0)
		return false;
	uint8 canFightNum = (pUser->GetExtData8(EData8_BPCopyNum) >= BP_COPY_NUM) ? 0 : (BP_COPY_NUM - pUser->GetExtData8(EData8_BPCopyNum));
	if(canFightNum == 0)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0541, TIPS_FAILURE_COLOR);
		return true;
	}
	CGuanQiaCfgMgr &gqMgr = SingletonCGuanQiaCfgMgr::instance();

	uint8 count = 0;
	bool allMonDie = true;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		uint8 idx = 0xff;
		for(uint8 i=0; i < m_copyData.copyInfo.size(); i++)
		{
			if(m_copyData.copyInfo[i].chapId == chapId)
			{
				idx = i;
				break;
			}
		}
		if(idx == 0xff)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1407, TIPS_FAILURE_COLOR);
			return true;
		}
		SBangPai_CopyChap &chap = m_copyData.copyInfo[idx];
		map<int, SBangPai_CopyData>::iterator it = chap.info.find(copyId);
		if(it == chap.info.end())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0536, TIPS_FAILURE_COLOR);
			return true;
		}
		if(chap.complete > 0) // 完成
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0537, TIPS_FAILURE_COLOR);
			return true;
		}
		SBangPai_CopyData &copy = it->second;
		if(copy.complete > 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0538, TIPS_FAILURE_COLOR);
			return true;
		}

		// 开始战斗
		MapNodeCfg *pNode = gqMgr.GetMapNodeCfg(copyId);
		if(pNode == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1407, TIPS_FAILURE_COLOR);
			return true;
		}

		msg<<PRO_SUCCESS;

		vector<SAttrData> buff;
		GetCopyBuffAttr(buff);

		SFightCfgData *pCfg = SingletonCFightCfgManager::instance().GetFightCfg(pNode->fightId);
		if(pCfg == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1407, TIPS_FAILURE_COLOR);
			return true;
		}
		ShareUserPtr ptr = SingletonOnlineUser::instance().GetUserByRoleId(pUser->GetRoleId());
		SFastFightResult result;
		uint32 pos = msg.GetDataLen();
		msg<<count;
		do
		{
			ShareFightPtr fight = SingletonFightManager::instance().CreateFight();
			if(fight.get() == NULL)
				return false;
			fight->SetFightType(CFight::EFT_BangPaiCopy);
			// 人
			fight->AddUserGroupToFight(ptr);
			fight->AddGroupUnitsAttr(CFight::EGT_GROUP1, buff);

			// 怪
			vector<uint64> monLeftHp(copy.monLeftHp, copy.monLeftHp + ZHEN_FA_POS_NUM);
			fight->AddMonsterWithFightId(pNode->fightId, monLeftHp);
			
			// 结果
			fight->BeginFastFight(result, false, pUser->GetSock());
			
			uint64 damage = 0;
			for(uint8 i=0; i < ZHEN_FA_POS_NUM; i++)
				damage += copy.monLeftHp[i];
			allMonDie = true;
			for(uint8 i=0; i < result.group2.size(); i++)
			{
				SFastFightUnit &m = result.group2[i];
				copy.monLeftHp[m.pos] = m.hp;
				damage -= m.hp;
				if(m.hp > 0)
					allMonDie = false;
			}
			copy.AddRoleDamage(pUser->GetRoleId(), damage);
			copy.complete = allMonDie ? 1 : 0;

			SendAndMakeAwardMsg(pUser, pNode->fightAward, msg, false, MUT_BangFuBen);

			msg<<damage;

			canFightNum--;
			count++;
		}while(canFightNum > 0 && !allMonDie);
		msg.WriteData(pos, &count, sizeof(count));
		msg<<canFightNum;
		
		BroadcastUpdateCopy(chapId, copyId);
		
		if(allMonDie)
		{
			copy.killerRoleId = pUser->GetRoleId();

			// 检测本章节是否全部完成
			bool chapComplete = true;
			for(map<int, SBangPai_CopyData>::iterator _it = chap.info.begin(); _it != chap.info.end(); _it++)
			{
				if(_it->second.complete == 0)
				{
					chapComplete = false;
					break;
				}
			}
			chap.complete = chapComplete ? 1 : 0;
			if(chapComplete)
			{
				AddNewChapCopy();
				BroadcastUpdateChapter(chapId);
			}
		}
	}

	if(allMonDie)
	{
		CheckHotPoint(EHPoint_BP_CopyAward);
	}
	pUser->SetExtData8(EData8_BPCopyNum, pUser->GetExtData8(EData8_BPCopyNum) + count);
	sCMissionManager.UpdateQuestState(pUser, EMQCT_60, count);
	return true;
}

bool CBangPai::UpdateGradeBuff(CNetMessage &msg, CUser *pUser, uint16 buffId)
{
	if(pUser == NULL || buffId == 0)
		return false;
	uint8 rank = GetMemberRank(pUser->GetRoleId());
	if(rank == 0)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0542, TIPS_FAILURE_COLOR);
		return true;
	}
	else if(rank >= EBRBangZhong)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0543, TIPS_FAILURE_COLOR);
		return true;
	}

	SBP_BuffCfg *pCfg = SingletonCBP_CfgMgr::instance().GetBuffCfg(buffId);
	if(pCfg == NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0544, TIPS_FAILURE_COLOR);
		return true;
	}

	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		map<uint16, SBangPai_Buff>::iterator it = m_copyData.buffInfo.find(buffId);
		if(it == m_copyData.buffInfo.end())
		{
			pair<map<uint16, SBangPai_Buff>::iterator, bool> _tmpIt = m_copyData.buffInfo.insert(make_pair(buffId, SBangPai_Buff(buffId, 0)));
			if(_tmpIt.second)
				it = _tmpIt.first;
			else
				return false;
		}
		SBangPai_Buff &buff = it->second;
		if(buff.level >= pCfg->maxLevel)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0545, TIPS_FAILURE_COLOR);
			return true;
		}
		if(m_huoyue < pCfg->cost)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0546, TIPS_FAILURE_COLOR);
			return true;
		}
		m_huoyue -= pCfg->cost;
		buff.level++;
		msg<<PRO_SUCCESS<<m_huoyue;

		msg<<(uint8)m_copyData.buffInfo.size();
		for(map<uint16, SBangPai_Buff>::iterator i = m_copyData.buffInfo.begin(); i != m_copyData.buffInfo.end(); i++)
			msg<<i->second.id<<i->second.level;
	}

	CheckHotPoint(EHPoint_BP_UpgradeSkill);
	return true;
}

void CBangPai::CheckHotPoint(uint16 type, uint32 roleId)
{
	vector<uint32> roleList;
	uint8 status = EHPointS_NotShow;
	switch(type)
	{
	case EHPoint_BP_UpgradeSkill:	// 帮派副本技能是否可升级
	{
		CBP_CfgMgr &cfgMgr = SingletonCBP_CfgMgr::instance();
		{
			boost::recursive_mutex::scoped_lock lk(m_mutex);
			for(map<uint16, SBangPai_Buff>::iterator it = m_copyData.buffInfo.begin(); it != m_copyData.buffInfo.end(); it++)
			{
				SBangPai_Buff &buff = it->second;
				SBP_BuffCfg *pCfg = cfgMgr.GetBuffCfg(buff.id);
				if(pCfg == NULL || buff.level >= pCfg->maxLevel)
					continue;
				if(m_huoyue >= pCfg->cost)
				{
					status = EHPointS_Show;
					break;
				}
			}

			if(roleId == 0)
			{
				for(map<uint32,SBangPaiMember>::iterator it = m_allMember.begin(); it != m_allMember.end(); it++)
				{
					if(it->second.rank <= EBRHuFa)
						roleList.push_back(it->first);
				}
			}
			else
			{
				roleList.push_back(roleId);
			}
		}
		break;
	}
	case EHPoint_BP_JoinApply:	// 帮派是否有入帮申请
	{
		{
			boost::recursive_mutex::scoped_lock lk(m_mutex);
			if(!m_askJoinUser.empty())
				status = EHPointS_Show;

			if(roleId == 0)
			{
				for(map<uint32,SBangPaiMember>::iterator it = m_allMember.begin(); it != m_allMember.end(); it++)
				{
					if(it->second.rank <= EBRZhangLao)
						roleList.push_back(it->first);
				}
			}
			else
			{
				roleList.push_back(roleId);
			}
		}
		break;
	}
	case EHPoint_BP_Event:	// 帮派事件
	{
		{
			boost::recursive_mutex::scoped_lock lk(m_mutex);
			if(!m_optionLog.empty())
				status = EHPointS_Show;
			
			if(roleId == 0)
			{
				for(map<uint32,SBangPaiMember>::iterator it = m_allMember.begin(); it != m_allMember.end(); it++)
					roleList.push_back(it->first);
			}
			else
			{
				roleList.push_back(roleId);
			}
		}
		break;
	}
	case EHPoint_BP_CopyAward:	// 帮派副本是否有可领取的奖励
	{
		vector<int> finishCopyIdList;
		{
			boost::recursive_mutex::scoped_lock lk(m_mutex);
			for(uint8 i=0; i < m_copyData.copyInfo.size(); i++)
			{
				SBangPai_CopyChap &chap = m_copyData.copyInfo[i];
				for(map<int, SBangPai_CopyData>::iterator it = chap.info.begin(); it != chap.info.end(); it++)
				{
					SBangPai_CopyData &copy = it->second;
					if(copy.complete > 0)	// 完成
						finishCopyIdList.push_back(copy.id);
				}
			}

			if(roleId == 0)
			{
				for(map<uint32,SBangPaiMember>::iterator it = m_allMember.begin(); it != m_allMember.end(); it++)
					roleList.push_back(it->first);
			}
			else
			{
				roleList.push_back(roleId);
			}
		}

		COnlineUser &onlineUser = SingletonOnlineUser::instance();
		for(uint32 i = 0; i < roleList.size(); i++)
		{
			CUser *pU = onlineUser.GetUserByRoleId(roleList[i]).get();
			if(pU != NULL)
			{
				bool canGetAward = false;
				for(uint16 j=0; j < finishCopyIdList.size(); j++)
				{
					int copyId = finishCopyIdList[j];
					if(!pU->HaveGetBangPaiCopyAward(copyId))
					{
						canGetAward = true;
						break;
					}
				}
				status = canGetAward ? EHPointS_Show : EHPointS_NotShow;
				SendHotPointStatus(pU, type, status);
			}
		}
		return;
	}
	case EHPoint_BP_HuoYueAward:	// 帮派活跃度奖励是否可领取
	{
		vector<uint16> finishHuoYueIdList;
		{
			uint32 todayHuoYue = GetTodayHuoYue();
			boost::recursive_mutex::scoped_lock lk(m_mutex);
			CBP_CfgMgr &mgr = SingletonCBP_CfgMgr::instance();
			vector<uint16> vec;
			mgr.GetBuffIdList(vec);
			
			for(uint8 i=0; i < vec.size(); i++)
			{
				SBP_HuoYueAwardCfg *p = mgr.GetHuoYueCfg(vec[i]);
				if(p == NULL)
					continue;
				if(todayHuoYue >= p->activity)
					finishHuoYueIdList.push_back(vec[i]);
			}
		}

		COnlineUser &onlineUser = SingletonOnlineUser::instance();
		for(uint32 i = 0; i < roleList.size(); i++)
		{
			CUser *pU = onlineUser.GetUserByRoleId(roleList[i]).get();
			if(pU != NULL)
			{
				bool canGetAward = false;
				for(uint16 j=0; j < finishHuoYueIdList.size(); j++)
				{
					uint16 huoyueId = finishHuoYueIdList[j];
					if(!pU->HaveGetBangPaiHuoYueAward(huoyueId))
					{
						canGetAward = true;
						break;
					}
				}
				status = canGetAward ? EHPointS_Show : EHPointS_NotShow;
				SendHotPointStatus(pU, type, status);
			}
		}
		return;
	}
	
	default:
		return;
	}

	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	for(uint32 i = 0; i < roleList.size(); i++)
	{
		CUser *pU = onlineUser.GetUserByRoleId(roleList[i]).get();
		if(pU != NULL)
			SendHotPointStatus(pU, type, status);
	}
}

void CBangPai::GetBuffInfo(CNetMessage &msg)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	msg<<m_huoyue<<(uint8)m_copyData.buffInfo.size();
	for(map<uint16, SBangPai_Buff>::iterator it = m_copyData.buffInfo.begin(); it != m_copyData.buffInfo.end(); it++)
	{
		msg<<it->second.id<<it->second.level;
	}
}

void CBangPai::SaveLog(int roleId,int tarBangPaiId,int type,const char *str1,const char *str2)
{
	if(str1 == NULL)
		return;
	
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
	char sql[2048];
	uint32 curTime = GetSysTime();
	if(str2 != NULL)
		snprintf(sql,sizeof(sql),"insert into bang_pai_log (bang_id,role_id,type,msg,msg2,time,tar_bang_id) values(%u,%u,%d,'%s','%s',%u,%d)",m_id,roleId,type,str1,str2,curTime,tarBangPaiId);
	else
		snprintf(sql,sizeof(sql),"insert into bang_pai_log (bang_id,role_id,type,msg,msg2,time,tar_bang_id) values(%u,%u,%d,'%s','%s',%u,%d)",m_id,roleId,type,str1,"",curTime,tarBangPaiId);
	if(!pDb->Query(sql))
		return;
}

void CBangPai::GetOptionLog(CNetMessage &msg,uint8 type)
{
	if(type == 0 || type > 3)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0061,TIPS_FAILURE_COLOR);
		return;
	}
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0235,TIPS_FAILURE_COLOR);
		return;
	}

	char sql[512];
	if(type == 1)	// 1捐献信息
		snprintf(sql,sizeof(sql),"select from_unixtime(time),msg from bang_pai_log where bang_id=%u and type=17 order by time desc limit 50",m_id);
	else if(type == 2)	// 2上仙互动
		snprintf(sql,sizeof(sql),"select from_unixtime(time),msg from bang_pai_log where bang_id=%u and type>=11 and type<=15 order by time desc limit 50",m_id);
	else if(type == 3)	// 3其他信息
		snprintf(sql,sizeof(sql),"select from_unixtime(time),msg from bang_pai_log where bang_id=%u and type=16 order by time desc limit 50",m_id);
	else
		return;

	if(!pDb->Query(sql))
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0235,TIPS_FAILURE_COLOR);
		return;
	}
	msg<<PRO_SUCCESS;

	char **row = NULL;
	uint16 num = 0;
	uint16 numPos = msg.GetDataLen();
	msg<<num;
	while((row = pDb->GetRow()) != NULL)
	{
		num++;
		msg<<num<<row[0]<<row[1];
	}
	msg.WriteData(numPos,&num,sizeof(num));
}

///////////////////////////////////////////////////////////////////////////////////////////////////////

CBangPai *CBangPaiManager::FindBangPai(uint32 id)
{
	CBangPai *pBangPai = NULL;
	boost::mutex::scoped_lock lk(m_mutex);
	m_bangPaiList.Find(id,pBangPai);
	return pBangPai;
}

CBangPai *CBangPaiManager::CreateBangPai(CUser *pUser,const char *name,int pic,uint16 limitLv)
{
	if(pUser == NULL)
		return NULL;
	string bpName = SQLFilter(name);

	CBangPai *pBangPai = new CBangPai;
	m_curId++;
	pBangPai->SetId(m_curId);
	pBangPai->SetName(bpName.c_str());
	pBangPai->SetPic(pic);
	pBangPai->SetAutoAcceptSign(limitLv);
	pBangPai->InitLianQiLv();
	pBangPai->InitCopy();

	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return NULL;
	int rank = m_bangPaiList.NodeNum()+1;
	boost::format fmt("INSERT INTO bang_pai (id,name,`rank`,pic,info,gonggao,copy,memberReward,shangxian_info,mission,juanxian_rank,lianqi_lv,skills) VALUES (%1%,\"%2%\",%3%,%4%,\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\")");
	fmt % m_curId % bpName % rank % pic;
	if(pDb->Query(fmt.str().c_str()))
	{
		boost::mutex::scoped_lock lk(m_mutex);
		pBangPai->AddMemberNoLocked(pUser->GetRoleId(),EBRBangZhu);
		pBangPai->InitZhongZhi(false);
		pBangPai->SetCreateTime(GetSysTime());
		m_bangPaiList.Insert(m_curId,pBangPai);
		pBangPai->SetRank(rank);
		return pBangPai;
	}
	delete pBangPai;
	return NULL;
}

void CBangPaiManager::Erase(uint32 id)
{
	{
		boost::mutex::scoped_lock lk(m_mutex);
		m_bangPaiList.Erase(id);
    }
}

void CBangPaiManager::DelBangPai(uint32 id)
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
	char buf[256];

	snprintf(buf,sizeof(buf),"DELETE FROM bang_pai WHERE bang_pai.id = %u",id);
	pDb->Query(buf);
}

bool CBangPaiManager::Init()
{
	int curTime = time(NULL);
	m_curId = 0;

	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return false;
	if(gyu::util::CIniFile::GetValue("local_test","server",gConfigFile) == "1")
	{
		pDb->Query("update bang_pai set info=ifnull(info,''),gonggao=ifnull(gonggao,''),copy=ifnull(copy,''),memberReward=ifnull(memberReward,''),shangxian_info=ifnull(shangxian_info,''),mission=ifnull(mission,''),juanxian_rank=ifnull(juanxian_rank,''),lianqi_lv=ifnull(lianqi_lv,''),skills=ifnull(skills,'') where state=1");
	}
#ifdef KUA_FU
	//                   0   1   2   3     4     5     6       7    8   9   10  11  12           13
	if(!pDb->Query("select id,name,info,level,fanrong,money,kouhao,gonggao,title,copy,res2,res3,res4,unix_timestamp(create_time),"\
		//	14		 15		16		17		18		  19	20		21		22		23		24		  25			26			 27         28        29        30         31
		"activity,gongXian,exp,fireState,onFireTime,robNum,robExp,treeExp,prayExp,treeLv,prayNum,addTreeExpTime,memberReward,treeTotalExp,bz_jifen,serverId,kfbz_jifen,kfbz_jifen_final"\
		//  32            33      34       35
		",auto_limit_lv,huoyue,lianqi_lv,skills"\
		" from bang_pai where state=1 order by level desc,exp desc"))
#else
	//                   0   1   2   3	   4	 5	   6	  7     8   9   10  11  12            13
	if(!pDb->Query("select id,name,info,level,fanrong,money,kouhao,gonggao,title,copy,res2,res3,res4,unix_timestamp(create_time),"\
		//	14		 15		16		17		18		  19	20		21		22		23		24		  25			26			 27         28
		"activity,gongXian,exp,fireState,onFireTime,robNum,robExp,treeExp,prayExp,treeLv,prayNum,addTreeExpTime,memberReward,treeTotalExp,bz_jifen "\
		//    29          30             31         32        33           34           35     36      37
		",xianzhun_lv,yingxiangli,shangxian_info,mission,juanxian_rank,auto_limit_lv,huoyue,lianqi_lv,skills from bang_pai where state=1 order by level desc,exp desc"))
#endif
	{
		return false;
	}
	int bangNum = pDb->GetRowNum();
	char **row = NULL;
	int rank = 1;
	vector<int> delBangPai;
	while((row = pDb->GetRow()) != NULL)
	{
		CBangPai *pBangPai = new CBangPai;
		m_curId = atoi(row[0]);
		pBangPai->SetState(1);
		pBangPai->SetId(m_curId);
#ifdef KUA_FU
		pBangPai->SetName(row[1]);
//		char *pName = strstr(row[1],".");
//		if(pName == NULL)
//			pBangPai->SetName(row[1]);
//		else
//			pBangPai->SetName(pName+1);
		pBangPai->SetServerId(atoi(row[29]));
		pBangPai->SetBZ_JiFen_KF(atoi(row[30]));
		pBangPai->SetBZ_JiFen_KF_Final(atoi(row[31]));
		pBangPai->SetAutoAcceptSign(atoi(row[32]));
		pBangPai->SetHuoYue(atoi(row[33]));
		pBangPai->SetLianQiLv(row[34]);
		pBangPai->SetBangSkill(row[35]);
#else
		pBangPai->SetName(row[1]);
		pBangPai->SetXianZhunGeLv(atoi(row[29]));
		pBangPai->SetYingXiangLi(atoi(row[30]));
		pBangPai->ReadSX_Info(row[31]);
		pBangPai->ReadMission(row[32]);
		pBangPai->ReadJuanXianPaiHang(row[33]);
		pBangPai->SetAutoAcceptSign(atoi(row[34]));
		pBangPai->SetHuoYue(atoi(row[35]));
		pBangPai->SetLianQiLv(row[36]);
		pBangPai->SetBangSkill(row[37]);
#endif
		pBangPai->Read(row[2]);
		pBangPai->SetLevel(atoi(row[3]));
		pBangPai->SetFanRong(atoi(row[4]));
		pBangPai->SetMoney(atoi(row[5]));
		pBangPai->SetKouHao(row[6]);
		pBangPai->SetGongGao(row[7]);
		pBangPai->SetTitle(atoi(row[8]));
		pBangPai->SetCopy(row[9]);
//		pBangPai->SetRes1(atoi(row[9]));
//		pBangPai->SetRes2(atoi(row[10]));
//		pBangPai->SetRes3(atoi(row[11]));
//		pBangPai->SetRes4(atoi(row[12]));
		pBangPai->InitZhongZhi();
		pBangPai->InitGuard();
		pBangPai->SetCreateTime(atoi(row[13]));
		pBangPai->SetActivity(atoi(row[14]));
		pBangPai->SetTotolGongXian(atoi(row[15]));
		pBangPai->SetExp(atoi(row[16]));
		pBangPai->SetFireState(atoi(row[17]));
		pBangPai->SetOnFireTime(atoi(row[18]));
		pBangPai->SetTreeRobbedNum(atoi(row[19]));
		pBangPai->SetTreeRobbedExp(atoi(row[20]));
		pBangPai->SetTreeExp(atoi(row[21]));
		pBangPai->SetPrayExp(atoi(row[22]));
		pBangPai->SetTreeLevel(atoi(row[23]));
		pBangPai->SetPrayNum(atoi(row[24]));
		pBangPai->SetAddTreeExpTime(atoi(row[25]));
		pBangPai->SetMemberReward(row[26]);
		pBangPai->SetTreeTotalExp((uint32)atoi(row[27]));
		pBangPai->SetBZ_JiFen(atoi(row[28]));

		pBangPai->ReadMember();
		if(bangNum <=10 || !pBangPai->CheckDeleteBangPai(curTime))	// 不需要删除
		{
			pBangPai->SetRank(rank);
			pBangPai->CheckBangZhu();
			rank++;
			m_bangPaiList.Insert(m_curId,pBangPai);
		}
		else	// 删除
		{
			if(pBangPai != NULL)
				delete pBangPai;
			delBangPai.push_back(m_curId);
		}
	}
	if(pDb->Query("select max(id) from bang_pai"))
	{
		char **row = pDb->GetRow();
		if((row != NULL) && (row[0] != NULL))
			m_curId = atoi(row[0])+1;
	}

	int size = delBangPai.size();
	if(size > 0)
	{
		stringstream sql;
#ifdef KUA_FU
		sql<<"delete from bang_pai where id in(";
#else
		sql<<LANGUAGE_TRANSFORM_423<<curTime<<") where id in(";
#endif
		for(int i=0;i < size;i++)
		{
			if(i == 0)
				sql<<delBangPai[i];
			else
				sql<<","<<delBangPai[i];
		}
		sql<<")";
		pDb->Query(sql.str().c_str());

		stringstream sql_1;
		sql_1<<"delete from bang_pai_role where bangpai_id in(";
		for(int i=0;i < size;i++)
		{
			if(i == 0)
				sql_1<<delBangPai[i];
			else
				sql_1<<","<<delBangPai[i];
		}
		sql_1<<")";
		pDb->Query(sql_1.str().c_str());
	}

	InitBangZhanData();
	InitBangPaiShangXian();
	InitBangPaiMission();

	string res = GetGlobalVaribleData(EGV_BPZ);
	if (res.length() != 0)
	{
		char buf[512];
		strncpy(buf, res.c_str(), sizeof(buf));
		char *p[30];
		int limit = SplitLine(p, 30, buf);
		for (int i = 0; i < (limit / 3); ++i)
		{
			uint32 rank = atoi(p[i * 3]);
			uint32 bangpaiId = atoi(p[i * 3 + 1]);
			string bangpaiName = p[i * 3 + 2];
			if (rank == 1)
			{
				m_firstBang = bangpaiId;
				break;
			}
		}
	}
	return true;
}

#ifdef KUA_FU
void CBangPaiManager::KF_ReadBangPai(CNetMessage &msg)
{
	uint32 serverId = 0;
	uint32 roleId = 0;
	uint32 bangId = 0;
	string bName;
	string gonggao;
	uint8 bLevel = 0;
	uint32 bExp = 0;
	int bz_jifen = 0;
	int bHuoyue = 0;
	uint16 limitLv = 0;

	char sql[512];
	msg>>serverId>>roleId>>bangId;
	if(bangId == 0)
	{
		if(roleId > 0)
		{
			snprintf(sql,sizeof(sql)-1,"delete from bang_pai_role where role_id=%d",roleId);
			SendLongQuerySql(sql);
			return;
		}
	}

	msg>>bName>>bLevel>>bExp>>gonggao>>bz_jifen>>bHuoyue>>limitLv;


	
	boost::mutex::scoped_lock lk(m_mutex);
	CBangPai *pBang = NULL;
	m_bangPaiList.Find(bangId,pBang);
	if(pBang == NULL)	// 没有帮派，创建
	{
		pBang = new CBangPai;
		if(m_curId < (int)bangId)
			m_curId = bangId;
		const char *pName = strstr(bName.c_str(),".");
		snprintf(sql,sizeof(sql)-1,"insert into bang_pai (id,name,rank,serverId,bz_jifen,huoyue,auto_limit_lv) values(%u,\"%s\",%u,%u,%d,%d,%d)",bangId,bName.c_str(),pBang->GetRank(),serverId,bz_jifen,bHuoyue,limitLv);
		SendLongQuerySql(sql);
		
		pBang->SetState(1);
		pBang->SetId(bangId);

		if(pName == NULL)
			pBang->SetName(bName.c_str());
		else
			pBang->SetName(pName+1);
		pBang->SetServerId(serverId);
		pBang->SetLevel(bLevel);
		pBang->SetGongGao(gonggao.c_str());
		pBang->SetExp(bExp);
		pBang->SetRank(m_bangPaiList.NodeNum()+1);
		pBang->SetBZ_JiFen(bz_jifen);
		pBang->SetHuoYue(bHuoyue);
		pBang->SetAutoAcceptSign(limitLv);
		pBang->KF_ReadSkill(msg);
		pBang->KF_ReadMember(msg);
		m_bangPaiList.Insert(bangId,pBang);
	}
	else	// 已存在，更新
	{
		const char *pName = strstr(bName.c_str(),".");
		if(pName == NULL)
			pBang->SetName(bName.c_str());
		else
			pBang->SetName(pName+1);
		snprintf(sql,sizeof(sql)-1,"update bang_pai set name=\"%s\",serverId=%u,bz_jifen=%d,huoyue=%d,huoyue=%d where id=%u",bName.c_str(),serverId,bz_jifen,bHuoyue,limitLv,bangId);
		SendLongQuerySql(sql);

		pBang->SetServerId(serverId);
		pBang->SetLevel(bLevel);
		pBang->SetGongGao(gonggao.c_str());
		pBang->SetExp(bExp);
		pBang->SetBZ_JiFen(bz_jifen);
		pBang->SetHuoYue(bHuoyue);
		pBang->SetAutoAcceptSign(limitLv);
		pBang->KF_ReadSkill(msg);
		pBang->KF_ReadMember(msg);
	}
}
#endif

static bool EachBangPai(CBangPai *pBangPai,vector<CBangPai*> *pBangPaiList)
{
	pBangPaiList->push_back(pBangPai);
	return true;
}

struct SSortBangPai
{
	bool operator()(CBangPai *const &b1,CBangPai *const &b2)
	{
		return b1->GetRank() < b2->GetRank();
	}
};

struct SSortBangPaiSXQinMi
{
	SSortBangPaiSXQinMi()
	{
		sxId = 0;
	}
	bool operator()(CBangPai *const &b1,CBangPai *const &b2)
	{
		return b1->GetSXQinMi(sxId) > b2->GetSXQinMi(sxId);
	}
	uint16 sxId;
};

struct SSortBangPaiActivity
{
	bool operator()(CBangPai *const &b1,CBangPai *const &b2)
	{
		return b1->GetActivity() > b2->GetActivity();
	}
};

void CBangPaiManager::AddBangGong(CUser *pUser,int banggong,bool showTips)
{
	if(pUser == NULL)
		return;

	uint32 bangId = pUser->GetBangPai();
	if(bangId > 0)
	{
		CBangPai *pBangPai = FindBangPai(bangId);
		if(pBangPai == NULL)
			return;
		pBangPai->AddMemberBangGong(pUser,banggong,showTips);
	}
	else
	{
		pUser->AddBangGong(banggong);
	}
}

void CBangPaiManager::AddBangPaiJiFen(CUser *pUser,int jifen)
{
	if(pUser == NULL)
		return;

	uint32 bangId = pUser->GetBangPai();
	if(bangId > 0)
	{		
		CBangPai *pBangPai = FindBangPai(bangId);
		if(pBangPai == NULL)
			return;
#ifndef KUA_FU
		pBangPai->AddBZ_JiFen(jifen);
#else
		int type = GetKuaFuBangZhanType();
		if(type == 1)
			pBangPai->AddBZ_JiFen_KF(jifen);
		else
			pBangPai->AddBZ_JiFen_KF_Final(jifen);
#endif
		pUser->SetExtData32(90,pUser->GetExtData32(90)+jifen);

		SBangZhanRoleData data;
		data.roleId = pUser->GetRoleId();
		data.name = pUser->GetName();
		data.jifen = pUser->GetExtData32(90);
		data.bangId = bangId;
		
		boost::mutex::scoped_lock lk(m_mutex);
		for(uint32 i=0;i < m_bz_roleRank.size();i++)
		{
			if(m_bz_roleRank[i].roleId == pUser->GetRoleId())
			{
				m_bz_roleRank[i].jifen += jifen;
				return;
			}
		}
		m_bz_roleRank.push_back(data);
	}
}

void CBangPaiManager::AddBangPaiJiFen(uint32 guildId, int jifen)
{
	int addCnt = 0;
	CBangPai *pBangPai = FindBangPai(guildId);
	if (pBangPai == NULL)
		return;
	{
		boost::mutex::scoped_lock lk(m_mutex);
		for (uint32 i = 0; i < m_bz_roleRank.size(); i++)
		{
			if (m_bz_roleRank[i].bangId == guildId)
			{
				m_bz_roleRank[i].jifen += jifen;
				addCnt++;
			}
		}
	}
	pBangPai->AddBZ_JiFen(jifen * addCnt);
}

void CBangPaiManager::DelAskJoin(int roleId)
{
	if(roleId <= 0)
		return;
	vector<CBangPai*> bangList;
	{
		boost::mutex::scoped_lock lk(m_mutex);
		m_bangPaiList.ForEach(boost::bind(EachBangPai,_2,&bangList));
	}
	for(uint16 i=0;i < bangList.size();i++)
	{
		if(bangList[i]->IsAskJoin(roleId))
			bangList[i]->DelAskForJoin(roleId);
	}
}

bool CBangPaiManager::AddRobTreeExp(CUser *pUser,uint32 robExp)
{
	if(pUser == NULL || robExp == 0)
		return false;
	uint32 bangId = pUser->GetBangPai();
	if(bangId > 0)
	{
		CBangPai *pBangPai = FindBangPai(bangId);
		if(pBangPai == NULL)
			return false;
		return pBangPai->AddTreeExpWithRobbedExp(robExp);
	}
	return false;
}

void CBangPaiManager::AddExp(CUser *pUser,uint32 exp)
{
	if(pUser == NULL)
		return;

	uint32 bangId = pUser->GetBangPai();
	if(bangId > 0)
	{
		CBangPai *pBangPai = FindBangPai(bangId);
		if(pBangPai == NULL)
			return;
		pBangPai->AddExp(exp);
	}
}

void CBangPaiManager::Timer()
{
	static bool sortRank = false;
	static bool bangzhu = false;
	int hour = GetHour();
	int minute = GetMinute();
	if (hour == 0 && minute == 0 && !bangzhu)
	{
		bangzhu = true;
		BangZhuTimer();
	}
	else if (hour == 0)
	{
		sortRank = false;
	}
	else if (hour == 1 && bangzhu)
	{
		bangzhu = false;
	}
	 vector<CBangPai*> bangpaiList;
	 {
		 boost::mutex::scoped_lock lk(m_mutex);
		 m_bangPaiList.ForEach(boost::bind(EachBangPai, _2, &bangpaiList));

		 if (hour == 23 && !sortRank)
		 {
			 sortRank = true;

			 int size = bangpaiList.size();
			 if (size > 1)
			 {
				 for (int i = 1; i < size; i++)
				 {
					 CBangPai *p = bangpaiList[i];
					 uint16 idx = 0xffff;
					 for (int j = 0; j < i; j++)
					 {
						 if ((p->GetLevel() > bangpaiList[j]->GetLevel()) || (p->GetLevel() == bangpaiList[j]->GetLevel() && p->GetExp() > bangpaiList[j]->GetExp()))
						 {
							 idx = j;
							 break;
						 }
					 }
					 if (idx != 0xffff)
					 {
						 for (int k = i; k > idx; k--)
							 bangpaiList[k] = bangpaiList[k - 1];
						 bangpaiList[idx] = p;
					 }
				 }
				 for (int i = 0; i < size; i++)
					 bangpaiList[i]->SetRank(i + 1);
			 }
		 }
	 }
#ifdef KUA_FU
	vector<uint32> bangpaiIdList;
	vector<int> bangpaiServerIdList;
#endif
	for(uint32 i = 0; i < bangpaiList.size(); i++)
	{
		bangpaiList[i]->Timer();
		if(hour == 0)
			bangpaiList[i]->UpdateMission(m_missionList);
#ifdef KUA_FU
		bangpaiIdList.push_back(bangpaiList[i]->GetId());
		bangpaiServerIdList.push_back(bangpaiList[i]->GetServerId());
#endif
	}

	// 生成帮战列表
#ifndef KUA_FU
	BangZhanTimer();
#else
/*
	static bool getBangFromGS = true;
	static bool createFightList = false;
	int wday = GetWeekDay();
	if(wday == 6 && hour == 23 && minute > 30 && getBangFromGS)
	{
		getBangFromGS = false;
		QueryGS_BangZhan_FirstInfo();
	}
	else if(wday == 0 && !getBangFromGS)
	{
		getBangFromGS = true;
	}
	if((wday == 0 || wday == 3) && hour == 0 && minute < 20 && !createFightList)
	{
		createFightList = true;
		ClearBangPaiFightJiFen();
		bool success = CreateBangFightList();
		if(success)
			SysInfoToAllUser(LANGUAGE_SSJ_0088);
		else
			SysInfoToAllUser(LANGUAGE_TRANSFORM_427);
	}
	else if(hour == 23 && createFightList)
	{
		createFightList = false;
	}
*/
#endif

#ifdef KUA_FU
	static bool isCheck = false;
	if(hour == 2)
	{
		if(!isCheck)
		{
			isCheck = true;
			for(uint32 idx=0; idx < bangpaiIdList.size(); idx++)
				QueryGameServer_BangPaiExist(bangpaiServerIdList[idx],bangpaiIdList[idx]);
		}
	}
	else if(hour == 0 && isCheck)
	{
		isCheck = false;
	}
#endif

//	BangPaiShangXianTimer();
}

bool CBangPaiManager::IsInBangZhanWeek()
{
	static set<uint8> addWeeks;
	if (addWeeks.empty())
	{
		addWeeks.insert(3);
		addWeeks.insert(6);
	}
	int wday = GetWeekDay();
	return addWeeks.find(wday) != addWeeks.end();
}

void CBangPaiManager::BangZhanTimer()
{
	static bool beginRob = false;
	static bool endRob = false;
	static bool createFightList = false;
	static bool notify = false;
	int wday = GetWeekDay();
	int hour = GetHour();
	int minute = GetMinute();
	if (!sSystemOpenCfgMananger.OpenWeekDay(SOT_BangPaiZhan))
		return;
	if (!notify && CSceneManager::IsNotifyActivityTime(SOT_BangPaiZhan))	// 19:35~19:50
	{
		notify = true;
		ShowBangZhanIcon(3);	// 预告
	}
	else if (CSceneManager::IsInActivityTime(SOT_BangPaiZhan) && !beginRob)	// 19:35~19:50
	{
		notify = false;
		beginRob = true;
		SysInfoToAllUser(LANGUAGE_TRANSFORM_424);
		ShowBangZhanIcon(1);	// 显示活动图标
	}
	else if (CSceneManager::IsAfterActivityTime(SOT_BangPaiZhan) && !endRob)
	{
		endRob = true;
		ShowBangZhanIcon(2);	// 清除活动图片
		/*GetBangZhanFirstBang()
		snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0060, )
		SysInfoToAllUser(MakeStringColor(LANGUAGE_ZQX_0060, ));
		LANGUAGE_ZQX_0060*/
		/*SMailData mdata;
		SItemInstance item;
		item.tmplId = 2497;
		item.num = 1;
		mdata.item.push_back(item);
		SingletonOnlineUser::instance().ForEachUser(boost::bind(SendBangPai_TreeRobAward, _1, &mdata));*/
	}
	if (hour == BP_FIGHT_READY_HOUR && minute <= 20 && !createFightList)
	{
		createFightList = true;
		if (wday == 3)
			ClearBangPaiFightJiFen();
		if (CreateBangFightList())
			SysInfoToAllUser(LANGUAGE_TRANSFORM_426);
		else
			SysInfoToAllUser(LANGUAGE_TRANSFORM_427);
	}
	else if (hour == 0 && createFightList)
	{
		createFightList = false;
	}
	else if (hour == 0)
	{
		beginRob = false;
		endRob = false;
	}
}

void CBangPaiManager::SaveBangPai()
{
	vector<CBangPai*> bangpaiList;
	{
		boost::mutex::scoped_lock lk(m_mutex);
		m_bangPaiList.ForEach(boost::bind(EachBangPai,_2,&bangpaiList));
	}

	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
	pDb->Query("delete from bang_pai_plant");
	pDb->Query("delete from bang_pai_guard");
	pDb->Query("delete from bang_pai_role");
	for(uint32 i = 0; i < bangpaiList.size(); i++)
	{
		bangpaiList[i]->Save();
		bangpaiList[i]->SaveBangPaiMember();
		bangpaiList[i]->SaveZhongZhi();
		bangpaiList[i]->SaveGuard();
	}

	SaveBangZhanData();
	SaveShangXianData();
	cout<<"CBangPaiManager::SaveBangPai() end"<<endl;
}

void CBangPaiManager::SaveData()
{
	vector<CBangPai*> bangpaiList;
	{
		boost::mutex::scoped_lock lk(m_mutex);
		m_bangPaiList.ForEach(boost::bind(EachBangPai,_2,&bangpaiList));
	}
	for(uint32 i = 0; i < bangpaiList.size(); i++)
		bangpaiList[i]->Save();
}

void CBangPaiManager::GetBangPaiTopList(uint16 topNum,vector<uint32> &bangpaiList)
{
	vector<CBangPai*> bangList;
	{
		boost::mutex::scoped_lock lk(m_mutex);
		m_bangPaiList.ForEach(boost::bind(EachBangPai,_2,&bangList));
	}
	if(bangList.size() > 0)
	{
		SSortBangPai bangSort;
		std::sort(bangList.begin(),bangList.end(),bangSort);
	}
	bangpaiList.clear();
	
	uint16 num = 0;
	for(uint16 i=0;i < bangList.size();i++)
	{
		if(bangList[i]->GetMemberNum() > 0)
		{
			bangpaiList.push_back(bangList[i]->GetId());
			num++;
			if(num >= topNum)
				break;
		}
	}
}

void CBangPaiManager::MakeBangPaiList(CNetMessage &msg,uint32 bId,uint32 roleId,bool haveMeBang)
{
	CBangPai *pBangPai = NULL;
	if(bId != 0)
	{
		pBangPai = FindBangPai(bId);
		if(pBangPai == NULL)
			return;
	}
	uint16 num = 0;
	uint8 pos = msg.GetDataLen();
	msg<<num;

	vector<CBangPai*> bangList;
	{
		boost::mutex::scoped_lock lk(m_mutex);
		m_bangPaiList.ForEach(boost::bind(EachBangPai,_2,&bangList));
	}
	if(bangList.size() > 0)
	{
		SSortBangPai bangSort;
		std::sort(bangList.begin(),bangList.end(),bangSort);
	}

	for(uint16 i = 0; i < bangList.size(); i++)
	{
		if(!haveMeBang && bangList[i]->GetId() == bId)
			continue;
		if(bangList[i]->GetMemberNum()==0)
			continue;
		list<uint32> memberList;
		bangList[i]->GetMember(memberList);
		bool isInAsk = false;
		if(bId == 0)
			isInAsk = bangList[i]->IsAskJoin(roleId);
		msg<<bangList[i]->GetRank()<<bangList[i]->GetId()<<bangList[i]->GetName()<<bangList[i]->GetLevel()<<bangList[i]->GetBangZhuName()
			<<bangList[i]->GetMemberNum()<<bangList[i]->GetMaxMemberNum()<<bangList[i]->GetPlantedPlantNum()<<bangList[i]->GetGongGao()
			<<(uint8)(isInAsk ? 1 : 0);
		msg<<bangList[i]->GetAutoAcceptLv();
		num++;
	}
	msg.WriteData(pos,&num,sizeof(num));
}

void CBangPaiManager::BangPaiHuoYuePaiHang(CUser *pUser,char *str)
{
	if(pUser == NULL || str == NULL)
		return;
	vector<CBangPai*> bangpaiList;
	{
		boost::mutex::scoped_lock lk(m_mutex);
		m_bangPaiList.ForEach(boost::bind(EachBangPai,_2,&bangpaiList));
	}
	if(bangpaiList.size() > 0)
	{
		SSortBangPaiActivity bangSort;
		std::sort(bangpaiList.begin(),bangpaiList.end(),bangSort);
	}
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_INTERACT);
	msg<<(uint8)17;
	msg<<(uint8)13<<str;
	uint16 pos = msg.GetDataLen();
	uint8 num = 0;
	msg<<num;
	vector<CBangPai*>::iterator i = bangpaiList.begin();
	for(; i != bangpaiList.end(); i++)
	{
		num++;
		msg<<(*i)->GetId()<<(*i)->GetName()<<(*i)->GetActivity();
		if(num == 30)
			break;
	}
	msg.WriteData(pos,&num,1);
	sock.SendMsg(pUser->GetSock(),msg);
}

void CBangPaiManager::InitBangPaiMission()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
	char **row = NULL;
	//                      0  1       2      3    4     5     6     7     8
	if(!pDb->Query("select id,name,desc_str,type,value,award1,num1,award2,num2 from bang_pai_mission order by id asc"))
		return;
	m_missionList.clear();
	while((row = pDb->GetRow()) != NULL)
	{
		SBangPaiMission data;
		data.id = atoi(row[0]);
		data.name = row[1];
		data.desc = row[2];
		data.type = atoi(row[3]);
		data.value = atoi(row[4]);
		data.award_itemId = atoi(row[5]);
		data.award_itemNum = atoi(row[6]);
		data.award_type = atoi(row[7]);
		data.award_num = atoi(row[8]);
		m_missionList.push_back(data);
	}
}

void CBangPaiManager::InitBangPaiShangXian()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
	char **row = NULL;
	//                      0  1       2        3       4         5           6          7              8              9            10         11
	if(!pDb->Query("select id,name,bangpai_id,qin_mi,add_type,add_value,gift_item_id,gift_item_num,gift_banggong,src_bangpai_id,lalong_time,timer_time from bang_pai_shangxian order by id asc"))
		return;
	m_shangxian_list.clear();
	while((row = pDb->GetRow()) != NULL)
	{
		SBPShangXianData data;
		data.id = atoi(row[0]);
		data.name = row[1];
		data.bangpai_id = atoi(row[2]);
		data.qinmi = atoi(row[3]);
		data.add_type = atoi(row[4]);
		data.add_value = atoi(row[5]);
		data.gift_id = atoi(row[6]);
		data.gift_num = atoi(row[7]);
		data.gift_banggong = atoi(row[8]);
		data.src_bangpai_id = atoi(row[9]);
		data.protect_time = atoi(row[10]);
		data.timer_time = atoi(row[11]);
		m_shangxian_list.push_back(data);
	}

	//                      0   1   2        3         4          5             6           7             8            9          10          11          12        13         14
	if(!pDb->Query("select id,name,type,succ_ratio,vip_limit,use_item_id1,use_item_num1,use_item_id2,use_item_num2,gain_type1,gain_value1,gain_type2,gain_value2,loss_type,loss_value from bang_pai_shangxian_mode order by type asc,id asc"))
		return;
	m_shangxian_mode.clear();
	while((row = pDb->GetRow()) != NULL)
	{
		SBPShangXian_ModeInfo data;
		data.id = atoi(row[0]);
		data.name = row[1];
		data.type = atoi(row[2]);
		data.succ_ratio = atoi(row[3]);
		data.vip_limit = atoi(row[4]);
		data.need_item_id[0] = atoi(row[5]);
		data.need_item_num[0] = atoi(row[6]);
		data.need_item_id[1] = atoi(row[7]);
		data.need_item_num[1] = atoi(row[8]);
		data.gain_type[0] = atoi(row[9]);
		data.gain_value[0] = atoi(row[10]);
		data.gain_type[1] = atoi(row[11]);
		data.gain_value[1] = atoi(row[12]);
		data.loss_type = atoi(row[13]);
		data.loss_value = atoi(row[14]);
		m_shangxian_mode.push_back(data);
	}
}

void CBangPaiManager::InitBangZhanData()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
#ifndef KUA_FU
	//                         0
	if(!pDb->Query("select bangpai_id from bangzhan order by id asc"))
		return;
	char **row = NULL;
	m_bz_bangRank.clear();
	while((row = pDb->GetRow()) != NULL)
	{
		int bangId = atoi(row[0]);
		if(bangId > 0)
		{
			CBangPai *p = FindBangPai(bangId);
			if(p != NULL)
				m_bz_bangRank.push_back(p);
		}
	}
#else
	//                         0         1      2
	if(!pDb->Query("select bangpai_id,`group`,type from bangzhan order by `group` asc,id asc"))
		return;
	char **row = NULL;
	for(int i=0;i < MAX_KFBZ_GROUP;i++)
	{
		m_bz_bangRank[i].clear();
		m_bz_bangRank_old[i].clear();
	}
	while((row = pDb->GetRow()) != NULL)
	{
		int bangId = atoi(row[0]);
		int group = atoi(row[1]);
		int type = atoi(row[2]);
		if(bangId > 0 && group >= 0 && group < MAX_KFBZ_GROUP)
		{
			CBangPai *p = FindBangPai(bangId);
			if(p != NULL)
			{
				if(type == 0)
					m_bz_bangRank[group].push_back(p);
				else
					m_bz_bangRank_old[group].push_back(p);
			}
		}
	}
#endif

	//                          0        1               2        3
	if(!pDb->Query("select a.role_id,b.bangpai_id,a.role_name,a.jifen from bangzhan_role as a,bang_pai_role as b where a.role_id=b.role_id order by a.id asc"))
		return;
	m_bz_roleRank.clear();
	while((row = pDb->GetRow()) != NULL)
	{
		SBangZhanRoleData data;
		data.roleId = atoi(row[0]);
		data.bangId = atoi(row[1]);
		data.name = row[2];
		data.jifen = atoi(row[3]);
		m_bz_roleRank.push_back(data);
	}
}

void CBangPaiManager::SaveShangXianData()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
	
	char sql[512];
	boost::mutex::scoped_lock lk(m_mutex);
	if(!m_shangxian_list.empty())
	{
		for(uint32 i = 0;i < m_shangxian_list.size();i++)
		{
			snprintf(sql,sizeof(sql)-1,"update bang_pai_shangxian set bangpai_id=%d,qin_mi=%d,lalong_time=%d,timer_time=%d where id=%u",
				m_shangxian_list[i].bangpai_id,m_shangxian_list[i].qinmi,m_shangxian_list[i].protect_time,m_shangxian_list[i].timer_time,m_shangxian_list[i].id);
			pDb->Query(sql);
		}
	}
}

void CBangPaiManager::SaveBangZhanData()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
	pDb->Query("delete from bangzhan");
	{
		boost::mutex::scoped_lock lk(m_mutex);
#ifndef KUA_FU
		if(!m_bz_bangRank.empty())
		{
			stringstream sql;
			sql<<"insert into bangzhan(bangpai_id) values";
			for(uint32 i=0;i < m_bz_bangRank.size();i++)
			{
				if(i > 0)
					sql<<",";
				sql<<"("<<m_bz_bangRank[i]->GetId()<<")";
			}
			pDb->Query(sql.str().c_str());
		}
#else
		for(int j=0;j < MAX_KFBZ_GROUP;j++)
		{
			if(!m_bz_bangRank[j].empty())
			{
				stringstream sql;
				sql<<"insert into bangzhan(bangpai_id,`group`,type) values";
				for(uint32 i=0;i < m_bz_bangRank[j].size();i++)
				{
					if(i > 0)
						sql<<",";
					sql<<"("<<m_bz_bangRank[j][i]->GetId()<<","<<j<<",0)";
				}
				pDb->Query(sql.str().c_str());
			}
			if(!m_bz_bangRank_old[j].empty())
			{
				stringstream sql;
				sql<<"insert into bangzhan(bangpai_id,`group`,type) values";
				for(uint32 i=0;i < m_bz_bangRank_old[j].size();i++)
				{
					if(i > 0)
						sql<<",";
					sql<<"("<<m_bz_bangRank_old[j][i]->GetId()<<","<<j<<",1)";
				}
				pDb->Query(sql.str().c_str());
			}
		}
#endif
	}

	pDb->Query("delete from bangzhan_role");
	char sql[256];
	{
		boost::mutex::scoped_lock lk(m_mutex);
		if(!m_bz_roleRank.empty())
		{
			for(uint32 i = 0;i < m_bz_roleRank.size();i++)
			{
				snprintf(sql,sizeof(sql)-1,"insert into bangzhan_role(role_id,bang_id,role_name,jifen) values(%u,%u,\"%s\",%d)",m_bz_roleRank[i].roleId,m_bz_roleRank[i].bangId,m_bz_roleRank[i].name.c_str(),m_bz_roleRank[i].jifen);
				pDb->Query(sql);
			}
		}
	}

	cout<<"SaveBangZhanData end"<<endl;
}

#ifndef KUA_FU
bool CBangPaiManager::CreateBangFightList()
{
	vector<CBangPai*> bangList;
	{
		boost::mutex::scoped_lock lk(m_mutex);
		m_bangPaiList.ForEach(boost::bind(EachBangPai,_2,&bangList));
	}

	vector<CBangPai *> bangFightList;
	for(int i=0;i < (int)bangList.size();i++)
	{
		CBangPai *p = bangList[i];
		if(p != NULL && p->GetLevel() >= BP_FIGHT_LIMIT_LV && p->GetMemberNum() >= BP_FIGHT_LIMIT_MEM_NUM)
		{
			bool isInsert = false;
			for(vector<CBangPai *>::iterator j=bangFightList.begin();j != bangFightList.end();j++)
			{
				if(*j != NULL)
				{
					if(p->GetBZ_JiFen() > (*j)->GetBZ_JiFen())
					{
						bangFightList.insert(j,p);
						isInsert = true;
						break;
					}
					else if(p->GetBZ_JiFen() == (*j)->GetBZ_JiFen())
					{
						if(p->GetLevel() > (*j)->GetLevel())
						{
							bangFightList.insert(j,p);
							isInsert = true;
							break;
						}
						else if(p->GetLevel() == (*j)->GetLevel())
						{
							if(p->GetExp() > (*j)->GetExp())
							{
								bangFightList.insert(j,p);
								isInsert = true;
								break;
							}
						}
					}
				}
			}
			if(!isInsert)
			{
				bangFightList.push_back(p);
			}
		}
	}

	boost::mutex::scoped_lock lk(m_mutex);
	m_bz_roleRank.clear();
	m_bz_bangRank.clear();
	m_bz_bangRank = bangFightList;
	return (m_bz_bangRank.size() > 0 ? true : false);
}

#else

bool CBangPaiManager::CreateBangFightList()
{
	int wday = GetWeekDay();
	vector<CBangPai*> bangList;
	if(wday == 0)	// 预赛
	{
		for(uint32 i=0;i < m_bz_idList.size();i++)
		{
			CBangPai *pBangPai = FindBangPai(m_bz_idList[i]);
			if(pBangPai != NULL)
				bangList.push_back(pBangPai);
		}
	}
	else if(wday == 3)	// 决赛
	{
		SSortBZJiFenKF sortFun;
		for(int i=0;i < MAX_KFBZ_GROUP;i++)
		{
			if(!m_bz_bangRank[i].empty())
			{
				std::sort(m_bz_bangRank[i].begin(),m_bz_bangRank[i].end(),sortFun);
				CBangPai *pBangPai = m_bz_bangRank[i][0];
				if(pBangPai != NULL)
					bangList.push_back(pBangPai);
			}
		}
	}

	vector<CBangPai *> bangFightList;
	for(int i=0;i < (int)bangList.size();i++)
	{
		CBangPai *p = bangList[i];
		if(p != NULL)
		{
			bool isInsert = false;
			for(vector<CBangPai *>::iterator j=bangFightList.begin();j != bangFightList.end();j++)
			{
				if(*j != NULL)
				{
					if(p->GetBZ_JiFen() > (*j)->GetBZ_JiFen())
					{
						bangFightList.insert(j,p);
						isInsert = true;
						break;
					}
					else if(p->GetBZ_JiFen() == (*j)->GetBZ_JiFen())
					{
						if(p->GetLevel() > (*j)->GetLevel())
						{
							bangFightList.insert(j,p);
							isInsert = true;
							break;
						}
						else if(p->GetLevel() == (*j)->GetLevel())
						{
							if(p->GetExp() > (*j)->GetExp())
							{
								bangFightList.insert(j,p);
								isInsert = true;
								break;
							}
						}
					}
				}
			}
			if(!isInsert)
			{
				bangFightList.push_back(p);
			}
		}
	}

	bool res = false;
	if(!bangFightList.empty())
		res = true;

	boost::mutex::scoped_lock lk(m_mutex);
	m_bz_roleRank.clear();
	for(uint8 i=0;i < MAX_KFBZ_GROUP;i++)
	{
		if(wday == 0)
			m_bz_bangRank_old[i].clear();
		else	// 决赛
			m_bz_bangRank_old[i] = m_bz_bangRank[i];
		m_bz_bangRank[i].clear();
	}
	int perGroupNum = MAX_JOIN_BANGPAI_NUM/MAX_KFBZ_GROUP;
	if((int)bangFightList.size() <= perGroupNum)
		m_bz_bangRank[0] = bangFightList;
	else
	{
		int size = bangFightList.size();
		if(size > MAX_JOIN_BANGPAI_NUM)
			size = MAX_JOIN_BANGPAI_NUM;
		for(uint8 i=0;i < MAX_KFBZ_GROUP;i++)
		{
			if(size <= perGroupNum)
			{
				for(int j=0;j < size && j < perGroupNum;j++)
					m_bz_bangRank[i].push_back(bangFightList[j]);
				break;
			}
			else
			{
				int array[MAX_JOIN_BANGPAI_NUM];
				RandomSequence(array,size,size);
				// min to max
				std::sort(array,array+perGroupNum);
				for(int k=0;k < perGroupNum;k++)
					m_bz_bangRank[i].push_back(bangFightList[array[k]-1]);
				for(int k=0;k < perGroupNum;k++)
					bangFightList.erase(bangFightList.begin()+array[k]-1-k);
				size -= perGroupNum;
			}
		}
	}
	return res;
}
#endif

#ifndef KUA_FU
void CBangPaiManager::MakeBangFightMsg(CNetMessage &msg)
{
	vector<CBangPai *> dataList;
	{
		boost::mutex::scoped_lock lk(m_mutex);
		SSortBZJiFen t;
		std::sort(m_bz_bangRank.begin(),m_bz_bangRank.end(),t);
		dataList = m_bz_bangRank;
	}
	
	uint16 num = 0;
	uint16 numPos = msg.GetDataLen();
	msg<<num;
	for(vector<CBangPai *>::iterator i=dataList.begin();i != dataList.end();i++)
	{
		if((*i) != NULL)
		{
			msg<<(*i)->GetId()<<(*i)->GetName()<<(*i)->GetLevel()<<(*i)->GetMemberNum()<<(*i)->GetBangZhuName()<<(*i)->GetBZ_JiFen();
			num++;
		}
	}
	msg.WriteData(numPos,&num,sizeof(num));
}
#else
void CBangPaiManager::MakeBangFightMsg(CNetMessage &msg)
{
	vector<CBangPai *> dataList[MAX_KFBZ_GROUP];
	{
		boost::mutex::scoped_lock lk(m_mutex);
		SSortBZJiFen t;
		for(uint8 i=0;i < MAX_KFBZ_GROUP;i++)
		{
			if(!m_bz_bangRank[i].empty())
			{
				std::sort(m_bz_bangRank[i].begin(),m_bz_bangRank[i].end(),t);
				dataList[i] = m_bz_bangRank[i];
			}
		}
	}

	int type = GetKuaFuBangZhanType();
	uint16 num = 0;
	uint16 numPos = msg.GetDataLen();
	msg<<num;
	for(uint8 j=0;j < MAX_KFBZ_GROUP;j++)
	{
		for(vector<CBangPai *>::iterator i=dataList[j].begin();i != dataList[j].end();i++)
		{
			if((*i) != NULL)
			{
				if(type == 1)
					msg<<(*i)->GetId()<<(*i)->GetName()<<(*i)->GetLevel()<<(*i)->GetBangZhuName()<<(*i)->GetBZ_JiFen_KF()<<(uint8)(j+1);
				else
					msg<<(*i)->GetId()<<(*i)->GetName()<<(*i)->GetLevel()<<(*i)->GetBangZhuName()<<(*i)->GetBZ_JiFen_KF_Final()<<(uint8)(j+1);
				num++;
			}
		}
		msg.WriteData(numPos,&num,sizeof(num));
	}
}

void CBangPaiManager::MakeBangFightOldMsg(CNetMessage &msg)
{
	vector<CBangPai *> dataList[MAX_KFBZ_GROUP];
	{
		boost::mutex::scoped_lock lk(m_mutex);
		SSortBZJiFen t;
		for(uint8 i=0;i < MAX_KFBZ_GROUP;i++)
		{
			if(!m_bz_bangRank_old[i].empty())
			{
				std::sort(m_bz_bangRank_old[i].begin(),m_bz_bangRank_old[i].end(),t);
				dataList[i] = m_bz_bangRank_old[i];
			}
		}
	}
	
	uint16 num = 0;
	uint16 numPos = msg.GetDataLen();
	msg<<num;
	for(uint8 j=0;j < MAX_KFBZ_GROUP;j++)
	{
		for(vector<CBangPai *>::iterator i=dataList[j].begin();i != dataList[j].end();i++)
		{
			if((*i) != NULL)
			{
				msg<<(*i)->GetId()<<(*i)->GetName()<<(*i)->GetLevel()<<(*i)->GetBangZhuName()<<(*i)->GetBZ_JiFen_KF()<<(uint8)(j+1);
				num++;
			}
		}
		msg.WriteData(numPos,&num,sizeof(num));
	}
}

#endif

#ifndef KUA_FU
void CBangPaiManager::GetBangZhanBangPaiList(vector<uint32> &idList)
{
	idList.clear();
	boost::mutex::scoped_lock lk(m_mutex);
	for(int i=0;i < (int)m_bz_bangRank.size();i++)
	{
		if(m_bz_bangRank[i] != NULL)
			idList.push_back(m_bz_bangRank[i]->GetId());
	}
}

#else
void CBangPaiManager::GetBangZhanBangPaiList(vector<uint32> &idList)
{
	idList.clear();
	boost::mutex::scoped_lock lk(m_mutex);
	for(int j=0;j < MAX_KFBZ_GROUP;j++)
	{
		for(int i=0;i < (int)m_bz_bangRank[j].size();i++)
		{
			if(m_bz_bangRank[j][i] != NULL)
				idList.push_back(m_bz_bangRank[j][i]->GetId());
		}
	}
}
#endif

void CBangPaiManager::MakeBangZhanPaiHang(CUser *pUser,CNetMessage &msg)
{
	const int showNum = 30;
	if(pUser == NULL)
		return;
	uint32 bId = pUser->GetBangPai();
	if(bId == 0)
		return;
	CBangPai *pBangPai = FindBangPai(bId);
	if(pBangPai == NULL)
		return;
#ifndef KUA_FU
	msg<<pBangPai->GetBZ_JiFen();
#else
	int type = GetKuaFuBangZhanType();
	if(type == 1)
		msg<<pBangPai->GetBZ_JiFen_KF();
	else
		msg<<pBangPai->GetBZ_JiFen_KF_Final();
#endif
	
	int bpRank = 0;
	int bpNum = 0;
	uint16 bpRankPos = msg.GetDataLen();
	msg<<bpRank<<bpNum;
	
	{
		boost::mutex::scoped_lock lk(m_mutex);
#ifndef KUA_FU
		SSortBZJiFen sortFun;
		std::sort(m_bz_bangRank.begin(),m_bz_bangRank.end(),sortFun);
		int idx = 0;
		for(vector<CBangPai *>::iterator i=m_bz_bangRank.begin();i != m_bz_bangRank.end();i++)
		{
			if(*i != NULL)
			{
				idx++;
				if((*i)->GetId() == bId)
					bpRank = idx;
				if(bpNum <= showNum && (*i)->GetBZ_JiFen() > 0)
				{
					msg << idx << (*i)->GetId() << (*i)->GetName() << (*i)->GetBZ_JiFen();
					bpNum++;
				}
			}
			if(bpRank > 0 && bpNum >= showNum)
				break;
		}
#else
		int roomIdx = pUser->GetSceneId();
		if(roomIdx < KUAFU_BZ_SCENE_ID_BEGIN || roomIdx >= KUAFU_BZ_SCENE_ID_BEGIN+MAX_KFBZ_GROUP)
			return;
		roomIdx -= KUAFU_BZ_SCENE_ID_BEGIN;
		
		if(type == 1)
		{
			SSortBZJiFenKF sortFun;
			if(!m_bz_bangRank[roomIdx].empty())
				std::sort(m_bz_bangRank[roomIdx].begin(),m_bz_bangRank[roomIdx].end(),sortFun);
		}
		else
		{
			SSortBZJiFenKF_Final sortFun;
			if(!m_bz_bangRank[roomIdx].empty())
				std::sort(m_bz_bangRank[roomIdx].begin(),m_bz_bangRank[roomIdx].end(),sortFun);
		}

		int idx = 0;
		for(vector<CBangPai *>::iterator i=m_bz_bangRank[roomIdx].begin();i != m_bz_bangRank[roomIdx].end();i++)
		{
			if(*i != NULL)
			{
				idx++;
				if((*i)->GetId() == bId)
					bpRank = idx;
				if(bpNum <= showNum && (*i)->GetBZ_JiFen() > 0)
				{
					if(type == 1)
						msg<<idx<<(*i)->GetName()<<(*i)->GetBZ_JiFen_KF();
					else
						msg<<idx<<(*i)->GetName()<<(*i)->GetBZ_JiFen_KF_Final();
					bpNum++;
				}
			}
			if(bpRank > 0 && bpNum >= showNum)
				break;
		}
#endif
		msg.WriteData(bpRankPos,&bpRank,sizeof(bpRank));
		msg.WriteData(bpRankPos+sizeof(bpRank),&bpNum,sizeof(bpNum));
	}

	msg<<pUser->GetExtData32(90);

	int myRank = 0;
	int num = 0;
	uint16 rankPos = msg.GetDataLen();
	msg<<myRank<<num;
	{
		SSortBZRoleJiFen sortFun;
		boost::mutex::scoped_lock lk(m_mutex);
		std::sort(m_bz_roleRank.begin(),m_bz_roleRank.end(),sortFun);
		int idx = 0;
		for(vector<SBangZhanRoleData>::iterator i=m_bz_roleRank.begin();i != m_bz_roleRank.end();i++)
		{
			idx++;
			if(i->roleId == pUser->GetRoleId())
				myRank = idx;
			if(num <= showNum)
			{
				msg<<idx<<i->name<<i->jifen;
				num++;
			}
			if(myRank > 0 && num >= showNum)
				break;
		}
		msg.WriteData(rankPos,&myRank,sizeof(myRank));
		msg.WriteData(rankPos+sizeof(myRank),&num,sizeof(num));
	}

	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

bool CBangPaiManager::IsInBangPaiFightList(uint32 bId)
{
	boost::mutex::scoped_lock lk(m_mutex);
#ifndef KUA_FU
	for(vector<CBangPai *>::iterator i=m_bz_bangRank.begin();i != m_bz_bangRank.end();i++)
	{
		if((*i)->GetId() == bId)
			return true;
	}
#else
	for(int j=0;j < MAX_KFBZ_GROUP;j++)
	{
		for(vector<CBangPai *>::iterator i=m_bz_bangRank[j].begin();i != m_bz_bangRank[j].end();i++)
		{
			if((*i)->GetId() == bId)
				return true;
		}
	}
#endif
	return false;
}

#ifdef KUA_FU
bool CBangPaiManager::IsInBangPaiFightListOld(uint32 bId)
{
	for(int j=0;j < MAX_KFBZ_GROUP;j++)
	{
		for(vector<CBangPai *>::iterator i=m_bz_bangRank_old[j].begin();i != m_bz_bangRank_old[j].end();i++)
		{
			if((*i)->GetId() == bId)
				return true;
		}
	}
	return false;
}
#endif


int CBangPaiManager::GetKuaFuBangZhanGroupIdx(uint32 bId)
{
#ifdef KUA_FU
	boost::mutex::scoped_lock lk(m_mutex);
	for(int j=0;j < MAX_KFBZ_GROUP;j++)
	{
		for(vector<CBangPai *>::iterator i=m_bz_bangRank[j].begin();i != m_bz_bangRank[j].end();i++)
		{
			if((*i)->GetId() == bId)
				return (j+1);
		}
	}
#endif
	return -1;
}

bool CBangPaiManager::IsOpenBangPaiFight()
{
	boost::mutex::scoped_lock lk(m_mutex);
#ifndef KUA_FU
	return (m_bz_bangRank.size() > 0 ? true : false);
#else
	for(int j=0;j < MAX_KFBZ_GROUP;j++)
	{
		if(!m_bz_bangRank[j].empty())
			return true;
	}
	return false;
#endif
}

void CBangPaiManager::ClearBangPaiFightJiFen()
{
	vector<CBangPai*> bangList;
	{
		boost::mutex::scoped_lock lk(m_mutex);
		m_bangPaiList.ForEach(boost::bind(EachBangPai,_2,&bangList));
	}
	for(int i=0;i < (int)bangList.size();i++)
	{
		if(bangList[i] != NULL)
#ifndef KUA_FU
			bangList[i]->ClearFightJiFen();
#else
		{
			int wday = GetWeekDay();
			if(wday <= 2)
				bangList[i]->ClearFightJiFen();
			else
				bangList[i]->ClearKuaFuBZ_FinalJiFen();
		}
#endif
	}
}

int CBangPaiManager::GetBangZhanFirstBang()
{
#ifndef KUA_FU
	if(m_bz_bangRank.empty())
		return 0;
	CSceneManager &scene = SingletonSceneManager::instance();
	CScene *pFightScene = scene.FindScene(BP_FIGHT_SID);
	if (pFightScene == NULL)
		return 0;
	map<int, int> towerCnt;
	pFightScene->CalcTowerJifen(towerCnt);
	{
		SSortBZJiFenEx sortFun(towerCnt);
		boost::mutex::scoped_lock lk(m_mutex);
		std::sort(m_bz_bangRank.begin(), m_bz_bangRank.end(), sortFun);
	}
	if(m_bz_bangRank[0] != NULL)
		return m_bz_bangRank[0]->GetId();
	else
		return 0;
#else
	return 0;
#endif
}

vector<int> CBangPaiManager::GetBangZhanFirstBangList()
{
	vector<int> temp;
#ifdef KUA_FU
	for(int j=0;j < MAX_KFBZ_GROUP;j++)
	{
		if(m_bz_bangRank[j].empty())
		{
			temp.push_back(0);
			continue;
		}
		SSortBZJiFenKF sortFun1;
		SSortBZJiFenKF_Final sortFun2;
		int type = GetKuaFuBangZhanType();
		boost::mutex::scoped_lock lk(m_mutex);
		if(type == 1)
			std::sort(m_bz_bangRank[j].begin(),m_bz_bangRank[j].end(),sortFun1);
		else if(type == 2)
			std::sort(m_bz_bangRank[j].begin(),m_bz_bangRank[j].end(),sortFun2);
		if(m_bz_bangRank[j][0] != NULL)
			temp.push_back(m_bz_bangRank[j][0]->GetId());
		else
			temp.push_back(0);
	}
#endif
	return temp;
}

#ifndef KUA_FU
void CBangPaiManager::SendBangZhanAward()
{
	/*char buf[512];
	{
		SSortBZRoleJiFen sortFun;
		boost::mutex::scoped_lock lk(m_mutex);
		std::sort(m_bz_roleRank.begin(),m_bz_roleRank.end(),sortFun);
	}
	vector<SAwardData> awards;
	for (uint32 i = 0; i < m_bz_roleRank.size(); i++)
	{
		uint32 rank = i+1;
		SMailData mdata;
		if(rank == 1)
		{
			CBangPai *pBangPai = FindBangPai(m_bz_roleRank[i].bangId);
			if (pBangPai != NULL)
				snprintf(buf, sizeof(buf), LANGUAGE_CHY_42, BANG_NAME_COLOR, pBangPai->GetName().c_str(), ROLE_NAME_COLOR, m_bz_roleRank[i].name.c_str());
			else
				snprintf(buf,sizeof(buf),LANGUAGE_CHY_43,BANG_NAME_COLOR,m_bz_roleRank[i].name.c_str());
			SysInfoToAllUser(buf);
		}
		snprintf(buf, sizeof(buf), LANGUAGE_CHY_44, rank);
		sAwardManager.SendRankAwardMail(EMRA_BANG_ZHAN_ROLE, m_bz_roleRank[i].roleId, rank, buf);
	}

	CSceneManager &scene = SingletonSceneManager::instance();
	CScene *pFightScene = scene.FindScene(BP_FIGHT_SID);
	if (pFightScene == NULL)
		return;
	map<int, int> towerCnt;
	pFightScene->CalcTowerJifen(towerCnt);
	{
		SSortBZJiFenEx sortFun(towerCnt);
		boost::mutex::scoped_lock lk(m_mutex);
		std::sort(m_bz_bangRank.begin(), m_bz_bangRank.end(), sortFun);
	}
	stringstream strall;
	for (uint32 i = 0; i < m_bz_bangRank.size(); i++)
	{
		uint32 rank = i + 1;
		if (m_bz_bangRank[i] != NULL && m_bz_bangRank[i]->GetBZ_JiFen() != 0)
		{
			if (rank == 1)
			{
				snprintf(buf, sizeof(buf) - 1, LANGUAGE_TRANSFORM_431, BANG_NAME_COLOR, m_bz_bangRank[i]->GetName().c_str());
				SysInfoToAllUser(buf);
				snprintf(buf, sizeof(buf) - 1, LANGUAGE_TRANSFORM_432, GetSysMonth() + 1, GetSysMDay(), BANG_NAME_COLOR, m_bz_bangRank[i]->GetName().c_str());
				SysInfoToAllUser(buf);
				m_bz_bangRank[i]->AddAllMemberTitle(E2UT_TIANXIADIYIBANG);
				strall << rank << "|" << m_bz_bangRank[i]->GetId() << "|" << m_bz_bangRank[i]->GetName() << "|";
				string str1 = strall.str();
				string str2 = str1.substr(0, str1.length() - 1);
				SetGlobalVaribleData(EGV_BPZ, str2.c_str());
				SetFirstBang(m_bz_bangRank[i]->GetId());
			}
			uint32 bangzhu = m_bz_bangRank[i]->GetBangZhu();
			snprintf(buf, sizeof(buf) - 1, LANGUAGE_TRANSFORM_433, rank);
			sAwardManager.SendRankAwardMail(EMRA_BANG_ZHAN_GUILD, bangzhu, rank, buf);
			m_bz_bangRank[i]->SetBZ_JiFen(0);
		}
	}
	m_bz_roleRank.clear();
	m_bz_bangRank.clear();*/
}
#else
void CBangPaiManager::SendBangZhanAward()
{
/*
	const char *RANK_NAME[] = {"一","二","三","四","五","六","七","八","九","十"};
	char buf[512];
	{
		SSortBZRoleJiFen sortFun;
		boost::mutex::scoped_lock lk(m_mutex);
		std::sort(m_bz_roleRank.begin(),m_bz_roleRank.end(),sortFun);
	}
	SItemInstance item;
	SItemInstance item2;
	item.num = 1;
	item2.num = 1;
	for(uint32 i=0;i < m_bz_roleRank.size();i++)
	{
		uint32 rank = i+1;
		SMailData mdata;
		if(rank == 1)
		{
			item.tmplId = 2556;
			item2.tmplId = 2800;
			CBangPai *pBangPai = FindBangPai(m_bz_roleRank[i].bangId);
			if(pBangPai != NULL)
				snprintf(buf,sizeof(buf),LANGUAGE_CHY_42,BANG_NAME_COLOR,pBangPai->GetName().c_str(),ROLE_NAME_COLOR,m_bz_roleRank[i].name.c_str(),ITEM_NAME_COLOR,GetItemName(item.tmplId),ITEM_NAME_COLOR,GetItemName(item2.tmplId));
			else
				snprintf(buf,sizeof(buf),LANGUAGE_CHY_43,BANG_NAME_COLOR,m_bz_roleRank[i].name.c_str(),ITEM_NAME_COLOR,GetItemName(item.tmplId),ITEM_NAME_COLOR,GetItemName(item2.tmplId));
			SysInfoToAllUser(buf);
		}
		else if(rank == 2)
		{
			item.tmplId = 2557;
			item2.tmplId = 2801;
		}
		else if(rank == 3)
		{
			item.tmplId = 2558;
			item2.tmplId = 2802;
		}
		else if(rank >= 4 && rank <= 10)
		{
			item.tmplId = 2559;
			item2.tmplId = 2803;
		}
		else if(rank >= 11 && rank <= 30)
		{
			item.tmplId = 2560;
			item2.tmplId = 2804;
		}
		else
		{
			item.tmplId = 2561;
			item2.tmplId = 2805;
		}
		mdata.item.push_back(item);
		mdata.item.push_back(item2);
		snprintf(buf,sizeof(buf),LANGUAGE_CHY_44,rank);
		SendSystemMail(m_bz_roleRank[i].roleId,buf,&mdata);
	}

	int wday = GetWeekDay();
	for(int k=0;k < MAX_KFBZ_GROUP;k++)
	{
		for(uint32 i=0;i < m_bz_bangRank[k].size();i++)
		{
			uint32 rank = i+1;
			SMailData mdata;
			if(rank == 1)
			{
				if(wday == 2)
					mdata.YB = 200;
				else
					mdata.YB = 300;
			}
			else
				break;
			if(m_bz_bangRank[k][i] != NULL)
			{
				if(rank == 1)
				{
					snprintf(buf,sizeof(buf)-1,LANGUAGE_SSJ_0087,BANG_NAME_COLOR,m_bz_bangRank[k][i]->GetName().c_str(),RANK_NAME[k]);
					SysInfoToAllUser(buf);
					if(wday == 5)
					{
						snprintf(buf,sizeof(buf)-1,LANGUAGE_TRANSFORM_432,BANG_NAME_COLOR,m_bz_bangRank[k][i]->GetName().c_str());
						SysInfoToAllUser(buf);
						m_bz_bangRank[k][i]->AddAllMemberTitle(E2UT_TIANXIADIYIBANG);
					}
				}
				uint32 bangzhu = m_bz_bangRank[k][i]->GetBangZhu();
				snprintf(buf,sizeof(buf)-1,LANGUAGE_TRANSFORM_433,rank,mdata.YB);
				SendSystemMail(bangzhu,buf,&mdata);
			}
		}
	}
*/
}
#endif

void CBangPaiManager::ShowBangZhanIcon(int flag)
{
#ifndef KUA_FU
	vector<CBangPai *> bangList;
	{
		boost::mutex::scoped_lock lk(m_mutex);
		bangList = m_bz_bangRank;
	}

	for(uint32 i=0;i < bangList.size();i++)
		bangList[i]->ShowBangZhanIcon(flag);
#else
	vector<CBangPai *> bangList[MAX_KFBZ_GROUP];
	{
		boost::mutex::scoped_lock lk(m_mutex);
		for(int i=0;i < MAX_KFBZ_GROUP;i++)
			bangList[i] = m_bz_bangRank[i];
	}
	for(int j=0;j < MAX_KFBZ_GROUP;j++)
	{
//		for(uint32 i=0;i < bangList[j].size();i++)
//			bangList[j][i]->ShowKuaFuBangZhanIcon(show);
	}
#endif
}

void CBangPaiManager::MakeShangXianInfo(CNetMessage &msg,uint32 bangpaiID,uint32 roleId)
{
	CBangPai *pBangPai = FindBangPai(bangpaiID);
	if(pBangPai == NULL)
	{
		msg<<0;
		return;
	}

	vector<SBPShangXianData> shangxianlist;
	{
		boost::mutex::scoped_lock lk(m_mutex);
		shangxianlist = m_shangxian_list;
	}
	bool isAdmin = pBangPai->IsAdmin(roleId);
	uint16 size = m_shangxian_list.size();
	msg<<size;
	for(uint16 i=0;i < size;i++)
	{
		SBPShangXianData &data = shangxianlist[i];
		int qinmi = pBangPai->GetSXQinMi(data.id);
		int ownQinMi = 0;
		if(data.bangpai_id == 1 || data.bangpai_id == 2)
		{
			ownQinMi = data.qinmi;
		}
		else
		{
			CBangPai *pOwnBP = FindBangPai(data.bangpai_id);
			if(pOwnBP != NULL)
				ownQinMi = pOwnBP->GetSXQinMi(data.id);
		}
		uint8 isHave = (data.bangpai_id == (int)bangpaiID) ? 1 : 0;	// 0未拉拢 1已拉拢
		msg<<data.id<<data.name<<ownQinMi<<qinmi<<isHave<<pBangPai->GetSXTarget(data.id);
		string ownBPName;
		if(data.bangpai_id == 1)
			ownBPName = LANGUAGE_SSJ_0294;
		else if(data.bangpai_id == 2)
			ownBPName = LANGUAGE_SSJ_0295;
		else
		{
			CBangPai *p = FindBangPai(data.bangpai_id);
			if(p != NULL)
				ownBPName = p->GetName();
		}
		msg<<ownBPName<<data.add_type<<data.add_value<<data.gift_id<<data.gift_num<<data.gift_banggong;
		uint8 youhaoState = 1;
		uint8 lijianState = 1;
		uint8 lalongState = isHave ? 0 : 1;	// 0不显示1显示
		uint8 jiechuState = isHave ? 1 : 0;	// 0不显示1显示
		if(!isAdmin)
		{
			lalongState = 0;
			jiechuState = 0;
		}
		msg<<youhaoState<<lijianState<<lalongState<<jiechuState;
		//add by zhudaolong
		int curTime = GetSysTime();
		if(data.protect_time > 0 && data.protect_time + SHANG_XIAN_PROTECT_TIME > curTime)
			msg<<(data.protect_time + SHANG_XIAN_PROTECT_TIME);
		else
			msg<<(int)0;
	}
}

void CBangPaiManager::DuiHuanShangXianGift(CUser *pUser,CNetMessage &msg,uint16 sxId)
{
	if(pUser == NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0061,TIPS_FAILURE_COLOR);
		return;
	}
	CBangPai *pBangPai = FindBangPai(pUser->GetBangPai());
	if(pBangPai == NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0297,TIPS_FAILURE_COLOR);
		return;
	}

	SBPShangXianData tarData;
	{
		boost::mutex::scoped_lock lk(m_mutex);
		uint16 size = m_shangxian_list.size();
		for(uint16 i=0;i < size;i++)
		{
			SBPShangXianData &data = m_shangxian_list[i];
			if(data.id == sxId)
			{
				if(data.bangpai_id == (int)pUser->GetBangPai())
				{
					tarData = data;
					break;
				}
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0347,TIPS_FAILURE_COLOR);
				return;
			}
		}
	}

	if(tarData.id != sxId)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0061,TIPS_FAILURE_COLOR);
		return;
	}
	int banggong = pUser->GetBangGong();
	if(banggong < tarData.gift_banggong)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0298,TIPS_FAILURE_COLOR);
		return;
	}
	else
	{
		pUser->AddBangGong(-tarData.gift_banggong);
		pUser->AddBangDingPackage(tarData.gift_id,tarData.gift_num);
		uint32 state = pUser->GetExtData32(438);
		state |= 1 << (sxId-1);
		pUser->SetExtData32(438,state);
		char buf[256];
		snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0299,GetItemName(tarData.gift_id),tarData.gift_num);
		msg<<PRO_SUCCESS<<MakeStringColor(buf,TIPS_WARNING_COLOR);
	}
}

void CBangPaiManager::SetShangXianLaLongState(CUser *pUser,CNetMessage &msg,uint16 sxId,uint8 state)
{
	if(pUser == NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0061,TIPS_FAILURE_COLOR);
		return;
	}
	CBangPai *pBangPai = FindBangPai(pUser->GetBangPai());
	if(pBangPai == NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0297,TIPS_FAILURE_COLOR);
		return;
	}

	boost::mutex::scoped_lock lk(m_mutex);
	uint16 size = m_shangxian_list.size();
	for(uint16 i=0;i < size;i++)
	{
		SBPShangXianData &data = m_shangxian_list[i];
		if(data.id == sxId)
		{
			uint8 tarState = pBangPai->GetSXTarget(sxId);
			if(tarState == state)
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0300,TIPS_FAILURE_COLOR);
				return;
			}
			pBangPai->SetSXTaget(sxId,state);
			if(state == 1)
				msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_SSJ_0301,TIPS_FAILURE_COLOR);
			else
				msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_SSJ_0382,TIPS_FAILURE_COLOR);
			return;
		}
	}
	msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0061,TIPS_FAILURE_COLOR);
}

// type 1友好2拉拢3离间4彻查验生石5彻查堕仙印
void CBangPaiManager::GetShangXianModeInfo(CUser *pUser,CNetMessage &msg,uint16 type,uint16 sxId)
{
	if(pUser == NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0061,TIPS_FAILURE_COLOR);
		return;
	}
	CBangPai *pBangPai = FindBangPai(pUser->GetBangPai());
	if(pBangPai == NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0297,TIPS_FAILURE_COLOR);
		return;
	}

	int sxQinMi = 0;
	vector<SBPShangXian_ModeInfo> modeList;
	{
		boost::mutex::scoped_lock lk(m_mutex);
		modeList = m_shangxian_mode;
		if(sxId > 0)
		{
			for(uint32 i=0;i < m_shangxian_list.size();i++)
			{
				SBPShangXianData &data = m_shangxian_list[i];
				if(data.id == sxId)
				{
					if(data.bangpai_id == 1 || data.bangpai_id == 2)
						sxQinMi = data.qinmi;
					else
					{
						CBangPai *p = NULL;
						m_bangPaiList.Find(data.bangpai_id,p);
						if(p != NULL)
							sxQinMi = p->NoLockGetSXQinMi(sxId);
					}
					break;
				}
			}
		}
	}
	msg<<PRO_SUCCESS;
	uint8 num = 0;
	uint16 numPos = msg.GetDataLen();
	msg<<num;
	uint16 size = modeList.size();
	for(uint16 i=0;i < size;i++)
	{
		SBPShangXian_ModeInfo &data = modeList[i];
		if(data.type == type)
		{
			int addRatio = 0;
			if(data.type == 2)
				addRatio = pBangPai->GetSupportRatio(sxId,sxQinMi) + pBangPai->GetSupportRatioByLv();
			msg<<data.id<<(data.succ_ratio+addRatio)<<data.vip_limit;
			uint8 awardNum = 0;
			uint16 awardNumPos = msg.GetDataLen();
			msg<<awardNum;
			for(uint8 j=0;j < sizeof(data.need_item_id)/sizeof(data.need_item_id[0]);j++)
			{
				if(data.need_item_id[j] > 0 && data.need_item_num[j] > 0)
				{
					awardNum++;
					msg<<data.need_item_id[j]<<data.need_item_num[j];
				}
			}
			msg.WriteData(awardNumPos,&awardNum,sizeof(awardNum));

			uint8 gainNum = 0;
			uint16 gainNumPos = msg.GetDataLen();
			msg<<gainNum;
			for(uint8 j=0;j < sizeof(data.gain_type)/sizeof(data.gain_type[0]);j++)
			{
				if(data.gain_type[j] > 0 && data.gain_value[j] > 0)
				{
					gainNum++;
					msg<<data.gain_type[j]<<data.gain_value[j];
				}
			}
			msg.WriteData(gainNumPos,&gainNum,sizeof(gainNum));
			msg<<data.loss_type<<data.loss_value;
			num++;
		}
	}
	msg.WriteData(numPos,&num,sizeof(num));
}

void CBangPaiManager::ShangXianOption(CUser *pUser,CNetMessage &msg,uint16 modeId,uint16 sxId,int chechaBangId)
{
	if(pUser == NULL)
	{
		msg<<PRO_ERROR;
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0061,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	CBangPai *pBangPai = FindBangPai(pUser->GetBangPai());
	if(pBangPai == NULL)
	{
		msg<<PRO_ERROR;
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0297,TIPS_FAILURE_COLOR).c_str());
		return;
	}

	string awardStr = LANGUAGE_SSJ_0355;
	string sxName;
	int logType = 0;
	int srcBangId = 0;
	int bangId = 0;
	int curTime = GetSysTime();
	char buf[512];
	SBPShangXian_ModeInfo mode;
	for(uint16 j=0;j < m_shangxian_mode.size();j++)
	{
		if(m_shangxian_mode[j].id == modeId)
		{
			mode = m_shangxian_mode[j];
			break;
		}
	}
	if(mode.id == 0)
	{
		msg<<PRO_ERROR;
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0061,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	if(mode.type == 2)	// 结交
	{
		if(!pBangPai->IsAdmin(pUser->GetRoleId()))
		{
			msg<<PRO_ERROR;
			SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0289,TIPS_FAILURE_COLOR).c_str());
			return;
		}
	}

	int idx = -1;
	if(mode.type <= 3)	// 除彻查外
	{
		boost::mutex::scoped_lock lk(m_mutex);
		uint16 size = m_shangxian_list.size();
		for(uint16 i=0;i < size;i++)
		{
			SBPShangXianData &data = m_shangxian_list[i];
			if(data.id == sxId)
			{
				srcBangId = data.bangpai_id;
				bangId = data.bangpai_id;
				sxName = data.name;
				if(mode.type == 2)	// 结交
				{
					if(data.protect_time > 0 && data.protect_time + SHANG_XIAN_PROTECT_TIME > curTime)
					{
						msg<<PRO_ERROR;
						SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0316+mode.name,TIPS_FAILURE_COLOR).c_str());
						return;
					}
					if(data.bangpai_id == (int)pUser->GetBangPai())
					{
						msg<<PRO_ERROR;
						SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0348,TIPS_FAILURE_COLOR).c_str());
						return;
					}
				}
				idx = i;
				break;
			}
		}
		if(idx == -1)
		{
			msg<<PRO_ERROR;
			SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0061,TIPS_FAILURE_COLOR).c_str());
			return;
		}
	}

	if((int)pUser->GetVipLevel() < mode.vip_limit)
	{
		msg<<PRO_ERROR;
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0302,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	for(uint8 j=0;j < sizeof(mode.need_item_id)/sizeof(mode.need_item_num[0]);j++)
	{
		if(mode.need_item_id[j] > 0 && mode.need_item_num[j] > 0)
		{
			if(mode.need_item_id[j] < HDAT_MONEY)
			{
				if(pUser->GetItemNum(mode.need_item_id[j]) < mode.need_item_num[j])
				{
					snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0303,GetItemName(mode.need_item_id[j]));
					msg<<PRO_ERROR;
					SendSysInfo(pUser,MakeStringColor(buf,TIPS_FAILURE_COLOR).c_str());
					return;
				}
			}
			else if(mode.need_item_id[j] == HDAT_MONEY)
			{
				if(pUser->GetMoney() < mode.need_item_num[j])
				{
					msg<<PRO_ERROR;
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0234,TIPS_FAILURE_COLOR).c_str());
					return;
				}
			}
			else if(mode.need_item_id[j] == HDAT_BANG_YB)
			{
				if(pUser->GetTongBao(1) < mode.need_item_num[j])
				{
					msg<<PRO_ERROR;
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0233,TIPS_FAILURE_COLOR).c_str());
					return;
				}
			}
			else if(mode.need_item_id[j] == HDAT_YB)
			{
				if(pUser->GetTongBao() < mode.need_item_num[j])
				{
					msg<<PRO_ERROR;
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0232,TIPS_FAILURE_COLOR).c_str());
					return;
				}
			}
			else if(mode.need_item_id[j] == HDAT_BANGPAI_MONEY)
			{
				if(pBangPai->GetMoney() < mode.need_item_num[j])
				{
					msg<<PRO_ERROR;
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0304,TIPS_FAILURE_COLOR).c_str());
					return;
				}
			}
		}
	}

	for(uint8 j=0;j < sizeof(mode.need_item_id)/sizeof(mode.need_item_num[0]);j++)
	{
		if(mode.need_item_id[j] > 0 && mode.need_item_num[j] > 0)
		{
			if(j > 0)
				awardStr += ",";
			if(mode.need_item_id[j] < HDAT_MONEY)
			{
				awardStr += GetItemName(mode.need_item_id[j]);
				awardStr += "*" + IntToStr(mode.need_item_num[j]);
				pUser->DelPackageById(mode.need_item_id[j],mode.need_item_num[j]);
			}
			else if(mode.need_item_id[j] == HDAT_MONEY)
			{
				awardStr += LANGUAGE_TRANSFORM_1500 + IntToStr(mode.need_item_num[j]);
				pUser->AddMoney(-mode.need_item_num[j]);
			}
			else if(mode.need_item_id[j] == HDAT_BANG_YB)
			{
				awardStr += LANGUAGE_TRANSFORM_1501 + IntToStr(mode.need_item_num[j]);
				pUser->AddTongBao(-mode.need_item_num[j],1);
			}
			else if(mode.need_item_id[j] == HDAT_YB)
			{
				awardStr += LANGUAGE_TRANSFORM_1502 + IntToStr(mode.need_item_num[j]);
				pUser->AddTongBao(-mode.need_item_num[j]);
			}
			else if(mode.need_item_id[j] == HDAT_BANGPAI_MONEY)
			{
				awardStr += LANGUAGE_SSJ_0308 + IntToStr(mode.need_item_num[j]);
				pBangPai->AddMoney(-mode.need_item_num[j]);
			}
		}
	}

	if(mode.type == 1)
		logType = EBLT_JIAOYOU;
	else if(mode.type == 2)
		logType = EBLT_JIE_JIAO;
	else if(mode.type == 3)
		logType = EBLT_QI_MOU;
	else if(mode.type == 4 || mode.type == 5)
		logType = EBLT_CHE_CHA;

	string ccName;
	string tarBPName;
	if(mode.type == 4 || mode.type == 5)
	{
		if(chechaBangId == 1)
			ccName = LANGUAGE_SSJ_0294;
		else if(chechaBangId == 2)
			ccName = LANGUAGE_SSJ_0295;
		else if(chechaBangId > 2)
		{
			CBangPai *p = FindBangPai(chechaBangId);
			if(p != NULL)
				ccName = p->GetName();
		}
	}
	if(srcBangId == 1)
		tarBPName = LANGUAGE_SSJ_0294;
	else if(srcBangId == 2)
		tarBPName = LANGUAGE_SSJ_0295;
	else if(srcBangId > 2)
	{
		CBangPai *p = FindBangPai(srcBangId);
		if(p != NULL)
			tarBPName = p->GetName();
	}

	int ratio = Random(1,10000);
	int succ_ratio = mode.succ_ratio * 100;
	if(mode.type == 2)
	{
		int srcQinMiVal = 0;
		if(srcBangId == 1 || srcBangId == 2)
			srcQinMiVal = m_shangxian_list[idx].qinmi;
		else
		{
			CBangPai *p = FindBangPai(srcBangId);
			if(p != NULL)
				srcQinMiVal = p->GetSXQinMi(sxId);
		}
		succ_ratio += pBangPai->GetSupportRatio(sxId,srcQinMiVal) * 100 + pBangPai->GetSupportRatioByLv() * 100;
	}
	if(succ_ratio > 10000)
		succ_ratio = 10000;
	if(ratio > succ_ratio)	// 失败
	{
		snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0305,mode.name.c_str());
		msg<<PRO_ERROR;
		SendSysInfo(pUser,MakeStringColor(buf,TIPS_FAILURE_COLOR).c_str());

		if(mode.type == 1)
			snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0365,pUser->GetName(),sxName.c_str(),mode.name.c_str());
		else if(mode.type == 2)
			snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0375,pUser->GetName(),sxName.c_str(),mode.name.c_str());
		else if(mode.type == 3)
			snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0369,pUser->GetName(),sxName.c_str(),mode.name.c_str());
		else if(mode.type == 4 || mode.type == 5)
			snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0369,pUser->GetName(),ccName.c_str(),mode.name.c_str());
		pBangPai->SaveLog(pUser->GetRoleId(),srcBangId,logType,buf,awardStr.c_str());

		if(mode.type == 4 || mode.type == 5)
			srcBangId = chechaBangId;
		if(srcBangId != 1 && srcBangId != 2 && (int)pBangPai->GetId() != srcBangId)
		{
			CBangPai *pTar = FindBangPai(srcBangId);
			if(pTar != NULL)
			{
				if(mode.type == 2)
					snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0367,pUser->GetName(),pBangPai->GetName().c_str(),sxName.c_str(),mode.name.c_str());
				else if(mode.type == 3 || mode.type == 4 || mode.type == 5)
					snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0371,pUser->GetName(),pBangPai->GetName().c_str(),sxName.c_str(),mode.name.c_str());
				else
					return;
				pTar->SaveLog(pUser->GetRoleId(),srcBangId,logType,buf);
			}
		}
		return;
	}

	int addQinMi = 0;
	string retStr;
	awardStr += ";";
	awardStr += LANGUAGE_SSJ_0358;
	for(uint8 j=0;j < sizeof(mode.gain_type)/sizeof(mode.gain_type[0]);j++)
	{
		if(mode.gain_type[j] > 0 && mode.gain_value[j] > 0)
		{
			if(j > 0)
				awardStr += ",";
			if(mode.gain_type[j] == 1)	// 个人帮贡
			{
				AddBangGong(pUser,mode.gain_value[j],false);
				if(!retStr.empty())
					retStr += ",";
				retStr += LANGUAGE_SSJ_0306 + IntToStr(mode.gain_value[j]);
				awardStr += LANGUAGE_SSJ_0306 + IntToStr(mode.gain_value[j]);
			}
			else if(mode.gain_type[j] == 2)	// 帮派亲密度
			{
				pBangPai->SetSXQinMi(sxId,pBangPai->GetSXQinMi(sxId)+mode.gain_value[j]);
				if(!retStr.empty())
					retStr += ",";
				retStr += LANGUAGE_SSJ_0307 + IntToStr(mode.gain_value[j]);
				awardStr += LANGUAGE_SSJ_0307 + IntToStr(mode.gain_value[j]);
				addQinMi += mode.gain_value[j];
			}
			else if(mode.gain_type[j] == 3)	// 帮派资金
			{
				pBangPai->SetMoney(pBangPai->GetMoney()+mode.gain_value[j]);
				if(!retStr.empty())
					retStr += ",";
				retStr += LANGUAGE_SSJ_0308 + IntToStr(mode.gain_value[j]);
				awardStr += LANGUAGE_SSJ_0308 + IntToStr(mode.gain_value[j]);
			}
			else if(mode.gain_type[j] == 4)	// 帮派影响力
			{
				pBangPai->SetYingXiangLi(pBangPai->GetYingXiangLi()+mode.gain_value[j]);
				if(!retStr.empty())
					retStr += ",";
				retStr += LANGUAGE_SSJ_0309 + IntToStr(mode.gain_value[j]);
				awardStr += LANGUAGE_SSJ_0309 + IntToStr(mode.gain_value[j]);
			}
		}
	}
	SendSysInfo(pUser,MakeStringColor((mode.name+LANGUAGE_SSJ_0310+retStr).c_str(),TIPS_WARNING_COLOR).c_str());

	string lossStr;
	int lossQinMi = 0;
	int lossMoney = 0;
	int lossYingXiangLi = 0;
	awardStr += ";";
	awardStr += LANGUAGE_SSJ_0359;
	if(mode.loss_type > 0 && mode.loss_value > 0)
	{
		if(mode.type == 4 || mode.type == 5)
			bangId = chechaBangId;
		if(bangId > 2)
		{
			CBangPai *pTar = FindBangPai(bangId);
			if(pTar != NULL)
			{
				if(mode.loss_type == 2)
				{
					if(pTar->GetSXQinMi(sxId) < mode.loss_value)
						pTar->SetSXQinMi(sxId,0);
					else
						pTar->SetSXQinMi(sxId,pTar->GetSXQinMi(sxId)-mode.loss_value);
					lossQinMi = mode.loss_value;
				}
				else if(mode.loss_type == 3)
				{
 					pTar->AddMoney(-mode.loss_value);
					lossMoney = mode.loss_value;
 				}
				else if(mode.loss_type == 4)
				{
					if(pTar->GetYingXiangLi() < mode.loss_value)
						pTar->SetYingXiangLi(0);
					else
	 					pTar->SetYingXiangLi(pTar->GetYingXiangLi()-mode.loss_value);
					lossYingXiangLi = mode.loss_value;
 				}
			}
		}
		else if(bangId >= 1 && bangId <= 2)
		{
			if(mode.loss_type == 2)
			{
				m_shangxian_list[idx].qinmi -= mode.loss_value;
				lossQinMi = mode.loss_value;
			}
			else if(mode.loss_type == 3)
			{
				lossMoney = mode.loss_value;
			}
			else if(mode.loss_type == 4)
			{
				lossYingXiangLi = mode.loss_value;
			}
		}

		if(mode.loss_type == 2)
		{
			lossStr += LANGUAGE_SSJ_0311 + IntToStr(mode.loss_value);
			awardStr += LANGUAGE_SSJ_0311 + IntToStr(mode.loss_value);
		}
		else if(mode.loss_type == 3)
 		{
 			lossStr += LANGUAGE_SSJ_0312 + IntToStr(mode.loss_value);
			awardStr += LANGUAGE_SSJ_0312 + IntToStr(mode.loss_value);
		}
		else if(mode.loss_type == 4)
		{
 			lossStr += LANGUAGE_SSJ_0313 + IntToStr(mode.loss_value);
			awardStr += LANGUAGE_SSJ_0313 + IntToStr(mode.loss_value);
		}
		if(mode.type == 4 || mode.type == 5)
			SendSysInfo(pUser,MakeStringColor(ccName+lossStr,TIPS_WARNING_COLOR).c_str());
		else
			SendSysInfo(pUser,MakeStringColor(tarBPName+lossStr,TIPS_WARNING_COLOR).c_str());
	}
	msg<<PRO_SUCCESS<<mode.type<<pBangPai->GetSXQinMi(sxId);

	if(mode.type == 1)	// 交游
		pUser->AddJiaoYouCount();
	else if(mode.type == 3)	// 奇谋
		pUser->AddQiMouCount();
	else if(mode.type == 4)	// 查验生石
		pUser->AddCheckYanShengShiCount();
	else if(mode.type == 5)	// 查堕仙印
		pUser->AddCheckDuoXianYinCount();

	if(mode.type == 1)
		snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0364,pUser->GetName(),sxName.c_str(),mode.name.c_str(),sxName.c_str(),addQinMi);
	else if(mode.type == 2)
		snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0374,pUser->GetName(),sxName.c_str(),mode.name.c_str());
	else
	{
		string srcBangName;
		string chechaBangName;
		if(srcBangId == 1)
		{
			srcBangName = LANGUAGE_SSJ_0294;
			chechaBangName = LANGUAGE_SSJ_0294;
		}
		else if(srcBangId == 2)
		{
			srcBangName = LANGUAGE_SSJ_0295;
			chechaBangName = LANGUAGE_SSJ_0295;
		}
		else
		{
			CBangPai *pSrc = FindBangPai(srcBangId);
			if(pSrc != NULL)
				srcBangName = pSrc->GetName();
			
			if(chechaBangId == 1)
				chechaBangName = LANGUAGE_SSJ_0294;
			else if(chechaBangId == 2)
				chechaBangName = LANGUAGE_SSJ_0295;
			else
			{
				pSrc = FindBangPai(chechaBangId);
				if(pSrc != NULL)
					chechaBangName = pSrc->GetName();
			}
		}
		if(mode.type == 3)
			snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0368,pUser->GetName(),sxName.c_str(),mode.name.c_str(),srcBangName.c_str(),lossQinMi);
		else if(mode.type == 4)
			snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0376,pUser->GetName(),chechaBangName.c_str(),mode.name.c_str(),chechaBangName.c_str(),lossMoney);
		else if(mode.type == 5)
			snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0377,pUser->GetName(),chechaBangName.c_str(),mode.name.c_str(),chechaBangName.c_str(),lossYingXiangLi);
	}
	if(mode.type >= 4)
		pBangPai->SaveLog(pUser->GetRoleId(),chechaBangId,logType,buf,awardStr.c_str());
	else
		pBangPai->SaveLog(pUser->GetRoleId(),srcBangId,logType,buf,awardStr.c_str());

	if(mode.type < 4)
	{
		if(srcBangId != 1 && srcBangId != 2 && (int)pBangPai->GetId() != srcBangId)
		{
			CBangPai *pTar = FindBangPai(srcBangId);
			if(pTar != NULL)
			{
				if(mode.type == 2)
				{
					snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0366,pUser->GetName(),pBangPai->GetName().c_str(),sxName.c_str(),mode.name.c_str(),lossQinMi);
					pTar->SaveLog(pUser->GetRoleId(),srcBangId,logType,buf);
				}
				else if(mode.type == 3)
				{
					snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0370,pUser->GetName(),pBangPai->GetName().c_str(),sxName.c_str(),mode.name.c_str(),lossQinMi);
					pTar->SaveLog(pUser->GetRoleId(),srcBangId,logType,buf);
				}
			}
		}
	}
	else
	{
		if(chechaBangId != 1 && chechaBangId != 2 && (int)pBangPai->GetId() != chechaBangId)
		{
			CBangPai *pTar = FindBangPai(chechaBangId);
			if(pTar != NULL)
			{
				if(mode.type == 4)
				{
					snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0378,pUser->GetName(),pBangPai->GetName().c_str(),mode.name.c_str(),lossMoney);
					pTar->SaveLog(pUser->GetRoleId(),chechaBangId,logType,buf);
				}
				else if(mode.type == 5)
				{
					snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0379,pUser->GetName(),pBangPai->GetName().c_str(),mode.name.c_str(),lossYingXiangLi);
					pTar->SaveLog(pUser->GetRoleId(),chechaBangId,logType,buf);
				}
			}
		}
	}

	//add by zhudaolong
	uint32 cd_time = 0;
	if(mode.type == 2 && idx != -1)	// 结交
	{
		{
			boost::mutex::scoped_lock lk(m_mutex);
			m_shangxian_list[idx].bangpai_id = pBangPai->GetId();
			m_shangxian_list[idx].protect_time = curTime;
			cd_time = m_shangxian_list[idx].protect_time + SHANG_XIAN_PROTECT_TIME;
		}
		string addTypeName = GetShangXianTypeName(m_shangxian_list[idx].add_type);
		snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0349,m_shangxian_list[idx].name.c_str(),addTypeName.c_str(),m_shangxian_list[idx].add_value);
		pBangPai->UpdateAllMemberZhanDouLi();
		pBangPai->SendMailToAllMember(buf);
		msg<<pBangPai->GetName()<<pBangPai->GetSXQinMi(sxId);

		if(srcBangId > 2)
		{
			CBangPai *pSrcBangPai = FindBangPai(srcBangId);
			if(pSrcBangPai != NULL)
			{
				snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0350,m_shangxian_list[idx].name.c_str(),pBangPai->GetName().c_str(),addTypeName.c_str(),m_shangxian_list[idx].add_value);
				pSrcBangPai->UpdateAllMemberZhanDouLi();
				pSrcBangPai->SendMailToAllMember(buf);
			}
		}
	}
	else
	{
		if(srcBangId == 1)
			msg<<LANGUAGE_SSJ_0294<<m_shangxian_list[idx].qinmi;
		else if(srcBangId == 2)
			msg<<LANGUAGE_SSJ_0295<<m_shangxian_list[idx].qinmi;
		else
		{
			CBangPai *pSrcBangPai = FindBangPai(srcBangId);
			if(pSrcBangPai != NULL)
				msg<<pSrcBangPai->GetName()<<pSrcBangPai->GetSXQinMi(sxId);
			else
				msg<<""<<0;
		}
	}
	msg<<cd_time;
}

void CBangPaiManager::ShangXianJieChu(CUser *pUser,CNetMessage &msg,uint16 sxId)
{
	if(pUser == NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0061,TIPS_FAILURE_COLOR);
		return;
	}
	CBangPai *pBangPai = FindBangPai(pUser->GetBangPai());
	if(pBangPai == NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0297,TIPS_FAILURE_COLOR);
		return;
	}
	if(!pBangPai->IsAdmin(pUser->GetRoleId()))
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0289,TIPS_FAILURE_COLOR);
		return;
	}

	int curTime = GetSysTime();
	string ownName;
	string sxName;
	int ownQinMi = 0;
	bool success = false;
	{
		boost::mutex::scoped_lock lk(m_mutex);
		uint16 size = m_shangxian_list.size();
		for(uint16 i=0;i < size;i++)
		{
			SBPShangXianData &data = m_shangxian_list[i];
			if(data.id == sxId)
			{
				if(data.protect_time > 0 && data.protect_time + SHANG_XIAN_PROTECT_TIME > curTime)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0317,TIPS_FAILURE_COLOR);
					return;
				}

				if(data.bangpai_id != (int)pBangPai->GetId())
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0318,TIPS_FAILURE_COLOR);
					return;
				}
				data.bangpai_id = data.src_bangpai_id;
				data.qinmi += 10000;
				success = true;
				if(data.bangpai_id == 1)
					ownName = LANGUAGE_SSJ_0341;
				else if(data.bangpai_id == 2)
					ownName = LANGUAGE_SSJ_0342;
				ownQinMi = data.qinmi;
				sxName = data.name;
				break;
			}
		}
	}
	if(success)
	{
		if(pBangPai->GetSXQinMi(sxId) < 10000)
			pBangPai->SetSXQinMi(sxId,0);
		else
			pBangPai->SetSXQinMi(sxId,pBangPai->GetSXQinMi(sxId)-10000);
		msg<<PRO_SUCCESS<<ownName<<ownQinMi<<pBangPai->GetSXQinMi(sxId)<<MakeStringColor(LANGUAGE_SSJ_0319,TIPS_WARNING_COLOR);

		char buf[512];
		snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0351,sxName.c_str());
		pBangPai->UpdateAllMemberZhanDouLi();
		pBangPai->SendMailToAllMember(buf);

		snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0363,pUser->GetName(),sxName.c_str(),10000);
		pBangPai->SaveLog(pUser->GetRoleId(),0,EBLT_JIE_CHU,buf);
	}
	else
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0061,TIPS_FAILURE_COLOR);
	}
}

int CBangPaiManager::GetMaxMissionNum()
{
	return m_missionList.size();
}

void CBangPaiManager::MakeCheckBangPaiList(CUser *pUser,CNetMessage &msg)
{
	uint32 self_BangId = pUser->GetBangPai();
	CBangPai *pBangPai = FindBangPai(self_BangId);
	if(pBangPai == NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0104,TIPS_FAILURE_COLOR);
		return;
	}
	msg<<PRO_SUCCESS;
	
	int tarBangPaiId = pBangPai->GetCheckTarBangId();
	uint16 num = 0;
	uint16 pos = msg.GetDataLen();
	msg<<num;
	vector<CBangPai*> bangList;
	{
		boost::mutex::scoped_lock lk(m_mutex);
		m_bangPaiList.ForEach(boost::bind(EachBangPai,_2,&bangList));
	}
	if(bangList.size() > 1)
	{
		SSortBangPai bangSort;
		std::sort(bangList.begin(),bangList.end(),bangSort);
	}

	msg<<(uint32)1<<LANGUAGE_SSJ_0294<<LANGUAGE_SSJ_0341<<(uint16)0<<(uint16)0<<(uint8)((tarBangPaiId == 1) ? 1 : 0);
	msg<<(uint32)2<<LANGUAGE_SSJ_0295<<LANGUAGE_SSJ_0342<<(uint16)0<<(uint16)0<<(uint8)((tarBangPaiId == 2) ? 1 : 0);
	num += 2;
	for(uint16 i = 0; i < bangList.size(); i++)
	{
		if(bangList[i] == NULL)
			continue;
		if(bangList[i]->GetId() == self_BangId)
			continue;
		if(bangList[i]->GetMemberNum()==0)
			continue;
		uint8 target = 0;	// 0未设置目标1设置目标
		if(tarBangPaiId == (int)bangList[i]->GetId())
			target = 1;
		list<uint32> memberList;
		bangList[i]->GetMember(memberList);
		msg<<bangList[i]->GetId()<<bangList[i]->GetName()<<bangList[i]->GetBangZhuName()<<bangList[i]->GetMemberNum();
		msg<<bangList[i]->GetMaxMemberNum()<<target;
		num++;
	}
	msg.WriteData(pos,&num,sizeof(num));
}

void CBangPaiManager::GetShangXianAttr(uint32 bangpaiId,SBP_ShangXianAttr &attr)
{
	attr.Clear();
	if(bangpaiId == 0)
		return;
	
	CBangPai *pBangPai = FindBangPai(bangpaiId);
	if(pBangPai == NULL)
		return;
//	boost::mutex::scoped_lock lk(m_mutex);
	for(uint32 i=0;i < m_shangxian_list.size();i++)
	{
		SBPShangXianData &data = m_shangxian_list[i];
		if(data.bangpai_id == (int)bangpaiId)
		{
			if(data.add_type == 1)
				attr.speed += data.add_value;
			else if(data.add_type == 2)
				attr.recovery += data.add_value;
			else if(data.add_type == 3)
				attr.jianshang += data.add_value;
			else if(data.add_type == 4)
				attr.renxing += data.add_value;
			else if(data.add_type == 5)
				attr.shanbi += data.add_value;
			else if(data.add_type == 6)
				attr.attack += data.add_value;
			else if(data.add_type == 7)
				attr.baoji += data.add_value;
			else if(data.add_type == 8)
				attr.maxHp += data.add_value;
			else if(data.add_type == 9)
				attr.fanshang += data.add_value;
			else if(data.add_type == 10)
				attr.mingzhong += data.add_value;
		}
	}
}

void CBangPaiManager::GetBPQinMiPaiHang(CNetMessage &msg,uint16 sxId)
{
	if(sxId == 0)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0061,TIPS_FAILURE_COLOR);
		return;
	}

	vector<CBangPai*> bangList;
	SBPShangXianData data;
	{
		bool isFind = false;
		boost::mutex::scoped_lock lk(m_mutex);
		for(uint32 i=0;i < m_shangxian_list.size();i++)
		{
			if(m_shangxian_list[i].id == sxId)
			{
				data = m_shangxian_list[i];
				isFind = true;
				break;
			}
		}
		if(!isFind || data.id == 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0061,TIPS_FAILURE_COLOR);
			return;
		}
		m_bangPaiList.ForEach(boost::bind(EachBangPai,_2,&bangList));
	}
	
	if(bangList.size() > 1)
	{
		SSortBangPaiSXQinMi func;
		func.sxId = sxId;
		std::sort(bangList.begin(),bangList.end(),func);
	}
	
	msg<<PRO_SUCCESS;
	uint16 num = 0;
	uint16 pos = msg.GetDataLen();
	msg<<num;
	msg<<(uint32)1<<LANGUAGE_SSJ_0294<<LANGUAGE_SSJ_0341<<((data.src_bangpai_id == 1) ? data.qinmi : 0);
	msg<<(uint32)2<<LANGUAGE_SSJ_0295<<LANGUAGE_SSJ_0342<<((data.src_bangpai_id == 2) ? data.qinmi : 0);
	num += 2;
	for(uint16 i = 0; i < bangList.size(); i++)
	{
		if(bangList[i] == NULL)
			continue;
		if(bangList[i]->GetMemberNum()==0)
			continue;
		msg<<bangList[i]->GetId()<<bangList[i]->GetName()<<bangList[i]->GetBangZhuName()<<bangList[i]->GetSXQinMi(sxId);
		num++;
	}
	msg.WriteData(pos,&num,sizeof(num));
}

void CBangPaiManager::MakeHaveShangXianList(int bangId,CNetMessage &msg)
{
	uint8 num = 0;
	uint16 numPos = msg.GetDataLen();
	msg<<num;
	if(bangId == 0)
		return;

	CBangPai *pBangPai = FindBangPai(bangId);
	if(pBangPai == NULL)
		return;
	boost::mutex::scoped_lock lk(m_mutex);
	for(uint32 i=0;i < m_shangxian_list.size();i++)
	{
		if(m_shangxian_list[i].bangpai_id == bangId)
		{
			msg<<m_shangxian_list[i].id;
			num++;
		}
	}
	msg.WriteData(numPos,&num,sizeof(num));
}

void CBangPaiManager::BangZhuTimer()
{
	vector<CBangPai*> bangList;
	{
		boost::mutex::scoped_lock lk(m_mutex);
		m_bangPaiList.ForEach(boost::bind(EachBangPai, _2, &bangList));
	}
	for (int i = 0; i < (int)bangList.size(); i++)
	{
		if (bangList[i] != NULL)
		{
			bangList[i]->CheckChangeBangzhu();
		}
	}
}

void CBangPaiManager::BangPaiShangXianTimer()
{
	const int TIME_SPACE = 5*24*3600;
	static bool IsJiaoYou = true;
	static bool IsCheCha = true;
	static bool IsQiMou = true;	
	int curTime = GetSysTime();
	int hour = GetHour();
	int minute = GetMinute();
	
	vector<SBPShangXian_ModeInfo> modeList;
	{
		boost::mutex::scoped_lock lk(m_mutex);
		if(hour%6 == 1 && minute >= 10 && IsJiaoYou)
		{
			IsJiaoYou = false;
			
			for(uint32 i=0;i < m_shangxian_mode.size();i++)
			{
				SBPShangXian_ModeInfo &data = m_shangxian_mode[i];
				if(data.type == 1)
					modeList.push_back(data);
			}
		}
		else if(hour%12 == 3 && minute >= 25 && IsCheCha)
		{
			IsCheCha = false;

			for(uint32 i=0;i < m_shangxian_mode.size();i++)
			{
				SBPShangXian_ModeInfo &data = m_shangxian_mode[i];
				if(data.type == 4 || data.type == 5)
					modeList.push_back(data);
			}
		}
		else if(hour == 5 && minute >= 48 && IsQiMou)
		{
			IsQiMou = false;

			for(uint32 i=0;i < m_shangxian_mode.size();i++)
			{
				SBPShangXian_ModeInfo &data = m_shangxian_mode[i];
				if(data.type == 3)
					modeList.push_back(data);
			}
		}

		for(uint32 i=0;i < m_shangxian_mode.size();i++)
		{
			SBPShangXian_ModeInfo &data = m_shangxian_mode[i];
			if(data.type == 2)
				modeList.push_back(data);
		}
	}

	if(modeList.empty())
		return;
	vector<CBangPai *> initBangPaiList;
	{
		char buf[512];
		boost::mutex::scoped_lock lk(m_mutex);
		for(uint32 i=0;i < m_shangxian_list.size();i++)
		{
			SBPShangXianData &data = m_shangxian_list[i];
			if(data.bangpai_id != data.src_bangpai_id)
			{
				uint32 idx = Random(1,modeList.size())-1;
				SBPShangXian_ModeInfo &mode = modeList[idx];
				if(mode.type == 2)
				{
					if(curTime - data.timer_time < TIME_SPACE || curTime - data.protect_time < SHANG_XIAN_PROTECT_TIME)
						continue;
					data.timer_time = curTime;
				}
				int r = Random(1,10000);
				int lossQinMi = 0;
				int lossMoney = 0;
				int lossYingXiangLi = 0;
				int succRatio = mode.succ_ratio*100;
				if(mode.type == 2)
					succRatio = 8000;
				string name;
				string bzName;
				if(data.src_bangpai_id == 1)
				{
					name = LANGUAGE_SSJ_0294;
					bzName = LANGUAGE_SSJ_0341;
				}
				else if(data.src_bangpai_id == 2)
				{
					name = LANGUAGE_SSJ_0295;
					bzName = LANGUAGE_SSJ_0342;
				}

				if(r <= succRatio)
				{
					for(uint16 j=0;j < sizeof(mode.gain_type)/sizeof(mode.gain_type[0]);j++)
					{
						if(mode.gain_type[j] == 2)
							data.qinmi += mode.gain_value[j];
					}
					CBangPai *pTar = NULL;
					if(mode.loss_type > 0)
					{
						m_bangPaiList.Find(data.bangpai_id,pTar);
						if(pTar != NULL)
						{
							if(mode.loss_type == 2)
							{
								if(pTar->GetSXQinMi(data.id) < mode.loss_value)
									pTar->SetSXQinMi(data.id,0);
								else
									pTar->SetSXQinMi(data.id,pTar->GetSXQinMi(data.id)-mode.loss_value);
								lossQinMi = mode.loss_value;
							}
							else if(mode.loss_type == 3)
							{
			 					pTar->AddMoney(-mode.loss_value);
								lossMoney = mode.loss_value;
			 				}
							else if(mode.loss_type == 4)
							{
								if(pTar->GetYingXiangLi() < mode.loss_value)
									pTar->SetYingXiangLi(0);
								else
				 					pTar->SetYingXiangLi(pTar->GetYingXiangLi()-mode.loss_value);
								lossYingXiangLi = mode.loss_value;
			 				}
						}
					}

					if(pTar != NULL)
					{
						if(mode.type == 1)	// 交游
						{

						}
						else if(mode.type == 2)	// 结交
						{
							data.bangpai_id = data.src_bangpai_id;
							data.protect_time = curTime;
							initBangPaiList.push_back(pTar);
							snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0366,bzName.c_str(),name.c_str(),data.name.c_str(),mode.name.c_str(),lossQinMi);
							pTar->SaveLog(data.src_bangpai_id,data.bangpai_id,EBLT_JIE_JIAO,buf);

							snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0350,data.name.c_str(),name.c_str(),GetShangXianTypeName(data.add_type).c_str(),data.add_value);
							pTar->SendMailToAllMember(buf);
						}
						else if(mode.type == 3)	// 奇谋
						{
							snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0372,name.c_str(),data.name.c_str(),mode.name.c_str(),lossQinMi);
							pTar->SaveLog(data.src_bangpai_id,data.bangpai_id,EBLT_QI_MOU,buf);
						}
						else if(mode.type == 4)	// 彻查
						{
							snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0380,name.c_str(),"",mode.name.c_str(),lossMoney);
							pTar->SaveLog(data.src_bangpai_id,data.bangpai_id,EBLT_CHE_CHA,buf);
						}
						else if(mode.type == 5)
						{
							snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0381,name.c_str(),"",mode.name.c_str(),lossYingXiangLi);
							pTar->SaveLog(data.src_bangpai_id,data.bangpai_id,EBLT_CHE_CHA,buf);
						}
					}
				}
				else
				{
					CBangPai *pTar = NULL;
					m_bangPaiList.Find(data.bangpai_id,pTar);
					if(pTar != NULL)
					{
						if(mode.type == 1)	// 交游
						{

						}
						else if(mode.type == 2)	// 结交
						{
							snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0367,bzName.c_str(),name.c_str(),data.name.c_str(),mode.name.c_str());
							pTar->SaveLog(data.src_bangpai_id,data.bangpai_id,EBLT_JIE_JIAO,buf);
						}
						else if(mode.type == 3)	// 奇谋
						{
							snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0369,name.c_str(),data.name.c_str(),mode.name.c_str());
							pTar->SaveLog(data.src_bangpai_id,data.bangpai_id,EBLT_QI_MOU,buf);
						}
						else if(mode.type == 4)	// 彻查
						{
							snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0373,name.c_str(),"",mode.name.c_str());
							pTar->SaveLog(data.src_bangpai_id,data.bangpai_id,EBLT_CHE_CHA,buf);
						}
						else if(mode.type == 5)
						{
							snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0373,name.c_str(),"",mode.name.c_str());
							pTar->SaveLog(data.src_bangpai_id,data.bangpai_id,EBLT_CHE_CHA,buf);
						}
					}
				}
			}
		}
	}
	for(uint32 i=0;i < initBangPaiList.size();i++)
	{
		if(initBangPaiList[i] != NULL)
			initBangPaiList[i]->UpdateAllMemberZhanDouLi();
	}

	if(hour%6 == 0 && !IsJiaoYou)
		IsJiaoYou = true;
	if(hour%12 == 0 && !IsCheCha)
		IsCheCha = true;
	if(hour == 0 && !IsQiMou)
		IsQiMou = true;
}

string CBangPaiManager::GetRankName(uint8 rank)
{
	switch (rank)
	{
	case EBRBangZhu:
		return LANGUAGE_ZQX_0013;

	case EBRZhangLao:
		return LANGUAGE_ZQX_0014;

	case EBRHuFa:
		return LANGUAGE_ZQX_0015;

	case EBRBangZhong:
		return LANGUAGE_ZQX_0016;
	}
	return "";
}
