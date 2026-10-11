#ifndef _MEN_PAI_H_
#define _MEN_PAI_H_

#include "self_typedef.h"
#include "utility.h"
#include <boost/thread.hpp>
#include <list>
#include <map>
#include <string>

using namespace std;

class CUser;
struct SAttrTypeValue;
struct SBangPai_CopyData;
struct SFastFightUnit;

struct SBP_CopyDamage
{
	SBP_CopyDamage()
	{
		role_id = 0;
		damage = 0;
	}
	SBP_CopyDamage(uint32 id, uint64 &val)
	{
		role_id = id;
		damage = val;
	}

	uint32 role_id;
	uint64 damage;
};

struct SSortBP_DamRank
{
	bool operator()(const SBP_CopyDamage &a1, const SBP_CopyDamage &a2)
	{
		return a1.damage > a2.damage;
	}
};

struct SBangPai_CopyData
{
	SBangPai_CopyData()
	{
		needSort = false;
		complete = 0;
		id = 0;
		killerRoleId = 0;
		memset(monLeftHp, 0, sizeof(monLeftHp));
		damRank.clear();
	}

	void Sort();
	
	void AddRoleDamage(uint32 roleId, uint64 &damage);

	void UpdateMonsterHp(vector<SFastFightUnit> &vec);

	uint32 GetMaxDamageRoleId();

	bool needSort;
	uint8 complete;	// 0 未完成 1 完成
	int id;
	uint32 killerRoleId;	// 击杀角色id
	uint64 monLeftHp[ZHEN_FA_POS_NUM];	// 怪剩余血量, 为0时死亡
	vector<SBP_CopyDamage> damRank;	// 伤害榜
};

struct SBangPai_CopyChap
{
	SBangPai_CopyChap()
	{
		Clear();
	}

	void Clear()
	{
		complete = 0;
		chapId = 0;
		info.clear();
	}

	uint8 complete;	// 0 未完成 1 完成
	int chapId;		// 章节id
	map<int, SBangPai_CopyData> info;	// 副本信息 [copyId]-data
};

struct SBangPai_Buff
{
	SBangPai_Buff()
	{
		id = 0;
		level = 0;
	}
	SBangPai_Buff(uint16 _id, uint8 _lv)
	{
		id = _id;
		level = _lv;
	}
	uint16 id;
	uint8 level;
};

struct SBangPai_CopyInfo
{
	void Clear()
	{
		buffInfo.clear();
		copyInfo.clear();
	}
	map<uint16, SBangPai_Buff> buffInfo;
	vector<SBangPai_CopyChap> copyInfo;
};

enum EBangPaiRank
{
	EBRBangZhu = 1,	// 帮主
	EBRZhangLao = 2,// 长老
	EBRHuFa = 3,	// 护法
	EBRBangZhong = 4,// 帮众
	EBRRANK_MAX = EBRBangZhong,
};

enum ETangzhu
{
	BingQi = 1,
	BaiCao,
	ShiLian,
	ShouYu
};

enum EBangPaiLogType
{
	EBPLT_Member_Change = 1,	// 成员变更



	EBLT_PRAY = 101,			// 帮派祈福
	EBLT_STEAL_PLANT = 102,	// 紫色及以上品质的植物被偷取
	EBLT_FIRE = 103,			// 领地魔火被点燃
	EBLT_STEAL_TREE = 104,	// 神树被掠夺
	EBLT_KILL_BUG = 105,		// 植物被其他帮派帮助除虫
	EBLT_WATERING = 106,		// 植物被其他帮派帮助浇水
	EBLT_TASK = 107,			// 其他帮派成员在本帮内完成巡视
	EBLT_LEVELUP = 108,		// 本帮等级提升
	EBLT_PUBLISH_TASK = 109,	// 发布任务
	EBLT_GET_TASK_AWARD = 110,	// 完成任务领奖
	EBLT_JIAOYOU = 111,		// 交游
	EBLT_JIE_JIAO = 112,		// 结交
	EBLT_QI_MOU = 113,		// 奇谋
	EBLT_CHE_CHA = 114,		// 彻查
	EBLT_JIE_CHU = 115,		// 上仙解除
	EBLT_LV_UP_ZXG = 116,	// 仙尊阁升级
	EBLT_JUANXIAN = 117,	// 捐献金币
};

enum EBangPaiTaskType
{
	EBTT_ZhongZhi = 1,	// 种植任务
	EBTT_Watering = 2,	// 浇水任务
	EBTT_KillBug = 3,	// 除虫任务
	EBTT_Steal = 4,		// 偷窃任务
	EBTT_KillPlayer = 5,	// 杀人任务
	EBTT_MAX,
};

enum EBangPaiHuoYueType
{
	EBHT_KillPlayer = 1,	// 本帮击杀
	EBHT_ZhongZhi = 2,		// 种植
	EBHT_KillBug = 3,		// 除虫
	EBHT_Watering = 4,		// 浇水
	EBHT_Steal = 5,			// 偷菜
	EBHT_JuanXian = 6,		// 捐献
	EBHT_Login = 7,			// 登录
	EBHT_OnLineTime1 = 8,	// 累计时间1
	EBHT_OnLineTime2 = 9,	// 累计时间2
	EBHT_OnLineTime3 = 10,	// 累计时间3
	EBHT_Pray = 11,			// 金币祈福
	EBHT_TongBaoPray = 12,	// 元宝祈福
    EBHT_ShopBuy = 13,      // 帮派商店购买
    EBHT_JoinBangZhan = 14,	// 参加帮战
    EBHT_Skill = 15,		// 技能修炼
	EBHT_MAX,
};

struct SBangPaiMember
{
	SBangPaiMember()
	{
		rank = 0;
		huoyue_day = 0;
		bpFightJifen = 0;
		roleId = 0;
		utime = 0;
		total_gongXian = 0;
	}

