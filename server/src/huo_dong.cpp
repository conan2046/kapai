#include "huo_dong.h"
#include "singleton.h"
#include "scene_manager.h"
#include "script_call.h"
#include "call_script.h"
#include "init.h"
#include "chuangguan_reward_manager.h"
#include <boost/format.hpp>
#include "xml.h"

#include "rapidjson/document.h"
#include "rapidjson/prettywriter.h"
#include "rapidjson/filereadstream.h"
#include <algorithm>
#include "mission_manager.h"
#include "rank.h"
#include <time.h>

extern const char *gConfigFile;
const int ROLL_ZEROCD_VIP=8;

const int YOUYUANREN_NPC_POS[][3] = {
	{1,1231,525},{2,2059,386},{3,2149,986},{4,653,915},{5,556,1071},{6,1846,1114},{7,432,1146},{8,1278,261},{9,1841,1186},{10,1863,1041},
	{1,520,1223},{2,2112,869},{3,2168,668},{4,685,555},{5,884,874},{6,1580,888},{7,754,818},{8,977,303},{9,1477,1321},{10,1511,865},
	{1,1081,1154},{2,1765,1149},{3,1976,343},{4,951,261},{5,1168,756},{6,1378,1085},{7,1138,961},{8,725,497},{9,1327,1008},{10,1005,766},
	{1,1554,1257},{2,1331,1157},{3,1491,186},{4,1550,276},{5,1568,527},{6,994,1012},{7,1265,721},{8,1075,590},{9,1062,1288},{10,1485,527},
	{1,1883,1278},{2,666,1270},{3,1228,492},{4,2021,334},{5,2112,441},{6,503,858},{7,1597,1118},{8,821,878},{9,864,965},{10,1137,329},
	{1,2126,718},{2,580,813},{3,936,756},{4,1990,674},{5,2330,591},{6,462,582},{7,2181,907},{8,1021,986},{9,856,688},{10,658,567},
	{1,2153,553},{2,323,447},{3,654,1008},{4,2241,875},{5,1173,447},{6,1408,518},{7,520,687},{8,1664,800},{9,390,728},{10,1366,279},
	{1,613,353},{2,647,1078},{3,580,613},{4,1995,1102},{5,801,437},{6,1734,374},{7,688,332},{8,1941,538},{9,743,450},{10,660,978},
	{1,998,858},{2,1518,1005},{3,282,432},{4,1629,895},{5,2231,1029},{6,2016,303},{7,2273,707},{8,2332,327},{9,1227,211},{10,380,765},
	{1,2198,1036},{2,2191,617},{3,1403,467},{4,1218,897},{5,1723,1290},{6,2293,495},{7,1063,831},{8,1530,571},{9,1866,546},{10,1672,421}};

//活动排行榜使用类型
static const uint32 PAIHANG_TYPE[] = {CHuoDongAwardManager::XIANSHI_CHOU,CHuoDongAwardManager::SHENGDAN_FENGSHOU,CHuoDongAwardManager::XINCHUN_HAPPY,
									CHuoDongAwardManager::ZHENYING_PK,CHuoDongAwardManager::ZHENYING_PK1,CHuoDongAwardManager::ZHENYING_PK2,
									CHuoDongAwardManager::ZHOU_NIAN_QING_1};
//活动掉落使用类型
static const uint32 ITEMDROP_TYPE[] = {CHuoDongAwardManager::FESTIVAL,CHuoDongAwardManager::SHENGDAN_FENGSHOU,CHuoDongAwardManager::XINCHUN_HAPPY
										,CHuoDongAwardManager::ZHENYING_PK1,CHuoDongAwardManager::ZHENYING_PK2};
static const uint32 ITEMDROP_TYPE_NEW[] = {CHuoDongAwardManager::MEIRI_HUANHAOLI};

static time_t sZhanShenEnd;
//设置战神祝福
void SetZhanShen(time_t endTime)
{
	sZhanShenEnd = endTime;
}
bool InZhanShen()
{
	return sZhanShenEnd > GetSysTime();
}

// 增加鱼于鱼篓
void CFishData::AddFish(CUser* pUser,int fishId)
{
	if (pUser == NULL)
		return;

	// 向鱼篓中增加鱼
	for (int i = 0; i < CAPACITY; ++i)
	{
		if (m_fishList[i] == 0)
		{
			m_fishList[i] = fishId;
			return;
		}
	}

	// 鱼篓满了，移出第一条鱼，放入最后一条鱼
	int firstFishId = m_fishList[0];
	for (int i = 0; i < CAPACITY-1; ++i)
	{
		m_fishList[i] = m_fishList[i+1];
	}
	m_fishList[CAPACITY-1] = fishId;

	// 第一条鱼被发往玩家背包，背包满了自动发邮件
	if (fishId != 0)
		pUser->AddBangDingPackage(firstFishId,1);
}

// 删除鱼篓中的某条鱼
void CFishData::RemoveFish(int fishIdx)
{
	if (fishIdx > (CAPACITY-1))
		return;
	m_fishList[fishIdx] = 0;
	SortFish();
}

// 领取鱼篓中的某条鱼
void CFishData::GetFish(CUser* pUser,int fishIdx)
{
	if (pUser == NULL)
		return;
	if ((pUser->m_grabedTime != 0))
	{
		if ((GetSysTime() - pUser->m_grabedTime) < FISH_GRAB_TIMEOUT)
		{
			SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_32,TIPS_FAILURE_COLOR).c_str());
			return;
		}
		else
			pUser->m_grabedTime = 0;
	}
	if (fishIdx > (CAPACITY-1))
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_33,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	int fishId = m_fishList[fishIdx];
	m_fishList[fishIdx] = 0;
	if (fishId == 0)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_34,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	SaveDate(pUser, 38, fishId);
	pUser->AddBangDingPackage(fishId,1);
	char info[128];
	snprintf(info,sizeof(info),LANGUAGE_TRANSFORM_35,GetItemName(fishId));
	SendSysInfo(pUser,MakeStringColor(info,TIPS_WARNING_COLOR).c_str());
	SortFish();

	CNetMessage msg;
	msg.SetType(MSG_FISH);
	msg<<(uint8)CFishManager::EFOP_GetFish<<PRO_SUCCESS;
	CSocketServer &sock = SingletonSocket::instance();
	sock.SendMsg(pUser->GetSock(),msg);
}

// 获取鱼篓中的所有鱼
void CFishData::GetFishAll(CUser* pUser)
{
	if (pUser == NULL)
		return;
	for (int i = 0; i < CAPACITY; ++i)
	{
		if (m_fishList[i] == 0)
			break;
		pUser->AddBangDingPackage(m_fishList[i],1);
	}
}

// 获取钓鱼剩余时间
int CFishData::GetLeftFishTime()
{
	time_t curTime = GetSysTime();
	if ((m_fishTime + CFishData::FISH_TIME) > curTime)
	{
		return ((m_fishTime + CFishData::FISH_TIME) - curTime);
	}
	else
		return 0;
}

// 排序剔除零
void CFishData::SortFish()
{
	int usefulIdx = 0;
	for (int i = 0; i < CAPACITY; ++i)
	{
		if (m_fishList[i] != 0)
		{
			m_fishList[usefulIdx] = m_fishList[i];
			++usefulIdx;
			m_fishList[i] = 0;
		}
	}
}

// 复制构造函数 只是空房间而已
CFishRoom::CFishRoom(const CFishRoom& room)
{
	m_id = room.m_id;
	m_sceneId = room.m_sceneId;
}

// 玩家是否可以进入这个房间
bool CFishRoom::IsEnterable()
{
	boost::mutex::scoped_lock lk(m_freeManLMutex);
	return ((int)m_freeManL.size() < MAX_MAN);
}

// 玩家是否可以钓鱼
bool CFishRoom::IsFishable()
{
	boost::mutex::scoped_lock lk(m_fishDataLMutex);
	return ((int)m_fishDataL.size() < MAX_FISHER);
}

// 进入房间
void CFishRoom::EnterRoom(int roleId, const char* name)
{
	boost::mutex::scoped_lock lk(m_freeManLMutex);
	CFishData fishData;
	fishData.m_roleId = roleId;
	strncpy(fishData.m_name,name,MAX_NAME_LEN);
	m_freeManL.push_back(fishData);
}

// 是否是在钓鱼状态
bool CFishRoom::IsFisher(CUser* pUser)
{
	if (pUser == NULL)
		return ERS_ERR;
	return (ERS_FISHING == GetRoleState(pUser->GetRoleId()));
}

// 是否是在房间内
bool CFishRoom::IsInRoom(CUser* pUser)
{
	if (pUser == NULL)
		return ERS_ERR;
	return (ERS_ERR != GetRoleState(pUser->GetRoleId()));
}

// 同步玩家列表给所有房间内成员 user为空则同步全房间数据 不为空则为同步这个玩家给所有人，isadd为1是新增，0为减少
void CFishRoom::SyncPlayerList(CUser* pTarUser, int isAdd)
{
	int roleIds[MAX_MAN] = {0};
	memset(roleIds,0,sizeof(roleIds));
	int idx = 0;
	{
		boost::mutex::scoped_lock lk(m_freeManLMutex);
		for (itFreemManL_t it = m_freeManL.begin(); it != m_freeManL.end(); ++it)
		{
			if (idx >= MAX_MAN)
				break;
			if (it->m_roleId != 0)
			{
				roleIds[idx++] = it->m_roleId;
			}
		}
	}
	{
		boost::mutex::scoped_lock lk(m_fishDataLMutex);
		for (itFishDataL_t it = m_fishDataL.begin(); it != m_fishDataL.end(); ++it)
		{
			if (idx >= MAX_MAN)
				break;
			if (it->m_roleId != 0)
			{
				roleIds[idx++] = it->m_roleId;
			}
		}
	}
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	if (pTarUser == NULL)
	{
		for (int i = 0; i < MAX_MAN; ++i)
		{
			ShareUserPtr ptr = onlineUser.GetUserByRoleId(roleIds[i]);
			CUser* pUser = ptr.get();
			if (pUser == NULL)
				continue;
			GetPlayerList(pUser);
		}
		cout << LANGUAGE_TRANSFORM_36 << endl;
	}
	else
	{
		CSocketServer &sock = SingletonSocket::instance();
		CNetMessage msg;
		msg.SetType(MSG_FISH);
		msg<<(uint8)CFishManager::EFOP_UpdatePlayerList<<(uint8)isAdd<<pTarUser->GetRoleId()<<pTarUser->GetName();
		for (int i = 0; i < MAX_MAN; ++i)
		{
			ShareUserPtr ptr = onlineUser.GetUserByRoleId(roleIds[i]);
			CUser* pUser = ptr.get();
			if (pUser == NULL)
				continue;
			sock.SendMsg(pUser->GetSock(),msg);
		}
		//cout << "同步单人的进入信息！" << endl;
	}
}

// 同步玩家列表给所有房间内成员 user为空则同步全房间数据 不为空则为同步这个玩家给所有人，isadd为1是新增，0为减少
void CFishRoom::SyncFisherList(CUser* pTarUser, int isAdd)
{
	int roleIds[MAX_MAN] = {0};
	memset(roleIds,0,sizeof(roleIds));
	int idx = 0;
	{
		boost::mutex::scoped_lock lk(m_freeManLMutex);
		for (itFreemManL_t it = m_freeManL.begin(); it != m_freeManL.end(); ++it)
		{
			if (idx >= MAX_MAN)
				break;
			if (it->m_roleId != 0)
			{
				roleIds[idx++] = it->m_roleId;
			}
		}
	}
	{
		boost::mutex::scoped_lock lk(m_fishDataLMutex);
		for (itFishDataL_t it = m_fishDataL.begin(); it != m_fishDataL.end(); ++it)
		{
			if (idx >= MAX_MAN)
				break;
			if (it->m_roleId != 0)
			{
				roleIds[idx++] = it->m_roleId;
			}
		}
	}
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	if (pTarUser == NULL)
	{
		for (int i = 0; i < MAX_MAN; ++i)
		{
			ShareUserPtr ptr = onlineUser.GetUserByRoleId(roleIds[i]);
			CUser* pUser = ptr.get();
			if (pUser == NULL)
				continue;
			GetPlayerList(pUser);
		}
		cout << LANGUAGE_TRANSFORM_37 << endl;
	}
	else
	{
		CSocketServer &sock = SingletonSocket::instance();
		CNetMessage msg;
		msg.SetType(MSG_FISH);
		msg<<(uint8)CFishManager::EFOP_UpdateFisherList<<(uint8)isAdd<<pTarUser->GetRoleId()<<pTarUser->GetName();
		for (int i = 0; i < MAX_MAN; ++i)
		{
			ShareUserPtr ptr = onlineUser.GetUserByRoleId(roleIds[i]);
			CUser* pUser = ptr.get();
			if (pUser == NULL)
				continue;
			sock.SendMsg(pUser->GetSock(),msg);
		}
		//cout << "同步单人的进入信息！" << endl;
	}
}

// 获取房间渔夫数
int CFishRoom::GetFisherNum()
{
	boost::mutex::scoped_lock lk(m_fishDataLMutex);
	return m_fishDataL.size();
}

// 获取房间人数
int CFishRoom::GetManNum()
{
	int freeManLSize = 0;
	int fishDataLSize = 0;
	{
		boost::mutex::scoped_lock lk(m_freeManLMutex);
		freeManLSize = m_freeManL.size();
	}
	{
		boost::mutex::scoped_lock lk(m_fishDataLMutex);
		fishDataLSize = m_fishDataL.size();
	}
	return (freeManLSize + fishDataLSize);
}

// 开始钓鱼
void CFishRoom::StartFish(CUser* pUser,uint8 face)
{
	if (pUser == NULL)
		return;
	int roleId = pUser->GetRoleId();
	int state = GetRoleState(roleId);
	if (state == ERS_ERR)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_38,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	else if (state == ERS_FISHING)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_39,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	else if (state == ERS_FREE)
	{
		if (!IsFishable())
		{
			SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_40,TIPS_FAILURE_COLOR).c_str());
			return;
		}
		CFishData fishData;
		fishData.m_roleId = -1;
		{ // 将玩家移出自由人队列 获取鱼篓
			boost::mutex::scoped_lock lk(m_freeManLMutex);
			for (itFreemManL_t it = m_freeManL.begin(); it != m_freeManL.end(); ++it)
			{
				if (it->m_roleId == roleId)
				{
					fishData = *it; // 复制出来
					m_freeManL.erase(it);
					break;
				}
			}
		}
		if (fishData.m_roleId == -1)
		{
			SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_41,TIPS_FAILURE_COLOR).c_str());
			return;
		}
		{ // 将玩家加入钓鱼人队列
			boost::mutex::scoped_lock lk(m_fishDataLMutex);
			fishData.m_fishTime = GetSysTime();
			m_fishDataL.push_back(fishData);
		}
		pUser->m_fishState = ERS_FISHING;

		CNetMessage msg;
		msg.SetType(MSG_FISH);
		msg<<(uint8)CFishManager::EFOP_Fish<<PRO_SUCCESS<<CFishData::FISH_TIME<<face;
		CSocketServer &sock = SingletonSocket::instance();
		sock.SendMsg(pUser->GetSock(),msg);
		pUser->SetFace(face);

		CScene *pScene = pUser->GetScene();
		if(pScene == NULL)
			return;
		pScene->UpdateUserInfo(pUser,ESRT_Fish_State);
		SyncFisherList(pUser,1);
	}
}

// 停止钓鱼
void CFishRoom::StopFish(CUser* pUser)
{
	if (pUser == NULL)
		return;
	int roleId = pUser->GetRoleId();
	int state = GetRoleState(roleId);
	if (state != ERS_FISHING)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_42,TIPS_FAILURE_COLOR).c_str());
		return;
	}

	CFishData fishData;
	fishData.m_roleId = -1;
	{
		boost::mutex::scoped_lock lk(m_fishDataLMutex);
		for (itFishDataL_t it = m_fishDataL.begin(); it != m_fishDataL.end(); ++it)
		{
			if (it->m_roleId == roleId)
			{
				fishData = *it;
				m_fishDataL.erase(it);
				break;
			}
		}
	}
	if (fishData.m_roleId == -1)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_43,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	fishData.m_fishTime = 0;
	pUser->m_fishState = ERS_FREE;
	{
		boost::mutex::scoped_lock lk(m_freeManLMutex);
		m_freeManL.push_back(fishData);
	}

	CNetMessage msg;
	msg.SetType(MSG_FISH);
	msg<<(uint8)CFishManager::EFOP_StopFish<<PRO_SUCCESS;
	CSocketServer &sock = SingletonSocket::instance();
	sock.SendMsg(pUser->GetSock(),msg);

	CScene *pScene = pUser->GetScene();
	if(pScene == NULL)
		return;
	pScene->UpdateUserInfo(pUser,ESRT_Fish_State);
	SyncFisherList(pUser,0);
}

// 获取鱼篓数据
void CFishRoom::GetFishList(CUser* pUser, int tarRoleId)
{
	if (pUser == NULL)
		return;
	int roleId = pUser->GetRoleId();
	int state = GetRoleState(roleId);
	if (state == ERS_ERR)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_44,TIPS_FAILURE_COLOR).c_str());
		return;
	}

	CFishData* pFishData = GetFishData(tarRoleId);
	if (pFishData == NULL)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_45,TIPS_FAILURE_COLOR).c_str());
		return;
	}

	CNetMessage msg;
	msg.SetType(MSG_FISH);
	msg<<(uint8)CFishManager::EFOP_FishList<<tarRoleId;
	uint16 pos = msg.GetDataLen();
	uint8 num = 0;
	msg<<(uint8)0;
	for (int i = 0; i < CFishData::CAPACITY; ++i)
	{
		if (pFishData->m_fishList[i] != 0)
		{
			++num;
			msg<<pFishData->m_fishList[i];
		}
	}
	msg.WriteData(pos,&num,1);
	CSocketServer &sock = SingletonSocket::instance();
	sock.SendMsg(pUser->GetSock(),msg);
}

// 抢夺鱼篓
void CFishRoom::GrabFish(CUser* pUser, int tarRoleId, int tarFishIdx)
{
	if (pUser == NULL)
		return;
	int roleId = pUser->GetRoleId();
	int state = GetRoleState(roleId);
	if (state == ERS_ERR)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_46,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	if (roleId == tarRoleId)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_47,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	if (pUser->GetExtData8(63) >= MAX_GRAB_COUNT)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_48,TIPS_FAILURE_COLOR).c_str());
		return;
	}

	CFishData* pFishData = GetFishData(tarRoleId);
	if (pFishData == NULL)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_49,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	if (pFishData->m_fishList[tarFishIdx] == 0)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_50,TIPS_FAILURE_COLOR).c_str());
		return;
	}

	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	ShareUserPtr tarPtr = onlineUser.GetUserByRoleId(tarRoleId);
	CUser* pTarUser = tarPtr.get();
	if (pTarUser == NULL)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_51,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	/* // 玩家被抢夺保护次数去掉了
	if (pTarUser->GetExtData8(64) >= MAX_BE_GRABED_COUNT)
	{
	SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_52,TIPS_FAILURE_COLOR).c_str());
	return;
	}
	*/
	if (pTarUser->m_grabedTime != 0)
	{
		if ((GetSysTime() - pTarUser->m_grabedTime) < CFishData::FISH_GRAB_TIMEOUT)
		{
			SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_53,TIPS_FAILURE_COLOR).c_str());
			return;
		}
	}
	time_t curTime = GetSysTime();
	if ((pTarUser->m_grabedProtectTime != 0) && (curTime < pTarUser->m_grabedProtectTime))
	{
		time_t leftTime = pTarUser->m_grabedProtectTime - curTime;
		char info[128];
		snprintf(info,sizeof(info),LANGUAGE_TRANSFORM_54,(int)leftTime);
		SendSysInfo(pUser,MakeStringColor(info,TIPS_FAILURE_COLOR).c_str());
		return;
	}

	pTarUser->m_grabedTime = GetSysTime(); // 标记玩家正在被抢夺
	pUser->SetExtData8(65,tarFishIdx); // 要抢这个玩家鱼篓的那条鱼

	CScene* pScene = pUser->GetScene();
	if (pScene == NULL)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_55,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	pScene->GrabFishUserFight(pUser,tarRoleId);
}

// 成功抢夺对方鱼篓
int CFishRoom::GrabFishSuccess(CUser* pUser, int tarRoleId, int tarFishIdx)
{
	if (pUser == NULL)
		return 0;
	CFishData* pTarFishData = GetFishData(tarRoleId);
	if (pTarFishData == NULL)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_56,TIPS_FAILURE_COLOR).c_str());
		return 0;
	}
	int fishId = pTarFishData->m_fishList[tarFishIdx];
	pTarFishData->RemoveFish(tarFishIdx);
	if (fishId == 0)
		return 0;
	pUser->AddBangDingPackage(fishId,1);
	char info[128];
	snprintf(info,sizeof(info),LANGUAGE_TRANSFORM_57,GetItemName(fishId));
	SendSysInfoFightEnd(pUser,MakeStringColor(info,TIPS_WARNING_COLOR).c_str());
	return fishId;
}

// 领取某条鱼
void CFishRoom::GetFish(CUser* pUser, int fishIdx)
{
	if (pUser == NULL)
		return;
	int roleId = pUser->GetRoleId();
	int state = GetRoleState(roleId);
	if (state == ERS_ERR)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_58,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	CFishData* pFishData = GetFishData(roleId);
	if (pFishData == NULL)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_59,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	pFishData->GetFish(pUser,fishIdx);
}

void CFishRoom::ExitByUserLogout(CUser *pUser)
{
	if(pUser == NULL)
		return;
	// 收获鱼篓中的内容
	CFishData* pFishData = GetFishData(pUser->GetRoleId());
	if(pFishData != NULL)
		pFishData->GetFishAll(pUser);
	pUser->m_grabedTime = 0;
	pUser->m_fishSceneSrcId = 0;
	SyncFisherList(pUser,0);
	pUser->SetFishRoom(NULL); // 清除玩家对应的房间
	pUser->m_fishState = CFishRoom::ERS_ERR;

	SyncPlayerList(pUser,0); // 同步更新房间成员列表
	SingletonFishManager::instance().ExitSubPlayer();
	int roleId = pUser->GetRoleId();
	{
		boost::mutex::scoped_lock lk(m_freeManLMutex);
		for (itFreemManL_t it = m_freeManL.begin(); it != m_freeManL.end(); ++it)
		{
			if (it->m_roleId == roleId)
			{
				m_freeManL.erase(it);
				return;
			}
		}
	}
	{
		boost::mutex::scoped_lock lk(m_fishDataLMutex);
		for (itFishDataL_t it = m_fishDataL.begin(); it != m_fishDataL.end(); ++it)
		{
			if (it->m_roleId == roleId)
			{
				m_fishDataL.erase(it);
				return;
			}
		}
	}
}

// 退出房间 是否需要删除房间内角色的数据 返回删除的角色数
int CFishRoom::Exit(CUser* pUser, bool clearRoom)
{
	if (pUser == NULL)
		return 0;
	// 收获鱼篓中的内容
	CFishData* pFishData = GetFishData(pUser->GetRoleId());
	if (pFishData != NULL)
	{
		pFishData->GetFishAll(pUser);
	}
	pUser->m_grabedTime = 0;
	pUser->m_fishSceneSrcId = 0;
	pUser->SetFishRoom(NULL); // 清除玩家对应的房间
	pUser->m_fishState = CFishRoom::ERS_ERR;
	SyncFisherList(pUser, 0);
	pUser->ExitFuBen(); // 切换玩家到普通地图

	// 删除角色在房间中的数据
	if (clearRoom)
	{
		SyncPlayerList(pUser,0); // 同步更新房间成员列表
		SingletonFishManager::instance().ExitSubPlayer();
		//cout << "退出房间后，总人数：" << SingletonFishManager::instance().m_manNum << endl;
		int roleId = pUser->GetRoleId();
		{
			boost::mutex::scoped_lock lk(m_freeManLMutex);
			for (itFreemManL_t it = m_freeManL.begin(); it != m_freeManL.end(); ++it)
			{
				if (it->m_roleId == roleId)
				{
					m_freeManL.erase(it);
					return 1;
				}
			}
		}
		{
			boost::mutex::scoped_lock lk(m_fishDataLMutex);
			for (itFishDataL_t it = m_fishDataL.begin(); it != m_fishDataL.end(); ++it)
			{
				if (it->m_roleId == roleId)
				{
					m_fishDataL.erase(it);
					return 1;
				}
			}
		}
	}
	return 0;
}

// 切换房间的退出房间
int CFishRoom::SwitchExit(CUser* pUser)
{
	if (pUser == NULL)
		return 0;
	// 收获鱼篓中的内容
	CFishData* pFishData = GetFishData(pUser->GetRoleId());
	if (pFishData != NULL)
	{
		pFishData->GetFishAll(pUser);
	}
	pUser->SetFishRoom(NULL); // 清除玩家对应的房间
	//pUser->ExitFuBen(); // 切换玩家到普通地图

	// 删除角色在房间中的数据
	int roleId = pUser->GetRoleId();
	{
		boost::mutex::scoped_lock lk(m_freeManLMutex);
		for (itFreemManL_t it = m_freeManL.begin(); it != m_freeManL.end(); ++it)
		{
			if (it->m_roleId == roleId)
			{
				m_freeManL.erase(it);
				return 1;
			}
		}
	}
	{
		boost::mutex::scoped_lock lk(m_fishDataLMutex);
		for (itFishDataL_t it = m_fishDataL.begin(); it != m_fishDataL.end(); ++it)
		{
			if (it->m_roleId == roleId)
			{
				m_fishDataL.erase(it);
				return 1;
			}
		}
	}
	return 0;
}

// 清空房间
void CFishRoom::AllExit()
{
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	int playerList[MAX_MAN] = {0};
	memset(playerList,0,sizeof(playerList));
	int idx = 0;
	{
		boost::mutex::scoped_lock lk(m_freeManLMutex);
		for (itFreemManL_t it = m_freeManL.begin(); it != m_freeManL.end(); ++it)
		{
			playerList[idx++] = it->m_roleId;
		}
	}

	{
		boost::mutex::scoped_lock lk(m_fishDataLMutex);
		for (itFishDataL_t it = m_fishDataL.begin(); it != m_fishDataL.end(); ++it)
		{
			playerList[idx++] = it->m_roleId;
		}
	}
	for (int i = 0; i < idx; ++i)
	{
		ShareUserPtr ptr = onlineUser.GetUserByRoleId(playerList[i]);
		CUser* pUser = ptr.get();
		if (pUser == NULL)
			continue;
		Exit(pUser,false);
	}
	{
		boost::mutex::scoped_lock lk(m_freeManLMutex);
		m_freeManL.clear();
	}
	{
		boost::mutex::scoped_lock lk(m_fishDataLMutex);
		m_fishDataL.clear();
	}

	// 清除地图数据
	CSceneManager &sceneMgr = SingletonSceneManager::instance();
	CScene* pScene = sceneMgr.Find2Scene(m_sceneId,m_sceneId);
	if (pScene == NULL)
		return;
	pScene->Clear();
}

// 获取玩家列表
void CFishRoom::GetPlayerList(CUser* pUser)
{
	if (pUser == NULL)
		return;

	CNetMessage msg;
	msg.SetType(MSG_FISH);
	msg<<(uint8)CFishManager::EFOP_PlayerList<<(uint8)GetManNum();

	{
		boost::mutex::scoped_lock lk(m_freeManLMutex);
		for (itFreemManL_t it = m_freeManL.begin(); it != m_freeManL.end(); ++it)
		{
			msg<<it->m_roleId<<it->m_name;
		}
	}
	{
		boost::mutex::scoped_lock lk(m_fishDataLMutex);
		for (itFishDataL_t it = m_fishDataL.begin(); it != m_fishDataL.end(); ++it)
		{
			msg<<it->m_roleId<<it->m_name;
		}
	}

	CSocketServer &sock = SingletonSocket::instance();
	sock.SendMsg(pUser->GetSock(),msg);
}

// 获取玩家列表 只显示钓鱼的玩家列表
void CFishRoom::GetFisherList(CUser* pUser)
{
	if (pUser == NULL)
		return;

	CNetMessage msg;
	msg.SetType(MSG_FISH);
	msg<<(uint8)CFishManager::EFOP_FisherList<<(uint8)GetFisherNum();

	{
		boost::mutex::scoped_lock lk(m_fishDataLMutex);
		for (itFishDataL_t it = m_fishDataL.begin(); it != m_fishDataL.end(); ++it)
		{
			msg<<it->m_roleId<<it->m_name;
		}
	}

	CSocketServer &sock = SingletonSocket::instance();
	sock.SendMsg(pUser->GetSock(),msg);
}

// 同步钓鱼时间
void CFishRoom::SyncFishTime(CUser* pUser)
{
	if (pUser == NULL)
		return;
	CFishData* pFishData = GetFishData(pUser->GetRoleId());
	if (pFishData == NULL)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_60,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	CNetMessage msg;
	msg.SetType(MSG_FISH);
	msg<<(uint8)CFishManager::EFOP_FishTime<<pFishData->GetLeftFishTime();
	CSocketServer &sock = SingletonSocket::instance();
	sock.SendMsg(pUser->GetSock(),msg);	
}

// 获取玩家的鱼篓信息
CFishData* CFishRoom::GetFishData(int roleId)
{
	{
		boost::mutex::scoped_lock lk(m_fishDataLMutex);
		for (itFishDataL_t it = m_fishDataL.begin(); it != m_fishDataL.end(); ++it)
		{
			if (it->m_roleId == roleId)
			{
				return &(*it);
			}
		}
	}

	{
		boost::mutex::scoped_lock lk(m_freeManLMutex);
		for (itFreemManL_t it = m_freeManL.begin(); it != m_freeManL.end(); ++it)
		{
			if (it->m_roleId == roleId)
			{
				return &(*it);
			}
		}
	}
	return NULL;
}

// 获取玩家状态
int CFishRoom::GetRoleState(int roleId)
{
	{
		boost::mutex::scoped_lock lk(m_freeManLMutex);
		for (itFreemManL_t it = m_freeManL.begin(); it != m_freeManL.end(); ++it)
		{
			if (roleId == it->m_roleId)
				return ERS_FREE;
		}
	}

	{
		boost::mutex::scoped_lock lk(m_fishDataLMutex);
		for (itFishDataL_t it = m_fishDataL.begin(); it != m_fishDataL.end(); ++it)
		{
			if (roleId == it->m_roleId)
				return ERS_FISHING;
		}
	}
	return ERS_ERR;
}

// 是否是活动时间
bool CFishManager::IsInHuoDongTime()
{
	uint16 curTime = GetHour() * 100 + GetMinute();
	uint16 minTime = HUO_DONG_TIME * 100 + HUO_DONG_TIME_MIN;
	uint16 maxTime = HUO_DONG_TIME * 100 + HUO_DONG_TIME_MAX;
	return curTime >= minTime && curTime < maxTime;
}

// 发送错误信息
void CFishManager::SendErrorInfo(CUser* pUser, const char* info)
{
	if (pUser == NULL)
		return;
	if (info == NULL)
		return;

	CNetMessage msg;
	msg.SetType(MSG_FISH);
	msg<<(uint8)EFOP_ErrorInfo<<info;
	CSocketServer &sock = SingletonSocket::instance();
	sock.SendMsg(pUser->GetSock(),msg);
}

// 获取房间列表
void CFishManager::GetRoomList(CUser* pUser)
{
	if (pUser == NULL)
		return;
	if (!IsInHuoDongTime())
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_61,TIPS_FAILURE_COLOR).c_str());
		return;
	}

	int roomSize = 0;
	{
		boost::mutex::scoped_lock lk(m_fishRoomMMutex);
		roomSize = m_fishRoomM.size();
	}
	if (roomSize == 0)
		CheckCreateRoom();

	{
		boost::mutex::scoped_lock lk(m_fishRoomMMutex);
		CNetMessage msg;
		msg.SetType(MSG_FISH);
		msg<<(uint8)EFOP_RoomList<<(int)m_fishRoomM.size(); // 房间数量
		for (itFishRoomM_t it = m_fishRoomM.begin(); it != m_fishRoomM.end(); ++it)
		{
			msg<<it->first<<(uint8)it->second.GetManNum();
		}
		CSocketServer &sock = SingletonSocket::instance();
		sock.SendMsg(pUser->GetSock(),msg);
	}
}

// 加入房间
CFishRoom* CFishManager::JoinRoom(CUser* pUser, int roomId)
{
	if (pUser == NULL)
		return NULL;
	if (!IsInHuoDongTime())
	{
		char showInfo[128];
		snprintf(showInfo,sizeof(showInfo),LANGUAGE_TRANSFORM_62,HUO_DONG_TIME,HUO_DONG_TIME_MIN,(HUO_DONG_TIME+1));
		SendSysInfo(pUser,MakeStringColor(showInfo,TIPS_FAILURE_COLOR).c_str());
		return NULL;
	}
	if(pUser->HaveTeam())
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_63,TIPS_FAILURE_COLOR).c_str());
		return NULL;
	}
	/*if (pUser->GetLevel() < HUO_DONG_LEVEL)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_64,TIPS_FAILURE_COLOR).c_str());
		return NULL;
	}*/
	if(!CanJoinActivity(pUser))
		return NULL;
	if(pUser->GetFightId() > 0)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0481,TIPS_FAILURE_COLOR).c_str());
		return NULL;
	}
	if(!pUser->CanWorldTransPort(FISH_ID2))
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0475,TIPS_FAILURE_COLOR).c_str());
		return NULL;
	}

	CFishRoom* pRoom = pUser->GetFishRoom();
	if (pRoom != NULL)
	{
		// 这里应该是切换房间流程
		if ((roomId != 0) && (pRoom->m_id != roomId))
		{
			SwitchRoom(pUser,pRoom,roomId);
		}
		else
			SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_65,TIPS_FAILURE_COLOR).c_str());
		return NULL;
	}
	if (roomId == 0) // 自动进入房间
	{
		int roomSize = 0;
		{
			boost::mutex::scoped_lock lk(m_fishRoomMMutex);
			roomSize = m_fishRoomM.size();
		}
		if (roomSize == 0)
			CheckCreateRoom();

		{
			boost::mutex::scoped_lock lk(m_fishRoomMMutex);
			for (itFishRoomM_t it = m_fishRoomM.begin(); it != m_fishRoomM.end(); ++it)
			{
				if (it->second.GetManNum() < CFishRoom::MAX_FISHER)
				{
					pRoom = &(it->second);
					break;
				}
			}
		}
	}
	else // 自己选择要进入的房间
	{
		boost::mutex::scoped_lock lk(m_fishRoomMMutex);
		itFishRoomM_t it = m_fishRoomM.find(roomId);
		if (it == m_fishRoomM.end())
		{
			SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_66,TIPS_FAILURE_COLOR).c_str());
			return NULL;
		}
		pRoom = &(it->second);
	}
	if (pRoom == NULL)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_67,TIPS_FAILURE_COLOR).c_str());
		return NULL;
	}

	if (!pRoom->IsEnterable())
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_68,TIPS_FAILURE_COLOR).c_str());
		return NULL;
	}
	CSceneManager &sceneMgr = SingletonSceneManager::instance();
	CScene* pScene = sceneMgr.Find2Scene(pRoom->m_sceneId,pRoom->m_sceneId);
	if (pScene == NULL)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_69,TIPS_FAILURE_COLOR).c_str());
		return NULL;
	}

	++m_manNum;
	pRoom->EnterRoom(pUser->GetRoleId(), pUser->GetName());
	pUser->m_fishState = CFishRoom::ERS_FREE;
	pUser->SetFishRoom(pRoom);
	pUser->m_grabedTime = 0;
	pUser->SaveEnterPos(pUser->GetSceneId(),pUser->GetX(),pUser->GetY()); // 保存进入副本位置信息
	if (!pUser->HaveBitSet(169))
	{
		pUser->SetBitSet(169); // 每日活跃度 参加钓鱼
		pUser->CheckMissionHuoYueDu();
	}
	TransportUser(pUser,pScene->GetId(),FISH_POS_X,FISH_POS_Y,ENTER_FU_BEN_DEFAULT_MAP_FACE); // 切换地图

	CNetMessage msg;
	msg.SetType(MSG_FISH);
	msg<<(uint8)EFOP_Join<<PRO_SUCCESS<<pRoom->m_id; // 进入房间成功
	CSocketServer &sock = SingletonSocket::instance();
	sock.SendMsg(pUser->GetSock(),msg);

	pRoom->SyncPlayerList(pUser); // 同步更新房间成员列表

	//cout << "加入房间后，总人数：" << SingletonFishManager::instance().m_manNum << endl;
	CheckCreateRoom();

	if(roomId == 0)
		SendPKNotice(pUser);
	return pRoom;
}

// 切换房间
void CFishManager::SwitchRoom(CUser* pUser, CFishRoom* pCurRoom, int tarRoomId)
{
	if (pUser == NULL)
		return;
	if (pCurRoom == NULL)
		return;
	CScene* pScene = pUser->GetScene();
	if (pScene == NULL)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_70,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	if (tarRoomId == 0)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_71,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	CFishRoom* pTarRoom = GetRoom(tarRoomId);
	if (pTarRoom == NULL)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_72,TIPS_FAILURE_COLOR).c_str());
		return;
	}

	if (!pTarRoom->IsEnterable())
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_73,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	if (pUser->m_fishState == CFishRoom::ERS_FISHING)
		pCurRoom->StopFish(pUser);
	pCurRoom->SwitchExit(pUser);

	pTarRoom->EnterRoom(pUser->GetRoleId(), pUser->GetName());
	pUser->m_fishState = CFishRoom::ERS_FREE;
	pUser->SetFishRoom(pTarRoom);
	TransportUser(pUser,pTarRoom->m_sceneId,FISH_POS_X,FISH_POS_Y,ENTER_FU_BEN_DEFAULT_MAP_FACE); // 切换地图

	CNetMessage msg;
	msg.SetType(MSG_FISH);
	msg<<(uint8)EFOP_Join<<PRO_SUCCESS<<pTarRoom->m_id; // 进入房间成功
	CSocketServer &sock = SingletonSocket::instance();
	sock.SendMsg(pUser->GetSock(),msg);

	pCurRoom->SyncPlayerList(pUser,0); // 同步更新房间成员列表
	pTarRoom->SyncPlayerList(pUser); // 同步更新房间成员列表
	pUser->m_grabedTime = 0;
}

// 退出房间
void CFishManager::ExitRoom(CUser* pUser)
{
	if (pUser == NULL)
		return;
	CFishRoom* pRoom = pUser->GetFishRoom();
	if (pRoom == NULL)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_74,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	if (!pRoom->IsInRoom(pUser))
	{
		pUser->SetFishRoom(NULL);
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_75,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	pRoom->Exit(pUser);

}

// 获取房间内的玩家列表
void CFishManager::GetRoomPlayerList(CUser* pUser, int roomId)
{
	if (pUser == NULL)
		return;
	CFishRoom* pRoom = NULL;
	{
		boost::mutex::scoped_lock lk(m_fishRoomMMutex);
		itFishRoomM_t it = m_fishRoomM.find(roomId);
		if (it == m_fishRoomM.end())
		{
			SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_76,TIPS_FAILURE_COLOR).c_str());
			return;
		}
		pRoom = &(it->second);
	}
	if (pRoom == NULL)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_77,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	pRoom->GetPlayerList(pUser);
}

// 获取房间内的钓鱼玩家列表
void CFishManager::GetRoomFisherList(CUser* pUser)
{
	if (pUser == NULL)
		return;
	CFishRoom *pRoom = pUser->GetFishRoom();
	if (pRoom == NULL)
	{
		SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_79,TIPS_FAILURE_COLOR).c_str());
		return;
	}
	pRoom->GetFisherList(pUser);
}

// 清空房间(活动结束)
void CFishManager::CleanRoom()
{
	boost::mutex::scoped_lock lk(m_fishRoomMMutex);
	for (itFishRoomM_t it = m_fishRoomM.begin(); it != m_fishRoomM.end(); ++it)
	{
		it->second.AllExit();
	}
	m_fishRoomM.clear();
	m_curId = 0;
	m_manNum = 0;
}

// 检查是否需要创建房间
void CFishManager::CheckCreateRoom()
{
	//cout << "1当前人数：" << m_manNum << ",房间号数：" << m_curId << endl;
	if (m_manNum < (m_curId*(CFishRoom::MAX_FISHER))) // 房间可以容纳当前人数时
		return;
	CreateRoom();
	//cout << "创建房间了！id:" << m_curId << endl;
}

// 创建房间
CFishRoom* CFishManager::CreateRoom()
{
	CSceneManager &scene = SingletonSceneManager::instance();
	CScene *pScene = scene.GetFishingRoom();
	if(pScene == NULL)
		return NULL;
	CFishRoom room;
	room.m_id = ++m_curId;
	room.m_sceneId = pScene->GetId();

	boost::mutex::scoped_lock lk(m_fishRoomMMutex);
	pair<itFishRoomM_t,bool> ret = m_fishRoomM.insert(make_pair(room.m_id,room));
	if (!ret.second)
	{
		--m_curId;
		// 删除钓鱼房间数据未处理
		return NULL;
	}
	return &(ret.first->second);
}

// 查找房间
CFishRoom* CFishManager::GetRoom(int roomId)
{
	if (roomId == 0)
		return NULL;
	boost::mutex::scoped_lock lk(m_fishRoomMMutex);
	itFishRoomM_t it = m_fishRoomM.find(roomId);
	if (it == m_fishRoomM.end())
	{
		return NULL;
	}
	return &(it->second);
}

// 加载商城数据
bool CShopManager::LoadShopItems()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
	{
		cout << "Error:LoadShopItems Get db connect error." << endl;
		return false;
	}

	static bool readSaveData = false;
	char sql[1024];
	char** row = NULL;
	if(!readSaveData)
	{
		readSaveData = true;
		snprintf(sql,sizeof(sql),"select discount_Id from shop_discount_save order by id asc");
		if(!pDb->Query(sql))
		{
			cout << "Error:LoadShopItems query shop_discount_save error." << endl;
			return false;
		}

		boost::mutex::scoped_lock lk(m_shopItemsMutex);
		uint8 count = 0;
		m_discountItems_Effect.clear();
		while((row = pDb->GetRow()) != NULL)
		{
			if(count >= SHOW_DISCOUNT_NUM)
				break;
			count++;
			m_discountItems_Effect.push_back((uint16)atoi(row[0]));
		}
	}

	//								 0	1		2	3		4	 5		6		7		8			9		10      11        12
	snprintf(sql,sizeof(sql),"select id,item, price,offprice,type,tag,starttime,endtime,limitcount,count,vipLimit, value, exvalue from shop "\
		"where ((starttime=0) or ((starttime<=(unix_timestamp()+%d)) && (endtime>starttime) && (endtime>unix_timestamp()))) order by type asc,vipLimit asc,id asc",
		LOAD_SHOP_ITEM_TIMEOUT);
	if(!pDb->Query(sql))
	{
		cout << "Error:LoadShopItems query shop items error." << endl;
		return false;
	}

	{
		boost::mutex::scoped_lock lk(m_shopItemsMutex);
		m_shopItems.clear();

		string tagStr;
		while((row = pDb->GetRow()) != NULL)
		{
			uint8 type = (uint8)atoi(row[4]);
			CShopItem shopItem;
			shopItem.m_type = type;
			shopItem.m_id = atoi(row[0]);
			shopItem.m_itemId = atoi(row[1]);
			shopItem.m_price = atoi(row[2]);
			shopItem.m_offPrice = atoi(row[3]);
			tagStr = row[5];
			bitset<32> bt(tagStr);
			shopItem.m_tag = bt.to_ulong();
			shopItem.m_startTime = atoi(row[6]);
			shopItem.m_endTime = atoi(row[7]);
			shopItem.m_limit = atoi(row[8]);
			shopItem.m_count = atoi(row[9]);
			shopItem.value = atoi(row[11]);
			shopItem.extValue = atoi(row[12]);
			m_shopItems.push_back(shopItem);
			//cout << "物品id：" << shopItem.m_id << ",bitstr:" << tagStr.c_str() << ",tag:" << shopItem.m_tag << endl;
		}
	}

	
	snprintf(sql,sizeof(sql),"select id,item,num, exvalue,price,rate1,rate2,rate3,rate4,rate5,rate6,rate7,rate8,rate9 from shop_mystery order by id");
	if(!pDb->Query(sql))
	{
		cout << "Error:LoadShopItems query shop_mystery items error." << endl;
		return false;
	}
	{
		boost::mutex::scoped_lock lk(m_shopItemsMutex);
		m_MysteryItem.clear();

		string tagStr;
		while((row = pDb->GetRow()) != NULL)
		{
			UserMysteryItem item;
			item.id = (uint16)atoi(row[0]);
			item.itemId = (uint16)atoi(row[1]);
			item.itemNum = (uint16)atoi(row[2]);
			item.extValue = (uint16)atoi(row[3]);
			item.price = (uint16)atoi(row[4]);
			for(int i=0;i<9;i++)
				item.rate[i]=(uint16)atoi(row[5+i]);
			m_MysteryItem.push_back(item);
		}
	}

	//                                0   1     2       3    4    5     6
	snprintf(sql,sizeof(sql),"select id,name,buy_type,price,time,`rank`,`desc` from footprint_config order by `rank` asc,id asc");
	if(!pDb->Query(sql))
	{
		cout << "Error:LoadShopItems query footprint_config items error." << endl;
		return false;
	}
	{
		boost::mutex::scoped_lock lk(m_shopItemsMutex);
		m_footShop.clear();
		while((row = pDb->GetRow()) != NULL)
		{
			SFootPrintShopData item;
			item.id = atoi(row[0]);
			item.name = row[1];
			item.buy_type = atoi(row[2]);
			item.price = atoi(row[3]);
			item.time = atoi(row[4]);
			item.rank = atoi(row[5]);
			item.desc = row[6];
			m_footShop.push_back(item);
		}
	}

	//                                0    1        2      3      4     5
	snprintf(sql,sizeof(sql),"select id,item_id,buy_type,price,mei_li,qin_mi from flower_config order by `rank` asc,id asc");
	if(!pDb->Query(sql))
	{
		cout << "Error:LoadShopItems query flower_config items error." << endl;
		return false;
	}
	{
		boost::mutex::scoped_lock lk(m_shopItemsMutex);
		m_flowerShop.clear();
		while((row = pDb->GetRow()) != NULL)
		{
			SFlowerData data;
			data.itemId = atoi(row[1]);
			data.buy_type = atoi(row[2]);
			data.price = atoi(row[3]);
			data.meili = atoi(row[4]);
			data.qinmi = atoi(row[5]);
			m_flowerShop.push_back(data);
		}
	}

	static bool isfirstRead = true;
	if(isfirstRead)
	{
		//                         0    1    2
		snprintf(sql,sizeof(sql),"select role1,role2,qin_mi from qin_mi_log order by id asc");
		if(!pDb->Query(sql))
		{
			cout << "Error:LoadShopItems query qin_mi_log error." << endl;
			return false;
		}
		{
			boost::mutex::scoped_lock lk(m_shopItemsMutex);
			m_qinmiData.clear();
			while((row = pDb->GetRow()) != NULL)
			{
				m_qinmiData.insert(make_pair(GetQinMiStr(atoi(row[0]),atoi(row[1])),atoi(row[2])));
			}
		}

		// 加载历届数据
		//                                  0      1       2       3        4
		snprintf(sql, sizeof(sql), "select round, role_id, name, mei_li, title from mei_li_history order by round, mei_li desc");
		if (!pDb->Query(sql))
		{
			cout << "Error:LoadShopItems query mei_li_paihang error." << endl;
			return false;
		}
		{
			boost::mutex::scoped_lock lk(m_shopItemsMutex);
			m_allRoundDatas.clear();
			while ((row = pDb->GetRow()) != NULL)
			{
				uint16 round = atoi(row[0]);
				meiliDatas tmp;
				pair<sessionMeiliIt, bool> bInsert = m_allRoundDatas.insert(make_pair(round, tmp));
				meiliDatas& curData = bInsert.first->second;

				SMeiLiData data;
				data.role_id = atoi(row[1]);
				data.name = row[2];
				data.mei_li = atoi(row[3]);
				data.title = atoi(row[4]);
				curData.push_back(data);
			}
		}

		//                                   1     2      3       4
		snprintf(sql,sizeof(sql),"select role_id,name,mei_li from mei_li_paihang order by mei_li desc");
		if(!pDb->Query(sql))
		{
			cout << "Error:LoadShopItems query mei_li_paihang error." << endl;
			return false;
		}
		{
			boost::mutex::scoped_lock lk(m_shopItemsMutex);
			m_meiliData.clear();
			while((row = pDb->GetRow()) != NULL)
			{
				SMeiLiData data;
				data.role_id = atoi(row[0]);
				data.name = row[1];
				data.mei_li = atoi(row[2]);
				m_meiliData.push_back(data);
			}
		}
		isfirstRead = false;
	}

	snprintf(sql,sizeof(sql),"select id,item,num,price,rate1,rate2,rate3,rate4,rate5,rate6,rate7,rate8,rate9,rate10,rate11,rate12 from shop_yaoshi order by id");
	if(!pDb->Query(sql))
	{
		cout << "Error:LoadShopItems query shop_yaoshi items error." << endl;
		return false;
	}
	{
		boost::mutex::scoped_lock lk(m_shopItemsMutex);
		m_YaoShiItem.clear();

		string tagStr;
		while((row = pDb->GetRow()) != NULL)
		{
			UserYaoShiItem item;
			item.id = (uint32)atoi(row[0]);
			item.itemId = (uint32)atoi(row[1]);
			item.itemNum = (uint32)atoi(row[2]);
			item.price = (uint32)atoi(row[3]);
			for(int i=0;i<12;i++)
				item.rate[i]=(uint32)atoi(row[4+i]);
			m_YaoShiItem.push_back(item);
		}
	}
	
	//                                0   1	  2       3       4         5          6      7    8    9   10    11   12   13   14   15   16   17     18    19    20    21    22      23        24       25
	snprintf(sql,sizeof(sql),"select id,type,name,srcPrice,discount,weekdayInfo,vipLimit,vip0,vip1,vip2,vip3,vip4,vip5,vip6,vip7,vip8,vip9,vip10,vip11,vip12,vip13,vip14,vip15,awardType1,awardID1,awardNum1,"\
		//     26      27        28        29         30       31    32   33
		"awardType2,awardID2,awardNum2,awardType3,awardID3,awardNum3,msg,def from shop_discount order by type asc,def desc,vipLimit asc,id asc");
	if(!pDb->Query(sql))
	{
		cout<<"Error:LoadShopItems query shop_discount error." << endl;
		return false;
	}
	{
		boost::mutex::scoped_lock lk(m_shopItemsMutex);
		m_discountItems.clear();
		m_discountItems_NewUser.clear();
		m_discountMap_Effect.clear();

		while((row = pDb->GetRow()) != NULL)
		{
			EShopDiscountItem item;
			item.awardCount = 0;
			item.id = (uint16)atoi(row[0]);
			item.type = (uint8)atoi(row[1]);
			item.name = row[2];
			item.srcPrice = (uint16)atoi(row[3]);

			item.vipLimit = (uint8)atoi(row[6]);
			for(int i=0;i<16;i++)
				item.vipCanBuyNum[i] = (uint8)atoi(row[7+i]);
			item.awardType[0] = (uint8)atoi(row[23]);
			item.awardId[0] = (uint16)atoi(row[24]);
			item.awardNum[0] = (uint8)atoi(row[25]);
			item.awardType[1] = (uint8)atoi(row[26]);
			item.awardId[1] = (uint16)atoi(row[27]);
			item.awardNum[1] = (uint8)atoi(row[28]);
			item.awardType[2] = (uint8)atoi(row[29]);
			item.awardId[2] = (uint16)atoi(row[30]);
			item.awardNum[2] = (uint8)atoi(row[31]);
			item.desc = row[32];
			item.def = atoi(row[33]);

			string str = row[4];
			char *split[WEEK_DAY_NUM];
			int num = SplitLine(split,WEEK_DAY_NUM,(char*)str.c_str());
			if(num < WEEK_DAY_NUM)
			{
				cout<<"read shop_discount id="<<row[0]<<", SplitLine discount error!!!"<<endl;
				continue;
			}
			for(uint8 i = 0;i < WEEK_DAY_NUM;i++)
				item.discount[i] = (uint8)atoi(split[i]);

			str = row[5];
			num = SplitLine(split,WEEK_DAY_NUM,(char*)str.c_str());
			if(num < WEEK_DAY_NUM)
			{
				cout<<"read shop_discount id="<<row[0]<<", SplitLine weekdayInfo error!!!"<<endl;
				continue;
			}
			for(uint8 i = 0;i < WEEK_DAY_NUM;i++)
				item.weekdayInfo[i] = (uint8)atoi(split[i]);

			for(uint8 i=0;i < MAX_DISCOUNT_AWARDNUM;i++)
			{
				if(item.awardType[i] > 0)
					item.awardCount++;
			}

			if(item.type == 1)
				m_discountItems_NewUser.push_back(item);
			else
				m_discountItems.push_back(item);
		}

		for(uint8 i=0;i < m_discountItems_Effect.size();i++)
		{
			for(uint8 j=0;j < m_discountItems.size();j++)
			{
				if(m_discountItems_Effect[i] == m_discountItems[j].id)
				{
					m_discountMap_Effect.insert(make_pair(m_discountItems[j].id,j));
					break;
				}
			}
		}
	}
	return true;
}

// 加载新的神将数据
bool CShopManager::ReloadShenjiangShopItems()
{
	//                       0       1            2          3       4        5        6          7        8         9        10        11        12        13        14
	const char *keys[] = { "id", "min_level", "max_level", "item", "num" , "price" , "rate1" , "rate2" , "rate3" , "rate4" , "rate5" , "rate6" , "rate7" , "rate8" , "rate9" };
	vector<map<string, string> > data;
	uint16 size = sizeof(keys) / sizeof(keys[0]);
	CXMLReader reader("shop_shenjiang_mystery.xml");
	if (!reader.GetAllElements(data, keys, size))
		return false;

	for (uint32 i = 0; i < data.size(); i++)
	{
		pair<int, int> key = pair<int, int>(atoi(data[i][keys[1]].c_str()), atoi(data[i][keys[2]].c_str()));
		UserMysteryItem item;
		item.id = (uint16)atoi(data[i][keys[0]].c_str());
		item.itemId = (uint16)atoi(data[i][keys[3]].c_str());
		item.itemNum = (uint8)atoi(data[i][keys[4]].c_str());
		item.price = (uint16)atoi(data[i][keys[5]].c_str());
		for (int j = 0; j < 9; j++)
			item.rate[j] = (uint16)atoi(data[i][keys[6+j]].c_str());
		M9RateShopItems items;
		pair<ShenjiangShopItemMapIt, bool> itb = m_ShenhunItems.insert(make_pair(key, items));
		itb.first->second.push_back(item);
	}
	return true;
}


void CShopManager::Save()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
	{
		cout << "Error:CShopManager::Save() error." << endl;
		return;
	}
	pDb->Query("truncate qin_mi_log");
//	cout<<">> run sql: truncate qin_mi_log"<<endl;

	char sql[512];
	map<string,int> qinmiList;
	vector< SMeiLiData > meiliList;
	{
		boost::mutex::scoped_lock lk(m_shopItemsMutex);
		qinmiList = m_qinmiData;
		meiliList= m_meiliData;
	}
	
	for(map<string,int>::iterator it=qinmiList.begin();it != qinmiList.end();it++)
	{
		string str = it->first;
		uint32 role1=0,role2=0;
		GetQinMiRoleId(str,role1,role2);
		if(role1 == 0 || role2 == 0)
			continue;
		snprintf(sql,sizeof(sql),"insert into qin_mi_log(role1,role2,qin_mi) values(%u,%u,%d)",role1,role2,it->second);
		pDb->Query(sql);
//		cout<<">> insert qin_mi_log sql: "<<sql<<";"<<endl;
	}

	pDb->Query("truncate mei_li_paihang");
//	cout<<">> run sql: truncate mei_li_paihang"<<endl;
	if(meiliList.size() > 1)
	{
		SSortMeiLi sortFunc;
		std::sort(meiliList.begin(),meiliList.end(),sortFunc);
	}
	for(uint32 i=0;i < meiliList.size();i++)
	{
		snprintf(sql,sizeof(sql),"insert into mei_li_paihang(role_id,name,mei_li) values(%u,'%s',%d)",meiliList[i].role_id,meiliList[i].name.c_str(),meiliList[i].mei_li);
		pDb->Query(sql);
//		cout<<">> insert mei_li_paihang sql: "<<sql<<";"<<endl;
	}
}

//定时器
void CShopManager::Timeout()
{
	static bool resetShopDiscount = false;
	if(GetHour() == 0 && GetMinute() <= 20 && !resetShopDiscount)
	{
		resetShopDiscount = true;
		ReSetDiscountItems_Effect();
	}
	else if(GetHour() != 0)
	{
		resetShopDiscount = false;
	}

#ifndef KUA_FU
	SendMeiLiPaiAward();
#endif

	static time_t lastTime = GetSysTime();
	int curTime = GetSysTime();
	if((curTime - lastTime) < LOAD_SHOP_ITEM_TIMEOUT)
		return;

	lastTime = curTime;
	LoadShopItems();
}

void CShopManager::SendMeiLiPaiAward()
{
	/*int hour = GetHour();
	int min = GetMinute();*/
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint32 type = CHuoDongAwardManager::XIANHUA_MEILI;
	if (m_meiliData.empty() || awardManager.InHuoDongTime(type))
	{
		return;
	}

	if (!m_meiliData.empty() && !awardManager.InHuoDongTime(type))
	{
		// clear
		vector<SMeiLiData> meiliList;
		{
			boost::mutex::scoped_lock lk(m_shopItemsMutex);
			uint32 size = m_meiliData.size();
			if (size > 1)
			{
				SSortMeiLi sortFunc;
				std::sort(m_meiliData.begin(), m_meiliData.end(), sortFunc);
			}
			meiliList = m_meiliData;
			m_meiliData.clear();
		}

		int round = m_allRoundDatas.size() + 1;
		uint32 size = meiliList.size();

		char buf[512];
		for (uint32 i = 0; i < size; i++)
		{
			SHuoDongAward award;
			awardManager.GetAwardDataByRange(type, 1, i + 1, award);
			for (size_t ai = 0; ai < award.AWARD_NUM; ++ai)
			{
				if (award.award[ai] == HDAT_CHENGHAO)
				{
					meiliList[i].title = award.num[ai];
					break;
				}
			}

			if (meiliList[i].title == 0)
			{
				snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0042, round, awardManager.GetHuoDongName(type).c_str(), i + 1);
			}
			else
			{
				snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0041, round, awardManager.GetHuoDongName(type).c_str(), i + 1, sTitltAttrCfgManager.GetTitleName(meiliList[i].title));
			}
			
			SendHuoDongAwardMail(m_meiliData[i].role_id, 1, award, buf, type);
		}
		m_allRoundDatas.insert(make_pair(m_allRoundDatas.size() + 1, meiliList));

		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		if (pDb != NULL)
		{
			pDb->Query("truncate mei_li_paihang_bak");
			for (uint32 i = 0; i < meiliList.size(); i++)
			{
				snprintf(buf, sizeof(buf), "insert into mei_li_paihang_bak(role_id,name,mei_li) values(%u,'%s',%d)", meiliList[i].role_id, meiliList[i].name.c_str(), meiliList[i].mei_li);
				pDb->Query(buf);
			}

			for (uint32 i = 0; i < meiliList.size(); i++)
			{
				snprintf(buf, sizeof(buf), "insert into mei_li_history(`rank`, `round`, `role_id`, `name`, `mei_li`, `title`) values(%u,%u,%u,'%s',%d,%u)",
					i + 1, round, meiliList[i].role_id, meiliList[i].name.c_str(), meiliList[i].mei_li, meiliList[i].title);
				pDb->Query(buf);
			}
			cout << ">>>  CShopManager::SendMeiLiPaiAward() send award success and save paihang.." << endl;
		}
	}
}

int CShopManager::GetQinMiValue(uint32 roleId1,uint32 roleId2)
{
	boost::mutex::scoped_lock lk(m_shopItemsMutex);
	map<string,int>::iterator it = m_qinmiData.find(GetQinMiStr(roleId1,roleId2));
	if(it == m_qinmiData.end())
		return 0;
	return it->second;
}

int CShopManager::GetMeiLiValue(uint32 roleId)
{
	boost::mutex::scoped_lock lk(m_shopItemsMutex);
	for(uint32 i=0;i < m_meiliData.size();i++)
	{
		if(m_meiliData[i].role_id == roleId)
		{
			return m_meiliData[i].mei_li;
		}
	}
	return 0;
}

bool CShopManager::IsMeiliHuodongOpen()
{
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	return awardManager.InHuoDongTime(CHuoDongAwardManager::XIANHUA_MEILI);
}

// 获取商城物品
void CShopManager::ShowShopItems(CUser* pUser, int type)
{
	if(pUser == NULL)
		return;
	time_t curTime = GetSysTime();

	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_SHOP);
	msg<<(uint8)ESOP_Show<<(uint8)type;

	uint8 xianShiNum = 0;
	uint8 xianShiPos = msg.GetDataLen();
	msg<<xianShiNum;

	uint8 otherNum = 0;
	uint8 otherPos = msg.GetDataLen();
	msg<<otherPos;

	boost::mutex::scoped_lock lk(m_shopItemsMutex);
	// 默认限时物品在最前面
	for(itShopItems_t it = m_shopItems.begin(); it != m_shopItems.end(); ++it)
	{
		//		if(it->m_type == ESIT_XIANSHI && type != ESIT_JINGJIJIFEN)		// 竞技商店不发限时物品
		//		{
		//			if((it->m_startTime <= curTime) && (it->m_endTime > curTime))
		//			{
		//				++xianShiNum;
		//				msg<<it->m_itemId<<it->m_price<<it->m_offPrice<<(it->m_limit-it->m_count)<<(int)(it->m_endTime-curTime)<<it->m_tag;
		//			}
		//		}
		if(it->m_type == type)
		{
			if(it->m_startTime == 0 || ((it->m_startTime <= curTime) && (it->m_endTime > curTime)))
			{
				++otherNum;
				int leftTime = it->m_endTime - curTime;
				msg<<it->m_itemId << it->value << it->extValue <<it->m_price<<it->m_offPrice<<it->m_tag<<leftTime;
			}
		}
	}

	msg.WriteData(xianShiPos,&xianShiNum,1);
	msg.WriteData(otherPos,&otherNum,1);
	sock.SendMsg(pUser->GetSock(),msg);
}


void CShopManager::ShowZaDanShopItems(CUser *pUser)
{
	if(pUser == NULL)
		return;	
	CNetMessage msg;
	msg.SetType(MSG_SHOP);
	uint32 ext32Idx = 0;
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	if (awardManager.InHuoDongTime(CHuoDongAwardManager::ZHA_DAN))
		ext32Idx = 12;
	else if (awardManager.InHuoDongTime(CHuoDongAwardManager::ZHA_DAN_COPY))
		ext32Idx = 468;
	msg<<(uint8)ESOP_ZaDanShow<< pUser->GetExtData32(ext32Idx);
	int type = 0;
	if (awardManager.InHuoDongTime(CHuoDongAwardManager::ZHA_DAN))
		type = ESIT_ZaDanJiFen;
	else if (awardManager.InHuoDongTime(CHuoDongAwardManager::ZHA_DAN_COPY))
		type = ESIT_ZaDanJiFenCopy;
	uint16 num = 0;
	time_t curTime = GetSysTime();
	uint16 pos = msg.GetDataLen();
	msg<<num;
	
	boost::mutex::scoped_lock lk(m_shopItemsMutex);
	for(itShopItems_t it = m_shopItems.begin(); it != m_shopItems.end(); ++it)
	{
		if(it->m_type == type && (it->m_startTime == 0 || ((it->m_startTime <= curTime) && (it->m_endTime > curTime))))
		{
			int leftTime = it->m_endTime - curTime;
			num++;
			msg << it->m_itemId << it->value << it->extValue << it->m_price << it->m_offPrice << it->m_tag << leftTime;
		}
	}
	msg.WriteData(pos,&num,sizeof(num));
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void CShopManager::BuyZaDanShopItems(CUser *pUser,int itemId,int itemNum)
{
	if(pUser == NULL)
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_SHOP);
	msg<<(uint8)ESOP_ZaDanBuy;

	int type = 0;
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	if (awardManager.InHuoDongTime(CHuoDongAwardManager::ZHA_DAN))
		type = ESIT_ZaDanJiFen;
	else if (awardManager.InHuoDongTime(CHuoDongAwardManager::ZHA_DAN_COPY))
		type = ESIT_ZaDanJiFenCopy;
	if(itemNum == 0 || itemNum == 0 || itemNum > EItemDieJiaNum)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_80,TIPS_FAILURE_COLOR);
		sock.SendMsg(pUser->GetSock(),msg);
		return;
	}

	uint32 ext32Idx = 0;
	if (awardManager.InHuoDongTime(CHuoDongAwardManager::ZHA_DAN))
		ext32Idx = 12;
	else if (awardManager.InHuoDongTime(CHuoDongAwardManager::ZHA_DAN_COPY))
		ext32Idx = 468;
	time_t curTime = GetSysTime();
	uint32 blessValue = pUser->GetExtData32(ext32Idx);
	CShopItem* pSItem = GetShopItem(type,itemId);
	if(pSItem == NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_81,TIPS_FAILURE_COLOR);
		sock.SendMsg(pUser->GetSock(),msg);
		return;
	}

	if (pSItem->m_startTime != 0 && ((pSItem->m_startTime > curTime) || (pSItem->m_endTime <= curTime)))
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_82,TIPS_FAILURE_COLOR);
		sock.SendMsg(pUser->GetSock(),msg);
		return;
	}
	
	int price = pSItem->m_price;
	uint32 needValue = price * itemNum;
	if(blessValue < needValue)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_83,TIPS_FAILURE_COLOR);
		sock.SendMsg(pUser->GetSock(),msg);
		return;
	}

	blessValue -= needValue;
	if(pUser->AddBangDingPackage(itemId,itemNum))
	{
		char buf[128];
		snprintf(buf,sizeof(buf)-1,LANGUAGE_TRANSFORM_84,GetItemName(itemId),itemNum);
		pUser->SetExtData32(ext32Idx,blessValue);
		msg<<PRO_SUCCESS<<blessValue<<MakeStringColor(buf,TIPS_WARNING_COLOR);
		sock.SendMsg(pUser->GetSock(),msg);
		SaveLog(pUser,ESIT_ZaDanJiFen,itemId,itemNum,needValue); // 记录
	}
	else
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_85,TIPS_FAILURE_COLOR);
		sock.SendMsg(pUser->GetSock(),msg);
	}
}

void CShopManager::ShowHongLiJiFenShopItems(CUser *pUser,uint32 huodongType)
{
	if(pUser == NULL)
		return;	
	CNetMessage msg;
	msg.SetType(MSG_SHOP);

	uint32 timeDataId = 0;
	uint32 jifenDataId = 0;
	if (!GetHongLiJiFenDataId(huodongType,timeDataId,jifenDataId))
		return;
	
	msg<<(uint8)ESOP_HongLiJiFenShow<<pUser->GetExtData32(jifenDataId)<<huodongType;

	uint16 num = 0;
	time_t curTime = GetSysTime();
	uint16 pos = msg.GetDataLen();
	msg<<num;
	
	boost::mutex::scoped_lock lk(m_shopItemsMutex);
	for(itShopItems_t it = m_shopItems.begin(); it != m_shopItems.end(); ++it)
	{
		if(it->m_type == ESIT_HongLiJiFen && (it->m_startTime == 0 || ((it->m_startTime <= curTime) && (it->m_endTime > curTime))))
		{
			num++;
			int leftTime = it->m_endTime - curTime;
			msg<<it->m_itemId<<it->m_price<<leftTime;
		}
	}
	msg.WriteData(pos,&num,sizeof(num));
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void CShopManager::BuyHongLiJiFenShopItems(CUser *pUser,int itemId,int itemNum,uint32 huodongType)
{
	if(pUser == NULL)
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	CNetMessage msg;
	msg.SetType(MSG_SHOP);
	msg<<(uint8)ESOP_HongLiJiFenBuy;

	if(!awardManager.InHuoDongTime(huodongType))
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_86,TIPS_FAILURE_COLOR);
		sock.SendMsg(pUser->GetSock(),msg);
		return;
	}

	uint32 timeDataId = 0;
	uint32 jiFenDataId = 0;
	if (!GetHongLiJiFenDataId(huodongType,timeDataId,jiFenDataId))
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_87,TIPS_FAILURE_COLOR);
		sock.SendMsg(pUser->GetSock(),msg);
		return;
	}

	if(itemNum == 0 || itemNum == 0 || itemNum > EItemDieJiaNum)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_87,TIPS_FAILURE_COLOR);
		sock.SendMsg(pUser->GetSock(),msg);
		return;
	}

	time_t curTime = GetSysTime();
	uint32 hongLiValue = pUser->GetExtData32(jiFenDataId);
	CShopItem* pSItem = GetShopItem(ESIT_HongLiJiFen,itemId);
	if(pSItem == NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_88,TIPS_FAILURE_COLOR);
		sock.SendMsg(pUser->GetSock(),msg);
		return;
	}

	if (pSItem->m_startTime != 0 && ((pSItem->m_startTime > curTime) || (pSItem->m_endTime <= curTime)))
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_89,TIPS_FAILURE_COLOR);
		sock.SendMsg(pUser->GetSock(),msg);
		return;
	}
	
	int price = pSItem->m_price;
	uint32 needValue = price * itemNum;
	if(hongLiValue < needValue)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_90,TIPS_FAILURE_COLOR);
		sock.SendMsg(pUser->GetSock(),msg);
		return;
	}

	hongLiValue -= needValue;
	if(pUser->AddBangDingPackage(itemId,itemNum))
	{
		char buf[128];
		snprintf(buf,sizeof(buf)-1,LANGUAGE_TRANSFORM_91,GetItemName(itemId),itemNum);
		pUser->SetExtData32(jiFenDataId,hongLiValue);
		msg<<PRO_SUCCESS<<hongLiValue<<MakeStringColor(buf,TIPS_WARNING_COLOR);
		sock.SendMsg(pUser->GetSock(),msg);
		SaveLog(pUser,ESIT_HongLiJiFen,itemId,itemNum,needValue); // 记录
	}
	else
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_92,TIPS_FAILURE_COLOR);
		sock.SendMsg(pUser->GetSock(),msg);
	}
}

void CShopManager::ReSetDiscountItems_Effect()	// 生成打折列表
{
	int weekDay = GetWeekDay();	// 星期 0-6

	{
		boost::mutex::scoped_lock lk(m_shopItemsMutex);
		m_discountItems_Effect.clear();
		m_discountMap_Effect.clear();
		
		const uint16 MAX_ITEM_NUM = 1024;
		const uint16 size = (m_discountItems.size() > MAX_ITEM_NUM) ? MAX_ITEM_NUM : m_discountItems.size();
		int sequence[MAX_ITEM_NUM];
		uint16 def0_pos = 0;
		int count = 0;
		int totalIdx = 0;
		for(uint8 i=0;i < size;i++)
		{
			if(m_discountItems[i].def == 0)
			{
				def0_pos = i;
				break;
			}
		}

		for(uint8 i=0;i < def0_pos;i++)
		{
			totalIdx++;
			if(m_discountItems[i].weekdayInfo[weekDay] == 1 && m_discountItems[i].discount[weekDay] > 0)
			{
				if(count >= SHOW_DISCOUNT_NUM)
					break;
				count++;
				m_discountItems_Effect.push_back(m_discountItems[i].id);
				m_discountMap_Effect.insert(make_pair(m_discountItems[i].id,i));
			}
			
		}
		
		if(!RandomSequence(sequence,size-totalIdx,size-totalIdx))
			return;

		int idx2 = totalIdx;
		for(uint8 i=0;i < size-totalIdx;i++)
		{
			int idx = sequence[i] - 1 + idx2;
			if(m_discountItems[idx].weekdayInfo[weekDay] == 1 && m_discountItems[idx].discount[weekDay] > 0)
			{
				if(count >= SHOW_DISCOUNT_NUM)
					break;
				count++;
				m_discountItems_Effect.push_back(m_discountItems[idx].id);
				m_discountMap_Effect.insert(make_pair(m_discountItems[idx].id,idx));
			}
		}
	}

	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
	{
		cout << "Error:ReSetDiscountItems_Effect Get db connect error." << endl;
		return;
	}
	char sql[128];
	pDb->Query("delete from shop_discount_save");
	for(uint8 i=0;i < m_discountItems_Effect.size();i++)
	{
		snprintf(sql,sizeof(sql),"insert into shop_discount_save (discount_Id) values(%d)",m_discountItems_Effect[i]);
		pDb->Query(sql);
	}
}

void CShopManager::ShowDiscountItems(CUser *pUser)
{
	if(pUser == NULL)
		return;

	uint8 type = 2;	// 1折扣商店 2新手特惠
	CNetMessage msg;
	msg.SetType(MSG_SHOP);
	msg<<(uint8)ESOP_DiscountShow;

	int curTime = (int)GetSysTime();
	int weekDay = GetWeekDay();	// 星期 0-6
	int vipLv = pUser->GetVipLevel();

	if(m_discountItems_Effect.empty())	// 生成打折列表,第一次才生效
		ReSetDiscountItems_Effect();

	boost::mutex::scoped_lock lk(m_shopItemsMutex);
	vector<EShopDiscountItem> *pDiscount = NULL;
	uint8 size = 0;

	if(pUser->GetRegTime() + NEW_USER_DISCOUNT_TIME > curTime)	// 7天以内才有新手特惠
	{
		type = 1;
		size = m_discountItems_NewUser.size();
		int leftTime = pUser->GetRegTime() + NEW_USER_DISCOUNT_TIME - curTime;
		msg<<type<<leftTime;
		pDiscount = &m_discountItems_NewUser;
	}
	else
	{
		type = 1;
		msg << type << (int)0;
		SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);
		return;
		//if (!pUser->HaveBitSet(227))		// 新手特惠切换折扣商城
		//{
		//	pUser->SetBitSet(227);
		//	pUser->ClearShopDiscountBuyNum();
		//}
	}
	if(pDiscount == NULL)	// 折扣商店
	{
		type = 2;
		size = (uint8)m_discountItems_Effect.size();
		pDiscount = &m_discountItems;
		msg<<type;
	}

	uint8 count = 0;	
	uint16 pos = msg.GetDataLen();
	msg<<count;
	for(uint8 k=0;k < size;k++)
	{
		uint8 idx = 0xff;
		if(type == 1)
		{
			idx = k;
		}
		else if(type == 2)
		{
			map<uint16,uint8>::iterator it = m_discountMap_Effect.find(m_discountItems_Effect[k]);
			if(it == m_discountMap_Effect.end())
				continue;
			idx = it->second;
			if(idx > m_discountItems.size())
				continue;
		}

		uint16 curPrice = (uint16)((*pDiscount)[idx].srcPrice * (*pDiscount)[idx].discount[weekDay] / 100);
		uint8 canBuyNum = (*pDiscount)[idx].vipCanBuyNum[vipLv] - pUser->GetShopDiscountBuyNum(k);
		uint8 vipLimit = vipLv;
		if(canBuyNum == 0)
		{
			for(uint8 i=vipLv+1;i <= 15;i++)
			{
				if((*pDiscount)[idx].vipCanBuyNum[i] > (*pDiscount)[idx].vipCanBuyNum[vipLv])
				{
					canBuyNum = (*pDiscount)[idx].vipCanBuyNum[i] - pUser->GetShopDiscountBuyNum(k);
					vipLimit = i;
					break;
				}
			}
		}
		if(canBuyNum > (*pDiscount)[idx].vipCanBuyNum[vipLv])
			canBuyNum = 0;
		msg<<(*pDiscount)[idx].id<<(*pDiscount)[idx].name<<(*pDiscount)[idx].desc<<(*pDiscount)[idx].srcPrice
			<<curPrice<<(uint8)((*pDiscount)[idx].discount[weekDay]/10*10)<<canBuyNum<<vipLimit;
		msg<<(*pDiscount)[idx].awardCount;

		for(uint8 i=0;i < MAX_DISCOUNT_AWARDNUM;i++)
		{
			if((*pDiscount)[idx].awardType[i] == 0)
				continue;

			msg<<(*pDiscount)[idx].awardType[i];
			if((*pDiscount)[idx].awardType[i] == 1)	// 物品
				msg<<(*pDiscount)[idx].awardId[i]<<(*pDiscount)[idx].awardNum[i];
			else if((*pDiscount)[idx].awardType[i] == 2)	// 神将
			{
				int petId = (*pDiscount)[idx].awardId[i];
				MakePetMsg(pUser,msg,petId);
			}
			else if((*pDiscount)[idx].awardType[i] == 3)	// 神将蛋
			{
				uint8 quality = (*pDiscount)[idx].awardId[i];
				msg<<quality;
			}
			else if((*pDiscount)[idx].awardType[i] == 4)	// 非指定技能书
			{

			}
		}
		count++;
		if(count > SHOW_DISCOUNT_NUM)
			break;
	}
	msg.WriteData(pos,&count,sizeof(count));
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void CShopManager::BuyDiscountItems(CUser *pUser,uint16 itemId)
{
	if(pUser == NULL || !pUser->HaveBitSet(200))
		return;

	const uint16 PURPLE_PET_ID[] = {28,29,30};
	const uint16 ORANGE_PET_ID[] = {31,32,33,34,35,36,37,38,39};
	const uint16 GOLD_PET_ID[] = {31,32,38,39};
	int curTime = (int)GetSysTime();
	int weekDay = GetWeekDay();	// 星期 0-6
	int vipLv = pUser->GetVipLevel();

	CNetMessage msg;
	msg.SetType(MSG_SHOP);
	msg<<(uint8)ESOP_DiscountBuy;

	uint8 type = 2;	// 1新手特惠2折扣商店
	if(pUser->GetRegTime() + NEW_USER_DISCOUNT_TIME > curTime)	// 新手特惠
		type = 1;

	boost::mutex::scoped_lock lk(m_shopItemsMutex);
	uint8 itemShowIndex = 0xff;
	uint8 pos = 0xff;
	if(type == 1)
	{
		for(uint8 i=0;i < m_discountItems_NewUser.size();i++)
		{
			if(m_discountItems_NewUser[i].id == itemId)
			{
				itemShowIndex = i;
				pos = i;
				break;
			}
		}
	}
	else if(type == 2)
	{
		for(uint8 i=0;i < SHOW_DISCOUNT_NUM;i++)
		{
			if(m_discountItems_Effect[i] == itemId)
			{
				itemShowIndex = i;
				break;
			}
		}

		map<uint16,uint8>::iterator it = m_discountMap_Effect.find(itemId);
		if(it == m_discountMap_Effect.end())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_93,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}
		pos = it->second;
		if(pos > m_discountItems.size())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_94,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}
	}
	else
		return;
	if(itemShowIndex == 0xff || pos == 0xff)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_95,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}

	vector<EShopDiscountItem> *pDiscount = NULL;
	if(type == 1)
		pDiscount = &m_discountItems_NewUser;
	else
		pDiscount = &m_discountItems;

	if(pUser->GetShopDiscountBuyNum(itemShowIndex) >= (*pDiscount)[pos].vipCanBuyNum[vipLv])
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_96,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}
	uint16 curPrice = (uint16)((*pDiscount)[pos].srcPrice * (*pDiscount)[pos].discount[weekDay] / 100);
	if(pUser->GetTongBao() < curPrice)
	{
		msg<<PRO_ERROR<<"";
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		ShowJumpNotice(pUser,JUMP_NOTICE_YB);
		return;
	}

	pUser->AddTongBao(-curPrice);
	pUser->AddShopDiscountBuyNum(itemShowIndex);

	msg<<PRO_SUCCESS;
	uint8 leftAwardNum = (*pDiscount)[pos].vipCanBuyNum[vipLv] - pUser->GetShopDiscountBuyNum(itemShowIndex);
	uint8 awardType = 2;	// 1物品2神将
	uint16 typePos = msg.GetDataLen();
	msg<<awardType;

	string res = "";
	string gonggao = "";
	int petNum = 0;
	for(uint8 i=0;i < MAX_DISCOUNT_AWARDNUM;i++)
	{
		if((*pDiscount)[pos].awardType[i] == 0)
			continue;

		char buf[256];
		if((*pDiscount)[pos].awardType[i] == 1)	// 物品
		{
			pUser->AddPackage((*pDiscount)[pos].awardId[i],(*pDiscount)[pos].awardNum[i]);
			if(res.size() == 0)
				snprintf(buf,sizeof(buf),"%s*%d",GetItemName((*pDiscount)[pos].awardId[i]),(int)(*pDiscount)[pos].awardNum[i]);
			else
				snprintf(buf,sizeof(buf),", %s*%d",GetItemName((*pDiscount)[pos].awardId[i]),(int)(*pDiscount)[pos].awardNum[i]);
			res += buf;

			if(gonggao.size() == 0)
				snprintf(buf,sizeof(buf),"[c%d]%s*%d[/c]",ITEM_NAME_COLOR,GetItemName((*pDiscount)[pos].awardId[i]),(int)(*pDiscount)[pos].awardNum[i]);
			else
				snprintf(buf,sizeof(buf),", [c%d]%s*%d[/c]",ITEM_NAME_COLOR,GetItemName((*pDiscount)[pos].awardId[i]),(int)(*pDiscount)[pos].awardNum[i]);
			gonggao += buf;

			awardType = 1;
		}
		else if((*pDiscount)[pos].awardType[i] == 2)	// 神将
		{
			int petId = (*pDiscount)[pos].awardId[i];
			::AddPet(pUser,petId,1);
			if(res.size() == 0)
				snprintf(buf,sizeof(buf),"%s",GetPetName(petId));
			else
				snprintf(buf,sizeof(buf),", %s",GetPetName(petId));
			res += buf;

			if(gonggao.size() == 0)
				snprintf(buf,sizeof(buf),"[c%d]%s[/c]",PetQualityColor[PQT_PURPLE],GetPetName(petId));
			else
				snprintf(buf,sizeof(buf),", [c%d]%s[/c]",PetQualityColor[PQT_PURPLE],GetPetName(petId));
			gonggao += buf;

			awardType = 2;
			petNum++;
			if(petNum == 1)
			{
				MakePetMsg(pUser,msg,petId);
			}
		}
		else if((*pDiscount)[pos].awardType[i] == 3)	// 神将蛋
		{
			uint8 quality = (*pDiscount)[pos].awardId[i];
			int petId = 0;
			if(quality == PQT_PURPLE)
			{
				int size = sizeof(PURPLE_PET_ID)/sizeof(PURPLE_PET_ID[0]);
				petId = PURPLE_PET_ID[Random(1,size)-1];
			}
			else if(quality == PQT_ORANGE)
			{
				int size = sizeof(ORANGE_PET_ID)/sizeof(ORANGE_PET_ID[0]);
				petId = ORANGE_PET_ID[Random(1,size)-1];
			}
			else if(quality == PQT_GOLD)
			{
				int size = sizeof(GOLD_PET_ID)/sizeof(GOLD_PET_ID[0]);
				petId = GOLD_PET_ID[Random(1,size)-1];
			}
			if(petId == 0)
				continue;

			::AddPet(pUser,petId,1);
			if(res.size() == 0)
				snprintf(buf,sizeof(buf),"%s",GetPetName(petId));
			else
				snprintf(buf,sizeof(buf),", %s",GetPetName(petId));
			res += buf;

			if(gonggao.size() == 0)
				snprintf(buf,sizeof(buf),"[c%d]%s[/c]",PetQualityColor[quality],GetPetName(petId));
			else
				snprintf(buf,sizeof(buf),", [c%d]%s[/c]",PetQualityColor[quality],GetPetName(petId));
			gonggao += buf;

			awardType = 2;
			petNum++;
			if(petNum == 1)
			{
				MakePetMsg(pUser,msg,petId);
			}
		}
		else if((*pDiscount)[pos].awardType[i] == 4)	// 非指定技能书
		{

			awardType = 1;
		}
	}

	string outStr = LANGUAGE_TRANSFORM_97 + res;
	msg.WriteData(typePos,&awardType,sizeof(awardType));
	msg<<MakeStringColor(outStr,TIPS_WARNING_COLOR);
	msg<<itemId<<leftAwardNum;
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
	if(type == 1)	// 新手
		ItemCurrencyLog(pUser->GetRoleId(),itemId,1,0,curPrice,pUser->GetTongBao(),YBL_SHOP_NEW_USER);
	else
		ItemCurrencyLog(pUser->GetRoleId(),itemId,1,0,curPrice,pUser->GetTongBao(),YBL_SHOP_DISCOUNT);

	char temp[512];
//	if(type == 1)
	snprintf(temp,sizeof(temp),LANGUAGE_TRANSFORM_98,ROLE_NAME_COLOR,pUser->GetName(),gonggao.c_str());
//	else
//		snprintf(temp,sizeof(temp),"恭喜[c%d]%s[/c]在【每日限购】获得%s，战斗力得到大幅提升！",ROLE_NAME_COLOR,pUser->GetName(),gonggao.c_str());
	SysInfoToAllUser(temp);

	//	if(type == 1)	// 新手特惠
	//	{
	//		uint16 usertotolNum = pUser->GetShopDiscountTotolNum();
	//		uint16 totolNum = 0;
	//		uint8 size = (uint8)m_discountItems_NewUser.size();
	//		msg<<size;
	//		for(uint8 idx=0;idx < size;idx++)
	//			totolNum += m_discountItems_NewUser[idx].vipCanBuyNum[vipLv];
	//		if(usertotolNum == totolNum)
	//		{
	//			pUser->ClearShopDiscountBuyNum();
	//			pUser->SetBitSet(227);
	//		}
	//	}
}

void CShopManager::ShowMysteryItems(CUser *pUser)
{
	if(pUser == NULL)
		return;

	boost::mutex::scoped_lock lk(m_shopItemsMutex);
	pUser->ShowMysteryItems(m_MysteryItem);
}

void CShopManager::ReFreshShenhunItems(CUser *pUser)
{
	CNetMessage msg;
	msg.SetType(MSG_SHOP);
	msg << (uint8)ESOP_ShenhunRefresh;

	if (pUser->GetTongBao() < REFRESH_SHENHUN_YB)
	{
		msg << PRO_ERROR << "";
		SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);
		ShowJumpNotice(pUser, JUMP_NOTICE_YB);
	}
	else
	{
		int level = pUser->GetLevel();
		pUser->AddTongBao(-REFRESH_SHENHUN_YB);
		boost::mutex::scoped_lock lk(m_shopItemsMutex);
		for (ShenjiangShopItemMapIt it = m_ShenhunItems.begin(); it != m_ShenhunItems.end(); ++it)
		{
			if (level < it->first.first || level > it->first.second)
			{
				continue;
			}
			pUser->CreateShenhunItem(it->second);
		}
		pUser->ClearAllShenhunBitSet();
		pUser->SendShenhunItemsInfo();
		msg << PRO_SUCCESS;
		ItemCurrencyLog(pUser->GetRoleId(), 0, 1, 0, REFRESH_SHENHUN_YB, pUser->GetTongBao(), YBL_SHOP_SHENHUN_REFRESH);
		SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);
	}
}

void CShopManager::ShowShenhunItems(CUser *pUser)
{
	if (pUser == NULL)
		return;
	int level = pUser->GetLevel();
	boost::mutex::scoped_lock lk(m_shopItemsMutex);
	for (ShenjiangShopItemMapIt it = m_ShenhunItems.begin(); it != m_ShenhunItems.end(); ++it)
	{
		if (level < it->first.first || level > it->first.second)
		{
			continue;
		}
		pUser->ShowShenhunItems(it->second);
	}
}


void CShopManager::ShowYaoShiItems(CUser *pUser)
{
	if(pUser == NULL)
		return;

	vector<HDPeiZhiInfo> info;
	uint32 hd_type = CHuoDongAwardManager::YAOSHI_SHANGDIAN;
	SingletonCHuoDongAwardManager::instance().GetPeiZhiInfo(info,hd_type);
	if (info.size() == 0)
		return;

	boost::mutex::scoped_lock lk(m_shopItemsMutex);
	pUser->ShowYaoShiItems(m_YaoShiItem,info);
}

void CShopManager::ShowFootPrintShopItems(CUser *pUser)
{
	if(pUser == NULL)
		return;

	vector<SFootPrintShopData> footShop;
	{
		boost::mutex::scoped_lock lk(m_shopItemsMutex);
		footShop = m_footShop;
	}
	pUser->ShowFootPrintItems(footShop);
}

void CShopManager::BuyFootPrint(CUser *pUser,int id,CNetMessage &msg)
{
	if(pUser == NULL || id < 1)
		return;
	vector<SFootPrintShopData> footShop;
	{
		boost::mutex::scoped_lock lk(m_shopItemsMutex);
		footShop = m_footShop;
	}
	pUser->BuyFootPrint(footShop,id,msg);
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void CShopManager::EquipFootPrint(CUser *pUser,int id,CNetMessage &msg)
{
	if(pUser == NULL || id < 1)
		return;
	pUser->EquipFootPrint(id,msg);
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void CShopManager::UnEquipFootPrint(CUser *pUser,int id,CNetMessage &msg)
{
	if(pUser == NULL || id < 1)
		return;
	pUser->UnEquipFootPrint(id,msg);
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

SFlowerData* CShopManager::GetFlowerCfg(int id)
{
	boost::mutex::scoped_lock lk(m_shopItemsMutex);
	for (uint32 i = 0; i < m_flowerShop.size(); i++)
	{
		if (m_flowerShop[i].itemId == id)
		{
			return &m_flowerShop[i];
		}
	}
	return NULL;
}

void CShopManager::ShowFlowerShopItems(CUser *pUser,CNetMessage &msg)
{
	if(pUser == NULL)
		return;
	{
		boost::mutex::scoped_lock lk(m_shopItemsMutex);
		msg<<(uint16)m_flowerShop.size();
		for(uint32 i=0;i < m_flowerShop.size();i++)
			msg<<m_flowerShop[i].itemId<<m_flowerShop[i].buy_type<<m_flowerShop[i].price;
	}
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}


void CShopManager::RequestFlowerShopAndSelfFlower(CUser *pUser)
{
	if(pUser == NULL){
		return;
	}

	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_FLOWER);
	msg<<(uint8)7; 

	// ===========================
	// 商店鲜花
	{
		boost::mutex::scoped_lock lk(m_shopItemsMutex);
		msg<<(uint32)m_flowerShop.size(); // 拥有鲜花的数量
		for(uint32 i=0;i < m_flowerShop.size();i++){
			msg<<(uint32)m_flowerShop[i].itemId;
			msg<<(uint32)m_flowerShop[i].buy_type;
			msg<<(uint32)m_flowerShop[i].price;
			msg<<(uint32)m_flowerShop[i].meili;
			msg<<(uint32)m_flowerShop[i].qinmi;
		}
	}

	vector<SFlowerData> flowerList;
	{
		boost::mutex::scoped_lock lk(m_shopItemsMutex);
		flowerList = m_flowerShop;
	}

	// ===========================
	// 玩家鲜花
	uint32 num = 0;
	CNetMessage myflower;
	for(uint32 i=0; i < flowerList.size();i++)
	{
		uint16 itemId = flowerList[i].itemId;
		int itemNum = pUser->GetItemNum(itemId);
		if(itemNum > 0)
		{
			myflower<<(uint32)itemId;
			myflower<<(uint32)itemNum;
			myflower<<(uint32)flowerList[i].meili;
			myflower<<(uint32)flowerList[i].qinmi;
			num++;
		}
	}
	msg<<num;
	msg<<myflower;

	//节日活动-赠送道具
	SingletonCHuoDongAwardManager::instance().MakeFestivalItem(msg);
	sock.SendMsg(pUser->GetSock(), msg);
}


void CShopManager::BuyFlower(CUser *pUser,int itemId,int buyNum,CNetMessage &msg)
{
	if(pUser == NULL || itemId < 1 || buyNum < 1)
		return;
	if(buyNum > 200)
		buyNum = 200;
	do
	{
		SFlowerData data;
		boost::mutex::scoped_lock lk(m_shopItemsMutex);
		for(uint32 i=0;i < m_flowerShop.size();i++)
		{
			if(m_flowerShop[i].itemId == itemId)
			{
				data = m_flowerShop[i];
				break;
			}
		}
		if(data.itemId == 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0235,TIPS_FAILURE_COLOR);
			break;
		}
		int price = data.price*buyNum;
		if(data.buy_type == 1)	// 元宝
		{
			if(pUser->GetTongBao() < price)
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0232,TIPS_FAILURE_COLOR);
				break;
			}
			pUser->AddTongBao(-price);
			ItemCurrencyLog(pUser->GetRoleId(),itemId,buyNum,data.buy_type,price,pUser->GetTongBao(),YBL_BUY_FLOWER);
		}
		else if(data.buy_type == 2)	// 绑元
		{
			if(pUser->GetTongBao(1) < price)
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0233,TIPS_FAILURE_COLOR);
				break;
			}
			pUser->AddTongBao(-price,1);
			ItemCurrencyLog(pUser->GetRoleId(),itemId,buyNum,data.buy_type,price,pUser->GetTongBao(1),YBL_BUY_FLOWER);
		}
		else if(data.buy_type == 3)	// 金币
		{
			if(pUser->GetMoney() < price)
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0234,TIPS_FAILURE_COLOR);
				break;
			}
			pUser->AddMoney(-price);
			ItemCurrencyLog(pUser->GetRoleId(),itemId,buyNum,data.buy_type,price,pUser->GetMoney(),YBL_BUY_FLOWER);
		}
		else
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0235,TIPS_FAILURE_COLOR);
			break;
		}
		pUser->AddBangDingPackage(data.itemId,buyNum);

		char buf[256];
		snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0239,GetItemName(data.itemId),buyNum);
		msg<<PRO_SUCCESS<<MakeStringColor(buf,TIPS_WARNING_COLOR);
	}while(0);
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void CShopManager::ShowSelfFlower(CUser *pUser,CNetMessage &msg)
{
	if(pUser == NULL)
		return;
	uint16 num=0;
	uint16 pos = msg.GetDataLen();
	msg<<num;

	vector<SFlowerData> flowerList;
	{
		boost::mutex::scoped_lock lk(m_shopItemsMutex);
		flowerList = m_flowerShop;
	}
	for(uint32 i=0;i < flowerList.size();i++)
	{
		uint16 itemId = flowerList[i].itemId;
		int itemNum = pUser->GetItemNum(itemId);
		if(itemNum > 0)
		{
			msg<<itemId<<itemNum<<flowerList[i].meili<<flowerList[i].qinmi;
			num++;
		}
	}
	if(num > 0)
		msg.WriteData(pos,&num,sizeof(num));
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void CShopManager::AddMeiLiValue(uint32 role_id,string &name,int value)
{
	if (!IsMeiliHuodongOpen())
	{
		return;
	}
	for(uint32 i=0;i < m_meiliData.size();i++)
	{
		if(m_meiliData[i].role_id == role_id)
		{
			m_meiliData[i].name = name;
			m_meiliData[i].mei_li += value;
			return;
		}
	}
	SMeiLiData data;
	data.role_id = role_id;
	data.name = name;
	data.mei_li = value;
	m_meiliData.push_back(data);
}


void CShopManager::ShowMeiLiPaiHang(CUser *pUser,CNetMessage &msg)
{
	uint32 type = CHuoDongAwardManager::XIANHUA_MEILI;
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	msg << PRO_SUCCESS;
	string desc = awardManager.GetHuoDongTimeDesc(type);
	uint32 endTime = awardManager.GetHuoDongEndTime(type);
	uint32 startTime = awardManager.GetHuoDongStartTime(type);
	uint32 curTime = GetSysTime(); // 当前时间
	uint32 cdTime = 0;
	if (curTime < startTime)
	{ // 未开始
		msg << (uint8)0;
	}
	else if (curTime > endTime)
	{// 已结束
		msg << (uint8)2;
	}
	else
	{// 进行中
		msg << (uint8)1;
		cdTime = endTime - startTime;
	}
	msg << desc << cdTime;
	boost::mutex::scoped_lock lk(m_shopItemsMutex);
	uint8 round = m_allRoundDatas.size() + 1;
	msg << (uint8)round << (uint8)m_meiliData.size();

	if (m_meiliData.size() > 1)
	{
		SSortMeiLi sortFunc;
		std::sort(m_meiliData.begin(), m_meiliData.end(), sortFunc);
	}

	uint8 myPaiHang = 0;
	int myMeili = 0;
	for (uint32 i = 0; i < m_meiliData.size(); i++)
	{
		SHuoDongAward award;
		awardManager.GetAwardDataByRange(type, 1, i + 1, award);

		msg << m_meiliData[i].role_id << m_meiliData[i].name.c_str() << "" << m_meiliData[i].mei_li;

		if (m_meiliData[i].role_id == pUser->GetRoleId())
		{
			myPaiHang = i + 1;
			myMeili = m_meiliData[i].mei_li;
		}

		uint16 pos = msg.GetDataLen();
		uint8 typeNum = 0;
		msg << typeNum;
		typeNum = MakeAwardMsg(pUser, award, type, msg);
		msg.WriteData(pos, &typeNum, sizeof(typeNum));
	}
	msg << IntToStr(myMeili) << (uint8)myPaiHang;
}

void CShopManager::ShowHistoryPaiHang(CUser *pUser, CNetMessage &msg)
{
	uint8 round = 0;
	msg >> round;
	if (round == 0)
	{
		round = m_allRoundDatas.size();
	}
	boost::mutex::scoped_lock lk(m_shopItemsMutex);
	sessionMeiliIt rit = m_allRoundDatas.find(round);
	if (rit == m_allRoundDatas.end())
	{
		msg << 0;
		return;
	}
	msg << (uint8)round;
	meiliDatas& curData = rit->second;
	msg << (uint8)curData.size();
	for (uint8 i = 0; i < curData.size(); ++i)
	{
		msg << (int)(i + 1) << curData[i].role_id << curData[i].name << curData[i].mei_li << (uint16)curData[i].title;
	}
}

void CShopManager::SetRoleName(uint32 role_id,const char *name)
{
	boost::recursive_mutex m_mutex;
	// sessionMeiliIt mapIter;
	// for( mapIter = m_allRoundDatas.begin() ; mapIter != m_allRoundDatas.end() ; ++mapIter )
	// {
	// 	meiliDatas &curData = mapIter->second;
	// 	for (uint8 i = 0; i < curData.size(); ++i)
	// 	{
	// 		if(curData[i].role_id == role_id)
	// 		{
	// 			curData[i].name = name;
	// 		}
	// 	}
	// }

	if(!InHuoDongTime(CHuoDongAwardManager::XIANHUA_MEILI))
		return;
	for (uint32 i = 0; i < m_meiliData.size(); i++)
	{
		if (m_meiliData[i].role_id == role_id)
		{
			m_meiliData[i].name = name;
		}
	}
}

bool CShopManager::SendFlowerToFriend(CUser *pUser,uint16 itemId,int itemNum,int roleId,CNetMessage &msg)
{
	if(itemId == 0 || itemNum == 0 || roleId == 0)
		return false;
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return false;

	char buf[1024];
	if(pUser->GetItemNum(itemId) < itemNum)
	{
		snprintf(buf, sizeof(buf),LANGUAGE_SSJ_0240,GetItemName(itemId));
		msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
		return true;
	}
/*	if(!pUser->IsHot(roleId))
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0241,TIPS_FAILURE_COLOR);
		return true;
	}
*/
	string name;
	SFlowerData flowerData;
	{
		string qingMiStr = GetQinMiStr(pUser->GetRoleId(),roleId);
		boost::mutex::scoped_lock lk(m_shopItemsMutex);
		map<string,int>::iterator it = m_qinmiData.find(qingMiStr);
		if(it == m_qinmiData.end())
		{
			pair<map<string,int>::iterator,bool> ret = m_qinmiData.insert(make_pair(qingMiStr,0));
			if(ret.second)
				it = ret.first;
			else
				return false;
		}

		{
			for(uint32 i=0;i < m_flowerShop.size();i++)
			{
				if(m_flowerShop[i].itemId == itemId)
				{
					flowerData = m_flowerShop[i];
					break;
				}
			}
		}
		if(flowerData.itemId != itemId)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0235,TIPS_FAILURE_COLOR);
			return true;
		}
		pUser->DelPackageById(itemId,itemNum);
		pUser->SetExtData32(440,pUser->GetExtData32(440)+itemNum);
		snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0242,roleId);
		SaveUseItem(pUser->GetRoleId(),itemId,buf,itemNum);
		it->second += flowerData.qinmi*itemNum;

		char rname[128];
		if(GetRoleName(roleId,rname) > 0)
		{
			name = rname;
			AddMeiLiValue(roleId,name,flowerData.meili*itemNum);
		}
		msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_SSJ_0243,TIPS_WARNING_COLOR);
	}

	ShareUserPtr ptr = SingletonOnlineUser::instance().GetUserByRoleId(roleId);
	CUser *pU = ptr.get();
	if(pU != NULL)
	{
		pU->SetExtData32(441,pU->GetExtData32(441)+itemNum);
		pU->SetExtData32(465, pU->GetExtData32(465) + flowerData.meili*itemNum);
		pU->SendUpdateInfo(EUUT_MeiLi);
	}
	else
	{
		pU = new CUser;
		if(pU->ReadDataSimple(roleId))
		{
			pU->SetExtData32(441, pU->GetExtData32(441) + itemNum);
			pU->SetExtData32(465, pU->GetExtData32(465) + flowerData.meili*itemNum);
			pU->SaveDataSimple();
		}
		delete pU;
		pU = NULL;
	}
	
	snprintf(buf,sizeof(buf),"insert into mei_li_send_log (sender_id,sender_name,recv_id,recv_name,item_id,num,time) values(%u,'%s',%d,'%s',%u,%d,%u)",
		pUser->GetRoleId(),pUser->GetName(),roleId,name.c_str(),itemId,itemNum,(uint32)GetSysTime());
	pDb->Query(buf);

	snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0253,name.c_str(),pUser->GetName(),GetItemName(itemId),itemNum,name.c_str());
	SysInfoToAllUser(buf);
	return true;
}


void CShopManager::ReFreshMysteryItems(CUser *pUser)
{
	CNetMessage msg;
	msg.SetType(MSG_SHOP);
	msg<<(uint8)ESOP_MysteryRefresh;

	if(pUser->GetTongBao() < REFRESH_MYSTERY_YB)
	{
		msg<<PRO_ERROR<<"";
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		ShowJumpNotice(pUser,JUMP_NOTICE_YB);
	}
	else
	{
		pUser->AddTongBao(-REFRESH_MYSTERY_YB);
		pUser->CreateMysteryItem(m_MysteryItem);
		pUser->ClearAllMysteryBitSet();
		pUser->SendMysterItemsInfo();
		msg<<PRO_SUCCESS;
		ItemCurrencyLog(pUser->GetRoleId(),0,1,0,REFRESH_MYSTERY_YB,pUser->GetTongBao(),YBL_SHOP_MYSTERY_REFRESH);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
	}	
}

void CShopManager::ReFreshYaoShiItems(CUser *pUser)
{
	CNetMessage msg;
	msg.SetType(MSG_SHOP);
	msg<<(uint8)ESOP_YaoShiRefresh;

	vector<HDPeiZhiInfo> info;
	uint32 hd_type = CHuoDongAwardManager::YAOSHI_SHANGDIAN;
	SingletonCHuoDongAwardManager::instance().GetPeiZhiInfo(info,hd_type);
	if (info.size() == 0)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1511,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}

	if(pUser->GetYaoShi() < REFRESH_YAOSHI_YB)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0241,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
	}
	else
	{
		pUser->SetYaoShi(pUser->GetYaoShi() - REFRESH_YAOSHI_YB);
		pUser->SetCostYaoShi(pUser->GetCostYaoShi() + REFRESH_YAOSHI_YB);
		pUser->CreateYaoShiItem(m_YaoShiItem);
		pUser->SendYaoShiItemsInfo(info);
		msg<<PRO_SUCCESS<<pUser->GetYaoShi()<<pUser->GetCostYaoShi();
		ItemCurrencyLog(pUser->GetRoleId(),0,1,0,REFRESH_YAOSHI_YB,pUser->GetYaoShi(),YBL_SHOP_YAOSHI_REFRESH);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
	}	
}


// 购买商城物品
void CShopManager::Buy(CUser* pUser, int type, int itype, uint16 ivalue, uint16 exvalue, uint8 buyNum)
{
	if (pUser == NULL)
		return;
	
	time_t curTime = GetSysTime();
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_SHOP);
	msg<<(uint8)ESOP_Buy<<(uint8)type;
	
	// 合法性校验
	if((buyNum == 0) || (buyNum > EItemDieJiaNum))
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_99,TIPS_FAILURE_COLOR);
		sock.SendMsg(pUser->GetSock(),msg);
		return;
	}
	CShopItem* pSItem = GetShopItem(type, itype, ivalue, exvalue);
	if (pSItem == NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_100,TIPS_FAILURE_COLOR);
		sock.SendMsg(pUser->GetSock(),msg);
		return;
	}

	if (pSItem->m_startTime != 0 && ((pSItem->m_startTime > curTime) || (pSItem->m_endTime <= curTime)))
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_101,TIPS_FAILURE_COLOR);
		sock.SendMsg(pUser->GetSock(),msg);
		return;
	}
	
	if (type == ESIT_XIANSHI)
	{
		if ((pSItem->m_limit-pSItem->m_count) < (int)buyNum)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_102,TIPS_FAILURE_COLOR);
			sock.SendMsg(pUser->GetSock(),msg);
			return;
		}
	}
	int price = pSItem->m_price;
	if (pSItem->m_offPrice != 0)
		price = pSItem->m_offPrice;
	if (price < 0)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_103,TIPS_FAILURE_COLOR);
		sock.SendMsg(pUser->GetSock(),msg);
		return;
	}
	int needMoney = price * buyNum;
	if (type == ESIT_JINGJIJIFEN) // 竞技场积分购买
	{
		//if (pUser->GetLevel() < 33) // 购买等级限制
		//{
		//	msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_104,TIPS_FAILURE_COLOR);
		//	sock.SendMsg(pUser->GetSock(),msg);
		//	return;
		//}
		int curJiFen = pUser->GetArenaJiFen();
		if (curJiFen < needMoney)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_105,TIPS_FAILURE_COLOR);
			sock.SendMsg(pUser->GetSock(),msg);
			return;
		}
	}
	else if (type == ESIT_BANGGONG)	// 帮贡商店
	{
		int curBangGong = pUser->GetBangGong();
		if(curBangGong < needMoney)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_106,TIPS_FAILURE_COLOR);
			sock.SendMsg(pUser->GetSock(),msg);
			return;
		}
	}
	else if (type == ESIT_BANGDING) // 绑定元宝购买
	{
		int bdTongbao = pUser->GetTongBao(1);
		if (bdTongbao < needMoney)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_107,TIPS_FAILURE_COLOR);
			sock.SendMsg(pUser->GetSock(),msg);
			return;
		}
	}
	else if (type == ESIT_LEITAIJIFEN)
	{
		int jifen = pUser->GetJifen();
		if (jifen < needMoney)
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_LLD_0195, TIPS_FAILURE_COLOR);
			sock.SendMsg(pUser->GetSock(), msg);
			return;
		}
	}
	else // 元宝购买
	{
		int tongbao = pUser->GetTongBao();
		if (tongbao < needMoney)
		{
			msg<<PRO_ERROR<<"";
			sock.SendMsg(pUser->GetSock(),msg);
			ShowJumpNotice(pUser,JUMP_NOTICE_YB);
			return;
		}
	}

	// 购买
	if (type == ESIT_JINGJIJIFEN) // 竞技场积分
	{
		if (pUser->AddMutilMaterial(itype, ivalue, exvalue, buyNum))
		{
			pUser->AddArenaJiFen(-needMoney);
			msg<<PRO_SUCCESS<<pUser->GetArenaJiFen();
			sock.SendMsg(pUser->GetSock(),msg);
			SaveLog(pUser,type,itype, ivalue,needMoney); // 记录
			return;
		}
	}
	else if (type == ESIT_BANGGONG)	// 帮贡商店
	{
		if (pUser->AddMutilMaterial(itype, ivalue, exvalue, buyNum))
		{
			SingletonCBangPaiManager::instance().AddBangGong(pUser,-needMoney);
			msg<<PRO_SUCCESS<<pUser->GetBangGong();
			sock.SendMsg(pUser->GetSock(),msg);
			SaveLog(pUser,type,itype, ivalue,needMoney); // 记录
			pUser->UpdateBangHuoYue(EBHT_ShopBuy,buyNum);
			return;
		}
	}
	else if (type == ESIT_BANGDING)
	{
		if (pUser->AddMutilMaterial(itype, ivalue, exvalue, buyNum))
		{
			pUser->AddTongBao(-needMoney,1);
			msg<<PRO_SUCCESS<<(int)pUser->GetTongBao()<<(int)pUser->GetTongBao(1);
			sock.SendMsg(pUser->GetSock(),msg);
			SaveLog(pUser,type,itype, ivalue,needMoney); // 记录
			pUser->SetBitSet(170); // 每日活跃度 商城消费
			return;
		}
	}
	else if (type == ESIT_LEITAIJIFEN)
	{
		if (pUser->AddMutilMaterial(itype, ivalue, exvalue, buyNum))
		{
			pUser->AddJifen(-needMoney);
			msg << PRO_SUCCESS << (int)pUser->GetJifen();
			sock.SendMsg(pUser->GetSock(), msg);
			SaveLog(pUser, type, itype, ivalue, needMoney); // 记录
			return;
		}
	}
	else	// 元宝
	{
		bool result = pUser->AddMutilMaterial(itype, ivalue, exvalue, buyNum);
		if(result)
		{
			pUser->AddTongBao(-needMoney);
			if (type == ESIT_XIANSHI) // 更新抢购数据
			{
				pSItem->m_count += buyNum;
				SaveLimitItemBuyCount(pSItem->m_id, buyNum);
			}
			msg<<PRO_SUCCESS<<(int)pUser->GetTongBao()<<(int)pUser->GetTongBao(1);
			sock.SendMsg(pUser->GetSock(),msg);
			SaveLog(pUser,type,itype, ivalue,needMoney); // 记录
			pUser->SetBitSet(170); // 每日活跃度 商城消费
			return;
		}
	}
	msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_108,TIPS_FAILURE_COLOR);
	sock.SendMsg(pUser->GetSock(),msg);
}

// 刷新抢购道具的购买数量
void CShopManager::RefreshCount(CUser* pUser)
{
	if (pUser == NULL)
		return;

	CNetMessage msg;
	msg.SetType(MSG_SHOP);
	msg<<(uint8)ESOP_RefreshCount;
	time_t curTime = GetSysTime();
	uint16 pos = msg.GetDataLen();
	uint8 num = 0;
	msg<<(uint8)num;
	int leftCnt = 0;
	boost::mutex::scoped_lock lk(m_shopItemsMutex);
	for (itShopItems_t it = m_shopItems.begin(); it != m_shopItems.end(); ++it)
	{
		if (it->m_type == CShopManager::ESIT_XIANSHI)
		{
			if ((it->m_startTime <= curTime) && (it->m_endTime > curTime))
			{
				++num;
				leftCnt = it->m_limit-it->m_count;
				if (leftCnt < 0)
					leftCnt = 0;
				msg<<leftCnt;
				if (num >= 2)
					break;
			}
		}
		else
			break;
	}
	msg.WriteData(pos,&num,1);
	CSocketServer &sock = SingletonSocket::instance();
	sock.SendMsg(pUser->GetSock(),msg);
}

// 获取商品
CShopItem* CShopManager::GetShopItem(int stype, int itype, int value/* = 0*/, int extValue/* = 0*/)
{
	boost::mutex::scoped_lock lk(m_shopItemsMutex);
	for (itShopItems_t it = m_shopItems.begin(); it != m_shopItems.end(); ++it)
	{
		if ((it->m_type == stype) && (it->m_itemId == itype && it->value == value && it->extValue == extValue))
		{
			return &(*it);
		}
	}
	return NULL;
}

// 保存购买记录
void CShopManager::SaveLog(CUser* pUser, int type, int itemId, int itemNum, int costMoney)
{
	if(pUser == NULL)
		return;
	if(type == ESIT_JINGJIJIFEN)
		ItemCurrencyLog(pUser->GetRoleId(),itemId,itemNum,0,costMoney,pUser->GetArenaJiFen(),type);
	else if (type == ESIT_ZaDanJiFen)
		ItemCurrencyLog(pUser->GetRoleId(), itemId, itemNum, 0, costMoney, pUser->GetExtData32(12), type);
	else if (type == ESIT_ZaDanJiFenCopy)
		ItemCurrencyLog(pUser->GetRoleId(), itemId, itemNum, 0, costMoney, pUser->GetExtData32(468), type);
	else if (type == ESIT_HongLiJiFen)
		ItemCurrencyLog(pUser->GetRoleId(),itemId,itemNum,0,costMoney,pUser->GetExtData32(282),type);
	else if (type == ESIT_BANGDING)
		ItemCurrencyLog(pUser->GetRoleId(),itemId,itemNum,0,costMoney,pUser->GetTongBao(1),type);
	else if (type == ESIT_BANGGONG)
		ItemCurrencyLog(pUser->GetRoleId(),itemId,itemNum,0,costMoney,pUser->GetBangGong(),type);
	else
		ItemCurrencyLog(pUser->GetRoleId(),itemId,itemNum,0,costMoney,pUser->GetTongBao(),type);
}

// 保存限制数量道具的购买数量
void CShopManager::SaveLimitItemBuyCount(int id, int itemNum)
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if (pDb == NULL)
	{
		cout << "Error:SaveLimitItemBuyCount Get db connect error." << endl;
		return;
	}
	char sql[128];
	snprintf(sql,sizeof(sql),"update shop set count=count+%d where id = %d;",itemNum,id);
	pDb->Query(sql);
}

CRiChangFuBenManager::CRiChangFuBenManager()
{
}

CRiChangFuBenManager::~CRiChangFuBenManager()
{
	m_eRiChangFuBenList.clear();
}

bool CRiChangFuBenManager::Load()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if (pDb == NULL)
		return false;

	//                           0        1    2        3        4       5        6     7    8       9          10         11       12         13         14        15         16        17       18         19         20
	if (!pDb->Query("select fuben_index,name,level,enterlimit,reward1,extdata8,mop_time,mobs,type,lvup_type1,lvup_value1,condes1,lvup_type2,lvup_value2,condes2,lvup_type3,lvup_value3,condes3,lvup_type4,lvup_value4,condes4,"\
	//       21          22         23       24       25      26
		"desc_title,desc_ratio,desc_ratio1,reward2,reward3,reward4,sceneId from fuben_richang where isShow=1 order by id asc"))
		return false;

	ERiChangFuBen riChang;
	char** row;
	while ((row = pDb->GetRow()) != NULL)
	{
		riChang.id = (uint16)atoi(row[0]);
		riChang.name = row[1];
		riChang.level = (uint16)atoi(row[2]);
		riChang.enterLimit = (uint8)atoi(row[3]);
		riChang.reward[0] = row[4];
		riChang.reward[1] = row[24];
		riChang.reward[2] = row[25];
		riChang.reward[3] = row[26];
		riChang.sceneId = atoi(row[27]);
		riChang.extdata8 = (uint16)atoi(row[5]);
		riChang.mopTime = (uint16)atoi(row[6]);
		riChang.mobs = row[7];
		riChang.type = (uint8)atoi(row[8]);
		for(int i=0;i<4;i++)
		{
			riChang.lvuptype[i]=atoi(row[9+3*i]);
			riChang.lvupvalue[i]=atoi(row[10+3*i]);
			riChang.condes[i]=row[11+3*i];
		}
		riChang.desc_title = row[21];
		riChang.desc_ratio[0] = row[22];
		riChang.desc_ratio[1] = row[23];
		m_eRiChangFuBenList.push_back(riChang);
	}
	return true;
}

void CRiChangFuBenManager::ListFuBen(CUser *pUser,CNetMessage &msg)
{
	uint8 num = m_eRiChangFuBenList.size();
	msg<<num;
	for(list<ERiChangFuBen>::iterator it = m_eRiChangFuBenList.begin(); it != m_eRiChangFuBenList.end(); ++it)
	{
		uint8 fbLv = pUser->GetFBLevel(it->id);
		uint8 enterLimit = it->enterLimit;
		/*uint8 monCardValue = pUser->GetMonthCard();
		if((monCardValue & 0x2) > 0)
			enterLimit += 1;
		if((monCardValue & 0x4) > 0)
			enterLimit += 2;*/
		string reward = (fbLv > 0) ? it->reward[fbLv-1] : it->reward[0];
		msg<<it->id<<it->name<<it->level<<(uint8)0<<enterLimit;
		msg<<reward<<pUser->GetExtData8(it->extdata8)<<it->type;
		if(pUser->GetLevel() >= SaoDangLevelLimit)
		{
			if(pUser->GetFBTongGuan(it->id))
				msg<<(uint8)1; 
			else
				msg<<(uint8)0; //没有通关过，不可以扫荡
		}
		else
			msg<<(uint8)0;
		msg<<fbLv;
		if(fbLv==MAX_FUBEN_LEVEL)
			msg<<LANGUAGE_TRANSFORM_112;
		else
			msg<<it->condes[fbLv];

		if(pUser->GetExtData8(it->extdata8) >= enterLimit)
			msg<<pUser->GetEnterFBMoney(it->id,true)<<it->desc_title<<it->desc_ratio[1];
		else
			msg<<pUser->GetEnterFBMoney(it->id,false)<<it->desc_title<<it->desc_ratio[0];
	}
}

void CRiChangFuBenManager::QueryFuBenCiShu(CUser *pUser,CNetMessage &msg)
{
	uint8 num = m_eRiChangFuBenList.size();
	msg<<num;
	for (list<ERiChangFuBen>::iterator it = m_eRiChangFuBenList.begin(); it != m_eRiChangFuBenList.end(); ++it)
	{
		msg<<it->id;
		if(pUser->GetFBLevel(it->id)>0)
		{
			uint8 enterLimit = it->enterLimit;
			/*uint8 monCardValue = pUser->GetMonthCard();
			if((monCardValue & 0x2) > 0)
				enterLimit += 1;
			if((monCardValue & 0x4) > 0)
				enterLimit += 2;*/
			msg<<enterLimit<<pUser->GetExtData8(it->extdata8);
		}
		else
			msg<<(uint8)0<<(uint8)0;
	}
}

ERiChangFuBen* CRiChangFuBenManager::FindFuBen(int id)
{
	for (list<ERiChangFuBen>::iterator it = m_eRiChangFuBenList.begin(); it != m_eRiChangFuBenList.end(); ++it)
	{
		if(it->id==id)
			return &(*it);
	}
	return NULL;
}

void CRiChangFuBenManager::CheckFuBenLevel(CUser *pUser)
{
	int myvalue;
	const char *Level_Name[]={LANGUAGE_TRANSFORM_113,LANGUAGE_TRANSFORM_114,LANGUAGE_TRANSFORM_115,LANGUAGE_TRANSFORM_116,LANGUAGE_TRANSFORM_117};
	const char *Cond_Name[]={LANGUAGE_TRANSFORM_118,LANGUAGE_TRANSFORM_119,LANGUAGE_TRANSFORM_120,LANGUAGE_TRANSFORM_121,LANGUAGE_TRANSFORM_122,LANGUAGE_TRANSFORM_123};
	char buf[128];
	uint8 fbLv;
	
	for (list<ERiChangFuBen>::iterator it = m_eRiChangFuBenList.begin(); it != m_eRiChangFuBenList.end(); ++it)
	{
		fbLv=pUser->GetFBLevel(it->id);
		for(int i=fbLv+1;i<5;i++)
		{
			if(it->lvuptype[i-1]==0)
				break;
			switch(it->lvuptype[i-1])
			{
			case 1:
				myvalue=pUser->GetLevel();
				break;
			case 2:
				myvalue=pUser->GetZhanDouLi();
				break;
			case 3:
//				myvalue=pUser->GetTotalZhanDouLi();
				break;
			case 4:
				myvalue=pUser->GetPetNumByLimitQuality(PQT_PURPLE);
				break;
			case 5:
				myvalue=pUser->GetPetNumByLimitQuality(PQT_ORANGE);
				break;
			case 6:
				myvalue=pUser->GetVipLevel();
				break;
			}
			if((fbLv==i-1) && myvalue>=it->lvupvalue[i-1])
			{
				pUser->UpgradeFBLevel(it->id);
				if(fbLv>0) //副本开启不提示
				{
					snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_124,Cond_Name[it->lvuptype[i-1]-1],it->name.c_str(),Level_Name[fbLv+1]);
					SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
				}
				fbLv++;
			}
		}
	}
}

PracticeTemple::PracticeTemple()
{
	for(int i=0;i < TYPE_NUM;i++)
	{
		for(int j=0;j < USER_LIMIT_NUM;j++)
			m_userList[i][j].reset();
	}
}

PracticeTemple::~PracticeTemple()
{

}

void PracticeTemple::Init()
{
	const int type = 1;
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
	char sql[256];
	snprintf(sql,sizeof(sql),"select typeInfo,role_id from role_mirror where type=%d",type);
	if(!pDb->Query(sql))
		return;

	char **row = NULL;
	boost::mutex::scoped_lock lk(m_mutex);
	while((row = pDb->GetRow()) != NULL)
	{
		string typeInfo = row[0];
		if(typeInfo.empty())
			continue;

		char *split[2];
		if(SplitLine(split,2,(char*)typeInfo.c_str()) < 2)
			continue;
		int typeIdx = atoi(split[0]);
		int uIdx = atoi(split[1]);
		if(typeIdx >= TYPE_NUM || uIdx >= USER_LIMIT_NUM)
			continue;

		CUser *pUser = new CUser;
		pUser->SetRoleId((uint32)atoi(row[1]));
		pUser->SetSock(-1);
		ShareUserPtr ptr(pUser);
		m_userList[typeIdx][uIdx] = ptr;
	}

	for(uint8 i=0;i < sizeof(m_userList)/sizeof(m_userList[0]);i++)
	{
		for(uint8 j=0;j < sizeof(m_userList[i])/sizeof(m_userList[i][0]);j++)
		{
			if(m_userList[i][j].get() != NULL && !m_userList[i][j]->ReadMirrorRoleData(type))
				m_userList[i][j].reset();
		}
	}
}

ShareUserPtr PracticeTemple::GetPracticeUser(int type,int uIdx)
{
	ShareUserPtr t;
	if(type >= TYPE_NUM || uIdx >= USER_LIMIT_NUM)
		return t;
	boost::mutex::scoped_lock lk(m_mutex);
	return m_userList[type][uIdx];
}

void PracticeTemple::SetPracticeUser(int type,int uIdx,CUser *pUser)
{
	if(pUser == NULL|| type >= TYPE_NUM || uIdx >= USER_LIMIT_NUM)
		return;

	boost::mutex::scoped_lock lk(m_mutex);
	ShareUserPtr ptr(pUser);
	m_userList[type][uIdx] = ptr;
}

bool InitVipConfig()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
	{
		cout << "Error:InitVipConfig Get db connect error." << endl;
		return false;
	}

	char sql[512];
	char** row = NULL;

	//                        0    1      2     3      4       5     6       7      8     9    10    11        12
	snprintf(sql,sizeof(sql),"select vip,yuanbao,lingqi,arenatz,arenabuy,bosstz,bossbuy,openshop,fxdown,fxexp,offline,zhongzhi,jingbi_tree,"\
	//        13         14        15       16     17      18    19      20      21       22       23          24
		"yuanbao_tree,neidan_tree,jingyan_tree,awardt1,awardn1,awardt2,awardn2,awardt3,awardn3,yaoqianshu,yaoqianshu2, sweep_copy,"\
	//         25
		"fengshen_shilian from vip_def");
	if(!pDb->Query(sql))
	{
		cout << "Error:InitVipConfig query shop_discount_save error." << endl;
		return false;
	}
	char buf[1024];
	while((row = pDb->GetRow()) != NULL)
	{
		uint8 viplv=atoi(row[0]);
		if(viplv>15)
		{
			cout << "Error:InitVipConfig viplv error:" << viplv<<endl;
			continue;
		}
		G_VipConfig[viplv].yuanbao=atoi(row[1]);
		G_VipConfig[viplv].lingqi=atoi(row[2]);
		G_VipConfig[viplv].arenatz=atoi(row[3]);
		G_VipConfig[viplv].arenabuy=atoi(row[4]);
		G_VipConfig[viplv].bosstz=atoi(row[5]);
		G_VipConfig[viplv].bossbuy=atoi(row[6]);
		G_VipConfig[viplv].openshop=atoi(row[7]);
		G_VipConfig[viplv].fxdown=atoi(row[8]);
		G_VipConfig[viplv].fxexp=atoi(row[9]);
		G_VipConfig[viplv].offline=atoi(row[10]);
		G_VipConfig[viplv].bpzhongzhi=atoi(row[11]);
		for(int i=0;i<4;i++)
			G_VipConfig[viplv].seedtype[i]=atoi(row[12+i]);
		for(int i=0;i<3;i++)
		{
			G_VipConfig[viplv].awardt[i]=atoi(row[16+2*i]);
			G_VipConfig[viplv].awardn[i]=atoi(row[16+2*i+1]);
		}
		G_VipConfig[viplv].yaoqianshuNum[0] = atoi(row[22]);
		G_VipConfig[viplv].yaoqianshuNum[1] = atoi(row[23]);
		G_VipConfig[viplv].fengShenNum = atoi(row[25]);

		if (viplv > 0)
		{
			G_VipConfig[viplv].sweepCopys = G_VipConfig[viplv - 1].sweepCopys;
		}

		string sweepStr = row[24];
		if (sweepStr.empty())
			continue;
		int num = 0;
		char *p[100];
		strncpy(buf, sweepStr.c_str(), sizeof(buf));
		num = SplitLine(p, buf, ';');
		for (int si = 0; si < num; si++)
		{
			int fid = atoi(p[si]);
			G_VipConfig[viplv].sweepCopys.insert(fid);
		}
	}
	return true;
}


//////////////////////////////////////////////////////////////////////

bool CHDExchangeManager::Init()
{
	if(!InitHDDrop_New())
		return false;
	return true;

/*
	if(!InitExchangeDrop())
		return false;
	if(!InitExchangeMap())
		return false;
	if(!InitHDDrop())
		return false;
	
	return true;
*/
	//Print();
}

bool CHDExchangeManager::InitExchangeDrop()
{
	m_dropList.clear();

	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char sql[512];
	char **row = NULL;
	if(pDb == NULL)
		return false;
	//									0	1		2	3		4		  5
	snprintf(sql, sizeof(sql), "select id,name,item_id,ratio,limit_num,ext8_idx from hd_exchange_drop order by id asc");
	if(!pDb->Query(sql))
		return false;
	int num = pDb->GetRowNum();
	if(num > 0)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		HD_Exchange_Drop data;
		while((row = pDb->GetRow()) != NULL)
		{
			data.hd_id = (uint32)atoi(row[0]);
			data.hd_name = row[1];
			data.itemId = (uint32)atoi(row[2]);
			data.ratio = (uint16)atoi(row[3]);
			data.dropNum_limit = (uint16)atoi(row[4]);
			data.ext8_idx = (uint16)atoi(row[5]);
			m_dropList.insert(make_pair(data.hd_id,data));
		}
	}
	return true;
}

bool CHDExchangeManager::InitExchangeMap()
{
	m_exchangeList.clear();

	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char sql[512];
	char **row = NULL;
	if(pDb == NULL)
		return false;

	//										0		1			2			3				4		  5				6			7				8			9	10	  11
	snprintf(sql, sizeof(sql), "select targetId,target_num,material_1,material_1_num,material_2,material_2_num,material_3,material_3_num,exchange_num_limit,day,id,saveExt8 from hd_exchange_list order by day,id asc");
	if(!pDb->Query(sql))
		return false;
	int num = pDb->GetRowNum();
	if(num > 0)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		HD_Exchange_Data edata;
		while((row = pDb->GetRow()) != NULL)
		{
			uint16 dayIdx = (uint16)atoi(row[9]);
			if(dayIdx == 0)
				continue;
			
			map< uint16,exchangeMap >::iterator it = m_exchangeList.find(dayIdx);
			if(it == m_exchangeList.end())
			{
				exchangeMap temp;
				pair<map<uint16,exchangeMap>::iterator,bool> t = m_exchangeList.insert(make_pair(dayIdx,temp));
				if(t.second)
					it = t.first;
			}
			if(it == m_exchangeList.end())
				continue;
			edata.id = (uint32)atoi(row[10]);
			edata.saveExt8 = (uint16)atoi(row[11]);
			edata.targetId = (uint32)atoi(row[0]);
			edata.targetNum = (uint32)atoi(row[1]);
			edata.material[0] = (uint32)atoi(row[2]);
			edata.materialNum[0] = (uint32)atoi(row[3]);
			edata.material[1] = (uint32)atoi(row[4]);
			edata.materialNum[1] = (uint32)atoi(row[5]);
			edata.material[2] = (uint32)atoi(row[6]);
			edata.materialNum[2] = (uint32)atoi(row[7]);
			edata.exchangeNumLimit = (uint8)atoi(row[8]);
			it->second.insert(make_pair(edata.id,edata));
		}
	}

	if(!pDb->Query("select sum(exchange_num_limit) from hd_exchange_list"))
		return false;
	if((row = pDb->GetRow()) != NULL)
		m_totalLimitNum = atoi(row[0]);
	return true;
}

bool CHDExchangeManager::InitHDDrop()
{
	map<uint32,HD_Exchange_Drop> *hdDropList = NULL;
	string tableName = "";

	for (uint32 i = 0; i < sizeof(ITEMDROP_TYPE)/sizeof(ITEMDROP_TYPE[0]); i++)
	{
		uint32 hd_type = ITEMDROP_TYPE[i];

		switch(hd_type) 
		{
		case CHuoDongAwardManager::FESTIVAL:
			hdDropList = &m_festivalDropList;
			tableName = "festival_drop";
			break;
		//case CHuoDongAwardManager::MEIRI_HUANHAOLI:
		//	hdDropList = &m_huanHaoLiDropList;
		//	tableName = "huan_haoli_drop";
		//	break;
		case CHuoDongAwardManager::SHENGDAN_FENGSHOU:
			hdDropList = &m_christmasTreeDropList;
			tableName = "hd_christmastree_drop";
			break;
		case CHuoDongAwardManager::XINCHUN_HAPPY:
			hdDropList = &m_xinchunhappyDropList;
			tableName = "xinchuan_happy_drop";
			break;
		case CHuoDongAwardManager::ZHENYING_PK1:
			hdDropList = &m_zhenyingPK1DropList;
			tableName = "zhenying_pk1_drop";
			break;
		case CHuoDongAwardManager::ZHENYING_PK2:
			hdDropList = &m_zhenyingPK2DropList;
			tableName = "zhenying_pk2_drop";
			break;
		default:
			return false;
		}

		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		char sql[512];
		char **row = NULL;
		if(pDb == NULL)
			return false;
		//									0	1		2	   3	4		  5      6        7
		snprintf(sql, sizeof(sql), "select id,name,item_id,item_num,ratio,limit_num,ext8_idx,type from %s order by id asc",tableName.c_str());
		if(!pDb->Query(sql))
			return false;
		int num = pDb->GetRowNum();
		if(num > 0)
		{
			boost::recursive_mutex::scoped_lock lk(m_mutex);
			hdDropList->clear();
			HD_Exchange_Drop data;
			while((row = pDb->GetRow()) != NULL)
			{
				data.hd_id = (uint32)atoi(row[0]);
				data.hd_name = atoi(row[1]);
				data.itemId = (uint32)atoi(row[2]);
				data.itemNum = (uint32)atoi(row[3]);
				data.ratio = (uint16)atoi(row[4]);
				data.dropNum_limit = (uint16)atoi(row[5]);
				data.ext8_idx = (uint16)atoi(row[6]);

				data.hd_type.clear();
				string hd_type = row[7];
				char *split[100];
				int num = SplitLine(split, (char *)hd_type.c_str(), '|');
				for (int i = 0; i < num; i++)
					data.hd_type.push_back(atoi(split[i]));

				hdDropList->insert(make_pair(data.hd_id,data));
			}
		}
	}
	return true;
}

bool CHDExchangeManager::InitHDDrop_New()
{
	map<uint32,HD_Exchange_Drop_New> *hdDropList = NULL;
	string tableName = "";

	for (uint32 i = 0; i < sizeof(ITEMDROP_TYPE_NEW)/sizeof(ITEMDROP_TYPE_NEW[0]); i++)
	{
		uint32 hd_type = ITEMDROP_TYPE_NEW[i];

		switch(hd_type) 
		{

		case CHuoDongAwardManager::MEIRI_HUANHAOLI:
			hdDropList = &m_huanHaoLiDropList;
			tableName = "huan_haoli_drop";
			break;
		default:
			return false;
		}

		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		char sql[512];
		char **row = NULL;
		if(pDb == NULL)
			return false;
		//									0	1		2	   3		4		
		snprintf(sql, sizeof(sql), "select id,name,limit_num,ext8_idx,type,item_id from %s order by id asc",tableName.c_str());
		if(!pDb->Query(sql))
			return false;
		int num = pDb->GetRowNum();
		if(num > 0)
		{
			boost::recursive_mutex::scoped_lock lk(m_mutex);
			hdDropList->clear();
			
			while((row = pDb->GetRow()) != NULL)
			{
				HD_Exchange_Drop_New data;
				data.hd_id = (uint32)atoi(row[0]);
				data.hd_name = row[1];
				data.dropNum_limit = (uint16)atoi(row[2]);
				data.ext8_idx = (uint16)atoi(row[3]);

				data.hd_type.clear();
				string hd_type = row[4];
				char *split[100];
				int num = SplitLine(split, (char *)hd_type.c_str(), '|');
				for (int i = 0; i < num; i++)
				{
					data.hd_type.push_back(atoi(split[i]));
				}
                data.drop_id = atoi(row[5]);
				
				hdDropList->insert(make_pair(data.hd_id,data));			
			}
		}
	}
	return true;
}

void CHDExchangeManager::TimeOut()
{
	static time_t lastTime = 0;
	time_t cur = GetSysTime();
	if(cur == 0)
		lastTime = cur;
	if(cur - lastTime >= 20*60)
	{
		lastTime = cur;
		Init();
	}
}

bool CHDExchangeManager::DropExchangeItem(CUser *pUser,uint32 hdId)
{
	if(pUser == NULL || hdId == 0)
		return false;
	if(GetDropExItemDayIdx() == 0)
		return false;
	HD_Exchange_Drop data;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		map<uint32,HD_Exchange_Drop>::iterator it = m_dropList.find(hdId);
		if(it != m_dropList.end())
			data = it->second;
	}
	if(data.hd_id == 0)
		return false;
	if(pUser->GetExtData8(data.ext8_idx) >= data.dropNum_limit)
		return false;
	if(Random(1,100) <= (int)data.ratio)
	{
		pUser->AddBangDingPackage(data.itemId,1);
		pUser->SetExtData8(data.ext8_idx, pUser->GetExtData8(data.ext8_idx) + 1);
		char buf[128];
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_125,GetItemName(data.itemId));
		if(pUser->GetFightId() == 0)
			SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
		else
			SendSysInfoFightEnd(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
		return true;
	}
	else
	{
		return false;
	}
}

bool CHDExchangeManager::DropHDItem(CUser *pUser,uint32 hdId)
{
	if(pUser == NULL || hdId == 0)
		return false;

	for (uint32 i = 0; i < sizeof(ITEMDROP_TYPE)/sizeof(ITEMDROP_TYPE[0]); i++)
	{
		uint32 hdType = ITEMDROP_TYPE[i];

		map<uint32,HD_Exchange_Drop> *hdDropList = NULL;
		switch(hdType) {
			case CHuoDongAwardManager::FESTIVAL:
				hdDropList = &m_festivalDropList;
				break;
			//case CHuoDongAwardManager::MEIRI_HUANHAOLI:
			//	hdDropList = &m_huanHaoLiDropList;
			//	break;
			case CHuoDongAwardManager::SHENGDAN_FENGSHOU:
				hdDropList = &m_christmasTreeDropList;
				break;
			case CHuoDongAwardManager::XINCHUN_HAPPY:
				hdDropList = &m_xinchunhappyDropList;
				break;
			case CHuoDongAwardManager::ZHENYING_PK1:
				hdDropList = &m_zhenyingPK1DropList;
				break;
			case CHuoDongAwardManager::ZHENYING_PK2:
				hdDropList = &m_zhenyingPK2DropList;
				break;
			default:
				continue;
		}

		HD_Exchange_Drop data;
		{
			boost::recursive_mutex::scoped_lock lk(m_mutex);
			map<uint32,HD_Exchange_Drop>::iterator it = hdDropList->find(hdId);
			if(it != hdDropList->end())
				data = it->second;
		}
		if(data.hd_id == 0 || data.itemNum < 1  || data.itemId < 1)
			continue;
		if(data.dropNum_limit > 0 && pUser->GetExtData8(data.ext8_idx) >= data.dropNum_limit)
			continue;
		if(Random(1,100) <= (int)data.ratio)
		{
			if (data.itemNum > 0)
			{
				for (uint32 i = 0; i < data.hd_type.size(); i++)
				{
					bool inHuodongTime = false;
					if ((uint32)data.hd_type[i] == CHuoDongAwardManager::FESTIVAL)
					{
						inHuodongTime = SingletonCHuoDongAwardManager::instance().InHuoDongLeijiTime(data.hd_type[i]);
					}
					else if ((uint32)data.hd_type[i] == CHuoDongAwardManager::ZHENYING_PK1 || (uint32)data.hd_type[i] == CHuoDongAwardManager::ZHENYING_PK2)
					{
						if (pUser->GetExtData32(383) == hdType)
							inHuodongTime = SingletonCHuoDongAwardManager::instance().InHuoDongTime(data.hd_type[i]);
					}
					else
						inHuodongTime = SingletonCHuoDongAwardManager::instance().InHuoDongTime(data.hd_type[i]);

					if (inHuodongTime)
					{
						pUser->AddBangDingPackage(data.itemId,data.itemNum);
						pUser->SetExtData8(data.ext8_idx, pUser->GetExtData8(data.ext8_idx) + data.itemNum);
						char buf[128];
						snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_126,GetItemName(data.itemId), data.itemNum);
						if(pUser->GetFightId() == 0)
							SendSysInfo(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
						else
							SendSysInfoFightEnd(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
					}	
				}
			}
		}
	}
	return true;
}

bool CHDExchangeManager::DropHDItem_New(CUser *pUser,uint32 hdId)
{
	if(pUser == NULL || hdId == 0)
		return false;

	for (uint32 i = 0; i < sizeof(ITEMDROP_TYPE_NEW)/sizeof(ITEMDROP_TYPE_NEW[0]); i++)
	{
		uint32 hdType = ITEMDROP_TYPE_NEW[i];

		map<uint32,HD_Exchange_Drop_New> *hdDropList = NULL;
		switch(hdType) {
			case CHuoDongAwardManager::MEIRI_HUANHAOLI:
				hdDropList = &m_huanHaoLiDropList;
				break;
			default:
				continue;
		}

		HD_Exchange_Drop_New data;
		{
			boost::recursive_mutex::scoped_lock lk(m_mutex);
			map<uint32,HD_Exchange_Drop_New>::iterator it = hdDropList->find(hdId);
			if(it != hdDropList->end())
				data = it->second;
		}
		if(data.hd_id == 0 || data.hd_type.size() == 0 || data.drop_id == 0)
			continue;
		if(data.dropNum_limit > 0 && pUser->GetExtData8(data.ext8_idx) >= data.dropNum_limit)
			continue;

		CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
		bool IsInHuoDongTime = false;
		//检查是否有掉落活动在进行
		for (uint32 i = 0; i < data.hd_type.size(); i++)
		{
			bool inHuodong =  awardManager.InHuoDongLeijiTime(data.hd_type[i]);
			if (inHuodong)
			{
				IsInHuoDongTime = true;
				break;
			}	
		}
		if(!IsInHuoDongTime)
			continue;
		
		CHuoDongAwardManager::HDExchangeList infos;
		awardManager.GetExchangeInfo(hdType,infos);
		
		std::vector<SAwardData> awvec;
		SingletonAwardManager::instance().GetAwardById(data.drop_id, awvec);
		for (uint16 i = 0; i < awvec.size(); ++i)
		{
			if(awvec[i].type < 1 || awvec[i].num < 1)
				continue;
			pUser->AddMaterial(awvec[i], true, true);	
			if (data.dropNum_limit > 0 && data.ext8_idx > 0 &&  infos.size() > 0)
			{
				bool isMaterial = false;
				for(uint16 k=0;k<infos.size();k++)
				{
					for(uint8 j= 0;j<HD_Exchange_Data::MATERIAL_NUM;j++)
					{
						if(infos[k].material[j] > 0 && awvec[i].type == (int)infos[k].material[j])
						{
							isMaterial = true;
							break;
						}
					}
					if(isMaterial)
						break;
				}
				if(isMaterial)
					pUser->SetExtData8(data.ext8_idx, pUser->GetExtData8(data.ext8_idx) + awvec[i].num);
			}
		}
	}
	return true;
}

HD_Exchange_Data CHDExchangeManager::GetExchangeDataByTargetId(uint16 day,uint32 id)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	HD_Exchange_Data data;
	map<uint16,exchangeMap>::iterator it = m_exchangeList.find(day);
	if(it != m_exchangeList.end())
	{
		exchangeMap::iterator t = it->second.find(id);
		if(t != it->second.end())
			data = t->second;
	}
	return data;
}

void CHDExchangeManager::GetExchangeListByDayIdx(uint16 dayIdx,vector<HD_Exchange_Data> &data)
{
	if(dayIdx == 0)
		return;
	data.clear();
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint16,exchangeMap>::iterator it = m_exchangeList.find(dayIdx);
	if(it != m_exchangeList.end())
	{
		for(exchangeMap::iterator i = it->second.begin(); i != it->second.end(); i++)
			data.push_back(i->second);
	}
}

//圣诞宝箱-开启
void CHDExchangeManager::OpenXtmasBox(CUser *pUser)
{
	if(pUser == NULL)
		return;
	
	if(!InHuoDongTime(CHuoDongAwardManager::XTMAS_BOX))
		return;

	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	const int box_id = awardManager.GetHuoDongPic(CHuoDongAwardManager::XTMAS_BOX);
	const int drop_id = box_id*100;

	std::vector<SAwardData> awvec;
	SingletonAwardManager::instance().GetAwardById(drop_id, awvec);
	for (uint16 i = 0; i < awvec.size(); ++i)
	{
		pUser->AddMaterial(awvec[i], true, true);
	}
}

void CHDExchangeManager::Print()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	cout<<"----------------------------------------------"<<endl;
	/*
	for(map<uint32,HD_Exchange_Drop>::iterator it = m_dropList.begin(); it != m_dropList.end(); it++)
		cout<<"-- drop: hdid="<<it->first<<", itemId="<<it->second.itemId<<", ratio="<<it->second.ratio<<",limit="<<it->second.dropNum_limit<<", ext8="<<it->second.ext8_idx<<endl;
    cout << endl;
	for(map<uint16,exchangeMap>::iterator it = m_exchangeList.begin(); it != m_exchangeList.end(); it++)
	{
		for(exchangeMap::iterator i = it->second.begin(); i != it->second.end(); i++)
		{
			cout<<"-- exchangeList: day="<<it->first<<", id="<<i->first<<", tarId="<<i->second.targetId<<", tarNum="<<i->second.targetNum<<", limit="<<i->second.exchangeNumLimit
				<<",mid0="<<i->second.material[0]<<", midnum0="<<i->second.materialNum[0]
				<<",mid1="<<i->second.material[1]<<", midnum1="<<i->second.materialNum[1]
				<<",mid2="<<i->second.material[2]<<", midnum2="<<i->second.materialNum[2]<<endl;
		}
	}

	for(map<uint32,HD_Exchange_Drop>::iterator it = m_festivalDropList.begin(); it != m_festivalDropList.end(); it++)
	{
		cout<<"-- drop: hdid="<<it->first<<", itemId="<<it->second.itemId<<", ratio="<<it->second.ratio<<",limit="<<it->second.dropNum_limit<<", ext8="<<it->second.ext8_idx<<endl;
		for (uint32 i =0; i < it->second.hd_type.size(); i++)
			cout << it->second.hd_type[i] << ",";
		cout <<endl;
	}
	*/

	cout<<"huan_haoli_drop"<<endl;
	for(map<uint32,HD_Exchange_Drop_New>::iterator it = m_huanHaoLiDropList.begin(); it != m_huanHaoLiDropList.end(); it++)
	{
		cout<<"-- drop: hdid="<<it->first<<",limit="<<it->second.dropNum_limit<<", ext8="<<it->second.ext8_idx<<", drop_id="<<it->second.drop_id<<endl;
		for (uint32 i =0; i < it->second.hd_type.size(); i++)
		{
			cout <<"type="<< it->second.hd_type[i] << ",";
		}
		cout <<endl;
	}
	cout << endl;
	cout<<"-----------------------------------------------"<<endl;
}

bool CHuoDongAwardManager::Init()
{
	static bool isInit = true;
	if(!InitAward())
		return false;
	if(!InitInfo())
		return false;
	if(!InitZhaDan())
		return false;
	if(!InitPeiZhiInfo())
		return false;
	if(!InitExchangInfo())
		return false;
	if(!InitFestivalAward())
		return false;
	if(!InitHDBangGoods())
		return false;
	if(!InitHDTaoHuaGengInfo())
		return false;
	if (!InitHDPaiHangInfo())
		return false;
	if (!InitHDRandAwardInfo())
		return false;
	if (!InitHDItemScoreExChange())
		return false;
	if (isInit)
	{
		isInit = false;
		if (!InitHDPaiHangRecord())
			return false;

		if (!InitHDChouInfo())
			return false;

		if (!InitHDSave())
			return false;

		if (!InitHDQiangHongBao())
			return false;
	}
	
	CheckXtmasTree();
	CheckKuaFuXueLian();
	
	m_startSec = GetServerOpenTime();
	if(!SingletonCHuoDongMoneyGiftBag::instance().LoadDB())
	{    
		return false;
	}
	return true;
}

bool CHuoDongAwardManager::InitHDQiangHongBao()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char sql[512];
	char **row = NULL;
	if(pDb == NULL)
		return false;
	//									 0			  1            2
	snprintf(sql, sizeof(sql), "select role_id, send_hb_count, renqi_king_count from qiang_hongbao_record");
	if(!pDb->Query(sql))
		return false;
	int num = pDb->GetRowNum();
	if(num > 0)
	{
		m_hongbao_record.clear();
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		while((row = pDb->GetRow()) != NULL)
		{
			HDHongBaoGetRecord record;
			record.roleId = (uint32)atoi(row[0]);
			record.sendHBCount = (uint32)atoi(row[1]);
			record.renQiKingCount = (uint32)atoi(row[2]);
			record.isDirty = false;
			m_hongbao_record.insert(make_pair(record.roleId,record));
		}
	}
	return true;
}

bool CHuoDongAwardManager::InitHDSave()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char sql[512];
	char **row = NULL;
	if(pDb == NULL)
		return false;
	//									 0	          1    
	snprintf(sql, sizeof(sql), "select hd_type,	save_data from hd_save_data");
	if(!pDb->Query(sql))
		return false;
	int num = pDb->GetRowNum();
	if(num > 0)
	{
		while((row = pDb->GetRow()) != NULL)
		{
			uint32 hd_type = (uint32)atoi(row[0]);
			string save_data = row[1];

			switch(hd_type)
			{
				case FIND_YOUYUANREN:
					SetFindYouYuanRenStr(save_data);
					break;
				case SHENGDAN_FENGSHOU:
					SetChristmasTreeStr(save_data);
					break;
				case ZHENYING_PK:
					SetZhenYingPKStr(save_data);
					break;
				case QIANG_HONGBAO:
					SetQiangHongBaoStr(save_data);
					break;
				default:
					break;
			}
		}
	}
	return true;
}

void CHuoDongAwardManager::PaiHangBangTimer()
{
	map<uint32, HDPaiHangRecordList> endBang;

	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		map<uint32, HDPaiHangRecordList>::iterator it = m_paiHang_record.begin();  
		while(it != m_paiHang_record.end())  
		{
			if(it->first == ZHOU_NIAN_QING_1)
			{
				if(InHuoDongTime(it->first) && !InHuoDongLeijiTime(it->first))
				{
					HDPaiHangRecordList recordList;
					GetNoLockHDPaiHangRecord(it->first,recordList);
					endBang.insert(make_pair(it->first,recordList));
					m_paiHang_record.erase(it++);
				}
				else
					it++;
				continue;
			}
			if (!InHuoDongTime(it->first))
			{
				if ((it->first == SHENGDAN_FENGSHOU) && (GetHuoDongPic(SHENGDAN_FENGSHOU) != CHRISTMAS_TREE_ID))
					continue;

				HDPaiHangRecordList recordList;
				GetNoLockHDPaiHangRecord(it->first,recordList);
				endBang.insert(make_pair(it->first,recordList));
				m_paiHang_record.erase(it++);
			}
			else
				it++;
		}
	}

	map<uint32, HDPaiHangRecordList>::iterator it = endBang.begin();
	while(it != endBang.end())  
	{
		SendHDPaiHangRecord(it->first,it->second);
		SaveHDPaiHangRecordInfo(it->first,it->second,true);
		it++;
	} 
}

void CHuoDongAwardManager::SaveHDPaiHangRecordInfo(uint32 type, vector<HDPaiHangRecordInfo> &info,bool isSendAward)
{
	uint32 startTime = GetHuoDongStartTime(type);

	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;

	if (info.size() <= 0)
		return;

	char csql[1024];
	snprintf(csql, sizeof(csql), "delete from hd_paihang_record where huodong_type = %d and start_time = %d", type, startTime);
	pDb->Query(csql);
	{
		stringstream sql;
		sql<<"insert into hd_paihang_record(huodong_type,role_id,role_name,role_lv,role_zhandouli,bangpai_name,data,`rank`,start_time,time,xiang,sex,send_award) values";
		for (uint32 i = 0; i < info.size(); i++)
		{
			
			
			if(i > 0)
				sql<<",";
			sql<<"("<<type<<","<<info[i].role_id<<",\'"<<info[i].role_name<<"\',"<<info[i].role_lv<<","<<info[i].role_zhandouli<<",\'"<<info[i].bang_name;
			sql<<"\',"<<info[i].data<<","<<(i+1)<<","<<startTime<<","<<info[i].time<<","<<info[i].xiang<<","<<info[i].sex;
			if (isSendAward)
				sql<<",1)";
			else
				sql<<",0)";
			
		}
		pDb->Query(sql.str().c_str());
	}
}

void CHuoDongAwardManager::SaveHDPaiHangRecord(bool isSave)
{
	static uint32 lastSaveTime = 0;
	uint32 curTime = GetSysTime();
	if (lastSaveTime == 0)
		lastSaveTime = curTime;
	else if (lastSaveTime + 3600 >= curTime)
	{
		isSave = true;
		lastSaveTime = curTime;
	}

	if (isSave)
	{
		map<uint32, HDPaiHangRecordList> endBang;
		{
			boost::recursive_mutex::scoped_lock lk(m_mutex);
			map<uint32, HDPaiHangRecordList>::iterator it = m_paiHang_record.begin();  
			while(it != m_paiHang_record.end())  
			{
				HDPaiHangRecordList recordList;
				GetNoLockHDPaiHangRecord(it->first,recordList);
				endBang.insert(make_pair(it->first,recordList));
				it++;
			} 
		}

		map<uint32, HDPaiHangRecordList>::iterator itBang = endBang.begin();
		while(itBang != endBang.end())  
		{
			SaveHDPaiHangRecordInfo(itBang->first,itBang->second);
			itBang++;  
		}
	}
}

bool CHuoDongAwardManager::InitHDPaiHangRecord()
{
	bool isFirst = true;
	stringstream strRecord;
	char tmp[512];

	for (uint32 i = 0; i < sizeof(PAIHANG_TYPE)/sizeof(PAIHANG_TYPE[0]); i++)
	{
		snprintf(tmp,sizeof(tmp),"(huodong_type = %d and start_time = %d and send_award = 0)", PAIHANG_TYPE[i],GetHuoDongStartTime(PAIHANG_TYPE[i]));
		if (isFirst)
		{
			isFirst = false;
		}
		else
		{
			strRecord<<" or ";
		}
		strRecord<<tmp;
	}
	
	if (isFirst)
		return true;

	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	stringstream sql;
	char **row = NULL;
	if(pDb == NULL)
		return false;
	//                 0         1         2          3       4      5          6         7     8    9
	sql<<"select huodong_type,role_id,role_name,bangpai_name,data,role_lv,role_zhandouli,time,xiang,sex from hd_paihang_record where " << strRecord.str() << " order by `rank` asc";
	if(!pDb->Query(sql.str().c_str()))
		return false;
	int num = pDb->GetRowNum();
	if(num > 0)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);

		m_paiHang_record.clear();
		while((row = pDb->GetRow()) != NULL)
		{
			HDPaiHangRecordInfo info;
			info.role_id = (uint32)atoi(row[1]);
			info.role_name = row[2];
			info.bang_name = row[3];
			info.data = (uint32)atoi(row[4]);
			info.role_lv= (uint32)atoi(row[5]);
			info.role_zhandouli = (uint32)atoi(row[6]);
			info.time = (uint32)atoi(row[7]);
			info.xiang = (uint32)atoi(row[8]);
			info.sex = (uint32)atoi(row[9]);

			uint32 huodong_type = (uint32)atoi(row[0]);

			map<uint32,HDPaiHangRecordList>::iterator it = m_paiHang_record.find(huodong_type);
			if(it != m_paiHang_record.end())
			{
				it->second.push_back(info);
			}
			else
			{
				HDPaiHangRecordList vecInfo;
				vecInfo.push_back(info);
				m_paiHang_record.insert(make_pair(huodong_type, vecInfo));
			}
		}
	}
	//		Print();
	return true;
}

bool CHuoDongAwardManager::InitHDPaiHangInfo()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char sql[512];
	char **row = NULL;
	if(pDb == NULL)
		return false;
	//									 0	          1        2 	3     4
	snprintf(sql, sizeof(sql), "select huodong_type,start_id,end_id,idx,score from hd_paihang_info order by huodong_type desc,start_id asc");
	if(!pDb->Query(sql))
		return false;
	int num = pDb->GetRowNum();
	if(num > 0)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);

		m_paiHang_info.clear();
		m_paiHang_size.clear();
		while((row = pDb->GetRow()) != NULL)
		{
			HDPaiHangInfo info;
			info.startId = (uint32)atoi(row[1]);
			info.endId = (uint32)atoi(row[2]);
			info.idx = (uint32)atoi(row[3]);
			info.score = (uint32)atoi(row[4]);

			uint32 huodong_type = (uint32)atoi(row[0]);

			map<uint32,vector<struct HDPaiHangInfo> >::iterator it = m_paiHang_info.find(huodong_type);
			if(it != m_paiHang_info.end())
			{
				it->second.push_back(info);
			}
			else
			{
				HDPaiHangList vecInfo;
				vecInfo.push_back(info);
				m_paiHang_info.insert(make_pair(huodong_type, vecInfo));
			}

			map<uint32,uint32>::iterator itHDSize = m_paiHang_size.find(huodong_type);
			if (itHDSize == m_paiHang_size.end())
				m_paiHang_size.insert(make_pair(huodong_type,info.endId));
			else if (itHDSize->second < info.endId)
				itHDSize->second = info.endId;
		}
	}
	//		Print();
	return true;
}

//add by zhudaolong 2017.11.01
bool CHuoDongAwardManager::InitHDTaoHuaGengInfo()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char sql[512];
	char** row = NULL;
	if(pDb == NULL)
		return false;
	snprintf(sql, sizeof(sql), "select material_id,material_per_num from taohuageng_config order by id ");
	if(!pDb->Query(sql))
		return false;
	int num = pDb->GetRowNum();
	if(num > 0)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);

		m_THG_material_info.clear();

		while((row = pDb->GetRow()) != NULL)
		{
			uint32 material_id = (uint32)atoi(row[0]);
			uint32 material_per_num = (uint32)atoi(row[1]);

			m_THG_material_info.insert(make_pair(material_id,material_per_num));
		}
	}
	return true;
}
bool CHuoDongAwardManager::InitHDRandAwardInfo()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char sql[512];
	char **row = NULL;
	if(pDb == NULL)
		return false;
	//									 0	          1    2 	3      4	 5    
	snprintf(sql, sizeof(sql), "select huodong_type,award,num,petQt,petQtLv,rate from hd_rand_award order by id asc,huodong_type desc");
	if(!pDb->Query(sql))
		return false;
	int num = pDb->GetRowNum();
	if(num > 0)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);

		m_randAward_info.clear();
		m_XianShiChouMaxRate = 0;
		
		while((row = pDb->GetRow()) != NULL)
		{
			HDRandAwardInfo info;
			info.award = (uint32)atoi(row[1]);
			info.num = (uint32)atoi(row[2]);
			info.petQt = (uint16)atoi(row[3]);
			info.petQtLv = (uint16)atoi(row[4]);

			uint32 huodong_type = (uint32)atoi(row[0]);
			uint32 myRate = (uint32)atoi(row[5]);

			info.rate = 0;
			if (myRate != 0)
			{
				if (huodong_type == CHuoDongAwardManager::XIANSHI_CHOU)
				{
					m_XianShiChouMaxRate += myRate;
					info.rate = m_XianShiChouMaxRate;
				}
			}

			map<uint32,vector<struct HDRandAwardInfo> >::iterator it = m_randAward_info.find(huodong_type);
			if(it != m_randAward_info.end())
			{
				it->second.push_back(info);
			}
			else
			{
				HDRandAwardList vecInfo;
				vecInfo.push_back(info);
				m_randAward_info.insert(make_pair(huodong_type, vecInfo));
			}
		}
	}
	//		Print();
	return true;
}

bool CHuoDongAwardManager::InitHDChouInfo()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char sql[512];
	char **row = NULL;
	if(pDb == NULL)
		return false;

	//									0        1        2   3      4
	snprintf(sql, sizeof(sql), "select role_id,role_name,unix_timestamp(time),award,level from hd_chou_record where award != %d and UNIX_TIMESTAMP(time) > (SELECT UNIX_TIMESTAMP( NOW( ) ) DIV 3600 *3600  - 3600)",CHOU_AWARD2);
	if(!pDb->Query(sql))
		return false;
	int num = pDb->GetRowNum();
	if(num > 0)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);

		m_chou_info.clear();
		
		while((row = pDb->GetRow()) != NULL)
		{
			uint32 role_id = (uint32)atoi(row[0]);
			string role_name = row[1];
			uint32 time = ((uint32)atoi(row[2])) / 3600 * 3600;
			uint32 award = (uint32)atoi(row[3]);
			uint32 level = (uint32)atoi(row[4]);

			map<uint32,map<uint32,HDChouInfo> >::iterator it = m_chou_info.find(time);
			if(it != m_chou_info.end())
			{
				map<uint32,HDChouInfo> &chouInfo = it->second;
				map<uint32,HDChouInfo>::iterator itInfo = chouInfo.find(role_id);
				if(itInfo != chouInfo.end() && award != CHOU_AWARD)
				{
					itInfo->second.count++;
					itInfo->second.award = award;
					itInfo->second.level = level > itInfo->second.level ? level : itInfo->second.level;
				}
				else
				{
					HDChouInfo info;
					info.role_id = role_id;
					info.role_name = role_name;
					info.count = 1;
					info.award = award;
					info.level = level;
					chouInfo.insert(make_pair(role_id,info));
				}
			}
			else
			{
				map<uint32,HDChouInfo> mapInfo;
				HDChouInfo info;
				info.role_id = role_id;
				info.role_name = role_name;
				info.count = 1;
				info.award = award;
				mapInfo.insert(make_pair(role_id,info));
				m_chou_info.insert(make_pair(time, mapInfo));
			}

			if (award == CHOU_AWARD_NONE)
			{
				map<uint32,vector<uint32> >::iterator itChouList = m_chou_list.find(time);
				if (itChouList != m_chou_list.end())
				{
					itChouList->second.push_back(role_id);
				}
				else
				{
					vector<uint32> choulist;
					choulist.push_back(role_id);
					m_chou_list.insert(make_pair(time,choulist));
				}
			}
		}
	}
	//Print();
	return true;
}

bool CHuoDongAwardManager::InitHDItemScoreExChange()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char sql[512];
	char **row = NULL;
	if(pDb == NULL)
		return false;

	//									0        1            2
	snprintf(sql, sizeof(sql), "select item_id,score_give,score_get from item_score_exchange");
	if(!pDb->Query(sql))
		return false;
	int num = pDb->GetRowNum();
	if(num > 0)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);

		m_item_score_exchange.clear();
		
		while((row = pDb->GetRow()) != NULL)
		{
			HDItemScoreExchangeInfo info;
			info.itemId = (uint32)atoi(row[0]);
			info.giveScore = (uint32)atoi(row[1]);
			info.getScore = (uint32)atoi(row[2]);
			m_item_score_exchange.insert(make_pair(info.itemId, info));
		}
	}
	//Print();
	return true;
}


bool CHuoDongAwardManager::InitAward()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char sql[512];
	char **row = NULL;
	if(pDb == NULL)
		return false;
	//									 0	 1	2    3	    4	  5	      6       7    8     9       10      11    12    13      14
	snprintf(sql, sizeof(sql), "select type,idx,YB,award1,num1,petQt1,petQtLv1,award2,num2,petQt2,petQtLv2,award3,num3,petQt3,petQtLv3,"\
	//     15     16    17      18     19    20    21      22      23    24    25    26       27   28
		"award4,num4,petQt4,petQtLv4,award5,num5,petQt5,petQtLv5,award6,num6,petQt6,petQtLv6,idx2,idx3 from huodong_award order by type asc,idx asc,idx3 asc");
	if(!pDb->Query(sql))
		return false;
	int num = pDb->GetRowNum();
	if(num > 0)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);

		m_award.clear();
		HuoDongList datalist;
		int type = 0;
		while((row = pDb->GetRow()) != NULL)
		{
			int ntype = atoi(row[0]);
			if(ntype != type)
			{
				if(!datalist.empty())
				{
					m_award.insert(make_pair(type,datalist));
					datalist.clear();
				}
				type = ntype;
			}

			SHuoDongAward data;
			data.idx = atoi(row[1]);
			data.needYB = atoi(row[2]);
			data.idx2 = atoi(row[27]);
			data.idx3 = atoi(row[28]);
			for(uint8 i=0;i < SHuoDongAward::AWARD_NUM;i++)
			{
				data.award[i] = atoi(row[3+i*4]);
				data.num[i] = atoi(row[4+i*4]);
				data.petQuality[i] = atoi(row[5+i*4]);
				data.petQualityLv[i] = atoi(row[6+i*4]);
			}
			
			datalist.push_back(data);
		}
		if(!datalist.empty())
			m_award.insert(make_pair(type,datalist));
	}
	return true;
	//	Print();
}

bool CHuoDongAwardManager::InitInfo()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char sql[1024];
	char **row = NULL;
	if(pDb == NULL)
		return false;
	time_t startTime = GetServerOpenTime();
	struct tm *start = localtime(&startTime);
	start->tm_hour = 0;
	start->tm_min = 0;
	start->tm_sec = 0;
	uint32 startSec = mktime(start);
	uint32 endSec = startSec + 7 * 24 * 3600;

	//startSec - (startSec + 8 * 3600) % 86400 + day * 24 * 3600 - 1
	//                          0     1      2               3              4               5                6   7   8                                     9                                                            10     11     12
	snprintf(sql, sizeof(sql), "select type,showIdx,isShow,UNIX_TIMESTAMP(startTime),startTime,UNIX_TIMESTAMP(endTime),endTime,pic,day,FROM_UNIXTIME(UNIX_TIMESTAMP(startTime)-(UNIX_TIMESTAMP(startTime)+8*3600)%%86400+day*24*3600-1),name,startHour,endHour"\
		", FROM_UNIXTIME(%u), FROM_UNIXTIME(%u), FROM_UNIXTIME(%u-(%u+8*3600)%%86400+day*24*3600-1) from huodong_info order by showIdx asc", startSec, endSec, startSec, startSec);
		//  13                  14                     15
	sql[1023] = '\0';
	if(!pDb->Query(sql))
		return false;
	int num = pDb->GetRowNum();
	if(num > 0)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);

		m_info.clear();
		m_list.clear();
		while((row = pDb->GetRow()) != NULL)
		{
			SHuoDongInfo info;
			info.type = (uint32)atoi(row[0]);
			info.showIdx = (uint32)atoi(row[1]);
			info.isShow = (uint8)atoi(row[2]);
			info.iStartTime = (uint32)atoi(row[3]);
			info.iEndTime = (uint32)atoi(row[5]);
			info.pic = (uint32)atoi(row[7]);
			info.day = (uint32)atoi(row[8]);
			info.name = row[10];
			info.startHour = (uint32)atoi(row[11]);
			info.endHour = (uint32)atoi(row[12]);
			info.zeroStartTime = info.iStartTime - (uint32)GetZeroTime(row[4]);

			if (info.type == CHONG_ZHI_BANG
				|| info.type == ROLE_LEVEL_BANG
				|| info.type == ZHAN_LI_BANG
				|| info.type == SHEN_CHONG_BANG
				|| info.type == WING_BANG
				|| info.type == EQUIP_QIANGHUA_BANG)
			{
				info.iStartTime = startSec;
				info.iEndTime = endSec;
				GetTimeDesc(info.type, row[13], row[14], info.timeDesc);
			}
			else
			{
				GetTimeDesc(info.type, row[4], row[6], info.timeDesc);
			}
			if (info.day != 0)
			{
				info.leijiTime = info.iStartTime + info.day * 24 * 3600;
			}
			if (info.type == CHONG_ZHI_BANG
				|| info.type == ROLE_LEVEL_BANG
				|| info.type == ZHAN_LI_BANG
				|| info.type == SHEN_CHONG_BANG
				|| info.type == WING_BANG
				|| info.type == EQUIP_QIANGHUA_BANG)
			{
				GetTimeDesc(info.type, row[13], row[15], info.leijiDesc);
			}
			else
			{
				GetTimeDesc(info.type, row[4], row[9], info.leijiDesc);
			}
			SetMoGuAwardDay(info.type,info.iStartTime,info.iEndTime,info.day,info.moguAwardDay);

			m_info.insert(make_pair(info.type, info));

			if (info.isShow == 1)
				m_list.push_back(info.type);
		}
	}
	return true;
//	Print();
}

bool CHuoDongAwardManager::InitZhaDan()
{
	if(!InitZhaDanInfo())
		return false;
	if(!InitZhaDanHistory())
		return false;
	return true;
}

bool CHuoDongAwardManager::InitZhaDanInfo()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char sql[512];
	char **row = NULL;
	if(pDb == NULL)
		return false;
	//									 0	 1	   2 	 3 	4         5	    6		7      8	
	snprintf(sql, sizeof(sql), "select type,award,num,petQt,petQtLv,rate,isJinPin,isShow,notice from zha_dan_info  order by id asc");
	if(!pDb->Query(sql))
		return false;
	int num = pDb->GetRowNum();
	if(num > 0)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);

		m_ybZhaDan.clear();
		m_ybMaxRate = 0;
		m_copyZhaDan.clear();
		m_copyMaxRate = 0;
		uint32 rate = 0;
		uint32 cpRate = 0;
		
		while((row = pDb->GetRow()) != NULL)
		{
			SZhaDanInfo info;
			info.type = (uint8)atoi(row[0]);
			info.award = (uint32)atoi(row[1]);
			info.num = (uint32)atoi(row[2]);
			info.petQt = (uint16)atoi(row[3]);
			info.petQtLv = (uint16)atoi(row[4]);
			info.isJinPin = (uint8)atoi(row[6]);
			info.isShow = (uint8)atoi(row[7]);
			info.notice = (uint8)atoi(row[8]);
			if (info.isShow != 1)
				continue;
			if (info.type == 0)					// 复制
			{
				if (atoi(row[5]) != 0)
					info.rate = cpRate + (uint32)atoi(row[5]);
				else
					info.rate = 0;

				cpRate += (uint32)atoi(row[5]);
				m_copyZhaDan.push_back(info);
				m_copyMaxRate += (uint32)atoi(row[5]);
			}
			else if (info.type == 1)			// 初版
			{
				if (atoi(row[5]) != 0)
					info.rate = rate + (uint32)atoi(row[5]);
				else
					info.rate = 0;

				rate += (uint32)atoi(row[5]);
				m_ybZhaDan.push_back(info);
				m_ybMaxRate += (uint32)atoi(row[5]);
			}
		}
	}
	return true;
	//		Print();
}

bool CHuoDongAwardManager::InitZhaDanHistory()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char sql[512];
	char **row = NULL;
	if(pDb == NULL)
		return false;
	uint32 startTime = 0;
	uint32 endTime = 0;
	if (InHuoDongTime(ZHA_DAN))
	{
		startTime = GetHuoDongStartTime(ZHA_DAN);
		endTime = GetHuoDongEndTime(ZHA_DAN);
	}
	else if (InHuoDongTime(ZHA_DAN_COPY))
	{
		startTime = GetHuoDongStartTime(ZHA_DAN_COPY);
		endTime = GetHuoDongEndTime(ZHA_DAN_COPY);
	}
	
	snprintf(sql, sizeof(sql), "select data from zha_dan_log where UNIX_TIMESTAMP(time) >= %u and  UNIX_TIMESTAMP(time) <= %u order by id desc limit 10;", startTime, endTime);
	if(!pDb->Query(sql))
		return false;
	int num = pDb->GetRowNum();
	if(num > 0)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);

		m_zhaDanPublicHistory.clear();
		while((row = pDb->GetRow()) != NULL)
		{
			string data = row[0];
			m_zhaDanPublicHistory.push_front(data);
		}
	}
	return true;
}

bool CHuoDongAwardManager::InitFestivalAward()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char sql[512];
	char **row = NULL;
	if(pDb == NULL)
		return false;

	//		                            0     1        2       3   4							 
	snprintf(sql, sizeof(sql), "select type,start_id,end_id,score,idx from festival_award order by type,idx asc");
	if(!pDb->Query(sql))
		return false;
	int num = pDb->GetRowNum();
	if(num > 0)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);

		m_festival_award[0].clear();
		m_festival_award[1].clear();
		m_festival_min_score[0] = 0;
		m_festival_min_score[1] = 0;
		while((row = pDb->GetRow()) != NULL)
		{
			SFestivalAward award;
			award.type = (uint8)atoi(row[0]);
			award.startId = (uint8)atoi(row[1]);
			award.endId = (uint8)atoi(row[2]);
			award.score = (uint32)atoi(row[3]);
			award.idx = (uint8)atoi(row[4]);

			m_festival_award[award.type].push_back(award);
			if (award.startId == 0)
				m_festival_min_score[award.type] = award.score;
		}
	}
	return true;
}

bool CHuoDongAwardManager::InitHDBangGoods()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char sql[512];
	char **row = NULL;
	if(pDb == NULL)
		return false;

	//									 0 	   1	  2              3     4		5				6	 
	snprintf(sql, sizeof(sql), "select  pic,award1,score1_give,score1_get,award2,score2_give,score2_get from hd_bang_goods order by id asc");
	if(!pDb->Query(sql))
		return false;
	int num = pDb->GetRowNum();
	if(num > 0)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);

		m_hd_bang_goods.clear();
		while((row = pDb->GetRow()) != NULL)
		{
			HDBangGoods goods;
			GoodsInfo info;
			
			goods.pic = (uint32)atoi(row[0]);
			
			info.award = (uint32)atoi(row[1]);
			info.score_give = (uint32)atoi(row[2]);
			info.score_get = (uint32)atoi(row[3]);
			info.give_data_id = 219;				// 节日活动专用
			info.get_data_id = 220;					// 节日活动专用
			goods.info.push_back(info);

			info.award = (uint32)atoi(row[4]);
			info.score_give = (uint32)atoi(row[5]);
			info.score_get = (uint32)atoi(row[6]);
			info.give_data_id = 221;				// 节日活动专用
			info.get_data_id = 222;					// 节日活动专用
			goods.info.push_back(info);

			m_hd_bang_goods.insert(make_pair(goods.pic, goods));
		}
	}
	return true;
}

bool CHuoDongAwardManager::InitPeiZhiInfo()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char sql[512];
	char **row = NULL;
	if(pDb == NULL)
		return false;

	//                                   0  1    2    3  4    5       6      7            8                9             10         11       12      13      14
	snprintf(sql, sizeof(sql), "select type,yb,count,lv,idx,cdTime,price,count_ext8,lastTime_ext32,zhenying1_name,zhenying2_name,water_cz,bug_cz,step1_cz,step2_cz from hd_peizhi_info order by type,id asc");
	if(!pDb->Query(sql))
		return false;

	int num = pDb->GetRowNum();
	if(num > 0)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		m_peizhi_info.clear();
		while((row = pDb->GetRow()) != NULL)
		{
			HDPeiZhiInfo info;

			info.type = (uint32)atoi(row[0]);
			info.YB = (uint32)atoi(row[1]);
			info.count = (uint8)atoi(row[2]);
			info.lv = (uint32)atoi(row[3]);
			info.index = (uint32)atoi(row[4]);
			info.cd = (uint32)atoi(row[5]);
			info.price = (uint32)atoi(row[6]);
			info.saveCountId = (uint32)atoi(row[7]);
			info.saveLastTimeId = (uint32)atoi(row[8]);
			info.zhenYing1Name = row[9];
			info.zhenYing2Name = row[10];
			info.water_cz = (uint32)atoi(row[11]);
			info.bug_cz = (uint32)atoi(row[12]);
			info.step1_cz = (uint32)atoi(row[13]);
			info.step2_cz = (uint32)atoi(row[14]);

			if (info.type == CHuoDongAwardManager::JIERI_LIBAO || info.type == CHuoDongAwardManager::JIERI_LIBAO2)
			{
				vector<uint32> idxList;
				uint32 firstId = 0;
				GetNoLockAwardIdxList(info.type,info.index,idxList);
				for (uint32 j = 0; j < idxList.size(); j++)
				{
					if (firstId == 0)
					{
						firstId = idxList[j];
					}
					else if (idxList[j] < firstId)
					{
						firstId = idxList[j];
					}			
				}
				info.firstId = firstId;
				info.num = idxList.size();
			}
			map<uint32,vector<struct HDPeiZhiInfo> >::iterator it = m_peizhi_info.find(info.type);
			if(it != m_peizhi_info.end())
			{
				it->second.push_back(info);
			}
			else
			{
				vector<struct HDPeiZhiInfo> vecInfo;
				vecInfo.push_back(info);
				m_peizhi_info.insert(make_pair(info.type, vecInfo));
			}
		}
	}
	return true;
//	Print();
}

bool CHuoDongAwardManager::InitExchangInfo()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char sql[512];
	char **row = NULL;
	if(pDb == NULL)
		return false;

	//									 0	   1				2	  3	 4		  5		  6		   
	snprintf(sql, sizeof(sql), "select type,exchange_num_limit,saveExt8,idx,isShow,material_is_or,material_1,material_1_num,material_2,material_2_num,material_3,material_3_num,material_4,material_4_num,material_5,material_5_num,"\
	// 16	 
	"award1,num1,petQt1,petQtLv1,award2,num2,petQt2,petQtLv2,award3,num3,petQt3,petQtLv3,award4,num4,petQt4,petQtLv4,award5,num5,petQt5,petQtLv5,award6,num6,petQt6,petQtLv6 from huodong_exchange order by type,idx asc");

	if(!pDb->Query(sql))
		return false;

	int num = pDb->GetRowNum();
	if(num > 0)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		m_exchange_info.clear();
		HDExchangeList datalist;
		int type = 0;
		while((row = pDb->GetRow()) != NULL)
		{
			int ntype = atoi(row[0]);
			if(ntype != type)
			{
				if(!datalist.empty())
				{
					m_exchange_info.insert(make_pair(type,datalist));
					datalist.clear();
				}
				type = ntype;
			}

			HDExchangeInfo data;
			data.exchange_num_limit = (uint32)atoi(row[1]);
			data.saveExt8 = (uint32)atoi(row[2]);
			data.idx = (uint32)atoi(row[3]);
			data.isShow = (uint8)atoi(row[4]);
			data.materialIsOr = (uint8)atoi(row[5]);

			for(uint8 i=0;i < HDExchangeInfo::MATERIAL_NUM;i++)
			{
				data.material[i] = atoi(row[6+i*2]);
				data.material_num[i] = atoi(row[7+i*2]);
			}
			
			for(uint8 i=0;i < HDExchangeInfo::AWARD_NUM;i++)
			{
				data.award[i] = atoi(row[16+i*4]);
				data.num[i] = atoi(row[17+i*4]);
				data.petQuality[i] = atoi(row[18+i*4]);
				data.petQualityLv[i] = atoi(row[19+i*4]);
			}			

			datalist.push_back(data);
		}
		if(!datalist.empty())
			m_exchange_info.insert(make_pair(type,datalist));
	}
	return true;
	//Print();
}

bool CHuoDongAwardManager::GetHDExchangeScoreInfoByItem(uint32 itemId, HDItemScoreExchangeInfo &info)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,struct HDItemScoreExchangeInfo>::iterator it = m_item_score_exchange.find(itemId);
	if (it != m_item_score_exchange.end())
	{
		info = it->second;
		return true;
	}
	return false;
}


void CHuoDongAwardManager::Save()
{
	string findYouYUanRenStr;
	GetFindYouYuanRenStr(findYouYUanRenStr);

	string christmasTreeStr;
	GetChristmasTreeStr(christmasTreeStr);

	string zhenyingPKStr;
	GetZhenYingPKStr(zhenyingPKStr);

	string qiangHongBaoStr;
	GetQiangHongBaoStr(qiangHongBaoStr);

	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;

	char csql[1024];
	snprintf(csql, sizeof(csql), "TRUNCATE hd_save_data");
	pDb->Query(csql);
	{
		stringstream sql;
		sql<<"insert into hd_save_data(hd_type,	save_data) values";
		sql<<"("<<FIND_YOUYUANREN<<",'"<<findYouYUanRenStr<<"')";
		sql<<",("<<SHENGDAN_FENGSHOU<<",'"<<christmasTreeStr<<"')";
		sql<<",("<<ZHENYING_PK<<",'"<<zhenyingPKStr<<"')";
		sql<<",("<<QIANG_HONGBAO<<",'"<<qiangHongBaoStr<<"')";
		pDb->Query(sql.str().c_str());
	}
	
}

void CHuoDongAwardManager::SetFindYouYuanRenStr(string &save_data)
{
	uint32 len = 1024;
	uint8 *p = new uint8[len];
	boost::scoped_array<uint8> autoDel(p);

	if ((!InHuoDongTime(FIND_YOUYUANREN)) || (!InHuoDongHour(FIND_YOUYUANREN)))
		return;
	
	if(!UnCompress(save_data.c_str(),p,len))
	{
		return;
	}
	
	CNetMessage msg;
	msg.WriteData(p,len);
	
	uint32 npc_flush_time = 0;
	msg>>npc_flush_time;

	int npc_index = 0;
	msg>>npc_index;

	int count = 0;
	msg>>count;

	uint32 time = MakeFindYouYuanRenCurTime();
	if (time == npc_flush_time)
	{
		if (FindYouYuanRenNpcCreate(npc_index))
		{
			boost::recursive_mutex::scoped_lock lk(m_mutex);
			m_npc_flush_time = npc_flush_time;
			m_npc_index = npc_index;
			m_count = count;
		}
	}
	
}

void CHuoDongAwardManager::GetFindYouYuanRenStr(string &str)
{
	CNetMessage msg;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		msg << m_npc_flush_time;
		msg << m_npc_index;
		msg << m_count;
	}

	if(!Compress((uint8*)(msg.GetMsgData()->c_str() + CNetMessage::GetHeadLen()),msg.GetDataLenExceptHead(), str))
		str.clear();
}


void CHuoDongAwardManager::TimeOut()
{
	BaoWeiZhanTimer();

#ifndef KUA_FU
	static time_t lastTime = 0;
	time_t cur = GetSysTime();
	if(cur == 0)
		lastTime = cur;
	if(cur - lastTime >= 30*60)
	{
		lastTime = cur;
		Init();

		DelInvalidHongBao();

		SaveQiangHongBaoRecord();
	}
	int hour = GetSysHour();
	int minutes = GetSysMinute(); 
	int seconds = GetSysSecond();
	if( hour == 0 && minutes >= 0 && minutes <= 3 && (seconds > 0 && seconds <15 ) )
	{
		CheckXtmasTree();//圣诞树npc活动
	}//end of if
	if( (hour == 12 || hour == 15|| hour == 18))
	{
		CheckXtmasBox_New();//圣诞礼盒活动(节日宝箱)
	}
	else
	{
		m_box_refresh_sign = false;
	}
	ClearXtmasBox_New();
	ClearFestivalPaiHang();
	FindYouYuanRenTimer();//寻找有缘人
#else
	HuanLeShengYanTimer();	// 欢乐盛宴
#endif
}

uint32 CHuoDongAwardManager::MakeFindYouYuanRenCurTime()
{
	int year = GetYear() * 1000000;
	int mon = GetMonth() * 10000;
	int day = GetDay() * 100;
	int hour = GetHour();

	return year + mon + day + hour;
}

void CHuoDongAwardManager::HuanLeShengYanTimer()
{
	if(!InHuoDongTime(ZHOU_NIAN_QING_1))
	{
		SetHDHuanLeShengYanJiFen(0);
		m_hlsy_paihang.clear();
	}
	if(!InHuoDongTime(ZHOU_NIAN_QING_2))
	{
		SetBaoWeiZhanBossCurHp(-1);
	}
	
	CSceneManager &sceneMgr = SingletonSceneManager::instance();
	CScene *pScene = sceneMgr.FindScene(70);
	if (pScene == NULL)
		return;
	const int npcId = 237;
	if(InHuoDongTime(ZHOU_NIAN_QING_1) || InHuoDongTime(ZHOU_NIAN_QING_2))	// 显示npc
	{
		if(pScene->FindNpc(npcId) == NULL)
		{
			CNpcManager &npcManager = SingletonNpcManager::instance();
			SNpcTemplate *pNpc = npcManager.GetNpcTemplate(npcId);
			if (pNpc == NULL)
				return;
			pScene->AddNpcWithIndex(npcId,pNpc->pic,607,1105,2,0);
		}
	}
	else	// 消失
	{
		pScene->DelNpc(npcId);
	}
}

void CHuoDongAwardManager::FindYouYuanRenTimer()
{
	int curMin = GetMinute();
	if (InHuoDongTime(FIND_YOUYUANREN) && InHuoDongHour(FIND_YOUYUANREN))
	{
		if (!FindYouYuanRenNpcExist() && curMin <= YOUYUANREN_TIME)  // npc 不存在，到显示时间 npc创建
		{
			int pos_index = Random(1,sizeof(YOUYUANREN_NPC_POS)/sizeof(YOUYUANREN_NPC_POS[0]));
			if (FindYouYuanRenNpcCreate(pos_index - 1))
			{
				boost::recursive_mutex::scoped_lock lk(m_mutex);
				m_npc_flush_time = MakeFindYouYuanRenCurTime();
				m_npc_index = pos_index - 1;
				m_count = 0;

			}
		}
		else if (FindYouYuanRenNpcExist() && ((GetFindYouYuanRenNpcFlushTime() != MakeFindYouYuanRenCurTime()) || (curMin > YOUYUANREN_TIME))) // npc 存在，到消失时间 npc消失
		{
			FindYouYuanRenNpcDisappear();
		}
	}
	else if(FindYouYuanRenNpcExist()) // 不在活动时间内 npc消失
	{
		FindYouYuanRenNpcDisappear();
	}
}

bool CHuoDongAwardManager::FindYouYuanRenNpcExist()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return m_npc_flush_time != 0;	
}

uint32 CHuoDongAwardManager::GetFindYouYuanRenNpcFlushTime()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return m_npc_flush_time;	
}

bool CHuoDongAwardManager::FindYouYuanRenNpcCreate(int pos_index)
{
	if (pos_index < 0 || pos_index >= (int)(sizeof(YOUYUANREN_NPC_POS) / sizeof(YOUYUANREN_NPC_POS[0])))
		return false;

	int mapId = YOUYUANREN_NPC_POS[pos_index][0];
	int posX = YOUYUANREN_NPC_POS[pos_index][1];
	int posY = YOUYUANREN_NPC_POS[pos_index][2];

	CSceneManager &sceneMgr = SingletonSceneManager::instance();
	CScene *pScene = sceneMgr.FindScene(mapId);
	if (pScene == NULL)
		return false;

	CNpcManager &npcManager = SingletonNpcManager::instance();
	SNpcTemplate *pNpc = npcManager.GetNpcTemplate(YOUYUANREN_NPC_ID);
	if (pNpc == NULL)
		return false;

	pScene->AddNpcWithIndex(pNpc->id,pNpc->pic,posX,posY,0,0);

	char buf[512];
	snprintf(buf,sizeof(buf),LANGUAGE_LLD_0153,pNpc->name.c_str());
	SysInfoToAllUser(buf);
	cout << "add npc mapid:" << mapId << ",X:" << posX << ",Y" << posY << endl;
	return true;
}

void CHuoDongAwardManager::FindYouYuanRenNpcDisappear()
{
	int npc_index = -1;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		npc_index = m_npc_index;
	}

	if (npc_index < 0 || npc_index >= (int)(sizeof(YOUYUANREN_NPC_POS) / sizeof(YOUYUANREN_NPC_POS[0])))
		return;

	int mapId = YOUYUANREN_NPC_POS[npc_index][0];

	CSceneManager &sceneMgr = SingletonSceneManager::instance();
	CScene *pScene = sceneMgr.FindScene(mapId);
	if (pScene == NULL)
		return;

	CNpcManager &npcManager = SingletonNpcManager::instance();
	SNpcTemplate *pNpc = npcManager.GetNpcTemplate(YOUYUANREN_NPC_ID);
	if (pNpc == NULL)
		return;

	pScene->DelNpc(pNpc->id,0);

	char buf[512];
	snprintf(buf,sizeof(buf),LANGUAGE_LLD_0154,pNpc->name.c_str());
	SysInfoToAllUser(buf);
	cout << "del npc mapid:" << mapId << endl;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_npc_flush_time = 0;
	m_npc_index = -1;
	m_count = 0;
}

int CHuoDongAwardManager::GetFindYouYuanRenCount()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return m_count;
}

void CHuoDongAwardManager::AddFindYouYuanRenCount(int count)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_count += count;
}

void CHuoDongAwardManager::CheckXtmasTree()
{
	const uint32 hd_type = SHENGDAN_FENGSHOU;
	uint32 npcid = GetHuoDongPic(hd_type);
	CSceneManager &sceneMgr = SingletonSceneManager::instance();
	CScene *pScene = sceneMgr.FindScene(11);
	if(pScene == NULL)
		return;
	if(InHuoDongTime(hd_type))
	{
		if( !FindNpcByScene(npcid,11))
		{
			pScene->AddNpcWithIndex(npcid,0,1479,876,0,0);
			CNetMessage msg;
			msg.SetType(MSG_XTMAS_TREE);
			uint8 type = 0;
			uint8 num =5; 
			uint32 time = 0; 
			int mapID =11;
			int pos_x = 1479;
			int pos_y = 876;
			switch (npcid)
			{
				case CHRISTMAS_TREE_ID:
					{
						uint32 startTime = GetHuoDongStartTime(hd_type);
						if (startTime != GetChristmasStartTime())
						{
							ClearChristmasInfo();
							SetChristmasStartTime(startTime);
						}
						type = 1;
					}
					break;
				case 223:
					{
						type = 2;
					}
					break;
				case 224:
					{
						type =3;
					}
					break;
				default:
					break;
			}
			msg<<(uint8)1<<type<<num<<time<<mapID<<pos_x<<pos_y;
			SendMsgToAllUser( msg );
		}
	}
	else
	{
		if( FindNpcByScene(npcid,11))
		{
			pScene->DelNpc(npcid,0);
			SingletonCWaitForFightManager::instance().ClearNpcInfo( npcid );
			//发消息给所有人去清除图标
			CNetMessage msg;
			msg.SetType(MSG_XTMAS_TREE);
			msg<<(uint8)2;
			SendMsgToAllUser( msg );

			if (npcid == CHRISTMAS_TREE_ID)
				ClearChristmasInfo();
		}
	}//end of if
}
CHuoDongAwardManager::CHuoDongAwardManager()
{
	xtmasbox_index_vec.clear();
	xuelian_index_vec.clear();
	m_xtmasbox_map.clear();
	m_box_refresh_sign = false;
	m_box_index = 0;

	m_npc_flush_time = 0;
	m_npc_index = -1;
	m_count = 0;

	m_christmas_changzhangzhi = 0;
	m_christmas_starttime = 0;

	m_save_hb_data = false;
	m_needSort = false;
}
void CHuoDongAwardManager::CheckXtmasBox()
{
	const int pos[][2]={{1002,941},{5861,91},{1059,1135},{1122,1390},{1495,1483},{1844,1468},{1857,1113},
						 {2048,1218},{2232,1315},{2441,667},{2457,396},{2076,463},{1871,702},{1616,199},
						 {1120,158},{738,172},{565,299},{309,423},{887,468},{571,575},{232,853},{116,1145},
						 {344,1263},{656,1353},{908,1496}};		
	const int box_id = GetHuoDongPic(XTMAS_BOX);	
	CSceneManager &sceneMgr = SingletonSceneManager::instance();
	CScene *pScene = sceneMgr.FindScene(11);
	if (pScene == NULL)
		return;
	if(InHuoDongTime(XTMAS_BOX))
	{
		char buf[128];
		snprintf(buf,sizeof(buf),LANGUAGE_CHY_17);
		SysInfoToAllUser(buf);
		if( !xtmasbox_index_vec.empty())
		{
			vector<int>::iterator vec_iter= xtmasbox_index_vec.begin();
			for( ;vec_iter != xtmasbox_index_vec.end(); ++vec_iter )
			{
				pScene->DelNpc(box_id,*vec_iter);
			}
			SingletonCWaitForFightManager::instance().ClearNpcInfo( box_id );
		}
		xtmasbox_index_vec.clear();
		for(int counter = 0; counter < 15; ++counter )
		{
			int pos_num = sizeof(pos)/sizeof(pos[0]);
			int pos_x = 0;
			int pos_y = 0;
			bool isfind = false;
			int max_random_num = 100;
			int random_num = 0;
			do
			{
				int pos_index = Random(1,pos_num);
				pos_x = pos[pos_index-1][0];
				pos_y = pos[pos_index-1][1];
				if( NULL == pScene->FindNpcByPos(pos_x,pos_y))
					isfind = true;
				++random_num;
				if( random_num >= max_random_num)
					break;
			}while( !isfind );
			if(isfind )
			{
				xtmasbox_index_vec.push_back(counter+1);
				pScene->AddNpcWithIndex(box_id,0,pos_x,pos_y,0,counter+1);
			}
		}//end of for

	}
}

void CHuoDongAwardManager::ClearXtmasBox_New()
{
	if(InHuoDongTime(XTMAS_BOX) || m_xtmasbox_map.empty())
		return;
	const int box_id = GetHuoDongPic(XTMAS_BOX);	
	if(box_id < 1)
		return;
	CSceneManager &sceneMgr = SingletonSceneManager::instance();
	map<int,vector<int> >::iterator mapIter;
	for( mapIter = m_xtmasbox_map.begin() ; mapIter != m_xtmasbox_map.end() ; ++mapIter )
	{
		CScene *pScene = sceneMgr.FindScene(mapIter->first);
		if(pScene == NULL || mapIter->second.size() == 0)
			continue;
		for(uint16 i=0;i<mapIter->second.size();i++)
		{
			pScene->DelNpc(box_id,mapIter->second[i]);
		}
	}
	m_xtmasbox_map.clear();
	m_box_refresh_sign = false;
	m_box_index = 0;
}

void CHuoDongAwardManager::CheckXtmasBox_New()
{
	if(m_box_refresh_sign || !InHuoDongTime(XTMAS_BOX))
		return;
	const int box_id = GetHuoDongPic(XTMAS_BOX);	
	if(box_id < 1)
		return;
	CNpcManager &npcManager = SingletonNpcManager::instance();
	SNpcTemplate *pNpc = npcManager.GetNpcTemplate(box_id);
	if(pNpc == NULL)
		return;

	const int sceneId[3] = {2,3,4};
	const int ADD_BOX_NUM = 10;
	if(m_box_index < 1)
		m_box_index = 1;
	CSceneManager &sceneMgr = SingletonSceneManager::instance();
	for(int i=0;i<3;i++)
	{
		CScene *pScene = sceneMgr.FindScene(sceneId[i]);
		if (pScene == NULL)
			continue;

		char buf[128];
		snprintf(buf,sizeof(buf),LANGUAGE_CC_0011,pScene->GetName(),pNpc->name.c_str());
		SysInfoToAllUser(buf);

		for(int k=0;k<ADD_BOX_NUM;k++)
		{
			m_xtmasbox_map[sceneId[i]].push_back(m_box_index+k);
		}
		pScene->AddXtmasBox(box_id,m_box_index,pNpc->pic,ADD_BOX_NUM);

	}
	m_box_refresh_sign = true;
}

//节日活动后清除排行榜数据
void CHuoDongAwardManager::ClearFestivalPaiHang()
{
	if(InHuoDongTime(FESTIVAL))
		return;
//	SingletonCRankDataMgr::instance().ClearRankData(ECRT_FestivalF);
//	SingletonCRankDataMgr::instance().ClearRankData(ECRT_FestivalT);
}

void CHuoDongAwardManager::CheckKuaFuXueLian()
{
#ifndef KUA_FU
	return;
#endif
	if(!xuelian_index_vec.empty())
		return;
	CSceneManager &sceneMgr = SingletonSceneManager::instance();
	CScene *pScene = sceneMgr.FindScene(KUA_FU_SCENE_ID);
	if (pScene == NULL)
		return;
	for(int counter = 0; counter < 10; ++counter )
	{
		int index = pScene->AddXueLianNpc();
		AddXueLianIndex(index);
	}//end of for

}
void CHuoDongAwardManager::AddXueLianIndex(int index)
{
	if( index != 0 )
		xuelian_index_vec.push_back(index);
}

bool CHuoDongAwardManager::GetExchangeInfo(uint32 type, uint32 idx, HDExchangeInfo &info)
{
	if(type == 0 || idx == 0)
		return false;
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,HDExchangeList>::iterator it = m_exchange_info.find(type);
	if(it != m_exchange_info.end())
	{
		for(HDExchangeList::iterator t=it->second.begin();t != it->second.end();t++)
		{
			if(t->idx == idx)
			{
				info = *t;
				return true;
			}
		}
	}
	return false;
}

void CHuoDongAwardManager::GetExchangeInfo(uint32 type, HDExchangeList &info)
{
	if(type == 0)
		return;
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	info.clear();
	map<uint32,HDExchangeList>::iterator it = m_exchange_info.find(type);
	if(it != m_exchange_info.end())
	{
		for(HDExchangeList::iterator t=it->second.begin();t != it->second.end();t++)
			info.push_back(*t);
	}
}


void CHuoDongAwardManager::GetAwardData(uint32 type,uint32 idx,SHuoDongAward &awardList)
{
	if(type == 0 || idx == 0)
		return;

	if (type == ZHENYING_PK1 || type == ZHENYING_PK2)
		type = ZHENYING_PK;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,HuoDongList>::iterator it = m_award.find(type);
	if(it != m_award.end())
	{
		for(HuoDongList::iterator t=it->second.begin();t != it->second.end();t++)
		{
			if(t->idx == idx)
			{
				awardList = *t;
				return;
			}
		}
	}
}

// idx 第几届 range 为 idx2 与 idx3之间的某个值
void CHuoDongAwardManager::GetAwardDataByRange(uint32 type, uint32 idx, uint32 range, SHuoDongAward &awardList)
{
	if (type == 0 || idx == 0)
		return;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32, HuoDongList>::iterator it = m_award.find(type);
	if (it != m_award.end())
	{
		for (HuoDongList::iterator t = it->second.begin(); t != it->second.end(); t++)
		{
			if (t->idx == idx && t->idx2 <= range && t->idx3 >= range)
			{
				awardList = *t;
				return;
			}
		}
	}
}

//add by zhudaolong 2017.11.01
void CHuoDongAwardManager::GetMaterialInfo(map<uint32,uint32> &materialinfo)
{
	materialinfo.clear();
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,uint32>::iterator it = m_THG_material_info.begin();
	for(;it != m_THG_material_info.end();it++)
	{
		materialinfo.insert(make_pair(it->first, it->second));
	}
}

void CHuoDongAwardManager::GetAwardDataList(uint32 type,vector<uint32> idxs,vector<SHuoDongAward> &awardList)
{
	if(type == 0)
		return;
	
	awardList.clear();
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,HuoDongList>::iterator it = m_award.find(type);
	for (uint32 i = 0; i < idxs.size(); i++)
	{
		if(it != m_award.end())
		{
			for(HuoDongList::iterator t=it->second.begin();t != it->second.end();t++)
			{
				if(t->idx == idxs[i])
				{
					awardList.push_back(*t);
					break;
				}
			}
		}
	}
}

void CHuoDongAwardManager::GetAwardIdxList(uint32 type,vector<uint32> &idxList)
{
	idxList.clear();
	if(type == 0)
		return;
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,HuoDongList>::iterator it = m_award.find(type);
	if(it != m_award.end())
	{
		for(HuoDongList::iterator t=it->second.begin();t != it->second.end();t++)
			idxList.push_back(t->idx);
	}
}

void CHuoDongAwardManager::GetAwardIdxList(uint32 type,uint32 idx2,vector<uint32> &idxList)
{
	idxList.clear();
	if(type == 0)
		return;
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,HuoDongList>::iterator it = m_award.find(type);
	if(it != m_award.end())
	{
		for(HuoDongList::iterator t=it->second.begin();t != it->second.end();t++)
		{
			if(t->idx2 == idx2)
			{
				idxList.push_back(t->idx);
			}
		}
	}
}

void CHuoDongAwardManager::GetNoLockAwardIdxList(uint32 type,uint32 idx2,vector<uint32> &idxList)
{
	idxList.clear();
	if(type == 0)
		return;
	
	map<uint32,HuoDongList>::iterator it = m_award.find(type);
	if(it != m_award.end())
	{
		for(HuoDongList::iterator t=it->second.begin();t != it->second.end();t++)
		{
			if(t->idx2 == idx2)
			{
				idxList.push_back(t->idx);
			}
		}
	}
}


uint32 CHuoDongAwardManager::GetAwardIdx(uint32 type,uint32 idx2,uint32 idx3)
{
	if(type == 0)
		return 0;

	if (type == ZHENYING_PK1 || type == ZHENYING_PK2)
		type = ZHENYING_PK;
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,HuoDongList>::iterator it = m_award.find(type);
	if(it != m_award.end())
	{
		for(HuoDongList::iterator t=it->second.begin();t != it->second.end();t++)
		{
			if(t->idx2 == idx2 && t->idx3 == idx3)
			{
				return t->idx;
			}
		}
	}
	return 0;
}

uint32 CHuoDongAwardManager::GetLevelJiJinAwardIdx(uint32 type, uint32 jjlv, uint32 getindex, uint32 userLevel)
{
	if (type == 0)
		return 0;

	if (type == ZHENYING_PK1 || type == ZHENYING_PK2)
		type = ZHENYING_PK;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32, HuoDongList>::iterator it = m_award.find(type);
	if (it != m_award.end())
	{
		uint32 curIdx = 0;
		for (HuoDongList::iterator t = it->second.begin(); t != it->second.end(); t++)
		{
			if (t->idx2 == jjlv && ++curIdx == getindex)
			{
				if (userLevel >= t->idx3)
					return t->idx;
				else
					return 0;
			}
		}
	}
	return 0;
}

int CHuoDongAwardManager::GetFestivalAwardIdxCnt(uint16 festivalType)
{
	if(festivalType > 1)
		return 0;
	
	int cnt = 0;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for (uint32 i = 0; i < m_festival_award[festivalType].size(); i++)
	{

		if (m_festival_award[festivalType][i].endId > cnt)
		{
			cnt = m_festival_award[festivalType][i].endId;
		}
	}
	return cnt;
}


int CHuoDongAwardManager::GetNeedYB(uint32 type,uint32 idx)
{
	if(type == 0)
		return 0;
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,HuoDongList>::iterator it = m_award.find(type);
	if(it != m_award.end())
	{
		for(HuoDongList::iterator t=it->second.begin();t != it->second.end();t++)
		{
			if(t->idx == idx)
				return t->needYB;
		}
	}
	return 0;
}

int CHuoDongAwardManager::GetIdx3(uint32 type,uint32 idx)
{
	if(type == 0)
		return 0;
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,HuoDongList>::iterator it = m_award.find(type);
	if(it != m_award.end())
	{
		for(HuoDongList::iterator t=it->second.begin();t != it->second.end();t++)
		{
			if(t->idx == idx)
				return t->idx3;
		}
	}
	return 0;
}

int CHuoDongAwardManager::GetHuoDongInfo(uint32 type, SHuoDongInfo &info)
{
	if(type == 0)
		return 0;
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,SHuoDongInfo>::iterator it = m_info.find(type);
	if(it != m_info.end())
	{
		info = it->second;
	}
	return 0;
}

bool CHuoDongAwardManager::CheckHuoDongShow(uint32 type)
{
	if(type == 0)
		return 0;
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,SHuoDongInfo>::iterator it = m_info.find(type);
	if(it != m_info.end())
	{
		return it->second.isShow == 1;
	}
	return false;
}

int CHuoDongAwardManager::GetHuoDongList(vector<uint32> &list)
{
	list.clear();
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for (uint32 i = 0; i < m_list.size(); i++)
		list.push_back(m_list[i]);
	return 0;
}

void CHuoDongAwardManager::GetHDPaiHangInfo(uint32 type, HDPaiHangList &info)
{

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	
	map<uint32,HDPaiHangList>::iterator it = m_paiHang_info.find(type);
	if(it != m_paiHang_info.end())
	{
		for (HDPaiHangList::iterator t=it->second.begin();t != it->second.end();t++)
		{
			info.push_back(*t);
		}
	}

	return;
}

uint32 CHuoDongAwardManager::GetHDPaiHangAwardIdxByRank(uint32 type, uint32 rank)
{
	if(type == 0)
		return 0;

	if (type == ZHENYING_PK1 || type == ZHENYING_PK2)
		type = ZHENYING_PK;
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,HDPaiHangList>::iterator it = m_paiHang_info.find(type);
	if(it != m_paiHang_info.end())
	{
		for (HDPaiHangList::iterator t=it->second.begin();t != it->second.end();t++)
		{
			if ((*t).startId <= rank && (*t).endId >= rank)
				return ((*t).idx);
		}
	}

	return 0;
}

void CHuoDongAwardManager::GetNoLockHDPaiHangRecord(uint32 type, vector<HDPaiHangRecordInfo> &info)
{
	if(type == 0)
		return;

	map<uint32,HDPaiHangRecordList>::iterator it = m_paiHang_record.find(type);
	if(it != m_paiHang_record.end())
	{
		if (type == MEIRI_HUANHAOLI)
		{
			SSortXianShiChouPaiHang sortPaiHang;
			std::sort(it->second.begin(),it->second.end(),sortPaiHang);
		}
		else
		{
			SSortChristmasTreePaiHang sortPaiHang;
			std::sort(it->second.begin(),it->second.end(),sortPaiHang);
		}
		
		for (HDPaiHangRecordList::iterator t=it->second.begin();t != it->second.end();t++)
			info.push_back(*t);
	}

	return;

}

void CHuoDongAwardManager::SendHDPaiHangRecord(uint32 type, vector<HDPaiHangRecordInfo> &info)
{
	if(type == 0)
		return;

	int idx2 = 1;
	uint32 zhenYingPKWin = 0;
	double ratio = 1.0;

	if (type == SHENGDAN_FENGSHOU)
		idx2 = CHRISTMAS_TREE_IDX2_PAIHANG;
	else if (type == XINCHUN_HAPPY)
		idx2 = XINCHUN_HAPPY_IDX2_PAIHANG;
	else if (type == ZHENYING_PK1 || type == ZHENYING_PK2)
	{
		idx2 = ZHENYING_PK_MEM_IDX2;
		
		zhenYingPKWin = GetZhenYingWinId();
	}

	map<uint32, uint32> getAwardRole;
	getAwardRole.clear();

	HDPaiHangList paiHangInfo;
	GetHDPaiHangInfo(type, paiHangInfo);

	char mailMsg[512];
	for (uint32 i = 0; i < info.size(); i++)
	{
		int idx3 = GetHDPaiHangAwardIdxByRank(type, i + 1);
		int idx = GetAwardIdx(type,idx2,idx3);
		if (idx > 0)
		{
			SHuoDongAward award;
			GetAwardData(type,idx,award);
			if (type == SHENGDAN_FENGSHOU)
				snprintf(mailMsg,sizeof(mailMsg),LANGUAGE_LLD_0178,(i + 1));
			else if (type == ZHENYING_PK)
				snprintf(mailMsg,sizeof(mailMsg),LANGUAGE_LLD_0210,(i + 1));
			else if (type == ZHENYING_PK1 || type == ZHENYING_PK2)
			{
				if (type == zhenYingPKWin)
				{
					ratio = 1.5;
					snprintf(mailMsg,sizeof(mailMsg),LANGUAGE_LLD_0211,(i + 1),(int)(ratio * 100));
				}
				else
				{
					ratio = 0.8;
					snprintf(mailMsg,sizeof(mailMsg),LANGUAGE_LLD_0212,(i + 1),(int)(ratio * 100));
				}
			}
			else
				snprintf(mailMsg,sizeof(mailMsg),LANGUAGE_LLD_0033,GetHuoDongTimeDesc(type).c_str(), GetHuoDongName(type).c_str(),(i + 1));
			
			SendHuoDongAwardMail(info[i].role_id, info[i].role_lv, award, mailMsg,type,ratio);
		}

		getAwardRole.insert(make_pair(info[i].role_id,1));
	}

	if (type == ZHENYING_PK1 || type == ZHENYING_PK2)
	{
		SendHDNotInPaiHangInScoreAward(1,getAwardRole,type); // 1 为受赠
	}
	return;
}

void CHuoDongAwardManager::GetHDPaiHangRecord(uint32 type, vector<HDPaiHangRecordInfo> &info)
{
	if(type == 0)
		return;
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	GetNoLockHDPaiHangRecord(type,info);
}

void CHuoDongAwardManager::ChargeTime(const char *srcTime, string &dstTime)
{
	if (srcTime == NULL)
		return;
	
	string src = srcTime;
	char *time[2];
	char *time1[3];
	char *time2[3];
	char tmp[100];
	SplitLine(time, (char*)src.c_str(), ' ');
	SplitLine(time1, time[0], '-');
	SplitLine(time2, time[1], ':');

	
	snprintf(tmp, sizeof(tmp), LANGUAGE_TRANSFORM_128, atoi(time1[1]), atoi(time1[2]), atoi(time2[0]), atoi(time2[1]));

	dstTime = tmp;
}

void CHuoDongAwardManager::ChargeBangTime(const char *srcTime, string &sTime,string &eTime)
{
	if (srcTime == NULL)
		return;
	
	string src = srcTime;
	char *time[2];
	char *time1[3];
	char *time2[3];
	char startTime[100];
	char endTime[100];
	
	SplitLine(time, (char*)src.c_str(), ' ');
	SplitLine(time1, time[0], '-');
	SplitLine(time2, time[1], ':');

	snprintf(startTime, sizeof(startTime), LANGUAGE_TRANSFORM_129, atoi(time1[1]), atoi(time1[2]), 0);
	snprintf(endTime, sizeof(endTime), LANGUAGE_TRANSFORM_130, atoi(time1[1]), atoi(time1[2]), 24);

	sTime = startTime;
	eTime = endTime;
}

//获取到当天0点的秒数
int CHuoDongAwardManager::GetZeroTime(const char *srcTime)
{
	if (srcTime == NULL)
		return 0;
	
	string src = srcTime;
	char *time[2];
	char *time2[3];
	
	SplitLine(time,(char*)src.c_str(), ' ');
	SplitLine(time2, time[1], ':');

    int value = atoi(time2[0])*3600+atoi(time2[1])*60+atoi(time2[2]);
	return value;
}

void CHuoDongAwardManager::GetTimeDesc(uint32 type, const char *sTime, const char *eTime, string &timeDesc)
{
	string startDesc;
	string endDesc;

	if (type == CHuoDongAwardManager::SHEN_CHONG_BANG || type == CHuoDongAwardManager::EQUIP_QIANGHUA_BANG || type == CHuoDongAwardManager::ROLE_LEVEL_BANG
		|| type == CHuoDongAwardManager::ZHAN_LI_BANG || type == CHuoDongAwardManager::CHONG_ZHI_BANG || type == CHuoDongAwardManager::WING_BANG)
	{
		ChargeBangTime(eTime, startDesc, endDesc);
	}
	else
	{
		ChargeTime(sTime, startDesc);
		ChargeTime(eTime, endDesc);
	}

	timeDesc = startDesc + " - " + endDesc;
}

bool CHuoDongAwardManager::InHuoDongTime(uint32 type)
{
	if(type == 0)
		return false;

	if (type == ZHENYING_PK1 || type == ZHENYING_PK2)
		type = ZHENYING_PK;
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,SHuoDongInfo>::iterator it = m_info.find(type);
	if(it != m_info.end())
	{
		SHuoDongInfo *info = &it->second;
		uint32 curTime = GetSysTime();
		return (curTime >= info->iStartTime && curTime < info->iEndTime);
	}
	else if (type == HUOYUE_JIJIN_FANLI)
		return true;

	return false;
}

bool CHuoDongAwardManager::InHuoDongHour(uint32 type)
{
	if(type == 0)
		return false;
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,SHuoDongInfo>::iterator it = m_info.find(type);
	if(it != m_info.end())
	{
		SHuoDongInfo *info = &it->second;
		uint32 curHour = GetSysHour();
		return (curHour >= info->startHour && curHour <= info->endHour);
	}

	return false;
}

void CHuoDongAwardManager::GetHuoDongHour(uint32 type,uint32 &startHour,uint32 &endHour)
{
	if(type == 0)
		return;
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,SHuoDongInfo>::iterator it = m_info.find(type);
	if(it != m_info.end())
	{
		SHuoDongInfo *info = &it->second;
		startHour = info->startHour;
		endHour = info->endHour;
	}
}

bool CHuoDongAwardManager::InHuodongLimit(CUser *pUser,uint32 type)
{
	if (pUser != NULL)
	{
		uint32 curHour = GetHour();
		//uint8 level = pUser->GetLevel();
		if (type == CHuoDongAwardManager::EXP_TEN_REWARD)
		{
			//uint8 limitLevel = 30;
			if (/*level >= limitLevel &&*/ InHuoDongTime(type) && (curHour >= CHuoDongAwardManager::EXP_TEN_REWARD_START && curHour < CHuoDongAwardManager::EXP_TEN_REWARD_END))
				return true;
		}
	}

	return false;
}

uint32 CHuoDongAwardManager::GetHuoDongZeroStartTime(uint32 type)
{
	if(type == 0)
		return 0xffffffff;

	if (type == ZHENYING_PK1 || type == ZHENYING_PK2)
		type = ZHENYING_PK;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,SHuoDongInfo>::iterator it = m_info.find(type);
	if(it != m_info.end())
		return it->second.zeroStartTime;
		
	return 0xffffffff;
}

uint32 CHuoDongAwardManager::GetHuoDongStartTime(uint32 type)
{
	if(type == 0)
		return 0xffffffff;

	if (type == ZHENYING_PK1 || type == ZHENYING_PK2)
		type = ZHENYING_PK;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,SHuoDongInfo>::iterator it = m_info.find(type);
	if(it != m_info.end())
		return it->second.iStartTime;
		
	return 0xffffffff;
}

uint32 CHuoDongAwardManager::GetHuoDongEndTime(uint32 type)
{
	if(type == 0)
		return 0;
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,SHuoDongInfo>::iterator it = m_info.find(type);
	if(it != m_info.end())
		return it->second.iEndTime;
		
	return 0;
}

uint32 CHuoDongAwardManager::GetHuoDongIconEndTime()
{
	uint32 iEndTime = 0;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(map<uint32,SHuoDongInfo>::iterator it = m_info.begin(); it != m_info.end(); it++)
	{
		if (it->second.iEndTime > iEndTime)
			iEndTime = it->second.iEndTime;
	}
	return iEndTime;
}

string CHuoDongAwardManager::GetHuoDongTimeDesc(uint32 type)
{
	string timeDesc;
	if(type == 0)
		return timeDesc;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,SHuoDongInfo>::iterator it = m_info.find(type);
	if(it != m_info.end())
		timeDesc = it->second.timeDesc;

	return timeDesc;
}

string CHuoDongAwardManager::GetHuoDongLeiJiTimeDesc(uint32 type)
{
	string timeDesc;
	if(type == 0)
		return timeDesc;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,SHuoDongInfo>::iterator it = m_info.find(type);
	if(it != m_info.end())
		timeDesc = it->second.leijiDesc;

	return timeDesc;
}


uint32 CHuoDongAwardManager::GetHuoDongPic(uint32 type)
{
	uint32 picId = 14;

	if(type == 0)
		return picId;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,SHuoDongInfo>::iterator it = m_info.find(type);
	if(it != m_info.end())
		picId = it->second.pic;

	return picId;
}

string CHuoDongAwardManager::GetHuoDongName(uint32 type)
{
	string name;

	if(type == 0)
		return name;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,SHuoDongInfo>::iterator it = m_info.find(type);
	if(it != m_info.end())
		name = it->second.name;

	return name;

}

uint32 CHuoDongAwardManager::GetHuoDongLeijiTime(uint32 type)
{
	uint32 LeijiTime = 0;
	
	if(type == 0)
		return LeijiTime;
	
	uint32 now = GetSysTime();
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,SHuoDongInfo>::iterator it = m_info.find(type);
	if (it != m_info.end())
	{
		if (type == ROUND_ZHEKOU_HUODONG1
			|| type == ROUND_ZHEKOU_HUODONG2
			|| type == ROUND_ZHEKOU_HUODONG3)
		{
			if (it->second.leijiTime == 0)
				return it->second.iEndTime;
			while (it->second.leijiTime < now)
			{
				it->second.leijiTime += it->second.day * 24 * 3600;
				if (it->second.leijiTime > it->second.iEndTime)
				{
					it->second.leijiTime = it->second.iEndTime;
					break;
				}
			}
		}
		LeijiTime = it->second.leijiTime != 0 ? it->second.leijiTime : it->second.iEndTime;
	}
		
	return LeijiTime;
}

bool CHuoDongAwardManager::InHuoDongLeijiTime(uint32 type)
{
	uint32 curTime = GetSysTime();
	uint32 startTime = GetHuoDongStartTime(type);
	uint32 leijiTime = GetHuoDongLeijiTime(type);

	return curTime >= startTime && leijiTime >= curTime;
}


void CHuoDongAwardManager::GetZhaDanShowInfo(vector<struct SZhaDanInfo> &info, int type)
{
	info.clear();

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if (type == 1)
	{
		for (uint32 i = 0; i < m_ybZhaDan.size(); i++)
		{
			if (m_ybZhaDan[i].isShow)
				info.push_back(m_ybZhaDan[i]);
		}
	}
	else if (type == 0)
	{
		for (uint32 i = 0; i < m_copyZhaDan.size(); i++)
		{
			if (m_copyZhaDan[i].isShow)
				info.push_back(m_copyZhaDan[i]);
		}
	}
}

uint32 CHuoDongAwardManager::GetHDRandAwardIdx(HDRandAwardList &info,uint32 maxRate)
{
	uint32 index = 0;
	uint32 minRate = 0;
	uint32 rand = Random(1,maxRate);
	
	if (rand < 1)
		rand = 1;
	
	if (rand > maxRate)
		rand = maxRate;
	
	for (uint32 j = 0; j < info.size(); j++)
	{
		if ((info[j].rate > 0) && rand > minRate && info[j].rate >= rand)
		{
			index = j;
			minRate = info[j].rate;
		}
	}
	return index;
}

uint32 CHuoDongAwardManager::GetPaiHangLimitScore(uint32 type)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);

	if (type == ZHENYING_PK1 || type == ZHENYING_PK2)
		type = ZHENYING_PK;

	map<uint32,HDPaiHangList>::iterator it = m_paiHang_info.find(type);
	if(it != m_paiHang_info.end())
	{
		for (HDPaiHangList::iterator t=it->second.begin();t != it->second.end();t++)
		{
			if ((*t).startId == 0)
				return ((*t).score);
		}
	}

	return 0;
}

uint32 CHuoDongAwardManager::GetPaiHangSize(uint32 type)
{
	if (type == ZHENYING_PK1 || type == ZHENYING_PK2)
		type = ZHENYING_PK;

	boost::recursive_mutex::scoped_lock lk(m_mutex);

	map<uint32,uint32>::iterator it = m_paiHang_size.find(type);
	if (it == m_paiHang_size.end())
		return 0;
	else
		return it->second;
}

bool CHuoDongAwardManager::GetPaiHangState(uint32 type)
{
	map<uint32,uint32>::iterator it = m_paiHang_state.find(type);
	if (it == m_paiHang_state.end())
		return false;
	else
		return it->second == 1 ? true : false;
}

void CHuoDongAwardManager::SetPaiHangState(uint32 type)
{
	map<uint32,uint32>::iterator it = m_paiHang_state.find(type);
	if (it == m_paiHang_state.end())
		m_paiHang_state.insert(make_pair(type, 1));
	else
		it->second = 1;
}

void CHuoDongAwardManager::ClearPaiHangState(uint32 type)
{
	map<uint32,uint32>::iterator it = m_paiHang_state.find(type);
	if (it == m_paiHang_state.end())
		m_paiHang_state.insert(make_pair(type, 0));
	else
		it->second = 0;
}


void CHuoDongAwardManager::UpdatePaiHang(CUser *pUser,uint32 type,uint32 data)
{
	if (data == 0)
		return;

	uint32 limitScore = GetPaiHangLimitScore(type);
	if (limitScore > 0 && limitScore > data)
		return;

	uint32 maxSize = GetPaiHangSize(type);
	if (maxSize == 0)
		return;

	HDPaiHangRecordInfo recordInfo;
	recordInfo.role_id = pUser->GetRoleId();
	recordInfo.role_name = pUser->GetName();
	recordInfo.role_lv = pUser->GetLevel();
	recordInfo.role_zhandouli = pUser->GetZhanDouLi();
	recordInfo.bang_name = pUser->GetBangPaiName();
	recordInfo.data = data;
	recordInfo.time = GetSysTime();
	recordInfo.sex = pUser->GetSex();

	if (type == ZHENYING_PK || type == ZHENYING_PK1 || type == ZHENYING_PK2)
	{
		uint32 zhenYingType = pUser->GetExtData32(383);
		char buff[125];
		snprintf(buff,sizeof(buff),"-----%d",zhenYingType);
		recordInfo.bang_name = recordInfo.bang_name + buff;
	}
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	
	map<uint32,HDPaiHangRecordList>::iterator it = m_paiHang_record.find(type);
	if (it == m_paiHang_record.end())
	{
		HDPaiHangRecordList recordList;
		recordList.push_back(recordInfo);
		m_paiHang_record.insert(make_pair(type, recordList));
	}
	else
	{
		int idx = -1;
		uint32 minScore = 999999;
		int minIdx = 0;
		HDPaiHangRecordList &recordList = it->second;
		for (uint32 i = 0; i < recordList.size(); i++)
		{
			if (recordList[i].role_id == recordInfo.role_id)
			{
				idx = i;
				break;
			}

			if (minScore > recordList[i].data)
			{
				minScore = recordList[i].data;
				minIdx = i;
			}
		}

		if (idx == -1)
		{
			
			if (recordList.size() >= maxSize)
			{
				if (HDPaiHangCompare(recordList[minIdx],recordInfo,type))
				{
					recordList[minIdx] = recordInfo;
					SetPaiHangState(type);
				}
			}
			else
			{
				recordList.push_back(recordInfo);
				SetPaiHangState(type);
			}
		}
		else
		{
			recordList[idx] = recordInfo;
			SetPaiHangState(type);
		}
	}
}

void CHuoDongAwardManager::GetHDRandAwardInfo(uint32 type,HDRandAwardList &info)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,HDRandAwardList>::iterator it = m_randAward_info.find(type);
	if (it != m_randAward_info.end())
	{
		for (uint32 i = 0; i < it->second.size(); i++)
		{
			info.push_back(it->second[i]);
		}
	}
}


bool CHuoDongAwardManager::AddHDRandAward(CUser *pUser,  uint32 huodong_type, uint32 count, uint32 costYB)
{
	if(pUser == NULL)
		return false;

	HDRandAwardList info;
	GetHDRandAwardInfo(huodong_type,info);

	if (info.size() == 0)
		return false;
		
	uint32 maxRate;
	uint32 YBL_TYPE;
	if (huodong_type == XIANSHI_CHOU)
	{
		maxRate = m_XianShiChouMaxRate;
		YBL_TYPE = YBL_XIAN_SHI_CHOU;
	}
	else
		return false;

	for (uint32 i = 0; i < count; i++)
	{
		uint32 index = GetHDRandAwardIdx(info,maxRate);
		AddHuoDongAward(pUser,huodong_type,info[index].award,info[index].num,info[index].petQt,info[index].petQtLv,true,false);
		ItemCurrencyLog(pUser->GetRoleId(),info[index].award,info[index].num,0,costYB,pUser->GetTongBao(),YBL_TYPE);
	}

	return true;
}

bool CHuoDongAwardManager::AddZhaDanAward(CUser *pUser, uint32 count, uint8 type, vector<string> &myHisTory, vector<string> &publicHistory, uint32 costYB, int& idx)
{
	if(pUser == NULL)
		return false;

	if (type != 1 && type != 0)
		return false;

	vector<SZhaDanInfo> *info = &m_ybZhaDan;
	uint32 maxRate = m_ybMaxRate;
	if (type == 0)
	{
		info = &m_copyZhaDan;
		maxRate = m_copyMaxRate;
	}

	for (uint32 i = 0; i < count; i++)
	{
		int index = 0;
		uint32 minRate = 0;
		uint32 rand = Random(1,maxRate);

		if (rand < 1)
			rand = 1;

		if (rand > maxRate)
			rand = maxRate;

		for (uint32 j = 0; j < info->size(); j++)
		{
			if (((*(info))[j].rate > 0) && rand > minRate && (*(info))[j].rate >= rand)
			{
				index = j;
				minRate = (*(info))[j].rate;
				break;
			}
		}

		if (count == 50)
			AddHuoDongAward(pUser,CHuoDongAwardManager::ZHA_DAN,(*(info))[index].award,(*(info))[index].num,(*(info))[index].petQt,(*(info))[index].petQtLv, false);
		else
			AddHuoDongAward(pUser,CHuoDongAwardManager::ZHA_DAN,(*(info))[index].award,(*(info))[index].num,(*(info))[index].petQt,(*(info))[index].petQtLv);
		
		GetHistory(pUser, &((*(info))[index]), myHisTory, publicHistory);

		if ((*(info))[index].award > 0 && (*(info))[index].num > 0)
		{
			ItemCurrencyLog(pUser->GetRoleId(),(*(info))[index].award,(*(info))[index].num,0,costYB,pUser->GetTongBao(), YBL_ZADAN_CHUIZI);
		}
		idx = index;
	}
	if (publicHistory.size() > 0)
		AddZhaDanPubHistory(pUser->GetRoleId(), publicHistory);
	return true;
}

void CHuoDongAwardManager::GetHistory(CUser *pUser, SZhaDanInfo *info, vector<string> &myHisTory, vector<string> &publicHistory)
{
	char buf[512];

	char goods[100];
	if(info->award < 60000)
	{
		snprintf(goods,sizeof(goods),"[c%d]%s[/c]*%u",ITEM_NAME_COLOR,GetItemName(info->award),info->num);
	}
	else if(info->award == HDAT_MONEY)
	{
		snprintf(goods,sizeof(goods),LANGUAGE_TRANSFORM_131,ITEM_NAME_COLOR,info->num);
	}
	else if(info->award == HDAT_BANG_YB)
	{
		snprintf(goods,sizeof(goods),LANGUAGE_TRANSFORM_132,ITEM_NAME_COLOR,info->num);
	}
	else if(info->award == HDAT_PET)
	{
		snprintf(goods,sizeof(goods),"[c%d]%s[/c]",ITEM_NAME_COLOR,GetPetName(info->num));
	}
	else if(info->award == HDAT_YB)
	{
		snprintf(goods,sizeof(goods),LANGUAGE_TRANSFORM_133,ITEM_NAME_COLOR,info->num);
	}
	else if(info->award == HDAT_EXP)
	{
		snprintf(goods,sizeof(goods),LANGUAGE_TRANSFORM_134,ITEM_NAME_COLOR,info->num);
	}
	else if(info->award == HDAT_QIANNENG)
	{
		snprintf(goods,sizeof(goods),LANGUAGE_TRANSFORM_135,ITEM_NAME_COLOR,info->num);
	}

	{
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_136,goods);
		string history = buf;
		myHisTory.push_back(history);
	}

	if (info->notice == 1)
	{
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_137,ROLE_NAME_COLOR,pUser->GetName(),goods);
		string history = buf;
		publicHistory.push_back(history);
	}
	
	if (info->notice == 1)
	{
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_138,ROLE_NAME_COLOR,pUser->GetName(),goods);
		SysInfoToAllUser(buf);
	}
}

void CHuoDongAwardManager::GetZhaDanPubHistory(vector<string> &publicHistory)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);

	publicHistory.clear();
	list<string>::iterator j;
	for (j = m_zhaDanPublicHistory.begin(); j != m_zhaDanPublicHistory.end(); ++j)   
		publicHistory.push_back(*j);
}

void CHuoDongAwardManager::AddZhaDanPubHistory(uint32 role_id, vector<string> &publicHistory)
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;

	char sql[40960];
	snprintf(sql, sizeof(sql), "insert INTO `zha_dan_log` (`id`,`type`, `role_id`, `data`) values ");

	for (uint32 i = 0; i < publicHistory.size(); i++)
	{
		int size = strlen(sql);
		snprintf(sql + size, sizeof(sql) - size, " (NULL, '%d','%d','%s'),", 1, role_id, publicHistory[i].c_str());
	}
	sql[strlen(sql) - 1] = ';';
	pDb->Query(sql);

	boost::recursive_mutex::scoped_lock lk(m_mutex);

	uint32 size = publicHistory.size();
	uint32 list_size = m_zhaDanPublicHistory.size();

	if (size >= 10)
	{
		m_zhaDanPublicHistory.clear();
		for (uint32 i = 0; i < 10; i++)
		{
			m_zhaDanPublicHistory.push_back(publicHistory[size - 10 + i]);
		}
	}
	else if ((size + list_size) > 10)
	{
		int pop_num = list_size + size -10;
		for (int i = 0; i< pop_num; i++)
			m_zhaDanPublicHistory.pop_front();

		for (uint32 i = 0; i < publicHistory.size(); i++)
			m_zhaDanPublicHistory.push_back(publicHistory[i]);
	}
	else
	{
		for (uint32 i = 0; i < publicHistory.size(); i++)
			m_zhaDanPublicHistory.push_back(publicHistory[i]);
	}
}

void CHuoDongAwardManager::GetFestivalAward(uint8 festivalType, vector<SFestivalAward> &award)
{
	award.clear();
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for (uint32 i = 0; i < m_festival_award[festivalType].size(); i++)
		award.push_back(m_festival_award[festivalType][i]);
}

void CHuoDongAwardManager::GetHDBangGoods(uint32 pic, vector<GoodsInfo> &info,uint32 hd_type)
{
	info.clear();
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,HDBangGoods>::iterator it = m_hd_bang_goods.find(pic);
	if(it != m_hd_bang_goods.end())
	{
		if (it->second.info.size() != 2)
			return;

		for (uint32 i = 0; i < it->second.info.size(); i++)
		{
			if (hd_type == ZHENYING_PK)
			{
				if (i == 0)
				{
					it->second.info[i].give_data_id = 386; // 赠送数量的ExtDataId       默认的为节日排行榜的 dataID
					it->second.info[i].get_data_id = 387; // 受赠数量的ExtDataId		默认的为节日排行榜的 dataID
				}
				else if (i == 1)
				{
					it->second.info[i].give_data_id = 388; // 赠送数量的ExtDataId
					it->second.info[i].get_data_id = 389; // 受赠数量的ExtDataId
				}
			}
			else if(hd_type == ZHOU_NIAN_QING_1)
			{
				if(i == 0)
				{
					it->second.info[i].give_data_id = 434;	// 兑换记录
					it->second.info[i].get_data_id = 0;
				}
				else if(i == 1)
				{
					it->second.info[i].give_data_id = 435;
					it->second.info[i].get_data_id = 0;
				}
			}
			if(it->second.info[i].award > 0)
				info.push_back(it->second.info[i]);
		}
	}
}

uint32 CHuoDongAwardManager::GetFestivalMinScore(uint32 festivalType)
{
	return m_festival_min_score[festivalType];
}

uint32 CHuoDongAwardManager::GetFestivalAwardIdx3(uint32 festivalType, uint32 paiHang, uint32 score)
{
	for (uint32 i = 0; i < m_festival_award[festivalType].size(); i++)
	{
		if (m_festival_award[festivalType][i].startId == 0 )
		{
			if(paiHang == 0 || score >= m_festival_award[festivalType][i].score)
			{
				return m_festival_award[festivalType][i].idx;
			}
		}
		else
		{
			if (m_festival_award[festivalType][i].startId <= paiHang && m_festival_award[festivalType][i].endId >= paiHang)
			{
				return m_festival_award[festivalType][i].idx;
			}
		}
	}
	return 0;
}

void CHuoDongAwardManager::GetPeiZhiInfo(vector<HDPeiZhiInfo> &info, uint32 type)
{
	info.clear();
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,vector<struct HDPeiZhiInfo> >::iterator it = m_peizhi_info.find(type);
	if (it != m_peizhi_info.end())
	{
		vector<struct HDPeiZhiInfo> vecInfo = it->second;
		for (uint32 i = 0; i < vecInfo.size(); i++)
		{
			info.push_back(vecInfo[i]);
		}
	}
}

void CHuoDongAwardManager::GetPeiZhiInfo(HDPeiZhiInfo &info, uint32 type, uint32 idx)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32, vector<struct HDPeiZhiInfo> >::iterator it = m_peizhi_info.find(type);
	if (it != m_peizhi_info.end())
	{
		vector<struct HDPeiZhiInfo> vecInfo = it->second;
		for (uint32 i = 0; i < vecInfo.size(); i++)
		{
			if (vecInfo[i].index == idx)
			{
				info = vecInfo[i];
				return;
			}
		}
	}
}

bool CHuoDongAwardManager::GetDailyFanliCfg(uint32 yb, HDPeiZhiInfo& cfg)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	int type = CHuoDongAwardManager::DAILY_CHONGZHI_FANLI;
	map<uint32, vector<struct HDPeiZhiInfo> >::iterator it = m_peizhi_info.find(type);
	if (it != m_peizhi_info.end())
	{
		vector<struct HDPeiZhiInfo> vecInfo = it->second;
		for (uint32 i = 0; i < vecInfo.size(); i++)
		{
			if (vecInfo[i].price <= yb && vecInfo[i].water_cz >= yb)
			{
				cfg = vecInfo[i];
				return true;
			}
		}
	}
	return false;
}

void CHuoDongAwardManager::Print()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	cout<<"-----------------------------------------------"<<endl;
/*
	for(map<uint32,HuoDongList>::iterator it = m_award.begin(); it != m_award.end(); it++)
	{
		for(HuoDongList::iterator t=it->second.begin();t != it->second.end();t++)
		{
			cout<<"-- award: type="<<it->first<<", idx="<<t->idx<<", award1="<<t->award[0]<<", num1="<<t->num[0]
				<<", award2="<<t->award[1]<<", num2="<<t->num[1]
				<<", award3="<<t->award[2]<<", num3="<<t->num[2]
				<<", award4="<<t->award[3]<<", num4="<<t->num[3]
				<<", award5="<<t->award[4]<<", num5="<<t->num[4]
				<<", award6="<<t->award[5]<<", num6="<<t->num[5]<<endl;
		}
	}

	for(map<uint32,SHuoDongInfo>::iterator it = m_info.begin(); it != m_info.end(); it++)
	{
		SHuoDongInfo t = it->second;
			cout<<"-- award: type="<<it->first<<", type="<<t.type<<", showIndex="<<t.showIdx<<", isShow="<<(int)t.isShow
				<<", iStartTime="<<t.iStartTime<<", iEndTime="<<t.iEndTime<<", pic="<<t.pic<<",desc="<<t.timeDesc<<endl;
	}

	cout << "list:";
	for(uint32 i = 0; i < m_list.size(); i++)
	{
		cout << m_list[i] << ",";
	}
	cout << endl;

	for (uint32 i = 0; i < m_ybZhaDan.size(); i++)
	{
		cout << "info YB, type:" << (int)m_ybZhaDan[i].type << ",award:" << (int)m_ybZhaDan[i].award << ",num:" << (int)m_ybZhaDan[i].num
			<<"rate:" << (int)m_ybZhaDan[i].rate << ",isJinPin:"<<(int)m_ybZhaDan[i].isJinPin<<",isShow:" << (int)m_ybZhaDan[i].isShow<<"notice:"<<(int)m_ybZhaDan[i].notice<<endl;;
	}

	for (uint32 i = 0; i < m_czZhaDan.size(); i++)
	{
		cout << "info CZ, type:" << (int)m_czZhaDan[i].type << ",award:" << (int)m_czZhaDan[i].award << ",num:" << (int)m_czZhaDan[i].num
			<<"rate:" << (int)m_czZhaDan[i].rate << ",isJinPin:"<<(int)m_czZhaDan[i].isJinPin<<",isShow:" << (int)m_czZhaDan[i].isShow<<"notice:"<<(int)m_czZhaDan[i].notice<<endl;
	}
	cout <<"YB rate:" << (int)m_ybMaxRate<<endl;
	cout <<"CZ rate:" << (int)m_czMaxRate<<endl;

	

	for(map<uint32,vector<struct HDPeiZhiInfo> >::iterator it = m_peizhi_info.begin(); it != m_peizhi_info.end(); it++)
	{
		vector<struct HDPeiZhiInfo> t = it->second;
		for (uint32 i = 0; i < t.size(); i++)
		{
			cout<<"-- award: type="<<t[i].type<<", yb="<<t[i].YB<<", index="<<t[i].index<<", cd="<<t[i].cd<<", price="<<t[i].price<<", firstId="<<t[i].firstId<<", num="<<(int)t[i].num
				<<", saveCountId="<<(int)t[i].saveCountId<<", saveLastTimeId="<<(int)t[i].saveLastTimeId<<", count="<<(int)t[i].count<<", lv="<<(int)t[i].lv<<endl;
		}
	}
	*/

	for(map<uint32,HDExchangeList>::iterator it = m_exchange_info.begin(); it != m_exchange_info.end(); it++)
	{
		HDExchangeList t = it->second;
		for (uint32 i = 0; i < t.size(); i++)
		{
			cout<<"award: type="<<it->first<<", idx="<<t[i].idx<<", exchange_num_limit="<<t[i].exchange_num_limit<<", ext8="<<t[i].saveExt8
				<<", material1="<<t[i].material[0]<<",material_1_num="<<t[i].material_num[0]
				<<",material2="<<t[i].material[1]<<",material_2_num="<<t[i].material_num[1]
				<<",material3="<<t[i].material[2]<<",material_3_num="<<t[i].material_num[2]
				<<", award1="<<t[i].award[0]<<", num1="<<t[i].num[0]
				<<", award2="<<t[i].award[1]<<", num2="<<t[i].num[1]
				<<", award3="<<t[i].award[2]<<", num3="<<t[i].num[2]
				<<", award4="<<t[i].award[3]<<", num4="<<t[i].num[3]
				<<", award5="<<t[i].award[4]<<", num5="<<t[i].num[4]
				<<", award6="<<t[i].award[5]<<", num6="<<t[i].num[5]<<endl;
		}
	}

	for(map<uint32, map<uint32,HDChouInfo> >::iterator it = m_chou_info.begin(); it != m_chou_info.end(); it++)
	{
		cout << "time:" << it->first << endl;
		for(map<uint32,HDChouInfo>::iterator it2 = it->second.begin(); it2 != it->second.end(); it2++)
		{
			cout << "role id:" << it2->first<< "role count:" << it2->second.count << endl;
		}
	}

	cout<<"-------------------------------------------"<<endl;
}

/////////////////////////////CWaitForFightManager START///////////////////////////////////////////
CWaitForFightManager::CWaitForFightManager()
{
	waitForFightList.clear();
}

void CWaitForFightManager::EnterWaitingList(int user_id,int npc_id,int index)
{
	WaintingUser info;
	info.npc_id = npc_id;
	info.user_id = user_id;
	info.npc_index = index;
	ClearUserInfo( (uint32)user_id);
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	WaitForFightIter vec_iter = std::find( waitForFightList.begin(),waitForFightList.end(),info);
	if( vec_iter == waitForFightList.end())
	{
		waitForFightList.push_back( info );
	}
}

void CWaitForFightManager::StartToFight( CUser *pUser,int npc_id ,int index ,int des)
{
	if( NULL == pUser)
		return;
	const int XUELIAN_ID = 227;
	WaintingUser info;
	int user_id = pUser->GetRoleId();
	info.user_id = user_id;
	info.npc_index = index;
	info.npc_id = npc_id;
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	bool isFind = false;
	int enemy_id = 0;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if( npc_id == (int)awardManager.GetHuoDongPic(CHuoDongAwardManager::XTMAS_BOX) )
		{
			WaitForFightIter vec_iter = std::find( waitForFightList.begin(),waitForFightList.end(),info);
			if( vec_iter != waitForFightList.end())
			{
				isFind = true;
				waitForFightList.erase( vec_iter );
			}
		}	
		else if(npc_id == (int)awardManager.GetHuoDongPic(CHuoDongAwardManager::SHENGDAN_FENGSHOU) )
		{
			WaitForFightIter vec_iter = std::find( waitForFightList.begin(),waitForFightList.end(),info);
			if( vec_iter == waitForFightList.end())
				return;
			else
				waitForFightList.erase( vec_iter );

		}
		else if( npc_id == XUELIAN_ID)
		{
			WaitForFightIter vec_iter = std::find( waitForFightList.begin(),waitForFightList.end(),info);
			if( vec_iter != waitForFightList.end())
			{
				isFind = true;
				waitForFightList.erase( vec_iter );
			}
		}
		else
		{
			return;
		}

		if( !FightCheck(user_id))
			return;
		//寻找下一个同index的记录
		WaitForFightIter vec_iter = waitForFightList.begin();
		while( vec_iter != waitForFightList.end() )
		{
			if( vec_iter->npc_id == npc_id && vec_iter->npc_index == index )
			{
				enemy_id = vec_iter->user_id;
				vec_iter = waitForFightList.erase( vec_iter );
				if( !FightCheck(enemy_id))
				{
					return;	
				}
				else
					break;
			}
			else
			{
				++vec_iter;
			}
		}//end  of while
	}//end of m_mutex

	if( npc_id == (int)awardManager.GetHuoDongPic(CHuoDongAwardManager::XTMAS_BOX)  ||npc_id == XUELIAN_ID)
	{//我不在，也没其他人在，则读条
		if( !isFind && enemy_id == 0 && des == 1)
		{
			EnterWaitingList(user_id,npc_id,index);
			Collect(pUser,npc_id,index,1,4,LANGUAGE_SSJ_0405);
			pUser->SetCallFun("CollectCall");
			return;
		}
		else if(isFind && enemy_id == 0 && des == 1)
		{
			EnterWaitingList(user_id,npc_id,index);
			Collect(pUser,npc_id,index,1,4,LANGUAGE_SSJ_0405);
			pUser->SetCallFun("CollectCall");
			return;
		}
	}

	//进入战斗处理
	CScene *pScene = pUser->GetScene();
	if(pScene)
	{
		if( npc_id == (int)awardManager.GetHuoDongPic(CHuoDongAwardManager::XTMAS_BOX))
		{
			pScene->XtmasBoxFight( user_id, enemy_id );
			//删除NPC
			pScene->DelNpc(npc_id,index);
		}
		else if( npc_id == (int)awardManager.GetHuoDongPic(CHuoDongAwardManager::SHENGDAN_FENGSHOU) )
		{
			pScene->XtmasTreeFight( user_id, enemy_id );
		}

		if( npc_id == XUELIAN_ID)  //跨服雪莲
		{
			pScene->KuaFuXueLianFight( user_id, enemy_id );
			
			//召唤新的NPC
			int new_index = pScene->AddXueLianNpc();
			awardManager.AddXueLianIndex(new_index);
			//删除当前NPC
			pScene->DelNpc(npc_id,index);
		}

	}
}

bool CWaitForFightManager::FightCheck( int user_id)
{
	ShareUserPtr pUser = SingletonOnlineUser::instance().GetUserByRoleId(user_id);
	char buf[128];//提示文字 
	if( pUser.get() == NULL)//不在线
	{
		return false;
	}
	/*if (pUser->GetLevel() < 30)
	{
		snprintf(buf, sizeof(buf), LANGUAGE_CHY_15);
		SendSysInfo(pUser.get(), MakeStringColor(buf, TIPS_FAILURE_COLOR).c_str());
		return false;
	}*/
	if( pUser->GetTeam())//组队了
	{
		snprintf(buf,sizeof(buf),LANGUAGE_CHY_16);
		SendSysInfo(pUser.get(),MakeStringColor(buf,TIPS_FAILURE_COLOR).c_str());
		return false;
	}
	if(pUser->GetKuaFuState() != EKFS_IN_LOCAL)
		return false;
	if( pUser->GetFightId() != 0 )//在战斗中
	{
		return false;
	}
	return true;
}

void CWaitForFightManager::ClearNpcInfo(int npc_id)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	WaitForFightIter vec_iter = waitForFightList.begin();
	while( vec_iter != waitForFightList.end() )
	{
		if( vec_iter->npc_id == npc_id )
		{
			vec_iter = waitForFightList.erase( vec_iter );
		}
		else
		{
			++vec_iter;
		}
	}
}

void CWaitForFightManager::ClearUserInfo(uint32 user_id)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	WaitForFightIter vec_iter = waitForFightList.begin();
	while( vec_iter != waitForFightList.end() )
	{
		if( vec_iter->user_id == (int)user_id )
		{

			vec_iter = waitForFightList.erase( vec_iter );
		}
		else
		{
			++vec_iter;
		}
	}
}
/////////////////////////////////CWaitForFightManager  END//////////////////////////////////////


/////////////////////////////////CFestivalRandomBoxManager START////////////////////////////////

CFestivalRandomBoxManager::CFestivalRandomBoxManager()
{
	Init();
}

bool CFestivalRandomBoxManager::Init()
{	
	last_fresh_day = 0;
	randombox_stamp = 0;
	boxIdVec.clear();
	limitSaveMap.clear();
	randombox_cfg.clear();
	return LoadCfg();
}

void CFestivalRandomBoxManager::TimeOut()
{
	if(randombox_stamp == 0)
		randombox_stamp = GetSysTime();
	if(randombox_stamp +60*60 >= GetSysTime())
	{
		LoadCfg();
	}
}

bool CFestivalRandomBoxManager::LoadCfg()
{
	randombox_stamp = GetSysTime();
	if( last_fresh_day != GetSysMDay() )
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		limitSaveMap.clear();
		last_fresh_day = GetSysMDay(); 
	}

	boxIdVec.clear();
	randombox_cfg.clear();

	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	//										0   1			2	3	4	5		6				7		8			
	if ((pDb != NULL) && (pDb->Query("select id,box_id,item_id,odds,num,quality,quality_level,isnotice,day_limit from festival_box order by box_id asc")))
	{    
		char **row; 
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		uint32 last_boxid = 0;
		while ((row = pDb->GetRow()) != NULL) 
		{    
			FestivalRandomBoxCfg temp; 
			uint32 id = (uint32)atoi(row[0]);
			temp.box_id = (uint32)atoi(row[1]); 
			temp.item_id = (uint32)atoi(row[2]); 
			temp.odds = (uint32)atoi(row[3]); 
			temp.num = (uint32)atoi(row[4]); 
			temp.quality = (uint32)atoi(row[5]); 
			temp.quality_level = (uint32)atoi(row[6]); 
			temp.notice = (uint32)atoi(row[7]); 
			temp.day_limit = (uint32)atoi(row[8]); 
			randombox_cfg.insert(std::make_pair(id,temp));
			if( last_boxid != temp.box_id )
			{
				last_boxid = temp.box_id;
				boxIdVec.push_back( temp.box_id );
			}
		}//end of while 
		return true;
	}//end of if 
	return false;
}
bool CFestivalRandomBoxManager::UseBox( CUser *pUser,uint32 item_id, uint8 pos, int num )
{
	if( NULL == pUser )
		return false;
#ifdef KUA_FU
	SendInfoToMe(pUser,TIPS_FAILURE_COLOR,LANGUAGE_CHY_106);
	return false;
#endif
	SItemInstance *pItem = pUser->GetItem(pos);
	if(  NULL == pItem || pItem->num < num || num > 200 )
		return false;
	pUser->DelPackage(pos,num);
	
	std::vector<FestivalRandomBoxAward> award_vec;
	award_vec.clear();
	for(int counter= 0; counter<num; ++counter)
	{
		DoOnceRandom( item_id , award_vec);	
	}

	if( !award_vec.empty() )
	{
		AddAllAward(pUser,item_id,award_vec);
	}
	return true;
}

bool CFestivalRandomBoxManager::isFestivalRandomBox( uint32 item_id )
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);

	std::vector<uint32>::iterator vec_iter = std::find( boxIdVec.begin(),boxIdVec.end(),item_id);
	if( boxIdVec.end() != vec_iter )
	{
		return true;
	}
	return false;
}

void CFestivalRandomBoxManager::DoOnceRandom( uint32 box_id , FestivalAwardVec &award_vec)//进行一次随机返回key)
{
	uint32 ret = 0;
	uint32 oddsRanmdom = Random(1,100000);
	uint32 oddsSum = 0;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	std::map<uint32,FestivalRandomBoxCfg>::iterator map_iter = randombox_cfg.begin();
	for(; map_iter  != randombox_cfg.end() ;++map_iter)
	{
		if( map_iter->second.box_id == box_id )
		{
			if(!ret)
			{
				ret = map_iter->first;
			}
			oddsSum += map_iter->second.odds;
			if( oddsSum >= oddsRanmdom )
			{
				if(map_iter->second.day_limit)
				{
					std::map<uint32,uint32>::iterator limit_iter = limitSaveMap.find(map_iter->first);
					if( limit_iter != limitSaveMap.end() )
					{
						if( map_iter->second.day_limit <= limit_iter->second )
						{
							continue;
						}
						else
						{
							limit_iter->second = limit_iter->second  + 1;
						}
					}
					else
					{
						limitSaveMap.insert(std::make_pair(map_iter->first,1));
					}
					ret = map_iter->first;
					break;
				}
				else
				{
					ret = map_iter->first;
					break;
				}
			}
		}
	}//end of for

	if( 0 != ret )
	{
		map_iter = randombox_cfg.find(ret);
		if( randombox_cfg.end() != map_iter )
		{
			bool isIn = false;
			std::vector<FestivalRandomBoxAward>::iterator vec_iter = award_vec.begin();
			for( ; vec_iter != award_vec.end(); ++vec_iter )
			{
				if( vec_iter->item_id != HDAT_PET && vec_iter->item_id == map_iter->second.item_id )
				{
					vec_iter->num +=  map_iter->second.num;
					isIn = true;
				}
			}//end of for
			if( !isIn)
			{
				FestivalRandomBoxAward info;
				info.id = map_iter->first;
				info.item_id = map_iter->second.item_id;
				info.num = map_iter->second.num;
				info.quality = map_iter->second.quality;
				info.quality_level = map_iter->second.quality_level;
				info.notice = map_iter->second.notice;
				award_vec.push_back(info);
			}
		}

	}//end of if
}

void CFestivalRandomBoxManager::AddAllAward(CUser *pUser,uint32 item_id ,FestivalAwardVec &award_vec)
{
	if( NULL == pUser)
		return;
	char buf[256];
	std::vector<FestivalRandomBoxAward>::iterator vec_iter = award_vec.begin();
	for( ; vec_iter != award_vec.end(); ++vec_iter )
	{
		bool isShow = vec_iter->notice?true:false;
		AddBoxAward( pUser,item_id,vec_iter->item_id,vec_iter->num,vec_iter->quality,vec_iter->quality_level,isShow);
		snprintf(buf,sizeof(buf),"%u*%u,%u,%u",vec_iter->item_id,vec_iter->num,vec_iter->quality,vec_iter->quality_level);
		SaveDate(pUser,717,item_id,buf);
	}//end of for
}

////////////////////////////////CFestivalRandomBoxManager END//////////////////////////////////

///////////////////////////////CXianYuanManager START//////////////////////////////////////////
CXianYuanManager::CXianYuanManager()
{
	totalOdds = 0;
	totalTenOdds = 0;
	memset(display_card,0,sizeof(display_card));	
	cardMap.clear();
	chapterMap.clear();
}
bool CXianYuanManager::Init()
{
	if(!LoadXianYuanCardDB())
		return false;
	if(!LoadXianYuanChapterDB())
		return false;
	if(!InitDisPlayCard())
		return false;
	return true;
}
bool CXianYuanManager::LoadXianYuanCardDB()
{
	totalOdds = 0;
	totalTenOdds = 0;
	cardMap.clear();

	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
										//0   1			2       3		  4			5			6		7
	if ((pDb != NULL) && (pDb->Query("select id,name,quality,xy_value,single_odds,ten_odds,isnotice,item_id from xianyuan_card order by id asc")))
	{    
		char **row; 
		while ((row = pDb->GetRow()) != NULL) 
		{    
			XianYuanCardInfo temp; 
			temp.card_id = atoi(row[0]);
			temp.name = row[1];
			temp.quality = atoi(row[2]);
			temp.xy_value = atoi(row[3]); 
			temp.single_odds = atoi(row[4]);
			temp.ten_odds = atoi(row[5]); 
			temp.isNotice = atoi(row[6]);
			temp.item_id = atoi(row[7]);
			cardMap.insert(std::make_pair(temp.card_id,temp));
			totalOdds += temp.single_odds;
			totalTenOdds += temp.ten_odds;
		}//end of while 
		return true;
	}//end of if
	return false;
}
bool CXianYuanManager::LoadXianYuanChapterDB()
{
	chapterMap.clear();
	
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
										//	  0   1				2		 3		  4			5			6			7		8			9			10			11
//      12			13	  
	if ((pDb != NULL) && (pDb->Query("select id,need_card1,need_card2,need_card3,need_card4,need_card5,attr_type1,attr_value1,attr_type2,attr_value2,attr_type3,attr_value3,attr_type4,attr_value4 from xianyuan_chapter order by id asc")))
	{    
		char **row; 
		while ((row = pDb->GetRow()) != NULL) 
		{    
			XianYuanChapterInfo temp; 
			temp.chapter_id = atoi(row[0]);
			temp.need_card1 = atoi(row[1]);
			temp.need_card2 = atoi(row[2]);
			temp.need_card3 = atoi(row[3]);
			temp.need_card4 = atoi(row[4]);
			temp.need_card5 = atoi(row[5]);
			temp.attr_type1 = atoi(row[6]);
			temp.attr_value1 = atoi(row[7]);
			temp.attr_type2 = atoi(row[8]);
			temp.attr_value2 = atoi(row[9]);
			temp.attr_type3 = atoi(row[10]);
			temp.attr_value3 = atoi(row[11]);
			temp.attr_type4 = atoi(row[12]);
			temp.attr_value4 = atoi(row[13]);
			chapterMap.insert(std::make_pair(temp.chapter_id,temp));
		}//end of while 
		return true;
	}//end of if 
	return false;
}
bool CXianYuanManager::GetXianYuanCardInfoByID(uint32 card_id,XianYuanCardInfo &info)
{
	CardMapIter map_iter = cardMap.find( card_id );
	if( cardMap.end() != map_iter )
	{
		info.card_id = map_iter->second.card_id;
		info.name = map_iter->second.name;
		info.quality = map_iter->second.quality;
		info.xy_value = map_iter->second.xy_value;
		info.single_odds = map_iter->second.single_odds;
		info.ten_odds = map_iter->second.ten_odds;
		info.isNotice = map_iter->second.isNotice;
		return true;
	}
	return false;
}
bool CXianYuanManager::GetXianYuanChapterInfoByID(uint32 chapter_id,XianYuanChapterInfo &info)
{
	ChapterMapIter map_iter = chapterMap.find(chapter_id);
	if( chapterMap.end() != map_iter )
	{
		info.chapter_id = map_iter->second.chapter_id; 
		info.need_card1 = map_iter->second.need_card1; 
		info.need_card2 = map_iter->second.need_card2; 
		info.need_card3 = map_iter->second.need_card3; 
		info.need_card4 = map_iter->second.need_card4; 
		info.need_card5 = map_iter->second.need_card5; 
		info.attr_type1 = map_iter->second.attr_type1; 
		info.attr_value1 = map_iter->second.attr_value1; 
		info.attr_type2 = map_iter->second.attr_type2; 
		info.attr_value2 = map_iter->second.attr_value2; 
		info.attr_type3 = map_iter->second.attr_type3; 
		info.attr_value3 = map_iter->second.attr_value3;
		info.attr_type4 = map_iter->second.attr_type4;
		info.attr_value4 = map_iter->second.attr_value4;
			return true;
	}
	return false;
}
bool CXianYuanManager::DoCardRandom(CUser *pUser,uint32 &card_id,uint8 type ,uint32 &quality)
{
	if( NULL == pUser)
		return false;
	int sumOdds = 0;
	int random = Random(1,totalOdds);
	CardMapIter map_iter = cardMap.begin();
	for( ; cardMap.end() != map_iter; ++map_iter )
	{
		if( map_iter->second.single_odds != 0 )
		{
			sumOdds += map_iter->second.single_odds;
			if( sumOdds >= random )
			{
				card_id = map_iter->second.card_id;
				if( map_iter->second.isNotice)
				{
					char buf[256];
					quality = map_iter->second.quality;
					int qualityColor = GetXianYuanCardQualityColor( quality );
					if( 1 == type )
					{
						snprintf(buf,sizeof(buf),LANGUAGE_CHY_29,ROLE_NAME_COLOR,pUser->GetName(),qualityColor,map_iter->second.name.c_str());
					}
					else if ( 2 == type )
					{
						snprintf(buf,sizeof(buf),LANGUAGE_CHY_30,ROLE_NAME_COLOR,pUser->GetName(),qualityColor,map_iter->second.name.c_str());
					}
					SysInfoToAllUser(buf);
				}
				return true;
			}
		}
	}//end of for
	return false;
	
}
bool CXianYuanManager::DoTenCardRandom(CUser *pUser,std::vector<uint32> &card_map)
{
	if( NULL == pUser)
		return false;
	card_map.clear();
	int sumOdds = 0;
	int random = 0;
	bool isGetSpecialCard = false;	//得到紫卡橙卡标志
	bool isGetOrangeCard = false;
	pUser->SetExtData8(468,pUser->GetExtData8(468)+1);
	for( int counter = 0; counter<8 ; ++counter )
	{
		uint32 card_id = 0;
		uint32 quality  = 0;
		if( DoCardRandom( pUser,card_id,2,quality))
		{
			card_map.push_back(card_id);
			if( quality >=3 )
				isGetSpecialCard = true;
			if( quality == 4 )
				isGetOrangeCard = true;
		}
	}//end of for

	//第九次---累计10次十连抽必出橙卡
	if( pUser->GetExtData8(468) >= 10 && !isGetOrangeCard )
	{
		uint32 orange_card_id = GetRandomCardByQuality(4);

		card_map.push_back(orange_card_id);
		XianYuanCardInfo info;
		if(GetXianYuanCardInfoByID( orange_card_id ,info))
		{
			char buf[256];
			int qualityColor = GetXianYuanCardQualityColor( info.quality);
			snprintf(buf,sizeof(buf),LANGUAGE_CHY_30,ROLE_NAME_COLOR,pUser->GetName(),qualityColor,info.name.c_str());
			SysInfoToAllUser(buf);
		}
		pUser->SetExtData8(468,0);
	}
	else
	{
		uint32 card_id = 0;
		uint32 quality  = 0;
		if( DoCardRandom( pUser,card_id,2,quality))
		{
			card_map.push_back(card_id);
			if( quality >=3 )
				isGetSpecialCard = true;
		}
	}

	if( !isGetSpecialCard )//前9次没抽到紫橙卡
	{
		sumOdds = 0;
		random = Random(1,totalTenOdds);
		CardMapIter map_iter = cardMap.begin();
		for( ; cardMap.end() != map_iter; ++map_iter )
		{
			if( map_iter->second.ten_odds != 0 )
			{
				sumOdds += map_iter->second.ten_odds;
				if( sumOdds >= random )
				{
					card_map.push_back(map_iter->second.card_id);
					if( map_iter->second.isNotice)
					{
						char buf[256];
						int qualityColor = GetXianYuanCardQualityColor( map_iter->second.quality);
						snprintf(buf,sizeof(buf),LANGUAGE_CHY_30,ROLE_NAME_COLOR,pUser->GetName(),qualityColor,map_iter->second.name.c_str());
						SysInfoToAllUser(buf);
					}
					break;
				}
			}
		}//end of for
	}
	else
	{
		uint32 card_id = 0;
		uint32 quality  = 0;
		if( DoCardRandom( pUser,card_id,2,quality))
		{
			card_map.push_back(card_id);
		}
	}
	return true;
}
int CXianYuanManager::GetXianYuanCardQualityColor( uint32 quality)
{
	int color = GGCT_WHITE;
	switch( quality)
	{
		case 1://绿
			{
				color = GGCT_GREEN;
			}
			break;
		case 2://蓝
			{
				color = GGCT_BLUE;
			}
			break;
		case 3://紫
			{
				color = GGCT_PURPLE;
			}
			break;
		case 4://橙
			{
				color = GGCT_ORANGE;
			}
		default:break;
	}
	return color;
}

void CXianYuanManager::MakeDisPlayCardMsg( CNetMessage &msg)
{
	int num = sizeof(display_card)/sizeof(display_card[0]);
	for(int counter =0 ;counter<num; ++counter)
	{
		msg<<display_card[counter];
	}
}

uint32 CXianYuanManager::GetRandomCardByQuality( uint32 quality)
{
	uint32 card_id = 0;
	int seq = 1;
	std::map<int,uint32> tempMap;
	tempMap.clear();
	CardMapIter map_iter = cardMap.begin();
	for( ; cardMap.end() != map_iter; ++map_iter )
	{
			if( map_iter->second.quality == quality )
			{
				tempMap.insert(std::make_pair(seq,map_iter->second.card_id));
				++seq;
			}
	}//end of for
	int card_seq = Random(1,tempMap.size());
	card_id = tempMap[card_seq];
	return card_id;
}

bool CXianYuanManager::InitDisPlayCard()
{
	display_card[0] = GetRandomCardByQuality(1);
	display_card[1] = GetRandomCardByQuality(2);
	display_card[2] = GetRandomCardByQuality(3);
	display_card[3] = GetRandomCardByQuality(2);
	display_card[4] = GetRandomCardByQuality(3);
	display_card[5] = GetRandomCardByQuality(4);
	return true;
}
void CXianYuanManager::TimeOut()
{
	//每周刷新一次
	if(GetSysWDay() == 0)
		InitDisPlayCard();
}

bool CXianYuanManager::isCardItemID( uint32 id)
{
	CardMapIter map_iter = cardMap.begin();
	for( ; cardMap.end() != map_iter; ++map_iter )
	{
		if( map_iter->second.item_id == id )
		{
			return true;
		}
	}//end of for
	return false;
}
bool CXianYuanManager::XianYuanItemToCard( CUser *pUser,uint32 item_id ,uint8 pos,int num)
{
	if( NULL == pUser || 0 == num )
		return false;
	CardMapIter map_iter = cardMap.begin();
	for( ; cardMap.end() != map_iter; ++map_iter )
	{
			if( map_iter->second.item_id == item_id )
			{
				SItemInstance* pItem=pUser->GetItem(pos);
				if( pItem && pItem->num >= num)
				{
					pUser->DelPackage(pos,num);
					pUser->AddXianYuanCard( map_iter->second.card_id ,num);
					SendInfoToMe(pUser,TIPS_WARNING_COLOR,LANGUAGE_CHY_31,map_iter->second.name.c_str(),num);
					return true;
				}
				else
				{
					return false;
				}
			}
	}//end of for
	return false;
}
///////////////////////////////CXianYuanManager END//////////////////////////////////////////

//////////////////////////////////CKuaFu1vs1PreliminaryManager START/////////////////////////////////////
#ifdef KUA_FU
CKuaFu1vs1PreliminaryManager::CKuaFu1vs1PreliminaryManager()
{
	for( int counter = 0;counter<SORT_MAX_NUM;++counter)
		sortlist[counter].clear();
	last_rewad_day = 0 ;
	last_rearrange_day = 0;
	day_save = 0;
}
bool CKuaFu1vs1PreliminaryManager::LoadDB()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	//                                   0    1     2     3    4    5   6   7      8        9      10         11        12       13
	if ((pDb != NULL) && (pDb->Query("select id,sort_id,role_id,score,name,level,xiang,sex,super_level,wing_id,weapon_id,weapon_level,zhandouli,server_id from kuafu_1vs1_preliminary order by sort_id asc")))
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		for( int counter = 0;counter<SORT_MAX_NUM;++counter)
			sortlist[counter].clear();

		char **row; 
		while ((row = pDb->GetRow()) != NULL)
		{
			int sort_id = atoi(row[1]);
			if(sort_id >= 1 && sort_id <= SORT_MAX_NUM )
			{
				StKuaFu1Vs1SortKey key;
				key.score = atoi(row[3]);
				key.zhandouli = atoi(row[12]);
				key.role_id = atoi(row[2]);

				StKuaFu1Vs1SortUserInfo info;
				info.role_id = key.role_id;
				info.name = row[4];
				info.level = atoi(row[5]);
				info.xiang = atoi(row[6]);
				info.sex = atoi(row[7]);
				info.super_level = atoi(row[8]);
				info.wing_id = atoi(row[9]);
				info.weapon_id = atoi(row[10]);
				info.weapon_level = atoi(row[11]);
				info.zhandouli = key.zhandouli;
				info.server_id = atoi(row[13]);
				
				sortlist[sort_id-1].insert(std::make_pair(key,info));
			}
		}//end of while
		return true;
	}
	return false;
}
void CKuaFu1vs1PreliminaryManager::SaveDB()
{
	CGetDbConnect getDb; 
	CDatabaseSql *pDb = getDb.GetDbConnect(); 
	char sql[1024]; 
	if(pDb == NULL) 
	{ 
		cout<<LANGUAGE_TRANSFORM_140<<endl; 
		return; 
	} 
	pDb->Query("truncate table kuafu_1vs1_preliminary"); 
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for( int sort_id = 0; sort_id < SORT_MAX_NUM; ++sort_id )	
	{
		SortIter map_iter = sortlist[sort_id].begin();
		for( ; map_iter!= sortlist[sort_id].end(); ++map_iter)
		{ 
			snprintf(sql,sizeof(sql),"insert into kuafu_1vs1_preliminary (sort_id,role_id,score,name,level,xiang,sex,super_level,wing_id,weapon_id,weapon_level,zhandouli,server_id) "\
				"values(%d,%d,%d,'%s',%d,%d,%d,%d,%d,%d,%d,%d,%d)",
				sort_id+1,map_iter->first.role_id,map_iter->first.score,map_iter->second.name.c_str(),map_iter->second.level,map_iter->second.xiang,map_iter->second.sex,map_iter->second.super_level,map_iter->second.wing_id,map_iter->second.weapon_id,map_iter->second.weapon_level,map_iter->second.zhandouli,map_iter->second.server_id); 
			if(!pDb->Query(sql))
				cout<<LANGUAGE_TRANSFORM_141<<sql<<endl; 
		}//end of for
	}//end of for sort_id
}
void CKuaFu1vs1PreliminaryManager::SaveDBByLong()
{
	char sql[1024];
	SendLongQuerySql("truncate table kuafu_1vs1_preliminary");
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for( int sort_id = 0; sort_id < SORT_MAX_NUM; ++sort_id )	
	{
		SortIter map_iter = sortlist[sort_id].begin();
		for( ; map_iter!= sortlist[sort_id].end(); ++map_iter)
		{ 
			snprintf(sql,sizeof(sql),"insert into kuafu_1vs1_preliminary (sort_id,role_id,score,name,level,xiang,sex,super_level,wing_id,weapon_id,weapon_level,zhandouli,server_id) values(%d,%d,%d,'%s',%d,%d,%d,%d,%d,%d,%d,%d,%d)",sort_id+1,map_iter->first.role_id,map_iter->first.score,map_iter->second.name.c_str(),map_iter->second.level,map_iter->second.xiang,map_iter->second.sex,map_iter->second.super_level,map_iter->second.wing_id,map_iter->second.weapon_id,map_iter->second.weapon_level,map_iter->second.zhandouli,map_iter->second.server_id); 
		SendLongQuerySql(sql);
		}//end of for
	}//end of for sort_id

}
void CKuaFu1vs1PreliminaryManager::SendSingleSortInfo(CUser* pUser ,int sort_id)
{
	if(!pUser || sort_id < 1 || sort_id >SORT_MAX_NUM)
		return;
	CNetMessage msg;
	msg.SetType(MSG_KUA_FU_1V1);
	msg<<(uint8)3<<sort_id;
	--sort_id;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		msg<<(int)sortlist[sort_id].size();
		SortIter map_iter = sortlist[sort_id].begin();
		int counter = 1;
		for( ; map_iter!= sortlist[sort_id].end(); ++map_iter)
		{
			msg<<counter<<map_iter->second.name<<map_iter->first.score;
			++counter;
		}//end of for
	}
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

int CKuaFu1vs1PreliminaryManager::SearchUserSortID(CUser* pUser,SortIter *it)
{
	if(!pUser)
		return 0; 
	int role_id = pUser->GetRoleId();
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(int counter = 0; counter < SORT_MAX_NUM ;++counter)
	{
		SortIter map_iter = sortlist[counter].begin();
		for( ; map_iter!= sortlist[counter].end(); ++map_iter)
		{
			if(map_iter->first.role_id == role_id)
			{
				if(it != NULL)
					*it = map_iter;
				return counter+1;
			}
		}
	}
	return 0;
}

int CKuaFu1vs1PreliminaryManager::SearchUserRankFromSort(CUser* pUser)
{
	if(!pUser || 0 == pUser->GetKuaFu1vs1PreliminarySortID())
		return 0;
	int rank = 0; 
	int sort_id = pUser->GetKuaFu1vs1PreliminarySortID();
	--sort_id;
	int role_id = pUser->GetRoleId();
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		SortIter map_iter = sortlist[sort_id].begin();
		int counter = 0;
		for( ; map_iter!= sortlist[sort_id].end(); ++map_iter)
		{
			++counter;
			if( map_iter->first.role_id == role_id )
			{
				rank = counter;
				break;
			}
		}//end of for
	}
	return rank;
}
bool CKuaFu1vs1PreliminaryManager::IsInKuaFu1vs1PreliminaryTime()
{
	int curDay = GetWeekDay();
	if( curDay == 0 )
		return false;
	return true;
}
int CKuaFu1vs1PreliminaryManager::MakeUserRankScoreInfo(CUser* pUser,CNetMessage &msg)
{
	if(!pUser || 0 == pUser->GetKuaFu1vs1PreliminarySortID())
		return 0;
	int role_id = pUser->GetRoleId();
	int sort_id = pUser->GetKuaFu1vs1PreliminarySortID();
	if( sort_id >= 1 && sort_id <= SORT_MAX_NUM)
	{
		sort_id--;
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		SortIter map_iter = sortlist[sort_id].begin();
		int counter = 0;
		for( ; map_iter!= sortlist[sort_id].end(); ++map_iter)
		{
			++counter;
			if( map_iter->first.role_id == role_id )
			{
				msg<<map_iter->first.score;
				msg<<counter;
				return counter;
			}
		}//end of for

	}//end of if
	pUser->SetKuaFu1vs1PreliminarySortID(0);
	return 0;
}

void CKuaFu1vs1PreliminaryManager::MakeRankRewardInfo(int rank ,CNetMessage &msg)
{
	vector<SAwardData> award;
	int index = sAwardManager.GetRankAward(EMRA_KF_1V1_Preliminary,rank,award);
	if(index <= 0)
	{
		msg<<0<<"";
	}
	else
	{
		string str = GetAwardsString(award);

		typeRankRewards* rewards = sAwardManager.GetAllRankAwards(EMRA_KF_1V1_Preliminary);
		if (rewards == NULL || rewards->ranks.size() != rewards->rewards.size() || rewards->ranks.size() < 5)
		{
			msg<<0<<"";
			return;
		}

		char buf[512];
		if(index == 1)
			snprintf(buf,sizeof(buf),LANGUAGE_CHY_64,rewards->ranks[index-1].first,rewards->ranks[index-1].second,str.c_str());
		else if(index == 2)
			snprintf(buf,sizeof(buf),LANGUAGE_CHY_65,rewards->ranks[index-1].first,rewards->ranks[index-1].second,str.c_str(),rewards->ranks[index-2].first,rewards->ranks[index-2].second);
		else if(index == 3)
			snprintf(buf,sizeof(buf),LANGUAGE_CHY_66,rewards->ranks[index-1].first,rewards->ranks[index-1].second,str.c_str(),rewards->ranks[index-2].first,rewards->ranks[index-2].second);
		else if(index == 4)
			snprintf(buf,sizeof(buf),LANGUAGE_CHY_67,rewards->ranks[index-1].first,rewards->ranks[index-1].second,str.c_str(),rewards->ranks[index-2].first,rewards->ranks[index-2].second);
		else if(index == 5)
			snprintf(buf,sizeof(buf),LANGUAGE_CHY_68,rewards->ranks[index-1].first,str.c_str(),rewards->ranks[index-2].first,rewards->ranks[index-2].second);
		else
		{
			msg<<0<<"";
			return;
		}
		msg<<index<<buf;
	}
}

void CKuaFu1vs1PreliminaryManager::SendKuaFu1vs1PreliminaryPanelInfo(CUser* pUser)
{
    if(pUser== NULL ||0 == pUser->GetKuaFu1vs1PreliminarySortID())
		return;
	
	CNetMessage msg;
	msg.SetType(MSG_KUA_FU_1V1);
	msg<<(uint8)8<<pUser->GetKuaFu1vs1PreliminarySortID();
	int rank = 0;
	rank = MakeUserRankScoreInfo(pUser,msg);
	if(!rank)
		return;
	MakeRankRewardInfo(rank ,msg);
	uint8 refresh_hero = 0;
	if(pUser->GetKuaFu1vs1PreliminaryRefreshHeroNum())
		refresh_hero = 1;
	msg<<refresh_hero;
	msg<<(int)(MAX_CHALLENGUE_NUM - pUser->GetKuaFu1vs1PreliminaryUsedChallengueNum())<<MAX_CHALLENGUE_NUM;
	msg<<GetAddChallengeNumSpendYB( pUser->GetKuaFu1vs1PreliminaryUsedChallengueTotalNum());
	int cd_time = 0;
	if(GetSysTime() < pUser->GetKuaFu1vs1PreliminaryChallengueCDTime())
	{
		cd_time = (int)(pUser->GetKuaFu1vs1PreliminaryChallengueCDTime() - GetSysTime());
	}
	msg<<cd_time;
	pUser->MakeKuaFu1vs1SaveEnemyInfo(msg);
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}
void CKuaFu1vs1PreliminaryManager::ApplyForKuaFu1vs1Preliminary(CUser* pUser)
{
	if(pUser == NULL)
		return;
	int sort_id = SearchUserSortID(pUser);
	if(sort_id > 0)
		return;
	
	int zhandouli = pUser->GetZhanDouLi();
	sort_id = GetLeastKuaFu1vs1PreliminarySortID();
	StKuaFu1Vs1SortKey key;
	key.score = 0;
	key.zhandouli = zhandouli;
	key.role_id = pUser->GetRoleId();
	
	StKuaFu1Vs1SortUserInfo info;
	info.role_id = pUser->GetRoleId();
	info.name = pUser->GetName();
	info.level = pUser->GetLevel();
	info.sex = pUser->GetSex();
	info.super_level = (int)pUser->GetVipLevel();
	info.zhandouli = zhandouli;
	info.server_id = pUser->GetServerId();

	if(sort_id >= 1 || sort_id <= SORT_MAX_NUM)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		sortlist[sort_id-1].insert(std::make_pair(key,info));
	}
	else
	{
		return;
	}
	pUser->SetKuaFu1vs1PreliminarySortID(sort_id);
	//分配5个敌人
	ChooseFiveEnemyFromSort(pUser);
	SendKuaFu1vs1PreliminaryPanelInfo(pUser);
}
void CKuaFu1vs1PreliminaryManager::HandleKuaFu1vs1PreliminaryReq( CUser* pUser )
{
	if(pUser == NULL)
		return;
	if(pUser->GetKuaFu1vs1PreliminarySortID() == 0)
	{
		SortIter it = sortlist[0].end();
		int sort_id = SearchUserSortID(pUser,&it);
		if(sort_id == 0)
		{
			CNetMessage msg;
			msg.SetType(MSG_KUA_FU_1V1);
			msg<<(uint8)2;
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}
		else
		{
			int zhandouli = pUser->GetZhanDouLi();
			if(it == sortlist[0].end())
				return;
			{
				boost::recursive_mutex::scoped_lock lk(m_mutex);
				if(it->first.zhandouli != zhandouli)
				{
					StKuaFu1Vs1SortKey key;
					StKuaFu1Vs1SortUserInfo info;
					key = it->first;
					info = it->second;
					key.zhandouli = zhandouli;
					info.zhandouli = zhandouli;
					sortlist[sort_id-1].erase(it);
					sortlist[sort_id-1].insert(std::make_pair(key,info));
				}
			}

			pUser->SetKuaFu1vs1PreliminarySortID(sort_id);
			ChooseFiveEnemyFromSort(pUser);//每周一重新分组后第一次点开界面需要重新分配敌人
		}
	}
	SendKuaFu1vs1PreliminaryPanelInfo(pUser);
}
int CKuaFu1vs1PreliminaryManager::GetLeastKuaFu1vs1PreliminarySortID()
{
	int sort_id = 1;
	int sort_num = sortlist[0].size();
	for( int counter = 1 ; counter < SORT_MAX_NUM ; ++counter )
	{
		if( (int)sortlist[counter].size() < sort_num )
		{
			sort_id = counter + 1;
			sort_num = sortlist[counter].size();
		}
	}//end of for
	return sort_id;
}

bool CKuaFu1vs1PreliminaryManager::ChooseFiveEnemyFromSort( CUser* pUser)
{
	if(!pUser || 0 == pUser->GetKuaFu1vs1PreliminarySortID())
		return false;
	int sort_id = pUser->GetKuaFu1vs1PreliminarySortID();
	if(sort_id < 1 || sort_id > SORT_MAX_NUM)
		return false;
	int rank = SearchUserRankFromSort(pUser);
	int max_num = sortlist[sort_id-1].size(); 
	StKuaFu1vs1SelectEnemySeq enemy[5];
	ChooseOneDifficultyEnemy( rank ,max_num,pUser->GetZhanDouLi(),enemy);
	ChooseTwoNormalEnemy( rank ,max_num,pUser->GetZhanDouLi(),enemy);
	ChooseTwoSimpleEnemy( rank ,max_num,pUser->GetZhanDouLi(),enemy);
	FillUserEnemyInfo(pUser,sort_id , enemy);
	FillRobotEnemyInfo(pUser,enemy);
	for( int pos = 1;pos <= 5;++pos )
	{
		pUser->kuaFu1vs1SaveEnemyInfo[pos-1].score = GetEnemyScoreReward(pos,true);
	}
	return true;
}

bool CKuaFu1vs1PreliminaryManager::ChooseOneDifficultyEnemy(int rank ,int maxNum ,int zhandouli,StKuaFu1vs1SelectEnemySeq *info)
{
	//////////////////////////////////////////////////////////////////////////////////////////
	//困难抽取
	//{
	//	if (X ≤ a * Y )
	//	{
	//		if (X > 1)	在(1--【X-1】)范围内查找1个，找足就返回；
	//
	//		if (X = 1) 在【X+1】--Y范围内查找1个，找足就返回；
	//
	//			不足1个则添加1个机器人。
	//	}
	//	else if(a*Y＜X＜=Y) 
	//	{
	//	在1--【X-a*Y】范围内查找1个，找足就返回，不足或范围不成立就继续往下运行；
	//	添加1个机器人。
	//	}
	//}
	/////////////////////////////////////////////////////////////////////////////
	if( !info || !rank || !maxNum)
		return false;
	int percentage = GetChooseRangeRandomPercentage(maxNum);
	int range = (int)(percentage/100.0*maxNum );
	int min_rank = 0;
	int max_rank = 0;
	bool isRobot = false;
	if( rank <= range )
	{
		if( 1 == rank )
		{
			if( 1 == maxNum )
				isRobot = true;
			else
			{
				min_rank = 2;
				max_rank = 2;
			}
		}
		else  //rank > 1
		{
			min_rank = 1;
			max_rank = rank-1;
		}
	}
	else
	{
		min_rank = 1;
		max_rank = rank - range;
	}

	if( isRobot )
	{
		int percent= Random(190,210);
		info[0].rank = GetKuaFu1vs1RobotByZhandouli((int)(zhandouli*percent/100.0)); 
		info[0].kind  = 1; 
	}
	else
	{
		info[0].rank = Random(min_rank,max_rank); 
		info[0].kind  = 0; 
	}
	//cout<<"困难抽取 1:kind="<<info[0].kind<<"rank="<<info[0].rank<<endl;
	return true;
}

bool CKuaFu1vs1PreliminaryManager::ChooseTwoNormalEnemy(int rank ,int maxNum ,int zhandouli,StKuaFu1vs1SelectEnemySeq *info)
{
	////////////////////////////////////////////////////////////////////////////////////
	//普通抽取
	//{
	//	if (X ≤ a * Y )
	//	{
	//		if（x+2y）机器人
	//			在【X+1】--【X+a*Y】范围内查找2个，找到就返回，不足或范围不成立就继续往下运行；
    //
    //			在【X+a*Y】（不包含）--Y范围内查找2个，找到就返回，不足或范围不成立就继续往下运行；
    //
	//			添加机器人。
	//	}
	//	else if(a*Y＜X＜=Y) 
	//	{
	//		在【X-a*Y】（不包含）--【X+a*Y】范围内查找2个，找足就返回，不足或范围不成立就继续往下运行；
    //
	//			在【X+a*Y】（不包含）--Y范围内查找2个，找到就返回，不足或范围不成立就继续往下运行；
	//
	//			添加机器人。
	//	}
	//}
	////////////////////////////////////////////////////////////////////////////////////
	if( !info || !rank || !maxNum )
		return false;
	int percentage = GetChooseRangeRandomPercentage(maxNum);
	int range = (int)(percentage/100.0*maxNum );
	int min_rank = 0;
	int max_rank = 0;
	bool isRobot1 = false;
	bool isRobot2 = false;
	if( rank <= range )
	{
		if( maxNum <= rank + 2 )
		{
			isRobot1 = true;
			isRobot2 = true;
		}
		else
		{
			if( rank ==1 )
			{
				min_rank = rank + 2;
				max_rank = rank + 3;
			}
			else
			{
				min_rank = rank + 1;
				max_rank =min(( rank + range-1),maxNum);
				if( min_rank>= max_rank)
					max_rank =  rank + range+1;

			}
		}
	}
	else // rank > range
	{
		if( maxNum <= rank + 2 )
		{
			isRobot1 = true;
			isRobot2 = true;
		}
		else
			
		if( rank+ range <= maxNum)
		{
			min_rank = rank - range+1;
			max_rank = rank + range;
			
		}
		else
		{
			min_rank = rank - range+1;
			max_rank = maxNum;
		}
	}
	if( isRobot1 )
	{
		int percent= Random(110,130);	
		info[1].rank = GetKuaFu1vs1RobotByZhandouli((int)(zhandouli*percent/100.0));
		info[1].kind  = 1; 
	}
	if( isRobot2 )
	{
		int percent= Random(110,130);
		info[2].rank = GetKuaFu1vs1RobotByZhandouli((int)(zhandouli*percent/100.0)); 
		info[2].kind  = 1; 
	}
	//cout<<"普通抽取"<<"min_rank="<<min_rank<<",max_rank="<<max_rank<<endl;
	if( min_rank && max_rank)
	{
		int findNum = 0;
		while( findNum <2 )
		{
			int findRank = Random(min_rank,max_rank);
			if( findRank == rank || IsChooseRepeatEnemy(findRank,info))
				continue;
			++findNum;
			info[findNum].rank = findRank; 
			info[findNum].kind  = 0; 
		}//end of while
	}//end of if
	//cout<<"普通抽取 2:kind="<<info[1].kind<<"rank="<<info[1].rank<<endl;
	//cout<<"普通抽取 3:kind="<<info[2].kind<<"rank="<<info[2].rank<<endl;
	return true;
}

bool CKuaFu1vs1PreliminaryManager::ChooseTwoSimpleEnemy(int rank ,int maxNum ,int zhandouli,StKuaFu1vs1SelectEnemySeq *info)
{
	/////////////////////////////////////////////////////////////////////////////////////
	//	简单抽取
	//	{
	//		if ()
	//		{
	//
	//			if ( ( X + a*Y )  <= Y)
	//
	//			{
	//				在【X+a*Y】（不包含）--Y范围内查找2个，找到就返回；
	//
	//					不足2人就添加机器人。
	//			}
	//
	//			else( Y <= (X+a*Y) )  找2个机器人;
	//
	//		}
	//	}
	//
	///////////////////////////////////////////////////////////////////////////////
	if( !info || !rank || !maxNum )
		return false;
	int percentage = GetChooseRangeRandomPercentage(maxNum);
	int range = (int)(percentage/100.0*maxNum );
	int min_rank = 0;
	int max_rank = 0;
	bool isRobot1 = false;
	bool isRobot2 = false;
	if( rank <= range )
	{
		if( maxNum <= rank+range+3)//rank + 4 )
		{
			isRobot1 = true;
			isRobot2 = true;
		}
		else
		{
			min_rank = rank+range+2;//rank +4;
			max_rank = maxNum;
		}
	}
	else //rank > range
	{
		if( maxNum <= rank+range + 3)
		{
			isRobot1 = true;
			isRobot2 = true;
		}
		else
		{
			min_rank = rank+range + 3;
			max_rank = maxNum;
		}
	}
	
	if( isRobot1 )
	{
		int percent= Random(60,80);
		info[3].rank = GetKuaFu1vs1RobotByZhandouli((int)(zhandouli*percent/100.0)); 
		info[3].kind  = 1; 
	}
	if( isRobot2 )
	{
		int percent= Random(60,80);
		info[4].rank = GetKuaFu1vs1RobotByZhandouli((int)(zhandouli*percent/100.0)); 
		info[4].kind  = 1; 
	}
	//cout<<"简单抽取"<<"min_rank="<<min_rank<<",max_rank="<<max_rank<<endl;
	if( min_rank && max_rank)
	{
		int findNum = 0;
		while( findNum <2 )
		{
			int findRank = Random(min_rank,max_rank);
			if( findRank == rank || IsChooseRepeatEnemy(findRank,info))
				continue;
			++findNum;
			info[findNum+2].rank = findRank; 
			info[findNum+2].kind  = 0; 
		}//end of while
	}//end of if
	//cout<<"简单抽取 4:kind="<<info[3].kind<<"rank="<<info[3].rank<<endl;
	//cout<<"简单抽取 5:kind="<<info[4].kind<<"rank="<<info[4].rank<<endl<<endl;;
	return true;

}
bool CKuaFu1vs1PreliminaryManager::IsChooseRepeatEnemy( int rank , StKuaFu1vs1SelectEnemySeq *info)
{
	if( !info )
		return true;
	for( int counter = 0; counter < 5 ;++counter )
	{
		if(  info[counter].kind == 0 && info[counter].rank == rank)
			return true;
	}
	return false;
}

int CKuaFu1vs1PreliminaryManager::GetChooseRangeRandomPercentage( int maxNum )
{
	int percentage = 0;
	if ( maxNum >= 100 )
	{
		percentage = 10;
	}
	else if ( maxNum>= 10 && maxNum  < 100)
	{
		percentage = 40;
	}
	else if( maxNum > 5 && maxNum  < 10 )
	{
		percentage = 50;
	}
	else if ( maxNum <= 5 )
	{
		percentage = 100;
	}
	return percentage;
}
bool CKuaFu1vs1PreliminaryManager::FillUserEnemyInfo(CUser* pUser,int sort_id, StKuaFu1vs1SelectEnemySeq *info)
{
	if( pUser == NULL ||info == NULL || sort_id < 1 || sort_id > SORT_MAX_NUM )
		return false;
	sort_id--;
	int max_rank = 0;
	for(int info_num = 0; info_num<5 ; ++info_num )
	{
		if(info[info_num].kind == 0 && info[info_num].rank > max_rank )
			max_rank = info[info_num].rank;
	}

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	SortIter map_iter = sortlist[sort_id].begin();
	int counter = 0;
	for( ; map_iter!= sortlist[sort_id].end(); ++map_iter)
	{
		++counter;
		
		for(int info_num = 0; info_num<5 ; ++info_num )
		{
			if(info[info_num].kind == 0 && info[info_num].isFind == false && info[info_num].rank == counter )
			{
				info[info_num].isFind = true;
				pUser->kuaFu1vs1SaveEnemyInfo[info_num].kind = info[info_num].kind; 
				pUser->kuaFu1vs1SaveEnemyInfo[info_num].role_id = map_iter->first.role_id;
				pUser->kuaFu1vs1SaveEnemyInfo[info_num].name = map_iter->second.name;
				pUser->kuaFu1vs1SaveEnemyInfo[info_num].level = map_iter->second.level;
				pUser->kuaFu1vs1SaveEnemyInfo[info_num].xiang = map_iter->second.xiang;
				pUser->kuaFu1vs1SaveEnemyInfo[info_num].sex = map_iter->second.sex; 
				pUser->kuaFu1vs1SaveEnemyInfo[info_num].super_level = map_iter->second.super_level;
				pUser->kuaFu1vs1SaveEnemyInfo[info_num].wing_id = map_iter->second.wing_id;
				pUser->kuaFu1vs1SaveEnemyInfo[info_num].weapon_id = map_iter->second.weapon_id; 
				pUser->kuaFu1vs1SaveEnemyInfo[info_num].weapon_level = map_iter->second.weapon_level;
				pUser->kuaFu1vs1SaveEnemyInfo[info_num].zhandouli = map_iter->first.zhandouli;
				pUser->kuaFu1vs1SaveEnemyInfo[info_num].score = 0;
				pUser->kuaFu1vs1SaveEnemyInfo[info_num].server_id = map_iter->second.server_id;
				break;
			}
		}
		if(counter == max_rank)
			break;
	}//end of for
	return true;
}
bool CKuaFu1vs1PreliminaryManager::FillRobotEnemyInfo(CUser* pUser,StKuaFu1vs1SelectEnemySeq *info)
{
	if( pUser == NULL ||info == NULL)
		return false;
	for(int info_num = 0; info_num < 5 ; ++info_num )
	{
		if(info[info_num].kind == 1 && info[info_num].isFind == false )
		{
			info[info_num].isFind = true;
			CopyKuaFu1vs1RobotInfo( info[info_num].rank,pUser->kuaFu1vs1SaveEnemyInfo[info_num]);
			pUser->kuaFu1vs1SaveEnemyInfo[info_num].server_id = pUser->GetServerId();
		}
	}
	return true;
}

void CKuaFu1vs1PreliminaryManager::SelectEnemyToFight(CUser* pUser,int enemy_seq)
{
	if(pUser == NULL || enemy_seq < 1 || enemy_seq > 5)
		return;
	if(pUser->HaveTeam())
	{
		SendInfoToMe(pUser,TIPS_FAILURE_COLOR,LANGUAGE_TRANSFORM_1396);
		return;
	}
	CScene *pScene = pUser->GetScene();
	//没CD
	if(pUser->GetKuaFu1vs1PreliminaryChallengueCDTime() > GetSysTime())
		return;
	//有次数
	if(pUser->GetKuaFu1vs1PreliminaryUsedChallengueNum() >= MAX_CHALLENGUE_NUM)
		return;
	if(0 == pUser->kuaFu1vs1SaveEnemyInfo[enemy_seq-1].role_id)
		return;
	if(pScene != NULL)// && pScene->GetId() == KUA_FU_SCENE_ID )
	{
		ShareUserPtr pEnemy;
		pEnemy = GetKuaFu1vs1EnemyInfo(pUser->kuaFu1vs1SaveEnemyInfo[enemy_seq-1]);

		if(pEnemy.get() == NULL)
			return;
		pUser->SetKuaFu1vs1PreliminaryFightEnemySeq( enemy_seq );
		pUser->SetKuaFu1vs1PreliminaryUsedChallengueNum(pUser->GetKuaFu1vs1PreliminaryUsedChallengueNum()+1);
		pScene->KuaFu1vs1PreliminaryFight(pUser->GetRoleId(),pEnemy);
	}
}
int CKuaFu1vs1PreliminaryManager::GetEnemyScoreReward( int pos,bool isWin)
{
	const int score_win[5]={500,300,300,100,100};
	int score = LOSE_SCORE;
	if( pos < 1 || pos > 5 )
	{
		return score;
	}
	if(isWin)
	{
		score = score_win[pos-1];	
	}
	return score;
}
void CKuaFu1vs1PreliminaryManager::AddUserScore( CUser* pUser,bool isWin)
{
	if(!pUser || 0 == pUser->GetKuaFu1vs1PreliminarySortID() || 0 == pUser->GetKuaFu1vs1PreliminaryFightEnemySeq())
		return ;
	int score = GetEnemyScoreReward(pUser->GetKuaFu1vs1PreliminaryFightEnemySeq(),isWin);
	int role_id = pUser->GetRoleId();
	int sort_id = pUser->GetKuaFu1vs1PreliminarySortID();
	if( sort_id >= 1 && sort_id <= SORT_MAX_NUM)
	{
		sort_id--;
		int counter = 0;
		StKuaFu1Vs1SortKey key;
		StKuaFu1Vs1SortUserInfo info;
		bool isFind = false;

		int zhandouli = pUser->GetZhanDouLi();
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		SortIter map_iter = sortlist[sort_id].begin();
		for( ; map_iter!= sortlist[sort_id].end(); ++map_iter)
		{
			++counter;
			if( map_iter->first.role_id == role_id )
			{
				key = map_iter->first;
				info = map_iter->second;
				
				key.score += score;
				key.role_id = pUser->GetRoleId();
				key.zhandouli = zhandouli;
				
				info.role_id = pUser->GetRoleId();
				info.name = pUser->GetName();
				info.level = pUser->GetLevel();
				info.sex = pUser->GetSex();
				info.super_level = pUser->GetVipLevel();
				info.zhandouli = zhandouli;
				info.server_id = pUser->GetServerId();

				sortlist[sort_id].erase(map_iter);
				isFind = true;
				break;
			}
		}//end of for
		if( isFind )
			sortlist[sort_id].insert(std::make_pair(key,info));
	}//end of if
	return;
}

int CKuaFu1vs1PreliminaryManager::GetRewardKind( int rank)
{
	int kind =0;
	if( rank >=1 && rank <= 4 )
	{
		kind  = 1;
	}
	else if( rank >= 5 && rank <= 50 )
	{
		kind = 2;
	}
	else if( rank >= 51 && rank <= 100 )
	{
		kind = 3;
	}
	else if( rank >= 101 && rank <= 200 )
	{
		kind = 4;
	}
	else if( rank > 200 )
	{
		kind = 5;
	}
	return kind;
}

void CKuaFu1vs1PreliminaryManager::RearrangeToRandomSort()
{	
	//////////////////////////////////////////////////////////
	//前32名随机分配到个8小组中，1~8 每组选4个
	//后面的人去人少的组
	//遍历原有组时，跳过积分为0的记录
	/////////////////////////////////////////////////////////
	vector<StKuaFu1Vs1SortUserInfo> finalUser,otherUser;
	finalUser.clear();
	otherUser.clear();
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	//转移老记录
	for( int sort_id = 0; sort_id < SORT_MAX_NUM; ++sort_id  )	
	{
		SortIter map_iter = sortlist[sort_id].begin();
		int rank = 0;
		for( ; map_iter!= sortlist[sort_id].end(); ++map_iter)
		{
			++rank;
			if( map_iter->first.score == 0)
				continue;
			if( rank >= 1 && rank <= 4 )
			{
				finalUser.push_back( map_iter->second);
			}
			else
			{
				otherUser.push_back( map_iter->second);
			}
		}//end of for
	}//end of for sort_id
	
	for( int sort_id = 0; sort_id < SORT_MAX_NUM; ++sort_id  )
	{
		sortlist[sort_id].clear();
	}//end of for
	
	//重新分组，先分配前32,
	int user_aver = (int)(finalUser.size()/8);
	int one_more = (int)(finalUser.size()%8);
	vector<StKuaFu1Vs1SortUserInfo>::iterator vec_iter = finalUser.begin();
	for( ; vec_iter != finalUser.end(); ++vec_iter)
	{
		while(1)
		{
			int sort_id = Random(1, SORT_MAX_NUM);
			int user_num = user_aver;
			if(sort_id <= one_more)
				++user_num;
			if((int)(sortlist[sort_id-1].size()) >= user_num)
			{
				continue;
			}
			else
			{
				StKuaFu1Vs1SortKey key;
				key.score= 0;
				key.zhandouli = vec_iter->zhandouli;
				key.role_id = vec_iter->role_id;
				sortlist[sort_id-1].insert(make_pair(key,*vec_iter));
				break;
			}
		}//end of while
	}//end of for

	vec_iter = otherUser.begin();
	for( ; vec_iter != otherUser.end(); ++vec_iter)
	{
		int sort_id = GetLeastKuaFu1vs1PreliminarySortID();
		StKuaFu1Vs1SortKey key;
		key.score= 0;
		key.zhandouli = vec_iter->zhandouli;
		key.role_id = vec_iter->role_id;
		sortlist[sort_id-1].insert(make_pair(key,*vec_iter));
	}
	
}

void CKuaFu1vs1PreliminaryManager::SendDayReward()
{
	char buf[256];
	AwardManager &awardMgr = SingletonAwardManager::instance();
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for( int sort_id = 0; sort_id < SORT_MAX_NUM; ++sort_id)
	{
		int rank = 0;
		for(SortIter map_iter = sortlist[sort_id].begin();map_iter != sortlist[sort_id].end(); ++map_iter)
		{
			++rank;
			StKuaFu1Vs1SortUserInfo &data = map_iter->second;
			snprintf(buf,sizeof(buf),LANGUAGE_CHY_63,rank);
			awardMgr.SendRankAwardMail(EMRA_KF_1V1_Preliminary, data.role_id, rank, buf);
		}
	}
}

void CKuaFu1vs1PreliminaryManager::TimeOut()
{
	int hour = GetSysHour();
	int minutes = GetSysMinute(); 
	//int seconds = GetSysSecond();
	int curWeekDay = GetWeekDay();
	int curMonthDay = GetDay();
	if( last_rewad_day != curMonthDay && curWeekDay != 0 && hour == 23 && minutes == 59)
	{
		//周一到周六发名次奖励
		SendDayReward();
		last_rewad_day = curMonthDay;
	}
	else if( last_rearrange_day != curMonthDay && curWeekDay == 0 && hour == 23 && minutes == 30 )
	{
		//周天晚上
		RearrangeToRandomSort();
		last_rearrange_day = curMonthDay;
		SaveDBByLong();
	}
	
	if( day_save != curMonthDay && hour == 4 && minutes == 30 )
	{
		day_save = curMonthDay;
		SaveDBByLong();
	}

}
int CKuaFu1vs1PreliminaryManager::GetAddChallengeNumSpendYB( int total)
{
	//////////////////////////////////////
	//预赛购买次数消耗的元宝改动：			
	//	1~3次	1元宝	
	//	4~6次	2元宝	
	//	7~9次	4元宝	
	//	10~12次	8元宝	
	//	13~15次	16元宝	
	//	16~18次	32元宝	
	//	19次及之后	50元宝	
	/////////////////////////////////////
	/*int use_tongbao = 20;
	if( total >= 0 && total <= 2)
	{
		use_tongbao = 1;
	}
	else if(  total >= 3 && total <= 5 )
	{
		use_tongbao = 2;
	}
	else if(  total >= 6 && total <= 8 )
	{
		use_tongbao = 4;
	}
	else if(  total >= 9 && total <= 11 )
	{
		use_tongbao = 8;
	}
	else if(  total >= 12 && total <= 14 )
	{
		use_tongbao = 16;
	}
	else if(  total >= 15 && total <= 17 )
	{
		use_tongbao = 32;
	}
	else
	{
		use_tongbao = 50;
	}*/
	return 100;
}

void CKuaFu1vs1PreliminaryManager::AddChallengeNum( CUser *pUser)
{
	if( pUser == NULL )
		return;
	if(pUser->GetKuaFu1vs1PreliminaryUsedChallengueNum() == 0)
		return;
	int use_tongbao = GetAddChallengeNumSpendYB(pUser->GetKuaFu1vs1PreliminaryUsedChallengueTotalNum());
	int used_num = pUser->GetKuaFu1vs1PreliminaryUsedChallengueNum();
	if( used_num<= 0 || pUser->GetTongBao() <use_tongbao)
		return;
	pUser->AddTongBao(-use_tongbao);
	pUser->SetKuaFu1vs1PreliminaryUsedChallengueNum(used_num-1);
	pUser->SetKuaFu1vs1PreliminaryUsedChallengueTotalNum(pUser->GetKuaFu1vs1PreliminaryUsedChallengueTotalNum()+1);
	ItemCurrencyLog(pUser->GetRoleId(),0,0,0,use_tongbao,pUser->GetTongBao(),YBL_KUA_FU_1VS1_PRELIMINARY_ADD_NUM);

	CNetMessage msg;
	msg.SetType(MSG_KUA_FU_1V1);
	msg<<(uint8)6<<(int)(MAX_CHALLENGUE_NUM-pUser->GetKuaFu1vs1PreliminaryUsedChallengueNum())<<MAX_CHALLENGUE_NUM;
	msg<<GetAddChallengeNumSpendYB( pUser->GetKuaFu1vs1PreliminaryUsedChallengueTotalNum());
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}
void CKuaFu1vs1PreliminaryManager::RefreshEnemy( CUser *pUser)
{
	int use_tongbao = 20;
	if( pUser == NULL )
		return;
	if(pUser->GetKuaFu1vs1PreliminaryRefreshHeroNum()>= 1 && pUser->GetTongBao() <use_tongbao)
		return;
	if(pUser->GetKuaFu1vs1PreliminaryRefreshHeroNum()>= 1) 
	{
		pUser->AddTongBao(-use_tongbao);
		ItemCurrencyLog(pUser->GetRoleId(),0,0,0,use_tongbao,pUser->GetTongBao(),YBL_KUA_FU_1VS1_PRELIMINARY_REFRESH);
	}
	pUser->SetKuaFu1vs1PreliminaryRefreshHeroNum( pUser->GetKuaFu1vs1PreliminaryRefreshHeroNum()+1);
	SingletonCKuaFu1vs1PreliminaryManager::instance().ChooseFiveEnemyFromSort(pUser);
	SendKuaFu1vs1PreliminaryPanelInfo(pUser);
}

void CKuaFu1vs1PreliminaryManager::ClearChallengeCDTime( CUser *pUser)
{
	int use_tongbao = 50;
	if( pUser == NULL )
		return;
	if( pUser->GetKuaFu1vs1PreliminaryChallengueCDTime() < GetSysTime() ||  pUser->GetTongBao() <use_tongbao )
		return;
	pUser->AddTongBao(-use_tongbao);
	pUser->SetKuaFu1vs1PreliminaryChallengueCDTime(0);
	ItemCurrencyLog(pUser->GetRoleId(),0,0,0,use_tongbao,pUser->GetTongBao(),YBL_KUA_FU_1VS1_PRELIMINARY_CLEAR_CD);

	CNetMessage msg;
	msg.SetType(MSG_KUA_FU_1V1);
	msg<<(uint8)7<<(int)0;
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void CKuaFu1vs1PreliminaryManager::FillFinalUserInfo(SKuaFu1V1UserData (*info)[MAX_PAIMING_NUM])
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	int index = 0;
	for( int sort_id = 0; sort_id < SORT_MAX_NUM; ++sort_id)
	{
		int rank = 0;
		for(SortIter map_iter = sortlist[sort_id].begin();map_iter != sortlist[sort_id].end(); ++map_iter)
		{
			++rank;
			if(rank == 1 || rank == 4)
				index = 0;
			else
				index = 1;
			if(rank <= 4)
			{
				int seq = sort_id*2 + (rank-1)/2;
				info[seq][index].data = map_iter->second;
				info[seq][index].rank = rank;
				// 晋级决赛
				SendSystemMail(map_iter->second.role_id, LANGUAGE_ZQX_0078);
			}
			else
			{
				SendSystemMail(map_iter->second.role_id, LANGUAGE_ZQX_0079);
			}
		}//end of for
	}//end of for sort_id
	
	SaveDBByLong();	
}
#endif


/////////////////////////////////CKuaFu1vs1PreliminaryManager END///////////////////////////////////////

/////////////////////////////////CShenJieMiJingManager START///////////////////////////////////////
CShenJieMiJingManager::CShenJieMiJingManager()
{
	currentBossID = 0;
	currentBossHp = 0;
	currentBossMaxHp = 0;
	bossState.init();
	m_sort.clear();
	boss_10_mins_check = false;
	boss_20_mins_check = false;
	isSendReward = false;
	boss_dead_time = 0;
	isInitState = false;
}
void CShenJieMiJingManager::JoinIn(CUser *pUser)
{
	if(pUser == NULL)
		return;
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_SHENJIE_MIJING);
	msg<<(uint8)1;

	vector<ShareUserPtr> pMember;
	GetTeamMemberList(pUser,pMember);
	int roleNum = pMember.size();
	if(roleNum == 0)
		return;

	int serverZoneId = GetServerZone(pUser->GetServerId());
	for(int counter = 0; counter < roleNum; ++counter)
	{
		if(pMember[counter].get() != NULL)
		{
			if(GetServerZone(pMember[counter]->GetServerId()) != serverZoneId)
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0021,TIPS_FAILURE_COLOR);
				SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
				return;
			}
		}
	}

	CSceneManager &scene = SingletonSceneManager::instance();
	CScene *pScene = scene.GetShenJieMiJingFirstScene();
	if(pScene == NULL)
		return;
	int index = 1;
	while(pScene->GetUserNum() + roleNum > SHENJIEMIJING_ROOM_LIMIT)
	{
		index++;
		pScene = scene.GetShenJieMiJingSceneByIndex(index);
		if(pScene == NULL)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0022,TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			return;
		}
	}
	for(int counter = 0; counter < roleNum; ++counter)
	{
		if(pMember[counter].get() !=NULL)
		{
			pMember[counter]->SaveEnterPos(pUser->GetSceneId(),pMember[counter]->GetX(),pMember[counter]->GetY());
		}
	}	

	uint16 x = pScene->GetX();
	uint16 y = pScene->GetY();	
	uint16 srcSceneId = pScene->GetSrcSceneId();
	pUser->GetNextSrcSceneId(srcSceneId);

	CNetMessage msg1;
	msg1.ReWrite();
	msg1.SetType(PRO_JUMP_SCENE);
	msg1<<(uint16)srcSceneId<<x<<y<<(uint8)0<<(uint8)0;
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg1);
	pUser->SetPos(x,y);
	pUser->SetFace(0);
	pUser->EnterScene(pScene);
	for(int counter = 0; counter < roleNum; ++counter)
	{
		if(pMember[counter].get() !=NULL)
		{
			SendBossHpInfoToUser(pMember[counter].get());
			ShowReliveTime(pMember[counter].get());
		}
	}

}
void CShenJieMiJingManager::SendBossHpInfoToUser(CUser* pUser)
{
	if(pUser== NULL)
		return;
	CNetMessage msg;
	msg.SetType(MSG_SHENJIE_MIJING);
	msg<<(uint8)7;
	if(MakeBossHpInfo(msg))
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
	else
	{
		msg.ReWrite();
		msg.SetType(MSG_SHENJIE_MIJING);
		msg<<(uint8)8;
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
	}
}
void CShenJieMiJingManager::GetSort(CUser *pUser)
{
	if(pUser == NULL)
		return;

	const uint16 show_rank = 100;	// 上榜名次显示限制，前100名上榜
	const uint16 max_show_num = 30;
	uint32 my_score = 0;
	uint32 my_server_score = 0;
	uint16 all_myRank = 0;
	int bangPai = pUser->GetBangPai();
	uint16 allRankNum = 0;
	
	CNetMessage msg;
	msg.SetType(MSG_SHENJIE_MIJING);
	msg<<(uint8)2;
	uint16 pos = msg.GetDataLen();
	msg<<allRankNum;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	uint16 index = 0;
	//所有服
	for(SortIter map_iter = m_sort.begin(); map_iter != m_sort.end();++map_iter)
	{
		index++;
		if(index <= max_show_num)
		{
			allRankNum++;
			msg<<index<<map_iter->second.name<<map_iter->first.score;
		}
		if(map_iter->first.role_id == pUser->GetRoleId())
		{
			my_score = map_iter->first.score;
			all_myRank = index;
		}
	}
	if(allRankNum > 0)
		msg.WriteData(pos,&allRankNum,sizeof(allRankNum));
	if(all_myRank > show_rank)
		all_myRank = 0;
	msg<<all_myRank;

	// 本服
	uint16 server_rank = 0;
	allRankNum = 0;
	index = 0;
	pos = msg.GetDataLen();
	msg<<allRankNum;
	for(SortIter map_iter = m_sort.begin(); map_iter != m_sort.end();++map_iter)
	{
		if(map_iter->second.bangPai == bangPai)
		{
			index++;
			if(index <= max_show_num)
			{
				allRankNum++;
				msg<<index<<map_iter->second.name<<map_iter->first.score;
			}
			if(map_iter->first.role_id == pUser->GetRoleId())
			{
				server_rank = index;
			}
			my_server_score += map_iter->first.score;
		}

	}
	if(allRankNum > 0)
		msg.WriteData(pos,&allRankNum,sizeof(allRankNum));
	if(server_rank > show_rank)
		server_rank = 0;
	msg<<server_rank;
	msg<<my_score<<my_server_score;
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void CShenJieMiJingManager::GetRoomInfo(CUser *pUser)
{
	if(pUser == NULL)
		return;
	CNetMessage msg;
	msg.SetType(MSG_SHENJIE_MIJING);
	msg<<(uint8)3;
	CScene *pScene = pUser->GetScene();
	if(pScene == NULL)
		return;
	if(pScene->GetSrcSceneId() != SHENJIEMIJING_SCENE_ID)
		return;
	msg<<(uint16)(pScene->GetId()-SHENJIEMIJING_SCENE_ID_BEGIN+1);
	SingletonSceneManager::instance().GetShenJieMiJingRoomInfo(msg);
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void CShenJieMiJingManager::TryBossFight(CUser *pUser)
{
	ShareFightPtr pFight = SingletonFightManager::instance().CreateFight();
	if (pFight.get() == NULL)
		return;
	SMonsterBossCfg* cfg = SingletonMonsterBossManager::instance().GetMonsterBossCfg(bossState.boss_id);
	if (cfg == NULL)
		return;

	pFight->SetFightType(CFight::EFKuaFuShenJieMiJingBossPVE);
	pFight->SetFightChooseMode();
	ShareUserPtr ptrUser = SingletonOnlineUser::instance().GetUserByRoleId(pUser->GetRoleId());
	pFight->AddUserGroupToFight(ptrUser);

	pFight->AddMonsterWithFightId(bossState.boss_id);
	SFastFightResult result;
	pFight->BeginFastFight(result, true, pUser->GetSock());
}

void CShenJieMiJingManager::SwitchRoom(CUser *pUser,int room_id)
{
	if(pUser == NULL)
		return;
	CNetMessage msg;
	msg.SetType(MSG_SHENJIE_MIJING);
	msg<<(uint8)4<<room_id;
	if(room_id == 0)
		return;
	if(room_id > SingletonSceneManager::instance().GetShenJieMiJingSceneNum())
		return;
	CScene *pScene = pUser->GetScene();
	if(pScene == NULL || pScene->GetSrcSceneId() != SHENJIEMIJING_SCENE_ID)
		return;
	if(room_id == pScene->GetId()-SHENJIEMIJING_SCENE_ID_BEGIN+1)
	{
		msg<<MakeStringColor(LANGUAGE_SSJ_0042,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}
	
	vector<ShareUserPtr> pMember;
	GetTeamMemberList(pUser,pMember);
	int teamNum = pMember.size();
	if(teamNum == 0)
	{
		msg<<MakeStringColor(LANGUAGE_SSJ_0052,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}
	pScene = SingletonSceneManager::instance().GetShenJieMiJingSceneByIndex(room_id);
	if(pScene == NULL)
		return;
	if(pScene->GetUserNum()+teamNum > SHENJIEMIJING_ROOM_LIMIT)
	{
		msg<<MakeStringColor(LANGUAGE_SSJ_0043,TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
		return;
	}

	uint16 x=0,y=0;
	if(!pScene->GetCanWalkPos(x,y))
		return;
	uint16 srcSceneId = pScene->GetSrcSceneId();
	pUser->GetNextSrcSceneId(srcSceneId);

	CNetMessage msg1;
	msg1.ReWrite();
	msg1.SetType(PRO_JUMP_SCENE);
	msg1<<(uint16)srcSceneId<<x<<y<<(uint8)0<<(uint8)0;
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg1);
	pUser->SetPos(x,y);
	pUser->SetFace(0);
	pUser->EnterScene(pScene);

	for(int counter = 0; counter < teamNum; ++counter)
	{
		if(pMember[counter].get() !=NULL)
		{
			SendBossHpInfoToUser(pMember[counter].get());
			ShowReliveTime(pMember[counter].get());
		}
	}
}

void CShenJieMiJingManager::SummonBoss(int id,CScene *pSceneOne)
{
	if (bossState.state == STATE_BEFOR)
		return;

	int curIdx = bossState.boss_id - 30000;

	int fightId = id;
	const SPoint pos[] = { { 493,246 },{ 1250,745 },{ 2188,1231 } };;
	if((uint32)curIdx >= sizeof(pos)/sizeof(pos[0]))
		return;
	int pos_x = pos[curIdx].x;
	int pos_y = pos[curIdx].y;
	CSceneManager &sceneMgr = SingletonSceneManager::instance();
	if(pSceneOne == NULL)
	{
		if(bossState.state != STATE_NEXT)
			return;
		currentBossID = id;
		currentBossMaxHp = GetBossMaxHp();
		currentBossHp = currentBossMaxHp;
		SetBossState(currentBossID, STATE_NOW_FIGFHT);
		int sceneNum = SingletonSceneManager::instance().GetShenJieMiJingSceneNum();
		for(int counter=0;counter<sceneNum; ++counter)
		{
			uint16 sceneId = SHENJIEMIJING_SCENE_ID_BEGIN + counter;
			CScene *pScene = sceneMgr.FindScene(sceneId);
			if (pScene == NULL)
				return;
			pScene->AddVisibleBossByFightId(fightId,pos_x,pos_y);
		}
		boss_10_mins_check = false;
		boss_20_mins_check = false;
		isSendReward = false;
		boss_dead_time = 0;
		SendSysInfoToAll(false,0,LANGUAGE_CHY_77,GetMonsterBossName(id));
		RefreshBossHp();
		
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		m_sort.clear();
	}
	else
	{
		pSceneOne->AddVisibleBossByFightId(fightId,pos_x,pos_y);
	}
}

void CShenJieMiJingManager::ClearCurrentBoss(int state/* = STATE_BEFOR*/)
{
	if( currentBossID == 0)
		return;
	SetBossState( currentBossID, state);
	currentBossID = 0;
	currentBossHp = 0;
	currentBossMaxHp = 0;
	ClearMapBossHpShow();
	CSceneManager &sceneMgr = SingletonSceneManager::instance();
	int sceneNum = SingletonSceneManager::instance().GetShenJieMiJingSceneNum();
	for( int counter = 0;counter<sceneNum; ++counter)
	{
		uint16 sceneId = SHENJIEMIJING_SCENE_ID_BEGIN + counter;
		CScene *pScene = sceneMgr.FindScene(sceneId);
		if (pScene == NULL)
			return;
		pScene->ClearVisibleMonsterBoss();
	}
}
void CShenJieMiJingManager::SendSortReward()
{
	int rank = 0;
	char buf[256];
	AwardManager &awardMgr = SingletonAwardManager::instance();
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for( SortIter map_iter = m_sort.begin(); map_iter != m_sort.end();++map_iter)
	{
		++rank;
		if(rank > 30)
			snprintf(buf,sizeof(buf),LANGUAGE_CHY_76);
		else
			snprintf(buf,sizeof(buf),LANGUAGE_CHY_75,rank);
		awardMgr.SendRankAwardMail(CRankMgr::ERT_BossGeRen, map_iter->first.role_id, rank, buf);
	}
	ClearMapBossHpShow();
	isSendReward = true;
}

void CShenJieMiJingManager::SendSortMail(const char* str, SMailData& mdata)
{
	int rank = 0;
	for (SortIter map_iter = m_sort.begin(); map_iter != m_sort.end(); ++map_iter)
	{
		if (++rank > 30)
			return;
		SendSystemMail(map_iter->first.role_id, str, &mdata);
	}
}

void CShenJieMiJingManager::TimeOut(int setHour ,int setMin)
{
	int hour = GetHour();
	int minutes = GetMinute();
#ifdef _DEBUG_CHY
	if( hour != -1 && minutes != -1)
	{
		hour = setHour;
		minutes = setMin;
	}
#endif
	static bool notify = false;
	static bool start = false;
	static bool clear = false;
	static bool flushBoss = false;
	{
		if (!notify && CSceneManager::IsNotifyActivityTime(SOT_ShenJieMiJing))
		{
			SendHuoDongFlag(SOT_ShenJieMiJing, 3);
			notify = true;
		}
		if(CSceneManager::IsInActivityTime(SOT_ShenJieMiJing))
		{
			if (boss_dead_time != 0 && GetSysTime() > boss_dead_time + 60 * 2 && GetSysTime() < boss_dead_time + 60 * 5)
			{
				if(!isSendReward && currentBossID == 0)
				{
					SendSortReward();
					SendHuoDongFlag(SOT_ShenJieMiJing, 2);
					boss_dead_time = 0;
					isSendReward = true;
					notify = false;
					start = false;
					flushBoss = false;
					clear = true;
				}
				SaveDB();
			}
			else if (!start && !flushBoss && bossState.state != STATE_BEFOR)
			{
				SummonBoss(bossState.boss_id);
				flushBoss = true;
				start = true;
				isInitState = false;
				clear = false;
				SendHuoDongFlag(SOT_ShenJieMiJing, 1);
				SaveDB();
			}
			switch(minutes)
			{
				case 40:
					{
						if( !boss_10_mins_check)
						{
							if(currentBossID == 0)
							{
								UpBossRatio(0);	
							}
							boss_10_mins_check = true;
						}
					}
					break;
				case 50:
					{
						if( !boss_20_mins_check)
						{
							if(currentBossID != 0)
							{
								DownBossRatio(0);		
							}
							boss_20_mins_check = true;
						}
					}
					break;
			}//end of switch
		}
		if (!clear && CSceneManager::IsAfterActivityTime(SOT_ShenJieMiJing))
		{
			if (currentBossID == 0)
			{
				SendSortReward();
			}
			else
			{
				ClearCurrentBoss(STATE_TAOPAO);
				SendSysInfoToAll(false, 0, LANGUAGE_CHY_79, GetMonsterBossName(bossState.boss_id));
				char buf[512];
				snprintf(buf, sizeof(buf), LANGUAGE_CHY_79, GetMonsterBossName(bossState.boss_id));
				SMailData mdata;
				mdata.AddAward(2798, 0, 3);
				mdata.AddAward(4403, 0, 3);
				SendSortMail(buf, mdata);
			}
			SendHuoDongFlag(SOT_ShenJieMiJing, 2);
			isSendReward = true;
			notify = false;
			start = false;
			clear = true;
			flushBoss = false;
			SaveDB();
		}
	}//end of for
	
	if(hour == 0)
	{
		if( isInitState == false)
		{
			cout << "ChangeBoss" << endl;
			ChangeBoss();
			SaveDB();
			isInitState = true;
			isSendReward = false;
		}
	}

}

int CShenJieMiJingManager::GetCurrentBossHp()
{
	return currentBossHp;
}
void CShenJieMiJingManager::SetCurrentBossHp(int hp)
{
	currentBossHp = hp;
}
int CShenJieMiJingManager::GetCurrentBossID()
{
	return currentBossID;
}

void CShenJieMiJingManager::HandleBossFightEnd(CUser *pUser,int boss_id,int reduceHp)
{
	if( currentBossHp > reduceHp)
	{
		currentBossHp -= reduceHp;
	}
	else if( currentBossHp != 0)
	{
		currentBossHp = 0;
		ClearCurrentBoss();
		boss_dead_time = GetSysTime();
		ClearMapBossHpShow();
		//胜利公告
		SendSysInfoToAll(false,0,LANGUAGE_CHY_78,GetMonsterBossName(boss_id));
	}
	if(isSendReward == true)
		return;

//	vector<ShareUserPtr> pMember;
//	GetTeamMemberList(pUser,pMember);
//	for(uint16 counter = 0; counter < pMember.size(); counter++)
//	{
//		if(pMember[counter].get() != NULL)
//			AddUserScore(pMember[counter].get(), reduceHp);
//	}
	RefreshBossHp();
}

void CShenJieMiJingManager::AddUserScore( CUser *pUser,int score)
{
	if(pUser == NULL || isSendReward == true || score == 0)
		return;
	StShenJieMiJingSortKey key;
	key.role_id = pUser->GetRoleId();
	key.zhandouli = pUser->GetZhanDouLi();
	key.score = 0;

	StShenJieMiJingSortUserInfo info;
	info.name = pUser->GetName();
	info.bangPai = pUser->GetBangPai();
		
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	SortIter map_iter = m_sort.begin();
	bool isFind = false;
	for( ; map_iter != m_sort.end();++map_iter)
	{
		if( map_iter->first.role_id == key.role_id )
		{
			key.score = map_iter->first.score + score;
			m_sort.erase(map_iter);
			isFind = true;
			break;
		}
	}//end of for
	if(!isFind)
		key.score = score;
	m_sort.insert(std::make_pair(key,info));
} 

void CShenJieMiJingManager::ClearSort()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_sort.clear();
}

bool CShenJieMiJingManager::CanFight( CUser *pUser)
{
	if(pUser == NULL)
		return false;
	
	vector<ShareUserPtr> pMember;
	GetTeamMemberList(pUser,pMember);
	int roleNum = pMember.size();
	if(roleNum == 0)
		return false;
	for(int counter = 0; counter < roleNum; ++counter)
	{
		if(pMember[counter].get() != NULL)
		{
			if((int)(pMember[counter]->GetExtData32(301)+ 60) > GetSysTime())
				return false;
		}
	}
	return true;
}

void CShenJieMiJingManager::SendPanelInfo(CUser *pUser)
{
	const string time[3] = {LANGUAGE_CHY_80,LANGUAGE_CHY_81,LANGUAGE_CHY_82};
	const int reward_id[3] = {4406,2517,2798};

	if(pUser == NULL)
		return;
	CNetMessage msg;
	msg.SetType(MSG_SHENJIE_MIJING);
	msg<<(uint8)5;
	{
		// 今天boss
		int pic = 0;
		string name;
		if(!SingletonMonsterBossManager::instance().GetMonsterBossInfo(bossState.boss_id,pic,name))
		{
			cout<<"Can not find boss, bossId="<<bossState.boss_id<<endl;
			return;
		}
		msg << pic << name << bossState.state << time[0];

		// 明天boss
		if (!SingletonMonsterBossManager::instance().GetMonsterBossInfo(GetNextBossID(), pic, name))
		{
			cout << "Can not find boss, bossId=" << bossState.boss_id << endl;
			return;
		}
		msg << pic << name << (int)STATE_NEXT << time[0];
	}
	msg << reward_id[0] << reward_id[1] << reward_id[2];
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

void CShenJieMiJingManager::FightPunish(CUser *pUser)
{
	if(pUser == NULL)
		return;
	
	vector<ShareUserPtr> pMember;
	GetTeamMemberList(pUser,pMember);
	int roleNum = pMember.size();
	if(roleNum == 0)
		return;
	for(int counter = 0; counter < roleNum; ++counter)
	{
		if(pMember[counter].get() != NULL)
		{
			pMember[counter]->SetExtData32(301,GetSysTime());
			CScene *pScene = pMember[counter]->GetScene();
			if(pScene != NULL)
			{
				pScene->GoTo(pMember[counter].get(),pScene->GetX(),pScene->GetY());
			}
			ShowReliveTimeClearPanel(pMember[counter].get());
		}
	}
//		pUser->ExitFuBen();
}

void CShenJieMiJingManager::SendWinReward(CUser *pUser)
{
	if(pUser == NULL)
		return;

	vector<ShareUserPtr> pMember;
	GetTeamMemberList(pUser,pMember);
	int roleNum = pMember.size();
	if(roleNum == 0)
		return;
	for(int counter = 0; counter < roleNum; ++counter)
	{
		if(pMember[counter].get() != NULL)
		{
			if(pMember[counter]->GetExtData8(476) < 10)
			{
				//30%概率获得一个随机一级宝石
				if(Random(1,100)<=15)
				{
					int item_id[]={2595,2605,2615,2625,2635,2645,2655,2665,2675,2685,2695,2705,2715};
					int seq = Random(1,sizeof(item_id)/sizeof(item_id[0]));
					if(AddPackageByID( pMember[counter].get(),item_id[seq-1],1,true,true))
						pMember[counter]->SetExtData8(476,pMember[counter]->GetExtData8(476)+1);
				}
			}
		}
	}
}

void CShenJieMiJingManager::RefreshBossHp()
{
	CSceneManager &sceneMgr = SingletonSceneManager::instance();
	int sceneNum =  SingletonSceneManager::instance().GetShenJieMiJingSceneNum();
	for( int counter = 0;counter<sceneNum; ++counter)
	{
		uint16 sceneId = SHENJIEMIJING_SCENE_ID_BEGIN + counter;
		CScene *pScene = sceneMgr.FindScene(sceneId);
		if (pScene == NULL)
			return;
		CNetMessage msg;  
		msg.SetType(MSG_SHENJIE_MIJING);
		msg<<(uint8)7;
		if(MakeBossHpInfo(msg))
			pScene->BroadcastMsgDirect(msg);	
	}

}
bool CShenJieMiJingManager::MakeBossHpInfo(CNetMessage &msg)
{
	int pic = 0;
	string name;
	if(!SingletonMonsterBossManager::instance().GetMonsterBossInfo(currentBossID,pic,name))
		return false;
	if( currentBossHp == 0)
		return false;
	int min = 60;
	if (GetHour() == 19)
		min -= 30;
	int leftSeconds = min * 60 - GetMinute() * 60 - GetSecond();
	pic = GetBossPic(currentBossID);
	msg<<pic<<name<<currentBossHp<<currentBossMaxHp<<currentBossID<<leftSeconds;
	return true;
}
int CShenJieMiJingManager::GetBossMaxHp()
{
	int maxHp = SingletonMonsterBossManager::instance().GetMonsterBossMaxHp(currentBossID);
	if(maxHp < 0)
		return 0;
	maxHp = (int)(maxHp *(1 + bossState.ratio / 100.0));
	if (maxHp < 0)
		maxHp = 0x7fffffff;
	return maxHp;
}
void CShenJieMiJingManager::ClearMapBossHpShow()
{
	CSceneManager &sceneMgr = SingletonSceneManager::instance();
	int sceneNum =  SingletonSceneManager::instance().GetShenJieMiJingSceneNum();
	for( int counter = 0;counter<sceneNum; ++counter)
	{
		uint16 sceneId = SHENJIEMIJING_SCENE_ID_BEGIN + counter;
		CScene *pScene = sceneMgr.FindScene(sceneId);
		if (pScene == NULL)
			return;
		CNetMessage msg;
		msg.SetType(MSG_SHENJIE_MIJING);
		msg<<(uint8)8;
		pScene->BroadcastMsgDirect(msg);
	}
}
void CShenJieMiJingManager::AskClearReliveTime(CUser* pUser)
{
	if(pUser == NULL)
		return;
	if((int)(pUser->GetExtData32(301) +60) < GetSysTime())
		return;
	const int cost_yb = 100;
	if( pUser->GetTongBao() < cost_yb)
	{
		SendInfoToMe(pUser,TIPS_FAILURE_COLOR,LANGUAGE_CHY_83);
		return;
	}
	pUser->AddTongBao(-cost_yb);
	pUser->SetExtData32(301,0);
	ClearReliveTime(pUser);
	SaveDate(pUser,712,cost_yb );
	char buf[128];
	snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0090, cost_yb);
	SendSysInfo(pUser, MakeStringColor(buf, TIPS_WARNING_COLOR).c_str());
}
void CShenJieMiJingManager::ShowReliveTime(CUser* pUser)
{
	if(pUser == NULL)
		return;
	CNetMessage msg;
	msg.SetType(MSG_SHENJIE_MIJING);
	msg<<(uint8)9;
	int second = 0;
	if((int)(pUser->GetExtData32(301) +60) > GetSysTime())
	{
		second = (int)(pUser->GetExtData32(301) +60 - GetSysTime());
		msg<<second;
	}
	else
		return;
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);	
}

void CShenJieMiJingManager::ClearReliveTime(CUser* pUser)
{
	if(pUser == NULL)
		return;
	CNetMessage msg;
	msg.SetType(MSG_SHENJIE_MIJING);
	msg<<(uint8)9;
	int second = 0;
	msg<<second;
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);	
}
void CShenJieMiJingManager::ShowReliveTimeClearPanel(CUser* pUser)
{
	if(pUser == NULL)
		return;
	ShowReliveTime(pUser);
	CNetMessage msg;
	msg.SetType(MSG_SHENJIE_MIJING);
	msg<<(uint8)10;
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);

}
void CShenJieMiJingManager::InitBossState()
{
	if (bossState.boss_id == 0)
	{
		bossState.boss_id = 30000;
		bossState.ratio = 1;
		bossState.refresh_day = 0;
		bossState.state = STATE_NEXT;
	}
}

int CShenJieMiJingManager::GetNextBossID()
{
	const int boss_id[3] = { 30000,30001,30002 };
	int idx = 0;
	for (; idx < (int)(sizeof(boss_id) / sizeof(boss_id[0])); ++idx)
	{
		if (bossState.boss_id == boss_id[idx])
			break;
	}
	if (idx >= 2)
		idx = 0;
	else
		idx++;
	return boss_id[idx];
}

void CShenJieMiJingManager::ChangeBoss()
{
	bossState.boss_id = GetNextBossID();
	bossState.state = STATE_NEXT;
	bossState.refresh_day = GetDay();
}

void CShenJieMiJingManager::GetBossBuffData(int boss_id,StBossState &buff)
{
	buff = bossState;
}

void CShenJieMiJingManager::SetBossStateID(int seq,int boss_id)
{
	bossState.boss_id = boss_id;
}

void CShenJieMiJingManager::SetBossState(int id,int state)
{
	bossState.state = state;
	if (state == STATE_NOW_FIGFHT)
		AddRedPointInfoToAll();
	else if (state == STATE_BEFOR || state == STATE_TAOPAO)
		ClearRedPointInfoToAll();
}

int CShenJieMiJingManager::GetBossState(int id)
{
	return bossState.state;
}

int CShenJieMiJingManager::GetCurBossState()
{
	return GetBossState(currentBossID);
}

int CShenJieMiJingManager::GetBossID(int seq)
{
	if( seq <=0 || seq>3)
		return 0;
	const int boss_id[3]={30000,30001,30002};
	return boss_id[seq-1];
}

int CShenJieMiJingManager::GetBossPic(int bossId)
{
	const int PIC[3] = {508,605,311};
	int idx = 0;
	for(int i=1;i <= 3;i++)
	{
		if(GetBossID(i) == bossId)
		{
			idx = i;
			break;
		}
	}
	if(idx == 0)
		return 0;
	return PIC[idx-1];
}

bool CShenJieMiJingManager::Init()
{
	LoadDB();
	InitBossState();
	return true;
}
bool CShenJieMiJingManager::LoadDB()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	int day = GetDay();
	//                                    0  1
	if ((pDb != NULL) && (pDb->Query("select id,ratio, state, refresh_day from mijing_boss_ratio order by id asc")))
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		char **row; 
		while ((row = pDb->GetRow()) != NULL)
		{
			bossState.boss_id = atoi(row[0]);
			bossState.ratio = atoi(row[1]);
			bossState.state = atoi(row[2]);
			bossState.refresh_day = atoi(row[3]);
			if (bossState.refresh_day != day)
			{
				ChangeBoss();
			}
			else if(bossState.state == STATE_NOW_FIGFHT)
			{
				bossState.state = STATE_NEXT;
			}
		}
	}
	else
	{
		return false;
	}
	return true;
}
void CShenJieMiJingManager::SaveDB()
{
	CGetDbConnect getDb; 
	CDatabaseSql *pDb = getDb.GetDbConnect(); 
	char sql[1024]; 
	if(pDb == NULL) 
	{ 
		cout<<LANGUAGE_TRANSFORM_140<<endl; 
		return; 
	} 
	pDb->Query("truncate table mijing_boss_ratio"); 
	
	snprintf(sql, sizeof(sql), "insert into mijing_boss_ratio (id,ratio,state, refresh_day) values(%d,%d,%d, %u)", bossState.boss_id, bossState.ratio, bossState.state, bossState.refresh_day);
	if (!pDb->Query(sql))
		cout << LANGUAGE_TRANSFORM_141 << sql << endl;
}

void CShenJieMiJingManager::SendRedPointInfo(CUser *pUser)
{
	if( pUser == NULL || currentBossID == 0)
		return;
	CNetMessage msg;
	msg.SetType(MSG_SHENJIE_MIJING);
	msg<<(uint8)6<<(int)1;
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}
void CShenJieMiJingManager::AddRedPointInfoToAll()
{
	CNetMessage msg;
	msg.SetType(MSG_SHENJIE_MIJING);
	msg<<(uint8)6<<(int)1;
	SendMsgToAllUser(msg);
}
void CShenJieMiJingManager::ClearRedPointInfoToAll()
{
	CNetMessage msg;
	msg.SetType(MSG_SHENJIE_MIJING);
	msg<<(uint8)6<<(int)0;
	SendMsgToAllUser(msg);
}

void CShenJieMiJingManager::SetBossRatio(int seq,int ratio)
{
	bossState.ratio = ratio;
}

int CShenJieMiJingManager::GetBossRatio()
{
	return bossState.ratio;
}

void CShenJieMiJingManager::UpBossRatio(int seq)
{
	if( bossState.ratio +10 >300)
		return;
	bossState.ratio += 10;
}
void CShenJieMiJingManager::DownBossRatio(int seq)
{
	if( bossState.ratio -10 <-90)
		return;
	bossState.ratio -= 10;
}

int CShenJieMiJingManager::GetCurrentBossMaxHp()
{
	return currentBossMaxHp;
}
////////////////////////////////CShenJieMiJingManager END///////////////////////////////////////

///////////////////////////////CHuoDongMoneyGiftBag START///////////////////////////////////////
CHuoDongMoneyGiftBag::CHuoDongMoneyGiftBag()
{
	hd_gift_map.clear();
}
bool CHuoDongMoneyGiftBag::MakeHuoDongList(CNetMessage &msg)
{
	CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
	uint8 num = 0;
	uint16 pos = msg.GetDataLen();
	msg<<num;
	boost::recursive_mutex::scoped_lock lk(m_mutex);	
	for(HdGiftMapIter map_iter = hd_gift_map.begin();map_iter!= hd_gift_map.end();++map_iter)
	{
		int hd_type = map_iter->first;
		if(hd_type != 0)
		{
			if (awardManager.InHuoDongTime(hd_type))
			{
				msg<<hd_type<<awardManager.GetHuoDongName(hd_type)<<(uint8)0;
				msg<<(uint8)GetHuoDongNewSign(hd_type);
				num++;
			}
		}
	}//end of for
	msg.WriteData(pos,&num,sizeof(num));
	return true;	
}
bool CHuoDongMoneyGiftBag::MakeHuoDongDeatilInfo(CNetMessage &msg,int hd_type, CUser *pUser)
{
	if(pUser == NULL)
		return false;
	HdGiftMapIter hd_map_iter = hd_gift_map.find(hd_type);
	if( hd_map_iter != hd_gift_map.end())
	{
		uint32 cur_time = GetSysTime();
		uint32 hd_end_time = SingletonCHuoDongAwardManager::instance().GetHuoDongEndTime(hd_type);
		uint32 cd_time = (cur_time > hd_end_time) ? 0 : hd_end_time - cur_time;

		msg<<hd_type<<cd_time;
		int gift_num = 0;
		uint16 pos = msg.GetDataLen();
		msg<<gift_num;
		GiftMapIter gift_map_iter = hd_map_iter->second.giftMap.begin();
		for( ;gift_map_iter!= hd_map_iter->second.giftMap.end();++gift_map_iter)
		{
			int left_time = 0;
			if(  gift_map_iter->second.end_time!=0 && gift_map_iter->second.start_time!= 0)
			{
				if(gift_map_iter->second.end_time > GetSysTime() && GetSysTime() >= gift_map_iter->second.start_time)
				{
					left_time = gift_map_iter->second.end_time - GetSysTime();
				}
				else
				{
					continue;
				}
			}
			msg<<gift_map_iter->first<<gift_map_iter->second.gift_name<<gift_map_iter->second.money<<left_time;
			msg<<pUser->GetMoneyGiftBagBuyNum(hd_type,gift_map_iter->first);
			msg<<gift_map_iter->second.limit_buy_num;
			MakeGiftLimitMsg(msg,pUser,gift_map_iter->second.limit_type,gift_map_iter->second.limit_data1,gift_map_iter->second.limit_data2,hd_type);
			
			int award_num = 0;
			SHuoDongAward gift_award;
			gift_award.award[0] = gift_map_iter->second.award1;
			gift_award.num[0] = gift_map_iter->second.num1;
			gift_award.petQuality[0] = gift_map_iter->second.petQt1;
			gift_award.petQualityLv[0] = gift_map_iter->second.petQtLv1;
			if( gift_award.award[0] != 0 && gift_award.num[0] != 0)
				++award_num;
			gift_award.award[1] = gift_map_iter->second.award2;
			gift_award.num[1] = gift_map_iter->second.num2;
			gift_award.petQuality[1] = gift_map_iter->second.petQt2;
			gift_award.petQualityLv[1] = gift_map_iter->second.petQtLv2;
			if( gift_award.award[1] != 0 && gift_award.num[1] != 0)
				++award_num;
			
			gift_award.award[2] = gift_map_iter->second.award3;
			gift_award.num[2] = gift_map_iter->second.num3;
			gift_award.petQuality[2] = gift_map_iter->second.petQt3;
			gift_award.petQualityLv[2] = gift_map_iter->second.petQtLv3;
			if( gift_award.award[2] != 0 && gift_award.num[2] != 0)
				++award_num;
			msg<<award_num;
			MakeAwardMsg(pUser,gift_award,hd_type,msg);
			
			++gift_num;
		}//end of for
		msg.WriteData(pos,&gift_num,sizeof(gift_num));
	}
	return false;
}
bool CHuoDongMoneyGiftBag::CheckMoneyGiftBagBuyData( CUser *pUser,int money)
{
	if(pUser == NULL)
		return false;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(HdGiftMapIter hd_map_iter = hd_gift_map.begin();hd_map_iter!= hd_gift_map.end();++hd_map_iter)
	{
		GiftMapIter gift_map_iter = hd_map_iter->second.giftMap.begin();
		for( ;gift_map_iter!= hd_map_iter->second.giftMap.end();++gift_map_iter)
		{
			if( gift_map_iter->second.money == money
			&& CheckBuyLimit(pUser,gift_map_iter->second.limit_type,gift_map_iter->second.limit_data1,gift_map_iter->second.limit_data2,hd_map_iter->first,false))
			{
				int curTime = GetSysTime();
				if (gift_map_iter->second.start_time > curTime || gift_map_iter->second.end_time < curTime)
					continue;
				
				if(  gift_map_iter->second.limit_buy_num != 0
					&& pUser->GetMoneyGiftBagBuyNum( hd_map_iter->first,gift_map_iter->first)>=gift_map_iter->second.limit_buy_num)
				{
					return false;
				}
				//邮件发奖励
				SMailData mdata;
				char buf[256];
				snprintf(buf,sizeof(buf),LANGUAGE_CHY_89,SingletonCHuoDongAwardManager::instance().GetHuoDongName(hd_map_iter->first).c_str(),gift_map_iter->second.gift_name.c_str());
				AddRewardToMail(pUser,mdata,gift_map_iter->second.award1,gift_map_iter->second.num1,gift_map_iter->second.petQt1,gift_map_iter->second.petQtLv1);
				AddRewardToMail(pUser,mdata,gift_map_iter->second.award2,gift_map_iter->second.num2,gift_map_iter->second.petQt2,gift_map_iter->second.petQtLv2);
				AddRewardToMail(pUser,mdata,gift_map_iter->second.award3,gift_map_iter->second.num3,gift_map_iter->second.petQt3,gift_map_iter->second.petQtLv3);
				SendSystemMail(pUser->GetRoleId(),buf,&mdata);
				pUser->AddMoneyGiftBagBuyNum(hd_map_iter->first,gift_map_iter->first);
				SaveDate(pUser,713,money,"money_gift_bag");
				return true;
			}
		}
	}//emd of for
	return false;
}
void CHuoDongMoneyGiftBag::ReqCheckBuyLimit(CUser *pUser,int hd_type,int gift_id)
{
	if(pUser == NULL)
		return;
	int ad = pUser->GetAd();
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	HdGiftMapIter hd_map_iter = hd_gift_map.find(hd_type);
	if( hd_map_iter != hd_gift_map.end())
	{
		if(!SingletonCHuoDongAwardManager::instance().InHuoDongTime(hd_type))
		{
			SendInfoToMe(pUser,TIPS_FAILURE_COLOR,LANGUAGE_CHY_91);
			return;
		}

		GiftMapIter gift_map_iter = hd_map_iter->second.giftMap.find(gift_id);
		if( gift_map_iter != hd_map_iter->second.giftMap.end())
		{
			if( gift_map_iter->second.start_time != 0 && gift_map_iter->second.end_time != 0
				&& (GetSysTime() < gift_map_iter->second.start_time || GetSysTime() > gift_map_iter->second.end_time +15) )
			{
				SendInfoToMe(pUser,TIPS_FAILURE_COLOR,LANGUAGE_CHY_91);
				return;
			}
			if(  gift_map_iter->second.limit_buy_num != 0
				&& pUser->GetMoneyGiftBagBuyNum(hd_type,gift_id)>=gift_map_iter->second.limit_buy_num)
			{
				SendInfoToMe(pUser,TIPS_FAILURE_COLOR,LANGUAGE_CHY_95);
				return;
			}
			if(CheckBuyLimit(pUser,gift_map_iter->second.limit_type,gift_map_iter->second.limit_data1,gift_map_iter->second.limit_data2,hd_map_iter->first))
			{
				CNetMessage msg;
				msg.SetType(MSG_KOREA_MONEY_GIFT);
				string payStr;
				GetPayId(ad,gift_map_iter->second.money,payStr);
				msg<<(uint8)4<<hd_type<<gift_id<<gift_map_iter->second.money<<payStr;
				SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
			}
		}
	}
}

void CHuoDongMoneyGiftBag::GetPayId(int ad,int money,string &payStr)
{
	payStr.clear();
	map<int,map<int,string> >::iterator it = hd_money_map.find(ad);
	if(it == hd_money_map.end())
		return;
	
	map<int,string>::iterator it2 = it->second.find(money);
	if(it2 == it->second.end())
		return;
	payStr = it2->second;
}

bool CHuoDongMoneyGiftBag::CheckBuyLimit(CUser *pUser,int limit_type,int limit_data1,int limit_data2,int hd_type,bool isShow)
{
	if(pUser == NULL)
		return false;

	switch(limit_type)
	{
		case 0:	//无限制
			{
				return true;
			}
			break;
		case 1:	//角色等级[limit_data1,limit_data2]
			{
				if(pUser->GetLevel()>= limit_data1 && pUser->GetLevel()<=limit_data2)
				{
					return true;
				}
				if(isShow)
				{
					SendInfoToMe(pUser,TIPS_FAILURE_COLOR,LANGUAGE_CHY_92,limit_data1,limit_data2);	
				}
				return false;
			}
			break;
		case 2: //至尊等级>= limit_data1
			{
				if(pUser->GetVipLevel()>=limit_data1)
				{
					return true;
				}
				if(isShow)
				{
					SendInfoToMe(pUser,TIPS_FAILURE_COLOR,LANGUAGE_CHY_93,limit_data1);			
				}
				return false;
			}
			break;
		case 3: //活动期间充值>= limit_data1
			{	
				if(pUser->GetMoneyGiftBagChargeNum(hd_type)>=limit_data1)
				{
					return true;
				}
				if(isShow)
				{
					SendInfoToMe(pUser,TIPS_FAILURE_COLOR,LANGUAGE_CHY_94,limit_data1);	
				}
				else
				{
					//isShow=false时充值记录可能已被清除，不做检测
					return true;
				}
				return false;
			}
			break;
		default:
			{
				cout<<"error:unknown money gift bag limit_type"<<limit_type<<endl;
				return false;
			}
	}//end of switch
	return false;
}
void CHuoDongMoneyGiftBag::SendIconInfo(CUser *pUser)//角色上线相关处理
{
	if(pUser ==NULL)
		return;
	int time = GetMinHuoDongSecondLeft();
	//if(time)  Client要求没有就发0
	{
		CNetMessage msg;
		msg.SetType(MSG_KOREA_MONEY_GIFT);
		msg<<(uint8)1<<time;
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
	}
}
int CHuoDongMoneyGiftBag::GetMinHuoDongSecondLeft()
{
	int min_time = 0;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(HdGiftMapIter map_iter = hd_gift_map.begin();map_iter!= hd_gift_map.end();++map_iter)
	{
		int left_second = GetHuoDongSecondLeft(map_iter->first);
		if( (min_time == 0 || left_second < min_time) && left_second != 0 )
			min_time = left_second;
	}//end of for
	return min_time;
}
int CHuoDongMoneyGiftBag::GetHuoDongSecondLeft(int hd_type)
{
	int left_second = 0;
	int end_time = SingletonCHuoDongAwardManager::instance().GetHuoDongEndTime(hd_type);
	int start_time = SingletonCHuoDongAwardManager::instance().GetHuoDongStartTime(hd_type);
	int curTime = GetSysTime();
	if(start_time <= curTime && end_time > curTime)
	{
		left_second = end_time - GetSysTime();
	}
	return left_second;
}
void CHuoDongMoneyGiftBag::AddUserPayRecordInHuoDongTime(CUser *pUser, int value)
{
	if(pUser == NULL || value == 0)
		return;
	boost::recursive_mutex::scoped_lock lk(m_mutex);	
	for(HdGiftMapIter map_iter = hd_gift_map.begin();map_iter!= hd_gift_map.end();++map_iter)
	{
		int hd_type = map_iter->first;
		if(hd_type != 0 || SingletonCHuoDongAwardManager::instance().InHuoDongTime(hd_type))
		{
			pUser->AddMoneyGiftBagChargeNum(hd_type,value);
		}
	}//end of for
}
bool CHuoDongMoneyGiftBag::LoadDB()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
										//	0		1	2			3		4		5							6							7		8			9		10			11	   12	13	   14		15		16	17		18		19		20	21		22		 23			
	if ((pDb != NULL) && (pDb->Query("select id,hd_type,gift_id,gift_name,money,UNIX_TIMESTAMP(startTime),UNIX_TIMESTAMP(endTime),limit_buy_num,limit_type,limit_data1,limit_data2,award1,num1,petQt1,petQtLv1,award2,num2,petQt2,petQtLv2,award3,num3,petQt3,petQtLv3,pay_id from money_giftbag_huodong order by hd_type asc")))
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		hd_gift_map.clear();
		StHuoDongMoneyGiftInfo hd_info;
		char **row;
		int last_hd_type = 0;
		while ((row = pDb->GetRow()) != NULL)
		{
			int hd_type = atoi(row[1]);
			if( last_hd_type != 0 && last_hd_type != hd_type )
			{
				hd_info.hd_type = last_hd_type;
				hd_gift_map.insert(std::make_pair( last_hd_type,hd_info));
				hd_info.init();
			}
			last_hd_type = hd_type;
			int gift_id = atoi(row[2]);
			StMoneyGiftBagInfo gift_info;
			gift_info.gift_name = row[3];
			gift_info.money = atoi(row[4]);
			gift_info.start_time = atoi(row[5]);
			gift_info.end_time = atoi(row[6]);
			gift_info.limit_buy_num = atoi(row[7]);
			gift_info.limit_type = atoi(row[8]);
			gift_info.limit_data1 = atoi(row[9]);
			gift_info.limit_data2 = atoi(row[10]);
			gift_info.award1 = atoi(row[11]);
			gift_info.num1 = atoi(row[12]);
			gift_info.petQt1 = atoi(row[13]);
			gift_info.petQtLv1 = atoi(row[14]);
			gift_info.award2 = atoi(row[15]);
			gift_info.num2 = atoi(row[16]);
			gift_info.petQt2 = atoi(row[17]);
			gift_info.petQtLv2 = atoi(row[18]);
			gift_info.award3 = atoi(row[19]);
			gift_info.num3 = atoi(row[20]);
			gift_info.petQt3 = atoi(row[21]);
			gift_info.petQtLv3 = atoi(row[22]);
			gift_info.pay_id = row[23];
			hd_info.giftMap.insert(std::make_pair(gift_id,gift_info));	
		}//end of while
		hd_info.hd_type = last_hd_type;
		if(last_hd_type > 0)
			hd_gift_map.insert(std::make_pair( last_hd_type,hd_info));
	}
	else
	{
		return false;
	}

	//                                         0    1   2
	if ((pDb != NULL) && (pDb->Query("select money,ad,pay_id from money_giftbag_pay order by ad asc,money asc")))
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		hd_money_map.clear();
		map<int,string> data;
		char **row = NULL;
		int last_ad = 0;
		while ((row = pDb->GetRow()) != NULL)
		{
			int ad = atoi(row[1]);
			if(last_ad != 0 && last_ad != ad)
			{
				hd_money_map.insert(std::make_pair(last_ad,data));
				data.clear();
			}
			last_ad = ad;
			int money = atoi(row[0]);
			string payId = row[2];
			data.insert(std::make_pair(money,payId));
		}
		if(last_ad > 0)
			hd_money_map.insert(std::make_pair(last_ad,data));
	}
	else
	{
		return false;
	}
	return true;
}
void CHuoDongMoneyGiftBag::MakeGiftLimitMsg(CNetMessage &msg,CUser *pUser,int limit_type,int limit_data1,int limit_data2,int hd_type)
{
	if(pUser == NULL)
	{
		msg<<limit_type<<limit_data1<<limit_data2;
		return;
	}
	switch(limit_type)
	{
		case 0:	//无限制
		case 1:	//角色等级[limit_data1,limit_data2]
		case 2: //至尊等级>= limit_data1
			{
				msg<<limit_type<<limit_data1<<limit_data2;
				return;
			}
			break;
		case 3: //活动期间充值>= limit_data1
			{	
				msg<<limit_type<<limit_data1;
				msg<<pUser->GetMoneyGiftBagChargeNum(hd_type);
				return;
			}
			break;
		default:
			{
				cout<<"error:unknown money gift bag limit_type"<<limit_type<<endl;
				return;
			}
	}//end of switch

}
void CHuoDongMoneyGiftBag::AddRewardToMail( CUser *pUser, SMailData &mdata,int award,int num,int petLevel,int petStar)
{
	/*if(award == 0 || num == 0 || pUser == NULL)
		return;
	if(award < 60000)
	{
		SItemInstance item;
		item.tmplId = award;
		item.num = num;  
		mdata.item.push_back(item);
	}
	else if( award == HDAT_MONEY)
	{
		mdata.money += num;
	}
	else if( award == HDAT_YB)
	{
		mdata.YB += num;
	}
	else if( award == HDAT_BANG_YB)
	{
		mdata.bdYB += num;
	}
	else if( award == HDAT_PET)
	{
		int petId = num;
		AddPetToMail(mdata,petId,petLevel,petStar);
	}
	else
	{
		cout<<"money gift bag error award type ("<<award<<","<<num<<")"<<endl;
	}*/
}
///////////////////////////////CHuoDongMoneyGiftBag END/////////////////////////////////////////


///////////////////////////////CTransFormManager START///////////////////////////////////////////////
CTransFormManager::CTransFormManager()
{
	transformMap.clear();
	blue_quality_vec.clear();
	green_quality_vec.clear();
}

bool CTransFormManager::LoadDB()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if ((pDb != NULL) && (pDb->Query("select item_id,name,quality,last_time,target_type,monster_id,monster_name,attr_type1,attr_value1,attr_type2,attr_value2,attr_type3,attr_value3,attr_type4,attr_value4,attr_type5,attr_value5,attr_type6,attr_value6,attr_type7,attr_value7,attr_type8,attr_value8 from transform order by item_id asc")))
	{
		transformMap.clear();
		char **row;
		while ((row = pDb->GetRow()) != NULL)
		{
			StTransFormCardInfo info;
			info.item_id = atoi(row[0]);
			info.name= row[1];
			info.quality = atoi(row[2]);
			info.last_time = atoi(row[3]);
			info.target_type = atoi(row[4]);
			info.monster_id = atoi(row[5]);
			info.monster_name = row[6];
			int counter = 0;
			while( counter < 8 )
			{
				info.attr_type[counter] = atoi(row[counter * 2 +7]);
				info.attr_value[counter] = atoi(row[counter * 2 + 8]);
				++counter;
			}//end of while
			transformMap.insert(std::make_pair(info.item_id,info));
			if(info.quality == 1)
			{
				green_quality_vec.push_back(info.item_id);
			}
			else if( info.quality == 2)
			{
				blue_quality_vec.push_back(info.item_id);
			}
		}//end of while
	}
	else
	{
		return false;
	}
	return true;
}
bool CTransFormManager::IsTransFormCardID( int item_id )
{
	TransformMapIter map_iter = transformMap.find(item_id);
	if(map_iter != transformMap.end())
	{
		return true;
	}
	return false;
}
bool CTransFormManager::GetTransFormCardInfoByID( int item_id,StTransFormCardInfo &info )
{
	TransformMapIter map_iter = transformMap.find(item_id);
	if(map_iter != transformMap.end())
	{
		info = map_iter->second;
		return true;
	}
	return false;
}

int CTransFormManager::GetRandomDropTransFormCardID()
{
	int item_id = 0;
	int odds = Random(1,1000);
#ifdef _DEBUG_CHY
	odds = Random(1,20);
#endif
	if( odds <= 10)
	{
		int seq = Random(1,green_quality_vec.size());
		if(seq)
			item_id	= green_quality_vec[seq-1];
	}
	else if( odds == 11)
	{
		int seq = Random(1,blue_quality_vec.size());
		if(seq)
			item_id	= green_quality_vec[seq-1];			
	}
	return item_id;
}

///////////////////////////////CTransFormManager END/////////////////////////////////////////////////

const SQunXianZhengBa_Role QXZB_Role[] = {
	{1,98,100,1,92,95,2,86,89,3,0.0125,60001,50,50},
	{2,95,98,1,89,92,2,82,86,3,0.025,60000,30000,50},
	{3,92,95,1,86,89,2,79,82,3,0.0375,60001,50,50},
	{4,89,92,1,82,86,2,76,79,3,0.05,60000,30000,50},
	{5,86,89,1,79,82,2,73,76,3,0.0625,60001,100,100},
	{6,82,86,1,76,79,2,70,73,3,0.075,60000,50000,100},
	{7,79,82,1,73,76,2,67,70,3,0.0875,60001,100,100},
	{8,76,79,1,70,73,2,64,67,3,0.1,60000,50000,100},
	{9,73,76,1,67,70,2,61,64,3,0.1125,60001,150,150},
	{10,70,73,1,64,67,2,58,61,3,0.125,60000,70000,150},
	{11,67,70,1,61,64,2,55,58,3,0.1375,60001,150,150},
	{12,64,67,1,58,61,2,51,55,3,0.15,60000,70000,150},
	{13,61,64,1,55,58,2,48,51,3,0.1625,60001,150,150},
	{14,58,61,1,51,55,2,45,48,3,0.175,60000,70000,150},
	{15,55,58,1,48,51,2,42,45,3,0.1875,60001,200,200},
	{16,51,55,1,45,48,2,39,42,3,0.2,60000,100000,200},
	{17,48,51,1,42,45,2,36,39,3,0.2125,60001,200,200},
	{18,45,48,1,39,42,2,33,36,3,0.225,60000,100000,200},
	{19,42,45,1,36,39,2,30,33,3,0.2375,60001,200,200},
	{20,39,42,1,33,36,2,27,30,3,0.25,60000,100000,200},
	{21,36,39,1,30,33,2,24,27,3,0.2625,60001,200,200},
	{22,33,36,1,27,30,2,20,24,3,0.275,60000,100000,200},
	{23,30,33,1,24,27,2,17,20,3,0.2875,60001,200,200},
	{24,27,30,1,20,24,2,14,17,3,0.3,60000,100000,200},
	{25,24,27,1,17,20,2,11,14,3,0.3125,60001,200,200},
	{26,20,24,1,14,17,2,8,11,3,0.325,60000,100000,200},
	{27,17,20,1,11,14,2,5,8,3,0.3375,60001,200,200},
	{28,14,17,1,8,11,2,3,5,3,0.35,60000,100000,200},
	{29,11,14,1,5,8,2,2,3,3,0.3625,60001,200,200},
	{30,8,11,1,3,5,2,0,2,3,0.375,60000,100000,200},
};

const SQunXianZhengBa_Buff QXZB_Buff[] = {
	{1,20,300,2,21,700,4,17,1000,6},
	{2,23,300,2,24,700,4,22,1000,6},
	{3,19,300,2,20,700,4,21,1000,6},
	{4,18,300,2,23,700,4,24,1000,6},
	{5,17,300,2,19,700,4,20,1000,6},
	{6,22,300,2,18,700,4,23,1000,6},
	{7,21,300,2,17,700,4,19,1000,6},
	{8,24,300,2,22,700,4,18,1000,6},
	{9,20,300,2,21,700,4,17,1000,6},
	{10,23,300,2,24,700,4,22,1000,6},
	{11,19,300,2,20,700,4,21,1000,6},
	{12,17,300,2,23,700,4,24,1000,6},
	{13,22,300,2,19,700,4,20,1000,6},
	{14,21,300,2,17,700,4,23,1000,6},
	{15,24,300,2,22,700,4,19,1000,6},
};

const SQunXianZhengBa_Box QXZB_Box[] = {
	{1, {60000,2370,0},   {5000, 1,0},{4, 7, 10,15,22},{2920,2920,2920,834,834,834,613,613,613,614,614,614,60000,60000,60000,0,0,0,0,0},{44, 30,15,44, 30,15,44, 30,15,44, 30,15,44, 30,15,0,0,0,0,0},{1,2,3,1,2,3,1,2,3,1,2,3,1,2,3,0,0,0,0,0},{222,889,2222,2444,3111,4444,4666,5333,6666,6888,7555,8888,8999,9332,10000,10000,10000,10000,10000,10000}},
	{2, {60000,2370,0},   {5800, 1,0},{4, 7, 10,15,22},{2920,2920,2920,834,834,834,613,613,613,614,614,614,60000,60000,60000,0,0,0,0,0},{44, 30,15,44, 30,15,44, 30,15,44, 30,15,44, 30,15,0,0,0,0,0},{1,2,3,1,2,3,1,2,3,1,2,3,1,2,3,0,0,0,0,0},{222,889,2222,2444,3111,4444,4666,5333,6666,6888,7555,8888,8999,9332,10000,10000,10000,10000,10000,10000}},
	{3, {60000,2370,0},   {6600, 1,0},{4, 7, 10,15,22},{2920,2920,2920,834,834,834,613,613,613,614,614,614,60000,60000,60000,0,0,0,0,0},{44, 30,15,44, 30,15,44, 30,15,44, 30,15,44, 30,15,0,0,0,0,0},{1,2,3,1,2,3,1,2,3,1,2,3,1,2,3,0,0,0,0,0},{222,889,2222,2444,3111,4444,4666,5333,6666,6888,7555,8888,8999,9332,10000,10000,10000,10000,10000,10000}},
	{4, {60000,834, 0},   {7400, 1,0},{4, 7, 10,15,22},{2920,2920,2920,834,834,834,613,613,613,614,614,614,60000,60000,60000,0,0,0,0,0},{44, 30,15,44, 30,15,44, 30,15,44, 30,15,44, 30,15,0,0,0,0,0},{1,2,3,1,2,3,1,2,3,1,2,3,1,2,3,0,0,0,0,0},{222,889,2222,2444,3111,4444,4666,5333,6666,6888,7555,8888,8999,9332,10000,10000,10000,10000,10000,10000}},
	{5, {60000,613, 2920},{8200, 1,1},{4, 7, 10,15,22},{2920,2920,2920,834,834,834,613,613,613,614,614,614,60000,60000,60000,0,0,0,0,0},{44, 30,15,44, 30,15,44, 30,15,44, 30,15,44, 30,15,0,0,0,0,0},{1,2,3,1,2,3,1,2,3,1,2,3,1,2,3,0,0,0,0,0},{222,889,2222,2444,3111,4444,4666,5333,6666,6888,7555,8888,8999,9332,10000,10000,10000,10000,10000,10000}},
	{6, {60000,614, 0},   {9000, 1,0},{8, 14,20,30,44},{2920,2920,2920,834,834,834,613,613,613,614,614,614,60000,60000,60000,0,0,0,0,0},{89, 59,30,89, 59,30,89, 59,30,89, 59,30,89, 59,30,0,0,0,0,0},{1,2,3,1,2,3,1,2,3,1,2,3,1,2,3,0,0,0,0,0},{222,889,2222,2444,3111,4444,4666,5333,6666,6888,7555,8888,8999,9332,10000,10000,10000,10000,10000,10000}},
	{7, {60000,2370,0},   {9800, 2,0},{8, 14,20,30,44},{2920,2920,2920,834,834,834,613,613,613,614,614,614,60000,60000,60000,0,0,0,0,0},{89, 59,30,89, 59,30,89, 59,30,89, 59,30,89, 59,30,0,0,0,0,0},{1,2,3,1,2,3,1,2,3,1,2,3,1,2,3,0,0,0,0,0},{222,889,2222,2444,3111,4444,4666,5333,6666,6888,7555,8888,8999,9332,10000,10000,10000,10000,10000,10000}},
	{8, {60000,834, 0},   {10600,2,0},{8, 14,20,30,44},{2920,2920,2920,834,834,834,613,613,613,614,614,614,60000,60000,60000,0,0,0,0,0},{89, 59,30,89, 59,30,89, 59,30,89, 59,30,89, 59,30,0,0,0,0,0},{1,2,3,1,2,3,1,2,3,1,2,3,1,2,3,0,0,0,0,0},{222,889,2222,2444,3111,4444,4666,5333,6666,6888,7555,8888,8999,9332,10000,10000,10000,10000,10000,10000}},
	{9, {60000,613, 0},   {11400,2,0},{8, 14,20,30,44},{2920,2920,2920,834,834,834,613,613,613,614,614,614,60000,60000,60000,0,0,0,0,0},{89, 59,30,89, 59,30,89, 59,30,89, 59,30,89, 59,30,0,0,0,0,0},{1,2,3,1,2,3,1,2,3,1,2,3,1,2,3,0,0,0,0,0},{222,889,2222,2444,3111,4444,4666,5333,6666,6888,7555,8888,8999,9332,10000,10000,10000,10000,10000,10000}},
	{10,{60000,614, 2920},{12200,2,2},{8, 14,20,30,44},{2920,2920,2920,834,834,834,613,613,613,614,614,614,60000,60000,60000,0,0,0,0,0},{89, 59,30,89, 59,30,89, 59,30,89, 59,30,89, 59,30,0,0,0,0,0},{1,2,3,1,2,3,1,2,3,1,2,3,1,2,3,0,0,0,0,0},{222,889,2222,2444,3111,4444,4666,5333,6666,6888,7555,8888,8999,9332,10000,10000,10000,10000,10000,10000}},
	{11,{60000,2370,0},   {13000,2,0},{12,21,30,45,66},{2920,2920,2920,834,834,834,613,613,613,614,614,614,60000,60000,60000,0,0,0,0,0},{133,89,44,133,89,44,133,89,44,133,89,44,133,89,44,0,0,0,0,0},{1,2,3,1,2,3,1,2,3,1,2,3,1,2,3,0,0,0,0,0},{222,889,2222,2444,3111,4444,4666,5333,6666,6888,7555,8888,8999,9332,10000,10000,10000,10000,10000,10000}},
	{12,{60000,834, 0},   {13800,2,0},{12,21,30,45,66},{2920,2920,2920,834,834,834,613,613,613,614,614,614,60000,60000,60000,0,0,0,0,0},{133,89,44,133,89,44,133,89,44,133,89,44,133,89,44,0,0,0,0,0},{1,2,3,1,2,3,1,2,3,1,2,3,1,2,3,0,0,0,0,0},{222,889,2222,2444,3111,4444,4666,5333,6666,6888,7555,8888,8999,9332,10000,10000,10000,10000,10000,10000}},
	{13,{60000,613, 0},   {14600,2,0},{12,21,30,45,66},{2920,2920,2920,834,834,834,613,613,613,614,614,614,60000,60000,60000,0,0,0,0,0},{133,89,44,133,89,44,133,89,44,133,89,44,133,89,44,0,0,0,0,0},{1,2,3,1,2,3,1,2,3,1,2,3,1,2,3,0,0,0,0,0},{222,889,2222,2444,3111,4444,4666,5333,6666,6888,7555,8888,8999,9332,10000,10000,10000,10000,10000,10000}},
	{14,{60000,614, 0},   {15400,2,0},{12,21,30,45,66},{2920,2920,2920,834,834,834,613,613,613,614,614,614,60000,60000,60000,0,0,0,0,0},{133,89,44,133,89,44,133,89,44,133,89,44,133,89,44,0,0,0,0,0},{1,2,3,1,2,3,1,2,3,1,2,3,1,2,3,0,0,0,0,0},{222,889,2222,2444,3111,4444,4666,5333,6666,6888,7555,8888,8999,9332,10000,10000,10000,10000,10000,10000}},
	{15,{60000,2370,2920},{16200,3,3},{12,21,30,45,66},{2920,2920,2920,834,834,834,613,613,613,614,614,614,60000,60000,60000,0,0,0,0,0},{133,89,44,133,89,44,133,89,44,133,89,44,133,89,44,0,0,0,0,0},{1,2,3,1,2,3,1,2,3,1,2,3,1,2,3,0,0,0,0,0},{222,889,2222,2444,3111,4444,4666,5333,6666,6888,7555,8888,8999,9332,10000,10000,10000,10000,10000,10000}},
};

const SQunXianZhengBaConig QXZB_Floor[CQunXianZhengBaManager::MAX_FLOOR] = {
	{1,1},
	{1,2},
	{2,1},
	{3,1},
	{1,3},
	{1,4},
	{2,2},
	{3,2},
	{1,5},
	{1,6},
	{2,3},
	{3,3},
	{1,7},
	{1,8},
	{2,4},
	{3,4},
	{1,9},
	{1,10},
	{2,5},
	{3,5},
	{1,11},
	{1,12},
	{2,6},
	{3,6},
	{1,13},
	{1,14},
	{2,7},
	{3,7},
	{1,15},
	{1,16},
	{2,8},
	{3,8},
	{1,17},
	{1,18},
	{2,9},
	{3,9},
	{1,19},
	{1,20},
	{2,10},
	{3,10},
	{1,21},
	{1,22},
	{2,11},
	{3,11},
	{1,23},
	{1,24},
	{2,12},
	{3,12},
	{1,25},
	{1,26},
	{2,13},
	{3,13},
	{1,27},
	{1,28},
	{2,14},
	{3,14},
	{1,29},
	{1,30},
	{2,15},
	{3,15},
};


CQunXianZhengBaManager::CQunXianZhengBaManager()
{
	m_sortFlag = false;
}

CQunXianZhengBaManager::~CQunXianZhengBaManager()
{

}

void CQunXianZhengBaManager::GetFloorConfig(uint8 floor,SQunXianZhengBaConig &data)
{
	uint8 size = sizeof(QXZB_Floor)/sizeof(QXZB_Floor[0]);
	data.Clear();
	if(floor > size || floor == 0)
		return;
	data = QXZB_Floor[floor-1];
}

void CQunXianZhengBaManager::GetBuffCfgByIdx(uint8 index,SQunXianZhengBa_Buff &data)
{
	uint8 size = sizeof(QXZB_Buff)/sizeof(QXZB_Buff[0]);
	data.Clear();
	if(index > size || index == 0)
		return;
	data = QXZB_Buff[index-1];
}

void CQunXianZhengBaManager::GetBoxCfgByIdx(uint8 index,SQunXianZhengBa_Box &data)
{
	uint8 size = sizeof(QXZB_Box)/sizeof(QXZB_Box[0]);
	data.Clear();
	if(index > size || index == 0)
		return;
	data = QXZB_Box[index-1];
}

void CQunXianZhengBaManager::GetRoleCfgByIdx(uint8 index,SQunXianZhengBa_Role &data)
{
	uint8 size = sizeof(QXZB_Role)/sizeof(QXZB_Role[0]);
	data.Clear();
	if(index > size || index == 0)
		return;
	data = QXZB_Role[index-1];
}

void CQunXianZhengBaManager::SendPaiHangAward()
{
#ifdef KUA_FU
	const uint32 USER_NUM = 30;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(m_floorRank.empty())
		return;
	SQunXianSortRank sortFun;
	std::sort(m_floorRank.begin(),m_floorRank.end(),sortFun);

	char buf[512];
	SMailData mdata;
	SendLongQuerySqlToAllDB("delete from level_rank where id>30100 and id<=30150");
	for(uint32 i=0;i < m_floorRank.size() && i < USER_NUM;i++)
	{
		int rank = i+1;
		if(rank == 1)
			mdata.bdYB = 300;
		else if(rank >= 2 && rank <= 5)
			mdata.bdYB = 250;
		else if(rank >= 6 && rank <= 10)
			mdata.bdYB = 200;
		else
			mdata.bdYB = 100;
		snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0111,rank);
		SendSystemMail(m_floorRank[i].roleId,buf,&mdata);
		if(rank <= (int)USER_NUM)
		{
			snprintf(buf,sizeof(buf)-1,"insert into level_rank(id,role_id,role_name,rank,type,data,xiang) values(%d,%u,'%s',%u,603,%d,%d)",
				30100+rank,m_floorRank[i].roleId,m_floorRank[i].name.c_str(),i+1,m_floorRank[i].floor,(int)m_floorRank[i].xiang);
			SendLongQuerySqlToAllDB(buf);
		}
	}
#endif
}

void CQunXianZhengBaManager::Timer()
{
	int hour = GetHour();
	{
		static int lastHour = 0xff;
		int size = 0;
		{
			boost::recursive_mutex::scoped_lock lk(m_mutex);
			size = m_rankList.size();
		}
		if(size <= OPEN_ROLE_NUM)
		{
			if(lastHour != hour)
			{
				lastHour = hour;
				LoadRankData();
			}
			return;
		}
	}
	
	int weekday = GetWeekDay();
	static bool reload = true;
	if(weekday == 1 && hour == 5 && reload)
	{
		reload = false;
		LoadRankData();
	}
	if(hour == 0)
	{
		reload = true;
	}

	static int day = 0;
	int curDay = GetDay();
	if(curDay > 0)
	{
		if(day == 0)
			day = curDay;
		if(day != curDay)
		{
			day = curDay;
			SendPaiHangAward();
		}
	}
}

bool CQunXianZhengBaManager::LoadRankData()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return false;
	//                  0   1   2      3       4
	if(pDb->Query("select id,name,sex,zhanDouLi,bank_item from role_info order by zhanDouLi desc limit 10000"))
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		m_rankList.clear();
		m_roleIdMap.clear();

		char **row = NULL;
		CUser user;
		SQunXianPowerPaiHang temp;
		int idx = 0;
		while((row = pDb->GetRow()) != NULL)
		{
			temp.roleId = atoi(row[0]);
			temp.name = row[1];
			temp.sex = atoi(row[2]);
			temp.zhandouli = atoi(row[3]);
			
			user.SetExtData32(13,0);
			user.SetBankItem(row[4]);
			temp.vipLv = ::GetVipLevel(user.GetChongzhiTotal() + user.GetExVipExp());
			m_rankList.push_back(temp);
			m_roleIdMap.insert(std::make_pair(temp.roleId,idx));
			idx++;
		}
		return true;
	}
	return false;
}

bool CQunXianZhengBaManager::ReadData()
{
	if(!LoadRankData())
		return false;
	if(!InitPaiHang())
		return false;
	return true;
}

bool CQunXianZhengBaManager::InitPaiHang()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return false;
	//                        0     1    2       3       4
	if(pDb->Query("select role_id,name,xiang,server_id,floor from qunxian_paihang order by id asc"))
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		m_floorRank.clear();

		char **row = NULL;
		SQunXianFloorPaiHang temp;
		while((row = pDb->GetRow()) != NULL)
		{
			temp.roleId = atoi(row[0]);
			temp.name = row[1];
			temp.xiang = atoi(row[2]);
			temp.serverId = atoi(row[3]);
			temp.floor = atoi(row[4]);
			m_floorRank.push_back(temp);
		}
		return true;
	}
	return false;
}

void CQunXianZhengBaManager::SavePaiHang()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;
	if(!pDb->Query("truncate qunxian_paihang"))
		return;

	char buf[256];
	SQunXianSortRank sortFun;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	std::sort(m_floorRank.begin(),m_floorRank.end(),sortFun);
	for(uint32 i=0;i < m_floorRank.size();i++)
	{
		snprintf(buf,sizeof(buf)-1,"insert into qunxian_paihang(role_id,name,xiang,server_id,floor) values(%u,'%s',%d,%d,%d)",
			m_floorRank[i].roleId,m_floorRank[i].name.c_str(),(int)m_floorRank[i].xiang,m_floorRank[i].serverId,m_floorRank[i].floor);
		pDb->Query(buf);
	}
}

bool CQunXianZhengBaManager::IsOpen()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return (m_rankList.size() > (uint32)OPEN_ROLE_NUM ? true : false);
}

void CQunXianZhengBaManager::GetMatchRole(uint8 floor,uint32 &s_role,uint32 &m_role,uint32 &h_role)
{
	s_role = 0;
	m_role = 0;
	h_role = 0;
	if(floor == 0 || floor > MAX_FLOOR)
		return;

	SQunXianZhengBaConig floorCF;
	GetFloorConfig(floor,floorCF);
	if(floorCF.type != 1)
		return;
	SQunXianZhengBa_Role roleCF;
	GetRoleCfgByIdx(floorCF.t_index,roleCF);
	if(roleCF.index != floorCF.t_index)
		return;
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	int size = m_rankList.size();
	if(size <= OPEN_ROLE_NUM)
		return;
	int s_begin = (int)(size*roleCF.s_minPercent/100.0);
	int s_end = (int)(size*roleCF.s_maxPercent/100.0);
	int m_begin = (int)(size*roleCF.m_minPercent/100.0);
	int m_end = (int)(size*roleCF.m_maxPercent/100.0);
	int h_begin = (int)(size*roleCF.h_minPercent/100.0);
	int h_end = (int)(size*roleCF.h_maxPercent/100.0);
	s_begin = (s_begin > size) ? size : ((s_begin == 0) ? 1 : s_begin);
	s_end = (s_end > size) ? size : ((s_end == 0) ? 1 : s_end);
	m_begin = (m_begin > size) ? size : ((m_begin == 0) ? 1 : m_begin);
	m_end = (m_end > size) ? size : ((m_end == 0) ? 1 : m_end);
	h_begin = (h_begin > size) ? size : ((h_begin == 0) ? 1 : h_begin);
	h_end = (h_end > size) ? size : ((h_end == 0) ? 1 : h_end);

	s_role = m_rankList[Random(s_begin,s_end) - 1].roleId;
	m_role = m_rankList[Random(m_begin,m_end) - 1].roleId;
	h_role = m_rankList[Random(h_begin,h_end) - 1].roleId;
}

void CQunXianZhengBaManager::GetRoleDataById(uint32 roleId,SQunXianPowerPaiHang &info)
{
	info.Clear();
	if(roleId <= 0)
		return;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,uint32>::iterator it = m_roleIdMap.find(roleId);
	if(it == m_roleIdMap.end())
		return;
	uint32 pos = it->second;
	if(pos >= m_rankList.size())
		return;
	info = m_rankList[pos];
}

void CQunXianZhengBaManager::UpdateRoleFloor(CUser *pUser,int floor)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(pUser == NULL || floor < 1)
		return;
	uint32 roleId = pUser->GetRoleId();
	int size = m_floorRank.size();
	bool isFind = false;
	for(int i=0;i < size;i++)
	{
		if(m_floorRank[i].roleId == roleId)
		{
			if(m_floorRank[i].floor < floor)
			{
				m_floorRank[i].floor = floor;
				m_sortFlag = true;
				isFind = true;
			}
			break;
		}
	}
	if(!isFind)
	{
		SQunXianFloorPaiHang temp;
		temp.Clear();
		temp.roleId = roleId;
		temp.floor = floor;
		temp.name = pUser->GetName();
		temp.serverId = pUser->GetServerId();
		m_floorRank.push_back(temp);
	}
}

void CQunXianZhengBaManager::MakeRoleFloorHaiHang(CNetMessage &msg)
{
	int num = 0;
	uint16 pos = msg.GetDataLen();
	msg<<num;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(m_floorRank.empty())
		return;
	if(m_sortFlag)
	{
		SQunXianSortRank sortFun;
		std::sort(m_floorRank.begin(),m_floorRank.end(),sortFun);
		m_sortFlag = false;
	}
	for(uint32 i=0;i < SHOW_RANK_NUM && i < m_floorRank.size();i++)
	{
		msg<<i+1<<m_floorRank[i].roleId<<m_floorRank[i].name<<m_floorRank[i].floor;
		num++;
	}
	msg.WriteData(pos,&num,sizeof(num));
}


void CHuoDongAwardManager::GetChouInfo(map<uint32,HDChouInfo> &chouInfo,uint32 time)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	
	map<uint32, map<uint32,HDChouInfo> >::iterator it = m_chou_info.find(time);
	if (it != m_chou_info.end())
	{
		chouInfo = it->second;
	}
}

void CHuoDongAwardManager::SetChouInfo(HDChouInfo &chouInfo,uint32 time)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	
	map<uint32, map<uint32,HDChouInfo> >::iterator it = m_chou_info.find(time);
	if (it != m_chou_info.end())
	{
		m_chou_info.erase(it);
		map<uint32,HDChouInfo> mapChouInfo;
		mapChouInfo.insert(make_pair(chouInfo.role_id,chouInfo));
		m_chou_info.insert(make_pair(time,mapChouInfo));
	}
}

bool CHuoDongAwardManager::GetChouAwardInfo(uint32 &costId,int &costNum,uint32 &awardId,int &awardNum,string &errStr)
{
	uint32 huodongType = CHuoDongAwardManager::DUOBAO_CHOU;

	uint32 idx = 0;
	uint32 curHour = GetSysHour();
	idx = GetAwardIdx(huodongType,CHOU_JIANG_COST_IDX2,CHOU_JIANG_COST_IDX3);
	if (idx == 0)
	{
		errStr = LANGUAGE_LLD_0102;
		return false;
	}

	// cost
	SHuoDongAward awardList;
	GetAwardData(huodongType,idx,awardList);
	for(uint8 i=0;i < SHuoDongAward::AWARD_NUM;i++)
	{
		if (awardList.award[i] != 0)
		{
			costId = awardList.award[i];
			costNum = awardList.num[i];
			break;
		}
	}
	
	if (costId == 0)
	{
		errStr = LANGUAGE_LLD_0104;
		return false;
	}

	// award
	vector<HDPeiZhiInfo> peizhiInfo;
	GetPeiZhiInfo(peizhiInfo,huodongType);
	if (peizhiInfo.size() <= 0)
	{
		errStr = LANGUAGE_LLD_0103;
		return false;
	}

	uint32 idx2 = 0;
	for (uint32 i = 0; i < peizhiInfo.size(); i++)
	{
		if (peizhiInfo[i].cd == curHour)
		{
			idx2 = peizhiInfo[i].index;
			break;
		}
	}

	if (idx2 == 0)
	{
		errStr = LANGUAGE_LLD_0105;
		return false;
	}

	idx = GetAwardIdx(huodongType,idx2,CHuoDongAwardManager::CHOU_AWARD);
	GetAwardData(huodongType,idx,awardList);
	for(uint8 i=0;i < SHuoDongAward::AWARD_NUM;i++)
	{
		if (awardList.award[i] != 0)
		{
			awardId = awardList.award[i];
			awardNum = awardList.num[i];
			break;
		}
	}

	if (awardId == 0)
	{
		errStr = LANGUAGE_LLD_0104;
		return false;
	}
	return true;
}


void CHuoDongAwardManager::HDChouSendAward(uint32 time,uint32 curHour)
{
	uint32 role_id = 0;
	uint32 huodongType = DUOBAO_CHOU;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		map<uint32, vector<uint32> >::iterator itChouList = m_chou_list.find(time);
		if (itChouList != m_chou_list.end() && itChouList->second.size() > 0)
		{
			int ranNum = Random(1,itChouList->second.size());
			role_id = itChouList->second[ranNum - 1];
			m_chou_list.erase(itChouList);
		}	
	}
	
	if (role_id == 0)
		return;

	vector<HDPeiZhiInfo> peizhiInfo;
	GetPeiZhiInfo(peizhiInfo,huodongType);
	if (peizhiInfo.size() <= 0)
		return;

	uint32 idx2 = 0;
	for (uint32 i = 0; i < peizhiInfo.size(); i++)
	{
		if (peizhiInfo[i].cd == curHour)
		{
			idx2 = peizhiInfo[i].index;
			break;
		}
	}

	if (idx2 == 0)
		return;

	SHuoDongAward awardList,awardList2;
	GetAwardData(huodongType,GetAwardIdx(DUOBAO_CHOU,idx2,CHOU_AWARD),awardList);
	GetAwardData(huodongType,GetAwardIdx(DUOBAO_CHOU,idx2,CHOU_AWARD2),awardList2);

	map<uint32,HDChouInfo> chouInfo;
	GetChouInfo(chouInfo,time);
	for (map<uint32,HDChouInfo>::iterator it = chouInfo.begin(); it != chouInfo.end(); it++)
	{
		if (it->second.award == CHOU_AWARD_NONE)
		{
			if (it->second.role_id == role_id)
			{
				it->second.award = CHOU_AWARD;
				SetChouInfo(it->second,time);
				SendHuoDongAwardMail(it->second.role_id, it->second.level, awardList,LANGUAGE_LLD_0094,huodongType);
			}
			else
				SendHuoDongAwardMail(it->second.role_id, it->second.level, awardList2, LANGUAGE_LLD_0093,huodongType);
		}
	}
	
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char sql[512];
	if(pDb == NULL)
		return;

	snprintf(sql, sizeof(sql), "update hd_chou_record set award = %d where UNIX_TIMESTAMP(time) >= %d and UNIX_TIMESTAMP(time) < %d",CHOU_AWARD2,time,time + 3600);
	if(!pDb->Query(sql))
		return;

	snprintf(sql, sizeof(sql), "update hd_chou_record set award = %d where role_id = %d and UNIX_TIMESTAMP(time) >= %d and UNIX_TIMESTAMP(time) < %d",CHOU_AWARD,role_id,time,time + 3600);
	if(!pDb->Query(sql))
		return;
}


void CHuoDongAwardManager::HDChouTimer()
{
	static uint32 lastTime = 0;
	uint32 time = GetSysTime() / 3600 * 3600;
	uint32 curMin = GetSysMinute();
	uint32 curHour = GetSysHour();
	uint8 state = GetChouState(curMin);

	if (state != CHOU_END && time != lastTime)
		return;

	HDChouSendAward(time,curHour);
	lastTime = time;
}

void CHuoDongAwardManager::SetMoGuAwardDay(uint32 type,uint32 sTime, uint32 eTime,uint32 waterDay,uint32 &moguDay)
{
	if(type != MOGU)
		return;
	if(sTime == 0 || eTime == 0)
		return;
	time_t start = sTime;
	time_t end = eTime;
	struct tm *pStart = localtime(&start);
	struct tm sTM = *pStart;
	sTM.tm_sec = 0;
	sTM.tm_min = 0;
	sTM.tm_hour = 0;
	time_t s = mktime(&sTM);
	struct tm *pEnd = localtime(&end);
	struct tm eTM = *pEnd;
	eTM.tm_sec = 0;
	eTM.tm_min = 0;
	eTM.tm_hour = 0;
	time_t e = mktime(&eTM);
	uint32 dt = e - s;
	moguDay = dt/(24*3600) + 1;
	if(moguDay > waterDay)
		moguDay -= waterDay;
	else
		moguDay = 0;
}

uint32 CHuoDongAwardManager::GetMoGuWaterDay()
{
	const uint32 type = MOGU;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,SHuoDongInfo>::iterator it = m_info.find(type);
	if(it != m_info.end())
		return it->second.day;
	return 0;
}

uint32 CHuoDongAwardManager::GetMoGuAwardDay()
{
	const uint32 type = MOGU;
	uint32 day = 0;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,SHuoDongInfo>::iterator it = m_info.find(type);
	if(it != m_info.end())
		day = it->second.moguAwardDay;
	return day;
}

uint32 CHuoDongAwardManager::GetMoGuWaterCZ()
{
	const uint32 type = MOGU;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,vector<HDPeiZhiInfo> >::iterator it = m_peizhi_info.find(type);
	if(it != m_peizhi_info.end())
	{
		vector<HDPeiZhiInfo> vecInfo = it->second;
		if(!vecInfo.empty())
			return vecInfo[0].water_cz;
	}
	return 0;
}

uint32 CHuoDongAwardManager::GetMoGuBugCZ()
{
	const uint32 type = MOGU;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,vector<HDPeiZhiInfo> >::iterator it = m_peizhi_info.find(type);
	if(it != m_peizhi_info.end())
	{
		vector<HDPeiZhiInfo> vecInfo = it->second;
		if(!vecInfo.empty())
			return vecInfo[0].bug_cz;
	}
	return 0;
}

uint32 CHuoDongAwardManager::GetMoGuStep1CZ()
{
	const uint32 type = MOGU;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,vector<HDPeiZhiInfo> >::iterator it = m_peizhi_info.find(type);
	if(it != m_peizhi_info.end())
	{
		vector<HDPeiZhiInfo> vecInfo = it->second;
		if(!vecInfo.empty())
			return vecInfo[0].step1_cz;
	}
	return 0;
}

uint32 CHuoDongAwardManager::GetMoGuStep2CZ()
{
	const uint32 type = MOGU;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,vector<HDPeiZhiInfo> >::iterator it = m_peizhi_info.find(type);
	if(it != m_peizhi_info.end())
	{
		vector<HDPeiZhiInfo> vecInfo = it->second;
		if(!vecInfo.empty())
			return vecInfo[0].step2_cz;
	}
	return 0;
}


// 0:不在夺宝抽活动内 1:抽奖活动开始但是还不到投注时间 2:投注中 2:抽奖结束
uint8 CHuoDongAwardManager::GetChouState(uint32 curMin)
{
	if (!InHuoDongTime(DUOBAO_CHOU))
		return CHOU_NOT_START;

	if (!InHuoDongHour(DUOBAO_CHOU))
		return CHOU_START;

	if (curMin < CHOU_MIN)
		return CHOU_DOING;
	else
		return CHOU_END;
}


uint32 CHuoDongAwardManager::GetChouCount(uint32 time,uint32 role_id)
{
	int count = 0;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32, map<uint32,HDChouInfo> >::iterator it = m_chou_info.find(time);
	if (it != m_chou_info.end())
	{
		map<uint32,HDChouInfo>::iterator itChouInfo = it->second.find(role_id);
		if (itChouInfo != it->second.end())
		{
			return itChouInfo->second.count;
		}
	}
	
	return count;
}

string CHuoDongAwardManager::GetChouWinPlayName(uint32 time)
{
	string name;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32, map<uint32,HDChouInfo> >::iterator it = m_chou_info.find(time);
	if (it != m_chou_info.end())
	{
		map<uint32,HDChouInfo>::iterator itChouInfo;
		for (itChouInfo = it->second.begin(); itChouInfo != it->second.end(); itChouInfo++)
		{
			if (itChouInfo->second.award == CHOU_AWARD)
			{
				name =  itChouInfo->second.role_name;
				break;
			}
		}
	}
	
	return name;
}

bool CHuoDongAwardManager::HDBetChou(CUser *pUser,uint32 curTime)
{
	if (pUser == NULL)
		return false;

	uint32 role_id = pUser->GetRoleId();
	string role_name = pUser->GetName();
	uint32 level = pUser->GetLevel();
	uint32 time = curTime / 3600 * 3600;

	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char sql[512];
	if(pDb == NULL)
		return false;

	snprintf(sql, sizeof(sql), "insert hd_chou_record (role_id,role_name,level,time) values ('%d','%s','%d',from_unixtime(%d))",role_id,role_name.c_str(),level,curTime);
	if(!pDb->Query(sql))
		return false;


	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32, map<uint32,HDChouInfo> >::iterator it = m_chou_info.find(time);
	if (it != m_chou_info.end())
	{
		map<uint32,HDChouInfo> &chouInfo = it->second;
		map<uint32,HDChouInfo>::iterator itInfo = chouInfo.find(role_id);
		if(itInfo != chouInfo.end())
		{
			itInfo->second.count++;
		}
		else
		{
			map<uint32,HDChouInfo> mapInfo;
			HDChouInfo info;
			info.role_id = role_id;
			info.role_name = role_name;
			info.count = 1;
			info.level = level;
			chouInfo.insert(make_pair(role_id,info));
		}
	}
	else
	{
		map<uint32,HDChouInfo> mapInfo;
		HDChouInfo info;
		info.role_id = role_id;
		info.role_name = role_name;
		info.count = 1;
		info.level = level;
		mapInfo.insert(make_pair(role_id,info));
		m_chou_info.insert(make_pair(time, mapInfo));
	}

	map<uint32, vector<uint32> >::iterator itChouList = m_chou_list.find(time);
	if (itChouList != m_chou_list.end())
	{
		itChouList->second.push_back(role_id);
	}
	else
	{
		vector<uint32> roleIds;
		roleIds.push_back(role_id);
		m_chou_list.insert(make_pair(time,roleIds));
	}

	return true;
}

CJiaoYiHangManager::CJiaoYiHangManager()
{
	m_jiaoyiGoldYuZhi = 0;
}

CJiaoYiHangManager::~CJiaoYiHangManager()
{
}

bool CJiaoYiHangManager::Init()
{
	if (!InitJiaoYiInfo())
		return false;

	if (!InitJiaoYiGoldYuZhi())
		return false;
	
	return true;
}

bool CJiaoYiHangManager::InitJiaoYiInfo()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char **row = NULL;
	char sql[512];
	if(pDb == NULL)
		return false;
	//									0      1                  2          3       4        5  			6
	snprintf(sql, sizeof(sql), "select id,unix_timestamp(time),seller_id,sell_yb,buy_gold,already_sell_yb,seller_name from jiaoyi_info where sell_yb > already_sell_yb and state = 0 order by time asc");
	if(!pDb->Query(sql))
		return false;

	int num = pDb->GetRowNum();
	if(num > 0)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);

		m_jiaoyiInfo.clear();

		while((row = pDb->GetRow()) != NULL)
		{
			JiaoYiInfo info;
			info.id = (int)atoi(row[0]);
			info.time = (uint32)atoi(row[1]);
			info.seller_id = (uint32)atoi(row[2]);
			info.seller_name = row[6];
			info.sell_yb = (int)atoi(row[3]);
			info.buy_gold = (int)atoi(row[4]);
			info.already_sell_yb = (int)atoi(row[5]);

			NoLockInsertJiaoYiInfo(info);
			NoLockAddJiaoYiSellCount(info.seller_id);
		}
	}
	//		Print();
	return true;
}

bool CJiaoYiHangManager::InitJiaoYiGoldYuZhi()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char **row = NULL;
	char sql[512];
	if(pDb == NULL)
		return false;
	//								    0    
	snprintf(sql, sizeof(sql), "select gold,unix_timestamp(time),id from jiaoyi_gold_yuzhi order by id desc limit 1");
	if(!pDb->Query(sql))
		return false;

	int num = pDb->GetRowNum();
	if(num > 0)
	{
		if ((row = pDb->GetRow()) != NULL)
		{
			int id = (int)atoi(row[2]);
			int goldYuZhi = (int)atoi(row[0]);
			uint32 goldYuZhiTime = (uint32)atoi(row[1]);

			{
				boost::recursive_mutex::scoped_lock lk(m_mutex);
				m_jiaoyiGoldYuZhi = goldYuZhi;
				m_jiaoyiGoldYuZhiTime = goldYuZhiTime;
			}

			if ((id != 1) && (CurlZeroTime(GetSysTime()) != goldYuZhiTime))
			{
				CalJiaoYiGoldYuZhi();
			}

			return true;
		}
	}
	return false;
}

void CJiaoYiHangManager::Timer()
{
	OverTimeJiaoYiInfo();

	static bool clearFlag = true;
	int h = GetHour();
	if(h == 0 && clearFlag)
	{
		clearFlag = false;

		CalJiaoYiGoldYuZhi();
	}
	else if(h != 0 && !clearFlag)
	{
		clearFlag = true;
	}
}

void CJiaoYiHangManager::OverTimeJiaoYiInfo()
{
	uint32 curTime = GetSysTime();
	if (curTime == 0)
		return;

	//vector<JiaoYiInfo> infos;
	//{
	//	boost::recursive_mutex::scoped_lock lk(m_mutex);
	//	list<JiaoYiInfo>::iterator it = m_jiaoyiInfo.begin();
	//	for (;it != m_jiaoyiInfo.end();)
	//	{
	//		if ((MAX_TIME + it->time) < curTime)
	//		{
	//			infos.push_back(*it);		
	//			NoLockDelJiaoYiSellCount(it->seller_id);
	//			it = m_jiaoyiInfo.erase(it);
	//		}
	//		else
	//		{
	//			break;
	//		}
	//	}
	//}

	//for (uint32 i = 0; i < infos.size(); i++)
	//{
	//	UpdateJiaoYiInfo(infos[i].id,infos[i].already_sell_yb,true);
	//	AddJiaoYiRecord(infos[i],0,"",0,0,OVER_TIME);

	//	SMailData mdata;
	//	char buff[512];
	//	
	//	mdata.YB = infos[i].sell_yb - infos[i].already_sell_yb;
	//	snprintf(buff,sizeof(buff),LANGUAGE_LLD_0117,mdata.YB);
	//	SendSystemMail(infos[i].seller_id,buff,&mdata);
	//}
}

void CJiaoYiHangManager::CalJiaoYiGoldYuZhi()
{
	uint32 curTime = GetSysTime();
	uint32 curTimeZero = CurlZeroTime(curTime);

	if (curTime == 0 || curTimeZero == m_jiaoyiGoldYuZhiTime)
		return;

	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char **row = NULL;
	char sql[512];
	if(pDb == NULL)
		return;
	//									    0    
	snprintf(sql, sizeof(sql), "select ifnull(sum(buy_gold),0),ifnull(sum(sell_yb),0) from jiaoyi_record where state = %d and unix_timestamp(time) >= %d and unix_timestamp(time) <= %d",SELL,curTimeZero - MAX_TIME,curTimeZero);
	if(!pDb->Query(sql))
		return;

	int goldSum = 0;
	int ybSum = 0;
	int goldYuZhi = MIN_GOLD_YUZHI;
	int num = pDb->GetRowNum();
	if(num > 0)
	{
		if ((row = pDb->GetRow()) != NULL)
		{
			goldSum = (int)atoi(row[0]);
			ybSum = (int)atoi(row[1]);

			if (ybSum != 0)
				goldYuZhi = goldSum / ybSum;
			
			if (goldYuZhi < MIN_GOLD_YUZHI)
				goldYuZhi = MIN_GOLD_YUZHI;

			boost::recursive_mutex::scoped_lock lk(m_mutex);
			m_jiaoyiGoldYuZhi = goldYuZhi;
			m_jiaoyiGoldYuZhiTime = curTimeZero;
		}
	}

	snprintf(sql, sizeof(sql), "insert into jiaoyi_gold_yuzhi (gold,time) values (%d,from_unixtime(%d))",goldYuZhi,curTimeZero);
	if(!pDb->Query(sql))
	return;

}


void CJiaoYiHangManager::AddJiaoYiInfo(CUser *pUser,int sell_yb,int buy_gold,CNetMessage &msg)
{
	if (pUser == NULL)
		return;
	if(pUser->GetVipLevel() < 3)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_1003,TIPS_FAILURE_COLOR);
		ShowJiaoYiInfo(msg,pUser->GetRoleId());
		return;
	}

	if (GetJiaoYiSellCount(pUser->GetRoleId()) >= MAX_SELL_COUNT)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0113,TIPS_FAILURE_COLOR);
		ShowJiaoYiInfo(msg,pUser->GetRoleId());
		return;
	}

	if (sell_yb <= 0)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0114,TIPS_FAILURE_COLOR);
		ShowJiaoYiInfo(msg,pUser->GetRoleId());
		return;
	}

	if (pUser->GetTongBao() < sell_yb)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0155,TIPS_FAILURE_COLOR);
		ShowJiaoYiInfo(msg,pUser->GetRoleId());
		return;
	}

	int goldYuZhi = GetJiaoYiGoldYuZhi();
	if (buy_gold > (goldYuZhi * (1 + GOLD_RATIO)) || buy_gold < goldYuZhi * (1 - GOLD_RATIO))
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0115,TIPS_FAILURE_COLOR);
		ShowJiaoYiInfo(msg,pUser->GetRoleId());
		return;
	}
	if(sell_yb * buy_gold > 50000000 || sell_yb > 3333)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_1004,TIPS_FAILURE_COLOR);
		ShowJiaoYiInfo(msg,pUser->GetRoleId());
		return;
	}

	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char sql[512];
	uint32 curTime = GetSysTime();
	if(pDb == NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0083,TIPS_FAILURE_COLOR);
		ShowJiaoYiInfo(msg,pUser->GetRoleId());
		return;
	}
	//									
	snprintf(sql, sizeof(sql), "insert into jiaoyi_info (time,seller_id,seller_name,sell_yb,buy_gold) values (FROM_UNIXTIME(%d),%d,'%s',%d,%d)",
												curTime,pUser->GetRoleId(),pUser->GetName(),sell_yb,buy_gold);
	if(!pDb->Query(sql))
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0083,TIPS_FAILURE_COLOR);
		ShowJiaoYiInfo(msg,pUser->GetRoleId());
		return;
	}

	uint32 id = pDb->InsertId();

	JiaoYiInfo info;
	info.id = id;
	info.time = curTime;
	info.seller_id = pUser->GetRoleId();
	info.seller_name = pUser->GetName();
	info.sell_yb = sell_yb;
	info.buy_gold = buy_gold;
	info.already_sell_yb = 0;

	InsertJiaoYiInfo(info);
	AddJiaoYiSellCount(info.seller_id);
	pUser->AddTongBao(-sell_yb,0,0,false);
	msg<<PRO_SUCCESS<<pUser->GetTongBao()<<pUser->GetMoney();
	ShowJiaoYiInfo(msg,pUser->GetRoleId());
}

void CJiaoYiHangManager::ChannelJiaoYiInfo(CUser *pUser,int id,CNetMessage &msg)
{
	/*bool endSell = true;
	if (pUser == NULL)
		return;

	if (id <= 0)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0122,TIPS_FAILURE_COLOR);
		ShowJiaoYiInfo(msg,pUser->GetRoleId());
		return;
	}

	JiaoYiInfo info;
	bool isFind = false;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		list<JiaoYiInfo>::iterator it = m_jiaoyiInfo.begin();
		for (;it != m_jiaoyiInfo.end();it++)
		{
			if (id == it->id)
			{
				isFind = true;
				info = *it;			
				NoLockDelJiaoYiSellCount(it->seller_id);
				m_jiaoyiInfo.erase(it);
				break;
			}
		}
	}

	if (isFind)
	{
		msg<<PRO_SUCCESS;
		ShowJiaoYiInfo(msg,pUser->GetRoleId());

		UpdateJiaoYiInfo(info.id,info.already_sell_yb,endSell);
		AddJiaoYiRecord(info,0,"",0,0,CHANNEL_SELL);

		SMailData mdata;
		char buff[512];

		mdata.YB = info.sell_yb - info.already_sell_yb;
		snprintf(buff,sizeof(buff),LANGUAGE_LLD_0116,mdata.YB);
		SendSystemMail(info.seller_id,buff,&mdata);
	}
	else
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0124,TIPS_FAILURE_COLOR);
		ShowJiaoYiInfo(msg,pUser->GetRoleId());
	}*/
}


void CJiaoYiHangManager::InsertJiaoYiInfo(JiaoYiInfo &info)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);

	NoLockInsertJiaoYiInfo(info);
}

void CJiaoYiHangManager::NoLockInsertJiaoYiInfo(JiaoYiInfo &info)
{
	m_jiaoyiInfo.push_back(info);
}

void CJiaoYiHangManager::AddJiaoYiSellCount(uint32 role_id)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);

	NoLockAddJiaoYiSellCount(role_id);
}

void CJiaoYiHangManager::NoLockAddJiaoYiSellCount(uint32 role_id)
{
	map<uint32,int>::iterator it = m_jiaoyiSellCount.find(role_id);
	if (it != m_jiaoyiSellCount.end())
	{
		it->second++;
	}
	else
	{
		m_jiaoyiSellCount.insert(make_pair(role_id,1));
	}
}

int CJiaoYiHangManager::GetJiaoYiSellCount(uint32 role_id)
{
	int count = 0;
	boost::recursive_mutex::scoped_lock lk(m_mutex);

	map<uint32,int>::iterator it = m_jiaoyiSellCount.find(role_id);
	if (it != m_jiaoyiSellCount.end())
	{
		count = it->second;
	}

	return count;
}


void CJiaoYiHangManager::NoLockDelJiaoYiSellCount(uint32 role_id)
{
	map<uint32,int>::iterator it = m_jiaoyiSellCount.find(role_id);
	if (it != m_jiaoyiSellCount.end())
	{
		if (it->second > 0)
			it->second--;
	}
}

void CJiaoYiHangManager::ShowJiaoYiInfo(CNetMessage &msg,uint32 role_id)
{
	uint32 num = 0;
	uint16 numPos = 0;

	numPos = msg.GetDataLen();
	msg<<num;

	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		list<JiaoYiInfo>::iterator it = m_jiaoyiInfo.begin();
		for (;it != m_jiaoyiInfo.end();it++)
		{
			if (role_id != 0 && it->seller_id != role_id)
				continue;

			msg<<it->id<<it->time<<(it->sell_yb - it->already_sell_yb)<<it->buy_gold;
			num++;
		}
	}
	msg.WriteData(numPos,&num,sizeof(num));
}

void CJiaoYiHangManager::JiaoYiBuyYB(CUser *pUser,int id,int yb,CNetMessage &msg)
{
	/*if (pUser == NULL)
		return;

	if (id <= 0)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0122,TIPS_FAILURE_COLOR);
		ShowJiaoYiInfo(msg);
		return;
	}

	if (yb <= 0)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0123,TIPS_FAILURE_COLOR);
		ShowJiaoYiInfo(msg);
		return;
	}

	JiaoYiInfo info;
	int poundage = 0;
	int getGold = 0;
	int costGold = 0;
	int sellerId = 0;
	bool isFind = false;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		list<JiaoYiInfo>::iterator it = m_jiaoyiInfo.begin();
		for (;it != m_jiaoyiInfo.end();it++)
		{
			if (id == it->id)
			{
				poundage = yb * it->buy_gold * BUY_GOLD_RATIO;
				getGold = yb * it->buy_gold;
				costGold = getGold + poundage;
				sellerId = it->seller_id;
				if ((it->sell_yb - it->already_sell_yb) < yb)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0120,TIPS_FAILURE_COLOR);
					ShowJiaoYiInfo(msg);
					return;
				}

				if (pUser->GetMoney() < costGold)
				{
					msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0121,TIPS_FAILURE_COLOR);
					ShowJiaoYiInfo(msg);
					return;
				}

				it->already_sell_yb += yb;
				isFind = true;
				info = *it;

				if (it->sell_yb == it->already_sell_yb)
				{
					NoLockDelJiaoYiSellCount(it->seller_id);
					m_jiaoyiInfo.erase(it);
				}
				break;
			}
		}
	}

	if (isFind && sellerId != 0)
	{
		pUser->AddMoney(-costGold);
		UpdateJiaoYiInfo(info.id,info.already_sell_yb,info.sell_yb == info.already_sell_yb);
		AddJiaoYiRecord(info,pUser->GetRoleId(),pUser->GetName(),yb,getGold,SELL,poundage);
		SysInfo(pUser,LANGUAGE_LLD_0156);

		{
			SMailData mdata;
			mdata.YB = yb;
			string buff = CreateJiaoYiRecord(pUser->GetName(),yb,getGold,CJiaoYiHangManager::BUY);
			SendSystemMail(pUser->GetRoleId(),buff.c_str(),&mdata);
		}

		{
			SMailData mdata;
			mdata.money = getGold;
			string buff = CreateJiaoYiRecord(pUser->GetName(),yb,getGold,CJiaoYiHangManager::SELL);
			SendSystemMail(sellerId,buff.c_str(),&mdata);
		}

		msg<<PRO_SUCCESS<<pUser->GetTongBao()<<pUser->GetMoney();
		ShowJiaoYiInfo(msg);
	}
	else
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0124,TIPS_FAILURE_COLOR);
		ShowJiaoYiInfo(msg);
	}*/
}


void CJiaoYiHangManager::UpdateJiaoYiInfo(int id,int already_sell_yb,bool end)
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char sql[512];
	if(pDb == NULL)
		return;
	snprintf(sql, sizeof(sql), "update jiaoyi_info set already_sell_yb = %d,state = %d where id = %d",already_sell_yb,end?1:0,id);
	if(!pDb->Query(sql))
		return;
}

void CJiaoYiHangManager::AddJiaoYiRecord(JiaoYiInfo &info,uint32 buyer_id,string buyer_name,int buy_yb,int buy_gold,uint32 state,int poundage)
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char sql[512];
	uint32 curTime = GetSysTime();
	if(pDb == NULL)
		return;

	if (state == SELL)
	{
		snprintf(sql, sizeof(sql), "insert into jiaoyi_record (seller_id,seller_name,buyer_id,buyer_name,sell_yb,buy_gold,time,state,poundage) values (%d,'%s',%d,'%s',%d,%d,from_unixtime(%d),%d,%d)",
									info.seller_id,info.seller_name.c_str(),buyer_id,buyer_name.c_str(),buy_yb,buy_gold,curTime,state,poundage);
	}
	else
	{
		snprintf(sql, sizeof(sql), "insert into jiaoyi_record (seller_id,seller_name,buyer_id,buyer_name,sell_yb,buy_gold,time,state,poundage) values (%d,'%s',%d,'%s',%d,%d,from_unixtime(%d),%d,%d)",
									info.seller_id,info.seller_name.c_str(),0,"",info.sell_yb - info.already_sell_yb,0,curTime,state,poundage);
	}
	
	if(!pDb->Query(sql))
		return;

	HdShowHistoryNode record;
	record.time = curTime;

	ShareUserPtr pUSeller = SingletonOnlineUser::instance().GetUserByRoleId(info.seller_id);
	CUser *pSeller = pUSeller.get();
	if(pSeller != NULL)
	{
		if (state == SELL)
			record.data = CreateJiaoYiRecord(buyer_name,buy_yb,buy_gold,state);
		else
			record.data = CreateJiaoYiRecord(buyer_name,info.sell_yb - info.already_sell_yb,0,state);
		
		pSeller->AddJiaoYiHangRecord(record,SELL_RECORD);
	}

	ShareUserPtr pUBuyer = SingletonOnlineUser::instance().GetUserByRoleId(buyer_id);
	CUser *pBuyer = pUBuyer.get();
	if(state == SELL && pBuyer != NULL)
	{
		record.data = CreateJiaoYiRecord(buyer_name,buy_yb,buy_gold,BUY);
		pBuyer->AddJiaoYiHangRecord(record,BUY_RECORD);
	}

}

int CJiaoYiHangManager::GetJiaoYiGoldYuZhi()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);

	return m_jiaoyiGoldYuZhi;
}

CFunctionSwitchManager::CFunctionSwitchManager()
{
}

CFunctionSwitchManager::~CFunctionSwitchManager()
{
}

bool CFunctionSwitchManager::Init()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	char **row = NULL;
	char sql[512];
	if(pDb == NULL)
		return false;
	//								    0               1
	snprintf(sql, sizeof(sql), "select function_type,switch_state from function_switch");
	if(!pDb->Query(sql))
		return false;

	int num = pDb->GetRowNum();
	if(num > 0)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);

		m_function_switch.clear();

		while((row = pDb->GetRow()) != NULL)
		{
			uint32 function_type = (uint32)atoi(row[0]);
			uint32 switch_state = (uint32)atoi(row[1]);
			m_function_switch.insert(make_pair(function_type,switch_state));
		}
		return true;
	}
	//		Print();

	return false;
}

void CFunctionSwitchManager::Timer()
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
		Init();
	}
}

bool CFunctionSwitchManager::IsFunctionSwitchActivity(uint32 function_type)
{
	map<uint32,uint32>::iterator it = m_function_switch.find(function_type);
	if (it != m_function_switch.end() && it->second == ACTIVITY)
	{
		return true;
	}

	return false;
}

void CHuoDongAwardManager::SetChristmasTreeStr(string &save_data)
{
	uint32 len = 1024;
	uint8 *p = new uint8[len];
	boost::scoped_array<uint8> autoDel(p);
	uint32 hd_type = SHENGDAN_FENGSHOU;

	if ((!InHuoDongTime(hd_type)) || (!GetHuoDongPic(hd_type) == CHRISTMAS_TREE_ID))
		return;
	
	if(!UnCompress(save_data.c_str(),p,len))
	{
		return;
	}
	
	CNetMessage msg;
	msg.WriteData(p,len);
	
	uint32 christmas_starttime = 0;
	msg>>christmas_starttime;

	uint32 christmas_changzhangzhi = 0;
	msg>>christmas_changzhangzhi;

	uint32 start_time = GetHuoDongStartTime(hd_type);
	
	if (start_time != christmas_starttime)
	{
		christmas_starttime = start_time;
		christmas_changzhangzhi = 0;
	}

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_christmas_starttime = christmas_starttime;
	m_christmas_changzhangzhi = christmas_changzhangzhi;	
}

void CHuoDongAwardManager::GetChristmasTreeStr(string &str)
{
	CNetMessage msg;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		msg << m_christmas_starttime;
		msg << m_christmas_changzhangzhi;
	}

	if(!Compress((uint8*)(msg.GetMsgData()->c_str() + CNetMessage::GetHeadLen()),msg.GetDataLenExceptHead(), str))
		str.clear();
}

void CHuoDongAwardManager::SetZhenYingPKStr(string &save_data)
{
	uint32 len = 1024;
	uint8 *p = new uint8[len];
	boost::scoped_array<uint8> autoDel(p);
	uint32 hd_type = ZHENYING_PK;

	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		m_zhenyingPK_socre.clear();
	}

	if (!InHuoDongTime(hd_type))
		return;
	
	if(!UnCompress(save_data.c_str(),p,len))
	{
		return;
	}
	
	CNetMessage msg;
	msg.WriteData(p,len);

	uint32 zhenyingStartTime = 0;
	msg>>zhenyingStartTime;

	if (zhenyingStartTime != GetHuoDongStartTime(ZHENYING_PK))
		return;

	uint32 timeNum = 0;
	msg>>timeNum;

	for (uint32 i = 0; i < timeNum; i++)
	{
		uint32 time = 0;
		uint32 num = 0;
		
		msg>>time;
		msg>>num;

		map<uint32,struct ZhenYingScoreInfo> score_info;
		for (uint32 j = 0; j < num; j++)
		{
			struct ZhenYingScoreInfo  info;
			uint32 zhenYingType = 0;
			
			msg>>zhenYingType;
			msg>>info.score;
			msg>>info.time;

			score_info.insert(make_pair(zhenYingType,info));
		}
		m_zhenyingPK_socre.insert(make_pair(time,score_info));
	}
}

void CHuoDongAwardManager::GetZhenYingPKStr(string &str)
{
	CNetMessage msg;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		map<uint32,map<uint32,struct ZhenYingScoreInfo> >::iterator iter;

		if (!InHuoDongTime(ZHENYING_PK))
			return;

		msg<<GetHuoDongStartTime(ZHENYING_PK);

		uint16 timePos = msg.GetDataLen();
		uint32 timeNum = 0;
		msg<<timeNum;

		for(iter=m_zhenyingPK_socre.begin();iter!=m_zhenyingPK_socre.end();iter++)
		{
			msg << iter->first;
			timeNum++;

			uint16 infoNumPos = msg.GetDataLen();
			uint32 num = 0;
			msg<<num;

			map<uint32,struct ZhenYingScoreInfo>::iterator iterInfo;
			for(iterInfo=iter->second.begin();iterInfo!=iter->second.end();iterInfo++)
			{
			
				msg << iterInfo->first;
				msg << iterInfo->second.score;
				msg << iterInfo->second.time;
				num++;
			}
				
			msg.WriteData(infoNumPos,&num,sizeof(num));
		}

		msg.WriteData(timePos,&timeNum,sizeof(timeNum));
	}

	if(!Compress((uint8*)(msg.GetMsgData()->c_str() + CNetMessage::GetHeadLen()),msg.GetDataLenExceptHead(), str))
		str.clear();
}

uint32 CHuoDongAwardManager::GetChristmasStartTime()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return m_christmas_starttime;
}

void CHuoDongAwardManager::SetChristmasStartTime(uint32 time)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_christmas_starttime = time;
}

uint32 CHuoDongAwardManager::GetChristmasChengZhangZhi()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return m_christmas_changzhangzhi;
}

void CHuoDongAwardManager::AddChristmasChengZhangZhi(uint32 value)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_christmas_changzhangzhi += value;
}

void CHuoDongAwardManager::ClearChristmasInfo()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_christmas_starttime = 0;
	m_christmas_changzhangzhi = 0;
}


bool CHuoDongAwardManager::HDPaiHangCompare(struct HDPaiHangRecordInfo &a,struct HDPaiHangRecordInfo &b,uint32 hd_type)  
{
	if (hd_type == XIANSHI_CHOU)
	{
		if (a.data != b.data)
			return a.data < b.data;
		else if (a.role_lv != b.role_lv)
			return a.role_lv < b.role_lv;
		else if (a.role_zhandouli != b.role_zhandouli)
			return a.role_zhandouli < b.role_zhandouli;

		return a.role_id < b.role_id;
	}
	else
	{
		if (a.data != b.data)
			return a.data < b.data;

		return a.time > b.time;
	}

	return false;
}  

uint32 CHuoDongAwardManager::GetZhenYingScore(uint32 zhenYingType)
{
	uint32 time = GetHuoDongStartTime(zhenYingType);
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);

	map<uint32,map<uint32,struct ZhenYingScoreInfo> >::iterator it = m_zhenyingPK_socre.find(time);
	if (it != m_zhenyingPK_socre.end())
	{
		map<uint32,struct ZhenYingScoreInfo> &score_info = it->second;
		map<uint32,struct ZhenYingScoreInfo>::iterator it_score = score_info.find(zhenYingType);
		if (it_score != score_info.end())
			return it_score->second.score;
	}
	
	return 0;
}

uint32 CHuoDongAwardManager::AddZhenYingScore(uint32 zhenYingType,uint32 score)
{
	if (zhenYingType != ZHENYING_PK1 && zhenYingType != ZHENYING_PK2)
		return 0;

	uint32 time = GetHuoDongStartTime(zhenYingType);

	boost::recursive_mutex::scoped_lock lk(m_mutex);

	map<uint32,map<uint32,struct ZhenYingScoreInfo> >::iterator it = m_zhenyingPK_socre.find(time);
	if (it != m_zhenyingPK_socre.end())
	{
		map<uint32,struct ZhenYingScoreInfo> &score_info = it->second;
		map<uint32,struct ZhenYingScoreInfo>::iterator it_score = score_info.find(zhenYingType);
		if (it_score != score_info.end())
		{
			it_score->second.score = it_score->second.score + score;
			it_score->second.time = GetSysTime();
			return it_score->second.score;
		}
		else
		{
			struct ZhenYingScoreInfo info;
			info.score = score;
			info.time = GetSysTime();
			score_info.insert(make_pair(zhenYingType,info));
			return score;
		}
	}
	else
	{
		struct ZhenYingScoreInfo info;
		info.score = score;
		info.time = GetSysTime();
	
		map<uint32,struct ZhenYingScoreInfo> score_info;
		score_info.insert(make_pair(zhenYingType,info));
		m_zhenyingPK_socre.insert(make_pair(time,score_info));
		return score;
	}
	return 0;
}

struct ZhenYingScoreInfo CHuoDongAwardManager::GetZhenYingScoreInfo(uint32 zhenYingType)
{
	struct ZhenYingScoreInfo info;
	uint32 time = GetHuoDongStartTime(zhenYingType);
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);

	map<uint32,map<uint32,struct ZhenYingScoreInfo> >::iterator it = m_zhenyingPK_socre.find(time);
	if (it != m_zhenyingPK_socre.end())
	{
		map<uint32,struct ZhenYingScoreInfo> &score_info = it->second;
		map<uint32,struct ZhenYingScoreInfo>::iterator it_score = score_info.find(zhenYingType);
		if (it_score != score_info.end())
			info = it_score->second;
	}
	
	return info;
}

uint32 CHuoDongAwardManager::GetZhenYingWinId()
{
	struct ZhenYingScoreInfo info1 = GetZhenYingScoreInfo(ZHENYING_PK1);
	struct ZhenYingScoreInfo info2 = GetZhenYingScoreInfo(ZHENYING_PK2);

	if (info1.score != info2.score)
	{
		if (info1.score > info2.score)
			return ZHENYING_PK1;
		else
			return ZHENYING_PK2;
	}

	if (info1.time != info2.time)
	{
		if (info1.time < info2.time)
			return  ZHENYING_PK1;
		else
			return ZHENYING_PK2;
	}

	return ZHENYING_PK1; // 都相同 阵营1赢
}

uint32 CHuoDongAwardManager::FaBuHongBao(CUser *pUser,HDPeiZhiInfo &info)
{
	uint32 retCount = 0;
	if (pUser == NULL)
		return retCount;

	HDHongBaoInfo hongbaoInfo;
	hongbaoInfo.send_player_info.role_id = pUser->GetRoleId();
	hongbaoInfo.send_player_info.role_name = pUser->GetName();
	hongbaoInfo.send_player_info.sex = pUser->GetSex();
	hongbaoInfo.send_player_info.end_time = GetSysTime() + info.cd;

	hongbaoInfo.yb_random_chi = info.YB - info.count * info.lv;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_hongbao_list.push_front(hongbaoInfo);

	map<uint32,HDHongBaoGetRecord>::iterator it = m_hongbao_record.find(pUser->GetRoleId());
	if (it != m_hongbao_record.end())
	{
		it->second.sendHBCount++;
		retCount = it->second.sendHBCount;
		it->second.isDirty = true;
	}
	else
	{
		HDHongBaoGetRecord getRecord;
		getRecord.roleId = pUser->GetRoleId();
		getRecord.sendHBCount++;
		getRecord.isDirty = true;
		m_hongbao_record.insert(make_pair(pUser->GetRoleId(),getRecord));
		retCount = getRecord.sendHBCount;
	}

	SMailData mdata;
	mdata.AddAward(2957, 0, 5);
	SendSystemMail(pUser->GetRoleId(),LANGUAGE_LLD_0229,&mdata);

	NoLockSetSaveQiangHongBao();
	return retCount;
}

void CHuoDongAwardManager::GetHongBaoList(vector<HDHongBaoInfo> &infos)
{
	infos.clear();
	uint32 curTime = GetSysTime();
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	
	list<HDHongBaoInfo>::iterator it = m_hongbao_list.begin();
	for (;it != m_hongbao_list.end();it++)
	{
		if ((it->send_player_info.end_time) > curTime)
		{
			infos.push_back(*it);
		}
		else
		{
			break;
		}
	}
}

void CHuoDongAwardManager::ClickHongBao(HDPeiZhiInfo &info,uint32 role_id,CUser *pUser,CNetMessage &msg)
{
	if (pUser == NULL)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0222,TIPS_FAILURE_COLOR);
		return;
	}
	uint32 curTime = GetSysTime();
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	list<HDHongBaoInfo>::iterator it = m_hongbao_list.begin();
	for (;it != m_hongbao_list.end();it++)
	{
		if ((it->send_player_info.role_id == role_id))
		{
			if (it->send_player_info.end_time < curTime)
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0223,TIPS_FAILURE_COLOR);
				return;
			}
		
			vector<HDHongBaoPlayerInfo> &get_player_infos = it->get_player_infos;
			bool isGet = false;
			for (uint32 i = 0; i < get_player_infos.size(); i++)
			{
				if (get_player_infos[i].role_id == pUser->GetRoleId())
				{
					isGet = true;
					break;
				}
			}

			uint32 YB = 0;
			uint8 state = 0;
			if (isGet || get_player_infos.size() == info.count)
			{
				if (isGet)
					state = 1; // 已领取
				else
					state = 2; // 已领完
			}
			else
			{
				uint32 randYB = 0;
				if (it->yb_random_chi > 0)
					randYB = Random(0,it->yb_random_chi);

				if (get_player_infos.size() + 1 == info.count)
					randYB = it->yb_random_chi;

				YB = info.lv + randYB;
				it->yb_random_chi -= randYB;
				state = 1; // 已领取

				pUser->AddTongBao(YB);

				char buf[125];
				snprintf(buf,sizeof(buf),"%d",it->send_player_info.role_id);
				SaveDate(pUser->GetRoleId(),QIANG_HONGBAO+500,YB,buf);
				
				HDHongBaoPlayerInfo player_info;
				player_info.role_id = pUser->GetRoleId();
				player_info.role_name = pUser->GetName();
				player_info.sex = pUser->GetSex();
				player_info.yb = YB;
				player_info.end_time = GetSysTime();

				get_player_infos.push_back(player_info);

				if (it->renqi_role_id == 0 && get_player_infos.size() == info.count)
				{
					uint32 maxYB = get_player_infos[0].yb;
					uint32 maxI = 0;
					for (uint32 i = 1;i < get_player_infos.size(); i++)
					{
						if (maxYB < get_player_infos[i].yb)
						{
							maxYB = get_player_infos[i].yb;
							maxI = i;
						}
					}

                    bool haveSame = false;
                    for (uint32 i = 1;i < get_player_infos.size(); i++)
					{
						if (maxYB == get_player_infos[i].yb && maxI != i)
						{
                            haveSame = true;
                            break;
						}
					}

                    if(!haveSame)
                    {
    					it->renqi_role_id = get_player_infos[maxI].role_id;
	    				NoLockAddRenqiRecord(it->renqi_role_id,pUser);
                    }
				}
			}

			if (YB == 0)
			{
				msg<<PRO_SUCCESS<<info.count<<state<<YB<<(uint32)get_player_infos.size();
				for (uint32 i = 0;i < get_player_infos.size(); i++)
				{
					msg<<get_player_infos[i].role_name;
					msg<<get_player_infos[i].yb;
					msg<<get_player_infos[i].end_time;
					msg<<(get_player_infos[i].role_id == it->renqi_role_id ? (uint8)1 : (uint8)0);
				}
			}
			else
			{
				msg<<PRO_SUCCESS<<info.count<<state<<YB<<(uint32)0;
			}
			return;
		}
	}
}

void CHuoDongAwardManager::NoLockAddRenqiRecord(uint32 role_id,CUser *pUser)
{
	map<uint32,HDHongBaoGetRecord>::iterator it = m_hongbao_record.find(role_id);
	if (it != m_hongbao_record.end())
	{
		it->second.renQiKingCount++;
		it->second.isDirty = true;
	}
	else
	{
		HDHongBaoGetRecord getRecord;
		getRecord.roleId = role_id;
		getRecord.renQiKingCount++;
		getRecord.isDirty = true;
		m_hongbao_record.insert(make_pair(role_id,getRecord));
	}

	SMailData mdata;
	mdata.AddAward(2958, 0, 5);
    SendSystemMail(role_id,LANGUAGE_LLD_0228,&mdata);

	NoLockSetSaveQiangHongBao();
}

void CHuoDongAwardManager::GetHDHongBaoRecord(uint32 role_id,HDHongBaoGetRecord &record)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,HDHongBaoGetRecord>::iterator it = m_hongbao_record.find(role_id);
	if (it != m_hongbao_record.end())
	{
		record = it->second;
	}
}

void CHuoDongAwardManager::DelInvalidHongBao()
{
	uint32 curTime = GetSysTime();
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	list<HDHongBaoInfo>::iterator it = m_hongbao_list.begin();
	for (;it != m_hongbao_list.end();)
	{
		if (it->send_player_info.end_time < curTime)
			it = m_hongbao_list.erase(it);
		else
			it++;
	}
}

void CHuoDongAwardManager::SaveQiangHongBaoRecord(bool save)
{
	uint32 curHour = GetSysHour();
	vector<HDHongBaoGetRecord> record;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if (m_save_hb_data && (save || curHour == 2))
		{
			m_save_hb_data = false;
		
			map<uint32,HDHongBaoGetRecord>::iterator iter;

			for(iter=m_hongbao_record.begin(); iter!=m_hongbao_record.end(); iter++)
			{
				if (iter->second.isDirty)
				{
					record.push_back(iter->second);
					iter->second.isDirty = false;
				}
			}
		}
	}
	
	if (record.size() > 0)
	{
		CGetDbConnect getDb;
		CDatabaseSql *pDb = getDb.GetDbConnect();
		if(pDb == NULL)
			return;

		stringstream insertSql;
		insertSql<<"REPLACE into qiang_hongbao_record(role_id,send_hb_count, renqi_king_count) values";
			
		for (uint32 i = 0; i < record.size(); i++)
		{
			if (i == 0)
				insertSql<<"("<<record[i].roleId<<",'"<<record[i].sendHBCount<<"','"<<record[i].renQiKingCount<<"')";
			else
				insertSql<<",("<<record[i].roleId<<",'"<<record[i].sendHBCount<<"','"<<record[i].renQiKingCount<<"')";
		}
		pDb->Query(insertSql.str().c_str());
	}
}

void CHuoDongAwardManager::NoLockSetSaveQiangHongBao()
{
	uint32 curHour = GetSysHour();

	if (curHour != 2)
	{
		m_save_hb_data = true;
	}
}

void CHuoDongAwardManager::GetQiangHongBaoStr(string &str)
{
	uint32 curTime = GetSysTime();
	uint32 hd_type = QIANG_HONGBAO;

	vector<HDPeiZhiInfo> peizhiInfo;
	GetPeiZhiInfo(peizhiInfo,hd_type);
	if (peizhiInfo.size() != 1)
	{
		return;
	}
	
	CNetMessage msg;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);

		if (!InHuoDongTime(hd_type))
			return;

		msg<<GetHuoDongStartTime(hd_type);

		uint16 hongBaoNumPos = msg.GetDataLen();
		uint32 hongBaoNum = 0;
		msg<<hongBaoNum;

		list<HDHongBaoInfo>::iterator it = m_hongbao_list.begin();
		for (;it != m_hongbao_list.end();it++)
		{
			if (it->send_player_info.end_time > curTime)
			{
				if (it->get_player_infos.size() == peizhiInfo[0].count)
					continue;

				msg<<it->send_player_info.role_id;
				msg<<it->send_player_info.role_name;
				msg<<it->send_player_info.sex;
				msg<<it->send_player_info.xiang;
				msg<<it->send_player_info.end_time;
				msg<<it->renqi_role_id;
				msg<<it->yb_random_chi;
				hongBaoNum++;

				vector<HDHongBaoPlayerInfo> &get_player_infos = it->get_player_infos;
				msg<<(uint32)get_player_infos.size();
				for (uint32 i = 0; i < get_player_infos.size(); i++)
				{
				
					msg<<get_player_infos[i].role_id;
					msg<<get_player_infos[i].role_name;
					msg<<get_player_infos[i].sex;
					msg<<get_player_infos[i].xiang;
					msg<<get_player_infos[i].end_time;
					msg<<get_player_infos[i].yb;
				}
			}
			else
				break;
		}
		msg.WriteData(hongBaoNumPos,&hongBaoNum,sizeof(hongBaoNum));
	}

	if(!Compress((uint8*)(msg.GetMsgData()->c_str() + CNetMessage::GetHeadLen()),msg.GetDataLenExceptHead(), str))
		str.clear();
}

void CHuoDongAwardManager::SetQiangHongBaoStr(string &save_data)
{
	uint32 len = 20480;
	uint8 *p = new uint8[len];
	boost::scoped_array<uint8> autoDel(p);
	uint32 hd_type = QIANG_HONGBAO;
	uint32 curTime = GetSysTime();

	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		m_hongbao_list.clear();
	}

	if (!InHuoDongTime(hd_type))
		return;
	
	if(!UnCompress(save_data.c_str(),p,len))
	{
		return;
	}
	
	CNetMessage msg;
	msg.WriteData(p,len);

	uint32 startTime = 0;
	msg>>startTime;

	if (startTime != GetHuoDongStartTime(hd_type))
		return;

	uint32 hongBaoNum = 0;
	msg>>hongBaoNum;

	boost::recursive_mutex::scoped_lock lk(m_mutex);

	for (uint32 i = 0; i < hongBaoNum; i++)
	{
		HDHongBaoInfo info;
		msg>>info.send_player_info.role_id;
		msg>>info.send_player_info.role_name;
		msg>>info.send_player_info.sex;
		msg>>info.send_player_info.xiang;
		msg>>info.send_player_info.end_time;
		msg>>info.renqi_role_id;
		msg>>info.yb_random_chi;

		uint32 getPlayerNum;
		msg>>getPlayerNum;
		for (uint32 j = 0; j < getPlayerNum; j++)
		{
			HDHongBaoPlayerInfo playerInfo;
			msg>>playerInfo.role_id;
			msg>>playerInfo.role_name;
			msg>>playerInfo.sex;
			msg>>playerInfo.xiang;
			msg>>playerInfo.end_time;
			msg>>playerInfo.yb;

			info.get_player_infos.push_back(playerInfo);
		}

		if (info.send_player_info.end_time > curTime)
			m_hongbao_list.push_back(info);
		else
			break;
	}
}

void CHuoDongAwardManager::UpdateHLSY_PaiHangData(int roleId,string name,int jifen)
{
	if(roleId <= 0)
		return;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	bool isFind = false;
	int size = m_hlsy_paihang.size();
	for(int i=0;i < size;i++)
	{
		HuanLeSYPaiHangData &data = m_hlsy_paihang[i];
		if(data.roleId == (uint32)roleId)
		{
			data.roleName = name;
			data.jifen = jifen;
			m_needSort = true;
			isFind = true;
			break;
		}
	}

	if(!isFind)
	{
		HuanLeSYPaiHangData data;
		data.roleId = roleId;
		data.roleName = name;
		data.jifen = jifen;
		m_hlsy_paihang.push_back(data);
		m_needSort = true;
	}
}

bool CHuoDongAwardManager::MakeHLSYPaiHangData(CUser *pUser,CNetMessage &msg,vector<SHuoDongAward> &awardList)
{
	if(pUser == NULL)
		return false;
	const int MAX_SHOW_NUM = 10;
	int size = 0;
	int awardSize = awardList.size();
	if(awardSize < 1)
		return false;
	vector<HuanLeSYPaiHangData> paihang;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		size = m_hlsy_paihang.size();
		if(m_needSort && size > 1)
		{
			SSortHLSY sortFunc;
			std::sort(m_hlsy_paihang.begin(),m_hlsy_paihang.end(),sortFunc);
			m_needSort = false;
			paihang = m_hlsy_paihang;
		}
	}

	uint16 numPos = msg.GetDataLen();
	uint16 roleNum = 0;
	msg<<roleNum;
	for(int i=0;i < size && i < MAX_SHOW_NUM;i++)
	{
		msg<<(i+1)<<paihang[i].roleId<<paihang[i].roleName<<paihang[i].jifen;

		uint16 idx = (i > awardSize-1) ? (awardSize-1) : i;
		uint16 pos = msg.GetDataLen();
		uint8 typeNum = 0;
		msg<<typeNum;
		typeNum = MakeAwardMsg(pUser,awardList[idx],CHuoDongAwardManager::ZHOU_NIAN_QING_1,msg);
		msg.WriteData(pos,&typeNum,sizeof(typeNum));
		roleNum++;
	}
	msg.WriteData(numPos,&roleNum,sizeof(roleNum));
	return true;
}

bool CHuoDongAwardManager::CheckServerOpenInDay(int day)
{
	time_t now = GetSysTime();
	return (now - m_startSec) < 3600 * 24 * day;
}

uint16 CHuoDongAwardManager::ServerOpenDay()
{
	uint32 nextDay = GetTomorrow();
	return ceil((nextDay - m_startSec) / (3600 * 24.0));
}

uint32 CHuoDongAwardManager::ServerOpenZeroTime()
{
	time_t startTime = m_startSec;
	tm* zeroTime = localtime(&startTime);
	zeroTime->tm_hour = 0;
	zeroTime->tm_min = 0;
	zeroTime->tm_sec = 0;
	return mktime(zeroTime);
}

void CHuoDongAwardManager::GetHDSingleAwardMsg(CUser *pUser, int type, CNetMessage& msg)
{
	if (!InHuoDongTime(type))
		return;
	uint32 curTime = GetSysTime();
	uint32 endTime = GetHuoDongEndTime(type);

	vector<HDPeiZhiInfo> peizhi;
	GetPeiZhiInfo(peizhi, type);
	if (peizhi.size() < 1)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_1511, TIPS_FAILURE_COLOR);
		return;
	}
	int bitSetIdx = ZHEKOU_HUODONG_BITSET + type - ZHEKOU_HUODONG1;
	int clearIdx = ZHEKOU_HUODONG_CLEAR + type - ZHEKOU_HUODONG1;
	int clearData = pUser->GetExtData32(clearIdx);
	if (GetSysTime() > clearData)
	{
		pUser->ClearBitSet(bitSetIdx);
		pUser->SetExtData32(clearIdx, endTime);
	}
	uint8 buyState = pUser->HaveBitSet(bitSetIdx) ? 1 : 0;
	SHuoDongAward award;
	GetAwardData(type, 1, award);
	msg << PRO_SUCCESS << endTime - curTime << peizhi[0].YB  << (uint8)peizhi[0].count << award.needYB << buyState << SHuoDongAward::AWARD_NUM;
	for (uint8 i = 0; i < SHuoDongAward::AWARD_NUM; i++)
	{
		msg << (uint32)award.award[i] << (uint16)award.num[i] << (uint16)award.petQuality[i] << (uint16)award.petQualityLv[i];
	}
}

void CHuoDongAwardManager::BuyHDSingleAwardMsg(CUser *pUser, int type, CNetMessage& msg)
{
	if (!InHuoDongTime(type))
		return;
	uint32 endTime = GetHuoDongEndTime(type);
	int bitSetIdx = ZHEKOU_HUODONG_BITSET + type - ZHEKOU_HUODONG1;
	int clearIdx = ZHEKOU_HUODONG_CLEAR + type - ZHEKOU_HUODONG1;
	int clearData = pUser->GetExtData32(clearIdx);
	if (GetSysTime() > clearData)
	{
		pUser->ClearBitSet(bitSetIdx);
		pUser->SetExtData32(clearIdx, endTime);
	}
	uint8 buyState = pUser->HaveBitSet(bitSetIdx) ? 1 : 0;
	if (buyState == 1)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0030, TIPS_FAILURE_COLOR);
		return;
	}

	SHuoDongAward award;
	GetAwardData(type, 1, award);
	if (pUser->GetTongBao() < (int)award.needYB)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_SSJ_0414, TIPS_FAILURE_COLOR);
		SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);
		return;
	}

	pUser->AddTongBao(-award.needYB, 0);
	char buf[128];
	for (uint8 j = 0; j < SHuoDongAward::AWARD_NUM; j++)
	{
		AddHuoDongAward(pUser, type, award.award[j], award.num[j], award.petQuality[j], award.petQualityLv[j]);
		if (award.award[j] == HDAT_PET)
		{
			snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0034, pUser->GetName(), MakePetColorStr(award.num[j]).c_str());
			SysInfoToAllUser(buf);
		}
	}
	snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0074, pUser->GetName());
	SysInfoToAllUser(buf);

	pUser->SetBitSet(bitSetIdx);
	msg << PRO_SUCCESS;
}

void CHuoDongAwardManager::GetXunHuanHDSingleAwardMsg(CUser *pUser, int type, CNetMessage& msg)
{
	if (!InHuoDongTime(type))
		return;
	uint32 idx = GetHuoDongZhouQi(type);
	uint32 clearTime = GetHuoDongLeijiTime(type);
	uint32 curTime = GetSysTime();
	HDPeiZhiInfo peizhi;
	GetPeiZhiInfo(peizhi, type, idx);
	if (peizhi.type == 0)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_1511, TIPS_FAILURE_COLOR);
		return;
	}
	if (peizhi.bug_cz == 0)
		return;
	int hasBitSet = 0;
	int clearIdx = 0;
	switch (type)
	{
	case ROUND_ZHEKOU_HUODONG1:
		hasBitSet = 618;
		clearIdx = 573;
		break;
	case ROUND_ZHEKOU_HUODONG2:
		hasBitSet = 619;
		clearIdx = 574;
		break;
	case ROUND_ZHEKOU_HUODONG3:
		hasBitSet = 620;
		clearIdx = 575;
		break;
	}
	int clearData = pUser->GetExtData32(clearIdx);
	if (pUser->HaveBitSet(hasBitSet) && GetSysTime() > clearData)
	{
		pUser->ClearBitSet(hasBitSet);
		pUser->SetExtData32(clearIdx, 0);}
	uint8 typeNum = 0;
	SHuoDongAward award;
	GetAwardData(type, idx, award);
	msg << PRO_SUCCESS << clearTime - curTime << (uint8)peizhi.water_cz << peizhi.YB << peizhi.price << (uint8)pUser->HaveBitSet(hasBitSet);
	uint16 pos = msg.GetDataLen();
	msg << typeNum;
	typeNum = MakeAwardMsg(pUser, award, type, msg);
	msg.WriteData(pos, &typeNum, sizeof(typeNum));
}

void CHuoDongAwardManager::BuyXunHuanHDSingleAwardMsg(CUser *pUser, int type, CNetMessage& msg)
{
	if (!InHuoDongTime(type))
		return;
	uint32 idx = GetHuoDongZhouQi(type);
	uint32 clearTime = GetHuoDongLeijiTime(type);
	HDPeiZhiInfo peizhi;
	GetPeiZhiInfo(peizhi, type, idx);
	if (peizhi.type == 0)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_1511, TIPS_FAILURE_COLOR);
		return;
	}
	if (peizhi.bug_cz == 0)
		return;
	int hasBitSet = 0;
	int clearIdx = 0;
	switch (type)
	{
	case ROUND_ZHEKOU_HUODONG1:
		hasBitSet = 618;
		clearIdx = 573;
		break;
	case ROUND_ZHEKOU_HUODONG2:
		hasBitSet = 619;
		clearIdx = 574;
		break;
	case ROUND_ZHEKOU_HUODONG3:
		hasBitSet = 620;
		clearIdx = 575;
		break;
	}
	uint32 clearData = pUser->GetExtData32(clearIdx);
	if (pUser->HaveBitSet(hasBitSet) && GetSysTime() > clearData)
	{
		pUser->ClearBitSet(hasBitSet);
		pUser->SetExtData32(clearIdx, 0);
	}
	if (pUser->HaveBitSet(hasBitSet))
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0030, TIPS_FAILURE_COLOR);
		return;
	}

	if (peizhi.water_cz != 2)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_SSJ_0416, TIPS_FAILURE_COLOR);
		return;
	}

	if (peizhi.water_cz == 2 && pUser->GetTongBao() < (int)peizhi.price)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_SSJ_0414, TIPS_FAILURE_COLOR);
		return;
	}

	pUser->AddTongBao(-peizhi.price, 0);
	pUser->SetBitSet(hasBitSet);
	pUser->SetExtData32(clearIdx, clearTime);
	SHuoDongAward award;
	GetAwardData(type, idx, award);
	string name = GetHuoDongName(type);
	char buf[128];
	snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0108, name.c_str());
	SendHuoDongAwardMail(pUser->GetRoleId(), 1, award, buf, type);
	msg << PRO_SUCCESS << MakeStringColor(buf, TIPS_WARNING_COLOR).c_str();
}

int CHuoDongAwardManager::GetHuoDongZhouQi(int type)
{
	int idx = 0;
	int startTime = 0;
	int sysTime = GetSysTime();
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		map<uint32, SHuoDongInfo>::iterator it = m_info.find(type);
		if (it != m_info.end())
		{
			idx = it->second.day;
			startTime = it->second.iStartTime;
		}
	}

	vector<HDPeiZhiInfo> peizhi;
	GetPeiZhiInfo(peizhi, type);
	if (peizhi.empty())
		return 0;
	int nowIdx = (sysTime - startTime) / (24 * 3600);
	idx = nowIdx % peizhi.size() + 1;
	return idx;
}

//节日活动（送彩带）奖励获得
void CHuoDongAwardManager::GetFestivalRankAward(int festivalType,int rank,int score,SHuoDongAward &award)
{
	int type = CHuoDongAwardManager::FESTIVAL;

	uint32 idx3 = GetFestivalAwardIdx3(festivalType,(uint32)rank,score);
	if (idx3 == 0)
	{
		return;
	}
	uint32 idx = GetAwardIdx(type,festivalType,idx3);
	GetAwardData(type,idx,award);
}

//节日活动 ,赠送道具显示
void CHuoDongAwardManager::MakeFestivalItem(CNetMessage &msg)
{
	uint8 num = 0;
	int type = CHuoDongAwardManager::FESTIVAL;
	vector<GoodsInfo> goodsInfo;
	if (InHuoDongLeijiTime(type))
	{
		uint32 pic = GetHuoDongPic(type);	
		GetHDBangGoods(pic, goodsInfo,type);
		num = (uint8)goodsInfo.size();
	}
	msg<<num;
	for(int i=0;i<num;i++)
	{
		msg<<goodsInfo[i].award<<goodsInfo[i].score_give<<goodsInfo[i].score_get;
	}
}

//节日活动，赠送道具给好友
bool CHuoDongAwardManager::SendItemToFriend(CUser *pUser,uint16 itemId,int itemNum,int roleId,CNetMessage &msg)
{
	if(pUser == NULL)
		return false;
	if(itemId == 0 || itemNum == 0 || roleId == 0)
		return false;
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return false;

	int type = CHuoDongAwardManager::FESTIVAL;
	if (!InHuoDongLeijiTime(type))
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1617,TIPS_FAILURE_COLOR);
		return true;
	}
/*	if(!pUser->IsHot(roleId))
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0241,TIPS_FAILURE_COLOR);
		return true;
	}
*/
	uint32 pic = GetHuoDongPic(type);
	vector<GoodsInfo> goodsInfo;
	GetHDBangGoods(pic, goodsInfo,type);
	uint8 num = (uint8)goodsInfo.size();
	bool flag = false;
	int idx = 0;
	for(int i=0;i<num;i++)
	{
		if(goodsInfo[i].award == itemId)
		{
			flag = true;
			idx = i;
			break;
		}
	}
	if(!flag)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_1621,TIPS_FAILURE_COLOR);
		return true;
	}

	ShareUserPtr ptr = SingletonOnlineUser::instance().GetUserByRoleId(roleId);
	CUser *pU = ptr.get();
	if(pU == NULL)
	{
		char sql[128];
		snprintf(sql,sizeof(sql)-1,"select kuafu_state from role_info where id = %d",roleId);
		char **row = NULL;
		if(pDb->Query(sql) && (row = pDb->GetRow()) != NULL)
		{
			if (atoi(row[0]) == 1)
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0057,TIPS_FAILURE_COLOR);
				return true;
			}
		}
		else
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_LLD_0011,TIPS_FAILURE_COLOR);
			return true;
		}
	}

	char buf[1024];
	if(pUser->GetItemNum(itemId) < itemNum)
	{
		snprintf(buf, sizeof(buf),LANGUAGE_CC_0017,GetItemName(itemId));
		msg<<PRO_ERROR<<MakeStringColor(buf,TIPS_FAILURE_COLOR);
		return true;
	}
	pUser->DelPackageById(itemId,itemNum);
	int index1 = goodsInfo[idx].give_data_id;
	int index2 = goodsInfo[idx].get_data_id;
	pUser->SetExtData32(index1,pUser->GetExtData32(index1)+itemNum);
	pUser->SetExtData32(223,pUser->GetExtData32(223)+itemNum*goodsInfo[idx].score_give);
	snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0242,roleId);
	SaveUseItem(pUser->GetRoleId(),itemId,buf,itemNum);		

	string name;
	char rname[128];
	if(GetRoleName(roleId,rname) > 0)
	{
		name = rname;
	}
	memset(buf,0x00,sizeof(buf));
	snprintf(buf,sizeof(buf),LANGUAGE_CC_0016,name.c_str(),GetItemName(itemId),itemNum);
	msg<<PRO_SUCCESS<<MakeStringColor(buf,TIPS_WARNING_COLOR);

	if(pU != NULL)
	{
		pU->SetExtData32(index2,pU->GetExtData32(index2)+itemNum);
		pU->SetExtData32(224,pU->GetExtData32(224) + itemNum*goodsInfo[idx].score_get);

		char mBuf[128];
		snprintf(mBuf, sizeof(mBuf), LANGUAGE_CC_0014,pUser->GetName(),GetItemName(itemId),itemNum);
		if(pU->GetFightId() == 0)
			SendSysInfo(pU,MakeStringColor(mBuf,TIPS_WARNING_COLOR).c_str());
		else
			SendSysInfoFightEnd(pU,MakeStringColor(mBuf,TIPS_WARNING_COLOR).c_str());
	}
	else
	{
		pU = new CUser;
		if(pU->ReadDataSimple(roleId))
		{
			pU->SetExtData32(index2,pU->GetExtData32(index2)+itemNum);
			pU->SetExtData32(224,pU->GetExtData32(224) + itemNum*goodsInfo[idx].score_get);
			pU->SaveDataSimple();
			pU->SetName(rname);
//			SingletonCRankDataMgr::instance().SeRankData(ECRT_FestivalT,pU);
		}
		delete pU;
		pU = NULL;
	}
	//记录
	memset(buf,0x00,sizeof(buf));
	snprintf(buf,sizeof(buf),"insert into mei_li_send_log (sender_id,sender_name,recv_id,recv_name,item_id,num,time,send_type) values(%u,'%s',%d,'%s',%u,%d,%u,%d)",
		pUser->GetRoleId(),pUser->GetName(),roleId,name.c_str(),itemId,itemNum,(uint32)GetSysTime(),EST_Festival);
	pDb->Query(buf);

	//snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0253,name.c_str(),pUser->GetName(),GetItemName(itemId),itemNum,name.c_str());
	//SysInfoToAllUser(buf);
	return true;
}

//节日活动、鲜花赠送记录获取
bool CHuoDongAwardManager::GetMeilLiSendLog(int roleId,int type,CNetMessage &msg)
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return false;
	
	char sql[512];
	char **row = NULL;
	if(type == 1)	// 赠送
	{
		//								   0		 1		  2	   3		 4	 5
		snprintf(sql,sizeof(sql),"select sender_id,sender_name,recv_id,recv_name,item_id,num,send_type from mei_li_send_log where sender_id=%d order by time desc limit 10",roleId);
	}
	else	// 受赠
	{
		//								   0		 1		  2	   3		 4	 5
		snprintf(sql,sizeof(sql),"select sender_id,sender_name,recv_id,recv_name,item_id,num,send_type from mei_li_send_log where recv_id=%d order by time desc limit 10",roleId);
	}
	
	if(!pDb->Query(sql))
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0235,TIPS_FAILURE_COLOR);
		return true;
	}
	uint8 num = pDb->GetRowNum();
	msg<<PRO_SUCCESS;
	uint16 pos = msg.GetDataLen();
	uint8 count = 0;
	char buf[512];
	msg<<count;
	for(uint8 i=0;i < num;i++)
	{
		if((row = pDb->GetRow()) != NULL)
		{
			int itemId = atoi(row[4]);
			int itemNum = atoi(row[5]);
			const char* srcName = row[3];
			const char* dstName = row[1];
			const char* itemName = GetItemName(itemId);
			int send_type = atoi(row[6]);
			if(send_type == 0)
			{
				SFlowerData* data = SingletonShopManager::instance().GetFlowerCfg(itemId);
				if (data == NULL)
					continue;
				if (type == 1)
					snprintf(buf, sizeof(buf), LANGUAGE_SSJ_0245, srcName, itemName, itemNum, data->qinmi*itemNum, srcName, data->meili*itemNum);
				else
					snprintf(buf, sizeof(buf), LANGUAGE_SSJ_0244, dstName, itemName, itemNum, data->qinmi*itemNum, data->meili*itemNum);
			}
			else if(send_type == 1)
			{
				int score = GetFestivalItemScore(type,itemId);
				if(score > 0)
				{
					if (type == 1)
						snprintf(buf, sizeof(buf), LANGUAGE_CC_0012, srcName, itemName, itemNum, score*itemNum);
					else
						snprintf(buf, sizeof(buf), LANGUAGE_CC_0013, dstName, itemName, itemNum, score*itemNum);
				}
			}
			msg << buf;
			count++;
		}
	}
	msg.WriteData(pos,&count,sizeof(count));
	return true;
}

//获取节日赠送、受赠道具获得的积分
//@param isGive 1-赠送，2-受赠
int CHuoDongAwardManager::GetFestivalItemScore(int isGive,int itemId)
{
	int type = CHuoDongAwardManager::FESTIVAL;
	uint32 pic = GetHuoDongPic(type);
	vector<GoodsInfo> goodsInfo;
	GetHDBangGoods(pic, goodsInfo,type);
	for(uint16 i=0;i<goodsInfo.size();i++)
	{
		if((int)goodsInfo[i].award == itemId)
		{
			if(isGive == 1)
				return goodsInfo[i].score_give;
			else
				return goodsInfo[i].score_get;
		}
	}
	return 0;
}
