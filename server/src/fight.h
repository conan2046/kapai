#ifndef _FIGHT_H_
#define _FIGHT_H_

#include "self_typedef.h"
#include "user.h"
#include "monster.h"
#include <boost/thread.hpp>
#include <boost/any.hpp>

class COnlineUser;
class CFight;
struct SSkillData;
struct BloodFight;

const uint16 SKILL_TAO_PAO = 200;
const uint16 SKILL_ZI_BAO = 201;
const uint16 SKILL_ZHAO_HUAN = 202;
const uint16 SKILL_HUANMIE_TAOPAO = 303;
const int FIGHT_TIME_OUT = 60*30;
const int MATCH_TIME_OUT = 60*10;
const int KUA_FU_1V1_TIME_OUT = 60*4;

const uint8 CartonType_ShuiGhui = 1;
const uint8 MAX_FIGHT_MAMBER = 18;
const int TASK_NUM_LIMIT = 10;
const int TASK_MAX_LIMIT = 50;

enum EFightPlayType
{
	EFPT_Jump = 1,		// 跳过
	EFPT_PlayBack_1 = 2,	// 回放，没战斗结果
	EFPT_PlayBack_2 = 3,	// 回放，有战斗结果
};

struct SFastFightUnit
{
	SFastFightUnit()
	{
		pos = 0;
		hp = 0;
		maxHp = 0;
	}
	uint8 pos;
	uint64 hp;
	uint64 maxHp;
};

struct SFastFightResult
{
	SFastFightResult()
	{
		Clear();
	}
	void Clear()
	{
		win = false;
		group1.clear();
		group2.clear();
	}
	
	bool win;
	vector<SFastFightUnit> group1;
	vector<SFastFightUnit> group2;
};

enum EFightPlayBackType
{
	EFPB_ARENA = 1,	// 竞技场

};

enum EFightEndType
{
	EFET_Turn = 1,		// 回合限制
	EFET_HpPercent = 2,	// 每个单位血量限制
	EFET_DieNum = 3,	// 死亡数量限制
};

struct SFightEndData
{
	SFightEndData()
	{
		type = 0;
		value = 0;
	}
	SFightEndData(int t, int v)
	{
		type = t;
		value = v;
	}
	int type;
	int value;
};
typedef vector<SFightEndData> StarCond;

typedef boost::shared_ptr<CFight> ShareFightPtr;


struct SCallUserScript
{
	ShareUserPtr pUser;
	int scriptId;
	string scriptFun;
	uint8 state;
};

struct SFightZhenFa
{
	uint16 role_level;
	uint16 zhenfa_level;
};

struct SFightCfgData
{
	SFightCfgData()
	{
		id = 0;
		showId = 0;
		zhenfa_id = 0;
		level_rewardId = 0;
		fight_dialog_id = 0;
		teamBuffActive = 0;
		zhenfaLevel.clear();
		memset(bossId,0,sizeof(bossId));
	}

	uint16 GetZhenFaLv(uint16 role_level)
	{
		if(!zhenfaLevel.empty())
			return zhenfaLevel[0].zhenfa_level;
		return 1;
/*		for(uint8 i=0;i < zhenfaLevel.size();i++)
		{
			if(role_level <= zhenfaLevel[i].role_level)
			{
				lv = zhenfaLevel[i].zhenfa_level;
				break;
			}
		}
		return lv;
*/
	}
	
	int id;
	int showId;
	int zhenfa_id;
	int level_rewardId;
	int fight_dialog_id;
	int bossId[ZHEN_FA_POS_NUM];
	int teamBuffActive;	// 0不生效1生效
	vector<SFightZhenFa> zhenfaLevel;
};

struct SFightSpecCfgData
{
	SFightSpecCfgData()
	{
		id = 0;
		zhenfa_id = 0;
		fight_dialog_id = 0;
		zhenfaLv.clear();
		memset(bossId,0,sizeof(bossId));

		user_zhenfa_id = 0;
		user_zhenfaLv.clear();
		user_pos = 0;
		zhuzhanId = 0;
	}

	uint16 GetUserZhenFaLv(uint16 role_level)
	{
		uint16 lv = 1;
		for(uint8 i=0;i < user_zhenfaLv.size();i++)
		{
			if(role_level <= user_zhenfaLv[i].role_level)
			{
				lv = user_zhenfaLv[i].zhenfa_level;
				break;
			}
		}
		return lv;
	}

	uint16 GetZhenFaLv(uint16 role_level)
	{
		uint16 lv = 1;
		for(uint8 i=0;i < zhenfaLv.size();i++)
		{
			if(role_level <= zhenfaLv[i].role_level)
			{
				lv = zhenfaLv[i].zhenfa_level;
				break;
			}
		}
		return lv;
	}
	
	int id;
	int zhenfa_id;
	int fight_dialog_id;
	vector<SFightZhenFa> zhenfaLv;
	int bossId[ZHEN_FA_POS_NUM];

	int user_zhenfa_id;
	vector<SFightZhenFa> user_zhenfaLv;
	int user_pos;	// 1~5, 指定角色在阵法中的位置
	int zhuzhanId;
};

struct SFightZhuZhanCfg
{
	SFightZhuZhanCfg()
	{
		group = 0;
		zhenfaIdx = 0;
		type = 0;
		petStar = 0;
		petLevel = 0;
		id = 0;
		turn = 0;
		unit_id = 0;
	}

	uint8 group;	// 1(1~9) 2(10~18)
	uint8 zhenfaIdx;
	uint8 type;	// 1神将 2怪物
	uint8 petStar;
	uint8 petLevel;
	int id;
	int turn;
	int unit_id;
};

struct SSortFightZhuZhan
{
	bool operator()(const SFightZhuZhanCfg &b1,const SFightZhuZhanCfg &b2)
	{
		return b1.turn < b2.turn;
	}
};

struct SFightDialogCfg
{
	SFightDialogCfg()
	{
		Clear();
	}
	void Clear()
	{
		showTurn = 0;
		group = 0;
		order = 0;
		zhenfaIdx = 0;
		lastTime = 0;
		dialog.clear();
	}
	uint8 showTurn;	// 第几回合显示>=1
	uint8 group;	// 1(1~9) 2(10~18)
	uint8 order;
	uint8 zhenfaIdx;
	uint8 lastTime;
	string dialog;
};

struct SSortFightDialog
{
	bool operator()(const SFightDialogCfg &b1,const SFightDialogCfg &b2)
	{
		if(b1.showTurn < b2.showTurn)
			return true;
		else if(b1.showTurn == b2.showTurn)
			return b1.order < b2.order;
		else
			return false;
	}
};

struct SFightResultData
{
	SFightResultData()
	{
		Clear();
	}
	void Clear()
	{
		pLeader_1 = NULL;
		pLeader_2 = NULL;
		num_1 = 0;
		num_2 = 0;
		pMonster = NULL;
		winGroup = 0;
		monVisableId = 0;
		for(uint8 i=0;i < sizeof(pos_1)/sizeof(pos_1[0]);i++)
		{
			pos_1[i] = 0;
			pHots_1[i] = NULL;
			pos_2[i] = 0;
			pHots_2[i] = NULL;
		}
	}