	void AddTotalBangGong(int value)
	{
		if(value > 0)
			total_gongXian += value;
	}

	uint8 rank;
	int bpFightJifen;
	uint32 roleId;
	uint32 huoyue_day;	// 每日活跃度
	uint32 utime;		// 入帮时间
	int total_gongXian;	// 个人获得的总帮贡,只增不减
};

enum SZZState
{
	EZZSNormal = 0,		// 正常状态
	EZZSRipe = 1,		// 成熟
	EZZSWatering = 2,	// 浇水
	EZZSKillingBug = 4,	// 除虫
	EZZSCanClear = 8,	// 可铲除
};

enum BangPaiFireState
{
	BPFire_OFF = 1,	// 熄灭
	BPFire_ON,		// 着火
};

enum ZZQualityType
{
	ZZQT_WHITE = 0,	// 白
	ZZQT_GREEN = 1,	// 绿
	ZZQT_BLUE = 2,	// 蓝
	ZZQT_PURPLE = 3,// 紫
	ZZQT_ORANGE = 4,// 橙
	ZZQT_GOLD = 5,	// 金
	ZZQT_PINK = 6,	// 粉
	ZZQT_RED = 7,	// 红
	ZZQT_NUM = ZZQT_RED+1,
};

enum ZZGainType
{
	ZZGain_Money = 1,	// 金币
	ZZGain_YB = 2,		// 元宝
	ZZGain_Item = 3,	// 物品
	ZZGain_EXP = 4,		// 经验

	ZZGain_MIN_Type = ZZGain_Money,
	ZZGain_MAX_Type = ZZGain_EXP,
};

struct SPlant
{
	SPlant()
	{
		Clear();
	}
	void Clear()
	{
		itemId = 0;
		state = 0;
		roleId = 0;
		time = 0;
		ripeTime = 0;
		gain = 0;
		stealNum = 0;
		wateringTime = 0;
		wateringCount = 0;
		killBugTime = 0;
		killBugCount = 0;
		quality = 0;
		pic = 0;
		thiefList.clear();
	}
	void print()
	{
		cout<<">>>> itemId="<<itemId<<", state="<<state<<", quality="<<(int)quality<<", pic="<<pic<<", roleId="<<roleId<<", roleNam="<<roleName<<endl;
		cout<<"     time="<<time<<", ripeTime="<<ripeTime<<", gain="<<gain<<", stealNum="<<(int)stealNum<<", wateringTime="<<wateringTime
			<<", wateringCount="<<wateringCount<<", killBugTime="<<killBugTime<<", killBugCount="<<killBugCount<<endl;
		cout<<"     thiefList=";
		for(uint8 i=0;i < thiefList.size();i++)
			cout<<thiefList[i]<<"|";
		cout<<endl;
	}
	uint16 state;	// 状态0正常, 1成熟...
	uint8 quality;	// 0~4 白绿~橙
	uint16 itemId;	// 种植作物类型(物品id)
	uint16 pic;
	uint32 roleId;	// 种植角色id
	uint32 time;	// 种植时间
	uint32 ripeTime;// 成熟时间
	uint32 gain;	// 产出量
	uint8 stealNum;	// 偷窃次数
	uint32 wateringTime;// 最后浇水时间
	uint32 wateringCount;
	uint32 killBugTime;	// 最后除虫时间
	uint32 killBugCount;
	string roleName;
	vector<uint32> thiefList;	// 偷窃角色ID列表
};

struct SPlantSeed
{
	uint16 itemId;
	string treeName;
	uint16 step_pic1;		// 模型1
	uint16 step_pic2;		// 模型2
	uint16 step_pic3;		// 模型3
	uint32 ripeTimeGap;		// 成熟时间间隔
	uint32 wateringTimeGap;
	uint32 wateringReduceTime;
	uint16 wateringLimit;	// 浇水次数上限
	uint32 killBugTimeGap;
	uint16 killBugLimit;	// 除虫次数上限
	uint8 stealNumLimit;	// 偷取次数上限
	uint8 gainType;
	uint32 gainValue;
	uint32 gainItemId;
	uint8 priceType;
	uint32 price;
	uint32 witheredTimeGap;	// 枯萎时间间隔
};

class CPlantSeedManager
{
public:
	CPlantSeedManager(){}
	~CPlantSeedManager(){}

	bool Init();
	SPlantSeed *FindSeed(uint32 id);

private:
	map<uint16,SPlantSeed *> m_seedData;
};

struct SBP_BuffCfg
{
	SBP_BuffCfg()
	{
		id = 0;
		maxLevel = 0;
		cost = 0;
	}

	uint8 maxLevel;
	uint16 id;
	SAttrData attr;
	int cost;
};

struct SBP_HuoYueAwardCfg
{
	SBP_HuoYueAwardCfg()
	{
		id = 0;
		activity = 0;
		rewardFixId = 0;
	}

	uint16 id;
	uint32 activity;
	int rewardFixId;
};


class CBP_CfgMgr
{
public:
	CBP_CfgMgr();
	
	~CBP_CfgMgr();

	bool Init();

	SBP_BuffCfg *GetBuffCfg(uint16 id);

	void GetBuffIdList(vector<uint16> &vec);

	SBP_HuoYueAwardCfg *GetHuoYueCfg(int id);

	void GetHuoYueCfgList(vector<uint16> &vec);
	

private:
	map<uint16, SBP_BuffCfg> m_buffCfg;		// buff配置
	map<uint16, SBP_HuoYueAwardCfg> m_awardCfg;	// 活跃度奖励配置
};

struct SBPShangXianData
{
	SBPShangXianData()
	{
		Clear();
	}

