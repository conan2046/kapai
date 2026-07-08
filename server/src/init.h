#ifndef _INIT_H_
#define _INIT_H_

#include "xml.h"
#include "singleton.h"
#include "huo_dong_mgr.h"
#include "hero_cfg_manager.h"
#include "rapidjson/document.h"
#include <set>
#include "utility.h"

enum EMExtData32
{
	ED32_6 = 6,					// 答题开始事件  --当前题目计时用
	ED32_ShenHunMoney = 93,			// 神魂
	ED32_XZMoney = 466,			// 血战货币
	ED32_JingJiZuiGaoMing = 476, // 竞技场最高排名
	ED32_JingJiRand = 477, 	// 竞技场随机挑战随机名次
	ED32_JJCMoney = 480, 	// 竞技场货币
	ED32_KLMoney = 481, 	// 昆仑币
};

enum EMExtData16
{
	ED16_68 = 68, // 今日获取的神将个数
	ED16_69 = 69, // 竞技场剩余挑战次数
	ED16_70 = 70, // 今日获取法宝个数
	ED16_71 = 71, // 今日搜索法宝次数
	ED16_72 = 72, // 今日竞技场挑战次数
};

enum EMExtData8
{
	ED8_6 = 6,		// 今日答题次数
	ED8_35 = 35,	// 今日答题数
	ED8_683 = 683, // 今日答题正确数
};


const uint16 ArenaYuanBaoBase = 600;

struct SSkillData;
class CUser;

bool InitJsonConfig();
bool InitXMLConfig();
bool LoadJosnValue(const string& file, const char** titleArrs, const int* typeArrs, int size, rapidjson::Document& d, rapidjson::Value &_para);
bool ReadSingleAward(const rapidjson::Value &_arr, SAwardData& awards);
bool ReadMultiAward(const rapidjson::Value &_arr, MultiAward& awards);
bool ReadSingleCost(const rapidjson::Value &_arr, SCostData& costs);
bool ReadMultiCost(const rapidjson::Value &_arr, MultiCost& costs);
bool ReadSingleAttr(const rapidjson::Value &_arr, SAttrData& attrs);
bool ReadMultiAttr(const rapidjson::Value &_arr, MultiAttr& attrs);
bool ReadTupoAttr(const rapidjson::Value &_arr, TupoAttrVec& attrs);
bool ReadMultiSkill(const rapidjson::Value &_arr, vector<SSkillData>& skills);
bool ReadMultiTypeValue(const rapidjson::Value &_arr, MultiTypeValue& tvs);
bool ReadSingleTypeValue(const rapidjson::Value &_arr, TypeValue& tv);
void MakeFightEndMsg(CUser*, uint8 star, CNetMessage& msg, MultiAward* awards = NULL, int addType = 0);
void MakeMultiAwardMsg(std::vector<SAwardData> &awvec, CNetMessage& msg);
void SendAndMakeAwardMsg(CUser *pUser, std::vector<SAwardData> &awvec, CNetMessage& msg, bool showMsg = false, int addType = 0);
void MakeSingleAwardMsg(CUser* pUser, SAwardData& award, CNetMessage& msg);
void MergeMultiCost(MultiCost &inCost, MultiCost &outCosts);
void MergeSigleCost(MultiCost &inCost, SCostData &outCost);
void MakeSingleCostMsg(SCostData& cost, CNetMessage& msg);
void MakeMultiCostMsg(MultiCost& costs, CNetMessage& msg);
void MakeAwardMsg(SAwardData& ad, CNetMessage& msg);

struct SMountConfig
{
	SMountConfig()
	{
		id = 0;
		getWay = 0;
		getWay_num = 0;
		getWay_itemId = 0;
		buy_time_limit = 0;
		moveSpeed = 0;
		name.clear();
		desc.clear();
		error_msg.clear();
		attrList.clear();
	}

	int id;
	uint8 getWay;	// 0进阶获得 1 元宝购买 2 道具兑换
	int getWay_num;
	int getWay_itemId;
	int moveSpeed;	// 移动速度
	int jinjieId;	// 进阶获得坐骑id
	uint32 buy_time_limit;	// 购买时间限制
	string name;
	string desc;
	string error_msg;
	vector<SAwardData> jinjie_cost;
	vector<SAttrData> attrList;
};

struct SMountQH
{
	SMountQH()
	{
		level = 0;
		needExp = 0;
		attrList.clear();
	}

	int level;
	int needExp;
	vector<SAttrData> attrList;
};

class CMountConfigMgr
{
public:
	CMountConfigMgr()
	{
		m_mountList.clear();
		m_qhList.clear();
	}
	bool Init();
	SMountConfig *GetCfg(int id);
	SMountQH *GetQHCfg(int lv);
	void GetMountList(vector<int> &var);

private:
	map<int,SMountConfig> m_mountList;
	map<int,SMountQH> m_qhList;
};

typedef boost::details::pool::singleton_default<CMountConfigMgr> SingletonMountCfgMgr;

