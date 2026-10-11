#ifndef _PACK_DEAL_H_
#define _PACK_DEAL_H_

#include "self_typedef.h"
#include "bangpai.h"
#include "item.h"
#include "huo_dong.h"
#include "script_call.h"
#include "skill.h"
#include <list>
#include <vector>
#include <map>
#include <boost/thread.hpp>
using namespace std;

class COnlineUser;
class CNpcManager;
class CSceneManager;
class CUser;
class CFightManager;
class CScene;
class ArenaPaiHangData;
class SJumpTo;
class SItemInstance;

const int ANSWER_QUESTION_SAPCE = 2*60*60;
const int USE_QIAN_NENG = 100;
const int USE_TILI_CHAT = 20;
const uint8 ADMIN_LEVEL = 1;
const int HELP_LIMIT = 16; // 帮助限制条目数

void ClearSockLongIdx(int sock);

class CPackageDeal
{
public:
	CPackageDeal();
	void UserLogout(CUser*);
	void SetVerInfo(const string &version);

	static void SendMoBaiData(CUser *pUser,uint8 showNum);
	static void UpdateMoBaiData(uint8 showNum);
	static void ErrorProtocolDeal(uint16 protocol,int sock);

private:
	void UserLogin(CNetMessage*,int sock);
	void RoleNameOption(CNetMessage *pMsg,int sock);

	void CreateRole(CNetMessage *,int);
	void RemoveFastRoleName(int sex,string &name);
	void SelectRole(CNetMessage *,int);
	void GetPackage(CNetMessage *,int);
	void RoleMove(CNetMessage *,int);
	void ClientJump(CNetMessage *,int);
	void SendJumpPoint(CNetMessage *,int);
	void OpenNpcInteract(CNetMessage *,int);
	void NpcInteract(CNetMessage *,int);
	void IgnoreNpcDialog(CNetMessage *,int);
	void GetItemInfo(CNetMessage *,int);//获得物品信息
	void UserTeamOption(CNetMessage *,int);//组队
	void GetPlayerInfo(CNetMessage *,int);//查询玩家信息
	void PlayerPk(CNetMessage *,int);//玩家pk
	void PlayerMatch(CNetMessage *,int);//玩家切磋
	void NearPlayerList(CNetMessage *,int);//附近玩家列表
	void PetOption(CNetMessage *,int);//查询神将列表
	void MountOption(CNetMessage *,int);//坐骑操作
	void WingOption(CNetMessage *pMsg,int sock);
	
	void UserRankOption(CNetMessage *,int);//用户排行
	void AnswerQuestionOption(CNetMessage *,int);// 答题
	void SyncTime(CNetMessage *,int);// 客户端同步获取服务器时间
	void GetMissionList(CNetMessage *,int);//任务列表
	void GetPetSkill(CNetMessage *,int);//

	void SendTeamInfoToWorldChat(CUser *pUser,const char *pStr);
	void UserChat(CNetMessage *, int);
	bool DoGMString(CUser *pUser, string chatMsg);
	void GetOtherUserItemInfo(CNetMessage*msg,int sock);//获得其他玩家物品信息

	void FriendOption(CNetMessage *pMsg,int sock);
	
	void ChongZhiOption(CNetMessage *pMsg,int sock);
	void UseSpecialItem(CNetMessage *pMsg,int sock);
	void ZhenFaOption(CNetMessage *pMsg,int sock);
	void QueryFinishedCMissions(CNetMessage *pMsg,int sock);
	void QueryUserPetInfo(CNetMessage *pMsg,int sock);
	void FindResourceOption(CNetMessage *pMsg,int sock);
	void ClientShopReturnCall(CNetMessage *pMsg,int sock);
	void GetUserDetail(CNetMessage *pMsg,int sock);

	void ServerQueryOnlineNum(CNetMessage *pMsg,int sock);

	void BangPai(CNetMessage *pMsg,int sock);//帮派
	void BangZhanOption(CNetMessage *pMsg,int sock);
	void BangPaiZhongZhi(CNetMessage *pMsg,int sock);
	void BangPaiCopyOption(CNetMessage *pMsg,int sock);
	