	void Clear()
	{
		id = 0;
		name.clear();
		src_bangpai_id = 0;
		bangpai_id = 0;
		protect_time = 0;
		qinmi = 0;
		add_type = 0;
		add_value = 0;
		gift_id = 0;
		gift_num = 0;
		gift_banggong = 0;
		timer_time = 0;
	};
	
	uint16 id;
	string name;
	int src_bangpai_id;
	int bangpai_id;
	int protect_time;
	int timer_time;
	int qinmi;
	int add_type;	// 1速度2防御3减伤4韧性5闪避6攻击7暴击8气血9反伤10命中
	int add_value;
	int gift_id;
	int gift_num;
	int gift_banggong;
};

struct SBPShangXian_ModeInfo
{
	SBPShangXian_ModeInfo()
	{
		Clear();
	}
	void Clear()
	{
		id = 0;
		name.clear();
		type = 0;
		succ_ratio = 0;
		vip_limit = 0;
		for(uint16 i=0;i < 2;i++)
		{
			need_item_id[i] = 0;
			need_item_num[i] = 0;
			gain_type[i] = 0;
			gain_value[i] = 0;
		}
		loss_type = 0;
		loss_value = 0;
	}
	
	uint16 id;
	string name;
	uint16 type;	// 1交游2结交3奇谋4查验生石5查堕仙印
	int succ_ratio;
	int vip_limit;
	int need_item_id[2];
	int need_item_num[2];
	int gain_type[2];	// 1个人帮贡2帮派亲密度3帮派资金4帮派影响力
	int gain_value[2];
	int loss_type;		// 对方损失
	int loss_value;
};

struct SBPShangXian_SelfData
{
	SBPShangXian_SelfData()
	{
		Clear();
	}
	void Clear()
	{
		setTarget = 0;
		qinmi = 0;
	}
	
	uint8 setTarget;	// 0未设置1设置拉拢
	int qinmi;
};

struct SBangPaiMission
{
	SBangPaiMission()
	{
		Clear();
	}
	void Clear()
	{
		id = 0;
		name.clear();
		desc.clear();
		type = 0;
		value = 0;
		award_itemId = 0;
		award_itemNum = 0;
		award_type = 0;
		award_num = 0;
	}

	uint32 id;
	string name;
	string desc;
	uint32 type;	// 1捐金币2交游3查验生石4查堕仙印5奇谋6浇水7除虫8种植9偷菜10本帮击杀
	uint32 value;
	uint32 award_itemId;
	uint32 award_itemNum;
	uint32 award_type;	// 1个人帮贡2帮派亲密度3帮派资金4帮派影响力
	uint32 award_num;
};

struct SBPMission_SelfData
{
	SBPMission_SelfData()
	{
		Clear();
	}
	void Clear()
	{
		missionId = 0;
		isSelect = 0;
	}

	int missionId;
	int isSelect;	// 0未发布1已发布
};

struct SBP_JuanXianPaiHang
{
	SBP_JuanXianPaiHang()
	{
		Clear();
	}
	void Clear()
	{
		roleId = 0;
		name.clear();
		money = 0;
	}
	
	uint32 roleId;
	int money;
	string name;
};

struct SSortBP_JuanXian
{
	bool operator()(SBP_JuanXianPaiHang const &b1,SBP_JuanXianPaiHang const &b2)
	{
		return b1.money > b2.money;
	}
};

const uint8 BP_AREA_MAX_NUM = 5;	// 大菜地总数
static const uint8 PLANT_SEED_TYPE_COUNT_LIMIT[ZZGain_MAX_Type+1] = {0,3,2,3,2};//种子种类数量限制

class CBangPai
{
public:
	CBangPai():
		m_level(1),
		m_fanrong(0),
		m_money(0),
		m_title(0),
		m_paiMing(0),
		m_huoyue(0),
		m_rank(0),
		m_totolGongXian(0)
	{
		m_pic = 0;
		m_state = 1;
		m_tangzhu_rank = 0;
		m_chuangwei = 0;
		m_bangzhu_old = 0;
		dismissbang_time = 0;
		activity = 0;
		ZhongZhiMax = false;
		m_fireState = BPFire_OFF;
		m_onFireTime = 0;
		m_treeLv = 1;
		m_exp = 0;
		m_treeTotalExp = 0;
		m_treeExp = 0;
		m_treeRobbedExp = 0;
		m_treeRobbedNum = 0;
		m_prayNum = 0;
		m_prayExp = 0;
		m_totalPlantsNum = 0;
		m_havePlantedNum = 0;
		m_serverId = 0;

		m_lastAddRipeTime = 0;
		m_lastAddAwardTime = 0;
		m_addTreeExpTime = 0;
		m_todayBangGong = 0;
		m_yesterdayBangGong = 0;
		m_BZ_jifen = 0;
		m_kfBZ_jifen = 0;
		m_kfBZ_jifen_final = 0;
		m_xianzhun_lv = 0;
		m_yingxiangli = 0;
		m_updateMission = 0;
		m_tarCheChaBangId = 0;
		m_clearJXPaiHang = true;
		m_autoLimitLv = 0;
		memset(m_memberGetRewardNum,0,sizeof(m_memberGetRewardNum));

		m_isAddTreeExp = false;
		m_clearTreeData = false;
		for(uint8 i = 0; i < sizeof(m_guard)/sizeof(m_guard[0]); i++)
			m_guard[i].reset();
	}

	uint8 GetState()
	{
		return 0;
	}
	void DismissBang_updata();

	void SetId(uint32 id)
	{
		m_id = id;
	}
	uint32 GetId()
	{
		return m_id;
	}
	void SetPic(int pic)
	{
		m_pic = pic;
	}
	uint32 GetPic()
	{
		return m_pic;
	}
	