/////////////////////////////////////////////////////////////////////

struct SWingConfig
{
	void init()
	{
		wing_id = 0;
		getWay = 0;
		getWay_Num = 0;
		getWay_itemId = 0;
		name.clear();
		des_info.clear();
		err_info.clear();
		attrList.clear();
	}
	int wing_id;		//翅膀ID eg SWing::WT_Wing_21
	uint8 getWay;			//获取方式 0进阶获得;1元宝购买,元宝数;2道具兑换,道具数量,道具Id
	int getWay_Num;		//道具数量
	int getWay_itemId;	//道具Id
	string name;
	string des_info;	//描述信息
	string err_info;	//错误信息
	vector<SAttrData> attrList;	// 属性
};

struct SWingQH
{
	SWingQH()
	{
		level = 0;
		star = 0;
		needExp = 0;
		attrList.clear();
	}

	int level;
	int star;
	int needExp;
	vector<SAttrData> attrList;	// 属性
};

class CWingConfigMgr
{
public:
	CWingConfigMgr()
	{
		m_wingList.clear();
		m_qhList.clear();
	}
	bool Init();
	SWingConfig *GetCfg(int id);
	SWingQH *GetQHCfg(int lv,int star);
	void GetWingList(vector<int> &var);

private:
	map<int,SWingConfig> m_wingList;
	map<int,SWingQH> m_qhList;
};


typedef boost::details::pool::singleton_default<CWingConfigMgr> SingletonWingCfgMgr;


/////////////////////////////////////////////////////////////////////////////////////

struct SShenQiConfig
{
	SShenQiConfig()
	{
		Clear();
	}
	void Clear()
	{
		id = 0;
		name.clear();
		desc.clear();
		attrList.clear();
	}

	int id;
	string name;
	string desc;
	vector<SAttrData> attrList;
};

struct SShenQiPeiYang
{
	SShenQiPeiYang()
	{
		Clear();
	}
	
	void Clear()
	{
		level = 0;
		star = 0;
		needExp = 0;
		cur_shenqi = 0;
		next_shenqi = 0;
		add_shenqi = 0;
		attrList.clear();
	}

	int level;
	int star;
	int needExp;
	int cur_shenqi;
	int next_shenqi;
	int add_shenqi;
	vector<SAttrData> attrList;
};

class CShenQiConfigMgr
{
public:
	CShenQiConfigMgr()
	{
		m_shenqiList.clear();
		m_pyList.clear();
		m_nilStr = "";
	}
	bool Init();
	SShenQiConfig *GetCfg(int id);
	const string& GetShenQiName(int id) const;
	SShenQiPeiYang *GetPYCfg(int lv, int star);
	void GetShenQiList(vector<int> &var);

private:
	map<int,SShenQiConfig> m_shenqiList;
	map<int,SShenQiPeiYang> m_pyList;
	string m_nilStr;
};

typedef boost::details::pool::singleton_default<CShenQiConfigMgr> SingletonShenQiCfgMgr;

///////////////////////////////////////////////////////////////////////////////////////////

struct STeamFaBuCfgData
{
	STeamFaBuCfgData()
	{
		type = 0;
		openLv = 0;
		name.clear();
	}
	uint16 type;
	uint16 openLv;
	string name;
};

struct STeamFaBuData
{
	STeamFaBuData()
	{
		minLevel = 0;
		maxLevel = 0;
		teamId = 0;
	}
	bool operator==(const STeamFaBuData &info)
	{
		if(info.teamId == teamId)
			return true;
		return false;
	}
	uint16 minLevel;
	uint16 maxLevel;
	uint32 teamId;
};

class CTeamFaBuConfigMgr
{
public:
	CTeamFaBuConfigMgr()
	{
		m_cfgList.clear();
		m_fabuList.clear();
		m_teamList.clear();
		m_matchRoleList.clear();
		m_roleMap.clear();
	}
	bool Init();
	STeamFaBuCfgData *GetCfg(int id);
	void GetCfgList(vector<int> &var);
	bool InsertFaBuList(int type,uint32 teamId,uint16 minLv,uint16 maxLv);
	void RemoveFaBuTeam(int type,uint32 teamId);
	bool GetFaBuList(int type,list<STeamFaBuData> &var);
	bool GetFaBuListBackward(int type,list<STeamFaBuData> &var);
	bool FindTeamByType(int type,uint32 teamId);
	bool GetFaBuTeamInfo(int type,uint32 teamId,STeamFaBuData &var);
	bool GetFaBuTeamInfo(uint32 teamId,STeamFaBuData &var,int &type);
	void ChangeTeamIdByType(int type,uint32 srcTeamId,uint32 tarTeamId);
	void ChangeTeamInfo(int type,uint32 teamId,uint16 minLv,uint16 maxLv);

