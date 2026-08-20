#include <iostream>
#include "pack_deal.h"
#include "main.h"
#include "singleton.h"
#include "call_script.h"
#include "script_call.h"
#include "huo_dong.h"
#include "utility.h"
#include "mission_manager.h"
#include "init.h"
#include "pet_equip_manage.h"
#include "role_simple_mgr.h"
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <signal.h>
#include <boost/bind.hpp>
#include <boost/archive/binary_oarchive.hpp>
#include <boost/archive/text_oarchive.hpp>
#include <fstream>
#include <sstream>
#include <zlib.h>
#include <boost/thread/thread.hpp>
#include <boost/format.hpp>
#include "award_manager.h"
#include "rank.h"
#include "arena.h"
#include "friend.h"

using namespace std;

const char *gConfigFile = "config";
CDatabaseSql g_LoginDB;
boost::recursive_mutex G_LoginDB_Mutex;

vector<SChongZhiData> G_CZ_INFO_A;
vector<SChongZhiData> G_CZ_INFO_IOS;
vector<SChongZhiData> G_CZ_INFO_RMBSHOP;
vector<SChongZhiData> G_CZ_MYCARD;
vector<SChongZhiData> G_CZ_INFO_WEIXIN;
vector<SChongZhi2OtherAward> G_CZ_TO_OTHER_INFO;

time_t last_loadFanlicfg_time = 0;
boost::recursive_mutex cz_fanli_mutex;	//充值返利返物品

std::map<uint16,SkillInfoNode> skillInfoListMap;
boost::recursive_mutex tongTianTa_mutex;
list<ArenaPaiHangData> arenaPaiHang;	//竞技场排行

uint16 tongTianTaBaZhuFloor[5] = {20,60,100,150,200};
vector<uint32> tongTianTaBaZhuData;		//通天塔霸主ID,20/60/100/150/200
boost::recursive_mutex lingQiJuanXian_mutex;//灵气捐献
int lingQiValue = 0;		//灵气捐献系统值
int refreshLingQiValue = 0;	//刷怪时的灵气值
vector<uint32> topBangPai;

map<int, int> guaiWuGongChengItemCount;	//怪物攻城奖励的道具数量记录

int mdCheckSock = 0;
int mdCheckIndex = 0;
int mdCheckIndexArr[MAX_CON_USER];
string mdCheckHost = "";
int mdCheckPort = 0;
//随机宝箱相关
uint32 randombox_stamp = 0;//随机宝箱数据库刷新时间戳    
std::map<uint32,uint32> limitSaveMap;
std::map<uint32,RandomBoxItem> randombox_cfg;//随机宝箱配置

static void EachUserNoLock(CUser *pUser,CDatabaseSql *pDb)
{
	if(pUser == NULL || pDb == NULL)
		return;
	pUser->SaveData(pDb,false);
	pUser->SaveLoginLog(pDb);

#ifdef KUA_FU
	CopyKuaFuDataToGameServer(pUser->GetRoleId(),pUser->GetServerId());
#endif
}

static bool sExit = true;
static void SigHandlerCreateCore(int sig)
{
	cout<<"SigHandlerCreateCore sig="<<sig<<endl;
	SingletonCBangPaiManager::instance().SaveBangPai();
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	onlineUser.ForEachUserNoLock(boost::bind(EachUserNoLock,_1,pDb));
	abort();
	sExit = false;
}

static void EachUser(CUser *pUser,CDatabaseSql *pDb)
{
	if(pUser == NULL || pDb == NULL)
		return;
	pUser->SaveData(pDb);
	pUser->SaveLoginLog(pDb);

#ifdef KUA_FU
	CopyKuaFuDataToGameServer(pUser->GetRoleId(),pUser->GetServerId());
#endif
}

static void SigHandler(int sig)
{
	cout<<"SigHandler sig="<<sig<<endl;
	cout<<"save bangPaiZhongZhi"<<endl;
	SingletonCBangPaiManager::instance().SaveBangPai();
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	
	cout<<"save role data"<<endl;
	onlineUser.ForEachUser(boost::bind(EachUser,_1,pDb));
	
	cout<<"save arena"<<endl;
	SingletonCArenaManager::instance().Save();

//	cout<<"save TongTianTa"<<endl;
//	SaveTongTianTa();

	cout<<"save PaiHangBang"<<endl;
	SingletonCHuoDongAwardManager::instance().SaveHDPaiHangRecord(true);
	SaveHuoDongGlobalData();

	cout<<"save HuoDong INFO"<<endl;
	SingletonCHuoDongAwardManager::instance().Save();

	cout<<"save HuoDong Qiang Hong Bao"<<endl;
	SingletonCHuoDongAwardManager::instance().SaveQiangHongBaoRecord(true);

#ifdef KUA_FU
	cout<<"save kuafu_1v1_preliminary"<<endl;
	SingletonCKuaFu1vs1PreliminaryManager::instance().SaveDB();

	cout<<"save kuafu_1v1_final_data"<<endl;
	SaveKuaFu1V1FinalData();

	cout<<"save shenjiemijing boss_ratio"<<endl;
	SingletonCShenJieMiJingManager::instance().SaveDB();

	cout<<"save qunxianzhengba paihang"<<endl;
	SingletonCQunXianZhengBaManager::instance().SavePaiHang();
#endif
	cout<<"save ShopManager data"<<endl;
	SingletonShopManager::instance().Save();

//	cout<<"save CRankDataMgr data"<<endl;
//	SingletonCRankDataMgr::instance().SaveDB();

	cout<<"save CSimpleRoleDataMgr data"<<endl;
	SingletonCSimpleRoleDataMgr::instance().Save();

	cout<<"save CFriendMgr data"<<endl;
	SingletonCFriendMgr::instance().Save();

	cout<<"save CRankMgr data"<<endl;
	SingletonCRankMgr::instance().Save();

	sExit = false;
	cout<<"save data end"<<endl;
}

static bool InitSysTime()
{
	time_t t,t1;
	struct timeval tv;
	local_gettimeofday(&tv, NULL);
	SetSysTime(tv.tv_sec);
	SetSysTimeMs(tv.tv_usec/1000);
	t = GetSysTime();
	t1 = t;
	tm *pTm = localtime(&t);
	if(pTm == NULL)
		return false;
	SetSysYear(pTm->tm_year);
	SetSysYDay(pTm->tm_yday);
	SetSysWDay(pTm->tm_wday);
	SetSysMonth(pTm->tm_mon);
	SetSysMDay(pTm->tm_mday);
	SetSysHour(pTm->tm_hour);
	SetSysMinute(pTm->tm_min);
	SetSysSecond(pTm->tm_sec);
	
	// 每周一 0点
	int wday = pTm->tm_wday;
	if(GetClearWeekTime() == 0)
	{
		if(pTm->tm_wday == 0)
		{
			t -= pTm->tm_wday*3600*24+pTm->tm_hour*3600+pTm->tm_min*60+pTm->tm_sec + 6*24*3600;
		}
		else
		{
			t -= pTm->tm_wday*3600*24+pTm->tm_hour*3600+pTm->tm_min*60+pTm->tm_sec;
			t += 3600*24;
		}
		SetClearWeekTime(t);
	}
	if(wday == 1)
	{
		if(t - GetClearWeekTime() > 24*3600)
			SetClearWeekTime(t);
	}
	
	t = t1;
	int mday = pTm->tm_mday;
	if(GetClearMonthTime() == 0)
	{
		t -= (pTm->tm_mday-1)*3600*24 + pTm->tm_hour*3600+pTm->tm_min*60+pTm->tm_sec;
		SetClearMonthTime(t);
	}
	if(mday == 1)
	{
		if(t - GetClearMonthTime() > 24*3600)
		{
			t = (pTm->tm_mday-1)*3600*24 + pTm->tm_hour*3600+pTm->tm_min*60+pTm->tm_sec;
			SetClearMonthTime(t);
		}
	}
	
	t = t1;
	int hour = pTm->tm_hour;
	if(GetClearDayTime() == 0)
	{
		t -= pTm->tm_hour*3600+pTm->tm_min*60+pTm->tm_sec;
		SetClearDayTime(t);
	}
	if(hour == 0)
	{
		if(t - GetClearDayTime() > 3600)
		{
			t -= pTm->tm_hour*3600+pTm->tm_min*60+pTm->tm_sec;
			SetClearDayTime(t);
		}
	}
	return true;
}

static void SaveUserData()
{
	gyu::util::SetSignal(&SigHandler, &SigHandlerCreateCore);
	while(sExit)
	{
		sleep(1);
		InitSysTime();
	}
}

static bool InitConfig()
{
	if(!SingletonCFriendMgr::instance().Init())
	{
		cout<<"ReadFriendData falied !!!"<<endl;
		return false;
	}

	if(!ReadSkillConfig())
	{
		cout<<"ReadSkillConfig() falied !!!"<<endl;
		return false;
	}
	if(!HuoDongExpInfo())
	{
		cout<<"HuoDongExpInfo() falied !!!"<<endl;
		return false;
	}
	if(!ReadMonsterDistribution())
	{
		cout<<"ReadMonsterDistribution() falied !!!"<<endl;
		return false;
	}
	if(!ReadItem())
	{
		cout<<"ReadItem() falied !!!"<<endl;
		return false;
	}
	if(!InitVipConfig())
	{
		cout<<"InitVipConfig() falied !!!"<<endl;
		return false;
	}
	if(!LoadRandomBoxCfg())
	{
		cout<<"LoadRandomBoxCfg() falied !!!"<<endl;
		return false;
	}
	if(!SingletonCArenaManager::instance().Init())
	{
		cout<<"SingletonCArenaManager::instance().Init() falied !!!"<<endl;
		return false;
	}
	if(!InitTongTianTa())
	{
		cout<<"InitTongTianTa() falied !!!"<<endl;
		return false;
	}
	if(!LoadMoBaiLog())
	{
		cout<<"LoadMoBaiLog() falied !!!"<<endl;
		return false;
	}
	if(gyu::util::CIniFile::GetValue("local_test","server",gConfigFile) == "1")
	{
		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		if(pDb != NULL)
		{
			pDb->Query("CREATE TABLE IF NOT EXISTS `question` (`id` int NOT NULL AUTO_INCREMENT, PRIMARY KEY (`id`)) ENGINE=MyISAM DEFAULT CHARSET=utf8");
			struct SLocalColumn
			{
				const char *name;
				const char *define;
			};
			const SLocalColumn questionColumns[] = {
				{"question", "`question` varchar(255) NOT NULL DEFAULT ''"},
				{"answer1", "`answer1` varchar(255) NOT NULL DEFAULT ''"},
				{"answer2", "`answer2` varchar(255) NOT NULL DEFAULT ''"},
				{"answer3", "`answer3` varchar(255) NOT NULL DEFAULT ''"},
				{"answer4", "`answer4` varchar(255) NOT NULL DEFAULT ''"},
			};
			char sql[1024];
			for(size_t i = 0; i < sizeof(questionColumns) / sizeof(questionColumns[0]); ++i)
			{
				snprintf(sql, sizeof(sql), "SHOW COLUMNS FROM `question` LIKE '%s'", questionColumns[i].name);
				if(pDb->Query(sql) && pDb->GetRow() == NULL)
				{
					snprintf(sql, sizeof(sql), "ALTER TABLE `question` ADD COLUMN %s", questionColumns[i].define);
					pDb->Query(sql);
				}
			}
			if(pDb->Query("select count(id) from question"))
			{
				char **row = pDb->GetRow();
				int questionCount = (row == NULL) ? 0 : atoi(row[0]);
				for(int i = questionCount; i < 21; ++i)
				{
					snprintf(sql, sizeof(sql), "insert into question (question,answer1,answer2,answer3,answer4) values ('Local test question %d?','A','B','C','D')", i + 1);
					pDb->Query(sql);
				}
			}
			pDb->Query("update question set question=if(question='',concat('Local test question ',id,'?'),question),answer1=if(answer1='','A',answer1),answer2=if(answer2='','B',answer2),answer3=if(answer3='','C',answer3),answer4=if(answer4='','D',answer4)");
		}
	}
	if(GetQuestion() == NULL)
	{
		cout<<"Load Question falied !!!"<<endl;
		return false;
	}
	if(!SingletonCPlantSeedManager::instance().Init())
	{
		cout<<"SingletonCPlantSeedManager::instance().Init() falied !!!"<<endl;
		return false;
	}
	if(!SingletonCFestivalRandomBoxManager::instance().Init())
	{
		cout<<"SingletonCFestivalRandomBoxManager::instance().Init() falied !!!"<<endl;
		return false;
	}
	if(!SingletonCXianYuanManager::instance().Init())
	{
		cout<<"SingletonCXianYuanManager::instance().Init() falied !!!"<<endl;
		return false;
	}
	if(!SingletonCTransFormManager::instance().LoadDB())
	{
		cout<<"SingletonCTransFormManager::instance().LoadDB() falied !!!"<<endl;
		return false;
	}
	if(!SingletonCJiaoYiHangManager::instance().Init())
	{
		cout<<"SingletonCJiaoYiHangManager::instance() falied !!!"<<endl;
		return false;
	}

	if( !SingletonCFunctionSwitchManager::instance().Init())
	{
		cout<<"SingletonCFunctionSwitchManager()::instance()  falied !!!"<<endl;
		return false;
	}
#ifdef KUA_FU
	if(!SingletonCKuaFu1vs1PreliminaryManager::instance().LoadDB())
	{
		cout<<"SingletonCKuaFu1vs1PreliminaryManager::instance().Init() falied !!!"<<endl;
		return false;
	}
	if(!ReadKuaFu1V1FinalDataFromDB())
	{
		cout<<"ReadKuaFu1V1FinalDataFromDB() falied !!!"<<endl;
		return false;
	}
	if( !SingletonCShenJieMiJingManager::instance().Init())
	{
		cout<<"ReadShenJieMiJingFromDB() falied !!!"<<endl;
		return false;
	}
	
#endif
	return true;
}

static bool ConfigInit()
{
	if(!InitJsonConfig())
		return false;
	string localTest = gyu::util::CIniFile::GetValue("local_test","server",gConfigFile);
	if(localTest == "1")
		cout << "[local] ConfigInit: loading complete gameplay configuration" << endl;
	if(!InitXMLConfig())
		return false;
	return true;
}