	uint16 GetRank()
	{
		return m_rank;
	}
	void SetRank(uint16 val)
	{
		m_rank = val;
	}
	void DelAskForJoin(uint32 id)
	{
		boost::mutex::scoped_lock lk(m_AskJoinmutex);
		m_askJoinUser.remove(id);
	}
	void GetAskForJoin(list<uint32> &userList)
	{
		boost::mutex::scoped_lock lk(m_AskJoinmutex);
		userList = m_askJoinUser;
	}
	void GetMember(list<uint32> &userList)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		userList = m_userList;
	}
	void ClearFightJiFen();
	void ClearKuaFuBZ_FinalJiFen();
	void AddAllMemberTitle(int title);

	uint16 GetMaxMemberNum();
	int GetMaxRankNum(uint8 rank);
	int GetMemNumByRank(uint8 rank);
	bool AddMember(CUser *pUser,uint8 rank);
	bool AddMemberNoLocked(uint32 roleId,uint8 rank);
	bool AddMemberLocked(uint32 roleId,uint8 rank);

	bool IsAskJoin(uint32 id);
	bool IsAdmin(uint32 id);
	void AcceptAllAskJoin(CUser *pUser,int type);
	int AddAskJoin(uint32 id);
	void DelMember(uint32 roleId, CUser *pUser = NULL);
	uint8 GetMemberRank(uint32 roleId);
	SBangPaiMember *NolockGetMemberData(uint32 roleId);
	void UpdateMemberName(int roleId,string &name);

	void SetMemberRank(uint32 roleId,uint8 rank);
	void GetMemberInfoById(uint32 memberId,SBangPaiMember &memberNode);
	void CheckChangeBangzhu();

	bool GetNextBangZhuData(SBangPaiMember &nextBangZhu);
	bool CheckDeleteBangPai(int time);
	void CheckBangZhu();

	void Read(char *);

#ifdef KUA_FU
	void KF_ReadMember(CNetMessage &msg);
	void KF_ReadSkill(CNetMessage &msg);
#endif
	
	void MakeSkillInfo(CNetMessage &msg);
	void ReadMember();
	void SetName(const char *name)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if(name != NULL)
			m_name = name;
	}
	string GetName()
	{
		//        boost::recursive_mutex::scoped_lock lk(m_mutex);
		return m_name;
	}
	uint8 GetLevel()
	{
		return m_level;
	}
	int GetFanRong()
	{
		return m_fanrong;
	}
	int GetMoney()
	{
		return m_money;
	}

	string GetKouHao()
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		return m_kouhao.c_str();
	}

	uint32 GetExp();
	void SetExp(uint32 t);
	void AddExp(uint32 t);
	uint32 GetLevelUpExp();

	void SetTreeLevel(uint8 lv);
	uint8 GetTreeLevel();

	uint32 GetTreeTotalExp();
	void SetTreeTotalExp(uint32 t);
	void AddTreeTotalExp(uint32 t);

	uint32 GetTreeExp();
	void SetTreeExp(uint32 t);
	void AddTreeExp(uint32 t);
	uint32 GetAddTreeExpTime();
	void SetAddTreeExpTime(uint32 t);
	void SetMemberReward(const char *pStr);

	void SetPrayNum(uint32 t);
	void AddPrayNum();
	uint32 GetPrayExp();
	void SetPrayExp(uint32 t);
	void AddPrayExp(uint32 t);

	uint32 GetTreeRobbedExp();
	void SetTreeRobbedExp(uint32 t);
	void AddTreeRobbedExp(uint32 t);
	uint8 GetTreeRobbedNum();
	void SetTreeRobbedNum(uint8 t);
	void AddTreeRobbedNum(uint8 t);
	bool AddTreeExpWithRobbedExp(int robExp);

	int GetTreeCanRobbedExp();	
	uint8 GetTreeMaxRobbedNum();

	void SaveBangPaiLog(CUser *pUser,uint16 type,const char *str);
	void SavePrayLog(CUser *pUser,uint8 prayType,string &log);
	void SendTreeMsg(CUser *pUser);
	void TreePray(CUser *pUser,uint8 type);
	void RobTree(CUser *pUser);
	void QueryTreeRobState(CUser *pUser);
	bool IsInRobTime();

	static int GetYBPrayConsume(int ybPrayIndex);

	uint32 GetPrayAddExp(uint8 type);

	void SetOnFireTime(uint32 t){m_onFireTime = t;}
	void SetFireState(uint8 state){m_fireState = state;}
	uint8 GetFireState(){return m_fireState;}
	uint32 GetOnFireTime(){return m_onFireTime;}

#ifdef KUA_FU
	void SetServerId(int id)
	{
		m_serverId = id;
	}
	int GetServerId()
	{
		return m_serverId;
	}
