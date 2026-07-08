#ifndef _MAIN_CLASS_H_
#define _MAIN_CLASS_H_

#include "pack_deal.h"
#include "singleton.h"
#include <string>
#include "self_typedef.h"

class CUser;

struct SServerBasicCfg
{
	SServerBasicCfg()
	{
		port = 0;
		dbId = 0;
		long_port = 0;
		match_port = 0;
		longHost.clear();
		matchHost.clear();
		server_type.clear();
		version.clear();
		dbHost.clear();
		dbPort.clear();
		dbName.clear();
		dbUser.clear();
		dbPwd.clear();
	}
	
	int port;
	int dbId;
	int long_port;
	int match_port;
	string longHost;
	string matchHost;
	string server_type;
	string version;
	string dbHost;
	string dbPort;
	string dbName;
	string dbUser;
	string dbPwd;
};

class CMainClass
{
public:
	CMainClass():m_despatch(SingletonDespatch::instance()),
		m_socketServer(SingletonSocket::instance()),
		m_fightMgr(SingletonFightManager::instance()),
		m_onlineUser(SingletonOnlineUser::instance()),
		m_thread(NULL)
	{
		m_inBaihua = false;
		m_addMonster = 0;
	}
	bool Init(const SServerBasicCfg &cfg);
	void Run();
	void UserLogOut(CUser *pUser)
	{
		packDeal.UserLogout(pUser);
	}
	void SendGongGao(int sock);
	void SendSysInfo(CNetMessage *msg,CUser *pUser);
	const char *GetCZGongGao()
	{
		return m_cxGongGao.c_str();
	}
	void ChongZhiSuccess(int ad,int type,int serverId,uint32 userId,uint32 roleId,int money,const char *msg);
private:
	void ShopMysteryItemTimer();
	void ShopYaoShiItemTimer();
	void ShopShenhunItemTimer();

	void ArenaTimer();
	void WorldLevelTimer();
	void TongTianTaTimer();
	void KunLunShanTimer();
	void KunLunShanTeamTimer();	
	void KuaFu1V1Timer();
	void FeiXianTimer();
	void TreasureTimer();
	void XunChaShiTimer();
	void LingQiJuanXianTimer();
	void HuSongShenShouTimer();
	void PetDrawTimer();
	void ZhengDianZaiXianLiBaoTimer();
	void XinShiClear();
	void KaiFuChongJiSaiTimer(); // 开服冲级赛
	void XinFuZhanLiBangTimer(); // 新服战力榜
	void ZuiQiangShenChongBangTimer(); //最强神将榜
	void XianJiaQiangHuaBangTimer(); // 仙甲强化榜
	void DengJiChongCiBangTimer();  // 等级冲刺榜
	void QunXianZhanLiBangTimer(); // 群仙战力榜
	void XinFuChongZhiBangTimer();  // 新服充值榜
	void FestivalBangTimer();  // 节日榜
	void WingBangTimer();  // 神级羽翼榜
	void QiangHongBaoTimer(); //抢红包

    bool LoadChongZhiDang();
	void BaiHuaTimer();	// 百花仙子
	void NianshouTimer();	// 年兽
	void ShuangBeiTimer(); //双倍
	void BangPaiLueDuoTimer(); //帮派掠夺
	void SpiritTimer(); //体力补充
	void SendDaTiHuoDong(CSocketServer *pSock, CNetMessage *pMsg, CUser *pUser, int limitLv = 0);
	void LeiTaiSaiHuoDong(); // 擂台赛活动
	void TrySendLeiTaiHuoDong(CSocketServer *pSock,CNetMessage *pMsg,CUser *pUser); // 尝试发送擂台赛活动，包含校验
	void ShuangGuWuXianShi();
	//13:00-13:30,20:00-20:30

	void InitMonster(SVisibleMonster &monster,uint8 x,uint8 y);

	void DuoRenChuangGuan(); // 多人闯关
	void FishHuoDong(); // 钓鱼

	void IdleThread();
	void ChongZhi();
	bool ChongZhiToOtherSuccess(int roleId,SChongZhi2OtherAward &data);
	CUser* ReadUserSimpleData(int roleId);
	bool AddYuanBao(int serverId,uint32 userId,uint32 roleId,int tongbao,char *msg,uint8 type = 0,bool isShouChong = false,int money = 0);

	void SendMsgToUser();
	void TimeOut();
	void DealPackThread();
	void Join();
	CPackageDeal packDeal;
	CDespatchCommand &m_despatch;
	CSocketServer &m_socketServer;
	CFightManager &m_fightMgr;
	COnlineUser &m_onlineUser;
	boost::thread **m_thread;
	int m_threadNum;
	bool m_inBaihua;

	time_t m_addMonster;
	const static uint8 GONGGAO_GROUP_NUM = 2;

	time_t m_readMsgTime;
	CNetMessage m_GongGaoMsg;
	int m_sysInfoTimeSpace[GONGGAO_GROUP_NUM];
	time_t m_sendTime[GONGGAO_GROUP_NUM];
	vector<string> m_sysInfo[GONGGAO_GROUP_NUM];
	uint8 m_sendIdx[GONGGAO_GROUP_NUM];
	string m_cxGongGao;
};

// 竞技场排行相关函数
void CleanArenaPaiHang();

void SaveTongTianTa();
bool InitTongTianTa();

int KaiFuChongJiSaiGetReward(int rank); // 开服冲级赛 获取奖励
int XinFuZhanLiBangGetReward(int rank); // 新服战力榜 获取奖励

#ifdef _WIN32
#ifndef bzero
#define bzero(ptr, size) memset((ptr), 0, (size))
#endif
#endif

struct RandomBoxItem
{
	RandomBoxItem()
	{
		bzero(this,sizeof(*this));
	}
	uint32 box_id;
	uint32 item_id;
	uint32 odds;
	uint32 id;
	uint32 num;
	uint32 quality;
	uint32 quality_level;
	uint32 notice;
	uint32 day_limit;
};

struct SChongZhiData
{
	SChongZhiData()
	{
		dang = 0;
		fanLi = 0;
		firstFanLi = 0;
		itemId = 0;
		itemNum = 0;
		firstItemId = 0;
		firstItemNum = 0;
	}
	
	int type;
	int dang;
	int fanLi;
	int firstFanLi;
	int itemId;
	int itemNum;
	int firstItemId;
	int firstItemNum;
	int show_idx;
	int pic_idx;
};

int Connect(const char *ip,uint16 port);

#endif