static bool InitDB(SServerBasicCfg &cfg)
{
	string localTest = gyu::util::CIniFile::GetValue("local_test","server",gConfigFile);
	if(localTest == "1")
	{
		string serverIdStr = gyu::util::CIniFile::GetValue("server_id","server",gConfigFile);
		int serverId = atoi(serverIdStr.c_str());
		if(serverId < 1)
			serverId = 1;

		cfg.port = atoi(gyu::util::CIniFile::GetValue("port","server",gConfigFile).c_str());
		cfg.dbId = 1;
		cfg.longHost = gyu::util::CIniFile::GetValue("host","long_server",gConfigFile);
		cfg.long_port = atoi(gyu::util::CIniFile::GetValue("port","long_server",gConfigFile).c_str());
		cfg.matchHost = gyu::util::CIniFile::GetValue("host","queue",gConfigFile);
		cfg.match_port = atoi(gyu::util::CIniFile::GetValue("port","queue",gConfigFile).c_str());
		cfg.server_type = gyu::util::CIniFile::GetValue("server_type","server",gConfigFile);
		cfg.version = gyu::util::CIniFile::GetValue("client_version","server",gConfigFile);
		cfg.dbHost = gyu::util::CIniFile::GetValue("host","database",gConfigFile);
		cfg.dbPort = gyu::util::CIniFile::GetValue("port","database",gConfigFile);
		cfg.dbName = gyu::util::CIniFile::GetValue("dbname","database",gConfigFile);
		cfg.dbUser = gyu::util::CIniFile::GetValue("username","database",gConfigFile);
		cfg.dbPwd = gyu::util::CIniFile::GetValue("password","database",gConfigFile);

		vector<int> serverIdList;
		serverIdList.push_back(serverId);
		SetServerIdList(serverIdList);
		SetSelfZoneId(serverId);
		SetServerType(cfg.server_type);
		SetServerOpenTime((uint32)time(NULL));
		return cfg.port > 0 && !cfg.dbName.empty();
	}

	string user = gyu::util::CIniFile::GetValue("username","login_db",gConfigFile);
	string password = gyu::util::CIniFile::GetValue("password","login_db",gConfigFile);
	string host = gyu::util::CIniFile::GetValue("host","login_db",gConfigFile);
	string db = gyu::util::CIniFile::GetValue("dbname","login_db",gConfigFile);
	string port = gyu::util::CIniFile::GetValue("port","login_db",gConfigFile);
	if(!g_LoginDB.Connect(user.c_str(),password.c_str(),host.c_str(),db.c_str(),atoi(port.c_str())))
	{
		cout<<"InitDB() : connect login db error"<<endl;
		return false;
	}

	char sql[512];
	char **row = NULL;
#ifndef KUA_FU
	string str = gyu::util::CIniFile::GetValue("server_id","server",gConfigFile);
	int serverId = atoi(str.c_str());
	if(str.empty() || serverId < 1)
	{
		cout<<"InitDB() : config.server.server_id error! "<<endl;
		return false;
	}
	//                         0      1       2       3        4          5           6           7       8    9      10     11    12            13
	snprintf(sql,sizeof(sql),"select s.port,s.db_id,s.long_ip,s.long_port,s.match_ip,s.match_port,s.server_type,s.version_limit,d.ip,d.port,d.db_name,d.user,d.pwd,unix_timestamp(s.openTime) from server_list as s,db_config as d where s.server_id=%d and s.db_id=d.id",serverId);
	if(!g_LoginDB.Query(sql))
	{
		cout<<"InitDB() : g_LoginDB.Query(sql) error1 , cannot find server_id  ...  sql="<<sql<<endl;
		return false;
	}
	if((row = g_LoginDB.GetRow()) == NULL)
	{
		cout<<"InitDB() : g_LoginDB.GetRow() error ... "<<endl;
		return false;
	}
	cfg.port = atoi(row[0]);
	cfg.dbId = atoi(row[1]);
	cfg.longHost = row[2];
	cfg.long_port = atoi(row[3]);
	cfg.matchHost = row[4];
	cfg.match_port = atoi(row[5]);
	cfg.server_type = row[6];
	cfg.version = row[7];
	cfg.dbHost = row[8];
	cfg.dbPort = row[9];
	cfg.dbName = row[10];
	cfg.dbUser = row[11];
	cfg.dbPwd = row[12];
	uint32 openTime = atoi(row[13]);
	SetServerOpenTime(openTime);

	if(cfg.dbId < 1)
	{
		cout<<"InitDB() :  dbId config  error "<<endl;
		return false;
	}
	SetServerType(cfg.server_type);
	
	snprintf(sql,sizeof(sql),"select server_id from server_list where db_id=%d order by server_id asc",cfg.dbId);
	if(!g_LoginDB.Query(sql))
	{
		cout<<"InitDB() : g_LoginDB.Query(sql) error2 , cannot find server_id  ...  sql="<<sql<<endl;
		return false;
	}
#else
	string str = gyu::util::CIniFile::GetValue("kuafuID","server",gConfigFile);
	int kuafuId = atoi(str.c_str());
	if(str.empty() || kuafuId < 1)
	{
		cout<<"InitDB() : config.server.kuafuID error! "<<endl;
		return false;
	}

	//                         0     1       2       3        4       5       6     7       8      9
	snprintf(sql,sizeof(sql),"SELECT port,long_ip,long_port,match_ip,match_port,db_host,db_port,db_user,db_pwd,db_name FROM kf_config WHERE id=%d",kuafuId);
	if(!g_LoginDB.Query(sql))
	{
		cout<<"InitDB() : g_LoginDB.Query(sql) error1 , cannot find kuafuID  ...	sql="<<sql<<endl;
		return false;
	}
	if((row = g_LoginDB.GetRow()) == NULL)
	{
		cout<<"InitDB() : g_LoginDB.GetRow() error ... "<<endl;
		return false;
	}
	cfg.port = atoi(row[0]);
	cfg.longHost = row[1];
	cfg.long_port = atoi(row[2]);
	cfg.matchHost = row[3];
	cfg.match_port = atoi(row[4]);
	cfg.dbHost = row[5];
	cfg.dbPort = row[6];
	cfg.dbUser = row[7];
	cfg.dbPwd = row[8];
	cfg.dbName = row[9];

	snprintf(sql,sizeof(sql),"select server_id from server_list where kf_id=%d order by server_id asc",kuafuId);
	if(!g_LoginDB.Query(sql))
	{
		cout<<"InitDB() : g_LoginDB.Query(sql) error2 , cannot find kuafuID  ...	sql="<<sql<<endl;
		return false;
	}
#endif

	int zoneId = 0;
	vector<int> serverIdList;
	while((row = g_LoginDB.GetRow()) != NULL)
	{
		int serverId = atoi(row[0]);
		if(serverId < 1)
			continue;
#ifndef KUA_FU
		if(zoneId == 0)
			zoneId = serverId;
		else if(zoneId > serverId)
			zoneId = serverId;
#endif
		serverIdList.push_back(serverId);
	}
	if(serverIdList.empty())
	{
		cout<<"InitDB() : serverIdList is empty, error"<<endl;
		return false;
	}
	SetServerIdList(serverIdList);
	SetSelfZoneId(zoneId);

	if(cfg.port > 0)
	{
		FILE *fp = fopen("port","w+");
		if(fp != NULL)
		{
			char buf[32];
			snprintf(buf,sizeof(buf),"%d",cfg.port);
			fwrite(buf,strlen(buf),1,fp);
			fclose(fp);
		}
	}
	return true;
}




bool CMainClass::LoadChongZhiDang()
{
	time_t cur = GetSysTime();
	
	if( last_loadFanlicfg_time == 0 || cur >= last_loadFanlicfg_time + 30*60)
		last_loadFanlicfg_time = GetSysTime();
	else
		return false;

	char sql[512];
	char **row = NULL;	
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return false;
	//                                   0      1        2         3        4          5             6         7        8     9
	snprintf(sql,sizeof(sql),"select chongzhi,fanli,first_fanli,item_id,item_num,first_item_id,first_item_num,type, show_idx,pic_idx from chong_fanli order by type asc,chongzhi asc");
	if(!pDb->Query(sql))
	{
		cout<<"CMainClass:LoadChongZhiDang error"<<endl;
		return false;
	}

	{
		boost::recursive_mutex::scoped_lock lk(cz_fanli_mutex);
		G_CZ_INFO_A.clear();
		G_CZ_INFO_IOS.clear();
		G_CZ_INFO_RMBSHOP.clear();
		G_CZ_MYCARD.clear();
		G_CZ_INFO_WEIXIN.clear();
		while((row = pDb->GetRow()) != NULL)
		{
			SChongZhiData data;
			data.dang = atoi(row[0]);
			data.fanLi = atoi(row[1]);
			data.firstFanLi = atoi(row[2]);
			data.itemId = atoi(row[3]);
			data.itemNum = atoi(row[4]);
			data.firstItemId = atoi(row[5]);
			data.firstItemNum = atoi(row[6]);
			data.type = atoi(row[7]);
			data.show_idx = atoi(row[8]);
			data.pic_idx = atoi(row[9]);
			switch (data.type)
			{
			case 6: // 月卡
			case 7: // 永久月卡
				G_CZ_INFO_IOS.push_back(data);
				G_CZ_INFO_A.push_back(data);
				break;

			case 1: // 1 andriod 
				G_CZ_INFO_A.push_back(data);
				break;

			case 2:	// IOS
				G_CZ_INFO_IOS.push_back(data);
				break;

			case 3: //RMB_SHOP
				G_CZ_INFO_RMBSHOP.push_back(data);
				break;
				
			case 4: // 台湾mycard
				G_CZ_MYCARD.push_back(data);
				break;

			case 5: // 微信充值
				G_CZ_INFO_WEIXIN.push_back(data);
				break;

			default:
				break;
			}
		}
	}

	//                                  0        1           2         3          4          5         6          7           8       9       10      11      12      13      14      15      16   17
	snprintf(sql,sizeof(sql)-1,"select RMB,self_award1,self_num1,self_award2,self_num2,self_award3,self_num3,self_award4,self_num4,f_award1,f_num1,f_award2,f_num2,f_award3,f_num3,f_award4,f_num4,id from cz_to_other_reward order by RMB asc");
	if(!pDb->Query(sql))
	{
		cout<<"CMainClass:LoadChongZhiDang error  sql"<<sql<<endl;
		return false;
	}

	{
		boost::recursive_mutex::scoped_lock lk(cz_fanli_mutex);
		G_CZ_TO_OTHER_INFO.clear();
		while((row = pDb->GetRow()) != NULL)
		{
			SChongZhi2OtherAward data;
			data.RMB = atoi(row[0]);
			for(int i=0;i < SChongZhi2OtherAward::AWARD_NUM;i++)
			{
				data.self_award[i] = atoi(row[2*i+1]);
				data.self_num[i] = atoi(row[2*i+2]);
				data.friend_award[i] = atoi(row[2*i+9]);
				data.friend_num[i] = atoi(row[2*i+10]);
			}
			G_CZ_TO_OTHER_INFO.push_back(data);
		}
	}
	return true;
}

bool CMainClass::Init(const SServerBasicCfg &cfg)
{
	bool localTest = (gyu::util::CIniFile::GetValue("local_test","server",gConfigFile) == "1");
	cout << "[local] CMainClass::Init: net message setup" << endl;
	CNetMessage::SetNetMsgEncodeType(MET_Unicode);
	CNetMessage::SetMsgMaxLenSize(MMS_4Byte);
	
	cout << "[local] CMainClass::Init: GetScript" << endl;
	if(GetScript() == NULL)
		return false;
	cout << "[local] CMainClass::Init: LoadSysDoubleExpCfg" << endl;
	LoadSysDoubleExpCfg();
	for(uint8 i=0;i < GONGGAO_GROUP_NUM;i++)
		m_sysInfo[i].clear();

	string num = gyu::util::CIniFile::GetValue("threadnum","server",gConfigFile);
	cout << "[local] CMainClass::Init: CSimpleRoleDataMgr" << endl;
	if(!SingletonCSimpleRoleDataMgr::instance().Init())
		return false;
	cout << "[local] CMainClass::Init: SceneManager" << endl;
	if(!SingletonSceneManager::instance().Init())
		return false;
	cout << "[local] CMainClass::Init: LoadShopItems" << endl;
	if(!SingletonShopManager::instance().LoadShopItems() && !localTest)
		return false;
	cout << "[local] CMainClass::Init: ReloadShenjiangShopItems" << endl;
	if (!SingletonShopManager::instance().ReloadShenjiangShopItems() && !localTest)
		return false;
	cout << "[local] CMainClass::Init: RiChangFuBen" << endl;
	if(!SingletonCRiChangFuBenManager::instance().Load() && !localTest)
		return false;
	cout << "[local] CMainClass::Init: HDExchange" << endl;
	if(!SingletonCHDExchangeManager::instance().Init() && !localTest)
		return false;
	cout << "[local] CMainClass::Init: AwardManager" << endl;
	if(!SingletonAwardManager::instance().InitAwardManager() && !localTest)
		return false;
	cout << "[local] CMainClass::Init: RankMgr" << endl;
	if(!SingletonCRankMgr::instance().Init() && !localTest)
		return false;
//	if(!SingletonCRankDataMgr::instance().Init())
//		return false;
	cout << "[local] CMainClass::Init: DropMatching" << endl;
	if(!sCDropMatchingMgr.Init() && !localTest)
		return false;

	cout << "[local] CMainClass::Init: LoadChongZhiDang" << endl;
	if(!LoadChongZhiDang() && !localTest)
		return false;

	cout << "[local] CMainClass::Init: Socket Init port=" << cfg.port << endl;
	const char *listenIp = localTest ? "127.0.0.1" : NULL;
	if(!m_socketServer.Init(MAX_CON_USER, true, IntToStr(cfg.port).c_str(), listenIp))
		return false;
	ServerCfg tmp;
	if(cfg.long_port > 0)
	{
		tmp.ip = cfg.longHost;
		tmp.port = cfg.long_port;
		tmp.type = EST_LONG;
		if(!m_socketServer.AddServerInfo(tmp))
			return false;
	}
	if(cfg.match_port > 0)
	{
		tmp.ip = cfg.matchHost;
		tmp.port = cfg.match_port;
		tmp.type = EST_MATCH;
		if(!m_socketServer.AddServerInfo(tmp))
			return false;
	}
	
#ifdef KUA_FU
	{
		vector<int> zoneIdList;
		map<int,SKuaFuServerData> kfdata;
		GetGameZoneIdList(zoneIdList);
		GetGameServerData(kfdata);
		for(uint16 i=0; i < zoneIdList.size(); i++)
		{
			map<int,SKuaFuServerData>::iterator it = kfdata.find(zoneIdList[i]);
			if(it == kfdata.end())
				continue;
			tmp.ip = it->second.ip;
			tmp.port = it->second.port;
			tmp.type = EST_ZoneSerStart + it->first;
			m_socketServer.AddServerInfo(tmp);
		}
	}
	if(!SingletonCQunXianZhengBaManager::instance().ReadData())
		return false;
#else
//	LoadHuoDongGlobalData();
	cout << "[local] CMainClass::Init: HuoDongAward" << endl;
	if(!SingletonCHuoDongAwardManager::instance().Init() && !localTest)
		return false;
	cout << "[local] CMainClass::Init: HuoDongAward TimeOut" << endl;
	SingletonCHuoDongAwardManager::instance().TimeOut();
#endif
	packDeal.SetVerInfo(cfg.version);
	
	m_threadNum = atoi(num.c_str());
	cout << "[local] CMainClass::Init: threadnum=" << m_threadNum << endl;
	if(m_thread == NULL)
		m_thread = new boost::thread*[m_threadNum+3];
	for(int i = 0; i < atoi(num.c_str()); i++)
	{
		cout << "[local] CMainClass::Init: start DealPackThread " << i << endl;
		boost::thread *pTh = new boost::thread(boost::bind(&CMainClass::DealPackThread,this));
		//pTh->detach();
		m_thread[i] = pTh;
	}

	cout << "[local] CMainClass::Init: start TimeOut thread" << endl;
	m_thread[m_threadNum] = new boost::thread(boost::bind(&CMainClass::TimeOut,this));
	cout << "[local] CMainClass::Init: start SaveUserData thread" << endl;
	m_thread[m_threadNum+1] = new boost::thread(&SaveUserData);
	cout << "[local] CMainClass::Init: start IdleThread" << endl;
	m_thread[m_threadNum+2] = new boost::thread(boost::bind(&CMainClass::IdleThread,this));

	cout << "[local] CMainClass::Init: mdcheck" << endl;
	memset(mdCheckIndexArr,0,MAX_CON_USER*sizeof(int));
	mdCheckHost = gyu::util::CIniFile::GetValue("host","mdcheck",gConfigFile);
	string mdCheckPortStr = gyu::util::CIniFile::GetValue("port","mdcheck",gConfigFile);
	mdCheckPort = atoi(mdCheckPortStr.c_str());
	mdCheckSock = Connect(mdCheckHost.c_str(),mdCheckPort);

	{
		cout << "[local] CMainClass::Init: bootstrap user_info tables" << endl;
		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		if(pDb == NULL)
			return true;
		vector<int> sidList;
		GetServerIdList(sidList);
		char sql[1024];
		for(uint16 i=0;i < sidList.size();i++)
		{
			snprintf(sql,sizeof(sql),"CREATE TABLE IF NOT EXISTS `user_info%d` ("
				"`id` int(11) NOT NULL AUTO_INCREMENT,"\
				"`role0` int(11) NOT NULL DEFAULT '0',"\
				"`del_time0` int(11) NOT NULL DEFAULT '0',"\
				"`money` int(11) NOT NULL DEFAULT '0',"\
				"`bd_money` int(11) NOT NULL DEFAULT '0',"\
				"`type` smallint(6) NOT NULL,"\
				"`reg_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,"\
				"`mobile_type` smallint(6) NOT NULL,"\
				"`ad` smallint(6) NOT NULL,"\
				"`new_user` smallint(6) NOT NULL,"\
				"`mobile_info` varchar(64) NOT NULL,"
				"UNIQUE KEY `id` (`id`),KEY `reg_time` (`reg_time`)) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=1",
				sidList[i]);
			pDb->Query(sql);
		}
		if(localTest)
		{
			pDb->Query("CREATE TABLE IF NOT EXISTS `notice_login` (`id` int NOT NULL AUTO_INCREMENT, PRIMARY KEY (`id`)) ENGINE=MyISAM DEFAULT CHARSET=utf8");
			struct SLocalColumn
			{
				const char *name;
				const char *define;
			};
			const SLocalColumn noticeColumns[] = {
				{"title", "`title` varchar(255) NOT NULL DEFAULT ''"},
				{"msg", "`msg` text NULL"},
				{"showType", "`showType` int NOT NULL DEFAULT 0"},
				{"jumpType", "`jumpType` int NOT NULL DEFAULT 0"},
				{"beginTime", "`beginTime` int NOT NULL DEFAULT 0"},
				{"endTime", "`endTime` int NOT NULL DEFAULT 0"},
			};
			for(size_t i = 0; i < sizeof(noticeColumns) / sizeof(noticeColumns[0]); ++i)
			{
				snprintf(sql, sizeof(sql), "SHOW COLUMNS FROM `notice_login` LIKE '%s'", noticeColumns[i].name);
				if(pDb->Query(sql) && pDb->GetRow() == NULL)
				{
					snprintf(sql, sizeof(sql), "ALTER TABLE `notice_login` ADD COLUMN %s", noticeColumns[i].define);
					pDb->Query(sql);
				}
			}

			pDb->Query("CREATE TABLE IF NOT EXISTS `xin_shi` (`id` int NOT NULL AUTO_INCREMENT, PRIMARY KEY (`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8");
			const SLocalColumn mailColumns[] = {
				{"money", "`money` int NOT NULL DEFAULT 0"},
				{"YB", "`YB` int NOT NULL DEFAULT 0"},
				{"bdYB", "`bdYB` int NOT NULL DEFAULT 0"},
				{"attachment", "`attachment` text NULL"},
				{"from_id", "`from_id` int NOT NULL DEFAULT 0"},
				{"to_id", "`to_id` int NOT NULL DEFAULT 0"},
				{"gmtime", "`gmtime` int NOT NULL DEFAULT 0"},
				{"time", "`time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP"},
				{"shenhun", "`shenhun` int NOT NULL DEFAULT 0"},
				{"deleted", "`deleted` tinyint NOT NULL DEFAULT 0"},
				{"from_name", "`from_name` varchar(64) NOT NULL DEFAULT ''"},
				{"message", "`message` text NULL"},
			};
			for(size_t i = 0; i < sizeof(mailColumns) / sizeof(mailColumns[0]); ++i)
			{
				snprintf(sql, sizeof(sql), "SHOW COLUMNS FROM `xin_shi` LIKE '%s'", mailColumns[i].name);
				if(pDb->Query(sql) && pDb->GetRow() == NULL)
				{
					snprintf(sql, sizeof(sql), "ALTER TABLE `xin_shi` ADD COLUMN %s", mailColumns[i].define);
					pDb->Query(sql);
				}
			}

			pDb->Query("CREATE TABLE IF NOT EXISTS `fight_playback` (`id` int NOT NULL AUTO_INCREMENT, PRIMARY KEY (`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8");
			const SLocalColumn fightPlaybackColumns[] = {
				{"type", "`type` int NOT NULL DEFAULT 0"},
				{"role_id", "`role_id` int NOT NULL DEFAULT 0"},
				{"tar_role_id", "`tar_role_id` int NOT NULL DEFAULT 0"},
				{"fightMsg", "`fightMsg` mediumtext NOT NULL"},
				{"notice", "`notice` varchar(256) NOT NULL DEFAULT ''"},
				{"time", "`time` int NOT NULL DEFAULT 0"},
			};
			for(size_t i = 0; i < sizeof(fightPlaybackColumns) / sizeof(fightPlaybackColumns[0]); ++i)
			{
				snprintf(sql, sizeof(sql), "SHOW COLUMNS FROM `fight_playback` LIKE '%s'", fightPlaybackColumns[i].name);
				if(pDb->Query(sql) && pDb->GetRow() == NULL)
				{
					snprintf(sql, sizeof(sql), "ALTER TABLE `fight_playback` ADD COLUMN %s", fightPlaybackColumns[i].define);
					pDb->Query(sql);
				}
			}

			// The production activity tables are not part of the minimal local dump.
			// Seed only the missing first-charge rows so the shipped UI receives a
			// structurally valid five-item reward list.
			pDb->Query("insert into hd_peizhi_info (type,yb,count,lv,idx,cdTime,price,count_ext8,lastTime_ext32,zhenying1_name,zhenying2_name,water_cz,bug_cz,step1_cz,step2_cz) select 29,60,1,0,1,0,6,0,0,'','',0,0,0,0 from dual where not exists (select 1 from hd_peizhi_info where type=29)");
			pDb->Query("insert into huodong_award (type,idx,YB,award1,num1,petQt1,petQtLv1,award2,num2,petQt2,petQtLv2,award3,num3,petQt3,petQtLv3,award4,num4,petQt4,petQtLv4,award5,num5,petQt5,petQtLv5,award6,num6,petQt6,petQtLv6,idx2,idx3) select 29,1,0,60002,19,5,1,1001,10,0,0,837,10,0,0,60000,100000,0,0,60001,500,0,0,0,0,0,0,0,0 from dual where not exists (select 1 from huodong_award where type=29 and idx=1)");
		}

		if(pDb->Query("select count(id) from role_info"))
		{
			char **row = NULL;
			if((row = pDb->GetRow()) != NULL)
			{
				if(atoi(row[0]) == 0)
				{
					snprintf(sql,sizeof(sql),"insert into role_info (id) values(%d)",sidList[0]*1000000);
					pDb->Query(sql);					
				}
			}
		}		
	}
	cout << "[local] CMainClass::Init: done" << endl;
	return true;
}