#endif

	int GetXianZhunGeLv(){return m_xianzhun_lv;}
	int GetYingXiangLi(){return m_yingxiangli;}
	double GetSupportRatio(int sxId,int srcQinMiVal)
	{
		double r = 0.0;
		int v = GetSXQinMi(sxId) - srcQinMiVal;
		if(v > 50000)
			r = 40.0;
		else if(v >= 0 && v <= 50000)
			r = 39.0 - (50000 - v)/1800.0;
		else if(v >= -20000 && v < 0)
			r = 28.0 - (50000 - v)/2500.0;
		return r;
	}
	int GetSupportRatioByLv()
	{
		int y=0,m=0,r=0;
		GetZhunXianGeLvUpInfo(m_xianzhun_lv,y,m,r);
		return r;
	}
	void SetXianZhunGeLv(int lv)
	{
		m_xianzhun_lv = lv;
	}
	int GetSXQinMi(int sxID);
	int NoLockGetSXQinMi(int sxID);
	void SetSXQinMi(int szID,int qinmi);
	uint8 GetSXTarget(int sxID);
	void SetSXTaget(int sxID,uint8 state);
	void ReadSX_Info(const char *str);
	void GetSX_Info(string &str);
	void ReadMission(const char *str);
	void GetMissionStr(string &str);
	void UpdateMission(const vector<SBangPaiMission> &mList);
	void ReadJuanXianPaiHang(const char *str);
	void GetJuanXianPaiHang(string &str);
	void AddJuanXianPaiHangData(uint32 roleId,int money,string name);
	void MakeJuanXianPaiHang(CNetMessage &msg);
	
	
	void SetYingXiangLi(int y)
	{
		m_yingxiangli = y;
	}
	void SetLevel(uint8 level)
	{
		m_level = level;
	}
	void SetFanRong(int fanrong)
	{
		m_fanrong = fanrong;
	}
	void SetMoney(int money)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		m_money = money;
	}
	void AddMoney(int money)
	{
		const int MAX = 2100000000;
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if(money > 0)
		{
			if(MAX - m_money < money)
				m_money = MAX;
			else
				m_money += money;
		}
		else
		{
			if(m_money + money < 0)
				m_money = 0;
			else
				m_money += money;
		}
	}

	void SetKouHao(const char *kouhao)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if(kouhao != NULL)
			m_kouhao = kouhao;	        
	}
	uint32 GetBangZhu()
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		for(map<uint32,SBangPaiMember>::iterator i = m_allMember.begin(); i != m_allMember.end(); i++)
		{
			if(i->second.rank == EBRBangZhu)
				return i->first;
		}
		return 0;
	}

	string GetBangZhuName();

	uint32 GetBangCreater()
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if(m_allMember.size() > 0)
			return (m_allMember.begin())->first;
		return 0;
	}
	uint16 GetMemberNum()
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		return m_allMember.size();
	}

	uint16 GetPlantedPlantNum()
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		return m_havePlantedNum;
	}

	uint16 GetTotalPlantsNum()
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		return m_totalPlantsNum;
	}

	string GetGongGao()
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		return m_gonggao;
	}
	void SetGongGao(const char *gonggao)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if(gonggao != NULL)
		{
			m_gonggao = gonggao;

		}
	}
	void SetPaiMing(int paiming)
	{
		m_paiMing = paiming;
	}
	uint16 GetPaiMing()
	{
		return m_paiMing;
	}
	
	void SetTitle(int title)
	{
		m_title = title;
	}
	int GetTitle()
	{
		return m_title;
	}
	void Record_bangzhu(uint32 id)
	{
		m_bangzhu_old = id;
	}
	uint32 GetTotolGongXian()
	{
		return m_totolGongXian;
	}
	void AddTotolGongXian(uint32 val)
	{
		m_totolGongXian += val;
	}
	void SetTotolGongXian(uint32 val)
	{
		m_totolGongXian = val;
	}
	
	void AddBZ_JiFen(int value){m_BZ_jifen += value;}
	void SetBZ_JiFen(int value){m_BZ_jifen = value;}
	int GetBZ_JiFen(){return m_BZ_jifen;}

	void AddBZ_JiFen_KF(int value){m_kfBZ_jifen += value;}
	void SetBZ_JiFen_KF(int value){m_kfBZ_jifen = value;}
	int GetBZ_JiFen_KF(){return m_kfBZ_jifen;}
	void AddBZ_JiFen_KF_Final(int value){m_kfBZ_jifen_final += value;}
	void SetBZ_JiFen_KF_Final(int value){m_kfBZ_jifen_final = value;}
	int GetBZ_JiFen_KF_Final(){return m_kfBZ_jifen_final;}
	
	void ShowBangZhanIcon(int flag);
	void ShowKuaFuBangZhanIcon(bool show);

	bool IsChuangwei()
	{
		return (m_chuangwei>0 ? true : false);
	}

	void PlantResource(CUser *pUser,uint16 itemId,uint8 plantIdx,uint8 cellPos);	// 种植
	void WateringPlant(CUser *pUser,uint8 plantIdx,uint8 cellPos);	// 浇水
	void KillPlantBug(CUser *pUser,uint8 plantIdx,uint8 cellPos);	// 除虫
	void ClearUpPlant(CUser *pUser,uint8 plantIdx,uint8 cellPos);	// 铲除
	void GainPlant(CUser *pUser,uint8 plantIdx,uint8 cellPos);	// 收获
	void StealPlant(CUser *pUser,uint8 plantIdx,uint8 cellPos);	// 偷菜
	void GetTaskReward(CUser *pUser,uint8 type);

	static void UpdateTaskInfo(CUser *pUser,uint8 type);	// 更新任务信息
	void GetTaskList(CUser *pUser);	// 获取帮派任务列表

	void AddMemberBangGong(CUser *pUser,int banggong,bool showTips=true);

	void LightFire(CUser *pUser);
	void ExtinguishFire(CUser *pUser);
	void NolockUpdateFireState();

	void StealFightEnd(CUser *pUser,uint8 plantIdx,uint8 cellPos,bool win);

	void SetGuard(CUser *pUser,uint8 guardIdx);	// 设置守卫
	void RemoveGuard(CUser *pUser,uint8 guardIdx);	// 解除守卫
	void NolockUpdateGuard(uint8 guardIdx);	// 更新守卫
	void QueryGuardMsg(CUser *pUser,uint8 guardIdx,uint8 type);

	void RemoveGuardByRoleId(uint32 roleId);

	void MakeZZMsg(CUser *pUser,CNetMessage &msg);	// 种植列表
	void GetPlantMsgByPosition(CUser *pUser,uint8 plantedIdx,uint8 cellPos,CNetMessage &msg);	// 某块地的详细信息
	bool NolockMakePlantCellMsg(uint8 plantedIdx,uint8 cellPos,CNetMessage &msg);
	void NoLockUpdateZZCell(uint8 plantedIdx,uint8 cellPos);
	void BroadcastAddPlantMsg(uint8 plantedIdx,uint8 cellPos);
	void SendBangPaiLogMsg(CUser *pUser);
	uint8 GetPlantCanStealNumByRole(CUser *pUser,SPlant &seed);
	void GetRewardByRank(CUser *pUser);

	void SaveZhongZhi();
	void InitZhongZhi(bool query = true);
	void InitGuard();
	void SaveGuard();
	void SaveBangPaiMember();

	bool GetZhongZhiInfo(uint32 ind,uint32 pos,SPlant &zz);
	void Timer();
	void PlantTimer();
	void FireTimer();
	void GodTreeTimer();
	void UpdateAllMemberZhanDouLi();
	void SendMailToAllMember(const char *pMsg,SMailData *pMailData=NULL);

	void Save();

	void SetState(uint8 s)
	{
		m_state = s;
	}
	uint8 GetDimisss()
	{
		return m_state;
	}

	bool HaveRight2DelMember(uint32 adminId,uint32 roleId);
	void SetCreateTime(time_t t)
	{
		m_createTime = t;
	}
	time_t GetCreateTime()
	{
		return m_createTime;
	}

	void SetActivity(int n);
	int GetActivity(){return activity;}
	void SetZhongZhiMax(){ZhongZhiMax = true;}
	void Say(const char* info); // 发送帮派信息
	void BroadcastMsg(CNetMessage &msg);

	void TipsToAllOnLineMembers(const char* info);
	void ShowTaskList(CUser *pUser,CNetMessage &msg);
	void GetPublishTaskList(CUser *pUser,CNetMessage &msg);
	void PublishTask(CUser *pUser,CNetMessage &msg,int missionId);
	void TakeTaskAward(CUser *pUser,CNetMessage &msg,int missionId);
	void GetJuanXianInfo(CUser *pUser,CNetMessage &msg);
	void JuanXian(CUser *pUser,CNetMessage &msg,uint8 type);
	void SetChectBangPaiTarget(CUser *pUser,CNetMessage &msg,uint8 type,int tarBP_id);
	int GetCheckTarBangId(){return m_tarCheChaBangId;}
	void SaveLog(int roleId,int tarBangPaiId,int type,const char *str1,const char *str2=NULL);
	void GetOptionLog(CNetMessage &msg,uint8 type);
	uint32 GetYesterdayBangGong(){return m_yesterdayBangGong;}

	void SetAutoAcceptSign(uint16 level);
	uint16 GetAutoAcceptLv();
	void UpdateHuoYue(CUser *pUser,int type,int num = 0);
	void UpdateMemberHuoYue(uint32 roleId, uint32 huoyue);
	void UpdateHuoYue_KuaFu(CUser *pUser,int type);
	void AddMemberHuoYue(uint32 roleid,int huoyue);
	uint16 GetMemberHuoYue(uint32 roleid);
	void DrawHuoYue(CNetMessage &msg,CUser *pUser,int type,int huoyue);//领取活跃奖励，@type 1-个人，2-帮派

	void AddUserHuoYue(CUser *pUser, int addHuoYue);
	void AddHuoYue(int huoYue);
	void SetHuoYue(int huoYue);
	int GetHuoYue();
	void UpgradeLianQiPavilion(CUser *pUser,uint8 type,CNetMessage &msg);
	uint8 GetLianQiPavilionLv(uint8 type);
	void GetLianQiPavilionLv(vector<uint8> &vec);
	void AddLianQiPavilionLv(uint8 type);
	void InitLianQiLv();
	void SetLianQiLv(const char *level);
	void UpSkillLv(CNetMessage &msg,CUser *pUser,int id,bool isAuto);
	int GetSkillLv(int id);
	void GetSkillLv(vector<SAttrTypeValue> &vec);
	void SetBangSkill(const char *skills);
	void GetBangSkill(string &str);
	void UpdateBangName2Member();

	void GetCopyStr(string &str);
	void SetCopy(const char *pStr);
	bool MakeCopyMsg(CNetMessage &msg, int chapId, int copyId);
	void MakeChapDamRankInfo(CNetMessage &msg, int chapId);
	bool MakeChapterMsg(CNetMessage &msg, CUser *pUser);
	bool AddNewChapCopy(bool sendMsg=true);
	bool InitCopy();
	void GetCopyBuffAttr(vector<SAttrData> &vec);
	bool CopyFight(CNetMessage &msg, CUser *pUser, int chapId, int copyId);
	bool RunMulCopyFight(CNetMessage &msg, CUser *pUser, int chapId, int copyId);
	bool UpdateGradeBuff(CNetMessage &msg, CUser *pUser, uint16 buffId);
	void GetBuffInfo(CNetMessage &msg);
	bool GetCopyNormalAward(CNetMessage &msg, CUser *pUser, int chapId, int copyId);
	bool GetHuoYueInfo(CNetMessage &msg, CUser *pUser);
	uint32 GetTodayHuoYue();
	bool GetHuoYueAward(CNetMessage &msg, CUser *pUser, int hyAwardId);

	void CheckHotPoint(uint16 type, uint32 roleId=0);

	time_t dismissbang_time;
	static const int MAX_XIAN_ZHUN_GE_LV = 20;
	static const int MoneyRatio = 10000;
	static const int ZXG_TASK_OPEN_LV = 2;
	static const uint8 BP_COPY_NUM = 10;	// 帮派副本每天参与次数
	static const uint32 JOIN_TIME_LIMIT = 3600;

