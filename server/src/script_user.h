class CScene;

class CUser
{
public:
	bool Init();
	uint32 GetUserId();
	uint32 GetRoleId();
	uint8 GetFace();
	CScene *GetScene();

	uint32 GetFightId();
	uint16 GetOriAd();
	const char *GetName();
	uint8 GetSex();
	uint16 GetX();
	uint16 GetY();
	uint16 GetLevel();
	uint8 GetCanDoRingBossNum();

	//int64 GetExp();
	const char *GetExpStr();

	int AddCollect(int npcId,int npcIdx,int sceneId,int x,int y); // 添加采集npc
	int DelCollect(int npcId,int npcIdx,int sceneId); // 删除采集npc
	int GetCollectIndex(); // 获取当前采集npc的索引

	uint8 GetVipLevel();
	void AddExVipExp(uint32 val);
	void UpdateVipInfoEx();

	int GetMaxHp();
	void SetUserDouble(int hour);
	void SetUserDoubleTime(int time);

	void SetName(const char *name);
	void AddLevel();         //等级
	void SendMailByLevel();
	int AddExp(int exp, bool isSend = false, bool fightEnd = false);            //经验
	void UptoLevel(int level); // 直升等级到多少级，不会降级

	void AddHp(int hp);              //气血

	void AddExpByItemWithTips(int exp,bool sendTipsFightEnd=false);

	void AddDamage(int damage);
	void AddSkillDamage(int skillDamage);
	void AddRecovery(int recovery);
	void AddSpeed(int speed);
	bool AddPackage(SItemInstance &item);
	bool AddPackage(int itemId,int num = 1);	//增加物品，指定物品id，目前不支持指定物品数量            
	bool DelPackage(int pos,int num = 1); //删除物品，指定物品在包裹里的位置，0-35，直接清除格子        
	void SetAutoLevelUp(uint8 type,uint8 level,int endTime);//设置自动升级

	int GetTeamMemberNum(); // 获取队伍人数

	void AddMoney(int add);			//增加绑定金币

	bool HaveTeam();

	void SaveEnterPos(int sceneId, int posX, int posY); // 进入副本前位置信息 设置
	uint8 GetBossMissionTotolStarNum();

	// 金币相关
	uint32 GetMoney();
	void SetMoney(uint32 money);	

	uint32 GetTeam();
	uint32 TempLeaveTeam();
	void RecoveryAllHp();

	void DelPet(uint16 petId);
	bool DelPetWithNoLock(uint16 petId);
	void SetMonthCard(uint8 type);

	void SetCall(int script,const char *call);
	void SendYaBiaoMissionState(uint8 type,uint8 quality);

	uint16 GetTeamLevel();
	bool IsXunChaShiKilled(int npcId,int index);
	void SetXunChaShiKilled(int npcId,int index);

	bool AcceptCMission(int id,const char *pInts,const char *pStrs);
	bool AddTeamCMission(int id,const char *pInts,const char *pStrs);
	bool HaveCMission(int id);
	bool UpdateCMission(int id,const char *pInts,const char *pStrs);
	void UpdateCMissionState(int missId,int state);
	bool IsCMissionFinished(int missId);
	bool DelCMission(int id);
	
	//回归礼包信息
	bool CanGetBackLibao(const char *name);
	void UpdateBackLibaoInfo(const char *name);

	//用于临时保存变量，不存储数据库
	void SetVal(int id,int val);
	//获取保存变量
	int GetVal(int id);

	//保存变量，下线后保存数据库
	void SetSaveVal(uint8 index,int val);
	int GetSaveVal(uint8 index);

	const char* GetDataStr(int type); // 获取已经保存的记录
	bool SetDataStr(int type, const char* data); // 保存记录信息 每个玩家的type具有唯一性会覆盖

	//设置位，存储数据库
	void SetBitSet(int ind);
	void ClearBitSet(int ind);
	bool HaveBitSet(int ind);

	// 阶段目标，位变量
	void SetSGBitSet(int ind);
	void ClearSGBitSet(int ind);
	bool HaveSGBitSet(int ind);

	SItemInstance *GetItem(uint8 pos);

	//不限制数量num传入-1
	bool DelPackageById(int id,int num);

	bool AddBaiHuaChip(uint8 type,int num,uint8 fightend);

	void PushGongGao(const char *pStr);

	//设置进入场景是否调用脚本
	//void SetEnterSceneCall(int id);

	void AddQianNeng(int qianNeng);

	void SetCallScript(int script);
	void SetCallFun(const char *call);

	void SetPetZhongCheng(uint8 pos,int zhongcheng);

	void SetQianNeng(int qianNeng);
	int GetQianNeng();

	bool HaveItem(int id);
	bool HaveItem_PackageBank(int id);

	bool HavePet(uint16 petId);

	//如果有帮派返回id，如果无返回0
	uint32 GetBangPai();

	int GetBangState();
	int GetBangRank();
	void DismissBang();// 解散帮派
	void UndismissBang();// 解除解散状态
	int GetItemNum(int id, int level = 0);
	bool DelPackageByIdLevel(int id, int level, int num); // 删除特定等级的物品数量
	int GetWeiJianDingShuiJingNum(); // 蓝水晶未绑定数量特殊处理
	bool DelWeiJianDingShuiJing(int num); // 删除未鉴定水晶的数量