	uint8 pos_1[MAX_FIGHT_MAMBER/2];
	CUser *pHots_1[MAX_FIGHT_MAMBER/2];
	CUser *pLeader_1;
	uint8 num_1;
	uint8 pos_2[MAX_FIGHT_MAMBER/2];
	CUser *pHots_2[MAX_FIGHT_MAMBER/2];
	CUser *pLeader_2;
	uint8 num_2;
	SMonsterInst *pMonster;
	uint8 winGroup;	// 1 group1 win, 2 gruop2 win
	uint32 monVisableId;
};

class CFightCfgManager
{
public:
	CFightCfgManager()
	{
		m_fightCfg.clear();
		m_fightSpecCfg.clear();
		m_fightDialog.clear();
		m_zhuzhanCfg.clear();
	}
	~CFightCfgManager(){}

	bool Init();

	bool GetFirstBossInfo(int fightId,int &pic,string &name,int &bossId);
	int GetFirstBossId(int fightId);
	SFightCfgData *GetFightCfg(int id);
	SFightSpecCfgData *GetSpecFightCfg(int id);
	bool GetFightDialog(vector<SFightDialogCfg> &dialog,int dialogId);
	bool GetZhuZhanCfg(vector<SFightZhuZhanCfg> &zhuzhan,int zhuzhanId);
	
private:
	bool SetFightZhenFaLevel(vector<SFightZhenFa> &data,string &str);
	
	map<int,SFightCfgData> m_fightCfg;
	map<int,SFightSpecCfgData> m_fightSpecCfg;
	map<int,vector<SFightDialogCfg> > m_fightDialog;
	map<int,vector<SFightZhuZhanCfg> > m_zhuzhanCfg;
};


class CFight
{
public:
	enum EFightType
	{
		EFTMeetMonster = 1,	//野外打怪
		EFTPlayerPk = 2,	//玩家PK
		EFTPlayerQieCuo = 3,//切磋
		EFTScript = 4,		//脚本触发
		EFTBaiHua = 5,		//百花仙子
		EFTZhuoGui = 6,		// 捉鬼任务
		EFTMatch = 7,		//比赛
		EFTCMission = 8,	// 主线、支线任务专用
		
		EFTBangPaiGuard = 10,	// 帮派守卫战斗
		EFTBangPaiPK = 11,	// 帮派PK强杀
		EFTTreasure = 12,	// 藏宝图活动战斗
		EFTShiLian = 13,	// 试炼活动

		EFT_KuaFuBossPK = 15,	// 跨服boss战pk
		EFT_GuanQia = 16,	// 关卡
		EFTBloodFight = 17,	// 血战
		EFTShiLianFight = 18,	// 试炼
		EFTLieZhuanFight = 19,	// 列传
		EFTJueZhanKunLunFight = 20,	// 决战昆仑
		EFTXunBaoFight = 21,	// 寻宝

		EFT_BangPaiCopy = 31,	// 帮派副本

		EFTJingJiChang = 44,// 竞技场
		EFTBangZhan = 45,	// 帮战
		EFTXiuXian = 46,	// 修仙
		EFXtmasTree	=47,	//圣诞树
		EFXtmasBox	= 48,	//圣诞宝箱
		EFKuaFuXueLian = 49,	//跨服雪莲战斗
		EFKuaFu1vs1Preliminary = 50,	//跨服1vs1预赛战斗
		EFKuaFuShenJieMiJingNormalPVE	= 51,	//神界秘境野怪战斗
		EFKuaFuShenJieMiJingElitePVE	= 52,	//神界秘境精英怪战斗
		EFKuaFuShenJieMiJingBossPVE		= 53,	//界秘境BOSS战斗

		EFTChuangGuanRobber = 55,	// 多人闯关 小贼
		EFTChuangGuanUserFight = 56,// 多人闯关 对战
		EFTTongTianTa = 57,			// 通天塔
		EFTTongTianTa_TiaoZhan = 58,// 通天塔霸主挑战
		EFTKunLunShan = 59,			// 昆仑山
		EFTGrabFish = 60,			// 钓鱼 抢夺
		EFTLingQiJuanXian = 61,	// 灵气捐献
		EFTFB_QiangHua = 62,	// 强化副本
		EFTFB_JinQian = 63,		// 金钱副本
		EFTFB_ShengJie = 64,	// 升阶副本
		EFTFB_QianNeng = 65,	// 潜能副本
		EFTDailyBoss = 67,		// 每日boss
		EFTFB_Pet = 68,			// 神将副本
		EFTHuSong = 69,			// 护送PK
		EFTFB_XiangQian = 70,	// 镶嵌副本
		EFTFB_XiLian = 71,		// 洗炼副本
		EFTFB_ChongKai = 72,	// 神将铠副本

		EFTMission105 = 74,	// 狐妖王
		EFT_FEI_XIAN = 77,	// 飞仙战斗
		EFT_XunChaShi = 78,	// 巡察使战斗
		EFT_KunLunShanTeam = 79,	// 组队昆仑山战斗
		EFT_KuaFu_1V1 = 80,	// 跨服1V1
		EFT_QunXianZhengBa = 81,	// 跨服群仙争霸
		EFT_KuaFu_ZhuoGui = 82,		// 跨服捉鬼
		EFT_BaoWeiZhanBoss = 83,	// 蛋糕保卫战
		EFT_Nianshou = 84,	// 年兽
		EFT_FengShen = 85,	// 封神boss
		
		EFTCGFight = 100,	// CG战斗
		
		EFT_TEST = 200,		// 演示战斗
	};

	enum EMemberType
	{
		EFMT_MONSTER = 1,
		EFMT_USER = 2,
		EFMT_PET = 3,
	};

	enum EFightStep
	{
		EFStep_TurnBegin = 1,
		EFStep_UserActBegin = 2,
		EFStep_UserActEnd = 3,
		EFStep_CureHp = 4,	// 加血时
		EFStep_MAX,
	};

	enum EOptionType
	{
		EOTNormal = 0,	// 物理攻击
		EOTSkill  = 1,	// 法术技能
		EOTEscape = 2,	// 逃跑
		EOTAuto = 3,	// 自动战斗
		EOTZhaoHuan = 4,	//召唤
		
		EOTSpecial = 10,//特殊技能
		EOTOtherSkill = 11,	// 特定技能特定解析
		EOTSpeek = 13,		//文字技能

		EOTNone = 20,	// 不行动
	};

	enum EHitType
	{
		EHIT_ShanBi = 0,	// 闪避
		EHIT_MingZhong = 1,	// 命中
	};

	enum EGroupType
	{
		EGT_GROUP1 = 0,
		EGT_GROUP2 = 1,
	};
	
	CFight()
	{
		Clear();
	}
	void Clear();

	void SetGroupZhenFaData(uint16 zhenfaId,uint8 zhenfaLevel,uint8 group=EGT_GROUP1);

	bool AddUser(ShareUserPtr user, uint8 group=EGT_GROUP1);
	uint8 AddPet(SharePetPtr pet,uint8 pos,uint32 userId,uint8 zhenfaPos=0xff);

	void SetBelongToUserWithPos(uint8 fromPos,uint8 userPos);
	uint8 AddMonster(ShareMonsterPtr monster,uint8 pos,uint8 zhenfaPos=0xff);
	void AddUnitStateBeforeFight(uint8 pos,uint16 state,uint8 turn,int value);

	void InitTeamBuff();

	void BeginFastFight(SFastFightResult &result, bool isShowFight=false, int sock=0);

	void BeginFight(CScene *pScene=NULL);
	void UserBattle(CNetMessage &msg,CUser *pUser);

	bool GetFightAllNetMsg(CNetMessage &msg, int type=EFPT_Jump);

