#ifndef _SCRIPT_CALL_H_
#define _SCRIPT_CALL_H_
#include <list>
#include <vector>
#include <map>
#include <string>
#include "self_typedef.h"
#include "bangpai.h"

using namespace std;
class CUser;
class SItemTemplate;
class SMonsterTmpl;
struct SNpcPos
{
	int sceneId;
	int x;
	int y;
};

struct KuaFu_TeamInfo
{
	uint32 role_id[3];
	string name[3];
	int jifen;
};

// 简化信息
struct LianHuanRankData
{
	int id;
	string name;
	int level; // 这个从来就没有当level用过……就是数量的意思
	//LianHuanRankData(int tid,string& tname,int tlevel):id(tid),name(tname),level(tlevel){}
	bool operator >(const LianHuanRankData& data) const
	{
		return level > data.level;
	}
};

// 帮派挑战赛数据
struct BangPaiTiaoZhanData
{
	int bang;
	int point;
	BangPaiTiaoZhanData() : bang(0),point(0) {}
	bool operator<(const BangPaiTiaoZhanData& data)
	{
		return point < data.point;
	}
};

struct BangPaiTiaoZhanDataSort
{
	bool operator()(const BangPaiTiaoZhanData& d1,const BangPaiTiaoZhanData& d2)
	{
		return d1.point > d2.point;
	}
};

struct MineInfo_81
{
	uint32 ownerId;
	uint16 sceneId;
	uint16 x;
	uint16 y;
};

struct RoleInfo_81
{
	uint32 roleId;
	int wa;
	int mai;
	int wa_success;
	int mai_success;
};

int Random(int min,int max);
int Dialog ( CUser *pUser, const char *name, const char *text );
int Dialog_End(CUser *pUser,const char *name,const char *text);

bool SetGenSuiPetDown(CUser *pUser);
void SetGenSuiPetUp(CUser *pUser);
bool SetQiPetDown(CUser *pUser);
void SetQiPetUp(CUser *pUser);
void ShowDailyBossFightEnd(CUser *pUser,int starNum,int exp,int index,int type,int addStar,int itemId,int itemNum);

void SendDailyBossShowIconInfo(CUser *pUser);

void PlayPetDrawCartoon(CUser *pUser,uint16 petId,uint16 petLevel,uint8 petStar,uint16 transItemId,uint16 trasItemNum);
void PlayItemDrawCartoon(CUser *pUser,uint16 itemId,uint16 itemNum);

int MakeDailyBossInfo(CUser *pUser,int type,int sid,int x,int y,const char *str);
int UpdateDailyBossInfo(CUser *pUser,int index,int starNum,const char* pStr1,int isfinish1,const char* pStr2,int isfinish2);
void CloseDailyBossPanel(CUser *pUser);

void SendFightFailed_PushMsg(CUser *pUser, const char *pStr, const char* pHintStr);

bool CheckPass(char *pStr);

int DialogT ( CUser *pUser, const char *name, const char *text );
int Option ( CUser *pUser, const char *name, const char *text, const char *opt );
int OptionConfirm (CUser *pUser,const char *name,const char *text,const char *opt);

int DialogS(CUser* pUser, int npcId, int state, const char* name, const char* text); // 剧情对话
int DialogS_Start(CUser* pUser, int npcId, const char* name, const char* text); // 剧情对话 特化处理 开始 npcId是-1的话代表是玩家
int DialogS_Doing(CUser* pUser, int npcId, const char* name, const char* text); // 剧情对话 特化处理 进行
int DialogS_End(CUser* pUser, int npcId, const char* name, const char* text); // 剧情对话 特化处理 结束

int Collect(CUser *pUser,int npcId,int npcIdx,int pic=1,int type=1,const char *showMsg=""); // 采集草药,开启宝箱
bool CollectTower(CUser *pUser, int npcId);
void ClearCollectState(CUser *pUser);
int ShowGuidance(CUser *pUser,int type); // 显示引导

void ShowPetCopyPanel(CUser *pUser);
void ShowMinePanel(CUser *pUser);

void CreateBangPaiPanel(CUser *pUser);

void ShowChoosePanel2(CUser *pUser,char *str);

void SysInfo(CUser *pUser, const char *info);

//弹出式消息
void SMessage ( CUser *pUser, const char *msg );
void SMessage_End(CUser *pUser,const char *pMsg);