void CMainClass::Join()
{
	for(uint8 i = 0; i < m_threadNum+3; i++)
	{
		m_thread[i]->join();
	}
	delete []m_thread;
	m_thread = NULL;
}

void CMainClass::DealPackThread()
{
	int sock;
	while (sExit)
	{
		CNetMessage *pMsg = m_socketServer.GetPackage(sock);
		if(pMsg != NULL)
		{
			unsigned short msgType = pMsg->GetType();
			if(gyu::util::CIniFile::GetValue("local_test","server",gConfigFile) == "1")
				cout << "[local] DealPackThread: sock=" << sock << " type=" << msgType << endl;
			m_despatch.Despatch(pMsg,sock);
			delete pMsg;
		}
	}
}

void CMainClass::InitMonster(SVisibleMonster &monster,uint8 x,uint8 y)
{
	monster.x = x;
	monster.y = y;
	if(Random(0,100) > 50)
		monster.face = 6;
	else
		monster.face = 4;
	monster.type = 2;
	monster.pic = 51;
	monster.flag = 0;//0正常,1战斗中
}

int GetOnlineUserNum();

void CMainClass::XinShiClear()
{
	static bool clearflag = true;
	if(GetHour() == 1)
	{
		if(clearflag)
		{
			CGetDbConnect getDb;
			CDatabaseSql *pDb = getDb.GetDbConnect();
			if(pDb == NULL)
				return;
			char sql[256];
			// 玩家发给系统的信件和GM回复的信件保留，其余信件3天之后删除
			snprintf(sql,sizeof(sql),"delete from xin_shi where UNIX_TIMESTAMP(time)<%u and (not (to_id=0 or (from_id=0 and gmtime>0)))",(uint32)(GetSysTime() - 30*24*3600));
			pDb->Query(sql);
			clearflag = false;
		}
	}
	else
	{
		if(!clearflag)
			clearflag = true;
	}
}

void CMainClass::KaiFuChongJiSaiTimer()
{
	static bool isEnd = false;

	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 huodong_type = CHuoDongAwardManager::KAI_FU_CHONGJISAI;
	bool isShow = awardManager.CheckHuoDongShow(huodong_type);
	if (!isShow)
		return;
	
	uint32 leijiTime = awardManager.GetHuoDongLeijiTime(huodong_type);
	uint32 startTime = awardManager.GetHuoDongStartTime(huodong_type);

	uint32 curTime = GetSysTime();
	if(curTime < leijiTime)	// 未到活动结束时间
		return;
	if(curTime > leijiTime + 1200)	// 发放奖励1小时之后
	{
		isEnd = false;
		return;
	}

	if(isEnd)
		return;
	uint32 time = GetGlobalVaribleTime(EGV_KFCJS);  // 已经发过奖励
	if (time == startTime)
		return;

    vector<SLRankData> vecRankData;
    //改为内存数据
//	SingletonCRankDataMgr::instance().GetRankData(ECRT_Level,10,vecRankData,true);
	isEnd = true;
	
	char mailMsg[512];
	stringstream strall;
	int rank = 1;
	int addBdYuanBao = 0;
	uint32 roleId = 0;
	for(int i = 0;i<(int)vecRankData.size();i++)
	{
		rank = i+1;
		roleId = vecRankData[i].role_id;
		strall<<roleId<<"|"<<vecRankData[i].data<<"|"<<vecRankData[i].role_name<<"|";
		addBdYuanBao = KaiFuChongJiSaiGetReward(rank);
		
		::AddTongBao(roleId,addBdYuanBao);
		snprintf(mailMsg,sizeof(mailMsg),LANGUAGE_TRANSFORM_1840,rank,addBdYuanBao);
		SendSystemMail(roleId,mailMsg);

		snprintf(mailMsg,sizeof(mailMsg),LANGUAGE_TRANSFORM_1841,rank,addBdYuanBao);
		SaveDate(roleId,CHuoDongAwardManager::KAI_FU_CHONGJISAI,addBdYuanBao,mailMsg);
	}
	string str1 = strall.str();
	string str2 = str1.substr(0,str1.length()-1);
	GetGlobalVaribleData(EGV_KFCJS);
	SetGlobalVaribleData(EGV_KFCJS,str2.c_str());
}

void CMainClass::XinFuZhanLiBangTimer()
{
	static bool isEnd = false;

	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 huodong_type = CHuoDongAwardManager::XIN_FU_ZHANLIBANG;
	bool isShow = awardManager.CheckHuoDongShow(huodong_type);
	if (!isShow)
		return;
	
	uint32 leijiTime = awardManager.GetHuoDongLeijiTime(huodong_type);
	uint32 startTime = awardManager.GetHuoDongStartTime(huodong_type);
	uint32 curTime = GetSysTime();
	if(curTime < leijiTime)	// 未到活动结束时间
		return;
	if(curTime > leijiTime + 1200)	// 结束1小时之后
	{
		isEnd = false;
		return;
	}

	if(isEnd)
		return;
	uint32 time = GetGlobalVaribleTime(EGV_XFZLB);  // 已经发过奖励
	if (time == startTime)
		return;

    vector<SLRankData> vecRankData;
    //改为读取内存数据
//	SingletonCRankDataMgr::instance().GetRankData(ECRT_Power,10,vecRankData,true);
	isEnd = true;

	char mailMsg[512];
	stringstream strall;
	int rank = 1;
	int addBdYuanBao = 0;
	uint32 roleId = 0;
	uint32 power = 0;
	for(int i = 0;i<(int)vecRankData.size();i++)
	{
		rank = i+1;
		power = (uint32)(1.5f*vecRankData[i].data);
		roleId = vecRankData[i].role_id;
		strall<<roleId<<"|"<<power<<"|"<<vecRankData[i].role_name<<"|";
		addBdYuanBao = XinFuZhanLiBangGetReward(rank);	
		::AddTongBao(roleId,addBdYuanBao,1);
		snprintf(mailMsg,sizeof(mailMsg),LANGUAGE_TRANSFORM_1842,rank,addBdYuanBao);
		SendSystemMail(roleId,mailMsg);

		snprintf(mailMsg,sizeof(mailMsg),LANGUAGE_TRANSFORM_1843,rank,addBdYuanBao);
		SaveDate(roleId,CHuoDongAwardManager::XIN_FU_ZHANLIBANG,addBdYuanBao,mailMsg);
	}
	string str1 = strall.str();
	string str2 = str1.substr(0,str1.length()-1);
	GetGlobalVaribleData(EGV_XFZLB);
	SetGlobalVaribleData(EGV_XFZLB,str2.c_str());
}

void CMainClass::ZuiQiangShenChongBangTimer()
{
	static bool isEnd = false;

	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 huodong_type = CHuoDongAwardManager::SHEN_CHONG_BANG;
	bool isShow = awardManager.CheckHuoDongShow(huodong_type);
	if (!isShow)
		return;
	
	uint32 leijiTime = awardManager.GetHuoDongLeijiTime(huodong_type);
	uint32 startTime = awardManager.GetHuoDongStartTime(huodong_type);
	uint32 curTime = GetSysTime();
	vector<uint32> idxList;
	
	if(curTime < leijiTime)	// 未到活动结束时间
		return;
	if(curTime > leijiTime + 1200)	// 结束1小时之后
	{
		isEnd = false;
		return;
	}

	if(isEnd)
		return;

	uint32 time = GetGlobalVaribleTime(EGV_ZQSCB);  // 已经发过奖励
	if (time == startTime)
		return;

	idxList.clear();
	awardManager.GetAwardIdxList(huodong_type,idxList);
	if(idxList.empty())
		return;

    vector<SLRankData> vecRankData;
//	SingletonCRankDataMgr::instance().GetRankData(ECRT_MaxPet,(int)idxList.size(),vecRankData,true);
	
	isEnd = true;

	char mailMsg[512];
	stringstream strall;
	int rank = 1;
	string petName = "";
	uint32 roleId = 0;
	for(int k=0;k<(int)vecRankData.size();k++)
	{
		rank = k+1;
		SHuoDongAward award;
		awardManager.GetAwardData(huodong_type,rank,award);
		roleId = vecRankData[k].role_id;
		
		strall<<roleId<<"|"<<vecRankData[k].level<<"|"<<vecRankData[k].role_name<<"|"<<vecRankData[k].pet_name<<"|"<<vecRankData[k].data<<"|";

		for(uint8 i=0;i < SHuoDongAward::AWARD_NUM;i++)
		{
			strall<<award.award[i]<<"|"<<award.num[i]<<"|"<<award.petQuality[i]<<"|"<<award.petQualityLv[i]<<"|";
		}

		snprintf(mailMsg,sizeof(mailMsg),LANGUAGE_TRANSFORM_1844,awardManager.GetHuoDongName(huodong_type).c_str(), rank);
		SendHuoDongAwardMail(roleId, vecRankData[k].level, award, mailMsg,huodong_type);
	}
	string str1 = strall.str();
	string str2 = str1.substr(0,str1.length()-1);
	SetGlobalVaribleDataAndTime(EGV_ZQSCB,str2.c_str(),startTime);
}

void CMainClass::XianJiaQiangHuaBangTimer()
{
	static bool isEnd = false;

	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 huodong_type = CHuoDongAwardManager::EQUIP_QIANGHUA_BANG;
	bool isShow = awardManager.CheckHuoDongShow(huodong_type);
	if (!isShow)
		return;
	
	uint32 leijiTime = awardManager.GetHuoDongLeijiTime(huodong_type);
	uint32 startTime = awardManager.GetHuoDongStartTime(huodong_type);
	uint32 curTime = GetSysTime();
	vector<uint32> idxList;
	
	if(curTime < leijiTime)	// 未到活动结束时间
		return;
	if(curTime > leijiTime + 1200)	// 结束1小时之后
	{
		isEnd = false;
		return;
	}
	if(isEnd)
		return;
	
	uint32 time = GetGlobalVaribleTime(EGV_XJQHB);  // 已经发过奖励
	if (time == startTime)
		return;

	idxList.clear();
	awardManager.GetAwardIdxList(huodong_type,idxList);
	if(idxList.empty())
		return;
	vector<SLRankData> vecRankData;
	//改为内存数据
//	SingletonCRankDataMgr::instance().GetRankData(ECRT_EquipQHLv,(int)idxList.size(),vecRankData,true);
	isEnd = true;

	char mailMsg[512];
	stringstream strall;
	int rank = 1;
	uint32 roleId = 0;
	for(int k=0;k<(int)vecRankData.size();k++)
	{
		rank = k+1;

		roleId = vecRankData[k].role_id;
		SHuoDongAward award;
		awardManager.GetAwardData(huodong_type,rank,award);
		
		strall<<roleId<<"|"<<vecRankData[k].level<<"|"<<vecRankData[k].role_name<<"|"<<vecRankData[k].data<<"|";

		for(uint8 i=0;i < SHuoDongAward::AWARD_NUM;i++)
		{
			strall << award.award[i] << "|" << award.num[i] << "|" << award.petQuality[i] << "|" << award.petQualityLv[i] << "|";
		}

		snprintf(mailMsg,sizeof(mailMsg),LANGUAGE_TRANSFORM_1845,awardManager.GetHuoDongName(huodong_type).c_str(), rank);
		SendHuoDongAwardMail(roleId,vecRankData[k].level, award, mailMsg,huodong_type);
	}
	string str1 = strall.str();
	string str2 = str1.substr(0,str1.length()-1);
	SetGlobalVaribleDataAndTime(EGV_XJQHB,str2.c_str(),startTime);
}

void CMainClass::DengJiChongCiBangTimer()
{
	static bool isEnd = false;

	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 huodong_type = CHuoDongAwardManager::ROLE_LEVEL_BANG;
	bool isShow = awardManager.CheckHuoDongShow(huodong_type);
	if (!isShow)
		return;
	
	uint32 leijiTime = awardManager.GetHuoDongLeijiTime(huodong_type);
	uint32 startTime = awardManager.GetHuoDongStartTime(huodong_type);
	uint32 curTime = GetSysTime();
	vector<uint32> idxList; 
	
	if(curTime < leijiTime)	// 未到活动结算时间
		return;
	if(curTime > leijiTime + 1200)	// 结束1小时之后
	{
		isEnd = false;
		return;
	}
	if(isEnd)
		return;

	uint32 time = GetGlobalVaribleTime(EGV_DJCCB);  // 已经发过奖励
	if (time == startTime)
		return;

	idxList.clear();
	awardManager.GetAwardIdxList(huodong_type,idxList);
	if(idxList.empty())
		return;

    vector<SLRankData> vecRankData;
    //改为内存数据
//	SingletonCRankDataMgr::instance().GetRankData(ECRT_Level,(int)idxList.size(),vecRankData,true);
	isEnd = true;

	char mailMsg[512];
	stringstream strall;
	int rank = 1;
	for(int k = 0;k<(int)vecRankData.size();k++)
	{
		rank = k+1;
		uint32 roleId = vecRankData[k].role_id;
		SHuoDongAward award;
		awardManager.GetAwardData(huodong_type,rank,award);
		
		strall<<roleId<<"|"<< vecRankData[k].data <<"|"<<vecRankData[k].role_name<<"|"<<vecRankData[k].data<<"|";
		//cout<<"EGV_DJCCB "<<strall.str();

		for(uint8 i=0;i < SHuoDongAward::AWARD_NUM;i++)
		{
			strall<<award.award[i]<<"|"<<award.num[i]<<"|"<<award.petQuality[i]<<"|"<<award.petQualityLv[i]<<"|";
		}

		snprintf(mailMsg,sizeof(mailMsg),LANGUAGE_TRANSFORM_1846,awardManager.GetHuoDongName(huodong_type).c_str(),rank);
		SendHuoDongAwardMail(roleId, (int)vecRankData[k].data, award, mailMsg,huodong_type);
	}
	string str1 = strall.str();
	string str2 = str1.substr(0,str1.length()-1);
	SetGlobalVaribleDataAndTime(EGV_DJCCB,str2.c_str(),startTime);
}

void CMainClass::QunXianZhanLiBangTimer()
{
	static bool isEnd = false;

	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 huodong_type = CHuoDongAwardManager::ZHAN_LI_BANG;
	bool isShow = awardManager.CheckHuoDongShow(huodong_type);
	if (!isShow)
		return;
	
	uint32 leijiTime = awardManager.GetHuoDongLeijiTime(huodong_type);
	uint32 startTime = awardManager.GetHuoDongStartTime(huodong_type);
	uint32 curTime = GetSysTime();
	vector<uint32> idxList; 
	
	if(curTime < leijiTime)	// 未到活动结束时间
		return;
	if(curTime > leijiTime + 1200)	// 结束1小时之后
	{
		isEnd = false;
		return;
	}
	if(isEnd)
		return;

	uint32 time = GetGlobalVaribleTime(EGV_QXZLB);  // 已经发过奖励
	if (time == startTime)
		return;

	idxList.clear();
	awardManager.GetAwardIdxList(huodong_type,idxList);
	if(idxList.empty())
		return;
	vector<SLRankData> vecRankData;
    //改为读取内存数据
//	SingletonCRankDataMgr::instance().GetRankData(ECRT_Power,(int)idxList.size(),vecRankData,true);
	isEnd = true;

	char mailMsg[512];
	stringstream strall;
	int rank = 1;
	uint32 roleId = 0;
	for(int k=0;k<(int)vecRankData.size();k++)
	{
		rank = k+1;
		roleId = vecRankData[k].role_id;
		SHuoDongAward award;
		awardManager.GetAwardData(huodong_type,rank,award);
		
		strall<<roleId<<"|"<<vecRankData[k].level<<"|"<<vecRankData[k].role_name<<"|"<<vecRankData[k].data<<"|";

		for(uint8 i=0;i < SHuoDongAward::AWARD_NUM;i++)
		{
			strall<<award.award[i]<<"|"<<award.num[i]<<"|"<<award.petQuality[i]<<"|"<<award.petQualityLv[i]<<"|";
		}

		snprintf(mailMsg,sizeof(mailMsg),LANGUAGE_TRANSFORM_1847,awardManager.GetHuoDongName(huodong_type).c_str(),rank);
		SendHuoDongAwardMail(roleId, vecRankData[k].level, award, mailMsg,huodong_type);
	}
	string str1 = strall.str();
	string str2 = str1.substr(0,str1.length()-1);
	SetGlobalVaribleDataAndTime(EGV_QXZLB,str2.c_str(),startTime);
}

