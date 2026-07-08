--[[
所有的UI消息号全部在这里
]]

--[[
LUILogic的UI事件
]]
--local lUIBegin = LManagerID.LUIManager + 1

local lUIBegin = LManagerID.LUIManager
local function MsgIdAdd()
    lUIBegin = lUIBegin + 1
    return lUIBegin
end

--[[
总的UI事件
]]
LUILogicEvent = 
{
    InitUI = MsgIdAdd(),
    InitUIInBattle = MsgIdAdd(),
	ShowUI = MsgIdAdd(),
	HideUI = MsgIdAdd(),
    DeleteUI = MsgIdAdd(),
    ShowSrcollTips = MsgIdAdd(),
    ShowSrcollTipsAtferBattle = MsgIdAdd(),
    ShowPowerChangeEffect = MsgIdAdd(),
    ShowItemInfo = MsgIdAdd(),
    ShowItemSource = MsgIdAdd(),--显示道具来源
    PlotChatModel = MsgIdAdd(),
    ShowItemListUI = MsgIdAdd(),
    ShowNumInputUI = MsgIdAdd(),
    ChangeScene = MsgIdAdd(),--lua给C#调用的显示滚动提示的命令号
    ShowFloatNotice = MsgIdAdd(),
    ShowLabaNotice = MsgIdAdd(),
    ShowCommomBtnList = MsgIdAdd(),--显示通用btn list
    ShowFlyItems = MsgIdAdd(),--道具飞入背包效果
    TaskAccept = MsgIdAdd(),--任务接受特效
    TaskComplete = MsgIdAdd(),--任务完成特效
    InitBagBtnPos = MsgIdAdd(),--获取主界面背包按钮位置
    InitHeroBtnPos = MsgIdAdd(),--获取主界面英雄头像位置
    EnterBattle = MsgIdAdd(),
    ExitBattle = MsgIdAdd(),
    Clear = MsgIdAdd(),
    ShowFiristAwardUI = MsgIdAdd(),
    ShowPetInfo = MsgIdAdd(),--宠物信息弹框（暂只支持表格数据）
    ShowBestStrong = MsgIdAdd(),--显示变强弹窗
    RedDotState = MsgIdAdd(), -- 小红点状态
    RedDotCheck = MsgIdAdd(), -- 小红点检查
    RedDotItemCheck = MsgIdAdd(), -- 物品相关小红点检查
    RedDotMoneyCheck = MsgIdAdd(), -- 金钱相关小红点检查
    RedDotLevelCheck = MsgIdAdd(), -- 等级相关小红点检查
    RedDotStateUpdate = MsgIdAdd(),--服务器从到红点
    ShowGuide = MsgIdAdd(), -- 显示引导
    HideGuide = MsgIdAdd(), -- 隐藏引导
    GetSettingInfo = MsgIdAdd(), -- 获取设置数据
    GetSettingStringInfo = MsgIdAdd(), -- 获取设置数据
    CheckLayerExist = MsgIdAdd(), --是否存在界面
    CanAutoPath =  MsgIdAdd(), --是否可以寻路
    CloseAllPopup =  MsgIdAdd(), --关闭所有弹窗和界面
    CloseHighPopup = MsgIdAdd(), --关闭所有高层级的弹窗和界面
    ShowItemWearTips =  MsgIdAdd(),--打开神器、坐骑、羽翼Tips
    MaxValue = MsgIdAdd(),
    addBattleMenu = MsgIdAdd(),
    checkAllBattleRedPot = MsgIdAdd(),
    buyItemSucEvent = MsgIdAdd(),
    paymentSuccess = MsgIdAdd(),
    paymentPreview = MsgIdAdd(),
    updatePreViewUI = MsgIdAdd(),
    EnterJingji=MsgIdAdd(),
    ShowPetEquipTips = MsgIdAdd(),
    interruptCollectUI = MsgIdAdd(),
    updateRechargeUIAfterPay = MsgIdAdd(),
    DataTimeEvent = MsgIdAdd(),
    ShowMonsterInfo = MsgIdAdd(),--显示怪物信息
	RoleActiveGame = MsgIdAdd(),--玩家挂机激活
	IsAutoPath = MsgIdAdd(),
    changeNameSuc = MsgIdAdd(), --改名成功
    changeBpNameSuc = MsgIdAdd(), --改名成功
    ShowEquipGetUI = MsgIdAdd(),--显示装备获得界面
    ChangeOtherTab = MsgIdAdd(),--其他玩家界面切换页签
    PlotChatOver = MsgIdAdd(),
    ClosePetInfo = MsgIdAdd(),--关闭神将预览界面
    ClosePetYangChengUI = MsgIdAdd(),--关闭神将养成界面
}

--[[
总的UI事件
]]
LUIFClassBgEvent = 
{
    SetTitle = MsgIdAdd(),
    SetCloseCallback = MsgIdAdd(),
    AddTabBtn = MsgIdAdd(),
    RemoveTabBtn = MsgIdAdd(),
    SelectTab = MsgIdAdd(),
    RedDotState = MsgIdAdd(),
    GetTabBtn = MsgIdAdd(),--获取tab按钮节点
    GetCloseBtn = MsgIdAdd(),--获取关闭按钮节点
    RegisterCloseGuide = MsgIdAdd(),--注册关闭按钮引导
    RegisterTabGuide = MsgIdAdd(),--注册右侧页签按钮引导
    MaxValue = MsgIdAdd(),
	BGChange = MsgIdAdd(),
    IsHideBgAndBtn= MsgIdAdd(),
	UpdateUI = MsgIdAdd(), --更新UI
	AddSecondTabBtn = MsgIdAdd(), --二级选项
	SelectSecondTab = MsgIdAdd(),
	RemoveSecondTabBtn = MsgIdAdd(),
	ResumeResourceData = MsgIdAdd(),
    HelpBtn=MsgIdAdd(),--帮助
}

--[[
总的UI事件
]]
LUIPopFClassBgEvent = 
{
    AddTabBtn = MsgIdAdd(),
    RemoveTabBtn = MsgIdAdd(),
    SetTitle = MsgIdAdd(),
    SetCloseCallback = MsgIdAdd(),
    SelectTab = MsgIdAdd(),
    ChangeTab = MsgIdAdd(),
    RedDotState = MsgIdAdd(),
    GetTabBtn = MsgIdAdd(),--获取tab按钮节点
    GetCloseBtn = MsgIdAdd(),--获取关闭按钮节点
    RegisterCloseGuide = MsgIdAdd(),--注册关闭按钮引导
    RegisterTabGuide = MsgIdAdd(),--注册右侧页签按钮引导
    MaxValue = MsgIdAdd(),
    BGChange = MsgIdAdd(),
    HelpBtn  = MsgIdAdd(),-- 帮助按钮
    ChangeBg = MsgIdAdd(), --改变背景
    ResetBg = MsgIdAdd(), --改变背景
}