void FirstLoginPanel(CUser *pUser,const char *pMsg);

//物品选择
void SelectItem ( CUser *pUser, int i, int j );

//选择神将
void SelectPet ( CUser *pUser, int petId, const char *name, const char *msg );

//卖物品,item为物品id，用“|”隔开
void SellItem ( CUser *pUser, int type, const char *items ,int selectId = 0, int cnt = 0);//items "1|2|3……"

void SellSeedItem(CUser *pUser,const char *items);

SPlantSeed *GetSeedItem(uint32 itemId);

void ShowUserExchangePanel(CUser *pUser);

//关闭npc交互
void CloseInteract ( CUser *pUser );

// 尝试转换钓鱼场景srcid
void TryTranslateFishingSrcSceneId(CUser *pUser, uint16& srcSceneId);
bool IsInFishingRoom(int sceneSrcId); // 是否是在钓鱼房间

bool CanJoinActivity (CUser *pUser);

// 场景位置同步
void SyncUserScenePos(CUser *pUser,uint16 x,uint16 y,uint8 face);


//玩家跳转
void TransportUser ( CUser *pUser, int sceneId, uint16 x, uint16 y, uint8 face);
//玩家本场景跳转
void UserJumpTo ( CUser *pUser, uint16 sceneId, uint16 x, uint16 y, uint8 face);

// 玩家跳转 特殊读条
void TransportUserWithLoadingType ( CUser *pUser, int sceneId, uint16 x, uint16 y, uint8 face , uint8 loadType);

//进入帮派场景
//bool EnterBangPaiScene(CUser *pUser,uint8 x,uint8 y,uint8 face);
bool EnterBangPaiScene ( CUser *pUser, int bId );//14,14,8
bool EnterBPFightReadyScene(CUser *pUser);
bool EnterBPFightScene(CUser *pUser);
void EnterBPFightSafeArea(CUser *pUser);
void GetSafeAreaPos(uint16& x, uint16& y);
bool CheckSafeAreaPos(uint16 x, uint16 y);
int GetEnterBangPaiTime(CUser *pUser);
bool CanEnterBangPaiFightScene(CUser *pUser);
bool IsOpenBangPaiFight();

//脚本添加物品，程序中用于初始化物品列表
void AddItemTmpl ( SItemTemplate* );

//脚本添加怪物，程序中用于初始化怪物
//void AddMonsterTmpl(SMonsterTmpl*);

const char *GetMonsterBossName(int bossId);


//通过怪物id获得名字
const char *GetMonsterName ( int id );

const char *GetPetName(int id);

int GetPetDefaultQuality(int id);

//获得场景名字
const char *GetSceneName ( int id );

//获得物品
SItemTemplate *GetItem ( int itemId );

const char *GetItemName(int item);
int GetItemColor(int item);
int GetQualityColor(int quality);
string GetItemColorStr(int type, int value, int extValue = 0, int extValue1 = 0);

void ItemCurrencyLog(uint32 userId,int itemId,int num,int itemLevel,int useTongbao,int leftTongbao,int type);

const char *GetUserNpcName ( CUser *pUser, int npcId );

void DelMonster(CUser *pUser,int monsterType,int sceneId);
int AddMonster(CUser *pUser,int taskType,int pic,const char *name,int sceneId,int x,int y);
int AddNpc ( CUser *pUser, int npcId, const char *name, int sceneId, int x, int y, int timeOut = 0 );
int AddNpcDirect(CUser* pUser, int npcId, int sceneId, int x, int y, int direct = 0,int index=0);
int AddNpcWithInfo(CUser *pUser,int npcId,int sceneId,int x,int y,int type,int pic,const char *name, int color = 0);

bool FindNpc(CUser *pUser,int npcId);

// 全地图人可见
void AddNpcScene(CUser *pUser,int npcId,const char *name,int sceneId,int posX = -1,int posY = -1);
bool FindNpcScene(CUser *pUser,int npcId, int sceneId);
bool FindNpcByScene(int npcId, int sceneId);
void DelNpcScene(CUser *pUser,int npcId, int sceneId,int npcIndex=0);

int AddDefaultNpc ( CUser *pUser, int npcId, int sceneId, int x, int y, int timeOut = 0 );