	void FuncHotPointOption(CNetMessage *pMsg,int sock);		// 功能小红点

	void YaoLingOption(CNetMessage *pMsg,int sock);

	void SendTeamListByType(CUser *pUser,uint8 type);

	void UpdatePackage(CNetMessage*msg,int sock);//背包物品
	void PetKaiJiaOption(CNetMessage *pMsg,int sock);
	void NPC_AutoTransport(CNetMessage *pMsg,int sock);
	void FuBenOption(CNetMessage *pMsg,int sock);
	void HeChengOption(CNetMessage *pMsg,int sock);
	void QueryRolePackageItem(CNetMessage *pMsg,int sock);

	void HuoDongOption(CNetMessage *pMsg,int sock);		//活动
	void OpenPackageOption(CNetMessage *pMsg,int sock);	// 背包开启操作
	void CanMeetMonsterOption(CNetMessage *pMsg,int sock);
	
	void HelpOption(CNetMessage *pMsg,int sock);
	void GetHelpTitleList(CUser *pUser);
	void GetHelpContent(CUser *pUser,int helpId);
	
	void DailyActivityOption(CNetMessage *pMsg,int sock); // 每日玩法
	void AnimationOption(CNetMessage *pMsg,int sock); // 播放动画
	void ChuangGuanOption(CNetMessage *pMsg,int sock); // 多人闯关

	void XiuXianLiLianOption(CNetMessage *pMsg,int sock);
	void TongTianTa(CNetMessage *pMsg,int sock);
	void FishOption(CNetMessage *pMsg,int sock); // 钓鱼
	void OfflineExpOption(CNetMessage *pMsg,int sock); // 离线经验
	void UserVIPOption(CNetMessage *pMsg,int sock); // VIP设置
	void ShopOption(CNetMessage *pMsg,int sock); // 商城
	void HuoDongTmpOption(CNetMessage *pMsg,int sock); // 临时活动，开服活动等
	void StageGoalOption(CNetMessage *pMsg,int sock); // 阶段目标
	void PetDraw(CNetMessage *pMsg,int sock);	// 抽神将
	void DailyBossOption(CNetMessage *pMsg,int sock);	// 跑环任务,积分任务
	void FengShenShiLianOption(CNetMessage *pMsg,int sock);	// 新每日boss
	void HuSongShenShouOption(CNetMessage *pMsg,int sock);
	void LeiTaiSaiOption(CNetMessage *pMsg,int sock); // 擂台赛
	void CaiQuanOption(CNetMessage *pMsg,int sock); // 猜拳
	void QueryGongGao(CNetMessage *pMsg,int sock);	// 系统公告
	void GetChongZhiServerId(CNetMessage *pMsg,int sock);

	void SendUserGongGaoMsg(CNetMessage *pMsg,int sock);	// 角色消息公告

	void MoBaiOption(CNetMessage *pMsg,int sock);

	void PetCopyOption(CNetMessage *pMsg,int sock);

	void TreasureMapOption(CNetMessage *pMsg,int sock);
	void ShiLianOption(CNetMessage *pMsg,int sock);
	void FeiXianOption(CNetMessage *pMsg,int sock);

	void QueryChongZhiNotice(CNetMessage *pMsg,int sock);

	void QueryTaskTrack(CNetMessage *pMsg,int sock);

	void FindRoleByNameId(CNetMessage *pMsg,int sock);

	void UserJumpOk(CNetMessage*msg,int sock);

	void GetNpcState(CNetMessage*msg,int sock);

	void ChatChannel(CNetMessage*msg,int sock);

	void WorldMapTransport(CNetMessage *pMsg,int sock);

	void QuerySkillDesc(CNetMessage*msg,int sock);

	void SwitchInfo(CNetMessage *msg,int sock);
	void QueryPetInfo(CNetMessage *msg,int sock);
	void MyBangPai(CNetMessage *msg,int sock);
	void ChangeUserFace(CNetMessage *msg,int sock);
	void ItemDesc(CNetMessage *msg,int sock);
	void Charge(CNetMessage *msg,int sock);
	void GetChargeOrder(CNetMessage *pMsg,int sock);