private:
	void NolockSetStealData(CUser *pUser,uint8 plantIdx,uint8 cellPos,uint32 &stealValue);
	void AddStealAward(CUser *pUser,uint8 plantIdx,uint8 cellPos,uint32 stealValue,bool fightEnd=false);
	void GetLianQiLvStr(string &str);
	void ResetHuoYue();	// 重启前一天总活跃，用于副本buff升级

	void BroadcastOpenChapter(int chapterId);
	void BroadcastUpdateChapter(int chapterId);
	void BroadcastUpdateCopy(int chapterId, int copyId);

private:
	boost::recursive_mutex m_mutex;
	boost::mutex m_AskJoinmutex;
	uint32 m_id;
	uint32 m_pic;
	string m_name;
	list<uint32> m_adminUser;
	list<uint32> m_userList;
	list<uint32> m_askJoinUser;
	uint8 m_fireState;
	uint32 m_onFireTime;

	map<uint32,SBangPaiMember> m_allMember;
	vector<vector<SPlant> > m_plantData;
	ShareUserPtr m_guard[BP_AREA_MAX_NUM];

	vector<uint8> m_plantAreaLv;	// 菜地等级

	uint8 m_level;
	int m_fanrong;
	int m_money;
	int m_title;
	uint16 m_paiMing;
	int m_huoyue;	// 前一天所有成员活跃总和，用于副本buff升级
	int m_serverId;

	uint32 m_lastAddRipeTime;
	uint32 m_lastAddAwardTime;
	uint32 m_exp;
	uint16 m_totalPlantsNum;	// 可种植地块数量
	uint16 m_havePlantedNum;	// 已种植地块数量
	uint8 m_treeLv;	// 神树等级
	uint32 m_prayNum;	// 祈福次数
	uint32 m_prayExp;	// 祈福经验

	bool m_clearTreeData;		// 每天22点重置神树数据
	bool m_isAddTreeExp;		// 增加神树经验标识
	uint32 m_addTreeExpTime;	// 最后增加神树经验产出时间
	uint32 m_treeTotalExp;	// 神树每天总经验，定时清0
	uint32 m_treeExp;		// 神树当前经验,定时清0
	uint32 m_treeRobbedExp;	// 掠夺得到经验
	uint8 m_treeRobbedNum;	// 掠夺次数
	uint32 m_todayBangGong;		// 当天帮众获得的总帮贡
	uint32 m_yesterdayBangGong;	// 前一天帮众获得的总帮贡
	uint8 m_memberGetRewardNum[EBRRANK_MAX];

	list<SBangPaiLog> m_prayLog;	// 祈福记录上限5条
	list<SBangPaiLog> m_optionLog;	// 帮派操作记录

	time_t m_createTime;//帮派创建时间
	time_t m_chuangwei;	//传位
	uint32 m_bangzhu_old;
	uint8 m_tangzhu_rank;
	uint16 m_rank;			// 排名
	uint32 m_totolGongXian;	// 总贡献
	int m_BZ_jifen;
	int m_kfBZ_jifen;		// 跨服帮战积分
	int m_kfBZ_jifen_final;	// 跨服帮战积分-决赛

	uint8 m_state;
	string m_kouhao;
	string m_gonggao;
	int activity;
	bool ZhongZhiMax;
	int m_xianzhun_lv;
	map<int,SBPShangXian_SelfData> m_sx_data;
	vector<SBPMission_SelfData> m_mission;
	uint8 m_updateMission;	// 0未更新1已更新
	int m_yingxiangli;
	int m_tarCheChaBangId;
	vector<SBP_JuanXianPaiHang> m_juanxianPaiHang;
	bool m_clearJXPaiHang;
	uint16 m_autoLimitLv;	//自动接受申请等级限制； 
	vector<uint8> m_lianqi_vec;//炼器阁,等级
	map<int,int> m_skills;	//帮派技能key-id,value-level
	SBangPai_CopyInfo m_copyData;
};