void DelNpc ( CUser *pUser, int npcId,int index=0);
void DelNpcScript(CUser *pUser, int npcId, int index = 0);
void DelAllNpc(CUser *pUser, int npcId, int index = 0);

void DelDynamicNpcWithIndex(CUser *pUser,int npcId,int npcIdx);
bool FindDynamicNpcWithIndex(CUser *pUser,int npcId,int npcIdx);

//师门任务战斗
void ShiMenFight ( CUser *pUser );

// ******************************************************* 任务战斗 开始 *******************************************************

void SendPKNotice(CUser *pUser);
void SendSysInfo(CUser*,const char *info);
void SendSysInfoRD(CUser*,const char *info); // 发右下角的系统信息
void SendSysInfoFightEnd(CUser*,const char *info); // 发送系统信息，战斗后显示

//队长
int GetTeamAllMemNum(CUser *pUser);
int GetTeamMemNum ( CUser *pUser );
CUser *GetTeamMember(CUser *pUser,int idx);

int GetNpcSceneId ( int npcId );

SNpcPos GetNpcScenePos ( int sceneId );
SNpcPos GetNpcTmplPos ( int tmplId);

uint8 GetNpcPicType(int npcId);
uint16 GetNpcPicId(int npcId);
const char *GetNpcName ( int npcId );
const char *GetNpcTmplName(int tmplId);
const char *GetDiaNameByIndex(CUser *pUser,int npcId,int index=0);

//打开背包，选择物品
void OpenPackage ( CUser *pUser, int p );

void ShiLianNoticeToExit(CUser *pUser,int second);

void EnterFeiXianScene(CUser *pUser,int floor);
void EnterShiLianFuBen(CUser *pUser);
void EnterQiangHuaFuBen(CUser *pUser);	// 强化副本
void EnterChongWuFuBen(CUser *pUser,int difficulty=0); // 神将副本
void EnterJinBiFuBen(CUser *pUser); 	// 金币副本
void EnterShengJieFuBen(CUser *pUser);	// 道具副本
void EnterQianNengFuBen(CUser *pUser);	// 潜能副本
void EnterXiangQianFuBen(CUser *pUser);	// 镶嵌副本
void EnterXiLianFuBen(CUser *pUser);	// 洗炼副本
void EnterChongKaiFuBen(CUser *pUser);	// 神将铠副本

void UpdateNpcState ( CUser *pUser, int npcId, int state );
void UpdateNpcHeadState(CUser *pUser,int npcId,int npcIndex,int headState);

//创建帮派，type:0 用游戏币创建(1000000)，type:1用道具创建（item 1816)
int CreateBangPai ( CUser *pUser, const char *name,const char *gonggao,int pic,uint16 limitLv);

void InputStr ( CUser *pUser, const char *pMsg );
void Input2Str( CUser *pUser, const char *pMsg);
void Input3Str ( CUser *pUser, const char *pMsg ); // 答题用 比较长的文字输入框

SNpcPos GetNpcPos ( CUser *pUser );

void DoItem ( CUser *pUser, int stype );

void SetHuoDong ( bool );
void SetHuoDongBeiLv ( int );
bool InHuoDong();
int GetHuoDongBeiLv();

struct SUserAward
{
	int id;
	int num;
};
//id: <0没有重奖，0重奖已领过，>0重奖物品
SUserAward GetAward ( CUser *pUser );

//设置玩家已经领取奖励
void SetGetAword ( CUser *pUser );

int GetSecond();
int GetMinute();
int GetHour();
int GetDay();
int GetMonth();
int GetYear();
int GetYDay();
int GetMonthDayNum();

void SysInfoToAllUser(const char *msg,bool checkTime=false);
void SysInfoToBangPai(int bId, const char* msg); // 发送帮派信息
void SysInfoToBangPai_Tips(int bangId,const char *msg);

void SysMailToAllUser (const char *message);

void SaveDate(CUser *pUser,int type,int data,const char *str);
void SaveDate(int user_id,int type,int data,const char *str);

CUser *GetTeamLeader ( CUser *pUser );
//得到场景中可过点
SNpcPos GetCanWalkPos ( int npcId );

//选择属性
void SelectAttr ( CUser *pUser, uint8 pos );

char *GetPaiMing ();

int GetWeekDay();