LUISecondClassBgEvent = 
{
    SetTitle = MsgIdAdd(),
    SetCloseCallback = MsgIdAdd(),
    RegisterCloseGuide = MsgIdAdd(),--注册关闭按钮引导
    MaxValue = MsgIdAdd()
}

--[[
道具选择的UI事件
]]
LUIItemListUIEvent = 
{
    SelectItem = MsgIdAdd(),
    MaxValue = MsgIdAdd()
}

LUIMsgBoxEvent = 
{
    ShowMsgBox = MsgIdAdd(),
    HideMsgBox = MsgIdAdd(),
    RegisterCloseGuide = MsgIdAdd(),--注册关闭按钮引导
}

--[[
主UI的相关事件
]]
LUIMainEvent = 
{
    ShowUI = MsgIdAdd(), --刷新主界面开放活动
    HideUI = MsgIdAdd(), --刷新主界面开放活动
    FlushOpenActivity = MsgIdAdd(), --刷新主界面开放活动
    GetOpenActivity = MsgIdAdd(), --获取主界面开放活动
    ClickNearHeros = MsgIdAdd(),--点击场景获取玩家列表
    ShowImproveBtn = MsgIdAdd(),--显示提升按钮
    CheckImproveBtn = MsgIdAdd(),--检测提升按钮
    ShowImproveView = MsgIdAdd(),--显示提升面板
    CheckImproveMedal = MsgIdAdd(),--调用检测称号
    StartAutoUseItemCheck = MsgIdAdd(),--启动自动使用物品timer
    CheckFirstRechargeBtn = MsgIdAdd(),--显示\隐藏首充按钮
    OpenOrCloseBtmBtn = MsgIdAdd(),--折叠/展开底部功能按钮
    OpenOrCloseTopBtn = MsgIdAdd(),--折叠/展开顶部功能按钮
    GetMainBtnPos = MsgIdAdd(),--获取主界面UI按钮坐标
    ISOpenBtmBtn = MsgIdAdd(),--获取底部功能按钮是否展开
    ISOpenTopBtn = MsgIdAdd(),--获取顶部功能按钮是否展开
    GetMapName = MsgIdAdd(),--获取地图名称
    WorshipEvent = MsgIdAdd(),--膜拜
    ChangeHookEvent = MsgIdAdd(),--切换挂机按钮状态
    CheckFactionBtn = MsgIdAdd(),--检测邀请入帮按钮状态
    ShowActivityIcon = MsgIdAdd(), --显示主界面Icon
    SetFuncBtnVisible = MsgIdAdd(), --设置主界面Icon显示状态
    UpdateDiscountBag = MsgIdAdd(), --更新折扣礼包显示状态
    ChangeDayMsg = MsgIdAdd(), --跨天消息
}

--[[
翅膀UI相关的消息
]]
LUIWingDataEvent = 
{
    SetWingState = MsgIdAdd(),--翅膀状态改变
    UpgradWing = MsgIdAdd(),--强化翅膀
    GetWingList = MsgIdAdd(),--获取翅膀列表
    GotNewWing = MsgIdAdd(),--获取新翅膀
    UpgradEnd = MsgIdAdd(),--收到强化结果
}

--[[
任务UI相关的消息
]]
LUITaskDataEvent = 
{
    GotTaskList = MsgIdAdd(),--收到任务列表
    GotTaskInfo = MsgIdAdd(),--收到任务详细信息
    GotDailyTaskInfo = MsgIdAdd(),--收到每日任务列表
    DailyTaskUpdate = MsgIdAdd(),--收到每日任务列表
    GotDailyTaskReward = MsgIdAdd(),--每日任务奖励
    GotDailyRewardInfo = MsgIdAdd(),--收到每日任务列表
    DeleteOneTask = MsgIdAdd(),--删除一个任务
    DeleteAllTask = MsgIdAdd(),--删除所有任务
    ClickTask = MsgIdAdd(),--点击任务
    ContinueTask = MsgIdAdd(),--继续任务
    AddOneTask = MsgIdAdd(),--添加一个任务
    GetCompletedTask = MsgIdAdd(),--获取已完成任务列表
    TaskCellTouchPos = MsgIdAdd(), --任务点击位置
    ChangeTeamTab = MsgIdAdd(),--切换队伍页签
    afterDeleteOneTask = MsgIdAdd(),--任务详细信息更新完毕
    ShowTaskPanel = MsgIdAdd(), --显示任务面板

    updateQiRiUIAfterAward = MsgIdAdd(), --更新七日
    WanFaDailyTaskInfo = MsgIdAdd(), --玩法每日任务信息
    WanFaDailyTaskReward = MsgIdAdd(), --玩法每日任务更新
}

--[[
玩家信息变更的UI消息汇总
]]
--lUIBegin = LUILogicEvent.MaxValue + 1
LUIRoleDataChangeEvent = 
{
    
    InitRoleNode = MsgIdAdd(),--人物初始化显示节点
    LvUp = MsgIdAdd(),--升级
    ExpChanged = MsgIdAdd(),--经验变化
    HpChanged = MsgIdAdd(),--血条变化
    MpChanged = MsgIdAdd(),--蓝条变化
    PowerChanged = MsgIdAdd(),--战斗力变化
    VIPChanged = MsgIdAdd(),--VIP改变了
    TongBaoChanged = MsgIdAdd(),--元宝改变了
    BindTongBaoChanged = MsgIdAdd(),--绑定元宝改变了
    MoneyChanged = MsgIdAdd(),--金币改变了
    BindMoneyChanged = MsgIdAdd(),--绑定金币改变了
    CompeteScoreChanged = MsgIdAdd(),--竞技积分改变了(擂台赛)
    BangGongChanged = MsgIdAdd(),--帮贡改变了
    PotentialChanged = MsgIdAdd(),--潜能改变了
    ShenHunChanged = MsgIdAdd(),--神魂改变了
    HuoyueChanged = MsgIdAdd(),--活跃度改变了
    ZaDanJiFenChanged = MsgIdAdd(),--砸蛋积分改变了
    StartHangUp = MsgIdAdd(),--开始挂机
    StopHangUp = MsgIdAdd(),--结束挂机
    AttrChanged = MsgIdAdd(),--玩家属性变化
    ChangeUser = MsgIdAdd(),--切换用户
    ClickMapToMove = MsgIdAdd(),--点击地图寻路
    MaxValue = MsgIdAdd(),--
    CheckOpenBuffTips=MsgIdAdd(),
    XinXiuJingHuaChanged = MsgIdAdd(),--血战币
    ClickBuffItem=MsgIdAdd(),
    UpdateBuffTime=MsgIdAdd(),
    TiliChanged = MsgIdAdd(),  --体力变化
    BGVisible = MsgIdAdd(),  --背景隐藏
    GetTiliSuc = MsgIdAdd(), --获取体力成功
    GetFreeTili = MsgIdAdd(), --
    ArenaSorceChanged = MsgIdAdd(), --竞技场积分
    KunlunMoneyChanged = MsgIdAdd(), --昆仑币
    HuoYueChanged = MsgIdAdd(), --活跃度修改
    ShengLingChanged = MsgIdAdd(), --圣灵凭证修改
    TurntableScoreChanged = MsgIdAdd(), --转盘积分修改
--  BagDataChanged = MsgIdAdd(),--背包数据改变
}