	// 匹配
	void GetMatchRoleList(int type,list<uint32> &var);
	void InsertMatchUser(int type,uint32 roleId);
	void RemoveMatchUser(int type,uint32 roleId);
	bool PlayerMatchFaBuTeam(int type,uint32 roleId,bool isInsert=false);
	bool TeamMatchPlayerList(int type,uint32 teamId);
	void MatchTimer();

private:
	bool NoLockInsertFaBuList(int type,uint32 teamId,uint16 minLv,uint16 maxLv);
	void NoLockRemoveFaBuTeam(int type,uint32 teamId);
	bool NoLockGetFaBuTeamInfo(int type,uint32 teamId,STeamFaBuData &var);

	boost::recursive_mutex m_mutex;
	map<int,STeamFaBuCfgData> m_cfgList;
	
	map<int,list<STeamFaBuData> > m_fabuList;	// type, teamIdList(后发布在前)
	map<uint32,int> m_teamList;		// teamId, type
	
	map<int,list<uint32> > m_matchRoleList;	// type,roleId(先发布在前)
	map<uint32,int> m_roleMap;	// roleId,type
};

typedef boost::details::pool::singleton_default<CTeamFaBuConfigMgr> SingletonTeamFaBuCfgMgr;

////////////////////////////////////////////////////////////////////////////////////////////////

enum EPetDrawType
{
	EPDT_Single = 1,	// 单抽
	EPDT_Time10 = 2,	// 十连
	EPDT_First10 = 3,	// 首次十连
};

struct SPetDrawPoolBasicData
{
	SPetDrawPoolBasicData()
	{
		Clear();
	}
	void Clear()
	{
		awardType = 0;
		id = 0;
		petstar = 0;
		petLevel = 0;
		itemNum = 0;
		ratio = 0;
	}
	uint16 awardType;	// 60002 神将，<60000 道具
	uint16 id;	// petid,itemid
	uint16 petstar;
	uint16 petLevel;
	uint16 itemNum;
	uint32 ratio;	// 权重
};

struct SPetDrawPoolData
{
	SPetDrawPoolData()
	{
		must_be_orange_times = 0;
		orange_pet_num = 0;
		save_times_ext8 = 0;
		needItemId = 0;
		needItemNum = 0;
		need_YB = 0;
		awardList.clear();
	}
	uint8 must_be_orange_times;	// 每隔多少次十连必得1只橙神将
	uint8 orange_pet_num;	// 每次十连获得橙神将以上个数
	uint16 save_times_ext8;	// 十连抽次数记录extdata8
	uint16 needItemId;
	uint16 needItemNum;
	uint32 need_YB;
	vector<SPetDrawPoolBasicData> awardList;
};

struct SPetDrawCfgData
{
	SPetDrawCfgData()
	{
		openLv = 0;
		name.clear();
		awardPool.clear();
	}
	uint16 openLv;
	string name;
	map<uint16,SPetDrawPoolData> awardPool;	// type,award(单抽、10连用type=1池，最后一个必出用type=2池)
};

class CPetDrawCfgMgr
{
public:
	CPetDrawCfgMgr()
	{
		m_cfgList.clear();
	}
	bool Init();
	bool MakePetDrawMsg(CUser *pUser,CNetMessage &msg);
	bool DoPetDraw(CUser *pUser,uint16 kind,uint16 type,CNetMessage &msg);

private:
	static const uint32 SingleTimeLimit = 24*3600;
	void SetAward(SPetDrawPoolBasicData &data,string &str);
	bool SinglePetDraw(CUser *pUser,SPetDrawPoolData &poolData,bool &isOrange,CNetMessage &msg,bool canDrawOrange=true, bool isSingel = true);
	int RandFromPool(vector<SPetDrawPoolBasicData> &pool);
	map<uint16,SPetDrawCfgData> m_cfgList;	// kind,SPetDrawCfgData
};

typedef boost::details::pool::singleton_default<CPetDrawCfgMgr> SingletonCPetDrawCfgMgr;

///////////////////////////////////////////////////////////////////////////////////////


enum ZhenFaMemberType
{
	EZFMT_NONE = 0,
	EZFMT_USER = 1,
	EZFMT_PET = 2,
};

struct SZhenFaMemData
{
	SZhenFaMemData()
	{
		Clear();
	}
	void Clear()
	{
		mem_type = EZFMT_NONE;
		mem_id = 0;
		fightPos = 0;
	}
	uint8 mem_type;
	uint8 fightPos;
	uint32 mem_id;	// 队员id或神将id
};

struct SZhenFaData
{
	SZhenFaData()
	{
		Clear();
	}
	void Clear()
	{
		zhenfaId = 0;
		zhenfaLevel = 0;
	}
	uint16 zhenfaId;
	uint8 zhenfaLevel;
};