	void AddTongTianTaSay(CNetMessage &msg,uint8 &addFightUnitNum);

	uint8 GetFightNum(){ return m_memNum; }
	uint32 GetId(){ return m_id; }
	void SetId(uint32 id){ m_id = id; }
	uint8 GetFightType(){ return m_type; }
	uint16 GetVisibleMonsterId(){ return m_visibleMonsterId; }
	void SetVisibleMonsterId(uint16 id){ m_visibleMonsterId = id; }
	void SetDiaoXiangId(int id){ m_diaoxiangId = id; }
	void SetCanSkip(bool f=true){ m_canSkip = f; }
	void SetHuiCun(bool f){ m_huiCun = f; }
	int GetUseTime(){ return GetSysTime() - m_beginTime;}

	bool IsUserAllMemberDie(uint8 me);
	int GetAnotherGroupLevel(uint8 me);

	CUser *GetUser(uint8 pos);
	CUser *GetUserInFight(uint32 roleId, uint8 group);
	SMonsterInst *GetMonster(uint8 pos);
	SPet *GetPet(uint8 pos);
	
	void SetMonsterHpBeforeFight(uint32 bossId,int hp,int maxHp,int attackRatio,int recoveryRatio);
	void SetWorldMonsterFlag(uint32 bossId);
	uint8 FindMonsterPos(uint32 bossId);

	int GetUnitSpeed_Rand(uint8 pos);
	int GetUnitSpeed(uint8 pos);

	bool FightTimeout();
	bool ReBegin(CSocketServer &sock,ShareUserPtr pUser);
	bool IsFightEnd(bool isfast=false);
	bool FastFightEnd(SFastFightResult &result);

	int GetTurnLimit();

	void UserFightEndHandle();
	void SetCfgFightId(int fightId){m_cfgFightId = fightId;}
	void SetDialog(vector<SFightDialogCfg> &dialog){m_dialog.assign(dialog.begin(),dialog.end());}
	void SetZhuZhan(vector<SFightZhuZhanCfg> &zhuzhan){m_zhuzhan.assign(zhuzhan.begin(),zhuzhan.end());}
	
	void DelMember(uint8 pos);
	void SetFightType(EFightType type)
	{
		m_type = type;
//		if(type == EFTPlayerPk || type == EFTPlayerQieCuo || type == EFTBangPaiPK || type == EFTBangZhan || type == EFXtmasTree	
//			|| type == EFXtmasBox || type == EFKuaFuXueLian || type == EFTGrabFish || type == EFTHuSong)
//		{
//			m_canSkip = true;
//		}
		if(m_type == EFTMatch)
			m_timeOut = MATCH_TIME_OUT;
		else if(m_type == EFT_KuaFu_1V1)
			m_timeOut = KUA_FU_1V1_TIME_OUT;
		else
			m_timeOut = FIGHT_TIME_OUT;
	}

	int GetMonsterNum(int id);
	void BroadcastMsg(CNetMessage &msg);
	
	void Logout(uint8 pos);

	bool showFightLog;	// 是否显示战斗记录
	int monsterId1;		// 战斗野怪Id,回调脚本用
	int monsterId2;		// 战斗野怪Id,回调脚本用
	int GetUnitDamage(uint8 pos,int damage);

	void SetDelNpc(uint16 id,uint16 index=0)
	{
		m_delNpcId = id;
		m_delNpcIndex = index;
	}

	void GuanZhan(CUser*);
	void LeaveGuanZhan(CUser*);
	void SendGuanZhanOver();	
	uint8 GetGroup2UnitsNum();
	void SetPetCeLue(uint16 cl);
	void SetUserCeLue(uint16 cl);

public:
	bool FindBuffData(uint8 pos,uint16 buffId);
	bool HaveBuff(uint8 pos,uint16 buffId);
	bool HaveHunLuan(uint8 pos);
	bool HaveMeiHuo(uint8 pos);
	bool HaveFanJian(uint8 pos);

	int CalculateFightStar(uint8 selfGroup, bool win);
	
	void CalculateFightResult(bool isfast=false);
	void SetFightEndCondition(vector<SFightEndData> &val);

	void AddGroupUnitsAttr(uint8 group, vector<SAttrData> &attr);
	uint8 AddBossToFight(uint32 bossId, uint8 pos, uint8 zhenfaPos, uint64 &hp, SMonsterInst **ppMonster);
	bool AddMonsterWithFightId(int fightId, const vector<uint64> &hpList=vector<uint64>(), int group=EGT_GROUP2);
	bool AddBloodFightMonster(BloodFight& fightCfg, double ratio);
	void AddSingleUserToFight(ShareUserPtr &user, uint8 begin);
	uint16 AddUserGroupToFight(ShareUserPtr &pUser,uint8 group=EGT_GROUP1);

private:
	struct SFightBuffData
	{
		SFightBuffData()
		{
			srcPos = 0;
			id = 0;
			leftTurn = 0;
			paraList.clear();
		}
		uint8 srcPos;	// 施法者pos
		uint16 id;
		int leftTurn;
		vector<int> paraList;	// 参数
	};
	
	void AddJiangLi(CUser *pUser,int state);

	void SetAllUserDie();

	int GetEndConditionValue(int type);
	int GetUserGroupDieNum();
	void InitActionFirstGroup();

	int GetLessHp(uint8 selfGroup, vector<uint16>& leesHp);
	SCallUserScript UserFightEnd(ShareUserPtr &user, uint8 group, bool win, bool isfast=false);

//	SCallUserScript UserFightEnd(uint8 pos,list<uint32> &userList, bool isfast=false);
	void LeiTaiSaiTaoPao(CUser *pUser, uint8 pos);
	void MatchUserFightEnd(CUser *pUser, uint8 pos, SPet *pPet, list<uint32> &userList, int state, uint8 res, bool isfast=false);
	void BangPaiTiaoZhanSaiFightEnd(CUser *pUser,int state);
	//state:0胜利、1 死亡、2 逃跑
	void OtherTypeUserFightEnd(CUser *pUser,uint8 pos,SPet *pPet,list<uint32> &userList,int state,int exp,int money,uint8 res, bool isfast=false);

	//pos 0起始
	void MonsterSkillCeLue(uint8 pos);

	void SyncSceneTeamPos(CUser* pUser,int x,int y); // 同步坐标
	void SpecialFightEnd();

	void CMissionFightEnd();

	CUser *GetGroupHead(int group=EGT_GROUP1);
	void GetPVE_FightResult(CUser **pLeader,CUser **pHots,int &num,bool &isWin,int *type=NULL);
	void GetPVP_FightResult(SFightResultData &result);

	void XiuXianFightEnd();
	void BangZhanEnd();
	void BangPaiPKEnd();
	void BangPaiPKTaoPao(CUser *pUser, uint8 pos);
	void BangPaiZhanTaoPao(CUser *pUser, uint8 pos);
	void BangPaiGuardFightEnd();
	void ChuangGuanFightEnd(); // 多人闯关战斗结束
	void GrabFishFightEnd(); // 钓鱼 抢夺战斗结束
	void GrabFishTaoPao(CUser *pUser,uint8 pos);
	void LingQiJuanXianEnd();// 灵气捐献
	void XunChaShiFightEnd();	// 巡察使战斗
	void RiChangQiangHuaFuBenEnd();// 强化副本
	void RiChangChongWuFuBenEnd(); // 神将副本
	void RiChangJinBiFuBenEnd();	// 金币副本
	void RiChangShengJieFuBenEnd();	// 道具副本
	void RiChangQianNengFuBenEnd();// 潜能副本
	void RiChangXiangQianFuBenEnd();	// 镶嵌副本
	void RiChangXiLianFuBenEnd();	// 洗炼副本
	void RiChangChongKaiFuBenEnd();	// 神将铠副本