--[[
玩家队伍状态UI消息汇总
]]
LUIRoleTeamEvent = 
{
    CreateTeam = MsgIdAdd(),
    TeamMemberChanged = MsgIdAdd(),
    ApplyListChanged = MsgIdAdd(),
    AutoApplyChanged = MsgIdAdd(),--个人自动组队标志变化
    TeamTargetChanged = MsgIdAdd(),
    RecvTeamPublishList = MsgIdAdd(),
    RecvNearPlayers = MsgIdAdd(),
    SetQuickTeamInd = MsgIdAdd(),
}

LUITeamEvent = 
{
    ChangeTeamTab = MsgIdAdd(),
}


LUIRoleEquipChangeEvent = 
{
    UnEquip = MsgIdAdd(),--装备卸下
    Equiped  = MsgIdAdd(),--装备穿上
    EquipeShuaXin  = MsgIdAdd(),--装备刷新
    EquipeJXCost  = MsgIdAdd(),
}

--[[
上浮提示的UI事件
]]
LUIScrollTipsEvent = 
{
    ShowTips = MsgIdAdd(),
    MaxValue = MsgIdAdd()
}

--[[
走马灯
]]
LUIFloatNoticeEvent = 
{
    ShowTips = MsgIdAdd(),--显示
}


LUIWaitAni = 
{
    ShowWait = MsgIdAdd(),
    ClearWait = MsgIdAdd(),
    ForceClearWait = MsgIdAdd(),
    MaxValue = MsgIdAdd()
}

LUILoadingEvt = 
{
    ShowLoading = MsgIdAdd(),--显示加载loading条
    HideLoading = MsgIdAdd(),--隐藏加载loading条
    ShowLoadingProcess = MsgIdAdd(),--显示进度
    ShowLoadingTips = MsgIdAdd(),--显示loading文字提示
}

--[[
登录注册的一些UI消息
]]
LUILoginEvent = 
{
    RegisterCheckAccountResult = MsgIdAdd(),--检查注册用户名返回
    RecvServerList = MsgIdAdd(),--收到服务器列表
    RecvRoleServerList = MsgIdAdd(),--收到玩家服务器列表
    LoginSuccess = MsgIdAdd(),--登录成功消息
    RecvCheckHeroName = MsgIdAdd(), --检查名字返回
    MaxValue = MsgIdAdd()
}


--[[
技能UI消息
]]
LUISkillEvent = 
{
    SkillNextDepInfo = MsgIdAdd(),
    SkillUpGrade = MsgIdAdd(),
    SkillNewUnLock = MsgIdAdd(),--新解锁技能
}

--[[
排行榜
]]
LUIRankEvent = 
{
    RankListInfo = MsgIdAdd(),
    ShowIndexRank = MsgIdAdd(),
}

--[[
鲜花排行榜
]]
LUIXianHuaRankEvent = 
{
    XianHuaRankListInfo = MsgIdAdd(),
}