void CMainClass::XinFuChongZhiBangTimer()
{
	static bool isEnd = false;

	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 huodong_type = CHuoDongAwardManager::CHONG_ZHI_BANG;
	bool isShow = awardManager.CheckHuoDongShow(huodong_type);
	if (!isShow)
		return;
	
	uint32 leijiTime = awardManager.GetHuoDongLeijiTime(huodong_type);
	uint32 startTime = awardManager.GetHuoDongStartTime(huodong_type);
	uint32 curTime = GetSysTime();
	vector<uint32> idxList; 
	
	if(curTime < leijiTime)	// 未到活动结束时间
		return;
	if(curTime > leijiTime + 1200)	// 结束1小时之后
	{
		isEnd = false;
		return;
	}
	if(isEnd)
		return;

	uint32 time = GetGlobalVaribleTime(EGV_XFCZB);  // 已经发过奖励
	if (time == startTime)
		return;

	idxList.clear();
	awardManager.GetAwardIdxList(huodong_type,idxList);
	if(idxList.empty())
		return;
//    int bang_num = (int)idxList.size();

    vector<SLRankData> vecRankData;
	//改为内存数据
//	SingletonCRankDataMgr::instance().GetRankData(ECRT_Chong,bang_num,vecRankData,true);
	isEnd = true;

	char mailMsg[512];
	stringstream strall;
	int rank = 1;
	uint32 roleId = 0;
	for(int k=0;k<(int)vecRankData.size();k++)
	{
        rank = k+1;
        roleId = vecRankData[k].role_id;
		SHuoDongAward award;
		awardManager.GetAwardData(huodong_type,rank,award);
		
		strall<<roleId<<"|"<<vecRankData[k].level<<"|"<<vecRankData[k].role_name<<"|"<<vecRankData[k].data<<"|";

		for(uint8 i=0;i < SHuoDongAward::AWARD_NUM;i++)
		{
			strall<<award.award[i]<<"|"<<award.num[i]<<"|"<<award.petQuality[i]<<"|"<<award.petQualityLv[i]<<"|";
		}

		snprintf(mailMsg,sizeof(mailMsg),LANGUAGE_TRANSFORM_1848,awardManager.GetHuoDongName(huodong_type).c_str(),rank);
		SendHuoDongAwardMail(roleId, vecRankData[k].level, award, mailMsg,huodong_type);
	}
	string str1 = strall.str();
	string str2 = str1.substr(0,str1.length()-1);
	SetGlobalVaribleDataAndTime(EGV_XFCZB,str2.c_str(),startTime);
}

static bool SendFestivalAward(uint8 festivalType, uint32 startTime)
{
	const char *name[2] = {LANGUAGE_TRANSFORM_1852,LANGUAGE_TRANSFORM_1853};
	uint32 EGV_FESTIVAL_TYPE[2] = {EGV_FESTIVAL_GIVE,EGV_FESTIVAL_GET};
//	const uint32 level_rank[2] = {29, 30};

	uint32 time = GetGlobalVaribleTime(EGV_FESTIVAL_TYPE[festivalType]);	// 已经发过奖励
	if (time == startTime)
		return true;

	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 huodong_type = CHuoDongAwardManager::FESTIVAL;
	int cnt = awardManager.GetFestivalAwardIdxCnt(festivalType);
	if(cnt < 1)
		return false;

    vector<SLRankData> vecRankData;
	//改为内存数据
//	SingletonCRankDataMgr::instance().GetRankData(level_rank[festivalType],MAX_RANK_NUM,vecRankData,true);

	char mailMsg[512];
	stringstream strall;
	//map<uint32, uint32> getAwardRole;
	//getAwardRole.clear();
	int rank = 0;
	uint32 roleId = 0;
	for(int k=0;k<(int)vecRankData.size();k++)
	{
		++rank;
		SHuoDongAward award;
		awardManager.GetFestivalRankAward(festivalType,rank,vecRankData[k].data,award);
		if(award.award[0] == 0)
			continue;
		roleId = vecRankData[k].role_id;
		strall<<roleId<<"|"<<vecRankData[k].level<<"|"<<vecRankData[k].role_name<<"|"<<vecRankData[k].data<<"|"<<vecRankData[k].festival_num1<<"|"<<vecRankData[k].festival_num2<<"|";
		
		if(rank > cnt)
			snprintf(mailMsg,sizeof(mailMsg),LANGUAGE_TRANSFORM_1851,awardManager.GetHuoDongName(huodong_type).c_str(),name[festivalType]);
		else
			snprintf(mailMsg,sizeof(mailMsg),LANGUAGE_TRANSFORM_1855,awardManager.GetHuoDongName(huodong_type).c_str(),name[festivalType],rank);

		SendHuoDongAwardMail(roleId, vecRankData[k].level, award, mailMsg,huodong_type);
	}
	string str1 = strall.str();
	string str2 = str1.substr(0,str1.length()-1);

	SetGlobalVaribleDataAndTime(EGV_FESTIVAL_TYPE[festivalType],str2.c_str(),startTime);

	//SendHDNotInPaiHangInScoreAward(festivalType,getAwardRole,huodong_type);
	return true;
}

void CMainClass::FestivalBangTimer()
{
	static bool isEnd[2] = {false,false};

	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 huodong_type = CHuoDongAwardManager::FESTIVAL;
	
	uint32 leijiTime = awardManager.GetHuoDongLeijiTime(huodong_type);
	uint32 startTime = awardManager.GetHuoDongStartTime(huodong_type);
	uint32 curTime = GetSysTime();

	if(curTime < leijiTime) // 未到活动结算时间
		return;
	if(curTime > leijiTime + 1200)	// 发放奖励1小时之后
	{
		isEnd[0] = false;
		isEnd[1] = false;
		return;
	}

	if(isEnd[0] && isEnd[1])
		return;

	for (int i = 0 ; i < 2; i++)
	{
		if (! isEnd[i])
			isEnd[i] = SendFestivalAward(i,startTime);
	}
}

void CMainClass::WingBangTimer()
{
	static bool isEnd = false;

	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 huodong_type = CHuoDongAwardManager::WING_BANG;
	
	uint32 leijiTime = awardManager.GetHuoDongLeijiTime(huodong_type);
	uint32 startTime = awardManager.GetHuoDongStartTime(huodong_type);
	uint32 curTime = GetSysTime();
	vector<uint32> idxList;
	
	if(curTime < leijiTime)	// 未到活动结算时间,延时半小时
		return;
	 if(curTime > leijiTime + 1200)	// 发放奖励1小时之后
	 {
	 	isEnd = false;
	 	return;
	 }

	 if(isEnd)
	 	return;

	uint32 time = GetGlobalVaribleTime(EGV_WING);  // 已经发过奖励
	if (time == startTime)
		return;

	idxList.clear();
	awardManager.GetAwardIdxList(huodong_type,idxList);
	if(idxList.empty())
		return;

    vector<SLRankData> vecRankData;
	//改为内存数据
//	SingletonCRankDataMgr::instance().GetRankData(ECRT_Wing,(int)idxList.size(),vecRankData,true);
	isEnd = true;

	char mailMsg[512];
	stringstream strall;
	int rank = 1;
	uint32 roleId = 0;
	for(int k=0;k<(int)vecRankData.size();k++)
	{
		rank = k+1;
		roleId = vecRankData[k].role_id;
		SHuoDongAward award;
		awardManager.GetAwardData(huodong_type,rank,award);
		
		strall<<roleId<<"|"<<vecRankData[k].level<<"|"<<vecRankData[k].role_name<<"|"<<vecRankData[k].pet_id<<"|"<<vecRankData[k].data<<"|";

		for(uint8 i=0;i < SHuoDongAward::AWARD_NUM;i++)
		{
			strall<<award.award[i]<<"|"<<award.num[i]<<"|"<<award.petQuality[i]<<"|"<<award.petQualityLv[i]<<"|";
		}

		snprintf(mailMsg,sizeof(mailMsg),LANGUAGE_TRANSFORM_1856,awardManager.GetHuoDongName(huodong_type).c_str(), rank);
		SendHuoDongAwardMail(roleId,vecRankData[k].level, award, mailMsg,huodong_type);
	}
	string str1 = strall.str();
	string str2 = str1.substr(0,str1.length()-1);
	SetGlobalVaribleDataAndTime(EGV_WING,str2.c_str(),startTime);
}

void CMainClass::XunChaShiTimer()
{
	const int StartTime = 1000;	// hour*100+min
	const int ClearTime = 0;	// hour*100+min
	const int SceneId[] = {11, 2, 3, 4};
	const SPointFace MonPoint[][6] = {
		{{1326,520,1},{1244,1006,1},{908,1949,1},{1335,1421,1},{2381,1757,1},{3485,1673,1}},
		{{261,569,1},{777,1223,1},{1671,310,1},{2254,853,1},{1628,975,1},{1710,633,1}},
		{{743,1179,1},{1625,1106,1},{2586,802,1},{2414,1235,1},{1090,696,1},{1427,191,1}},
		{{194,533,1},{1755,491,1},{1181,1045,1},{1604,1445,1},{2020,1085,1},{2202,602,1}},
		};
	static bool gonggao = true;
	static bool flushMonster = true;
	static bool clearMonster = true;
	static int t_date = 0;

	int hour = GetHour();
	int minute = GetMinute();
	int curTime = hour*100 + minute;
	if(t_date == 0)
		t_date = GetDay();
	if(GetDay() != t_date && hour == 1)
	{
		t_date = GetDay();
		gonggao = true;
		clearMonster = true;
		flushMonster = true;
	}

/*
	static bool notify = false;
	static bool start = false;
	if (!notify && CSceneManager::IsNotifyActivityTime(SOT_Liujieshizhe))
	{
		notify = true;
		SendHuoDongFlag(SOT_Liujieshizhe, 3);
	}
	else if (!start && CSceneManager::IsInActivityTime(SOT_Liujieshizhe))
	{
		start = true;
		SendHuoDongFlag(SOT_Liujieshizhe, 1);
	}
	else if (start && CSceneManager::IsAfterActivityTime(SOT_Liujieshizhe))
	{
		start = false;
		notify = false;
		SendHuoDongFlag(SOT_Liujieshizhe, 2);
	}
*/

	// 提前公告
	if(curTime >= StartTime - 40 - 5 && curTime < StartTime && gonggao)
	{
		gonggao = false;
		SysInfoToAllUser(LANGUAGE_TRANSFORM_1887);
	}
	else if(curTime >= StartTime && flushMonster)	// 刷新
	{
		flushMonster = false;
		clearMonster = true;

		CSceneManager &sceneMgr = SingletonSceneManager::instance();
		for(uint32 k=0;k < sizeof(SceneId)/sizeof(SceneId[0]);k++)
		{
			CScene *pScene = sceneMgr.FindScene(SceneId[k]);
			if(pScene == NULL)
				continue;
			vector<SPointFace> point;
			vector<int> fightId;
			vector<int> monterId;
			for(uint32 i=0;i < sizeof(MonPoint[k])/sizeof(MonPoint[k][0]);i++)
			{
				point.push_back(MonPoint[k][i]);
				fightId.push_back(11301+ k*30 + 5*i);
				monterId.push_back(11305+ k*30 + 5*i);
			}
			pScene->AddXunChaShiNPCMonster(GetXunChaShiNpcId(k),point,fightId,monterId);
			SysInfoToAllUser(LANGUAGE_TRANSFORM_1889);
		}
	}
	else if(curTime >= ClearTime && curTime < ClearTime+30 && clearMonster)	// 清理
	{
		clearMonster = false;
		gonggao = true;
		flushMonster = true;

		CSceneManager &sceneMgr = SingletonSceneManager::instance();
		for(uint32 k=0;k < sizeof(SceneId)/sizeof(SceneId[0]);k++)
		{
			CScene *pScene = sceneMgr.FindScene(SceneId[k]);
			if(pScene == NULL)
				continue;
			pScene->ClearXunChaShiNPCMonster();
		}
	}
}

void CMainClass::LingQiJuanXianTimer()
{
	const int ClearTime = 1700;	// 17:00
	const int topBangPaiNum = 10;
	static bool flushMonster = true;
	static bool clearMonster = true;
	static int t_date = 0;
	static bool flag = false;
	static bool notify = false;
	int hour = GetHour();
	int minute = GetMinute();
	int curTime = hour*100 + minute;

	if(t_date == 0)
		t_date = GetDay();
	if(GetDay() != t_date)
	{
		t_date = GetDay();
		clearMonster = true;
		flushMonster = true;
		boost::recursive_mutex::scoped_lock lk(lingQiJuanXian_mutex);
		lingQiValue = 0;
		refreshLingQiValue = 0;
	}

	if (!notify && CSceneManager::IsNotifyActivityTime(SOT_Bangpailingmo))
	{
		notify = true;
		SendHuoDongFlag(SOT_Bangpailingmo, 3);
	}
	if(!flag && CSceneManager::IsInActivityTime(SOT_Bangpailingmo))	// 活动时间内
	{
		flag = true;
		if(minute%5 <= 2 && flushMonster)	// 刷怪
		{
			if(!IsInLingMoActivity())
			{
				SingletonCBangPaiManager::instance().GetBangPaiTopList(topBangPaiNum, topBangPai);
				if (!topBangPai.empty())
					SetLingMoActivity(true);
			}
			if(!IsInLingMoActivity())
				return;
			int refreshValue = 0;
			{
				boost::recursive_mutex::scoped_lock lk(lingQiJuanXian_mutex);
				if(refreshLingQiValue == 0)		// 第一次刷怪，设置刷怪灵气值
				{
					refreshLingQiValue = lingQiValue;

					char buf[256];
					snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0152,topBangPaiNum,GGCT_BLUE);
					SysInfoToAllUser(buf);
					SendHuoDongFlag(SOT_Bangpailingmo,1);
				}
				refreshValue = refreshLingQiValue;
			}
			flushMonster = false;

			CSceneManager &sceneMgr = SingletonSceneManager::instance();
			for(uint8 idx = 0;idx < topBangPai.size();idx++)
			{
				CScene *pScene = sceneMgr.GetBangPaiScene(BANG_PAI_SCENE_ID,topBangPai[idx]);
				if(pScene == NULL)
					continue;
				pScene->AddLingQiJuanXianNPCMonster(refreshValue);
			}
		}
		else if(minute%5 >= 3 && !flushMonster)
		{
			flushMonster = true;
		}
	}
	if(flag && CSceneManager::IsAfterActivityTime(SOT_Bangpailingmo))	// 灵魔图标消失
	{
		flag = false;
		notify = false;
		SetLingMoActivity(false);
		SendHuoDongFlag(SOT_Bangpailingmo,2);
	}
	if(curTime >= ClearTime && clearMonster)	// 清理
	{
		clearMonster = false;
		CSceneManager &sceneMgr = SingletonSceneManager::instance();
		for(uint8 idx = 0;idx < topBangPai.size();idx++)
		{
			CScene *pScene = sceneMgr.GetBangPaiScene(BANG_PAI_SCENE_ID,topBangPai[idx]);
			if(pScene == NULL)
				continue;
			pScene->ClearLingQiJuanXianNPCMonster();
		}
	}
}

void CMainClass::QiangHongBaoTimer()
{
	static bool isStart = false;

	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 hd_type = CHuoDongAwardManager::QIANG_HONGBAO;

	if (awardManager.InHuoDongTime(hd_type) && isStart == false)
	{
		QiangHongBaoZhuDong(CHuoDongAwardManager::QIANGHB_UP);
		isStart = true;
	}
	else if ((!awardManager.InHuoDongTime(hd_type)) && isStart == true)
	{
		QiangHongBaoZhuDong(CHuoDongAwardManager::QIANGHB_DOWN);
		isStart = false;
	}
}

void CMainClass::PetDrawTimer()
{
	static bool flag = false;
	if(GetWeekDay() == 5 && GetHour() == 0 && !flag)
	{
		flag = true;
		NeedUpdatePetDraw();
	}
	else
	{
		flag = false;
	}
}