	void ShiLianFightEnd();
	void TreasureFightEnd();
	void DailyBossFightEnd();
	void FengShenFightEnd();
	bool IsFightWithPlayerWin(); // 是否和玩家战斗成功
	void GetFightResult(bool &group1_allDie,bool &group2_allDie,CUser **pUser1,CUser **pUser2,SMonsterInst **pMonster=NULL,int *visableId=NULL);
	void HuSongShenShouEnd();	// 护送神将任务

	void RiChangChongWuFuBenJieSuan(CUser* pUser); // 日常 神将副本 结算
	void RiChangChongWu_Middle(CUser *pUser);
	void RiChangChongWu_Tianshu(CUser *pUser);

	void RecoverAllUserHp(bool isBegin=false);	// 恢复所有单位气血
	void ResetQunXianHp(uint8 pos,bool isBegin);
	void RecoverGroupUnitHp(uint8 pos,bool isBegin=false);	// 恢复一组单位气血
	void ChangeGroupUnitHpByMaxHp(uint8 pos,bool isBegin=false);	// 当前血量随血量上限调整按比例调整

	void ZhuoGuiFightEnd();
	void KuaFuZhuoGuiFightEnd();
	void TongTianTaFightEnd();
	void TongTianTa_BaZhuFightEnd();	// 通天塔霸主挑战
	void KunLunShanFightEnd();
	void FeiXianFightTaoPao(CUser *pUser, uint8 pos);
	void FeiXianFightEnd();
	void KunLunShanTeamFightEnd();
	void KuaFu1V1FightEnd();

	void RecoverGroupMaxHp(uint8 group);
	void ResetGroupFightHp(uint8 group);

	void SendPkInfo(uint8 dieGroup);
	void SendMatchInfo(uint8 type);
	void BaiHuaXianZiJiangLi(CUser *,CNetMessage&);

	void NoLockInitUnitsBeforeFight();
	void NoLockMakeEnterFight(CNetMessage &msg);
	void UpdateUserInfo(CUser *pUser,list<uint32> &userList);

	void MakeShowName(CNetMessage &msg);

	void SendUserSelect(uint8 pos);

	//战斗结束，对玩家进行奖惩,返回是否需要传送
	bool JiangCheng(uint8 state,CUser *pUser,uint8 pos);

	bool IsGongFang(uint8 pos);

	void DropItem(CUser *pUser,uint8 pos,CNetMessage &msg);
	int64 GetMaxHp(uint8 pos);
	int64 GetHp(uint8 pos);
	//1-6死返回1，7－12死返回2，都没死光返回0
	uint8 OneGroupAllDie();

	uint8 CalculateWinGroup();

	void CancelAutoFight(CUser *pUser);

	bool AllUserAutoFight(uint16 &userMask);

	int GetBaoJiDamage(uint8 src,int damage,int passBaojiAdd=0);
	
	//计算命中率
	int CalculateHitRatio(uint8 src,uint8 target);
	bool CalculateBaoJiRatio(uint8 src,uint8 target,int &damage,vector<SAttrData> &attrList);
	bool CalculateBaoJiRatio_AddHp(uint8 src,vector<SAttrData> &attrList);
	bool CalculateFanJiRatio(uint8 src,uint8 target,vector<SAttrData> &attrList,int extFanJiLv=0);
	bool CalculateLianJiRatio(uint8 src,uint8 target);
	bool CalculateIsFuHuo(uint8 src,int &fuhuoHp);

	int CalculateFanShang(uint8 src,uint8 target,int damage,vector<SAttrData> &attrList);

	uint8 NormalButtle(uint8 src,uint8 target);	// 普通攻击
	uint8 SkillButtle(uint8 src,uint16 skillId); // 使用技能
	uint8 EscapeAction(uint8 src);
	uint8 GetUnitSkillLevel(uint8 pos,uint16 skillId);
	bool CanTaoPao(uint8 src);

	void GetPassiveSkill_Target(vector<uint8> &allTarget,int trigger,int additiveId,uint8 src,uint8 target,uint16 buffId=0);
	bool IsPassiveToBuff(int trigger,int additiveId);
	void CalculatePassiveSkill_ExtAttrEffect(uint8 src,uint8 target,vector<ESkillTriggerType> &triggerList,vector<ESkillPassitiveType> passList=vector<ESkillPassitiveType>(),uint16 skillId=0,uint16 skillLevel=0,int value=0);
	void CalculatePassiveSkill_ExtValue(uint8 src,uint8 target,vector<ESkillTriggerType> &triggerList,vector<SAttrData> &attr,uint16 skillId=0,uint16 skillLevel=0,int value=0);
	void CalculatePassiveSkill_ActionBuff(uint8 src,uint8 target,const vector<ESkillTriggerType> &triggerList);
	int CalculatePassiveSkill_ExtUnitAndBuff(uint8 src,uint8 target,const vector<ESkillTriggerType> &triggerList,uint16 skillId,uint16 skillLevel,int value=0,vector<SAttrData> *attrData=NULL,bool turnEnd=false,SFightBuffData *buffData=NULL);

	uint8 BasicFightAction(uint8   src,uint8 target,uint16 skillId,uint16 skillLevel,int &selfDamage,vector<SAttrData> &attrData,vector<SAttrData> &tarAttrData,bool isFanji=false,bool firstAttack=true);
	uint8 CalculateOnceAction(uint8 src,uint8 target,uint16 skillId,uint16 skillLevel,int &selfDamage,bool firstAttack=true);
	uint8 CalculateNormal_DamageHp(uint8 src,uint8 target);
	uint8 CalculateSkill_DamageHp(uint8 src,uint16 skillId,int skillLevel);
	uint8 CalculateSkill_AddHp(uint8 src,uint16 skillId,int skillLevel);
	uint8 CalculateSkill_AddBuff(uint8 src,uint16 skillId,int skillLevel);
	uint8 CalculateSkill_ClearBuff(uint8 src,uint16 skillId,int skillLevel);
	uint8 ChangeFightPos(uint8 src);

	void ClearBuffNotMerge(uint8 target,SSkillBuff *pBuff);
	void GetPassivePara(uint8 src,vector<int> &para,SSkillAdditiveEffect *pActive,int skillLevel);
	void GetPassiveBuffPara(uint8 src,vector<int> &para,SSkillAdditiveEffect *pActive,int skillLevel);
	void GetBuffPara(uint8 src,vector<int> &para,SSkillActiveEffect *pActive,int skillLevel);
	
	uint8 XunChaShiZhaoHuan(uint8 src,CNetMessage &msg);

	void GetLiveMember(uint8 *arr,uint8 &num);
	void GetAllMember(uint8 *arr,uint8 &num);

	void GetAllUnitByOrder(uint8 *arr, uint8 &num);

	void GetMeGroupByHpRatioMin2Max(uint8 me,uint8 *arr,uint8 &loseHpNum,uint8 &totolNum);
	void GetMeGroupByAttackedOrder(uint8 me,uint8 *arr,uint8 &num);
	void GetMeGroupUser(uint8 me,CUser **pHots,uint8 &num);