--[[
 神器
 ]]
 LUIShenQiEvent = 
 {
     CurShenQiChanged = MsgIdAdd(),          --当前跟随神器修改
     ShenQiDevelopInfoChanged = MsgIdAdd(),  --神器培养信息修改
     ShenQiStateChanged = MsgIdAdd(),        --获得新神器(状态改变）
     GotShenQiList = MsgIdAdd(),             --获得神器列表
 }


--[[
 邮件
 ]]
 LUIMailEvent = 
 {
     OpenMail = MsgIdAdd(),              -- op = 0 打开信使 
     SendMail = MsgIdAdd(),              -- op = 1 发送结果 
     QueryMailList = MsgIdAdd(),         -- op = 2 信使列表 
     SaveMail = MsgIdAdd(),              -- op = 3 收信结果 
     ReadMail = MsgIdAdd(),              -- op = 4 已读邮件服务端删除 
     NewMail = MsgIdAdd(),               -- op = 5 收到新邮件
     delAllMail = MsgIdAdd(),               -- 删除所有邮件
     QueryMail = MsgIdAdd(),             --  查询邮件
     OpenWriteMail = MsgIdAdd(),         --打开写邮件
     TurnWriteMail = MsgIdAdd(),         --  转到写邮件

}


--[[
坐骑相关的UI消息
]]
LUIHorseEvent = 
{
    RideStateChanged = MsgIdAdd(),--乘骑状态改变
    RecvEnforceValue = MsgIdAdd(),
    GotHorseList = MsgIdAdd(),--获取坐骑列表
    HorseListChange = MsgIdAdd(),--列表变动
    AddNewHorse = MsgIdAdd(),--新获得坐骑
    UpdateHorseTotalAttr=MsgIdAdd(),--刷新坐骑总属性
}
--[[
 境界相关的UI消息
]]
LUIJingJieEvent = 
{
    RideStateChanged = MsgIdAdd(),--穿的状态改变
    GotJingJieList = MsgIdAdd(),--获取境界列表
    JingJieListChange = MsgIdAdd(),--列表变动
    AddNewJingJie = MsgIdAdd(),--新获得境界
    UpdateJingJieTotalAttr=MsgIdAdd(),--境界总属性
    ReceiveReward=MsgIdAdd(),--领取奖励
    UpdateInfo=MsgIdAdd(),--更新
}


--[[
宠物相关UI消息
]]
LUIPetEvent = 
{
    GotPetList = MsgIdAdd(),
    SelectedPet = MsgIdAdd(),--左侧列表选中宠物
    PetDataChanged = MsgIdAdd(),--宠物信息改变
    ChangePetName = MsgIdAdd(),--宠物改名
    ChangePetLv = MsgIdAdd(),--宠物等级变更
    ChangePetPower =  MsgIdAdd(),--宠物战斗力变更
    ChangePetFollow = MsgIdAdd(),--宠物跟随变更
    ChangePetSkill = MsgIdAdd(),--宠物技能变化
    ChangePetStar = MsgIdAdd(),--宠物星级有变化
    ChangePetXiulian = MsgIdAdd(),--宠物修炼数据有变化
    GetPet = MsgIdAdd(),--增加宠物
    ComposionPet = MsgIdAdd(), --兑换神将
    PetResolveInfo = MsgIdAdd(), --请求神将分解获得资源返回
    ResolveSucess = MsgIdAdd(), --神将分解成功
    PetStarAdd = MsgIdAdd(), --宠物星级增加
    GotPetEquip = MsgIdAdd(),--获取神将装备
    PetEquipChanged = MsgIdAdd(),--宠物装备变化（已穿）
    PetBagEquipChanged = MsgIdAdd(),--宠物装备变化（背包）
    PetEquipStrengthenSuc = MsgIdAdd(),--宠物装备强化成功
    PetEquipResolveSuc = MsgIdAdd(),--神将装备分解成功
    PetEquipAdd = MsgIdAdd(),--获得装备消息-用于小红点显示
    PetExpRedDot=MsgIdAdd(),
	UpdatePetData=MsgIdAdd(),--更新tab选中的神将数据
    PetEquipWear = MsgIdAdd(),--神将装备穿脱

    PetXLSuc = MsgIdAdd(), --神将修炼
    PetJiHuoSuc = MsgIdAdd(), --神将激活
}


--[[
阵法相关UI消息
]]
LUIFormationEvent = 
{
    GotList = MsgIdAdd(),
    ZhenfaChanged = MsgIdAdd(),--阵法信息改变，升级或学习
    UseZhenfaChanged = MsgIdAdd(),--切换使用阵法
    PetFight = MsgIdAdd(),--宠物出站
    ChangePos = MsgIdAdd(),--更换出站位置
    UseTeamZhenfaChanged = MsgIdAdd(),--切换组队使用阵法
    updateZhengRongUI = MsgIdAdd(), --更新位置
    ChangeShowPos = MsgIdAdd(), --改变显示位置
}

--[[
 背包
 ]]
LUIBagEvent = 
{
    BagDataChanged = MsgIdAdd(),    --单格背包，参数为0表示整体刷新
    BagUnLock = MsgIdAdd(),         --背包格解锁
    RefreshUnLockTime = MsgIdAdd(), --刷新解锁时间
    SynthesisSucess = MsgIdAdd(),   --合成成功
    ResolveSucess = MsgIdAdd(),     --分解成功
    SelectTab = MsgIdAdd(),         --切换页签
}

 --[[

 ]]
LUIMapEvent = 
{
    ChangeMapSuccess = MsgIdAdd(),    --
--SetMapName = MsgIdAdd(),    --
}
 
 --[[
 竞技场
 ]]
LUIArenaEvent = 
{
    UpdateTime = MsgIdAdd(),          --更新次数
    ResetCD = MsgIdAdd(),             --重置冷却时间
    UpdateArenaWarInfo = MsgIdAdd(),  --更新排名战信息
    UpdateHeroListInfo = MsgIdAdd(),  --更新英雄榜信息
    OpenRecordUI = MsgIdAdd(),        --打开记录（战报）界面
    RefreshWarship = MsgIdAdd(),      --刷新膜拜信息
    OpenRewardUI = MsgIdAdd(),        --打开奖励界面
    GetMyRecordInfo = MsgIdAdd(),     --获取本人战报
}

 --[[
 玩法
 ]]
LUIActivityEvent = 
{
    RefreshPage = MsgIdAdd(),           --刷新玩法页面
    GuessFistResult = MsgIdAdd(),       --猜拳结果
    ShenshouResult = MsgIdAdd(),        --界面刷新
    ShenshouState = MsgIdAdd(),         --护送状态改变
    ShenshouFinish = MsgIdAdd(),        --护送完成
    RefreshMoneyTreeUI = MsgIdAdd(),    --刷新摇钱树界面
    MoneyEffectPlay = MsgIdAdd(),       --金币满屏动画播放
    RefreshKunlunRank = MsgIdAdd(),     --昆仑山排行
    RefreshKunlunRoom = MsgIdAdd(),     --昆仑山房间
    RefreshKunlunInfo = MsgIdAdd(),     --昆仑山信息
    RefreshDonate = MsgIdAdd(),         --捐献信息
    RefreshLiLianInfo = MsgIdAdd(),     --修仙历练信息刷新
    RefreshFlyFary = MsgIdAdd(),        -- 飞仙战场信息刷新
    UpdateAnswerInfo = MsgIdAdd(),      -- 跟新答题记录
    UpdateQuestion = MsgIdAdd(),        -- 跟新问题信息
    LeaveShilian = MsgIdAdd(),          -- 离开试炼场景
    FanPaiShiLian = MsgIdAdd(),         -- 翻牌试炼
    closeFanPai = MsgIdAdd(),           -- 关闭翻牌界面
    ShowBox = MsgIdAdd(),               -- 显示玩法界面活跃度
    RefreshInstances = MsgIdAdd(),      -- 副本刷新
    RefreshInstancesCount = MsgIdAdd(),      -- 副本次数刷新
    CloseInstancesAndGetValue = MsgIdAdd(),      -- 关闭副本并且获取副本UI当前选中的信息
    RefreshFirstRechargeUI = MsgIdAdd(),-- 首充奖励刷新
    ClickActivity = MsgIdAdd(),         -- 点击指定玩法
    CloseActivityInfoUI = MsgIdAdd(),   -- 关闭选中玩法信息界面
    EnterFubBen = MsgIdAdd(),           -- 进入副本
    ExitFuBen = MsgIdAdd(),             -- 退出副本
    RefreshFengShenStoryUI = MsgIdAdd(),-- 封神试炼界面刷新
    FengShenStoryFightEnd = MsgIdAdd(),--战斗结束
    RefreshYouLiUI = MsgIdAdd(),--游历三界主界面更新
    StartYouLi = MsgIdAdd(),--游历三界开始游历
    YouLiModeChoose = MsgIdAdd(),--游历三界选择初中高级
    YouLiTimeChoose = MsgIdAdd(),--游历三界选择时长
    CloseShenJiangChooseUI = MsgIdAdd(),--关闭神将选择界面
}

  --[[
英勇试炼(血战)
 ]]
LUIXueZhanEvent = 
{
    UpdateChapterInfo = MsgIdAdd(), --更新章节信息
    UpdateBuffShow = MsgIdAdd(),    --更新Buff信息
    RefreshChapterBuffUI = MsgIdAdd(), --更新章节界面buffUI
    RefreshChapterSweepUI = MsgIdAdd(), --更新章节界面扫荡设置UI
    GetActivityInfo = MsgIdAdd(), --获取活动数据
    RefreshBtnState = MsgIdAdd(), --领取昨日奖励后刷新主界面按钮
}

--[[
寻宝
 ]]
LUIXunBaoEvent = 
{
    UpdateCntUI = MsgIdAdd(), --更新次数
    ShowResultUI = MsgIdAdd(),--显示搜寻结果 
    FaBaoHechengSuc = MsgIdAdd(),--法宝合成成功
    FaBaoOneKeyHCSuc = MsgIdAdd(),--法宝一键合成成功
}

  --[[
 每日Boss
 ]]
LUIDailyBossEvent = 
{
    DailyBossShowBossInfo = MsgIdAdd(), --显示每日Boss玩法Boss信息
    DailyBossShowAward = MsgIdAdd(),    --显示每日Boss玩法奖励信息
    DailyBossUpdateTime = MsgIdAdd(),   --更新每日Boss玩法次数、星级
    DailyBossDrawState =  MsgIdAdd(),   --每日Boss玩法奖励领取状态更新
}

   --[[
 礼包
 ]]
 LUIWelfareEvent = 
 {
     RefreshLoginGiftPage = MsgIdAdd(),      --刷新登录礼包界面
     RefreshLevelGiftPage = MsgIdAdd(),      --刷新等级礼包界面
     RefreshStageGoal = MsgIdAdd(),          --刷新阶段奖励
     updateSevenCharge = MsgIdAdd(),         --显示7天登录界面
     refrashSevenChargeUI = MsgIdAdd(),      --刷新7天登录界面
     refrashAwardBtn = MsgIdAdd(),           --领取额外奖励
 }
 
 --[[
 锻造
 ]]
 LUIForgeEvent = 
 {
     StrengthenRefresh = MsgIdAdd(),      --刷新强化页面
     --StrengthenInfo = MsgIdAdd(),         --强化展示界面
     UpgradeRefresh = MsgIdAdd(),         --刷新升阶页面
     QuenchRefresh = MsgIdAdd(),          --刷新淬炼页面
     RuneAttrInfo = MsgIdAdd(),           --符文属性界面
     XiLianRefresh = MsgIdAdd(),          --刷新洗炼界面
     StrengthenRedDot = MsgIdAdd(),       --强化界面内Icon红点
     UpgradeRedDot = MsgIdAdd(),          --升阶界面内Icon红点
     QuenchRedDot = MsgIdAdd(),           --淬炼界面内Icon红点
     SynthesisSucess=MsgIdAdd(),
 }

 --[[
聊天相关
]]
LUIChatEvent = 
{
    addMsg = MsgIdAdd(),            --增加一条聊天消息
    updateTextField = MsgIdAdd(),   --更新聊天界面聊天框
    showChat =  MsgIdAdd(),         --显示聊天框
    addPcTempChat = MsgIdAdd(),     --私聊
    turnToPcChatState = MsgIdAdd(), --跳转到私聊状态
    addEmotion = MsgIdAdd(),  --表情
    showVoiceWindow = MsgIdAdd(),    --显示语音提示
    cancelVoiceWindow = MsgIdAdd(),  --取消语音
    beginVoiceProgress = MsgIdAdd(), --进度条
    ShowOrCloseChatPanel = MsgIdAdd(), --显示或关闭聊天框
    updateSendLabaMsg = MsgIdAdd(),    --喇叭使用
    openSendLabaUI = MsgIdAdd(),       --打开发送喇叭界面
    intoLeiTaiSai = MsgIdAdd(),        --进入个人擂台赛,默认切换到当前
    getRoleTeamId=MsgIdAdd(),           --得到玩家的队伍信息
    OpenPrivateChat=MsgIdAdd(),           --打开私聊界面
}

 --[[
社交相关
]]
LUISocialEvent = 
{
    updateFriendLayer = MsgIdAdd(),            --更新社交UI
    updateAddFriendLayer = MsgIdAdd(),         --更新添加好友界面
    addPcChatMsg = MsgIdAdd(),                 --添加私聊消息
    updateBlackList = MsgIdAdd(),              --更新黑名单
    updateSearchPlayer = MsgIdAdd(),              --添加黑名单列表
    gotoMailUI = MsgIdAdd(),                  --切换到mailUI
    updateFriendApplyListLayer = MsgIdAdd(),            --更新
    UpdateFriendGift = MsgIdAdd(),            --更新
    UpdateGiftLeft = MsgIdAdd(),            --更新
}

--[[
称号
]]

LUITitleEvent = 
{
    updateTitleUI = MsgIdAdd(),            --更新称号
    updateMedalShow = MsgIdAdd(),          --更新属性显示
    updateShowMedelSuc = MsgIdAdd(),         --更新显示称号
}

LUIBattleEvent = 
{
    SelectAction = MsgIdAdd(),--回合开始
    ActionPlaying = MsgIdAdd(),--回合播放中，
    updateSkillData = MsgIdAdd(),--更新技能数据
    InitSkillCD = MsgIdAdd(),--初始化cd
    UpdateSpeed = MsgIdAdd(),--更新战斗速度
    UpdateFightHP = MsgIdAdd(),--更新血条
    ShowFightHP = MsgIdAdd(),--显示血条
    -- ResetTime = MsgIdAdd(),--重置计时器
    -- RecvEnterBattle = MsgIdAdd(),
    -- RecvBattleWatch = MsgIdAdd(),
    -- RecvDoBattle = MsgIdAdd(),
    -- RecvBattleOver = MsgIdAdd(),
    -- RecvRunAway = MsgIdAdd(),       --逃跑
    -- RecvAutoBattle = MsgIdAdd(),    --
}

--[[
帮派列表的一些UI消息
]]
LUIBangPaiEvent = 
{
    ShowBangPaiList = MsgIdAdd(),--接收帮派列表消息
    UpdateAskJoinBangPai = MsgIdAdd(),--成功加入帮派
    UpdateRedDot = MsgIdAdd(), --红点
    LoadMemberList = MsgIdAdd(), --加载成员列表
    UpdateMyFactionInfo = MsgIdAdd(), --刷新我的帮派信息
    CreateCost = MsgIdAdd(), --创建帮派需要花费元宝
    LoadJoinApplyList = MsgIdAdd(), --申请列表
    UpdateGongGao = MsgIdAdd(), --更新公告
    UpdateNameShow = MsgIdAdd(), --更新显示帮名
    UpdateManorInfo = MsgIdAdd(), --更新种植信息
    ReloadGodTreeInfo = MsgIdAdd(), --初始化神树信息
    EnterBPPlantArea = MsgIdAdd(), --进入帮派领地信息
    UpdateMemberWeiJie = MsgIdAdd(), --更新帮派成员职位信息
    DelMemberByRoleId = MsgIdAdd(), --踢人，更新帮派成员列表信息
    UpdateBangZhuChuangWei = MsgIdAdd(), --帮主传位，更新帮派信息
    UpdateSelfZhiWei = MsgIdAdd(), --更新自己的帮派职位
    UpdateRobButton = MsgIdAdd(), --更新掠夺按钮状态
    CloseFactionZoneOpLayer = MsgIdAdd(), --关闭领地操作窗口
    UpdateFactionZoneGuard = MsgIdAdd(), --更新守卫面板信息
    UpdateJuanXianRecord = MsgIdAdd(), --更新捐献信息
    ReloadJuanXianMsg = MsgIdAdd(), --更新捐献界面
    ReloadXianZunGeMsg = MsgIdAdd(), --更新仙尊阁信息
    ReloadFactionTaskList = MsgIdAdd(), --更新任务列表
    CloseBangPaiPopup = MsgIdAdd(), --关闭帮派弹窗
    GetFactionTaskReward = MsgIdAdd(), --领取任务奖励
    PlantResultEvent = MsgIdAdd(), --刷新帮派浇水除虫界面
    UpdateBangPaiWarInfo = MsgIdAdd(),--刷新帮派战信息
    ShowBangPaiWarTask = MsgIdAdd(), --显示帮派
    ReloadFactionActivityList = MsgIdAdd(), --刷新帮派活跃度奖励
    FlushFactionActivity = MsgIdAdd(), --刷新 帮派/个人 活跃度

    GotChapterData = MsgIdAdd(), --收到副本信息
    UpdateChapterData = MsgIdAdd(), --收到副本信息
    GotCopyData = MsgIdAdd(), --收到副本信息
    UpdateCopyData = MsgIdAdd(), --更新副本信息
    UpdateFightTimes = MsgIdAdd(), --更新副本信息
    GotBuffData = MsgIdAdd(), --收到副本buff信息
    GotRankData = MsgIdAdd(), --伤害排行
    GotQuickFightData = MsgIdAdd(), --
    UpdateTodayHuoyue = MsgIdAdd(), --
    JoinSuccess = MsgIdAdd(), --
}

--[[
帮派战的一些UI消息
]]
LUIBangPaiWarEvent = 
{
    ShowRankInfo = MsgIdAdd(),    --显示帮派战排行榜信息
    ShowCountDown = MsgIdAdd(),   --显示倒计时
    ShowActionPower = MsgIdAdd(), --显示行动力
	ShowBoxCountDown = MsgIdAdd(),--显示宝箱倒计时
    updateBpWarTowerUI = MsgIdAdd(), --更新帮派任务UI
    updateBpWarData = MsgIdAdd(),  --占塔后更新数据
    ShowBpWarHurtRank = MsgIdAdd(), --显示帮战伤害帮
    ShowTakeTowerEvent = MsgIdAdd(), --占塔事件
    UpdateBpKejiUI = MsgIdAdd(),  --更新科技界面
    UpdateSkillUpUI = MsgIdAdd(), --更新技能
}

 --商城
 LUIShopEvent = 
 {
     ReloadShopData = MsgIdAdd(), --刷新从服务器获取的商店数据
     SelectShopItem = MsgIdAdd(), --选中某一商品
     ReloadShopCount = MsgIdAdd(), --刷新某一商品数量
     UpdateDiscountShop = MsgIdAdd(), --更新折扣商店界面
     UpdateCountByItemId = MsgIdAdd(), --根据ID刷新折扣商店
    ---------------------new---------------------------------
    UpdateKaPaiShop = MsgIdAdd(), --更新将魂商店
    UpdateShopUIAfterBuySuc = MsgIdAdd(), --购买商品成功后更新UI
    QueryBuyCntResult = MsgIdAdd(), --查询商城道具购买次数返回
 }


 --签到
 LUIDailySignEvent = 
 {
    DailySignInfo = MsgIdAdd(), --刷新从服务器获取的商店数据
    DailySignResult = MsgIdAdd(), --刷新从服务器获取的商店数据
 }

 -- 通天塔
 LUITowerEvent = 
 {
    TowerInfo = MsgIdAdd(),     -- 
    TowerKingData = MsgIdAdd(), -- 霸主数据
    TowerSaoDang = MsgIdAdd(),
    TowerKingUIInfo = MsgIdAdd(),
    TowerReset = MsgIdAdd(),
    TowerFightAward = MsgIdAdd(),
    TowerShowReward = MsgIdAdd(),--显示当前霸主奖励
    TowerStartChange = MsgIdAdd(),--开始切换
    TowerShowDetailInfo = MsgIdAdd(),--显示敌方或推荐阵容
}


 -- 多人闯关
 LUIMonopolyEvent = 
 {  
    recvRoleMove = MsgIdAdd(), --更新摇骰子UI
    ResetRolePos = MsgIdAdd(), --还原主角位置
    RoleMove = MsgIdAdd(),     --角色移动
    RoleMoveOver = MsgIdAdd(), --角色移动完成
    RoleOnMove = MsgIdAdd(), --角色移动完成
    updateMonopoly = MsgIdAdd(), --更新UI
    monopolyChatDialog = MsgIdAdd(), --NPCchat触发对话战斗UI
    updateMoveOverUI = MsgIdAdd(), --事件完成后更新UI
    showBattleChatLayer = MsgIdAdd(), --展示对话界面
    recvRandomEvent = MsgIdAdd(), --随机事件
    updateAwardUI = MsgIdAdd(), --更新奖励界面
    updateAwardUIIcon = MsgIdAdd(), --更新奖励界面图标
    updateBattleUI = MsgIdAdd(),   --更新战斗
    updateBattleUIIcon = MsgIdAdd(), --更新战斗界面
    afterBattleUIMove = MsgIdAdd(), --战斗后行走
    udaptePlayTimes = MsgIdAdd(),  --更新摇塞子次数
    showBuyTicket = MsgIdAdd(), --购买次数
    justShowBattleChatLayer = MsgIdAdd(), --显示对话
    finishEvent = MsgIdAdd(), --结束事件
    afterMoveEvent = MsgIdAdd(), --自动显示对战界面
}


 -- 在线奖励
 LUIOnlineAwardEvent = 
 {
    OnlineAwardInfo = MsgIdAdd(),     -- 
    OnlineAward = MsgIdAdd(),     -- 
    KaifuReddotRefresh = MsgIdAdd(),--刷新红点
}


--[[
宠物相关UI消息
]]
LUIFaBaoEvent = 
{
    GotPetFaBao = MsgIdAdd(),--获取神将装备
    PetFaBaoWear = MsgIdAdd(), --法宝穿戴
    PetQHMaterialSelect = MsgIdAdd(), --法宝强化选择
    PetQHSuc = MsgIdAdd(), --法宝强化成功
    PetJLSuc = MsgIdAdd(), --精炼成功
    FaBaoWearSuc = MsgIdAdd(), --法宝穿戴
    FaBaoTakeOffSuc = MsgIdAdd(), --法宝穿戴
    UpdateFaBaoSuc = MsgIdAdd(), --增加法宝成功
}

 --抽卡
 LUILuckDrawEvent = 
 {
     ReloadLDData = MsgIdAdd(), --从服务器获取的抽卡数据
     DrawSuccess = MsgIdAdd(), --抽卡结果数据
     ShowDrawResult = MsgIdAdd(), --抽卡结果数据
 }

-- 离线经验
LUIOfflineAwardEvent = 
{
    OfflineInfo = MsgIdAdd(),     -- 
    GetOfflineExp = MsgIdAdd(),     -- 
}
 
 
--赠送鲜花
LUIGiveGiftEvent = 
{
    updateXianHuaShop = MsgIdAdd(),     -- 更新鲜花商店
    receiveXianHuaFullScreen = MsgIdAdd(),     -- 收到鲜花，全屏显示
    buyXHSuccess = MsgIdAdd(),                  --购买鲜花成功
    updateXianHuaRecord = MsgIdAdd(),       --鲜花赠送记录
    xianHuaRecordNeedRefresh = MsgIdAdd(),       --赠送鲜花,记录需要更新
    showXianhua = MsgIdAdd(),                   --展示鲜花
    updateMeili = MsgIdAdd(),
    updateAfterGiveUI = MsgIdAdd(),      --赠送后更新UI
    updateUIAfterSendGift = MsgIdAdd(),  --赠送国庆活动彩带后更新UI
}

--开服活动
LUIWelfareActivityEvent = 
{
    InitListData = MsgIdAdd(),--左侧列表数据
    ReloadData = MsgIdAdd(),--刷新界面
    ClosePopup = MsgIdAdd(),--关闭窗口
    DailyReChargeBtnState = MsgIdAdd(), --每日首充
    updateRechargeUI = MsgIdAdd(), --充值送礼领取后更新UI
    UpdateRedDot = MsgIdAdd(), --更新小红点
    updateConsumAwardUI = MsgIdAdd(), --更新小红点
    updateExchangeWordUI = MsgIdAdd(), --国庆集字活动兑换后刷新UI
}
--新功能预告，功能开启
LUIFunctionEvent = 
{
    FunctionOpen = MsgIdAdd(),--已开启功能
    FunctionStartFly = MsgIdAdd(),--功能开启ICON开始飞
    FunctionFinishFly = MsgIdAdd(),--功能开启ICON开始飞
    FunctionFly = MsgIdAdd(),--功能开启完成
    GetFuncOpen = MsgIdAdd(),--获取功能是否已开启
    GetFuncOpenList = MsgIdAdd(),--获取功能开启弹出列表
    PushFuncOpenList = MsgIdAdd(),--推送功能开启弹出列表
}
--新手引导
LUIGuideEvent = 
{
    RegisterStep = MsgIdAdd(),--注册引导
    UnRegisterStep = MsgIdAdd(),--取消注册引导
    CheckGuideStep = MsgIdAdd(),--检测引导步骤
    GuideComplete = MsgIdAdd(),--完成引导步骤
    PreGuide = MsgIdAdd(),--引导前处理
    AutoFinishGuide = MsgIdAdd(),--自动完成引导
    ShowingGuide = MsgIdAdd(),--显示的引导
}

LUIRewardGetEvent = 
{
    RegisterDrawGuide = MsgIdAdd(),--注册领取按钮引导
}

--白金会员
LUIPlatinumEvent = 
{
    updateBuyPlatinum = MsgIdAdd(),--注册引导
    updateAwardUI = MsgIdAdd(),--领奖UI
    goToBuyPlatinum = MsgIdAdd(), --去购买白金会员
}

LUIFishEvent = 
{
    ShowFishBasket = MsgIdAdd(),--显示鱼篮
    UpdateState = MsgIdAdd(),--更新钓鱼状态
    LoadUserList = MsgIdAdd(),--加载钓鱼玩家列表
    LoadFishBasketList = MsgIdAdd(),--加载鱼篮列表
    UpdateUserList = MsgIdAdd(),--更新钓鱼玩家列表（增加或减少）
    QuitFishState = MsgIdAdd(),--退出钓鱼状态
}

LUIRedDotEvent = 
{
    RegisterRedDot = MsgIdAdd(),--注册红点节点
    SetRedDotState = MsgIdAdd(),--设置红点状态
    GetRedDotState = MsgIdAdd(),--获取红点状态
    UpdateRedDotState = MsgIdAdd(),--刷新红点状态
}

LUIGetPetWingEvent = 
{
    CheckNext = MsgIdAdd(),--显示下一个
}

LUIResRecoveryEvent = 
{
    updateResRecoveryUI = MsgIdAdd(),--显示下一个
    showAwardLayer = MsgIdAdd(), --显示奖励界面
    convertBuyTimes = MsgIdAdd(), --购买次数
    changeTitleTxt = MsgIdAdd(), --修改title
}

LUIFundRebateEvent = 
{
    LoadDataEvent = MsgIdAdd(), --加载基金返利数据
    GetRewardDataEvent = MsgIdAdd(), --领取基金奖励数据
}

LUIHuoyueLayerEvent = 
{
    LoadDataEvent = MsgIdAdd(), --加载基金返利数据
    GetRewardDataEvent = MsgIdAdd(), --领取基金奖励数据
}

LUIFengShenEvent = 
{
    LoadDataEvent = MsgIdAdd(), --加载封神战场数据
	TiaoZhanDataEvent = MsgIdAdd(), ---挑战封神试炼结果
	SaoDangDataEvent = MsgIdAdd(), --扫荡封神试炼结果
}

LUIKunLunEvent = 
{
	LoadDataEvent = MsgIdAdd(), --加载昆仑决战得英雄数据
	UpdateDataEvent = MsgIdAdd(), --更新战斗结果
	UpdateFightEvent = MsgIdAdd(),--战斗结果通知
	FightFailedEvent = MsgIdAdd(), --战斗失败
	FightRewardShow = MsgIdAdd(), --显示领取奖励通知
	GetRobotZhenFaInfo = MsgIdAdd(), --获取机器人的阵法信息
	UpdateBuyFightNum = MsgIdAdd(), --更新购买战斗次数
}

LUIPetDiscountEvent = 
{
    BuyResultEvent = MsgIdAdd(), --购买结果
}

LUITaskGiftEvent = 
{
    LoadDataEvent = MsgIdAdd(), --加载任务目标数据
    GetRewardRetEvent = MsgIdAdd(), --领取奖励结果
    UpdateDataEvent = MsgIdAdd(), --更新章节数据
    InitTaskEvent = MsgIdAdd(), --默认显示任务
    UpdateTaskEvent = MsgIdAdd(), --刷新任务状态
}
--[[
擂台赛
]]
LUILeiTaiSaiEvent = 
{
    UpdateDataEvent = MsgIdAdd(), --更新个人擂台赛数据
    UpdateRankEvent = MsgIdAdd(), --更新擂台赛排行榜数据
}
--[[
神界论道
]]
LUILunDaoEvent = 
{
    UpdateDataEvent = MsgIdAdd(), --更新个人数据
    UpdateRankEvent = MsgIdAdd(), --更新排行榜数据
    UpdateTaskEvent = MsgIdAdd(), --更新个人任务数据
}
--[[
神界秘境
]]
LUIMiJingEvent = 
{
    UpdateDataEvent         = MsgIdAdd(), --更新面板数据
    UpdateRankEvent         = MsgIdAdd(), --更新排行榜数据
    UpdateHPEvent           = MsgIdAdd(), --更新血条数据
    UpdateFaildedTimeEvent  = MsgIdAdd(), --更新重伤时间
    UpdateBattleFailedEvent = MsgIdAdd(), --战斗失败
    UpdateRedDotEvent       = MsgIdAdd(), --更新小红点
}


--[[
唯我独仙
]]
LUIWeiWoDuXianEvent = 
{
    UpdateWWDXPreUIEvent = MsgIdAdd(), --更新预赛界面
    UpdateWWDXGroupEvent = MsgIdAdd(), --
    UpdateWWDXCostEvent = MsgIdAdd(), --
    UpdateWWDXLeftTimes = MsgIdAdd(), --
    UpdateWWDXLeftSecond = MsgIdAdd(), --
    WWDXUIEvent = MsgIdAdd(), --根据type显示数据
    WWDXFinalDataEvent = MsgIdAdd(), --决赛信息
    WWDXBetDialogEvent = MsgIdAdd(), --根据type显示数据
    WWDXUpdateBetData = MsgIdAdd(),
    WWDXBetNodeState = MsgIdAdd(),
    ShowWWDXTimer = MsgIdAdd(),
    ReadWWDXInfo = MsgIdAdd(),
    UpdateBoxInfo = MsgIdAdd(),
    EnterWWDXBattleSuc = MsgIdAdd(),
    WWDXBattleCoundDown = MsgIdAdd(),
    WWDXUpdateAfterBetUI = MsgIdAdd(),
    WWDXUpdateCound = MsgIdAdd(),
}

LUIDiscountBagEvent = 
{
    UpdateDataEvent = MsgIdAdd(),--更新数据
    BuyResultEvent = MsgIdAdd(),--更新数据
    NewUpdateDataEvent = MsgIdAdd(),--更新数据
    NewBuyResultEvent = MsgIdAdd(),--更新数据
}

LUIZaDanEvent = 
{
    UpdateDataEvent = MsgIdAdd(),--更新数据
    BuyResultEvent = MsgIdAdd(),--更新数据
}

--------------------------------大地图相关-----------------------------------------------------
LUIFuBenMapEvent = 
{
    refrashBigMapUI = MsgIdAdd(), --刷新大地图UI
    refrashStageMapUI = MsgIdAdd(), --刷新第二层地图
    refrashUIAfterFight = MsgIdAdd(), --战斗结束后,刷新UI
    updateSaoDangEvent = MsgIdAdd(), --扫荡事件
    getBoxAwardSuc = MsgIdAdd(), --领取宝箱成功
    resetFightTimesSuc = MsgIdAdd(), --重置战斗次数
    updateFuBenAchievement = MsgIdAdd(), --更新副本
    FormationUIClosed = MsgIdAdd(), --更新副本

    tongGuanEvent = MsgIdAdd(), --通关事件
    getSingleNodeSuc = MsgIdAdd(), --请求单关数据成功
}
---------------------------在线奖励------------------ 
LOnLineEvent={
    GetReward=MsgIdAdd(),
    DeleteTimeFun=MsgIdAdd(),
    AddTimeFun=MsgIdAdd(),
    UpdateTime=MsgIdAdd(),
}
-------------

--------------------------------神将相关-----------------------------------------------------
LUIKaPaiPetEvent = 
{
    ShowPetLeftInfo = MsgIdAdd(), --刷新大地图UI
    updatePetLvUp = MsgIdAdd(), --更新宠物升级
    ShowHeroBookUI = MsgIdAdd(), --显示图鉴UI
    UpdateHeroBookUI = MsgIdAdd(), --显示图鉴UI
    BookLevelUpSuc = MsgIdAdd(),    --图鉴升级成功
    ChangePetInitData = MsgIdAdd(), --更换神将传入数据
	BGVisible = MsgIdAdd(), --tab背景是否显示
}

---------------------------------抽卡------------------------------------------------------
LUIDrawEvent = 
{
    updateDrawUI = MsgIdAdd(), --更新抽卡界面
    SingleDrawSuccess = MsgIdAdd(), --抽卡成功
    TenDrawSuccess = MsgIdAdd(), --十连抽成功
    continueDanCiDrawSuc = MsgIdAdd(), --单抽
    continueDrawSuc = MsgIdAdd(), --继续十连抽
}

LHuiShouEvent =
{
	SelectShengJiang = MsgIdAdd(),
	ShengJiangChaXun = MsgIdAdd(),
	ShengJiangChongSheng = MsgIdAdd(),
	SelectZhuangBei = MsgIdAdd(),
	ZhuangBeiChaXun = MsgIdAdd(),
	ZhuangBeiChongSheng = MsgIdAdd(),
	SelectFenJieZhuangBei = MsgIdAdd(),
	FenJieZhuangBeiChaXun = MsgIdAdd(),
	FenJieZhuangBei = MsgIdAdd(),
	SelectFaBao = MsgIdAdd(),
	FaBaoChaXun = MsgIdAdd(),
	FaBaoChongSheng	= MsgIdAdd(),
	SelectFenJieFaBao = MsgIdAdd(),
	FenJieFaBaoChaXun = MsgIdAdd(),
	FenJieFaBao = MsgIdAdd(),
}

-------------------------------资源加载相关的消息-----------------------------------------
lUIBegin = LManagerID.LAssetManager
LResEvent = 
{
    Init = MsgIdAdd(),--初始化
    LoadCsb = MsgIdAdd(),--加载csb文件
    UnusedCsb = MsgIdAdd(),--
    LoadAni = MsgIdAdd(),--加载动画文件
    LoadImg = MsgIdAdd(),--同步加载图片
    LoadImgSync = MsgIdAdd(),--异步加载图片
    UnLoadImgSync = MsgIdAdd(),--取消加载图片
    DeleteImg = MsgIdAdd(),--删除指定的图片
    ChangeMap = MsgIdAdd(),--切换地图
    ChangeMapSuccess = MsgIdAdd(),--切换地图
    DeleteUnUsedImg = MsgIdAdd(),--删除未使用的图片
}