struct SZhenFaBasicCfg
{
	SZhenFaBasicCfg()
	{
		id = 0;
		restrainList.clear();
		name.clear();
		for(uint8 i=0;i < sizeof(fightPos)/sizeof(fightPos[0]);i++)
		{
			fightPos[i] = 0;
			open_level[i] = 0;
		}
	}
	uint16 id;
	uint8 fightPos[ZHEN_FA_POS_NUM];
	uint16 open_level[ZHEN_FA_POS_NUM];
	vector<uint16> restrainList;	// 克制阵法Id
	string name;
};

struct SZhenFaLevelUpData
{
	SZhenFaLevelUpData()
	{
		id = 0;
		level = 0;
		zhandouli = 0;
		for(uint8 i=0;i < ZHEN_FA_POS_NUM;i++)
		{
			attrList[i].clear();
		}
	}
	uint16 id;
	uint8 level;
	MultiCost costs;
	uint32 zhandouli;
	vector<SAttrData> attrList[ZHEN_FA_POS_NUM];
};

class CZhenFaCfgMgr
{
public:
	CZhenFaCfgMgr()
	{
		m_zhenfaData.clear();
		m_zhenfaUp.clear();
	}
	~CZhenFaCfgMgr()
	{
		m_zhenfaData.clear();
		m_zhenfaUp.clear();
	}

	bool Init();

	SZhenFaBasicCfg *GetBasicCfg(uint16 id);
	SZhenFaLevelUpData *GetLevelUpCfg(uint16 id,uint8 level);
	uint16 GetDefaultId(){return DEFAULT_ZHEN_FA_ID;}
	bool IsKeZhi(uint16 srcId,uint16 tarId);

private:
	static const uint16 DEFAULT_ZHEN_FA_ID = 1;
	void SetRestrainData(vector<uint16> &data,string &str);
	void SetAttrData(vector<SAttrData> &data,string &str);

	map<uint16,SZhenFaBasicCfg> m_zhenfaData;	// <id,cfg>
	map<uint32,SZhenFaLevelUpData> m_zhenfaUp;	// 强化消耗及属性 <id|level, upcfg>
};

typedef boost::details::pool::singleton_default<CZhenFaCfgMgr> SingletonCZhenFaCfgMgr;


///////////////////////////////////////////////////////////////////////////////////////////


struct SAttrTypeData
{
	SAttrTypeData()
	{
		type = 0;
		zhandouliRatio = 0;
		name.clear();
	}
	int type;
	int zhandouliRatio;	// value=zhandouliRatio/10;
	string name;
};

class CAttrCfgMgr
{
public:
	CAttrCfgMgr()
	{
		m_data.clear();
	}
	~CAttrCfgMgr()
	{
		m_data.clear();
	}

	bool Init();
	SAttrTypeData *GetCfg(int type);
	int GetTypeRatio(int type);
	const char *GetTypeName(int type);
	int CalulateZhanDouLi(SUnitBasicAttr &unitAttr);
	int CalulateZhanDouLi(vector<SAttrData> &attrList);

private:
	map<int, SAttrTypeData> m_data;
};

typedef boost::details::pool::singleton_default<CAttrCfgMgr> SingletonCAttrCfgMgr;


/////////////////////////////////////////////////////////////////////////////////////////

struct SUserSkillList
{
	SUserSkillList()
	{
		skillId = 0;
		openLevel = 0;
	}
	int skillId;	
	int openLevel;
};

struct SUserProCfgData
{
	SUserProCfgData()
	{
		profession = 0;
		attack_type = 0;
		attrList.clear();
		skillList.clear();
	}
	int profession;
	int attack_type;
	vector<SAttrData> attrList;
	vector<SUserSkillList> skillList;
};

struct SUserBasicLevelData
{
	SUserBasicLevelData()
	{
		profession = 0;
		level = 0;
		attack = 0;
		wufang = 0;
		fafang = 0;
		qixue = 0;
		sudu = 0;
		mingzhong = 0;
		shanbi = 0;
		baoji = 0;
		baojiKang = 0;
	}
	int profession;
	int level;
	int attack;
	int wufang;
	int fafang;
	int qixue;
	int sudu;
	int mingzhong;
	int shanbi;
	int baoji;
	int baojiKang;
};

class CUserCfgMgr
{
public:
	CUserCfgMgr()
	{
		m_data.clear();
		m_levelData.clear();
	}
	~CUserCfgMgr()
	{
		m_data.clear();
		m_levelData.clear();
	}

	bool Init();
	SUserProCfgData *GetBasicCfg(int profession);
	SUserBasicLevelData *GetLevelAttr(int profession,int level);

private:
	bool SetUserSkillData(vector<SUserSkillList> &data,string &str);
	
	map<int,SUserProCfgData> m_data;	// 基础属性
	map<int,SUserBasicLevelData> m_levelData;	// 等级属性
};

typedef boost::details::pool::singleton_default<CUserCfgMgr> SingletonCUserCfgMgr;


//////////////////////////////////////////////////////////////////////////////////////////////

struct SFindResCfg
{
	SFindResCfg()
	{
		Clear();
	}
	void Clear()
	{
		type = 0;
		cost.Clear();
		level.clear();
		award.clear();
	}