struct SBangZhanRoleData
{
	SBangZhanRoleData()
	{
		roleId = 0;
		jifen = 0;
		name.clear();
	}
	uint32 roleId;
	uint32 bangId;
	int jifen;
	string name;
};

struct SSortBZJiFen
{
	bool operator()(CBangPai *const &b1,CBangPai *const &b2)
	{
		return b1->GetBZ_JiFen() > b2->GetBZ_JiFen();
	}
};
struct SSortBZJiFenEx
{
	SSortBZJiFenEx(map<int, int> t)
	{
		tower = t;
	}
	bool operator()(CBangPai *const &b1, CBangPai *const &b2)
	{
		int bt1 = 0;
		int bt2 = 0;
		map<int, int>::iterator it = tower.find(b1->GetId());
		if (it != tower.end())
		{
			bt1 += it->second;
		}
		it = tower.find(b2->GetId());
		if (it != tower.end())
		{
			bt2 += it->second;
		}
		if (bt1 > bt2)
			return true;
		else if (bt1 < bt2)
			return false;
		else if(bt1 == bt2)
			return b1->GetBZ_JiFen() > b2->GetBZ_JiFen();
		return false;
	}
	map<int, int> tower;
};

struct SSortBZJiFenKF
{
	bool operator()(CBangPai *const &b1,CBangPai *const &b2)
	{
		return b1->GetBZ_JiFen_KF() > b2->GetBZ_JiFen_KF();
	}
};

struct SSortBZJiFenKF_Final
{
	bool operator()(CBangPai *const &b1,CBangPai *const &b2)
	{
		return b1->GetBZ_JiFen_KF_Final() > b2->GetBZ_JiFen_KF_Final();
	}
};

struct SSortBZRoleJiFen
{
	bool operator()(SBangZhanRoleData const &b1,SBangZhanRoleData const &b2)
	{
		return b1.jifen > b2.jifen;
	}
};

struct SBP_ShangXianAttr
{
	SBP_ShangXianAttr()
	{
		Clear();
	}
	void Clear()
	{
		speed = 0;
		recovery = 0;
		jianshang = 0;
		renxing = 0;
		shanbi = 0;
		attack = 0;
		baoji = 0;
		maxHp = 0;
		fanshang = 0;
		mingzhong = 0;
	}