	void GetGroupByAttackedOrder(uint8 me,uint8 *arr,uint8 &num,bool myGroup=true,bool alive=true);
	void GetAnotherGroupByAttackedOrder(uint8 me,uint8 *arr,uint8 &num);
	void GetAnotherGroup(uint8 me,uint8 *arr,uint8 &num);
	void GetAnotherGroupExceptTar(uint8 me,uint8 target,uint8 *arr,uint8 &num);
	void GetAnotherGroup_User(uint8 me,uint8 *arr,uint8 &num);

	uint8 FindYuanHuPos(uint8 groupPos);
	bool HaveDieMember(uint8 me);
	bool HaveLoseHpMember(uint8 me);
	void GetMeGroupExceptSelf(uint8 me,uint8 *arr,uint8 &num);
	void GetMeGroup(uint8 me,uint8 *arr,uint8 &num);
	void GetTargetGroup(uint8 me,uint8 *arr,uint8 &num,bool myGroup=true);

	void GetAllMemberExceptSelf(uint8 me,uint8 *arr,uint8 &num);

	void GetSkillTargetRange(uint8 me,uint16 skillId,uint16 skillLv,uint8 *array,uint8 &num);
	void GetSkillTargetSelCondition(uint8 *array,uint8 &num,int target_select);

	int CalculateSealRatio(uint8 src,uint8 target,uint16 skillId,int skillLevel,int &skillTurn);
	int GetBingDongRatio(uint8 src,uint8 target,uint16 skillId,int skillLevel,int &skillTurn);
	int GetHunShuiRatio(uint8 src,uint8 target,uint16 skillId,int skillLevel,int &skillTurn);
	int GetHunLuanRatio(uint8 src,uint8 target,uint16 skillId,int skillLevel,int &skillTurn);

	void GetAnotherGroup_UserToPetToMonster(uint8 me,uint8 *arr,uint8 &roleNum,uint8 &petNum,uint8 &monsterNum);
	void GetMeGroup_UserToPetToMonster(uint8 me,uint8 *arr,uint8 &roleNum,uint8 &petNum,uint8 &monsterNum);

	void GetExcept(uint8 except,uint8 *arr,uint8 &num);
	void SortBySpeed(uint8 *arr,uint8 num);

	void SetOption(uint8 pos,uint8 option,int para,uint8 target);

	int GetPower(uint8 pos);
	void ClearChaoFeng(uint8 diePos);
	int GetChaoFengTarget(uint8 pos);
	void DecreaseHp(uint8 pos, uint8 srcPos, int &hp, int &absorpionHp, bool ignoreDun=false, int *fuhuoHp=NULL, bool activeTongShengGongSi=true);
	void ImproveRevovery(uint8 pos,int revovery);

	int GetSkillAddHpValue(uint8 src,uint8 target,int skillId,int skillLevel);
	int CalculateSkillDamage(uint8 src,uint8 target,int skillId,int skillLevel,int &selfDamage,vector<SAttrData> &attrList,vector<SAttrData> &tarAttrList);

	bool IsShieldBuff(uint16 buffId);
	void ShieldAbsorptionDamage(uint8 pos, int &hp, int &absorptionHp);	// 盾吸收伤害
	bool ShieldBrokenCheck(uint8 pos);

	uint8 GetStateSrcPos(uint8 pos, uint16 buffId);
	int GetStatePara1(uint8 pos,uint16 buffId);
	int GetStatePara2(uint8 pos,uint16 buffId);
	int GetStatePara3(uint8 pos,uint16 buffId);
	void DecHunShuiTimes(uint8 pos);
	
	void DecAllStateEffectTurn(uint8 pos);
	void DecAllSkillCD(uint8 pos);
	void ClearAdditiveSkillTurnData(uint8 pos);

	void ClearRandomEnBuff(uint8 pos,uint16 buffNum,uint8 src);
	void ClearRandomDeBuff(uint8 pos,uint16 buffNum);
	void ClearMulBuff(uint8 pos,uint16 buffId,uint8 src);
	void ClearBuff(uint8 pos, uint16 buffId, vector<SFightBuffData> *dataList=NULL);
	void AddBuff(uint8 pos, uint8 src, uint16 buffId, uint8 effectTurn=0, vector<int> *para=NULL);

	void SetState(uint8 pos, int state);
	void ClearState(uint8 pos, int state);
	bool HaveState(uint8 pos, int state);

	void StealBuff(uint8 src,SFightBuffData &buffData);
	void SpecialBuffPassAttr(uint8 pos,uint16 buffId,bool add);
	bool HaveEnBuffState(uint8 pos);
	bool HaveDeBuffState(uint8 pos);
	bool HaveShieldState(uint8 pos);
	bool HaveZhongDuState(uint8 pos);
	bool IsAlive(uint8 pos);
	void MakeBuffList(uint8 pos,CNetMessage &msg);
	void MakeSkillInfoInFight(uint8 pos,CNetMessage &msg);

	uint64 GetState(uint8 pos);
	bool IsSameGroup(uint8 pos1,uint8 pos2);
	void GetOption(uint8 pos,uint8 &option,int &para,uint8 &target);
	uint16 GetUnitAISkillId(uint8 pos);
	uint8 GetTarget(uint8 pos);
	bool IsEmpty(uint8 pos)
	{
		if((pos > 0) && (pos <= MAX_MEMBER))
			return m_members[pos-1].memPtr.empty();
		return true;
	}
	int GiveItemByMonster(CUser *pUser,SMonsterInst *pInst);

	uint8 GetProtecterPos(uint8 mePos,int damage);

	int GetUnitAttack(uint8 pos);
	int GetUnitFangYu(uint8 pos,uint8 attackType);
	float CalUnitZengShangLv(uint8 src,uint8 target,uint8 attackType,int extMianshangLv=0);
	float CalUnitAddShangHaiLv(uint8 src,uint8 target,uint8 attackType);
	float CalUnitShangHaiJianMianLv(uint8 src,uint8 target,uint8 attackType);
	int CalculateDamage(uint8 src,uint8 target,vector<SAttrData> &attrList,vector<SAttrData> &tarAttrList);
	int GetSuccesExp(uint8 pos,int *pMoney = NULL);
	int GetShiYaoExp(uint8 pos);

	uint8 AddNewFightUnit(CNetMessage &msg);
	uint8 ShowDialog(CNetMessage &msg);

	uint8 DiePassiveAcion(CNetMessage &msg);
	uint8 MemberActionEffectOther(uint8 src,CNetMessage &msg);
	uint8 MergeExtActionMsg(CNetMessage &msg);
	uint8 MergeUnitAcionMsg(CNetMessage &msg,bool addOtherMsg=true);

	bool AllUserOption();
	void CalculateFight(CNetMessage &msg);
	uint8 KilledAction(uint8 src,CNetMessage &msg);
	uint8 NotKilledAction(uint8 src,CNetMessage &msg);

	uint8 UnitPassiveAction(uint8 pos,EFightStep step,CNetMessage &msg,int data=0);
	uint8 PassiveAction(EFightStep step,CNetMessage &extActionMsg,uint8 pos=0,int value=0);
	
	void CalculateTaoPao(CUser *pUser,uint8 pos);
	void TurnOver(uint8 pos);