	uint8 type;	// 1 按次数找回, 2 没参与才能找回
	SCostData cost;
	vector<vector<uint16> > level;
	vector<vector<SAwardData> > award;
};

class CFindResourceManager
{
public:
	CFindResourceManager()
	{
		m_findList.clear();
	}

	~CFindResourceManager()
	{
		m_findList.clear();
	}

	bool Init();
	
	bool GetResourceCfg(int funcId, SFindResCfg &val);

	void GetFindResFuncIds(vector<int> &vec);

	bool GetAwardInfo(int funcId, uint16 level, SCostData &cost, vector<SAwardData> &award);

private:
	map<int, SFindResCfg> m_findList;	// [funcId]--data
};

typedef boost::details::pool::singleton_default<CFindResourceManager> SingletonCFindResourceMgr;

///////////////////////////////////////////////////////////////////////////////////////////

typedef vector<SAttrData> STitleAttrs;
typedef map<int, STitleAttrs> SAllTitleAttrs;
typedef map<int, STitleAttrs>::iterator SAllTitleAttrsIt;
class CTitltAttrCfgManager
{
public:
	CTitltAttrCfgManager()
	{
		m_allTitleAttrs.clear();
	}
	~CTitltAttrCfgManager()
	{
		m_allTitleAttrs.clear();
	}

	bool Init();
	STitleAttrs* GetTitleAttrs(uint16 titleId);
	// 获取称号属性加成
	uint32 GetTitleAddPower(uint16 title);
	// 是否需要重新计算神将物属性
	bool IsNeedRecalcPetAttr(uint16 title);
	const char *GetTitleName(uint16 title);
	// 获取称号有效时间
	uint32 GetTitleContinueTime(uint16 title, uint32 time);
	// 是否是非永久称号
	bool IsForeveryTitle(uint16 title);
private:
	SAllTitleAttrs m_allTitleAttrs;
	map<int, bool> m_needRecalcs;
	map<int, string> m_names;
	set<int> m_notForeveryTitle; // 非永久称号
	map<int, uint32> m_continueTime; // 持续时间
};

typedef boost::details::pool::singleton_default<CTitltAttrCfgManager> SingletonCTitltAttrCfgManager;
#define sTitltAttrCfgManager SingletonCTitltAttrCfgManager::instance()

struct CSystemOpenCfg
{
	CSystemOpenCfg()
	{
		id = 0;
		type = 0;
		show_icon = false;
		before_time = 0;
		start_time = 0;
		end_time = 0;
		openWeekday.clear();
		openCond.clear();
	}
	uint32 id;
	uint32 type; // 0 ||, 1 &&
	bool show_icon;
	uint16 before_time;
	uint16 start_time;
	uint16 end_time;
	uint8 show;
	std::map<uint8,uint8> openWeekday;
	MultiTypeValue openCond;
};

enum SYSTEM_OPEN_TYPE
{
	SOT_DailyBoss = 1,            // 日常boss
	SOT_ShiMen = 2,				  // 师门任务
	SOT_ChuangGuan = 3,           // 多人闯关,昆仑寻宝
	SOT_Lingqijuanxian = 4,       // 灵气捐献
	SOT_Kunlunshan = 5,           // 诸天幻境
	SOT_Fish = 6,                 // 钓鱼
	SOT_Baihua = 8,               // 百花仙子
	SOT_Nianshou = 9,             // 年兽
	SOT_TongTianTa = 14,          // 通天塔
	SOT_Husong = 16,              // 护送神将
	SOT_Bangpailingmo = 17,       // 挑战灵魔
	SOT_Yabiao = 20,              // 运镖
	SOT_ShaDiDuoBao = 24,         // 杀敌夺宝
	SOT_WeiHuDanYuan = 25,        // 维护丹园
	SOT_LeiTaiSai = 26,           // 擂台赛
	SOT_TreasureMap = 29,         // 藏宝图
	SOT_Shilian = 30,             // 英勇试炼
	SOT_FeiXian = 31,             // 封神战场
	SOT_ZhuoGui = 32,             // 捉鬼
	SOT_Liujieshizhe = 33,        // 六界使者
	SOT_BangPaiLueDuo = 34,       // 帮派掠夺
	SOT_MoneyTree = 35,           // 摇钱树
	SOT_BangPaiZhan = 36,         // 帮派战
	SOT_XiuXianLiLian = 37,       // 修仙历练
	SOT_KuaFuLunDao = 39,		  // 神界论道
	SOT_ShenJieMiJing = 41,		  // 神界秘境
	SOT_Shuangbei = 51,           // 双倍
	SOT_Spirit = 52,              // 体力
	SOT_Bangpai = 120,
	SOT_Qianghua = 131,
	SOT_Shengjie = 132,
	SOT_Cuilian = 133,
	SOT_Xilian = 134,
	SOT_Zuoqi = 140,
	SOT_Zuoqi_Jinjie = 141,
	SOT_Zuoqi_Shengxing = 142,
	SOT_Shenjiang = 150,
	SOT_Shenjiang_Jineng = 151,
	SOT_Shenjiang_Shengxing = 152,
	SOT_Shenjiang_Xiulian = 153,
	SOT_Zhenfa = 154,
	SOT_PetDraw = 160,
	SOT_RoleSkill = 170,
	SOT_Wing = 190,
	SOT_Wing_Jinjie = 191,
	SOT_ShenQi_Shouji = 200,
	SOT_ShenQi_Jinjie = 201,
	SOT_Shop_Normal = 210,
	SOT_Shop_Shenmi = 211,
	SOT_Shop_Bind = 212,
	SOT_Shop_Tegong = 213,
	SOT_Shop_Jifen = 214,
	SOT_Huodong = 220,
	SOT_Fuli = 230,
	SOT_Fuben = 240,
	SOT_Arena = 250,	// 竞技场
	SOT_Rank = 260,//排行榜
	SOT_VIP = 280,
	SOT_Team = 290,
	SOT_Social = 300, // 社交
	SOT_SocialMail = 301, // 邮件
	SOT_SocialChat = 302, // 社交好友
	SOT_WorldChat = 330,
	SOT_Qiecuo = 340,
	SOT_FightSpeed2 = 360,
	SOT_JingJie = 380,	// 境界
	SOT_KuaFu_SYS = 390,	// 跨服系统
	SOT_KuaFuShilian = 400,	// 跨服试炼
};