//根据帮派id,得到帮派繁荣度
int GetBangPros ( CUser *pUser, int bid );

string GetRoleBangPaiName(uint32 roleId);
const char *GetBangName ( int id );

void UpdateUserInfo(CUser *pUser,uint8 uType);

//获得所在场景帮派id
int GetSceneBang ( CUser *pUser );

//得到帮派资金
int GetBangMoney ( CUser *pUser );
void AddBangMoney ( CUser *pUser, int money );

//兑换帮贡
void DuiHuanBG ( CUser *pUser, char *info );

void DonateBang ( CUser *pUser );

//返回"题目|答案1|答案2|答案3|答案4"
const char *GetQuestion(CUser *pUser = NULL);

char *IdentifyBook ( CUser *pUser, uint8 pos );

void InputNumber ( CUser *pUser, int id );

//0成功
int ChangeCharName ( CUser *pUser, char *name );
int ChangeRoleName(CUser *pUser,char *name);

bool CanChangeName ( CUser *pUser );

void EnterFuBen(CUser *pUser,int mapId,int x,int y,int face);

//TYPE=1 普通礼花
//TYPE=2 结婚礼花
//scene 0,所有场景
void TeXiao ( int type, int scene );

void SendSysChannelMsg ( const char *info );

//0正确，1已领取，2无
int FindUniqueJiHuoMa(CUser *pUser,char *str,int ad,int type = 0,bool useMul = false);

//type礼包类型|ad渠道
const char *GetJiHuoMaInfo(char *str);

bool IsTestCZAccount(CUser *pUser);
const char *GetTestCZFanLiInfo(CUser *pUser);
bool SetTestCZFanLiAward(CUser *pUser);

bool HaveAward_TestAccount(CUser *pUser);
bool SetAward_TestAccount(CUser *pUser);

void SendHotPointStatus(CUser *pUser, uint16 type, uint8 status);


//打开寄信界面
void OpenXinShi ( CUser *pUser );
//列出收到的信
void ListXinShi ( CUser *pUser );

void QueryArenaLog(CUser *pUser);
void InitArena(CUser *pUser);
void QueryRoleName(int sock,uint8 sex);

int GetLeiTaiJiFen ( CUser *pUser);
void ClearLeiTaiJiFen(CUser *pUser);

void SendNpcPos(CUser *pUser,int mapId,uint8 x,uint8 y);

void SendNpcMsg(CUser *pUser,int npcId,const char *msg);

void AddRoleExp(uint32 roleId,uint32 exp);


bool HaveChongZhi(CUser *pUser);

bool CanEnterLeiTai(uint32 roleId);

//得到连续登陆天数1,2
int GetOnlineDay(int roleId);

int BitAnd(int i,int j);

int BitOr(int i,int j);

int GetRoleLastTime(const int id,bool isForce = false);

void DisMissBangActive(CUser *pUser);

char *GetName(CUser *pUser,int rank,int tangzhurank=0);

int IsChuangWei(CUser *pUser);

int IsDisMissBangPai(CUser *pUser);

int ExportUserInfo(CUser *pUser);

int GetSceneUserNum(int id);

int SendYinDaoNPCPos(CUser *pUser, int mapId, int x, int y, int npcId);
int SendYinDaoMissionNPCPos(CUser *pUser, int mapId, int x, int y, int npcId, int mid);
int SendYinDaoMonsterPos(CUser *pUser,int mapId,int x,int y,int monsterId);

void SendYinDao2_Op(CUser *pUser, int op); // 总体的引导
int GetLvUpExp(int level); // 获取升级经验

void BangPaiHuoYuePaiHang(CUser *pUser,char *str);

void KuaFuZhan_paihang(CUser *pUser,char *time,char *str);
char *TiaoZhanSai_paihang(CUser *pUser,char *time);

void ChangeRoleShape(CUser *pUser,int val);

int GetGlobalVarible(int key); // 全局表读取
void SetGlobalVarible(int key, int value); // 全局表设置
string GetGlobalVaribleData(int key); // 全局表数据读取
void SetGlobalVaribleData(int key, const char* data); // 全局表数据设置
void SetGlobalVaribleDataAndTime(int key, const char* data, uint32 time);
void SetGlobalVaribleData(int key, int data); // 全局表数据设置