	void PrintMsg(CNetMessage &msg);
	void ReadBuffListFromMsg(CNetMessage &msg, uint8 &state, vector<uint8> &buffList);

public:
	static const int FIGHT_TIMEOUT = 30;	//秒
	static const int MAX_MEMBER = MAX_FIGHT_MAMBER;
	static const int GROUP2_BEGIN = MAX_MEMBER/2;
	static const int GROUP_MEMBER = MAX_MEMBER/2;
	static const int GROUP_POS_STEP = MAX_MEMBER/2;
	static const int ADD_POWER_ATTACKED = 15;
	static const int ADD_POWER_PER_TURN = 35;
	static const int MAX_POWER = 100;
	static const int FIGHT_END_DATA_NUM = 3;
	static const uint8 GROUP1_MAIN_POS = GROUP2_BEGIN-GROUP_MEMBER/2;
	static const uint8 GROUP2_MAIN_POS = MAX_MEMBER-GROUP_MEMBER/2;

	void SetTalkIdx(int idx) { m_talkIdx = idx; }
	int GetTalkIdx() const { return m_talkIdx; }
	void SetTalkPos(int pos) { m_talkPos = pos; }
	int GetTalkPos() const { return m_talkPos; }
	void SetAllMemberSpeedLevel(uint8 speed);
	void SetFightChooseMode(){m_IsAutoMode = 0;}
	void SetPlaySpeed(uint8 speed=0){m_playSpeed = speed;}
	void SetUserOperatorTime(uint8 time){m_userOperateTime = time;}
	void AddCacheData(uint32 t){m_cacheData.push_back(t);}
	void SetFightEndData(int index,int value);
	void SetTaskId(int tid){m_taskId = tid;}
	void SetMemberFirstCartonType(uint8 pos,uint8 type);
	void SetFightPosAndSay(uint8 pos,const string &say)
	{
		if(pos == 0 || pos > GROUP2_BEGIN)
			return;
		m_fightSayPos = pos;
		m_fightSay = say;
	}
	void XtmasTreeFightEnd();
	void XtmasBoxFightEnd();
	void SetQunXianImageGain(uint8 pos,uint8 imageIdx,float ratio);
	void GetQunXianAttrWithGainValue(int type,int &srcVal,uint8 pos);	// type 1攻击 2暴击 3闪避 4反击 5连击 6防御 7速度 8抗性       16血
	void BaoWeiZhanFightEnd();
	void UpdateUnitHp(uint8 pos);

#ifdef KUA_FU
	void QunXianZhengBaEnd();
	void KuaFuBossPkEnd();
	void QieCuoFightEnd();
	void KuaFu1vs1PreliminaryEnd();
	uint8 ShenJieMiJingUpdateBossHp();
	void ShenJieMiJingNormalFightEnd();
	void ShenJieMiJingEliteFightEnd();
	void GuWuXianShiTaoPao(CUser *pUser, uint8 pos);
	void ShenJieMiJingBossFightEnd();
	void EFKuaFuXueLianFightEnd();
	void KuaFuQieCuoTaoPao(CUser *pUser, uint8 pos);
#endif
	void SendFightReward(CUser* pUser);

	void SetGroupShowName(uint8 group, const char * pName);
	void SetUnitPercentData(vector<SFastFightUnit>& percent, uint8 group = CFight::EGT_GROUP2);

public:
	static const int MingZhongRatio = 325;
	static const int ShanBiRatio = 325;
	static const int BaoJiRatio = 130;
	static const int RenXingRatio = 130;
	static const int LianJiRatio = 130;
	static const int ZhaoJiaRatio = 130;
	static const int FanJiRatio = 260;
	static const int GeDangRatio = 130;
	static const int FanShangRatio = 130;
	static const int FanShangDiKangRatio = 325;
	static const int JianShangRatio = 130;
	static const int KangBingDongRatio = 10;
	static const int KangHunShuiRatio = 10;
	static const int KangHunLuanRatio = 10;
	static const int JiaQiangBingDongRatio = 10;
	static const int JiaQiangHunShuiRatio = 10;
	static const int JiaQiangHunLuanRatio = 10;
private:
	bool ReLoadUserNoLock(ShareUserPtr user);
	void SetUnitBasicData(uint8 pos);
	void AddDieUnit(uint8 pos)
	{
		if(!IsAlive(pos))
		{
			if(std::find(m_dieList.begin(),m_dieList.end(),pos) == m_dieList.end())
			{
				m_dieList.push_back(pos);
			}
		}
	}
	void DelDieUnit(uint8 pos)
	{
		vector<uint8>::iterator it = std::find(m_dieList.begin(),m_dieList.end(),pos);
		if(it != m_dieList.end())
			m_dieList.erase(it);
	}
	
	template<typename Type> uint8 AddTmpl(Type,uint8 pos,uint8 zhenfaPos=0xff);
	template<typename Type> uint8 AddTmplNoLock(Type,uint8 pos,uint8 zhenfaPos=0xff);
	template<typename Type> uint8 ReAddTmplNoLock(Type val,uint8 pos);

	struct SFightLimitData
	{
		SFightLimitData()
		{
			_value = 0;
			_count = 0;
			_clear_perTurn = false;
		}
		SFightLimitData(int v,int t,bool c=false)
		{
			_value = v;
			_count = t;
			_clear_perTurn = c;
		}
		int _value;
		int _count;
		bool _clear_perTurn;
	};
	struct SFightMember
	{
		boost::any memPtr;
		
		bool select;
		uint8 option;
		uint8 target;
		uint8 zhenfaPos;
		uint8 isWorldBoss;	// 1是 0否
		uint8 state;

		uint16 celue;
		uint8 belongUserPos;// 神将，怪所属玩家位置(影响战斗胜利结算)
		uint8 speedLevel;	// 客户端加速等级		
		uint8 skill245UseNum;		
		uint8 firstCartonType;	// 第一回合战斗动画特效
		bool killUnit_ext_IsLimit;

		uint32 petOwner;		// 神将主人roleId		
		int para;
		int nextAITurn;		// 下次执行AI的轮次
		int srcHp;
		int type;	// 怪，人，神将

		// 基础属性
		int level;
		int xiang;
		int speed_rand;	// 用于速度排序
		int attackType;	// 1物攻2法攻
		SUnitBasicAttr unitAttr;
		
		int jiaQiangSeal;		// 加强封印
		int jiaQiangZhongDu;	// 加强中毒
		int jiaQiangBingDong;	// 加强冰冻
		int jiaQiangHunShui;	// 加强昏睡
		int jiaQiangHunLuan;	// 加强混乱
		int kangSeal;		// 抗封印
		int kangZhongDu;	// 抗中毒
		int kangBingDong;	// 抗冰冻
		int kangHunShui;	// 抗昏睡
		int kangHunLuan;	// 抗混乱
		
//		uint32 state[BuffStateNum];

		int64 hp;

		// 战斗统计
		int64 sum_damage;	// 伤害统计
		int64 sum_cure;		// 治疗统计
		int64 sum_beDamage;	// 承伤统计

		list<SFightBuffData> buff_list;
		string name;
		vector<SSkillData> skill_list;	// 主动技能
		vector<SSkillData> passive_skill;	// 被动技能
		vector<int> notEffectBuff;
		vector<SAttrData> passive_attr;
		vector<uint8> killList;
		map<uint64,SFightLimitData> passSkillLimit;	// key=skillId|passType|attrType, value=data
		map<uint16,vector<int> > skillExtData;	// skillId, dataList (用于记录技能额外添加参数)