enum SYSTEM_OPEN_NEW
{
	SOT_1 = 1,    // 游历三界
	SOT_2 = 2,    // 封神试炼
	SOT_3 = 3,    // 封神列传
	SOT_4 = 4,    // 主线副本
	SOT_5 = 5,    // 支线副本
	SOT_6 = 6,    // 竞技场
	SOT_7 = 7,    // 决战昆仑
	SOT_8 = 8,    // 血战到底
	SOT_9 = 9,    // 法宝搜索
	SOT_10 = 10,   // 每日任务
	SOT_11 = 11,   // 七日目标
	SOT_12 = 12,   // 好友赠送
	SOT_18 = 18,   // 体力赠送
	SOT_21 = 21,   // 昆仑寻宝
	SOT_22 = 22,   // 境界
	
	SOT_1010 = 1010, // 神将招募
	SOT_1011 = 1011, // 神将招募（友情）
	SOT_1020 = 1020, // 封神试炼
	SOT_1021 = 1021, // 封神试炼扫荡
	SOT_1022 = 1022, // 金币试炼
	SOT_1023 = 1023, // 突破试炼
	SOT_1024 = 1024, // 经验试炼
	SOT_1025 = 1025, // 法宝试炼
	
	SOT_1030 = 1030, // 神将阵容
	SOT_1031 = 1031, // 神将1号上阵位
	SOT_1032 = 1032, // 神将2号上阵位
	SOT_1033 = 1033, // 神将3号上阵位
	SOT_1034 = 1034, // 神将4号上阵位
	SOT_1035 = 1035, // 神将5号上阵位
	SOT_1040 = 1040, // 神将布阵
	SOT_1050 = 1050, // 强化大师
	SOT_1060 = 1060, // 神将升级
	SOT_1061 = 1061, // 神将一键升级
	SOT_1070 = 1070, // 神将升星
	SOT_1071 = 1071, // 神将升星万能碎片
	SOT_1080 = 1080, // 神将突破
	SOT_1090 = 1090, // 神将图鉴
	SOT_1091 = 1091, // 神将碎片
	SOT_1100 = 1100, // 神将背包
	SOT_1110 = 1110, // 装备背包
	SOT_1120 = 1120, // 装备强化
	SOT_1130 = 1130, // 装备精炼
	SOT_1131 = 1131, // 装备一键精炼
	SOT_1140 = 1140, // 装备觉醒
	SOT_1141 = 1141, // 装备觉醒一键升星
	SOT_1142 = 1142, // 装备觉醒一键兑换
	SOT_1045 = 1045, // 武器装备栏解锁
	SOT_1046 = 1046, // 靴子装备栏解锁
	SOT_1047 = 1047, // 衣服装备栏解锁
	SOT_1048 = 1048, // 护腕装备栏解锁
	SOT_1150 = 1150, // 装备神铸
	SOT_1151 = 1151, // 装备神铸一键升层
	SOT_1152 = 1152, // 装备神铸一键升阶
	SOT_1160 = 1160, // 英勇试炼（血战）
	SOT_1161 = 1161, // 英勇试炼一键扫荡
	SOT_1170 = 1170, // 关卡
	SOT_1171 = 1171, // 关卡扫荡
	SOT_1180 = 1180, // 法宝系统
	SOT_1181 = 1181, // 法宝一键搜索
	SOT_1182 = 1182, // 法宝强化
	SOT_1183 = 1183, // 法宝精炼
	SOT_1210 = 1210, // VIP
	SOT_1220 = 1220, // 社交
	SOT_1221 = 1221, // 社交/邮件
	SOT_1222 = 1222, // 社交/好友
	SOT_1230 = 1230, // 世界聊天
	SOT_1240 = 1240, // 切磋
	SOT_1250 = 1250, // 自动战斗
	SOT_1251 = 1251, // 加速战斗X2
	SOT_1260 = 1260, // 称号
};
typedef map<int, CSystemOpenCfg> CSystemOpenCfgs;
class CSystemOpenCfgMananger
{
public:
	CSystemOpenCfgMananger()
	{
		m_allSystemCfgs.clear();
	}
	~CSystemOpenCfgMananger()
	{
		m_allSystemCfgs.clear();
	}