void CMainClass::HuSongShenShouTimer()
{
	/*static bool sendflag50 = false;
	static bool sendflag55 = false;*/
	static bool startflag = false;
	static bool notify = false;
	char buf[128];
	/*int hour = GetHour();
	int minite = GetMinute();*/

	uint16 notifyTm;
	uint16 startTm;
	uint16 endTm;

	if (!sSystemOpenCfgMananger.OpenWeekDay(SOT_Husong))
		return;
	if (!sSystemOpenCfgMananger.GetFuncLvTime(SOT_Husong, notifyTm, startTm, endTm))
		return;

	if (!notify && CSceneManager::IsNotifyActivityTime(SOT_Husong))
	{
		notify = true;
		SendHuoDongFlag(SOT_Husong, 3);
	}
	/*else if (hour == HU_SONG_SHEN_SHOU_HOUR && minite < 30)
	{
		if (minite >= 20 && minite <= 24 && !sendflag50)
		{
			sendflag50 = true;
			snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_1891, HU_SONG_SHEN_SHOU_HOUR);
			SysInfoToAllUser(buf);
		}
		if (minite >= 25 && minite <= 29 && !sendflag55)
		{
			sendflag55 = true;
			snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_1892, HU_SONG_SHEN_SHOU_HOUR);
			SysInfoToAllUser(buf);
		}
	}*/
	else if (!startflag && CSceneManager::IsInActivityTime(SOT_Husong))
	{
		startflag = true;
		notify = false;
		snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_1893);
		SysInfoToAllUser(buf);
		SendHuoDongFlag(SOT_Husong, 1);
	}
	else if(startflag && CSceneManager::IsAfterActivityTime(SOT_Husong))
	{
		startflag = false;
		SendHuoDongFlag(SOT_Husong, 2);
	}
}

void CMainClass::FeiXianTimer()
{
	static int addExpMinue = -1;
	static int endFlag = false;
	int hour = GetHour();
	int minute = GetMinute();
	static bool notify = false;
	static bool start = false;
	char buf[128];
	//uint16 curTime = hour * 100 + minute;
	uint16 notifyTm;
	uint16 startTm;
	uint16 endTm;

	int type = SOT_FeiXian;
	if (!sSystemOpenCfgMananger.OpenWeekDay(type))
		return;
	if (!sSystemOpenCfgMananger.GetFuncLvTime(type, notifyTm, startTm, endTm))
		return;
	
	if (CSceneManager::IsBeforeActivityTime(SOT_FeiXian))
	{
		snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_1894, startTm / 100, startTm % 100);
		SysInfoToAllUser(buf);
	}
	if (!notify && CSceneManager::IsNotifyActivityTime(SOT_FeiXian))
	{
		SendHuoDongFlag(SOT_FeiXian, 3);
		notify = true;
	}
	else if(CSceneManager::IsInActivityTime(SOT_FeiXian))
	{
		if (!start)
		{
			snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_1895);
			SysInfoToAllUser(buf);
			start = true;
			SendHuoDongFlag(SOT_FeiXian, 1);
		}
		if(addExpMinue != minute)
		{
			addExpMinue = minute;
			SingletonSceneManager::instance().FeiXianSceneAddExp();
		}
	}
	else if(!endFlag && CSceneManager::IsAfterActivityTime(SOT_FeiXian))
	{
		endFlag = true;
		SendHuoDongFlag(SOT_FeiXian,2);
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1896);
		SysInfoToAllUser(buf);

		SingletonSceneManager::instance().SendFeiXianAward();
		SingletonSceneManager::instance().TransportOutOfFeiXian();
	}
	else if(hour == 0)
	{
		addExpMinue = -1;
		endFlag = false;
		notify = false;
		start = false;
	}
}

void CMainClass::KunLunShanTimer()
{
	static bool flag = false;
	static bool endFlag = false;
	static bool notify = false;
	char buf[128];
	int hour = GetHour();
	int minute = GetMinute();
	uint16 notifyTm;
	uint16 startTm;
	uint16 endTm;

	int type = SOT_Kunlunshan;
	if (!sSystemOpenCfgMananger.OpenWeekDay(type))
		return;
	if (!sSystemOpenCfgMananger.GetFuncLvTime(type, notifyTm, startTm, endTm))
		return;
	
	CSceneManager &sceneMgr = SingletonSceneManager::instance();
	if (!notify && CSceneManager::IsNotifyActivityTime(type))
	{
		notify = true;
		SendHuoDongFlag(type, 3);
		snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_1897, startTm / 100, startTm % 100);
		SysInfoToAllUser(buf);
	}
	else if (CSceneManager::IsInActivityTime(SOT_Kunlunshan))
	{
		if(minute%5 == 0 && !flag)
		{
			SendHuoDongFlag(type,1);
			flag = true;
			sceneMgr.GetKunLunShanFirstScene();
			sceneMgr.AddKunLunShanMonster();
			sceneMgr.SendKunLunShanTime();
			if(minute <= 31)
			{
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1898);
				SysInfoToAllUser(buf);
			}
			else
			{
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1899);
				SysInfoToAllUser(buf,true);
			}
		}
		else if(minute%5 == 4 && flag)
		{
			flag = false;
		}
	}
	else if(!endFlag && CSceneManager::IsAfterActivityTime(SOT_Kunlunshan))
	{
		SendHuoDongFlag(type, 2);
		endFlag = true;
		snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_1900);
		SysInfoToAllUser(buf);
		SendPaiHangJiangLi();
		ClearKunLunShanPaiHang();
		sceneMgr.TransportOutOfKunLunShan();
	}
	else if(hour == 0)
	{
		notify = false;
		flag = false;
		endFlag = false;
		ClearKunLunShanPaiHang();
	}
}

void CMainClass::KunLunShanTeamTimer()
{
	static bool flag = false;
	static bool showIcon = true;
	const int FuncLevel_ID = SOT_KuaFuLunDao;
	CSystemOpenCfgMananger &openSys = SingletonCSystemOpenCfgMgr::instance();
	if(!openSys.OpenWeekDay(FuncLevel_ID))
		return;
	
	uint16 readyTime = 0;
	uint16 startTime = 0;
	uint16 endTime = 0;
	if(!openSys.GetFuncLvTime(FuncLevel_ID,readyTime,startTime,endTime))
		return;
	if(readyTime == 0 && startTime == 0 && endTime == 0)
		return;
	
	char buf[256];
	int hour = GetHour();
	int minute = GetMinute();
	int second = GetSysTime()%60;
	uint16 time = hour*100 + minute;

#ifdef KUA_FU
	CSceneManager &sceneMgr = SingletonSceneManager::instance();
#endif
	if(time == readyTime && showIcon)
	{
		showIcon = false;
		SendHuoDongFlag(FuncLevel_ID,3);
		SysInfoToAllUser(LANGUAGE_SSJ_0050);
	}
	else if(time >= startTime && time < endTime)
	{
		if(minute%5 == 0 && !flag)
		{
			flag = true;
#ifdef KUA_FU
			sceneMgr.GetTeamKunLunShanFirstScene();
			sceneMgr.AddKunLunShanTeamMonster();
			sceneMgr.SendKunLunShanTeamTime();
#endif
			if(time <= startTime+1)
			{
				snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0046);
				SysInfoToAllUser(buf);
			}
#ifdef KUA_FU
			else
			{
				snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0047);
				SysInfoToAllUser(buf);
			}
#endif
			SendHuoDongFlag(FuncLevel_ID,1);
		}
		else if(minute%5 == 4 && flag)
		{
			flag = false;
			//			SendKunLunShanTopUser();
		}
	}
	else if(time >= endTime && time < endTime+10)
	{
		if(!flag)
		{
			SendHuoDongFlag(FuncLevel_ID,2);
			flag = true;

			snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0048);
			SysInfoToAllUser(buf);
#ifdef KUA_FU
			SendKunLunShanTeamAward();
			ClearKunLunShanTeamPaiHang();
			sceneMgr.TransportOutOfTeamKunLunShan();
#endif
		}
		else
		{
			if(minute%5 == 0 && second < 15)
				SendHuoDongFlag(FuncLevel_ID,2);
		}
	}
	else if(hour == 4)
	{
#ifdef KUA_FU
		ClearKunLunShanTeamPaiHang();
#endif
		flag = false;
		showIcon = true;
	}
}

void CMainClass::KuaFu1V1Timer()
{
#ifdef KUA_FU
	static bool showMsg[5] = {false,false,false,false,false};
	static bool runEnd = false;
	static bool isInit = false;
	static bool showGongGao1 = false;
	int week = GetWeekDay();
	if(week == 0)	// 周日
	{
		uint32 time = GetSysTime();
		int hour = GetHour();
		int minute = GetMinute();
		int curTime = hour*100 + minute;
		char buf[512];

		if(hour == 0 && minute < 5 && !isInit)
		{
			isInit = true;
			runEnd = false;
			showGongGao1 = false;
			for(uint8 i=0;i < sizeof(showMsg)/sizeof(showMsg[0]);i++)
				showMsg[i] = false;
			LoadKuaFu1V1FinalUserData();
			return;
		}
		
		if(curTime >= KUA_FU_FINALS_START_TIME && curTime < KUA_FU_FINALS_START_TIME+15)	// 第一场
		{
			isInit = false;
			if(!showMsg[0])
			{
				showMsg[0] = true;
				CheckKuaFu1V1Players();
				snprintf(buf,sizeof(buf)-1,LANGUAGE_SSJ_0059,1);
				SysInfoToAllUser(buf);
				SendKuaFu1V1LeftTime();
			}
		}
		else if(curTime >= KUA_FU_FINALS_START_TIME+15 && curTime < KUA_FU_FINALS_START_TIME+70)	// 第二场
		{
			isInit = false;
			if(!showMsg[1])
			{
				showMsg[1] = true;
				PushKuaFu1V1TurnRankData();
				CheckKuaFu1V1Players();
				snprintf(buf,sizeof(buf)-1,LANGUAGE_SSJ_0059,2);
				SysInfoToAllUser(buf);
				SendKuaFu1V1LeftTime();
			}
		}
		else if(curTime >= KUA_FU_FINALS_START_TIME+70 && curTime < KUA_FU_FINALS_START_TIME+85)	// 第三场
		{
			isInit = false;
			if(!showMsg[2])
			{
				showMsg[2] = true;
				PushKuaFu1V1TurnRankData();
				CheckKuaFu1V1Players();
				snprintf(buf,sizeof(buf)-1,LANGUAGE_SSJ_0059,3);
				SysInfoToAllUser(buf);
				SendKuaFu1V1LeftTime();
			}
		}
		else if(curTime >= KUA_FU_FINALS_START_TIME+85 && curTime < KUA_FU_FINALS_START_TIME+100)	// 第四场
		{
			isInit = false;
			if(!showMsg[3])
			{
				showMsg[3] = true;
				PushKuaFu1V1TurnRankData();
				CheckKuaFu1V1Players();
				snprintf(buf,sizeof(buf)-1,LANGUAGE_SSJ_0059,4);
				SysInfoToAllUser(buf);
				SendKuaFu1V1LeftTime();
				// 半决赛
			}
		}
		else if(curTime >= KUA_FU_FINALS_START_TIME+100 && curTime < KUA_FU_FINALS_START_TIME+115)	// 第五场
		{
			isInit = false;
			if(!showMsg[4])
			{
				showMsg[4] = true;
				PushKuaFu1V1TurnRankData();
				CheckKuaFu1V1Players();
				snprintf(buf,sizeof(buf)-1,LANGUAGE_SSJ_0059,5);
				SysInfoToAllUser(buf);
				SendKuaFu1V1LeftTime();
			}

			if(CheckKuaFu1V1_FirstResult())
			{
				if(!showGongGao1)
				{
					showGongGao1 = true;
					runEnd = true;
					SendKuaFu1V1Award();
					return;
				}
			}
		}
		else if(curTime >= KUA_FU_FINALS_END_TIME && !runEnd)	// 结束
		{
			runEnd = true;
			SendKuaFu1V1Award();
			return;
		}

		if(InKuaFu1V1FinalsTime())
		{
			CSceneManager &scene = SingletonSceneManager::instance();
			for(uint16 i=0;i < KUA_FU_1V1_SCENE_NUM;i++)
			{
				CScene *pScene = scene.GetKuaFu1V1SceneByIndex(i+1);
				if(pScene != NULL)
				{
					uint8 index = pScene->GetFBStep();
					uint32 sceneTime = pScene->m_1V1SceneTime;
					if((time - sceneTime >= 2*60-5 && index == 0)	// 开始战斗,第一局
						|| (time - sceneTime >= 60 && (index == 2 || index == 4)))	// 开始战斗，第2、3局
					{
						index++;
						pScene->SetFBStep(index);
						pScene->MatchKuaFu1V1Fight();
					}
					else if(index == 6)	// 传出场景
					{
						index++;
						pScene->SetFBStep(0);
						pScene->m_1V1SceneTime = GetKuaFu1V1TurnStartTime()+15*60;
					}
				}
			}
		}
	}
#endif
}

void CMainClass::TreasureTimer()
{
	for(int sid=1;sid <= 10;sid++)
	{
		CSceneManager &scene = SingletonSceneManager::instance();
		CScene *pScene = scene.FindScene(sid);
		if(pScene != NULL)
			pScene->ClearTreasureMonster();
	}
}

void CMainClass::TongTianTaTimer()
{
	static bool flag = false;
	int hour = GetHour();
	int minute = GetMinute();
	int second = GetSysTime()%60;
	
	if(hour == 0 && minute >= 0 && minute < 5 && second < 10 && !flag)
	{
		flag = true;
		{
			vector<uint32> bazhuList;
			{
				boost::recursive_mutex::scoped_lock lk(tongTianTa_mutex);
				for(unsigned int i = 0;i < tongTianTaBaZhuData.size();i++)
					bazhuList.push_back(tongTianTaBaZhuData[i]);
			}

			char buf[256];
			SItemInstance item;
			SMailData mdata;
			for(unsigned int i = 0;i < bazhuList.size();i++)
			{
				if(bazhuList[i] > 0)
				{
					if(i == 0)	// 20层
						item.extData = 1;
					else if(i == 1)	// 60层
						item.extData = 2;
					else if(i == 2)	// 100层
						item.extData = 3;
					else if(i == 3)	// 150层
						item.extData = 4;
					else if(i == 4)	// 200层
						item.extData = 5;
					else
						break;
					mdata.AddAward(2368, 0, 1);

					snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1901,tongTianTaBaZhuFloor[i]);
					SendSystemMail(bazhuList[i],buf,&mdata);
				}
			}
		}
	}
	if(hour == 0 && minute >= 5 && flag)
		flag = false;
}

void CMainClass::ShopMysteryItemTimer()
{
	uint32 nextUpdateTime = GetNextMysteryUpdateTime();
	uint32 curStamp = GetSysTime();
	if(nextUpdateTime == 0)
	{
		uint32 dayStamp = GetClearDayTime();
		uint32 nextStamp = UpdateMysteryTimeStep;
		while(dayStamp + nextStamp < curStamp)
			nextStamp += UpdateMysteryTimeStep;
		nextUpdateTime = dayStamp+nextStamp;
		SetNextMysteryUpdateTime(nextUpdateTime);
	}

	if(nextUpdateTime < curStamp)
	{
		nextUpdateTime += UpdateMysteryTimeStep;
		SetNextMysteryUpdateTime(nextUpdateTime);
	}
}

void CMainClass::ShopYaoShiItemTimer()
{
	uint32 nextUpdateTime = GetNextYaoShiUpdateTime();
	uint32 curStamp = GetSysTime();
	if(nextUpdateTime == 0)
	{
		uint32 dayStamp = GetClearDayTime();
		uint32 nextStamp = UpdateYaoShiTimeStep;
		while(dayStamp + nextStamp < curStamp)
			nextStamp += UpdateYaoShiTimeStep;
		nextUpdateTime = dayStamp+nextStamp;
		SetNextYaoShiUpdateTime(nextUpdateTime);
	}

	if(nextUpdateTime < curStamp)
	{
		nextUpdateTime += UpdateYaoShiTimeStep;
		SetNextYaoShiUpdateTime(nextUpdateTime);
	}
}

void CMainClass::ShopShenhunItemTimer()
{
	uint32 nextUpdateTime = GetNextShenhunUpdateTime();
	uint32 curStamp = GetSysTime();
	if (nextUpdateTime == 0)
	{
		uint32 dayStamp = GetClearDayTime();
		uint32 nextStamp = UpdateShenhunTimeStep;
		while (dayStamp + nextStamp < curStamp)
			nextStamp += UpdateShenhunTimeStep;
		nextUpdateTime = dayStamp + nextStamp;
		SetNextShenhunUpdateTime(nextUpdateTime);
	}

	if (nextUpdateTime < curStamp)
	{
		nextUpdateTime += UpdateShenhunTimeStep;
		SetNextShenhunUpdateTime(nextUpdateTime);
	}
}

void CMainClass::ArenaTimer()
{
	static bool flag = false;
	int hour = GetHour();
	int minute = GetMinute();
	if(hour == 0) 
	{
		if(minute >= 0 && minute < 5)
		{
			if(!flag)
			{
				flag = true;
				SingletonCArenaManager::instance().SendAwardToAllUser();
			}
		}
		else if(minute > 30)
		{
			if(flag)
				flag = false;
		}
	}
}

void CMainClass::WorldLevelTimer()
{
	static bool update = true;
	if(GetWorldLevel() == 0)
	{
		UpdateWorldLevel();
		if(GetWorldLevel() == 0)
			SetWorldLevel(WORLD_LEVEL_DEFAULT);
		return;
	}

	int minute = GetMinute();
	if(minute >= 30)
	{
		if(update)
		{
			update = false;
			UpdateWorldLevel();
		}
	}
	else
	{
		if(!update)
			update = true;
	}
}