		void Clear()
		{
			memPtr = boost::any();
			select = false;
			option = 0;
			para = 0;
			target = 0;
			zhenfaPos = 0;
			isWorldBoss = 0;
			petOwner = 0;
			belongUserPos = 0;
			speedLevel = 0;
			skill245UseNum = 0;		
			firstCartonType = 0;
			killUnit_ext_IsLimit = false;
			nextAITurn = 0;
			srcHp = 0;
			type = 0;
			level = 0;
			xiang = 0;
			speed_rand = 0;
			hp = 0;
			attackType = 0;
			unitAttr.Clear();
			jiaQiangSeal = 0;
			jiaQiangZhongDu = 0;
			jiaQiangBingDong = 0;
			jiaQiangHunShui = 0;
			jiaQiangHunLuan = 0;
			kangSeal = 0;
			kangZhongDu = 0;
			kangBingDong = 0;
			kangHunShui = 0;
			kangHunLuan = 0;
			celue = 0;
			state = 0;
			buff_list.clear();
			name.clear();
			skill_list.clear();
			passive_skill.clear();
			notEffectBuff.clear();
			passive_attr.clear();
			killList.clear();
			passSkillLimit.clear();
			skillExtData.clear();

			sum_damage = 0;
			sum_cure = 0;
			sum_beDamage = 0;
		}

		int GetSkillExtDataPara(uint16 skillId,int paraIdx)
		{
			if(paraIdx < 1)
				return -1;
			map<uint16,vector<int> >::iterator it = skillExtData.find(skillId);
			if(it == skillExtData.end())
				return -1;
			vector<int> &paraList = it->second;
			if((int)paraList.size() < paraIdx)
				return -1;
			return paraList[paraIdx-1];
		}
		void AddSkillExtData(uint16 skillId,vector<int> &val)
		{
			if(val.empty())
				return;
			map<uint16,vector<int> >::iterator it = skillExtData.find(skillId);
			if(it == skillExtData.end())
			{
				skillExtData.insert(make_pair(skillId,val));
				return;
			}
			vector<int> &srcVal = it->second;
			uint32 size = srcVal.size();
			uint32 vsize = val.size();
			for(uint32 i=0;i < size && i < vsize;i++)
				srcVal[i] += val[i];
			for(uint32 i=size;i < vsize;i++)
				srcVal.push_back(val[i]);
		}
		void RemoveSkillExtData(uint16 skillId)
		{
			map<uint16,vector<int> >::iterator it = skillExtData.find(skillId);
			if(it == skillExtData.end())
				return;
			skillExtData.erase(it);
		}

		SFightLimitData *GetPassSkillLimitData(uint64 skillId,uint64 additiveType,uint16 attrType=0,bool clearFlag=false)
		{
			if(skillId == 0 || additiveType == 0)
				return NULL;
			uint64 key = (skillId << 32) | (additiveType << 16) | attrType;
			map<uint64,SFightLimitData>::iterator it = passSkillLimit.find(key);
			if(it == passSkillLimit.end())
			{
				SFightLimitData data;
				data._clear_perTurn = clearFlag;
				it = passSkillLimit.insert(make_pair(key,data)).first;
			}
			return &it->second;
		}

		bool AddPassSkillLimitAttrData(uint64 skillId,uint64 additiveType,uint16 attrType,int addPerValue,int num,int countLimit)
		{
			SFightLimitData *pData = GetPassSkillLimitData(skillId,additiveType,attrType);
			if(pData == NULL)
				return false;
			if(pData->_count >= countLimit)
				return false;
			int addNum = (countLimit - pData->_count >= num) ? num : (countLimit - pData->_count);
			int addValue = addPerValue * addNum;
			pData->_count += addNum;
			vector<SAttrData> attrList;
			attrList.push_back(SAttrData(attrType,addValue));
			unitAttr.AddAttrValue(attrList);
			pData->_value += addValue;
			return true;
		}
		bool DecPassSkillLimitAttrData(uint64 skillId,uint64 additiveType,uint16 attrType,int decPerValue,int num)
		{
			SFightLimitData *pData = GetPassSkillLimitData(skillId,additiveType,attrType);
			if(pData == NULL)
				return false;
			int decNum = (num > pData->_count) ? (pData->_count) : num;
			int decValue = decPerValue * decNum;
			pData->_count -= decNum;
			vector<SAttrData> attrList;
			attrList.push_back(SAttrData(attrType,-decValue));
			unitAttr.AddAttrValue(attrList);
			pData->_value -= decValue;
			return true;
		}
		bool SetPassSkillLimitAttrData(uint64 skillId,uint64 additiveType,uint16 attrType,int addPerValue,int num)
		{
			SFightLimitData *pData = GetPassSkillLimitData(skillId,additiveType,attrType);
			if(pData == NULL)
				return false;
			int srcValue = pData->_value;
			int addValue = addPerValue * num;
			pData->_count = num;
			vector<SAttrData> attrList;
			attrList.push_back(SAttrData(attrType,addValue-srcValue));
			unitAttr.AddAttrValue(attrList);
			pData->_value = addValue;
			return true;
		}
		void ClearPassSkillTurnData()
		{
			for(map<uint64,SFightLimitData>::iterator it = passSkillLimit.begin(); it != passSkillLimit.end(); it++)
			{
				SFightLimitData &data = it->second;
				if(data._clear_perTurn)
					data._count = 0;
			}
		}

		void AddKillUnit(uint8 pos)
		{
			killList.push_back(pos);
		}
		
		bool HaveKillUnit()
		{
			return (!killList.empty());
		}
		
		void ClearKillUnit()
		{
			killList.clear();
		}

		int AddHp(int addHp,int _maxHp=0)
		{
			int srcHp = hp;
			hp += addHp;
			if(_maxHp > 0 && hp > _maxHp)
				hp = _maxHp;
			else if(_maxHp == 0 && hp > unitAttr.maxHp)
				hp = unitAttr.maxHp;
			if(hp <= 0)
				hp = 0;
			return (int)(hp - srcHp);
		}

		bool InNotEffectBuff(int buffId)
		{
			for(uint16 i=0;i < notEffectBuff.size();i++)
			{
				if(notEffectBuff[i] == buffId)
					return true;
			}
			return false;
		}
		
		int GetSkillLevel(int skillId)
		{
			if(skillId == 0)
				return 0;
			for(uint32 i=0;i < skill_list.size();i++)
			{
				if(skill_list[i].id == skillId)
					return skill_list[i].level;
			}
			return 0;
		}

		uint16 SelectAvailableSkill(uint16 expectSkillId)
		{
			for(uint16 i=0;i < skill_list.size();i++)
			{
				if(skill_list[i].leftCD == 0)
				{
					if(expectSkillId == 0 || (expectSkillId > 0 && skill_list[i].id != expectSkillId))
						return skill_list[i].id;
				}
			}
			return 0;
		}

		bool CanUseSkill(uint16 skillId)
		{
			for(uint16 i=0;i < skill_list.size();i++)
			{
				if(skill_list[i].id == skillId)
					return (skill_list[i].leftCD == 0) ? true : false;
			}
			return false;
		}

		bool SetSkillCD(uint16 skillId)
		{
			for(uint16 i=0;i < skill_list.size();i++)
			{
				if(skill_list[i].id == skillId)
				{
					skill_list[i].leftCD = skill_list[i].CD;
					return true;
				}
			}
			return false;
		}

		void DecAllSkillCD(int cd=1)
		{
			for(uint16 i=0;i < skill_list.size();i++)
			{
				if(skill_list[i].leftCD > 0)
				{
					if(skill_list[i].leftCD >= cd)
						skill_list[i].leftCD -= cd;
					else
						skill_list[i].leftCD = 0;
				}
			}
		}