	bool Init();
	bool CheckSystemOpen(CUser *pUser, int sysId);
	bool CanShow(int sysId);
	bool OpenWeekDay(int sysId);
	bool GetFuncLvTime(int sysId,uint16 &b_time,uint16 &s_time,uint16 &e_time);
	uint32 GetFuncOpenLevel(int sysId);
	
private:
	CSystemOpenCfg* GetSystemCfg(int id);

private:
	CSystemOpenCfgs m_allSystemCfgs;
};

typedef boost::details::pool::singleton_default<CSystemOpenCfgMananger> SingletonCSystemOpenCfgMgr;
#define sSystemOpenCfgMananger SingletonCSystemOpenCfgMgr::instance()

struct tagSkillLvUpCost
{
	tagSkillLvUpCost()
		: pos(0), level(0)
		, learnLevel(0), moneyCost(0)
		, qiannengCost(0)
	{

	}
	int pos;
	int level;
	int learnLevel;
	int moneyCost;
	int qiannengCost;
};

typedef map<int, tagSkillLvUpCost> MSkillLvCosts;
typedef map<int, MSkillLvCosts> roleSkillLvUps;
class CRoleSkillLvUpCfgMananger
{
public:
	CRoleSkillLvUpCfgMananger()
	{
		m_allLvUpCosts.clear();
	}
	~CRoleSkillLvUpCfgMananger()
	{
		m_allLvUpCosts.clear();
	}

	bool Init();
	tagSkillLvUpCost* GetSkillLvUpCost(int pos, int level);
private:
	void AddCostCfg(tagSkillLvUpCost cost);

private:
	roleSkillLvUps m_allLvUpCosts;
};

#define sRoleSkillLvUpCfgMananger boost::details::pool::singleton_default<CRoleSkillLvUpCfgMananger>::instance()


/////////////////////////////////////////////////////////////////////////////////////////////

struct SFengShenCfg
{
	SFengShenCfg()
	{
		id = 0;
		index = 0;
		open_weekDay = 0;
		memset(level_reward,0,sizeof(level_reward));
		bossId = 0;
		fightId = 0;
		show_award.clear();
		recommend_pets.clear();
		desc.clear();
	}

	uint8 open_weekDay;		// 位变量
	uint8 index;
	uint16 id;
	int level_reward[3];	// star reward, 0: 1star 1: 2star 2: 3star
	int bossId;
	int fightId;
	vector<uint16> show_award;
	vector<uint16> recommend_pets;
	string desc;
};

class CFengShenMgr
{
public:
	CFengShenMgr()
	{
		m_cfg.clear();
	}

	~CFengShenMgr()
	{
		m_cfg.clear();
	}

	bool Init();
	void SendFengShenBossMsg(CUser *pUser);
	SFengShenCfg *GetFengShenBossCfg(uint16 id);

	int GetFSFightNum();
	
	static const uint8 CAN_DO_NUM = 2;

private:
	vector<SFengShenCfg> m_cfg;
};

typedef boost::details::pool::singleton_default<CFengShenMgr> SingletonCFengShenMgr;

////////////////////////////////////////境界///////////////////////////////////////////////////

struct SJingJieCfg
{
	SJingJieCfg()
	{
		Clear();
	}
	void Clear()
	{
		lv = 0;
		quality = 0;
		lvCond = 0;
		powerCond = 0;
		name.clear();
		costs.clear();
		attr.clear();
	}

	uint8 lv;
	uint8 quality;
	uint8 lvCond;
	uint64 powerCond;
	string name;
	MultiCost costs;
	vector<SAttrData> attr;
};

class CJingJieManager
{
public:
	CJingJieManager()
	{
		m_cfg.clear();
	}

	~CJingJieManager()
	{
		m_cfg.clear();
	}

	bool Init();
	bool GetCfg(int jingjieID,SJingJieCfg &val);

private:
	map<int,SJingJieCfg> m_cfg;
};

typedef boost::details::pool::singleton_default<CJingJieManager> SingletonCJingJieMgr;


///////////////////////////////////////////////////////////////////////////////////////