uint32 GetGlobalVaribleTime(int key);


void SaveDataEx(CUser* pUser, int type, int data1 = 0, int data2 = 0, int data3 = 0); // 保存记录

int GetMoney(uint16 skillId,uint8 skillLevel,int &qianNeng,int &money);

// 帮派挑战赛
int BangPaiTiaoZhanSaiBaoMing(CUser *pUser, int bId, int roleId1, int roleId2, int roleId3); // 返回0：成功报名；1：已经报过了；2：达到帮派报名上限了；3：系统忙
bool BangPaiTiaoZhanSaiBangEnterEnable(int roleId1, int roleId2, int roleId3); // 是否可以进入场景
int BangPaiTiaoZhanSaiState(); // 帮派挑战赛活动状态 返回：0：不在活动中；1：报名中；2：活动进行中
const char* BangPaiTiaoZhanSaiPaiHang(); // 获取排行榜
int BangPaiTiaoZhanSaiEnableLingJiang(CUser *pUser); // 是否可以领奖 返回：0：不能领奖；1：第一名奖励；2：第二名奖励；3：第三名奖励；4：已经领取过了；5：第一名帮派奖励；6：参与奖
bool BangPaiTiaoZhanSaiLingJiang(CUser *pUser,int type); // 领奖

bool SendSystemMail(int roleId, const char *pMsg, SMailData *pMailData = NULL);
bool SendSystemAwardMail(int roleId, const char *str, std::vector<SAwardData> &awvec);
bool SendSysTest(int roleId, int type, int rank);

bool SendMailToUser(int fromId,string fromName,int toId,const char *pMsg,SMailData *pMailData=NULL);

void MakeMailAttachStr(string &strCompress,SMailData *pMailData);

const char* GetJiHuoMa(int type = 0); // 获取激活码

int64 GetRoleLevelUpExp(int level);
void ChangeClientGuaJiState(CUser *pUser,uint8 state);

int GetTongTianTaBaZhuId(uint8 bazhuIndex);
int TongTianTaBaZhuFight(CUser *pUser,int bazhuIndex);
int GetHuoDongExpWithType(CUser *pUser,int type,double ratio=1.0);
void KunLunShan_UpdateRoleMsg(CUser *pUser, int type, int value, int index = 0);
void KunLunShan_SendMonsterReward(CUser *pUser, int type);

void KunLunShanTeam_UpdateRoleMsg(CUser *pUser,int type,int value,int index=0);

void ShowYaYunBiaoCheNextTaskPanel(CUser *pUser,int exp,int money,int item_id,int item_num);

void ShowHuSongShenShowTaskPanel(CUser *pUser);
void UserLeaveTeam(CUser *pUser);
void UpdateHuSongTaskState(CUser *pUser);
void ShowHuSongShenShouNextTaskPanel(CUser *pUser);
void GetYaYunBiaoCheInfo(CUser *pUser,uint8 op);
void ShowYaYunBiaoChePanel(CUser *pUser,uint8 isChanged,int npcId);
void ShowYaYunBiaoChe_CheckChange(CUser *pUser,const char *str);
void ShowFinishYaYunBiaoChePanel(CUser *pUser);
void SendChangeYaYunBiaoCheSuccess(CUser *pUser,int step);

void SaveUseItemStr(uint32 userId,uint32 itemId,const char *reason,uint8 num,const char *before,const char *end);

void AddKunLunShanPaiHangScore(CUser *pUser);
void SendKunLunShanTopUser();

void AddKunLunShanTeamPaiHangScore(CUser *pUser);

void ShowBaiHuaAwardPanel(CUser *pUser,const char *data,const char *userMsg);
void ShowJoinBangPaiPanel(CUser *pUser);

void SortKunLunShanPaiHang_NoLocked();
void ClearKunLunShanPaiHang();
void GetKunLunShanPaiHang(CUser *pUser,CNetMessage &msg);

void SortKunLunShanTeamPaiHang_NoLocked();
void ClearKunLunShanTeamPaiHang();
void GetKunLunShanTeamPaiHang(CUser *pUser,CNetMessage &msg);

void SendPaiHangJiangLi();
void SendKunLunShanTeamAward();
int LingQiJuanXianFight(CUser *pUser);
void XunChaShiFight(CUser *pUser,int npcId,int index);