		void DecSkillCD(uint16 skillId,int decCD)
		{
			for(uint16 i=0;i < skill_list.size();i++)
			{
				if(skill_list[i].id == skillId)
				{
					skill_list[i].leftCD -= decCD;
					if(skill_list[i].leftCD < 0)
						skill_list[i].leftCD = 0;
					break;
				}
			}
		}

		uint16 GetSkillNum(){	return skill_list.size();}

		const vector<SSkillData> &GetUnitSkillList(){return skill_list;}
		
		uint16 RandSelectSkill(vector<uint16> *expectSkillList=NULL)
		{
			if(skill_list.empty())
				return 0;
			vector<SSkillData> availableList;
			for(uint16 i=0;i < skill_list.size();i++)
			{
				if(skill_list[i].leftCD == 0)
				{
					if(expectSkillList == NULL || (std::find(expectSkillList->begin(),expectSkillList->end(),skill_list[i].id) == expectSkillList->end()))
						availableList.push_back(skill_list[i]);
				}
			}
			int size = availableList.size();
			if(size == 0)
				return 0;
			int totleRatio = 0;
			for(int i=0;i < size;i++)
				totleRatio += availableList[i].ratio;
			int r = Random(1,totleRatio);
			int ratio = 0;
			for(int i=0;i < size;i++)
			{
				if(r > ratio && r <= ratio+availableList[i].ratio)
					return availableList[i].id;
				else
					ratio += availableList[i].ratio;
			}
			return 0;
		}
	};

	SFightMember *GetFightMember(uint8 pos);

	bool m_fightIsEnd;
	bool m_useSpeekSkill;
	bool m_useZhaoHuanSkill;
	bool m_canSkip;		// 是否可以跳过战斗播放
	bool m_huiCun;		//脚本战斗，战斗结束失败是否回新手村
	
	uint8 m_type;
	uint8 m_memNum;
	uint8 m_IsAutoMode;	// 0手动模式 1自动模式 (开始战斗的模式)
	uint8 m_playSpeed;	// 战斗播放速度, 0根据客户端自身速度 > 0 指定速度(1~5)
	uint8 m_userOperateTime;	// 玩家操作限时(s)
	
	uint16 m_delNpcId;
	uint16 m_delNpcIndex;
	uint16 m_visibleMonsterId;//战斗对应的可见怪id
	
	int m_timeOut;		// 整场战斗超时时间
	int m_diaoxiangId;
	int m_talkIdx;		// 喊话类型
	int m_talkPos;		// 喊话位置
	int m_taskId;
	int m_zhaoHuanTimes;
	int m_fightTurn;	//战斗轮次
	int m_cfgFightId;	// 配置表fightId
	uint32 m_id;
	uint32 m_beginTurnMask;
	int m_fightEndData[FIGHT_END_DATA_NUM];	// 战斗结束时用的数据1
	time_t m_beginTime;
	time_t m_turnBegin;
	time_t m_userOpTime;
	uint8 m_fightSayPos;
	string m_fightSay;
	string m_fightNotice;
	vector<SFightDialogCfg> m_dialog;
	vector<SFightZhuZhanCfg> m_zhuzhan;
	vector<uint8> m_dieList;
	vector<uint8> m_actionList;
	CNetMessage m_actionMsg;
	CNetMessage m_otherMsg;	// 战斗回合数据缓存
	CNetMessage m_extActionMsg;	// 战斗回合数据缓存
	CNetMessage m_shareDamageMsg;	// 分摊伤害数据
	uint8 m_curActionPos;	// 当前战斗行动单位pos
	
	uint8 m_ActionFirstGroup;	// 先出手的队伍
	
	SFightMember m_members[MAX_MEMBER];
	uint16 m_zhenfaId[2];
	uint8 m_zhenfaLevel[2];
	string m_ShowName[2];
	
	CScene *m_pScene;
	boost::recursive_mutex m_mutex;
	string arenaInfo;
	list<int> m_guanZhanSock;
	vector<uint32> m_cacheData;	// 缓存数据，特殊战斗结束时候传出
	vector<uint8> m_taopaoList;	// 逃跑poslist

	vector<CNetMessage> m_fightMsgList;		// 战斗网络包记录
	vector<ShareUserPtr> m_groupUser[2];	// 两边角色数据
	vector<SFightEndData> m_endCond;	// 战斗结束条件
	bool m_forceEnd;	// 是否强制结束

	uint8 m_qx_userPos;	// 群仙，发起者pos
	uint32 m_qx_userAttrVal[CUser::MAX_QX_ATTR_NUM];	// 群仙，发起者值加成
	uint16 m_qx_userAttrPercent[CUser::MAX_QX_ATTR_NUM];// 群仙，发起者比例加成，比例val /= 10000
	uint8 m_qx_imagePos;	// 群仙，镜像人物pos
	uint8 m_qx_imageIdx;	// 1 普通 2 中等 3 困难
	float m_qx_imageGain;	// 群仙，镜像人物增益

	static const uint8 MISS = 0;
	static const int BaoJiQiangHua = 1;
	static const int LianJiQiangHua = 1;
	static const int FanJiQiangHua = 1;
	static const int FanShangQiangHua = 1;
	static const int JianShangQiangHua = 1;
	static const int RenXingQiangHua = 1;
	static const int GeDangQiangHua = 1;
	static const int ZhaoJiaQiangHua = 1;
};


class CFightManager
{
public:
	CFightManager();
	ShareFightPtr CreateFight();
	void AddFight(ShareFightPtr ptr);

	void UserBattle(CNetMessage*,int);
	void FightOption(CNetMessage *pMsg,int sock);

	//1秒运行一次此函数
	void RunFightTimeOut();

	ShareFightPtr FindFight(uint32 id);
	void RemoveFight(uint32 id);

private:
	CHashTable<uint32,ShareFightPtr> m_fights;

	uint32 m_curFightId;
	COnlineUser &m_onlineUser;
	boost::recursive_mutex m_mutex;
};

inline void CFight::SetOption(uint8 pos,uint8 option,int para,uint8 target)
{
	if((pos > 0) && (pos <= MAX_MEMBER))
	{
		m_members[pos-1].option = option;
		m_members[pos-1].para = para;
		m_members[pos-1].target = target;
		m_members[pos-1].select = true;
	}
}

inline uint64 CFight::GetState(uint8 pos)
{
	return 0;
}

inline bool CFight::IsSameGroup(uint8 pos1,uint8 pos2)
{
	if(pos1 == 0 || pos1 > MAX_MEMBER || pos2 == 0 || pos2 > MAX_MEMBER)
		return false;
	if((pos1 <= GROUP2_BEGIN && pos2 <= GROUP2_BEGIN) || (pos1 > GROUP2_BEGIN && pos2 > GROUP2_BEGIN))
		return true;
	return false;
}

inline bool CFight::IsAlive(uint8 pos)
{
	if(pos > 0 && pos <= MAX_MEMBER)
	{
		if(m_members[pos-1].memPtr.empty())
			return false;
		if(HaveState(pos, EFST_STATE_Die))
			return false;
		return true;
	}
	return false;
}

inline uint8 CFight::GetTarget(uint8 pos)
{
	if((pos > 0) && (pos <= MAX_MEMBER))
		return m_members[pos-1].target;
	return 0;
}

#endif