	void AvailableTask(CNetMessage *msg,int sock);
	void GetScenePos(CNetMessage *msg,int sock);
	void SpecChat(CNetMessage *msg,int sock);
	void NPCYinDao(CNetMessage *pMsg,int sock);
	void XinShouYinDao(CNetMessage *pMsg,int sock);
	void QueryScene(CNetMessage *msg,int sock);
	void QueryItem(CNetMessage *msg,int sock);
	void HeartBeat(CNetMessage *msg,int sock);
	void GooglePlayRestult(CNetMessage *pMsg,int sock);
	void GetTitleList(CNetMessage *msg,int sock);
	void TitleOption(CNetMessage *msg,int sock);
	void CXGongGao(CNetMessage *pMsg,int sock);
	void FuQi(CNetMessage *pMsg,int sock);
	void DelRole(CNetMessage *pMsg,int sock);

	void GuanZhan(CNetMessage *pMsg,int sock);
	void LeaveGuanZhan(CNetMessage *pMsg,int sock);

	//信使功能
	void XinShi(CNetMessage *pMsg,int sock);

	void SetSaveVal(CNetMessage *pMsg,int sock);
	void GetSaveVal(CNetMessage *pMsg,int sock);
	void ClientDataOperation(CNetMessage *pMsg, int sock);
	//提供后台管理功能
	void ServerMgr(CNetMessage *pMsg,int sock);
	void WriteAdminLog(uint32 roleId,const char *fmt, ...);

	void BroadcastChat(CUser *pUser,CNetMessage *msg,int ignoreId);
	void BroadcastChatByZoneId(CUser *pUser,CNetMessage *msg,int ignoreId,int zoneId);

	void SendHuoDongInfo(CNetMessage *pMsg,int sock);
	void GUAJI(CNetMessage *pMsg,int sock);
	void OnSockClose(int sock);
	void ClientLogOut(CNetMessage *pMsg,int sock);
	void ArenaOption(CNetMessage *pMsg,int sock);
	void DOptionCallBack(CNetMessage *pMsg,int sock);

	void Get360Token(CNetMessage *pMsg,int sock);

	bool UserMoveOneStep(CUser *pUser,CScene *pScene,ShareUserPtr &ptr,uint16 x,uint16 y);
	void GetHuoDongConfig(int day=-1);
	void GetExitHuoDongConfig();
	void GetHuoDongInfo(list<HuoDongInfo> &huodong_list,FILE *file);
	void ClientNetCheck(CNetMessage *pMsg,int sock);
	void Send360Token(CUser *pUser);

	int TryRiChangJinBiFuBenJump(CUser *pUser, SJumpTo* pJump); // 魔道2 金币副本 切换地图
	int TryRiChangDaoJuFuBenJump(CUser *pUser, SJumpTo* pJump); // 魔道2 道具副本 切换地图
	int TryRiChangQianNengFuBenJump(CUser *pUser, SJumpTo* pJump); // 魔道2 潜能副本 切换地图
	void GetHuoYueDuRewardInfo(CUser *pUser,int huoYueDu); // 获取活跃度对应的礼包文字信息
	void GetHuoYueDuReward(CUser *pUser,int huoYueDu); // 获取活跃度对应的礼包
	void GetStageGoalInfo(CUser *pUser); // 获取阶段目标列表
	void GetSGSectionReward(CUser *pUser,int stage,int section); // 领取小节奖励
	void GetSGStageReward(CUser *pUser,int stage); // 领取章节奖励
	void EquipSGStageReward(CUser *pUser,int stage); // 装备章节奖励
	void LoadHd7RiDengLu(vector<HD_7RiDengLu>& rewardArr); // 加载7日登陆奖励

	void CompleteHuoDong(CUser *pUser,uint16 huodongId,int &res,int &leftNum);

	void SendWorldLevel(CNetMessage *pMsg,int sock); //获取世界等级

	void ServerRank(CNetMessage *pMsg,int sock);
	void ServerTongTianTa(CNetMessage *pMsg,int sock);
	void ServerXinShi(CNetMessage *pMsg,int sock);
	void ServerArena(CNetMessage *pMsg,int sock);
    void ServerChongZhiNotice(CNetMessage *pMsg,int sock);
	void ServerRoleName(CNetMessage *pMsg,int sock);
	