SharePetPtr CreatePet(int petId,int level,int star=-1,CUser *pUser=NULL);

bool AddPet(CUser *pUser, int petId, int level, int star = -1, bool isShow = true, uint8 *pType = NULL, uint16 *itemId = NULL, uint16 *itemNum = NULL);

bool AddPetToMail(SMailData &mdata,int petId,int level,int star=-1);

void ExitCaiJiFB(CUser* pUser); // 退出采集副本
void ExitDengLuFB(CUser* pUser); // 退出登陆副本

bool IsLeiTaiSaiTime(int level, bool ignoreItme = false); // 是否是擂台赛时间 是否忽略时间

bool SaveUserInput(int roleId, int type, char* input); // 保存玩家输入的字符串

const char *GetRandomSequence(int maxValue);

void ShiLianFight(CUser *pUser,int floor,int xiang);

int GetMonsterFindPathSidById(int monsterId);

int GetMonsterFindPathX(int monsterId);
int GetMonsterFindPathY(int monsterId);

void ZhuoGuiFight(CUser *pUser,int fightType,int monPic,const char *pName,int turn);

int GetJuanxianMax(CUser *pUser);

int GetArenaLeftNum(CUser *pUser);

void SetLingMoActivity(bool val);
bool IsInLingMoActivity();

void HD_DropExchangeItem(CUser *pUser,int hd_id);
void HD_DropHDItem(CUser *pUser,int hd_id);

int GetDropExItemDayIdx();

float GetWorldExpRatio(uint16 level);
int GetWorldExpPercent(uint16 level);
int GetWorldExp(uint16 level, int exp);

const char *GetAccountName(CUser *pUser);

const char *GetServerType();
void SetServerType(string &type);
void SetServerOpenTime(uint32 time);
uint32 GetServerOpenTime();

void Test_SendPetMail(CUser *pUser,int petId);

void SetBZ_WIN_BANG_ID(int id);
int GetBZ_WIN_BANG_ID();
void SetBZ_WIN_BANG_ID(int idx,int id);
int GetBZ_WIN_BANG_ID(int idx);
void ClearBZ_WIN_BANG_ID();

int GetMonthCardExpRatio(CUser *pUser);
uint32 doRandomByRandomBoxCfg( uint32 box_id );//进行一次随机返回key
uint32 getRandomBoxCfg( uint32 key ,const char* find ); //查找配置某项
void clearRandomBoxSaveLimit();//清楚限制存储数值 
void ShowXiuXianPanel(CUser *pUser);

void ShowJumpNotice(CUser *pUser,uint8 type);
void EnterWaitingList(int user_id,int npc_id,int index);
void StartToFight( CUser *pUser ,int npc_id,int index,int des=1);
void OpenXtmasBox( CUser *pUser);

int GetSystemTime();
bool InKuaFu();
bool IsOpenKuaFu();
void Binding(CUser *pUser,const char *npcName,const char *name,const char *passwd);
bool RecordPhoneInfo(CUser *pUser,const char *npcName,const char *qqNum,const char *phoneNum);
bool IsKuaFuBangZhanWinner(int bangId);

bool InFuncionLevelReadyTime(int sysId);
bool InFuncionLevelTime(int sysId);

void EnterTeamKunLunShan(CUser *pUser);

void AddKuaFu1V1RoleData_TEST(CUser *pUser);

bool AddHongLiJiFen(CUser *pUser,int jifen);

void MakeQunXianFloorMsg(CUser *pUser,uint8 floor,CNetMessage &msg);
void MakeQunXianMsg(CUser *pUser,CNetMessage &msg);
void SendQunXianMsg(CUser *pUser);

bool AddKuaFuZhuoGuiMiss(CUser *pUser);
void KuaFuZhuoGuiFight(CUser *pUser);

int GetUnOpenPackageNum(CUser *pUser);