struct SBangPaiHuoYueData
{
	SBangPaiHuoYueData()
	{
		Clear();
	}
	void Clear()
	{
		type = 0;
		param = 0;
		huoyue = 0;
		name.clear();
	}
	int type;
	int param;
	int huoyue;
	string name;
};

class CBangPaiHuoYueMgr
{
public:
	CBangPaiHuoYueMgr()
	{
		m_data.clear();
		m_size = 0;
	}
	~CBangPaiHuoYueMgr()
	{
		m_data.clear();
	}

	bool Init();
	bool GetCfg(int type,SBangPaiHuoYueData &val);
	int GetHuoYue(int type);
	int GetParam(int type);

private:
	int m_size;
	map<int,SBangPaiHuoYueData> m_data;
};

typedef boost::details::pool::singleton_default<CBangPaiHuoYueMgr> SingletonCBPHuoYueCfgMgr;

///////////////////////////////////////////////////////////////////////////////////////

struct SBangPaiHuoYueReward
{
	SBangPaiHuoYueReward()
	{
		Clear();
	}
	void Clear()
	{
		huoyue = 0;
		rewardid = 0;
		idx = 0;
	}
	int rewardid;
	int huoyue;
	int idx;
};

class CBangPaiHYRewardMgr
{
public:
	CBangPaiHYRewardMgr()
	{
		m_data.clear();
		m_singledata.clear();
		m_size = 0;
		m_maxHuoYue = 0;
		m_maxSingleHuoYue = 0;
	}
	~CBangPaiHYRewardMgr()
	{
		m_data.clear();
		m_singledata.clear();
	}

	bool Init();
	bool GetCfg(int type,int huoyue,SBangPaiHuoYueReward &val);
	int GetMaxHuoYue(int type);
	void GetHuoYueDrawInfo(int type,std::vector<SBangPaiHuoYueReward> &vec);

private:
	int m_size;
	map<int,SBangPaiHuoYueReward> m_data;
	map<int,SBangPaiHuoYueReward> m_singledata;
	int m_maxHuoYue;
	int m_maxSingleHuoYue;
};

typedef boost::details::pool::singleton_default<CBangPaiHYRewardMgr> SingletonCBPRewardCfgMgr;

///////////////////////////////////////////////////////////////////////////////////////
struct SBangPaiLianQiData
{
	SBangPaiLianQiData()
	{
		Clear();
	}
	void Clear()
	{
		level = 0;
		type = 0;
		money = 0;
        addValue = 0;
	}
	int level;//等级
	int type;//type
	int money;
	int addValue;
};

class CBangPaiLianQiMgr
{
public:
	CBangPaiLianQiMgr()
	{
		m_data.clear();
		m_maxType = 0;
		
	}
	~CBangPaiLianQiMgr()
	{
		m_data.clear();
	}

	bool Init();
	bool GetCfg(int level,int type,SBangPaiLianQiData &val);
	int GetValue(int level,int type);
	int GetMaxType();

private:
	int m_maxType;//类型数量
	map<string,SBangPaiLianQiData> m_data;//level_type
};

typedef boost::details::pool::singleton_default<CBangPaiLianQiMgr> SingletonCBPLianQiCfgMgr;
#define sCBPLianQiCfgMgr SingletonCBPLianQiCfgMgr::instance()

///////////////////////////////////////////////////////////////////////////////////////
struct SAttrTypeValue
{
	SAttrTypeValue()
	{
		type = 0;
		value = 0;
	}
	int type;
	int value;
};

struct SBangPaiSkillData
{
	SBangPaiSkillData()
	{
		Clear();
	}
	void Clear()
	{
		level = 0;
		type = 0;
		id = 0;
        attrs.clear();
        cost.clear();
        singleCost.clear();
	}
	int id;//id
	int level;//等级
	int type;//生效对象-1、主角，2、神将，3-全部
	vector<SAttrData> attrs;
	vector<SCostData> cost;//帮派升级消耗
	vector<SCostData> singleCost;//玩家神将消耗
};

struct SBangPaiSkillInfo
{
	SBangPaiSkillInfo()
	{
		Clear();
	}
	void Clear()
	{
		info.clear();
	}
	map<int,SBangPaiSkillData> info;
};

class CBangPaiSkillMgr
{
public:
	CBangPaiSkillMgr()
	{
		m_data.clear();	
		m_skillIds.clear();	
	}
	~CBangPaiSkillMgr()
	{
		m_data.clear();
		m_skillIds.clear();
	}

	bool Init();
	bool GetCfg(int id,int level,SBangPaiSkillData &val);
	void GetSkillIds(vector<int> &skillIds);

private:
	map<int,SBangPaiSkillInfo> m_data;//key-id
	vector<int> m_skillIds;
};

typedef boost::details::pool::singleton_default<CBangPaiSkillMgr> SingletonCBPSkillCfgMgr;
#define sCBPSkillCfgMgr SingletonCBPSkillCfgMgr::instance()
///////////////////////////////////////////////////////////////////////////////////////


#endif