	//给予绑定物品
	bool AddBangDingPackage(int itemId,int num=1);

	//给予指定等级强化装备
	bool AddLevelPackage(int itemId,int level);

	uint8 InHuSongMission();
	bool InTreasure();

	int EmptyPackage();

	int GetServerId();

	int GetTongBao();
	bool AddTongBao(int tongbao,int type=0,int serverId=0,bool huodongAdd=true);
	int GetMoBao();

	void AddChongzhiTotal(int tb);
	void CheckChongZhiHuoDong(bool isOnLine,int money,int tongbao,int type = 0);
	bool ChongZhiJiJinFanli(uint32 money);
	
	void AddArenaJiFen(int addJiFen);
	int GetArenaJiFen();

	void SaveSellItem(uint8 pos,uint8 num);

	int GetShengWang();

	int GetDieTimes();

	void SetShiFu();

	void AddWing(int id);
	bool HaveWing(int id);

	//0 师傅等级
	//1 比赛死亡次数
	//2使用title
	//3出师徒弟数量
	void SetData8(uint8 pos,uint8 data);
	uint8 GetData8(uint8 pos);

	void SetShengWang(int sw);

	//0 解散师徒关系时间
	//1 状元、探花、榜眼title时间
	//2 离开帮派时间
	//3 副本id
	//4 偷菜时间
	//5 帮贡
	void SetData32(uint8 pos,uint32 data);
	uint32 GetData32(uint8 pos);

	//0 声望（善恶）
	//1 比赛积分
	void SetData16(uint8 pos,uint16 data);
	uint16 GetData16(uint8 pos);

	SItemInstance *GetItemById(int id);
	int GetSceneId();
	uint16 GetSrcSceneId(); // 获取场景srcid

	const char *GetBossMissionStarInfo();
	void SetBossMissionData(int index,int starNum);
	uint8 GetBossMissionStarNum(int index);

	uint8 NoLockGetExtData8(uint16 pos);
	uint8 GetExtData8(uint16 pos);
	void SetExtData8(uint16 pos,uint8 val);
	uint16 GetDCMissExtData8Id(int miss);
	uint8 GetDCMissExtData8(int miss);

	uint16 NoLockGetExtData16(uint16 pos);
	uint16 GetExtData16(uint16 pos);
	void SetExtData16(uint16 pos,uint16 val);

	uint32 NoLockGetExtData32(uint16 pos);
	uint32 GetExtData32(uint16 pos);
	void SetExtData32(uint16 pos,uint32 val);

	void AddTitle(uint16 title);
	void UpdateInfo();
	void UpdatePackage(uint8 pos);
	void SetLockPass(const char *pass);
	const char *GetLockPass();
	void SetStrVal(const char *val);
	const char *GetStrVal();
	void SetDelPassTime(int t);
	int GetLeftDelPassTime();
	int GetmissDay();
	void UpdateBangPai();
	void Set_InScriptCall(bool flag);
	void DoptionPrint();
	int DoptionBegin(const char *name,const char *src,const char *op,uint8 call);
	int Doption(int pid,const char *selectop,const char *name,const char *src,const char *op,uint8 call);
	void DoptionEnd();
	void SetDoptionCall(int nodeId,const char *call);

	uint16 GetAd();
	int GetMobileType(); // 获取玩家机型
	int GetRegTime(); // 获取角色注册时间
	int GetOnlineSecond(); // 获取角色登陆时间长度
	bool HaveLevelItem(int id,int level); // 等级道具
	void AddMount(uint8 id); // 增加基础坐骑
	bool HaveMount(uint8 id);
	void SendCgInfo(const char *animation); // 播放动画
	void FinishStageGoalSection(int stage,int section); // 完成阶段目标 小节
	void FinishStageGoalStage(int stage); // 完成阶段目标 段落
	void CheckMissionHuoYueDu(bool isAdd = true); // 活跃度次数+1并任务完成校验
	int GetPetQualityNum(int quality); // 获取玩家目标品质的神将数量
	void ClearAllPackage();

	bool ActiveNewShenQi(int shenqi_id);
	
	uint32 GetXianYuanValue();
	uint32 AddXianYuanValue(uint32 value);
	uint32 SubXianYuanValue(uint32 value);
	uint32 GetXianYuanCardNum(uint32 card_id);
	uint32 AddXianYuanCard(uint32 card_id,uint32 num);
	uint32 SubXianYuanCard(uint32 card_id,uint32 num);

	SNpcPos FindNpcPos(int npcId);

	bool NoticeClientToKuaFuServer();
	bool NoticeClientToGameServer();
	int GetAccountBinding();
	int GetAccountRecordPhone();

	bool AddMaxPackageNum(int num=1);

	void NotifyUserShowCangBaoTuPanel();
	void NotifyTreasureMapUseResult(); // 藏宝图的使用结果

	void SetCangBaotuId(uint32 id );
	uint32 GetCangBaotuId();
	void AddShenhun(int addNum);
	bool AddMaterial(uint32 type, int num, bool isFight);
	void AddYingYongShiLianNpc();

	void BuyMonthCard(uint8 type);
	void AddEquip(uint16 id, uint8 star);
	void SetCollectIndex(uint16 npcIdx);
};