bool InHuoDongTime(uint32 huodong_type);
bool InHuoDongHour(uint32 huodong_type);
void HDChouCall(CUser *pUser,const char *npcName,const char  *callbackName);
void HDChouBet(CUser *pUser,const char *npcName,uint32 limitCount,const char  *callbackName);
void HDChouIntro(CUser *pUser,const char *npcName,uint32 limitCount);
void SendMianZhanPaiCD(CUser *pUser);
bool HDFindYouYuanRenShow(CUser *pUser,const char *npcName,const char  *callbackName);
bool HDFindYouYuanRenThank(CUser *pUser,const char *npcName);
bool HDFindYouYuanRenExchange(CUser *pUser,const char *npcName,bool isYB);
void DelSceneNpc(int mapId,int npcid,int index);
void ChristmasTreeShow(CUser *pUser,const char *npcName,const char  *callbackName,int costYB);
void ChristmasTreeBangShow(CUser *pUser,const char *npcName,const char  *callbackName);
void GetChristmasTreeGrowAward(CUser *pUser,const char *npcName);
void ChristmasTreeZhuangBan(CUser *pUser,const char *npcName,uint32 zhuangbanType);
void ShowShopYaoShiPanel(CUser *pUser);
const char* GetHuoYueTask(CUser *pUser, int taskMax);
int GetDelTestAwardStatus(CUser *pUser);
void ShowHuoYueTaskPanel(CUser *pUser, const char *taskListStr);
//add by zhudaolong 2017.11.10
void ShowTaoHuaGengPanel(CUser *pUser);
uint8 GetYaoQianShuFreeNum(CUser *pUser);

void LoadHuoDongGlobalData();
void SaveHuoDongGlobalData();

int GetBaoWeiZhanBossCurHp();
void SetBaoWeiZhanBossCurHp(int hp);
void ReduceBaoWeiZhanBossCurHp(int hp);
void BaoWeiZhanTimer();
void LoadHuanLeShengYanJiFen();
void SaveHuanLeShengYanJiFen();
void AddHDHuanLeShengYanJiFen(CUser *pUser,int jifen);
void SetHDHuanLeShengYanJiFen(int jifen);
bool HDHuanLeShengYanCall(CUser *pUser,const char *npcName);
const char *GetHuanLeShengYan_DuiHuanInfo();
bool HuanLeShengYan_LiBaoDesc(CUser *pUser,const char *npcName);
void HuanLeShengYan_SendLiBao(CUser *pUser);
void ShowHuanLeShengYan_PaiHang(CUser *pUser);
void ShowHuanLeShengYan_AwardList(CUser *pUser);
void UpdateHuanLeShengYan_PaiHangList(CUser *pUser,int jifen);
void BaoWeiZhanFight(CUser *pUser);
void ShowBangPai_XianZhunGe(CUser *pUser);

const char *GetCMissionInts(CUser *pUser,int id);
const char *GetCMissionStrs(CUser *pUser,int id);

void WabaoFight( CUser *pUser );

void SetTeamFaBuInfo(CUser *pUser,uint8 type,uint16 minLevel,uint16 maxLevel,uint8 fabu);	// fabu:1发布0不发布

void GetAwardFromLevelAward(CUser *pUser, uint32 awardid, bool isFight);

// 获取转盘
void SendZhuanpanFromLevelAward(CUser *pUser, uint32 awardid, int num);
void SendAwardByDropId(CUser *pUser, int dropId);

void StartCMissionFight(CUser *pUser,int missId,int fightId);

void UpdateDCMissionComplate(CUser *pUser, int mid, int num = 1, int cond = 0);

int GetShiMenExp(CUser *pUser);
int GetShiMenMoney(CUser *pUser);
void GetZhuoGuiExpAndMoney(int times,uint16 level,int &exp,int &money);
int GetDailyBossExp(int idx);

int GetFengShenDoNum(CUser *pUser);

int GetFSBossFightNumPerDay(CUser *pUser);

int GetCMissionAcceptLevel(int missId);

int GetFuncOpenLevel(int sysId);

void GetKuaFuXinMo(CUser *pUser);

void ShiLianXinMoFight(CUser *pUser);

void MsgToAllServer(CUser *pUser,const char *msg);

const char *GetBangPaiRobTime();
int CanCreateJZZXJiHuoMa(CUser *pUser);
const char* CreateJZZXJiHuoMa(CUser *pUser, int type);
const char* QueryJZZXJiHuoMa(CUser *pUser);
int UseJZZXJiHuoMa(CUser *pUser, const char *mark);
int	SendJZZXLuckBoxMail(uint32 role_id, int level, bool needChangeName);
const char* SQLFilterForLua(const char *sql);

void PlayFightCG(CUser *pUser, int id);


#endif