	void QueryOnlineAward(CUser* pUser,CNetMessage& pMsg,int sock); // 查询在线奖励状态
	void GetOnlineAward(CUser* pUser, CNetMessage& pMsg);   // 获取奖励
	void GetMissonAward(CNetMessage *pMsg,int sock);  // 领取任务奖励

	void GetDengJiLiBaoInfo();
	
	boost::mutex m_mutex;
	boost::mutex m_dbLock;	//登录数据库锁

	CSocketServer &m_socketServer;
	COnlineUser &m_onlineUser;
	CNpcManager &m_npcManager;
	CSceneManager &m_sceneManager;
	CBangPaiManager &m_bangPaiMgr;

	string m_version;

	CDatabaseSql m_loginDb;
	list<HuoDongInfo> huodong[HUODONG_SIZE];
	list<CheckCodeInfo> sock_ans;
	list<ExitHuoDongInfo> exit_huodong;
	vector<DengJiLiBaoInfo> m_dengJiLiBao;

	void ServerStopProgressBar(CNetMessage *pMsg,int sock);
	
	void ServerXianYuan(CNetMessage *pMsg,int sock);
	void KunLunShanTeamOption(CNetMessage *pMsg,int sock);

	void JingJieOption(CNetMessage *pMsg,int sock);
	void ServerTransFormOption(CNetMessage *pMsg,int sock);
	void SendWeiXinReward(CNetMessage *pMsg,int sock);
	void ServerIgnoreQieCuo(CNetMessage *pMsg,int sock);
	void ServerIgnoreFunc(CNetMessage *pMsg,int sock);
	void GetMianZhanPaiCD(CNetMessage *pMsg,int sock);
	void ServerJiaoYiHang(CNetMessage *pMsg,int sock);
	void PK_Notice_Option(CNetMessage *pMsg,int sock);
	void SysGongGaoOption(CNetMessage *pMsg,int sock);

	void RealNameReg_Option(CNetMessage *pMsg,int sock);
	void FlowerOption(CNetMessage *pMsg,int sock);

	void ChongZhiToOtherOption(CNetMessage *pMsg,int sock);
	void ShenJieMiJingOption(CNetMessage *pMsg, int sock);
#ifdef KUA_FU
	void KuaFuLoginRet(CNetMessage *pMsg,int sock);
	void KuaFu_QueryBangPaiRet(CNetMessage *pMsg,int sock);
	void KuaFu_1VS1_Option(CNetMessage *pMsg,int sock);
	void KuaFu_BangZhan_Option(CNetMessage *pMsg,int sock);
	void QunXianZhengBaOption(CNetMessage *pMsg,int sock);
#else
	void KuaFu_QueryBangPai(CNetMessage *pMsg,int sock);
	void QueryKuaFuState(CNetMessage *pMsg,int sock);
#endif
	void RecvServerSysInfo(CNetMessage *pMsg,int sock);

	void ServerNewShenQi(CNetMessage *pMsg,int sock);

	void ServerHuoDongMoneyGiftBag(CNetMessage *pMsg, int sock);
	void MatchResult(CNetMessage *pMsg, int sock);
	void DealShenJiangZheKou(CNetMessage& pMsg, CUser* pUser);
	void DealPetEquipOperate(CNetMessage *pMsg, int sock);
	void DealZheKouHuoDong(CNetMessage& pMsg, CUser* pUser, int type);
	void DealXunHuanZheKouHuoDong(CNetMessage& pMsg, CUser* pUser, int type);

	void ClientTestOption(CNetMessage *pMsg, int sock);
	void DealGuanQia(CNetMessage *pMsg, int sock);
	void DealSpirit(CNetMessage *pMsg, int sock);
	void DealHeroBook(CNetMessage *pMsg, int sock);
	void DealBloodFight(CNetMessage *pMsg, int sock);
	void DealYouLi(CNetMessage *pMsg, int sock);
	//void DealJiJin(CNetMessage *pMsg, int sock);
};
#endif