void CMainClass::BaiHuaTimer()
{
	/*int hour = GetHour();
	int minute = GetMinute();
	uint16 curTime = hour * 100 + minute;
	uint16 notifyTm;
	uint16 startTm;
	uint16 endTm;*/

	int type = SOT_Baihua;
	if (!sSystemOpenCfgMananger.OpenWeekDay(type))
		return;
	/*if (!sSystemOpenCfgMananger.GetFuncLvTime(type, notifyTm, startTm, endTm))
		return;*/
	static bool notify = false;
	if(!m_inBaihua)
	{
		if (!notify && CSceneManager::IsNotifyActivityTime(SOT_Baihua))
		{
			notify = true;
			SendHuoDongFlag(SOT_Baihua, 3);
		}
		else if (!m_inBaihua && CSceneManager::IsInActivityTime(SOT_Baihua))
		{
			m_inBaihua = true;
			BeginFightHuoDong();
			SendHuoDongFlag(SOT_Baihua,1);
			CNetMessage msg;
			msg.SetType(PRO_SYSTEM_INFO);
			SetLeftDropNum(200);
			msg<<LANGUAGE_TRANSFORM_1903<<(uint8)0;
			m_onlineUser.ForEachUser(boost::bind(&CMainClass::SendSysInfo,this,&msg,_1));
		}
	}
	else
	{
		if (CSceneManager::IsAfterActivityTime(SOT_Baihua) && m_inBaihua)
		{
			m_inBaihua = false;
			notify = false;
			EndFightHuoDong();
			SendHuoDongFlag(SOT_Baihua,2);
			CNetMessage msg;
			msg.SetType(PRO_SYSTEM_INFO);
			msg<<LANGUAGE_TRANSFORM_1904<<(uint8)0;
			m_onlineUser.ForEachUser(boost::bind(&CMainClass::SendSysInfo,this,&msg,_1));
		}
	}
}

void CMainClass::NianshouTimer()
{
	static bool notify = false;
	static bool start = false;
	if (!start)
	{
		//if(   hour == 19 && minute < 30)
		if (!notify && CSceneManager::IsNotifyActivityTime(SOT_Nianshou))
		{
			notify = true;
			SendHuoDongFlag(SOT_Nianshou, 3);
		}
		else if (!start && CSceneManager::IsInActivityTime(SOT_Nianshou))
		{
			start = true;
			BeginFightHuoDong();
			SendHuoDongFlag(SOT_Nianshou, 1);
			CNetMessage msg;
			msg.SetType(PRO_SYSTEM_INFO);
			SetLeftDropNum(200);
			msg << LANGUAGE_ZQX_0021 << (uint8)0;
			m_onlineUser.ForEachUser(boost::bind(&CMainClass::SendSysInfo, this, &msg, _1));
		}
	}
	else
	{
		if (CSceneManager::IsAfterActivityTime(SOT_Nianshou) && start)
		{
			start = false;
			notify = false;
			EndFightHuoDong();
			SendHuoDongFlag(SOT_Nianshou, 2);
			CNetMessage msg;
			msg.SetType(PRO_SYSTEM_INFO);
			msg << LANGUAGE_ZQX_0022 << (uint8)0;
			m_onlineUser.ForEachUser(boost::bind(&CMainClass::SendSysInfo, this, &msg, _1));
		}
	}
}

void CMainClass::ShuangBeiTimer() //双倍
{
	static bool notify = false;
	static bool start = false;
	if (!start)
	{
		if (!notify && CSceneManager::IsNotifyActivityTime(SOT_Shuangbei))
		{
			notify = true;
			SendHuoDongFlag(SOT_Shuangbei, 3);
		}
		else if (!start && CSceneManager::IsInActivityTime(SOT_Shuangbei))
		{
			// todo open
			start = true;
			SendHuoDongFlag(SOT_Shuangbei, 1);
			CNetMessage msg;
			msg.SetType(PRO_SYSTEM_INFO);
			char showInfo[256];
			snprintf(showInfo, sizeof(showInfo), LANGUAGE_ZQX_0024, GetSysDoubleExpRatio());

			msg << showInfo << (uint8)0;
			m_onlineUser.ForEachUser(boost::bind(&CMainClass::SendSysInfo, this, &msg, _1));
		}
	}
	else
	{
		if (CSceneManager::IsAfterActivityTime(SOT_Shuangbei) && start)
		{
			// todo cloee
			start = false;
			notify = false;
			SendHuoDongFlag(SOT_Shuangbei, 2);
			CNetMessage msg;
			msg.SetType(PRO_SYSTEM_INFO);
			char showInfo[256];
			snprintf(showInfo, sizeof(showInfo), LANGUAGE_ZQX_0024, GetSysDoubleExpRatio());
			msg << showInfo << (uint8)0;
			m_onlineUser.ForEachUser(boost::bind(&CMainClass::SendSysInfo, this, &msg, _1));
		}
	}
}

void CMainClass::ShuangGuWuXianShi() //双倍
{
	static bool notify = false;
	static bool start = false;
	int type = SOT_ShenJieMiJing;
	if (!start)
	{
		if (!notify && CSceneManager::IsNotifyActivityTime(type))
		{
			notify = true;
			SendHuoDongFlag(type, 3);
		}
		else if (!start && CSceneManager::IsInActivityTime(type))
		{
			start = true;
			SendHuoDongFlag(type, 1);
		}
	}
	else
	{
		if (CSceneManager::IsAfterActivityTime(type) && start)
		{
			start = false;
			notify = false;
			SendHuoDongFlag(type, 2);
		}
	}
}

//帮派掠夺
void CMainClass::BangPaiLueDuoTimer()
{
	static bool notify = false;
	static bool start = false;
	static int type = SOT_BangPaiLueDuo;
	if (!start)
	{
		if (!notify && CSceneManager::IsNotifyActivityTime(type))
		{
			notify = true;
			SendHuoDongFlag(type, 3);
		}
		else if (!start && CSceneManager::IsInActivityTime(type))
		{
			start = true;
			SendHuoDongFlag(type, 1);
			SysInfoToAllUser(LANGUAGE_ZQX_0076);
		}
	}
	else
	{
		if (CSceneManager::IsAfterActivityTime(type) && start)
		{
			start = false;
			notify = false;
			SendHuoDongFlag(type, 2);
			SysInfoToAllUser(LANGUAGE_ZQX_0077);
		}
	}
}

//体力补充
void CMainClass::SpiritTimer()
{
	//static bool notify = false;
	static bool start = false;
	static int type = SOT_18;
	CUserSpiritCfg& mgr = sCUserSpiritCfg;
	if (!start)
	{
		/*if (!notify && CSceneManager::InHuoDongTime(type))
		{
			notify = true;
			SendHuoDongFlag(type, 3);
		}
		else */if (!start && mgr.InHuoDongTime())
		{
			start = true;
			SendHuoDongFlag(type, 1);
		}
	}
	else
	{
		if (mgr.AfterHuoDongTime() && start)
		{
			start = false;
			//notify = false;
			SendHuoDongFlag(type, 2);
		}
	}
}



void CMainClass::SendDaTiHuoDong(CSocketServer *pSock,CNetMessage *pMsg,CUser *pUser,int limitLv)
{
	if (pUser == NULL)
		return;
	if (pUser->GetLevel() < limitLv)
		return;	
	pSock->SendMsg(pUser->GetSock(),*pMsg);
}

// 擂台赛活动
void CMainClass::LeiTaiSaiHuoDong()
{
	static const int leiTaiLevel[] = {40,50,60,70,80};
	static const int leiTaiWDay[] = {2,2,4,4,0};
	static const int leiTaiLen = sizeof(leiTaiWDay)/sizeof(leiTaiWDay[0]);
	static bool notify = false;
	static bool start = false;
	static int leiTaiLv = 0;
	static bool showMsg10 = false;
	static bool showMsg20 = false;

	if (!sSystemOpenCfgMananger.OpenWeekDay(SOT_LeiTaiSai))
		return;
	int hour = GetHour();
	int minute = GetMinute();
	if (leiTaiLv == 0)
	{
		int leiTaiIdx = 0;
		bool isHDDay = false;
		for (; leiTaiIdx < leiTaiLen; ++leiTaiIdx)
		{
			if (leiTaiWDay[leiTaiIdx] == GetWeekDay())
			{
				isHDDay = true;
				break;
			}
		}

		if (!isHDDay)
			return;

		leiTaiLv = leiTaiLevel[leiTaiIdx];
	}
	if (!start)
	{
		uint16 notifyTm;
		uint16 startTm;
		uint16 endTm;

		if (!sSystemOpenCfgMananger.GetFuncLvTime(SOT_LeiTaiSai, notifyTm, startTm, endTm))
			return;
		if (!notify && CSceneManager::IsNotifyActivityTime(SOT_LeiTaiSai))
		{
			notify = true;
			SendHuoDongFlag(SOT_LeiTaiSai, 3);
			char showInfo[256];
			snprintf(showInfo, sizeof(showInfo), LANGUAGE_TRANSFORM_1905, leiTaiLv, startTm / 100, startTm % 100);
			SysInfoToAllUser(showInfo);
		}
		else if (!start && CSceneManager::IsInActivityTime(SOT_LeiTaiSai))
		{
			start = true;
			SendHuoDongFlag(SOT_LeiTaiSai, 1);
			char showInfo[256];
			snprintf(showInfo, sizeof(showInfo), LANGUAGE_TRANSFORM_1907, leiTaiLv);
			SysInfoToAllUser(showInfo);
		}
		if (hour == 0)
		{
			// 0 点 数据没有置空时  置空数据
			leiTaiLv = 0;
			showMsg10 = false;
			showMsg20 = false;
		}
	}
	else
	{
		CSceneManager &scene = SingletonSceneManager::instance();
		CScene *pScene = scene.FindScene(LEI_TAI_ID2);
		if (pScene == NULL)
			return;
		char name[MAX_NAME_LEN] = { 0 };
		pScene->GetMatchTopRoleName(name);
		if (CSceneManager::IsInActivityTime(SOT_LeiTaiSai) && (minute == 10 || minute == 20) && (!showMsg10 || !showMsg20))
		{
			char showInfo[255] = { 0 };
			if (strlen(name) != 0)
			{
				snprintf(showInfo, sizeof(showInfo), LANGUAGE_TRANSFORM_1909, ROLE_NAME_COLOR, name, leiTaiLv);
			}

			if (minute == 10 && !showMsg10)
			{
				showMsg10 = true;
				CNetMessage sysMsg;
				sysMsg.SetType(PRO_SCENE_SYSTEM_INFO);
				sysMsg << showInfo;
				pScene->BroadcastMsgDirect(sysMsg);
			}
			else if (minute == 10 && !showMsg20)
			{
				showMsg20 = true;
				CNetMessage sysMsg;
				sysMsg.SetType(PRO_SCENE_SYSTEM_INFO);
				sysMsg << showInfo;
				pScene->BroadcastMsgDirect(sysMsg);
			}
		}
		if (CSceneManager::IsAfterActivityTime(SOT_LeiTaiSai) && start)
		{
			start = false;
			notify = false;
			SendHuoDongFlag(SOT_LeiTaiSai, 2);
			if (strlen(name) != 0)
			{
				char showInfo[255] = { 0 };
				snprintf(showInfo, sizeof(showInfo), LANGUAGE_ZQX_0075, ROLE_NAME_COLOR, name, leiTaiLv);
				SysInfoToAllUser(showInfo);
			}

			pScene->LeiTaiJiFenCalc();
		}
		if (hour == 0)
		{
			// 0 点 数据没有置空时  置空数据
			leiTaiLv = 0;
			showMsg10 = false;
			showMsg20 = false;
		}
	}
}

void CMainClass::ZhengDianZaiXianLiBaoTimer()
{
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	static bool flag = false;
	static int index = -1;
	int hour = GetHour();
	int minute = GetMinute();
	int TimeGet[][3] = {{21,0,1},{21,15,2},{21,30,3},{21,45,4},{22,0,5}};
	if (awardManager.InHuoDongTime(CHuoDongAwardManager::ZHENG_DIAN_ZAIXIAN))
	{
		for (unsigned int i = 0; i < sizeof(TimeGet)/sizeof(TimeGet[0]); i++)
		{
			if(hour == TimeGet[i][0] && minute == TimeGet[i][1] && !flag)
			{
				int idx = TimeGet[i][2];
				flag = true;
				index = i;
							
				SHuoDongAward award;
				awardManager.GetAwardData(CHuoDongAwardManager::ZHENG_DIAN_ZAIXIAN,idx,award);
				char buf[2048] = LANGUAGE_TRANSFORM_1911;
				int total_size = sizeof(buf) / sizeof(buf[0]);
				for(uint8 j=0;j < SHuoDongAward::AWARD_NUM;j++)
				{
					char *pbuf = buf + strlen(buf);
					int buf_size = total_size - strlen(buf);
					if (award.award[j] > 0 && award.num[j] > 0)
					{
						if(award.award[j] < 60000)
						{
							snprintf(pbuf,buf_size,"%s*%u, ",GetItemName(award.award[j]),award.num[j]);
						}
						else if(award.award[j] == HDAT_MONEY)
						{
							snprintf(pbuf,buf_size,LANGUAGE_TRANSFORM_1912,award.num[j]);
						}
						else if(award.award[j] == HDAT_BANG_YB)
						{
							snprintf(pbuf,buf_size,LANGUAGE_TRANSFORM_1913,award.num[j]);
						}
						else if(award.award[j] == HDAT_PET)
						{
							snprintf(pbuf,buf_size,LANGUAGE_TRANSFORM_1914,GetPetName(award.num[j]));
						}
						else if(award.award[j] == HDAT_YB)
						{
							snprintf(pbuf,buf_size,LANGUAGE_TRANSFORM_1915,award.num[j]);
						}
						else if(award.award[j] == HDAT_EXP)
						{
							snprintf(pbuf,buf_size,LANGUAGE_TRANSFORM_1916,award.num[j]);
						}
						else if(award.award[j] == HDAT_QIANNENG)
						{
							snprintf(pbuf,buf_size,LANGUAGE_TRANSFORM_1917,award.num[j]);
						}		
					}
				}
				snprintf(buf + strlen(buf) - 1,total_size - strlen(buf) + 1,LANGUAGE_TRANSFORM_1918);
				list<uint32> userList;
				m_onlineUser.GetUserList(userList);
				for(list<uint32>::iterator i = userList.begin(); i != userList.end(); i++)
				{
					ShareUserPtr ptr = m_onlineUser.GetUserByRoleId(*i);
					CUser *pUser = ptr.get();
					if(pUser != NULL)
					{
						SendHuoDongAwardMail(pUser->GetRoleId(),pUser->GetLevel(),award,buf,CHuoDongAwardManager::ZHENG_DIAN_ZAIXIAN);
					}
				}
				break;
			}
		}
	}
	
	if(index != -1 && hour == TimeGet[index][0] && minute >= TimeGet[index][1] + 4 && flag)
		flag = false;
}


// 尝试发送擂台赛活动，包含校验
void CMainClass::TrySendLeiTaiHuoDong(CSocketServer *pSock,CNetMessage *pMsg,CUser *pUser)
{
	if (pUser == NULL)
		return;
	if (!IsLeiTaiSaiTime(pUser->GetLevel(),true)) // 是否满足条件
		return;
	SendDaTiHuoDong(pSock,pMsg,pUser);
}

static int sOnlineNum;
void SetOnlineUserNum(int num)
{
	sOnlineNum = num;
}
int GetOnlineUserNum()
{
	return sOnlineNum;
}

