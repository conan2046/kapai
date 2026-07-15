#include "utility.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <boost/format.hpp>
#include <boost/scoped_array.hpp>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include "singleton.h"
#include "call_script.h"
#include "script_call.h"
#include "zlib.h"
#include "skill.h"
#include "main.h"
#include "init.h"
#include "rank.h"
#include "arena.h"
#include "blood_fight_manage.h"

extern vector<SMonsterDistribution *> MonsterDistributionList;
extern std::map<uint16,SkillInfoNode> skillInfoListMap;
extern const char *gConfigFile;
extern uint32 randombox_stamp;
extern std::map<uint32,uint32> limitSaveMap;
extern std::map<uint32,RandomBoxItem> randombox_cfg;
extern vector<uint32> tongTianTaBaZhuData;	// 通天塔霸主ID,12/24/36/48/60

SKuaFu1V1UserData G_1V1_PaiMing_Old_16[16][MAX_PAIMING_NUM];
SKuaFu1V1UserData G_1V1_PaiMing_Old_8[8][MAX_PAIMING_NUM];
SKuaFu1V1UserData G_1V1_PaiMing_Old_4[4][MAX_PAIMING_NUM];
SKuaFu1V1UserData G_1V1_PaiMing_Old_2[2][MAX_PAIMING_NUM];
SKuaFu1V1UserData G_1V1_PaiMing_Old_1[1][MAX_PAIMING_NUM];
SKuaFu1V1UserData G_1V1_PaiMing_First_Old;
map<uint32,KuaFu1V1VoteData> G_1V1_VoteList_Old[32];
KuaFu1V1VoteData G_1V1_VoteTotolMoney_Old[32][2];

SKuaFu1V1UserData G_1V1_PaiMing_16[16][MAX_PAIMING_NUM];
SKuaFu1V1UserData G_1V1_PaiMing_8[8][MAX_PAIMING_NUM];
SKuaFu1V1UserData G_1V1_PaiMing_4[4][MAX_PAIMING_NUM];
SKuaFu1V1UserData G_1V1_PaiMing_2[2][MAX_PAIMING_NUM];
SKuaFu1V1UserData G_1V1_PaiMing_1[1][MAX_PAIMING_NUM];
SKuaFu1V1UserData G_1V1_PaiMing_First;
map<uint32,KuaFu1V1VoteData> G_1V1_VoteList[32];
KuaFu1V1VoteData G_1V1_VoteTotolMoney[32][2];
vector<StKuaFu1Vs1SortUserInfo> G_1V1_RankList;	// 总排名倒序排列
vector<StKuaFu1Vs1SortUserInfo> G_1V1_TurnRank;	// 每轮排名
boost::recursive_mutex G_1V1_Mutex;

static uint32 mysteryTime = 0;

static uint32 yaoshiTime = 0;
static uint32 ShowYaoShiItemNum = 12;
static uint32 shenhunTime = 0;

VipConfig G_VipConfig[MAX_VIP_LEVEL+1];
static int WorldLevel = 0;
SSystemDoubleExpCfg G_SYS_EXP_CFG;

const char *GetTitleName(int tid)
{
	return MakeStringColor(sTitltAttrCfgManager.GetTitleName(tid), 4).c_str();
}

const char *GetShenqiName(int id)
{
	return MakeStringColor(SingletonShenQiCfgMgr::instance().GetShenQiName(id), 4).c_str();
}

const char *GetFaBaoName(int id)
{
	FaBaoCfg* cfg = sCItemCfgManager.GetFaBaoCfg(id);
	if (cfg == NULL)
		return "";
	return MakeStringColor(cfg->name.c_str(), 4).c_str();
}


static const char *ProfessionName[] = {"",LANGUAGE_SSJ_0494,LANGUAGE_SSJ_0495,LANGUAGE_SSJ_0496,LANGUAGE_SSJ_0497,LANGUAGE_SSJ_0498,LANGUAGE_SSJ_0499};
static const char *SexName[] = {LANGUAGE_SSJ_1012,LANGUAGE_SSJ_1013};

const char *GetProfessionName(uint32 profession)
{
	if(profession < 1 || profession >= sizeof(ProfessionName)/sizeof(ProfessionName[0]))
		return "";
	return ProfessionName[profession];
}

const char *GetSexName(uint32 sex)
{
	if(sex >= sizeof(SexName)/sizeof(SexName[0]))
		return "";
	return SexName[sex];
}

void SetNextMysteryUpdateTime(uint32 time)
{
	mysteryTime = time;
}

uint32 GetNextMysteryUpdateTime()
{
	return mysteryTime;
}

void SetNextShenhunUpdateTime(uint32 time)
{
	shenhunTime = time;
}

uint32 GetNextShenhunUpdateTime()
{
	return shenhunTime;
}

void SetNextYaoShiUpdateTime(uint32 time)
{
	yaoshiTime = time;
}

uint32 GetNextYaoShiUpdateTime()
{
	return yaoshiTime;
}

uint32 GetYaoShiItemNum()
{
	return ShowYaoShiItemNum;
}

int StrToHex(const char *str,uint8 *pHex,int hexLen)
{
	if (hexLen < (int)strlen(str)/2)
		return 0;

	int i = 0;
	for (; i < (int)strlen(str)/2; i++)
	{
		int temp = 0;
		sscanf(str+2*i,"%02x",&temp);
		pHex[i] = temp;
	}
	return i;
}

void HexToStr(uint8 *pHex,int hexLen,string &str)
{
	char buf[4];
	for (int i = 0; i < hexLen; i++)
	{
		snprintf(buf,sizeof(buf),"%02x",pHex[i]);
		str.append(buf);
	}
}

void ItemHexToStr(SItemInstance *pItem,string &toStr)
{
	if(pItem == NULL)
		return;
	uint8 buf[512];
	uint32 len = WriteItemBuf(pItem,buf,sizeof(buf));
	if(len > sizeof(buf))
	{		
		cout<<">> ERROR  ItemHexToStr  len > MaxBufLen"<<endl;
		return;
	}
	HexToStr((uint8 *)buf,len,toStr);
}

void PetHexToStr(SPet *pPet,string &toStr)
{
	if(pPet == NULL)
		return;
	uint8 buf[256];
	uint32 len = WritePetBuf(pPet,buf,sizeof(buf));
	if(len > sizeof(buf))
	{		
		cout<<">> ERROR  PetHexToStr  len > MaxBufLen"<<endl;
		return;
	}
	HexToStr((uint8 *)buf,len,toStr);
}

void GetLoginLogTab(char *buf,size_t bufSize)
{
	static int sMonth;
	int month = GetMonth() + 1;
	snprintf(buf,bufSize,"login_log_%d",month);
	if(sMonth != month)
	{
		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		if(pDb == NULL)
			return;
		char sql[512];
		snprintf(sql,sizeof(sql),"CREATE TABLE IF NOT EXISTS %s (id int(11) NOT NULL AUTO_INCREMENT,role_id int(11) NOT NULL,"\
			"level smallint(6) NOT NULL,ad int(11) NOT NULL DEFAULT '0',ip varchar(128) NOT NULL,net_info varchar(128) NOT NULL,mac varchar(128) NOT NULL,"\
			"IMEI varchar(128) NOT NULL,IDFA varchar(128) NOT NULL,login_time datetime NOT NULL,logout_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,"\
			"PRIMARY KEY (id),KEY role_id (role_id),KEY ad (ad)) ENGINE=MyISAM",buf);
		pDb->Query(sql);
		sMonth = month;
	}
}

void GetTradeTab(char *buf,size_t bufSize)
{
	snprintf(buf,bufSize,"trade_log");

	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
	char sql[512];
	snprintf(sql,sizeof(sql),"CREATE TABLE IF NOT EXISTS %s (id int(11) NOT NULL AUTO_INCREMENT,`time` int(11) NOT NULL,"\
		" money1 int(11) NOT NULL,"\
		" user1 int(11) NOT NULL,"\
		" item1 varchar(512) COLLATE utf8_bin NOT NULL,"\
		" pet1 varchar(512) COLLATE utf8_bin NOT NULL,"\
		" money2 int(11) NOT NULL,"\
		" user2 int(11) NOT NULL,"\
		" item2 varchar(512) COLLATE utf8_bin NOT NULL,"\
		" pet2 varchar(720) COLLATE utf8_bin NOT NULL,PRIMARY KEY (id)) ENGINE=MyISAM",buf); 
	pDb->Query(sql);
}

string GetUserInfoTab(int serverId)
{
	char buf[128];
	snprintf(buf,sizeof(buf),"user_info%d",serverId);
	return buf;
}

void SaveTrade(uint32 user1,int money1,string &item1,string &pet1,uint32 user2,int money2,string &item2,string pet2)
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;

	char tab[64];
	GetTradeTab(tab,sizeof(tab));
	char buf[1024];
	snprintf(buf,sizeof(buf),"INSERT INTO %s (time,user1,money1,item1,pet1,user2,money2,item2,pet2) "\
		"VALUES (%lu,%d,%d,'%s','%s',%d,%d,'%s','%s')",tab,
		GetSysTime(),
		user1,money1,item1.c_str(),pet1.c_str(),
		user2,money2,item2.c_str(),pet2.c_str());
	pDb->Query(buf);
}

void GetUseItemTab(char *buf,size_t bufSize)
{
	static int sMonth;
	int month = GetMonth() + 1;
	snprintf(buf,bufSize,"use_item_log_%d",month);
	if(sMonth != month)
	{
		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		if(pDb == NULL)
			return;
		char sql[512];
		snprintf(sql,sizeof(sql),"CREATE TABLE IF NOT EXISTS %s ("\
			" `id` int(11) NOT NULL AUTO_INCREMENT,"\
			" `role_id` int(11) NOT NULL,"\
			" `item` int(11) NOT NULL,"\
			" `num` int(11) NOT NULL,"\
			" `reason` varchar(16) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,"\
			" `before_use` varchar(256) COLLATE utf8_bin NOT NULL,"\
			" `end_use` varchar(256) COLLATE utf8_bin NOT NULL,"\
			" `time` int(11) NOT NULL,PRIMARY KEY (`id`)) ENGINE=MyISAM",buf);

		pDb->Query(sql);
		sMonth = month;
	}
}

void SaveUseItem(uint32 userId,uint32 itemId,const char *reason,uint8 num,string before,string end)
{
	if(itemId == 0)
		return;

	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_SERVER_SAVE_USE_ITEM);
	msg<<userId<<itemId<<num;
	int nlen=strlen(reason);
	msg<<(uint16)nlen;
	msg.WriteData((void *)reason,strlen(reason));
	msg<<before<<end;
	sock.SendServerMsg(EST_LONG, msg);
}

void SaveUseItemStr(uint32 userId,uint32 itemId,const char *reason,uint8 num,const char * before,const char * end)
{
	if (reason == NULL || before == NULL || end == NULL)
		return;
	SaveUseItem(userId,itemId,reason,num,before,end);
}

void SaveDelPet(uint32 userId,SPet *pPet)
{
	if(pPet == NULL)
		return;
	if(pPet->quality < PQT_PURPLE)
		return;
	uint8 buf[256];
	uint32 len = WritePetBuf(pPet,buf,sizeof(buf));
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_SERVER_SAVE_PET);
	msg<<userId;
	msg.WriteData(buf,len);
	sock.SendServerMsg(EST_LONG, msg);
}

void GeeUserShopTab(char *buf,size_t bufSize)
{
	snprintf(buf,bufSize,"user_shop_item");

	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
	char sql[512];
	snprintf(sql,sizeof(sql),"CREATE TABLE IF NOT EXISTS %s ("\
		" `id` int(11) NOT NULL AUTO_INCREMENT,"\
		" `time` int(11) NOT NULL,"\
		" `buyer` int(11) NOT NULL,"\
		" `seller` int(11) NOT NULL,"\
		" `money` int(11) NOT NULL,"\
		" `item` varchar(128) COLLATE utf8_bin NOT NULL DEFAULT '',PRIMARY KEY (`id`)) ENGINE=MyISAM",buf);
	pDb->Query(sql);
}

void SaveUserShopItem(uint32 buyer,uint32 seller,int money,string &item)
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;

	char tab[64];
	GeeUserShopTab(tab,sizeof(tab));
	char buf[1024];
	snprintf(buf,sizeof(buf),"INSERT INTO %s (time,buyer,seller,money,item) VALUES (%lu,%d,%d,%d,'%s')",
		tab,GetSysTime(),buyer,seller,money,item.c_str());
	pDb->Query(buf);
}

void SaveUserShopPet(uint32 buyer,uint32 seller,int money,string &pet)
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();

	if (pDb == NULL)
		return;

	char buf[1024];
	snprintf(buf,sizeof(buf),"INSERT INTO user_shop_pet (time,buyer,seller,money,pet) VALUES (%lu,%d,%d,%d,'%s')",
		GetSysTime(),buyer,seller,money,pet.c_str());
	pDb->Query(buf);
}

void GeeBuyShopTab(char *buf,size_t bufSize)
{
	static int sMonth;
	int month = GetMonth() + 1;
	snprintf(buf,bufSize,"buy_shop_item_%d",month);
	if(sMonth != month)
	{
		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		if(pDb == NULL)
			return;
		char sql[512];

		snprintf(sql,sizeof(sql),"CREATE TABLE IF NOT EXISTS %s ("\
			" `id` int(11) NOT NULL AUTO_INCREMENT,"\
			" `item_id` int(11) NOT NULL,"\
			" `num` int(11) NOT NULL,"\
			" `money_type` int(11) NOT NULL,"\
			" `role_id` int(11) NOT NULL,"\
			" `use_money` int(11) NOT NULL,"\
			" `left_money` int(11) NOT NULL,"\
			" `type` int(11) NOT NULL,"\
			" `time` int(11) NOT NULL,"\
			" PRIMARY KEY (`id`), KEY `role_id` (`role_id`)) ENGINE=MyISAM",buf);

		pDb->Query(sql);
		sMonth = month;
	}
}

void ItemCurrencyLog(uint32 userId,int itemId,int num,int moneyType, int useMoney, int lessMoney, int uerType)
{
	/*CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_SERVER_SAVE_BUY_ITEM);
	msg << userId << itemId << moneyType << num;
	msg << useMoney << lessMoney << uerType;
	sock.SendServerMsg(EST_LONG, msg);*/
}

void SaveBuyShopItem(uint8 type, uint32 userId, SAwardData& award, SCostData& cost, uint32 lessMoney)
{
	char buf[512];
	uint16 month = GetMonth() + 1;
	uint32 now = GetSysTime();
	snprintf(buf, sizeof(buf), "INSERT INTO `buy_shop_item_%d` (`role_id`, `type`, `item_type`, `item_id`, `num`, `money_type`, `use_money`, `left_money`, `time`)"\
		"VALUES (%u, %d, %d, %d, %d, %d, %d, %u, %u);", month, userId, type, award.type, award.typeId, award.num, cost.costType, cost.costValue, lessMoney, now);
	SendLongQuerySql(buf);
}

int SplitLine(char **templa, int templatecount, char *pkt)
{
	int i = 0;
	while (*pkt == '|')
		++pkt;
	while (*pkt != 0)
	{
		if ((*pkt == '\r') || (*pkt == '\n') || (*pkt == '\t'))
		{
			memmove(pkt,pkt+1,strlen(pkt+1)+1);
		}
		else if (i == 0)
		{
			templa[i] = pkt;
			++i;
		}
		else if ((*pkt == '|') && (i < templatecount))
		{
			*pkt = 0;
			++pkt;
			while (*pkt == '|')
				++pkt;

			templa[i] = pkt;
			++i;
		}
		else
		{
			++pkt;
		}
	}
	return i;
}

int SplitLine(char **templa,char *pkt)
{
	int i = 0;
	while (*pkt == '|')
		++pkt;
	while (*pkt != 0)
	{
		if ((*pkt == '\r') || (*pkt == '\n') || (*pkt == '\t'))
		{
			memmove(pkt,pkt+1,strlen(pkt+1)+1);
		}
		else if (i == 0)
		{
			templa[i] = pkt;
			++i;
		}
		else if (*pkt == '|')
		{
			*pkt = 0;
			++pkt;
			while (*pkt == '|')
				++pkt;
			
			templa[i] = pkt;
			++i;
		}
		else
		{
			++pkt;
		}
	}
	return i;
}

int SplitLine(char **templa,char *pkt, char sep)
{
	int i = 0;
	while (*pkt == sep)
		++pkt;
	while (*pkt != 0)
	{
		if ((*pkt == '\r') || (*pkt == '\n') || (*pkt == '\t'))
		{
			memmove(pkt,pkt+1,strlen(pkt+1)+1);
		}
		else if (i == 0)
		{
			templa[i] = pkt;
			++i;
		}
		else if (*pkt == sep)
		{
			*pkt = 0;
			++pkt;
			while (*pkt == sep)
				++pkt;

			if (*pkt == '\0')
				break;

			templa[i] = pkt;
			++i;
		}
		else
		{
			++pkt;
		}
	}
	return i;
}

int split_line (char **tem,int temcount, char *pkt)
{
	int i = 0;

	if (!pkt)
		return -1;
	while (ISSPACE (*pkt))
		pkt++;
	while (*pkt && i < temcount)
	{
		if (*pkt == '"')
		{
			/* quoted string */
			pkt++;
			tem[i++] = pkt;
			pkt = strchr (pkt, '"');
			if (!pkt)
			{
				/* bogus line */
				return -1;
			}
			*pkt++ = 0;
			if (!*pkt)
				break;
			pkt++;		/* skip the space */
		}
		else
		{
			tem[i++] = pkt;
			pkt = strpbrk (pkt, " \t\r\n");
			if (!pkt)
				break;
			*pkt++ = 0;
		}
		while (ISSPACE (*pkt))
			pkt++;
	}
	return i;
}

bool SplitString( const std::string& _src, std::vector<std::string>& _vec, char _ch )
{
	_vec.clear();
	if( _src.size() == 0 ) 
	{   
		return false;
	}   
	std::size_t pos = 0;
	std::size_t start = 0;
	while( ( pos = _src.find(_ch, start) ) != std::string::npos )
	{   
		std::string tempstr = _src.substr( start, pos - start );
		_vec.push_back( tempstr );
		start = pos + 1;
	}   

	if( _src.size() > start )
	{   
		std::string tempstr = _src.substr( start, _src.size() - start );
		_vec.push_back( tempstr );
	}   
	return true;
}   

bool SplitString(const std::string& _src, std::vector<std::string>& _vec, const char* chs)
{
	_vec.clear();
	if( _src.size() == 0 ) 
	{   
		return false;
	}
	char saveBuf[1024];
	snprintf(saveBuf, 1024, "%s",  _src.c_str());
	char* buf = saveBuf;
	char *p;
	char* ptr = strtok_r(buf, chs,  &p);
    while(ptr != NULL)
	{
		_vec.push_back(ptr);
		ptr = strtok_r(NULL, chs, &p);
    }
	return true;
}

string SQLFilter(string &sql)
{
	if(sql.empty())
		return sql;
	size_t idx = 0;
	if((idx = sql.find(";")) != string::npos)
		sql = sql.substr(0,idx);
	return sql;
}

string SQLFilter(const char *sql)
{
	if(sql == NULL)
		return "";
	string out = sql;
	return SQLFilter(out);
}

int Random(int min,int max)
{
	if (min >= max)
		return min;
	if (max - min + 1 == 0)
		return 0;
	int t = rand();
	int r = rand();
	for(int i=0;i < t%7;i++)
		r = rand();
	t = rand();
	for(int i=0;i < t%5;i++)
		r = rand();
	r %= (max - min + 1);
	return r + min;
}

string IntToStr(int value)
{
	string res;
	char buf[128];
	snprintf(buf,sizeof(buf),"%d",value);
	res = buf;
	return res;
}

static vector<int> ServerIdList;

void GetServerIdList(vector<int> &idList)
{
	idList.clear();
	idList.assign(ServerIdList.begin(),ServerIdList.end());
}

void SetServerIdList(vector<int> &idList)
{
	ServerIdList.clear();
	ServerIdList.assign(idList.begin(),idList.end());
}

// 获得一个1至max的随机不重复序列，共max个元素
bool RandomSequence(int *array,int arrayLen,int max)
{
	if(max < 1 || arrayLen != max || array == NULL)
		return false;
	for(int i=1;i <= max;i++)
		array[i-1] = i;
	for(int i=0;i < max-1;i++)
	{
		int r = Random(0,max-i-1);
		int temp;
		if(r == max-i-1)
			continue;
		temp = array[r];
		array[r] = array[max-i-1];
		array[max-i-1] = temp;
	}
	return true;
}

uint32 ReadItemBuf(SItemInstance *item,uint8 *buf,uint32 bufLen)
{
	if(item == NULL || buf == NULL || bufLen == 0)
		return 0;
	uint32 pos = 0;
	ReadDataFromBuf((char *)buf,&(item->tmplId),sizeof(item->tmplId),pos,bufLen);
	if(item->tmplId == 0)
		return pos;
	CItemTemplateManager &itemMgr = SingletonItemManager::instance();
	SItemTemplate *pItem = itemMgr.GetItem(item->tmplId);
	if(pItem == NULL)
		return pos;

	/*uint8 temp8;
	uint16 temp16;
	uint32 temp32;*/
	ReadDataFromBuf((char *)buf,&(item->num),sizeof(item->num),pos,bufLen);
	//if(pItem->type <= EIT_WuQi_6 || pItem->type >= EIT_TouKui_1)	// 装备
	//{
	//	ReadDataFromBuf((char *)buf,&(item->level),sizeof(item->level),pos,bufLen);
	//	ReadDataFromBuf((char *)buf,&(item->addAttrNum),sizeof(item->addAttrNum),pos,bufLen);
	//	uint8 maxSize = sizeof(item->addAttrType)/sizeof(item->addAttrType[0]);
	//	for(uint8 i=0;i < item->addAttrNum;i++)
	//	{
	//		if(i <= maxSize-1)
	//		{
	//			ReadDataFromBuf((char *)buf,&(item->addAttrType[i]),sizeof(item->addAttrType[i]),pos,bufLen);
	//			ReadDataFromBuf((char *)buf,&(item->addAttrVal[i]),sizeof(item->addAttrVal[i]),pos,bufLen);
	//			ReadDataFromBuf((char *)buf,&(item->addAttrStar[i]),sizeof(item->addAttrStar[i]),pos,bufLen);
	//			ReadDataFromBuf((char *)buf,&(item->cuilianUseYB[i]),sizeof(item->cuilianUseYB[i]),pos,bufLen);
	//		}
	//		else
	//		{
	//			ReadDataFromBuf((char *)buf,&temp16,sizeof(temp16),pos,bufLen);
	//			ReadDataFromBuf((char *)buf,&temp32,sizeof(temp32),pos,bufLen);
	//			ReadDataFromBuf((char *)buf,&temp8,sizeof(temp8),pos,bufLen);
	//			ReadDataFromBuf((char *)buf,&temp32,sizeof(temp32),pos,bufLen);
	//		}
	//	}

	//	uint8 xilianTypeNum = 0;
	//	ReadDataFromBuf((char *)buf,&xilianTypeNum,sizeof(xilianTypeNum),pos,bufLen);
	//	maxSize = sizeof(item->xilianType)/sizeof(item->xilianType[0]);
	//	for(uint8 i=0;i < xilianTypeNum;i++)
	//	{
	//		if(i <= maxSize-1)
	//		{
	//			ReadDataFromBuf((char *)buf,&(item->xilianType[i]),sizeof(item->xilianType[i]),pos,bufLen);
	//			ReadDataFromBuf((char *)buf,&(item->xilianVal[i]),sizeof(item->xilianVal[i]),pos,bufLen);
	//			ReadDataFromBuf((char *)buf,&(item->xilianStar[i]),sizeof(item->xilianStar[i]),pos,bufLen);
	//			ReadDataFromBuf((char *)buf,&(item->xilianSaveType[i]),sizeof(item->xilianSaveType[i]),pos,bufLen);
	//			ReadDataFromBuf((char *)buf,&(item->xilianSaveVal[i]),sizeof(item->xilianSaveVal[i]),pos,bufLen);
	//			ReadDataFromBuf((char *)buf,&(item->xilianSaveStar[i]),sizeof(item->xilianSaveStar[i]),pos,bufLen);
	//		}
	//		else
	//		{
	//			ReadDataFromBuf((char *)buf,&temp16,sizeof(temp16),pos,bufLen);
	//			ReadDataFromBuf((char *)buf,&temp32,sizeof(temp32),pos,bufLen);
	//			ReadDataFromBuf((char *)buf,&temp8,sizeof(temp8),pos,bufLen);
	//			ReadDataFromBuf((char *)buf,&temp16,sizeof(temp16),pos,bufLen);
	//			ReadDataFromBuf((char *)buf,&temp32,sizeof(temp32),pos,bufLen);
	//			ReadDataFromBuf((char *)buf,&temp8,sizeof(temp8),pos,bufLen);
	//		}
	//	}

	//	uint8 nameLen = 0;
	//	ReadDataFromBuf((char *)buf,&nameLen,sizeof(nameLen),pos,bufLen);
	//	maxSize = sizeof(item->name)-1;
	//	if(nameLen > maxSize)
	//	{
	//		ReadDataFromBuf((char *)buf,item->name,maxSize,pos,bufLen);
	//		item->name[maxSize] = '\0';
	//		pos += nameLen - maxSize;
	//	}
	//	else
	//	{
	//		ReadDataFromBuf((char *)buf,item->name,nameLen,pos,bufLen);
	//		item->name[nameLen] = '\0';
	//	}
	//}
	//else if(pItem->type == EIT_Box_2)
	//{
	//	ReadDataFromBuf((char *)buf,&(item->extData),sizeof(item->extData),pos,bufLen);
	//}
	return pos;
}

uint32 WriteItemBuf(SItemInstance *item,uint8 *buf,uint32 bufLen)
{
	if(item == NULL || buf == NULL)
		return 0;
	uint32 pos = 0;
	CopyDataToBuf((char *)buf, &(item->tmplId), sizeof(item->tmplId), pos, bufLen);
	if(item->tmplId == 0)
		return pos;
	CItemTemplateManager &itemMgr = SingletonItemManager::instance();
	SItemTemplate *pItem = itemMgr.GetItem(item->tmplId);
	if(pItem == NULL)
		return pos;

	CopyDataToBuf((char *)buf,&(item->num),sizeof(item->num),pos,bufLen);
	//if(pItem->type <= EIT_WuQi_6 || pItem->type >= EIT_TouKui_1)	// 装备
	//{
	//	CopyDataToBuf((char *)buf,&(item->level),sizeof(item->level),pos,bufLen);
	//	uint8 cuiLianNum = sizeof(item->addAttrType)/sizeof(item->addAttrType[0]);
	//	CopyDataToBuf((char *)buf,&cuiLianNum,sizeof(cuiLianNum),pos,bufLen);
	//	for(uint8 i = 0; i < cuiLianNum; i++)
	//	{
	//		CopyDataToBuf((char *)buf,&(item->addAttrType[i]),sizeof(item->addAttrType[i]),pos,bufLen);
	//		CopyDataToBuf((char *)buf,&(item->addAttrVal[i]),sizeof(item->addAttrVal[i]),pos,bufLen);
	//		CopyDataToBuf((char *)buf,&(item->addAttrStar[i]),sizeof(item->addAttrStar[i]),pos,bufLen);
	//		CopyDataToBuf((char *)buf,&(item->cuilianUseYB[i]),sizeof(item->cuilianUseYB[i]),pos,bufLen);
	//	}

	//	uint8 xilianTypeNum = sizeof(item->xilianType)/sizeof(item->xilianType[0]);
	//	CopyDataToBuf((char *)buf,&xilianTypeNum,sizeof(xilianTypeNum),pos,bufLen);
	//	for(uint8 i=0;i < xilianTypeNum;i++)
	//	{
	//		CopyDataToBuf((char *)buf,&(item->xilianType[i]),sizeof(item->xilianType[i]),pos,bufLen);
	//		CopyDataToBuf((char *)buf,&(item->xilianVal[i]),sizeof(item->xilianVal[i]),pos,bufLen);
	//		CopyDataToBuf((char *)buf,&(item->xilianStar[i]),sizeof(item->xilianStar[i]),pos,bufLen);
	//		CopyDataToBuf((char *)buf,&(item->xilianSaveType[i]),sizeof(item->xilianSaveType[i]),pos,bufLen);
	//		CopyDataToBuf((char *)buf,&(item->xilianSaveVal[i]),sizeof(item->xilianSaveVal[i]),pos,bufLen);
	//		CopyDataToBuf((char *)buf,&(item->xilianSaveStar[i]),sizeof(item->xilianSaveStar[i]),pos,bufLen);
	//	}

	//	uint8 nameLen = strlen(item->name);
	//	CopyDataToBuf((char *)buf,&nameLen,sizeof(nameLen),pos,bufLen);
	//	CopyDataToBuf((char *)buf,item->name,nameLen,pos,bufLen);
	//}
	//else if(pItem->type == EIT_Box_2)
	//{
	//	CopyDataToBuf((char *)buf,&(item->extData),sizeof(item->extData),pos,bufLen);
	//}
	return pos;
}

uint32 ReadPetBuf(SPet *pPet,uint8 *buf,uint32 bufLen,bool useDefName, uint8 extNum)
{
	if(pPet == NULL || buf == NULL || bufLen == 0)
		return 0;

	uint32 pos = 0;

	int lessNum = extNum;
	ReadDataFromBuf((char *)buf,&(pPet->id),sizeof(pPet->id),pos,bufLen);
	if(pPet->id == 0)
		return pos;
	uint8 nameLen = 0;
	ReadDataFromBuf((char *)buf, &(pPet->level), sizeof(pPet->level), pos, bufLen);
	ReadDataFromBuf((char *)buf, &(pPet->exp), sizeof(pPet->exp), pos, bufLen);
	ReadDataFromBuf((char *)buf, &(pPet->star), sizeof(pPet->star), pos, bufLen);
	ReadDataFromBuf((char *)buf, &(pPet->breakLevel), sizeof(pPet->breakLevel), pos, bufLen);
	ReadDataFromBuf((char *)buf,&nameLen,sizeof(nameLen),pos,bufLen);
	char name[512];
	ReadDataFromBuf((char *)buf,name,nameLen,pos,bufLen);
	name[nameLen] = '\0';
	pPet->name = name;

	if (lessNum > 0)
	{
		ReadDataFromBuf((char *)buf, &(pPet->xiuLianLevel), sizeof(pPet->xiuLianLevel), pos, bufLen);
		uint8 cSize = 0;
		ReadDataFromBuf((char *)buf, &cSize, sizeof(cSize), pos, bufLen);
		for (size_t i = 0; i < cSize; i++)
		{
			uint8 atype = 0;
			uint16 acnt = 0;
			ReadDataFromBuf((char *)buf, &atype, sizeof(atype), pos, bufLen);
			ReadDataFromBuf((char *)buf, &acnt, sizeof(acnt), pos, bufLen);
			pPet->curXiuLianCnts[atype] = acnt;
		}
	}
	return pos;
}


/*
pPet->curVer 描述
*/
uint32 WritePetBuf(SPet *pPet,uint8 *buf,uint32 bufLen)
{
	if(pPet == NULL || buf == NULL)
		return 0;

	uint32 pos = 0;
	CopyDataToBuf((char *)buf, &(pPet->id), sizeof(pPet->id), pos, bufLen);
	if(pPet->id == 0)
		return pos;
	CopyDataToBuf((char *)buf, &(pPet->level), sizeof(pPet->level), pos, bufLen);
	CopyDataToBuf((char *)buf, &(pPet->exp), sizeof(pPet->exp), pos, bufLen);
	CopyDataToBuf((char *)buf, &(pPet->star), sizeof(pPet->star), pos, bufLen);
	CopyDataToBuf((char *)buf, &(pPet->breakLevel), sizeof(pPet->breakLevel), pos, bufLen);
	
	uint8 nameLen = pPet->name.length();
	CopyDataToBuf((char *)buf,&nameLen,sizeof(nameLen),pos,bufLen);
	CopyDataToBuf((char *)buf,pPet->name.c_str(),nameLen,pos,bufLen);
	CopyDataToBuf((char *)buf, &pPet->xiuLianLevel, sizeof(pPet->xiuLianLevel), pos, bufLen);

	uint8 xSize = pPet->curXiuLianCnts.size();
	CopyDataToBuf((char *)buf, &xSize, sizeof(xSize), pos, bufLen);
	for (U8tU16MapIt xit = pPet->curXiuLianCnts.begin(); xit != pPet->curXiuLianCnts.end(); ++xit)
	{
		CopyDataToBuf((char *)buf, &xit->first, sizeof(xit->first), pos, bufLen);
		CopyDataToBuf((char *)buf, &xit->second, sizeof(xit->second), pos, bufLen);
	}
	return pos;
}

void SendSysInfo(CUser *pUser,const char *info)
{
	if(pUser == NULL)
		return;

	CNetMessage msg;
	msg.SetType(PRO_SYS_INFO);
	msg<<info;
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void SendPKNotice(CUser *pUser)
{
	if(pUser == NULL)
		return;
	if(pUser->HaveBitSet(594))
		return;
	const char *pInfo = LANGUAGE_SSJ_0215;
	CNetMessage msg;
	msg.SetType(MSG_PK_NOTICE);
	msg<<(uint8)1<<pInfo;
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

// 发右下角的系统信息
void SendSysInfoRD(CUser *pUser,const char *info)
{
	if (pUser == NULL)
		return;

	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_SYS_INFO_RIGHT_DOWN);
	msg<<info;
	sock.SendMsg(pUser->GetSock(),msg);
}

// 发送系统信息，战斗后显示
void SendSysInfoFightEnd(CUser *pUser,const char *info)
{
	if (pUser == NULL)
		return;

	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_FIGHT_END_MSG);
	msg<<info;
	sock.SendMsg(pUser->GetSock(),msg);
}

// 发送通知
void SendSysNotice(CUser *pUser, uint8 op/* = 1*/)
{
	if (pUser == NULL)
		return;

	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_SERVER_NOTICE);
	msg << op;
	sock.SendMsg(pUser->GetSock(), msg);
}


void SendPopMsg(CUser *pUser,const char *info)
{
	if ((pUser == NULL) || (info == NULL))
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_SYS_POP_MSG);
	msg<<info;
	sock.SendMsg(pUser->GetSock(),msg);
}

void SendSysChannelMsg(CUser *pUser,const char *info)
{
	if ((pUser == NULL) || (info == NULL))
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(PRO_MSG_CHAT);
	msg<<(uint8)0<<0<<LANGUAGE_TRANSFORM_196<<(uint8)0<<info;
	sock.SendMsg(pUser->GetSock(),msg);
}

void SendUserPos(CUser *pUser)
{
	if (pUser == NULL)
		return;
	SyncUserScenePos(pUser,pUser->GetX(),pUser->GetY(),pUser->GetFace());
}

void SendUserPos(CUser *pUser,list<uint32> &userList)
{
	if(pUser == NULL || userList.empty())
		return;

	CNetMessage msg;
	msg.SetType(PRO_SYNC_POS);
	msg<<pUser->GetRoleId()<<pUser->GetX()<<pUser->GetY()<<pUser->GetFace();
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);

	COnlineUser &online = SingletonOnlineUser::instance();
	CSocketServer &sock = SingletonSocket::instance();
	for(list<uint32>::iterator iter = userList.begin(); iter != userList.end(); iter++)
	{
		ShareUserPtr p = online.GetUserByRoleId(*iter);
		if (p.get() == NULL)
			continue;
		if (p->GetRoleId() == pUser->GetRoleId())
			continue;
		if (!p->UserInfoIsOpen() && ((p->GetTeam() == 0) || (pUser->GetTeam() != p->GetTeam())))
			continue;
		sock.SendMsg(p->GetSock(), msg);
	}
}

int64 GetLevelUpExp(uint16 level)
{
	const int64 levelExp[] = {45000LL,60000LL,75000LL,90000LL,105000LL,120000LL,135000LL,150000LL,165000LL,180000LL,195000LL,210000LL,225000LL,
		240000LL,255000LL,270000LL,285000LL,300000LL,315000LL,330000LL,345000LL,360000LL,375000LL,390000LL,405000LL,420000LL,435000LL,450000LL,
		465000LL,520000LL,503500LL,510000LL,525000LL,537500LL,550000LL,570000LL,610000LL,615000LL,620000LL,1102500LL,1157000LL,1709000LL,2280000LL,
		3000000LL,3290000LL,3360000LL,1746495LL,1822500LL,1858150LL,1932800LL,1969200LL,2005600LL,2042000LL,3688320LL,2744700LL,2900550LL,2949525LL,
		2998500LL,3047475LL,4540750LL,3585510LL,3641280LL,3697050LL,3752820LL,5366140LL,4496440LL,4561270LL,4626100LL,6668710LL,5758240LL,5836660LL,
		8660840LL,5993500LL,6071920LL,9004820LL,16871600LL,25033200LL,33392000LL,41948000LL,50701200LL,32534250LL,48748500LL,65332500LL,82286250LL,
		99609750LL,67596000LL,101858250LL,136860000LL,172601250LL,209082000LL,106355250LL,160514250LL,215782500LL,272160000LL,329646750LL,
		148812000LL,224716500LL,302100000LL,380962500LL,461304000LL};

	uint16 maxLevel = sizeof(levelExp)/sizeof(levelExp[0]);
	if (level >= maxLevel)
		return levelExp[maxLevel-1];
	return levelExp[level-1];
}

int64 GetPetLevelUpExp(uint16 level)
{
	const int64 levelExp[] = {28,75,92,131,198,305,456,663,932,1274,1694,2203,2808,3519,4342,5289,6364,7579,8940,10458,12138,13991,16024,18247,20666,23293,26132,29195,32488,36022,39802,43839,48140,52715,57570,62717,68160,73911,79976,86366,93086,100147,107556,115323,123456,138387,154278,171155,189047,207979,227981,249081,271301,294674,319226,344983,371974,400226,429766,460621,492819,526388,561355,597746,635601,779675,931750,1092004,1260611,1437748,1623592,1818317,2022101,2235121,2457550,2689565,2931343,3183061,3444894,3717018,3999608,4620000,5390000,6230000,7000000,8400000,9800000,11200000,13300000,15400000,18200000,21000000,24500000,28700000,33600000,39200000,45500000,52500000,60900000,70000000,84000000,98000000,112000000,133000000,154000000,182000000,210000000,245000000,287000000,336000000,392000000,455000000,525000000,609000000,700000000,840000000,980000000,1120000000LL,1330000000LL,1540000000LL,1820000000LL,2100000000LL,2450000000LL,2870000000LL,3360000000LL,3920000000LL,4550000000LL,5250000000LL,6090000000LL,7000000000LL};
	uint16 maxLevel = sizeof(levelExp)/sizeof(levelExp[0]);
	if (level >= maxLevel)
		return levelExp[maxLevel-1];
	return levelExp[level-1];
}

bool ReadSkillConfig()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if ((pDb != NULL) && (pDb->Query("select id,name,learnLevel,des,xiang from skill order by id asc")))
	{
		char **row;
		while ((row = pDb->GetRow()) != NULL)
		{
			SkillInfoNode temp;
			temp.id = (uint16)atoi(row[0]);
			temp.learnLevel = (uint16)atoi(row[2]);
			temp.name = row[1];
			temp.desc = row[3];
			temp.xiang = (uint8)atoi(row[4]);
			skillInfoListMap.insert(make_pair((uint16)atoi(row[0]),temp));
		}
		return true;
	}
	return false;
}

bool HuoDongExpInfo()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	//					0	  1	   2   3	4	  5   6		7	8	 9	  10	11	  12	13	  14	15	  16	17	  18	19	   20	 21	  22	23	   24
	string sql("select type,exp1,exp2,exp3,exp4,exp5,exp6,exp7,exp8,exp9,exp10,exp11,exp12,exp13,exp14,exp15,exp16,exp17,exp18,exp19,exp20,exp21,exp22,exp23,exp24,"\
		"exp25,exp26,exp27,exp28,exp29,exp30,exp31,exp32,exp33,exp34,exp35,exp36,exp37,exp38,exp39,exp40,exp41,exp42,exp43,exp44,exp45,exp46,exp47,"\
		"exp48,exp49,exp50,exp51,exp52,exp53,exp54,exp55,exp56,exp57,exp58,exp59,exp60,exp61,exp62,exp63,exp64,exp65,exp66,exp67,exp68,exp69,exp70,"\
		"exp71,exp72,exp73,exp74,exp75,exp76,exp77,exp78,exp79,exp80,exp81,exp82,exp83,exp84,exp85,exp86,exp87,exp88,exp89,exp90,exp91,exp92,exp93,"\
		"exp94,exp95,exp96,exp97,exp98,exp99,exp100,exp101,exp102,exp103,exp104,exp105,exp106,exp107,exp108,exp109,exp110,exp111,exp112,exp113,exp114,"\
		"exp115,exp116,exp117,exp118,exp119,exp120,exp121,exp122,exp123,exp124,exp125,exp126,exp127,exp128,exp129,exp130 from huodong_exp order by type asc");

	if((pDb != NULL) && (pDb->Query(sql.c_str())))
	{
		char **row;
		while((row = pDb->GetRow()) != NULL)
		{
			HuoDongAddExpInfo temp;
			temp.type = (uint8)atoi(row[0]);
			for(uint8 i=0;i < HuoDongAddExpInfo::ExpMaxNum;i++)
				temp.expRatio[i] = atof(row[i+1]);
			SingletonHuoDongExpManager::instance().AddHuoDongExpNode(temp);
		}
		return true;
	}
	return false;
}

bool ReadMonsterDistribution()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	//							0		1 		2		  3			4
	string sql("select scene_id,monster_id,radius,findPath_x,findPath_y from monster_distribution order by scene_id,monster_id asc");
	if((pDb != NULL) && (pDb->Query(sql.c_str())))
	{
		char **row = NULL;
		while((row = pDb->GetRow()) != NULL)
		{
			SMonsterDistribution *pVMonster = new SMonsterDistribution();
			pVMonster->scene_id = (uint16)atoi(row[0]);
			pVMonster->monster_id = (uint16)atoi(row[1]);
			pVMonster->radius = (uint16)atoi(row[2]);
			pVMonster->findPath_x = (uint16)atoi(row[3]);
			pVMonster->findPath_y = (uint16)atoi(row[4]);
			MonsterDistributionList.push_back(pVMonster);
		}
		return true;
	}
	return false;
}

int GetMonsterFindPathSidById(int monsterId)
{
	for(uint16 i=0;i < MonsterDistributionList.size();i++)
	{
		if(MonsterDistributionList[i]->monster_id == (uint16)monsterId)
			return (int)(MonsterDistributionList[i]->scene_id);
	}
	return 0;
}

bool GetMonsterFindPathPosById(uint16 monsterId,uint16 &x,uint16 &y)
{
	for(uint16 i=0;i < MonsterDistributionList.size();i++)
	{
		if(MonsterDistributionList[i]->monster_id == monsterId)
		{
			x = MonsterDistributionList[i]->findPath_x;
			y = MonsterDistributionList[i]->findPath_y;
			return true;
		}
	}
	return false;
}

void ClearMonsterDistributionList()
{
	for(uint16 i=0;i < MonsterDistributionList.size();i++)
	{
		if(MonsterDistributionList[i] != NULL)
		{
			delete MonsterDistributionList[i];
			MonsterDistributionList[i] = NULL;
		}
	}
	MonsterDistributionList.clear();
}

bool ReadItem()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	const char* splitChar = "[,]";

	//                  0   1     2    3     4        5     6          7          8        9          10         11       12         13       14
	string sql("select id, name, des, pic, quality, type, use_type, sub_value, limit_lv, limit_time, sell, sort_priority, jiage, item_from, script from item");
	if ((pDb != NULL) && pDb->Query(sql.c_str()))
	{
		char **row = NULL;
		while ((row = pDb->GetRow()) != NULL)
		{
			SItemTemplate *pItem = new SItemTemplate;
			pItem->quality = atoi(row[4]);
			pItem->useType = atoi(row[6]);
			pItem->level = atoi(row[8]);
			pItem->id = atoi(row[0]);
			pItem->type = atoi(row[5]);
			if (pItem->type == 999)
				continue;
			pItem->pic = atoi(row[3]);
			pItem->jiage = atoi(row[12]);
			pItem->sortPriority = atoi(row[11]);
			pItem->name = row[1];
			pItem->describe = row[2];
			vector<string> strs;
			strs.clear();
			if (pItem->type == 6)
			{
				if (SplitString(row[7], strs, splitChar) && strs.size() % 3 == 0)
				{
					for (uint8 i = 0; i < strs.size(); i += 3)
					{
						SAwardData ad;
						ad.type = atoi(strs[i].c_str());
						ad.typeId = atoi(strs[i + 1].c_str());
						ad.num = atoi(strs[i + 2].c_str());
						pItem->subAward.push_back(ad);
					}
				}
			}
			else
			{
				if (SplitString(row[7], strs, splitChar) && strs.size() % 2 == 0)
				{
					for (uint8 i = 0; i < strs.size(); i += 2)
					{
						uint32 type = atoi(strs[i].c_str());
						uint32 num = atoi(strs[i + 1].c_str());
						pItem->subVec.push_back(make_pair(type, num));

						if (pItem->type == 3 || pItem->type == 4)
							pItem->subValue = num;
					}
				}
			}

			strs.clear();
			if (SplitString(row[9], strs, ',') && strs.size() == 2)
			{
				pItem->activityId = atoi(strs[0].c_str());
				pItem->limitTime = atoi(strs[1].c_str());
			}
			
			uint16 script = atoi(row[14]);
			if(script != 0)
			{
				pItem->pScript = new CCallScript(script);
			}

			SingletonItemManager::instance().AddItem(pItem);
		}

		// The local minimal database can contain an older, incomplete item table.
		// Fill only missing templates from the shipped JSON so shop rewards are
		// actually added and their acquisition tips never show "(nil)".
		if(gyu::util::CIniFile::GetValue("local_test","server",gConfigFile) == "1")
		{
			const char* fields[] = { "id", "name", "des", "pic", "quality", "type", "use_type", "sub_value", "limit_lv", "limit_time", "sell", "sort_priority", "jiage", "item_from", "script" };
			const int types[] = { EJPT_INT, EJPT_STRING, EJPT_STRING, EJPT_INT, EJPT_INT, EJPT_INT, EJPT_INT, EJPT_ARRAY, EJPT_INT, EJPT_ARRAY, EJPT_INT, EJPT_INT, EJPT_INT, EJPT_STRING, EJPT_INT };
			rapidjson::Document d;
			rapidjson::Value items;
			if(LoadJosnValue("item.json", fields, types, sizeof(types) / sizeof(types[0]), d, items))
			{
				uint32 addCount = 0;
				for(rapidjson::SizeType i = 0; i < items.Size(); ++i)
				{
					const rapidjson::Value& data = items[i];
					uint16 itemId = (uint16)data["id"].GetInt();
					if(SingletonItemManager::instance().GetItem(itemId) != NULL)
						continue;

					SItemTemplate *pItem = new SItemTemplate;
					pItem->id = itemId;
					pItem->name = data["name"].GetString();
					pItem->describe = data["des"].GetString();
					pItem->pic = data["pic"].GetInt();
					pItem->quality = data["quality"].GetInt();
					pItem->type = data["type"].GetInt();
					pItem->useType = data["use_type"].GetInt();
					pItem->level = data["limit_lv"].GetInt();
					pItem->sortPriority = data["sort_priority"].GetInt();
					pItem->jiage = data["jiage"].GetInt();

					const rapidjson::Value& subValues = data["sub_value"];
					for(rapidjson::SizeType si = 0; si < subValues.Size(); ++si)
					{
						if(!subValues[si].IsArray())
							continue;
						if(pItem->type == 6 && subValues[si].Size() >= 3)
						{
							SAwardData ad;
							ad.type = subValues[si][0].GetInt();
							ad.typeId = subValues[si][1].GetInt();
							ad.num = subValues[si][2].GetInt();
							pItem->subAward.push_back(ad);
						}
						else if(subValues[si].Size() >= 2)
						{
							uint32 subType = subValues[si][0].GetInt();
							uint32 subNum = subValues[si][1].GetInt();
							pItem->subVec.push_back(make_pair(subType, subNum));
							if(pItem->type == 3 || pItem->type == 4)
								pItem->subValue = subNum;
						}
					}

					const rapidjson::Value& limitTime = data["limit_time"];
					if(limitTime.Size() >= 2)
					{
						pItem->activityId = limitTime[0].GetInt();
						pItem->limitTime = limitTime[1].GetInt();
					}
					uint16 script = data["script"].GetInt();
					if(script != 0)
						pItem->pScript = new CCallScript(script);

					SingletonItemManager::instance().AddItem(pItem);
					++addCount;
				}
				cout << "[local] ReadItem: filled " << addCount << " missing templates from item.json" << endl;
			}
		}
		return true;
	}
	return false;
}


struct SMissonData
{
	SMissonData():type(0),nextId(0){}
	uint8 type;	// 1主线3捉鬼5支线10日常
	uint16 nextId;
	string name;
};

const char *GetCMissionName(uint16 id)
{
	SMissionConfig *pMiss = SingletonCMissionManager::instance().GetMissionCfg(id);
	if(pMiss == NULL)
		return "";
	return pMiss->name.c_str();
}


uint8 GetQuality(int fen,uint8 num)
{
	if(fen == 0 || num == 0)
		return 0;
	int max = 1000*num;
	if(fen < (int)(max*0.05))
		return 0;
	else if(fen < (int)(max*0.125))
		return 1;
	else if(fen < (int)(max*0.225))
		return 2;
	else if(fen < (int)(max*0.35))
		return 3;
	else if(fen < (int)(max*0.5))
		return 4;
	else if(fen < (int)(max*0.625))
		return 5;
	else if(fen < (int)(max*0.75))
		return 6;
	else
		return 7;
}

bool MakeItemInfo(SItemInstance *item,CNetMessage &msg)
{
	if(item->tmplId == 0 || item->num == 0)
	{
		msg<<(uint16)0;
		return true;
	}
	SItemTemplate *pItem = SingletonItemManager::instance().GetItem(item->tmplId);
	if(pItem == NULL)
	{
		msg<<(uint16)0;
		return true;
	}

	msg<<item->tmplId<<item->num<<pItem->type;
	//if(pItem->type <= EIT_WuQi_6 || pItem->type >= EIT_TouKui_1)	// 装备
	//{
	//	uint8 qianghuaLevel = item->level;
	//	msg<<qianghuaLevel;

	//	uint8 num = 0;
	//	uint16 pos = msg.GetDataLen();
	//	msg<<num;
	//	for (uint8 i = 0; i < sizeof(item->addAttrType)/sizeof(item->addAttrType[0]); i++)
	//	{
	//		num++;
	//		msg<<item->addAttrType[i]<<item->addAttrVal[i]<<item->addAttrStar[i];
	//	}
	//	msg.WriteData(pos,&num,sizeof(num));

	//	uint8 xilianTypeNum = sizeof(item->xilianSaveType)/sizeof(item->xilianSaveType[0]);
	//	msg<<xilianTypeNum;
	//	for(uint8 i=0;i < xilianTypeNum;i++)
	//	{
	//		msg<<item->xilianType[i]<<item->xilianVal[i]<<item->xilianStar[i];
	//		msg<<item->xilianSaveType[i]<<item->xilianSaveVal[i]<<item->xilianSaveStar[i];
	//	}
	//}
	if (item->tmplId == 2441 || item->tmplId == 2442)
	{
		msg << item->extData;
	}
	return true;
}

static time_t sSysTime;
static time_t msSysTime;
static int g_yday = -1;	// 0~365
static int g_wday = -1;	// 0~6 周日~周一
static int g_year = -1;	// 1900开始
static int g_month = -1;// 0~11 1~12月
static int g_mday = -1;	// 1~31
static int g_hour = -1;	// 0~23
static int g_minute = -1;// 0~59
static int g_second = -1;// 0~59

void SetSysYDay(int t)
{
	g_yday = t;
}

int GetSysYDay()
{
	return g_yday;
}

void SetSysWDay(int t)
{
	g_wday = t;
}

int GetSysWDay()
{
	return g_wday;
}

void SetSysYear(int t)
{
	g_year = t;
}

int GetSysYear()
{
	return g_year;
}

void SetSysMonth(int t)
{
	g_month = t;
}

int GetSysMonth()
{
	return g_month;
}

void SetSysMDay(int t)
{
	g_mday = t;
}

int GetSysMDay()
{
	return g_mday;
}

void SetSysHour(int t)
{
	g_hour = t;
}

int GetSysHour()
{
	return g_hour;
}

void SetSysMinute(int t)
{
	g_minute = t;
}

int GetSysMinute()
{
	return g_minute;
}

void SetSysSecond(int t)
{
	g_second = t;
}

int GetSysSecond()
{
	return g_second;
}

void SetSysTime(time_t t)
{
	sSysTime = t;
}

time_t GetSysTime()
{
	return sSysTime;
}

void SetSysTimeMs(time_t t)
{
	msSysTime = t;
}

time_t GetSysTimeMs()
{
	return msSysTime;
}

uint32_t GetTodayZero()
{
	time_t now = time(0);
	tm* tmNow = localtime(&now);
	tmNow->tm_hour = 0;
	tmNow->tm_min = 0;
	tmNow->tm_sec = 0;
	return mktime(tmNow);
}

uint32_t GetTomorrow()
{
	return GetTodayZero() + 86400;
}

uint32_t GetTomorrowMillsec()
{
	time_t now = time(0);
	tm* tmNow = localtime(&now);
	return (23 - tmNow->tm_hour) * 3600 + (59 - tmNow->tm_min) * 60 + 69 - tmNow->tm_sec + 1;
}

uint32_t GetTodayMillsec()
{
	time_t now = time(0);
	tm* tmNow = localtime(&now);
	tmNow->tm_hour = 0;
	tmNow->tm_min = 0;
	tmNow->tm_sec = 0;
	time_t tomorrow = mktime(tmNow);
	return static_cast<uint32_t>(tomorrow - now + 1);
}


static boost::mutex m_mutex;

#if defined(_WIN32)
static int LocalCopyConvert(char *to,size_t toLen,char *from,size_t fromLen)
{
	if(to == NULL || from == NULL || toLen == 0)
		return 0;
	size_t copyLen = fromLen < toLen ? fromLen : toLen;
	memcpy(to, from, copyLen);
	return (int)copyLen;
}
#endif

int UTF8ToUnicode(char *to,size_t toLen,char *from,size_t fromLen)
{
#if defined(_WIN32)
	return LocalCopyConvert(to, toLen, from, fromLen);
#else
	static iconv_t sCdGbkUnicode = iconv_open("UNICODELITTLE","UTF-8");
	boost::mutex::scoped_lock lk(m_mutex);
	size_t oldToLen = toLen;
	iconv(sCdGbkUnicode,&from,&fromLen,&to,&toLen);
	return (oldToLen-toLen);
#endif
}

int UnicodeToUTF8(char *to,size_t toLen,char *from,size_t fromLen)
{
#if defined(_WIN32)
	return LocalCopyConvert(to, toLen, from, fromLen);
#else
	static iconv_t sCdUnicodeGbk = iconv_open("UTF-8","UNICODELITTLE");
	boost::mutex::scoped_lock lk(m_mutex);
	size_t oldToLen = toLen;
	iconv(sCdUnicodeGbk,&from,&fromLen,&to,&toLen);
	return (oldToLen-toLen);
#endif
}

int GbkToUnicode(char *to,size_t toLen,char *from,size_t fromLen)
{
#if defined(_WIN32)
	return LocalCopyConvert(to, toLen, from, fromLen);
#else
	static iconv_t sCdGbkUnicode = iconv_open("UNICODELITTLE","GBK");
	boost::mutex::scoped_lock lk(m_mutex);
	size_t oldToLen = toLen;
	iconv(sCdGbkUnicode,&from,&fromLen,&to,&toLen);
	return (oldToLen-toLen);
#endif
}

int UnicodeToGbk(char *to,size_t toLen,char *from,size_t fromLen)
{
#if defined(_WIN32)
	return LocalCopyConvert(to, toLen, from, fromLen);
#else
	static iconv_t sCdUnicodeGbk = iconv_open("GBK","UNICODELITTLE");
	boost::mutex::scoped_lock lk(m_mutex);
	size_t oldToLen = toLen;
	iconv(sCdUnicodeGbk,&from,&fromLen,&to,&toLen);
	return (oldToLen-toLen);
#endif
}

int GbkToUTF8(char *to,size_t toLen,char *from,size_t fromLen)
{
#if defined(_WIN32)
	return LocalCopyConvert(to, toLen, from, fromLen);
#else
	static iconv_t sCdGbkUnicode = iconv_open("UTF-8","GBK");
	boost::mutex::scoped_lock lk(m_mutex);
	size_t oldToLen = toLen;
	iconv(sCdGbkUnicode,&from,&fromLen,&to,&toLen);
	return (oldToLen-toLen);
#endif
}

int UTF8ToGbk(char *to,size_t toLen,char *from,size_t fromLen)
{
#if defined(_WIN32)
	return LocalCopyConvert(to, toLen, from, fromLen);
#else
	static iconv_t sCdUnicodeGbk = iconv_open("GBK","UTF-8");
	boost::mutex::scoped_lock lk(m_mutex);
	size_t oldToLen = toLen;
	iconv(sCdUnicodeGbk,&from,&fromLen,&to,&toLen);
	return (oldToLen-toLen);
#endif
}

bool ExchangeIgnoreCharacter(string &str)
{
	if(str.empty())
		return false;
	
	static vector<string> ignore;
	static uint32 lastLoadTime = 0;
	const uint32 LOAD_TIME = 60*5;
	uint32 curTime = GetSysTime();
	if(curTime - lastLoadTime > LOAD_TIME)
	{
		lastLoadTime = curTime;
		
		CDatabaseSql *pLogin = GetLoginDb();
		if (pLogin != NULL)
		{
			char sql[256];
			snprintf(sql,sizeof(sql),"select str from chat_ignore_word");
			if(pLogin->Query(sql))
			{
				char **row = NULL;
				ignore.clear();
				while((row = pLogin->GetRow()) != NULL)
				{
					ignore.push_back(row[0]);
				}
			}
		}
	}

	if(ignore.empty())
		return false;
	char buf[1024];
	bool isChange = false;
	snprintf(buf,sizeof(buf),"%s",str.c_str());
	char *p = buf;
	for(uint32 i=0; i < ignore.size();i++)
	{
		p = buf;
		int len = ignore[i].size();
		while((p = strstr(p,ignore[i].c_str())) != NULL)
		{
			isChange = true;
			for(int j = 0;j < len;j++)
			{
				if(*p != '\0')
					*p++ = '*';
				else
					break;
			}
		}
	}
	if(isChange)
		str = buf;
	return isChange;
}

bool HaveIgnoreCharacter(string &str)
{
	const char *IgnoreList[] = {LANGUAGE_TRANSFORM_2856,LANGUAGE_TRANSFORM_2857,LANGUAGE_TRANSFORM_2858,LANGUAGE_TRANSFORM_2859,LANGUAGE_TRANSFORM_2860,
		LANGUAGE_TRANSFORM_2861,LANGUAGE_TRANSFORM_2862,LANGUAGE_TRANSFORM_2863,LANGUAGE_TRANSFORM_2864,
		LANGUAGE_TRANSFORM_2867,LANGUAGE_TRANSFORM_2868,LANGUAGE_TRANSFORM_2869,LANGUAGE_TRANSFORM_2870,LANGUAGE_TRANSFORM_2871,LANGUAGE_TRANSFORM_2872,
		LANGUAGE_TRANSFORM_2873,LANGUAGE_TRANSFORM_2874,LANGUAGE_TRANSFORM_2875,LANGUAGE_TRANSFORM_2876,LANGUAGE_TRANSFORM_2877,LANGUAGE_TRANSFORM_2878,
		LANGUAGE_TRANSFORM_2879,LANGUAGE_TRANSFORM_2880,LANGUAGE_TRANSFORM_2881,LANGUAGE_TRANSFORM_2882,LANGUAGE_TRANSFORM_2883,LANGUAGE_TRANSFORM_2884,
		LANGUAGE_TRANSFORM_2885,LANGUAGE_TRANSFORM_2886,LANGUAGE_TRANSFORM_2887,LANGUAGE_TRANSFORM_2888,LANGUAGE_TRANSFORM_2889,LANGUAGE_TRANSFORM_2890,
		LANGUAGE_TRANSFORM_2891,LANGUAGE_TRANSFORM_2892,LANGUAGE_TRANSFORM_2893,LANGUAGE_TRANSFORM_2894,LANGUAGE_TRANSFORM_2895,LANGUAGE_TRANSFORM_2896,
		LANGUAGE_TRANSFORM_2897,LANGUAGE_TRANSFORM_2898,LANGUAGE_TRANSFORM_2899,LANGUAGE_TRANSFORM_2900,LANGUAGE_TRANSFORM_2901,LANGUAGE_TRANSFORM_2902,
		LANGUAGE_TRANSFORM_2903,LANGUAGE_TRANSFORM_2904,LANGUAGE_TRANSFORM_2905,LANGUAGE_TRANSFORM_2906,LANGUAGE_TRANSFORM_2907,LANGUAGE_TRANSFORM_2908,
		LANGUAGE_TRANSFORM_2909,LANGUAGE_TRANSFORM_2910,LANGUAGE_TRANSFORM_2911,LANGUAGE_TRANSFORM_2912,LANGUAGE_TRANSFORM_2913,LANGUAGE_TRANSFORM_2914,
		LANGUAGE_TRANSFORM_2915,LANGUAGE_TRANSFORM_2916,LANGUAGE_TRANSFORM_2917,LANGUAGE_TRANSFORM_2918,LANGUAGE_TRANSFORM_2919,LANGUAGE_TRANSFORM_2920,
		LANGUAGE_TRANSFORM_2921,LANGUAGE_TRANSFORM_2922,LANGUAGE_TRANSFORM_2923,LANGUAGE_TRANSFORM_2924,LANGUAGE_TRANSFORM_2925,LANGUAGE_TRANSFORM_2926,
		LANGUAGE_TRANSFORM_2927,LANGUAGE_TRANSFORM_2928,LANGUAGE_TRANSFORM_2929,LANGUAGE_TRANSFORM_2930,LANGUAGE_TRANSFORM_2931,LANGUAGE_TRANSFORM_2932,
		LANGUAGE_TRANSFORM_2933,LANGUAGE_TRANSFORM_2934,LANGUAGE_TRANSFORM_2935,LANGUAGE_TRANSFORM_2936,LANGUAGE_TRANSFORM_2937,LANGUAGE_TRANSFORM_2938,
		LANGUAGE_TRANSFORM_2939,LANGUAGE_TRANSFORM_2940,LANGUAGE_TRANSFORM_2941,LANGUAGE_TRANSFORM_2942,LANGUAGE_TRANSFORM_2943,LANGUAGE_TRANSFORM_2944,
		LANGUAGE_TRANSFORM_2945,LANGUAGE_TRANSFORM_2946,LANGUAGE_TRANSFORM_2947,LANGUAGE_TRANSFORM_2948,LANGUAGE_TRANSFORM_2949,LANGUAGE_TRANSFORM_2950,
		LANGUAGE_TRANSFORM_2951,LANGUAGE_TRANSFORM_2952,LANGUAGE_TRANSFORM_2953,LANGUAGE_TRANSFORM_2954,LANGUAGE_TRANSFORM_2955,LANGUAGE_TRANSFORM_2956,
		LANGUAGE_TRANSFORM_2957,
		};
	const char *p = str.c_str();
	int num = sizeof(IgnoreList)/sizeof(char*);
	for(int i = 0; i < num; i++)
	{
		if(strstr(p,IgnoreList[i]) != NULL)
			return true;
	}

	const int bitLimit = 5;
	int bitNum = 0;
	while(*p != 0)
	{
		if(*p >= '0' && *p <= '9')
		{
			bitNum++;
			if(bitNum >= bitLimit)
				return true;
		}
		else
			bitNum = 0;
		p++;
	}
	return false;
}


const char *pIllegalString[] = {LANGUAGE_TRANSFORM_198,	LANGUAGE_TRANSFORM_199,	LANGUAGE_TRANSFORM_200,	LANGUAGE_TRANSFORM_201,	LANGUAGE_TRANSFORM_202,
	LANGUAGE_TRANSFORM_203,	LANGUAGE_TRANSFORM_204,	LANGUAGE_TRANSFORM_205,	LANGUAGE_TRANSFORM_206,	LANGUAGE_TRANSFORM_207,
	"md","modao",".net","www","WWW","MD","MODAO"};

bool IllegalStr(string &str)
{
	const char *p = str.c_str();
	for(uint32 i = 0; i < strlen(p); i++)
	{
		if((p[i] == '&') || (p[i] == '\'') || (p[i] == '\"') || (p[i] == '\\') || (p[i] == '/') || (p[i] == '|') || (p[i] == '[')
			|| (p[i] == ']') || (p[i] == '#') || (p[i] == ',') || (p[i] == ';') || (p[i] == '@') || (p[i] == '%') || (p[i] == ' '))
		{
			str.clear();
			str.append(1,p[i]);
			return true;
		}
		else if(((p[i] == 'g') || (p[i] == 'G')) && ((p[i+1] == 'm') || (p[i+1] == 'M')))
		{
			str.clear();
			str.append(1,p[i]);
			str.append(1,p[i+1]);
			return true;
		}
	}

	int num = sizeof(pIllegalString)/sizeof(char*);
	for (int i = 0; i < num; i++)
	{
		if (strstr(p,pIllegalString[i]) != NULL)
		{
			str = pIllegalString[i];
			return true;
		}
	}
	return false;
}

CCallScript *GetScript()
{
	static CCallScript *pScript = NULL;
	if (pScript == NULL)
	{
		pScript = new CCallScript(10000);
	}
	return pScript;
}

CCallScript *GetScript30000()
{
	static CCallScript *pScript = NULL;
	if (pScript == NULL)
	{
		pScript = new CCallScript(30000);
	}
	return pScript;
}

CCallScript *GetScript176()
{
	static CCallScript *pScript = NULL;
	if (pScript == NULL)
	{
		pScript = new CCallScript(176);
	}
	return pScript;
}

CCallScript *GetScript235()
{
	static CCallScript *pScript = NULL;
	if (pScript == NULL)
	{
		pScript = new CCallScript(235);
	}
	return pScript;
}

CCallScript *GetScript250()
{
	static CCallScript *pScript = NULL;
	if (pScript == NULL)
	{
		pScript = new CCallScript(250);
	}
	return pScript;
}


const char *GetScriptDir()
{
	static string scriptDir;
	if (scriptDir.size() <= 0)
	{
		scriptDir = gyu::util::CIniFile::GetValue("script_dir","server",gConfigFile);
	}
	return scriptDir.c_str();
}

static void SendNianShouInfo(CSocketServer *pSock,CNetMessage *pMsg,CUser *pUser)
{
	pSock->SendMsg(pUser->GetSock(),*pMsg);
}

static void SendSystemMailInfo(CSocketServer *pSock,const char* message,CUser *pUser)
{
	SendSystemMail(pUser->GetRoleId(),message);
}

void SendMsgToAllUser(CNetMessage &msg)
{
	CSocketServer &sock = SingletonSocket::instance();
	SingletonOnlineUser::instance().ForEachUser(boost::bind(SendNianShouInfo,&sock,&msg,_1));
}

void SendSceneMsg(CNetMessage &msg,CScene *pScene)
{
	CSocketServer &sock = SingletonSocket::instance();
	COnlineUser   &onlineUser =  SingletonOnlineUser::instance();
	if (pScene != NULL)
	{
		list<uint32> userList;
		pScene->GetUserList(userList);
		list<uint32>::iterator iter = userList.begin();
		for (; iter != userList.end(); iter++)
		{
			ShareUserPtr p = onlineUser.GetUserByRoleId(*iter);
			if (p.get() != NULL)
			{
				sock.SendMsg(p->GetSock(),msg);
			}
		}
	}
}

void SendSceneMsg(CNetMessage &msg,int sceneId)
{
	CSceneManager &scene = SingletonSceneManager::instance();
	CSocketServer &sock = SingletonSocket::instance();
	COnlineUser   &onlineUser =  SingletonOnlineUser::instance();

	CScene *pScene = scene.FindScene(sceneId);
	if (pScene != NULL)
	{
		list<uint32> userList;
		pScene->GetUserList(userList);
		list<uint32>::iterator iter = userList.begin();
		for (; iter != userList.end(); iter++)
		{
			ShareUserPtr p = onlineUser.GetUserByRoleId(*iter);
			if (p.get() != NULL)
			{
				sock.SendMsg(p->GetSock(),msg);
			}
		}
	}
}

void SysInfoToAllUser(const char *msg,bool checkTime)
{
	const int TIME_GAP = 15;
	static time_t lastTime = 0;
	if(msg == NULL)
		return;
	time_t t = GetSysTime();
	if(lastTime == 0)
		lastTime = t;
	bool send = false;
	if(!checkTime)
	{
		lastTime = t;
		send = true;
	}
	else
	{
		if(t - lastTime >= (time_t)TIME_GAP)
		{
			lastTime = t;
			send = true;
		}
	}
	if(!send)
		return;

	CNetMessage sysMsg;
	sysMsg.SetType(PRO_SYSTEM_INFO);
	sysMsg<<msg;
	
	CSocketServer &sock = SingletonSocket::instance();
	SingletonOnlineUser::instance().ForEachUser(boost::bind(SendNianShouInfo,&sock,&sysMsg,_1));
}

void MsgForwardToServers(CNetMessage &msg)
{
	CNetMessage forward;
	forward.SetType(MSG_SERVER_FORWARD);
	forward<<GetSelfZoneId()<<msg;
	SingletonSocket::instance().SendServerMsg(EST_LONG, forward);
}

// 滚动条
void SysInfoToAllUserGunDong(CUser *pUser,const char *str)
{
	if(str == NULL || pUser == NULL)
		return;
	string msg = str;
	ChatCharacterLimit(msg, 50);

#ifdef KUA_FU
	string name = pUser->GetName();
#else
	string name = GetKuaFuRoleName(pUser);
#endif
	CNetMessage sysMsg;
	sysMsg.SetType(MSG_SYSTEM_INFO);
	sysMsg<<pUser->GetRoleId()<<name<<pUser->GetVipLevel()<<pUser->GetHead()<<pUser->GetSex()<<msg;
	
	CSocketServer &sock = SingletonSocket::instance();
	SingletonOnlineUser::instance().ForEachUser(boost::bind(SendNianShouInfo,&sock,&sysMsg,_1));

	UserMsgToAllServer(pUser,msg.c_str());
}

void SysInfoToAllUserGunDong(uint32 roleId,const char *name, uint8 vipLv,uint8 xiang,uint8 sex,const char *str)
{
	if(str == NULL || roleId == 0 || name == NULL)
		return;
	string msg = str;
	ChatCharacterLimit(msg, 50);

	CNetMessage sysMsg;
	sysMsg.SetType(MSG_SYSTEM_INFO);
	sysMsg<<roleId<<name<<vipLv<<xiang<<sex<<msg;
	
	CSocketServer &sock = SingletonSocket::instance();
	SingletonOnlineUser::instance().ForEachUser(boost::bind(SendNianShouInfo,&sock,&sysMsg,_1));
}

void SysMailToAllUser (const char *message)
{
	if (message == NULL)
		return;
	CSocketServer &sock = SingletonSocket::instance();
	SingletonOnlineUser::instance().ForEachUser(boost::bind(SendSystemMailInfo,&sock,message,_1));
}

void SysMsgToAllUser(CNetMessage &msg)
{
	CSocketServer &sock = SingletonSocket::instance();
	SingletonOnlineUser::instance().ForEachUser(boost::bind(SendNianShouInfo,&sock,&msg,_1));
}

string MakeStringColor(const char *pStr,int color)
{
	string out = "";
	if(pStr != NULL && strlen(pStr) > 0)
	{
		char buf[2*1024];
		snprintf(buf,sizeof(buf)-1,"[c%d]%s[/c]",color,pStr);
		out = buf;
	}
	return out;
}

string MakeStringColor(string str,int color)
{
	string out = "";
	if(str.size() > 0)
	{
		char buf[2*1024];
		snprintf(buf,sizeof(buf)-1,"[c%d]%s[/c]",color,str.c_str());
		out = buf;
	}
	return out;
}

static bool sUpdatePetDraw = false;
void NeedUpdatePetDraw()
{
	sUpdatePetDraw = true;
}
void NotNeedUpdatePetDraw()
{
	sUpdatePetDraw = false;
}
bool isNeedUpdatePetDraw()
{
	return sUpdatePetDraw;
}

static bool sFightHuoDong = false;
void BeginFightHuoDong()
{
	sFightHuoDong = true;
}
void EndFightHuoDong()
{
	sFightHuoDong = false;
}
bool InFightHuoDong()
{
	return sFightHuoDong;
}

static int sLeftNum = 0;
int GetLeftDropNum()
{
	return sLeftNum;
}
void SetLeftDropNum(int num)
{
	sLeftNum = num;
}

static bool sInELong = false;
void BeginELong()
{
	sInELong = true;
}
void EndELong()
{
	sInELong = false;
}
bool InELong()
{
	return sInELong;
}

time_t sClearWeekTime = 0;
time_t sClearMonthTime = 0;
time_t sClearDayTime = 0;

void SetClearDayTime(time_t t)
{
	sClearDayTime = t;
}

time_t GetClearDayTime()
{
	return sClearDayTime;
}

void SetClearWeekTime(time_t t)
{
	sClearWeekTime = t;
}

time_t GetClearWeekTime()
{
	return sClearWeekTime;
}

void SetClearMonthTime(time_t t)
{
	sClearMonthTime = t;
}

time_t GetClearMonthTime()
{
	return sClearMonthTime;
}

static const char* IllegalChatMsg[] =
{
	LANGUAGE_TRANSFORM_ILLEAGLCHATMSG
};

bool IsIllegalMsg(const char *pStr)
{
	//return false;
	
	if(pStr == NULL)
		return false;

	uint16 chinesePos[100];
	memset(chinesePos,0xff,sizeof(chinesePos));
	int msgLen = (int)strlen(pStr);
	const uint8 *p = (const uint8 *)pStr;
	int chineseNum = 0;
	int i = 0;
	while(i < msgLen)
	{
		if(p[i] < 128)
		{
			i++;
			continue;
		}
		else
		{
			chinesePos[chineseNum++] = i;
			i += 2;
		}
	}

	for(i = 0; i < (int)(sizeof(IllegalChatMsg)/sizeof(IllegalChatMsg[0])); i++)
	{
		const char *pFind = strstr(pStr,IllegalChatMsg[i]);
		if(pFind != NULL)
		{
			int count = 0;
			do
			{
				for(int j = 0;j < chineseNum;j++)
				{
					if(pFind == pStr+chinesePos[j] && chinesePos[j] != 0xffff)
						return true;
				}
				pFind = strstr(pFind+1,IllegalChatMsg[i]);
				if(pFind == NULL)
					break;
				count++;
			}while(count < 100);
		}
	}
	return false;
}

void IllegalMsgDeal(string &msg)
{
	char buf[1024];
	char *p = buf;
	snprintf(buf,sizeof(buf),"%s",msg.c_str());
	for(int i = 0; i < (int)(sizeof(IllegalChatMsg)/sizeof(IllegalChatMsg[0])); i++)
	{
		if((p = strstr(buf,IllegalChatMsg[i])) != NULL)
		{
			int len = strlen(IllegalChatMsg[i]);
			for(int j = 0;j < len;j++)
			{
				if(*p != '\0')
					*p++ = '*';
				else
					break;
			}
			i--;
		}
	}
	msg.clear();
	msg = buf;
}

void SysInfoToGroupUser(int sceneGroup,const char *info)
{
	CNetMessage msg;
	msg.SetType(PRO_SYSTEM_INFO);
	msg<<info<<(uint8)0;

	CSceneManager &scene = SingletonSceneManager::instance();
	CSocketServer &sock = SingletonSocket::instance();
	COnlineUser   &onlineUser =  SingletonOnlineUser::instance();

	list<int> sceneList;
	scene.GetGroupScene(sceneGroup,sceneList);
	for (list<int>::iterator i = sceneList.begin(); i != sceneList.end(); i++)
	{
		CScene *pScene = scene.FindScene(*i);
		if (pScene == NULL)
			continue;
		list<uint32> userList;
		pScene->GetUserList(userList);
		list<uint32>::iterator iter = userList.begin();
		for (; iter != userList.end(); iter++)
		{
			ShareUserPtr p = onlineUser.GetUserByRoleId(*iter);
			if (p.get() != NULL)
			{
				sock.SendMsg(p->GetSock(),msg);
			}
		}
	}
}

void SendSysInfoToGroup(int sceneGroup,const char *info)
{
	CSceneManager &scene = SingletonSceneManager::instance();
	CSocketServer &sock = SingletonSocket::instance();
	COnlineUser   &onlineUser =  SingletonOnlineUser::instance();
	CNetMessage msg;
	msg.SetType(PRO_SYS_INFO);
	msg<<info;

	list<int> sceneList;
	scene.GetGroupScene(sceneGroup,sceneList);
	for (list<int>::iterator i = sceneList.begin(); i != sceneList.end(); i++)
	{
		CScene *pScene = scene.FindScene(*i);
		if (pScene == NULL)
			continue;
		list<uint32> userList;
		pScene->GetUserList(userList);
		list<uint32>::iterator iter = userList.begin();
		for (; iter != userList.end(); iter++)
		{
			ShareUserPtr p = onlineUser.GetUserByRoleId(*iter);
			if (p.get() != NULL)
			{
				sock.SendMsg(p->GetSock(),msg);
			}
		}
	}
}

void AddRoleExp(uint32 roleId,uint32 exp)
{
	ShareUserPtr p = SingletonOnlineUser::instance().GetUserByRoleId(roleId);
	CUser *pUser = p.get();
	if(pUser != NULL)
	{
		pUser->AddExp(exp);
	}
	else
	{
		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		if (pDb == NULL)
			return;
		char sqlBuf[256];
		snprintf(sqlBuf,sizeof(sqlBuf),"update role_info set exp=exp+%u where id=%u",exp,roleId);
		pDb->Query(sqlBuf);
	}
}

void AddTongBao(uint32 roleId,int tongbao,int type)
{
	ShareUserPtr p = SingletonOnlineUser::instance().GetUserByRoleId(roleId);
	CUser *pUser = p.get();
	if (pUser != NULL)
	{
		pUser->AddTongBao(tongbao,type);
	}
	else
	{
		vector<int> idList;
		GetServerIdList(idList);
		if(idList.empty())
			return;
		
		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		if (pDb == NULL)
			return;
		char sqlBuf[256];
		for(uint16 i=0;i < idList.size();i++)
		{
			string userTab = GetUserInfoTab(idList[i]);
			snprintf(sqlBuf,sizeof(sqlBuf),"select id from %s where role0=%u limit 1",userTab.c_str(),roleId);
			if(!pDb->Query(sqlBuf))
				return;
			if(pDb->GetRowNum() == 0)
				continue;
			char **row = pDb->GetRow();
			if(row == NULL)
				continue;
			uint32 userId = atoi(row[0]);
			if(type == 1)
			{
				snprintf(sqlBuf,sizeof(sqlBuf),"update %s set bd_money=bd_money+%d where id=%d",userTab.c_str(),tongbao,userId);
				pDb->Query(sqlBuf);
			}
			else
			{
				snprintf(sqlBuf,sizeof(sqlBuf),"update %s set money=money+%d where id=%d",userTab.c_str(),tongbao,userId);
				pDb->Query(sqlBuf);
				SaveDate(userId,1077,tongbao);
			}
			return;
		}
	}
}

uint8 GetPetSpeed(int qinmi)
{
	if (qinmi < 100000)
		return 8;
	else if (qinmi < 300000)
		return (uint8)(1.5*8);
	else
		return 16;
}

uint64 GetTime()
{
	timeval tv;
	local_gettimeofday(&tv,NULL);
	uint64 t = 1000000*tv.tv_sec;
	t += tv.tv_usec;
	return t;
}

uint64 GetMillisecond()
{
	timeval tv;
	local_gettimeofday(&tv,NULL);
	uint64 t = tv.tv_sec;
	t *= 1000;     
	t += tv.tv_usec/1000;
	return t;
}

void ToUpper(string &str)
{
	char *p = (char*)str.c_str();
	size_t len = str.size();
	for(size_t i = 0; i < len; i++)
	{
		p[i] = toupper(p[i]);
	}
}

void ToLower(string &str)
{
	char *p = (char*)str.c_str();
	size_t len = str.size();
	for(size_t i = 0; i < len; i++)
	{
		p[i] = tolower(p[i]);
	}
}


uint8 GetRoleName(uint32 id,char *name)
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if (pDb == NULL)
		return 0;
	char sql[128];
	snprintf(sql,sizeof(sql),"select name,level from role_info where id=%u",id);
	if (!pDb->Query(sql))
		return 0;
	char **row = pDb->GetRow();
	if (row == NULL)
		return 0;
	strcpy(name,row[0]);
	return atoi(row[1]);
}

uint32 GetRoleId(const char *name,uint8 &level)
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if (pDb == NULL)
		return 0;
	char sql[128];
	snprintf(sql,sizeof(sql),"select id,level from role_info where name='%s'",name);
	if (!pDb->Query(sql))
		return 0;
	char **row = pDb->GetRow();
	if (row == NULL)
		return 0;
	level = atoi(row[1]);
	return atoi(row[0]);
}

void AddMoney(uint32 roleId,int money)
{
	COnlineUser   &onlineUser =  SingletonOnlineUser::instance();
	ShareUserPtr pUser = onlineUser.GetUserByRoleId(roleId);
	CUser *p = pUser.get();
	if (p != NULL)
	{
		p->AddMoney(money);
		return;
	}
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if (pDb == NULL)
		return;
	char sql[128];
	snprintf(sql,sizeof(sql),"update role_info set money=money+%d where id=%u",money,roleId);
	pDb->Query(sql);
}

int UnHexify(unsigned char *obuf, const char *ibuf)
{
	unsigned char c, c2;
	int len = strlen(ibuf) / 2;
	assert(!(strlen(ibuf) %1)); // must be even number of bytes

	while (*ibuf != 0)
	{
		c = *ibuf++;
		if ( c >= '0' && c <= '9' )
			c -= '0';
		else if ( c >= 'a' && c <= 'f' )
			c -= 'a' - 10;
		else if ( c >= 'A' && c <= 'F' )
			c -= 'A' - 10;
		else
			return 0;

		c2 = *ibuf++;
		if ( c2 >= '0' && c2 <= '9' )
			c2 -= '0';
		else if ( c2 >= 'a' && c2 <= 'f' )
			c2 -= 'a' - 10;
		else if ( c2 >= 'A' && c2 <= 'F' )
			c2 -= 'A' - 10;
		else
			return 0;

		*obuf++ = ( c << 4 ) | c2;
	}

	return len;
}

void Hexify(unsigned char *obuf, const unsigned char *ibuf, int len)
{
	unsigned char l, h;

	while (len != 0)
	{
		h = (*ibuf) / 16;
		l = (*ibuf) % 16;

		if ( h < 10 )
			*obuf++ = '0' + h;
		else
			*obuf++ = 'a' + h - 10;

		if ( l < 10 )
			*obuf++ = '0' + l;
		else
			*obuf++ = 'a' + l - 10;

		++ibuf;
		len--;
	}
}

bool AddPackage(uint32 roleId,SItemInstance &item)
{
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	ShareUserPtr p = onlineUser.GetUserByRoleId(roleId);
	CUser *pUser = p.get();
	if (pUser != NULL)
	{
		return pUser->AddPackage(item);
	}
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if (pDb == NULL)
		return false;

	char sqlBuf[128];
	snprintf(sqlBuf,sizeof(sqlBuf),"select package from role_info where id=%u",roleId);
	if (!pDb->Query(sqlBuf))
		return false;
	char **row = pDb->GetRow();
	if (row == NULL)
		return false;

	pUser = new CUser;
	ShareUserPtr user(pUser);
	pUser->SetMaxPackageNum();
	pUser->SetPackage(row[0]);
	pUser->SetSock(-1);
	if (pUser->AddPackage(item))
	{
		string str;
		pUser->GetPackage(str);
		boost::format fmt("update role_info set package='%1%' where id=%2%");
		fmt % str.c_str() % roleId;
		pDb->Query(fmt.str().c_str());
		return true;
	}
	return false;
}

//set true set bitset,false clear bitset
void SetBitSet(uint32 roleId,uint16 bitset,bool set)
{
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	ShareUserPtr p = onlineUser.GetUserByRoleId(roleId);
	CUser *pUser = p.get();
	if (pUser != NULL)
	{
		if (set)
			pUser->SetBitSet(bitset);
		else
			pUser->ClearBitSet(bitset);
		return;
	}
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if (pDb == NULL)
		return;

	char sqlBuf[128];
	snprintf(sqlBuf,sizeof(sqlBuf),"select bitset from role_info where id=%u",roleId);
	if (!pDb->Query(sqlBuf))
		return;
	char **row = pDb->GetRow();
	if (row == NULL)
		return;

	pUser = new CUser;
	ShareUserPtr user(pUser);

	pUser->SetBitSet(row[0]);
	pUser->SetSock(-1);
	string str;
	pUser->SetBitSet(bitset);
	pUser->GetBitSet(str);
	boost::format fmt("update role_info set bitset='%1%' where id=%2%");
	fmt % str.c_str() % roleId;
	pDb->Query(fmt.str().c_str());
}

bool Compress(uint8 *pInBuf,uint32 inLen,string &compress)
{
	uLongf outLen = compressBound(inLen);
	uint8 *res = new uint8[outLen];
	int ret = compress2((Bytef*)res,(uLongf*)&outLen,(Bytef*)pInBuf,inLen,9);
	if(ret != Z_OK)
	{
		delete[] res;
		return false;
	}

	compress.resize(2*outLen);
	Hexify((uint8*)compress.c_str(),res,outLen);
	delete[] res;
	return true;
}

bool UnCompress(const char *inStr,uint8 *pOutBuf,uint32 &outLen)
{
	uint8 *str = new uint8[strlen(inStr)*2];
	uLongf len = UnHexify(str,inStr);
	uLongf oLen = outLen;
	int ret = uncompress((Bytef*)pOutBuf,(uLongf*)&oLen,(Bytef*)str,len);
	delete[] str;
	if (ret != Z_OK)
		return false;
	return true;
}

int UnCompressEx(const char *inStr, uint8 *pOutBuf, uint32 outLen)
{
	uint8 *str = new uint8[strlen(inStr) * 2];
	uLongf len = UnHexify(str, inStr);
	uLongf oLen = outLen;
	int ret = uncompress((Bytef*)pOutBuf, (uLongf*)&oLen, (Bytef*)str, len);
	delete[] str;
	if (ret != Z_OK || oLen > outLen)
	{
		cout<<">> UnCompressEx  ERROR!!!  src_outLen="<<outLen<<",  outLen="<<oLen<<endl;
		return 0;
	}
	return oLen;
}

void UpdateUserInfo(CUser *pUser,uint8 uType)
{
	if (pUser == NULL)
		return;
	CScene *pScene = pUser->GetScene();
	if (pScene != NULL)
		pScene->UpdateUserInfo(pUser,uType);
}

void Sha256(string &str)
{
	/*
	uint8 out[32] = {0};
	sha2_context ctx;
	sha2_starts(&ctx,0);
	sha2_update(&ctx,(unsigned char *)str.c_str(),str.size());
	sha2_finish(&ctx,out);
	str.clear();
	HexToStr(out,32,str);
	*/
}

char *ToURL(char *des,const char *src)
{
	int i,j;
	char c = '\0';
	char hex[] = "0123456789ABCDEF";
	for(i=0,j=0;src[i]!='\0';i++,j++)
	{
		c = src[i];
		if(c == '-' || c == '_' || c == '.' || isalnum(c))
		{
			des[j] = src[i];
			continue;
		}
		des[j++] = '%';
		des[j++] = hex[c/16];
		des[j] = hex[c%16];
	}
	des[j] = '\0';
	return des;
}

void ChatCharacterLimit(string &str,int limit)
{
	char buf[1024];
	int count=0;
	snprintf(buf,sizeof(buf)-1,"%s",str.c_str());
	uint8 *p = (uint8 *)buf;
	for(;*p != '\0';p++)
	{
		if(((*p) & 0xc0) != 0x80)
			count++;
		if(count > limit)
			break;
	}
	if(*p == '\0')
		return;
	*(p+1) = '\0';
	str = buf;
}

void oauth_hmac_sha1(const char *date,const size_t ldate,const char *key,const size_t lkey,char *out)
{
/*
	unsigned char result[EVP_MAX_MD_SIZE];
	unsigned int resultlen = 0;
	HMAC(EVP_sha1(),key,lkey,(unsigned char*)date,ldate,result,&resultlen);
	oauth_encode_base64(resultlen, result,out);
*/
}

char oauth_b64_encode(unsigned char u)
{
	if(u < 26)
		return 'A'+u;
	if(u < 52)
		return 'a'+(u-26);
	if(u < 62)
		return '0'+(u-52);
	if(u == 62)
		return '+';
	return '/';
}

void oauth_encode_base64(int size, const unsigned char *src,char *out)
{
	int i;
	char *p;
	if(!src)
		return;
	if(!size)
		size= strlen((char *)src);
	//	out= (char*) xcalloc(sizeof(char), size*4/3+4);
	p= out;
	for(i=0; i<size; i+=3)
	{
		unsigned char b1=0, b2=0, b3=0, b4=0, b5=0, b6=0, b7=0;
		b1= src[i];
		if(i+1<size) b2= src[i+1];
		if(i+2<size) b3= src[i+2];
		b4= b1>>2;
		b5= ((b1&0x3)<<4)|(b2>>4);
		b6= ((b2&0xf)<<2)|(b3>>6);
		b7= b3&0x3f;
		*p++= oauth_b64_encode(b4);
		*p++= oauth_b64_encode(b5);
		if(i+1<size)
			*p++= oauth_b64_encode(b6);
		else
			*p++= '=';
		if(i+2<size)
			*p++= oauth_b64_encode(b7);
		else
			*p++= '=';
	}
	//	return out;
}

void GetQQOauthURL(string hostName,string &token,string &tokenSecret,string &nonce,char *time,string &result)
{
	const char *consumer_key = "VimyxOwvsaq882Q12t13";
	const char *consumer_secret = "5c4EEwG3C58IabT8";
	const char *signature_method = "HMAC-SHA1";
	const char *oauth_version = "1.0";
	char url[512];
	string base_string,sig_key;
	char signature[32] = {0};
	char signature_url[64];

	base_string = "GET&http%3A%2F%2F" + hostName + "%2Foauth%2Fconnect&oauth_consumer_key%3D";
	base_string += consumer_key;
	base_string += "%26oauth_nonce%3D" + nonce + "%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D" + time;
	base_string += "%26oauth_token%3D" + token + "%26oauth_version%3D1.0%26tt%3D2";
	sig_key = consumer_secret;
	sig_key += "&" + tokenSecret;
	oauth_hmac_sha1(base_string.c_str(),base_string.size(),sig_key.c_str(),sig_key.size(),signature);
	ToURL(signature_url,(char *)signature);

	//	sha1_hmac((unsigned char *)(sig_key.c_str()),strlen(sig_key.c_str()),(unsigned char *)(base_string_url),strlen(base_string_url),out);
	//	base64_encode(signature,(int *)&len,result,20);

	snprintf(url,sizeof(url),"/oauth/connect?oauth_consumer_key=%s&oauth_token=%s&oauth_signature=%s&oauth_nonce=%s&oauth_timestamp=%s&oauth_signature_method=%s&oauth_version=%s&tt=2",
		consumer_key,token.c_str(),(char *)signature_url,nonce.c_str(),time,signature_method,oauth_version);
	result = url;
}

void GetUserSuperQQInfo(string &openid,string hostName,string &token,string &tokenSecret,string &nonce,char *time,string &superUrl)
{
	const char *consumer_key = "VimyxOwvsaq882Q12t13";
	const char *consumer_secret = "5c4EEwG3C58IabT8";
	const char *signature_method = "HMAC-SHA1";
	const char *oauth_version = "1.0";
	char url[512];
	string base_string,sig_key;
	char signature[32] = {0};
	char signature_url[64];
	base_string = "GET&http%3A%2F%2F" + hostName + "%2Fpeople%2F%40me%2F%40self&fields%3Did%252Csqq%252CsqqLevel%26oauth_consumer_key%3D";
	base_string += consumer_key;
	base_string += "%26oauth_nonce%3D" + nonce + "%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D" + time;
	base_string += "%26oauth_token%3D" + token + "%26oauth_version%3D1.0%26tt%3D2";
	sig_key = consumer_secret;
	sig_key += "&" + tokenSecret;
	oauth_hmac_sha1(base_string.c_str(),base_string.size(),sig_key.c_str(),sig_key.size(),signature);
	ToURL(signature_url,(char *)signature);
	snprintf(url,sizeof(url),"/people/@me/@self?oauth_consumer_key=%s&oauth_token=%s&oauth_signature=%s&oauth_nonce=%s&oauth_timestamp=%s&oauth_signature_method=%s&oauth_version=%s&tt=2&fields=id,sqq,sqqLevel",
		consumer_key,token.c_str(),(char *)signature_url,nonce.c_str(),time,signature_method,oauth_version);
	superUrl = url;
}

bool IsItemCanMerge(uint16 type)
{
	bool canMerge = false;
	/*const uint16 MergeType[] = {EIT_Normal,EIT_PetBook,EIT_Box_3};
	for(uint16 i=0;i < sizeof(MergeType)/sizeof(MergeType[0]);i++)
	{
		if(type == MergeType[i])
		{
			canMerge = true;
			break;
		}
	}*/
	return canMerge;
}

// 超简单json解析 hasColon:是否是没有""标志是否是数字
void GetJsonValue(string& data, string key, string& value, bool hasColon)
{
	size_t offset = 0;
	if (hasColon)
		offset = 1;
	size_t idx1,idx2;
	if ((idx1 = data.find(key)) == string::npos)
	{
		cout << data << LANGUAGE_TRANSFORM_208 << key << endl;
		return;
	}
	if ((idx2 = data.find(",",idx1+key.length()+3-offset)) == string::npos)
	{
		if ((idx2 = data.find("}",idx1+key.length()+3-offset)) == string::npos)
		{
			cout << data << LANGUAGE_TRANSFORM_209 << key << endl;
			return;
		}
	}
	value = data.substr(idx1+key.length()+3-offset,idx2-(idx1+key.length()+3-offset*2)-1);
	//cout << "value:" << value << endl;
}

// 整理json字符串
void GetJsonData(string& src, string& data)
{
	size_t idx1,idx2;
	if ((idx1 = src.find("{")) == string::npos)
	{
		cout << src << LANGUAGE_TRANSFORM_210 << endl;
		return;
	}
	if ((idx2 = src.find("}",idx1)) == string::npos)
	{
		cout << src << LANGUAGE_TRANSFORM_211<< endl;
		return;
	}
	//cout << idx1 << "," << idx2 << endl;
	data = src.substr(idx1,idx2-(idx1)+1);
}

void SendTongTianTaInfo(CUser *pUser)
{
	if(pUser == NULL)
		return;
	const int SHOW_FLOOR = 4; 
	const int maxFloor = TONG_TIAN_TA_FLOOR_NUM;
	if(pUser->GetExtData16(51) == 0)
		pUser->SetExtData16(51,1);

	int roleTopFloor = pUser->GetExtData16(52);
	int roleCurFloor = (int)pUser->GetExtData16(51) - 1;
	if ((roleCurFloor > maxFloor+1) || (roleCurFloor < 0))
		roleCurFloor = 0;
	int fubenIndex = roleCurFloor;

	uint8 enterNum = pUser->GetExtData8(61); // 每日进入次数
	uint8 maxNum = 1; // 进入上限数

	int64 exp = (int64)0;
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_TONG_TIAN_TA);
	msg<<(uint8)6;
	msg<<enterNum<<maxNum<<(uint16)roleCurFloor<<(uint16)roleTopFloor<<(uint16)maxFloor<<exp;   

	uint8 ifFirstAward = 0;	// 1首次奖励0非首次奖励
	if(roleTopFloor == roleCurFloor+1)
		ifFirstAward = 1;
	else if(roleTopFloor == roleCurFloor && roleTopFloor == 0)	// 首次
		ifFirstAward = 1;
	msg<<ifFirstAward;
	if(ifFirstAward == 0)
	{
		uint8 itemNum = 1;
		msg<<itemNum;
		msg<<(uint16)2370;
	}
	else
	{
		uint8 itemNum = 1;
		msg<<itemNum;
		msg<<(uint16)2370;
	}

	uint8 num = (maxFloor - fubenIndex >= SHOW_FLOOR) ? SHOW_FLOOR : (maxFloor - fubenIndex);
	msg<<num;

	CMonsterBossManager &bossManager = SingletonMonsterBossManager::instance();
	for (int i = 0; i < (int)num && fubenIndex < maxFloor; ++i)
	{
		++fubenIndex;
		int fightId = 12001 + (fubenIndex - 1) * 5;
		SFightCfgData* fcfg = SingletonCFightCfgManager::instance().GetFightCfg(fightId);
		if (fcfg == NULL)
			continue;
		
		msg << (uint8)fcfg->zhenfa_id;

		uint16 pos = msg.GetDataLen();
		uint8 bossNum = 0;
		msg << bossNum;
		for (int bi = 0; bi < ZHEN_FA_POS_NUM; ++bi)
		{
			SMonsterBossCfg* cfg = bossManager.GetMonsterBossCfg(fcfg->bossId[bi]);
			if (cfg == NULL)
				continue;
			bossNum++;
			msg << cfg->id << cfg->name << (uint8)cfg->level << (uint8)cfg->quality << (uint8)cfg->type;
		}
		msg.WriteData(pos, &bossNum, sizeof(bossNum));
	}
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void SendTongTianTaFirstCompleteInfo(CUser *pUser,uint16 level,int item1,int num1,int item2,int num2,int item3,int num3)
{
	if(pUser == NULL || item1 == 0 || num1 == 0)
		return;
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_TONG_TIAN_TA);
	msg<<(uint8)9<<level;
	uint8 count = 0;
	uint16 numPos = msg.GetDataLen();
	msg<<count;
	if(item1 != 0 && num1 > 0)
	{
		msg<<(uint16)item1<<(uint8)num1;
		count++;
	}
	if(item2 != 0 && num2 > 0)
	{
		msg<<(uint16)item2<<(uint8)num2;
		count++;
	}
	if(item3 != 0 && num3 > 0)
	{
		msg<<(uint16)item3<<(uint8)num3;
		count++;
	}
	msg.WriteData(numPos,&count,sizeof(count));
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

bool LeiTaiLvCheck(int level)
{
	static std::map<int, pair<int, int> > joinLevel;
	if (joinLevel.empty())
	{
		joinLevel.insert(make_pair(EM_TUESDAY, make_pair(40, 59)));
		joinLevel.insert(make_pair(EM_THURSDAY, make_pair(60, 79)));
		joinLevel.insert(make_pair(EM_SUNDAY, make_pair(80, 255)));
	}
	int wday = GetWeekDay();
	std::map<int, pair<int, int> >::iterator it = joinLevel.find(wday);
	if (it == joinLevel.end())
	{
		return false;
	}

	return level >= it->second.first && level <= it->second.second;
}

int GetLeiTaiLv()
{
	static std::map<int, pair<int, int> > joinLevel;
	if (joinLevel.empty())
	{
		joinLevel.insert(make_pair(EM_TUESDAY, make_pair(40, 59)));
		joinLevel.insert(make_pair(EM_THURSDAY, make_pair(60, 79)));
		joinLevel.insert(make_pair(EM_SUNDAY, make_pair(80, 255)));
	}
	int wday = GetWeekDay();
	std::map<int, pair<int, int> >::iterator it = joinLevel.find(wday);
	if (it == joinLevel.end())
	{
		return 0;
	}
	return it->second.first;
}

int GetLeiTaiAId()
{
	static std::map<int, int> awardIds;
	if (awardIds.empty())
	{
		awardIds.insert(make_pair(EM_TUESDAY, 12));
		awardIds.insert(make_pair(EM_THURSDAY, 13));
		awardIds.insert(make_pair(EM_SUNDAY, 14));
	}
	int wday = GetWeekDay();
	std::map<int, int>::iterator it = awardIds.find(wday);
	if (it == awardIds.end())
	{
		return 0;
	}
	return it->second;
}

void UpdateUserChatTime(uint32 roleId,uint32 time)
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;

	char sql[256];
	snprintf(sql, sizeof(sql), "update role_info set chat_time=%u where id=%u", time, roleId);
	pDb->Query(sql);
}

uint32 GetUserChatTime(uint32 roleId)
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return 0;

	char sql[256];
	char **row = NULL;
	snprintf(sql, sizeof(sql), "select chat_time from role_info where id=%u", roleId);
	if(pDb->Query(sql))
	{
		if((row = pDb->GetRow()) != NULL)
			return atoi(row[0]);
	}
	return 0;
}


static void SendHuoDongInfoToAllUser(CSocketServer *pSock, CNetMessage *pMsg, uint16 type, CUser *pUser)
{
	if (pUser == NULL)
		return;

	if (!sSystemOpenCfgMananger.CheckSystemOpen(pUser, type))
		return;

	switch (type)
	{
	case SOT_LeiTaiSai:
		if (!LeiTaiLvCheck(pUser->GetLevel()))
			return;
		break;

	case SOT_Bangpai:
		if (!SingletonCBangPaiManager::instance().IsInBangPaiFightList(pUser->GetBangPai()))
			return;
		break;
	}
	if (type == SOT_LeiTaiSai && !LeiTaiLvCheck(pUser->GetLevel()))
		return;
	pSock->SendMsg(pUser->GetSock(),*pMsg);
}

// op = 1 百花仙子
// op = 4 昆仑山
// op = 9 护送活动
// op = 11 百花抽取效果
// op = 13 飞仙活动图标
// op = 14 帮派掠夺
// op = 18 兑换豪礼活动
// op = 19 多人闯关按钮(个人)
// op = 20 帮战
// op = 21 组队昆仑山(准备中)
// op = 22 组队昆仑山
// op = 23 跨服帮派战
// op = 24 结婚喜帖按钮
// op = 25 婚礼开始按钮
// op = 27 灵魔图标显示
void SendHuoDongFlag(uint8 type,uint8 flag)	// 活动开启flag=1,活动关闭flag=2
{
	CNetMessage sysMsg;
	sysMsg.SetType(MSG_HUODONG_OPTION);
	//                                leftTime
	sysMsg << (uint16)1 << (uint8)type << (uint8)flag;
	uint32 leftTime = 0;
	if (flag == 1)
	{
		leftTime = CSceneManager::GetActivityFinishTime(type);
	}
	else if (flag == 3)
	{
		leftTime = GetSysTime();
	}
	sysMsg << (uint32)leftTime;
	if (type == SOT_Shuangbei)
	{
		sysMsg << (uint8)GetSysDoubleExpRatio();
	}
	CSocketServer &sock = SingletonSocket::instance();
	SingletonOnlineUser::instance().ForEachUser(boost::bind(SendHuoDongInfoToAllUser,&sock,&sysMsg, type,_1));
	cout << "SendHuoDongFlag " << (int)type << " " << (int)flag << endl;
}

void SendHuoDongFlag_Single(CUser *pUser, uint8 type,uint8 flag,uint32 time)	// 活动开启flag=1,活动关闭flag=2
{
	if(pUser == NULL)
		return;
	CNetMessage msg;
	msg.SetType(MSG_HUODONG_OPTION);
	uint32 leftTime = 0;
	if (flag == 1)
	{
		leftTime = CSceneManager::GetActivityFinishTime(type);
	}
	else if (flag == 3)
	{
		leftTime = GetSysTime();
	}
	msg << (uint16)1 << (uint8)type << (uint8)flag << leftTime;
	if (type == SOT_Shuangbei)
	{
		msg << (uint8)GetSysDoubleExpRatio();
	}
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void SendBangPai_TreeRobAward(CUser *pUser,SMailData *pMail)	// 帮派掠夺奖励发放
{
	if(pUser == NULL || pMail == NULL)
		return;
	if(pUser->GetBangPai() == 0)
		return;
	SendSystemMail(pUser->GetRoleId(),LANGUAGE_TRANSFORM_212,pMail);
}

// 获取道具叠加上限
int GetItemDieJiaNum(int itemId)
{
	CItemTemplateManager &itemMgr = SingletonItemManager::instance();
	SItemTemplate *pItemSrc = itemMgr.GetItem(itemId);
	if (pItemSrc == NULL)
		return 1;
	return GetItemDieJiaNum(itemId,pItemSrc->type);
}

// 获取道具叠加上限
int GetItemDieJiaNum(int itemId,int itemType)
{
	//static int type[] = {EIT_Normal,EIT_PetBook,EIT_Box_3}; // 可叠加的物品类型
	//static int itemExcept[] = {1809,1815,683,684,1804,1805,1822,1827,1831}; // 不可叠加的特殊物品

	//static int typeSize = sizeof(type)/sizeof(int);
	//static int itemExceptSize = sizeof(itemExcept)/sizeof(int);
	//for (int i = 0; i < typeSize; ++i)
	//{
	//	if (itemType == type[i])
	//	{
	//		for (int j = 0; j < itemExceptSize; ++j)
	//		{
	//			if (itemId == itemExcept[j])
	//				return 1;
	//		}
	//		return EItemDieJiaNum;
	//	}
	//}
	return 1;
}

// 获取登陆服务器数据库
CDatabaseSql* GetLoginDb()
{
	static CDatabaseSql* pLoginDB = NULL;
	string localTest = gyu::util::CIniFile::GetValue("local_test","server",gConfigFile);
	if(localTest == "1")
		return NULL;
	if (pLoginDB == NULL)
	{
		pLoginDB = new CDatabaseSql;
		string user = gyu::util::CIniFile::GetValue("username","login_db",gConfigFile);
		string password = gyu::util::CIniFile::GetValue("password","login_db",gConfigFile);
		string host = gyu::util::CIniFile::GetValue("host","login_db",gConfigFile);
		string db = gyu::util::CIniFile::GetValue("dbname","login_db",gConfigFile);
		string port = gyu::util::CIniFile::GetValue("port","login_db",gConfigFile);
		if(!pLoginDB->Connect(user.c_str(),password.c_str(),host.c_str(),db.c_str(),atoi(port.c_str())))
		{
			delete pLoginDB;
			pLoginDB = NULL;
			cout<<"GetLoginDb() : connect login db error"<<endl;
			return NULL;
		}
	}
	return pLoginDB;
}

int64 GetHuoDongRobExpRatio(int64 exp,uint16 srcLv,uint8 robberLv)
{
	const uint8 limitLv = 27;
	if(srcLv < limitLv || robberLv == 0)
		return 0;
	if(robberLv <= srcLv)
		return exp;

	uint8 srcDuan = 0;
	uint8 robDuan = 0;
	if(srcLv <= 45)
		srcDuan = (srcLv - limitLv)/3 + 1;
	else
		srcDuan = (srcLv - 45)/5 + 7;
	if(robberLv <= 45)
		robDuan = (robberLv - limitLv)/3 + 1;
	else
		robDuan = (robberLv - 45)/5 + 7;
	if(robDuan > srcDuan)
		exp = 1000*srcDuan;
	return exp;
}

void GetYaYunBiaoCheRobExp(CUser *pSrcUser,uint8 robberLevel,int64 &exp,int &money)
{
/*
	exp = 0;
	money = 0;
	if(pSrcUser == NULL || robberLevel == 0)
		return;
	const char *pMission = pSrcUser->GetMission(213);
	if(pMission == NULL)
		return;

	//   0      1       2       3      4           5          6       7
	// step|quality|totolexp|lostexp|index|completeNpcIndex|money|loseMoney
	char *split[10];
	string str = pMission;
	int num = SplitLine(split,8,(char*)str.c_str());
	if(num < 8)
	{
		cout<<LANGUAGE_TRANSFORM_213<<endl;
		return;
	}

	const int qualityPercent[] = {100,106,111,128,156};
	int quality = atoi(split[1]);
	exp = strtoll(split[2],NULL,10);
	money = atoi(split[6]);
	if(quality < 0 || quality > 4)
		return;
	exp = (int64)(exp*qualityPercent[quality]/100.0/10.0);
	money = (int)(money*qualityPercent[quality]/100.0/10.0);
	exp = GetHuoDongRobExpRatio(exp,pSrcUser->GetLevel(),robberLevel);
*/
}

uint8 GetHeChengItemNum(uint16 itemId)
{
	return 0;
	/*ComposeCfg* pData = sCItemCfgManager.GetComposeCfg(CPT_ITEM_C, itemId);
	if (pData == NULL)
	{
		return 0;
	}
	return pData->needNum;*/
	//uint8 reqNum = 0;
	//if((itemId >= 506 && itemId <= 509)			// 装备升阶石
	//	|| (itemId >= 511 && itemId <= 514)		// 锦缎
	//	|| (itemId >= 516 && itemId <= 517)		// 金丝
	//	|| (itemId >= 520 && itemId <= 521)		// 铭刻符
	//	|| (itemId >= 801 && itemId <= 814)		// 炼化石
	//	|| (itemId >= 2310 && itemId <= 2312)	// 神将铠升星石
	//	|| (itemId == 2370)						// 神将进化丹
	//	)
	//	reqNum = 3;
	//else if((itemId >= 501 && itemId <= 504)	// 幸运符
	//	|| (itemId >= 834 && itemId <= 836)		// 神将内丹
	//	|| (itemId >= 851 && itemId <= 856)		// 强化宝石
	//	|| (itemId == 1099)						// 百花碎片
	//	|| (itemId >= 2251 && itemId <= 2253)	// 坐骑强化石
	//	|| (itemId >= 2354 && itemId <= 2356)	// 先锋令
	//	|| (itemId == 2798 )					//功勋牌
	//	)
	//	reqNum = 5;
	//else if(itemId == 838				// 仙桃
	//	|| (itemId >= 2401 && itemId <= 2404)	// 神将碎片
	//	)
	//	reqNum = 10;
	//else if((itemId >= 2405 && itemId <= 2409) || (itemId >= 2413 && itemId <= 2416) || (itemId >= 2521 && itemId <= 2524))	// 神将碎片
	//	reqNum = 15;
	//else if((itemId >= 2410 && itemId <= 2412) || (itemId >= 2525 && itemId <= 2529))	// 神将碎片
	//	reqNum = 20;
	//else if(itemId >= 2417 && itemId <= 2421)	// 神将碎片
	//	reqNum = 25;
	//else if((itemId >= 2530 && itemId <= 2533) || itemId == 2547 || itemId == 2565 || itemId == 2569)	// 金色碎片
	//	reqNum = 27;
	//else if(itemId == 2826 || itemId == 2911)	// 金色流光琴碎片, 金色碎片
	//	reqNum = 32;
	//else if((itemId >= 2422 && itemId <= 2424) || itemId == 2519 || itemId == 2544 || itemId == 2563 || itemId == 2567 || itemId == 2824 || itemId == 2909)	// 神将碎片
	//	reqNum = 35;
	//return reqNum;
}

uint16 GetHeChengTargetItemId(uint16 itemId)
{
	return 0;
	/*ComposeCfg* pData = sCItemCfgManager.GetComposeCfg(CPT_ITEM_C, itemId);
	if (pData == NULL)
	{
		return 0;
	}
	return pData->id;*/
	/*uint16 targetId = itemId+1;
	if(itemId == 838)
		targetId = 834;
	else if(itemId >= 2401 && itemId <= 2409)
		targetId = 2478 + (itemId - 2401);
	else if(itemId >= 2413 && itemId <= 2424)
		targetId = 2451 + (itemId - 2413);
	else if(itemId == 2410)
		targetId = 2476;
	else if(itemId == 2411)
		targetId = 2475;
	else if(itemId == 2412)
		targetId = 2477;
	else if(itemId >= 2521 && itemId <= 2532)
		targetId = 2463 + (itemId - 2521);
	else if(itemId == 2547)
		targetId = 2546;
	return targetId;*/
}

void ReSetAddPetLevel(uint16 &level)
{
	if(level > 30)
		level = 30;
}

uint16 GetFightLimitTurn(uint16 fightType)
{
	if(fightType == CFight::EFKuaFuShenJieMiJingBossPVE)
		return 10;
	return 30;
}

int GetEquipQualityByItemLevel(int itemLv)
{
	int quality = 0;
	if(itemLv <= 20)
		quality = itemLv/10 + 1;
	else
		quality = itemLv/10;
	if(quality > 10)
		quality = 10;
	return quality;
}

int GetEquipQiangHuaLevelQuality(int qhLevel)
{
	int quality = GGCT_WHITE;
	if(qhLevel < 7)
		quality = GGCT_WHITE;
	else if(qhLevel <= 9)
		quality = GGCT_PURPLE;
	else if(qhLevel <= 12)
		quality = GGCT_ORANGE;
	else if(qhLevel <= 15)
		quality = GGCT_GOLD;
	else if(qhLevel <= 18)
		quality = GGCT_PINK;
	else
		quality = GGCT_RED;
	return quality;
}

// 获取活跃度列表
void GetHuoYueDuInfo(CUser *pUser)
{
	if (pUser == NULL)
		return;
	CCallScript *pCallScript = FindScript(200);
	if(pCallScript == NULL)
		return;
	int huoYueDu = 0;
	char *huoYueDuInfo = NULL;
	pCallScript->Call("GetHuoYueDuInfo","u>is",pUser,&huoYueDu,&huoYueDuInfo);
	if(huoYueDuInfo == NULL)
		return;
	string info = huoYueDuInfo;

	CNetMessage msg;
	msg.SetType(MSG_DAILY_ACTIVITY);
	msg<<(uint8)1<<info;
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void LoadSysDoubleExpCfg()
{
	G_SYS_EXP_CFG.Clear();

	CCallScript *pCallScript = FindScript(200);
	if(pCallScript == NULL)
		return;
	pCallScript->Call("GetSystemDoubleExpCfg",">iiiii",&G_SYS_EXP_CFG.startHour,&G_SYS_EXP_CFG.startMinute,
		&G_SYS_EXP_CFG.stopHour,&G_SYS_EXP_CFG.stopMinute,&G_SYS_EXP_CFG.expRatio);
}

bool InSysDoubleExp()
{
	int hour = GetHour();
	int min = GetMinute();
	int current = hour * 100 + min;
	int start = G_SYS_EXP_CFG.startHour * 100 + G_SYS_EXP_CFG.startMinute;
	int end = G_SYS_EXP_CFG.stopHour * 100 + G_SYS_EXP_CFG.stopMinute;
	if(current >= start && current < end)
		return true;
	return false;
}

int GetSysDoubleExpNotifyTime()
{
	int hour = G_SYS_EXP_CFG.startHour;
	int min = G_SYS_EXP_CFG.startMinute;
	if (min < 30)
	{
		min = 60 + min - 30;
		hour -= 1;
	}
	else
	{
		min -= 30;
	}
	return hour * 100 + min;
}

int GetSysDoubleExpStartTime()
{
	return G_SYS_EXP_CFG.startHour * 100 + G_SYS_EXP_CFG.startMinute;
}

int GetSysDoubleExpEndTime()
{
	return G_SYS_EXP_CFG.stopHour * 100 + G_SYS_EXP_CFG.stopMinute;
}

int GetSysDoubleExpRatio()
{
	return G_SYS_EXP_CFG.expRatio;
}

uint8 GetVipLevel(int yb)
{
	for(int i=0;i < 16;i++)
	{
		if(yb < (int)G_VipConfig[i].yuanbao)
		{
			return i-1;
		}
	}
    return 15;
}

int GetMysteryOpenlv(int pos)
{
	for(int j=0;j<16;j++)
	{
		if(pos<G_VipConfig[j].openshop)
		{
			return j;
		}
	}
	return 0;
}

uint32 GetYaoShiLimitScore(uint32 pos,vector<HDPeiZhiInfo> &peizhiInfo)
{
	for(uint32 j=0;j<peizhiInfo.size();j++)
	{
		if(pos<peizhiInfo[j].count)
		{
			return peizhiInfo[j].YB;
		}
	}
	return 0;
}

uint16 GetVipDailyYB(uint8 vipLevel)
{
	const int VIPPrizePerDay[] = {20,50,150};
	return (vipLevel>0 && vipLevel<4) ? (uint16)VIPPrizePerDay[vipLevel-1] : 0; 
}

void GetPetCopyDropData(CUser *pUser,int difficulty,uint8 &type,uint16 &id,uint8 &quality,uint8 &qualityLevel)
{
	type = 0;
	id = 0;
	quality = 0;

	if(difficulty < 1 || difficulty > 3 || pUser == NULL)
		return;
	if(difficulty == 1)	// 初级副本
	{





	}
	else if(difficulty == 2)	// 中级副本
	{
		int r = Random(1,10000);
		if(r <= 2418)
		{
			type = 1;
			quality = PQT_GREEN;
		}
		else if(r <= 5206)
		{
			type = 1;
			quality = PQT_BLUE;
		}
		else if(r <= 6642)
		{
			type = 1;
			quality = PQT_BLUE;
		}
		else if(r <= 7614)
		{
			type = 1;
			quality = PQT_BLUE;
		}
		else if(r <= 8271)
		{
			type = 1;
			quality = PQT_BLUE;
		}
		else if(r <= 8285)
		{
			type = 1;
			quality = PQT_PURPLE;
		}
		else if(r <= 9558)	// 紫神将碎片
		{
			type = 2;
			quality = PQT_PURPLE;
		}
		else	// 橙神将碎片
		{
			type = 2;
			quality = PQT_ORANGE;
		}
	}
	else if(difficulty == 3)	// 高级副本
	{
		int r = Random(1,10000);
		if(r <= 6878)
		{
			type = 1;
			quality = PQT_BLUE;
		}
		else if(r <= 7035)
		{
			type = 1;
			quality = PQT_PURPLE;
		}
		else if(r <= 7060)
		{
			type = 1;
			quality = PQT_ORANGE;
		}
		else if(r <= 9322)	// 紫神将碎片
		{
			type = 2;
			quality = PQT_PURPLE;
		}
		else	// 橙神将碎片
		{
			type = 2;
			quality = PQT_ORANGE;
		}
	}

	if(type == 1)	// 神将
	{
		const uint8 (*pPetQuality)[2] = NULL;
		uint8 size = 0;
		if(quality == PQT_ORANGE)	// 橙色
		{
			pPetQuality = DrawPetId_Q4;
			size = sizeof(DrawPetId_Q4)/sizeof(DrawPetId_Q4[0]);
		}
		else if(quality == PQT_PURPLE)	// 紫色
		{
			pPetQuality = DrawPetId_Q3;
			size = sizeof(DrawPetId_Q3)/sizeof(DrawPetId_Q3[0]);
		}
		else if(quality == PQT_BLUE)	// 蓝色
		{
			pPetQuality = DrawPetId_Q2;
			size = sizeof(DrawPetId_Q2)/sizeof(DrawPetId_Q2[0]);
		}
		else	// 绿色
		{
			pPetQuality = DrawPetId_Q1;
			size = sizeof(DrawPetId_Q1)/sizeof(DrawPetId_Q1[0]);
		}

		int ratio = 0;
		int r = Random(1,100);
		for(uint8 i=0;i < size;i++)
		{
			ratio += pPetQuality[i][1];
			if(r <= ratio)
			{
				id = pPetQuality[i][0];
				break;
			}
		}
	}
	else if(type == 2)	// 神将碎片
	{
		if(quality == PQT_PURPLE)	// 紫色
			id = Random(1,12) + 2400;
		else if(quality == PQT_ORANGE)	// 橙色
			id = Random(13,24) + 2400;
	}
}


void GetPetCopyDropData_Primary(CUser* pUser,uint8 &type,uint16 &Id,uint8 &quality)
{
	if(pUser == NULL)
		return;
	const uint8 ziPetLimitNum1 = 1;
	const uint8 lanPetLimitNum1 = 8;
	const uint8 lvPetLimitNum1 = 6;
	const uint8 ziPetChipLimitNum1 = 0;
	const uint8 totlePetNum1 = ziPetLimitNum1 + lanPetLimitNum1 + lvPetLimitNum1 + ziPetChipLimitNum1;

	const uint8 ziPetLimitNum2 = 0;
	const uint8 lanPetLimitNum2 = 7;
	const uint8 lvPetLimitNum2 = 4;
	const uint8 ziPetChipLimitNum2 = 4;

	type = 0;
	Id = 0;
	quality = 0;

	uint16 curTotle = pUser->GetExtData8(95) + pUser->GetExtData8(96) + pUser->GetExtData8(97) + pUser->GetExtData8(132);
	uint8 ziNum = 0;
	uint8 lanNum = 0;
	uint8 lvNum = 0;
	uint8 ziChipNum = 0;
	if(curTotle < totlePetNum1)
	{
		ziNum = ziPetLimitNum1 - pUser->GetExtData8(95);
		lanNum = lanPetLimitNum1 - pUser->GetExtData8(96);
		lvNum = lvPetLimitNum1 - pUser->GetExtData8(97);
		ziChipNum = ziPetChipLimitNum1 - pUser->GetExtData8(132);
		if(ziNum > ziPetLimitNum1)
			ziNum = 0;
		if(lanNum > lanPetLimitNum1)
			lanNum = 0;
		if(lvNum > lvPetLimitNum1)
			lvNum = 0;
		if(ziChipNum > ziPetChipLimitNum1)
			ziChipNum = 0;
	}
	else
	{
		uint8 ratio = curTotle/totlePetNum1 - 1;
		ziNum = ziPetLimitNum2 - (pUser->GetExtData8(95) - ziPetLimitNum1 - ziPetLimitNum2*ratio);
		lanNum = lanPetLimitNum2 - (pUser->GetExtData8(96) - lanPetLimitNum1 - lanPetLimitNum2*ratio);
		lvNum = lvPetLimitNum2 - (pUser->GetExtData8(97) - lvPetLimitNum1 - lvPetLimitNum2*ratio);
		ziChipNum = ziPetChipLimitNum2 - (pUser->GetExtData8(132) - ziPetChipLimitNum1 - ziPetChipLimitNum2*ratio);

		if(ziNum > ziPetLimitNum2)
			ziNum = 0;
		if(lanNum > lanPetLimitNum2)
			lanNum = 0;
		if(lvNum > lvPetLimitNum2)
			lvNum = 0;
		if(ziChipNum > ziPetChipLimitNum2)
			ziChipNum = 0;
	}

	uint8 qualityType[totlePetNum1] = {0};
	for(uint8 i=0;i < ziNum;i++)
		qualityType[i] = PQT_PURPLE;
	for(uint8 i=ziNum;i < ziNum+lanNum;i++)
		qualityType[i] = PQT_BLUE;
	for(uint8 i=ziNum+lanNum;i < ziNum+lanNum+lvNum;i++)
		qualityType[i] = PQT_GREEN;
	for(uint8 i=ziNum+lanNum+lvNum;i < ziNum+lanNum+lvNum+ziChipNum;i++)
		qualityType[i] = 100 + PQT_PURPLE;
	int r = Random(1,ziNum+lanNum+lvNum+ziChipNum) - 1;
	if(curTotle < totlePetNum1 && ziNum > 0 && (Random(1,100) <= GetPrimaryPetCopyRatio(pUser)))
		r = 0;
	
	if(qualityType[r] == PQT_PURPLE)
	{
		pUser->SetExtData8(95,pUser->GetExtData8(95)+1);
		type = 1;
		quality = qualityType[r];
	}
	else if(qualityType[r] == PQT_BLUE)
	{
		pUser->SetExtData8(96,pUser->GetExtData8(96)+1);
		type = 1;
		quality = qualityType[r];
	}
	else if(qualityType[r] == PQT_GREEN)
	{
		pUser->SetExtData8(97,pUser->GetExtData8(97)+1);
		type = 1;
		quality = qualityType[r];
	}
	else
	{
		pUser->SetExtData8(132,pUser->GetExtData8(132)+1);
		type = 2;
		quality = PQT_PURPLE;
	}

	if(type == 1)
	{
		uint8 size = 0;
		const uint8 (*pPetQuality)[2] = NULL;
		if(quality == PQT_PURPLE) // 紫色
		{
			pPetQuality = DrawPetId_Q3;
			size = sizeof(DrawPetId_Q3)/sizeof(DrawPetId_Q3[0]);
		}
		else if(quality == PQT_BLUE) // 蓝色
		{
			pPetQuality = DrawPetId_Q2;
			size = sizeof(DrawPetId_Q2)/sizeof(DrawPetId_Q2[0]);
		}
		else // 绿色
		{
			pPetQuality = DrawPetId_Q1;
			size = sizeof(DrawPetId_Q1)/sizeof(DrawPetId_Q1[0]);
		}

		int ratio = 0;
		r = Random(1,100);
		for(uint8 i=0;i < size;i++)
		{
			ratio += pPetQuality[i][1];
			if(r <= ratio)
			{
				Id = pPetQuality[i][0];
				break;
			}
		}
	}
	else if(type == 2)
	{
		Id = Random(1,12) + 2400;
	}
}

// 检验是否达成阶段目标
void RiChangFuBenCheckStageGoal(CUser* pUser)
{
	//	if (pUser == NULL)
	//		return;
	//if (pUser->HaveBitSet(193) && pUser->HaveBitSet(195) && pUser->HaveBitSet(196) && pUser->HaveBitSet(197) && (!pUser->HaveSGBitSet(103))) // 去掉强化副本了
	//	if (pUser->HaveBitSet(193) && pUser->HaveBitSet(194) && pUser->HaveBitSet(195) && pUser->HaveBitSet(197) && (!pUser->HaveSGBitSet(103))) //  && pUser->HaveBitSet(196)
	//		pUser->FinishStageGoalSection(1,2); // 通关全部副本
}

// 获取神将数据
void MakePetMsg(CUser* pUser,CNetMessage& msg,int petId,int level,int star)
{
	SPet *pPet = new SPet;
	pPet->Clear();
	if(pPet == NULL)
	{
		msg<<(uint16)0;
		return;
	}
	SharePetPtr pet(pPet);
	CPetCfgManager &petMgr = SingletonCPetCfgMgr::instance();
	SPetBasicData *pCfg = petMgr.GetPetCfg(petId);
	if(pCfg == NULL)
	{
		msg<<(uint16)0;
		return;
	}
	pPet->id = petId;
	if(star == 1)
		pPet->star = pCfg->initStar;
	else
		pPet->star = star;
	pPet->level = level;
	pPet->name = pCfg->name;
	petMgr.InitBasicData(pPet);
	pPet->Init(pUser);
	pPet->hp = pPet->basicAttr.maxHp;
	pUser->MakePetData(pPet,msg);
}

void MakePetDiffInfo(SPet *pSrcPet,SPet *pNewPet,CNetMessage &msg)
{
	if(pSrcPet == NULL || pNewPet == NULL)
		return;
//	msg<<pSrcPet->GetZhanDouLi()<<pSrcPet->attack
//		<<pSrcPet->recovery<<pSrcPet->maxHp<<pSrcPet->speed;
//	msg<<pNewPet->GetZhanDouLi()<<(pNewPet->attack > pNewPet->fashuAttack ? pNewPet->attack : pNewPet->fashuAttack)
//		<<pNewPet->recovery<<pNewPet->maxHp<<pNewPet->speed;
//	msg<<(pNewPet->GetZhanDouLi() - pSrcPet->GetZhanDouLi())<<((pNewPet->attack-pSrcPet->attack) > (pNewPet->fashuAttack-pSrcPet->fashuAttack) ? (pNewPet->attack-pSrcPet->attack) : (pNewPet->fashuAttack-pSrcPet->fashuAttack))
//		<<(pNewPet->recovery - pSrcPet->recovery)<<(pNewPet->maxHp - pSrcPet->maxHp)<<(pNewPet->speed - pSrcPet->speed);
	uint16 addSkill = 0;
	for(uint8 i=1;i < 4;i++)
	{
		if(pSrcPet->skill[i] == 0)
		{
			if(pNewPet->skill[i] != 0)
				addSkill = pNewPet->skill[i];
			break;
		}
	}
	msg<<addSkill;
}

bool IsSeedItem(uint16 itemId)
{
	if(itemId >= 1201 && itemId <= 1400)
		return true;
	else
		return false;
}


static map<uint32, list<SBangPaiLog> > G_MoBaiData;
static boost::recursive_mutex G_MoBai_Mutex;

bool LoadMoBaiLog()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return false;
	char **row = NULL;
	char sql[256];
	for(int i=1;i <= 3;i++)
	{
		ArenaPaiHangData data;
		if(SingletonCArenaManager::instance().GetDataByRank(i, data))
			return true;
		int roleId = data.roleId;
		snprintf(sql,sizeof(sql),"select option_roleId,msg,time from mobai where role_id=%d order by time desc limit 10",roleId);
		if(!pDb->Query(sql))
			return false;
		boost::recursive_mutex::scoped_lock lk(G_MoBai_Mutex);
		map<uint32, list<SBangPaiLog> >::iterator it = G_MoBaiData.find(roleId);
		if(it == G_MoBaiData.end())	// 没找到
		{
			list<SBangPaiLog> logList;
			pair<map<uint32,list<SBangPaiLog> >::iterator,bool > ret = G_MoBaiData.insert(make_pair(roleId,logList));
			if(ret.second)
				it = ret.first;
			else
				return true;
		}
		while((row = pDb->GetRow()) != NULL)
		{
			SBangPaiLog temp;
			temp.option_roleId = atoi(row[0]);
			temp.log = row[1];
			temp.time = atoi(row[2]);
			it->second.push_back(temp);
		}
	}
	return true;
}

void SaveMoBaiLog(int option_roleId,int roleId,const char *pStr)
{
	if(pStr == NULL)
		return;
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
	char sql[256];
	snprintf(sql,sizeof(sql),"insert into mobai (option_roleId,role_id,msg,time) values(%d,%d,'%s',%u)",option_roleId,roleId,pStr,(uint32)GetSysTime());
	pDb->Query(sql);

	{
		boost::recursive_mutex::scoped_lock lk(G_MoBai_Mutex);
		map<uint32, list<SBangPaiLog> >::iterator it = G_MoBaiData.find(roleId);
		if(it == G_MoBaiData.end())	// 没找到
		{
			list<SBangPaiLog> logList;
			pair<map<uint32,list<SBangPaiLog> >::iterator,bool > ret = G_MoBaiData.insert(make_pair(roleId,logList));
			if(ret.second)
				it = ret.first;
			else
				return;
		}
		if(it->second.size() >= 10)
			it->second.pop_back();
		SBangPaiLog temp;
		temp.option_roleId = option_roleId;
		temp.log = pStr;
		temp.time = GetSysTime();
		it->second.push_front(temp);
	}
}

void GetMoBaiLogList(int roleId,list<SBangPaiLog> &log)
{
	log.clear();

	boost::recursive_mutex::scoped_lock lk(G_MoBai_Mutex);
	map<uint32, list<SBangPaiLog> >::iterator it = G_MoBaiData.find(roleId);
	if(it != G_MoBaiData.end())
		log = it->second;
}

void ChangeClientGuaJiState(CUser *pUser,uint8 state)
{
	// state 1 开始挂机 2 停止挂机
	if(state != 1 && state != 2)
		return;
	CNetMessage msg;
	msg.SetType(MSG_CHANGE_GUAJI_STATE);
	msg<<state;
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void ShowReviveChooseInCopy(CUser *pUser,uint8 difficulty)
{
	if(pUser == NULL)
		return;
	int useYB = GetPetCopyReviveYB(difficulty,pUser->GetExtData8(120));
	if(useYB == 0)
		return;

	char buf[128];
	snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_214,useYB);
	CNetMessage msg;
	msg.SetType(MSG_FUBEN_OPTION);
	msg<<(uint8)28<<buf;
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

int GetPetCopyReviveYB(uint8 difficulty,uint8 dieNum)
{
	const int ReviveYB[EUMT_NUM] = {2,5,10,15,20};//,22};
	int useYb = 0;
	if(difficulty < sizeof(ReviveYB)/sizeof(ReviveYB[0]))
		useYb = (int)(ReviveYB[difficulty] * pow(2.0,dieNum));
	return useYb;
}

struct ConfigFileData
{
	int id;
	string fileData;
};

void PushClientConfigFile(CUser *pUser)
{
	static vector<ConfigFileData> fileList;
	const int CONFIG_FILE_MAXID = 100;
	const uint32 FILE_MAX_SIZE = 0xf000;
	const uint32 MSG_MAX_LEN = 0xff00;
	if(pUser == NULL)
		return;

	if(fileList.empty())
	{
		char buf[FILE_MAX_SIZE];
		for(int i=1;i < CONFIG_FILE_MAXID;i++)
		{
			snprintf(buf,sizeof(buf),"clientConfig/%d.txt",i);
			FILE *fp = fopen(buf,"r");
			if(fp != NULL)
			{
				if(fread(buf,FILE_MAX_SIZE,1,fp) == FILE_MAX_SIZE)
					continue;
				ConfigFileData data;
				data.id = i;
				data.fileData = buf;
				fileList.push_back(data);
				fclose(fp);
			}
		}
	}

	if(!fileList.empty())
	{
		CNetMessage msg;
		msg.SetType(MSG_CLIENT_CONFIG_FILE);
		uint16 pos = msg.GetDataLen();
		uint16 num = 0;
		msg<<num;
		for(uint16 i=0;i < fileList.size();i++)
		{
			if(msg.GetDataLen() + fileList[i].fileData.size() > MSG_MAX_LEN)
			{
				msg.WriteData(pos,&num,sizeof(num));
				SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);

				msg.ReWrite();
				msg.SetType(MSG_CLIENT_CONFIG_FILE);
				num = 0;
				msg<<num;
			}
			msg<<fileList[i].id<<fileList[i].fileData;
			num++;
		}
		if(num > 0)
		{
			msg.WriteData(pos,&num,sizeof(num));
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		}
	}
}

int GetPetCopyMonsterId(uint8 difficulty,bool specPet)
{
	const int specPetId[] = {111,112,113,114,115,117,119,120};
	uint16 size = sizeof(specPetId)/sizeof(specPetId[0]);
	int mid = 0;
	switch(difficulty)
	{
	case 0:	// 绿色副本
		if(specPet)
			mid = specPetId[Random(1,size)-1];
		else
			mid = Random(9,30);
		break;
	case 1:	// 蓝色副本
		if(specPet)
			mid = specPetId[Random(1,size)-1];
		else
			mid = Random(9,30);
		break;
	case 2:	// 紫色副本
		if(specPet)
			mid = specPetId[Random(1,size)-1];
		else
			mid = Random(19,41);
		break;
	case 3:	// 天书副本
		mid = Random(31,41);
		break;
//	case 4:	
//		mid = Random(31,42);
//		break;
//	case 5:
//		mid = Random(31,42);
//		break;
	default:
		break;
	}
	if(mid == 26)
		mid = 9;
	return mid;
}

int AccelerateSaoDangCostYB(int leftTime)
{
	int yb = leftTime/30;
	if(yb == 0)
		yb = 1;
	return yb;
}

void GetFastRoleName(int sex,string &name)
{
	static int male_name_id = 0;
	static int female_name_id = 0;
	char buf[256];
	if(sex == 0)
		snprintf(buf,sizeof(buf),"select id,name from name_reg0 where id>%d limit 1",male_name_id);
	else
		snprintf(buf,sizeof(buf),"select id,name from name_reg1 where id>%d limit 1",female_name_id);

	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char **row = NULL;
	name.clear();
	if(pDb == NULL)
		return;
	if(!pDb->Query(buf))
		return;
	if((row = pDb->GetRow()) != NULL)
	{
		name = row[1];
		if(sex == 0)
			male_name_id = atoi(row[0]);
		else
			female_name_id = atoi(row[0]);
	}
	else	// 空了
	{
		if(sex == 0)
			male_name_id = 0;
		else
			female_name_id = 0;
	}
}

vector<uint16> GetFeiXianAward(int floor)
{
	const uint16 cnt = 5;
	const uint16 num[] = { 9, 11, 13, 15, 17 };
	vector<uint16> res;
	if (floor > 0 && floor <= cnt)
	{
		res.push_back(2818);
		res.push_back(num[floor-1]);
	}
	return res;
}

void GetExchangeTarItem(uint8 type,uint16 id,uint8 &srcNum,uint16 &tarItemId,uint16 &tarItemNum)
{
	const int ExItemId = 613;
	srcNum = 1;
	tarItemId = ExItemId;
	tarItemNum = 0;
	if(type == 1)	// 神将
	{
		const int ExZiZhiItemNum[] = {2,3,4,6,8,11,14,21,31,45,63,86,98,143,210,309,408,539,713,943,1247,1647,2178,2878,3684,4575,5640,6905,8400};
		uint16 zizhi = id;
		if(zizhi < 1 || zizhi > sizeof(ExZiZhiItemNum)/sizeof(ExZiZhiItemNum[0]))
			return;
		tarItemNum = ExZiZhiItemNum[zizhi-1];
	}
	else if(type == 2)	// 物品
	{
		if(id >= 2401 && id <= 2412)
			tarItemNum = 3;
		else if((id >= 2413 && id <= 2424) || (id == 2519) || (id == 2544) || id == 2563 || id == 2567 || id == 2824 || id == 2909)
			tarItemNum = 9;
		else if ((id >= 2421 && id <= 2533) || (id == 2547) || id == 2565 || id == 2569 || id == 2826 || id == 2911)
			tarItemNum = 15;
	}
}

int GetFeiXianExpByFloor(int floor,int level)
{
	const int baseExp[] = { 250,300,350,400,450 };
	const int expRatio[] = { 125,150,175,200,225 };
	if(floor < 1 || floor > 5)
		return 0;
	return expRatio[floor-1]*level + baseExp[floor - 1];
}

bool IsCanReturnTeamScene(int sceneId)
{
	int scene_Id[] = {
		COPY_ID_QIANG_HUA,
		COPY_ID_CHONG_WU_1,COPY_ID_CHONG_WU_2,COPY_ID_CHONG_WU_3,COPY_ID_CHONG_WU_4,
		COPY_ID_MONEY,
		COPY_ID_SHENG_JIE,
		COPY_ID_QIAN_NENG,
		COPY_ID_XIANG_QIAN,
		COPY_ID_CUI_LIAN,
		COPY_ID_CHONG_KAI,
		COPY_ID_SHI_LIAN,
	};
	for(uint8 i = 0; i < sizeof(scene_Id)/sizeof(int); i++)
	{
		if(sceneId == scene_Id[i])
			return false;
	}
	return true;
}

void NoticeClientChargeResult(uint32 roleId,uint8 res,int money,const char *str)
{
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	ShareUserPtr p = onlineUser.GetUserByRoleId(roleId);
	if(p.get() == NULL)
		return;
	CNetMessage msg;
	msg.SetType(MSG_CILENT_CHARGE);
	msg<<res<<money<<str;
	SingletonSocket::instance().SendMsg(p->GetSock(),msg);
}

static const int XCS_NPC_ID[] = {185,186,187,188,189,190};
uint8 GetXunChaShiNpcPos(int npcId)
{	
	for(uint8 i=0;i < sizeof(XCS_NPC_ID)/sizeof(XCS_NPC_ID[0]);i++)
	{
		if(XCS_NPC_ID[i] == npcId)
			return i;
	}
	return 0xff;
}

int GetXunChaShiNpcId(uint8 pos)
{
	if(pos >= sizeof(XCS_NPC_ID)/sizeof(XCS_NPC_ID[0]))
		return 0;
	return XCS_NPC_ID[pos];
}

int GetXunChaShiLevel()
{
	static int level = 30;
	static int day = 0;
	if(day == 0)
		day = GetDay();
	if(level == 30 || day != GetDay())
	{
		day = GetDay();
		
		// CGetDbConnect getDb;
		// CDatabaseSql *pDb = getDb.GetDbConnect();
		// if(pDb == NULL)
		// 	return level;
		//char **row = NULL;
		// if(!pDb->Query("select level from level_rank where rank=1 and type=1 limit 1"))	// 等级排行榜第一名等级
		// 	return level;
        vector<SLRankData> vecRankData;
		//改为内存数据
//		SingletonCRankDataMgr::instance().GetRankData(ECRT_Level,1,vecRankData);
		if(vecRankData.size() > 0)
			level = vecRankData[0].data;
		else	// 空了
			level = 30;
	}
	return level;
}

uint8 GetLogonDayNum()
{
	static uint8 HD_LogonDayNum = 0;
	if(HD_LogonDayNum == 0)
	{
		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		if(pDb == NULL)
			return 0;
		if(!pDb->Query("select count(id) from hd_7ridenglu"))
			return 0;
		char **row = NULL;
		if((row = pDb->GetRow()) != NULL)
			HD_LogonDayNum = atoi(row[0]);
	}
	return HD_LogonDayNum;
}


static const uint8 MAX_EXCHANGE_NUM = 100;
static const uint32 EXCHANGE_AWARD[][2] = {{30,852},{65,803},{100,2378}};	// 进度，id
static const uint32 EXCHANGE_BASIC_ITEM[] = {2487,2488,2489};
static uint32 lastDay = 0;

bool MakeExchangeMsg(CUser *pUser,CNetMessage &msg)
{
	if(pUser == NULL)
		return false;
	uint16 day = GetDropExItemDayIdx();
	if(day == 0)
	{
		//SendHuoDongFlag(18,2);
		return false;
	}
	uint32 time = (lastDay-day)*3600*24 + (23 - GetHour())*3600 + (59 - GetMinute())*60;
	
	vector<HD_Exchange_Data> data;
	SingletonCHDExchangeManager::instance().GetExchangeListByDayIdx(day,data);
	if(data.empty())
		return false;
	uint8 num = (uint8)data.size();
	msg<<day<<time<<num;
	for(uint8 i=0;i < num;i++)
	{
		msg<<data[i].id<<data[i].targetId<<data[i].targetNum;
		uint8 materialnum = 0;
		uint16 pos = msg.GetDataLen();
		msg<<materialnum;
		for(uint8 k=0;k < HD_Exchange_Data::MATERIAL_NUM;k++)
		{
			msg<<data[i].material[k]<<data[i].materialNum[k];
			materialnum++;
		}
		if(data[i].saveExt8 == 0)
			msg<<(uint8)0;
		else
			msg<<pUser->GetExtData8(data[i].saveExt8);
		msg<<data[i].exchangeNumLimit;
		msg.WriteData(pos,&materialnum,sizeof(materialnum));
	}

	uint8 max_exchangeNum = SingletonCHDExchangeManager::instance().GetTotalLimitNum();
	msg<<pUser->GetExtData8(331)<<max_exchangeNum;
	num = sizeof(EXCHANGE_AWARD)/sizeof(EXCHANGE_AWARD[0]);
	msg<<num;
	for(uint8 i=0;i < num;i++)
	{
		uint8 needExNum = (uint8)ceil(max_exchangeNum * EXCHANGE_AWARD[i][0] / 100.0);
		msg<<needExNum<<EXCHANGE_AWARD[i][1];
		uint8 flag = pUser->GetExtData8(332);
		uint8 getAward = (flag & (1<<i)) ? 1 : 0;
		msg<<getAward;
	}

	num = sizeof(EXCHANGE_BASIC_ITEM)/sizeof(EXCHANGE_BASIC_ITEM[0]);
	msg<<num;
	for(uint8 i=0;i < num;i++)
		msg<<EXCHANGE_BASIC_ITEM[i]<<pUser->GetItemNum(EXCHANGE_BASIC_ITEM[i]);
	return true;
}

bool ExchangeItem(CUser *pUser,CNetMessage &msg)
{
	if(pUser == NULL)
		return false;
	uint32 id=0;
	msg>>id;
	if(id == 0)
		return false;

	int day = GetDropExItemDayIdx();
	if(day == 0)
	{
		//SendHuoDongFlag(18,2);
		return false;
	}
	
	HD_Exchange_Data data = SingletonCHDExchangeManager::instance().GetExchangeDataByTargetId(day,id);
	if(data.id == 0 || data.saveExt8 == 0)
		return false;
	if(pUser->GetExtData8(data.saveExt8) >= (uint8)data.exchangeNumLimit)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_215,TIPS_FAILURE_COLOR);
		return true;
	}
	for(uint8 i=0;i < HD_Exchange_Data::MATERIAL_NUM;i++)
	{
		if(data.material[i] == HDAT_MONEY)
		{
			if(pUser->GetMoney() < (int)data.materialNum[i])
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_216,TIPS_FAILURE_COLOR);
				return true;
			}
		}
		else if(data.material[i] == HDAT_BANG_YB)
		{
			if(pUser->GetTongBao(1) < (int)data.materialNum[i])
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_217,TIPS_FAILURE_COLOR);
				return true;
			}
		}
		else if(data.material[i] == HDAT_YB)
		{
			if(pUser->GetTongBao() < (int)data.materialNum[i])
			{
				msg<<PRO_ERROR<<"";
				ShowJumpNotice(pUser,JUMP_NOTICE_YB);
				return true;
			}
		}
		else
		{
			if(pUser->GetItemNum(data.material[i]) < (int)data.materialNum[i])
			{
				char buf[128];
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_218,GetItemName(data.material[i]));
				msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
				return true;
			}
		}
	}

	for(uint8 i=0;i < HD_Exchange_Data::MATERIAL_NUM;i++)
	{
		if(data.material[i] == HDAT_MONEY)
			pUser->AddMoney(-data.materialNum[i]);
		else if(data.material[i] == HDAT_BANG_YB)
			pUser->AddTongBao(-(int)(data.materialNum[i]),1);
		else if(data.material[i] == HDAT_YB)
			pUser->AddTongBao(-(int)(data.materialNum[i]));
		else
			pUser->DelPackageById(data.material[i],data.materialNum[i]);
	}

	char buf[256];
	if(data.targetId == HDAT_MONEY)
	{
		pUser->AddMoney(data.targetNum);
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_219,data.targetNum);
	}
	else if(data.targetId == HDAT_BANG_YB)
	{
		pUser->AddTongBao(data.targetNum,1);
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_220,data.targetNum);
	}
	else if(data.targetId == HDAT_YB)
	{
		pUser->AddTongBao(data.targetNum,0);
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_221,data.targetNum);
	}
	else if(data.targetId == HDAT_EXP)
	{
		int exp = pUser->AddExp(data.targetNum);
		int worldExpPer = GetWorldExpPercent(pUser->GetLevel());
		if (worldExpPer > 0)
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_222,exp, worldExpPer);
		else
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_223,exp);
	}
	else if(data.targetId == HDAT_QIANNENG)
	{
		pUser->AddQianNeng(data.targetNum);
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_224,data.targetNum);
	}
	else
	{
		pUser->AddBangDingPackage(data.targetId,data.targetNum);
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_225,GetItemName(data.targetId),data.targetNum);
	}
	
	pUser->SetExtData8(data.saveExt8,pUser->GetExtData8(data.saveExt8)+1);	// 该类型次数
	pUser->SetExtData8(331,pUser->GetExtData8(331)+1);	// 总次数
	msg<<PRO_SUCCESS<<MakeStringColor(buf,TIPS_WARNING_COLOR);
	return true;
}

bool GetExchangeAward(CUser *pUser,CNetMessage &msg)
{
	if(pUser == NULL)
		return false;
	uint8 needExNum = 0;	// 进度(次数)
	msg>>needExNum;

	uint8 totalExNum = pUser->GetExtData8(331);
	uint8 flag = pUser->GetExtData8(332);
	uint8 idx = 0xff;
	uint8 num = sizeof(EXCHANGE_AWARD)/sizeof(EXCHANGE_AWARD[0]);
	uint8 max_exchangeNum = SingletonCHDExchangeManager::instance().GetTotalLimitNum();
	for(uint8 i=0;i < num;i++)
	{
		uint8 ExNum = (uint8)ceil(EXCHANGE_AWARD[i][0] * max_exchangeNum / 100.0);
		if(needExNum == ExNum)
		{
			idx = i;
			break;
		}
	}
	if(idx == 0xff)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_226,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return true;
	}

	if(totalExNum < needExNum)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_227,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return true;
	}
	if((flag & (1<<idx)) != 0)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_228,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return true;
	}
	pUser->AddBangDingPackage(EXCHANGE_AWARD[idx][1],1);
	flag |= (1<<idx);
	pUser->SetExtData8(332,flag);

	char buf[512];
	snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_229,GetItemName(EXCHANGE_AWARD[idx][1]));
	msg<<PRO_SUCCESS<<MakeStringColor(buf,TIPS_WARNING_COLOR);
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
	
	snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_230,ROLE_NAME_COLOR,pUser->GetName(),
		(int)needExNum,ITEM_NAME_COLOR,GetItemName(EXCHANGE_AWARD[idx][1]));
	SysInfoToAllUser(buf,true);
	return true;
}


int GetDropExItemDayIdx()
{
	static uint32 startStamp = 0;
	if(startStamp == 0)
	{
		string time = gyu::util::CIniFile::GetValue("DropExItemStartTime","huodong_time",gConfigFile);
		string dayNum = gyu::util::CIniFile::GetValue("DropExItemLastDay","huodong_time",gConfigFile);
		if(time.empty() || dayNum.empty())
			return 0;
		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		if(pDb == NULL)
			return 0;
		char sql[128];
		snprintf(sql,sizeof(sql),"select unix_timestamp(%s)",time.c_str());
		if(!pDb->Query(sql))
			return 0;
		char **row = NULL;
		if((row = pDb->GetRow()) != NULL)
		{
			startStamp = (uint32)atoi(row[0]);
			lastDay = (uint32)atoi(dayNum.c_str());
		}
		else
			return 0;
	}
	if(startStamp == 0 || lastDay == 0)
		return 0;
	uint16 dayIdx = 0;
	uint32 curTime = (uint32)GetSysTime();
	if(curTime > startStamp+24*3600*lastDay)
		return 0;
	dayIdx = (uint16)ceil((curTime - startStamp)/(24*3600.0));
	return dayIdx;
}

void UpdateWorldLevel()
{
	if(WorldLevel == 0)
		WorldLevel = WORLD_LEVEL_DEFAULT;

	const int COUNT_NUM = 30;
	// char sql[512];
	// char **row = NULL;
	// CGetDbConnect getDb;
	// CDatabaseSql *pDb = getDb.GetDbConnect();
	// if(pDb == NULL)
	// 	return;
	
	// snprintf(sql,sizeof(sql),"select sum(level) from level_rank where type=1 and rank<=%d",COUNT_NUM);
	// if(!pDb->Query(sql))
	// 	return;
	vector<SLRankData> vecRankData;
	//改为内存数据
//	SingletonCRankDataMgr::instance().GetRankData(ECRT_Level,COUNT_NUM,vecRankData);
	float sum = 0;
	for (int i=0;i<(int)vecRankData.size();i++)
	{
       sum += vecRankData[i].data;
	}
	if(sum > 0)
	{
		int level = int(sum/COUNT_NUM);
		if (level < WORLD_LEVEL_DEFAULT)
			WorldLevel = WORLD_LEVEL_DEFAULT;
		else
			WorldLevel = level;
	}
}

int GetWorldLevel()
{
	return WorldLevel;
}

void SetWorldLevel(int lv)
{
	WorldLevel = lv;
}

int GetPrimaryPetCopyRatio(CUser *pUser)
{
	if(pUser == NULL)
		return 0;
	uint8 ziNum = pUser->GetExtData8(95);
	uint8 lanNum = pUser->GetExtData8(96);
	uint8 lvNum = pUser->GetExtData8(97);
	uint8 ziChipNum = pUser->GetExtData8(132);
	uint8 num = ziNum + lanNum + lvNum + ziChipNum;
	int ratio = 0;
	if(ziNum == 0)
	{
		if(num >= 8)
			ratio = 100;
		else
			ratio = 20 + 10*num;
	}
	return ratio;
}


// type=1 元宝不足
void ShowJumpNotice(CUser *pUser,uint8 type)
{
	if(pUser == NULL)
		return;
	CNetMessage msg;
	msg.SetType(MSG_JUMP_NOTICE);
	msg<<type;
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

bool InDoubleExpHuoDong()
{
	static vector<int> doubleExpIdx;
	static int startTime = 0;
	static bool isInit = false;
	
	if(!isInit)
	{
		isInit = true;
		doubleExpIdx.clear();
	
		string time = gyu::util::CIniFile::GetValue("DropExItemStartTime","huodong_time",gConfigFile);
		string dayIdx = gyu::util::CIniFile::GetValue("ExpDoubleDayIdx","huodong_time",gConfigFile);
		if(time.empty() || dayIdx.empty())
			return false;
		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		if(pDb == NULL)
			return false;
		char sql[128];
		snprintf(sql,sizeof(sql),"select unix_timestamp(%s)",time.c_str());
		if(!pDb->Query(sql))
			return false;
		char **row = NULL;
		if((row = pDb->GetRow()) == NULL)
			return false;
		startTime = atoi(row[0]);
		
		char *split[20];
		int num = SplitLine(split,20,(char*)dayIdx.c_str());
		if(num > 0)
		{
			for(int i=0;i < num;i++)
				doubleExpIdx.push_back(atoi(split[i]));
		}
	}

	uint8 size = doubleExpIdx.size();
	int curTime = (int)GetSysTime();
	if(size == 0)
		return false;
	for(uint8 i=0;i < size;i++)
	{
		int idx = doubleExpIdx[i];
		if(curTime > startTime+3600*24*(idx-1) && curTime <= startTime+3600*24*idx)
			return true;
	}
	return false;
}

bool InDoubleMoneyHuoDong()
{
	static vector<int> doubleMoneyIdx;
	static int startTime = 0;
	static bool isInit = false;
	
	if(!isInit)
	{
		isInit = true;
		doubleMoneyIdx.clear();
	
		string time = gyu::util::CIniFile::GetValue("DropExItemStartTime","huodong_time",gConfigFile);
		string dayIdx = gyu::util::CIniFile::GetValue("MoneyDoubleDayIdx","huodong_time",gConfigFile);
		if(time.empty() || dayIdx.empty())
			return false;
		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		if(pDb == NULL)
			return false;
		char sql[128];
		snprintf(sql,sizeof(sql),"select unix_timestamp(%s)",time.c_str());
		if(!pDb->Query(sql))
			return false;
		char **row = NULL;
		if((row = pDb->GetRow()) == NULL)
			return false;
		startTime = atoi(row[0]);
		
		char *split[20];
		int num = SplitLine(split,20,(char*)dayIdx.c_str());
		if(num > 0)
		{
			for(int i=0;i < num;i++)
				doubleMoneyIdx.push_back(atoi(split[i]));
		}
	}

	uint8 size = doubleMoneyIdx.size();
	int curTime = (int)GetSysTime();
	if(size == 0)
		return false;
	for(uint8 i=0;i < size;i++)
	{
		int idx = doubleMoneyIdx[i];
		if(curTime > startTime+3600*24*(idx-1) && curTime < startTime+3600*24*idx)
			return true;
	}
	return false;
}

bool InDoubleItemNumHuoDong()
{
	static vector<int> doubleItemIdx;
	static int startTime = 0;
	static bool isInit = false;
	
	if(!isInit)
	{
		isInit = true;
		doubleItemIdx.clear();
	
		string time = gyu::util::CIniFile::GetValue("DropExItemStartTime","huodong_time",gConfigFile);
		string dayIdx = gyu::util::CIniFile::GetValue("ItemDoubleDayIdx","huodong_time",gConfigFile);
		if(time.empty() || dayIdx.empty())
			return false;
		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		if(pDb == NULL)
			return false;
		char sql[128];
		snprintf(sql,sizeof(sql),"select unix_timestamp(%s)",time.c_str());
		if(!pDb->Query(sql))
			return false;
		char **row = NULL;
		if((row = pDb->GetRow()) == NULL)
			return false;
		startTime = atoi(row[0]);
		
		char *split[20];
		int num = SplitLine(split,20,(char*)dayIdx.c_str());
		if(num > 0)
		{
			for(int i=0;i < num;i++)
				doubleItemIdx.push_back(atoi(split[i]));
		}
	}

	uint8 size = doubleItemIdx.size();
	int curTime = (int)GetSysTime();
	if(size == 0)
		return false;
	for(uint8 i=0;i < size;i++)
	{
		int idx = doubleItemIdx[i];
		if(curTime > startTime+3600*24*(idx-1) && curTime <= startTime+3600*24*idx)
			return true;
	}
	return false;
}

void AddHuoDongAward(CUser *pUser,int type,uint32 awardType,uint32 awardNum,uint16 petQuality,uint16 petQualityLv, bool isShow,bool isSave,char *pStr)
{
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();

	if(pUser == NULL || awardType == 0 || awardNum == 0)
		return;
	char buf[256];
	if(awardType < 60000)
	{
		pUser->AddBangDingPackage(awardType,awardNum);
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_231,GetItemName(awardType),awardNum);

		if (isShow)
			SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
	}
	else if(awardType == HDAT_MONEY)
	{
		pUser->AddMoney(awardNum);
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_232,awardNum);

		if (isShow)
			SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
	}
	else if(awardType == HDAT_BANG_YB)
	{
		pUser->AddTongBao(awardNum,1);
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_233,awardNum);

		if (isShow)
			SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
	}
	else if(awardType == HDAT_PET)
	{
		AddPet(pUser,awardNum, petQualityLv, petQuality);
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_234,GetPetName(awardNum));

		if (isShow)
			SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
	}
	else if(awardType == HDAT_YB)
	{
		pUser->AddTongBao(awardNum);
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_235,awardNum);

		if (isShow)
			SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
	}
	else if(awardType == HDAT_EXP)
	{
		pUser->AddExp(awardNum);
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_236,awardNum);

		if (isShow)
			SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
	}
	else if(awardType == HDAT_QIANNENG)
	{
		pUser->AddQianNeng(awardNum);
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_237,awardNum);

		if (isShow)
			SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
	}
	else if(awardType == HDAT_CHENGHAO)
	{
		pUser->AddTitle(awardNum);
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_238,GetTitleName(awardNum));
		if (isShow)
			SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
	}
	else if(awardType == HDAT_WING)
	{
		pUser->AddWing(awardNum);
		const char *pWName = GetWingName(awardNum);
		if (pWName != NULL)
		{
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_239,pWName);
			if (isShow)
				SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
		}
	}
	else if (awardType == HDAT_MOUNT)
	{
		if (awardNum > 0)
		{
			SMountConfig *pCfg = SingletonMountCfgMgr::instance().GetCfg(awardNum);
			if(pCfg == NULL)
				return;
			pUser->AddMount(awardNum);
			const char *pMName = GetMountName(awardNum);
			if(pMName != NULL)
			{
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_240,pMName);
				if (isShow)
					SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
			}
		}
	}
	else if (awardType == HDAT_CHRISTMASTREE_GROW_VALUE)
	{
		if (awardManager.InHuoDongTime(CHuoDongAwardManager::SHENGDAN_FENGSHOU)
			&& (awardManager.GetHuoDongPic(CHuoDongAwardManager::SHENGDAN_FENGSHOU) == CHuoDongAwardManager::CHRISTMAS_TREE_ID))
		{
			awardManager.AddChristmasChengZhangZhi(awardNum);
			snprintf(buf,sizeof(buf),LANGUAGE_LLD_0176,awardNum);
		}
	}
	else if (awardType == HDAT_CHRISTMASTREE_PERSON_VALUE)
	{
		if (awardManager.InHuoDongTime(CHuoDongAwardManager::SHENGDAN_FENGSHOU)
			&& (awardManager.GetHuoDongPic(CHuoDongAwardManager::SHENGDAN_FENGSHOU) == CHuoDongAwardManager::CHRISTMAS_TREE_ID))
		{
			uint32 gongxianDataId = 369;
			pUser->SetExtData32(gongxianDataId,pUser->GetExtData32(gongxianDataId) + awardNum);
			snprintf(buf,sizeof(buf),LANGUAGE_LLD_0177,awardNum);

			awardManager.UpdatePaiHang(pUser,CHuoDongAwardManager::SHENGDAN_FENGSHOU,pUser->GetExtData32(gongxianDataId));
		}
	}
	else
	{
		pUser->AddMaterial(awardType, awardNum, false, true, petQuality);
	}

	if (isSave)
	{
		if(pStr == NULL)
			SaveDate(pUser,type+500,awardType,buf);
		else
		{
			char tBuf[1024];
			snprintf(tBuf,sizeof(tBuf),"%s%s",pStr,buf);
			SaveDate(pUser,type+500,awardType,tBuf);
		}
	}
}
void AddHuoDongRewardDirect( CUser *pUser, uint32 type,uint32 idx,bool isShow)
{
	if( NULL == pUser )
		return;
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	SHuoDongAward award; 
	awardManager.GetAwardData(type,idx,award); 

	for(int counter=0; counter < SHuoDongAward::AWARD_NUM; ++counter ) 
	{ 
		AddHuoDongAward(pUser,type,award.award[counter],award.num[counter],award.petQuality[counter],award.petQualityLv[counter],isShow); 
	}
}

void SendHuoDongAwardMail(uint32 roleId,int level,SHuoDongAward &hdData,const char *pStr,int type,double ratio)
{
	if(pStr == NULL)
		return;	
	SMailData mdata;
	for(uint8 i=0;i < SHuoDongAward::AWARD_NUM ;i++)
	{
		mdata.AddAward(hdData.award[i], 0, hdData.num[i]);
	}
	SendSystemMail(roleId,pStr,&mdata);
	
	SaveDate(roleId,type+500,1,pStr);
}


//------------------活动-----------------------------------
bool GetHuoDongNewSign(uint32 huodongType)
{
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();

	bool isNew = false;
	uint32 huodongTime = awardManager.GetHuoDongStartTime(huodongType);
	uint32 curTime = GetSysTime();

	if (curTime >= huodongTime)
	{
		uint32 curDayTime = curTime - (curTime + 8 * 3600) % 86400;
		uint32 huodongDayTime = huodongTime - (huodongTime + 8 * 3600) % 86400;
		if (curDayTime == huodongDayTime)
			isNew = true;
	}
	
	return isNew;
}

void MakeHuoDongList(CNetMessage &msg, CUser *pUser)
{
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	vector<uint32> huodong_list;
	uint8 num = 0;
	uint16 pos = msg.GetDataLen();
	msg<<num;

	awardManager.GetHuoDongList(huodong_list);

	uint32 curTime = GetSysTime();
	for (uint32 i = 0; i < huodong_list.size(); i++)
	{
		if(huodong_list[i] != 0)
		{
			if (awardManager.InHuoDongTime(huodong_list[i]))
			{
				msg<<huodong_list[i]<<awardManager.GetHuoDongName(huodong_list[i])<<(uint8)GetHuoDongHotPoint(huodong_list[i], pUser);
				msg << (uint8)GetHuoDongNewSign(huodong_list[i]);
				uint32 leiji = awardManager.GetHuoDongLeijiTime(huodong_list[i]);
				if (leiji > curTime)
				{
					msg << (uint32)leiji - curTime;
				}
				else
				{
					msg << (uint32)0;
				}
				num++;
			}
		}
	}

	msg.WriteData(pos,&num,sizeof(num));
}

bool GetHuoDongHotPoint(uint32 id, CUser *pUser)
{
	bool hotPoint = false;
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	switch (id)
	{
		case CHuoDongAwardManager::MEIRI_SHOUCHONG:
		{
			if (pUser->HaveBitSet(550) &&  (!pUser->HaveBitSet(551)))
			{
				hotPoint = true;
			}

			if (pUser->HaveBitSet(595) &&  (!pUser->HaveBitSet(596))) // 微信首冲
			{
				hotPoint = true;
			}
			break;
		}

		case CHuoDongAwardManager::JIERI_LIBAO:
		case CHuoDongAwardManager::JIERI_LIBAO2:
		{
			uint32 curTime = GetSysTime();
			vector<HDPeiZhiInfo> libaoInfo;
			
			awardManager.GetPeiZhiInfo(libaoInfo, id);
			for (uint32 i = 0; i < libaoInfo.size(); i++)
			{
				uint32 lastTime = pUser->GetExtData32(libaoInfo[i].saveLastTimeId);
				uint32 cdTime = (lastTime == 0 || curTime > lastTime) ? 0 : (lastTime - curTime); 
				if ((cdTime <= 0) && 
					(pUser->GetExtData8(libaoInfo[i].saveCountId) < libaoInfo[i].num) &&
					(0 == (int)libaoInfo[i].price))
				{
					hotPoint = true;
					break;
				}
			}
			break;
		}
		case CHuoDongAwardManager::LEI_JI_CHONGZHI:
		case CHuoDongAwardManager::LEI_JI_CHONGZHI2:
		{
			uint32 totalCZDataId = 119;
			uint32 maskDataId = 121;
			if (id == CHuoDongAwardManager::LEI_JI_CHONGZHI2)
			{
				totalCZDataId = 137;
				maskDataId = 139;
			}
			
			vector<uint32> idxList;
			awardManager.GetAwardIdxList(id,idxList);
			if(! idxList.empty())
			{
				uint32 totalChongZhi = pUser->GetExtData32(totalCZDataId);
				uint32 getMask = pUser->GetExtData32(maskDataId);
				uint8 num = idxList.size();
				if(num > 32)
					num = 32;
				for(uint8 i=0;i < num;i++)
				{
					uint8 isGet = ((getMask&(1<<i)) == 0) ? (uint8)0 : (uint8)1;
					uint32 needYB = awardManager.GetNeedYB(id,idxList[i]);
					if (!isGet && totalChongZhi >= needYB)
					{
						hotPoint = true;
						break;
					}
				}
			}
			break;
		}
		case CHuoDongAwardManager::LEI_JI_XIAOFEI:
		case CHuoDongAwardManager::LEI_JI_XIAOFEI2:
		{
			uint32 totalCZDataId = 122;
			uint32 maskDataId = 124;
			if (id == CHuoDongAwardManager::LEI_JI_XIAOFEI2)
			{
				totalCZDataId = 140;
				maskDataId = 142;
			}
			
			vector<uint32> idxList;
			awardManager.GetAwardIdxList(id,idxList);
			if(! idxList.empty())
			{
				uint32 totalXiaoFei = pUser->GetExtData32(totalCZDataId);
				uint32 getMask = pUser->GetExtData32(maskDataId);
				uint8 num = idxList.size();
				if(num > 32)
					num = 32;
				for(uint8 i=0;i < num;i++)
				{
					uint32 needYB = awardManager.GetNeedYB(id,idxList[i]);
					uint8 isGet = ((getMask&(1<<i)) == 0) ? (uint8)0 : (uint8)1;
					if (!isGet && totalXiaoFei >= needYB)
					{
						hotPoint = true;
						break;
					}
				}
			}
			break;
		}
		case CHuoDongAwardManager::XIAN_CHONG_DASHOUJI:
		{
			uint8 xcdsj_max_stage = 0; // 档次数
			uint8 xcdsj_item_num = 0; // 每档次物品个数

			GetXCDSJArrayInfo(xcdsj_max_stage, xcdsj_item_num);
			
			for (int i = 0; i < xcdsj_max_stage; ++i)
			{
				int hasCnt = pUser->GetPetQualityNum(GetXCDSJConditionInfo(i,0));
				int needCnt = GetXCDSJConditionInfo(i,1);
				bool isGot = pUser->HaveBitSet(GetXCDSJConditionInfo(i,2));
				if ((hasCnt >= needCnt) && (! isGot))
				{
					hotPoint = true;
					break;
				}
			}

			break;
		}
		case CHuoDongAwardManager::QIANG_ZHUANG_LINGHAOLI:
		{
/*			uint8 qzlhl_max_stage = 0; // 档次数
			uint8 qzlhl_item_num = 0; // 每档次物品个数
			GetQZLHLArrayInfo(qzlhl_max_stage,qzlhl_item_num);
			for (int i = 0; i < qzlhl_max_stage; ++i)
			{
				int hasCnt = pUser->GetEquipStrengthLvNum(GetQZLHLConditionInfo(i,0));
				int needCnt = GetQZLHLConditionInfo(i,1);
				bool isGot = pUser->HaveBitSet(GetQZLHLConditionInfo(i,2));
				if ((hasCnt >= needCnt) && (! isGot))
				{
					hotPoint = true;
					break;
				}
			}
*/
			break;
		}
		case CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO:
		case CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO2:
		case CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO3:
		case CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO4:
		case CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO5:
		case CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO6:
		case CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO7:
		case CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO8:
		case CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO9:
		case CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO10:
		{
			uint32 totalCZDataId = 0;
			uint32 maskDataId = 0;
			if ( ! GetChongZhiFanYBDataId(id,totalCZDataId,maskDataId))
				break;
			
			vector<uint32> idxList;
			awardManager.GetAwardIdxList(id,idxList);
			if(! idxList.empty())
			{
				uint32 totalChongZhi = pUser->GetExtData32(totalCZDataId);
				uint32 getMask = pUser->GetExtData32(maskDataId);
				uint8 num = idxList.size();
				if(num > 32)
					num = 32;
				for(uint8 i=0;i < num;i++)
				{
					uint8 isGet = ((getMask&(1<<i)) == 0) ? (uint8)0 : (uint8)1;
					uint32 needYB = awardManager.GetNeedYB(id,idxList[i]);
					
					if (!isGet && totalChongZhi >= needYB)
					{
						hotPoint = true;
						break;
					}
				}
			}
			break;
		}
		case CHuoDongAwardManager::HONGLI_CHONGZHI:
		case CHuoDongAwardManager::HONGLI_CHONGZHI2:
		case CHuoDongAwardManager::HONGLI_CHONGZHI3:
		case CHuoDongAwardManager::HONGLI_CHONGZHI4:
		case CHuoDongAwardManager::HONGLI_CHONGZHI5:
		case CHuoDongAwardManager::HONGLI_CHONGZHI_RMB:
		case CHuoDongAwardManager::HONGLI_XIAOFEI:
		case CHuoDongAwardManager::HONGLI_XIAOFEI2:
		case CHuoDongAwardManager::HONGLI_XIAOFEI3:
		case CHuoDongAwardManager::HONGLI_XIAOFEI4:
		case CHuoDongAwardManager::HONGLI_XIAOFEI5:
		{
			uint32 timeDataId = 0;
			uint32 leijiDataId = 0;
			uint32 maskDataId = 0;

			if (!GetHongLiDataId(id,timeDataId,leijiDataId, maskDataId))
				break;

			uint32 hongliLeijiTime = awardManager.GetHuoDongLeijiTime(id);
			uint32 curTime = GetSysTime();
			uint32 cdTime = (curTime > hongliLeijiTime) ? 0 : hongliLeijiTime - curTime;
			
			if (cdTime == 0)
			{
				vector<HDPeiZhiInfo> info;
				uint32 leijiYB = pUser->GetExtData32(leijiDataId);
				uint32 index = 0;
				uint32 curDay = (curTime - hongliLeijiTime) / (24 * 3600) + 1; 

				awardManager.GetPeiZhiInfo(info, id);
				for (uint8 i = 0;  i < info.size(); i++)
				{
					if (info[i].YB < leijiYB)
					{
						index = info[i].index;
					}
				}

				if (index != 0)
				{
					vector<uint32> idxList;
					awardManager.GetAwardIdxList(id,index,idxList);
					uint32 getMask = pUser->GetExtData32(maskDataId);
					
					for (uint32 k = 0; k < idxList.size(); k++)
					{
						uint32 getDay = awardManager.GetIdx3(id, idxList[k]);
						uint8 isGet = ((getMask&(1<<getDay)) == 0) ? (uint8)0 : (uint8)1;
					
						if (!isGet && (curDay == getDay))
						{
							hotPoint = true;
							break;
						}
					}
				}
			}
			break;
		}
		case CHuoDongAwardManager::SHEN_CHONG_BANG:
		{
			break;
		}
		case CHuoDongAwardManager::EQUIP_QIANGHUA_BANG:
		{
			break;
		}
		case CHuoDongAwardManager::ROLE_LEVEL_BANG:
		{
			break;
		}
		case CHuoDongAwardManager::ZHAN_LI_BANG:
		{
			break;
		}
		case CHuoDongAwardManager::CHONG_ZHI_BANG:
		{
			break;
		}
		case CHuoDongAwardManager::QIANGHUA_KUANGHUAN:
		{
/*			if (awardManager.InHuoDongTime(id))
			{
				vector<HDPeiZhiInfo> huodong_info;
				uint32 getMask = pUser->GetExtData32(214);
			
				awardManager.GetPeiZhiInfo(huodong_info,id);
				
				for (uint32 i = 0; i < huodong_info.size(); ++i)
				{
					uint8 isGet = ((getMask&(1<<huodong_info[i].index)) == 0) ? (uint8)0 : (uint8)1;
					if (! isGet && (pUser->GetEquipStrengthLvNum(huodong_info[i].lv) >= huodong_info[i].count))
					{
						hotPoint = true;
						break;
					}
				}
				
			}
*/
			break;
		}
		case CHuoDongAwardManager::SHENGJIE_LETIAN:
		{
/*			if (awardManager.InHuoDongTime(id))
			{
				vector<HDPeiZhiInfo> huodong_info;
				uint32 getMask = pUser->GetExtData32(216);
			
				awardManager.GetPeiZhiInfo(huodong_info,id);
				
				for (uint32 i = 0; i < huodong_info.size(); ++i)
				{
					uint8 isGet = ((getMask&(1<<huodong_info[i].index)) == 0) ? (uint8)0 : (uint8)1;
					if (! isGet && (pUser->GetEquipQualityLvNum(huodong_info[i].lv) >= huodong_info[i].count))
					{
						hotPoint = true;
						break;
					}
				}
				
			}
*/
			break;
		}
		case CHuoDongAwardManager::LIANXU_CHONGZHI_ORI:
		case CHuoDongAwardManager::LIANXU_CHONGZHI_DELUXE:
		{
			if (awardManager.InHuoDongTime(id))
			{
//				uint32 firstTimeDataId = 262;
				uint32 YBMaskDataId = 263;
				uint32 getOriMaskDataId = 264;
				uint32 getSpeMaskDataId = 265;
				if (id == CHuoDongAwardManager::LIANXU_CHONGZHI_DELUXE)
				{
//					firstTimeDataId = 268;
					YBMaskDataId = 269;
					getOriMaskDataId = 270;
					getSpeMaskDataId = 271;

				}

				uint32 curTime = GetSysTime();
				
				//uint32 firstTime = GetExtData32(firstTimeDataId);  不按照首充时间计算
				uint32 firstTime = awardManager.GetHuoDongStartTime(id);
				uint8 costDay = curTime > firstTime ? ((curTime - firstTime) / (24 * 3600) + 1) : 1;
				if (costDay > 32)
					costDay = 32;
	
				const int ORI = 1;
				const int SPE = 2;
				uint32 YBMask = pUser->GetExtData32(YBMaskDataId);
				uint8 YBState = ((YBMask&(1<<costDay)) == 0) ? (uint8)0 : (uint8)1;
				if (YBState == 1)
				{
					uint32 getOriMask = pUser->GetExtData32(getOriMaskDataId);
					uint32 idx = awardManager.GetAwardIdx(id,ORI,costDay);
					if (idx != 0)
					{
						uint8 getOriState = ((getOriMask&(1<<costDay)) == 0) ? (uint8)0 : (uint8)1;
						if (getOriState == 0)
						{
							hotPoint = true;
							break;
						}
					}
	
					uint32 getSpeMask = pUser->GetExtData32(getSpeMaskDataId);
					idx = awardManager.GetAwardIdx(id,SPE,costDay);
					if (idx != 0)
					{
						uint8 getSpeState = ((getSpeMask&(1<<costDay)) == 0) ? (uint8)0 : (uint8)1;
						if (getSpeState == 0)
						{
							hotPoint = true;
							break;
						}
					}
				}
			}
			break;
		}
		case CHuoDongAwardManager::JIJIN_FANLI:
		case CHuoDongAwardManager::JIJIN_FANLI2:
		case CHuoDongAwardManager::JIJIN_FANLI3:
		{
			uint32 buyRecordDataId;
			uint32 buyFirstTimeDataId;
			uint32 getMaskDataId;
			uint32 startTimeDataId;

			if (!GetJiJinFanLiDataId(id,buyRecordDataId,startTimeDataId,buyFirstTimeDataId,getMaskDataId))
				break;

			uint8 buyRecord = pUser->GetExtData8(buyRecordDataId);
			uint32 buyFirstTime = pUser->GetExtData32(buyFirstTimeDataId);
			uint32 getMask = pUser->GetExtData32(getMaskDataId);
			uint32 curTime = GetSysTime();

			if (!awardManager.InHuoDongTime(id))
				break;

			uint8 costDay = 1;
			if (buyFirstTime != 0)
			{
				costDay = curTime > buyFirstTime ? ((curTime - buyFirstTime) / (24 * 3600) + 1) : 1;
				if (costDay > 31)
					costDay = 31;
			}
			
			vector<HDPeiZhiInfo> peizhiInfo;
			awardManager.GetPeiZhiInfo(peizhiInfo,id);

			for (uint32 i = 0; i < peizhiInfo.size(); i++)
			{
				uint8 buyState = ((buyRecord&(1<<peizhiInfo[i].index)) == 0) ? (uint8)0 : (uint8)1;
				if (buyState == 1)
				{
					uint32 idx = awardManager.GetAwardIdx(id,peizhiInfo[i].index,costDay);
					SHuoDongAward award;
					awardManager.GetAwardData(id,idx,award);

					if (award.idx3 > 0 && award.idx3 < 32)
					{
						uint8 getState = ((getMask&(1<<award.idx3)) == 0) ? (uint8)0 : (uint8)1;
						if (getState == 0)
						{
							hotPoint = true;
							break;
						}
					}
				}
			}
			break;
		}
		case CHuoDongAwardManager::MEIRI_HUANHAOLI:
		{
			if (!awardManager.InHuoDongTime(id))
				break;

			vector <HDExchangeInfo> infoList;
			awardManager.GetExchangeInfo(id,infoList);
			if (infoList.size() <= 0)
				break;

			for (uint32 i = 0; i < infoList.size(); i++)
			{
				if ((infoList[i].saveExt8) > 0 && (pUser->GetExtData8(infoList[i].saveExt8) < infoList[i].exchange_num_limit) && infoList[i].isShow == 1)
				{
					bool isHot = true;
					for (uint32 j = 0; j < HDExchangeInfo::MATERIAL_NUM; j++)
					{
						if (infoList[i].material[j] > 0 && infoList[i].material_num[j] > 0
							&& (uint32)pUser->GetItemNum(infoList[i].material[j]) < infoList[i].material_num[j])
						{
							isHot = false;
							break;
						}
					}
					if (isHot)
					{
						hotPoint = true;
						break;
					}
				}
			}
			break;
		}
		case CHuoDongAwardManager::DAOJUHUISHOU:
		{        
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
			uint32 hd_type = CHuoDongAwardManager::DAOJUHUISHOU;

			if(!awardManager.InHuoDongTime(hd_type))
				break;
			std::vector<HDExchangeInfo> infoVec;
			infoVec.clear();
			awardManager.GetExchangeInfo(hd_type,infoVec);
			std::vector<HDExchangeInfo>::iterator vec_iter = infoVec.begin();
			for( ; vec_iter != infoVec.end(); ++vec_iter )
			{        
				if( vec_iter->material[0] !=0 && vec_iter->material_num[0] !=0 )
				{        
					if((uint32)pUser->GetItemNum(vec_iter->material[0]) >= vec_iter->material_num[0])
					{        
						hotPoint = true;
						break;
					}        
				}        
			}//end of for 
			break;
		}
		case CHuoDongAwardManager::QIANG_HONGBAO:
		{        
			CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
			uint32 hd_type = CHuoDongAwardManager::QIANG_HONGBAO;

			if(!awardManager.InHuoDongTime(hd_type))
				break;


			uint32 leijiDataId = 406;
			uint32 isSendHongBaoBitId = 583;

			vector<HDPeiZhiInfo> info;
			awardManager.GetPeiZhiInfo(info,hd_type);
			if (info.size() != 1)
				break;

			uint32 myMoney = pUser->GetExtData32(leijiDataId);
			uint32 needMoney = info[0].price;
		
			if (! pUser->HaveBitSet(isSendHongBaoBitId) && myMoney >= needMoney)
				hotPoint = true;
			
			break;
		}
		case CHuoDongAwardManager::MOGU:
			{
				CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
				uint32 hd_type = CHuoDongAwardManager::MOGU;
				if(!awardManager.InHuoDongTime(hd_type))
					break;
				int waterDay = awardManager.GetMoGuWaterDay();
				int curDayIdx = GetMoGuCurrentDayIdx(awardManager.GetHuoDongStartTime(hd_type));
				int waterTimes = pUser->GetMoGuWaterTimes();
				int bugTimes = pUser->GetMoGuBugTimes();
				if(curDayIdx <= waterDay)
				{
					if(waterTimes > 0 || bugTimes > 0)
					{
						hotPoint = true;
						break;
					}
				}
				else
				{
					if(pUser->HaveBitSet(602))
						break;
					int moguCZ = pUser->GetMoGuCZ();
					int step1CZ = awardManager.GetMoGuStep1CZ();
					if(moguCZ >= step1CZ)
					{
						hotPoint = true;
						break;
					}
				}
			}
			break;
			
		
		default:
		{
			break;
		}
	}

	return hotPoint;
}

// 仙神将大收集的信息
const uint8 xcdsj_max_stage = 3; // 档次数
const uint8 xcdsj_item_num = 3; // 每档次物品个数
const uint8 xcdsj_parm_num = 2; // 物品属性数
static uint16 XCDSJ_REWARD[xcdsj_max_stage][xcdsj_item_num][xcdsj_parm_num] = {
	{
		{2370,5},{2310,5},{0,0}
	},
	{
		{2370,8},{614,8},{0,0}
	},
	{
		{2370,15},{614,15},{0,0}
	}
};
static uint16 XCDSJ_CONDITION[xcdsj_max_stage][xcdsj_item_num] = {
	{4,1,326}, // 品质、数量、位变量
	{4,2,327},
	{4,3,328}
};

void GetXCDSJArrayInfo(uint8 &max_stage,uint8 &item_num)
{
	max_stage = xcdsj_max_stage;
	item_num = xcdsj_item_num;
}

uint16 GetXCDSJRewardInfo(int i, int j, int k)
{
	return XCDSJ_REWARD[i][j][k];
}

uint16 GetXCDSJConditionInfo(int i, int j)
{
	return XCDSJ_CONDITION[i][j];
}

//强装领好礼
const uint8 qzlhl_max_stage = 3; // 档次数
const uint8 qzlhl_item_num = 3; // 每档次物品个数
const uint8 qzlhl_parm_num = 2; // 物品属性数
static uint16 QZLHL_REWARD[qzlhl_max_stage][qzlhl_item_num][qzlhl_parm_num] = {
	{
		{852,3},{502,2},{0,0}
	},
	{
		{853,1},{502,2},{801,1}
	},
	{
		{853,2},{802,1},{611,2}
	}
};
static uint16 QZLHL_CONDITION[qzlhl_max_stage][qzlhl_item_num] = {
	{6,9,329}, // 强化等级、装备数量、位变量
	{8,9,330},
	{9,9,331}
};

void GetQZLHLArrayInfo(uint8 &max_stage,uint8 &item_num)
{
	max_stage = qzlhl_max_stage;
	item_num = qzlhl_item_num;
}

uint16 GetQZLHLRewardInfo(int i, int j, int k)
{
	return QZLHL_REWARD[i][j][k];
}

uint16 GetQZLHLConditionInfo(int i, int j)
{
	return QZLHL_CONDITION[i][j];
}

void NoticeHuoDongHotPoint(CUser *pUser, uint32 huodongId)
{
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_HUODONG_HOTPOINT);
	msg<<huodongId<<(uint8)GetHuoDongHotPoint(huodongId,pUser);
	msg<<GetHuoDongNewSign(huodongId);
	
	sock.SendMsg(pUser->GetSock(),msg);
}


void SaveDate(CUser *pUser,int type,int data,const char *str)
{
	uint32 roleId = 0;
	if(pUser != NULL)
		roleId = pUser->GetRoleId();
	SaveDate(roleId,type,data,str);
}

void SaveDate(int user_id,int type,int data,const char *str)
{
	string sstr = "";
	if(str != NULL)
		sstr = str;
	uint16 nlen = sstr.size();

	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_SERVER_SAVE_DATA);
	msg<<user_id<<type<<(uint8)1<<data;
	msg<<nlen;
	msg.WriteData((void *)sstr.c_str(),nlen);
	sock.SendServerMsg(EST_LONG, msg);
}

void SaveDate(int user_id,int type,vector<int> &data,vector<string> &str)
{
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	uint8 size = data.size() > str.size() ? str.size() : data.size();
	msg.SetType(MSG_SERVER_SAVE_DATA);
	msg<<user_id;
	msg<<type;
	msg<<size;
	for(uint8 i=0;i < size;i++)
	{
		uint16 nlen = str[i].size();
		msg<<data[i];
		msg<<nlen;
		msg.WriteData((void *)str[i].c_str(),nlen);
	}
	sock.SendServerMsg(EST_LONG, msg);
}

void MakeMountCollectMsg(CNetMessage &msg)
{
	uint8 size = sizeof(MOUNT_COLLECT_DATA)/sizeof(MOUNT_COLLECT_DATA[0]);
	msg<<size;
	for(uint8 i=0;i < size;i++)
	{
		msg<<MOUNT_COLLECT_DATA[i][0]<<MOUNT_COLLECT_DATA[i][1]<<MOUNT_COLLECT_DATA[i][2]<<MOUNT_COLLECT_DATA[i][3]<<MOUNT_COLLECT_DATA[i][4]
			<<MOUNT_COLLECT_DATA[i][5]<<MOUNT_COLLECT_DATA[i][6]<<MOUNT_COLLECT_DATA[i][7]<<MOUNT_COLLECT_DATA[i][8]<<MOUNT_COLLECT_DATA[i][9]
			<<MOUNT_COLLECT_DATA[i][10];
	}
}

// 获取属性战斗力
uint32 GetAttrPower(vector<SAttrData>& atts)
{
	uint32 power = 0;
	for (size_t i = 0; i < atts.size(); ++i)
	{
		SAttrData& data = atts[i];
		CAttrCfgMgr &mgr = SingletonCAttrCfgMgr::instance();
		power += data.attrValue * mgr.GetTypeRatio(data.attrType);
	}
	return power;
}

void SetOffLineTitle(uint32 roleId, uint8 title)
{
	CUser *pUser = new CUser;
	if(pUser == NULL)
		return;
	
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
	{
		delete pUser;
		return;
	}

	char **row = NULL;
	char sql[4096];
	snprintf(sql, sizeof(sql), "select title from role_info where id=%u",roleId);
	if(!pDb->Query(sql) || (row = pDb->GetRow()) == NULL)
	{
		delete pUser;
		return;
	}
	
	pUser->ReadTitle(row[0]);
	pUser->AddTitle(title);
	string str;
	pUser->GetTitleStr(str);
	snprintf(sql, sizeof(sql), "update role_info set title='%s' where id=%u",str.c_str(),roleId);
	pDb->Query(sql);
	delete pUser;
}

void MakeTitleRoleData(uint32 roleId,CNetMessage &msg)
{
	msg.ReWrite();
	msg.SetType(MSG_TMP_HUODONG);
	msg<<(uint8)HD_ROLE_INFO;
	
	CUser *pUser = NULL;
	ShareUserPtr Ptr = SingletonOnlineUser::instance().GetUserByRoleId(roleId);
	pUser = Ptr.get();
	if(pUser == NULL)
	{
		pUser = new CUser;
		if(pUser == NULL)
		{
			msg<<PRO_ERROR<<roleId;
			return;
		}
		else
		{
			CGetDbConnect getDb;
			CDatabaseSql *pDb = getDb.GetDbConnect();
			if(pDb == NULL)
			{
				delete pUser;
				msg<<PRO_ERROR<<roleId;
				return;
			}

			char sql[512];
			char **row = NULL;
			//                        0    1    2   3     4
			snprintf(sql,sizeof(sql),"select sex,name,level,head,mount from role_info where id=%u",roleId);
			if(!pDb->Query(sql))
			{
				delete pUser;
				msg<<PRO_ERROR<<roleId;
				return;
			}
			if((row = pDb->GetRow()) != NULL)
			{
				pUser->SetMount(row[4]);
				msg<<PRO_SUCCESS<<roleId<<(uint8)atoi(row[0])<<(uint8)atoi(row[3])<<(uint8)atoi(row[2])<<row[1];
				pUser->MakeOtherMount(msg);
				delete pUser;
			}
			else
			{
				delete pUser;
				msg<<PRO_ERROR<<roleId;
				return;
			}
		}
	}
	else
	{
		msg<<PRO_SUCCESS<<roleId<<pUser->GetSex()<<pUser->GetHead()<<pUser->GetLevel()<<pUser->GetName();
		pUser->MakeOtherMount(msg);
	}
}

void AddHDShowLog(uint32 giveRoleId, vector<string> &giveLog, uint32 getId, vector<string> &getLog, uint32 huodong_type)
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;

	uint32 startTime = SingletonCHuoDongAwardManager::instance().GetHuoDongStartTime(huodong_type);
	uint32 curTime = GetSysTime();	
	char sql[40960];
	snprintf(sql, sizeof(sql), "insert INTO `hd_show_log` (`id`,`type`, `role_id`, `data`,`start_time`,`time`,`hd_type`) values ");
	
	
	for (uint32 i = 0; i < giveLog.size(); i++)
	{
		int size = strlen(sql);
		snprintf(sql + size, sizeof(sql) - size, " (NULL, '%d','%d','%s','%d', '%d','%d'),", 0, giveRoleId, giveLog[i].c_str(),startTime, curTime,huodong_type);
	}
	for (uint32 i = 0; i < getLog.size(); i++)
	{
		int size = strlen(sql);
		snprintf(sql + size, sizeof(sql) - size, " (NULL, '%d','%d','%s','%d', '%d','%d'),", 1, getId, getLog[i].c_str(),startTime, curTime,huodong_type);
	}

	sql[strlen(sql) - 1] = ';';
	sql[sizeof(sql) - 1] = '\0';
	pDb->Query(sql);
}

void AddFestivalRecord(vector<FestivalRecord> &record,uint32 hd_type)
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;

	uint32 startTime = SingletonCHuoDongAwardManager::instance().GetHuoDongStartTime(hd_type);

	for (uint32 i = 0; i < record.size(); i++)
	{
		char sql[2048];
		snprintf(sql, sizeof(sql), "select role_id from festival_record where hd_type = %d and role_id = %d and type = %d and start_time = %d",hd_type,record[i].role_id,record[i].type,startTime);
		if (pDb->Query(sql))
		{
			if (pDb->GetRow() != NULL)
				record[i].isFirst = false;
			else
				record[i].isFirst = true;
		}
		else
			continue;

		
		if (record[i].isFirst)
		{
			if (strlen(record[i].bang_name.c_str()) == 0)
			{
				snprintf(sql, sizeof(sql), "insert INTO `festival_record` (`id`,`type`,`role_id`,`role_name`,`level`,`num1`,`num2`,`score`,`start_time`,`xiang`,`sex`,`hd_type`) values  (NULL, %d, %d, '%s', %d, %d, %d, %d, %d,%d,%d,%d)"
									,record[i].type, record[i].role_id, record[i].role_name.c_str(),record[i].level,record[i].num[0],record[i].num[1],record[i].score,startTime,record[i].xiang,record[i].sex,hd_type);
			}
			else
			{
				snprintf(sql, sizeof(sql), "insert INTO `festival_record` (`id`,`type`,`role_id`,`role_name`,`bang_name`,`level`,`num1`,`num2`,`score`,`start_time`,`xiang`,`sex`,`hd_type`) values  (NULL, %d, %d, '%s', '%s', %d, %d, %d, %d, %d,%d,%d,%d)"
									,record[i].type, record[i].role_id, record[i].role_name.c_str(),record[i].bang_name.c_str(),record[i].level,record[i].num[0],record[i].num[1],record[i].score,startTime,record[i].xiang,record[i].sex,hd_type);
			}
		}
		else
		{
			if (strlen(record[i].bang_name.c_str()) == 0)
			{
				snprintf(sql, sizeof(sql), "update festival_record set level = %d,num1 = %d,num2 = %d,score = %d,xiang=%d where hd_type = %d and role_id = %d and type = %d and start_time = %d;"
									,record[i].level, record[i].num[0], record[i].num[1],record[i].score,record[i].xiang,hd_type,record[i].role_id,record[i].type,startTime);
			}
			else
			{
				snprintf(sql, sizeof(sql), "update festival_record set bang_name = '%s',level = %d,num1 = %d,num2 = %d,score = %d,xiang=%d where hd_type = %d and role_id = %d and type = %d and start_time = %d;"
									,record[i].bang_name.c_str(),record[i].level, record[i].num[0], record[i].num[1],record[i].score,record[i].xiang,hd_type,record[i].role_id,record[i].type,startTime);
			}
		}
		
		sql[sizeof(sql) - 1] = '\0';
		pDb->Query(sql);
	}
	
	
}

void GiveFestivalPresent(CUser *pUser,uint32 roleId, vector<GoodsInfo> &info, CNetMessage &msg)
{
	uint32 before_num[2] = {0, 0};
	string get_name;
	vector<string> giveLog;
	vector<string> getLog;
	vector<FestivalRecord> record;
	char buf[512];
	uint32 hd_type = CHuoDongAwardManager::FESTIVAL;
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 hdStartTime = awardManager.GetHuoDongStartTime(hd_type);
	uint32 hdTimeDataId = 218;
// get
	ShareUserPtr pU = SingletonOnlineUser::instance().GetUserByRoleId(roleId);
	CUser *p = pU.get();
	if(p != NULL)
	{
		if (p->GetExtData32(hdTimeDataId) != hdStartTime)
			p->FestivalClearData();

		get_name = p->GetName();

		FestivalRecord r;
		r.type = 1;
		r.role_id = roleId;
		r.role_name = p->GetName();
		r.bang_name = p->GetBangName();
		r.level = p->GetLevel();
//		r.xiang = p->GetXiang();
		r.sex = p->GetSex();

		before_num[0] = 0;
		before_num[1] = 0;
		for (uint32 i = 0; i < info.size(); i++)
		{
			before_num[i] = p->GetExtData32(info[i].get_data_id);
			if (info[i].num > 0)
			{
				p->SetExtData32(info[i].get_data_id, p->GetExtData32(info[i].get_data_id) + info[i].num);

				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_241,ROLE_NAME_COLOR,pUser->GetName(),info[i].num,GetItemName(info[i].award));
				getLog.push_back(buf);

				if (pUser->GetRoleId() == roleId) {
					snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_242,info[i].num,GetItemName(info[i].award));
					SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
				}
				else
				{
					snprintf(buf,sizeof(buf),LANGUAGE_LLD_0005, GetItemName(info[i].award));
					SendSysInfo(p,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
				}
			}
			
			r.num[i] = p->GetExtData32(info[i].get_data_id);
			r.score += r.num[i] * info[i].score_get;
		}
		if (before_num[0] == 0 && before_num[1] == 0)
			r.isFirst = true;
		else
			r.isFirst = false;
		
		record.push_back(r);
		
		p->SetHDShowHIstory(1, getLog,hd_type);
	}
	else
	{
		p = new CUser;
		if(p == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_244,TIPS_FAILURE_COLOR);
			return;
		}

		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		if(pDb == NULL)
		{
			delete p;
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_245,TIPS_FAILURE_COLOR);
			return;
		}

		char **row = NULL;
		char sql[4096];
		//                           0   1      2      3   4    5
		snprintf(sql, sizeof(sql), "select name,level,bank_item,head,sex,package from role_info where id=%u",roleId);
		if(!pDb->Query(sql) || (row = pDb->GetRow()) == NULL)
		{
			delete p;
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_246,TIPS_FAILURE_COLOR);
			return;
		}
		uint32 before_num[2] = {0, 0};
		FestivalRecord r;
		r.type = 1;
		r.role_id = roleId;
		r.role_name = row[0];
		r.level = atoi(row[1]);
		r.xiang = atoi(row[3]);
		r.sex = atoi(row[4]);

		get_name = row[0];
		p->SetBankItem(row[2]);
		p->SetPackage(row[5]);
		before_num[0] = 0;
		before_num[1] = 0;
		
		if (p->GetExtData32(hdTimeDataId) != hdStartTime)
			p->FestivalClearData();

		for (uint32 i = 0; i < info.size(); i++)
		{
			before_num[i] = p->GetExtData32(info[i].get_data_id);
			if (info[i].num > 0)
			{
				p->SetExtData32(info[i].get_data_id, p->GetExtData32(info[i].get_data_id) + info[i].num);

				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_247,ROLE_NAME_COLOR,pUser->GetName(),info[i].num,GetItemName(info[i].award));
				getLog.push_back(buf);
			}
			r.num[i] = p->GetExtData32(info[i].get_data_id);
			r.score += r.num[i] * info[i].score_get;
		}
		
		if (before_num[0] == 0 && before_num[1] == 0)
			r.isFirst = true;
		else
			r.isFirst = false;
		
		string str;
		string pkgStr;
		p->GetBankItem(str);
		p->GetPackage(pkgStr);
		boost::format fmt("update role_info set bank_item='%1%',package='%2%' where id=%3%");
		fmt % str.c_str() % pkgStr.c_str() % roleId;
		pDb->Query(fmt.str().c_str());
		delete p;
		p = NULL;

		snprintf(sql, sizeof(sql), "select bang_pai.name from bang_pai_role,bang_pai where bang_pai_role.role_id = %d and bang_pai_role.bangpai_id = bang_pai.id;",roleId);
		if(pDb->Query(sql) && (row = pDb->GetRow()) != NULL)
		{
			r.bang_name = row[0];
		}
		record.push_back(r);

	}	

//give
	FestivalRecord r;
	r.type = 0;
	r.role_id = pUser->GetRoleId();
	r.role_name = pUser->GetName();
	r.bang_name = pUser->GetBangName();
	r.level = pUser->GetLevel();
//	r.xiang = pUser->GetXiang();
	r.sex = pUser->GetSex();
	before_num[0] = 0;
	before_num[1] = 0;

	uint32 giveScore = 0;
	for (uint32 i = 0; i < info.size(); i++)
	{
		before_num[i] = pUser->GetExtData32(info[i].give_data_id);
		if (info[i].num > 0)
		{
			pUser->SetExtData32(info[i].give_data_id, pUser->GetExtData32(info[i].give_data_id) + info[i].num);
			pUser->DelPackageById(info[i].award,info[i].num);

			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_248,ROLE_NAME_COLOR,get_name.c_str(),info[i].num,GetItemName(info[i].award));
			giveLog.push_back(buf);

			giveScore += info[i].num * info[i].score_give;
		}
		r.num[i] = pUser->GetExtData32(info[i].give_data_id);
		r.score += r.num[i] * info[i].score_give;
	}
	if (before_num[0] == 0 && before_num[1] == 0)
		r.isFirst = true;
	else
		r.isFirst = false;
	record.push_back(r);

	snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_249,giveScore);
	SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
		
	pUser->SetHDShowHIstory(0, giveLog,hd_type);

	AddHDShowLog(pUser->GetRoleId(), giveLog, roleId, getLog,hd_type);

	AddFestivalRecord(record,hd_type);

	msg<<PRO_SUCCESS<<(uint8)2;

	msg<<(uint8)0<<(uint8)giveLog.size();
	for (uint32 i = 0; i < giveLog.size(); i++)
		msg<<(uint32)0<<giveLog[i].c_str();

	msg<<(uint8)1;
	if (pUser->GetRoleId() == roleId)
	{
		msg<<(uint8)getLog.size();
		for (uint32 i = 0; i < getLog.size(); i++)
			msg<<(uint32)0<<getLog[i].c_str();
	}
	else
	{
		msg<<(uint8)0;
	}
}

uint32 GetRoleIdByName(string name)
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char sql[512];
	char **row = NULL;
	if(pDb == NULL)
		return 0;
								
	snprintf(sql, sizeof(sql), "select id from role_info where name = '%s'", name.c_str());
	if(!pDb->Query(sql))
		return 0;
	int num = pDb->GetRowNum();
	if(num > 0)
	{
		row = pDb->GetRow();
		if (row == NULL)
			return 0;
		else
			return atoi(row[0]);
	}
	return 0;
}

void UniversalMakeAwardMsg(uint16 type, uint32 value, uint16 ext1, uint16 ext2, CNetMessage &msg)
{
	msg << type;
	switch (type)
	{
	case HDAT_PET:
		MakePetMsg(value, ext1, ext2, msg);
		break;

	case HDAT_CHENGHAO:
		MakeTitleMsg(value, msg);
		break;

	case HDAT_MOUNT:
		MakeMountMsg(value, msg);
		break;
	default:
		msg << value;
		break;
	}
}

void MakePetMsg(uint32 petId, uint8 star, uint8 level, CNetMessage &msg)
{
	msg << petId << star << level;
}


void MakeWingMsg(uint8 wingId,CNetMessage &msg)
{
	if(wingId >= SWing::WT_Max || wingId == 0)
	{
		msg<<(uint8)0;
	}
	else
	{
		SWingConfig *p = SingletonWingCfgMgr::instance().GetCfg(wingId);
		if(p == NULL)
			msg<<(uint8)0;
		else
			msg<<wingId;
	}
}

void MakeTitleMsg(uint32 title,CNetMessage &msg)
{
	if (title == 0 || title >= E2UT_MAX) // 没有使用称号
		msg<<(uint32)0 << (uint32)0;
	else
		msg<<title<< sTitltAttrCfgManager.GetTitleAddPower(title);
}

void MakeMountMsg(uint32 mountId,CNetMessage &msg)
{
	SMountConfig *p = SingletonMountCfgMgr::instance().GetCfg(mountId);
	if(p == NULL)
	{
		msg << (uint32)0 << (uint32)0;
		return;
	}
	msg<<mountId<<p->moveSpeed;
}

string GetMonthCardLastTime(time_t lastGetTime)
{
	char lastTime[128];
	
	snprintf(lastTime,sizeof(lastTime),LANGUAGE_TRANSFORM_252);
	if(lastGetTime > 0)
	{
		struct tm *p = gmtime(&lastGetTime);
		if(p != NULL)
			snprintf(lastTime,sizeof(lastTime),LANGUAGE_TRANSFORM_253,(int)(p->tm_year + 1900),(int)(p->tm_mon + 1),(int)p->tm_mday);
	}
	return lastTime;
}

void SetShaoDangString(stringstream &stringAward, SShaoDangAward &award)
{
	if (award.type == 1)
	{
		if (award.petQuality > 0)
			stringAward<<QualityColorName[award.petQuality]<<LANGUAGE_TRANSFORM_254;

		if (award.petAvoluteStar > 0)
			stringAward<<(int)award.petAvoluteStar<<LANGUAGE_TRANSFORM_255;
		
		stringAward<<GetPetName(award.id)<<"*1";
	}
	else if (award.type == 2)
		stringAward<<GetItemName(award.id)<<"*1";
}


bool TeamCanEnterBangPai(CUser *pUser)
{
	if(pUser == NULL)
		return false;
	if(pUser->GetTeam() != 0)
	{
		if(GetTeamAllMemNum(pUser) > 1 && pUser->GetBangPai() == 0)
		{
			SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_256,TIPS_FAILURE_COLOR).c_str());
			return false;
		}
		if(pUser->GetTeam() != pUser->GetRoleId())
		{
			SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_257,TIPS_FAILURE_COLOR).c_str());
			return false;
		}
		else
		{
			CScene *pScene = pUser->GetScene();
			if(pScene == NULL)
				return false;
			if(!pScene->CanEnterBangPai(pUser))
			{
				SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_258,TIPS_FAILURE_COLOR).c_str());
				return false;
			}
		}
	}
	else
	{
		if(pUser->TempLeaveTeam() > 0)
		{
			if(pUser->GetBangPai() == 0)
			{
				SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_259,TIPS_FAILURE_COLOR).c_str());
				return false;
			}
			CScene *pScene = pUser->GetScene();
			if(pScene == NULL)
				return false;
			if(!pScene->CanEnterBangPai(pUser))
			{
				SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_260,TIPS_FAILURE_COLOR).c_str());
				return false;
			}
		}
	}
	return true;
}

bool TeamCanEnterBangPaiFightScene(CUser *pUser)
{
	if(pUser == NULL)
		return false;
	if(pUser->GetTeam() != 0)
	{
		if(GetTeamAllMemNum(pUser) > 1 && pUser->GetBangPai() == 0)
		{
			SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_261,TIPS_FAILURE_COLOR).c_str());
			return false;
		}
		if(pUser->GetTeam() != pUser->GetRoleId())
		{
//			SendSysInfo(pUser,MakeStringColor("队长才能操作",TIPS_FAILURE_COLOR).c_str());
			return false;
		}
		else
		{
			CScene *pScene = pUser->GetScene();
			if(pScene == NULL)
				return false;
			if(!pScene->CanEnterBangPai(pUser))
			{
				SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_262,TIPS_FAILURE_COLOR).c_str());
				return false;
			}
		}
	}
	else
	{
		if(pUser->TempLeaveTeam() > 0)
		{
			if(pUser->GetBangPai() == 0)
			{
				SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_263,TIPS_FAILURE_COLOR).c_str());
				return false;
			}
			CScene *pScene = pUser->GetScene();
			if(pScene == NULL)
				return false;
			if(!pScene->CanEnterBangPai(pUser))
			{
				SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_264,TIPS_FAILURE_COLOR).c_str());
				return false;
			}
		}
	}
	return true;
}

// 同一天的时间值,获取时间差(秒数), time格式=hour*10000+minute*100+second
int GetNewTimeSecond(int curTime,int endTime)
{
	if(curTime > endTime)
		return 0;
	int h1 = curTime/10000;
	int m1 = curTime%10000/100;
	int s1 = curTime%100;
	int h2 = endTime/10000;
	int m2 = endTime%10000/100;
	int s2 = endTime%100;
	return (h2-h1)*3600 + (m2-m1)*60 + (s2-s1);
}

//void UpdateBZXingDongLi(CUser *pUser)
//{
//	if(pUser == NULL)
//		return;
//	int srcSceneId = pUser->GetSrcSceneId();
//	if(srcSceneId != BP_FIGHT_SID && srcSceneId != KUAFU_BZ_SID)
//		return;
//	CNetMessage msg;
//	msg.SetType(PRO_BANG_ZHAN);
//	msg<<(uint8)3<<pUser->GetExtData16(7);
//	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
//}

void AddBangZhanFightWinAward(CUser *pUser)
{
	const int AWARD_LIST[][2] = {{2818,2},{2251,2},{2538,2}};
	if(pUser == NULL)
		return;
	if(Random(1,10000) <= 1000)	// 10%
	{
		uint16 size = sizeof(AWARD_LIST)/sizeof(AWARD_LIST[0]);
		int idx = Random(1,size) - 1;
		char buf[128];
		if(AWARD_LIST[idx][0] == HDAT_MONEY)
		{
			pUser->AddMoney(AWARD_LIST[idx][1]);
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_265,AWARD_LIST[idx][1]);
		}
		else
		{
			pUser->AddBangDingPackage(AWARD_LIST[idx][0],AWARD_LIST[idx][1]);
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_266,GetItemName(AWARD_LIST[idx][0]),AWARD_LIST[idx][1]);
		}
		SendSysInfoFightEnd(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
	}
}

void MakeShenQiMsg(uint32 shenqiId,CNetMessage &msg)
{
	if (shenqiId == 0 || shenqiId > SHENQI_NUM)
	{
		msg <<(uint32)0;
	}
	else
	{
		SShenQiConfig *p = SingletonShenQiCfgMgr::instance().GetCfg(shenqiId);
		if(p == NULL)
			msg <<(uint32)0;
		else
			msg <<shenqiId;
	}
}

uint8 MakeAwardMsg(CUser *pUser,SHuoDongAward &award,uint32 huodong_type,CNetMessage &msg, uint32 *totalYB)
{
	uint8 typeNum = 0;
	uint32 YB = 0;

	for(uint8 j=0;j < SHuoDongAward::AWARD_NUM;j++)
	{
		if(award.award[j] > 0 && award.num[j] > 0)
		{
			UniversalMakeAwardMsg(award.award[j], award.num[j], award.petQuality[j], award.petQualityLv[j], msg);

			if (award.award[j] == HDAT_YB)
				YB += award.num[j];

			if (award.award[j] == HDAT_BANG_YB)
				YB += award.num[j];
			typeNum++;
		}
	}

	if (totalYB != NULL)
		*totalYB += YB;
	return typeNum;
}

void MakeExchangeInfoMsg(CUser *pUser,HDExchangeInfo &info,CNetMessage &msg, uint32 type, map<uint32,uint32> *goods)
{
	if(pUser == NULL)
		return;
	
	msg<<info.idx;
	msg<<info.materialIsOr;
	if (type == CHuoDongAwardManager::MEIRI_HUANHAOLI)
	{
		if (info.saveExt8 == 0)
			msg<<(uint8)0<<(uint8)0;
		else
			msg<<(uint8)pUser->GetExtData8(info.saveExt8)<<(uint8)info.exchange_num_limit;
	}

	uint16 pos = msg.GetDataLen();
	uint8 typeNum = 0;
	msg<<typeNum;
	for(uint8 j=0;j < HDExchangeInfo::MATERIAL_NUM;j++)
	{
		if(info.material[j] > 0 && info.material_num[j] > 0)
		{
			msg<<info.material[j];
			msg<<info.material_num[j];
			typeNum++;

			if (goods != NULL)
				(*goods).insert(make_pair(info.material[j], info.material_num[j]));
		}
	}
	msg.WriteData(pos,&typeNum,sizeof(typeNum));

	pos = msg.GetDataLen();
	typeNum = 0;
	msg<<typeNum;
	for(uint8 j=0;j < HDExchangeInfo::AWARD_NUM;j++)
	{
		if(info.award[j] > 0 && info.num[j] > 0)
		{
			msg<<info.award[j];

			if(info.award[j] == HDAT_PET)
				MakePetMsg(pUser,msg,info.num[j]);
			else if (info.award[j] == HDAT_WING)
				MakeWingMsg(info.num[j],msg);
			else if (info.award[j] == HDAT_CHENGHAO)
				MakeTitleMsg(info.num[j], msg);
			else if (info.award[j] == HDAT_MOUNT)
				MakeMountMsg(info.num[j], msg);
			else
				msg<<info.num[j];

			typeNum++;
		}
	}
	msg.WriteData(pos,&typeNum,sizeof(typeNum));
}

bool MakeDoExchangeMsg(CUser *pUser,HDExchangeInfo &info,CNetMessage &msg, uint32 type, uint8 materialIdx)
{
	if(pUser == NULL)
		return false;

	bool isEnough = true;
	if(info.materialIsOr == 0)
	{
		for (uint32 i = 0; i < HDExchangeInfo::MATERIAL_NUM; i++)
		{
			if (info.material[i] > 0 && info.material_num[i] > 0)
			{
				if ((uint32)pUser->GetItemNum(info.material[i]) < info.material_num[i])
				{
					isEnough = false;
					break;
				}
			}
		}
	}
	else
	{
		if(materialIdx > HDExchangeInfo::MATERIAL_NUM || info.material[materialIdx-1] < 0)
			return false;
		if((uint32)pUser->GetItemNum(info.material[materialIdx -1]) < info.material_num[materialIdx -1])
		{
			isEnough = false;
		}
	}

	if (isEnough)
	{
		if(info.materialIsOr == 0)
		{
			for (uint32 i = 0; i < HDExchangeInfo::MATERIAL_NUM; i++)
			{
				if (info.material[i] > 0 && info.material_num[i] > 0)
					pUser->DelPackageById(info.material[i], info.material_num[i]);
			}
		}
		else if (materialIdx <= HDExchangeInfo::MATERIAL_NUM)
		{
			pUser->DelPackageById(info.material[materialIdx-1], info.material_num[materialIdx-1]);
		}

		if (type == CHuoDongAwardManager::MEIRI_HUANHAOLI && info.saveExt8 > 0 && info.exchange_num_limit > 0)
			pUser->SetExtData8(info.saveExt8, pUser->GetExtData8(info.saveExt8) + 1);

		for (uint32 i = 0; i < HDExchangeInfo::AWARD_NUM;i++)
			AddHuoDongAward(pUser,type,info.award[i],info.num[i],info.petQuality[i],info.petQualityLv[i],true);
			
		msg<<PRO_SUCCESS;

		if (type == CHuoDongAwardManager::MEIRI_HUANHAOLI)
		{
			uint8 max = (uint8)info.exchange_num_limit;
			if (info.saveExt8 == 0)
				max = 0;
			msg<<pUser->GetExtData8(info.saveExt8)<<max;
		}
		return true;
	}
	else
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_267,TIPS_FAILURE_COLOR);
		return false;
	}	
}

bool LoadRandomBoxCfg()  //加载随机宝箱配置
{
	if(0 == randombox_stamp)
		limitSaveMap.clear();
	randombox_cfg.clear();
	randombox_stamp = (uint32)GetSysTime();
	
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if ((pDb != NULL) && (pDb->Query("select seq,box_id,item_id,odds,id,num,quality,quality_level,isnotice,day_limit from randombox_cfg order by seq asc")))
	{
		char **row;
		while ((row = pDb->GetRow()) != NULL)
		{
			RandomBoxItem temp;
				
			temp.box_id = (uint32)atoi(row[1]);
			temp.item_id = (uint32)atoi(row[2]);
			temp.odds = (uint32)atoi(row[3]);
			temp.id = (uint32)atoi(row[4]);
			temp.num = (uint32)atoi(row[5]);
			temp.quality = (uint32)atoi(row[6]);
			temp.quality_level = (uint32)atoi(row[7]);
			temp.notice = (uint32)atoi(row[8]);
			temp.day_limit = (uint32)atoi(row[9]);
			uint32 key = temp.box_id *1000 +  temp.item_id; 	
			randombox_cfg.insert(std::make_pair(key,temp));
		}//end of while
		return true;
	}//end of if
	return false;
}

void ShowBangZhanIcon_Single(CUser *pUser)
{
	if(pUser == NULL)
		return;

#ifndef KUA_FU
	/*if(wday == 3 || wday == 6)
	{
		int bId = pUser->GetBangPai();
		if(bId > 0 && pUser->GetLevel() >= CBangPaiManager::BP_FIGHT_ROLE_LIMIT_LV)
		{
			int hdTime = hour*100 + minute;
			if(hdTime >= BP_FIGHT_READY_START && hdTime < BP_FIGHT_BOX_END)
			{
				if(SingletonCBangPaiManager::instance().IsInBangPaiFightList(bId))
				{
					CBangPai *pBangPai = SingletonCBangPaiManager::instance().FindBangPai(bId);
					if(pBangPai != NULL)
					{
						SBangPaiMember data;
						pBangPai->GetMemberInfoById(pUser->GetRoleId(),data);
						if(data.roleId != 0 && (curTime - (int)data.utime) >= CBangPaiManager::BP_FIGHT_LIMIT_ENTER_TIME)
							SendHuoDongFlag_Single(pUser,20,1);
					}
				}
			}
		}
	}*/
#else
	int curTime = GetSysTime();
	int wday = GetWeekDay();
	int hour = GetHour();
	int minute = GetMinute();
	if(wday == 2 || wday == 5)
	{
		int bId = pUser->GetBangPai();
		if(bId > 0 && pUser->GetLevel() >= CBangPaiManager::KF_BP_FIGHT_ROLE_LIMIT_LV)
		{
			int hdTime = hour*100 + minute;
			if(hdTime >= BP_FIGHT_READY_START && hdTime < BP_FIGHT_BOX_END)
			{
				if(SingletonCBangPaiManager::instance().IsInBangPaiFightList(bId))
				{
					CBangPai *pBangPai = SingletonCBangPaiManager::instance().FindBangPai(bId);
					if(pBangPai != NULL)
					{
						SBangPaiMember data;
						pBangPai->GetMemberInfoById(pUser->GetRoleId(),data);
						if(data.roleId != 0 && (curTime - (int)data.utime) >= CBangPaiManager::BP_FIGHT_LIMIT_ENTER_TIME)
							SendHuoDongFlag_Single(pUser,23,1);
					}
				}
			}
		}
	}
#endif
}

bool CanJoinTeamInBangPaiScene(CUser *pHead,CUser *pJoin,string &str)
{
	str.clear();
	if(pHead == NULL || pJoin == NULL)
		return false;
	if(pHead->GetTeam() == 0 || pHead->GetTeam() != pHead->GetRoleId() || pJoin->GetTeam() > 0)
		return false;
	
	int curTime = GetSysTime();
	vector<ShareUserPtr> pMember;
	GetTeamMemberList(pHead,pMember);
	int roleNum = pMember.size();
	if(roleNum < 1)
		return false;
	
	bool isFailed = false;
	do
	{
		if((pHead->GetSrcSceneId() == BANG_PAI_SCENE_ID && pJoin->GetSrcSceneId() != BP_FIGHT_SID) || (pJoin->GetSrcSceneId() == BANG_PAI_SCENE_ID && pHead->GetSrcSceneId() != BP_FIGHT_SID))
		{
			if(pJoin->GetBangPai() == 0 || pJoin->GetBangPai() != pHead->GetBangPai())
			{
				isFailed = true;
				break;
			}
			
			for(int i=0;i < roleNum;i++)
			{
				if(pMember[i].get() != NULL || pMember[i]->GetBangPai() != pHead->GetBangPai())
				{
					isFailed = true;
					break;
				}
			}
			if(isFailed)
				break;
		}
		else if(pHead->GetSrcSceneId() == BP_FIGHT_READY_SID || pHead->GetSrcSceneId() == BP_FIGHT_SID || pJoin->GetSrcSceneId() == BP_FIGHT_READY_SID || pJoin->GetSrcSceneId() == BP_FIGHT_SID)
		{
			if(pJoin->GetBangPai() == 0 || pJoin->GetBangPai() != pHead->GetBangPai() 
				|| pJoin->GetLevel() < CBangPaiManager::BP_FIGHT_ROLE_LIMIT_LV || pHead->GetLevel() < CBangPaiManager::BP_FIGHT_ROLE_LIMIT_LV
				|| curTime - GetEnterBangPaiTime(pJoin) < CBangPaiManager::BP_FIGHT_LIMIT_ENTER_TIME || curTime - GetEnterBangPaiTime(pHead) < CBangPaiManager::BP_FIGHT_LIMIT_ENTER_TIME)
			{
				isFailed = true;
				break;
			}

			for(int i=0;i < roleNum;i++)
			{
				if (pMember[i].get() == NULL)
					continue;
				if(pMember[i]->GetBangPai() != pHead->GetBangPai()
					|| pMember[i]->GetLevel() < CBangPaiManager::BP_FIGHT_ROLE_LIMIT_LV 
					|| curTime - GetEnterBangPaiTime(pMember[i].get()) < CBangPaiManager::BP_FIGHT_LIMIT_ENTER_TIME)
				{
					isFailed = true;
					break;
				}
			}
			if(isFailed)
				break;
		}
		else if(pHead->GetSrcSceneId() == KUAFU_BZ_READY_SID || pHead->GetSrcSceneId() == KUAFU_BZ_SID || pJoin->GetSrcSceneId() == KUAFU_BZ_READY_SID || pJoin->GetSrcSceneId() == KUAFU_BZ_SID)
		{
			if(pJoin->GetBangPai() == 0 || pJoin->GetBangPai() != pHead->GetBangPai() 
				|| pJoin->GetLevel() < CBangPaiManager::KF_BP_FIGHT_ROLE_LIMIT_LV || pHead->GetLevel() < CBangPaiManager::KF_BP_FIGHT_ROLE_LIMIT_LV
				|| curTime - GetEnterBangPaiTime(pJoin) < CBangPaiManager::BP_FIGHT_LIMIT_ENTER_TIME || curTime - GetEnterBangPaiTime(pHead) < CBangPaiManager::BP_FIGHT_LIMIT_ENTER_TIME)
			{
				isFailed = true;
				break;
			}

			for(int i=0;i < roleNum;i++)
			{
				if(pMember[i].get() != NULL || pMember[i]->GetBangPai() != pHead->GetBangPai()
					|| pMember[i]->GetLevel() < CBangPaiManager::KF_BP_FIGHT_ROLE_LIMIT_LV 
					|| curTime - GetEnterBangPaiTime(pMember[i].get()) < CBangPaiManager::BP_FIGHT_LIMIT_ENTER_TIME)
				{
					isFailed = true;
					break;
				}
			}
			if(isFailed)
				break;
		}
		else if(IsInFishingRoom(pHead->GetSrcSceneId()) || IsInFishingRoom(pJoin->GetSrcSceneId()))
		{
			isFailed = true;
			break;
		}
	}while(0);

	if(isFailed)
	{
		str = LANGUAGE_TRANSFORM_269;
		return false;
	}
	return true;
}

static vector<ShareUserPtr> XiuXianRobot;
boost::recursive_mutex XIU_XIAN_Mutex;

static int GetXiuXianPosByIdx(int idx)
{
	if(idx % 5 != 0 || idx <= 0 || idx > CUser::MAX_XIU_XIAN_NUM)
		return 0xffff;
	return (idx/5 - 1);
}

void GetXiuXianRobotData(int idx,uint8 &xiang,uint8 &sex)
{
	xiang = 1;
	sex = 1;
	ShareUserPtr pU = GetXiuXianRobotByIdx(idx);
	if(pU.get() == NULL)
		return;
//	xiang = pU->GetXiang();
	sex = pU->GetSex();
}

ShareUserPtr GetXiuXianRobotByIdx(int idx)
{
	static int day = 0;
	int d = GetDay();
	ShareUserPtr ptrEmpty;
	if(day == 0 || day != d)
	{
		day = d;
		boost::recursive_mutex::scoped_lock lk(XIU_XIAN_Mutex);
		XiuXianRobot.clear();

		for(int i=0;i < CUser::MAX_XIU_XIAN_NUM/5;i++)
		{
			int robotId = i*10 + Random(1,10);
			ShareUserPtr ptr;
			CUser *pU = new CUser;
			if(pU == NULL)
				return ptrEmpty;
			pU->SetSock(-1);
			if(!pU->CopyUserData(robotId,3))
			{
				cout<<"Error: xiuxian robot id="<<robotId<<" cannot read"<<endl;
				if(!pU->CopyUserData(1,3))
				{
					delete pU;
					pU = NULL;
				}
			}
			if(pU != NULL)
				ptr.reset(pU);
			XiuXianRobot.push_back(ptr);
		}
	}

	int pos = GetXiuXianPosByIdx(idx);
	if(pos == 0xffff || pos >= (int)XiuXianRobot.size())
		return ptrEmpty;
	boost::recursive_mutex::scoped_lock lk(XIU_XIAN_Mutex);
	return XiuXianRobot[pos];	
}

void LeaveBangPaiTransport(CUser *pUser)
{
	if(pUser == NULL)
		return;
	CScene *pScene = pUser->GetScene();
	if(pScene == NULL)
		return;
	int srcSceneId = pScene->GetSrcSceneId();
#ifndef KUA_FU
	if(srcSceneId == BP_FIGHT_SID || srcSceneId == BP_FIGHT_READY_SID)
	{
		if(pUser->GetFightId() == 0)	// 不在战斗
		{
			int teamId = pUser->GetTeam();
			if(teamId == 0)
				teamId = pUser->TempLeaveTeam();
			if(teamId > 0)
				pScene->LeaveSceneTeam(teamId,pUser);
			TransportUser(pUser,BP_FIGHT_EXIT_SID,BP_FIGHT_EXIT_X,BP_FIGHT_EXIT_Y,1);
		}
	}
#else
	if(srcSceneId == KUAFU_BZ_SID || srcSceneId == KUAFU_BZ_READY_SID)
	{
		if(pUser->GetFightId() == 0)	// 不在战斗
		{
			int teamId = pUser->GetTeam();
			if(teamId == 0)
				teamId = pUser->TempLeaveTeam();
			if(teamId > 0)
				pScene->LeaveSceneTeam(teamId,pUser);
			TransportUser(pUser,KUAFU_EXIT_SID,KUAFU_EXIT_X,KUAFU_EXIT_Y,1);
		}
	}
#endif
}


bool IsIOSAD(int ad)
{
	if(ad == 201 || ad == 3101)
		return true;
	return false;
}

int GetYB_ByMoney(int money)
{
	return money*YUANBAO_BILV;
}

int GetMoney_ByYB(int yb)
{
	return yb / YUANBAO_BILV;
}


int GetCharacterNum(string &name)
{
	if(name.empty())
		return 0;
	int num = 0;
	for(uint32 i=0;i < name.size();i++)
	{
		char c = name.at(i);
		if(c != 0)
		{
			if((c & 0xc0) != 0x80)
				num++;
		}
		else
		{
			break;
		}
	}
    return num;
}

ShareUserPtr GetShiLianRobotByZhandouli(int zhandouli)
{
	ShareUserPtr ptr;
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return ptr;
	int tarRobotId = 1;
	int sex = 1;
	char sql[512];
	char **row = NULL;
	snprintf(sql,sizeof(sql),"select id from shilian_robot where zhanDouLi>=%d order by zhanDouLi asc limit 1",zhandouli);
	if(!pDb->Query(sql))
		return ptr;
	if((row = pDb->GetRow()) != NULL)
		tarRobotId = atoi(row[0]);

	CUser *pUser = new CUser;
	if(pUser == NULL)
		return ptr;
	pUser->SetSock(-1);
	if(!pUser->CopyUserData(tarRobotId,2))
	{    
		delete pUser;
		return ptr;
	}
	sex = pUser->GetSex();

	string robotName;
	GetFastRoleName(sex,robotName);
	snprintf(sql,sizeof(sql),"%s%c%c",robotName.c_str(),Random(0,25)+'a',Random(0,25)+'a');
	pUser->SetName(sql);
	ptr.reset(pUser);
	return ptr;
}

uint32 CurlZeroTime(uint32 time)
{
	return (time - (time + 8 * 3600) % 86400);
}

void AddBoxAward(CUser *pUser,uint32 item_id ,uint32 awardType,uint32 awardNum,uint16 petLevel,uint16 petStar, bool isShow)
{
	if(pUser == NULL || awardType == 0 || awardNum == 0)
		return;
	char buf[256];
	if(awardType < 60000)
	{
		pUser->AddBangDingPackage(awardType,awardNum);
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_231,GetItemName(awardType),awardNum);

		SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
		if (isShow)
		{
			snprintf(buf,sizeof(buf),LANGUAGE_CHY_18,ROLE_NAME_COLOR,pUser->GetName(),ITEM_NAME_COLOR,GetItemName(item_id),ITEM_NAME_COLOR,GetItemName(awardType),awardNum);
			SysInfoToAllUser(buf);
		}
	}
	else if(awardType == HDAT_MONEY)
	{
		pUser->AddMoney(awardNum);
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_232,awardNum);

		SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
		if (isShow)
		{
			snprintf(buf,sizeof(buf),LANGUAGE_CHY_19,ROLE_NAME_COLOR,pUser->GetName(),ITEM_NAME_COLOR,GetItemName(item_id),ITEM_NAME_COLOR,awardNum);
			SysInfoToAllUser(buf);
		}
	}
	else if(awardType == HDAT_BANG_YB)
	{
		pUser->AddTongBao(awardNum,1);
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_233,awardNum);

		SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
		if (isShow)
		{
			snprintf(buf,sizeof(buf),LANGUAGE_CHY_20,ROLE_NAME_COLOR,pUser->GetName(),ITEM_NAME_COLOR,GetItemName(item_id),ITEM_NAME_COLOR,awardNum);
			SysInfoToAllUser(buf);
		}
	}
	else if(awardType == HDAT_PET)
	{
		::AddPet(pUser,awardNum,petLevel,petStar);
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_234,GetPetName(awardNum));

		SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
		if (isShow)
		{
			snprintf(buf,sizeof(buf),LANGUAGE_CHY_21,ROLE_NAME_COLOR,pUser->GetName(),ITEM_NAME_COLOR,GetItemName(item_id),ITEM_NAME_COLOR,GetPetName(awardNum));
			SysInfoToAllUser(buf);
		}
	}
	else if(awardType == HDAT_YB)
	{
		pUser->AddTongBao(awardNum);
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_235,awardNum);
		SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
		if (isShow)
		{
			snprintf(buf,sizeof(buf),LANGUAGE_CHY_22,ROLE_NAME_COLOR,pUser->GetName(),ITEM_NAME_COLOR,GetItemName(item_id),ITEM_NAME_COLOR,awardNum);
			SysInfoToAllUser(buf);
		}
		else if(awardType == HDAT_EXP)
		{
			pUser->AddExp(awardNum);
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_236,awardNum);
			SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
			if (isShow)
			{
				snprintf(buf,sizeof(buf),LANGUAGE_CHY_23,ROLE_NAME_COLOR,pUser->GetName(),ITEM_NAME_COLOR,GetItemName(item_id),ITEM_NAME_COLOR,awardNum);
				SysInfoToAllUser(buf);
			}
		}
		else if(awardType == HDAT_QIANNENG) 
		{   
			pUser->AddQianNeng(awardNum); 
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_237,awardNum); 

			SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str()); 
			if (isShow) 
			{   
				snprintf(buf,sizeof(buf),LANGUAGE_CHY_24,ROLE_NAME_COLOR,pUser->GetName(),ITEM_NAME_COLOR,GetItemName(item_id),ITEM_NAME_COLOR,awardNum); 
				SysInfoToAllUser(buf); 
			} 
		}
		else if(awardType == HDAT_CHENGHAO)
		{
			pUser->AddTitle(awardNum);
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_238,GetTitleName(awardNum));
			SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
			if (isShow)
			{
				snprintf(buf,sizeof(buf),LANGUAGE_CHY_25,ROLE_NAME_COLOR,pUser->GetName(),ITEM_NAME_COLOR,GetItemName(item_id),ITEM_NAME_COLOR,GetTitleName(awardNum));
				SysInfoToAllUser(buf);
			}
		}
	}
	else if(awardType == HDAT_WING)
	{
		pUser->AddWing(awardNum);
		const char *pWName = GetWingName(awardNum);
		if (pWName != NULL)
		{
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_239,pWName);
			SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
			if (isShow)
			{
				snprintf(buf,sizeof(buf),LANGUAGE_CHY_26,ROLE_NAME_COLOR,pUser->GetName(),ITEM_NAME_COLOR,GetItemName(item_id),ITEM_NAME_COLOR,pWName);
				SysInfoToAllUser(buf);
			}
		}
	}
	else if (awardType == HDAT_MOUNT)
	{
		if (awardNum > 0)
		{
			SMountConfig *pCfg = SingletonMountCfgMgr::instance().GetCfg(awardNum);
			if(pCfg == NULL)
				return;
			pUser->AddMount(awardNum);
			const char *pMName = GetMountName(awardNum);
			if(pMName != NULL)
			{
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_240,pMName);
				SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
				if (isShow)
				{
					snprintf(buf,sizeof(buf),LANGUAGE_CHY_27,ROLE_NAME_COLOR,pUser->GetName(),ITEM_NAME_COLOR,GetItemName(item_id),ITEM_NAME_COLOR,pMName);
					SysInfoToAllUser(buf);
				}
			}
		}
	}
	else
		return;
}

void MakeXinShiError(const char *str,CNetMessage &msg)
{
	msg.ReWrite();
	msg.SetType(MSG_SERVER_XINSHI);
	msg<<(uint8)1;
	msg<<PRO_ERROR<<MakeStringColor(str,TIPS_FAILURE_COLOR);
}

int CopyDataToBuf( char* buf,const void* data,size_t size,int off )
{
	memcpy(buf+off,data,size);
	off += size;
	return off; 
}

void CopyDataToBuf(char *buf,const void *data,size_t size,uint32 &off,uint32 maxLen)
{
	if(off+size > maxLen)
		return;
	memcpy(buf+off,data,size);
	off += size;
}

int ReadDataFromBuf( char* buf,void* data,size_t size,int off )
{
	memcpy(data,buf+off,size);
	off += size;
	return off;
}

void ReadDataFromBuf(char *buf,void *data,size_t size,uint32 &off,uint32 maxLen)
{
	if(off+size > maxLen)
		return;
	memcpy(data,buf+off,size);
	off += size;
}

int CopyCharToBuf( char* buf, const char* data,int &off )
{
	short nlen = strlen(data);
	memcpy(buf+off,&nlen,sizeof(nlen));
	off += sizeof(nlen);
	memcpy(buf+off,data,nlen);
	off += nlen;
	return off; 
}
int ReadCharFromBuf( char* buf,char* data,int off )
{
	short nlen = 0;
	memcpy(&nlen,buf+off,sizeof(nlen));
	off+=sizeof(nlen);
	memcpy(data,buf+off,nlen);
	data[nlen]='\0';
	off += nlen;
	return off;
}

#define getMessage(msg,msglen,pat)      \
	do      \
{       \
	va_list ap;     \
	bzero(msg,msglen);     \
	va_start(ap,pat);              \
	vsnprintf(msg,msglen - 1,pat,ap);    \
	va_end(ap);     \
}while(false)



bool SendInfoToMe(CUser *pUser,int type,const char *pattern,...)
{
	if (pUser)
	{
		char buf[512];
		getMessage(buf,sizeof(buf)/sizeof(buf[0]),pattern);

		SendSysInfo(pUser,MakeStringColor(buf,type).c_str());
		return true;
	}
	return false;
}

bool SendSysInfoToMe(CUser *pUser,int type,const char *pattern,...)
{
	if (pUser)
	{
		char buf[128];
		getMessage(buf,128,pattern);
		CSocketServer &sock = SingletonSocket::instance();
		CNetMessage msg;
		msg.SetType(PRO_SYSTEM_INFO);
		msg<<MakeStringColor(buf,type).c_str();
		sock.SendMsg(pUser->GetSock(),msg);
		return true;
	}
	return false;
}
void SendSysInfoToAll(bool checkTime,int type,const char *pattern,...)
{
	char msg[256];
	getMessage(msg,sizeof(msg),pattern);

	const int TIME_GAP = 15;
	static time_t lastTime = 0;
	if(msg == NULL)
		return;
	time_t t = GetSysTime();
	if(lastTime == 0)
		lastTime = t;
	bool send = false;
	if(!checkTime)
	{
		lastTime = t;
		send = true;
	}
	else
	{
		if(t - lastTime >= (time_t)TIME_GAP)
		{
			lastTime = t;
			send = true;
		}
	}
	if(!send)
		return;

	CNetMessage sysMsg;
	sysMsg.SetType(PRO_SYSTEM_INFO);
	if( type )
		sysMsg<<MakeStringColor(msg,type).c_str();
	else
		sysMsg<<msg;
	CSocketServer &sock = SingletonSocket::instance();
	SingletonOnlineUser::instance().ForEachUser(boost::bind(SendNianShouInfo,&sock,&sysMsg,_1));
}

bool InFuncionLevelReadyTime(int sysId)
{
	CSystemOpenCfgMananger &openSys = SingletonCSystemOpenCfgMgr::instance();
	if(!openSys.OpenWeekDay(sysId))
		return false;
	
	uint16 readyTime = 0;
	uint16 startTime = 0;
	uint16 endTime = 0;
	if(!openSys.GetFuncLvTime(sysId,readyTime,startTime,endTime))
		return false;
	if(readyTime == 0 && startTime == 0 && endTime == 0)
		return false;
	uint16 time = GetHour()*100 + GetMinute();
	return (time >= readyTime && time < startTime);
}

bool InFuncionLevelTime(int sysId)
{
	CSystemOpenCfgMananger &openSys = SingletonCSystemOpenCfgMgr::instance();
	if(!openSys.OpenWeekDay(sysId))
		return false;
	
	uint16 readyTime = 0;
	uint16 startTime = 0;
	uint16 endTime = 0;
	if(!openSys.GetFuncLvTime(sysId,readyTime,startTime,endTime))
		return false;
	if(readyTime == 0 && startTime == 0 && endTime == 0)
		return false;
	uint16 time = GetHour()*100 + GetMinute();
	return (time >= startTime && time < endTime);
}

void EnterTeamKunLunShan(CUser *pUser)
{
#ifdef KUA_FU
	const int TEAM_MEMBER_NUM_LIMIT = 2;
	if(pUser == NULL)
		return;
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_KUN_LUN_SHAN_TEAM);
	msg<<(uint8)1;

	CSocketServer &sockServer = SingletonSocket::instance();
	if(InFuncionLevelTime(SOT_KuaFuLunDao))
	{
		if(!pUser->HaveTeam())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0019,TIPS_FAILURE_COLOR);
			sockServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(pUser->GetRoleId() != pUser->GetTeam())
			return;

		vector<ShareUserPtr> pMember;
		GetTeamMemberList(pUser,pMember);
		int roleNum = pMember.size();
		if(roleNum < TEAM_MEMBER_NUM_LIMIT)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0020,TIPS_FAILURE_COLOR);
			sockServer.SendMsg(pUser->GetSock(),msg);
			return;
		}

		/*int serverZoneId = GetServerZone(pUser->GetServerId());
		for (int i = 0; i < roleNum; i++)
		{
			if (pMember[i].get() != NULL && pMember[i]->GetRoleId() != pUser->GetRoleId() && GetServerZone(pMember[i]->GetServerId()) != serverZoneId)
			{
				msg << PRO_ERROR << MakeStringColor(LANGUAGE_SSJ_0021, TIPS_FAILURE_COLOR);
				sockServer.SendMsg(pUser->GetSock(), msg);
				return;
			}
		}*/

		CSceneManager &scene = SingletonSceneManager::instance();
		CScene *pScene = scene.GetTeamKunLunShanFirstScene();
		if(pScene == NULL)
			return;
		int index = 1;
		while(pScene->GetUserNum() + roleNum > KUN_LUN_SHAN_TEAM_ROOM_LIMIT)
		{
			index++;
			pScene = scene.GetKunLunShanTeamSceneByIndex(index);
			if(pScene == NULL)
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0022,TIPS_FAILURE_COLOR);
				sockServer.SendMsg(pUser->GetSock(),msg);
				return;
			}
		}

		for(int i=0;i < roleNum;i++)
		{
			if(pMember[i].get() != NULL)
				SetQiPetDown(pMember[i].get());
		}
		
		uint16 x=0,y=0;
		if(!pScene->GetCanWalkPos(x,y))
			return;
		if(x == 0 || y == 0)
			return;
		for(int i=0;i < roleNum;i++)
		{
			if(pMember[i].get() != NULL)
				pMember[i]->SaveEnterPos(pMember[i]->GetSceneId(),pMember[i]->GetX(),pMember[i]->GetY());
			SetQiPetDown(pMember[i].get());
		}

		uint16 srcSceneId = pScene->GetSrcSceneId();
		pUser->GetNextSrcSceneId(srcSceneId);

		CNetMessage msg1;
		msg1.ReWrite();
		msg1.SetType(PRO_JUMP_SCENE);
		msg1<<(uint16)srcSceneId<<x<<y<<(uint8)0<<(uint8)0;
		sockServer.SendMsg(pUser->GetSock(),msg1);
		pUser->SetPos(x,y);
		pUser->SetFace(0);
		pUser->EnterScene(pScene);
	}
	else
	{
		char buf[256];
		uint16 readyTime = 0;
		uint16 startTime = 0;
		uint16 endTime = 0;
		if(!sSystemOpenCfgMananger.GetFuncLvTime(SOT_KuaFuLunDao,readyTime,startTime,endTime))
			return;
		if(readyTime == 0 && startTime == 0 && endTime == 0)
			return;
		snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0023,startTime/100,endTime/100,endTime%100);
		msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
		sockServer.SendMsg(pUser->GetSock(),msg);
	}
#endif
}

bool InKuaFu1V1FinalsTime()
{
	int week = GetWeekDay();
	int hour = GetHour();
	int minute = GetMinute();
	if(week == 0)	// 周日
	{
		int time = hour*100 + minute;
		if(time >= KUA_FU_FINALS_START_TIME && time < KUA_FU_FINALS_END_TIME)
			return true;
	}
	return false;
}

// -1不在活动时间内，index=1~5
int GetKuaFu1V1FinalsTimeIndex()
{
	int week = GetWeekDay();
	int hour = GetHour();
	int minute = GetMinute();
	if(week == 0)	// 周日
	{
		int time = hour*100 + minute;
		if(time >= KUA_FU_FINALS_START_TIME && time < KUA_FU_FINALS_END_TIME)
		{
			int startHour = KUA_FU_FINALS_START_TIME/100;
			int startMinute = KUA_FU_FINALS_START_TIME%100;
			time = (hour - startHour)*60 + minute - startMinute;
			return (time/15 + 1);
		}
	}
	return -1;
}

int GetKuaFu1V1TurnStartTime()
{
	if(!InKuaFu1V1FinalsTime())
		return -1;

	uint32 time = GetSysTime();
	uint32 minute = GetMinute();
	uint32 second = time%60;
	if(minute < 15)
		return (time - minute*60 -second);
	else if(minute >= 15 && minute < 30)
		return (time - (minute-15)*60 - second);
	else if(minute >= 30 && minute < 45)
		return (time - (minute-30)*60 - second);
	else
		return (time - (minute-45)*60 - second);
}

void GetKuaFuPaiMingList(int timeIdx,SKuaFu1V1UserData (*&p)[MAX_PAIMING_NUM],int &size)
{
	p = NULL;
	size = 0;

	if(timeIdx == 1)
	{
		p = G_1V1_PaiMing_16;
		size = 16;
	}
	else if(timeIdx == 2)
	{
		p = G_1V1_PaiMing_8;
		size = 8;
	}
	else if(timeIdx == 3)
	{
		p = G_1V1_PaiMing_4;
		size = 4;
	}
	else if(timeIdx == 4)
	{
		p = G_1V1_PaiMing_2;
		size = 2;
	}
	else if(timeIdx == 5)
	{
		p = G_1V1_PaiMing_1;
		size = 1;
	}
}

void GetKuaFuPaiMingListOld(int timeIdx,SKuaFu1V1UserData (*&p)[MAX_PAIMING_NUM],int &size)
{
	p = NULL;
	size = 0;

	if(timeIdx == 1)
	{
		p = G_1V1_PaiMing_Old_16;
		size = 16;
	}
	else if(timeIdx == 2)
	{
		p = G_1V1_PaiMing_Old_8;
		size = 8;
	}
	else if(timeIdx == 3)
	{
		p = G_1V1_PaiMing_Old_4;
		size = 4;
	}
	else if(timeIdx == 4)
	{
		p = G_1V1_PaiMing_Old_2;
		size = 2;
	}
	else if(timeIdx == 5)
	{
		p = G_1V1_PaiMing_Old_1;
		size = 1;
	}
}

// roomIdx = 1~16
bool InKuaFu1V1FinalsPaiMingByIdx(int roleId,int timeIdx,int &roomIdx)
{
	if(roleId <= 0 || timeIdx < 1 || timeIdx > 5)
		return false;
	roomIdx = -1;

	boost::recursive_mutex::scoped_lock lk(G_1V1_Mutex);
	SKuaFu1V1UserData (*pPaiMing)[MAX_PAIMING_NUM] = NULL;
	int size = 0;
	GetKuaFuPaiMingList(timeIdx,pPaiMing,size);
	if(size == 0 || pPaiMing == NULL)
		return false;
	
	for(uint8 i=0;i < MAX_PAIMING_NUM;i++)
	{
		for(int j=0;j < size;j++)
		{
			if(roleId == pPaiMing[j][i].data.role_id)
			{
				roomIdx = j/2 + 1 + i*(size/2);
				return true;
			}
		}
	}
	return false;
}

int GetKuaFu1V1VoteStateIdByNode(int type,int nodeIdx,int roleId,KuaFu1V1VoteData &data)
{
	if((type <= 1 && nodeIdx > 15) || (type == 2 && nodeIdx > 1) || (type > 2) || (nodeIdx <= 0))
		return -1;
	int pos = 0xff;
	if(type == 0 || type == 1)
		pos = nodeIdx - 1 + 16*type;
	else
		pos = 31;
	if((uint32)pos >= sizeof(G_1V1_VoteList)/sizeof(G_1V1_VoteList[0]))
		return -1;

	boost::recursive_mutex::scoped_lock lk(G_1V1_Mutex);
	map<uint32,KuaFu1V1VoteData>::iterator it = G_1V1_VoteList[pos].find(roleId);
	if(it == G_1V1_VoteList[pos].end())
		return 0;
	else
	{
		data = it->second;
		return it->second.voteRoleId;
	}
}

int GetKuaFu1V1VoteStateIdByNodeOld(int type,int nodeIdx,int roleId,KuaFu1V1VoteData &data)
{
	if((type <= 1 && nodeIdx > 15) || (type == 2 && nodeIdx > 1) || (type > 2) || (nodeIdx <= 0))
		return -1;
	int pos = 0xff;
	if(type == 0 || type == 1)
		pos = nodeIdx - 1 + 16*type;
	else
		pos = 31;
	if((uint32)pos >= sizeof(G_1V1_VoteList_Old)/sizeof(G_1V1_VoteList_Old[0]))
		return -1;

	map<uint32,KuaFu1V1VoteData>::iterator it = G_1V1_VoteList_Old[pos].find(roleId);
	if(it == G_1V1_VoteList_Old[pos].end())
		return 0;
	else
	{
		data = it->second;
		return it->second.voteRoleId;
	}
}

void GetKuaFu1V1TotolMoneyByNode(int type,int nodeIdx,KuaFu1V1VoteData &role1,KuaFu1V1VoteData &role2)
{
	if((type <= 1 && nodeIdx > 15) || (type == 2 && nodeIdx > 1) || (type > 2) || (nodeIdx <= 0))
		return;
	int pos = 0xff;
	if(type == 0 || type == 1)
		pos = nodeIdx - 1 + 16*type;
	else
		pos = 31;
	if((uint32)pos >= sizeof(G_1V1_VoteList)/sizeof(G_1V1_VoteList[0]))
		return;
	
	boost::recursive_mutex::scoped_lock lk(G_1V1_Mutex);
	if(G_1V1_VoteTotolMoney[pos][0].voteRoleId == 0 && G_1V1_VoteTotolMoney[pos][1].voteRoleId == 0)
	{
		int index = 0xff;
		int paihangPos = 0xff;
		if(type <= 1)
		{
			if(nodeIdx <= 8)
			{
				index = 1;
				paihangPos = (nodeIdx-1)*2;
			}
			else if(nodeIdx <= 12)
			{
				index = 2;
				paihangPos = (nodeIdx-1-8)*2;
			}
			else if(nodeIdx <= 14)
			{
				index = 3;
				paihangPos = (nodeIdx-1-12)*2;
			}
			else if(nodeIdx <= 15)
			{
				index = 4;
				paihangPos = (nodeIdx-1-14)*2;
			}

			int size = 0;
			SKuaFu1V1UserData (*pPaiMing)[MAX_PAIMING_NUM] = NULL;
			GetKuaFuPaiMingList(index,pPaiMing,size);
			if(pPaiMing == NULL || size == 0)
				return;
			G_1V1_VoteTotolMoney[pos][0].voteRoleId = pPaiMing[paihangPos][type].data.role_id;
			G_1V1_VoteTotolMoney[pos][1].voteRoleId = pPaiMing[paihangPos+1][type].data.role_id;
		}
		else
		{
			G_1V1_VoteTotolMoney[pos][0].voteRoleId = G_1V1_PaiMing_1[0][0].data.role_id;
			G_1V1_VoteTotolMoney[pos][1].voteRoleId = G_1V1_PaiMing_1[0][1].data.role_id;
		}
	}

	if(G_1V1_VoteTotolMoney[pos][0].voteRoleId == 0 && G_1V1_VoteTotolMoney[pos][1].voteRoleId == 0)
		return;
	
	role1.voteRoleId = G_1V1_VoteTotolMoney[pos][0].voteRoleId;
	role1.money = 0;
	role2.voteRoleId = G_1V1_VoteTotolMoney[pos][1].voteRoleId;
	role2.money = 0;
	for(uint8 i=0;i < sizeof(G_1V1_VoteTotolMoney)/sizeof(G_1V1_VoteTotolMoney[0]);i++)
	{
		for(uint8 j=0;j < sizeof(G_1V1_VoteTotolMoney[0])/sizeof(G_1V1_VoteTotolMoney[0][0]);j++)
		{
			if(role1.voteRoleId == G_1V1_VoteTotolMoney[i][j].voteRoleId)
				role1.money += G_1V1_VoteTotolMoney[i][j].money;
			else if(role2.voteRoleId == G_1V1_VoteTotolMoney[i][j].voteRoleId)
				role2.money += G_1V1_VoteTotolMoney[i][j].money;
		}
	}
}

void GetKuaFu1V1TotolMoneyByNodeOld(int type,int nodeIdx,KuaFu1V1VoteData &role1,KuaFu1V1VoteData &role2)
{
	if((type <= 1 && nodeIdx > 15) || (type == 2 && nodeIdx > 1) || (type > 2) || (nodeIdx <= 0))
		return;
	int pos = 0xff;
	if(type == 0 || type == 1)
		pos = nodeIdx - 1 + 16*type;
	else
		pos = 31;
	if((uint32)pos >= sizeof(G_1V1_VoteList_Old)/sizeof(G_1V1_VoteList_Old[0]))
		return;
	if(G_1V1_VoteTotolMoney_Old[pos][0].voteRoleId == 0 && G_1V1_VoteTotolMoney_Old[pos][1].voteRoleId == 0)
		return;
	
	role1.voteRoleId = G_1V1_VoteTotolMoney_Old[pos][0].voteRoleId;
	role1.money = 0;
	role2.voteRoleId = G_1V1_VoteTotolMoney_Old[pos][1].voteRoleId;
	role2.money = 0;
	for(uint8 i=0;i < sizeof(G_1V1_VoteTotolMoney_Old)/sizeof(G_1V1_VoteTotolMoney_Old[0]);i++)
	{
		for(uint8 j=0;j < sizeof(G_1V1_VoteTotolMoney_Old[0])/sizeof(G_1V1_VoteTotolMoney_Old[0][0]);j++)
		{
			if(role1.voteRoleId == G_1V1_VoteTotolMoney_Old[i][j].voteRoleId)
				role1.money += G_1V1_VoteTotolMoney_Old[i][j].money;
			else if(role2.voteRoleId == G_1V1_VoteTotolMoney_Old[i][j].voteRoleId)
				role2.money += G_1V1_VoteTotolMoney_Old[i][j].money;
		}
	}
}

int GetKuaFu1V1TotolMoneyByRoleId(int roleId)
{
	if(roleId <= 0)
		return 0;
	int money = 0;
	for(uint8 i=0;i < sizeof(G_1V1_VoteTotolMoney)/sizeof(G_1V1_VoteTotolMoney[0]);i++)
	{
		for(uint8 j=0;j < sizeof(G_1V1_VoteTotolMoney[0])/sizeof(G_1V1_VoteTotolMoney[0][0]);j++)
		{
			if(G_1V1_VoteTotolMoney[i][j].voteRoleId == (uint32)roleId)
				money += G_1V1_VoteTotolMoney[i][j].money;
			else if(G_1V1_VoteTotolMoney[i][j].voteRoleId == (uint32)roleId)
				money += G_1V1_VoteTotolMoney[i][j].money;
		}
	}
	return money;
}

bool AddKuaFu1V1VoteDataByNode(CUser *pUser,int type,int nodeIdx,int voteId,uint32 money)
{
	if(pUser == NULL)
		return false;
	if((type <= 1 && nodeIdx > 15) || (type == 2 && nodeIdx > 1) || (type > 2) || (nodeIdx <= 0))
		return false;
	int pos = 0xff;
	if(type == 0 || type == 1)
		pos = nodeIdx - 1 + 16*type;
	else
		pos = 31;
	if((uint32)pos >= sizeof(G_1V1_VoteList)/sizeof(G_1V1_VoteList[0]))
		return false;
	int roleId = pUser->GetRoleId();

	boost::recursive_mutex::scoped_lock lk(G_1V1_Mutex);
	map<uint32,KuaFu1V1VoteData>::iterator it = G_1V1_VoteList[pos].find(roleId);
	if(it == G_1V1_VoteList[pos].end())
	{
		if(G_1V1_VoteTotolMoney[pos][0].voteRoleId == (uint32)voteId)
			G_1V1_VoteTotolMoney[pos][0].money += money;
		else if(G_1V1_VoteTotolMoney[pos][1].voteRoleId == (uint32)voteId)
			G_1V1_VoteTotolMoney[pos][1].money += money;
		else
			return false;
		
		KuaFu1V1VoteData data;
		data.voteRoleId = voteId;
		data.money = money;
		G_1V1_VoteList[pos].insert(make_pair(roleId,data));
		return true;
	}
	else
	{
		return false;
	}
}

void GetKuaFu1V1FightPlayers(int timeIdx,int roomIdx,SKuaFu1V1UserData &player1,SKuaFu1V1UserData &player2)
{
	if(roomIdx < 1 || timeIdx < 1 || timeIdx > 5)
		return;	
	boost::recursive_mutex::scoped_lock lk(G_1V1_Mutex);
	SKuaFu1V1UserData (*pPaiMing)[MAX_PAIMING_NUM] = NULL;
	int size = 0;
	GetKuaFuPaiMingList(timeIdx,pPaiMing,size);
	if(size == 0 || pPaiMing == NULL)
		return;

	if(roomIdx <= size)
	{
		if(timeIdx < 5)
		{
			int groupIdx = 0;
			int pos1 = -1;
			int pos2 = -1;
			if(roomIdx > size/2)
			{
				groupIdx = 1;
				pos1 = (roomIdx-size/2-1)*2;
				pos2 = (roomIdx-size/2-1)*2 + 1;
			}
			else
			{
				pos1 = (roomIdx-1)*2;
				pos2 = (roomIdx-1)*2 + 1;
			}
			if(pos2 > size-1 || pos1 < 0 || pos2 < 0)
				return;
			player1 = pPaiMing[pos1][groupIdx];
			player2 = pPaiMing[pos2][groupIdx];
		}
		else if(timeIdx == 5)
		{
			player1 = G_1V1_PaiMing_1[0][0];
			player2 = G_1V1_PaiMing_1[0][1];
		}
	}
}

void AddKuaFu1V1PlayerWinNum(int timeIdx,int roleId)
{
	if(roleId == 0 || timeIdx < 1 || timeIdx > 5)
		return;
	boost::recursive_mutex::scoped_lock lk(G_1V1_Mutex);
	SKuaFu1V1UserData (*pPaiMing)[MAX_PAIMING_NUM] = NULL;
	int size = 0;
	GetKuaFuPaiMingList(timeIdx,pPaiMing,size);
	if(size == 0 || pPaiMing == NULL)
		return;

	for(uint8 i=0;i < MAX_PAIMING_NUM;i++)
	{
		for(int j=0;j < size;j++)
		{
			if(roleId == pPaiMing[j][i].data.role_id)
			{
				pPaiMing[j][i].data.winNum++;
				return;
			}
		}
	}
	return;
}

void PushKuaFu1V1TurnRankData()
{
	boost::recursive_mutex::scoped_lock lk(G_1V1_Mutex);
	if(G_1V1_TurnRank.empty())
		return;
	SSortKuaFu1V1Data dataSort;
	std::sort(G_1V1_TurnRank.begin(),G_1V1_TurnRank.end(),dataSort);
	for(uint16 i=0;i < G_1V1_TurnRank.size();i++)
		G_1V1_RankList.push_back(G_1V1_TurnRank[i]);
	G_1V1_TurnRank.clear();
}

void SetKuaFu1V1WinnerData(int timeIdx,int roomIdx,int winnerId)
{
	if(timeIdx < 1 || timeIdx > 5 || roomIdx < 1)
		return;

	string name1,name2;
	int ratio = 0;
	boost::recursive_mutex::scoped_lock lk(G_1V1_Mutex);
	if(timeIdx < 5)
	{
		SKuaFu1V1UserData (*pPaiMing)[MAX_PAIMING_NUM] = NULL;
		SKuaFu1V1UserData (*pPaiMingNext)[MAX_PAIMING_NUM] = NULL;
		int size = 0;
		int sizeNext = 0;
		GetKuaFuPaiMingList(timeIdx,pPaiMing,size);
		GetKuaFuPaiMingList(timeIdx+1,pPaiMingNext,sizeNext);
		if(size == 0 || pPaiMing == NULL || pPaiMingNext == NULL || sizeNext == 0)
			return;

		if(roomIdx <= size)
		{
			int groupIdx = 0;
			int pos = -1;
			if(roomIdx > size/2)
			{
				groupIdx = 1;
				pos = (roomIdx-size/2-1)*2;
			}
			else
			{
				pos = (roomIdx-1)*2;
			}
			if(pos > size-2 || pos < 0)
				return;
			int nextPos = pos/2;
			if(pPaiMing[pos][groupIdx].data.role_id == winnerId)
			{
				pPaiMingNext[nextPos][groupIdx] = pPaiMing[pos][groupIdx];
				if(pPaiMing[pos+1][groupIdx].data.role_id > 0)
					G_1V1_TurnRank.push_back(pPaiMing[pos+1][groupIdx].data);
			}
			else if(pPaiMing[pos+1][groupIdx].data.role_id == winnerId)
			{
				pPaiMingNext[nextPos][groupIdx] = pPaiMing[pos+1][groupIdx];
				if(pPaiMing[pos][groupIdx].data.role_id > 0)
					G_1V1_TurnRank.push_back(pPaiMing[pos][groupIdx].data);
			}
			else
				return;
			pPaiMingNext[nextPos][groupIdx].data.winNum = 0;
			if(pPaiMing[pos][groupIdx].data.role_id == winnerId)
			{
				ratio = ((pPaiMing[pos][groupIdx].rank < pPaiMing[pos+1][groupIdx].rank) ? KUAFU_1V1_VOTE_RATIO_H : 
						((pPaiMing[pos][groupIdx].rank > pPaiMing[pos+1][groupIdx].rank) ? KUAFU_1V1_VOTE_RATIO_L : KUAFU_1V1_VOTE_RATIO_M));
			}
			else if(pPaiMing[pos+1][groupIdx].data.role_id == winnerId)
			{
				ratio = ((pPaiMing[pos+1][groupIdx].rank < pPaiMing[pos][groupIdx].rank) ? KUAFU_1V1_VOTE_RATIO_H : 
						((pPaiMing[pos+1][groupIdx].rank > pPaiMing[pos][groupIdx].rank) ? KUAFU_1V1_VOTE_RATIO_L : KUAFU_1V1_VOTE_RATIO_M));
			}
			name1 = pPaiMing[pos][groupIdx].data.name;
			name2 = pPaiMing[pos+1][groupIdx].data.name;
		}
		else
			return;
	}
	else
	{
		if(roomIdx < 1)
			return;
		if(G_1V1_PaiMing_1[0][0].data.role_id == winnerId)
		{
			G_1V1_PaiMing_First = G_1V1_PaiMing_1[0][0];
			if(G_1V1_PaiMing_1[0][1].data.role_id > 0)
				G_1V1_RankList.push_back(G_1V1_PaiMing_1[0][1].data);
			G_1V1_RankList.push_back(G_1V1_PaiMing_First.data);
		}
		else if(G_1V1_PaiMing_1[0][1].data.role_id == winnerId)
		{
			G_1V1_PaiMing_First = G_1V1_PaiMing_1[0][1];
			if(G_1V1_PaiMing_1[0][0].data.role_id > 0)
				G_1V1_RankList.push_back(G_1V1_PaiMing_1[0][0].data);
			G_1V1_RankList.push_back(G_1V1_PaiMing_First.data);
		}
		G_1V1_PaiMing_First.data.winNum = 0;
		if(G_1V1_PaiMing_1[0][0].data.role_id == winnerId)
		{
			ratio = ((G_1V1_PaiMing_1[0][0].rank < G_1V1_PaiMing_1[0][1].rank) ? KUAFU_1V1_VOTE_RATIO_H : 
					((G_1V1_PaiMing_1[0][0].rank > G_1V1_PaiMing_1[0][1].rank) ? KUAFU_1V1_VOTE_RATIO_L : KUAFU_1V1_VOTE_RATIO_M));
		}
		else if(G_1V1_PaiMing_1[0][1].data.role_id == winnerId)
		{
			ratio = ((G_1V1_PaiMing_1[0][1].rank < G_1V1_PaiMing_1[0][0].rank) ? KUAFU_1V1_VOTE_RATIO_H : 
					((G_1V1_PaiMing_1[0][1].rank > G_1V1_PaiMing_1[0][0].rank) ? KUAFU_1V1_VOTE_RATIO_L : KUAFU_1V1_VOTE_RATIO_M));
		}
		name1 = G_1V1_PaiMing_1[0][0].data.name;
		name2 = G_1V1_PaiMing_1[0][1].data.name;
	}
	if(ratio == 0)
		return;

	int voteNodePos = 0xff;
	if(timeIdx == 1)
	{
		if(roomIdx <= 8)
			voteNodePos = roomIdx-1;
		else
			voteNodePos = roomIdx-1-8+16;
	}
	else if(timeIdx == 2)
	{
		if(roomIdx <= 4)
			voteNodePos = roomIdx-1+8;
		else
			voteNodePos = roomIdx-1-4+16+8;
	}
	else if(timeIdx == 3)
	{
		if(roomIdx <= 2)
			voteNodePos = roomIdx-1+8+4;
		else
			voteNodePos = roomIdx-1-2+16+8+4;
	}
	else if(timeIdx == 4)
	{
		if(roomIdx <= 1)
			voteNodePos = roomIdx-1+8+4+2;
		else
			voteNodePos = roomIdx-1-1+16+8+4+2;
	}
	else if(timeIdx == 5)
		voteNodePos = 31;
	if(voteNodePos == 0xff)
		return;
	
	char buf[256];
	for(map<uint32,KuaFu1V1VoteData>::iterator it = G_1V1_VoteList[voteNodePos].begin();it != G_1V1_VoteList[voteNodePos].end();it++)
	{
		if(it->second.voteRoleId == (uint32)winnerId)
		{
			SMailData mail;
			SAwardData award;
			award.type = HDAT_MONEY;
			award.num = it->second.money * ratio / 100.0;
			mail.awards.push_back(award);
			snprintf(buf,sizeof(buf)-1,LANGUAGE_SSJ_0071,name1.c_str(),name2.c_str(), award.num);
			SendSystemMail(it->first,buf,&mail);
		}
		else
		{
			snprintf(buf, sizeof(buf) - 1, LANGUAGE_ZQX_0087, name1.c_str(), name2.c_str());
			SendSystemMail(it->first, buf);
		}
	}
}

void Enter1V1FinalsScene(CUser *pUser)
{
#ifdef KUA_FU
	if(pUser == NULL)
		return;
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_KUA_FU_1V1);
	msg<<(uint8)24;

	CSocketServer &sockServer = SingletonSocket::instance();
	if(InKuaFu1V1FinalsTime())
	{
		if(pUser->HaveTeam())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0056,TIPS_FAILURE_COLOR);
			sockServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		if(pUser->GetSrcSceneId() == KUA_FU_1V1_SCENE_ID)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0076,TIPS_FAILURE_COLOR);
			sockServer.SendMsg(pUser->GetSock(),msg);
			return;
		}
		
		int timeIdx = GetKuaFu1V1FinalsTimeIndex();
		int roomIdx = 0;
		if(!InKuaFu1V1FinalsPaiMingByIdx(pUser->GetRoleId(),timeIdx,roomIdx) || roomIdx < 1)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0057,TIPS_FAILURE_COLOR);
			sockServer.SendMsg(pUser->GetSock(),msg);
			return;
		}

		SKuaFu1V1UserData player1;
		SKuaFu1V1UserData player2;
		GetKuaFu1V1FightPlayers(timeIdx,roomIdx,player1,player2);
		if(player1.data.winNum >= 2 || player2.data.winNum >= 2 || player1.data.role_id == 0 || player2.data.role_id == 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0523,TIPS_FAILURE_COLOR);
			sockServer.SendMsg(pUser->GetSock(),msg);
			return;
		}

		CSceneManager &scene = SingletonSceneManager::instance();
		CScene *pScene = scene.GetKuaFu1V1SceneByIndex(roomIdx);
		if(pScene == NULL)
			return;

		msg<<PRO_SUCCESS;
		sockServer.SendMsg(pUser->GetSock(),msg);
		
		pUser->SaveEnterPos(pUser->GetSceneId(),pUser->GetX(),pUser->GetY());

		uint16 x=0,y=0;
		if(player1.data.role_id == (int)pUser->GetRoleId())
		{
			x = 469;
			y = 410;
		}
		else
		{
			x = 1152;
			y = 832;
		}
//		if(!pScene->GetCanWalkPos(x,y))
//			return;
		CNetMessage msg1;
		msg1.ReWrite();
		msg1.SetType(PRO_JUMP_SCENE);
		msg1<<(uint16)pScene->GetSrcSceneId()<<x<<y<<(uint8)0<<(uint8)0;
		sockServer.SendMsg(pUser->GetSock(),msg1);
		pUser->SetPos(x,y);
		pUser->SetFace(0);
		pUser->EnterScene(pScene);
	}
	else
	{
		char buf[128];
		snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0058);
		msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
		sockServer.SendMsg(pUser->GetSock(),msg);
	}
#endif
}

void MakeKuaFu1V1PanelInfo(CUser *pUser,uint8 type,CNetMessage &msg)
{
	if(pUser == NULL)
		return;
	int curTime = GetHour()*100 + GetMinute();
	int timeIdx = GetKuaFu1V1FinalsTimeIndex();

	msg.ReWrite();
	msg.SetType(MSG_KUA_FU_1V1);
	msg<<(uint8)21<<type;
	boost::recursive_mutex::scoped_lock lk(G_1V1_Mutex);
	if(type == 0 || type == 1)	// 上半场，下半场
	{
		int idx = type;
		uint8 roleNum = sizeof(G_1V1_PaiMing_16)/sizeof(G_1V1_PaiMing_16[0]);
		uint8 showIdx = 0;
		if(timeIdx > 0)
			showIdx = timeIdx;
		else if(curTime >= KUA_FU_FINALS_END_TIME)
			showIdx = 5;
		msg<<showIdx<<roleNum;
		for(uint8 i=0;i < roleNum;i++)
			msg<<G_1V1_PaiMing_16[i][idx].data.role_id<<G_1V1_PaiMing_16[i][idx].data.name;
		uint8 nodeNum1 = sizeof(G_1V1_PaiMing_8)/sizeof(G_1V1_PaiMing_8[0]);
		uint8 nodeNum2 = sizeof(G_1V1_PaiMing_4)/sizeof(G_1V1_PaiMing_4[0]);
		uint8 nodeNum3 = sizeof(G_1V1_PaiMing_2)/sizeof(G_1V1_PaiMing_2[0]);
		msg<<nodeNum1;
		if(timeIdx < 0 || timeIdx == 5)
		{
			if(curTime < KUA_FU_FINALS_START_TIME)	// 只有第一轮可下注
			{
				for(uint8 i=0;i < nodeNum1;i++)	// 8
				{
					if(G_1V1_PaiMing_16[i*2][idx].data.role_id > 0 && G_1V1_PaiMing_16[i*2+1][idx].data.role_id > 0)
						msg<<pUser->GetKuaFu1V1VoteState(i+idx*16)<<(-1);
					else
						msg<<(uint8)EKF_1V1_CannotVote<<(-1);
				}
				msg<<nodeNum2;
				for(uint8 i=0;i < nodeNum2;i++)	// 4
					msg<<(uint8)EKF_1V1_NotInTime<<(-1);
				msg<<nodeNum3;
				for(uint8 i=0;i < nodeNum3;i++)	// 2
					msg<<(uint8)EKF_1V1_NotInTime<<(-1);
				uint8 firstBetType = 1;	// 1下注 2出结果显示头像
				msg<<firstBetType;
				msg<<(uint8)EKF_1V1_NotInTime<<(-1);
			}
			else	// 全部不可下注,显示结果
			{
				for(uint8 i=0;i < nodeNum1;i++)	// 8
					msg<<(uint8)EKF_1V1_View<<G_1V1_PaiMing_8[i][idx].data.role_id;
				msg<<nodeNum2;
				for(uint8 i=0;i < nodeNum2;i++)	// 4
					msg<<(uint8)EKF_1V1_View<<G_1V1_PaiMing_4[i][idx].data.role_id;
				msg<<nodeNum3;
				for(uint8 i=0;i < nodeNum3;i++)	// 2
					msg<<(uint8)EKF_1V1_View<<G_1V1_PaiMing_2[i][idx].data.role_id;
				uint8 firstBetType = 2;	// 1下注 2出结果显示头像
				msg<<firstBetType;
				msg<<G_1V1_PaiMing_1[0][idx].data.role_id<<G_1V1_PaiMing_1[0][idx].data.name<<(uint8)G_1V1_PaiMing_1[0][idx].data.xiang<<(uint8)G_1V1_PaiMing_1[0][idx].data.sex<<(uint16)G_1V1_PaiMing_1[0][idx].data.level;
			}
		}
		else if(timeIdx >= 1 && timeIdx <= 4)	// 第1~4轮进行中
		{
			for(uint8 i=0;i < nodeNum1;i++)	// 8
			{
				if(timeIdx == 1 && G_1V1_PaiMing_8[i][idx].data.role_id <= 0)
					msg<<(uint8)EKF_1V1_CannotVote<<G_1V1_PaiMing_8[i][idx].data.role_id;
				else
					msg<<(uint8)EKF_1V1_View<<G_1V1_PaiMing_8[i][idx].data.role_id;
			}
			msg<<nodeNum2;
			for(uint8 i=0;i < nodeNum2;i++)	// 4
			{
				if(timeIdx == 1)
				{
					if(G_1V1_PaiMing_8[i*2][idx].data.role_id > 0 && G_1V1_PaiMing_8[i*2+1][idx].data.role_id > 0)
						msg<<pUser->GetKuaFu1V1VoteState(i+8+idx*16)<<G_1V1_PaiMing_4[i][idx].data.role_id;
					else
						msg<<(uint8)EKF_1V1_NotInTime<<G_1V1_PaiMing_4[i][idx].data.role_id;
				}
				else if(timeIdx == 2 && G_1V1_PaiMing_4[i][idx].data.role_id <= 0)
					msg<<(uint8)EKF_1V1_CannotVote<<G_1V1_PaiMing_4[i][idx].data.role_id;
				else
					msg<<(uint8)EKF_1V1_View<<G_1V1_PaiMing_4[i][idx].data.role_id;
			}
			msg<<nodeNum3;
			for(uint8 i=0;i < nodeNum3;i++)	// 2
			{
				if(timeIdx == 1)
					msg<<(uint8)EKF_1V1_NotInTime<<G_1V1_PaiMing_2[i][idx].data.role_id;
				else if(timeIdx == 2)
				{
					if(G_1V1_PaiMing_4[i*2][idx].data.role_id > 0 && G_1V1_PaiMing_4[i*2+1][idx].data.role_id > 0)
						msg<<pUser->GetKuaFu1V1VoteState(i+12+idx*16)<<G_1V1_PaiMing_2[i][idx].data.role_id;
					else
						msg<<(uint8)EKF_1V1_NotInTime<<G_1V1_PaiMing_2[i][idx].data.role_id;
				}
				else if(timeIdx == 3 && G_1V1_PaiMing_2[i][idx].data.role_id <= 0)
					msg<<(uint8)EKF_1V1_CannotVote<<G_1V1_PaiMing_2[i][idx].data.role_id;
				else
					msg<<(uint8)EKF_1V1_View<<G_1V1_PaiMing_2[i][idx].data.role_id;
			}
			uint8 firstBetType = 1;	// 1下注 2出结果显示头像
			if(timeIdx <= 2)
				msg<<firstBetType<<(uint8)EKF_1V1_NotInTime<<G_1V1_PaiMing_1[0][idx].data.role_id;
			else if(timeIdx == 3)
			{
				if(G_1V1_PaiMing_2[0][idx].data.role_id > 0 && G_1V1_PaiMing_2[1][idx].data.role_id > 0)
					msg<<firstBetType<<pUser->GetKuaFu1V1VoteState(14+idx*16)<<G_1V1_PaiMing_1[0][idx].data.role_id;
				else
					msg<<firstBetType<<(uint8)EKF_1V1_NotInTime<<G_1V1_PaiMing_1[0][idx].data.role_id;
			}
			else
			{
				if(G_1V1_PaiMing_1[0][idx].data.role_id > 0)
				{
					firstBetType = 2;
					msg<<firstBetType<<G_1V1_PaiMing_1[0][idx].data.role_id<<G_1V1_PaiMing_1[0][idx].data.name<<(uint8)G_1V1_PaiMing_1[0][idx].data.xiang<<(uint8)G_1V1_PaiMing_1[0][idx].data.sex<<(uint16)G_1V1_PaiMing_1[0][idx].data.level;
				}
				else
				{
					msg<<firstBetType<<(uint8)EKF_1V1_CannotVote<<G_1V1_PaiMing_1[0][idx].data.role_id;
				}
			}
		}
	}
	else if(type == 2)	// 总决赛
	{
		if(timeIdx < 0)
		{
			if(curTime < KUA_FU_FINALS_START_TIME)
				msg<<0<<0<<(uint8)EKF_1V1_NotInTime<<(-1);
			else
			{
				for(uint8 i=0;i < MAX_PAIMING_NUM;i++)
				{
					if(G_1V1_PaiMing_1[0][i].data.role_id > 0)
					{
						msg<<G_1V1_PaiMing_1[0][i].data.role_id<<G_1V1_PaiMing_1[0][i].data.name<<(uint8)G_1V1_PaiMing_1[0][i].data.xiang<<(uint8)G_1V1_PaiMing_1[0][i].data.sex<<(uint16)G_1V1_PaiMing_1[0][i].data.level
							<<G_1V1_PaiMing_1[0][i].data.super_level<<G_1V1_PaiMing_1[0][i].data.zhandouli;
					}
					else
						msg<<0;
				}
				msg<<(uint8)EKF_1V1_View<<G_1V1_PaiMing_First.data.role_id;
			}
		}
		else
		{
			for(uint8 i=0;i < MAX_PAIMING_NUM;i++)
			{
				if(G_1V1_PaiMing_1[0][i].data.role_id > 0)
				{
					msg<<G_1V1_PaiMing_1[0][i].data.role_id<<G_1V1_PaiMing_1[0][i].data.name<<(uint8)G_1V1_PaiMing_1[0][i].data.xiang<<(uint8)G_1V1_PaiMing_1[0][i].data.sex<<(uint16)G_1V1_PaiMing_1[0][i].data.level
						<<G_1V1_PaiMing_1[0][i].data.super_level<<G_1V1_PaiMing_1[0][i].data.zhandouli;
				}
				else
					msg<<0;
			}
			if(timeIdx <= 3)
				msg<<(uint8)EKF_1V1_NotInTime<<G_1V1_PaiMing_First.data.role_id;
			else if(timeIdx == 4)
			{
				if(G_1V1_PaiMing_1[0][0].data.role_id > 0 && G_1V1_PaiMing_1[0][1].data.role_id > 0)
					msg<<pUser->GetKuaFu1V1VoteState(31)<<G_1V1_PaiMing_First.data.role_id;
				else
					msg<<(uint8)EKF_1V1_NotInTime<<G_1V1_PaiMing_First.data.role_id;
			}
			else
			{
				if(G_1V1_PaiMing_First.data.role_id > 0)
					msg<<(uint8)EKF_1V1_View<<G_1V1_PaiMing_First.data.role_id;
				else
					msg<<(uint8)EKF_1V1_CannotVote<<G_1V1_PaiMing_First.data.role_id;
			}
		}
	}
}

void MakeKuaFu1V1PanelInfoOld(CUser *pUser,uint8 type,CNetMessage &msg)
{
	if(pUser == NULL)
		return;
	msg.ReWrite();
	msg.SetType(MSG_KUA_FU_1V1);
	msg<<(uint8)28<<type;
	
	if(type == 0 || type == 1)	// 上半场，下半场
	{
		int idx = type;
		uint8 roleNum = sizeof(G_1V1_PaiMing_Old_16)/sizeof(G_1V1_PaiMing_Old_16[0]);
		const uint8 showIdx = 5;
		msg<<showIdx<<roleNum;
		for(uint8 i=0;i < roleNum;i++)
			msg<<G_1V1_PaiMing_Old_16[i][idx].data.role_id<<G_1V1_PaiMing_Old_16[i][idx].data.name;
		uint8 nodeNum1 = sizeof(G_1V1_PaiMing_Old_8)/sizeof(G_1V1_PaiMing_Old_8[0]);
		uint8 nodeNum2 = sizeof(G_1V1_PaiMing_Old_4)/sizeof(G_1V1_PaiMing_Old_4[0]);
		uint8 nodeNum3 = sizeof(G_1V1_PaiMing_Old_2)/sizeof(G_1V1_PaiMing_Old_2[0]);
		msg<<nodeNum1;
		for(uint8 i=0;i < nodeNum1;i++)	// 8
			msg<<(uint8)EKF_1V1_View<<G_1V1_PaiMing_Old_8[i][idx].data.role_id;
		msg<<nodeNum2;
		for(uint8 i=0;i < nodeNum2;i++)	// 4
			msg<<(uint8)EKF_1V1_View<<G_1V1_PaiMing_Old_4[i][idx].data.role_id;
		msg<<nodeNum3;
		for(uint8 i=0;i < nodeNum3;i++)	// 2
			msg<<(uint8)EKF_1V1_View<<G_1V1_PaiMing_Old_2[i][idx].data.role_id;
		const uint8 firstBetType = 2;	// 1下注 2出结果显示头像
		msg<<firstBetType;
		msg<<G_1V1_PaiMing_Old_1[0][idx].data.role_id<<G_1V1_PaiMing_Old_1[0][idx].data.name<<(uint8)G_1V1_PaiMing_Old_1[0][idx].data.xiang<<(uint8)G_1V1_PaiMing_Old_1[0][idx].data.sex<<(uint16)G_1V1_PaiMing_Old_1[0][idx].data.level;
	}
	else if(type == 2)	// 总决赛
	{
		for(uint8 i=0;i < MAX_PAIMING_NUM;i++)
		{
			if(G_1V1_PaiMing_Old_1[0][i].data.role_id > 0)
			{
				msg<<G_1V1_PaiMing_Old_1[0][i].data.role_id<<G_1V1_PaiMing_Old_1[0][i].data.name<<(uint8)G_1V1_PaiMing_Old_1[0][i].data.xiang<<(uint8)G_1V1_PaiMing_Old_1[0][i].data.sex<<(uint16)G_1V1_PaiMing_Old_1[0][i].data.level
					<<G_1V1_PaiMing_Old_1[0][i].data.super_level<<G_1V1_PaiMing_Old_1[0][i].data.zhandouli;
			}
			else
				msg<<0;
		}
		msg<<(uint8)EKF_1V1_View<<G_1V1_PaiMing_First_Old.data.role_id;
	}
}

void MakeKuaFu1V1NodeInfo(CUser *pUser,uint8 type,uint8 nodeIdx,CNetMessage &msg)
{
	if((type <= 1 && nodeIdx > 15) || (type == 2 && nodeIdx > 1) || type > 2 || nodeIdx <= 0 || pUser == NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0061,TIPS_FAILURE_COLOR);
		return;
	}

	msg<<PRO_SUCCESS;

	int curTime = GetHour()*100 + GetMinute();
	int timeIdx = GetKuaFu1V1FinalsTimeIndex();
	boost::recursive_mutex::scoped_lock lk(G_1V1_Mutex);
	if(type == 0 || type == 1)
	{
		int lastIdx = 0;
		int curIdx = 0;
		int lastPos = 0;
		int curPos = 0;
		if(nodeIdx <= 8)
		{
			lastIdx = 1;
			curIdx = 2;
			lastPos = (nodeIdx-1)*2;
			curPos = nodeIdx-1;
		}
		else if(nodeIdx <= 12)
		{
			lastIdx = 2;
			curIdx = 3;
			lastPos = (nodeIdx-8-1)*2;
			curPos = nodeIdx-8-1;
		}
		else if(nodeIdx <= 14)
		{
			lastIdx = 3;
			curIdx = 4;
			lastPos = (nodeIdx-12-1)*2;
			curPos = nodeIdx-12-1;
		}
		else if(nodeIdx == 15)
		{
			lastIdx = 4;
			curIdx = 5;
			lastPos = (nodeIdx-14-1)*2;
			curPos = nodeIdx-14-1;
		}

		int sizeLast = 0;
		int sizeCur = 0;
		SKuaFu1V1UserData (*pPaiMingLast)[MAX_PAIMING_NUM] = NULL;
		SKuaFu1V1UserData (*pPaiMingCur)[MAX_PAIMING_NUM] = NULL;
		GetKuaFuPaiMingList(lastIdx,pPaiMingLast,sizeLast);
		GetKuaFuPaiMingList(curIdx,pPaiMingCur,sizeCur);
		if(pPaiMingLast == NULL || pPaiMingCur == NULL)
			return;

		KuaFu1V1VoteData data;
		uint32 winnerId = pPaiMingCur[curPos][type].data.role_id;
		uint32 voteId = GetKuaFu1V1VoteStateIdByNode(type,nodeIdx,pUser->GetRoleId(),data);
		uint8 canVote = 0;
		KuaFu1V1VoteData role1,role2;
		GetKuaFu1V1TotolMoneyByNode(type,nodeIdx,role1,role2);
		if(voteId == 0)	// 未投票
		{
			if((timeIdx+1 == lastIdx) || (timeIdx < 0 && curTime < KUA_FU_FINALS_START_TIME))
			{
				if(pPaiMingLast[lastPos][type].data.role_id > 0 && pPaiMingLast[lastPos+1][type].data.role_id > 0)
				{
					int state = pUser->GetKuaFu1V1VoteState(nodeIdx-1+type*16);
					if(state == EKF_1V1_CanVote)
						canVote = 1;
				}
			}
		}
		msg<<winnerId<<voteId<<canVote<<VOTE_NEED_MONEY;
		
		int ratio1 = 0;
		int ratio2 = 0;
		if(pPaiMingLast[lastPos][type].rank < pPaiMingLast[lastPos+1][type].rank)
		{
			ratio1 = KUAFU_1V1_VOTE_RATIO_H;
			ratio2 = KUAFU_1V1_VOTE_RATIO_L;
		}
		else if(pPaiMingLast[lastPos][type].rank == pPaiMingLast[lastPos+1][type].rank)
		{
			ratio1 = KUAFU_1V1_VOTE_RATIO_M;
			ratio2 = KUAFU_1V1_VOTE_RATIO_M;
		}
		else
		{
			ratio1 = KUAFU_1V1_VOTE_RATIO_L;
			ratio2 = KUAFU_1V1_VOTE_RATIO_H;
		}
		
		msg<<pPaiMingLast[lastPos][type].data.role_id;
		if(pPaiMingLast[lastPos][type].data.role_id > 0)
		{
			msg<<pPaiMingLast[lastPos][type].data.name<<(uint8)pPaiMingLast[lastPos][type].data.xiang<<(uint8)pPaiMingLast[lastPos][type].data.sex<<pPaiMingLast[lastPos][type].data.winNum;
			if(role1.voteRoleId == (uint32)pPaiMingLast[lastPos][type].data.role_id)
				msg<<role1.money;
			else
				msg<<role2.money;
			msg<<ratio1<<pPaiMingLast[lastPos][type].data.zhandouli;
		}
		msg<<pPaiMingLast[lastPos+1][type].data.role_id;
		if(pPaiMingLast[lastPos+1][type].data.role_id > 0)
		{
			msg<<pPaiMingLast[lastPos+1][type].data.name<<(uint8)pPaiMingLast[lastPos+1][type].data.xiang<<(uint8)pPaiMingLast[lastPos+1][type].data.sex<<pPaiMingLast[lastPos+1][type].data.winNum;
			if(role1.voteRoleId == (uint32)pPaiMingLast[lastPos+1][type].data.role_id)
				msg<<role1.money;
			else
				msg<<role2.money;
			msg<<ratio2<<pPaiMingLast[lastPos+1][type].data.zhandouli;
		}
	}
	else	// 总决赛
	{
		KuaFu1V1VoteData votedata;
		uint32 winnerId = G_1V1_PaiMing_First.data.role_id;
		uint32 voteId = GetKuaFu1V1VoteStateIdByNode(type,nodeIdx,pUser->GetRoleId(),votedata);
		uint8 canVote = 0;
		KuaFu1V1VoteData role1,role2;
		GetKuaFu1V1TotolMoneyByNode(type,nodeIdx,role1,role2);
		if(voteId == 0)	// 未投票
		{
			if(timeIdx+1 == 5)
			{
				if(G_1V1_PaiMing_1[0][0].data.role_id > 0 && G_1V1_PaiMing_1[0][1].data.role_id > 0)
				{
					int state = pUser->GetKuaFu1V1VoteState(31);
					if(state == EKF_1V1_CanVote)
						canVote = 1;
				}
			}
		}
		msg<<winnerId<<voteId<<canVote<<VOTE_NEED_MONEY;
		
		int ratio1 = 0;
		int ratio2 = 0;
		if(G_1V1_PaiMing_1[0][0].rank < G_1V1_PaiMing_1[0][1].rank)
		{
			ratio1 = KUAFU_1V1_VOTE_RATIO_H;
			ratio2 = KUAFU_1V1_VOTE_RATIO_L;
		}
		else if(G_1V1_PaiMing_1[0][0].rank == G_1V1_PaiMing_1[0][1].rank)
		{
			ratio1 = KUAFU_1V1_VOTE_RATIO_M;
			ratio2 = KUAFU_1V1_VOTE_RATIO_M;
		}
		else
		{
			ratio1 = KUAFU_1V1_VOTE_RATIO_L;
			ratio2 = KUAFU_1V1_VOTE_RATIO_H;
		}
		
		msg<<G_1V1_PaiMing_1[0][0].data.role_id;
		if(G_1V1_PaiMing_1[0][0].data.role_id > 0)
		{
			msg<<G_1V1_PaiMing_1[0][0].data.name<<(uint8)G_1V1_PaiMing_1[0][0].data.xiang<<(uint8)G_1V1_PaiMing_1[0][0].data.sex<<G_1V1_PaiMing_1[0][0].data.winNum;
			if(role1.voteRoleId == (uint32)G_1V1_PaiMing_1[0][0].data.role_id)
				msg<<role1.money;
			else
				msg<<role2.money;
			msg<<ratio1<<G_1V1_PaiMing_1[0][0].data.zhandouli;
		}
		msg<<G_1V1_PaiMing_1[0][1].data.role_id;
		if(G_1V1_PaiMing_1[0][1].data.role_id > 0)
		{
			msg<<G_1V1_PaiMing_1[0][1].data.name<<(uint8)G_1V1_PaiMing_1[0][1].data.xiang<<(uint8)G_1V1_PaiMing_1[0][1].data.sex<<G_1V1_PaiMing_1[0][1].data.winNum;
			if(role1.voteRoleId == (uint32)G_1V1_PaiMing_1[0][1].data.role_id)
				msg<<role1.money;
			else
				msg<<role2.money;
			msg<<ratio2<<G_1V1_PaiMing_1[0][1].data.zhandouli;
		}
	}
}

void MakeKuaFu1V1NodeInfoOld(CUser *pUser,uint8 type,uint8 nodeIdx,CNetMessage &msg)
{
	if((type <= 1 && nodeIdx > 15) || (type == 2 && nodeIdx > 1) || type > 2 || nodeIdx <= 0 || pUser == NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0061,TIPS_FAILURE_COLOR);
		return;
	}

	msg<<PRO_SUCCESS;
	if(type == 0 || type == 1)
	{
		int lastIdx = 0;
		int curIdx = 0;
		int lastPos = 0;
		int curPos = 0;
		if(nodeIdx <= 8)
		{
			lastIdx = 1;
			curIdx = 2;
			lastPos = (nodeIdx-1)*2;
			curPos = nodeIdx-1;
		}
		else if(nodeIdx <= 12)
		{
			lastIdx = 2;
			curIdx = 3;
			lastPos = (nodeIdx-8-1)*2;
			curPos = nodeIdx-8-1;
		}
		else if(nodeIdx <= 14)
		{
			lastIdx = 3;
			curIdx = 4;
			lastPos = (nodeIdx-12-1)*2;
			curPos = nodeIdx-12-1;
		}
		else if(nodeIdx == 15)
		{
			lastIdx = 4;
			curIdx = 5;
			lastPos = (nodeIdx-14-1)*2;
			curPos = nodeIdx-14-1;
		}

		int sizeLast = 0;
		int sizeCur = 0;
		SKuaFu1V1UserData (*pPaiMingLast)[MAX_PAIMING_NUM] = NULL;
		SKuaFu1V1UserData (*pPaiMingCur)[MAX_PAIMING_NUM] = NULL;
		GetKuaFuPaiMingListOld(lastIdx,pPaiMingLast,sizeLast);
		GetKuaFuPaiMingListOld(curIdx,pPaiMingCur,sizeCur);
		if(pPaiMingLast == NULL || pPaiMingCur == NULL)
			return;

		KuaFu1V1VoteData data;
		uint32 winnerId = pPaiMingCur[curPos][type].data.role_id;
		uint32 voteId = GetKuaFu1V1VoteStateIdByNodeOld(type,nodeIdx,pUser->GetRoleId(),data);
		uint8 canVote = 0;
		KuaFu1V1VoteData role1,role2;
		GetKuaFu1V1TotolMoneyByNodeOld(type,nodeIdx,role1,role2);
		msg<<winnerId<<voteId<<canVote<<VOTE_NEED_MONEY;
		
		int ratio1 = 0;
		int ratio2 = 0;
		if(pPaiMingLast[lastPos][type].rank < pPaiMingLast[lastPos+1][type].rank)
		{
			ratio1 = KUAFU_1V1_VOTE_RATIO_H;
			ratio2 = KUAFU_1V1_VOTE_RATIO_L;
		}
		else if(pPaiMingLast[lastPos][type].rank == pPaiMingLast[lastPos+1][type].rank)
		{
			ratio1 = KUAFU_1V1_VOTE_RATIO_M;
			ratio2 = KUAFU_1V1_VOTE_RATIO_M;
		}
		else
		{
			ratio1 = KUAFU_1V1_VOTE_RATIO_L;
			ratio2 = KUAFU_1V1_VOTE_RATIO_H;
		}
		
		msg<<pPaiMingLast[lastPos][type].data.role_id;
		if(pPaiMingLast[lastPos][type].data.role_id > 0)
		{
			msg<<pPaiMingLast[lastPos][type].data.name<<(uint8)pPaiMingLast[lastPos][type].data.xiang<<(uint8)pPaiMingLast[lastPos][type].data.sex<<pPaiMingLast[lastPos][type].data.winNum;
			if(role1.voteRoleId == (uint32)pPaiMingLast[lastPos][type].data.role_id)
				msg<<role1.money;
			else
				msg<<role2.money;
			msg<<ratio1<<pPaiMingLast[lastPos][type].data.zhandouli;
		}
		msg<<pPaiMingLast[lastPos+1][type].data.role_id;
		if(pPaiMingLast[lastPos+1][type].data.role_id > 0)
		{
			msg<<pPaiMingLast[lastPos+1][type].data.name<<(uint8)pPaiMingLast[lastPos+1][type].data.xiang<<(uint8)pPaiMingLast[lastPos+1][type].data.sex<<pPaiMingLast[lastPos+1][type].data.winNum;
			if(role1.voteRoleId == (uint32)pPaiMingLast[lastPos+1][type].data.role_id)
				msg<<role1.money;
			else
				msg<<role2.money;
			msg<<ratio2<<pPaiMingLast[lastPos+1][type].data.zhandouli;
		}
	}
	else	// 总决赛
	{
		KuaFu1V1VoteData votedata;
		uint32 winnerId = G_1V1_PaiMing_First_Old.data.role_id;
		uint32 voteId = GetKuaFu1V1VoteStateIdByNodeOld(type,nodeIdx,pUser->GetRoleId(),votedata);
		uint8 canVote = 0;
		KuaFu1V1VoteData role1,role2;
		GetKuaFu1V1TotolMoneyByNodeOld(type,nodeIdx,role1,role2);
		msg<<winnerId<<voteId<<canVote<<VOTE_NEED_MONEY;
		
		int ratio1 = 0;
		int ratio2 = 0;
		if(G_1V1_PaiMing_Old_1[0][0].rank < G_1V1_PaiMing_Old_1[0][1].rank)
		{
			ratio1 = KUAFU_1V1_VOTE_RATIO_H;
			ratio2 = KUAFU_1V1_VOTE_RATIO_L;
		}
		else if(G_1V1_PaiMing_Old_1[0][0].rank == G_1V1_PaiMing_Old_1[0][1].rank)
		{
			ratio1 = KUAFU_1V1_VOTE_RATIO_M;
			ratio2 = KUAFU_1V1_VOTE_RATIO_M;
		}
		else
		{
			ratio1 = KUAFU_1V1_VOTE_RATIO_L;
			ratio2 = KUAFU_1V1_VOTE_RATIO_H;
		}
		
		msg<<G_1V1_PaiMing_Old_1[0][0].data.role_id;
		if(G_1V1_PaiMing_Old_1[0][0].data.role_id > 0)
		{
			msg<<G_1V1_PaiMing_Old_1[0][0].data.name<<(uint8)G_1V1_PaiMing_Old_1[0][0].data.xiang<<(uint8)G_1V1_PaiMing_Old_1[0][0].data.sex<<G_1V1_PaiMing_Old_1[0][0].data.winNum;
			if(role1.voteRoleId == (uint32)G_1V1_PaiMing_Old_1[0][0].data.role_id)
				msg<<role1.money;
			else
				msg<<role2.money;
			msg<<ratio1<<G_1V1_PaiMing_Old_1[0][0].data.zhandouli;
		}
		msg<<G_1V1_PaiMing_Old_1[0][1].data.role_id;
		if(G_1V1_PaiMing_Old_1[0][1].data.role_id > 0)
		{
			msg<<G_1V1_PaiMing_Old_1[0][1].data.name<<(uint8)G_1V1_PaiMing_Old_1[0][1].data.xiang<<(uint8)G_1V1_PaiMing_Old_1[0][1].data.sex<<G_1V1_PaiMing_Old_1[0][1].data.winNum;
			if(role1.voteRoleId == (uint32)G_1V1_PaiMing_Old_1[0][1].data.role_id)
				msg<<role1.money;
			else
				msg<<role2.money;
			msg<<ratio2<<G_1V1_PaiMing_Old_1[0][1].data.zhandouli;
		}
	}
}

void KuaFu1V1Vote(CUser *pUser,uint8 type,uint8 nodeIdx,uint32 voteId,CNetMessage &msg)
{
	if((type <= 1 && nodeIdx > 15) || (type == 2 && nodeIdx > 1) || type > 2 || nodeIdx <= 0 || pUser == NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0061,TIPS_FAILURE_COLOR);
		return;
	}

	int curTime = GetHour()*100 + GetMinute();
	int timeIdx = GetKuaFu1V1FinalsTimeIndex();
	uint8 canVote = 0;
	uint8 voteFlagIdx = 0;
	
	boost::recursive_mutex::scoped_lock lk(G_1V1_Mutex);
	if(type == 0 || type == 1)
	{
		int lastIdx = 0;
		int curIdx = 0;
		int lastPos = 0;
//		int curPos = 0;
		if(nodeIdx <= 8)
		{
			lastIdx = 1;
			curIdx = 2;
			lastPos = (nodeIdx-1)*2;
//			curPos = nodeIdx-1;
		}
		else if(nodeIdx <= 12)
		{
			lastIdx = 2;
			curIdx = 3;
			lastPos = (nodeIdx-8-1)*2;
//			curPos = nodeIdx-8-1;
		}
		else if(nodeIdx <= 14)
		{
			lastIdx = 3;
			curIdx = 4;
			lastPos = (nodeIdx-12-1)*2;
//			curPos = nodeIdx-12-1;
		}
		else if(nodeIdx == 15)
		{
			lastIdx = 4;
			curIdx = 5;
			lastPos = (nodeIdx-14-1)*2;
//			curPos = nodeIdx-14-1;
		}

		int sizeLast = 0;
		int sizeCur = 0;
		SKuaFu1V1UserData (*pPaiMingLast)[MAX_PAIMING_NUM] = NULL;
		SKuaFu1V1UserData (*pPaiMingCur)[MAX_PAIMING_NUM] = NULL;
		GetKuaFuPaiMingList(lastIdx,pPaiMingLast,sizeLast);
		GetKuaFuPaiMingList(curIdx,pPaiMingCur,sizeCur);
		if(pPaiMingLast == NULL || pPaiMingCur == NULL)
			return;

		KuaFu1V1VoteData data;
		uint32 lastvoteId = GetKuaFu1V1VoteStateIdByNode(type,nodeIdx,pUser->GetRoleId(),data);
		if(lastvoteId == 0)	// 未投票
		{
			if((timeIdx+1 == lastIdx) || (timeIdx < 0 && curTime < KUA_FU_FINALS_START_TIME))
			{
				if(pPaiMingLast[lastPos][type].data.role_id > 0 && pPaiMingLast[lastPos+1][type].data.role_id > 0)
				{
					if(pPaiMingLast[lastPos][type].data.role_id == (int)voteId || pPaiMingLast[lastPos+1][type].data.role_id == (int)voteId)
					{
						int state = pUser->GetKuaFu1V1VoteState(nodeIdx-1+type*16);
						if(state == EKF_1V1_CanVote)
							canVote = 1;
					}
				}
			}
		}
		voteFlagIdx = nodeIdx-1+type*16;
	}
	else
	{
		KuaFu1V1VoteData votedata;
		uint32 lastvoteId = GetKuaFu1V1VoteStateIdByNode(type,nodeIdx,pUser->GetRoleId(),votedata);
		if(lastvoteId == 0)	// 未投票
		{
			if(timeIdx+1 == 5)
			{
				if(G_1V1_PaiMing_1[0][0].data.role_id > 0 && G_1V1_PaiMing_1[0][1].data.role_id > 0)
				{
					if(G_1V1_PaiMing_1[0][0].data.role_id == (int)voteId || G_1V1_PaiMing_1[0][1].data.role_id == (int)voteId)
					{
						int state = pUser->GetKuaFu1V1VoteState(31);
						if(state == EKF_1V1_CanVote)
							canVote = 1;
					}
				}
			}
		}
		voteFlagIdx = 31;
	}

	if(canVote == 1)	// 可投票
	{
		pUser->SetKuaFu1V1VoteState(voteFlagIdx);
		pUser->AddMoney(-VOTE_NEED_MONEY);
		if(AddKuaFu1V1VoteDataByNode(pUser,type,nodeIdx,voteId,VOTE_NEED_MONEY))
		{
			KuaFu1V1VoteData role1,role2;
			GetKuaFu1V1TotolMoneyByNode(type,nodeIdx,role1,role2);
			msg<<PRO_SUCCESS<<role1.voteRoleId<<role1.money<<role2.voteRoleId<<role2.money;
		}
		else
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0063,TIPS_FAILURE_COLOR);
		}
	}
	else
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0063,TIPS_FAILURE_COLOR);
	}
}

void SendKuaFu1V1LeftTime(CUser *pUser)
{
	int timeIdx = GetKuaFu1V1FinalsTimeIndex();
	if(timeIdx < 1)
		return;

	int hour = GetHour();
	int minute = GetMinute();
	int second = GetSysTime()%60;
	int leftSecond = (15 - (hour*100+minute-KUA_FU_FINALS_START_TIME)%100%15)*60 - second;
	char buf[256];
	if(timeIdx == 1)
		snprintf(buf,sizeof(buf)-1,LANGUAGE_SSJ_0064,LANGUAGE_SSJ_0065);
	else if(timeIdx == 2)
		snprintf(buf,sizeof(buf)-1,LANGUAGE_SSJ_0064,LANGUAGE_SSJ_0066);
	else if(timeIdx == 3)
		snprintf(buf,sizeof(buf)-1,LANGUAGE_SSJ_0064,LANGUAGE_SSJ_0067);
	else if(timeIdx == 4)
		snprintf(buf,sizeof(buf)-1,LANGUAGE_SSJ_0064,LANGUAGE_SSJ_0068);
	else if(timeIdx == 5)
		snprintf(buf,sizeof(buf)-1,LANGUAGE_SSJ_0064,LANGUAGE_SSJ_0069);
	else
		return;
	CNetMessage msg;
	msg.SetType(MSG_KUA_FU_1V1);
	msg<<(uint8)25<<(uint8)1<<buf<<leftSecond;

	CSocketServer &sock = SingletonSocket::instance();
	if(pUser == NULL)
		SingletonOnlineUser::instance().ForEachUser(boost::bind(SendNianShouInfo,&sock,&msg,_1));
	else
		sock.SendMsg(pUser->GetSock(),msg);
}


void SendKuaFu1V1SceneLeftTime(CScene *pScene,CUser *pUser)
{
	if(pScene == NULL)
		return;
	if(pScene->GetSrcSceneId() != KUA_FU_1V1_SCENE_ID)
		return;
	int roomIdx = pScene->GetId() - KUA_FU_1V1_SCENE_FB_BEGIN + 1;
	if(roomIdx < 1 || roomIdx > KUA_FU_1V1_SCENE_NUM)
		return;
	int timeIdx = GetKuaFu1V1FinalsTimeIndex();
	if(timeIdx < 1)
		return;
	uint8 stepIdx = pScene->GetFBStep();
	int sceneTime = pScene->m_1V1SceneTime;
	int leftSecond = 0;
	int time = GetSysTime();
	if(stepIdx == 0)
		leftSecond = 2*60 - (time - sceneTime);
	else if(stepIdx == 2 || stepIdx == 4)
		leftSecond = 60 - (time - sceneTime);
	else
		return;
	
	CNetMessage msg;
	msg.SetType(MSG_KUA_FU_1V1);
	msg<<(uint8)25<<(uint8)2<<LANGUAGE_SSJ_0070<<leftSecond;
	if(pUser == NULL)
		pScene->BroadcastMsg(msg);
	else
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void SendKuaFu1V1SceneScore(CUser *pUser)
{
	if(pUser == NULL)
		return;
	if(pUser->GetSrcSceneId() != KUA_FU_1V1_SCENE_ID)
		return;
	int roomIdx = pUser->GetSceneId() - KUA_FU_1V1_SCENE_FB_BEGIN + 1;
	if(roomIdx < 1 || roomIdx > KUA_FU_1V1_SCENE_NUM)
		return;
	int timeIdx = GetKuaFu1V1FinalsTimeIndex();
	if(timeIdx < 1)
		return;

	int size = 0;
	int type = 0;
	SKuaFu1V1UserData (*pPaiMing)[MAX_PAIMING_NUM] = NULL;
	GetKuaFuPaiMingList(timeIdx,pPaiMing,size);
	if(pPaiMing == NULL || size == 0)
		return;
	
	CNetMessage msg;
	msg.SetType(MSG_KUA_FU_1V1);
	msg<<(uint8)26;
	if(timeIdx < 5)
	{
		if(roomIdx > size/2)
		{
			type = 1;
			roomIdx -= size/2;
		}
		int pos = (roomIdx-1)*2;
		if(pos+1 > size-1)
			return;
		
		msg<<pPaiMing[pos][type].data.role_id<<pPaiMing[pos][type].data.name<<pPaiMing[pos][type].data.winNum;
		msg<<pPaiMing[pos+1][type].data.role_id<<pPaiMing[pos+1][type].data.name<<pPaiMing[pos+1][type].data.winNum;
	}
	else
	{
		msg<<pPaiMing[0][0].data.role_id<<pPaiMing[0][0].data.name<<pPaiMing[0][0].data.winNum;
		msg<<pPaiMing[0][1].data.role_id<<pPaiMing[0][1].data.name<<pPaiMing[0][1].data.winNum;
	}
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void UpdateKuaFu1V1SceneScore(CScene *pScene)
{
	if(pScene == NULL)
		return;
	if(pScene->GetSrcSceneId() != KUA_FU_1V1_SCENE_ID)
		return;
	int roomIdx = pScene->GetId();
	if(roomIdx < 1 || roomIdx > KUA_FU_1V1_SCENE_NUM)
		return;
	int timeIdx = GetKuaFu1V1FinalsTimeIndex();
	if(timeIdx < 1)
		return;
	
	int size = 0;
	int type = 0;
	SKuaFu1V1UserData (*pPaiMing)[MAX_PAIMING_NUM] = NULL;
	GetKuaFuPaiMingList(timeIdx,pPaiMing,size);
	if(pPaiMing == NULL || size == 0)
		return;
	
	CNetMessage msg;
	msg.SetType(MSG_KUA_FU_1V1);
	msg<<(uint8)27;
	if(timeIdx < 5)
	{
		if(roomIdx > size/2)
		{
			type = 1;
			roomIdx -= size/2;
		}
		int pos = (roomIdx-1)*2;
		if(pos+1 > size-1)
			return;
	
		msg<<pPaiMing[pos][type].data.role_id<<pPaiMing[pos][type].data.name<<pPaiMing[pos][type].data.winNum;
		msg<<pPaiMing[pos+1][type].data.role_id<<pPaiMing[pos+1][type].data.name<<pPaiMing[pos+1][type].data.winNum;
	}
	else
	{
		msg<<pPaiMing[0][0].data.role_id<<pPaiMing[0][0].data.name<<pPaiMing[0][0].data.winNum;
		msg<<pPaiMing[0][1].data.role_id<<pPaiMing[0][1].data.name<<pPaiMing[0][1].data.winNum;
	}
	pScene->BroadcastMsg(msg);
}

void AddUserTitle(int roleId,int title)
{
	if(roleId <= 0 || title >= E2UT_NUM || title <= 0)
		return;
	ShareUserPtr p = SingletonOnlineUser::instance().GetUserByRoleId(roleId);
	CUser *pUser = p.get();
	if(pUser != NULL)
		pUser->AddTitle(title);
	/*else
	{
		char sql[2048];
		snprintf(sql,sizeof(sql),"select title from role_info where id=%d",roleId);
		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		if(pDb == NULL)
			return;
		if(pDb->Query(sql))
		{
			char **row = NULL;
			if((row = pDb->GetRow()) != NULL)
			{
				string titleStr;
				CUser *pU = new CUser;
				pU->SetRoleId(roleId);
				pU->ReadTitle(row[0]);
				pU->AddTitle(title);
				pU->GetTitleStr(titleStr);
				snprintf(sql,sizeof(sql),"update role_info set title='%s' where id=%d",titleStr.c_str(),roleId);
				pDb->Query(sql);
				delete pU;
			}
		}
	}*/
}

//static void UpdateKuaFu_OldData()
//{
//	for(uint8 i=0;i < sizeof(G_1V1_PaiMing_16[0])/sizeof(G_1V1_PaiMing_16[0][0]);i++)
//	{
//		for(uint8 j=0;j < sizeof(G_1V1_PaiMing_16)/sizeof(G_1V1_PaiMing_16[0]);j++)
//			G_1V1_PaiMing_Old_16[j][i] = G_1V1_PaiMing_16[j][i];
//	}
//	for(uint8 i=0;i < sizeof(G_1V1_PaiMing_8[0])/sizeof(G_1V1_PaiMing_8[0][0]);i++)
//	{
//		for(uint8 j=0;j < sizeof(G_1V1_PaiMing_8)/sizeof(G_1V1_PaiMing_8[0]);j++)
//			G_1V1_PaiMing_Old_8[j][i] = G_1V1_PaiMing_8[j][i];
//	}
//	for(uint8 i=0;i < sizeof(G_1V1_PaiMing_4[0])/sizeof(G_1V1_PaiMing_4[0][0]);i++)
//	{
//		for(uint8 j=0;j < sizeof(G_1V1_PaiMing_4)/sizeof(G_1V1_PaiMing_4[0]);j++)
//			G_1V1_PaiMing_Old_4[j][i] = G_1V1_PaiMing_4[j][i];
//	}
//	for(uint8 i=0;i < sizeof(G_1V1_PaiMing_2[0])/sizeof(G_1V1_PaiMing_2[0][0]);i++)
//	{
//		for(uint8 j=0;j < sizeof(G_1V1_PaiMing_2)/sizeof(G_1V1_PaiMing_2[0]);j++)
//			G_1V1_PaiMing_Old_2[j][i] = G_1V1_PaiMing_2[j][i];
//	}
//	for(uint8 i=0;i < sizeof(G_1V1_PaiMing_1[0])/sizeof(G_1V1_PaiMing_1[0][0]);i++)
//	{
//		for(uint8 j=0;j < sizeof(G_1V1_PaiMing_1)/sizeof(G_1V1_PaiMing_1[0]);j++)
//			G_1V1_PaiMing_Old_1[j][i] = G_1V1_PaiMing_1[j][i];
//	}
//	for(uint8 i=0;i < sizeof(G_1V1_VoteTotolMoney[0])/sizeof(G_1V1_VoteTotolMoney[0][0]);i++)
//	{
//		for(uint8 j=0;j < sizeof(G_1V1_VoteTotolMoney)/sizeof(G_1V1_VoteTotolMoney[0]);j++)
//			G_1V1_VoteTotolMoney_Old[j][i] = G_1V1_VoteTotolMoney[j][i];
//	}
//	G_1V1_PaiMing_First_Old = G_1V1_PaiMing_First;
//	for(uint8 i=0;i < sizeof(G_1V1_VoteList)/sizeof(G_1V1_VoteList[0]);i++)
//	{
//		G_1V1_VoteList_Old[i].clear();
//		G_1V1_VoteList_Old[i] = G_1V1_VoteList[i];
//	}
//}

void SendKuaFu1V1Award()
{
//	if(G_1V1_RankList.empty())
//		return;
//	int size = G_1V1_RankList.size();
//	int rank = 0;
//	char buf[512];
//
//#ifdef KUA_FU
//	SendLongQuerySqlToAllDB("delete from level_rank where id>30050 and id<=30100");
//#endif
//
//	AwardManager &awardMgr = SingletonAwardManager::instance();
//	for(int i=size-1;i >= 0;i--)
//	{
//		if(G_1V1_RankList[i].role_id > 0)
//		{
//			rank++;
//			if(rank == 1)
//			{
//				snprintf(buf,sizeof(buf)-1,LANGUAGE_SSJ_0074,ROLE_NAME_COLOR,G_1V1_RankList[i].name.c_str());
//				SysInfoToAllUser(buf);
//				
//				snprintf(buf,sizeof(buf)-1,LANGUAGE_SSJ_0072);
////				AddUserTitle(G_1V1_RankList[i].role_id,E2UT_LJDYR);
//			}
//			else
//			{
//				snprintf(buf,sizeof(buf)-1,LANGUAGE_SSJ_0073,rank);
//			}
//			awardMgr.SendRankAwardMail(EMRA_KF_1V1_Final, G_1V1_RankList[i].role_id, rank, buf);
//
//#ifdef KUA_FU
//			int shenjia = GetKuaFu1V1TotolMoneyByRoleId(G_1V1_RankList[i].role_id);
//			string roleName = G_1V1_RankList[i].name;
//			snprintf(buf,sizeof(buf)-1,"insert into level_rank(id,role_id,role_name,rank,type,data,xiang) values(%d,%u,'%s',%u,602,%d,%d)",
//				30050+rank,G_1V1_RankList[i].role_id,roleName.c_str(),rank,shenjia,G_1V1_RankList[i].xiang);
//			SendLongQuerySqlToAllDB(buf);
//#endif
//		}
//	}
//
//	UpdateKuaFu_OldData();
//
//#ifdef KUA_FU
//	SaveKuaFu1V1FinalData();
//#endif
}

void ReSetKuaFu1V1Data()
{
	boost::recursive_mutex::scoped_lock lk(G_1V1_Mutex);
	for(uint8 i=0;i < MAX_PAIMING_NUM;i++)
	{
//		for(uint8 j=0;j < sizeof(G_1V1_PaiMing_16)/sizeof(G_1V1_PaiMing_16[0]);j++)
//			G_1V1_PaiMing_16[j][i].data.role_id = -1;
		for(uint8 j=0;j < sizeof(G_1V1_PaiMing_8)/sizeof(G_1V1_PaiMing_8[0]);j++)
			G_1V1_PaiMing_8[j][i].data.role_id = -1;
		for(uint8 j=0;j < sizeof(G_1V1_PaiMing_4)/sizeof(G_1V1_PaiMing_4[0]);j++)
			G_1V1_PaiMing_4[j][i].data.role_id = -1;
		for(uint8 j=0;j < sizeof(G_1V1_PaiMing_2)/sizeof(G_1V1_PaiMing_2[0]);j++)
			G_1V1_PaiMing_2[j][i].data.role_id = -1;
		for(uint8 j=0;j < sizeof(G_1V1_PaiMing_1)/sizeof(G_1V1_PaiMing_1[0]);j++)
			G_1V1_PaiMing_1[j][i].data.role_id = -1;
		G_1V1_PaiMing_First.data.role_id = -1;
	}
}

#ifdef KUA_FU

static void ClearKuaFu1V1UserData()
{
	for(uint8 i=0;i < MAX_PAIMING_NUM;i++)
	{
		for(uint8 j=0;j < sizeof(G_1V1_PaiMing_16)/sizeof(G_1V1_PaiMing_16[0]);j++)
			G_1V1_PaiMing_16[j][i].Clear();
		for(uint8 j=0;j < sizeof(G_1V1_PaiMing_8)/sizeof(G_1V1_PaiMing_8[0]);j++)
		{
			G_1V1_PaiMing_8[j][i].Clear();
			G_1V1_PaiMing_8[j][i].data.role_id = -1;
		}
		for(uint8 j=0;j < sizeof(G_1V1_PaiMing_4)/sizeof(G_1V1_PaiMing_4[0]);j++)
		{
			G_1V1_PaiMing_4[j][i].Clear();
			G_1V1_PaiMing_4[j][i].data.role_id = -1;
		}
		for(uint8 j=0;j < sizeof(G_1V1_PaiMing_2)/sizeof(G_1V1_PaiMing_2[0]);j++)
		{
			G_1V1_PaiMing_2[j][i].Clear();
			G_1V1_PaiMing_2[j][i].data.role_id = -1;
		}
		for(uint8 j=0;j < sizeof(G_1V1_PaiMing_1)/sizeof(G_1V1_PaiMing_1[0]);j++)
		{
			G_1V1_PaiMing_1[j][i].Clear();
			G_1V1_PaiMing_1[j][i].data.role_id = -1;
		}
	}
	G_1V1_PaiMing_First.Clear();
	G_1V1_PaiMing_First.data.role_id = -1;
	
	for(uint8 i=0;i < sizeof(G_1V1_VoteList)/sizeof(G_1V1_VoteList[0]);i++)
		G_1V1_VoteList[i].clear();
	for(uint8 i=0;i < sizeof(G_1V1_VoteTotolMoney)/sizeof(G_1V1_VoteTotolMoney[0]);i++)
	{
		for(uint8 j=0;j < sizeof(G_1V1_VoteTotolMoney[0])/sizeof(G_1V1_VoteTotolMoney[0][0]);j++)
			G_1V1_VoteTotolMoney[i][j].Clear();
	}
	G_1V1_RankList.clear();
	G_1V1_TurnRank.clear();
}

void LoadKuaFu1V1FinalUserData()
{
	boost::recursive_mutex::scoped_lock lk(G_1V1_Mutex);
	ClearKuaFu1V1UserData();
	SingletonCKuaFu1vs1PreliminaryManager::instance().FillFinalUserInfo(G_1V1_PaiMing_16);
}

bool ReadKuaFu1V1FinalDataFromDB()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return false;
	ClearKuaFu1V1UserData();

	char sql[512];
	char **row = NULL;
	// userData
	//                                    0     1     2    3     4       5        6        7           8           9        10       11   12      13     14     15    16
	snprintf(sql,sizeof(sql)-1,"select role_id,name,level,xiang,sex,super_level,wing_id,weapon_id,weapon_level,zhandouli,server_id,winNum,rank,group_id,type,oldflag,pos from kuafu_1vs1_final_data order by oldflag desc,type asc,group_id asc");
	if(!pDb->Query(sql))
		return false;
	int oldFlag = 0;	// 1 old,0 new
	int group = 0;		// 0 上半场 1 下半场 ,决赛0
	int type = 1;		// 1-16,2-8,3-4,4-2,5-1,6-0
	int pos = 0;
	while((row = pDb->GetRow()) != NULL)
	{
		group = atoi(row[13]);
		type = atoi(row[14]);
		oldFlag = atoi(row[15]);
		pos = atoi(row[16]);
		if(group < 0 || group > 1 || pos < 0)
			continue;
		if(type < 1 || type > 6)
			continue;

		SKuaFu1V1UserData temp;
		temp.data.role_id = atoi(row[0]);
		temp.data.name = row[1];
		temp.data.level = atoi(row[2]);
		temp.data.xiang = atoi(row[3]);
		temp.data.sex = atoi(row[4]);
		temp.data.super_level = atoi(row[5]);
		temp.data.wing_id = atoi(row[6]);
		temp.data.weapon_id = atoi(row[7]);
		temp.data.weapon_level = atoi(row[8]);
		temp.data.zhandouli = atoi(row[9]);
		temp.data.server_id = atoi(row[10]);
		temp.data.winNum = atoi(row[11]);
		temp.rank = atoi(row[12]);
		if(oldFlag == 0)	// current
		{
			if(type == 1)	// 16
			{
				if((uint32)pos >= sizeof(G_1V1_PaiMing_16)/sizeof(G_1V1_PaiMing_16[0]))
					continue;
				G_1V1_PaiMing_16[pos][group] = temp;
			}
			else if(type == 2)	// 8
			{
				if((uint32)pos >= sizeof(G_1V1_PaiMing_8)/sizeof(G_1V1_PaiMing_8[0]))
					continue;
				G_1V1_PaiMing_8[pos][group] = temp;
			}
			else if(type == 3)	// 4
			{
				if((uint32)pos >= sizeof(G_1V1_PaiMing_4)/sizeof(G_1V1_PaiMing_4[0]))
					continue;
				G_1V1_PaiMing_4[pos][group] = temp;
			}
			else if(type == 4)	// 2
			{
				if((uint32)pos >= sizeof(G_1V1_PaiMing_2)/sizeof(G_1V1_PaiMing_2[0]))
					continue;
				G_1V1_PaiMing_2[pos][group] = temp;
			}
			else if(type == 5)	// 1
			{
				if((uint32)pos >= sizeof(G_1V1_PaiMing_1)/sizeof(G_1V1_PaiMing_1[0]))
					continue;
				G_1V1_PaiMing_1[pos][group] = temp;
			}
			else if(type == 6)	// 第一名
			{
				G_1V1_PaiMing_First = temp;
			}
		}
		else	// old
		{
			if(type == 1)	// 16
			{
				if((uint32)pos >= sizeof(G_1V1_PaiMing_Old_16)/sizeof(G_1V1_PaiMing_Old_16[0]))
					continue;
				G_1V1_PaiMing_Old_16[pos][group] = temp;
			}
			else if(type == 2)	// 8
			{
				if((uint32)pos >= sizeof(G_1V1_PaiMing_Old_8)/sizeof(G_1V1_PaiMing_Old_8[0]))
					continue;
				G_1V1_PaiMing_Old_8[pos][group] = temp;
			}
			else if(type == 3)	// 4
			{
				if((uint32)pos >= sizeof(G_1V1_PaiMing_Old_4)/sizeof(G_1V1_PaiMing_Old_4[0]))
					continue;
				G_1V1_PaiMing_Old_4[pos][group] = temp;
			}
			else if(type == 4)	// 2
			{
				if((uint32)pos >= sizeof(G_1V1_PaiMing_Old_2)/sizeof(G_1V1_PaiMing_Old_2[0]))
					continue;
				G_1V1_PaiMing_Old_2[pos][group] = temp;
			}
			else if(type == 5)	// 1
			{
				if((uint32)pos >= sizeof(G_1V1_PaiMing_Old_1)/sizeof(G_1V1_PaiMing_Old_1[0]))
					continue;
				G_1V1_PaiMing_Old_1[pos][group] = temp;
			}
			else if(type == 6)	// 第一名
			{
				G_1V1_PaiMing_First_Old = temp;
			}
		}
	}

	// voteData
	//                                     0       1      2    3      4     5       6
	snprintf(sql,sizeof(sql)-1,"select node_idx,role_id,money,type,oldflag,idx,vote_roleId from kuafu_1vs1_final_vote order by oldflag desc,type asc,node_idx asc");
	if(!pDb->Query(sql))
		return false;
	while((row = pDb->GetRow()) != NULL)
	{
		type = atoi(row[3]);
		oldFlag = atoi(row[4]);

		int nodeIdx = atoi(row[0]);
		int pos = atoi(row[5]);
		if(nodeIdx < 1 || pos > 1)
			continue;
		
		KuaFu1V1VoteData voteTemp;
		voteTemp.voteRoleId = atoi(row[6]);
		voteTemp.money = atoi(row[2]);
		if(oldFlag == 0)	// current
		{
			if(type == 1)	// totolMoney
			{
				if((uint32)nodeIdx > sizeof(G_1V1_VoteTotolMoney)/sizeof(G_1V1_VoteTotolMoney[0]))
					continue;
				G_1V1_VoteTotolMoney[nodeIdx-1][pos] = voteTemp;
			}
			else	// voteList
			{
				int roleId = atoi(row[1]);
				if((uint32)nodeIdx > sizeof(G_1V1_VoteList)/sizeof(G_1V1_VoteList[0]))
					continue;
				G_1V1_VoteList[nodeIdx-1].insert(make_pair(roleId,voteTemp));
			}
		}
		else	// old
		{
			if(type == 1)	// totolMoney
			{
				if((uint32)nodeIdx > sizeof(G_1V1_VoteTotolMoney_Old)/sizeof(G_1V1_VoteTotolMoney_Old[0]))
					continue;
				G_1V1_VoteTotolMoney_Old[nodeIdx-1][pos] = voteTemp;
			}
			else	// voteList
			{
				int roleId = atoi(row[1]);
				if((uint32)nodeIdx > sizeof(G_1V1_VoteList_Old)/sizeof(G_1V1_VoteList_Old[0]))
					continue;
				G_1V1_VoteList_Old[nodeIdx-1].insert(make_pair(roleId,voteTemp));
			}
		}
	}
	return true;
}

void SaveKuaFu1V1FinalData()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
	if(!pDb->Query("truncate kuafu_1vs1_final_data"))
		return;
	if(!pDb->Query("truncate kuafu_1vs1_final_vote"))
		return;

	char sql[1024];
	boost::recursive_mutex::scoped_lock lk(G_1V1_Mutex);

	int oldflag = 0;	// 0 current 1 old
	int type = 1;
	// current
	for(uint8 i=0;i < MAX_PAIMING_NUM;i++)
	{
		type = 1;	// 16
		for(uint8 j=0;j < sizeof(G_1V1_PaiMing_16)/sizeof(G_1V1_PaiMing_16[0]);j++)
		{
			SKuaFu1V1UserData &value = G_1V1_PaiMing_16[j][i];
			snprintf(sql,sizeof(sql)-1,"insert into kuafu_1vs1_final_data(role_id,name,level,xiang,sex,super_level,wing_id,weapon_id,weapon_level,zhandouli,server_id,winNum,rank,group_id,type,pos,oldflag) values(%d,\"%s\",%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d)",
				value.data.role_id,value.data.name.c_str(),value.data.level,value.data.xiang,value.data.sex,value.data.super_level,value.data.wing_id,value.data.weapon_id,value.data.weapon_level,value.data.zhandouli,value.data.server_id,value.data.winNum,(int)value.rank,
				(int)i,type,(int)j,oldflag);
			pDb->Query(sql);
		}
		type = 2;	// 8
		for(uint8 j=0;j < sizeof(G_1V1_PaiMing_8)/sizeof(G_1V1_PaiMing_8[0]);j++)
		{
			SKuaFu1V1UserData &value = G_1V1_PaiMing_8[j][i];
			snprintf(sql,sizeof(sql)-1,"insert into kuafu_1vs1_final_data(role_id,name,level,xiang,sex,super_level,wing_id,weapon_id,weapon_level,zhandouli,server_id,winNum,rank,group_id,type,pos,oldflag) values(%d,\"%s\",%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d)",
				value.data.role_id,value.data.name.c_str(),value.data.level,value.data.xiang,value.data.sex,value.data.super_level,value.data.wing_id,value.data.weapon_id,value.data.weapon_level,value.data.zhandouli,value.data.server_id,value.data.winNum,(int)value.rank,
				(int)i,type,(int)j,oldflag);
			pDb->Query(sql);
		}
		type = 3;	// 4
		for(uint8 j=0;j < sizeof(G_1V1_PaiMing_4)/sizeof(G_1V1_PaiMing_4[0]);j++)
		{
			SKuaFu1V1UserData &value = G_1V1_PaiMing_4[j][i];
			snprintf(sql,sizeof(sql)-1,"insert into kuafu_1vs1_final_data(role_id,name,level,xiang,sex,super_level,wing_id,weapon_id,weapon_level,zhandouli,server_id,winNum,rank,group_id,type,pos,oldflag) values(%d,\"%s\",%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d)",
				value.data.role_id,value.data.name.c_str(),value.data.level,value.data.xiang,value.data.sex,value.data.super_level,value.data.wing_id,value.data.weapon_id,value.data.weapon_level,value.data.zhandouli,value.data.server_id,value.data.winNum,(int)value.rank,
				(int)i,type,(int)j,oldflag);
			pDb->Query(sql);
		}
		type = 4;	// 2
		for(uint8 j=0;j < sizeof(G_1V1_PaiMing_2)/sizeof(G_1V1_PaiMing_2[0]);j++)
		{
			SKuaFu1V1UserData &value = G_1V1_PaiMing_2[j][i];
			snprintf(sql,sizeof(sql)-1,"insert into kuafu_1vs1_final_data(role_id,name,level,xiang,sex,super_level,wing_id,weapon_id,weapon_level,zhandouli,server_id,winNum,rank,group_id,type,pos,oldflag) values(%d,\"%s\",%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d)",
				value.data.role_id,value.data.name.c_str(),value.data.level,value.data.xiang,value.data.sex,value.data.super_level,value.data.wing_id,value.data.weapon_id,value.data.weapon_level,value.data.zhandouli,value.data.server_id,value.data.winNum,(int)value.rank,
				(int)i,type,(int)j,oldflag);
			pDb->Query(sql);
		}
		type = 5;	// 1
		for(uint8 j=0;j < sizeof(G_1V1_PaiMing_1)/sizeof(G_1V1_PaiMing_1[0]);j++)
		{
			SKuaFu1V1UserData &value = G_1V1_PaiMing_1[j][i];
			snprintf(sql,sizeof(sql)-1,"insert into kuafu_1vs1_final_data(role_id,name,level,xiang,sex,super_level,wing_id,weapon_id,weapon_level,zhandouli,server_id,winNum,rank,group_id,type,pos,oldflag) values(%d,\"%s\",%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d)",
				value.data.role_id,value.data.name.c_str(),value.data.level,value.data.xiang,value.data.sex,value.data.super_level,value.data.wing_id,value.data.weapon_id,value.data.weapon_level,value.data.zhandouli,value.data.server_id,value.data.winNum,(int)value.rank,
				(int)i,type,(int)j,oldflag);
			pDb->Query(sql);
		}
	}

	{
		type = 6;
		SKuaFu1V1UserData &value = G_1V1_PaiMing_First;
		snprintf(sql,sizeof(sql)-1,"insert into kuafu_1vs1_final_data(role_id,name,level,xiang,sex,super_level,wing_id,weapon_id,weapon_level,zhandouli,server_id,winNum,rank,group_id,type,pos,oldflag) values(%d,\"%s\",%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d)",
			value.data.role_id,value.data.name.c_str(),value.data.level,value.data.xiang,value.data.sex,value.data.super_level,value.data.wing_id,value.data.weapon_id,value.data.weapon_level,value.data.zhandouli,value.data.server_id,value.data.winNum,(int)value.rank,
			(int)0,type,(int)0,oldflag);
		pDb->Query(sql);
	}

	for(uint8 i=0;i < sizeof(G_1V1_VoteTotolMoney)/sizeof(G_1V1_VoteTotolMoney[0]);i++)
	{
		for(uint8 j=0;j < sizeof(G_1V1_VoteTotolMoney[0])/sizeof(G_1V1_VoteTotolMoney[0][0]);j++)
		{
			KuaFu1V1VoteData &value = G_1V1_VoteTotolMoney[i][j];
			snprintf(sql,sizeof(sql)-1,"insert into kuafu_1vs1_final_vote(node_idx,role_id,vote_roleId,money,idx,type,oldflag) values(%d,%d,%d,%d,%d,%d,%d)",
				(int)(j+1),0,value.voteRoleId,value.money,(int)i,1,oldflag);
			pDb->Query(sql);
		}
	}
	for(uint8 i=0;i < sizeof(G_1V1_VoteList)/sizeof(G_1V1_VoteList[0]);i++)
	{
		for(map<uint32,KuaFu1V1VoteData>::iterator it=G_1V1_VoteList[i].begin(); it != G_1V1_VoteList[i].end(); it++)
		{
			KuaFu1V1VoteData &value = it->second;
			snprintf(sql,sizeof(sql)-1,"insert into kuafu_1vs1_final_vote(node_idx,role_id,vote_roleId,money,idx,type,oldflag) values(%d,%d,%d,%d,%d,%d,%d)",
				(int)(i+1),(int)it->first,value.voteRoleId,value.money,0,2,oldflag);
			pDb->Query(sql);
		}
	}

	// oldData
	oldflag = 1;	// 0 current 1 old
	for(uint8 i=0;i < MAX_PAIMING_NUM;i++)
	{
		type = 1;	// 16
		for(uint8 j=0;j < sizeof(G_1V1_PaiMing_Old_16)/sizeof(G_1V1_PaiMing_Old_16[0]);j++)
		{
			SKuaFu1V1UserData &value = G_1V1_PaiMing_Old_16[j][i];
			snprintf(sql,sizeof(sql)-1,"insert into kuafu_1vs1_final_data(role_id,name,level,xiang,sex,super_level,wing_id,weapon_id,weapon_level,zhandouli,server_id,winNum,rank,group_id,type,pos,oldflag) values(%d,\"%s\",%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d)",
				value.data.role_id,value.data.name.c_str(),value.data.level,value.data.xiang,value.data.sex,value.data.super_level,value.data.wing_id,value.data.weapon_id,value.data.weapon_level,value.data.zhandouli,value.data.server_id,value.data.winNum,(int)value.rank,
				(int)i,type,(int)j,oldflag);
			pDb->Query(sql);
		}
		type = 2;	// 8
		for(uint8 j=0;j < sizeof(G_1V1_PaiMing_Old_8)/sizeof(G_1V1_PaiMing_Old_8[0]);j++)
		{
			SKuaFu1V1UserData &value = G_1V1_PaiMing_Old_8[j][i];
			snprintf(sql,sizeof(sql)-1,"insert into kuafu_1vs1_final_data(role_id,name,level,xiang,sex,super_level,wing_id,weapon_id,weapon_level,zhandouli,server_id,winNum,rank,group_id,type,pos,oldflag) values(%d,\"%s\",%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d)",
				value.data.role_id,value.data.name.c_str(),value.data.level,value.data.xiang,value.data.sex,value.data.super_level,value.data.wing_id,value.data.weapon_id,value.data.weapon_level,value.data.zhandouli,value.data.server_id,value.data.winNum,(int)value.rank,
				(int)i,type,(int)j,oldflag);
			pDb->Query(sql);
		}
		type = 3;	// 4
		for(uint8 j=0;j < sizeof(G_1V1_PaiMing_Old_4)/sizeof(G_1V1_PaiMing_Old_4[0]);j++)
		{
			SKuaFu1V1UserData &value = G_1V1_PaiMing_Old_4[j][i];
			snprintf(sql,sizeof(sql)-1,"insert into kuafu_1vs1_final_data(role_id,name,level,xiang,sex,super_level,wing_id,weapon_id,weapon_level,zhandouli,server_id,winNum,rank,group_id,type,pos,oldflag) values(%d,\"%s\",%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d)",
				value.data.role_id,value.data.name.c_str(),value.data.level,value.data.xiang,value.data.sex,value.data.super_level,value.data.wing_id,value.data.weapon_id,value.data.weapon_level,value.data.zhandouli,value.data.server_id,value.data.winNum,(int)value.rank,
				(int)i,type,(int)j,oldflag);
			pDb->Query(sql);
		}
		type = 4;	// 2
		for(uint8 j=0;j < sizeof(G_1V1_PaiMing_Old_2)/sizeof(G_1V1_PaiMing_Old_2[0]);j++)
		{
			SKuaFu1V1UserData &value = G_1V1_PaiMing_Old_2[j][i];
			snprintf(sql,sizeof(sql)-1,"insert into kuafu_1vs1_final_data(role_id,name,level,xiang,sex,super_level,wing_id,weapon_id,weapon_level,zhandouli,server_id,winNum,rank,group_id,type,pos,oldflag) values(%d,\"%s\",%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d)",
				value.data.role_id,value.data.name.c_str(),value.data.level,value.data.xiang,value.data.sex,value.data.super_level,value.data.wing_id,value.data.weapon_id,value.data.weapon_level,value.data.zhandouli,value.data.server_id,value.data.winNum,(int)value.rank,
				(int)i,type,(int)j,oldflag);
			pDb->Query(sql);
		}
		type = 5;	// 1
		for(uint8 j=0;j < sizeof(G_1V1_PaiMing_Old_1)/sizeof(G_1V1_PaiMing_Old_1[0]);j++)
		{
			SKuaFu1V1UserData &value = G_1V1_PaiMing_Old_1[j][i];
			snprintf(sql,sizeof(sql)-1,"insert into kuafu_1vs1_final_data(role_id,name,level,xiang,sex,super_level,wing_id,weapon_id,weapon_level,zhandouli,server_id,winNum,rank,group_id,type,pos,oldflag) values(%d,\"%s\",%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d)",
				value.data.role_id,value.data.name.c_str(),value.data.level,value.data.xiang,value.data.sex,value.data.super_level,value.data.wing_id,value.data.weapon_id,value.data.weapon_level,value.data.zhandouli,value.data.server_id,value.data.winNum,(int)value.rank,
				(int)i,type,(int)j,oldflag);
			pDb->Query(sql);
		}
	}

	{
		type = 6;
		SKuaFu1V1UserData &value = G_1V1_PaiMing_First_Old;
		snprintf(sql,sizeof(sql)-1,"insert into kuafu_1vs1_final_data(role_id,name,level,xiang,sex,super_level,wing_id,weapon_id,weapon_level,zhandouli,server_id,winNum,rank,group_id,type,pos,oldflag) values(%d,\"%s\",%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d)",
			value.data.role_id,value.data.name.c_str(),value.data.level,value.data.xiang,value.data.sex,value.data.super_level,value.data.wing_id,value.data.weapon_id,value.data.weapon_level,value.data.zhandouli,value.data.server_id,value.data.winNum,(int)value.rank,
			(int)0,type,(int)0,oldflag);
		pDb->Query(sql);
	}

	for(uint8 i=0;i < sizeof(G_1V1_VoteTotolMoney_Old)/sizeof(G_1V1_VoteTotolMoney_Old[0]);i++)
	{
		for(uint8 j=0;j < sizeof(G_1V1_VoteTotolMoney_Old[0])/sizeof(G_1V1_VoteTotolMoney_Old[0][0]);j++)
		{
			KuaFu1V1VoteData &value = G_1V1_VoteTotolMoney_Old[i][j];
			snprintf(sql,sizeof(sql)-1,"insert into kuafu_1vs1_final_vote(node_idx,role_id,vote_roleId,money,idx,type,oldflag) values(%d,%d,%d,%d,%d,%d,%d)",
				(int)(j+1),0,value.voteRoleId,value.money,(int)i,1,oldflag);
			pDb->Query(sql);
		}
	}
	for(uint8 i=0;i < sizeof(G_1V1_VoteList_Old)/sizeof(G_1V1_VoteList_Old[0]);i++)
	{
		for(map<uint32,KuaFu1V1VoteData>::iterator it=G_1V1_VoteList_Old[i].begin(); it != G_1V1_VoteList_Old[i].end(); it++)
		{
			KuaFu1V1VoteData &value = it->second;
			snprintf(sql,sizeof(sql)-1,"insert into kuafu_1vs1_final_vote(node_idx,role_id,vote_roleId,money,idx,type,oldflag) values(%d,%d,%d,%d,%d,%d,%d)",
				(int)(i+1),(int)it->first,value.voteRoleId,value.money,0,2,oldflag);
			pDb->Query(sql);
		}
	}
}
#endif

string GetKuaFu1V1MailString(bool win)
{
	int timeIdx = GetKuaFu1V1FinalsTimeIndex();
	if (timeIdx < 1)
		return "";
	char mailStr[128];
	int roleNum = 0;
	switch (timeIdx)
	{
	case 1:
		roleNum = 16;
		if (win)
			snprintf(mailStr, sizeof(mailStr), LANGUAGE_ZQX_0082, roleNum);
		else
			snprintf(mailStr, sizeof(mailStr), LANGUAGE_ZQX_0083, roleNum * 2);
		break;

	case 2:
		roleNum = 8;
		if (win)
			snprintf(mailStr, sizeof(mailStr), LANGUAGE_ZQX_0082, roleNum);
		else
			snprintf(mailStr, sizeof(mailStr), LANGUAGE_ZQX_0083, roleNum * 2);
		break;
	case 3:
		roleNum = 4;
		if (win)
			snprintf(mailStr, sizeof(mailStr), LANGUAGE_ZQX_0082, roleNum);
		else
			snprintf(mailStr, sizeof(mailStr), LANGUAGE_ZQX_0083, roleNum * 2);
		break;

	case 4:
		if (win)
			sprintf(mailStr, LANGUAGE_ZQX_0084);
		else
			sprintf(mailStr, LANGUAGE_ZQX_0085);
		break;
	}
	return mailStr;
}

void CheckKuaFu1V1Players()
{
	int timeIdx = GetKuaFu1V1FinalsTimeIndex();
	if(timeIdx < 1)
		return;

	boost::recursive_mutex::scoped_lock lk(G_1V1_Mutex);
	if(timeIdx < 5)
	{
		int size = 0;
		int sizeNext = 0;

		SKuaFu1V1UserData (*pPaiMing)[MAX_PAIMING_NUM] = NULL;
		SKuaFu1V1UserData (*pPaiMingNext)[MAX_PAIMING_NUM] = NULL;
		GetKuaFuPaiMingList(timeIdx,pPaiMing,size);
		GetKuaFuPaiMingList(timeIdx+1,pPaiMingNext,sizeNext);
		if(pPaiMing == NULL || size == 0 || pPaiMingNext == NULL || sizeNext == 0)
			return;
		for(uint8 i=0;i < MAX_PAIMING_NUM;i++)
		{
			for(int j=0;j < size/2;j++)
			{
				if(pPaiMing[j*2][i].data.role_id == 0 || pPaiMing[j*2+1][i].data.role_id == 0)
				{
					pPaiMingNext[j][i] = (pPaiMing[j*2][i].data.role_id > pPaiMing[j*2+1][i].data.role_id) ? pPaiMing[j*2][i] : pPaiMing[j*2+1][i];
					pPaiMingNext[j][i].data.winNum = 0;
					uint32 mailRoleId = pPaiMing[j * 2][i].data.role_id == 0 ? pPaiMing[j * 2 + 1][i].data.role_id : pPaiMing[j * 2][i].data.role_id;
					if (mailRoleId != 0)
						SendSystemMail(mailRoleId, GetKuaFu1V1MailString(true).c_str());
				}
			}
		}
	}
	else if(timeIdx == 5)
	{
		if(G_1V1_PaiMing_1[0][0].data.role_id == 0 || G_1V1_PaiMing_1[0][1].data.role_id == 0)
		{
			G_1V1_PaiMing_First = (G_1V1_PaiMing_1[0][0].data.role_id > G_1V1_PaiMing_1[0][1].data.role_id) ? G_1V1_PaiMing_1[0][0] : G_1V1_PaiMing_1[0][1];
			G_1V1_PaiMing_First.data.winNum = 0;
			if(G_1V1_PaiMing_First.data.role_id > 0)
				G_1V1_RankList.push_back(G_1V1_PaiMing_First.data);
		}
	}
}

bool CheckKuaFu1V1_FirstResult()
{
	boost::recursive_mutex::scoped_lock lk(G_1V1_Mutex);
	if(G_1V1_PaiMing_First.data.role_id > 0)
		return true;
	else
		return false;
}

void AddKuaFu1V1RoleData_TEST(CUser *pUser)
{
	if(pUser == NULL)
		return;
	
	boost::recursive_mutex::scoped_lock lk(G_1V1_Mutex);
	for(uint8 i=0;i < MAX_PAIMING_NUM;i++)
	{
		for(uint8 j=0;j < sizeof(G_1V1_PaiMing_16)/sizeof(G_1V1_PaiMing_16[0]);j++)
		{
			if(G_1V1_PaiMing_16[j][i].data.role_id == (int)pUser->GetRoleId())
				return;
		}
	}
	
	for(uint8 i=0;i < MAX_PAIMING_NUM;i++)
	{
		for(uint8 j=0;j < sizeof(G_1V1_PaiMing_16)/sizeof(G_1V1_PaiMing_16[0]);j++)
		{
			if(G_1V1_PaiMing_16[j][i].data.role_id <= 0)
			{
				G_1V1_PaiMing_16[j][i].data.role_id = pUser->GetRoleId();
				G_1V1_PaiMing_16[j][i].data.name = pUser->GetName();
				G_1V1_PaiMing_16[j][i].data.level = pUser->GetLevel();
				G_1V1_PaiMing_16[j][i].data.sex = pUser->GetSex();
				G_1V1_PaiMing_16[j][i].data.super_level = pUser->GetVipLevel();
//				G_1V1_PaiMing_16[j][i].data.xiang = pUser->GetXiang();
				G_1V1_PaiMing_16[j][i].data.wing_id = pUser->GetWingId();
				G_1V1_PaiMing_16[j][i].data.zhandouli = pUser->GetZhanDouLi();
				G_1V1_PaiMing_16[j][i].rank = Random(1,4);
				return;
			}
		}
	}
}

void CheckBangPaiId()
{
	if(InKuaFu())
		return;
	vector<int> idList;
	GetServerIdList(idList);
	if(idList.empty())
		return;
	
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
	int id = idList[0];
	char buf[256];
	snprintf(buf,sizeof(buf)-1,"select id from bang_pai order by id asc limit 1");
	if(!pDb->Query(buf))
		return;
	char **row = NULL;
	if((row = pDb->GetRow()) == NULL)
	{
		snprintf(buf,sizeof(buf)-1,"insert into bang_pai (id) values(%d)",id*1000);
		pDb->Query(buf);
	}
	else
	{
		int bangId = atoi(row[0]);
		if(bangId < 1000)
		{
			snprintf(buf,sizeof(buf)-1,"update bang_pai set id=%d+id",id*1000);
			pDb->Query(buf);
			snprintf(buf,sizeof(buf)-1,"update bang_pai_plant set bang_id=%d+bang_id",id*1000);
			pDb->Query(buf);
			snprintf(buf,sizeof(buf)-1,"update bang_pai_role set bangpai_id=%d+bangpai_id",id*1000);
			pDb->Query(buf);
			snprintf(buf,sizeof(buf)-1,"update bang_pai_guard set bang_id=%d+bang_id",id*1000);
			pDb->Query(buf);
			snprintf(buf,sizeof(buf)-1,"update bang_tiaozhan set bang=%d+bang",id*1000);
			pDb->Query(buf);
			snprintf(buf,sizeof(buf)-1,"update bangzhan set bangpai_id=%d+bangpai_id",id*1000);
			pDb->Query(buf);
			snprintf(buf,sizeof(buf)-1,"update bangzhan_role set bang_id=%d+bang_id",id*1000);
			pDb->Query(buf);
		}
	}
}


static string KUA_FU_IP;
static int KUA_FU_PORT = 0;
static bool KUA_FU_OPEN = false;
void GetKuaFuConfig(string &ip,int &port)
{
	ip = KUA_FU_IP;
	port = KUA_FU_PORT;
}

bool InKuaFu()
{
#ifdef KUA_FU
	return true;
#else
	return false;
#endif
}

void UpdateKuaFuOpenState()
{
	static int lastTime = 0;
	int t = GetSysTime();
	bool update = false;
	if(lastTime == 0 || (t - lastTime) > 60*5)
	{
		lastTime = t;
		update = true;
	}

	if(update)
	{	
		vector<int> serverIdList;
		GetServerIdList(serverIdList);
		if(serverIdList.empty())
			return;

		char sql[128];
		CDatabaseSql *pDb = GetLoginDb();
		if(pDb == NULL)
			return;
		snprintf(sql,sizeof(sql)-1,"select s.kf_open,k.ip,k.port from server_list as s,kf_config as k where s.server_id=%d and s.kf_id=k.id",serverIdList[0]);
		if(pDb->Query(sql))
		{
			char **row = NULL;
			if((row = pDb->GetRow()) != NULL)
			{
				KUA_FU_OPEN = (atoi(row[0]) == 0) ? false : true;
				KUA_FU_IP = row[1];
				KUA_FU_PORT = atoi(row[2]);
			}
		}
	}
}

bool IsOpenKuaFu()
{
	return KUA_FU_OPEN;
}

bool CanGetKuaFuInfo()
{
#ifdef KUA_FU
	return true;
#else
	return IsOpenKuaFu();
#endif
}

bool SendKuaFuData(int serverId,int sigId,string &signature,int sock)
{
#ifndef KUA_FU
	string ip;
	int port = 0;
	GetKuaFuConfig(ip,port);
	if(ip.empty() || port == 0)
		return false;
	if(sigId == 0 || signature.empty() || serverId == 0)
		return false;

	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_KUA_FU);
	msg<<(uint8)1<<ip<<port<<sigId<<signature<<serverId;
	SingletonSocket::instance().SendMsg(sock,msg);
	return true;
#else
	return false;
#endif
}

void SendLongQuerySql(const char *sql)
{
	if(sql == NULL)
		return;

	CNetMessage msg;
	msg.SetType(MSG_SERVER_QUERY_SQL);
	uint16 nlen = strlen(sql);
	msg<<nlen;
	msg.WriteData((void *)sql,nlen);
	SingletonSocket::instance().SendServerMsg(EST_LONG, msg);
}

uint16 GetToMapId(int sceneId,int srcSceneId)
{
	if(srcSceneId == BANG_PAI_SCENE_ID || srcSceneId == BP_FIGHT_READY_SID || srcSceneId == BP_FIGHT_SID)
		return srcSceneId;
	else if(srcSceneId == KUAFU_BZ_READY_SID || srcSceneId == KUAFU_BZ_SID)
		return srcSceneId;
	else if(srcSceneId == KUN_LUN_SHAN_TEAM_SCENE_ID)
		return srcSceneId;
	else
		return (uint16)sceneId;
}

bool IsEffectiveKunLunShanPos(int x,int y)
{
//	if(x <= 400 || x >= 2160 || y <= 240 || y >= 1136)
//		return false;
	return true;
}

static map<int,SKuaFuServerData> KFData;
static map<int,int> ServerZoneMap;	// serverId,zoneId
static vector<int> ZoneIdList;
static int SelfZoneId = 0;

#ifdef KUA_FU

void CopyUserDataToKuaFu(int serverId,int serverZoneId,uint32 id,string &signature,int index,int sock)
{
	if(signature.empty())
		return;
	uint16 nlen = signature.size();

	CSocketServer &sockServer = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_KF_LOGIN);
	msg<<index<<sock<<serverId<<id<<serverZoneId;
	msg<<nlen;
	msg.WriteData((void *)signature.c_str(),nlen);
	sockServer.SendServerMsg(EST_LONG, msg);
}

void CopyKuaFuDataToGameServer(int roleId,int serverId)
{
	CSocketServer &sockServer = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_KF_LOGOUT);
	msg<<serverId<<roleId;
	sockServer.SendServerMsg(EST_LONG, msg);
}

bool SendBackToGameServer(int serverId,int sigId,string &signature,int sock)
{
	if(sigId == 0 || signature.empty() || serverId == 0)
		return false;

	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_KUA_FU);
	msg<<(uint8)2<<sigId<<signature<<serverId;
	SingletonSocket::instance().SendMsg(sock,msg);
	return true;
}

void QueryGameServer_BangPaiInfo(int serverId,int roleId)
{
	if(roleId < 1)
		return;
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_SERVER_KF_BANG_PAI);
	msg<<(uint8)1<<serverId<<roleId;
	SingletonSocket::instance().SendServerMsg(EST_ZoneSerStart + GetServerZone(serverId),msg);
}

void QueryGameServer_BangPaiExist(int serverId,int bangPaiId)
{
	if(bangPaiId < 1)
		return;
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_SERVER_KF_BANG_PAI);
	msg<<(uint8)2<<serverId<<bangPaiId;
	SingletonSocket::instance().SendServerMsg(EST_ZoneSerStart + GetServerZone(serverId),msg);
}

void QueryGameServer_BangPaiByBangId(int serverId,int bangId)
{
	if(bangId < 1)
		return;
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_SERVER_KF_BANG_PAI);
	msg<<(uint8)3<<serverId<<bangId;
	SingletonSocket::instance().SendServerMsg(EST_ZoneSerStart + GetServerZone(serverId),msg);
}

void QueryGS_BangZhan_FirstInfo()
{
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_SERVER_KF_BANGZHAN_INFO);
	msg<<(uint8)1;
	SingletonSocket::instance().SendServerMsg(EST_LONG, msg);
}

void CheckKuaFuQieCuoMission(CUser *pWin,CUser *pOther)
{
	if(pWin == NULL || pOther == NULL)
		return;
	if(GetServerZone(pWin->GetServerId()) == GetServerZone(pOther->GetServerId()))
		return;
	
	int missionId = MISSION_ID_KuaFuShilian;
	SAcceptMission *pMission = pWin->m_missList.GetAcceptedCMission(missionId);
	if(pMission != NULL && pMission->save_var[0] == 2)
	{
		pWin->UpdateCMissionState(missionId, 1);
		CCallScript *pScript = GetScript250();
		if (pScript != NULL)
		{
			pScript->Call("KuaFuShiLianFinish", "ui", pWin, 1);
		}
	}
}

void SendLongQuerySqlToAllDB(const char *sql)
{
	if(sql == NULL)
		return;

	CNetMessage msg;
	msg.SetType(MSG_SERVER_QUERY_SQL_ALL_DB);
	uint16 nlen = strlen(sql);
	msg<<nlen;
	msg.WriteData((void *)sql,nlen);
	SingletonSocket::instance().SendServerMsg(EST_LONG, msg);
}

void SysGongGaoToAllServer(const char *msg)
{
	if(msg == NULL)
		return;
	
	CNetMessage sysMsg;
	sysMsg.SetType(PRO_SYSTEM_INFO);
	sysMsg<<msg;

	CSocketServer &sock = SingletonSocket::instance();
	for(uint16 i=0; i < ZoneIdList.size(); i++)
	{
		sock.SendServerMsg(EST_ZoneSerStart + ZoneIdList[i], sysMsg);
	}
}

#endif

void GetGameServerData(map<int,SKuaFuServerData> &data)
{
	data = KFData;
}

void GetGameZoneIdList(vector<int> &data)
{
	data.assign(ServerIdList.begin(),ServerIdList.end());
}


void ReadGameServerData()
{
	CDatabaseSql *pLoginDb = GetLoginDb();
	if(pLoginDb == NULL)
		return;
	KFData.clear();
	ZoneIdList.clear();

	vector<int> idList;
	GetServerIdList(idList);
	if(idList.empty())
		return;

	string sql = "select server_id,ip,port from server_list where server_id in(";
	for(uint32 i=0;i < idList.size();i++)
	{
		if(i > 0)
			sql += ",";
		sql += IntToStr(idList[i]);
	}
	sql += ")";
	
	if(pLoginDb->Query(sql.c_str()))
	{
		char **row = NULL;
		while((row = pLoginDb->GetRow()) != NULL)
		{
			int serverId = atoi(row[0]);
			SKuaFuServerData data;
			data.ip = row[1];
			data.port = atoi(row[2]);
			KFData.insert(make_pair(serverId,data));
		}

		map<int,SKuaFuServerData> kfDataTemp = KFData;
		while(!kfDataTemp.empty())
		{
			int zoneId = 0;
			string ip;
			int port = 0;
			for(map<int,SKuaFuServerData>::iterator it=kfDataTemp.begin();it != kfDataTemp.end();it++)
			{
				if(zoneId == 0)
				{
					zoneId = it->first;
					ip = it->second.ip;
					port = it->second.port;
				}
				else if(it->second.ip == ip && it->second.port == port)
				{
					if(it->first < zoneId)
						zoneId = it->first;
				}
			}
			
			map<int,SKuaFuServerData>::iterator del_it = kfDataTemp.end();
			for(map<int,SKuaFuServerData>::iterator it=kfDataTemp.begin();it != kfDataTemp.end();)
			{
				if(it->second.ip == ip && it->second.port == port)
				{
					del_it = it;
					ServerZoneMap.insert(make_pair(it->first,zoneId));
					it++;
					kfDataTemp.erase(del_it);
					continue;
				}
				it++;
			}
			ZoneIdList.push_back(zoneId);
		}
	}
}

int GetServerZone(int serverId)
{
	map<int,int>::iterator it = ServerZoneMap.find(serverId);
	if(it == ServerZoneMap.end())
		return 0;
	return it->second;
}

void SetSelfZoneId(int zoneId)
{
	SelfZoneId = zoneId;
}

int GetSelfZoneId()
{
	return SelfZoneId;
}

void UserMsgToAllServer(CUser *pUser,const char *str)
{
	if(pUser == NULL || str == NULL)
		return;
	
#ifdef KUA_FU
	string name = pUser->GetName();
#else
	string name = GetKuaFuRoleName(pUser);
#endif

	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_SERVER_SYSINFO);
	msg<<(uint8)ECT_KuaFuBroadCast<<pUser->GetRoleId()<<name<<pUser->GetVipLevel()<<pUser->GetHead()<<pUser->GetSex()<<str;
//	SingletonSocket::instance().SendAllGameServer(msg);
	MsgForwardToServers(msg);
}

void KFChatMsgToAllServer(CNetMessage &msg)
{
	msg.SetType(MSG_SERVER_SYSINFO);
	MsgForwardToServers(msg);
}

string GetKuaFuRoleName(CUser *pUser)
{
	if(pUser == NULL)
		return "";
	int serverId = pUser->GetServerId();
	if(serverId == 0)
		return pUser->GetName();
	string roleName = "s" + IntToStr(serverId) + ".";
	roleName += pUser->GetName();
	return roleName;
}

bool GetShenQiEnhanceInfo( int level ,int star,SShenQiPeiYang &info)
{	
	info.Clear();
	if( level > SHENQI_MAX_LEVEL || level <= 0 || star > SHENQI_MAX_STAR || star<0 )
		return false;
	SShenQiPeiYang *p = SingletonShenQiCfgMgr::instance().GetPYCfg(level,star);
	if(p != NULL)
		info = *p;
	return true;
}

bool GetShenQiItemActiveInfo(int shenqi_id, StShenQiItemActiveInfo &info)
{
	if( shenqi_id <= SHENQI_NONE || shenqi_id > SHENQI_NUM )
		return false;
	info.init();
	for( int counter = 0;counter < (int)(sizeof(shenQiItemActiveInfo)/sizeof(shenQiItemActiveInfo[0]));++counter)
	{
		if( shenqi_id == shenQiItemActiveInfo[counter].shenqi_id)
		{
			info = shenQiItemActiveInfo[counter];
			return true;
		}
	}
	return false;
}
#ifdef KUA_FU
int GetKuaFu1vs1RobotByZhandouli(int zhandouli)
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return 0;
	int tarRobotId = 1;
	char sql[512];
	char **row = NULL;
	snprintf(sql,sizeof(sql),"select id from shilian_robot where zhanDouLi>=%d order by zhanDouLi asc limit 1",zhandouli);
	if(!pDb->Query(sql))
		return 0;
	if((row = pDb->GetRow()) != NULL)
		tarRobotId = atoi(row[0]);
	
	return tarRobotId;
}
bool CopyKuaFu1vs1RobotInfo(int rank ,StKuaFu1vs1SaveEnemyInfo &info)
{
	CUser *pUser = new CUser;
	if(pUser == NULL)
		return false;
	pUser->SetSock(-1);
	if(!pUser->CopyUserData(rank,2))
	{    
		delete pUser;
		return false;
	}
	string robotName;
	GetFastRoleName(pUser->GetSex(),robotName);
	char buf[128];
	snprintf(buf,sizeof(buf),"%s%c%c",robotName.c_str(),Random(0,25)+'a',Random(0,25)+'a');
	pUser->SetName(buf);
	pUser->SetServerId(1);

	info.kind = 1;
	info.role_id = rank;
	info.name = pUser->GetName();
	info.level = pUser->GetLevel();
//	info.xiang = pUser->GetXiang();
	info.sex = pUser->GetSex();
	info.super_level = pUser->GetVipLevel();
	info.wing_id = pUser->GetWingId();
	info.zhandouli = pUser->GetZhanDouLi();
	info.score = 0;
	info.server_id = pUser->GetServerId();
	delete pUser;
	
	return true;
}
ShareUserPtr GetKuaFu1vs1EnemyInfo(StKuaFu1vs1SaveEnemyInfo &info)
{
	ShareUserPtr ptr;
	
	CUser *pUser = new CUser;
	if(pUser == NULL)
		return ptr;
		pUser->SetSock(-1);
	if(info.kind ==1 )
	{
		if(!pUser->CopyUserData(info.role_id,2))
		{    
			delete pUser;
			return ptr;
		}
	}
	else
	{
		if(!pUser->CopyUserData(info.role_id,0))
		{
			delete pUser;
			return ptr;
		}
	}
	string robotName;
	pUser->SetName(info.name.c_str());
	ptr.reset(pUser);
	return ptr;
}

int GetKuaFuBangZhanType()
{
	int weekDay = GetWeekDay();
	if(weekDay == 2)	// 预赛
		return 1;
	else if(weekDay == 5)		// 决赛
		return 2;
	else
		return 0;
}

#endif
string GetKuaFuRoleNameByServerID(string name,int serverId)
{
	if(serverId == 0)
		return name;
	string roleName = "s" + IntToStr(serverId) + ".";
	roleName += name;
	return roleName;
}
bool AddPackageByID( CUser* pUser,int id,int num,bool isShow,bool isFightEnd)
{
	if(pUser == NULL)
		return false;
	if(!pUser->AddPackage(id,num))
		return false;
	if(isShow)
	{
		char buf[128];
		snprintf(buf, sizeof(buf),LANGUAGE_TRANSFORM_2212, GetItemName(id),num);
		if(isFightEnd)
			SendSysInfoFightEnd(pUser, MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
		else
			SendSysInfo(pUser, MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());	
	}
	return true;
}

bool GetChongZhiFanYBDataId(uint32 huodongType, uint32 &totalCZDataId,uint32 &maskDataId)
{
	switch(huodongType)
	{
 		case CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO:
			totalCZDataId = 205;
			maskDataId = 206;
			break;
		case CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO2:
			totalCZDataId = 258;
			maskDataId = 259;
			break;
		case CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO3:
			totalCZDataId = 272;
			maskDataId = 273;
			break;
		case CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO4:
			totalCZDataId = 274;
			maskDataId = 275;
			break;
		case CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO5:
			totalCZDataId = 276;
			maskDataId = 277;
			break;
		case CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO6:
			totalCZDataId = 307;
			maskDataId = 308;
			break;
		case CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO7:
			totalCZDataId = 309;
			maskDataId = 310;
			break;
		case CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO8:
			totalCZDataId = 311;
			maskDataId = 312;
			break;
		case CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO9:
			totalCZDataId = 313;
			maskDataId = 314;
			break;
		case CHuoDongAwardManager::CHONG_ZHI_FAN_YUANBAO10:
			totalCZDataId = 315;
			maskDataId = 316;
			break;
		default:
			return false;
	}

	return true;
}

bool GetLevelFanLiDataId(uint32 huodongType, uint32 &totalCZDataId, uint32 &maskDataId)
{
	switch (huodongType)
	{
	case CHuoDongAwardManager::LEVEL_JIJIN1_FANLI:
		totalCZDataId = 633;
		maskDataId = 458;
		break;

	default:
		return false;
	}
	return true;
}

bool GetMeiRiXiaoFeiYBDataId(uint32 huodongType,uint32 &totalXFDataId,uint32 &maskDataId)
{
	switch(huodongType)
	{
 		case CHuoDongAwardManager::MEIRI_XIAOFEI1:
			totalXFDataId = 423;
			maskDataId = 424;
			break;
		case CHuoDongAwardManager::MEIRI_XIAOFEI2:
			totalXFDataId = 425;
			maskDataId = 426;
			break;
		case CHuoDongAwardManager::MEIRI_XIAOFEI3:
			totalXFDataId = 427;
			maskDataId = 428;
			break;
		case CHuoDongAwardManager::MEIRI_XIAOFEI4:
			totalXFDataId = 429;
			maskDataId = 430;
			break;
		case CHuoDongAwardManager::MEIRI_XIAOFEI5:
			totalXFDataId = 431;
			maskDataId = 432;
			break;
		default:
			return false;
	}
	return true;
}

void GetHongLiJiFenHDs(vector<uint32> &HDlist)
{
	const uint32 HLJFlist[] = {CHuoDongAwardManager::HONGLI_JIFEN,CHuoDongAwardManager::HONGLI_JIFEN2,CHuoDongAwardManager::HONGLI_JIFEN3,CHuoDongAwardManager::HONGLI_JIFEN4,
			CHuoDongAwardManager::HONGLI_JIFEN5};

	HDlist.clear();

	for (uint32 i = 0; i < sizeof(HLJFlist)/sizeof(HLJFlist[0]); i++)
		HDlist.push_back(HLJFlist[i]);
}

bool GetHongLiJiFenDataId(uint32 huodongType, uint32 &timeDataId, uint32 &jifenDataId)
{
	switch(huodongType)
	{
 		case CHuoDongAwardManager::HONGLI_JIFEN:
			timeDataId = 281;
			jifenDataId = 282;
			break;
		case CHuoDongAwardManager::HONGLI_JIFEN2:
			timeDataId = 317;
			jifenDataId = 318;
			break;
		case CHuoDongAwardManager::HONGLI_JIFEN3:
			timeDataId = 319;
			jifenDataId = 320;
			break;
		case CHuoDongAwardManager::HONGLI_JIFEN4:
			timeDataId = 321;
			jifenDataId = 322;
			break;
		case CHuoDongAwardManager::HONGLI_JIFEN5:
			timeDataId = 323;
			jifenDataId = 324;
			break;
		default:
			return false;
	}
	return true;
}

bool AddHongLiJiFen(CUser *pUser,int jifen)
{
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	bool isAdd = false;

	vector<uint32> HLJFlist;
	GetHongLiJiFenHDs(HLJFlist);
	for (uint32 i = 0; i < HLJFlist.size(); i++)
	{
		uint32 timeDataId = 0;
		uint32 jifenDataId = 0;
		if (awardManager.InHuoDongTime(HLJFlist[i]))
		{
			if (GetHongLiJiFenDataId(HLJFlist[i],timeDataId,jifenDataId))
			{
				pUser->SetExtData32(jifenDataId, pUser->GetExtData32(jifenDataId) + jifen);
				isAdd = true;
			}
		}
	}
	return isAdd;
}

bool GetHongLiDataId(uint32 huodongType, uint32 &timeDataId, uint32 &leijiDataId,uint32 &maskDataId)
{
	switch(huodongType)
	{
		case CHuoDongAwardManager::HONGLI_CHONGZHI:
			timeDataId = 212;
			leijiDataId = 208;
			maskDataId = 209;
			break;
		case CHuoDongAwardManager::HONGLI_CHONGZHI2:
			timeDataId = 325;
			leijiDataId = 326;
			maskDataId = 327;
			break;
		case CHuoDongAwardManager::HONGLI_CHONGZHI3:
			timeDataId = 328;
			leijiDataId = 329;
			maskDataId = 330;
			break;
		case CHuoDongAwardManager::HONGLI_CHONGZHI4:
			timeDataId = 331;
			leijiDataId = 332;
			maskDataId = 333;
			break;
		case CHuoDongAwardManager::HONGLI_CHONGZHI5:
			timeDataId = 334;
			leijiDataId = 335;
			maskDataId = 336;
			break;
		case CHuoDongAwardManager::HONGLI_CHONGZHI_RMB:
			timeDataId = 280;
			leijiDataId = 278;
			maskDataId = 279;
			break;
		case CHuoDongAwardManager::HONGLI_XIAOFEI:
			timeDataId = 213;
			leijiDataId = 210;
			maskDataId = 211;
			break;
		case CHuoDongAwardManager::HONGLI_XIAOFEI2:
			timeDataId = 337;
			leijiDataId = 338;
			maskDataId = 339;
			break;
		case CHuoDongAwardManager::HONGLI_XIAOFEI3:
			timeDataId = 340;
			leijiDataId = 341;
			maskDataId = 342;
			break;
		case CHuoDongAwardManager::HONGLI_XIAOFEI4:
			timeDataId = 343;
			leijiDataId = 344;
			maskDataId = 345;
			break;
		case CHuoDongAwardManager::HONGLI_XIAOFEI5:
			timeDataId = 346;
			leijiDataId = 347;
			maskDataId = 348;
			break;

		default:
			return false;
	}
	return true;
}

double round(const double data,int digits)
{
	double tmp = data * pow( 10,digits);  
	tmp  =  (tmp > 0.0) ? floor(tmp + 0.5) : ceil(tmp - 0.5);
	tmp = tmp / pow( 10,digits);
	return tmp;
}

bool ChongZhiToOtherSendAward(int roleId,int friendId,SChongZhi2OtherAward &data)
{
	if(roleId <= 0 || friendId <=0 || data.RMB == 0)
		return false;
	char buf[512];
	char fName[128];

	int titleId = 0;
	
	SMailData m;
	for(int i=0;i < SChongZhi2OtherAward::AWARD_NUM;i++)
	{
		if(data.self_award[i] > 0 && data.self_num[i] > 0)
		{

			if(data.self_award[i] == HDAT_CHENGHAO)
			{
				titleId = data.self_num[i];
			}
		}
	}
	if(titleId > 0)
		AddUserTitle(roleId,titleId);
	snprintf(buf,sizeof(buf)-1,LANGUAGE_LLD_0054,GetTitleName(titleId));
	SendSystemMail(roleId,buf,&m);

	stringstream dataStr;
	for(int i=0;i < SChongZhi2OtherAward::AWARD_NUM;i++)
	{
		/*if(data.friend_award[i] > 0 && data.friend_num[i] > 0)
		{
			if(data.friend_award[i] < HDAT_MONEY)
			{
				SItemInstance item;
				item.tmplId = data.friend_award[i];
				item.num = data.friend_num[i];
				m.item.push_back(item);
				dataStr<<GetItemName(item.tmplId)<<"*"<<(int)item.num<<"，";
			}
			else if(data.friend_award[i] == HDAT_MONEY)
			{
				m.money += data.friend_num[i];
				dataStr<<LANGUAGE_TRANSFORM_1500<<(int)m.money<<"，";
			}
			else if(data.friend_award[i] == HDAT_BANG_YB)
			{
				m.bdYB += data.friend_num[i];
				dataStr<<LANGUAGE_TRANSFORM_1501<<(int)m.bdYB<<"，";
			}
			else if(data.friend_award[i] == HDAT_YB)
			{
				m.YB += data.friend_num[i];
				dataStr<<LANGUAGE_TRANSFORM_1502<<(int)m.YB<<"，";
			}
			else if(data.friend_award[i] == HDAT_CHENGHAO)
			{
				titleId = data.friend_num[i];
			}
		}*/
	}
	if(titleId > 0)
		AddUserTitle(friendId,titleId);
	GetRoleName(roleId,fName);
	snprintf(buf,sizeof(buf)-1,LANGUAGE_SSJ_0093,fName,dataStr.str().c_str(),GetTitleName(titleId));
	SendSystemMail(friendId,buf,&m);

	return true;
}

bool GetJiJinFanLiDataId(uint32 huodongType, uint32 &buyRecordDataId, uint32 &startTimeDataId,uint32 &buyFirstTimeDataId,uint32 &getMaskDataId)
{
	switch(huodongType)
	{
		case CHuoDongAwardManager::JIJIN_FANLI:
			buyRecordDataId = 437;
			startTimeDataId = 284;
			buyFirstTimeDataId = 285;
			getMaskDataId = 286;
			break;
		case CHuoDongAwardManager::JIJIN_FANLI2:
			buyRecordDataId = 483;
			startTimeDataId = 351;
			buyFirstTimeDataId = 352;
			getMaskDataId = 353;
			break;
		case CHuoDongAwardManager::JIJIN_FANLI3:
			buyRecordDataId = 484;
			startTimeDataId = 354;
			buyFirstTimeDataId = 355;
			getMaskDataId = 356;
			break;
		default:
			return false;
	}
	return true;
}

float GetQunXianHpRatio(int ratio)
{
	if(ratio <= 0)
		return 0.0f;
	return ratio/10000.0;
}

int GetQunXianAwardIdx(int floor)
{
	int idx = 0;
	if(floor < 1 || floor > CQunXianZhengBaManager::MAX_FLOOR)
		return idx;
	CQunXianZhengBaManager &manager = SingletonCQunXianZhengBaManager::instance();
	for(int i=1;i < floor;i++)
	{
		SQunXianZhengBaConig floorCF;
		manager.GetFloorConfig(i,floorCF);
		if(floorCF.type == 1)
			idx++;
	}
	return idx;
}

bool HaveQunXianAwardCanTake(CUser *pUser)
{
	if(pUser == NULL)
		return false;

	uint8 maxFloor = pUser->GetExtData8(488);
	CQunXianZhengBaManager &manager = SingletonCQunXianZhengBaManager::instance();
	int awardIdx = 0;
	for(int f=1;f <= maxFloor;f++)
	{
		SQunXianZhengBaConig floorCF;
		manager.GetFloorConfig(f,floorCF);
		if(floorCF.type == 1)
		{
			awardIdx++;
			if(!pUser->HaveGetQunXianAward(awardIdx))
				return true;
		}
	}
	return false;
}

string SendWinXinShareMail(CUser *pUser, uint32 awardType, uint32 awardNum)
{
	/*SMailData mdata;
	string awardName;

	if(awardType == HDAT_BANG_YB)
	{
		mdata.bdYB += awardNum;
		awardName = "绑定元宝";
	}
	else if(awardType > 0 && awardType < HDAT_MONEY)
	{
		SItemInstance item;
		item.tmplId = awardType;
		item.num = awardNum;
		mdata.item.push_back(item);
		awardName = GetItemName(awardType);
	}
	
	char buf[512];
	snprintf(buf,sizeof(buf)-1,LANGUAGE_LLD_0058,awardNum,awardName.c_str());
	SendSystemMail(pUser->GetRoleId(),buf,&mdata);
	return buf;*/
	return "";
}

const char *GetWingName(int wingId)
{
	SWingConfig *p = SingletonWingCfgMgr::instance().GetCfg(wingId);
	if(p == NULL)
		return NULL;
	return p->name.c_str();
}

const char *GetMountName(int mountId)
{
	SMountConfig *p = SingletonMountCfgMgr::instance().GetCfg(mountId);
	if(p == NULL)
		return NULL;
	return p->name.c_str();
}

void GetHDMsgGoods(vector<Goods> &goods,CNetMessage &msg)
{
	const uint32 size = 2;
	for (uint32 i = 0; i < size; i++)
	{
		Goods g;
		msg>>g.id;
		msg>>g.num;
		
		goods.push_back(g);
	}
}

string CreateJiaoYiRecord(string buyer_name,int sell_yb,int buy_glod,uint32 state)
{
	char buff[512] = {0};
	if (state == CJiaoYiHangManager::SELL)
	{
		snprintf(buff,sizeof(buff),LANGUAGE_LLD_0109,buyer_name.c_str(),buy_glod,sell_yb);
	}
	else if (state == CJiaoYiHangManager::BUY)
	{
		snprintf(buff,sizeof(buff),LANGUAGE_LLD_0112,buy_glod,sell_yb);
	}
	else if (state == CJiaoYiHangManager::CHANNEL_SELL)
	{
		snprintf(buff,sizeof(buff),LANGUAGE_LLD_0111,sell_yb);
	}
	else if (state == CJiaoYiHangManager::OVER_TIME)
	{
		snprintf(buff,sizeof(buff),LANGUAGE_LLD_0110,sell_yb);
	}
	return buff;
}

string GetAwardName(uint32 awardId)
{
	string name = "";
	if(awardId < 60000)
	{
		const char *itemName = GetItemName(awardId);
		if (itemName != NULL)
			name = itemName;
	}
	else if(awardId == HDAT_MONEY)
	{
		name = LANGUAGE_LLD_0106;
	}
	else if(awardId == HDAT_BANG_YB)
	{
		name = LANGUAGE_LLD_0107;
	}
	else if(awardId == HDAT_YB)
	{
		name = LANGUAGE_LLD_0108;
	}
	return name;
}

string GetAwardsName(uint32 *awardIds,uint32 *awardNums,uint32 size)
{
	char buf[512] = {0};
	int total_size = sizeof(buf);
	int num = 0;
	for(uint8 j=0;j < size;j++)
	{
		if (awardIds[j] > 0 && awardNums[j] > 0)
		{
			char *pbuf = buf + strlen(buf);
			int buf_size = total_size - strlen(buf);

			if (num > 0)
			{
				snprintf(pbuf,buf_size,LANGUAGE_LLD_0140);
				pbuf = buf + strlen(buf);
				buf_size = total_size - strlen(buf);
			}

			if(awardIds[j] < HDAT_MONEY)
			{
				snprintf(pbuf,buf_size,"%s*%u",GetItemName(awardIds[j]),awardNums[j]);
				num++;
			}
			else if(awardIds[j] == HDAT_MONEY)
			{
				snprintf(pbuf,buf_size,LANGUAGE_LLD_0134,awardNums[j]);
				num++;
			}
			else if(awardIds[j] == HDAT_BANG_YB)
			{
				snprintf(pbuf,buf_size,LANGUAGE_LLD_0135,awardNums[j]);
				num++;
			}
			else if(awardIds[j] == HDAT_PET)
			{
				snprintf(pbuf,buf_size,LANGUAGE_LLD_0136,GetPetName(awardNums[j]));
				num++;
			}
			else if(awardIds[j] == HDAT_YB)
			{
				snprintf(pbuf,buf_size,LANGUAGE_LLD_0137,awardNums[j]);
				num++;
			}
			else if(awardIds[j] == HDAT_EXP)
			{
				snprintf(pbuf,buf_size,LANGUAGE_LLD_0138,awardNums[j]);
				num++;
			}
			else if(awardIds[j] == HDAT_QIANNENG)
			{
				snprintf(pbuf,buf_size,LANGUAGE_LLD_0139,awardNums[j]);
				num++;
			}
		}
	}

	return buf;
}

string GetAwardsString(vector<SAwardData> &award)
{
	string str;
	for(uint16 i=0;i < award.size();i++)
	{
		const char *pName = GetItemName(award[i].type);
		if(pName == NULL)
			continue;
		if(!str.empty())
			str += ",";
		str += pName;
		str += "*" + IntToStr(award[i].num);
	}
	return str;
}

int GetRoleAwardNum(CUser *pUser,uint32 awardId)
{
	int num = 0;

	if (pUser != NULL)
	{
		if(awardId < 60000)
		{
			num =  pUser->GetItemNum(awardId);
		}
		else if(awardId == HDAT_MONEY)
		{
			num = pUser->GetMoney();
		}
		else if(awardId == HDAT_BANG_YB)
		{
			num = pUser->GetTongBao(1);
		}
		else if(awardId == HDAT_YB)
		{
			num = pUser->GetTongBao();
		}
	}
	return num;
}

void CostAward(CUser *pUser,uint32 awardId,int awardNum)
{
	if (pUser != NULL)
	{
		if(awardId < 60000)
		{
			pUser->DelPackageById(awardId,awardNum);
		}
		else if(awardId == HDAT_MONEY)
		{
			pUser->AddMoney(-awardNum);
		}
		else if(awardId == HDAT_BANG_YB)
		{
			pUser->AddTongBao(-awardNum,1);
		}
		else if(awardId == HDAT_YB)
		{
			pUser->AddTongBao(-awardNum);
		}
	}

}

void SendHDNotInPaiHangInScoreAward(uint8 festivalType, map<uint32, uint32> &getAwardRole,uint32 hd_type)
{
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char sql[512];
	char** row = NULL;
	char mailMsg[512];
	uint32 idx3 = 0;
	uint32 idx = 0;
	double ratio = 1.0;
	uint32 limitScore = 0;
	
	if (hd_type == CHuoDongAwardManager::FESTIVAL)
	{
		const char *name[2] = {LANGUAGE_TRANSFORM_1849,LANGUAGE_TRANSFORM_1850};
		idx3 = awardManager.GetFestivalAwardIdx3(festivalType,0,0);
		idx = awardManager.GetAwardIdx(hd_type,festivalType,idx3);
		limitScore = awardManager.GetFestivalMinScore(festivalType);
		
		snprintf(mailMsg,sizeof(mailMsg),LANGUAGE_TRANSFORM_1851,awardManager.GetHuoDongName(hd_type).c_str(),name[festivalType]);
		
	}
	else if (hd_type == CHuoDongAwardManager::ZHENYING_PK1 || hd_type == CHuoDongAwardManager::ZHENYING_PK2)
	{
		uint32 zhenYingPKWin = awardManager.GetZhenYingWinId();
		idx3 = awardManager.GetHDPaiHangAwardIdxByRank(hd_type,0);
		idx = awardManager.GetAwardIdx(hd_type,CHuoDongAwardManager::ZHENYING_PK_MEM_IDX2,idx3);
		limitScore = awardManager.GetPaiHangLimitScore(hd_type);

		if (hd_type == zhenYingPKWin)
		{
			ratio = 1.5;
			snprintf(mailMsg,sizeof(mailMsg),LANGUAGE_LLD_0214,(int)(ratio * 100));
		}
		else
		{
			ratio = 0.8;
			snprintf(mailMsg,sizeof(mailMsg),LANGUAGE_LLD_0214,(int)(ratio * 100));
		}
	}

	snprintf(sql, sizeof(sql), "select role_id,level from festival_record where hd_type = %d and type=%d and start_time = %d and score >= %d order by score desc",
												hd_type,festivalType,awardManager.GetHuoDongStartTime(hd_type), limitScore);
	if(pDb == NULL || !pDb->Query(sql))
		return;

	SHuoDongAward award;
	awardManager.GetAwardData(hd_type,idx,award);
	while((row = pDb->GetRow()) != NULL)
	{
		uint32 roleId = atoi(row[0]);
		uint32 level = atoi(row[1]);
		map<uint32, uint32>::iterator it = getAwardRole.find(roleId);
		if (it == getAwardRole.end())
		{
			SendHuoDongAwardMail(roleId, level, award, mailMsg,hd_type,ratio);
		}
	}

}

void HDGivePresent(CUser *pUser,uint32 roleId, vector<GoodsInfo> &info, CNetMessage &msg,uint32 hd_type)
{
	string get_name;
	vector<string> giveLog;
	vector<string> getLog;
	vector<FestivalRecord> record;
	char buf[512];
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 hdStartTime = awardManager.GetHuoDongStartTime(hd_type);
	uint32 hdTimeDataId = 0;
	uint32 zhenYingType = pUser->GetExtData32(383);
	char buff[125] = {0};

	if (hd_type == CHuoDongAwardManager::ZHENYING_PK)
	{
		hdTimeDataId = 385;
	}

	if (hdTimeDataId == 0)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0207,TIPS_FAILURE_COLOR);
		return;
	}

// 受赠积分
	ShareUserPtr pU = SingletonOnlineUser::instance().GetUserByRoleId(roleId);
	CUser *p = pU.get();
	bool playerOnline = false;
	FestivalRecord getRecord; // 受赠记录
	FestivalRecord giveRecord; // 赠与记录
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(p != NULL)
	{
		playerOnline = true;
	}

	if (playerOnline)
	{
		get_name = p->GetName();
		
		getRecord.type = 1;
		getRecord.role_id = roleId;
		getRecord.role_name = p->GetName();
		getRecord.bang_name = GetRoleBangPaiName(roleId);
		getRecord.level = p->GetLevel();
//		getRecord.xiang = p->GetXiang();
		getRecord.sex = p->GetSex();
		getRecord.score = 0;
	}
	else
	{
		p = new CUser;
		if(p == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_244,TIPS_FAILURE_COLOR);
			return;
		}

		if(pDb == NULL)
		{
			delete p;
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_245,TIPS_FAILURE_COLOR);
			return;
		}

		char **row = NULL;
		char sql[4096];
		//                           0   1      2      3   4    5       6
		snprintf(sql, sizeof(sql), "select name,level,bank_item,head,sex,package,zhanDouLi from role_info where id=%u",roleId);
		if(!pDb->Query(sql) || (row = pDb->GetRow()) == NULL)
		{
			delete p;
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_246,TIPS_FAILURE_COLOR);
			return;
		}

		getRecord.type = 1;
		getRecord.role_id = roleId;
		getRecord.role_name = row[0];
		getRecord.level = atoi(row[1]);
		getRecord.xiang = atoi(row[3]);
		getRecord.sex = atoi(row[4]);
		getRecord.score = 0;
		getRecord.bang_name = GetRoleBangPaiName(roleId);

		get_name = row[0];

		p->SetRoleId(roleId);
		p->SetName(row[0]);
		p->SetLevel(atoi(row[1]));
		p->SetBankItem(row[2]);
//		p->SetXiang(atoi(row[3]));
		p->SetSex(atoi(row[4]));
		p->SetPackage(row[5]);
		p->SetZhanDouLi(atoi(row[6]));
		p->SetBangPaiName(getRecord.bang_name);

	}

	if (hd_type == CHuoDongAwardManager::ZHENYING_PK)
	{
		snprintf(buff,sizeof(buff),"-----%d",zhenYingType);
	}
	getRecord.bang_name = getRecord.bang_name + buff;

	
	if (p->GetExtData32(hdTimeDataId) != hdStartTime)
	{
		if (hd_type == CHuoDongAwardManager::ZHENYING_PK)
			p->ZhenYingPKClearData();
	}

	for (uint32 i = 0; i < info.size(); i++)
	{
		if (info[i].num > 0)
		{
			p->SetExtData32(info[i].get_data_id, p->GetExtData32(info[i].get_data_id) + info[i].num);

			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_241,ROLE_NAME_COLOR,pUser->GetName(),info[i].num,GetItemName(info[i].award));
			getLog.push_back(buf);

			if (hd_type == CHuoDongAwardManager::ZHENYING_PK)
			{
				snprintf(buf,sizeof(buf),LANGUAGE_LLD_0208,GetItemName(info[i].award),getRecord.role_name.c_str(),getRecord.role_name.c_str(),info[i].num * info[i].score_get);
				SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());

				if (playerOnline)
				{
					snprintf(buf,sizeof(buf),LANGUAGE_LLD_0209, info[i].num * info[i].score_get,info[i].num * info[i].score_get);
					SendSysInfo(p,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
				}

				awardManager.AddZhenYingScore(zhenYingType,info[i].num * info[i].score_get);
			} 
		}
			
		getRecord.num[i] = p->GetExtData32(info[i].get_data_id);
		getRecord.score += getRecord.num[i] * info[i].score_get;
	}

	if (getRecord.score > 0)
	{
		record.push_back(getRecord);

		if (hd_type == CHuoDongAwardManager::ZHENYING_PK)
		{
			awardManager.UpdatePaiHang(p,CHuoDongAwardManager::ZHENYING_PK,getRecord.score);
			awardManager.UpdatePaiHang(p,zhenYingType,getRecord.score);
		}
	}

	if (playerOnline)
		p->SetHDShowHIstory(1, getLog,hd_type);
	else
	{
		string str;
		string pkgStr;
		p->GetBankItem(str);
		p->GetPackage(pkgStr);
		boost::format fmt("update role_info set bank_item='%1%',package='%2%' where id=%3%");
		fmt % str.c_str() % pkgStr.c_str() % roleId;
		pDb->Query(fmt.str().c_str());
		delete p;
		p = NULL;
	}

//赠送积分
	giveRecord.type = 0;
	giveRecord.role_id = pUser->GetRoleId();
	giveRecord.role_name = pUser->GetName();
	giveRecord.bang_name = pUser->GetBangName();
	giveRecord.level = pUser->GetLevel();
//	giveRecord.xiang = pUser->GetXiang();
	giveRecord.sex = pUser->GetSex();
	giveRecord.score = 0;
	giveRecord.bang_name = giveRecord.bang_name + buff;

	uint32 giveScore = 0;
	for (uint32 i = 0; i < info.size(); i++)
	{
		if (info[i].num > 0)
		{
			if (hd_type != CHuoDongAwardManager::ZHENYING_PK)
				pUser->SetExtData32(info[i].give_data_id, pUser->GetExtData32(info[i].give_data_id) + info[i].num);
			
			pUser->DelPackageById(info[i].award,info[i].num);
			giveScore += info[i].num * info[i].score_give;

			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_248,ROLE_NAME_COLOR,get_name.c_str(),info[i].num,GetItemName(info[i].award));
			giveLog.push_back(buf);
		}

		giveRecord.num[i] = pUser->GetExtData32(info[i].give_data_id);
		giveRecord.score += giveRecord.num[i] * info[i].score_give;
	}

	if (giveRecord.score > 0)
		record.push_back(giveRecord);

	if (giveScore > 0)
	{
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_249,giveScore);
		SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
	}
		
	pUser->SetHDShowHIstory(0, giveLog,hd_type);

	AddHDShowLog(pUser->GetRoleId(), giveLog, roleId, getLog,hd_type);

	if (hd_type == CHuoDongAwardManager::ZHENYING_PK)
		AddFestivalRecord(record,zhenYingType);
	else
		AddFestivalRecord(record,hd_type);

	msg<<PRO_SUCCESS;

	if (hd_type == CHuoDongAwardManager::ZHENYING_PK)
	{
		uint32 myScore = 0;
		msg<<awardManager.GetZhenYingScore(CHuoDongAwardManager::ZHENYING_PK1);
		msg<<awardManager.GetZhenYingScore(CHuoDongAwardManager::ZHENYING_PK2);

		for (uint32 i = 0; i < info.size(); i++)
		{
			myScore +=  pUser->GetExtData32(info[i].get_data_id) * info[i].score_get;
		}
		msg<<myScore;
	}

	msg<<(uint8)2<<(uint8)0<<(uint8)giveLog.size();
	for (uint32 i = 0; i < giveLog.size(); i++)
		msg<<(uint32)0<<giveLog[i].c_str();

	msg<<(uint8)1;
	if (pUser->GetRoleId() == roleId)
	{
		msg<<(uint8)getLog.size();
		for (uint32 i = 0; i < getLog.size(); i++)
			msg<<(uint32)0<<getLog[i].c_str();
	}
	else
	{
		msg<<(uint8)0;
	}
}

void GetZhenYingPKList(list<uint32> &idList,uint32 myZhenYingId,CNetMessage &msg)
{
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	list<uint32> unonline;
	uint32 hotNum = 0;
	uint16 pos = msg.GetDataLen();
	uint32 hdTimeDataId = 385;
	msg<<hotNum;

	char sql[1024] = "select name,level,id,head,sex,zhanDouLi,bank_item from role_info where id in(";
	char temp[32];
	const int len = strlen(sql);
	COnlineUser &m_onlineUser = SingletonOnlineUser::instance();

	for(list<uint32>::iterator i = idList.begin(); i != idList.end(); i++)
	{
		ShareUserPtr ptr = m_onlineUser.GetUserByRoleId(*i);
		CUser *pUser = ptr.get();
		if(pUser == NULL)
		{
			if(sql[len] == '\0')
				snprintf(temp,sizeof(temp),"%u",*i);
			else
				snprintf(temp,sizeof(temp),",%u",*i);
			unonline.push_back(*i);
			strcat(sql,temp);
		}
		else if (myZhenYingId == pUser->GetExtData32(383))
		{
			// roleId,name,level,xiang
			msg<<*i<<pUser->GetName()<<(uint8)pUser->GetLevel()<<pUser->GetHead()<<pUser->GetSex();
			hotNum++;
		}
	}
	if(sql[len] != '\0')
	{
		do
		{
			CGetDbConnect getDb;
			CDatabaseSql *pDb = getDb.GetDbConnect();
			char **row;
			strcat(sql,")");

			if((pDb == NULL) || !(pDb->Query(sql)))
				break;
			else
			{
				CUser *pUserGet = new CUser;

				while((row = pDb->GetRow()) != NULL)
				{
					for(list<uint32>::iterator i = unonline.begin(); i != unonline.end(); i++)
					{
						if(*i == (uint32)atoi(row[2]))
						{
							pUserGet->SetBankItem(row[6]);

							if (pUserGet->GetExtData32(hdTimeDataId) != awardManager.GetHuoDongStartTime(myZhenYingId))
								pUserGet->ZhenYingPKClearData();

							if (pUserGet->GetExtData32(383) == myZhenYingId)
							{
								msg<<*i<<row[0]<<(uint8)atoi(row[1])<<(uint8)atoi(row[3])<<(uint8)atoi(row[4]);
								hotNum++;
							}
							unonline.erase(i);
							break;
						}
					}
				}

				delete pUserGet;
				pUserGet = NULL;
			}
		}while(0);
	}
	msg.WriteData(pos,&hotNum,sizeof(hotNum));
}

void QiangHongBaoZhuDong(uint8 op,CUser *pUser)
{
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_TMP_HUODONG);
	msg<<(uint8)HD_QIANG_HONGBAO<<(uint8)5<<PRO_SUCCESS<<op;

	if (pUser == NULL)
		SysMsgToAllUser(msg);
	else
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

bool IsWeiXin(int type)
{
	return (type == 888 || type == 999);
}


bool CheckPersonalName(string &pStr)
{
	if(pStr.empty())
		return false;
	int num = 0;
	bool ignoreC = false;
	for(uint32 i=0; i < pStr.size(); i++)
	{
		if((uint8)pStr.at(i) > 128)
		{
			i += 1;
		}
		else
		{
			ignoreC = true;
			break;
		}
		num++;
	}
	if(ignoreC)
		return false;
	if(num < 2)
		return false;
	return true;
}

bool CheckPersonalID(const char *pID)
{
	if(pID == NULL)
		return false;
	uint32 len = strlen(pID);
	if(len != 15 && len != 18)
		return false;
	string ID = pID;
	const int bitVal[17] = {7,9,10,5,8,4,2,1,6,3,7,9,10,5,8,4,2};
	const char checkBit[11] = {'1','0','X','9','8','7','6','5','4','3','2'};
	if(len == 15)
	{
		for(uint32 i=0; i < len; i++)
		{
			if(pID[i] < '0' || pID[i] > '9')
				return false;
		}
		int year = atoi(ID.substr(6,2).c_str());
		int month = atoi(ID.substr(8,2).c_str());
		int day = atoi(ID.substr(10,2).c_str());
		if(year < 1 || year > 90)
			return false;
		if(month < 1 || month > 12)
			return false;
		if(day < 1 || day > 31)
			return false;
		return true;
	}
	else if(len == 18)
	{
		int sum = 0;
		char checkCode = pID[17];
		if(checkCode == 'x' || checkCode == 'X')
			checkCode = 'X';
		else if(checkCode < '0' || checkCode > '9')
			return false;
		for(uint32 i=0; i < 17; i++)
		{
			if(pID[i] < '0' || pID[i] > '9')
				return false;
			else
				sum += ((int)(pID[i] - '0'))*bitVal[i];
		}
		int month = atoi(ID.substr(10,2).c_str());
		int day = atoi(ID.substr(12,2).c_str());
		if(month < 1 || month > 12)
			return false;
		if(day < 1 || day > 31)
			return false;
		if(checkBit[sum%11] != checkCode)
			return false;
		return true;
	}
	return false;
}


uint8 GetHuoYueTaskState(uint32 data)
{
	return (uint8)(data>>16);
}

uint32 GetHuoYueTaskInfo(uint32 data)
{
	return data & 0x0000ffff;
}

uint32 UpdateHuoYueTaskState(uint32 data)
{
	return data | (1 << 16);
}

uint32 GetHuoYueTaskCompleteCount(CUser *pUser)
{
	uint32 count = 0;

	if (pUser != NULL)
	{
		for (int i = 0; i < HUOYUE_MAX_TASK; i++)
		{
			if (GetHuoYueTaskState(pUser->GetExtData32(HUOYUE_TASK_DATA_ID[i])) > 0)
			{
				count++;
			}
		}
	}
	
	return count;
}

string GetQinMiStr(uint32 role1,uint32 role2)
{
	char buf[128];
	if(role1 < role2)
		snprintf(buf,sizeof(buf),"%u|%u",role1,role2);
	else
		snprintf(buf,sizeof(buf),"%u|%u",role2,role1);
	return buf;
}

void GetQinMiRoleId(string &str,uint32 &role1,uint32 &role2)
{
	char buf[128];
	char *split[2];
	role1 = 0;
	role2 = 0;
	snprintf(buf,sizeof(buf),"%s",str.c_str());
	if(SplitLine(split,2,buf) == 2)
	{
		role1 = atoi(split[0]);
		role2 = atoi(split[1]);
	}
}

void AddRoleTitle(uint32 roleId,int titleId)
{
	if(roleId == 0 || titleId < 1)
		return;
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	ShareUserPtr ptr = onlineUser.GetUserByRoleId(roleId);
	if(ptr.get() != NULL)
	{
		ptr->AddTitle(titleId);
	}
	else
	{
		CUser *pUser = new CUser;
		auto_ptr<CUser> user(pUser);
		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		if(pDb == NULL)
			return;
		char sql[4096];
		snprintf(sql,sizeof(sql),"select title from role_info where id=%u",roleId);
		if(!pDb->Query(sql))
			return;
		char **row = pDb->GetRow();
		if(row == NULL)
			return;
		pUser->ReadTitle(row[0]);
		pUser->AddTitle(titleId);
		string str;
		pUser->GetTitleStr(str);
		snprintf(sql,sizeof(sql),"update role_info set title='%s' where id=%u",str.c_str(),roleId);
		pDb->Query(sql);
	}
}

void DeleteRoleTitle(uint32 roleId, int titleId)
{
	if (roleId == 0 || titleId < 1)
		return;
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	ShareUserPtr ptr = onlineUser.GetUserByRoleId(roleId);
	if (ptr.get() != NULL)
	{
		ptr->DelTitle(titleId);
	}
	else
	{
		CUser *pUser = new CUser;
		auto_ptr<CUser> user(pUser);
		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		if (pDb == NULL)
			return;
		char sql[4096];
		snprintf(sql, sizeof(sql), "select title from role_info where id=%u", roleId);
		if (!pDb->Query(sql))
			return;
		char **row = pDb->GetRow();
		if (row == NULL)
			return;
		pUser->ReadTitle(row[0]);
		pUser->DelTitle(titleId);
		string str;
		pUser->GetTitleStr(str);
		snprintf(sql, sizeof(sql), "update role_info set title='%s' where id=%u", str.c_str(), roleId);
		pDb->Query(sql);
	}
}

void ShowSpecialCartoon(int op,int type)
{
	CNetMessage msg;
	msg.SetType(MSG_SPECIAL_CARTOON);
	msg<<op<<type;

	CSocketServer &sock = SingletonSocket::instance();
	SingletonOnlineUser::instance().ForEachUser(boost::bind(SendNianShouInfo,&sock,&msg,_1));
}

int GetMoGuCurrentDayIdx(uint32 startTime)
{
	if(startTime == 0xffffffff || startTime == 0)
		return 0;
	
	uint32 curTime = GetSysTime();
	time_t start = startTime;
	time_t current = curTime;
	struct tm *pStart = localtime(&start);
	struct tm sTM = *pStart;
	sTM.tm_sec = 0;
	sTM.tm_min = 0;
	sTM.tm_hour = 0;
	time_t s = mktime(&sTM);
	struct tm *pCur = localtime(&current);
	struct tm cTM = *pCur;
	cTM.tm_sec = 0;
	cTM.tm_min = 0;
	cTM.tm_hour = 0;
	time_t e = mktime(&cTM);
	int dt = e - s;
	return dt/(24*3600) + 1;
}

void GetZhunXianGeLvUpInfo(int nextLv,int &yingxiangli,int &money,int &ratio)
{
	// 影响力，帮派资金，成功率
	const int NeedLvUp[][3] = {{0,240,1},{0,360,2},{5200,600,3},{12480,1440,4},{16380,1890,5},
		{19500,2250,6},			{22620,2610,7},			{25740,2970,8},		{28080,3240,9},		{31200,3600,10},
		{65520,7560,11},	{85995,9922,12},	{102375,11812,13},	{118755,13702,14},	{135135,15592,15},
		{147420,17010,16},	{163800,18900,17},	{360360,41580,18},	{524160,60480,19},	{753480,86940,20}};
	int size = sizeof(NeedLvUp)/sizeof(NeedLvUp[0]);
	yingxiangli = 0;
	money = 0;
	ratio = 0;

	if(nextLv < 1 || nextLv > size)
		return;
	yingxiangli = NeedLvUp[nextLv-1][0];
	money = NeedLvUp[nextLv-1][1];
	ratio = NeedLvUp[nextLv-1][2];
}

int GetZXG_MaxMissionNum(int lv)
{
	// lv,num
	const int MissionData[][2] = {{0,0},{1,0},{2,3},{3,3},{4,4},{5,4},{6,5},{7,5},{8,6},{9,6},{10,8},
		{11,8},{12,10},{13,10},{14,12},{15,12},{16,15},{17,15},{18,18},{19,18},{20,18}};
	if(lv < 0)
		return 0;
	if(lv > 20)
		lv = 20;
	return MissionData[lv][1];
}

string GetShangXianTypeName(int type)
{
	if(type == 1)
		return LANGUAGE_TRANSFORM_2567;
	else if(type == 2)
		return LANGUAGE_TRANSFORM_2564;
	else if(type == 3)
		return LANGUAGE_TRANSFORM_2570;
	else if(type == 4)
		return LANGUAGE_TRANSFORM_2576;
	else if(type == 5)
		return LANGUAGE_TRANSFORM_2568;
	else if(type == 6)
		return LANGUAGE_TRANSFORM_2565;
	else if(type == 7)
		return LANGUAGE_TRANSFORM_2573;
	else if(type == 8)
		return LANGUAGE_TRANSFORM_2566;
	else if(type == 9)
		return LANGUAGE_TRANSFORM_2569;
	else if(type == 10)
		return LANGUAGE_TRANSFORM_2571;
    return "";
}

void CreateMiJingBossBuff(int buffNum,vector<uint16> &buffList)
{
	const uint16 BUFF_ID_1[] = {29,30,31};	// 御守,神佑,克己
	const uint16 BUFF_ID_2[] = {1001,1002,1003};	// 压制,狂暴,威慑
	int size1 = sizeof(BUFF_ID_1)/sizeof(BUFF_ID_1[0]);
	int size2 = sizeof(BUFF_ID_2)/sizeof(BUFF_ID_2[0]);
	buffList.clear();
	if(buffNum < 1 || buffNum > 3)
	{
		for(int i=0;i < 6;i++)
			buffList.push_back(0);
		return;
	}

	uint16 buff_id[6];
	memset(buff_id,0,sizeof(buff_id));
	for(int i=0;i < buffNum;i++)
	{
		buff_id[i*2] = BUFF_ID_1[Random(1,size1)-1];
		buff_id[i*2+1] = BUFF_ID_2[Random(1,size2)-1];
	}
	if(buffNum >= 2)
	{
		if(buff_id[0] == buff_id[2] && buff_id[1] == buff_id[3])
		{
			for(int j=0;j < size2;j++)
			{
				if(buff_id[3] != BUFF_ID_2[j])
				{
					buff_id[3] = BUFF_ID_2[j];
					break;
				}
			}
		}
	}
	if(buffNum == 3)
	{
		for(int i=0;i < 200;i++)
		{
			if((buff_id[0] == buff_id[4] && buff_id[1] == buff_id[5]) || (buff_id[2] == buff_id[4] && buff_id[3] == buff_id[5]))
			{
				buff_id[4] = BUFF_ID_1[Random(1,size1)-1];
				buff_id[5] = BUFF_ID_2[Random(1,size2)-1];
			}
			else
				break;
		}
	}
	int r = Random(1,3)-1;
	if(buffNum == 1)
	{
		for(int i=0;i < 3;i++)
		{
			if(i == r)
			{
				buffList.push_back(buff_id[0]);
				buffList.push_back(buff_id[1]);
			}
			else
			{
				buffList.push_back(0);
				buffList.push_back(0);
			}
		}
	}
	else if(buffNum == 2)
	{
		int count = 0;
		for(int i=0;i < 3;i++)
		{
			if(i == r)
			{
				buffList.push_back(0);
				buffList.push_back(0);
			}
			else
			{
				buffList.push_back(buff_id[count*2]);
				buffList.push_back(buff_id[count*2+1]);
				count++;
			}
		}
	}
	else if(buffNum == 3)
	{
		for(int i=0;i < buffNum;i++)
		{
			buffList.push_back(buff_id[i*2]);
			buffList.push_back(buff_id[i*2+1]);
		}
	}
}

const char *GetFuBenName(int copyId)
{
	ERiChangFuBen *pFuben = SingletonCRiChangFuBenManager::instance().FindFuBen(copyId);
	if(pFuben == NULL)
		return NULL;
	return pFuben->name.c_str();
}

void ReplaceString(const string & src, string & out, vector<SReplaceStringData> &para)
{
	if(src.empty() || para.empty())
		return;

	out = src;
	for(uint16 i=0;i < para.size();i++)
	{
		SReplaceStringData &data = para[i];
		for(string::size_type pos=0; pos != string::npos && pos < out.length(); pos += data.replaceString.length())
		{
			if((pos = out.find(data.key,pos)) != string::npos)
				out.replace(pos,data.key.length(),data.replaceString);
			else
				break;
		}
	}
}

void GetTeamMemberList(CUser *pHead,vector<ShareUserPtr> &pMem)
{
	if (pHead == NULL)
		return;
	CScene *pScene = pHead->GetScene();
	if(pScene != NULL)
		pScene->GetTeamMemberList(pHead,pMem);
}

void SendLeaveTeamMsg(CUser *pUser)
{
	if(pUser == NULL)
		return;
	CNetMessage msg;
	msg.SetType(PRO_USER_TEAM);
	msg<<(uint8)9;
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void GetCMissionPara(vector<int> &var,vector<string> &str,const char *pInts,const char *pStrs)
{
	var.clear();
	str.clear();
	if(pInts == NULL || pStrs == NULL)
		return;

	char buf[1024];
	int num = 0;
	char *p[100];
	if(strlen(pInts) > 0)
	{
		strncpy(buf,pInts,sizeof(buf));
		num = SplitLine(p,buf,'|');
		for(int i=0;i < num;i++)
		{
			if(strlen(p[i]) > 0)
				var.push_back(atoi(p[i]));
		}
	}
	if(strlen(pStrs) > 0)
	{
		strncpy(buf,pStrs,sizeof(buf));
		num = SplitLine(p,buf,'|');
		for(int i=0;i < num;i++)
		{
			string value = p[i];
			str.push_back(value);
		}
	}
}

bool SetAttrData(vector<SAttrData> &data,string &str)
{
	data.clear();
	if(str.empty())
		return true;

	char buf[2048];
	int num = 0;
	char *p[200];
	strncpy(buf,str.c_str(),sizeof(buf));
	num = SplitLine(p,buf,';');
	for(int i=0;i < num;i++)
	{
		char tbuf[64];
		int tnum = 0;
		char *tp[2];
		strncpy(tbuf,p[i],sizeof(tbuf));
		tnum = SplitLine(tp,tbuf,'-');
		if(tnum != 2)
		{
			cout<<"SetAttrData() error , str = "<<str;
			return false;
		}

		SAttrData v;
		v.attrType = atoi(tp[0]);
		v.attrValue = atoi(tp[1]);
		data.push_back(v);
	}
	return true;
}

bool SetAwardData(vector<SAwardData> &reward,string &str)
{
	if(str.empty())
		return true;
	
	char buf[2048];
	char subbuf[128];
	int num = 0;
	int subnum = 0;
	char *p[100];
	char *subp[10];

	strncpy(buf,str.c_str(),sizeof(buf));
	num = SplitLine(p,buf,';');
	for(int i=0;i< num;i++)
	{
		strncpy(subbuf,p[i],sizeof(subbuf));
		subnum = SplitLine(subp,subbuf,'-');
		int type = atoi(subp[0]);
		if((type == HDAT_PET && subnum != 4)
			|| (type == HDAT_PetEquip && subnum != 3)
			|| (type != HDAT_PET && type != HDAT_PetEquip && subnum != 2))
		{
			cout<<">> SetAwardData  error... str="<<str<<endl;
			continue;
		}
		SAwardData data;
		data.type = type;
		if (subnum == 2)
		{
			data.typeId = 0;
			data.num = atoi(subp[1]);
		}
		else
		{
			data.typeId = atoi(subp[1]);
			data.num = atoi(subp[2]);
		}
		reward.push_back(data);
	}
	return true;
}

int GetAttrValue(vector<SAttrData> &attrList,uint16 type)
{
	if(attrList.empty())
		return 0;
	for(uint16 i=0;i < attrList.size();i++)
	{
		if(attrList[i].attrType == type)
		{
			return attrList[i].attrValue;
		}
	}
	return 0;
}

void AddToAttrList(vector<SAttrData> &tarAttr,SAttrData &src)
{
	bool isFind = false;
	for(uint16 j=0;j < tarAttr.size();j++)
	{
		SAttrData &tar = tarAttr[j];
		if(src.attrType == tar.attrType)
		{
			tar.attrValue += src.attrValue;
			isFind = true;
			break;
		}
	}
	if(!isFind)
	{
		tarAttr.push_back(src);
	}
}

void MergeAttrList(vector<SAttrData> &tarAttr,vector<SAttrData> &srcAttr)
{
	for(uint16 i=0;i < srcAttr.size();i++)
	{
		SAttrData &src = srcAttr[i];
		bool isFind = false;
		for(uint16 j=0;j < tarAttr.size();j++)
		{
			SAttrData &tar = tarAttr[j];
			if(src.attrType == tar.attrType)
			{
				tar.attrValue += src.attrValue;
				isFind = true;
				break;
			}
		}
		if(!isFind)
		{
			tarAttr.push_back(src);
		}
	}
}

void MergeAwardData(vector<SAwardData> &tarAward,SAwardData &src)
{
	if(src.type == 0 || src.num == 0)
		return;
	bool isFind = false;
	for(uint16 j=0;j < tarAward.size();j++)
	{
		SAwardData &tar = tarAward[j];
		if(src.type == tar.type && src.typeId == tar.typeId)
		{
			tar.num += src.num;
			isFind = true;
			break;
		}
	}
	if(!isFind)
	{
		tarAward.push_back(src);
	}
}

void MergeAwardList(vector<SAwardData> &tarAward,vector<SAwardData> &srcAward)
{
	for(uint16 i=0;i < srcAward.size();i++)
	{
		MergeAwardData(tarAward,srcAward[i]);
	}
}

bool SetCostData(vector<SCostData> &data,string &str)
{
	data.clear();
	if(str.empty())
		return true;
	
	char buf[2048];
	int num = 0;
	char *p[100];
	strncpy(buf,str.c_str(),sizeof(buf));
	num = SplitLine(p,buf,';');
	for(int i=0;i < num;i++)
	{
		char tbuf[128];
		int tnum = 0;
		char *tp[10];
		strncpy(tbuf,p[i],sizeof(tbuf));
		tnum = SplitLine(tp,tbuf,'-');

		SCostData cost;
		cost.costType = atoi(tp[0]);
		if(cost.costType < HDAT_MONEY || cost.costType == HDAT_MONEY || cost.costType == HDAT_QIANNENG 
			|| cost.costType == HDAT_YB || cost.costType == HDAT_BANG_YB || cost.costType == HDAT_BANGPAI_MONEY || cost.costType == HDAT_BANG_GONG)
		{
			if(tnum != 2)
			{
				cout<<">> SetCostData() cost error ... str="<<str<<endl;
				return false;
			}
			cost.costValue = atoi(tp[1]);
		}
		else
		{
			cout<<">> SetCostData() cost error type... str="<<str<<endl;
			return false;
		}
		data.push_back(cost);
	}
	return true;
}

const char *GetEquipAttrName(uint16 type)
{
	return SingletonCAttrCfgMgr::instance().GetTypeName(type);
}

int GetCuiLianAttrStar(int value,int maxValue)
{
	const int CUI_LIAN_STAR_RATIO[] = {530,1288,2046,2803,3570,4773,6023,7348,8637,10000};
	int starRatio = value*10000/maxValue;
	int star = 1;
	for(uint8 i=0;i < sizeof(CUI_LIAN_STAR_RATIO)/sizeof(CUI_LIAN_STAR_RATIO[0]);i++)
	{
		if(starRatio <= CUI_LIAN_STAR_RATIO[i])
		{
			star = i+1;
			break;
		}
	}
	return star;
}

const char* GetPetQualityStr(int petId)
{
	int quality = GetPetDefaultQuality(petId);
	switch (quality)
	{
	case 1:
		return "A";

	case 2:
		return "S";

	case 3:
	case 4:
	case 5:
	case 6:
		return "SS";

	case 7:
	case 8:
		return "SSS";

	default:
		break;
	}
	return "";
}

int GetPetQualityColor(int petId)
{
	int quality = GetPetDefaultQuality(petId);
	return GetQualityColor(quality);
}

void MakeAwardString(int type, int value, string& outString)
{
	if (type == 0 || value == 0)
	{
		return;
	}
	char buf[256];
	if (outString.size() == 0)
		outString += ", ";

	switch (type)
	{
	case HDAT_PET:
		snprintf(buf, sizeof(buf), "[c%d]%s•%s[/c]", PetQualityColor[PQT_PURPLE], GetPetQualityStr(value), GetPetName(value));
		break;

	default:
		snprintf(buf, sizeof(buf), ", [c%d]%s*%d[/c]", ITEM_NAME_COLOR, GetItemName(type), value);
		break;
	}

	outString += buf;
}

void MakeChatByChannel(CNetMessage &msg,uint8 channel,const char *str)
{
	if(str == NULL)
		return;
	msg.ReWrite();
	msg.SetType(PRO_CHAT_CHANNEL);
	msg<<channel<<str;
}


string MakePetColorStr(uint16 petId)
{
	char buf[128];
	snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0063, GetPetQualityColor(petId), GetPetName(petId));
	return buf;
}


void SaveChatLog(CUser    *pUser,int channel,const char *pStr)
{
	if(pUser == NULL || pStr == NULL)
		return;
	char sql[1024];
	snprintf(sql,sizeof(sql),"insert into chat_log (role_id,channel,name,vip,msg) values(%d,%d,'%s',%d,'%s')",
		pUser->GetRoleId(),channel,pUser->GetName(),(int)pUser->GetVipLevel(),pStr);
	SendLongQuerySql(sql);
}


string MakeJiHuoMa(int type)
{
	const int DICT_SIZE = 32;
	char AwardCodeDict[DICT_SIZE] = { 'A','B','C','D','E','F','G','H','J',
		'K','M','N','P','Q','R','S','T','U',
		'V','W','X','Y','Z',
		'1','2','3','4','5','6','7','8','9' };

	string str = "";
	if (type == 1)
	{
		// 反利
		str = "JZ";
	}
	else if (type == 2)
	{
		str = "WZ";
	}
	for (int i=0; i < 10; ++i)
	{
		str += AwardCodeDict[Random(0, 31)];
	}
	return str;
}

uint32 MakeUniqueId(CUser* pUser, int type)
{
	uint32 year = GetYear() << 24;
	uint32 mon = GetMonth() << 20;
	uint32 day = GetDay() << 15;
	uint32 data16Id = 0;
	switch (type)
	{
	case EIT_PET:
		data16Id = ED16_68;
		break;

	case EIT_FABAO:
		data16Id = ED16_70;
		break;
	
	default:
		return 0;
	}
	uint16 idx = pUser->GetExtData16(data16Id) + 1;
	pUser->SetExtData16(data16Id, idx);
	return ((year | mon) | day) | idx;
}

void CreateFightById()
{

}

int SaveFightNetMsg(CNetMessage &msg, int type, uint32 roleId, uint32 tarRoleId, string notice)
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return 0;
	
	string tarStr;
	string *pData = msg.GetMsgData();
	if(pData == NULL)
		return 0;
	if(!Compress((uint8 *)(pData->c_str()), msg.GetDataLen(), tarStr))
		return 0;
	int len = 512 + tarStr.length();
	char *p = new char[len];
	if(p == NULL)
		return 0;
	snprintf(p, len, "insert into fight_playback (type, role_id, tar_role_id, fightMsg, notice, time) values(%d, %u, %u, '%s', '%s', %u)", 
		type, roleId, tarRoleId, tarStr.c_str(), notice.c_str(), (uint32)GetSysTime());
	if(!pDb->Query(p))
		return 0;
	delete []p;
	return pDb->InsertId();
}

bool DecodeFightPlayData(CNetMessage &msg, const char *pStr)
{
	if(pStr == NULL)
		return false;

	const int MAX_LEN = 1024*800;	// 800k
	uint8 *buf = new uint8[MAX_LEN];
	int len = UnCompressEx(pStr, buf, MAX_LEN-1);
	if(len == 0)
	{
		cout<<">>> DecodeFightPlayData Error, buff is small... "<<endl;
		delete []buf;
		return false;
	}
	msg.SetData(buf, len);
//	uint8 op = 4;
//	msg.WriteData(msg.GetHeadLen(), &op, sizeof(op));
	delete []buf;
	return true;
}

bool GetFightNetMsgFromDB(CNetMessage &msg, int fightId)
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return false;
	char sql[512];
	snprintf(sql, sizeof(sql), "select fightMsg from fight_playback where id=%d", fightId);
	if(!pDb->Query(sql))
		return false;
	char **row = NULL;
	if((row = pDb->GetRow()) == NULL)
		return false;
	return DecodeFightPlayData(msg, row[0]);
}

void PlayFightCG(CUser *pUser, int id)
{
	if(pUser == NULL)
		return;
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
	char sql[512];
	snprintf(sql, sizeof(sql), "select fightMsg from fight_cg where id=%d", id);
	if(!pDb->Query(sql))
		return;
	char **row = NULL;
	if((row = pDb->GetRow()) == NULL)
		return;
	
	CNetMessage msg;
	if(!DecodeFightPlayData(msg, row[0]))
		return;
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

bool CheckUserCond(CUser* pUser, TypeValue& tv)
{
	bool can = false;
	switch (tv.type)
	{
	case 1:
		if (pUser->GetLevel() >= tv.value)
			can = true;
		break;
	case 2:
		if (pUser->GetVipLevel() >= tv.value)
			can = true;
		break;
	case 3:
	{
		CUserBloodFight * bf = pUser->GetBloodFight();
		if (bf == NULL)
			return false;
		if (bf->GetMaxFloor() >= tv.value)
			can = true;
		break;
	}
	case 4:
	{
		CUserBloodFight * bf = pUser->GetBloodFight();
		if (bf == NULL)
			return false;
		if (bf->GetMaxHardFloor() >= tv.value)
			can = true;
		break;
	}
	case 5:
		if (pUser->GetRegDay() >= (int)tv.value)
			can = true;
		break;
	case 6:
		if (pUser->GetExtData32(ED32_JingJiZuiGaoMing) <= tv.value)
			can = true;
		break;
	case 8:
	{
		CGuanQiaCfgMgr& mgr = sCGuanQiaCfgMgr;
		uint32 nodeId = tv.value;
		uint32 mapId = mgr.GetNodeMapId(nodeId);
		MapNodeCfg* cfg = mgr.GetMapNodeCfg(mapId, nodeId);
		if (cfg != NULL)
		{
			CUserGuanQia& gq = pUser->GetGuanQia();
			can = gq.GetNodeStar(1, mapId, nodeId) > 0;
		}
		break;
	}
	}
	return can;
}

bool CheckUserCond(CUser* pUser, MultiTypeValue& tvs)
{
	if (tvs.empty())
		return true;
	bool can = false;
	for (size_t i = 0; i < tvs.size(); i++)
	{
		TypeValue& tv = tvs[i];
		can = CheckUserCond(pUser, tv);
		if (can)
			break;
	}
	return can;
}

string MakeColorString(int quality, const string& inStr)
{
	char buf[128];
	snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0219, GetQualityColor(quality), inStr.c_str());
	return buf;
}

void UpdateUserRecord(uint32 roleId, uint32 type, uint32 typeId, uint32 typeValue, bool isUpdate/* = false*/)
{
	char buf[256];
	if (isUpdate)
	{
		snprintf(buf, sizeof(buf), "UPDATE `user_record_log` SET `type_value`=%u " \
			"WHERE  `role_id`=%u and `type`=%u and `type_id`=%u", typeValue, roleId, type, typeId);
	}
	else
	{
		snprintf(buf, sizeof(buf), "INSERT INTO `user_record_log` (`role_id`, `type`, `type_id`, `type_value`)"\
			"VALUES (%u, %u, %u, %u)", roleId, type, typeId, typeValue);
	}
	SendLongQuerySql(buf);
}

void SMailData::AddAward(uint16 type, uint16 typeId, uint32 num)
{
	SAwardData award;
	award.type = type;
	award.typeId = typeId;
	award.num = num;
	MergeAwardData(awards, award);
}