	int speed;
	int recovery;
	int jianshang;
	int renxing;
	int shanbi;
	int attack;
	int baoji;
	int maxHp;
	int fanshang;
	int mingzhong;
};

class CBangPaiManager
{
public:
	static const uint8 BP_FIGHT_LIMIT_LV = 1;	// 帮派等级限制
	static const uint8 BP_FIGHT_LIMIT_MEM_NUM = 1;	// 成员人数限制
	static const uint8 BP_FIGHT_ROLE_LIMIT_LV = 40;	// 角色等级限制
	static const int BP_FIGHT_LIMIT_ENTER_TIME = 3600*24;
	static const uint8 KF_BP_FIGHT_ROLE_LIMIT_LV = 60;	// 跨服帮战角色等级限制
	static const int MAX_KFBZ_GROUP = 8;
	static const int SHANG_XIAN_PROTECT_TIME = 24*3600;
	
public:
	CBangPaiManager():m_bangPaiList(100){}
	CBangPai *FindBangPai(uint32 id);
	CBangPai *CreateBangPai(CUser *pUser,const char *name,int pic,uint16 limitLv);

	void GetBangPaiTopList(uint16 topNum,vector<uint32> &bangpaiList);
	void MakeBangPaiList(CNetMessage &msg,uint32 bId,uint32 roleId,bool haveMeBang=true);
	void BangPaiHuoYuePaiHang(CUser *pUser,char *str);
	void DelBangPai(uint32 id);
	void Erase(uint32 id);
	bool Init();
	void SaveBangPai();
	void SaveData();
	void Timer();
	void BangZhanTimer();
	int GetMaxMissionNum();
	void MakeCheckBangPaiList(CUser *pUser,CNetMessage &msg);
	void GetShangXianAttr(uint32 bangpaiId,SBP_ShangXianAttr &attr);
	void GetBPQinMiPaiHang(CNetMessage &msg,uint16 sxId);
	void MakeHaveShangXianList(int bangId,CNetMessage &msg);
	void BangPaiShangXianTimer();
	void BangZhuTimer();
	bool IsInBangZhanWeek();

#ifdef KUA_FU
	void KF_ReadBangPai(CNetMessage &msg);
	void MakeBangFightOldMsg(CNetMessage &msg);
	void SetKuaFuBangList(vector<int> &val){ m_bz_idList = val; }
#endif
	
	void AddBangGong(CUser *pUser,int banggong,bool showTips=true);
	void AddBangPaiJiFen(CUser *pUser, int jifen);
	void AddBangPaiJiFen(uint32 guildId, int jifen);
	void DelAskJoin(int roleId);
	void AddExp(CUser *pUser,uint32 treeRobExp);
	bool AddRobTreeExp(CUser *pUser,uint32 robExp);

	void InitBangPaiMission();
	void InitBangPaiShangXian();
	void InitBangZhanData();
	void SaveBangZhanData();
	void SaveShangXianData();
	bool CreateBangFightList();
	void MakeBangFightMsg(CNetMessage &msg);
	void GetBangZhanBangPaiList(vector<uint32> &idList);
	bool IsInBangPaiFightList(uint32 bId);

	void MakeShangXianInfo(CNetMessage &msg,uint32 bangpaiID,uint32 roleId);
	void DuiHuanShangXianGift(CUser *pUser,CNetMessage &msg,uint16 sxId);
	void SetShangXianLaLongState(CUser *pUser,CNetMessage &msg,uint16 sxId,uint8 state);
	void GetShangXianModeInfo(CUser *pUser,CNetMessage &msg,uint16 type,uint16 sxId);
	void ShangXianOption(CUser *pUser,CNetMessage &msg,uint16 modeId,uint16 sxId=0,int chechaBangId=0);
	void ShangXianJieChu(CUser *pUser,CNetMessage &msg,uint16 sxId);
	void ShowTaskList(CUser *pUser,CNetMessage &msg);
	vector<SBangPaiMission> &GetMissionListData(){return m_missionList;}

#ifdef KUA_FU
	bool IsInBangPaiFightListOld(uint32 bId);
#endif
	
	int GetKuaFuBangZhanGroupIdx(uint32 bId);
	void ClearBangPaiFightJiFen();
	bool IsOpenBangPaiFight();
	void MakeBangZhanPaiHang(CUser *pUser,CNetMessage &msg);
	int GetBangZhanFirstBang();
	vector<int> GetBangZhanFirstBangList();
	void SendBangZhanAward();
	void ShowBangZhanIcon(int flag);

	static string GetRankName(uint8 rank);
	void SetFirstBang(uint32 bangId) { m_firstBang = bangId; }
	uint32 GetFirstBang() { return m_firstBang; }
private:
	vector<SBPShangXianData> m_shangxian_list;
	vector<SBPShangXian_ModeInfo> m_shangxian_mode;
	vector<SBangPaiMission> m_missionList;
	
#ifndef KUA_FU
	vector<CBangPai *> m_bz_bangRank;		// 参加帮战的帮派列表
#else
	static const int MAX_JOIN_BANGPAI_NUM = 40;
	vector<CBangPai *> m_bz_bangRank_old[MAX_KFBZ_GROUP];	// 参加跨服帮战预赛列表
	vector<CBangPai *> m_bz_bangRank[MAX_KFBZ_GROUP];		// 参加跨服帮战的帮派列表
#endif
	vector<SBangZhanRoleData> m_bz_roleRank;// 参加帮战的角色积分
	CHashTable<int,CBangPai*> m_bangPaiList;
	vector<int> m_bz_idList;

	boost::mutex m_mutex;
	int m_curId;
	uint32 m_firstBang;
};

#endif