void CMainClass::TimeOut()
{
	time_t saveOnlineNum = GetSysTime();
	time_t userTimeOut = GetSysTime();
	const int limitSaveOnceNum = 6;
	int saveRoleOnceNum = 0;
	string serverId;
	static bool SaveFlag[2] = {false,false};
	
	vector<int> sidList;
	GetServerIdList(sidList);
	if(!sidList.empty())
	{
		serverId = "(";
		uint16 size = sidList.size();
		for(uint16 i=0;i < size;i++)
		{
			serverId += IntToStr(sidList[i]);
			if(i != size-1)
				serverId += ",";
		}
		serverId += ")";
	}

#ifndef KUA_FU
	time_t onlineState = GetSysTime();
	static bool bzSaveFlag = true;
#endif
	
	while(sExit)
	{
		saveRoleOnceNum = 0;
		if(GetSysTime() - userTimeOut > 10)
		{
			gyu::util::TimePrint tPrint("==>>> CMainClass::TimeOut");
			
			userTimeOut = GetSysTime();
			list<uint32> userList;
			int num = 0;
			m_onlineUser.GetUserList(userList);
			for(list<uint32>::iterator i = userList.begin(); i != userList.end(); i++)
			{
				ShareUserPtr ptr = m_onlineUser.GetUserByRoleId(*i);
				CUser *pUser = ptr.get();
				if(pUser != NULL)
				{
					pUser->TimeOut(saveRoleOnceNum,limitSaveOnceNum);
					num++;
				}
			}
			SetOnlineUserNum(num);
			if(GetSysTime() - saveOnlineNum > 6*60)
			{
				saveOnlineNum = GetSysTime();
				CGetDbConnect getDb;
				CDatabaseSql *pDb = getDb.GetDbConnect();
				char sql[128];
				snprintf(sql,sizeof(sql)-1,"insert into online_user_num (num,time) values (%d,FROM_UNIXTIME(%lu))",num,GetSysTime());
				if(pDb != NULL)
				{
					pDb->Query(sql);
				}
			}

#ifndef KUA_FU
			if(!serverId.empty())
			{
				if(gyu::util::CIniFile::GetValue("local_test","server",gConfigFile) != "1" && GetSysTime() - onlineState > 6*60)
				{
					onlineState = GetSysTime();
					
					char sql[1024];
					uint8 state = 0;
					if(num > 400 && num < 700)
						state = 1;
					else if(num > 700)
						state = 2;
					snprintf(sql,sizeof(sql)-1,"update server_list set onlineState=%d where server_id in %s",state,serverId.c_str());
					
					boost::recursive_mutex::scoped_lock lk(G_LoginDB_Mutex);
					g_LoginDB.Query(sql);
				}
			}
#endif
			
			SingletonShopManager::instance().Timeout();
//			ShopMysteryItemTimer();
//			ShopYaoShiItemTimer();
//			ShopShenhunItemTimer();
//			PetDrawTimer();
			XinShiClear();
//			WorldLevelTimer();
			//ZhengDianZaiXianLiBaoTimer(); // 这个活动不开启
			SingletonCRankMgr::instance().Timer();

			SingletonCFunctionSwitchManager::instance().Timer();
			SingletonCHuoDongAwardManager::instance().TimeOut();
			SingletonCHuoDongAwardManager::instance().PaiHangBangTimer();

			SingletonCFriendMgr::instance().Timer();

//			KunLunShanTeamTimer();	// 神界论道

//			BaiHuaTimer();
//			HuSongShenShouTimer();
//			FishHuoDong(); // 钓鱼
//			XunChaShiTimer();   // 六界 巡查
//			NianshouTimer();	// 年兽
			
#ifndef KUA_FU
			SingletonCHDExchangeManager::instance().TimeOut();
			ArenaTimer();
			SpiritTimer();
//			ShuangBeiTimer();
//			BangPaiLueDuoTimer();
//			KunLunShanTimer();
//			TongTianTaTimer();
//			FeiXianTimer();
//			TreasureTimer();
//			LingQiJuanXianTimer();
//			DuoRenChuangGuan(); // 多人闯关
//			QiangHongBaoTimer();
//			KaiFuChongJiSaiTimer();		// 开服冲级赛
//			XinFuZhanLiBangTimer();		// 新服战力榜
//			ZuiQiangShenChongBangTimer();	//最强神将榜
//			XianJiaQiangHuaBangTimer();	// 仙甲强化榜
//			DengJiChongCiBangTimer();	// 等级冲刺榜
//			QunXianZhanLiBangTimer();	// 群仙战力榜
//			XinFuChongZhiBangTimer();	// 新服充值榜
//			FestivalBangTimer();		// 中秋活动
//			WingBangTimer();		//神级羽翼榜
			LoadChongZhiDang();
//			ShuangGuWuXianShi();
			SingletonCFestivalRandomBoxManager::instance().TimeOut();
//			SingletonCHuoDongAwardManager::instance().HDChouTimer();
			
//			LeiTaiSaiHuoDong();	// 擂台赛
			UpdateKuaFuOpenState();
//			SingletonCJiaoYiHangManager::instance().Timer();
#else
//			KuaFu1V1Timer();
//			SingletonCQunXianZhengBaManager::instance().Timer();
#endif

#ifdef KUA_FU
//			SingletonCKuaFu1vs1PreliminaryManager::instance().TimeOut();
//			SingletonCShenJieMiJingManager::instance().TimeOut();
#endif

			int hour = GetHour();
			if(((hour == 3 && !SaveFlag[0]) || (hour == 15 && !SaveFlag[1])) && GetMinute() >= Random(1,5))
			{
				if(hour == 3)
					SaveFlag[0] = true;
				else if(hour == 15)
					SaveFlag[1] = true;
				
				gyu::util::TimePrint aa("CMainClass::TimeOut Save");
				SingletonCBangPaiManager::instance().SaveBangPai();
				SingletonCRankMgr::instance().Save();
				SingletonCArenaManager::instance().Save();
				SingletonCSimpleRoleDataMgr::instance().Save();
				SingletonCFriendMgr::instance().Save();
			}
			if(hour == 0)
			{
				SaveFlag[0] = false;
				SaveFlag[1] = false;
			}

#ifndef KUA_FU
			if(GetWeekDay() == 6 && hour == 23 && GetMinute() >= 10 && bzSaveFlag)
			{
				bzSaveFlag = false;
				SingletonCBangPaiManager::instance().SaveBangPai();
			}
			else if(hour == 0 && !bzSaveFlag)
			{
				bzSaveFlag = true;
			}
#endif
		}
		sleep(1);
	}
}

void CMainClass::SendSysInfo(CNetMessage *msg,CUser *pUser)
{
	m_socketServer.SendMsg(pUser->GetSock(),*msg);
}

void CMainClass::SendMsgToUser()
{
	if(GetSysTime() - m_readMsgTime > 300)
	{
		//读取系统消息
		m_readMsgTime = GetSysTime();
		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		if(pDb == NULL)
			return;
		//						0	1		2			3		4		5	6
		if(!pDb->Query("select type,msg,time_space,begin_time,end_time,id,type1 from notice order by type1 asc,type asc,id asc"))
			return;
		char **row;
		//		m_gonggao[0] = 0;
		uint8 msgNum = 0;
		m_GongGaoMsg.ReWrite();
		m_GongGaoMsg.SetType(PRO_GONGGAO);
		uint16 msgPos = m_GongGaoMsg.GetDataLen();
		m_GongGaoMsg<<msgNum;

		m_cxGongGao.clear();
		for(uint8 i=0;i < GONGGAO_GROUP_NUM;i++)
			m_sysInfo[i].clear();
		while((row = pDb->GetRow()) != NULL)
		{
			time_t beginTime,endTime;
			beginTime = atoi(row[3]);
			endTime = atoi(row[4]);
			if((beginTime < GetSysTime()) && (GetSysTime() < endTime))
			{
				if(atoi(row[0]) == 0)
				{
					if(row[1] != NULL)
					{
						m_GongGaoMsg<<row[1];
						msgNum++;
					}
				}
				else if(atoi(row[0]) == 1)
				{
					uint8 groupIdx = (uint8)atoi(row[6]);
					if(groupIdx > GONGGAO_GROUP_NUM)
						continue;
					m_sysInfo[groupIdx-1].push_back(row[1]);
					m_sysInfoTimeSpace[groupIdx-1] = 60*atoi(row[2]);
				}
				else if(atoi(row[0]) == 2)
				{
					if(row[1] != NULL)
						m_cxGongGao = row[1];
				}
			}
		}

		m_GongGaoMsg.WriteData(msgPos,&msgNum,sizeof(msgNum));
		char sql[256];
		snprintf(sql,sizeof(sql),"select beilv from huodong_time where UNIX_TIMESTAMP(begin_time)<%lu and UNIX_TIMESTAMP(end_time)>%lu",
			GetSysTime(),GetSysTime());
		if(!pDb->Query(sql))
			return;
		row = pDb->GetRow();
		if(row != NULL)
		{
			if(!InHuoDong())
			{
				SetHuoDong(true);
				SetHuoDongBeiLv(atoi(row[0]));
				CNetMessage msg;
				msg.SetType(PRO_SYSTEM_INFO);
				msg<<LANGUAGE_TRANSFORM_1919<<(uint8)0;
				m_onlineUser.ForEachUser(boost::bind(&CMainClass::SendSysInfo,this,&msg,_1));
			}
		}
		else
		{
			SetHuoDong(false);
			SetHuoDongBeiLv(1);
		}
	}

	for(uint8 k=0;k < GONGGAO_GROUP_NUM;k++)
	{
		if((GetSysTime() - m_sendTime[k] > m_sysInfoTimeSpace[k]) && (!m_sysInfo[k].empty()))
		{
			m_sendTime[k] = GetSysTime();
			if(m_sendIdx[k] >= (int)(m_sysInfo[k].size()))
				m_sendIdx[k] = 0;

			CNetMessage msg;
			msg.SetType(PRO_SYSTEM_INFO);
			msg<<m_sysInfo[k][m_sendIdx[k]]<<(uint8)0;
			m_onlineUser.ForEachUser(boost::bind(&CMainClass::SendSysInfo,this,&msg,_1));			
			m_sendIdx[k]++;
		}
	}
}

void CMainClass::SendGongGao(int sock)
{
	if(m_GongGaoMsg.GetDataLen() > 5)
	{
		m_socketServer.SendMsg(sock,m_GongGaoMsg);
	}
	//cout<<"公告:"<<m_gonggao<<endl;
}

bool CMainClass::AddYuanBao(int serverId,uint32 userId,uint32 roleId,int tongbao,char *msg,uint8 type,bool isShouChong,int money)
{
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	ShareUserPtr p = onlineUser.GetUserByRoleId(roleId);
	CUser *pUser = p.get();
	if(pUser != NULL)
	{
		pUser->AddTongBao(tongbao,type,serverId);
	}
	else
	{
		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		if(pDb == NULL)
			return false;
		string userTab = GetUserInfoTab(serverId);
		char sqlBuf[256];
		if(type == 1)
			snprintf(sqlBuf,sizeof(sqlBuf),"update %s set bd_money=bd_money+%d where id=%u",userTab.c_str(),tongbao,userId);
		else
			snprintf(sqlBuf,sizeof(sqlBuf),"update %s set money=money+%d where id=%u",userTab.c_str(),tongbao,userId);
		pDb->Query(sqlBuf);

		int nIsShouChong = 0;
		if(isShouChong)
			nIsShouChong = 1;
		snprintf(sqlBuf,sizeof(sqlBuf),"insert into cz_notice (user_id,msg,is_first,money) values(%u,'%s',%d,%d)",userId,msg,nIsShouChong,money);
		pDb->Query(sqlBuf);
	}
	SendSystemMail(roleId,msg);
	return false;
}

//static bool IsMyCard(int type)
//{
//	return (type == 701 || type == 703);
//}

void CMainClass::ChongZhiSuccess(int ad,int type,int serverId,uint32 userId,uint32 roleId,int money,const char *cardno)
{
	char msg[256];

	NoticeClientChargeResult(roleId,PRO_SUCCESS,money,cardno);
	int addTongBao = GetYB_ByMoney(money);
	snprintf(msg,sizeof(msg),LANGUAGE_TRANSFORM_1920,money,addTongBao);
	ShareUserPtr ptr = m_onlineUser.GetUserByRoleId(roleId);
	CUser *pUser = ptr.get();
	bool needSave = false;

	do
	{
		if(pUser == NULL)
		{
			pUser = ReadUserSimpleData(roleId);
			if(pUser == NULL)
				return;
			pUser->SetServerId(serverId);
			pUser->SetUserId(userId);
			needSave = true;
		}
		uint32 sumMoney = pUser->GetExtData32(460) + money;
		pUser->SetExtData32(460, sumMoney);
		if(pUser->ChongZhiJiJinFanli(money)
			|| pUser->ChongZhiLevelJiJinFanli(money, addTongBao)
			|| pUser->ChongZhiHuoYueJinFanli(money, addTongBao))
		{
			pUser->SetBitSet(434);
			if (!needSave)
			{
				sCMissionManager.UpdateQuestState(pUser, EMQCT_38, sumMoney);
				//SingletonCMissionManager::instance().UpdateDCMissionComplate(pUser, EMISS_DC_72, money);
			}
			pUser->AddChongzhiTotal(addTongBao);
			pUser->UpdateVipInfoEx();
			pUser->CheckChongZhiHuoDong(!needSave, money, addTongBao, type); //校验玩家充值活动
			pUser->CheckMeiRiShouChong(!needSave, type);
			break;
		}
		else if (pUser->RoundZheKouHuoDong(money))
		{
			pUser->AddChongzhiTotal(addTongBao);
			pUser->UpdateVipInfoEx();
			pUser->CheckChongZhiHuoDong(!needSave, money, addTongBao, type); //校验玩家充值活动
			pUser->CheckMeiRiShouChong(!needSave, type);
			break;
		}

		//if(!IsMyCard(type))	// mycard不走直购
		{
			bool buyItem = false;
			int buyType = 0xff;
			for(uint8 i=0;i < sizeof(PrivilegePrice)/sizeof(PrivilegePrice[0]);i++)
			{
				if(money == PrivilegePrice[i])
				{
					buyItem = true;
					buyType = i;
					break;
				}
			}
			if(buyItem)	// 直接购买
			{
				if(buyType == 0xff)
					break;
				pUser->BuyMonthCard(buyType);
				pUser->AddChongzhiTotal(addTongBao);
				pUser->AddMaterial(HDAT_YB, addTongBao, false);
				pUser->UpdateVipInfoEx();
				if (UPT_Diamond == buyType)
				{
					SMailData mailData;
					mailData.AddAward(HDAT_CHENGHAO, 0, E2UT_88);
					SendSystemMail(roleId, LANGUAGE_ZQX_0111, &mailData);
				}
				pUser->CheckFestivalDrop(addTongBao / 100, true);
				pUser->CheckChongZhiHuoDong(!needSave, money, addTongBao, type); //校验玩家充值活动
				pUser->CheckMeiRiShouChong(!needSave, type);
				break;
			}

			boost::recursive_mutex::scoped_lock lk(cz_fanli_mutex);
			if(!G_CZ_TO_OTHER_INFO.empty())
			{
				SChongZhi2OtherAward data = G_CZ_TO_OTHER_INFO[0];
				if(money == data.RMB)
				{
					ChongZhiToOtherSuccess(roleId,data);
					break;
				}
			}
		}
		
		int addExtYB = 0;
		int addExtItem_ID = 0;
		int addExtItemNum = 0;
		int dangYB = 0;
		int dangIdx = -1;
		uint32 data = pUser->GetExtData32(207);
		{
			boost::recursive_mutex::scoped_lock lk(cz_fanli_mutex);
			{
				bool findItem = false;
				//在正常充值档之前先处理特供商品--RMB直买商品
				if(SingletonCHuoDongMoneyGiftBag::instance().CheckMoneyGiftBagBuyData(pUser,money))
				{
					findItem = true;
				}

				for(int i=G_CZ_INFO_RMBSHOP.size()-1;i>=0;i--)
				{
					if(money == G_CZ_INFO_RMBSHOP[i].dang)
					{
						addExtItem_ID = G_CZ_INFO_RMBSHOP[i].itemId;
						addExtItemNum = G_CZ_INFO_RMBSHOP[i].itemNum;
						if(addExtItem_ID > 0 && addExtItemNum > 0)
						{
							SItemInstance item;
							SMailData mdata;
							mdata.AddAward(addExtItem_ID, 0, addExtItemNum);
							char mailBuf[256];
							snprintf(mailBuf,sizeof(mailBuf),LANGUAGE_TRANSFORM_1924,GetItemName(addExtItem_ID),addExtItemNum);
							SendSystemMail(roleId,mailBuf,&mdata);
						}
						findItem = true;
						break;
					}
				}//end of for

				if(findItem)
					break;
				{
					for(int i=G_CZ_INFO_A.size()-1;i>=0;i--)
					{
						if(G_CZ_INFO_A[i].type != 6 && G_CZ_INFO_A[i].type != 7 && money >= G_CZ_INFO_A[i].dang)
						{
							dangIdx = i;
							dangYB = G_CZ_INFO_A[i].dang;
							if((data & (1<<dangIdx)) != 0)  // 首充过了 或者是月卡
							{
								addExtYB = G_CZ_INFO_A[i].fanLi;
								addExtItem_ID = G_CZ_INFO_A[i].itemId;
								addExtItemNum = G_CZ_INFO_A[i].itemNum;
							}
							else
							{
								addExtYB = G_CZ_INFO_A[i].firstFanLi;
								addExtItem_ID = G_CZ_INFO_A[i].firstItemId;
								addExtItemNum = G_CZ_INFO_A[i].firstItemNum;
							}
							break;
						}
					}
				}
			}
		}
		char extBuf[256];
		char extItemBuf[256];
		{
			if(dangIdx >= 0 && dangYB > 0 && addExtYB > 0)
			{
				if((data & (1<<dangIdx)) != 0)	// 首充过了
				{
					snprintf(extBuf,sizeof(extBuf),LANGUAGE_TRANSFORM_1925,addExtYB);
					if(addExtItem_ID > 0 && addExtItemNum > 0)
						snprintf(extItemBuf,sizeof(extItemBuf),LANGUAGE_TRANSFORM_1926,GetItemName(addExtItem_ID),addExtItemNum);
				}
				else	// 首充
				{
					data |= (1<<dangIdx);
					pUser->SetExtData32(207, data);
					snprintf(extBuf,sizeof(extBuf),LANGUAGE_TRANSFORM_1927,dangYB,addExtYB);
					if(addExtItem_ID > 0 && addExtItemNum > 0)
						snprintf(extItemBuf,sizeof(extItemBuf),LANGUAGE_TRANSFORM_1928,dangYB,GetItemName(addExtItem_ID),addExtItemNum);
				}
			}
			SingletonCHuoDongMoneyGiftBag::instance().AddUserPayRecordInHuoDongTime(pUser, addTongBao);

			if(pUser == NULL)
				AddYuanBao(serverId,userId,roleId,addTongBao,msg);
			else
				AddYuanBao(serverId,userId,roleId,addTongBao,msg,0,pUser->HaveBitSet(200),money);

			if(addExtYB > 0)
				AddYuanBao(serverId,userId,roleId,addExtYB,extBuf);
			if(addExtItem_ID > 0 && addExtItemNum > 0)
			{
				SItemInstance item;
				SMailData mdata;
				mdata.AddAward(addExtItem_ID, 0, addExtItemNum);
				SendSystemMail(roleId,extItemBuf,&mdata);
			}
		}
		
		if(pUser != NULL)
		{
			pUser->CheckChongZhiHuoDong(!needSave,money,addTongBao,type); //校验玩家充值活动
			pUser->CheckMeiRiShouChong(!needSave, type);
		}
	}while(0);

	if(needSave && (pUser != NULL))
	{
		pUser->SaveDataSimple();
		delete pUser;
		pUser = NULL;
	}
}

bool CMainClass::ChongZhiToOtherSuccess(int roleId,SChongZhi2OtherAward &data)
{
	if(roleId <= 0 || data.RMB == 0)
		return false;
	char buf[512];
	stringstream mydataStr;
	int titleId = 0;
	
	SMailData m;
	for(int i=0;i < SChongZhi2OtherAward::AWARD_NUM;i++)
	{
		/*if(data.self_award[i] > 0 && data.self_num[i] > 0)
		{
			if(data.self_award[i] < HDAT_MONEY)
			{
				SItemInstance item;
				item.tmplId = data.self_award[i];
				item.num = data.self_num[i];
				m.item.push_back(item);
				mydataStr<<GetItemName(item.tmplId)<<"*"<<(int)item.num<<"，";
			}
			else if(data.self_award[i] == HDAT_MONEY)
			{
				m.money += data.self_num[i];
				mydataStr<<LANGUAGE_TRANSFORM_1500<<(int)m.money<<"，";
			}
			else if(data.self_award[i] == HDAT_BANG_YB)
			{
				m.bdYB += data.self_num[i];
				mydataStr<<LANGUAGE_TRANSFORM_1501<<(int)m.bdYB<<"，";
			}
			else if(data.self_award[i] == HDAT_YB)
			{
				m.YB += data.self_num[i];
				mydataStr<<LANGUAGE_TRANSFORM_1502<<(int)m.YB<<"，";
			}
			else if(data.self_award[i] == HDAT_CHENGHAO)
			{
				titleId = data.self_num[i];
			}
		}*/
	}

	snprintf(buf,sizeof(buf)-1,LANGUAGE_SSJ_0092,mydataStr.str().c_str(),GetTitleName(titleId));
	SendSystemMail(roleId,buf,&m);

	return true;
}

void CMainClass::ChongZhi()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;

	char buf[512];
	//                       0       1       2       3        4          5          6         7           8      9
	if(!pDb->Query("select c.id,c.user_id,c.money,c.state,c.role_id,c.role_level,c.type,c.card_num,c.server_id,c.ad from cz_complete as c,role_info as r where c.is_deal=0 and c.role_id=r.id and r.kuafu_state=0 limit 1"))
		return;
	char **row = pDb->GetRow();
	if(row != NULL)
	{
		uint32 id = atoi(row[0]);
		uint32 userId = atoi(row[1]);
		int money = atoi(row[2]);
		int state = atoi(row[3]);
		uint32 roleId = atoi(row[4]);
		uint16 level = (uint16)atoi(row[5]);
		uint16 type = (uint16)atoi(row[6]);
		const char *order = row[7];
		int serverId = atoi(row[8]);
		int ad = atoi(row[9]);
		char msg[256];
		if(state == 0)
		{
			ChongZhiSuccess(ad,type,serverId,userId,roleId,money,order);
		}
		else
		{
			NoticeClientChargeResult(roleId,PRO_ERROR,money,order);
			
			snprintf(msg,sizeof(msg),LANGUAGE_TRANSFORM_1929);
			AddYuanBao(serverId,userId,roleId,0,msg);
		}
		snprintf(buf,sizeof(buf),"update cz_complete set is_deal=1,role_level=%d where id=%u",(int)level,id);
		pDb->Query(buf);
	}
}

CUser* CMainClass::ReadUserSimpleData(int roleId)
{
	CUser* pUser = new CUser;
	if(pUser->ReadDataSimple(roleId))
		return pUser;
	else
	{
		delete pUser;
		return NULL;
	}
}

// 多人闯关
void CMainClass::DuoRenChuangGuan()
{
	static bool flag = false;
	int hour = GetHour();
	if ((hour == 0) && (!flag)) // 整点重置活动数据
	{
		flag = true;
		CSocketServer &sock = SingletonSocket::instance();
		CNetMessage msg;
		msg.SetType(MSG_CHUANG_GUAN);
		msg<<(uint8)CXunBaoManage::ECGOp_Reset;
		SingletonOnlineUser::instance().ForEachUser(boost::bind(&CMainClass::SendDaTiHuoDong,this,&sock,&msg,_1,0));
	}
	else if ((hour != 0) && (flag))
	{
		flag = false;
	}
}

// 钓鱼
void CMainClass::FishHuoDong()
{
	int hour = GetHour();
	int minute = GetMinute();
	char buf[128];
	static bool notify = false;
	static bool flagBefore10 = false;
	static bool flagBefore5 = false;
	static bool flagBegin = false;
	static bool flagEnd = false;
	uint16 notifyTm;
	uint16 startTm;
	uint16 endTm;
	uint16 before10 = startTm - 10;
	uint16 before5 = startTm - 5;
	uint16 curTime = hour * 100 + minute;
	if (before5 % 100 > 60)
		before5 -= 50;
	if (before10 % 100 > 60)
		before10 -= 50;
	int type = SOT_Fish;
	if (!sSystemOpenCfgMananger.OpenWeekDay(type))
		return;
	if (!sSystemOpenCfgMananger.GetFuncLvTime(type, notifyTm, startTm, endTm))
		return;
	if (CSceneManager::IsNotifyActivityTime(type))
	{
		if (!notify)
		{
			SendHuoDongFlag(type, 3);
			notify = true;
			snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_1930, startTm / 100, startTm % 100);
			SysInfoToAllUser(buf);
		}

		if (!flagBefore10 && curTime >= before10)
		{
			flagBefore10 = true;
			snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_1930, startTm / 100, startTm % 100);
			SysInfoToAllUser(buf);
		}
		if (flagBefore5 && curTime >= before5)
		{
			flagBefore5 = true;
			snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_1930, startTm / 100, startTm % 100);
			SysInfoToAllUser(buf);
		}
	}

	{ // 活动开始公告
		if ((SingletonFishManager::instance().IsInHuoDongTime()) && (!flagBegin))
		{
			notify = false;
			flagBegin = true;
			//cout << "发送活动开始公告" << endl;
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1932);
			SysInfoToAllUser(buf);

			SendHuoDongFlag(type, 1);
		}
	}

	{ // 活动开始结束
		if (CSceneManager::IsAfterActivityTime(type) && (!flagEnd))
		{
			flagEnd = true;
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1933);
			SysInfoToAllUser(buf);
			SendHuoDongFlag(type, 2);
			SingletonFishManager::instance().CleanRoom();
		}
		else if (hour == CFishManager::HUO_DONG_TIME + 1 && flagEnd)
		{
			flagEnd = false;
			notify = false;
			flagBefore10 = false;
			flagBefore5 = false;
			flagBegin = false;
			flagEnd = false;
		}
	}
}

void CMainClass::IdleThread()
{
	time_t ggTimg = 0;
	time_t saveBangpai = 0;
	time_t fightTime = 0;
	time_t update_monster = 0;
	
	memset(&m_sendTime,0,sizeof(m_sendTime));
	memset(&m_sendIdx,0,sizeof(m_sendIdx));
	m_readMsgTime = 0;

	CSceneManager &sceneMgr = SingletonSceneManager::instance();
	CBangPaiManager &bangMgr = SingletonCBangPaiManager::instance();

	while(sExit)
	{
		{
			gyu::util::TimePrint tPrint("==>>> CMainClass::IdleThread");

			if(GetSysTime() - update_monster > 1)
			{
				if(update_monster > 0)
					sceneMgr.UpdateMonster();
				update_monster = GetSysTime();
			}
			if(GetSysTime() - fightTime > 5)
			{
				if(fightTime > 0)
				{
					m_fightMgr.RunFightTimeOut();
					sceneMgr.Timer();
					bangMgr.Timer();
					CleanArenaPaiHang();

					SingletonTeamFaBuCfgMgr::instance().MatchTimer();
				}
				fightTime = GetSysTime();
			}
			
			if(GetSysTime() - ggTimg > 20)
			{
				if(ggTimg > 0)
					SendMsgToUser();
				ggTimg = GetSysTime();
			}

			if(GetSysTime() - saveBangpai > 3600)
			{
				if(saveBangpai > 0)
					bangMgr.SaveData();
				saveBangpai = GetSysTime();
			}

			ChongZhi();
		}

		sleep(1);
	}
}

void CMainClass::Run()
{
	while(sExit)
	{
		m_socketServer.DespatchEvent(1000);
		//		m_socketServer.ClearTimeOutConnect();
	}
	m_socketServer.DestroyPackage();
	Join();
}

CMainClass *gpMain;

struct SSqliteStartupOptions
{
	bool enabled;
	string databasePath;
	string schemaPath;
	SSqliteStartupOptions():enabled(false) {}
};

static bool ReadTextFile(const string &path, string &contents)
{
	ifstream input(path.c_str(), ios::binary);
	if(!input)
		return false;
	ostringstream buffer;
	buffer << input.rdbuf();
	contents = buffer.str();
	return true;
}

static bool GetSqliteStartupOptions(int argc, char **argv, SSqliteStartupOptions &options)
{
	string driver = gyu::util::CIniFile::GetValue("driver","database",gConfigFile);
	if(driver == "sqlite" || driver == "SQLite" || driver == "SQLITE")
	{
		options.enabled = true;
		options.databasePath = gyu::util::CIniFile::GetValue("sqlite_path","database",gConfigFile);
		options.schemaPath = gyu::util::CIniFile::GetValue("sqlite_schema","database",gConfigFile);
	}
	for(int i = 1; i < argc; ++i)
	{
		if(strcmp(argv[i], "--sqlite") == 0)
		{
			if(i + 1 >= argc)
			{
				cout << "--sqlite requires a database path" << endl;
				return false;
			}
			options.enabled = true;
			options.databasePath = argv[++i];
		}
		else if(strcmp(argv[i], "--sqlite-schema") == 0)
		{
			if(i + 1 >= argc)
			{
				cout << "--sqlite-schema requires a schema path" << endl;
				return false;
			}
			options.schemaPath = argv[++i];
		}
	}
	if(options.enabled && (options.databasePath.empty() || options.schemaPath.empty()))
	{
		cout << "SQLite startup requires both database path and schema path" << endl;
		return false;
	}
	return true;
}

static bool PrepareSqliteDatabase(const SSqliteStartupOptions &options)
{
	string schema;
	if(!ReadTextFile(options.schemaPath, schema))
	{
		cout << "SQLite schema could not be read: " << options.schemaPath << endl;
		return false;
	}
	CDatabaseSql database;
	if(!database.ConnectSqlite(options.databasePath.c_str()))
	{
		cout << "SQLite database open failed path=" << options.databasePath << " error=" << database.GetErrMsg() << endl;
		return false;
	}
	if(!database.ExecuteScript(schema.c_str()))
	{
		cout << "SQLite schema migration failed path=" << options.schemaPath << " error=" << database.GetErrMsg() << endl;
		return false;
	}
	if(!database.Query("select version from schema_version order by version desc limit 1"))
	{
		cout << "SQLite schema version query failed: " << database.GetErrMsg() << endl;
		return false;
	}
	char **row = database.GetRow();
	if(row == NULL || row[0] == NULL || atoi(row[0]) < 1)
	{
		cout << "SQLite schema version is missing or invalid" << endl;
		return false;
	}
	string schemaVersion = row[0];
	if(!database.Query("PRAGMA integrity_check"))
	{
		cout << "SQLite integrity check failed to execute: " << database.GetErrMsg() << endl;
		return false;
	}
	row = database.GetRow();
	if(row == NULL || row[0] == NULL || strcmp(row[0], "ok") != 0)
	{
		cout << "SQLite integrity check failed: " << (row && row[0] ? row[0] : "missing result") << endl;
		return false;
	}
	cout << "[local] SQLite ready path=" << options.databasePath << " schema_version=" << schemaVersion << " integrity=ok" << endl;
	return true;
}

static void WaitForLocalShutdownCommand()
{
	string command;
	while(sExit && getline(cin, command))
	{
		if(command == "shutdown")
		{
			cout << "[local] graceful shutdown requested by owning client" << endl;
			SigHandler(SIGTERM);
			return;
		}
	}
}

int main(int argc,char **argv)
{
	SServerBasicCfg cfg;
	cout << "[local] main: InitDB" << endl;
	if(!InitDB(cfg))
		return -1;
	cout << "[local] main: ReadGameServerData" << endl;
	ReadGameServerData();

#ifdef KUA_FU
	ReSetKuaFu1V1Data();
#endif
	cout << "[local] main: ConfigInit" << endl;
	if(!ConfigInit())
	{
		cout<<"read config error and exit !!!"<<endl;
		return -1;
	}
	srand(time(NULL));
	cout << "[local] main: CDbPool::CreateInstance" << endl;
	CDbPool *pPool = CDbPool::CreateInstance(true);
	SSqliteStartupOptions sqliteOptions;
	if(!GetSqliteStartupOptions(argc, argv, sqliteOptions))
		return -1;
	if(sqliteOptions.enabled)
	{
		cout << "[local] main: Prepare SQLite" << endl;
		if(!PrepareSqliteDatabase(sqliteOptions))
			return -1;
		pPool->SetSqliteConfigure(sqliteOptions.databasePath);
	}
	else
	{
		cout << "[local] main: SetDbConfigure MySQL" << endl;
		pPool->SetDbConfigure(cfg.dbUser,cfg.dbPwd,cfg.dbHost,cfg.dbName,cfg.dbPort, "utf8");
	}
	
	cout << "[local] main: InitSysTime" << endl;
	if (!InitSysTime())
		return -1;
	cout << "[local] main: InitConfig" << endl;
	if(!InitConfig())
		return -1;
	
	cout << "[local] main: CMainClass::Init" << endl;
	CMainClass *pMain = new CMainClass;
	boost::thread *shutdownThread = NULL;
	if(pMain->Init(cfg))
	{
		gpMain = pMain;
		if(sqliteOptions.enabled)
			shutdownThread = new boost::thread(&WaitForLocalShutdownCommand);
		cout << "[local] main: Run" << endl;
		pMain->Run();
	}
	if(shutdownThread != NULL)
	{
		shutdownThread->join();
		delete shutdownThread;
	}

	cout<<"-- exit"<<endl;
	ClearMonsterDistributionList();
	delete pMain;
	return 0;
}

// 清理竞技场排行
void CleanArenaPaiHang()
{
	static bool enableClean = false;
	if(GetWeekDay() != 1)
	{
		enableClean = false;
		return;
	}
	if(GetHour() != 0)
	{
		enableClean = false;
		return;
	}
	if(enableClean)
		return;
	enableClean = true;

	// 每天保存一次
	SingletonCArenaManager::instance().Save();
}

bool InitTongTianTa()
{
	if(tongTianTaBaZhuData.size() > 0)
		tongTianTaBaZhuData.clear();

	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char sql[512];
	char **row = NULL;
	if(pDb == NULL)
		return false;
	snprintf(sql,sizeof(sql),"select roleId from tongtianta order by id asc");
	if(!pDb->Query(sql))
		return false;
	char temp[32];
	uint8 bazhuNum = sizeof(tongTianTaBaZhuFloor)/sizeof(tongTianTaBaZhuFloor[0]);
	int num = pDb->GetRowNum();
	if(num == 0)
	{
		for(int i=0;i < bazhuNum;i++)
			tongTianTaBaZhuData.push_back(0);
		snprintf(sql,sizeof(sql),"insert into tongtianta (id,roleId) values(1,0)");
		for(int i=2;i <= bazhuNum;i++)
		{
			snprintf(temp,sizeof(temp),",(%d,0)",i);
			strcat(sql,temp);
		}
		if(!pDb->Query(sql))
			return false;
		return true;
	}
	{
		vector<uint32> bazhuList;
		while ((row = pDb->GetRow()) != NULL)
			bazhuList.push_back((uint32)atoi(row[0]));

		for(uint8 i=0;i < bazhuList.size();i++)
		{
			snprintf(sql,sizeof(sql),"select name from role_info where id=%u",bazhuList[i]);
			if(pDb->Query(sql))
			{
				if((row = pDb->GetRow()) != NULL)
					tongTianTaBaZhuData.push_back(bazhuList[i]);
				else
					tongTianTaBaZhuData.push_back(0);
			}
		}
	}
	return true;
}

void SaveTongTianTa()
{
	if(tongTianTaBaZhuData.size() == 0)
		return;
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char sql[512];
	if(pDb == NULL)
		return;
	for(int i = 0;i < (int)tongTianTaBaZhuData.size();i++)
	{
		snprintf(sql,sizeof(sql),"update tongtianta set roleId=%u where id=%d",tongTianTaBaZhuData[i],i+1);
		if(!pDb->Query(sql))
		{
			snprintf(sql,sizeof(sql),"insert into tongtianta (id,roleId) values(%d,%u)",i+1,tongTianTaBaZhuData[i]);
			pDb->Query(sql);
		}
	}
}

// 开服冲级赛 获取奖励
int KaiFuChongJiSaiGetReward(int rank)
{
	int addBdYuanBao = 0;
	if (rank == 1)
		addBdYuanBao = 800;
	else if (rank == 2)
		addBdYuanBao = 500;
	else if (rank == 3)
		addBdYuanBao = 300;
	else if (rank == 4)
		addBdYuanBao = 100;
	else if (rank == 5)
		addBdYuanBao = 100;
	else
		addBdYuanBao = 50;
	return addBdYuanBao;
}

// 新服战力榜 获取奖励
int XinFuZhanLiBangGetReward(int rank)
{
	int addBdYuanBao = 0;
	if (rank == 1)
		addBdYuanBao = 1000;
	else if (rank == 2)
		addBdYuanBao = 800;
	else if (rank == 3)
		addBdYuanBao = 500;
	else if (rank == 4)
		addBdYuanBao = 300;
	else if (rank == 5)
		addBdYuanBao = 300;
	else
		addBdYuanBao = 100;
	return addBdYuanBao;
}

int Connect(const char *ip,uint16 port)
{
	CSocketServer &socketServer = SingletonSocket::instance();
	struct sockaddr_in addr;
	memset(&addr,0,sizeof(addr));
	addr.sin_addr.s_addr = inet_addr(ip);
	addr.sin_port = htons(port);
	addr.sin_family = AF_INET;
	int sock = socket(AF_INET,SOCK_STREAM,0);
	if(sock < 0)
		return 0;

	struct timeval timev;
	timev.tv_sec = 6;
	timev.tv_usec = 0;
	setsockopt(sock,SOL_SOCKET,SO_RCVTIMEO,(const char*)&timev,sizeof(timev));
	setsockopt(sock,SOL_SOCKET,SO_SNDTIMEO,(const char*)&timev,sizeof(timev));
	if(connect(sock,(sockaddr*)&addr,sizeof(addr)) != 0)
	{
		close(sock);
		return 0;
	}
	socketServer.SetSock(sock);
	socketServer.AddEvent(sock);
	return sock;
}
